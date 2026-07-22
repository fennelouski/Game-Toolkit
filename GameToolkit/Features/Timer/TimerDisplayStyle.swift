import Foundation

/// The selectable ways a timer can render. Raw values are the persisted identifiers
/// (`timer.styleID`, `Player.timerStyleID`) — never rename a case.
enum TimerDisplayStyle: String, CaseIterable, Identifiable {
    case classic
    case speedcube
    case analog
    case progressBar = "progress-bar"
    case waterClock = "water-clock"
    case snowfall
    case hourglass
    case sundial
    case sunriseSunset = "sunrise-sunset"
    case battery

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .classic: return "Classic"
        case .speedcube: return "Speedcube"
        case .analog: return "Analog"
        case .progressBar: return "Progress Bar"
        case .waterClock: return "Water Clock"
        case .snowfall: return "Snowfall"
        case .hourglass: return "Hourglass"
        case .sundial: return "Sundial"
        case .sunriseSunset: return "Sunrise"
        case .battery: return "Battery"
        }
    }

    var symbolName: String {
        switch self {
        case .classic: return "7.square"
        case .speedcube: return "cube"
        case .analog: return "clock"
        case .progressBar: return "minus.rectangle"
        case .waterClock: return "drop"
        case .snowfall: return "snowflake"
        case .hourglass: return "hourglass"
        case .sundial: return "sun.dust"
        case .sunriseSunset: return "sunrise"
        case .battery: return "battery.75percent"
        }
    }

    /// Whether the style only makes sense with a known total duration (it draws progress
    /// toward an end). Count-up timers can't use these.
    var requiresFixedLength: Bool {
        switch self {
        case .classic, .speedcube, .analog: return false
        case .progressBar, .waterClock, .snowfall, .hourglass, .sundial, .sunriseSunset, .battery:
            return true
        }
    }

    /// Shown in the picker on styles the current mode can't use.
    var unavailableReason: String { "Needs a set time" }

    var usesDeviceMotion: Bool { self == .snowfall }

    func isAvailable(isFixedLength: Bool) -> Bool {
        !requiresFixedLength || isFixedLength
    }

    /// Resolves which style actually renders, without ever mutating the stored choices:
    /// a player's pick wins, then the global default, then classic. A stored style the
    /// current mode can't show is skipped, not erased — switch the mode back and it returns.
    static func resolve(playerChoice: String?, defaultChoice: String?,
                        isFixedLength: Bool) -> TimerDisplayStyle {
        for raw in [playerChoice, defaultChoice] {
            if let style = raw.flatMap(TimerDisplayStyle.init(rawValue:)),
               style.isAvailable(isFixedLength: isFixedLength) {
                return style
            }
        }
        return .classic
    }
}
