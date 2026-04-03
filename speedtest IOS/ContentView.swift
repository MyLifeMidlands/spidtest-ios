import SwiftUI

struct ContentView: View {
    @State private var selectedTab = 0
    @State private var onboardingCompleted = UserDefaults.standard.bool(forKey: "onboarding_completed")
    @AppStorage("app_theme") private var appTheme: AppTheme = .dark

    var body: some View {
        Group {
            if !onboardingCompleted {
                OnboardingView(isCompleted: $onboardingCompleted)
            } else {
                TabView(selection: $selectedTab) {
                    VPNView()
                        .tabItem {
                            Image(systemName: "shield.fill")
                            Text(String(localized: "VPN"))
                        }
                        .tag(0)

                    SpeedTestView()
                        .tabItem {
                            Image(systemName: "gauge.open.with.lines.needle.33percent.and.arrowtriangle")
                            Text(String(localized: "Speed"))
                        }
                        .tag(1)

                    DNSLeakTestView()
                        .tabItem {
                            Image(systemName: "network.badge.shield.half.filled")
                            Text(String(localized: "DNS Test"))
                        }
                        .tag(2)

                    SettingsView()
                        .tabItem {
                            Image(systemName: "gearshape")
                            Text(String(localized: "Settings"))
                        }
                        .tag(3)
                }
                .tint(Theme.Colors.primary)
            }
        }
        .preferredColorScheme(appTheme.colorScheme)
    }
}

enum AppTheme: String, CaseIterable {
    case system
    case light
    case dark

    var label: String {
        switch self {
        case .system: return String(localized: "System")
        case .light: return String(localized: "Light")
        case .dark: return String(localized: "Dark")
        }
    }

    var colorScheme: ColorScheme? {
        switch self {
        case .system: return nil
        case .light: return .light
        case .dark: return .dark
        }
    }
}

enum AppLanguage: String, CaseIterable {
    case system
    case en
    case ru

    var label: String {
        switch self {
        case .system: return String(localized: "System")
        case .en: return "English"
        case .ru: return "Русский"
        }
    }

    func apply() {
        if self == .system {
            UserDefaults.standard.removeObject(forKey: "AppleLanguages")
        } else {
            UserDefaults.standard.set([self.rawValue], forKey: "AppleLanguages")
        }
    }
}

#Preview {
    ContentView()
}
