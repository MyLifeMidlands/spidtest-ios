import Foundation

struct SecurityRecommendation: Identifiable {
    let id = UUID()
    let icon: String
    let title: String
    let description: String
    let severity: Severity
    let isResolved: Bool

    enum Severity {
        case critical, warning, info, good

        var color: String {
            switch self {
            case .critical: return "error"
            case .warning: return "warning"
            case .info: return "primary"
            case .good: return "success"
            }
        }
    }

    static func generate(
        vpnConnected: Bool,
        killSwitchEnabled: Bool,
        dnsLeakDetected: Bool,
        webRTCLeakDetected: Bool
    ) -> [SecurityRecommendation] {
        var recs: [SecurityRecommendation] = []

        // VPN
        if vpnConnected {
            recs.append(SecurityRecommendation(
                icon: "shield.checkmark.fill",
                title: String(localized: "VPN is active"),
                description: String(localized: "Your traffic is encrypted and routed through a secure tunnel."),
                severity: .good,
                isResolved: true
            ))
        } else {
            recs.append(SecurityRecommendation(
                icon: "shield.slash",
                title: String(localized: "Connect VPN"),
                description: String(localized: "Your traffic is not encrypted. Connect to a VPN server to protect your privacy."),
                severity: .critical,
                isResolved: false
            ))
        }

        // Kill Switch
        if killSwitchEnabled {
            recs.append(SecurityRecommendation(
                icon: "hand.raised.fill",
                title: String(localized: "Kill Switch is on"),
                description: String(localized: "Traffic will be blocked if VPN connection drops."),
                severity: .good,
                isResolved: true
            ))
        } else {
            recs.append(SecurityRecommendation(
                icon: "hand.raised.slash",
                title: String(localized: "Enable Kill Switch"),
                description: String(localized: "Without Kill Switch, your real IP may be exposed if VPN disconnects unexpectedly."),
                severity: .warning,
                isResolved: false
            ))
        }

        // DNS Leak
        if dnsLeakDetected {
            recs.append(SecurityRecommendation(
                icon: "exclamationmark.shield.fill",
                title: String(localized: "DNS Leak detected"),
                description: String(localized: "Your DNS queries are bypassing the VPN tunnel. Try reconnecting or changing your DNS settings."),
                severity: .critical,
                isResolved: false
            ))
        } else if vpnConnected {
            recs.append(SecurityRecommendation(
                icon: "checkmark.shield.fill",
                title: String(localized: "No DNS Leak"),
                description: String(localized: "Your DNS queries are properly routed through the VPN."),
                severity: .good,
                isResolved: true
            ))
        }

        // WebRTC
        if webRTCLeakDetected {
            recs.append(SecurityRecommendation(
                icon: "video.slash.fill",
                title: String(localized: "WebRTC Leak detected"),
                description: String(localized: "Your real IP address may be visible through WebRTC. Use a browser with WebRTC disabled for maximum privacy."),
                severity: .warning,
                isResolved: false
            ))
        } else if vpnConnected {
            recs.append(SecurityRecommendation(
                icon: "video.fill",
                title: String(localized: "No WebRTC Leak"),
                description: String(localized: "WebRTC is not exposing your real IP address."),
                severity: .good,
                isResolved: true
            ))
        }

        return recs
    }
}
