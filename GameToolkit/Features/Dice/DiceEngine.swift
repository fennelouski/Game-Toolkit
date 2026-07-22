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
        var sides: Int = 6
        /// Custom colors from a dice-bag spec; `nil` follows the theme/settings.
        var faceHex: String? = nil
        var pipHex: String? = nil
        /// Bumps each time this die is thrown; the view keys its tumble animation off it.
        var rollTrigger: Int = 0
        /// Fresh randomness for each throw so every tumble takes a different path.
        var tumbleSeed: UInt64 = 0
        var isLocked = false
    }

    private(set) var dice: [Die] = []
    /// The uniform side count used by the classic d4…d100 chips. Bags may mix sides
    /// per die; check `Die.sides` when rendering.
    private(set) var sides: Int = 6
    private(set) var isRolling = false
    /// Bumps on every roll so views can trigger a bounce animation.
    private(set) var rollID = 0
    /// Non-nil while a dice bag is loaded; used to skip redundant reconfigures.
    private var loadedBagSpecs: [DieSpec]? = nil

    var total: Int { dice.reduce(0) { $0 + $1.value } }
    var lockedCount: Int { dice.filter(\.isLocked).count }
    var hasUnlockedDice: Bool { dice.contains { !$0.isLocked } }

    /// Matches the dice array to the requested count and uniform side count.
    func configure(count: Int, sides: Int) {
        self.sides = max(2, sides)
        loadedBagSpecs = nil
        if dice.count < count {
            dice.append(contentsOf: (dice.count..<count).map { _ in
                Die(value: Int.random(in: 1...self.sides), sides: self.sides)
            })
        } else if dice.count > count {
            dice.removeLast(dice.count - count)
        }
        for index in dice.indices {
            dice[index].sides = self.sides
            dice[index].faceHex = nil
            dice[index].pipHex = nil
            if dice[index].value > self.sides {
                dice[index].value = Int.random(in: 1...self.sides)
            }
        }
    }

    /// Loads a dice bag: an ordered set of dice with their own side counts and
    /// colors. Reloading the same bag is a no-op so tab switches keep held dice.
    func configure(bag specs: [DieSpec]) {
        guard specs != loadedBagSpecs else { return }
        loadedBagSpecs = specs
        dice = specs.map { spec in
            let sides = max(2, spec.sides)
            return Die(
                value: Int.random(in: 1...sides),
                sides: sides,
                faceHex: spec.faceHex,
                pipHex: spec.pipHex
            )
        }
        sides = specs.first.map { max(2, $0.sides) } ?? 6
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
            dice[index].tumbleSeed = UInt64.random(in: UInt64.min...UInt64.max)
            dice[index].rollTrigger += 1
            // The result is decided the moment the die leaves the hand: the landing
            // face carries its final value through the whole tumble, so no visible
            // face ever changes mid-roll. (The UI hides the total until settled.)
            dice[index].value = Int.random(in: 1...dice[index].sides)
        }

        Task { @MainActor in
            // Tactile bounce ticks that decay as the dice shed energy. `isRolling`
            // holds until the slowest tumble has settled (~1.4s in DieTrajectory).
            for tick in 0..<12 {
                Haptics.impact(.light, intensity: max(0.15, 0.5 - Double(tick) * 0.03))
                try? await Task.sleep(nanoseconds: UInt64(60_000_000 + tick * 8_000_000))
            }
            try? await Task.sleep(nanoseconds: 200_000_000)
            isRolling = false
            Haptics.notify(.success)
        }
    }
}
