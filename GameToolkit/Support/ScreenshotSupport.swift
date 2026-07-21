#if DEBUG
import Foundation
import SwiftData

/// Populates a believable roster and score history for App Store screenshots.
///
/// Compiled only into Debug builds, so it can never reach the App Store. Enable it by launching
/// with `-screenshotMode`, e.g.
/// `xcrun simctl launch <device> com.nathanfennel.Game-Toolkit -screenshotMode -ui.selectedTab 2`
enum ScreenshotSupport {
    static var isEnabled: Bool {
        ProcessInfo.processInfo.arguments.contains("-screenshotMode")
    }

    private static let cast: [(name: String, scores: [Int])] = [
        ("Maya",  [12, 8, 15, 9, 14]),
        ("Jonah", [9, 14, 7, 16, 11]),
        ("Priya", [15, 6, 12, 10, 13]),
        ("Diego", [7, 17, 9, 12, 8]),
    ]

    @MainActor
    static func seed(_ context: ModelContext, existing: [Player]) {
        // Start from a clean slate so repeated launches stay identical.
        for player in existing { context.delete(player) }
        let palette = ThemeManager.shared.current.light
        for (index, entry) in cast.enumerated() {
            let player = Player(name: entry.name,
                                colorHex: palette.playerHex(index),
                                paletteIndex: index,
                                sortIndex: index)
            player.scores = entry.scores
            context.insert(player)
        }
        try? context.save()
    }
}
#endif
