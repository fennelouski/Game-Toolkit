import SwiftUI

/// String keys shared by `@AppStorage` and `UserDefaults` reads across the app.
enum SettingsKey {
    static let diceCount = "settings.diceCount"
    static let diceSides = "settings.diceSides"
    static let diceShowTotal = "settings.diceShowTotal"
    static let diceColorHex = "settings.diceColorHex"
    static let diceDotSize = "settings.diceDotSize"

    static let secondsPerPlayer = "settings.secondsPerPlayer"
    /// Legacy: replaced by the `.sound` bit of `timerEndActions`. Read only by the migration.
    static let alarmEnabled = "settings.alarmEnabled"
    static let alarmDuration = "settings.alarmDuration"

    static let timerMode = "timer.mode"
    static let timerScope = "timer.scope"
    static let timerTapBehavior = "timer.tapBehavior"
    static let timerColorPulseTarget = "timer.colorPulseTarget"
    static let timerCountdownSeconds = "timer.countdownSeconds"
    static let timerAutoSwitchSeconds = "timer.autoSwitchSeconds"
    /// `TimerEndActions.rawValue`; what happens when a timer runs out.
    static let timerEndActions = "timer.endActions"
    /// `TimerEndActions.rawValue`; effects on each auto-switch turn change.
    static let timerSwitchActions = "timer.switchActions"
    static let timerHapticIntensity = "timer.hapticIntensity"
    static let timerSoundID = "timer.soundID"
    /// Seconds after a timer stops before it resets itself. Negative = off.
    static let timerAutoResetDelay = "timer.autoResetDelay"
    static let timerSystemAlarm = "timer.systemAlarm"
    static let timerLiveActivity = "timer.liveActivity"
    static let timerStyleID = "timer.styleID"

    static let hapticsEnabled = "settings.hapticsEnabled"
    static let soundEnabled = "settings.soundEnabled"
    static let appearance = "settings.appearance"
    static let selectedTab = "ui.selectedTab"
    static let piDayEnabled = "settings.piDayEnabled"
    /// Also settable as the launch argument `-ui.theme <id>` for reproducible screenshots.
    static let themeID = "ui.theme"
    static let onboardingCompleted = "onboarding.completed"
    /// Show the big scoreboard on AirPlay/HDMI screens instead of mirroring. Default true.
    static let externalScoreboard = "settings.externalScoreboard"
    /// `PlayerGroup.groupID` of the game night in play; "" is the built-in table.
    /// Per-device on purpose: two phones can run different game nights off one iCloud store.
    static let activeGroupID = "roster.activeGroupID"
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
