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
        let groups = (try? context.fetch(FetchDescriptor<PlayerGroup>())) ?? []
        for group in groups { context.delete(group) }
        UserDefaults.standard.set("", forKey: SettingsKey.activeGroupID)
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

    // MARK: - Game-night gallery demo

    /// `-ui.demoGroups` seeds a shelf of game nights so the masonry gallery (which only
    /// replaces the switcher menu past four tables) can be exercised in a simulator.
    static var demoGroupsEnabled: Bool {
        ProcessInfo.processInfo.arguments.contains("-ui.demoGroups")
    }

    private static let demoGroups: [(name: String, players: [String], rounds: Int)] = [
        ("Catan – Fridays", ["Maya", "Jonah", "Priya", "Diego"], 5),
        ("Family Game Night", ["Mom", "Dad", "Sam", "Alex", "Riley", "Quinn", "Jo", "Bea", "Max"], 3),
        ("Office Lunch Crew", ["Ash", "Blake"], 0),
        ("D&D Tuesdays", ["Rowan", "Ellis", "Noor", "Kit", "Vera"], 12),
        ("Wingspan Wednesdays", ["Petra"], 2),
        ("Cabin Weekend", [], 0),
    ]

    @MainActor
    static func seedDemoGroups(_ context: ModelContext) {
        let existing = (try? context.fetch(FetchDescriptor<PlayerGroup>())) ?? []
        guard existing.isEmpty else { return }
        for (name, players, rounds) in demoGroups {
            let group = Roster.createGroup(context, name: name)
            for player in players {
                let seat = Roster.add(context, name: player, group: group)
                seat.scores = (0..<rounds).map { _ in Int.random(in: 4...18) }
            }
        }
        try? context.save()
    }
}
#endif
