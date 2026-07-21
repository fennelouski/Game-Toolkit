import SwiftUI

/// Central place for colors, gradients and the player palette so the whole app feels like one system.
enum Theme {
    /// Vibrant, reasonably color-blind-friendly palette assigned to new players in order.
    static let playerPalette: [String] = [
        "#4D96FF", // blue
        "#FF6B6B", // coral
        "#6BCB77", // green
        "#FFD93D", // yellow
        "#B983FF", // purple
        "#FF9F45", // orange
        "#4ECDC4", // teal
        "#F96D80", // pink
        "#3AA0FF", // sky
        "#C0A0FF", // lilac
        "#8AC926", // lime
        "#FF7AA2", // rose
    ]

    /// The die colors offered in the roller and settings.
    static let diceColors: [(name: String, hex: String)] = [
        ("Classic", "#F5F5F7"),
        ("Ruby", "#E63946"),
        ("Sapphire", "#3A86FF"),
        ("Emerald", "#2A9D8F"),
        ("Amber", "#F4A825"),
        ("Amethyst", "#9B5DE5"),
        ("Onyx", "#2B2B2E"),
        ("Rose", "#FF6B9D"),
    ]

    static func nextPlayerColor(existingCount: Int) -> String {
        playerPalette[existingCount % playerPalette.count]
    }

    /// A soft, theme-aware background gradient used behind feature screens.
    static var backgroundGradient: LinearGradient {
        LinearGradient(
            colors: [
                Color(.systemBackground),
                Color.accentColor.opacity(0.08),
                Color(.systemBackground),
            ],
            startPoint: .top,
            endPoint: .bottom
        )
    }
}

extension Int {
    /// `mm:ss` formatting for a whole number of seconds.
    var clockString: String {
        let total = Swift.max(0, self)
        return String(format: "%d:%02d", total / 60, total % 60)
    }
}

extension Double {
    /// `mm:ss` formatting, rounding up so a countdown shows `0:01` until it truly hits zero.
    var clockString: String {
        Int(self.rounded(.up)).clockString
    }
}
