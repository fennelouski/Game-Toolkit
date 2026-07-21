import SwiftUI
import SwiftData
import Observation

/// A chess-clock style turn timer. Each player has a running budget; tapping a player starts their
/// clock and stops everyone else's. Timing is computed from wall-clock deltas so it never drifts.
@MainActor
@Observable
final class TimerEngine {
    struct Slot: Identifiable {
        let id: PersistentIdentifier
        var name: String
        var colorHex: String
        var remaining: Double
    }

    private(set) var slots: [Slot] = []
    private(set) var activeID: PersistentIdentifier?
    private(set) var expiredID: PersistentIdentifier?
    var isRunning: Bool { activeID != nil }

    var perPlayerSeconds: Double = 90
    var alarmDuration: Double = 3

    private var activeStart: Date?
    private var timer: Timer?

    // MARK: - Roster sync

    /// Rebuilds slots from the roster, preserving remaining time for players that still exist.
    func sync(with players: [Player], defaultSeconds: Double) {
        perPlayerSeconds = defaultSeconds
        let previous = slots
        slots = players.map { player in
            if let existing = previous.first(where: { $0.id == player.persistentModelID }) {
                return Slot(id: player.persistentModelID, name: player.name,
                            colorHex: player.colorHex, remaining: existing.remaining)
            }
            return Slot(id: player.persistentModelID, name: player.name,
                        colorHex: player.colorHex, remaining: defaultSeconds)
        }
        if let active = activeID, !slots.contains(where: { $0.id == active }) {
            stop()
        }
    }

    func remaining(for id: PersistentIdentifier) -> Double {
        slots.first(where: { $0.id == id })?.remaining ?? 0
    }

    // MARK: - Actions

    /// Toggles a player's clock: starts it, or stops it if they were already active.
    func toggle(_ id: PersistentIdentifier) {
        commit()
        expiredID = nil
        AudioManager.shared.stop()

        if activeID == id {
            stop()
            Haptics.impact(.soft)
            return
        }
        guard remaining(for: id) > 0 else { return }
        activeID = id
        activeStart = Date()
        Haptics.impact(.medium)
        startTimer()
    }

    func resetAll(to seconds: Double) {
        perPlayerSeconds = seconds
        for index in slots.indices { slots[index].remaining = seconds }
        stop()
        expiredID = nil
        AudioManager.shared.stop()
        Haptics.impact(.rigid)
    }

    func stop() {
        commit()
        activeID = nil
        activeStart = nil
        timer?.invalidate()
        timer = nil
    }

    // MARK: - Timing

    private func commit() {
        guard let activeID, let start = activeStart,
              let index = slots.firstIndex(where: { $0.id == activeID }) else { return }
        let elapsed = Date().timeIntervalSince(start)
        slots[index].remaining = max(0, slots[index].remaining - elapsed)
        activeStart = Date()
    }

    private func startTimer() {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            MainActor.assumeIsolated { self?.tick() }
        }
    }

    private func tick() {
        guard let activeID, let start = activeStart,
              let index = slots.firstIndex(where: { $0.id == activeID }) else { return }
        let elapsed = Date().timeIntervalSince(start)
        activeStart = Date()
        slots[index].remaining = max(0, slots[index].remaining - elapsed)
        if slots[index].remaining <= 0 {
            expire(activeID)
        }
    }

    private func expire(_ id: PersistentIdentifier) {
        activeID = nil
        activeStart = nil
        timer?.invalidate()
        timer = nil
        expiredID = id
        Haptics.notify(.error)
        AudioManager.shared.playAlarm(for: alarmDuration)
    }
}
