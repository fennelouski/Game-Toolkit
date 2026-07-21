import Testing
import SwiftData
@testable import Game_Toolkit

@Suite("Dice engine")
@MainActor
struct DiceEngineTests {

    private func makeEngine(count: Int, sides: Int = 6) -> DiceEngine {
        let engine = DiceEngine()
        engine.configure(count: count, sides: sides)
        return engine
    }

    @Test("Configure matches the requested dice count")
    func configureCount() {
        let engine = makeEngine(count: 5)
        #expect(engine.dice.count == 5)
        engine.configure(count: 2, sides: 6)
        #expect(engine.dice.count == 2)
    }

    @Test("Values always fall within the side count")
    func valuesWithinRange() {
        let engine = makeEngine(count: 12, sides: 20)
        #expect(engine.dice.allSatisfy { (1...20).contains($0.value) })
    }

    @Test("Shrinking the side count re-rolls values that no longer fit")
    func shrinkingSidesClampsValues() {
        let engine = makeEngine(count: 10, sides: 100)
        engine.configure(count: 10, sides: 4)
        #expect(engine.dice.allSatisfy { (1...4).contains($0.value) })
    }

    @Test("Fewer than two sides is not allowed")
    func minimumSides() {
        let engine = makeEngine(count: 1, sides: 1)
        #expect(engine.sides >= 2)
    }

    @Test("Locking a die keeps its value through a roll")
    func lockedDiceKeepValues() async {
        let engine = makeEngine(count: 4)
        let lockedID = engine.dice[0].id
        engine.toggleLock(lockedID)
        let lockedValue = engine.dice[0].value

        engine.roll()
        // Poll rather than sleeping a fixed amount: these suites share the main actor, so a
        // fixed wait is flaky under contention.
        var attempts = 0
        while engine.isRolling && attempts < 200 {
            try? await Task.sleep(nanoseconds: 25_000_000)
            attempts += 1
        }

        #expect(engine.isRolling == false)
        #expect(engine.dice[0].isLocked)
        #expect(engine.dice[0].value == lockedValue)
    }

    @Test("Toggling twice releases the die")
    func toggleReleases() {
        let engine = makeEngine(count: 2)
        let id = engine.dice[0].id
        engine.toggleLock(id)
        #expect(engine.lockedCount == 1)
        engine.toggleLock(id)
        #expect(engine.lockedCount == 0)
    }

    @Test("Unlock all releases every die")
    func unlockAll() {
        let engine = makeEngine(count: 3)
        for die in engine.dice { engine.toggleLock(die.id) }
        #expect(engine.lockedCount == 3)
        #expect(engine.hasUnlockedDice == false)
        engine.unlockAll()
        #expect(engine.lockedCount == 0)
        #expect(engine.hasUnlockedDice)
    }

    @Test("Rolling with every die locked does nothing")
    func rollWithAllLocked() {
        let engine = makeEngine(count: 3)
        for die in engine.dice { engine.toggleLock(die.id) }
        let before = engine.dice.map(\.value)
        engine.roll()
        #expect(engine.isRolling == false)
        #expect(engine.dice.map(\.value) == before)
    }

    @Test("Total sums the current faces")
    func total() {
        let engine = makeEngine(count: 3)
        #expect(engine.total == engine.dice.reduce(0) { $0 + $1.value })
    }
}

@Suite("Dot size scale")
struct DotSizeTests {

    @Test("Named sizes match the original scale", arguments: [
        (-1.0, "Tiny"), (0.0, "Extra-Small"), (1.0, "Small"), (2.0, "Medium"),
        (3.0, "Large"), (4.0, "Extra-Large"), (5.0, "Comically Large"),
    ])
    func names(value: Double, expected: String) {
        #expect(DotSize.name(for: value) == expected)
    }

    @Test("Clamping keeps the pip divisor positive")
    func clamping() {
        #expect((-99.0).clamped(to: DotSize.range) == -1)
        #expect(99.0.clamped(to: DotSize.range) == 5)
    }
}

@Suite("Roster name reset")
@MainActor
struct RosterNameResetTests {

    @Test("Reset renames in sort order and keeps scores")
    func resetNames() throws {
        let container = try ModelContainer(
            for: Schema([Player.self]),
            configurations: [ModelConfiguration(isStoredInMemoryOnly: true, cloudKitDatabase: .none)]
        )
        let context = ModelContext(container)
        let a = Player(name: "Zoe", sortIndex: 1)
        let b = Player(name: "Alex", sortIndex: 0)
        a.scores = [5, 6]
        context.insert(a)
        context.insert(b)

        Roster.resetNames(context, players: [a, b])

        #expect(b.name == "Player 1")
        #expect(a.name == "Player 2")
        #expect(a.scores == [5, 6])
    }
}

@Suite("Pi Day")
struct PiDayTests {

    @Test("Decoration only applies on 14 March")
    func decoration() {
        let result = PiDay.decorate("Player")
        if PiDay.isToday {
            #expect(result == "πlayer")
        } else {
            #expect(result == "Player")
        }
    }

    @Test("Names without P are unchanged either way")
    func noPIsUnchanged() {
        #expect(PiDay.decorate("Zoe") == "Zoe")
    }
}
