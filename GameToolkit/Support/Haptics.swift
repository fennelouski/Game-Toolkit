import UIKit

/// Thin wrapper around UIKit feedback generators, gated by the user's haptics preference.
enum Haptics {
    private static var enabled: Bool {
        // Defaults to true when the key has never been set.
        UserDefaults.standard.object(forKey: SettingsKey.hapticsEnabled) as? Bool ?? true
    }

    static func impact(_ style: UIImpactFeedbackGenerator.FeedbackStyle = .medium, intensity: CGFloat = 1.0) {
        guard enabled else { return }
        let generator = UIImpactFeedbackGenerator(style: style)
        generator.impactOccurred(intensity: intensity)
    }

    static func selection() {
        guard enabled else { return }
        UISelectionFeedbackGenerator().selectionChanged()
    }

    static func notify(_ type: UINotificationFeedbackGenerator.FeedbackType) {
        guard enabled else { return }
        UINotificationFeedbackGenerator().notificationOccurred(type)
    }
}
