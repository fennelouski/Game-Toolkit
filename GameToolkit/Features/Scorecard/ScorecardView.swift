import SwiftUI
import SwiftData

struct ScorecardView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.palette) private var palette
    @Query(sort: \Player.sortIndex) private var players: [Player]

    @State private var mode: Mode = ScorecardView.initialMode

    /// Lets the screenshot script open straight to the chart. Release builds always start on the table.
    private static var initialMode: Mode {
        #if DEBUG
        if ProcessInfo.processInfo.arguments.contains("-showChart") { return .chart }
        #endif
        return .table
    }
    @State private var roundEdit: RoundEdit?
    @State private var showResetAlert = false
    @State private var showTurnOrder = false

    private enum Mode: String, CaseIterable, Identifiable {
        case table = "Table"
        case chart = "Chart"
        var id: String { rawValue }
    }

    /// Identifies which round the entry sheet is editing (`id` is the round index).
    private struct RoundEdit: Identifiable { let id: Int }

    private let roundColumnWidth: CGFloat = 54
    private let playerColumnWidth: CGFloat = 92

    private var rounds: Int { Roster.roundCount(players) }
    private var leadingTotal: Int? {
        guard rounds > 0 else { return nil }
        return players.map(\.total).max()
    }

    var body: some View {
        NavigationStack {
            ZStack {
                palette.background.ignoresSafeArea()
                content
            }
            .navigationTitle("Scorecard")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { toolbarContent }
            .sheet(item: $roundEdit) { edit in
                RoundEntrySheet(players: players, round: edit.id) { values in
                    apply(values, toRound: edit.id)
                }
            }
            .sheet(isPresented: $showTurnOrder) {
                TurnOrderSheet(players: players)
                    .presentationDetents([.medium, .large])
            }
            // The original app shuffled the turn order when you shook the scorecard.
            .onShake {
                guard !players.isEmpty else { return }
                showTurnOrder = true
            }
            .alert("Reset all scores?", isPresented: $showResetAlert) {
                Button("Reset", role: .destructive) {
                    Roster.resetScores(context, players: players)
                    Haptics.notify(.warning)
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("This clears every round for all players. The roster is kept.")
            }
        }
    }

    @ViewBuilder
    private var content: some View {
        if players.isEmpty {
            ContentUnavailableView {
                Label("No Players", systemImage: "person.2")
            } description: {
                Text("Add players on the Players tab to start scoring.")
            }
        } else {
            VStack(spacing: 12) {
                Picker("View", selection: $mode) {
                    ForEach(Mode.allCases) { Text($0.rawValue).tag($0) }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)

                switch mode {
                case .table:
                    if rounds == 0 { emptyRounds } else { table }
                case .chart:
                    ScoreChartView(players: players)
                        .padding(.horizontal)
                }

                addRoundButton
                    .padding(.horizontal)
                    .padding(.bottom, 6)
            }
        }
    }

    private var emptyRounds: some View {
        VStack(spacing: 10) {
            Spacer()
            Image(systemName: "list.number")
                .font(.system(size: 44))
                .foregroundStyle(.tertiary)
            Text("No rounds yet")
                .font(.headline)
            Text("Add a round to start tracking scores.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Spacer()
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Table

    private var table: some View {
        ScrollView([.horizontal, .vertical]) {
            VStack(spacing: 0) {
                headerRow
                Divider()
                ForEach(0..<rounds, id: \.self) { round in
                    roundRow(round)
                    Divider().opacity(0.4)
                }
                totalsRow
            }
            .padding(.horizontal, 12)
            .frame(maxWidth: .infinity, alignment: .topLeading)
        }
        .defaultScrollAnchor(.topLeading)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(.ultraThinMaterial)
                .padding(.horizontal, 8)
        )
        .padding(.horizontal, 8)
    }

    private var headerRow: some View {
        HStack(spacing: 0) {
            Text("#")
                .font(.caption.weight(.bold))
                .foregroundStyle(.secondary)
                .frame(width: roundColumnWidth, alignment: .leading)

            ForEach(players) { player in
                VStack(spacing: 4) {
                    Circle()
                        .fill(player.color(in: palette).gradient)
                        .frame(width: 10, height: 10)
                    Text(PiDay.decorate(player.name.isEmpty ? "—" : player.name))
                        .font(.caption.weight(.semibold))
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                }
                .frame(width: playerColumnWidth)
            }
        }
        .padding(.vertical, 10)
    }

    private func roundRow(_ round: Int) -> some View {
        Button {
            Haptics.selection()
            roundEdit = RoundEdit(id: round)
        } label: {
            HStack(spacing: 0) {
                Text("R\(round + 1)")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(.secondary)
                    .frame(width: roundColumnWidth, alignment: .leading)

                ForEach(players) { player in
                    Text("\(player.score(inRound: round))")
                        .font(.body.weight(.medium).monospacedDigit())
                        .foregroundStyle(.primary)
                        .frame(width: playerColumnWidth)
                }
            }
            .padding(.vertical, 11)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .contextMenu {
            Button { roundEdit = RoundEdit(id: round) } label: {
                Label("Edit Round \(round + 1)", systemImage: "pencil")
            }
            Button(role: .destructive) {
                Roster.deleteRound(context, players: players, at: round)
                Haptics.impact(.rigid)
            } label: {
                Label("Delete Round \(round + 1)", systemImage: "trash")
            }
        }
    }

    private var totalsRow: some View {
        HStack(spacing: 0) {
            Image(systemName: "sum")
                .font(.caption.weight(.bold))
                .foregroundStyle(.secondary)
                .frame(width: roundColumnWidth, alignment: .leading)

            ForEach(players) { player in
                let isLeader = rounds > 0 && player.total == leadingTotal
                HStack(spacing: 3) {
                    if isLeader {
                        Image(systemName: "crown.fill")
                            .font(.caption2)
                            .foregroundStyle(.yellow)
                    }
                    Text("\(player.total)")
                        .font(.title3.weight(.heavy).monospacedDigit())
                        .contentTransition(.numericText())
                }
                .frame(width: playerColumnWidth)
                .foregroundStyle(isLeader ? Color.primary : Color.secondary)
            }
        }
        .padding(.vertical, 12)
        .background(Color.accentColor.opacity(0.08))
        .animation(.snappy, value: leadingTotal)
    }

    private var addRoundButton: some View {
        Button {
            Haptics.impact(.light)
            roundEdit = RoundEdit(id: rounds)
        } label: {
            Label("Add Round \(rounds + 1)", systemImage: "plus.circle.fill")
                .font(.headline)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
        }
        .buttonStyle(.borderedProminent)
        .buttonBorderShape(.capsule)
        .controlSize(.large)
    }

    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .topBarTrailing) {
            Menu {
                Button {
                    roundEdit = RoundEdit(id: rounds)
                } label: {
                    Label("Add Round", systemImage: "plus")
                }
                Button {
                    showTurnOrder = true
                } label: {
                    Label("Random Turn Order", systemImage: "shuffle")
                }
                if rounds > 0 {
                    Button(role: .destructive) {
                        Roster.deleteRound(context, players: players, at: rounds - 1)
                        Haptics.impact(.rigid)
                    } label: {
                        Label("Delete Last Round", systemImage: "minus.circle")
                    }
                    Divider()
                    Button(role: .destructive) { showResetAlert = true } label: {
                        Label("Reset All Scores", systemImage: "trash")
                    }
                }
            } label: {
                Label("Options", systemImage: "ellipsis.circle")
            }
        }
    }

    // MARK: - Editing

    private func apply(_ values: [Int], toRound round: Int) {
        for (index, player) in players.enumerated() where index < values.count {
            player.setScore(values[index], inRound: round)
        }
        Roster.normalizeRounds(context, players: players, to: Swift.max(rounds, round + 1))
        Haptics.notify(.success)
    }
}

#Preview {
    ScorecardView()
        .modelContainer(for: Player.self, inMemory: true)
}
