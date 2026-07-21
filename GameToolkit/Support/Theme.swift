import SwiftUI

/// Legacy color lists kept for migration and the die-color picker. The semantic theme
/// system lives in `Support/Theme/` (`ThemeModels`, `BuiltInThemes`, `ThemeManager`).
enum Theme {
    /// The player palette shipped in 2.0, before themes existed. Players created back then
    /// stored one of these hexes; `Roster.adoptPaletteIndices` maps them onto theme palette
    /// ordinals so the roster recolors when the theme changes.
    static let legacyPlayerPalette: [String] = [
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

    /// The die colors offered in the roller and settings, alongside the theme default.
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

    /// Sentinel stored in the die-color setting meaning "follow the current theme".
    static let themeDiceColor = "theme"
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
