import SwiftUI

/// String keys shared by `@AppStorage` and `UserDefaults` reads across the app.
enum SettingsKey {
    static let diceCount = "settings.diceCount"
    static let diceSides = "settings.diceSides"
    static let diceShowTotal = "settings.diceShowTotal"
    static let diceColorHex = "settings.diceColorHex"

    static let secondsPerPlayer = "settings.secondsPerPlayer"
    static let alarmEnabled = "settings.alarmEnabled"
    static let alarmDuration = "settings.alarmDuration"

    static let hapticsEnabled = "settings.hapticsEnabled"
    static let soundEnabled = "settings.soundEnabled"
    static let appearance = "settings.appearance"
    static let selectedTab = "ui.selectedTab"
}

/// Preferred color scheme, persisted as a plain string.
enum AppearanceMode: String, CaseIterable, Identifiable {
    case system, light, dark
    var id: String { rawValue }

    var label: String {
        switch self {
        case .system: return "System"
        case .light: return "Light"
        case .dark: return "Dark"
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
