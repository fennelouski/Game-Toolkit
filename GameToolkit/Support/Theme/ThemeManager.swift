import SwiftUI

/// Selects and persists the active theme, and resolves it to a palette for the current
/// appearance. Built-in themes are always available; fetched game themes join
/// `availableThemes` once the theme service lands, but the app never depends on them.
@MainActor
@Observable
final class ThemeManager {
    static let shared = ThemeManager()

    /// Every theme the picker can offer right now (built-ins plus any cached game themes).
    private(set) var availableThemes: [AppTheme]

    @ObservationIgnored private let defaults: UserDefaults

    var selectedThemeID: String {
        didSet {
            guard oldValue != selectedThemeID else { return }
            defaults.set(selectedThemeID, forKey: SettingsKey.themeID)
        }
    }

    /// The active theme; falls back to the default if the stored id no longer resolves.
    var current: AppTheme {
        availableThemes.first { $0.id == selectedThemeID } ?? BuiltInThemes.defaultTheme
    }

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        availableThemes = BuiltInThemes.all
        // `-ui.theme <id>` (used by the screenshot script) lands in UserDefaults' argument
        // domain under the same key, so a plain read honors both the stored choice and the
        // launch-argument override.
        selectedThemeID = defaults.string(forKey: SettingsKey.themeID)
            ?? BuiltInThemes.defaultTheme.id
    }

    func select(_ theme: AppTheme) {
        selectedThemeID = theme.id
    }

    /// Registers a fetched game theme so it can be selected; replaces any earlier copy.
    func register(_ theme: AppTheme) {
        guard theme.isSupported else { return }
        availableThemes.removeAll { $0.id == theme.id }
        availableThemes.append(theme)
    }
}

extension EnvironmentValues {
    /// The resolved palette for the current theme and appearance. Views read semantic
    /// roles from this instead of literal colors.
    @Entry var palette: ThemePalette = BuiltInThemes.defaultTheme.light
}
