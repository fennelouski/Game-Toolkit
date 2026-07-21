import SwiftUI

#if os(iOS)
extension UIDevice {
    static let deviceDidShakeNotification = Notification.Name("GameToolkit.deviceDidShake")
}

extension UIWindow {
    open override func motionEnded(_ motion: UIEvent.EventSubtype, with event: UIEvent?) {
        if motion == .motionShake {
            NotificationCenter.default.post(name: UIDevice.deviceDidShakeNotification, object: nil)
        }
        super.motionEnded(motion, with: event)
    }
}

private struct ShakeDetector: ViewModifier {
    let action: () -> Void
    func body(content: Content) -> some View {
        content.onReceive(NotificationCenter.default.publisher(for: UIDevice.deviceDidShakeNotification)) { _ in
            action()
        }
    }
}
#endif

extension View {
    /// Runs `action` whenever the device is shaken while this view is on screen.
    ///
    /// Only iPhone and iPad can be shaken; on Mac and Vision Pro this is a no-op, so every
    /// shake-triggered feature also has a button or menu item.
    func onShake(perform action: @escaping () -> Void) -> some View {
        #if os(iOS)
        return modifier(ShakeDetector(action: action))
        #else
        return self
        #endif
    }
}
