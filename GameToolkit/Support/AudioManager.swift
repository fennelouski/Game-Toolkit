import AVFoundation

/// Plays the bundled alarm sound when a turn timer runs out.
final class AudioManager {
    static let shared = AudioManager()
    private var player: AVAudioPlayer?

    private init() {}

    func playAlarm(for duration: TimeInterval) {
        guard UserDefaults.standard.object(forKey: SettingsKey.soundEnabled) as? Bool ?? true else { return }
        guard let url = Bundle.main.url(forResource: "Fire Pager", withExtension: "wav") else { return }

        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, options: [.mixWithOthers])
            try AVAudioSession.sharedInstance().setActive(true)
            let player = try AVAudioPlayer(contentsOf: url)
            player.numberOfLoops = -1
            player.prepareToPlay()
            player.play()
            self.player = player
            DispatchQueue.main.asyncAfter(deadline: .now() + max(0.5, duration)) { [weak self] in
                self?.stop()
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
