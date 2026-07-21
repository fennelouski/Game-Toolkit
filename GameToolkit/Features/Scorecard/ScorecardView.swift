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

    private let roundColumnWidth: CGFloat = 46
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
                modePicker

                switch mode {
                case .table:
                    if rounds == 0 { emptyRounds } else { scorepad }
                case .chart:
                    ScoreChartView(players: players)
                        .padding(.horizontal)
                        .frame(maxHeight: .infinity)
                }

                addRoundButton
                    .padding(.horizontal)
                    .padding(.bottom, 6)
            }
        }
    }

    private var modePicker: some View {
        HStack(spacing: 8) {
            ForEach(Mode.allCases) { candidate in
                SelectableChip(label: candidate.rawValue, isSelected: mode == candidate) {
                    withAnimation(.snappy) { mode = candidate }
                }
            }
            Spacer()
            ThemeSwitcherButton()
        }
        .padding(.horizontal)
    }

    private var emptyRounds: some View {
        VStack(spacing: 10) {
            Spacer()
            Image(systemName: "pencil.and.list.clipboard")
                .font(.system(size: 44))
                .foregroundStyle(palette.textSecondary.opacity(0.6))
            Text("No rounds yet")
                .font(.display(.headline))
                .foregroundStyle(palette.textPrimary)
            Text("Add a round to start tracking scores.")
                .font(.subheadline)
                .foregroundStyle(palette.textSecondary)
            Spacer()
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Scorepad

    /// The paper pad: ruled rows, tabular numerals, a serif totals line. Sized to its
    /// content so the pad ends where the writing ends.
    private var scorepad: some View {
        ScrollView([.horizontal, .vertical]) {
            VStack(spacing: 0) {
                headerRow
                rule(2)
                ForEach(0..<rounds, id: \.self) { round in
                    roundRow(round)
                    if round < rounds - 1 { rule(0.8).opacity(0.5) }
                }
                rule(2)
                totalsRow
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 6)
            .background {
                let shape = RoundedRectangle(cornerRadius: 18, style: .continuous)
                shape
                    .fill(palette.surface)
                    .overlay { shape.strokeBorder(.white.opacity(0.25), lineWidth: 0.8).blendMode(.overlay) }
                    .shadow(color: .black.opacity(0.10), radius: 10, y: 5)
                    .shadow(color: .black.opacity(0.06), radius: 1.5, y: 1)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 4)
            .frame(maxWidth: .infinity)
        }
        .defaultScrollAnchor(.topLeading)
        .scrollBounceBehavior(.basedOnSize, axes: [.horizontal, .vertical])
    }

    /// A horizontal pad rule, drawn in the ink color.
    private func rule(_ height: CGFloat) -> some View {
        Rectangle()
            .fill(palette.textSecondary.opacity(height > 1 ? 0.45 : 0.35))
            .frame(height: height)
    }

    private var headerRow: some View {
        HStack(spacing: 0) {
            Text("#")
                .font(.caption.weight(.bold))
                .foregroundStyle(palette.textSecondary)
                .frame(width: roundColumnWidth, alignment: .leading)

            ForEach(players) { player in
                VStack(spacing: 5) {
                    ZStack {
                        Circle().fill(player.color(in: palette).gradient)
                        Text(String((player.name.isEmpty ? "?" : player.name).prefix(1)).uppercased())
                            .font(.caption2.weight(.bold))
                            .foregroundStyle(player.color(in: palette).readableForeground)
                    }
                    .frame(width: 22, height: 22)
                    Text(PiDay.decorate(player.name.isEmpty ? "—" : player.name))
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(palette.textPrimary)
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
                    .foregroundStyle(palette.textSecondary)
                    .frame(width: roundColumnWidth, alignment: .leading)

                ForEach(players) { player in
                    Text("\(player.score(inRound: round))")
                        .font(.body.weight(.medium))
                        .monospacedDigit()
                        .foregroundStyle(palette.textPrimary)
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
            Text("Σ")
                .font(.display(.subheadline))
                .foregroundStyle(palette.textSecondary)
                .frame(width: roundColumnWidth, alignment: .leading)

            ForEach(players) { player in
                let isLeader = rounds > 0 && player.total == leadingTotal
                VStack(spacing: 1) {
                    if isLeader {
                        Image(systemName: "crown.fill")
                            .font(.caption2)
                            .foregroundStyle(palette.warning)
                    }
                    Text("\(player.total)")
                        .font(.display(.title2))
                        .monospacedDigit()
                        .contentTransition(.numericText())
                }
                .frame(width: playerColumnWidth)
                .foregroundStyle(isLeader ? palette.textPrimary : palette.textSecondary)
            }
        }
        .padding(.vertical, 10)
        .animation(.snappy, value: leadingTotal)
    }

    private var addRoundButton: some View {
        Button {
            Haptics.impact(.light)
            roundEdit = RoundEdit(id: rounds)
        } label: {
            Label("Add Round \(rounds + 1)", systemImage: "plus.circle.fill")
        }
        .buttonStyle(PrimaryButtonStyle())
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
