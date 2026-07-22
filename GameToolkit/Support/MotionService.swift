import Foundation
import CoreGraphics
import Observation
#if canImport(CoreMotion) && os(iOS) && !targetEnvironment(macCatalyst)
import CoreMotion
import UIKit
#endif

/// Publishes the device's gravity direction in screen space as a unit vector, for styles
/// that respond to tilting (snowfall). Reference-counted so several cards can share one
/// CoreMotion session; platforms without an accelerometer just report straight down,
/// which degrades the physics gracefully with no branching at call sites.
@MainActor
@Observable
final class MotionService {
    static let shared = MotionService()

    /// Screen-space gravity; `(0, 1)` is straight down.
    private(set) var gravity = CGVector(dx: 0, dy: 1)

    private var refCount = 0

    private init() {}

    #if canImport(CoreMotion) && os(iOS) && !targetEnvironment(macCatalyst)
    private let manager = CMMotionManager()

    func acquire() {
        refCount += 1
        guard refCount == 1, manager.isDeviceMotionAvailable,
              !ProcessInfo.processInfo.isiOSAppOnMac else { return }
        manager.deviceMotionUpdateInterval = 1 / 30
        manager.startDeviceMotionUpdates(using: .xArbitraryZVertical, to: .main) { [weak self] motion, _ in
            guard let self, let g = motion?.gravity else { return }
            MainActor.assumeIsolated {
                self.ingest(deviceX: g.x, deviceY: g.y)
            }
        }
    }

    func release() {
        refCount = max(0, refCount - 1)
        if refCount == 0 {
            manager.stopDeviceMotionUpdates()
            gravity = CGVector(dx: 0, dy: 1)
        }
    }

    /// Maps device-frame gravity into screen space for the current interface orientation
    /// and applies a light low-pass so flakes don't jitter.
    private func ingest(deviceX: Double, deviceY: Double) {
        let orientation = UIApplication.shared.connectedScenes
            .compactMap { ($0 as? UIWindowScene)?.interfaceOrientation }
            .first ?? .portrait

        var x: Double, y: Double
        switch orientation {
        case .landscapeLeft: (x, y) = (-deviceY, -deviceX)
        case .landscapeRight: (x, y) = (deviceY, deviceX)
        case .portraitUpsideDown: (x, y) = (-deviceX, deviceY)
        default: (x, y) = (deviceX, -deviceY)
        }

        let length = max(0.001, (x * x + y * y).squareRoot())
        let target = CGVector(dx: x / length, dy: y / length)
        let smoothing = 0.15
        gravity = CGVector(dx: gravity.dx + (target.dx - gravity.dx) * smoothing,
                           dy: gravity.dy + (target.dy - gravity.dy) * smoothing)
    }
    #else
    func acquire() {}
    func release() {}
    #endif
}
