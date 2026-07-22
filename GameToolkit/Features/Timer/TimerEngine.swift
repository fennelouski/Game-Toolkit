import SwiftUI
import SwiftData
import Observation

/// Identifies a timer slot: the single shared timer, or one player's timer.
enum TimerSlotID: Hashable {
    case shared
    case player(PersistentIdentifier)
}

/// Something the engine did that the view layer may want to turn into effects
/// (flash, haptics, sound, torch, system alarm). The engine itself has no side effects
/// beyond its own state, which keeps it deterministic and testable.
enum TimerEvent: Equatable {
    case expired(TimerSlotID, next: TimerSlotID?)
    case autoSwitched(from: TimerSlotID, to: TimerSlotID)
    case didAutoReset
}

/// The turn timer state machine. One engine drives all four modes; behavior differences
/// flow from `TimerConfiguration`. Timing is computed from wall-clock deltas so a delayed
/// tick never causes drift — the repeating `Timer` only refreshes the display.
@MainActor
@Observable
final class TimerEngine {
    struct Slot: Identifiable, Equatable {
        let id: TimerSlotID
        var name: String
        var colorHex: String
        /// Accumulated running time in seconds.
        var elapsed: Double
        /// Full budget in seconds; `nil` means count-up (never expires).
        var budget: Double?

        var remaining: Double { max(0, (budget ?? 0) - elapsed) }
        var isFixedLength: Bool { budget != nil }
        var isExpired: Bool {
            guard let budget else { return false }
            return elapsed >= budget
        }
    }

    private(set) var slots: [Slot] = []
    private(set) var activeID: TimerSlotID?
    /// Set while paused; `activeID` is nil but this slot resumes on the next start.
    private(set) var pausedID: TimerSlotID?
    private(set) var expiredID: TimerSlotID?
    private(set) var configuration = TimerConfiguration()

    var isRunning: Bool { activeID != nil }
    var isPaused: Bool { pausedID != nil }

    /// The view layer's hook for effects. Called after the engine's own state settles.
    var onEvent: ((TimerEvent) -> Void)?

    /// The same events, observable: each emission gets a fresh identity so SwiftUI's
    /// `onChange` fires even for two identical events in a row.
    struct StampedEvent: Equatable, Identifiable {
        let id = UUID()
        let event: TimerEvent
    }
    private(set) var lastEvent: StampedEvent?

    /// Injectable clock so tests can advance time without sleeping.
    var now: () -> Date = { Date() }

    private var activeStart: Date?
    private var timer: Timer?
    private var autoResetTask: Task<Void, Never>?
    private var players: [Player] = []

    // MARK: - Configuration & roster

    /// Applies a new configuration. A change of mode, scope, or budget hard-resets the
    /// clocks (the old times are meaningless under the new rules); an unchanged
    /// configuration is a no-op so the view can call this freely.
    func configure(_ config: TimerConfiguration) {
        guard config != configuration else { return }
        let needsRebuild = config.mode != configuration.mode
            || config.scope != configuration.scope
            || config.slotBudget != configuration.slotBudget
        configuration = config
        if needsRebuild {
            stopTicking()
            activeID = nil
            pausedID = nil
            expiredID = nil
            cancelAutoReset()
            rebuildSlots()
        }
    }

    /// Rebuilds slots from the roster, preserving elapsed time for players that still exist.
    func sync(with players: [Player]) {
        self.players = players
        rebuildSlots(preservingElapsed: true)
        if let active = activeID, !slots.contains(where: { $0.id == active }) {
            pauseTicking()
            activeID = nil
            pausedID = nil
        }
    }

    private func rebuildSlots(preservingElapsed: Bool = false) {
        let previous = preservingElapsed ? slots : []
        if configuration.usesSharedSlot {
            let existing = previous.first(where: { $0.id == .shared })
            slots = [Slot(id: .shared, name: "", colorHex: "",
                          elapsed: existing?.elapsed ?? 0,
                          budget: configuration.slotBudget)]
        } else {
            slots = players.map { player in
                let id = TimerSlotID.player(player.persistentModelID)
                let existing = previous.first(where: { $0.id == id })
                return Slot(id: id, name: player.name, colorHex: player.colorHex,
                            elapsed: existing?.elapsed ?? 0,
                            budget: configuration.slotBudget)
            }
        }
    }

    func slot(for id: TimerSlotID) -> Slot? {
        slots.first(where: { $0.id == id })
    }

    /// The slot after `id` in roster order, wrapping. `nil` when there's nowhere to go.
    func nextSlotID(after id: TimerSlotID) -> TimerSlotID? {
        guard slots.count > 1, let index = slots.firstIndex(where: { $0.id == id }) else { return nil }
        return slots[(index + 1) % slots.count].id
    }

    // MARK: - Actions

    /// Handles a tap on a slot. An inactive slot becomes active (chess-clock hand-off);
    /// the active slot either pauses or advances, per the configured tap behavior.
    func handleTap(on id: TimerSlotID) {
        cancelAutoReset()

        if activeID == id {
            switch configuration.tapBehavior {
            case .pause:
                pause()
            case .nextPlayer:
                if let next = nextSlotID(after: id) {
                    activate(next)
                } else {
                    pause()
                }
            }
            return
        }

        if pausedID == id {
            resume()
            return
        }

        activate(id)
    }

    /// Starts (or resumes) the shared/first slot. The single-timer UI's play button.
    func start() {
        if let pausedID { activate(pausedID); return }
        guard let first = slots.first else { return }
        activate(first.id)
    }

    func pause() {
        guard let activeID else { return }
        commit()
        pausedID = activeID
        self.activeID = nil
        pauseTicking()
    }

    func resume() {
        guard let pausedID else { return }
        activate(pausedID)
    }

    /// Advances to the next slot in roster order, keeping the clock running.
    func advanceToNext() {
        guard let activeID, let next = nextSlotID(after: activeID) else { return }
        activate(next)
    }

    /// Resets every slot to a full budget / zero elapsed and stops the clock.
    func reset() {
        stopTicking()
        activeID = nil
        pausedID = nil
        expiredID = nil
        cancelAutoReset()
        for index in slots.indices { slots[index].elapsed = 0 }
        AudioManager.shared.stop()
    }

    private func activate(_ id: TimerSlotID) {
        guard let slot = slot(for: id) else { return }
        guard !slot.isExpired else { return }
        commit()
        expiredID = nil
        AudioManager.shared.stop()
        activeID = id
        pausedID = nil
        activeStart = now()
        startTicking()
    }

    // MARK: - Timing

    /// Folds wall-clock time since `activeStart` into the active slot.
    private func commit() {
        guard let activeID, let start = activeStart,
              let index = slots.firstIndex(where: { $0.id == activeID }) else { return }
        slots[index].elapsed += now().timeIntervalSince(start)
        activeStart = now()
    }

    private func startTicking() {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            MainActor.assumeIsolated { self?.tick() }
        }
    }

    private func pauseTicking() {
        timer?.invalidate()
        timer = nil
        activeStart = nil
    }

    private func stopTicking() {
        pauseTicking()
    }

    /// Advances the active clock. Internal (not private) so tests can drive time by
    /// moving `now` and calling this directly instead of sleeping.
    func tick() {
        guard activeID != nil else { return }
        commit()
        guard let activeID, let slot = slot(for: activeID) else { return }
        guard let budget = slot.budget, slot.elapsed >= budget else { return }

        if configuration.mode == .autoSwitch, let next = nextSlotID(after: activeID) {
            // The turn is over, not the game: reset this slot's per-turn clock and move on.
            if let index = slots.firstIndex(where: { $0.id == activeID }) {
                slots[index].elapsed = 0
            }
            activate(next)
            emit(.autoSwitched(from: activeID, to: next))
        } else {
            expire(activeID)
        }
    }

    private func expire(_ id: TimerSlotID) {
        stopTicking()
        activeID = nil
        pausedID = nil
        if let index = slots.firstIndex(where: { $0.id == id }), let budget = slots[index].budget {
            slots[index].elapsed = budget
        }
        expiredID = id
        emit(.expired(id, next: nextSlotID(after: id)))
        scheduleAutoReset()
    }

    // MARK: - Auto-reset

    private func scheduleAutoReset() {
        cancelAutoReset()
        let delay = configuration.autoResetDelay
        guard delay >= 0 else { return }
        autoResetTask = Task { [weak self] in
            if delay > 0 {
                try? await Task.sleep(for: .seconds(delay))
            }
            guard let self, !Task.isCancelled else { return }
            self.reset()
            self.emit(.didAutoReset)
        }
    }

    private func cancelAutoReset() {
        autoResetTask?.cancel()
        autoResetTask = nil
    }

    private func emit(_ event: TimerEvent) {
        lastEvent = StampedEvent(event: event)
        onEvent?(event)
    }
}
