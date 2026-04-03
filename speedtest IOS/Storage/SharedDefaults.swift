import Foundation

final class SharedDefaults {
    static let shared = SharedDefaults()

    private let defaults: UserDefaults

    private enum Keys {
        static let vpnState = "vpn_state"
        static let servers = "vpn_servers"
        static let activeServerID = "vpn_active_server_id"
        static let autoConnect = "vpn_auto_connect"
        static let killSwitch = "vpn_kill_switch"
        static let connectedSince = "vpn_connected_since"
        static let balancingMode = "vpn_balancing_mode"
        static let autoReconnect = "vpn_auto_reconnect"
        static let aggressiveReconnect = "vpn_aggressive_reconnect"
        static let autoPingOnOpen = "vpn_auto_ping_on_open"
        static let subscriptionRefreshInterval = "vpn_subscription_refresh_interval"
        static let hapticFeedback = "vpn_haptic_feedback"
        static let lastConnectedServerID = "vpn_last_connected_server_id"
        static let subscriptionURLs = "vpn_subscription_urls"
    }

    init() {
        guard let defaults = UserDefaults(suiteName: AppConstants.VPN.appGroupID) else {
            fatalError("Failed to initialize UserDefaults with App Group: \(AppConstants.VPN.appGroupID)")
        }
        self.defaults = defaults
    }

    // MARK: - VPN State

    var vpnState: VPNConnectionState {
        get {
            guard let raw = defaults.string(forKey: Keys.vpnState),
                  let state = VPNConnectionState(rawValue: raw) else {
                return .disconnected
            }
            return state
        }
        set {
            defaults.set(newValue.rawValue, forKey: Keys.vpnState)
        }
    }

    // MARK: - Servers

    var servers: [VLESSConfig] {
        get {
            guard let data = defaults.data(forKey: Keys.servers),
                  let configs = try? JSONDecoder().decode([VLESSConfig].self, from: data) else {
                return []
            }
            return configs
        }
        set {
            if let data = try? JSONEncoder().encode(newValue) {
                defaults.set(data, forKey: Keys.servers)
            }
        }
    }

    var activeServerID: UUID? {
        get {
            guard let str = defaults.string(forKey: Keys.activeServerID) else { return nil }
            return UUID(uuidString: str)
        }
        set {
            defaults.set(newValue?.uuidString, forKey: Keys.activeServerID)
        }
    }

    var activeServer: VLESSConfig? {
        guard let id = activeServerID else { return nil }
        return servers.first { $0.id == id }
    }

    // MARK: - Settings

    var autoConnect: Bool {
        get { defaults.bool(forKey: Keys.autoConnect) }
        set { defaults.set(newValue, forKey: Keys.autoConnect) }
    }

    var killSwitch: Bool {
        get { defaults.bool(forKey: Keys.killSwitch) }
        set { defaults.set(newValue, forKey: Keys.killSwitch) }
    }

    var balancingMode: BalancingMode {
        get {
            guard let raw = defaults.string(forKey: Keys.balancingMode),
                  let mode = BalancingMode(rawValue: raw) else {
                return .bestPing
            }
            return mode
        }
        set {
            defaults.set(newValue.rawValue, forKey: Keys.balancingMode)
        }
    }

    // MARK: - Reconnection

    var autoReconnect: Bool {
        get { defaults.object(forKey: Keys.autoReconnect) == nil ? true : defaults.bool(forKey: Keys.autoReconnect) }
        set { defaults.set(newValue, forKey: Keys.autoReconnect) }
    }

    var aggressiveReconnect: Bool {
        get { defaults.bool(forKey: Keys.aggressiveReconnect) }
        set { defaults.set(newValue, forKey: Keys.aggressiveReconnect) }
    }

    var autoPingOnOpen: Bool {
        get { defaults.bool(forKey: Keys.autoPingOnOpen) }
        set { defaults.set(newValue, forKey: Keys.autoPingOnOpen) }
    }

    var hapticFeedback: Bool {
        get { defaults.object(forKey: Keys.hapticFeedback) == nil ? true : defaults.bool(forKey: Keys.hapticFeedback) }
        set { defaults.set(newValue, forKey: Keys.hapticFeedback) }
    }

    /// Subscription refresh interval in hours (0 = disabled)
    var subscriptionRefreshInterval: Int {
        get {
            let val = defaults.integer(forKey: Keys.subscriptionRefreshInterval)
            return val == 0 ? 12 : val
        }
        set { defaults.set(newValue, forKey: Keys.subscriptionRefreshInterval) }
    }

    var lastConnectedServerID: UUID? {
        get {
            guard let str = defaults.string(forKey: Keys.lastConnectedServerID) else { return nil }
            return UUID(uuidString: str)
        }
        set { defaults.set(newValue?.uuidString, forKey: Keys.lastConnectedServerID) }
    }

    var subscriptionURLs: [String] {
        get { defaults.stringArray(forKey: Keys.subscriptionURLs) ?? [] }
        set { defaults.set(newValue, forKey: Keys.subscriptionURLs) }
    }

    // MARK: - Connection Timer

    var connectedSince: Date? {
        get { defaults.object(forKey: Keys.connectedSince) as? Date }
        set { defaults.set(newValue, forKey: Keys.connectedSince) }
    }

    // MARK: - Reset

    func resetAll() {
        let domain = AppConstants.VPN.appGroupID
        defaults.removePersistentDomain(forName: domain)
        defaults.synchronize()
    }
}
