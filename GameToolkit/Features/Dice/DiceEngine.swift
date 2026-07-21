import SwiftUI
import Observation

/// Holds the current dice and performs an animated "tumble" roll.
///
/// Individual dice can be locked (held back) so they keep their value across rolls — the
/// behaviour games like Yahtzee and Farkle depend on.
@MainActor
@Observable
final class DiceEngine {
    struct Die: Identifiable {
        let id = UUID()
        var value: Int
        var spin: Double = 0
        var isLocked = false
    }

    private(set) var dice: [Die] = []
    private(set) var sides: Int = 6
    private(set) var isRolling = false
    /// Bumps on every roll so views can trigger a bounce animation.
    private(set) var rollID = 0

    var total: Int { dice.reduce(0) { $0 + $1.value } }
    var lockedCount: Int { dice.filter(\.isLocked).count }
    var hasUnlockedDice: Bool { dice.contains { !$0.isLocked } }

    /// Matches the dice array to the requested count and side count.
    func configure(count: Int, sides: Int) {
        self.sides = max(2, sides)
        if dice.count < count {
            dice.append(contentsOf: (dice.count..<count).map { _ in Die(value: Int.random(in: 1...self.sides)) })
        } else if dice.count > count {
            dice.removeLast(dice.count - count)
        }
        for index in dice.indices where dice[index].value > self.sides {
            dice[index].value = Int.random(in: 1...self.sides)
        }
    }

    /// Locks or unlocks a single die so it is kept out of (or returned to) the next roll.
    func toggleLock(_ id: Die.ID) {
        guard let index = dice.firstIndex(where: { $0.id == id }) else { return }
        dice[index].isLocked.toggle()
        Haptics.impact(dice[index].isLocked ? .rigid : .soft)
    }

    func unlockAll() {
        guard lockedCount > 0 else { return }
        for index in dice.indices { dice[index].isLocked = false }
        Haptics.impact(.soft)
    }

    func roll() {
        guard !isRolling, hasUnlockedDice else { return }
        isRolling = true
        rollID += 1
        Haptics.impact(.rigid)

        let rolling = dice.indices.filter { !dice[$0].isLocked }
        for index in rolling {
            dice[index].spin += Double([2, 3, 4].randomElement() ?? 3) * 360
        }

        Task { @MainActor in
            // Rapidly flip faces so the dice appear to tumble, then settle.
            for _ in 0..<6 {
                for index in rolling where index < dice.count {
                    dice[index].value = Int.random(in: 1...sides)
                }
                Haptics.impact(.light, intensity: 0.4)
                try? await Task.sleep(nanoseconds: 55_000_000)
            }
            for index in rolling where index < dice.count {
                dice[index].value = Int.random(in: 1...sides)
            }
            isRolling = false
            Haptics.notify(.success)
        }
    }
}
