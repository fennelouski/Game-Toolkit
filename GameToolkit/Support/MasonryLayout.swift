import SwiftUI

/// A Pinterest-style masonry: each tile drops into the currently shortest column, so tiles
/// of different heights pack tightly instead of aligning to grid rows. Column count adapts
/// to the available width. Used by the game-night gallery.
struct MasonryLayout: Layout {
    /// Columns are added as the width allows, never narrower than this.
    var minColumnWidth: CGFloat = 160
    var spacing: CGFloat = 14

    /// How many columns fit in `width`. At least one, even in absurdly narrow proposals.
    static func columnCount(for width: CGFloat, minColumnWidth: CGFloat, spacing: CGFloat) -> Int {
        guard width > minColumnWidth else { return 1 }
        return max(1, Int((width + spacing) / (minColumnWidth + spacing)))
    }

    /// Which column each tile lands in: always the shortest so far, ties going left.
    /// Pure so the packing behavior is pinned by unit tests.
    static func assignments(for heights: [CGFloat], columns: Int, spacing: CGFloat) -> [Int] {
        guard columns > 0 else { return heights.map { _ in 0 } }
        var columnHeights = [CGFloat](repeating: 0, count: columns)
        return heights.map { height in
            let column = columnHeights.indices.min { columnHeights[$0] < columnHeights[$1] } ?? 0
            columnHeights[column] += height + spacing
            return column
        }
    }

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let width = proposal.width ?? minColumnWidth * 2 + spacing
        let frames = frames(for: subviews, in: width)
        return CGSize(width: width, height: frames.map(\.maxY).max() ?? 0)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        for (frame, subview) in zip(frames(for: subviews, in: bounds.width), subviews) {
            subview.place(at: CGPoint(x: bounds.minX + frame.minX, y: bounds.minY + frame.minY),
                          proposal: ProposedViewSize(width: frame.width, height: frame.height))
        }
    }

    private func frames(for subviews: Subviews, in width: CGFloat) -> [CGRect] {
        let columns = Self.columnCount(for: width, minColumnWidth: minColumnWidth, spacing: spacing)
        let columnWidth = (width - spacing * CGFloat(columns - 1)) / CGFloat(columns)
        let heights = subviews.map {
            $0.sizeThatFits(ProposedViewSize(width: columnWidth, height: nil)).height
        }
        var columnY = [CGFloat](repeating: 0, count: columns)
        return zip(heights, Self.assignments(for: heights, columns: columns, spacing: spacing))
            .map { height, column in
                let frame = CGRect(x: CGFloat(column) * (columnWidth + spacing),
                                   y: columnY[column],
                                   width: columnWidth, height: height)
                columnY[column] += height + spacing
                return frame
            }
    }
}
