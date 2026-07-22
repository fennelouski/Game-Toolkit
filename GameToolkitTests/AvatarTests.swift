import Testing
import Foundation
import SwiftData
import SwiftUI
@testable import Game_Toolkit

// MARK: - Avatar model behavior

@Suite("Player appearance")
struct PlayerAppearanceTests {

    @Test("Avatar kind falls back to initial when its asset is missing")
    func avatarKindFallsBack() {
        let player = Player(name: "Maya")
        player.avatarKindRaw = "photo"
        #expect(player.avatarKind == .initial)

        player.avatarKindRaw = "emoji"
        #expect(player.avatarKind == .initial)
        player.avatarEmoji = "🦊"
        #expect(player.avatarKind == .emoji)

        player.avatarKindRaw = "monogram"
        #expect(player.avatarKind == .initial)
        player.monogramStyle = PlayerMonogramStyle()
        #expect(player.avatarKind == .monogram)

        // Unknown future kinds degrade gracefully too.
        player.avatarKindRaw = "hologram"
        #expect(player.avatarKind == .initial)
    }

    @Test("Monogram style round-trips through JSON and tolerates missing keys")
    func monogramRoundTrip() throws {
        let player = Player(name: "Maya")
        var style = PlayerMonogramStyle()
        style.text = "MB"
        style.fontName = "Didot-Bold"
        style.kerning = 0.08
        style.backgroundHex = "#123456"
        player.monogramStyle = style
        #expect(player.monogramStyle == style)

        // A blob from a future version with unknown/missing fields still decodes.
        let partial = try #require(#"{"text":"XY"}"#.data(using: .utf8))
        let decoded = try JSONDecoder().decode(PlayerMonogramStyle.self, from: partial)
        #expect(decoded.text == "XY")
        #expect(decoded.cornerRadius == 0.5)
    }

    @Test("Monogram initials come from the name's words")
    func monogramInitials() {
        #expect(Player(name: "Maya Beth Chen").monogramInitials == "MBC")
        #expect(Player(name: "Maya de la Cruz Ortiz").monogramInitials == "Mdl")
        #expect(Player(name: "Maya").monogramInitials == "M")
    }

    @Test("Reaction emoji default, override and reset")
    func reactionEmoji() {
        let player = Player(name: "Maya")
        #expect(player.reactionEmoji(for: .success) == ReactionKind.success.defaultEmoji)
        #expect(player.customReactionEmoji(for: .success) == nil)

        player.setReactionEmoji("🏆", for: .success)
        #expect(player.reactionEmoji(for: .success) == "🏆")
        #expect(player.reactionEmoji(for: .failure) == ReactionKind.failure.defaultEmoji)

        player.setReactionEmoji(nil, for: .success)
        #expect(player.reactionEmoji(for: .success) == ReactionKind.success.defaultEmoji)
        #expect(player.reactionEmojiData == nil)
    }

    @Test("Reaction setter keeps only the first emoji from free text")
    func reactionEmojiFiltering() {
        let player = Player(name: "Maya")
        player.setReactionEmoji("win! 🏆🎉", for: .success)
        #expect(player.reactionEmoji(for: .success) == "🏆")
    }

    @Test("firstEmoji extracts emoji and rejects plain text")
    func firstEmojiParsing() {
        #expect("abc😀x".firstEmoji == "😀")
        #expect("👍🏽 ok".firstEmoji == "👍🏽")
        #expect("👨‍👩‍👧".firstEmoji == "👨‍👩‍👧")
        #expect("no emoji".firstEmoji == nil)
        #expect("123".firstEmoji == nil)
    }

    @Test("The color list grows with the optional colors, third requiring a second")
    @MainActor
    func colorList() {
        let palette = ThemeManager.shared.current.light
        let player = Player(name: "Maya", colorHex: "#111111")
        #expect(player.colors(in: palette).count == 1)

        player.colorHex3 = "#333333"
        // A third color without a second doesn't count.
        #expect(player.colors(in: palette).count == 1)

        player.colorHex2 = "#222222"
        #expect(player.colors(in: palette).count == 3)
        #expect(player.colors(in: palette)[1] == Color(hex: "#222222"))
    }
}

// MARK: - Appearance propagation across game nights

@Suite("Appearance propagation")
@MainActor
struct AppearancePropagationTests {

    private func makeContext() throws -> ModelContext {
        let container = try ModelContainer(
            for: Schema([Player.self, PlayerGroup.self]),
            configurations: [ModelConfiguration(isStoredInMemoryOnly: true, cloudKitDatabase: .none)]
        )
        return ModelContext(container)
    }

    @Test("Avatar, extra colors and reactions propagate to synced seats")
    func appearancePropagates() throws {
        let context = try makeContext()
        let source = Roster.add(context, name: "Maya")
        let group = Roster.createGroup(context, name: "Catan")
        let copy = Roster.adopt(context, source: source, into: group)

        source.avatarEmoji = "🦊"
        source.avatarKind = .emoji
        source.colorHex2 = "#222222"
        source.colorHex3 = "#333333"
        source.setReactionEmoji("🏆", for: .success)
        var monogram = PlayerMonogramStyle()
        monogram.text = "MB"
        source.monogramStyle = monogram
        source.timerSoundID = "chime"
        source.timerStyleID = "ring"

        let all = try context.fetch(FetchDescriptor<Player>())
        Roster.propagatePreferences(context, from: source, players: all)

        #expect(copy.avatarKind == .emoji)
        #expect(copy.avatarEmoji == "🦊")
        #expect(copy.colorHex2 == "#222222")
        #expect(copy.colorHex3 == "#333333")
        #expect(copy.reactionEmoji(for: .success) == "🏆")
        #expect(copy.monogramStyle?.text == "MB")
        #expect(copy.timerSoundID == "chime")
        #expect(copy.timerStyleID == "ring")
    }

    @Test("Adopting carries the full appearance into the new game night")
    func adoptCarriesAppearance() throws {
        let context = try makeContext()
        let source = Roster.add(context, name: "Maya")
        source.avatarEmoji = "🐙"
        source.avatarKind = .emoji
        source.colorHex2 = "#ABCDEF"
        source.setReactionEmoji("🎆", for: .celebration)
        source.timerSoundID = "gong"

        let group = Roster.createGroup(context, name: "Catan")
        let copy = Roster.adopt(context, source: source, into: group)

        #expect(copy.avatarKind == .emoji)
        #expect(copy.avatarEmoji == "🐙")
        #expect(copy.colorHex2 == "#ABCDEF")
        #expect(copy.reactionEmoji(for: .celebration) == "🎆")
        #expect(copy.timerSoundID == "gong")
    }

    @Test("Propagating from or to a deleted player is a safe no-op")
    func propagationSkipsDeletedPlayers() throws {
        let context = try makeContext()
        let source = Roster.add(context, name: "Maya")
        let group = Roster.createGroup(context, name: "Catan")
        let copy = Roster.adopt(context, source: source, into: group)

        // Deleted source: nothing happens and nothing traps.
        let all = try context.fetch(FetchDescriptor<Player>())
        Roster.delete(context, player: source)
        Roster.propagatePreferences(context, from: source, players: all)
        #expect(copy.name == "Maya")

        // Deleted copy in the roster snapshot: skipped without touching it.
        let survivor = Roster.adopt(context, source: copy, into: nil)
        let snapshot = try context.fetch(FetchDescriptor<Player>())
        Roster.delete(context, player: survivor)
        copy.name = "Maya B."
        Roster.propagatePreferences(context, from: copy, players: snapshot)
        #expect(copy.name == "Maya B.")
    }

    @Test("An opted-out seat keeps its own look")
    func optOutKeepsLook() throws {
        let context = try makeContext()
        let source = Roster.add(context, name: "Maya")
        let group = Roster.createGroup(context, name: "Catan")
        let copy = Roster.adopt(context, source: source, into: group)
        copy.syncsPreferences = false

        source.avatarEmoji = "🦊"
        source.avatarKind = .emoji
        let all = try context.fetch(FetchDescriptor<Player>())
        Roster.propagatePreferences(context, from: source, players: all)

        #expect(copy.avatarKind == .initial)
        #expect(copy.avatarEmoji == nil)
    }
}
