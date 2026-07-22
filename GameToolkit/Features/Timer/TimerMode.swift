import Foundation

/// How the timer counts and hands turns between players.
enum TimerMode: String, CaseIterable, Identifiable {
    /// Each player has a running budget; tapping a player starts their clock and stops
    /// everyone else's. The original behavior.
    case chessClock
    /// Counts down from a fixed duration, either one shared timer or one per player.
    case countdown
    /// Counts up from zero, either one shared timer or one per player. Never expires.
    case countUp
    /// Every turn has the same length; when it runs out the clock automatically moves to
    /// the next player. For fast-paced games.
    case autoSwitch

    var id: String { rawValue }

    var label: String {
        switch self {
        case .chessClock: return "Chess Clock"
        case .countdown: return "Countdown"
        case .countUp: return "Count Up"
        case .autoSwitch: return "Auto-Switch"
        }
    }

    var symbolName: String {
        switch self {
        case .chessClock: return "checkerboard.rectangle"
        case .countdown: return "timer"
        case .countUp: return "stopwatch"
        case .autoSwitch: return "arrow.triangle.2.circlepath"
        }
    }

    /// Whether the mode supports choosing between one shared timer and per-player timers.
    var supportsScope: Bool { self == .countdown || self == .countUp }

    /// Whether timers in this mode run toward a known end.
    var isFixedLength: Bool { self != .countUp }
}

/// One shared timer or one timer per player. Only meaningful for countdown/count-up;
/// chess clock and auto-switch are inherently per-player.
enum TimerScope: String, CaseIterable, Identifiable {
    case single, perPlayer
    var id: String { rawValue }

    var label: String {
        switch self {
        case .single: return "One Timer"
        case .perPlayer: return "Per Player or Team"
        }
    }
}

/// What tapping the currently running timer does in multi-timer modes.
enum TapBehavior: String, CaseIterable, Identifiable {
    case pause, nextPlayer
    var id: String { rawValue }

    var label: String {
        switch self {
        case .pause: return "Pauses"
        case .nextPlayer: return "Next Player"
        }
    }
}

/// Whose color the momentary full-screen pulse uses when a timer ends.
enum ColorPulseTarget: String, CaseIterable, Identifiable {
    case expiredPlayer, nextPlayer
    var id: String { rawValue }

    var label: String {
        switch self {
        case .expiredPlayer: return "Player Whose Time Ended"
        case .nextPlayer: return "Next Player"
        }
    }
}

/// Effects that can fire when a timer ends (or, as `switchActions`, on each auto-switch).
/// Stored in `UserDefaults` as the raw `Int`.
struct TimerEndActions: OptionSet {
    let rawValue: Int

    static let flashScreen = TimerEndActions(rawValue: 1 << 0)
    static let colorPulse  = TimerEndActions(rawValue: 1 << 1)
    static let haptics     = TimerEndActions(rawValue: 1 << 2)
    static let flashlight  = TimerEndActions(rawValue: 1 << 3)
    static let sound       = TimerEndActions(rawValue: 1 << 4)
    static let systemAlarm = TimerEndActions(rawValue: 1 << 5)
}

/// A snapshot of everything the engine needs to run, assembled by the view from
/// `@AppStorage`. Keeps the engine free of `UserDefaults` reads so tests can drive it
/// directly.
struct TimerConfiguration: Equatable {
    var mode: TimerMode = .chessClock
    var scope: TimerScope = .perPlayer
    var tapBehavior: TapBehavior = .pause
    /// Chess-clock budget per player (the long-standing `settings.secondsPerPlayer`).
    var chessSeconds: Double = 90
    var countdownSeconds: Double = 300
    var autoSwitchSeconds: Double = 30
    /// Seconds to wait after a timer stops before resetting it. Negative means never.
    var autoResetDelay: Double = -1

    /// Whether the configuration produces one shared slot rather than one per player.
    var usesSharedSlot: Bool { mode.supportsScope && scope == .single }

    /// The full budget a slot starts with, or `nil` for count-up (no limit).
    var slotBudget: Double? {
        switch mode {
        case .chessClock: return chessSeconds
        case .countdown: return countdownSeconds
        case .countUp: return nil
        case .autoSwitch: return autoSwitchSeconds
        }
    }
}

/// One-time migrations for timer settings.
enum TimerSettings {
    /// Seeds `timer.endActions` from the legacy `settings.alarmEnabled` toggle, which was
    /// stored but never consulted. From now on the sound-on-expiry decision flows through
    /// the end-actions option set, which *is* honored.
    static func migrateIfNeeded() {
        let defaults = UserDefaults.standard
        guard defaults.object(forKey: SettingsKey.timerEndActions) == nil else { return }
        var actions: TimerEndActions = [.haptics]
        let legacyAlarm = defaults.object(forKey: SettingsKey.alarmEnabled) as? Bool ?? true
        if legacyAlarm { actions.insert(.sound) }
        defaults.set(actions.rawValue, forKey: SettingsKey.timerEndActions)
    }
}
