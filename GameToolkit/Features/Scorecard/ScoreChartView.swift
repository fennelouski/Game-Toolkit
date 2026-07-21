import SwiftUI
import SwiftData
import Charts

/// Score visualisation — the modern replacement for the old OpenGL graph view.
///
/// Mirrors the original's two modes: everyone's cumulative totals, or one player's
/// round-by-round scores (which the old app revealed with a long press).
struct ScoreChartView: View {
    let players: [Player]

    @Environment(\.palette) private var palette
    @State private var focusedPlayerID: PersistentIdentifier?

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

    private var focusedPlayer: Player? {
        guard let focusedPlayerID else { return nil }
        return players.first { $0.id == focusedPlayerID }
    }

    /// Builds one cumulative series per player, with de-duplicated labels so the color scale
    /// maps correctly even when two players share a name.
    private var series: [Series] {
        var seen: [String: Int] = [:]
        return players.enumerated().map { index, player in
            let base = PiDay.decorate(player.name.isEmpty ? "Player \(index + 1)" : player.name)
            let occurrence = (seen[base] ?? 0) + 1
            seen[base] = occurrence
            let label = occurrence > 1 ? "\(base) (\(occurrence))" : base

            var running = 0
            var points = [Point(round: 0, total: 0)]
            for round in 0..<rounds {
                running += player.score(inRound: round)
                points.append(Point(round: round + 1, total: running))
            }
            return Series(id: index, label: label, color: player.color(in: palette), points: points)
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
                VStack(spacing: 10) {
                    focusPicker
                    if let player = focusedPlayer {
                        individualChart(for: player)
                    } else {
                        cumulativeChart
                    }
                }
            }
        }
    }

    private var focusPicker: some View {
        Menu {
            Button { focusedPlayerID = nil } label: {
                Label("All players", systemImage: focusedPlayerID == nil ? "checkmark" : "person.2")
            }
            Divider()
            ForEach(players) { player in
                Button { focusedPlayerID = player.id } label: {
                    Label(PiDay.decorate(player.name), systemImage: focusedPlayerID == player.id ? "checkmark" : "person")
                }
            }
        } label: {
            HStack(spacing: 6) {
                Image(systemName: "line.3.horizontal.decrease.circle")
                Text(focusedPlayer.map { PiDay.decorate($0.name) } ?? "All players")
                    .fontWeight(.medium)
                Image(systemName: "chevron.down").font(.caption2)
            }
            .font(.subheadline)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var cumulativeChart: some View {
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

    /// One player's per-round scores, so you can see where the points actually came from.
    private func individualChart(for player: Player) -> some View {
        Chart {
            ForEach(0..<rounds, id: \.self) { round in
                BarMark(
                    x: .value("Round", "R\(round + 1)"),
                    y: .value("Score", player.score(inRound: round))
                )
                .foregroundStyle(player.color(in: palette).gradient)
                .cornerRadius(5)
                .annotation(position: .top) {
                    Text("\(player.score(inRound: round))")
                        .font(.caption2.monospacedDigit())
                        .foregroundStyle(.secondary)
                }
            }
            RuleMark(y: .value("Zero", 0))
                .foregroundStyle(.secondary.opacity(0.4))
                .lineStyle(StrokeStyle(lineWidth: 1))
        }
        .chartYAxis { AxisMarks(position: .leading) }
        .padding(12)
        .overlay(alignment: .topTrailing) {
            Text("Total \(player.total)")
                .font(.caption.weight(.semibold))
                .padding(.horizontal, 10).padding(.vertical, 5)
                .background(Capsule().fill(player.color(in: palette).opacity(0.18)))
                .padding(10)
        }
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(.ultraThinMaterial)
        )
    }
}
