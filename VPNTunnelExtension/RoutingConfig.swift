import Foundation

enum RoutingMode: String, Codable {
    case allThroughVPN = "all"
    case allExceptSelected = "bypass"
    case onlySelected = "proxy"
}

struct RoutingConfiguration: Codable {
    var mode: RoutingMode = .allThroughVPN
    var selectedPresetID: String?
    var selectedCountryCodes: Set<String> = []
    var selectedServiceNames: Set<String> = []
    var customDomains: [String] = []

    var allBypassDomains: [String] {
        var domains: [String] = []

        if let presetID = selectedPresetID {
            if let preset = knownPresets[presetID] {
                domains.append(contentsOf: preset)
            }
        }

        for serviceName in selectedServiceNames {
            if let serviceDomains = knownServices[serviceName] {
                domains.append(contentsOf: serviceDomains)
            }
        }

        domains.append(contentsOf: customDomains)
        return Array(Set(domains))
    }

    var allSelectedCountryCodes: [String] {
        var codes = Array(selectedCountryCodes)
        if selectedPresetID == "ru_direct" {
            codes.append("RU")
        }
        return Array(Set(codes))
    }

    // Minimal preset data for tunnel extension
    private var knownPresets: [String: [String]] {
        [
            "ru_direct": [
                "ru", "рф", "yandex.ru", "yandex.com", "ya.ru",
                "vk.com", "vk.me", "ok.ru", "mail.ru",
                "sberbank.ru", "tinkoff.ru", "gosuslugi.ru",
                "wildberries.ru", "ozon.ru", "avito.ru"
            ],
            "popular_vpn": [
                "youtube.com", "googlevideo.com", "google.com",
                "instagram.com", "facebook.com", "twitter.com", "x.com",
                "tiktok.com", "telegram.org", "t.me",
                "discord.com", "netflix.com", "spotify.com",
                "whatsapp.com", "openai.com", "chatgpt.com"
            ],
            "work_vpn": [
                "slack.com", "zoom.us", "zoom.com",
                "notion.so", "notion.com",
                "github.com", "githubusercontent.com",
                "gitlab.com", "figma.com", "linear.app",
                "atlassian.com", "jira.com", "trello.com",
                "dropbox.com", "drive.google.com",
                "microsoft.com", "office.com",
                "stackoverflow.com"
            ],
            "max_privacy": []
        ]
    }

    private var knownServices: [String: [String]] {
        [
            "YouTube": ["youtube.com", "googlevideo.com", "ytimg.com"],
            "Google": ["google.com", "googleapis.com", "gstatic.com"],
            "Instagram": ["instagram.com", "cdninstagram.com"],
            "Facebook": ["facebook.com", "fbcdn.net", "fb.com"],
            "X (Twitter)": ["twitter.com", "x.com", "twimg.com"],
            "TikTok": ["tiktok.com", "tiktokcdn.com"],
            "Telegram": ["telegram.org", "t.me", "telegram.me"],
            "Netflix": ["netflix.com", "nflxvideo.net"],
            "Spotify": ["spotify.com", "scdn.co"],
            "Discord": ["discord.com", "discord.gg", "discordapp.com"],
            "WhatsApp": ["whatsapp.com", "whatsapp.net"],
            "OpenAI / ChatGPT": ["openai.com", "chatgpt.com"],
            "Cloudflare": ["cloudflare.com", "cloudflareinsights.com"],
            "Amazon / AWS": ["amazon.com", "amazonaws.com"],
        ]
    }
}
