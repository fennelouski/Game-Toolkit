import Testing
import Foundation
import SwiftData
@testable import Game_Toolkit

@Suite("Timer engine")
@MainActor
struct TimerEngineTests {

    /// An engine with an injected, manually advanced clock and a roster of in-memory players.
    @MainActor
    private final class Harness {
        let engine = TimerEngine()
        let players: [Player]
        let container: ModelContainer
        var currentTime = Date(timeIntervalSinceReferenceDate: 0)
        var events: [TimerEvent] = []

        @MainActor
        init(playerCount: Int, config: TimerConfiguration) throws {
            container = try ModelContainer(
                for: Schema([Player.self]),
                configurations: [ModelConfiguration(isStoredInMemoryOnly: true, cloudKitDatabase: .none)]
            )
            let context = ModelContext(container)
            players = (0..<playerCount).map { Player(name: "Player \($0 + 1)", sortIndex: $0) }
            players.forEach(context.insert)

            engine.now = { [unowned self] in currentTime }
            engine.onEvent = { [unowned self] in events.append($0) }
            engine.configure(config)
            engine.sync(with: players)
        }

        @MainActor
        func advance(_ seconds: Double) {
            currentTime += seconds
            engine.tick()
        }

        @MainActor
        func slotID(_ index: Int) -> TimerSlotID {
            .player(players[index].persistentModelID)
        }
    }

    private func chessConfig(seconds: Double = 90) -> TimerConfiguration {
        TimerConfiguration(mode: .chessClock, chessSeconds: seconds)
    }

    // MARK: - Clock correctness

    @Test("Elapsed time comes from wall-clock deltas")
    func dateDeltaTiming() throws {
        let h = try Harness(playerCount: 2, config: chessConfig())
        h.engine.handleTap(on: h.slotID(0))
        h.advance(5)
        #expect(abs(h.engine.slot(for: h.slotID(0))!.elapsed - 5) < 0.001)
    }

    @Test("Two short commits equal one long one")
    func commitInvariance() throws {
        let h = try Harness(playerCount: 2, config: chessConfig())
        h.engine.handleTap(on: h.slotID(0))
        h.advance(2.5)
        h.advance(2.5)
        let split = h.engine.slot(for: h.slotID(0))!.elapsed

        let h2 = try Harness(playerCount: 2, config: chessConfig())
        h2.engine.handleTap(on: h2.slotID(0))
        h2.advance(5)
        #expect(abs(split - h2.engine.slot(for: h2.slotID(0))!.elapsed) < 0.001)
    }

    // MARK: - Chess clock

    @Test("Tapping another player hands off and freezes the first clock")
    func chessHandOff() throws {
        let h = try Harness(playerCount: 2, config: chessConfig())
        h.engine.handleTap(on: h.slotID(0))
        h.advance(10)
        h.engine.handleTap(on: h.slotID(1))
        h.advance(4)
        #expect(abs(h.engine.slot(for: h.slotID(0))!.elapsed - 10) < 0.001)
        #expect(abs(h.engine.slot(for: h.slotID(1))!.elapsed - 4) < 0.001)
        #expect(h.engine.activeID == h.slotID(1))
    }

    @Test("Tap-to-pause preserves elapsed time and resumes")
    func pauseResume() throws {
        let h = try Harness(playerCount: 2, config: chessConfig())
        h.engine.handleTap(on: h.slotID(0))
        h.advance(10)
        h.engine.handleTap(on: h.slotID(0))   // pause
        #expect(h.engine.isPaused)
        #expect(h.engine.activeID == nil)
        h.currentTime += 100                   // time passes while paused…
        h.engine.tick()
        #expect(abs(h.engine.slot(for: h.slotID(0))!.elapsed - 10) < 0.001)
        h.engine.handleTap(on: h.slotID(0))   // resume
        h.advance(5)
        #expect(abs(h.engine.slot(for: h.slotID(0))!.elapsed - 15) < 0.001)
    }

    @Test("Tap-advances behavior moves to the next player in order and wraps")
    func tapAdvances() throws {
        var config = chessConfig()
        config.tapBehavior = .nextPlayer
        let h = try Harness(playerCount: 3, config: config)
        h.engine.handleTap(on: h.slotID(2))
        h.engine.handleTap(on: h.slotID(2))   // active tap → advances, wraps to 0
        #expect(h.engine.activeID == h.slotID(0))
        h.engine.handleTap(on: h.slotID(0))
        #expect(h.engine.activeID == h.slotID(1))
    }

    @Test("Expiry emits one event, clamps at zero, and blocks reactivation")
    func chessExpiry() throws {
        let h = try Harness(playerCount: 2, config: chessConfig(seconds: 30))
        h.engine.handleTap(on: h.slotID(0))
        h.advance(31)
        let slot = h.engine.slot(for: h.slotID(0))!
        #expect(slot.remaining == 0)
        #expect(slot.isExpired)
        #expect(h.engine.expiredID == h.slotID(0))
        #expect(h.events == [.expired(h.slotID(0), next: h.slotID(1))])

        h.engine.handleTap(on: h.slotID(0))   // expired slot cannot restart
        #expect(h.engine.activeID == nil)

        h.engine.handleTap(on: h.slotID(1))   // others still work
        #expect(h.engine.activeID == h.slotID(1))
        #expect(h.engine.expiredID == nil)
        #expect(h.events.count == 1)
    }

    // MARK: - Countdown & count-up

    @Test("Single countdown uses one shared slot and expires with no next")
    func sharedCountdown() throws {
        let config = TimerConfiguration(mode: .countdown, scope: .single, countdownSeconds: 60)
        let h = try Harness(playerCount: 3, config: config)
        #expect(h.engine.slots.count == 1)
        #expect(h.engine.slots[0].id == .shared)
        h.engine.start()
        h.advance(61)
        #expect(h.events == [.expired(.shared, next: nil)])
    }

    @Test("Count-up never expires and grows monotonically")
    func countUpNeverExpires() throws {
        let config = TimerConfiguration(mode: .countUp, scope: .single)
        let h = try Harness(playerCount: 2, config: config)
        h.engine.start()
        h.advance(10_000)
        #expect(h.engine.slots[0].elapsed >= 10_000)
        #expect(h.engine.slots[0].budget == nil)
        #expect(h.events.isEmpty)
        #expect(h.engine.isRunning)
    }

    @Test("Per-player countdown budgets are independent")
    func perPlayerCountdown() throws {
        let config = TimerConfiguration(mode: .countdown, scope: .perPlayer, countdownSeconds: 60)
        let h = try Harness(playerCount: 2, config: config)
        h.engine.handleTap(on: h.slotID(0))
        h.advance(20)
        h.engine.handleTap(on: h.slotID(1))
        h.advance(5)
        #expect(abs(h.engine.slot(for: h.slotID(0))!.remaining - 40) < 0.001)
        #expect(abs(h.engine.slot(for: h.slotID(1))!.remaining - 55) < 0.001)
    }

    @Test("Sync preserves elapsed for surviving players and stops when the active player leaves")
    func syncPreservesAndStops() throws {
        let h = try Harness(playerCount: 3, config: chessConfig())
        h.engine.handleTap(on: h.slotID(0))
        h.advance(10)
        h.engine.handleTap(on: h.slotID(1))

        h.engine.sync(with: Array(h.players[0...1]))   // drop player 3, keep active player 2
        #expect(abs(h.engine.slot(for: h.slotID(0))!.elapsed - 10) < 0.001)
        #expect(h.engine.activeID == h.slotID(1))

        h.engine.sync(with: [h.players[0]])            // drop the active player
        #expect(h.engine.activeID == nil)
        #expect(abs(h.engine.slot(for: h.slotID(0))!.elapsed - 10) < 0.001)
    }

    // MARK: - Auto-switch

    @Test("Auto-switch resets the turn clock, activates the next player, and wraps")
    func autoSwitch() throws {
        let config = TimerConfiguration(mode: .autoSwitch, autoSwitchSeconds: 10)
        let h = try Harness(playerCount: 2, config: config)
        h.engine.handleTap(on: h.slotID(0))
        h.advance(10.5)
        #expect(h.events == [.autoSwitched(from: h.slotID(0), to: h.slotID(1))])
        #expect(h.engine.activeID == h.slotID(1))
        #expect(h.engine.slot(for: h.slotID(0))!.elapsed == 0)
        #expect(h.engine.isRunning)

        h.advance(10.5)                                // wraps back to player 1
        #expect(h.events.last == .autoSwitched(from: h.slotID(1), to: h.slotID(0)))
        #expect(h.engine.activeID == h.slotID(0))
    }

    // MARK: - Auto-reset

    @Test("Auto-reset with zero delay restores budgets after expiry")
    func autoResetImmediate() async throws {
        var config = chessConfig(seconds: 5)
        config.autoResetDelay = 0
        let h = try Harness(playerCount: 2, config: config)
        h.engine.handleTap(on: h.slotID(0))
        h.advance(6)

        // The reset runs on a Task; poll rather than sleeping a fixed amount.
        var attempts = 0
        while !h.events.contains(.didAutoReset) && attempts < 200 {
            try? await Task.sleep(nanoseconds: 25_000_000)
            attempts += 1
        }
        #expect(h.events.contains(.didAutoReset))
        #expect(h.engine.slot(for: h.slotID(0))!.elapsed == 0)
        #expect(h.engine.expiredID == nil)
    }

    @Test("A tap cancels a pending auto-reset")
    func autoResetCancelledByTap() async throws {
        var config = chessConfig(seconds: 5)
        config.autoResetDelay = 60
        let h = try Harness(playerCount: 2, config: config)
        h.engine.handleTap(on: h.slotID(0))
        h.advance(6)
        h.engine.handleTap(on: h.slotID(1))            // interaction cancels the scheduled reset

        try? await Task.sleep(nanoseconds: 100_000_000)
        #expect(!h.events.contains(.didAutoReset))
        #expect(h.engine.activeID == h.slotID(1))
    }

    @Test("Negative delay never auto-resets")
    func autoResetOff() async throws {
        let h = try Harness(playerCount: 2, config: chessConfig(seconds: 5))
        h.engine.handleTap(on: h.slotID(0))
        h.advance(6)
        try? await Task.sleep(nanoseconds: 100_000_000)
        #expect(!h.events.contains(.didAutoReset))
        #expect(h.engine.expiredID == h.slotID(0))
    }

    // MARK: - Configuration

    @Test("Reconfiguring the mode hard-resets clocks; an identical config is a no-op")
    func reconfigure() throws {
        let h = try Harness(playerCount: 2, config: chessConfig())
        h.engine.handleTap(on: h.slotID(0))
        h.advance(10)

        h.engine.configure(chessConfig())              // identical → nothing changes
        #expect(abs(h.engine.slot(for: h.slotID(0))!.elapsed - 10) < 0.001)
        #expect(h.engine.activeID == h.slotID(0))

        h.engine.configure(TimerConfiguration(mode: .countUp, scope: .perPlayer))
        #expect(h.engine.activeID == nil)
        #expect(h.engine.slots.allSatisfy { $0.elapsed == 0 && $0.budget == nil })
    }
}

@Suite("Timer sounds")
struct TimerSoundTests {

    @Test("The default sound resolves to a bundled file")
    func defaultSoundExists() {
        #expect(TimerSound.default.fileURL != nil)
    }

    @Test("Unknown identifiers fall back to the default")
    func unknownFallsBack() {
        #expect(TimerSound.resolve("not-a-sound") == .default)
        #expect(TimerSound.resolve(nil) == .default)
    }

    @Test("Available sounds all resolve to real files")
    func availableAllResolve() {
        #expect(TimerSound.available.allSatisfy { $0.fileURL != nil })
        #expect(TimerSound.available.contains(.firePager))
    }
}
