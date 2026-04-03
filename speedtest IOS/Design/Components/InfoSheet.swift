import SwiftUI

struct InfoSheet: View {
    let title: String
    let sections: [InfoSection]
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    ForEach(sections) { section in
                        VStack(alignment: .leading, spacing: 8) {
                            if let icon = section.icon {
                                Label(section.title, systemImage: icon)
                                    .font(Theme.Fonts.title)
                                    .foregroundStyle(Theme.Colors.primary)
                            } else {
                                Text(section.title)
                                    .font(Theme.Fonts.title)
                                    .foregroundStyle(Theme.Colors.textPrimary)
                            }

                            Text(section.body)
                                .font(Theme.Fonts.body)
                                .foregroundStyle(Theme.Colors.textSecondary)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                }
                .padding(Theme.Layout.screenPadding)
            }
            .background(Theme.Colors.background)
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(Theme.Colors.textSecondary)
                    }
                }
            }
        }
        .presentationDetents([.medium, .large])
    }
}

struct InfoSection: Identifiable {
    let id = UUID()
    let title: String
    let icon: String?
    let body: String

    init(title: String, icon: String? = nil, body: String) {
        self.title = title
        self.icon = icon
        self.body = body
    }
}

// MARK: - Predefined Info Sheets

enum HelpTopics {

    static let splitTunneling = [
        InfoSection(
            title: String(localized: "What is Split Tunneling?"),
            icon: "arrow.triangle.branch",
            body: String(localized: "Split tunneling lets you choose which traffic goes through the VPN and which connects directly. This can improve speed for local services while keeping sensitive traffic encrypted.")
        ),
        InfoSection(
            title: String(localized: "All through VPN"),
            icon: "shield.fill",
            body: String(localized: "Maximum security. All your internet traffic is routed through the VPN server. Your real IP is hidden from every website and service.")
        ),
        InfoSection(
            title: String(localized: "All except selected"),
            icon: "shield.slash",
            body: String(localized: "Everything goes through VPN except the domains and countries you choose. Useful when local banking or government sites block VPN connections.")
        ),
        InfoSection(
            title: String(localized: "Only selected through VPN"),
            icon: "shield.checkered",
            body: String(localized: "Only specified domains and services go through VPN. Everything else connects directly. Best for accessing specific blocked content while keeping maximum speed for everything else.")
        ),
    ]

    static let killSwitch = [
        InfoSection(
            title: String(localized: "What is Kill Switch?"),
            icon: "hand.raised.fill",
            body: String(localized: "Kill Switch blocks all internet traffic if the VPN connection drops unexpectedly. This prevents your real IP address and unencrypted data from being exposed, even for a moment.")
        ),
        InfoSection(
            title: String(localized: "When to use it"),
            icon: "checkmark.shield",
            body: String(localized: "Enable Kill Switch when privacy is critical — for example, when using public Wi-Fi, accessing sensitive accounts, or in countries with internet censorship.")
        ),
        InfoSection(
            title: String(localized: "How it works"),
            icon: "gearshape",
            body: String(localized: "The system blocks all network traffic outside the VPN tunnel using iOS 'includeAllNetworks' feature. Local network access (printers, AirDrop) remains available.")
        ),
    ]

    static let webRTCLeak = [
        InfoSection(
            title: String(localized: "What is a WebRTC Leak?"),
            icon: "video.slash.fill",
            body: String(localized: "WebRTC (Web Real-Time Communication) is a browser technology used for video calls and peer-to-peer connections. It can sometimes reveal your real IP address even when connected to a VPN.")
        ),
        InfoSection(
            title: String(localized: "Am I affected?"),
            icon: "questionmark.circle",
            body: String(localized: "WebRTC leaks primarily affect web browsers (Safari, Chrome). Native iOS apps like VPNeo are not affected. However, if you use a browser while connected to VPN, your real IP might be exposed through WebRTC.")
        ),
        InfoSection(
            title: String(localized: "How to prevent"),
            icon: "shield.checkmark.fill",
            body: String(localized: "Use browsers with WebRTC disabled, or install browser extensions that block WebRTC. On iOS, Safari has limited WebRTC support, which reduces the risk.")
        ),
    ]

    static let dnsLeak = [
        InfoSection(
            title: String(localized: "What is a DNS Leak?"),
            icon: "exclamationmark.shield.fill",
            body: String(localized: "A DNS leak occurs when your DNS queries bypass the VPN tunnel and go directly to your ISP's DNS servers. This can expose which websites you visit, even though your other traffic is encrypted.")
        ),
        InfoSection(
            title: String(localized: "Why is it dangerous?"),
            icon: "eye.slash",
            body: String(localized: "Even if your traffic is encrypted through VPN, DNS leaks let your ISP (and potentially governments) see every domain you visit. This defeats the privacy purpose of using a VPN.")
        ),
        InfoSection(
            title: String(localized: "How VPNeo protects you"),
            icon: "shield.checkmark.fill",
            body: String(localized: "VPNeo routes all DNS queries through the VPN tunnel using secure DNS servers (1.1.1.1, 8.8.8.8). The Kill Switch feature adds extra protection by blocking traffic outside the tunnel.")
        ),
    ]

    static let securityScore = [
        InfoSection(
            title: String(localized: "Security Score"),
            icon: "shield.lefthalf.filled",
            body: String(localized: "Your security score is calculated based on several checks: VPN connection, Kill Switch status, DNS leak test results, and WebRTC leak test results. A higher score means better privacy protection.")
        ),
        InfoSection(
            title: String(localized: "How to improve"),
            icon: "arrow.up.circle",
            body: String(localized: "Connect to VPN, enable Kill Switch, and ensure no DNS or WebRTC leaks are detected. Following all recommendations will give you a 100% security score.")
        ),
    ]

    static let autoReconnect = [
        InfoSection(
            title: String(localized: "Auto-Reconnect"),
            icon: "arrow.counterclockwise",
            body: String(localized: "When enabled, VPNeo will automatically try to reconnect if the VPN connection drops unexpectedly. It makes up to 3 attempts with increasing delays between tries.")
        ),
        InfoSection(
            title: String(localized: "Aggressive Reconnect"),
            icon: "bolt.horizontal.fill",
            body: String(localized: "Aggressive mode uses shorter delays between reconnection attempts (1-2-3 seconds instead of 3-6-9 seconds). Use this on unstable networks where connections drop frequently.")
        ),
    ]

    static let loadBalancing = [
        InfoSection(
            title: String(localized: "Load Balancing"),
            icon: "scale.3d",
            body: String(localized: "Load balancing determines how VPNeo selects which server to connect to when you have multiple servers configured.")
        ),
        InfoSection(
            title: String(localized: "Manual"),
            icon: "hand.tap",
            body: String(localized: "You manually select which server to use. The app connects to your chosen server every time.")
        ),
        InfoSection(
            title: String(localized: "Best Ping"),
            icon: "bolt.fill",
            body: String(localized: "Automatically measures latency to all servers and connects to the fastest one. Best for optimal speed.")
        ),
        InfoSection(
            title: String(localized: "Round Robin"),
            icon: "arrow.triangle.2.circlepath",
            body: String(localized: "Rotates through servers on each connection. Distributes load evenly across your server list.")
        ),
        InfoSection(
            title: String(localized: "Failover"),
            icon: "arrow.trianglehead.branch",
            body: String(localized: "If the current server fails, automatically switches to the next available server. Up to 3 failover attempts before giving up.")
        ),
    ]
}
