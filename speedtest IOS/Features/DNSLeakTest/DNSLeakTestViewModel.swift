import Foundation

@MainActor
final class DNSLeakTestViewModel: ObservableObject {
    @Published var status: LeakStatus = .idle
    @Published var results: [DNSLeakResult] = []
    @Published var isTesting = false
    @Published var queryTime: TimeInterval = 0

    // IP Info
    @Published var ipInfo: IPInfo?
    @Published var isLoadingIP = false

    // WebRTC
    @Published var webRTCResult: WebRTCLeakService.WebRTCResult?
    @Published var isTestingWebRTC = false

    // Recommendations
    @Published var recommendations: [SecurityRecommendation] = []

    private let service = DNSLeakTestService()
    private let vpnManager = VPNManager.shared

    var vpnConnected: Bool {
        vpnManager.state == .connected
    }

    // MARK: - Full Security Test

    func runFullTest() async {
        isTesting = true
        status = .testing
        results = []
        queryTime = 0
        webRTCResult = nil
        recommendations = []

        // Run IP Info + DNS + WebRTC in parallel
        await withTaskGroup(of: Void.self) { group in
            group.addTask { await self.fetchIPInfo() }
            group.addTask { await self.runDNSTest() }
            group.addTask { await self.runWebRTCTest() }
        }

        // Generate recommendations based on results
        generateRecommendations()

        isTesting = false
    }

    // MARK: - DNS Leak Test

    func runDNSTest() async {
        let startTime = CFAbsoluteTimeGetCurrent()

        do {
            let testResults = try await service.runTest()
            let elapsed = CFAbsoluteTimeGetCurrent() - startTime

            results = testResults
            queryTime = elapsed
            status = service.checkForLeaks(results: testResults, vpnConnected: vpnConnected)
        } catch {
            status = .error(error.localizedDescription)
        }
    }

    // MARK: - IP Info

    func fetchIPInfo() async {
        isLoadingIP = true
        do {
            ipInfo = try await IPInfoService.fetch()
        } catch {
            ipInfo = nil
        }
        isLoadingIP = false
    }

    // MARK: - WebRTC Leak Test

    func runWebRTCTest() async {
        isTestingWebRTC = true
        let result = await WebRTCLeakService.checkLeak(vpnIP: ipInfo?.ip)
        webRTCResult = result
        isTestingWebRTC = false
    }

    // MARK: - Recommendations

    private func generateRecommendations() {
        let dnsLeak = status == .leak
        let webRTCLeak = webRTCResult?.hasLeak ?? false

        recommendations = SecurityRecommendation.generate(
            vpnConnected: vpnConnected,
            killSwitchEnabled: SharedDefaults.shared.killSwitch,
            dnsLeakDetected: dnsLeak,
            webRTCLeakDetected: webRTCLeak
        )
    }

    // MARK: - Security Score

    var securityScore: Int {
        guard !recommendations.isEmpty else { return 0 }
        let resolved = recommendations.filter { $0.isResolved }.count
        return (resolved * 100) / recommendations.count
    }

    var securityScoreLabel: String {
        if securityScore >= 80 { return String(localized: "Excellent") }
        if securityScore >= 60 { return String(localized: "Good") }
        if securityScore >= 40 { return String(localized: "Fair") }
        return String(localized: "Poor")
    }
}
