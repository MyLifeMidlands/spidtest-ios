import SwiftUI

enum Theme {
    // MARK: - Colors
    enum Colors {
        // Adaptive background colors
        static let background = Color("background", bundle: nil)
        static let surface = Color("surface", bundle: nil)
        static let surfaceLight = Color("surfaceLight", bundle: nil)

        // Brand colors (same in both themes)
        static let primary = Color(hex: "00D4AA")
        static let primaryDark = Color(hex: "00A886")
        static let secondary = Color(hex: "6C63FF")

        // Adaptive text colors
        static let textPrimary = Color("textPrimary", bundle: nil)
        static let textSecondary = Color("textSecondary", bundle: nil)

        // Status colors (same in both themes)
        static let success = Color(hex: "00E676")
        static let warning = Color(hex: "FFB74D")
        static let error = Color(hex: "FF5252")

        static let gaugeGradient = LinearGradient(
            colors: [primary, Color(hex: "FFB74D"), error],
            startPoint: .leading,
            endPoint: .trailing
        )
    }

    // MARK: - Fonts
    enum Fonts {
        static let headlineLarge = Font.system(size: 34, weight: .bold, design: .rounded)
        static let headlineMedium = Font.system(size: 28, weight: .bold, design: .rounded)
        static let title = Font.system(size: 20, weight: .semibold)
        static let body = Font.system(size: 16, weight: .regular)
        static let caption = Font.system(size: 13, weight: .medium)
        static let speedValue = Font.system(size: 64, weight: .bold, design: .rounded)
        static let speedUnit = Font.system(size: 16, weight: .medium, design: .rounded)
        static let metric = Font.system(size: 24, weight: .semibold, design: .rounded)
    }

    // MARK: - Layout
    enum Layout {
        static let cornerRadius: CGFloat = 16
        static let cardPadding: CGFloat = 16
        static let screenPadding: CGFloat = 20
        static let spacing: CGFloat = 12
    }
}
