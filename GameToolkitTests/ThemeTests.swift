import Testing
import Foundation
import SwiftData
import SwiftUI
@testable import Game_Toolkit

// MARK: - Color math shared by the contrast tests

/// WCAG 2.1 relative luminance / contrast, CIE Lab distance, and dichromacy simulation.
/// These mirror the checks run when the palettes were designed, so a careless edit to any
/// built-in theme fails loudly here instead of shipping unreadable.
enum ColorMath {
    static func rgb(_ hex: String) -> (r: Double, g: Double, b: Double) {
        var value: UInt64 = 0
        Scanner(string: hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)).scanHexInt64(&value)
        return (Double((value >> 16) & 0xFF) / 255,
                Double((value >> 8) & 0xFF) / 255,
                Double(value & 0xFF) / 255)
    }

    static func linear(_ c: Double) -> Double {
        c <= 0.03928 ? c / 12.92 : pow((c + 0.055) / 1.055, 2.4)
    }

    static func luminance(_ hex: String) -> Double {
        let (r, g, b) = rgb(hex)
        return 0.2126 * linear(r) + 0.7152 * linear(g) + 0.0722 * linear(b)
    }

    /// WCAG contrast ratio, 1...21.
    static func contrast(_ a: String, _ b: String) -> Double {
        let la = luminance(a), lb = luminance(b)
        return (max(la, lb) + 0.05) / (min(la, lb) + 0.05)
    }

    static func lab(_ hex: String) -> (l: Double, a: Double, b: Double) {
        let (r, g, b) = rgb(hex)
        return labFromLinear(linear(r), linear(g), linear(b))
    }

    static func labFromLinear(_ r: Double, _ g: Double, _ b: Double) -> (l: Double, a: Double, b: Double) {
        let x = (r * 0.4124 + g * 0.3576 + b * 0.1805) / 0.95047
        let y = r * 0.2126 + g * 0.7152 + b * 0.0722
        let z = (r * 0.0193 + g * 0.1192 + b * 0.9505) / 1.08883
        func f(_ t: Double) -> Double {
            t > 0.008856 ? pow(t, 1.0 / 3.0) : 7.787 * t + 16.0 / 116.0
        }
        return (116 * f(y) - 16, 500 * (f(x) - f(y)), 200 * (f(y) - f(z)))
    }

    static func deltaE(_ a: (l: Double, a: Double, b: Double), _ b: (l: Double, a: Double, b: Double)) -> Double {
        sqrt(pow(a.l - b.l, 2) + pow(a.a - b.a, 2) + pow(a.b - b.b, 2))
    }

    /// Viénot-style linear-RGB projection matrices for the two common dichromacies.
    static let cvdMatrices: [String: [[Double]]] = [
        "protanopia": [[0.152286, 1.052583, -0.204868],
                       [0.114503, 0.786281, 0.099216],
                       [-0.003882, -0.048116, 1.051998]],
        "deuteranopia": [[0.367322, 0.860646, -0.227968],
                         [0.280085, 0.672501, 0.047413],
                         [-0.011820, 0.042940, 0.968881]],
    ]

    /// Lab coordinates of a color as seen with the given color-vision deficiency.
    static func simulatedLab(_ hex: String, cvd: String) -> (l: Double, a: Double, b: Double) {
        let (r, g, b) = rgb(hex)
        let (lr, lg, lb) = (linear(r), linear(g), linear(b))
        let m = cvdMatrices[cvd]!
        let sr = min(1, max(0, m[0][0] * lr + m[0][1] * lg + m[0][2] * lb))
        let sg = min(1, max(0, m[1][0] * lr + m[1][1] * lg + m[1][2] * lb))
        let sb = min(1, max(0, m[2][0] * lr + m[2][1] * lg + m[2][2] * lb))
        return labFromLinear(sr, sg, sb)
    }
}

// MARK: - Contrast gate for every built-in theme

@Suite("Built-in theme contrast")
struct ThemeContrastTests {

    private var variants: [(String, ThemePalette)] {
        BuiltInThemes.all.flatMap { [("\($0.id)/light", $0.light), ("\($0.id)/dark", $0.dark)] }
    }

    @Test("Text roles hold WCAG AA (4.5:1) on every surface")
    func textContrast() {
        for (tag, p) in variants {
            for (surfaceName, surface) in [("background", p.backgroundHex),
                                           ("surface", p.surfaceHex),
                                           ("surfaceElevated", p.surfaceElevatedHex)] {
                let primary = ColorMath.contrast(p.textPrimaryHex, surface)
                #expect(primary >= 4.5, "\(tag): textPrimary on \(surfaceName) is \(primary)")
                let secondary = ColorMath.contrast(p.textSecondaryHex, surface)
                #expect(secondary >= 4.5, "\(tag): textSecondary on \(surfaceName) is \(secondary)")
            }
        }
    }

    @Test("Dice pips hold WCAG AA on the die face")
    func diceContrast() {
        for (tag, p) in variants {
            let ratio = ColorMath.contrast(p.dicePipHex, p.diceFaceHex)
            #expect(ratio >= 4.5, "\(tag): dicePip on diceFace is \(ratio)")
        }
    }

    @Test("Semantic colors are visible (3:1, WCAG AA for large text / UI components)")
    func semanticContrast() {
        for (tag, p) in variants {
            for (name, hex) in [("positive", p.positiveHex), ("negative", p.negativeHex),
                                ("warning", p.warningHex), ("accent", p.accentHex)] {
                for surface in [p.backgroundHex, p.surfaceHex, p.surfaceElevatedHex] {
                    let ratio = ColorMath.contrast(hex, surface)
                    #expect(ratio >= 3.0, "\(tag): \(name) on \(surface) is \(ratio)")
                }
            }
        }
    }

    @Test("Button labels stay readable on the accent color")
    func accentForeground() {
        for (tag, p) in variants {
            let fg = Color(hex: p.accentHex).readableForeground == .black ? "#000000" : "#FFFFFF"
            let ratio = ColorMath.contrast(fg, p.accentHex)
            #expect(ratio >= 3.0, "\(tag): readable foreground on accent is \(ratio)")
        }
    }

    @Test("Player palettes have at least 10 colors, visible against the surface")
    func playerPaletteSize() {
        for (tag, p) in variants {
            #expect(p.playerHexes.count >= 10, "\(tag): only \(p.playerHexes.count) player colors")
            for hex in p.playerHexes {
                let ratio = ColorMath.contrast(hex, p.surfaceHex)
                #expect(ratio >= 1.6, "\(tag): player \(hex) fades into the surface (\(ratio))")
            }
        }
    }

    @Test("Player colors stay mutually distinguishable, including for common color-vision deficiencies")
    func playerDistinguishability() {
        for (tag, p) in variants {
            let normal = p.playerHexes.map { ColorMath.lab($0) }
            for i in 0..<p.playerHexes.count {
                for j in (i + 1)..<p.playerHexes.count {
                    let d = ColorMath.deltaE(normal[i], normal[j])
                    #expect(d >= 16, "\(tag): players \(p.playerHexes[i]) and \(p.playerHexes[j]) look alike (dE \(d))")
                }
            }
            for cvd in ["protanopia", "deuteranopia"] {
                let simulated = p.playerHexes.map { ColorMath.simulatedLab($0, cvd: cvd) }
                for i in 0..<p.playerHexes.count {
                    for j in (i + 1)..<p.playerHexes.count {
                        let d = ColorMath.deltaE(simulated[i], simulated[j])
                        #expect(d >= 9, "\(tag)/\(cvd): players \(p.playerHexes[i]) and \(p.playerHexes[j]) collide (dE \(d))")
                    }
                }
            }
        }
    }
}

// MARK: - Theme document decoding

@Suite("Theme decoding")
struct ThemeDecodingTests {

    static let paletteJSON = """
    {
      "background": "#F3EFE6", "surface": "#FFFFFF", "surfaceElevated": "#E8E1D4",
      "accent": "#2F5D50", "accentSecondary": "#B85C38",
      "textPrimary": "#1E2A24", "textSecondary": "#5C6660",
      "positive": "#3F7D5A", "negative": "#A8433A", "warning": "#C08A3E",
      "diceFace": "#F7F3EA", "dicePip": "#243029",
      "players": ["#2F5D50", "#B85C38", "#4A6FA5", "#7C9A82"]
    }
    """

    private func decoder() -> JSONDecoder {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }

    @Test("A full theme document decodes")
    func decodeFullDocument() throws {
        let json = """
        {
          "schemaVersion": 1,
          "id": "wingspan",
          "name": "Feathered Meadow",
          "game": { "name": "Wingspan", "slug": "wingspan", "aliases": ["wing span"] },
          "tags": ["nature", "soft"],
          "updatedAt": "2026-07-21T00:00:00Z",
          "light": \(Self.paletteJSON),
          "dark": \(Self.paletteJSON)
        }
        """
        let theme = try decoder().decode(AppTheme.self, from: Data(json.utf8))
        #expect(theme.id == "wingspan")
        #expect(theme.name == "Feathered Meadow")
        #expect(theme.game?.slug == "wingspan")
        #expect(theme.game?.aliases == ["wing span"])
        #expect(theme.tags == ["nature", "soft"])
        #expect(theme.updatedAt != nil)
        #expect(theme.isSupported)
        #expect(theme.light.backgroundHex == "#F3EFE6")
        #expect(theme.light.playerHexes.count == 4)
    }

    @Test("Unknown fields are ignored so newer servers don't break old clients")
    func unknownFieldsIgnored() throws {
        let json = """
        {
          "id": "future", "name": "From The Future",
          "brandNewField": {"nested": [1, 2, 3]},
          "light": \(Self.paletteJSON),
          "dark": \(Self.paletteJSON),
          "anotherSurprise": "ok"
        }
        """
        let theme = try decoder().decode(AppTheme.self, from: Data(json.utf8))
        #expect(theme.id == "future")
        #expect(theme.schemaVersion == 1, "schemaVersion defaults to 1 when absent")
        #expect(theme.tags.isEmpty)
        #expect(theme.game == nil)
    }

    @Test("A newer schema version is recognized as unsupported, not misread")
    func newerSchemaUnsupported() throws {
        let json = """
        {
          "schemaVersion": 99, "id": "v99", "name": "Too New",
          "light": \(Self.paletteJSON), "dark": \(Self.paletteJSON)
        }
        """
        let theme = try decoder().decode(AppTheme.self, from: Data(json.utf8))
        #expect(!theme.isSupported)
    }

    @Test("A document missing required colors fails to decode")
    func missingColorFails() {
        let json = """
        {
          "id": "broken", "name": "Broken",
          "light": { "background": "#FFFFFF" },
          "dark": \(Self.paletteJSON)
        }
        """
        #expect(throws: (any Error).self) {
            try decoder().decode(AppTheme.self, from: Data(json.utf8))
        }
    }

    @Test("Themes round-trip through their JSON encoding")
    func roundTrip() throws {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let data = try encoder.encode(BuiltInThemes.hearth)
        let decoded = try decoder().decode(AppTheme.self, from: data)
        #expect(decoded == BuiltInThemes.hearth)
    }

    @Test("Built-in theme ids are unique and resolvable")
    func builtInIntegrity() {
        let ids = BuiltInThemes.all.map(\.id)
        #expect(Set(ids).count == ids.count)
        for id in ids {
            #expect(BuiltInThemes.theme(id: id) != nil)
        }
        #expect(BuiltInThemes.theme(id: BuiltInThemes.defaultTheme.id) != nil)
    }
}

// MARK: - Player palette resolution

@Suite("Player theme colors")
struct PlayerPaletteTests {

    @Test("A palette index resolves through the theme and wraps past the end")
    func paletteIndexResolves() {
        let palette = BuiltInThemes.hearth.light
        let player = Player(name: "Avery", paletteIndex: 2)
        #expect(player.colorHex(in: palette) == palette.playerHexes[2])

        let wrapped = Player(name: "Blake", paletteIndex: palette.playerHexes.count + 1)
        #expect(wrapped.colorHex(in: palette) == palette.playerHexes[1])
    }

    @Test("A custom color survives theme changes")
    func customColorWins() {
        let player = Player(name: "Casey", colorHex: "#123456", paletteIndex: nil)
        #expect(player.colorHex(in: BuiltInThemes.hearth.light) == "#123456")
        #expect(player.colorHex(in: BuiltInThemes.gaslight.dark) == "#123456")
    }

    @Test("Legacy palette hexes adopt a palette index; custom hexes are left alone")
    @MainActor
    func migrationAdoptsLegacyColors() throws {
        let container = try TestSupport.container()
        let context = container.mainContext

        let legacy = Player(name: "Old", colorHex: Theme.legacyPlayerPalette[3])
        let custom = Player(name: "Custom", colorHex: "#0B1E2D")
        context.insert(legacy)
        context.insert(custom)

        Roster.adoptPaletteIndices(context, players: [legacy, custom])

        #expect(legacy.paletteIndex == 3)
        #expect(custom.paletteIndex == nil)
    }

    @Test("New players are dealt distinct palette indices")
    @MainActor
    func newPlayersGetIndices() throws {
        let container = try TestSupport.container()
        let context = container.mainContext

        let first = Roster.add(context)
        let second = Roster.add(context)

        #expect(first.paletteIndex == 0)
        #expect(second.paletteIndex == 1)
    }
}

enum TestSupport {
    @MainActor
    static func container() throws -> ModelContainer {
        let configuration = ModelConfiguration(isStoredInMemoryOnly: true)
        return try ModelContainer(for: Player.self, configurations: configuration)
    }
}
