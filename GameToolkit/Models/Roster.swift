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
    static func add(_ context: ModelContext, name: String? = nil) -> Player {
        let count = (try? context.fetchCount(FetchDescriptor<Player>())) ?? 0
        let palette = ThemeManager.shared.current.light
        let player = Player(
            name: name ?? "Player \(count + 1)",
            // The hex is a snapshot for older app versions sharing the CloudKit store;
            // this version renders from paletteIndex.
            colorHex: palette.playerHex(count),
            paletteIndex: count,
            sortIndex: count
        )
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
