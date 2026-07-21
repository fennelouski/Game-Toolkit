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
    /// Mirrors the choice through iCloud so game night looks the same on every device.
    /// `nil` in tests, where the shared key-value store must stay untouched.
    @ObservationIgnored private let cloudStore: NSUbiquitousKeyValueStore?

    var selectedThemeID: String {
        didSet {
            guard oldValue != selectedThemeID else { return }
            defaults.set(selectedThemeID, forKey: SettingsKey.themeID)
            if cloudStore?.string(forKey: SettingsKey.themeID) != selectedThemeID {
                cloudStore?.set(selectedThemeID, forKey: SettingsKey.themeID)
            }
        }
    }

    /// The active theme; falls back to the default if the stored id no longer resolves.
    var current: AppTheme {
        availableThemes.first { $0.id == selectedThemeID } ?? BuiltInThemes.defaultTheme
    }

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        let isShared = defaults === UserDefaults.standard
        self.cloudStore = isShared ? .default : nil
        availableThemes = BuiltInThemes.all
        // `-ui.theme <id>` (used by the screenshot script) lands in UserDefaults' argument
        // domain under the same key, so a plain read honors both the stored choice and the
        // launch-argument override. A choice made on another device wins over an old local
        // one, but never over an explicit launch argument.
        let launchOrLocal = defaults.string(forKey: SettingsKey.themeID)
        let cloud = cloudStore?.string(forKey: SettingsKey.themeID)
        selectedThemeID = launchOrLocal ?? cloud ?? BuiltInThemes.defaultTheme.id

        if let cloudStore {
            NotificationCenter.default.addObserver(
                forName: NSUbiquitousKeyValueStore.didChangeExternallyNotification,
                object: cloudStore, queue: .main
            ) { [weak self] _ in
                MainActor.assumeIsolated {
                    let store = NSUbiquitousKeyValueStore.default
                    guard let self, let remote = store.string(forKey: SettingsKey.themeID) else { return }
                    self.selectedThemeID = remote
                    // The other device may have picked a game theme we haven't registered yet.
                    GameThemeService.shared.restoreSelectedThemeIfNeeded(in: self)
                }
            }
            cloudStore.synchronize()
        }
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
