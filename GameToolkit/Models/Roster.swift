import Foundation
import SwiftData

/// Roster-level operations shared by the Players, Timer and Scorecard screens.
enum Roster {
    /// Ensures at least two players exist the first time the app runs.
    static func seedIfNeeded(_ context: ModelContext, existing: [Player]) {
        guard existing.isEmpty else { return }
        add(context, name: "Player 1")
        add(context, name: "Player 2")
    }

    @discardableResult
    static func add(_ context: ModelContext, name: String? = nil) -> Player {
        let count = (try? context.fetchCount(FetchDescriptor<Player>())) ?? 0
        let player = Player(
            name: name ?? "Player \(count + 1)",
            colorHex: Theme.nextPlayerColor(existingCount: count),
            sortIndex: count
        )
        context.insert(player)
        try? context.save()
        return player
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
}
