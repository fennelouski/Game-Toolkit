import SwiftUI
import SwiftData
import Observation

/// Turns `TimerEvent`s into user-visible effects — screen flash, color pulse, haptics,
/// flashlight, sound, and the system-alarm sound suppression — reading the configured
/// end/switch actions at fire time. The view layers `overlayColor`/`overlayOpacity` as a
/// full-screen non-interactive rectangle.
@MainActor
@Observable
final class TimerEffects {
    private(set) var overlayColor: Color = .clear
    private(set) var overlayOpacity: Double = 0

    /// Set by the view; effects honor Reduce Motion by collapsing pulses into one fade.
    var reduceMotion = false

    private var overlayTask: Task<Void, Never>?
    private var defaults: UserDefaults { .standard }

    func handle(_ event: TimerEvent, players: [Player], palette: ThemePalette) {
        switch event {
        case let .expired(id, next):
            runExpiry(for: id, next: next, players: players, palette: palette)
        case let .autoSwitched(_, to):
            runSwitch(to: to, players: players, palette: palette)
        case .didAutoReset:
            break
        }
    }

    private func runExpiry(for id: TimerSlotID, next: TimerSlotID?,
                           players: [Player], palette: ThemePalette) {
        let actions = TimerEndActions(rawValue: defaults.integer(forKey: SettingsKey.timerEndActions))
        let alarmDuration = defaults.object(forKey: SettingsKey.alarmDuration) as? Double ?? 3

        if actions.contains(.haptics) {
            playHaptics(intensity: hapticIntensity, count: 3)
        }
        if actions.contains(.sound) && !systemAlarmCoversAudio {
            AudioManager.shared.playAlarm(sound(for: id, players: players), for: alarmDuration)
        }
        if actions.contains(.flashlight) {
            TorchService.flash(.expiry)
        }
        // Color pulse wins over the plain flash when both are on: it carries information
        // (whose turn ended / who's next), the flash is pure salience.
        if actions.contains(.colorPulse) {
            pulseOverlay(color: pulseColor(expired: id, next: next, players: players, palette: palette),
                         pulses: 1, peak: 0.55, hold: 0.6)
        } else if actions.contains(.flashScreen) {
            // A literal photographic flash — white in every theme, not a palette role.
            pulseOverlay(color: .white, pulses: 3, peak: 0.8, hold: 0.1)
        }
    }

    private func runSwitch(to: TimerSlotID, players: [Player], palette: ThemePalette) {
        let actions = TimerEndActions(rawValue: defaults.integer(forKey: SettingsKey.timerSwitchActions))

        if actions.contains(.haptics) {
            Haptics.impact(.medium, intensity: hapticIntensity)
        }
        if actions.contains(.sound) {
            AudioManager.shared.playBlip(sound(for: to, players: players))
        }
        if actions.contains(.flashlight) {
            TorchService.flash(.turnChange)
        }
        if actions.contains(.colorPulse) {
            pulseOverlay(color: color(for: to, players: players, palette: palette),
                         pulses: 1, peak: 0.4, hold: 0.25)
        } else if actions.contains(.flashScreen) {
            pulseOverlay(color: .white, pulses: 1, peak: 0.6, hold: 0.08)
        }
    }

    // MARK: - Lookups

    private var hapticIntensity: CGFloat {
        CGFloat(defaults.object(forKey: SettingsKey.timerHapticIntensity) as? Double ?? 1.0)
    }

    /// When AlarmKit is about to ring a real system alarm, in-app audio would double up.
    private var systemAlarmCoversAudio: Bool {
        defaults.bool(forKey: SettingsKey.timerSystemAlarm) && SystemAlarmService.shared.backend == .alarmKit
    }

    private func player(for id: TimerSlotID, in players: [Player]) -> Player? {
        guard case let .player(pid) = id else { return nil }
        return players.first(where: { $0.persistentModelID == pid })
    }

    private func sound(for id: TimerSlotID, players: [Player]) -> TimerSound {
        let global = defaults.string(forKey: SettingsKey.timerSoundID)
        let perPlayer = player(for: id, in: players)?.timerSoundID
        return TimerSound.resolve(perPlayer ?? global)
    }

    private func color(for id: TimerSlotID, players: [Player], palette: ThemePalette) -> Color {
        player(for: id, in: players)?.color(in: palette) ?? palette.accent
    }

    private func pulseColor(expired: TimerSlotID, next: TimerSlotID?,
                            players: [Player], palette: ThemePalette) -> Color {
        let target = ColorPulseTarget(rawValue: defaults.string(forKey: SettingsKey.timerColorPulseTarget) ?? "")
            ?? .expiredPlayer
        if target == .nextPlayer, let next {
            return color(for: next, players: players, palette: palette)
        }
        return color(for: expired, players: players, palette: palette)
    }

    // MARK: - Overlay

    private func playHaptics(intensity: CGFloat, count: Int) {
        Haptics.notify(.error)
        Task {
            for _ in 0..<count {
                Haptics.impact(.heavy, intensity: intensity)
                try? await Task.sleep(for: .milliseconds(220))
            }
        }
    }

    private func pulseOverlay(color: Color, pulses: Int, peak: Double, hold: Double) {
        overlayTask?.cancel()
        overlayColor = color
        overlayTask = Task { [weak self] in
            guard let self else { return }
            if reduceMotion {
                // One gentle fade instead of strobing.
                withAnimation(.easeOut(duration: 0.4)) { self.overlayOpacity = min(peak, 0.35) }
                try? await Task.sleep(for: .milliseconds(500))
                withAnimation(.easeIn(duration: 0.5)) { self.overlayOpacity = 0 }
                return
            }
            for index in 0..<pulses {
                withAnimation(.easeOut(duration: 0.12)) { self.overlayOpacity = peak }
                try? await Task.sleep(for: .seconds(0.12 + hold))
                if Task.isCancelled { return }
                withAnimation(.easeIn(duration: 0.25)) { self.overlayOpacity = 0 }
                if index < pulses - 1 {
                    try? await Task.sleep(for: .milliseconds(320))
                    if Task.isCancelled { return }
                }
            }
        }
    }
}
