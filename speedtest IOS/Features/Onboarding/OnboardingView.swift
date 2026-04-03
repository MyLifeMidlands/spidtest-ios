import SwiftUI

struct OnboardingView: View {
    @Binding var isCompleted: Bool
    @State private var currentPage = 0

    private let pages: [OnboardingPage] = [
        OnboardingPage(
            icon: "shield.checkered",
            title: String(localized: "Secure Connection"),
            description: String(localized: "Protect your internet traffic with military-grade encryption. Your data stays private on any network."),
            color: .green
        ),
        OnboardingPage(
            icon: "bolt.horizontal.fill",
            title: String(localized: "Lightning Fast"),
            description: String(localized: "VLESS+Reality protocol ensures maximum speed with minimum overhead. No throttling, no limits."),
            color: .blue
        ),
        OnboardingPage(
            icon: "gauge.open.with.lines.needle.33percent.and.arrowtriangle",
            title: String(localized: "Speed Test & DNS Check"),
            description: String(localized: "Built-in speed test and DNS leak detection. Always know your connection quality."),
            color: .purple
        ),
        OnboardingPage(
            icon: "arrow.triangle.branch",
            title: String(localized: "Smart Routing"),
            description: String(localized: "Split tunneling lets you choose which apps and sites go through VPN. Flexible traffic rules for any scenario."),
            color: .orange
        ),
    ]

    var body: some View {
        ZStack {
            Theme.Colors.background.ignoresSafeArea()

            VStack(spacing: 0) {
                // Pages
                TabView(selection: $currentPage) {
                    ForEach(Array(pages.enumerated()), id: \.offset) { index, page in
                        pageView(page)
                            .tag(index)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))

                // Bottom
                VStack(spacing: 20) {
                    // Dots
                    HStack(spacing: 8) {
                        ForEach(0..<pages.count, id: \.self) { index in
                            Circle()
                                .fill(index == currentPage ? Theme.Colors.primary : Theme.Colors.textSecondary.opacity(0.3))
                                .frame(width: index == currentPage ? 10 : 6, height: index == currentPage ? 10 : 6)
                                .animation(.easeInOut(duration: 0.2), value: currentPage)
                        }
                    }

                    // Button
                    Button {
                        if currentPage < pages.count - 1 {
                            withAnimation {
                                currentPage += 1
                            }
                        } else {
                            completeOnboarding()
                        }
                    } label: {
                        Text(currentPage < pages.count - 1 ? String(localized: "Next") : String(localized: "Get Started"))
                            .font(Theme.Fonts.title)
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(
                                RoundedRectangle(cornerRadius: Theme.Layout.cornerRadius)
                                    .fill(Theme.Colors.primary)
                            )
                    }
                    .padding(.horizontal, Theme.Layout.screenPadding)

                    // Skip
                    if currentPage < pages.count - 1 {
                        Button {
                            completeOnboarding()
                        } label: {
                            Text(String(localized: "Skip"))
                                .font(Theme.Fonts.caption)
                                .foregroundStyle(Theme.Colors.textSecondary)
                        }
                    }
                }
                .padding(.bottom, 40)
            }
        }
    }

    private func pageView(_ page: OnboardingPage) -> some View {
        VStack(spacing: 32) {
            Spacer()

            // Icon
            ZStack {
                Circle()
                    .fill(page.color.opacity(0.15))
                    .frame(width: 140, height: 140)

                Circle()
                    .fill(page.color.opacity(0.08))
                    .frame(width: 180, height: 180)

                Image(systemName: page.icon)
                    .font(.system(size: 56, weight: .light))
                    .foregroundStyle(page.color)
            }

            VStack(spacing: 12) {
                Text(page.title)
                    .font(.system(size: 28, weight: .bold))
                    .foregroundStyle(Theme.Colors.textPrimary)
                    .multilineTextAlignment(.center)

                Text(page.description)
                    .font(Theme.Fonts.body)
                    .foregroundStyle(Theme.Colors.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }

            Spacer()
            Spacer()
        }
    }

    private func completeOnboarding() {
        withAnimation {
            UserDefaults.standard.set(true, forKey: "onboarding_completed")
            isCompleted = true
        }
    }
}

private struct OnboardingPage {
    let icon: String
    let title: String
    let description: String
    let color: Color
}
