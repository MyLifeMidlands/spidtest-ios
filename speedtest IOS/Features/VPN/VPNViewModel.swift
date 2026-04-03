import Foundation
import SwiftUI
import Combine
import UIKit

@MainActor
final class VPNViewModel: ObservableObject {
    @Published var state: VPNConnectionState = .disconnected
    @Published var connectionDuration: TimeInterval = 0
    @Published var showAddServer = false
    @Published var showServerList = false
    @Published var importText = ""
    @Published var errorMessage: String?
    @Published var reconnectInfo: String?

    private let vpnManager = VPNManager.shared
    let serverStore = ServerStore.shared
    let loadBalancer = LoadBalancer.shared

    private var timer: Timer?
    private var cancellables = Set<AnyCancellable>()
    private var lastConnectedServer: VLESSConfig?
    private var failoverAttempts = 0
    private let maxFailoverAttempts = 3

    // Reconnection
    private var reconnectAttempts = 0
    private let maxReconnectAttempts = 3
    private var reconnectTask: Task<Void, Never>?
    private var wasConnectedBeforeDisconnect = false

    // Subscription refresh
    private var subscriptionRefreshTask: Task<Void, Never>?

    // Logging & Traffic
    private let connectionLog = ConnectionLogStore.shared
    private let trafficStats = TrafficStatsStore.shared

    init() {
        vpnManager.$state
            .receive(on: DispatchQueue.main)
            .assign(to: &$state)

        $state
            .removeDuplicates()
            .sink { [weak self] newState in
                guard let self = self else { return }
                self.handleStateChange(newState)
            }
            .store(in: &cancellables)
    }

    // MARK: - State Handling

    private func handleStateChange(_ newState: VPNConnectionState) {
        let previouslyConnected = wasConnectedBeforeDisconnect

        switch newState {
        case .connected:
            startTimer()
            failoverAttempts = 0
            reconnectAttempts = 0
            reconnectInfo = nil
            wasConnectedBeforeDisconnect = true
            // Save last connected server
            if let server = lastConnectedServer {
                SharedDefaults.shared.lastConnectedServerID = server.id
                connectionLog.log(serverName: server.name, serverAddress: server.address, event: .connected)
            }
            // Traffic
            trafficStats.startSession()
            // Haptic
            triggerHaptic(.success)

        case .connecting:
            break

        case .disconnecting:
            break

        case .disconnected:
            let duration = connectionDuration
            stopTimer()
            connectionDuration = 0
            trafficStats.endSession()
            // Log disconnect
            if let server = lastConnectedServer {
                connectionLog.log(serverName: server.name, serverAddress: server.address, event: .disconnected, duration: duration)
            }
            // Auto-reconnect if was connected (unexpected disconnect)
            if previouslyConnected && SharedDefaults.shared.autoReconnect {
                wasConnectedBeforeDisconnect = false
                Task { await attemptAutoReconnect() }
            } else {
                wasConnectedBeforeDisconnect = false
                triggerHaptic(.warning)
            }

        case .error:
            stopTimer()
            connectionDuration = 0
            wasConnectedBeforeDisconnect = false
            trafficStats.endSession()
            // Log error
            if let server = lastConnectedServer {
                connectionLog.log(serverName: server.name, serverAddress: server.address, event: .error, error: errorMessage)
            }
            triggerHaptic(.error)
            // Failover mode
            if loadBalancer.mode == .failover, failoverAttempts < maxFailoverAttempts {
                Task { await attemptFailover() }
            }
            // Auto-reconnect on error
            else if SharedDefaults.shared.autoReconnect, reconnectAttempts < maxReconnectAttempts {
                Task { await attemptAutoReconnect() }
            }
        }
    }

    // MARK: - Actions

    func setup() async {
        do {
            try await vpnManager.loadOrCreateManager()
        } catch {
            errorMessage = error.localizedDescription
        }

        // Auto-ping on open
        if SharedDefaults.shared.autoPingOnOpen {
            await loadBalancer.measureAllPings(servers: serverStore.servers)
        } else if loadBalancer.mode == .bestPing {
            await loadBalancer.measureAllPings(servers: serverStore.servers)
        }

        // Auto-connect on launch
        if SharedDefaults.shared.autoConnect && state == .disconnected {
            await autoConnectToLastServer()
        }

        // Start subscription refresh
        startSubscriptionRefresh()
    }

    func toggleConnection() async {
        errorMessage = nil
        reconnectInfo = nil
        cancelReconnect()

        if state == .connected || state == .connecting {
            wasConnectedBeforeDisconnect = false // User-initiated disconnect
            vpnManager.disconnect()
            triggerHaptic(.light)
            return
        }

        // Select server based on balancing mode
        let server: VLESSConfig?
        if loadBalancer.mode == .bestPing && loadBalancer.serverPings.isEmpty {
            await loadBalancer.measureAllPings(servers: serverStore.servers)
            server = loadBalancer.selectServer(from: serverStore.servers, current: serverStore.activeServer)
        } else {
            server = loadBalancer.selectServer(from: serverStore.servers, current: serverStore.activeServer)
        }

        guard let server = server else {
            showAddServer = true
            return
        }

        serverStore.setActive(id: server.id)
        lastConnectedServer = server

        do {
            try await vpnManager.connect(server: server)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    @Published var isImporting = false

    func importURI() async {
        let text = importText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }

        isImporting = true
        defer { isImporting = false }

        do {
            let count = try await serverStore.importFromInput(text)
            importText = ""
            showAddServer = false
            errorMessage = nil
            if count > 1 {
                errorMessage = nil
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    // MARK: - Auto-Reconnect

    private func attemptAutoReconnect() async {
        guard reconnectAttempts < maxReconnectAttempts else {
            reconnectInfo = nil
            errorMessage = String(localized: "Reconnection failed after \(maxReconnectAttempts) attempts")
            return
        }

        reconnectAttempts += 1
        let attempt = reconnectAttempts

        let delay: UInt64
        if SharedDefaults.shared.aggressiveReconnect {
            delay = UInt64(attempt) * 1_000_000_000 // 1s, 2s, 3s
        } else {
            delay = UInt64(attempt) * 3_000_000_000 // 3s, 6s, 9s
        }

        reconnectInfo = String(localized: "Reconnecting... (\(attempt)/\(maxReconnectAttempts))")

        reconnectTask = Task {
            try? await Task.sleep(nanoseconds: delay)

            guard !Task.isCancelled else { return }

            let server = lastConnectedServer
                ?? serverStore.activeServer
                ?? lastSavedServer()

            guard let server = server else {
                reconnectInfo = nil
                errorMessage = String(localized: "No server available for reconnection")
                return
            }

            lastConnectedServer = server

            do {
                try await vpnManager.connect(server: server)
            } catch {
                if !Task.isCancelled {
                    errorMessage = error.localizedDescription
                }
            }
        }
    }

    private func cancelReconnect() {
        reconnectTask?.cancel()
        reconnectTask = nil
        reconnectAttempts = 0
        reconnectInfo = nil
    }

    private func lastSavedServer() -> VLESSConfig? {
        guard let id = SharedDefaults.shared.lastConnectedServerID else { return nil }
        return serverStore.servers.first { $0.id == id }
    }

    // MARK: - Auto-Connect on Launch

    private func autoConnectToLastServer() async {
        let server = serverStore.activeServer
            ?? lastSavedServer()
            ?? serverStore.servers.first

        guard let server = server else { return }

        serverStore.setActive(id: server.id)
        lastConnectedServer = server

        do {
            try await vpnManager.connect(server: server)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    // MARK: - Subscription Refresh

    private func startSubscriptionRefresh() {
        subscriptionRefreshTask?.cancel()

        let intervalHours = SharedDefaults.shared.subscriptionRefreshInterval
        guard intervalHours > 0 else { return }

        subscriptionRefreshTask = Task {
            while !Task.isCancelled {
                let intervalSeconds = UInt64(intervalHours) * 3600 * 1_000_000_000
                try? await Task.sleep(nanoseconds: intervalSeconds)
                guard !Task.isCancelled else { break }
                await serverStore.refreshSubscriptions()
            }
        }
    }

    func restartSubscriptionRefresh() {
        startSubscriptionRefresh()
    }

    // MARK: - Failover

    private func attemptFailover() async {
        guard let failed = lastConnectedServer else { return }
        failoverAttempts += 1

        errorMessage = String(localized: "Server failed. Switching... (\(failoverAttempts)/\(maxFailoverAttempts))")

        guard let next = loadBalancer.nextFailoverServer(from: serverStore.servers, failed: failed) else {
            errorMessage = String(localized: "No other servers available")
            return
        }

        serverStore.setActive(id: next.id)
        lastConnectedServer = next

        do {
            try await vpnManager.connect(server: next)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    // MARK: - Haptic Feedback

    private func triggerHaptic(_ type: UINotificationFeedbackGenerator.FeedbackType) {
        guard SharedDefaults.shared.hapticFeedback else { return }
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(type)
    }

    private func triggerHaptic(_ style: UIImpactFeedbackGenerator.FeedbackStyle) {
        guard SharedDefaults.shared.hapticFeedback else { return }
        let generator = UIImpactFeedbackGenerator(style: style)
        generator.impactOccurred()
    }

    // MARK: - Timer

    var formattedDuration: String {
        let hours = Int(connectionDuration) / 3600
        let minutes = (Int(connectionDuration) % 3600) / 60
        let seconds = Int(connectionDuration) % 60
        return String(format: "%02d:%02d:%02d", hours, minutes, seconds)
    }

    private func startTimer() {
        stopTimer()
        let startDate = vpnManager.connectedSince ?? Date()
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.connectionDuration = Date().timeIntervalSince(startDate)
            }
        }
    }

    private func stopTimer() {
        timer?.invalidate()
        timer = nil
    }
}
