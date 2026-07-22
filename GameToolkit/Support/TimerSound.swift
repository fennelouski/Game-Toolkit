import Foundation

/// The catalog of bundled timer sounds. Raw values are the persisted identifiers
/// (`timer.soundID`, `Player.timerSoundID`) — never rename a case.
///
/// The generated sounds are CAF/IMA4 mono (see `Scripts/generate-sounds.mjs`), which is
/// the one format accepted everywhere a timer sound can play: `AVAudioPlayer`, local
/// notification sounds, and AlarmKit. A case whose file is missing from the bundle simply
/// doesn't play — same silent-failure policy as the rest of the audio path.
enum TimerSound: String, CaseIterable, Identifiable, Codable {
    case firePager
    case chime, gong, buzzer, bell, chirp, drum, whistle, klaxon

    static let `default` = TimerSound.firePager

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .firePager: return "Fire Pager"
        case .chime: return "Chime"
        case .gong: return "Gong"
        case .buzzer: return "Buzzer"
        case .bell: return "Bell"
        case .chirp: return "Chirp"
        case .drum: return "Drum"
        case .whistle: return "Whistle"
        case .klaxon: return "Klaxon"
        }
    }

    /// File name as it appears in the bundle root (synchronized groups flatten resources).
    var fileName: String {
        switch self {
        case .firePager: return "Fire Pager.wav"
        default: return "\(rawValue).caf"
        }
    }

    var fileURL: URL? {
        let name = (fileName as NSString).deletingPathExtension
        let ext = (fileName as NSString).pathExtension
        return Bundle.main.url(forResource: name, withExtension: ext)
    }

    /// Cases whose audio file is actually present in this build.
    static var available: [TimerSound] { allCases.filter { $0.fileURL != nil } }

    /// Resolves a stored identifier, falling back to the default for unknown or missing ids.
    static func resolve(_ id: String?) -> TimerSound {
        guard let id, let sound = TimerSound(rawValue: id), sound.fileURL != nil else {
            return .default
        }
        return sound
    }
}
