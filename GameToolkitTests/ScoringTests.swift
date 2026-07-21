import Testing
import SwiftData
import SwiftUI
@testable import Game_Toolkit

// MARK: - Player score maths

@Suite("Player scoring")
struct PlayerScoringTests {

    @Test("Missing rounds read as zero")
    func missingRoundsAreZero() {
        let player = Player(name: "Avery")
        #expect(player.score(inRound: 0) == 0)
        #expect(player.score(inRound: 9) == 0)
        #expect(player.score(inRound: -1) == 0)
    }

    @Test("Setting a later round pads earlier rounds with zeros")
    func settingLaterRoundPads() {
        let player = Player(name: "Blake")
        player.setScore(12, inRound: 3)
        #expect(player.scores.count == 4)
        #expect(player.scores == [0, 0, 0, 12])
        #expect(player.score(inRound: 3) == 12)
    }

    @Test("Negative round index is ignored")
    func negativeRoundIgnored() {
        let player = Player(name: "Casey")
        player.setScore(5, inRound: -2)
        #expect(player.scores.isEmpty)
    }

    @Test("Total sums every round, including negatives")
    func totalSumsRounds() {
        let player = Player(name: "Devon")
        player.setScore(10, inRound: 0)
        player.setScore(-4, inRound: 1)
        player.setScore(7, inRound: 2)
        #expect(player.total == 13)
    }

    @Test("Overwriting a round replaces rather than appends")
    func overwriteRound() {
        let player = Player(name: "Erin")
        player.setScore(3, inRound: 0)
        player.setScore(8, inRound: 0)
        #expect(player.scores == [8])
        #expect(player.total == 8)
    }
}

// MARK: - Roster operations against a real (in-memory) SwiftData store

@Suite("Roster operations")
@MainActor
struct RosterTests {

    /// A fresh in-memory container so tests never touch the user's real store.
    private func makeContext() throws -> ModelContext {
        let container = try ModelContainer(
            for: Schema([Player.self]),
            configurations: [ModelConfiguration(isStoredInMemoryOnly: true, cloudKitDatabase: .none)]
        )
        return ModelContext(container)
    }

    @Test("Seeding creates two players only when the roster is empty")
    func seedingIsIdempotent() throws {
        let context = try makeContext()
        Roster.seedIfNeeded(context, existing: [])
        let afterFirst = try context.fetch(FetchDescriptor<Player>())
        #expect(afterFirst.count == 2)

        Roster.seedIfNeeded(context, existing: afterFirst)
        let afterSecond = try context.fetch(FetchDescriptor<Player>())
        #expect(afterSecond.count == 2)
    }

    @Test("Added players get distinct palette colors")
    func addedPlayersGetColors() throws {
        let context = try makeContext()
        let first = Roster.add(context)
        let second = Roster.add(context)
        #expect(first.colorHex != second.colorHex)
        #expect(second.sortIndex == 1)
    }

    @Test("Round count reflects the longest score array")
    func roundCountUsesLongest() {
        let a = Player(name: "A")
        let b = Player(name: "B")
        a.setScore(1, inRound: 0)
        b.setScore(1, inRound: 4)
        #expect(Roster.roundCount([a, b]) == 5)
        #expect(Roster.roundCount([]) == 0)
    }

    @Test("Normalizing pads short players and trims long ones")
    func normalizeRounds() throws {
        let context = try makeContext()
        let short = Player(name: "Short")
        let long = Player(name: "Long")
        short.setScore(2, inRound: 0)
        long.setScore(9, inRound: 5)
        context.insert(short)
        context.insert(long)

        Roster.normalizeRounds(context, players: [short, long], to: 3)
        #expect(short.scores.count == 3)
        #expect(long.scores.count == 3)
        #expect(short.scores == [2, 0, 0])
    }

    @Test("Deleting a round removes that column for every player")
    func deleteRound() throws {
        let context = try makeContext()
        let a = Player(name: "A")
        let b = Player(name: "B")
        a.scores = [1, 2, 3]
        b.scores = [4, 5, 6]
        context.insert(a)
        context.insert(b)

        Roster.deleteRound(context, players: [a, b], at: 1)
        #expect(a.scores == [1, 3])
        #expect(b.scores == [4, 6])
    }

    @Test("Deleting an out-of-range round is a no-op")
    func deleteRoundOutOfRange() throws {
        let context = try makeContext()
        let a = Player(name: "A")
        a.scores = [1, 2]
        context.insert(a)

        Roster.deleteRound(context, players: [a], at: 7)
        #expect(a.scores == [1, 2])
    }

    @Test("Resetting scores clears rounds but keeps the roster")
    func resetScores() throws {
        let context = try makeContext()
        let a = Player(name: "A")
        a.scores = [1, 2, 3]
        context.insert(a)

        Roster.resetScores(context, players: [a])
        #expect(a.scores.isEmpty)
        #expect(try context.fetch(FetchDescriptor<Player>()).count == 1)
    }

    @Test("Reordering rewrites sort indexes")
    func reorder() throws {
        let context = try makeContext()
        let a = Roster.add(context, name: "A")
        let b = Roster.add(context, name: "B")
        Roster.reorder(context, players: [b, a])
        #expect(b.sortIndex == 0)
        #expect(a.sortIndex == 1)
    }
}

// MARK: - Formatting and color helpers

@Suite("Formatting helpers")
struct FormattingTests {

    @Test("Seconds format as m:ss", arguments: [
        (0, "0:00"), (5, "0:05"), (59, "0:59"), (60, "1:00"), (90, "1:30"), (600, "10:00"),
    ])
    func clockStrings(seconds: Int, expected: String) {
        #expect(seconds.clockString == expected)
    }

    @Test("Negative durations clamp to zero")
    func negativeClamps() {
        #expect((-30).clockString == "0:00")
    }

    @Test("Countdown rounds up so it shows 0:01 until truly zero")
    func doubleRoundsUp() {
        #expect(0.2.clockString == "0:01")
        #expect(0.0.clockString == "0:00")
        #expect(89.4.clockString == "1:30")
    }

    @Test("Hex colors round-trip")
    func hexRoundTrip() {
        let hex = "#4D96FF"
        #expect(Color(hex: hex).hexString == hex)
    }

    @Test("Short and prefixed hex forms parse")
    func hexForms() {
        #expect(Color(hex: "FFF").hexString == "#FFFFFF")
        #expect(Color(hex: "#000000").hexString == "#000000")
    }

    @Test("Readable foreground flips with background luminance")
    func readableForeground() {
        #expect(Color(hex: "#FFFFFF").readableForeground == .black)
        #expect(Color(hex: "#000000").readableForeground == .white)
    }
}
