import Foundation
#if canImport(ActivityKit) && !targetEnvironment(macCatalyst)
import ActivityKit

/// The lock-screen/Dynamic Island timer contract, shared with the widget extension
/// (the widget target gains membership of this file via a synchronized-group exception).
///
/// The system renders the ticking clock itself from the date anchors
/// (`Text(timerInterval:)`), so the app only pushes updates on state transitions —
/// start, pause, resume, turn change, expiry — never per tick.
struct TimerActivityAttributes: ActivityAttributes {
    struct ContentState: Codable, Hashable {
        var playerName: String
        /// Player color; hex because the widget can't read the app's palette environment.
        var colorHex: String
        /// Fixed-length timers: when the clock hits zero.
        var endDate: Date?
        /// Count-up timers: when the clock started (already offset by prior elapsed time).
        var startDate: Date?
        var isPaused: Bool
        /// Frozen remaining seconds to show while paused.
        var pausedRemaining: TimeInterval?
        var isExpired: Bool
    }
}
#endif
