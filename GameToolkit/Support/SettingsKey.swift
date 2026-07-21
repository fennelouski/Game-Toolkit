import SwiftUI

/// String keys shared by `@AppStorage` and `UserDefaults` reads across the app.
enum SettingsKey {
    static let diceCount = "settings.diceCount"
    static let diceSides = "settings.diceSides"
    static let diceShowTotal = "settings.diceShowTotal"
    static let diceColorHex = "settings.diceColorHex"
    static let diceDotSize = "settings.diceDotSize"

    static let secondsPerPlayer = "settings.secondsPerPlayer"
    static let alarmEnabled = "settings.alarmEnabled"
    static let alarmDuration = "settings.alarmDuration"

    static let hapticsEnabled = "settings.hapticsEnabled"
    static let soundEnabled = "settings.soundEnabled"
    static let appearance = "settings.appearance"
    static let selectedTab = "ui.selectedTab"
    static let piDayEnabled = "settings.piDayEnabled"
}

/// The original app replaced every "P" with "π" on 14 March. Kept as an opt-out easter egg.
enum PiDay {
    static var isToday: Bool {
        let components = Calendar.current.dateComponents([.month, .day], from: .now)
        return components.month == 3 && components.day == 14
    }

    /// Applies the π substitution when it's Pi Day and the user hasn't turned it off.
    static func decorate(_ text: String) -> String {
        guard isToday, UserDefaults.standard.object(forKey: SettingsKey.piDayEnabled) as? Bool ?? true else {
            return text
        }
        return text.replacingOccurrences(of: "P", with: "π")
                   .replacingOccurrences(of: "p", with: "π")
    }
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
