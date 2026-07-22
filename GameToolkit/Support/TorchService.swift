import Foundation
#if os(iOS) && !targetEnvironment(macCatalyst)
import AVFoundation
#endif

/// Blinks the camera flashlight for timer effects. iOS devices with a torch only;
/// everywhere else the calls compile to no-ops, mirroring `Haptics`.
///
/// Torch control needs no camera permission — `NSCameraUsageDescription` is only
/// required for capture sessions.
@MainActor
enum TorchService {
    enum Pattern {
        /// Three quick blinks.
        case expiry
        /// One short blink.
        case turnChange

        var blinks: [(on: Duration, off: Duration)] {
            switch self {
            case .expiry:
                return Array(repeating: (.milliseconds(180), .milliseconds(140)), count: 3)
            case .turnChange:
                return [(.milliseconds(120), .milliseconds(0))]
            }
        }
    }

    #if os(iOS) && !targetEnvironment(macCatalyst)
    private static var task: Task<Void, Never>?

    static var isAvailable: Bool {
        AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back)?.hasTorch ?? false
    }

    static func flash(_ pattern: Pattern) {
        guard let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back),
              device.hasTorch else { return }

        task?.cancel()
        task = Task {
            // Whatever happens — cancellation, a throw mid-pattern — the torch ends off.
            defer { set(device, on: false) }
            for blink in pattern.blinks {
                set(device, on: true)
                try? await Task.sleep(for: blink.on)
                set(device, on: false)
                if Task.isCancelled { return }
                try? await Task.sleep(for: blink.off)
                if Task.isCancelled { return }
            }
        }
    }

    private static func set(_ device: AVCaptureDevice, on: Bool) {
        do {
            try device.lockForConfiguration()
            device.torchMode = on ? .on : .off
            device.unlockForConfiguration()
        } catch {
            // Torch is a nicety; never let it break the app.
        }
    }
    #else
    static var isAvailable: Bool { false }
    static func flash(_ pattern: Pattern) {}
    #endif
}
