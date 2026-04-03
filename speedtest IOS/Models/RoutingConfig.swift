import Foundation

// MARK: - Routing Mode

enum RoutingMode: String, Codable, CaseIterable {
    case allThroughVPN = "all"
    case allExceptSelected = "bypass"
    case onlySelected = "proxy"

    var label: String {
        switch self {
        case .allThroughVPN: return String(localized: "All through VPN")
        case .allExceptSelected: return String(localized: "All except selected")
        case .onlySelected: return String(localized: "Only selected through VPN")
        }
    }

    var description: String {
        switch self {
        case .allThroughVPN: return String(localized: "Route all traffic through VPN")
        case .allExceptSelected: return String(localized: "VPN for everything, except selected bypass rules")
        case .onlySelected: return String(localized: "Only selected traffic goes through VPN")
        }
    }

    var icon: String {
        switch self {
        case .allThroughVPN: return "shield.fill"
        case .allExceptSelected: return "shield.slash"
        case .onlySelected: return "shield.checkered"
        }
    }
}

// MARK: - Routing Preset

struct RoutingPreset: Identifiable, Codable, Hashable {
    let id: String
    let name: String
    let description: String
    let countries: [String]
    let domains: [String]

    static let ruTrafficDirect = RoutingPreset(
        id: "ru_direct",
        name: String(localized: "Russian traffic direct"),
        description: String(localized: "All traffic through VPN, Russian sites — direct"),
        countries: ["RU"],
        domains: [
            "ru", "рф",
            "yandex.ru", "yandex.com", "ya.ru",
            "vk.com", "vk.me",
            "ok.ru", "odnoklassniki.ru",
            "mail.ru", "list.ru",
            "sberbank.ru", "online.sberbank.ru",
            "tinkoff.ru",
            "gosuslugi.ru",
            "mos.ru",
            "wildberries.ru", "wb.ru",
            "ozon.ru",
            "avito.ru",
            "kinopoisk.ru",
            "ivi.ru",
            "2gis.ru",
            "hh.ru"
        ]
    )

    static let popularServicesVPN = RoutingPreset(
        id: "popular_vpn",
        name: String(localized: "Popular services through VPN"),
        description: String(localized: "YouTube, Telegram, Discord and others — through VPN"),
        countries: [],
        domains: [
            "youtube.com", "googlevideo.com", "ytimg.com", "yt.be",
            "google.com", "googleapis.com", "gstatic.com",
            "instagram.com", "cdninstagram.com",
            "facebook.com", "fbcdn.net", "fb.com",
            "twitter.com", "x.com", "twimg.com",
            "tiktok.com", "tiktokcdn.com",
            "telegram.org", "t.me", "telegram.me",
            "discord.com", "discord.gg", "discordapp.com",
            "netflix.com", "nflxvideo.net",
            "spotify.com", "scdn.co",
            "whatsapp.com", "whatsapp.net",
            "openai.com", "chatgpt.com",
            "linkedin.com",
            "reddit.com",
            "medium.com",
            "notion.so",
            "slack.com",
            "zoom.us",
            "twitch.tv"
        ]
    )


    static let workAndCloudVPN = RoutingPreset(
        id: "work_vpn",
        name: String(localized: "Work & Cloud through VPN"),
        description: String(localized: "Slack, Zoom, GitHub, Google Drive, Microsoft — through VPN"),
        countries: [],
        domains: [
            "slack.com", "slack-edge.com",
            "zoom.us", "zoom.com", "zoomcdn.com",
            "notion.so", "notion.com",
            "github.com", "github.io", "githubusercontent.com",
            "gitlab.com",
            "figma.com",
            "linear.app",
            "atlassian.com", "jira.com", "trello.com",
            "dropbox.com", "dropboxapi.com",
            "drive.google.com", "docs.google.com",
            "microsoft.com", "office.com", "live.com",
            "stackoverflow.com"
        ]
    )

    static let maxPrivacy = RoutingPreset(
        id: "max_privacy",
        name: String(localized: "Maximum privacy"),
        description: String(localized: "All traffic through VPN, no exceptions"),
        countries: [],
        domains: []
    )

    static let allPresets: [RoutingPreset] = [
        ruTrafficDirect,
        popularServicesVPN,
        workAndCloudVPN,
        maxPrivacy
    ]
}

// MARK: - Country for routing

struct RoutingCountry: Identifiable, Codable, Hashable {
    var id: String { code }
    let code: String
    let name: String

    var flagEmoji: String {
        let base: UInt32 = 0x1F1E6
        let aValue = UInt32(UnicodeScalar("A").value)
        let chars = code.uppercased().unicodeScalars.compactMap { scalar -> Character? in
            guard let s = UnicodeScalar(base + scalar.value - aValue) else { return nil }
            return Character(s)
        }
        return chars.count == 2 ? String(chars) : nil ?? code
    }

    static let all: [RoutingCountry] = [
        RoutingCountry(code: "RU", name: String(localized: "Russia")),
        RoutingCountry(code: "UA", name: String(localized: "Ukraine")),
        RoutingCountry(code: "BY", name: String(localized: "Belarus")),
        RoutingCountry(code: "KZ", name: String(localized: "Kazakhstan")),
        RoutingCountry(code: "CN", name: String(localized: "China")),
        RoutingCountry(code: "IR", name: String(localized: "Iran")),
        RoutingCountry(code: "US", name: String(localized: "USA")),
        RoutingCountry(code: "DE", name: String(localized: "Germany")),
        RoutingCountry(code: "FR", name: String(localized: "France")),
        RoutingCountry(code: "GB", name: String(localized: "United Kingdom")),
        RoutingCountry(code: "NL", name: String(localized: "Netherlands")),
        RoutingCountry(code: "PL", name: String(localized: "Poland")),
        RoutingCountry(code: "TR", name: String(localized: "Turkey")),
        RoutingCountry(code: "JP", name: String(localized: "Japan")),
    ]
}

// MARK: - Service for routing

struct RoutingService: Identifiable, Codable, Hashable {
    var id: String { name }
    let name: String
    let icon: String
    let domains: [String]

    static let all: [RoutingService] = [
        RoutingService(name: "YouTube", icon: "play.rectangle.fill", domains: ["youtube.com", "googlevideo.com", "ytimg.com", "yt.be"]),
        RoutingService(name: "Google", icon: "magnifyingglass", domains: ["google.com", "googleapis.com", "gstatic.com"]),
        RoutingService(name: "Instagram", icon: "camera.fill", domains: ["instagram.com", "cdninstagram.com"]),
        RoutingService(name: "Facebook", icon: "person.2.fill", domains: ["facebook.com", "fbcdn.net", "fb.com"]),
        RoutingService(name: "X (Twitter)", icon: "at", domains: ["twitter.com", "x.com", "twimg.com"]),
        RoutingService(name: "TikTok", icon: "music.note", domains: ["tiktok.com", "tiktokcdn.com"]),
        RoutingService(name: "Telegram", icon: "paperplane.fill", domains: ["telegram.org", "t.me", "telegram.me"]),
        RoutingService(name: "Netflix", icon: "tv.fill", domains: ["netflix.com", "nflxvideo.net"]),
        RoutingService(name: "Spotify", icon: "music.note.list", domains: ["spotify.com", "scdn.co"]),
        RoutingService(name: "Discord", icon: "bubble.left.and.bubble.right.fill", domains: ["discord.com", "discord.gg", "discordapp.com"]),
        RoutingService(name: "WhatsApp", icon: "phone.fill", domains: ["whatsapp.com", "whatsapp.net"]),
        RoutingService(name: "OpenAI / ChatGPT", icon: "brain.head.profile.fill", domains: ["openai.com", "chatgpt.com"]),
        RoutingService(name: "Cloudflare", icon: "cloud.fill", domains: ["cloudflare.com", "cloudflareinsights.com"]),
        RoutingService(name: "Amazon / AWS", icon: "shippingbox.fill", domains: ["amazon.com", "amazonaws.com", "aws.amazon.com"]),
    ]
}

// MARK: - Routing Configuration

struct RoutingConfiguration: Codable {
    var mode: RoutingMode = .allThroughVPN
    var selectedPresetID: String?
    var selectedCountryCodes: Set<String> = []
    var selectedServiceNames: Set<String> = []
    var customDomains: [String] = []

    var allBypassDomains: [String] {
        var domains: [String] = []

        // From selected services (includes services auto-selected by preset)
        for serviceName in selectedServiceNames {
            if let service = RoutingService.all.first(where: { $0.name == serviceName }) {
                domains.append(contentsOf: service.domains)
            }
        }

        // Preset-specific domains not covered by services (e.g. yandex.ru, gosuslugi.ru)
        if let presetID = selectedPresetID,
           let preset = RoutingPreset.allPresets.first(where: { $0.id == presetID }) {
            domains.append(contentsOf: preset.domains)
        }

        // Custom domains
        domains.append(contentsOf: customDomains)

        return Array(Set(domains))
    }

    var allSelectedCountryCodes: [String] {
        var codes = Array(selectedCountryCodes)

        if let presetID = selectedPresetID,
           let preset = RoutingPreset.allPresets.first(where: { $0.id == presetID }) {
            codes.append(contentsOf: preset.countries)
        }

        return Array(Set(codes))
    }
}
