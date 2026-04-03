import SwiftUI

struct SettingsView: View {
    @State private var autoConnect = SharedDefaults.shared.autoConnect
    @State private var killSwitch = SharedDefaults.shared.killSwitch
    @State private var autoReconnect = SharedDefaults.shared.autoReconnect
    @State private var aggressiveReconnect = SharedDefaults.shared.aggressiveReconnect
    @State private var autoPingOnOpen = SharedDefaults.shared.autoPingOnOpen
    @State private var hapticFeedback = SharedDefaults.shared.hapticFeedback
    @State private var subscriptionInterval = SharedDefaults.shared.subscriptionRefreshInterval
    @State private var showResetConfirmation = false
    @State private var showRouting = false
    @State private var showExportImport = false
    @State private var showKillSwitchInfo = false
    @State private var showReconnectInfo = false
    @State private var showLoadBalancingInfo = false
    @State private var showLanguageRestartAlert = false
    @AppStorage("app_theme") private var appTheme: AppTheme = .dark
    @AppStorage("app_language") private var appLanguage: AppLanguage = .system
    @ObservedObject private var loadBalancer = LoadBalancer.shared
    @ObservedObject private var trafficStore = TrafficStatsStore.shared

    private let intervalOptions = [0, 1, 6, 12, 24, 48]

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.Colors.background.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 16) {
                        // VPN Settings
                        vpnSettingsSection

                        // Connection
                        connectionSection

                        // Subscription
                        subscriptionSection

                        // Routing
                        routingSection

                        // Load Balancing
                        loadBalancingSection

                        // Interface
                        interfaceSection

                        // Traffic Stats
                        trafficStatsSection

                        // History & Logs
                        VStack(spacing: 8) {
                            NavigationLink {
                                SpeedTestHistoryView()
                            } label: {
                                GlassCard {
                                    HStack {
                                        Image(systemName: "chart.bar.xaxis")
                                            .foregroundStyle(Theme.Colors.primary)
                                        Text(String(localized: "Speed Test History"))
                                            .font(Theme.Fonts.body)
                                            .foregroundStyle(Theme.Colors.textPrimary)
                                        Spacer()
                                        Image(systemName: "chevron.right")
                                            .foregroundStyle(Theme.Colors.textSecondary)
                                    }
                                }
                            }

                            NavigationLink {
                                ConnectionLogView()
                            } label: {
                                GlassCard {
                                    HStack {
                                        Image(systemName: "list.bullet.clipboard")
                                            .foregroundStyle(Theme.Colors.primary)
                                        Text(String(localized: "Connection Log"))
                                            .font(Theme.Fonts.body)
                                            .foregroundStyle(Theme.Colors.textPrimary)
                                        Spacer()
                                        Image(systemName: "chevron.right")
                                            .foregroundStyle(Theme.Colors.textSecondary)
                                    }
                                }
                            }
                        }
                        .padding(.horizontal, Theme.Layout.screenPadding)

                        // Export / Import
                        exportImportSection

                        // Links section
                        VStack(spacing: 8) {
                            linkRow(icon: "bubble.left.fill", title: String(localized: "Support"), url: AppConstants.supportURL)
                            linkRow(icon: "doc.text.fill", title: String(localized: "Privacy Policy"), url: AppConstants.privacyPolicyURL)
                            linkRow(icon: "doc.text.fill", title: String(localized: "Terms of Service"), url: AppConstants.termsURL)
                        }
                        .padding(.horizontal, Theme.Layout.screenPadding)

                        // Reset
                        resetSection

                        // App info
                        VStack(spacing: 4) {
                            Text(AppConstants.appName)
                                .font(Theme.Fonts.caption)
                                .foregroundStyle(Theme.Colors.textSecondary)
                            Text(String(format: String(localized: "Version %@"), Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"))
                                .font(Theme.Fonts.caption)
                                .foregroundStyle(Theme.Colors.textSecondary.opacity(0.6))
                        }
                        .padding(.top, 20)
                    }
                    .padding(.top, 8)
                }
            }
            .navigationTitle(String(localized: "Settings"))
            .toolbarColorScheme(.dark, for: .navigationBar)
        }
    }

    // MARK: - VPN Settings

    private var vpnSettingsSection: some View {
        GlassCard {
            VStack(spacing: 16) {
                HStack {
                    Image(systemName: "bolt.shield")
                        .foregroundStyle(Theme.Colors.primary)
                    Text(String(localized: "VPN Settings"))
                        .font(Theme.Fonts.title)
                        .foregroundStyle(Theme.Colors.textPrimary)
                    Spacer()
                }

                settingsToggle(
                    icon: "arrow.triangle.2.circlepath",
                    title: String(localized: "Auto-Connect"),
                    subtitle: String(localized: "Connect on app launch"),
                    isOn: $autoConnect
                ) { SharedDefaults.shared.autoConnect = $0 }

                Divider().background(Theme.Colors.surfaceLight)

                HStack {
                    settingsToggle(
                        icon: "hand.raised.fill",
                        title: String(localized: "Kill Switch"),
                        subtitle: String(localized: "Block traffic if VPN drops"),
                        isOn: $killSwitch
                    ) { SharedDefaults.shared.killSwitch = $0 }

                    infoButton { showKillSwitchInfo = true }
                }
                .sheet(isPresented: $showKillSwitchInfo) {
                    InfoSheet(title: String(localized: "Kill Switch"), sections: HelpTopics.killSwitch)
                }
            }
        }
        .padding(.horizontal, Theme.Layout.screenPadding)
    }

    // MARK: - Connection

    private var connectionSection: some View {
        GlassCard {
            VStack(spacing: 16) {
                HStack {
                    Image(systemName: "network")
                        .foregroundStyle(Theme.Colors.primary)
                    Text(String(localized: "Connection"))
                        .font(Theme.Fonts.title)
                        .foregroundStyle(Theme.Colors.textPrimary)
                    Spacer()
                    infoButton { showReconnectInfo = true }
                }
                .sheet(isPresented: $showReconnectInfo) {
                    InfoSheet(title: String(localized: "Connection"), sections: HelpTopics.autoReconnect)
                }

                settingsToggle(
                    icon: "arrow.counterclockwise",
                    title: String(localized: "Auto-Reconnect"),
                    subtitle: String(localized: "Reconnect on failure (up to 3 attempts)"),
                    isOn: $autoReconnect
                ) { SharedDefaults.shared.autoReconnect = $0 }

                Divider().background(Theme.Colors.surfaceLight)

                settingsToggle(
                    icon: "bolt.horizontal.fill",
                    title: String(localized: "Aggressive Reconnect"),
                    subtitle: String(localized: "Faster retry for unstable networks"),
                    isOn: $aggressiveReconnect
                ) { SharedDefaults.shared.aggressiveReconnect = $0 }

                Divider().background(Theme.Colors.surfaceLight)

                settingsToggle(
                    icon: "antenna.radiowaves.left.and.right",
                    title: String(localized: "Auto-Ping on Open"),
                    subtitle: String(localized: "Measure ping for all servers on launch"),
                    isOn: $autoPingOnOpen
                ) { SharedDefaults.shared.autoPingOnOpen = $0 }
            }
        }
        .padding(.horizontal, Theme.Layout.screenPadding)
    }

    // MARK: - Subscription

    private var subscriptionSection: some View {
        GlassCard {
            VStack(spacing: 16) {
                HStack {
                    Image(systemName: "arrow.triangle.2.circlepath.circle")
                        .foregroundStyle(Theme.Colors.primary)
                    Text(String(localized: "Subscription Refresh"))
                        .font(Theme.Fonts.title)
                        .foregroundStyle(Theme.Colors.textPrimary)
                    Spacer()
                }

                HStack(spacing: 10) {
                    Image(systemName: "clock.arrow.2.circlepath")
                        .foregroundStyle(Theme.Colors.textSecondary)
                        .frame(width: 24)

                    VStack(alignment: .leading, spacing: 2) {
                        Text(String(localized: "Refresh Interval"))
                            .font(Theme.Fonts.body)
                            .foregroundStyle(Theme.Colors.textPrimary)
                        Text(String(localized: "Auto-update server list from subscription"))
                            .font(Theme.Fonts.caption)
                            .foregroundStyle(Theme.Colors.textSecondary)
                    }

                    Spacer()

                    Menu {
                        ForEach(intervalOptions, id: \.self) { hours in
                            Button {
                                subscriptionInterval = hours
                                SharedDefaults.shared.subscriptionRefreshInterval = hours
                            } label: {
                                HStack {
                                    Text(intervalLabel(hours))
                                    if subscriptionInterval == hours {
                                        Image(systemName: "checkmark")
                                    }
                                }
                            }
                        }
                    } label: {
                        HStack(spacing: 4) {
                            Text(intervalLabel(subscriptionInterval))
                                .font(Theme.Fonts.caption)
                                .foregroundStyle(Theme.Colors.primary)
                            Image(systemName: "chevron.up.chevron.down")
                                .font(.system(size: 10))
                                .foregroundStyle(Theme.Colors.primary)
                        }
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Theme.Colors.primary.opacity(0.15))
                        )
                    }
                }
            }
        }
        .padding(.horizontal, Theme.Layout.screenPadding)
    }

    // MARK: - Load Balancing

    private var loadBalancingSection: some View {
        GlassCard {
            VStack(spacing: 12) {
                HStack {
                    Image(systemName: "scale.3d")
                        .foregroundStyle(Theme.Colors.primary)
                    Text(String(localized: "Load Balancing"))
                        .font(Theme.Fonts.title)
                        .foregroundStyle(Theme.Colors.textPrimary)
                    Spacer()
                    infoButton { showLoadBalancingInfo = true }
                }
                .sheet(isPresented: $showLoadBalancingInfo) {
                    InfoSheet(title: String(localized: "Load Balancing"), sections: HelpTopics.loadBalancing)
                }

                ForEach(BalancingMode.allCases, id: \.self) { mode in
                    Button {
                        loadBalancer.mode = mode
                    } label: {
                        HStack(spacing: 10) {
                            Image(systemName: mode.icon)
                                .foregroundStyle(loadBalancer.mode == mode ? Theme.Colors.primary : Theme.Colors.textSecondary)
                                .frame(width: 24)

                            VStack(alignment: .leading, spacing: 2) {
                                Text(mode.label)
                                    .font(Theme.Fonts.body)
                                    .foregroundStyle(Theme.Colors.textPrimary)
                                Text(mode.description)
                                    .font(Theme.Fonts.caption)
                                    .foregroundStyle(Theme.Colors.textSecondary)
                            }

                            Spacer()

                            if loadBalancer.mode == mode {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundStyle(Theme.Colors.primary)
                            }
                        }
                        .padding(.vertical, 4)
                    }

                    if mode != BalancingMode.allCases.last {
                        Divider()
                            .background(Theme.Colors.surfaceLight)
                    }
                }
            }
        }
        .padding(.horizontal, Theme.Layout.screenPadding)
    }

    // MARK: - Routing

    private var routingSection: some View {
        Button {
            showRouting = true
        } label: {
            GlassCard {
                HStack {
                    Image(systemName: "arrow.triangle.branch")
                        .foregroundStyle(Theme.Colors.primary)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(String(localized: "Routing"))
                            .font(Theme.Fonts.body)
                            .foregroundStyle(Theme.Colors.textPrimary)
                        Text(String(localized: "Traffic rules and split tunneling"))
                            .font(Theme.Fonts.caption)
                            .foregroundStyle(Theme.Colors.textSecondary)
                    }
                    Spacer()
                    Image(systemName: "chevron.right")
                        .foregroundStyle(Theme.Colors.textSecondary)
                }
            }
        }
        .padding(.horizontal, Theme.Layout.screenPadding)
        .sheet(isPresented: $showRouting) {
            RoutingView()
        }
    }

    // MARK: - Interface

    private var interfaceSection: some View {
        GlassCard {
            VStack(spacing: 16) {
                HStack {
                    Image(systemName: "paintbrush")
                        .foregroundStyle(Theme.Colors.primary)
                    Text(String(localized: "Interface"))
                        .font(Theme.Fonts.title)
                        .foregroundStyle(Theme.Colors.textPrimary)
                    Spacer()
                }

                // Theme picker
                HStack(spacing: 10) {
                    Image(systemName: "circle.lefthalf.filled")
                        .foregroundStyle(Theme.Colors.textSecondary)
                        .frame(width: 24)

                    Text(String(localized: "Theme"))
                        .font(Theme.Fonts.body)
                        .foregroundStyle(Theme.Colors.textPrimary)

                    Spacer()

                    HStack(spacing: 0) {
                        ForEach(AppTheme.allCases, id: \.self) { theme in
                            Button {
                                appTheme = theme
                            } label: {
                                Text(theme.label)
                                    .font(Theme.Fonts.caption)
                                    .foregroundStyle(appTheme == theme ? Theme.Colors.textPrimary : Theme.Colors.textSecondary)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 6)
                                    .background(
                                        appTheme == theme ? Theme.Colors.primary.opacity(0.2) : Color.clear
                                    )
                            }
                        }
                    }
                    .background(Theme.Colors.surfaceLight.opacity(0.5))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                }

                Divider().background(Theme.Colors.surfaceLight)

                settingsToggle(
                    icon: "iphone.radiowaves.left.and.right",
                    title: String(localized: "Haptic Feedback"),
                    subtitle: String(localized: "Vibration on connect/disconnect"),
                    isOn: $hapticFeedback
                ) { SharedDefaults.shared.hapticFeedback = $0 }

                Divider().background(Theme.Colors.surfaceLight)

                // Language picker
                HStack(spacing: 10) {
                    Image(systemName: "globe")
                        .foregroundStyle(Theme.Colors.textSecondary)
                        .frame(width: 24)

                    Text(String(localized: "Language"))
                        .font(Theme.Fonts.body)
                        .foregroundStyle(Theme.Colors.textPrimary)

                    Spacer()

                    Menu {
                        ForEach(AppLanguage.allCases, id: \.self) { lang in
                            Button {
                                if lang != appLanguage {
                                    appLanguage = lang
                                    lang.apply()
                                    showLanguageRestartAlert = true
                                }
                            } label: {
                                HStack {
                                    Text(lang.label)
                                    if appLanguage == lang {
                                        Image(systemName: "checkmark")
                                    }
                                }
                            }
                        }
                    } label: {
                        HStack(spacing: 4) {
                            Text(appLanguage.label)
                                .font(Theme.Fonts.caption)
                                .foregroundStyle(Theme.Colors.primary)
                            Image(systemName: "chevron.up.chevron.down")
                                .font(.system(size: 10))
                                .foregroundStyle(Theme.Colors.primary)
                        }
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Theme.Colors.primary.opacity(0.15))
                        )
                    }
                    .alert(String(localized: "Restart Required"), isPresented: $showLanguageRestartAlert) {
                        Button(String(localized: "OK")) {}
                    } message: {
                        Text(String(localized: "Please restart the app to apply the new language."))
                    }
                }
            }
        }
        .padding(.horizontal, Theme.Layout.screenPadding)
    }

    // MARK: - Traffic Stats

    private var trafficStatsSection: some View {
        GlassCard {
            VStack(spacing: 12) {
                HStack {
                    Image(systemName: "chart.bar.fill")
                        .foregroundStyle(Theme.Colors.primary)
                    Text(String(localized: "Traffic Statistics"))
                        .font(Theme.Fonts.title)
                        .foregroundStyle(Theme.Colors.textPrimary)
                    Spacer()
                }

                HStack(spacing: 16) {
                    trafficItem(
                        label: String(localized: "Session"),
                        download: trafficStore.stats.sessionDownload,
                        upload: trafficStore.stats.sessionUpload
                    )

                    Divider()
                        .background(Theme.Colors.surfaceLight)
                        .frame(height: 50)

                    trafficItem(
                        label: String(localized: "All Time"),
                        download: trafficStore.stats.totalDownload,
                        upload: trafficStore.stats.totalUpload
                    )
                }
            }
        }
        .padding(.horizontal, Theme.Layout.screenPadding)
    }

    private func trafficItem(label: String, download: Int64, upload: Int64) -> some View {
        VStack(spacing: 6) {
            Text(label)
                .font(Theme.Fonts.caption)
                .foregroundStyle(Theme.Colors.textSecondary)

            HStack(spacing: 4) {
                Image(systemName: "arrow.down")
                    .font(.system(size: 10))
                    .foregroundStyle(Theme.Colors.success)
                Text(TrafficStats.formatBytes(download))
                    .font(Theme.Fonts.caption)
                    .foregroundStyle(Theme.Colors.textPrimary)
                    .monospacedDigit()
            }

            HStack(spacing: 4) {
                Image(systemName: "arrow.up")
                    .font(.system(size: 10))
                    .foregroundStyle(Theme.Colors.secondary)
                Text(TrafficStats.formatBytes(upload))
                    .font(Theme.Fonts.caption)
                    .foregroundStyle(Theme.Colors.textPrimary)
                    .monospacedDigit()
            }
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Export / Import

    private var exportImportSection: some View {
        Button {
            showExportImport = true
        } label: {
            GlassCard {
                HStack {
                    Image(systemName: "square.and.arrow.up.on.square")
                        .foregroundStyle(Theme.Colors.primary)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(String(localized: "Export / Import"))
                            .font(Theme.Fonts.body)
                            .foregroundStyle(Theme.Colors.textPrimary)
                        Text(String(localized: "Share servers via QR code or URI"))
                            .font(Theme.Fonts.caption)
                            .foregroundStyle(Theme.Colors.textSecondary)
                    }
                    Spacer()
                    Image(systemName: "chevron.right")
                        .foregroundStyle(Theme.Colors.textSecondary)
                }
            }
        }
        .padding(.horizontal, Theme.Layout.screenPadding)
        .sheet(isPresented: $showExportImport) {
            ExportImportView()
        }
    }

    // MARK: - Reset

    private var resetSection: some View {
        Button {
            showResetConfirmation = true
        } label: {
            GlassCard {
                HStack {
                    Image(systemName: "trash")
                        .foregroundStyle(Theme.Colors.error)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(String(localized: "Reset All Data"))
                            .font(Theme.Fonts.body)
                            .foregroundStyle(Theme.Colors.error)
                        Text(String(localized: "Remove all servers, settings and history"))
                            .font(Theme.Fonts.caption)
                            .foregroundStyle(Theme.Colors.textSecondary)
                    }
                    Spacer()
                }
            }
        }
        .padding(.horizontal, Theme.Layout.screenPadding)
        .alert(String(localized: "Reset All Data"), isPresented: $showResetConfirmation) {
            Button(String(localized: "Cancel"), role: .cancel) {}
            Button(String(localized: "Reset"), role: .destructive) {
                performReset()
            }
        } message: {
            Text(String(localized: "This will delete all servers, connection settings and test history. This action cannot be undone."))
        }
    }

    // MARK: - Helpers

    private func settingsToggle(
        icon: String,
        title: String,
        subtitle: String,
        isOn: Binding<Bool>,
        onChange: @escaping (Bool) -> Void
    ) -> some View {
        Toggle(isOn: isOn) {
            HStack(spacing: 10) {
                Image(systemName: icon)
                    .foregroundStyle(Theme.Colors.textSecondary)
                    .frame(width: 24)
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(Theme.Fonts.body)
                        .foregroundStyle(Theme.Colors.textPrimary)
                    Text(subtitle)
                        .font(Theme.Fonts.caption)
                        .foregroundStyle(Theme.Colors.textSecondary)
                }
            }
        }
        .tint(Theme.Colors.primary)
        .onChange(of: isOn.wrappedValue) { _, newValue in
            onChange(newValue)
        }
    }

    private func infoButton(action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: "questionmark.circle")
                .foregroundStyle(Theme.Colors.textSecondary)
                .font(.system(size: 16))
        }
    }

    private func intervalLabel(_ hours: Int) -> String {
        switch hours {
        case 0: return String(localized: "Off")
        case 1: return String(localized: "1 hour")
        case 6: return String(localized: "6 hours")
        case 12: return String(localized: "12 hours")
        case 24: return String(localized: "24 hours")
        case 48: return String(localized: "48 hours")
        default: return "\(hours)h"
        }
    }

    private func performReset() {
        VPNManager.shared.disconnect()
        ServerStore.shared.removeAll()
        TestHistoryStore.shared.clear()
        ConnectionLogStore.shared.clear()
        TrafficStatsStore.shared.resetAll()
        RoutingStore.shared.resetAll()
        SharedDefaults.shared.resetAll()

        // Reset local state
        autoConnect = false
        killSwitch = false
        autoReconnect = true
        aggressiveReconnect = false
        autoPingOnOpen = false
        hapticFeedback = true
        subscriptionInterval = 12
        appTheme = .dark
    }

    private func linkRow(icon: String, title: String, url: String) -> some View {
        Button {
            openURL(url)
        } label: {
            GlassCard {
                HStack {
                    Image(systemName: icon)
                        .foregroundStyle(Theme.Colors.textSecondary)
                        .frame(width: 24)
                    Text(title)
                        .font(Theme.Fonts.body)
                        .foregroundStyle(Theme.Colors.textPrimary)
                    Spacer()
                    Image(systemName: "arrow.up.right")
                        .font(.system(size: 12))
                        .foregroundStyle(Theme.Colors.textSecondary)
                }
            }
        }
    }

    private func openURL(_ urlString: String) {
        guard let url = URL(string: urlString) else { return }
        UIApplication.shared.open(url)
    }
}
