import SwiftUI

/// One appearance variant of a theme: every semantic color role the UI reads.
///
/// Colors are stored as hex strings so the same type round-trips through the theme JSON
/// used by the theme service; views read the computed `Color` accessors.
struct ThemePalette: Codable, Hashable {
    var backgroundHex: String
    var surfaceHex: String
    var surfaceElevatedHex: String
    var accentHex: String
    var accentSecondaryHex: String
    var textPrimaryHex: String
    var textSecondaryHex: String
    var positiveHex: String
    var negativeHex: String
    var warningHex: String
    var diceFaceHex: String
    var dicePipHex: String
    /// Ordered palette assigned to players; at least 10 mutually distinguishable colors.
    var playerHexes: [String]

    enum CodingKeys: String, CodingKey {
        case backgroundHex = "background"
        case surfaceHex = "surface"
        case surfaceElevatedHex = "surfaceElevated"
        case accentHex = "accent"
        case accentSecondaryHex = "accentSecondary"
        case textPrimaryHex = "textPrimary"
        case textSecondaryHex = "textSecondary"
        case positiveHex = "positive"
        case negativeHex = "negative"
        case warningHex = "warning"
        case diceFaceHex = "diceFace"
        case dicePipHex = "dicePip"
        case playerHexes = "players"
    }

    // MARK: - Color accessors

    var background: Color { Color(hex: backgroundHex) }
    var surface: Color { Color(hex: surfaceHex) }
    var surfaceElevated: Color { Color(hex: surfaceElevatedHex) }
    var accent: Color { Color(hex: accentHex) }
    var accentSecondary: Color { Color(hex: accentSecondaryHex) }
    var textPrimary: Color { Color(hex: textPrimaryHex) }
    var textSecondary: Color { Color(hex: textSecondaryHex) }
    var positive: Color { Color(hex: positiveHex) }
    var negative: Color { Color(hex: negativeHex) }
    var warning: Color { Color(hex: warningHex) }
    var diceFace: Color { Color(hex: diceFaceHex) }
    var dicePip: Color { Color(hex: dicePipHex) }

    /// The player color for an ordinal index; wraps when the roster outgrows the palette.
    func playerColor(_ index: Int) -> Color {
        Color(hex: playerHex(index))
    }

    func playerHex(_ index: Int) -> String {
        guard !playerHexes.isEmpty else { return textPrimaryHex }
        return playerHexes[((index % playerHexes.count) + playerHexes.count) % playerHexes.count]
    }
}

/// A complete theme: identity plus a light and a dark palette.
///
/// Decoding is forward-compatible: unknown JSON fields are ignored, and optional metadata
/// (game association, tags, timestamps) may be absent. `schemaVersion` lets old clients
/// reject documents they cannot understand instead of misrendering them.
struct AppTheme: Codable, Identifiable, Hashable {
    static let supportedSchemaVersion = 1

    var schemaVersion: Int
    var id: String
    var name: String
    var game: GameAssociation?
    var tags: [String]
    var updatedAt: Date?
    var light: ThemePalette
    var dark: ThemePalette

    /// The board game a fetched theme is inspired by. Built-in themes have none.
    /// Themes are fan-made color schemes; names stay descriptive, never "official".
    struct GameAssociation: Codable, Hashable {
        var name: String
        var slug: String
        var aliases: [String]

        init(name: String, slug: String, aliases: [String] = []) {
            self.name = name
            self.slug = slug
            self.aliases = aliases
        }

        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            name = try container.decode(String.self, forKey: .name)
            slug = try container.decode(String.self, forKey: .slug)
            aliases = try container.decodeIfPresent([String].self, forKey: .aliases) ?? []
        }
    }

    init(schemaVersion: Int = AppTheme.supportedSchemaVersion,
         id: String,
         name: String,
         game: GameAssociation? = nil,
         tags: [String] = [],
         updatedAt: Date? = nil,
         light: ThemePalette,
         dark: ThemePalette) {
        self.schemaVersion = schemaVersion
        self.id = id
        self.name = name
        self.game = game
        self.tags = tags
        self.updatedAt = updatedAt
        self.light = light
        self.dark = dark
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        schemaVersion = try container.decodeIfPresent(Int.self, forKey: .schemaVersion) ?? 1
        id = try container.decode(String.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        game = try container.decodeIfPresent(GameAssociation.self, forKey: .game)
        tags = try container.decodeIfPresent([String].self, forKey: .tags) ?? []
        updatedAt = try container.decodeIfPresent(Date.self, forKey: .updatedAt)
        light = try container.decode(ThemePalette.self, forKey: .light)
        dark = try container.decode(ThemePalette.self, forKey: .dark)
    }

    /// Whether this client understands the document. Newer schema versions are rejected
    /// rather than guessed at.
    var isSupported: Bool { schemaVersion <= Self.supportedSchemaVersion }

    func palette(for scheme: ColorScheme) -> ThemePalette {
        scheme == .dark ? dark : light
    }
}
