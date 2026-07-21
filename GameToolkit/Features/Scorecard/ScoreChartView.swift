import SwiftUI
import Charts

/// Cumulative score over rounds — the modern replacement for the old OpenGL graph view.
struct ScoreChartView: View {
    let players: [Player]

    private struct Point: Identifiable {
        let id = UUID()
        let round: Int
        let total: Int
    }

    private struct Series: Identifiable {
        let id: Int
        let label: String
        let color: Color
        let points: [Point]
    }

    private var rounds: Int { players.map(\.scores.count).max() ?? 0 }

    /// Builds one cumulative series per player, with de-duplicated labels so the color scale
    /// maps correctly even when two players share a name.
    private var series: [Series] {
        var seen: [String: Int] = [:]
        return players.enumerated().map { index, player in
            let base = player.name.isEmpty ? "Player \(index + 1)" : player.name
            let occurrence = (seen[base] ?? 0) + 1
            seen[base] = occurrence
            let label = occurrence > 1 ? "\(base) (\(occurrence))" : base

            var running = 0
            var points = [Point(round: 0, total: 0)]
            for round in 0..<rounds {
                running += player.score(inRound: round)
                points.append(Point(round: round + 1, total: running))
            }
            return Series(id: index, label: label, color: player.color, points: points)
        }
    }

    var body: some View {
        Group {
            if rounds == 0 {
                ContentUnavailableView {
                    Label("No Data Yet", systemImage: "chart.xyaxis.line")
                } description: {
                    Text("Add a round to see the score chart.")
                }
            } else {
                chart
            }
        }
    }

    private var chart: some View {
        let data = series
        return Chart {
            ForEach(data) { item in
                ForEach(item.points) { point in
                    LineMark(
                        x: .value("Round", point.round),
                        y: .value("Total", point.total)
                    )
                    .foregroundStyle(by: .value("Player", item.label))
                    .interpolationMethod(.catmullRom)
                    .lineStyle(StrokeStyle(lineWidth: 3, lineCap: .round))

                    PointMark(
                        x: .value("Round", point.round),
                        y: .value("Total", point.total)
                    )
                    .foregroundStyle(by: .value("Player", item.label))
                    .symbolSize(40)
                }
            }
        }
        .chartForegroundStyleScale(
            domain: data.map(\.label),
            range: data.map(\.color)
        )
        // A little slack on each end so the first and last round labels aren't clipped.
        .chartXScale(domain: -0.15...(Double(rounds) + 0.15))
        .chartXAxis {
            AxisMarks(values: .stride(by: 1)) { value in
                AxisGridLine()
                AxisValueLabel {
                    if let round = value.as(Int.self) {
                        Text(round == 0 ? "Start" : "R\(round)")
                    }
                }
            }
        }
        .chartYAxis { AxisMarks(position: .leading) }
        .chartLegend(position: .bottom, spacing: 12)
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(.ultraThinMaterial)
        )
    }
}
