#if os(iOS)
import UIKit
#endif
import Foundation

/// Thin wrapper around UIKit feedback generators, gated by the user's haptics preference.
///
/// Feedback generators only exist on iOS (including Mac Catalyst, where they are harmless
/// no-ops). On visionOS every call compiles away to nothing.
enum Haptics {
    private static var enabled: Bool {
        // Defaults to true when the key has never been set.
        UserDefaults.standard.object(forKey: SettingsKey.hapticsEnabled) as? Bool ?? true
    }

    #if os(iOS)
    static func impact(_ style: UIImpactFeedbackGenerator.FeedbackStyle = .medium, intensity: CGFloat = 1.0) {
        guard enabled else { return }
        UIImpactFeedbackGenerator(style: style).impactOccurred(intensity: intensity)
    }

    static func selection() {
        guard enabled else { return }
        UISelectionFeedbackGenerator().selectionChanged()
    }

    static func notify(_ type: UINotificationFeedbackGenerator.FeedbackType) {
        guard enabled else { return }
        UINotificationFeedbackGenerator().notificationOccurred(type)
    }
    #else
    /// Platform-neutral stand-ins so call sites don't need `#if` at every use.
    enum FeedbackStyle { case light, medium, heavy, soft, rigid }
    enum FeedbackType { case success, warning, error }

    static func impact(_ style: FeedbackStyle = .medium, intensity: Double = 1.0) {}
    static func selection() {}
    static func notify(_ type: FeedbackType) {}
    #endif
}
