import Foundation
#if canImport(ActivityKit) && os(iOS) && !targetEnvironment(macCatalyst)
import ActivityKit
#endif

/// Runs the lock-screen/Dynamic Island timer Live Activity. All failures are silent and
/// every call is gated on the user's toggle plus the system's per-app permission —
/// callers just describe the current timer state and move on.
@MainActor
final class LiveActivityService {
    static let shared = LiveActivityService()

    private init() {}

    private var isEnabled: Bool {
        UserDefaults.standard.object(forKey: SettingsKey.timerLiveActivity) as? Bool ?? true
    }

    #if canImport(ActivityKit) && os(iOS) && !targetEnvironment(macCatalyst)
    private var activity: Activity<TimerActivityAttributes>?

    /// Starts the Activity if none is running, else pushes the new state.
    func startOrUpdate(_ state: TimerActivityAttributes.ContentState) {
        guard isEnabled, ActivityAuthorizationInfo().areActivitiesEnabled else { return }
        Task {
            // Adopt (and clean up) any Activity left over from a previous run.
            if activity == nil {
                let existing = Activity<TimerActivityAttributes>.activities
                activity = existing.first
                for stale in existing.dropFirst() {
                    await stale.end(nil, dismissalPolicy: .immediate)
                }
            }
            let content = ActivityContent(state: state, staleDate: state.endDate)
            if let activity {
                await activity.update(content)
            } else {
                activity = try? Activity.request(attributes: TimerActivityAttributes(), content: content)
            }
        }
    }

    func end() {
        Task {
            for activity in Activity<TimerActivityAttributes>.activities {
                await activity.end(nil, dismissalPolicy: .immediate)
            }
            activity = nil
        }
    }
    #else
    func end() {}
    #endif
}
