import Foundation
import SwiftData
import SwiftUI

/// A player in the shared roster. Persisted with SwiftData and synced through iCloud/CloudKit.
///
/// Every stored property has a default value and there are no unique constraints, which keeps the
/// schema compatible with CloudKit's mirroring requirements.
@Model
final class Player {
    var name: String = ""
    var colorHex: String = "#4D96FF"
    /// Ordinal into the active theme's player palette. When set, the player recolors
    /// automatically with the theme; `nil` means `colorHex` is a deliberate custom color
    /// that themes must not override. Optional keeps the schema CloudKit-compatible.
    var paletteIndex: Int? = nil
    var sortIndex: Int = 0
    var createdAt: Date = Date.now

    /// The player's own timer alarm sound (a `TimerSound` raw value); `nil` follows the
    /// global choice. Optional keeps the schema CloudKit-compatible.
    var timerSoundID: String? = nil
    /// The player's own timer display style (a `TimerDisplayStyle` raw value); `nil`
    /// follows the global choice. Optional keeps the schema CloudKit-compatible.
    var timerStyleID: String? = nil

    /// One entry per completed round. Index 0 is round 1. Kept in sync across players by the scorecard.
    var scores: [Int] = []

    /// The game night this player sits at. `nil` is the built-in table that exists before
    /// the user ever creates a group. The inverse lives on `PlayerGroup.players`.
    var group: PlayerGroup? = nil
    /// Links copies of the same person across game nights so name/color edits can follow
    /// them. `nil` until the person is first added to a second game night.
    var personID: UUID? = nil
    /// Sitting out keeps the seat but skips the player in the timer and scorecard.
    var isSittingOut: Bool = false
    /// When true (the default), name/color edits propagate between this person's copies
    /// in other game nights. The per-player opt-out for "consistent settings".
    var syncsPreferences: Bool = true

    // MARK: Appearance
    // All optional or defaulted so the schema stays CloudKit-compatible, and all raw
    // scalars/blobs so older app versions sharing the store simply ignore them.

    /// Which avatar face to show; see `AvatarKind`. Unknown or unbacked values fall back
    /// to the initial letter, so a bad sync can never blank an avatar.
    var avatarKindRaw: String = ""
    /// Downscaled selfie / library photo / Image Playground output. External storage
    /// keeps the CloudKit record itself small.
    @Attribute(.externalStorage) var avatarImageData: Data? = nil
    /// The player's chosen avatar emoji (used when `avatarKind == .emoji`).
    var avatarEmoji: String? = nil
    /// JSON-encoded `PlayerMonogramStyle` (letters + typography + shape).
    var monogramData: Data? = nil
    /// Optional second and third colors; together with `colorHex`/`paletteIndex` they
    /// form the player's gradient.
    var colorHex2: String? = nil
    var colorHex3: String? = nil
    /// JSON dictionary of `ReactionKind` raw value → emoji, for reaction animations.
    var reactionEmojiData: Data? = nil

    init(name: String, colorHex: String = "#4D96FF", paletteIndex: Int? = nil, sortIndex: Int = 0) {
        self.name = name
        self.colorHex = colorHex
        self.paletteIndex = paletteIndex
        self.sortIndex = sortIndex
        self.createdAt = .now
        self.scores = []
    }

    /// The literal stored color, ignoring themes. Prefer `color(in:)` in UI code.
    var color: Color {
        get { Color(hex: colorHex) }
        set { colorHex = newValue.hexString }
    }

    /// Resolves the display color: the theme palette when the player follows it, or the
    /// stored hex when the user picked a custom color.
    func color(in palette: ThemePalette) -> Color {
        if let paletteIndex { return palette.playerColor(paletteIndex) }
        return Color(hex: colorHex)
    }

    func colorHex(in palette: ThemePalette) -> String {
        if let paletteIndex { return palette.playerHex(paletteIndex) }
        return colorHex
    }

    var total: Int { scores.reduce(0, +) }

    /// Reads a round's score safely, treating missing rounds as zero.
    func score(inRound round: Int) -> Int {
        guard round >= 0, round < scores.count else { return 0 }
        return scores[round]
    }

    /// Writes a round's score, padding earlier rounds with zeros if needed.
    func setScore(_ value: Int, inRound round: Int) {
        guard round >= 0 else { return }
        while scores.count <= round { scores.append(0) }
        scores[round] = value
    }
}
