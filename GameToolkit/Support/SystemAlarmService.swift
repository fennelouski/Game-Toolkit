import Foundation
import UserNotifications
#if canImport(AlarmKit) && os(iOS) && !targetEnvironment(macCatalyst)
import AlarmKit
#endif

#if canImport(AlarmKit) && os(iOS) && !targetEnvironment(macCatalyst)
@available(iOS 26.0, *)
private struct TimerAlarmMetadata: AlarmMetadata {}
#endif

/// Ties the in-app timer into the system's own alarms ("tie into system timers").
///
/// On iOS 26+ this schedules a real AlarmKit alarm that breaks through silent mode and
/// Focus; earlier systems (and Mac Catalyst) fall back to a time-sensitive local
/// notification. Alarms are alert-only and fixed-date — nothing shows until the fire
/// time, so the app's own Live Activity stays the single lock-screen countdown — and
/// pause/resume maps to cancel + reschedule on both backends.
@MainActor
final class SystemAlarmService {
    static let shared = SystemAlarmService()

    enum Backend { case alarmKit, notification }

    private let notificationID = "timer.expiry"
    #if os(iOS) && !targetEnvironment(macCatalyst)
    private var alarmID: UUID?
    #endif

    private init() {}

    var backend: Backend {
        #if canImport(AlarmKit) && os(iOS) && !targetEnvironment(macCatalyst)
        if #available(iOS 26.0, *) { return .alarmKit }
        #endif
        return .notification
    }

    var isEnabled: Bool {
        UserDefaults.standard.bool(forKey: SettingsKey.timerSystemAlarm)
    }

    /// Prompts for the backend's permission on first use. Returns whether the feature can
    /// run; callers flip the toggle back off on `false`.
    func requestAuthorizationIfNeeded() async -> Bool {
        #if canImport(AlarmKit) && os(iOS) && !targetEnvironment(macCatalyst)
        if #available(iOS 26.0, *) {
            switch AlarmManager.shared.authorizationState {
            case .authorized:
                return true
            case .notDetermined:
                let state = try? await AlarmManager.shared.requestAuthorization()
                return state == .authorized
            default:
                return false
            }
        }
        #endif
        let center = UNUserNotificationCenter.current()
        let settings = await center.notificationSettings()
        switch settings.authorizationStatus {
        case .authorized, .provisional, .ephemeral:
            return true
        case .notDetermined:
            return (try? await center.requestAuthorization(options: [.alert, .sound])) ?? false
        default:
            return false
        }
    }

    /// Schedules the system alarm/notification for `endDate`, replacing any previous one.
    /// No-op when the user hasn't enabled the feature or the date is already past.
    func schedule(endDate: Date, label: String, sound: TimerSound) async {
        guard isEnabled else { return }
        await cancel()
        guard endDate.timeIntervalSinceNow > 1 else { return }

        #if canImport(AlarmKit) && os(iOS) && !targetEnvironment(macCatalyst)
        if #available(iOS 26.0, *) {
            let stopButton = AlarmButton(text: "Stop", textColor: .white, systemImageName: "stop.circle")
            let alert = AlarmPresentation.Alert(title: "\(label) — time's up!", stopButton: stopButton)
            let attributes = AlarmAttributes<TimerAlarmMetadata>(
                presentation: AlarmPresentation(alert: alert),
                tintColor: .accentColor
            )
            let soundName = (sound.fileName as NSString).deletingPathExtension
            let configuration = AlarmManager.AlarmConfiguration(
                schedule: .fixed(endDate),
                attributes: attributes,
                sound: .named(soundName)
            )
            let id = UUID()
            do {
                _ = try await AlarmManager.shared.schedule(id: id, configuration: configuration)
                alarmID = id
            } catch {
                // The alarm is a backstop; never let scheduling break the timer.
            }
            return
        }
        #endif

        let content = UNMutableNotificationContent()
        content.title = "Time's up!"
        content.body = label
        content.sound = UNNotificationSound(named: UNNotificationSoundName(sound.fileName))
        content.interruptionLevel = .timeSensitive
        let trigger = UNTimeIntervalNotificationTrigger(
            timeInterval: max(1, endDate.timeIntervalSinceNow), repeats: false)
        let request = UNNotificationRequest(identifier: notificationID, content: content, trigger: trigger)
        try? await UNUserNotificationCenter.current().add(request)
    }

    func cancel() async {
        #if canImport(AlarmKit) && os(iOS) && !targetEnvironment(macCatalyst)
        if #available(iOS 26.0, *), let id = alarmID {
            try? AlarmManager.shared.cancel(id: id)
            alarmID = nil
        }
        #endif
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [notificationID])
    }
}
