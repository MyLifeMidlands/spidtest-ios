import SwiftUI

struct DNSLeakTestView: View {
    @StateObject private var viewModel = DNSLeakTestViewModel()
    @State private var showDNSInfo = false
    @State private var showWebRTCInfo = false
    @State private var showScoreInfo = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Shield indicator
                    shieldSection

                    // Status text
                    statusSection

                    // Test button
                    VombatButton(
                        title: String(localized: viewModel.isTesting ? "Testing..." : "Run Security Test"),
                        icon: viewModel.isTesting ? "arrow.triangle.2.circlepath" : "shield.checkered"
                    ) {
                        Task { await viewModel.runFullTest() }
                    }
                    .disabled(viewModel.isTesting)
                    .opacity(viewModel.isTesting ? 0.6 : 1)

                    // VPN status info
                    if !viewModel.vpnConnected {
                        vpnWarning
                    }

                    // IP Info card
                    if let ipInfo = viewModel.ipInfo {
                        ipInfoSection(ipInfo)
                    } else if viewModel.isLoadingIP {
                        ProgressView()
                            .tint(Theme.Colors.primary)
                    }

                    // WebRTC result
                    if let webRTC = viewModel.webRTCResult {
                        webRTCSection(webRTC)
                    }

                    // DNS Results
                    if !viewModel.results.isEmpty {
                        resultsSection
                    }

                    // Security Score & Recommendations
                    if !viewModel.recommendations.isEmpty {
                        securityScoreSection
                        recommendationsSection
                    }

                    // Info card
                    infoCard

                    Spacer(minLength: 20)
                }
                .padding(.horizontal, Theme.Layout.screenPadding)
                .padding(.top, 20)
            }
            .background(Theme.Colors.background)
            .navigationTitle(String(localized: "Security Test"))
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    // MARK: - Shield

    private var shieldSection: some View {
        ZStack {
            Circle()
                .fill(shieldColor.opacity(0.1))
                .frame(width: 160, height: 160)

            Circle()
                .stroke(shieldColor.opacity(0.3), lineWidth: 3)
                .frame(width: 160, height: 160)

            Image(systemName: shieldIcon)
                .font(.system(size: 64, weight: .light))
                .foregroundStyle(shieldColor)
                .symbolEffect(.pulse, isActive: viewModel.isTesting)
        }
        .padding(.top, 20)
    }

    private var shieldColor: Color {
        switch viewModel.status {
        case .safe: return Theme.Colors.success
        case .leak: return Theme.Colors.error
        case .noVPN: return Theme.Colors.warning
        case .testing: return Theme.Colors.primary
        case .error: return Theme.Colors.error
        case .idle: return Theme.Colors.textSecondary
        }
    }

    private var shieldIcon: String {
        switch viewModel.status {
        case .safe: return "checkmark.shield.fill"
        case .leak: return "exclamationmark.shield.fill"
        case .noVPN: return "shield.slash"
        case .testing: return "shield.checkered"
        case .error: return "xmark.shield"
        case .idle: return "shield"
        }
    }

    // MARK: - Status

    private var statusSection: some View {
        VStack(spacing: 8) {
            Text(viewModel.status.label)
                .font(Theme.Fonts.title)
                .foregroundStyle(Theme.Colors.textPrimary)
                .multilineTextAlignment(.center)

            if viewModel.queryTime > 0 {
                Text(String(format: String(localized: "Completed in %@s"), String(format: "%.1f", viewModel.queryTime)))
                    .font(Theme.Fonts.caption)
                    .foregroundStyle(Theme.Colors.textSecondary)
            }
        }
    }

    // MARK: - VPN Warning

    private var vpnWarning: some View {
        GlassCard {
            HStack(spacing: 12) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundStyle(Theme.Colors.warning)

                Text(String(localized: "Connect VPN first for accurate results"))
                    .font(Theme.Fonts.caption)
                    .foregroundStyle(Theme.Colors.textSecondary)
            }
        }
    }

    // MARK: - IP Info

    private func ipInfoSection(_ info: IPInfo) -> some View {
        GlassCard {
            VStack(spacing: 12) {
                HStack {
                    Image(systemName: "globe")
                        .foregroundStyle(Theme.Colors.primary)
                    Text(String(localized: "Your IP Address"))
                        .font(Theme.Fonts.title)
                        .foregroundStyle(Theme.Colors.textPrimary)
                    Spacer()
                }

                HStack(spacing: 12) {
                    Text(info.flagEmoji)
                        .font(.system(size: 36))

                    VStack(alignment: .leading, spacing: 4) {
                        Text(info.ip)
                            .font(.system(size: 18, weight: .semibold, design: .monospaced))
                            .foregroundStyle(Theme.Colors.textPrimary)

                        Text(info.location)
                            .font(Theme.Fonts.caption)
                            .foregroundStyle(Theme.Colors.textSecondary)
                    }

                    Spacer()
                }

                Divider().background(Theme.Colors.surfaceLight)

                HStack(spacing: 16) {
                    ipDetail(icon: "building.2", label: "ISP", value: info.isp)
                    if !info.org.isEmpty && info.org != info.isp {
                        ipDetail(icon: "server.rack", label: "Org", value: info.org)
                    }
                }

                if !info.timezone.isEmpty {
                    HStack {
                        ipDetail(icon: "clock", label: String(localized: "Timezone"), value: info.timezone)
                        Spacer()
                    }
                }
            }
        }
    }

    private func ipDetail(icon: String, label: String, value: String) -> some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 12))
                .foregroundStyle(Theme.Colors.textSecondary)
            VStack(alignment: .leading, spacing: 1) {
                Text(label)
                    .font(.system(size: 10))
                    .foregroundStyle(Theme.Colors.textSecondary)
                Text(value)
                    .font(Theme.Fonts.caption)
                    .foregroundStyle(Theme.Colors.textPrimary)
                    .lineLimit(1)
            }
        }
    }

    // MARK: - WebRTC

    private func webRTCSection(_ result: WebRTCLeakService.WebRTCResult) -> some View {
        GlassCard {
            VStack(spacing: 12) {
                HStack {
                    Image(systemName: result.hasLeak ? "exclamationmark.triangle.fill" : "checkmark.circle.fill")
                        .foregroundStyle(result.hasLeak ? Theme.Colors.error : Theme.Colors.success)

                    Text(String(localized: "WebRTC Leak Test"))
                        .font(Theme.Fonts.title)
                        .foregroundStyle(Theme.Colors.textPrimary)

                    Button { showWebRTCInfo = true } label: {
                        Image(systemName: "questionmark.circle")
                            .foregroundStyle(Theme.Colors.textSecondary)
                            .font(.system(size: 14))
                    }
                    .sheet(isPresented: $showWebRTCInfo) {
                        InfoSheet(title: "WebRTC", sections: HelpTopics.webRTCLeak)
                    }

                    Spacer()

                    Text(result.hasLeak ? String(localized: "Leak") : String(localized: "Safe"))
                        .font(Theme.Fonts.caption)
                        .foregroundStyle(result.hasLeak ? Theme.Colors.error : Theme.Colors.success)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(
                            Capsule()
                                .fill((result.hasLeak ? Theme.Colors.error : Theme.Colors.success).opacity(0.15))
                        )
                }

                if !result.localIPs.isEmpty {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(String(localized: "Detected local IPs:"))
                            .font(Theme.Fonts.caption)
                            .foregroundStyle(Theme.Colors.textSecondary)

                        ForEach(result.localIPs, id: \.self) { ip in
                            HStack(spacing: 6) {
                                Circle()
                                    .fill(Theme.Colors.textSecondary.opacity(0.5))
                                    .frame(width: 4, height: 4)
                                Text(ip)
                                    .font(.system(size: 13, design: .monospaced))
                                    .foregroundStyle(Theme.Colors.textPrimary)
                            }
                        }
                    }
                }
            }
        }
    }

    // MARK: - DNS Results

    private var resultsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(String(localized: "DNS Servers Detected"))
                .font(Theme.Fonts.title)
                .foregroundStyle(Theme.Colors.textPrimary)

            ForEach(viewModel.results) { result in
                GlassCard {
                    HStack {
                        Text(result.flagEmoji)
                            .font(.system(size: 28))

                        VStack(alignment: .leading, spacing: 4) {
                            Text(result.ip)
                                .font(Theme.Fonts.body)
                                .foregroundStyle(Theme.Colors.textPrimary)
                                .monospacedDigit()

                            Text(result.isp)
                                .font(Theme.Fonts.caption)
                                .foregroundStyle(Theme.Colors.textSecondary)
                        }

                        Spacer()

                        Text(result.country)
                            .font(Theme.Fonts.caption)
                            .foregroundStyle(Theme.Colors.textSecondary)
                    }
                }
            }
        }
    }

    // MARK: - Security Score

    private var securityScoreSection: some View {
        GlassCard {
            VStack(spacing: 12) {
                HStack {
                    Image(systemName: "shield.lefthalf.filled")
                        .foregroundStyle(Theme.Colors.primary)
                    Text(String(localized: "Security Score"))
                        .font(Theme.Fonts.title)
                        .foregroundStyle(Theme.Colors.textPrimary)
                    Spacer()
                    Button { showScoreInfo = true } label: {
                        Image(systemName: "questionmark.circle")
                            .foregroundStyle(Theme.Colors.textSecondary)
                    }
                }
                .sheet(isPresented: $showScoreInfo) {
                    InfoSheet(title: String(localized: "Security Score"), sections: HelpTopics.securityScore)
                }

                HStack(spacing: 16) {
                    // Score circle
                    ZStack {
                        Circle()
                            .stroke(Theme.Colors.surfaceLight, lineWidth: 6)
                            .frame(width: 64, height: 64)

                        Circle()
                            .trim(from: 0, to: CGFloat(viewModel.securityScore) / 100)
                            .stroke(scoreColor, style: StrokeStyle(lineWidth: 6, lineCap: .round))
                            .frame(width: 64, height: 64)
                            .rotationEffect(.degrees(-90))

                        Text("\(viewModel.securityScore)%")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundStyle(Theme.Colors.textPrimary)
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        Text(viewModel.securityScoreLabel)
                            .font(Theme.Fonts.title)
                            .foregroundStyle(scoreColor)

                        let resolved = viewModel.recommendations.filter { $0.isResolved }.count
                        let total = viewModel.recommendations.count
                        Text(String(format: String(localized: "%d of %d checks passed"), resolved, total))
                            .font(Theme.Fonts.caption)
                            .foregroundStyle(Theme.Colors.textSecondary)
                    }

                    Spacer()
                }
            }
        }
    }

    private var scoreColor: Color {
        if viewModel.securityScore >= 80 { return Theme.Colors.success }
        if viewModel.securityScore >= 60 { return Theme.Colors.primary }
        if viewModel.securityScore >= 40 { return Theme.Colors.warning }
        return Theme.Colors.error
    }

    // MARK: - Recommendations

    private var recommendationsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(String(localized: "Recommendations"))
                .font(Theme.Fonts.title)
                .foregroundStyle(Theme.Colors.textPrimary)

            ForEach(viewModel.recommendations) { rec in
                GlassCard {
                    HStack(alignment: .top, spacing: 12) {
                        Image(systemName: rec.icon)
                            .foregroundStyle(recColor(rec.severity))
                            .font(.system(size: 20))
                            .frame(width: 24)

                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                Text(rec.title)
                                    .font(Theme.Fonts.body)
                                    .foregroundStyle(Theme.Colors.textPrimary)

                                Spacer()

                                if rec.isResolved {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundStyle(Theme.Colors.success)
                                        .font(.system(size: 14))
                                }
                            }

                            Text(rec.description)
                                .font(Theme.Fonts.caption)
                                .foregroundStyle(Theme.Colors.textSecondary)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                }
            }
        }
    }

    private func recColor(_ severity: SecurityRecommendation.Severity) -> Color {
        switch severity {
        case .critical: return Theme.Colors.error
        case .warning: return Theme.Colors.warning
        case .info: return Theme.Colors.primary
        case .good: return Theme.Colors.success
        }
    }

    // MARK: - Info Card

    private var infoCard: some View {
        Button { showDNSInfo = true } label: {
            GlassCard {
                VStack(alignment: .leading, spacing: 8) {
                    Label(String(localized: "About Security Tests"), systemImage: "info.circle")
                        .font(Theme.Fonts.body)
                        .foregroundStyle(Theme.Colors.primary)

                    Text(String(localized: "This test checks for DNS leaks, WebRTC IP exposure, and analyzes your connection security. Tap to learn more."))
                        .font(Theme.Fonts.caption)
                        .foregroundStyle(Theme.Colors.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
        .sheet(isPresented: $showDNSInfo) {
            InfoSheet(title: String(localized: "Security Tests"), sections: HelpTopics.dnsLeak)
        }
    }
}
