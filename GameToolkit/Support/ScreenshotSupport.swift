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

    private static let cast: [(name: String, colorHex: String, scores: [Int])] = [
        ("Maya",  "#4D96FF", [12, 8, 15, 9, 14]),
        ("Jonah", "#FF6B6B", [9, 14, 7, 16, 11]),
        ("Priya", "#6BCB77", [15, 6, 12, 10, 13]),
        ("Diego", "#FFD93D", [7, 17, 9, 12, 8]),
    ]

    static func seed(_ context: ModelContext, existing: [Player]) {
        // Start from a clean slate so repeated launches stay identical.
        for player in existing { context.delete(player) }
        for (index, entry) in cast.enumerated() {
            let player = Player(name: entry.name, colorHex: entry.colorHex, sortIndex: index)
            player.scores = entry.scores
            context.insert(player)
        }
        try? context.save()
    }
}
#endif
