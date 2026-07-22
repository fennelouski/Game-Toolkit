import Foundation
import SwiftUI

// MARK: - Avatar kind

/// The face a player shows around the app. Stored as a raw string on `Player` so the
/// CloudKit schema stays a plain scalar and future kinds degrade gracefully.
enum AvatarKind: String {
    case initial
    case photo
    case emoji
    case monogram
}

// MARK: - Reactions

/// Moments a player can attach a signature emoji to. Stored choices are read by
/// scoreboard/timer animations (wins, busts, celebrations) as those land.
enum ReactionKind: String, CaseIterable, Identifiable {
    case success, failure, joy, sadness, celebration

    var id: String { rawValue }

    var label: String {
        switch self {
        case .success: return "Success"
        case .failure: return "Failure"
        case .joy: return "Joy"
        case .sadness: return "Sadness"
        case .celebration: return "Celebration"
        }
    }

    var defaultEmoji: String {
        switch self {
        case .success: return "🎯"
        case .failure: return "💥"
        case .joy: return "😄"
        case .sadness: return "😢"
        case .celebration: return "🎉"
        }
    }

    var suggestions: [String] {
        switch self {
        case .success: return ["🎯", "✅", "💪", "🔥", "⭐️", "🏆"]
        case .failure: return ["💥", "🙈", "😵", "🪦", "❌", "🥀"]
        case .joy: return ["😄", "🥳", "😂", "☀️", "🌈", "🕺"]
        case .sadness: return ["😢", "😭", "🥺", "🌧️", "💔", "🫠"]
        case .celebration: return ["🎉", "🎊", "🍾", "🥂", "🎆", "👑"]
        }
    }
}

// MARK: - Monogram

/// Styling for a designed monogram avatar, stored as JSON in `Player.monogramData`.
/// Everything is relative to the rendered box size so one design scales from a 22 pt
/// scorecard chip to the TV scoreboard. Ported from the Tailor résumé monogram.
struct PlayerMonogramStyle: Codable, Equatable {
    /// Up to three letters. Empty means "derive initials from the player's name".
    var text: String = ""
    var fontName: String = "Baskerville-SemiBold"
    /// Glyph size as a fraction of the box height.
    var fontScale: Double = 0.42
    /// Center-out letter spread as a fraction of the box size (Tailor-style kerning:
    /// letters left of center shift right and vice versa, stronger further out).
    var kerning: Double = 0
    /// Corner radius as a fraction of the box size: 0 = square, 0.5 = circle.
    var cornerRadius: Double = 0.5
    /// `nil` = the player's color gradient; otherwise a fixed hex.
    var backgroundHex: String? = nil
    /// `nil` = automatic (whatever reads best on the background).
    var textHex: String? = nil
    var shadowEnabled: Bool = false

    /// Fonts curated from the Tailor list for tiny-size legibility plus a few showpieces.
    static let fontOptions: [(name: String, displayName: String)] = [
        ("Baskerville-SemiBold", "Baskerville"),
        ("Didot-Bold", "Didot"),
        ("Georgia-Bold", "Georgia"),
        ("HoeflerText-Black", "Hoefler Text"),
        ("Palatino-Bold", "Palatino"),
        ("BodoniSvtyTwoITCTT-Bold", "Bodoni 72"),
        ("Copperplate-Bold", "Copperplate"),
        ("Optima-Bold", "Optima"),
        ("Futura-Bold", "Futura"),
        ("AvenirNext-DemiBold", "Avenir Next"),
        ("GillSans-SemiBold", "Gill Sans"),
        ("DINAlternate-Bold", "DIN Alternate"),
        ("ArialRoundedMTBold", "Arial Rounded"),
        ("AmericanTypewriter-Bold", "Typewriter"),
        ("Menlo-Bold", "Menlo"),
        ("MarkerFelt-Wide", "Marker Felt"),
        ("SnellRoundhand-Bold", "Snell Roundhand"),
        ("Zapfino", "Zapfino"),
        ("Herculanum", "Herculanum"),
        ("Trattatello", "Trattatello"),
    ]

    // Decode with per-key fallbacks so styles written by future app versions (or with
    // fields we later add) still open instead of failing the whole avatar.
    init() {}

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        text = (try? c.decode(String.self, forKey: .text)) ?? ""
        fontName = (try? c.decode(String.self, forKey: .fontName)) ?? "Baskerville-SemiBold"
        fontScale = (try? c.decode(Double.self, forKey: .fontScale)) ?? 0.42
        kerning = (try? c.decode(Double.self, forKey: .kerning)) ?? 0
        cornerRadius = (try? c.decode(Double.self, forKey: .cornerRadius)) ?? 0.5
        backgroundHex = try? c.decodeIfPresent(String.self, forKey: .backgroundHex)
        textHex = try? c.decodeIfPresent(String.self, forKey: .textHex)
        shadowEnabled = (try? c.decode(Bool.self, forKey: .shadowEnabled)) ?? false
    }

    private enum CodingKeys: String, CodingKey {
        case text, fontName, fontScale, kerning, cornerRadius, backgroundHex, textHex, shadowEnabled
    }
}

// MARK: - Player accessors

extension Player {
    /// The resolved avatar kind: the stored choice, downgraded to `.initial` whenever the
    /// backing asset is missing (photo without data, emoji without a character, …).
    var avatarKind: AvatarKind {
        get {
            switch AvatarKind(rawValue: avatarKindRaw) {
            case .photo where avatarImageData != nil: return .photo
            case .emoji where avatarEmoji?.isEmpty == false: return .emoji
            case .monogram where monogramData != nil: return .monogram
            default: return .initial
            }
        }
        set { avatarKindRaw = newValue.rawValue }
    }

    var monogramStyle: PlayerMonogramStyle? {
        get { monogramData.flatMap { try? JSONDecoder().decode(PlayerMonogramStyle.self, from: $0) } }
        set { monogramData = newValue.flatMap { try? JSONEncoder().encode($0) } }
    }

    /// Up to three initials taken from the name's words — the monogram default.
    var monogramInitials: String {
        let words = name.split(separator: " ").prefix(3)
        let initials = words.compactMap(\.first).map(String.init).joined()
        return initials.isEmpty ? String(name.prefix(1)) : initials
    }

    // MARK: Colors

    /// The player's 1–3 colors, primary first. The third only counts when a second exists,
    /// matching what the editor allows.
    func colors(in palette: ThemePalette) -> [Color] {
        var result = [color(in: palette)]
        if let colorHex2 {
            result.append(Color(hex: colorHex2))
            if let colorHex3 { result.append(Color(hex: colorHex3)) }
        }
        return result
    }

    /// The fill used wherever the player is painted: the single color's system gradient,
    /// or a diagonal blend of their chosen colors.
    func fill(in palette: ThemePalette) -> AnyShapeStyle {
        let colors = colors(in: palette)
        guard colors.count > 1 else { return AnyShapeStyle(colors[0].gradient) }
        return AnyShapeStyle(LinearGradient(colors: colors, startPoint: .topLeading, endPoint: .bottomTrailing))
    }

    // MARK: Reactions

    private var reactionEmojiMap: [String: String] {
        get {
            guard let reactionEmojiData else { return [:] }
            return (try? JSONDecoder().decode([String: String].self, from: reactionEmojiData)) ?? [:]
        }
        set { reactionEmojiData = newValue.isEmpty ? nil : try? JSONEncoder().encode(newValue) }
    }

    /// The player's emoji for a moment, falling back to the app default.
    func reactionEmoji(for kind: ReactionKind) -> String {
        reactionEmojiMap[kind.rawValue] ?? kind.defaultEmoji
    }

    /// The player's own pick, `nil` when they use the default.
    func customReactionEmoji(for kind: ReactionKind) -> String? {
        reactionEmojiMap[kind.rawValue]
    }

    func setReactionEmoji(_ emoji: String?, for kind: ReactionKind) {
        var map = reactionEmojiMap
        map[kind.rawValue] = emoji?.firstEmoji
        reactionEmojiMap = map
    }
}

// MARK: - Emoji helpers

extension Character {
    /// True for characters that render as emoji, including multi-scalar sequences
    /// (skin tones, flags, ZWJ families) — used to keep emoji fields emoji-only.
    var isRenderableEmoji: Bool {
        guard let first = unicodeScalars.first else { return false }
        return first.properties.isEmojiPresentation
            || unicodeScalars.contains { $0.properties.isEmojiPresentation }
            || (first.properties.isEmoji && first.value > 0x238C)
    }
}

extension String {
    /// The first emoji in the string, or `nil` — free-text input becomes a single emoji.
    var firstEmoji: String? {
        first(where: \.isRenderableEmoji).map(String.init)
    }
}
