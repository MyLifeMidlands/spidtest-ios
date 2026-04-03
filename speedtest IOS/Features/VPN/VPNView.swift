import SwiftUI

struct VPNView: View {
    @StateObject private var viewModel = VPNViewModel()
    @ObservedObject private var trafficStore = TrafficStatsStore.shared
    @State private var showSupportOptions = false
    @State private var showRouting = false

    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottomTrailing) {
                ScrollView {
                    VStack(spacing: 32) {
                        // Connection Button
                        connectionButton

                        // Status
                        statusSection

                        // Traffic stats (when connected)
                        if viewModel.state == .connected {
                            trafficSection
                        }

                        // Active Server
                        serverSection

                        // Reconnect info
                        if let info = viewModel.reconnectInfo {
                            HStack(spacing: 8) {
                                ProgressView()
                                    .tint(Theme.Colors.primary)
                                    .scaleEffect(0.8)
                                Text(info)
                                    .font(Theme.Fonts.caption)
                                    .foregroundStyle(Theme.Colors.primary)
                            }
                            .transition(.opacity)
                        }

                        // Error
                        if let error = viewModel.errorMessage {
                            Text(error)
                                .font(Theme.Fonts.caption)
                                .foregroundStyle(Theme.Colors.error)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal)
                        }
                    }
                    .padding(.top, 40)
                    .padding(.horizontal, Theme.Layout.screenPadding)
                    .padding(.bottom, 80)
                }

                // Support button
                supportButton
                    .padding(.trailing, Theme.Layout.screenPadding)
                    .padding(.bottom, 16)
            }
            .background(Theme.Colors.background)
            .navigationTitle(String(localized: "VPN"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        showRouting = true
                    } label: {
                        Image(systemName: "arrow.triangle.branch")
                            .foregroundStyle(Theme.Colors.primary)
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        viewModel.showServerList = true
                    } label: {
                        Image(systemName: "server.rack")
                            .foregroundStyle(Theme.Colors.primary)
                    }
                }
            }
            .sheet(isPresented: $viewModel.showAddServer) {
                AddServerView(viewModel: viewModel)
            }
            .sheet(isPresented: $viewModel.showServerList) {
                ServerListView(serverStore: viewModel.serverStore, viewModel: viewModel)
            }
            .sheet(isPresented: $showRouting) {
                RoutingView()
            }
            .confirmationDialog(String(localized: "Support"), isPresented: $showSupportOptions, titleVisibility: .visible) {
                Button("Telegram") {
                    if let url = URL(string: AppConstants.supportURL) {
                        UIApplication.shared.open(url)
                    }
                }
                Button("Website") {
                    if let url = URL(string: AppConstants.supportWebURL) {
                        UIApplication.shared.open(url)
                    }
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text(String(localized: "How would you like to contact support?"))
            }
            .task {
                await viewModel.setup()
            }
        }
    }

    // MARK: - Connection Button

    private var connectionButton: some View {
        Button {
            Task { await viewModel.toggleConnection() }
        } label: {
            ZStack {
                // Outer ring
                Circle()
                    .stroke(ringColor.opacity(0.2), lineWidth: 4)
                    .frame(width: 200, height: 200)

                // Animated ring
                Circle()
                    .trim(from: 0, to: ringProgress)
                    .stroke(ringColor, style: StrokeStyle(lineWidth: 4, lineCap: .round))
                    .frame(width: 200, height: 200)
                    .rotationEffect(.degrees(-90))
                    .animation(ringAnimation, value: viewModel.state)

                // Inner circle
                Circle()
                    .fill(ringColor.opacity(0.1))
                    .frame(width: 180, height: 180)

                // Power icon
                VStack(spacing: 12) {
                    Image(systemName: powerIcon)
                        .font(.system(size: 48, weight: .light))
                        .foregroundStyle(ringColor)

                    Text(viewModel.state.label)
                        .font(Theme.Fonts.caption)
                        .foregroundStyle(Theme.Colors.textSecondary)
                }
            }
        }
        .buttonStyle(.plain)
        .padding(.top, 20)
    }

    // MARK: - Status Section

    private var statusSection: some View {
        VStack(spacing: 8) {
            if viewModel.state == .connected {
                Text(viewModel.formattedDuration)
                    .font(Theme.Fonts.headlineMedium)
                    .foregroundStyle(Theme.Colors.textPrimary)
                    .monospacedDigit()
            }
        }
    }

    // MARK: - Traffic Section

    private var trafficSection: some View {
        HStack(spacing: 12) {
            trafficTile(
                icon: "arrow.down.circle.fill",
                label: String(localized: "Download"),
                value: TrafficStats.formatBytes(trafficStore.stats.sessionDownload),
                color: Theme.Colors.success
            )
            trafficTile(
                icon: "arrow.up.circle.fill",
                label: String(localized: "Upload"),
                value: TrafficStats.formatBytes(trafficStore.stats.sessionUpload),
                color: Theme.Colors.secondary
            )
        }
    }

    private func trafficTile(icon: String, label: String, value: String, color: Color) -> some View {
        GlassCard {
            VStack(spacing: 6) {
                Image(systemName: icon)
                    .foregroundStyle(color)
                    .font(.system(size: 20))
                Text(value)
                    .font(Theme.Fonts.title)
                    .foregroundStyle(Theme.Colors.textPrimary)
                    .monospacedDigit()
                Text(label)
                    .font(Theme.Fonts.caption)
                    .foregroundStyle(Theme.Colors.textSecondary)
            }
            .frame(maxWidth: .infinity)
        }
    }

    // MARK: - Server Section

    private var serverSection: some View {
        Group {
            if let server = viewModel.serverStore.activeServer {
                GlassCard {
                    HStack {
                        if let flag = server.flagEmoji {
                            Text(flag)
                                .font(.system(size: 32))
                        }

                        VStack(alignment: .leading, spacing: 4) {
                            Text(server.name)
                                .font(Theme.Fonts.title)
                                .foregroundStyle(Theme.Colors.textPrimary)

                            Text(server.displayAddress)
                                .font(Theme.Fonts.caption)
                                .foregroundStyle(Theme.Colors.textSecondary)
                        }

                        Spacer()

                        VStack(alignment: .trailing, spacing: 4) {
                            if let ping = viewModel.loadBalancer.formattedPing(for: server) {
                                Text(ping)
                                    .font(Theme.Fonts.caption)
                                    .foregroundStyle(Theme.Colors.primary)
                            }

                            Text(server.securityLabel)
                                .font(Theme.Fonts.caption)
                                .foregroundStyle(Theme.Colors.textSecondary)
                        }
                    }
                }
                .onTapGesture {
                    viewModel.showServerList = true
                }
            } else {
                VombatButton(title: String(localized: "Add Server"), icon: "plus.circle") {
                    viewModel.showAddServer = true
                }
            }
        }
    }

    // MARK: - Support Button

    private var supportButton: some View {
        Button {
            showSupportOptions = true
        } label: {
            HStack(spacing: 6) {
                Image(systemName: "headset.circle.fill")
                    .font(.system(size: 20))
                Text(String(localized: "Support"))
                    .font(Theme.Fonts.caption)
            }
            .foregroundStyle(Theme.Colors.primary)
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(
                Capsule()
                    .fill(Theme.Colors.primary.opacity(0.15))
            )
        }
    }

    // MARK: - Helpers

    private var ringColor: Color {
        switch viewModel.state {
        case .connected: return Theme.Colors.success
        case .connecting, .disconnecting: return Theme.Colors.primary
        case .disconnected: return Theme.Colors.textSecondary
        case .error: return Theme.Colors.error
        }
    }

    private var ringProgress: CGFloat {
        switch viewModel.state {
        case .connected: return 1.0
        case .connecting, .disconnecting: return 0.75
        case .disconnected: return 0.0
        case .error: return 0.0
        }
    }

    private var ringAnimation: Animation? {
        if viewModel.state.isTransitioning {
            return .linear(duration: 1).repeatForever(autoreverses: false)
        }
        return .easeInOut(duration: 0.5)
    }

    private var powerIcon: String {
        switch viewModel.state {
        case .connected: return "power"
        case .connecting, .disconnecting: return "arrow.triangle.2.circlepath"
        case .disconnected: return "power"
        case .error: return "exclamationmark.triangle"
        }
    }
}
