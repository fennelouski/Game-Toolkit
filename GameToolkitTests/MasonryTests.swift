import Testing
import Foundation
@testable import Game_Toolkit

// MARK: - Masonry packing (game-night gallery)

@Suite("Masonry layout")
struct MasonryLayoutTests {

    @Test("Each tile lands in the shortest column, ties going left")
    func shortestColumnWins() {
        // Columns after each step (spacing 0 for readable arithmetic):
        // 30→col0 [30,0], 10→col1 [30,10], 10→col1 [30,20], 10→col1 [30,30], tie→col0.
        let columns = MasonryLayout.assignments(for: [30, 10, 10, 10, 10], columns: 2, spacing: 0)
        #expect(columns == [0, 1, 1, 1, 0])
    }

    @Test("Equal tiles alternate across columns")
    func equalTilesBalance() {
        let columns = MasonryLayout.assignments(for: [50, 50, 50, 50], columns: 2, spacing: 14)
        #expect(columns == [0, 1, 0, 1])
    }

    @Test("Spacing counts toward a column's running height")
    func spacingCounts() {
        // The left column holds two 10-point tiles; with 10 points of spacing after each
        // it stands at 40 against the right's 35, so the last tile goes right. With no
        // spacing the left column (20) is shorter and keeps it.
        #expect(MasonryLayout.assignments(for: [10, 25, 10, 5], columns: 2, spacing: 10) == [0, 1, 0, 1])
        #expect(MasonryLayout.assignments(for: [10, 25, 10, 5], columns: 2, spacing: 0) == [0, 1, 0, 0])
    }

    @Test("A single column takes everything in order")
    func singleColumn() {
        let columns = MasonryLayout.assignments(for: [10, 200, 30], columns: 1, spacing: 14)
        #expect(columns == [0, 0, 0])
    }

    @Test("Empty input and zero columns don't trap")
    func degenerateInputs() {
        #expect(MasonryLayout.assignments(for: [], columns: 2, spacing: 14).isEmpty)
        #expect(MasonryLayout.assignments(for: [10, 10], columns: 0, spacing: 14) == [0, 0])
    }

    @Test("Column count grows with width and never drops below one")
    func columnCounts() {
        // Narrower than one column still renders (a single squeezed column).
        #expect(MasonryLayout.columnCount(for: 100, minColumnWidth: 160, spacing: 14) == 1)
        // A phone-width sheet fits two columns…
        #expect(MasonryLayout.columnCount(for: 360, minColumnWidth: 160, spacing: 14) == 2)
        // …and an iPad-width one fits four.
        #expect(MasonryLayout.columnCount(for: 700, minColumnWidth: 160, spacing: 14) == 4)
    }
}
