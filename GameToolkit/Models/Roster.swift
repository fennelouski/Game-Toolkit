import Foundation
import SwiftData

/// Roster-level operations shared by the Players, Timer and Scorecard screens.
enum Roster {
    /// Ensures at least two players exist the first time the app runs.
    @MainActor
    static func seedIfNeeded(_ context: ModelContext, existing: [Player]) {
        guard existing.isEmpty else { return }
        add(context, name: "Player 1")
        add(context, name: "Player 2")
    }

    @discardableResult
    @MainActor
    static func add(_ context: ModelContext, name: String? = nil, group: PlayerGroup? = nil) -> Player {
        let all = (try? context.fetch(FetchDescriptor<Player>())) ?? []
        // Numbering, colors and sort order are all scoped to the game night the seat is
        // added to, so every table starts at "Player 1" with the first palette color.
        let count = members(all, inGroup: key(for: group)).count
        let palette = ThemeManager.shared.current.light
        let player = Player(
            name: name ?? "Player \(count + 1)",
            // The hex is a snapshot for older app versions sharing the CloudKit store;
            // this version renders from paletteIndex.
            colorHex: palette.playerHex(count),
            paletteIndex: count,
            sortIndex: count
        )
        player.group = group
        context.insert(player)
        try? context.save()
        return player
    }

    /// One-time migration: players created before themes existed carry a hex from the old
    /// built-in palette. Map those onto palette ordinals so the roster follows the theme;
    /// anything else is treated as a deliberate custom color and left alone.
    static func adoptPaletteIndices(_ context: ModelContext, players: [Player]) {
        var changed = false
        for player in players where player.paletteIndex == nil {
            if let index = Theme.legacyPlayerPalette.firstIndex(where: {
                $0.caseInsensitiveCompare(player.colorHex) == .orderedSame
            }) {
                player.paletteIndex = index
                changed = true
            }
        }
        if changed { try? context.save() }
    }

    static func delete(_ context: ModelContext, player: Player) {
        context.delete(player)
        try? context.save()
    }

    /// Re-writes `sortIndex` to match the given order.
    static func reorder(_ context: ModelContext, players: [Player]) {
        for (index, player) in players.enumerated() {
            player.sortIndex = index
        }
        try? context.save()
    }

    // MARK: - Game nights

    /// The name shown for the built-in table (`Player.group == nil`).
    static let defaultGroupName = "Game Night"

    /// The string stored in `SettingsKey.activeGroupID`; the empty string is the built-in table.
    static func key(for group: PlayerGroup?) -> String {
        group.map(\.groupID.uuidString) ?? ""
    }

    /// Everyone seated at the given game night, in roster order.
    static func members(_ players: [Player], inGroup key: String) -> [Player] {
        players
            .filter { self.key(for: $0.group) == key }
            .sorted { $0.sortIndex < $1.sortIndex }
    }

    /// The members who are actually playing tonight — what the timer and scorecard run on.
    static func playing(_ players: [Player], inGroup key: String) -> [Player] {
        members(players, inGroup: key).filter { !$0.isSittingOut }
    }

    @discardableResult
    @MainActor
    static func createGroup(_ context: ModelContext, name: String) -> PlayerGroup {
        let group = PlayerGroup(name: name)
        context.insert(group)
        try? context.save()
        return group
    }

    /// Deletes a game night and its seats (cascade). Copies of those people in other game
    /// nights are separate rows and survive.
    @MainActor
    static func deleteGroup(_ context: ModelContext, group: PlayerGroup) {
        context.delete(group)
        try? context.save()
    }

    /// Copies an existing person into another game night, carrying their name, color and
    /// sync preference. Scores start fresh — they belong to the table, not the person.
    @discardableResult
    @MainActor
    static func adopt(_ context: ModelContext, source: Player, into group: PlayerGroup?) -> Player {
        // First copy: mint the shared identity that ties the person's seats together.
        if source.personID == nil { source.personID = UUID() }
        let all = (try? context.fetch(FetchDescriptor<Player>())) ?? []
        let copy = Player(
            name: source.name,
            colorHex: source.colorHex,
            paletteIndex: source.paletteIndex,
            sortIndex: members(all, inGroup: key(for: group)).count
        )
        _ = copyAppearance(of: source, to: copy)
        copy.personID = source.personID
        copy.syncsPreferences = source.syncsPreferences
        copy.group = group
        context.insert(copy)
        try? context.save()
        return copy
    }

    /// Pushes an edited player's name and appearance (colors, avatar, reaction emoji) to
    /// that person's seats in other game nights. Seats that opted out of syncing are left
    /// alone, and an opted-out player pushes nothing.
    static func propagatePreferences(_ context: ModelContext, from player: Player, players: [Player]) {
        // The editor calls this on dismiss; by then the player (or a copy) can already be
        // deleted, and touching a deleted model's properties traps in SwiftData.
        guard !player.isDeleted, player.modelContext != nil else { return }
        guard player.syncsPreferences, let personID = player.personID else { return }
        var changed = false
        for copy in players
        where !copy.isDeleted
            && copy.persistentModelID != player.persistentModelID
            && copy.personID == personID
            && copy.syncsPreferences {
            if copyAppearance(of: player, to: copy) { changed = true }
        }
        if changed { try? context.save() }
    }

    /// Mirrors every synced preference field; returns whether anything actually changed.
    private static func copyAppearance(of player: Player, to copy: Player) -> Bool {
        var changed = false
        func sync<Value: Equatable>(_ keyPath: ReferenceWritableKeyPath<Player, Value>) {
            if copy[keyPath: keyPath] != player[keyPath: keyPath] {
                copy[keyPath: keyPath] = player[keyPath: keyPath]
                changed = true
            }
        }
        sync(\.name)
        sync(\.colorHex)
        sync(\.paletteIndex)
        sync(\.colorHex2)
        sync(\.colorHex3)
        sync(\.avatarKindRaw)
        sync(\.avatarImageData)
        sync(\.avatarEmoji)
        sync(\.monogramData)
        sync(\.reactionEmojiData)
        sync(\.timerSoundID)
        sync(\.timerStyleID)
        return changed
    }

    /// People who could be added to the given game night: one entry per distinct person,
    /// skipping anyone already seated there. Pass `nil` to list everyone (new group flow).
    static func candidates(_ players: [Player], excludingGroup key: String?) -> [Player] {
        let currentMembers = key.map { members(players, inGroup: $0) } ?? []
        let memberIDs = Set(currentMembers.map(\.persistentModelID))
        let memberPersonIDs = Set(currentMembers.compactMap(\.personID))
        var seenPersons = Set<UUID>()
        var result: [Player] = []
        // Newest copy first so the deduplicated entry reflects the latest edits even when
        // an older copy opted out of syncing.
        for player in players.sorted(by: { $0.createdAt > $1.createdAt }) {
            if memberIDs.contains(player.persistentModelID) { continue }
            if let personID = player.personID {
                if memberPersonIDs.contains(personID) || seenPersons.contains(personID) { continue }
                seenPersons.insert(personID)
            }
            result.append(player)
        }
        return result.sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
    }

    // MARK: - Scorecard rounds

    static func roundCount(_ players: [Player]) -> Int {
        players.map(\.scores.count).max() ?? 0
    }

    /// Pads every player's score array so they all have `count` rounds.
    static func normalizeRounds(_ context: ModelContext, players: [Player], to count: Int) {
        for player in players {
            while player.scores.count < count { player.scores.append(0) }
            if player.scores.count > count { player.scores.removeLast(player.scores.count - count) }
        }
        try? context.save()
    }

    /// Removes a round column from every player.
    static func deleteRound(_ context: ModelContext, players: [Player], at round: Int) {
        for player in players where round < player.scores.count {
            player.scores.remove(at: round)
        }
        try? context.save()
    }

    /// Clears all recorded scores while keeping the roster intact.
    static func resetScores(_ context: ModelContext, players: [Player]) {
        for player in players { player.scores = [] }
        try? context.save()
    }

    /// Renames everyone back to "Player 1", "Player 2", ... keeping scores and colors.
    static func resetNames(_ context: ModelContext, players: [Player]) {
        for (index, player) in players.sorted(by: { $0.sortIndex < $1.sortIndex }).enumerated() {
            player.name = "Player \(index + 1)"
        }
        try? context.save()
    }
}
