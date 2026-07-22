import SwiftUI
import Observation
#if canImport(CoreMotion)
import CoreMotion
#endif

/// Publishes a small, smoothed device tilt so the dice can lean and drift as the
/// phone moves in the hand.
///
/// The baseline attitude continually drifts toward the current one, so the effect
/// responds to *movement* and glides back to rest at whatever angle the phone is
/// held — the dice never sit permanently askew because someone plays lying down.
///
/// On hardware without motion sensors (Mac Catalyst, simulators) `start()` is a
/// no-op and both outputs stay at zero, so callers need no platform guards.
@MainActor
@Observable
final class MotionTiltMonitor {
    /// Fore/aft lean in degrees, clamped to ±`maxTilt`.
    private(set) var pitchDegrees: Double = 0
    /// Left/right lean in degrees, clamped to ±`maxTilt`.
    private(set) var rollDegrees: Double = 0

    private static let maxTilt = 7.0

    #if canImport(CoreMotion)
    @ObservationIgnored private let manager = CMMotionManager()
    @ObservationIgnored private var baseline: (pitch: Double, roll: Double)?

    func start() {
        guard manager.isDeviceMotionAvailable, !manager.isDeviceMotionActive else { return }
        manager.deviceMotionUpdateInterval = 1.0 / 30.0
        manager.startDeviceMotionUpdates(to: .main) { motion, _ in
            guard let motion else { return }
            // The update queue is OperationQueue.main, so this runs on the main actor.
            MainActor.assumeIsolated {
                self.ingest(motion.attitude)
            }
        }
    }

    func stop() {
        guard manager.isDeviceMotionActive else { return }
        manager.stopDeviceMotionUpdates()
        baseline = nil
        pitchDegrees = 0
        rollDegrees = 0
    }

    private func ingest(_ attitude: CMAttitude) {
        var base = baseline ?? (attitude.pitch, attitude.roll)
        base.pitch += (attitude.pitch - base.pitch) * 0.04
        base.roll += (attitude.roll - base.roll) * 0.04
        baseline = base

        let targetPitch = ((attitude.pitch - base.pitch) * 180 / .pi)
            .clamped(to: -Self.maxTilt...Self.maxTilt)
        let targetRoll = ((attitude.roll - base.roll) * 180 / .pi)
            .clamped(to: -Self.maxTilt...Self.maxTilt)

        // Ease toward the target and ignore sub-visible jitter so a phone resting
        // on a table doesn't keep the view re-rendering.
        let newPitch = pitchDegrees + (targetPitch - pitchDegrees) * 0.35
        let newRoll = rollDegrees + (targetRoll - rollDegrees) * 0.35
        if abs(newPitch - pitchDegrees) > 0.03 { pitchDegrees = newPitch }
        if abs(newRoll - rollDegrees) > 0.03 { rollDegrees = newRoll }
    }
    #else
    func start() {}
    func stop() {}
    #endif
}
