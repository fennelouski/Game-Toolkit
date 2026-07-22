import AVFoundation

/// Plays bundled timer sounds: looping alarms on expiry, short blips on turn changes,
/// and previews from the sound pickers.
final class AudioManager {
    static let shared = AudioManager()
    private var player: AVAudioPlayer?

    private init() {}

    private var soundEnabled: Bool {
        UserDefaults.standard.object(forKey: SettingsKey.soundEnabled) as? Bool ?? true
    }

    /// Loops the given alarm sound for `duration` seconds. Honors the global Sound toggle.
    func playAlarm(_ sound: TimerSound = .default, for duration: TimeInterval) {
        guard soundEnabled else { return }
        play(sound, loops: -1, stopAfter: max(0.5, duration))
    }

    /// One short play-through, for auto-switch turn changes. Honors the global Sound toggle.
    func playBlip(_ sound: TimerSound) {
        guard soundEnabled else { return }
        play(sound, loops: 0, stopAfter: 1.2)
    }

    /// Plays a sound once for the pickers. Deliberately not gated on the Sound toggle —
    /// the user explicitly asked to hear it.
    func preview(_ sound: TimerSound) {
        play(sound, loops: 0, stopAfter: nil)
    }

    private func play(_ sound: TimerSound, loops: Int, stopAfter: TimeInterval?) {
        guard let url = sound.fileURL else { return }
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, options: [.mixWithOthers])
            try AVAudioSession.sharedInstance().setActive(true)
            let player = try AVAudioPlayer(contentsOf: url)
            player.numberOfLoops = loops
            player.prepareToPlay()
            player.play()
            self.player = player
            if let stopAfter {
                DispatchQueue.main.asyncAfter(deadline: .now() + stopAfter) { [weak self, weak player] in
                    // Only stop if a newer sound hasn't replaced this one.
                    guard let self, self.player === player else { return }
                    self.stop()
                }
            }
        } catch {
            // Sound is a nicety; never let it break the app.
        }
    }

    func stop() {
        player?.stop()
        player = nil
    }
}
