import SwiftUI
import SwiftData

struct PlayersView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.palette) private var palette
    @Query(sort: \Player.sortIndex) private var players: [Player]
    @State private var editing: Player?

    private var rounds: Int { Roster.roundCount(players) }
    private var leadingTotal: Int? {
        guard rounds > 0 else { return nil }
        return players.map(\.total).max()
    }

    var body: some View {
        NavigationStack {
            Group {
                if players.isEmpty {
                    ContentUnavailableView {
                        Label("No Players", systemImage: "person.2")
                    } description: {
                        Text("Add players to use the timer and scorecard.")
                    } actions: {
                        Button("Add Player") { editing = Roster.add(context) }
                            .buttonStyle(.borderedProminent)
                    }
                } else {
                    List {
                        ForEach(players) { player in
                            Button { editing = player } label: { row(player) }
                                .buttonStyle(.plain)
                                .listRowBackground(palette.surface)
                                .listRowSeparatorTint(palette.textSecondary.opacity(0.25))
                        }
                        .onDelete(perform: delete)
                        .onMove(perform: move)
                    }
                    .scrollContentBackground(.hidden)
                }
            }
            .background(palette.background.ignoresSafeArea())
            .navigationTitle("Players")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    if !players.isEmpty { EditButton() }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        Haptics.impact(.light)
                        editing = Roster.add(context)
                    } label: {
                        Label("Add Player", systemImage: "plus")
                    }
                }
            }
            .sheet(item: $editing) { player in
                PlayerEditorSheet(player: player)
            }
        }
    }

    private func row(_ player: Player) -> some View {
        let color = player.color(in: palette)
        let isLeader = rounds > 0 && player.total == leadingTotal
        return HStack(spacing: 14) {
            ZStack {
                Circle().fill(color.gradient)
                Text(String((player.name.isEmpty ? "?" : player.name).prefix(1)).uppercased())
                    .font(.display(.headline))
                    .foregroundStyle(color.readableForeground)
            }
            .frame(width: 40, height: 40)

            VStack(alignment: .leading, spacing: 2) {
                Text(PiDay.decorate(player.name.isEmpty ? "Unnamed" : player.name))
                    .font(.headline)
                    .foregroundStyle(palette.textPrimary)
                Text("\(player.total) pts · \(player.scores.count) rounds")
                    .font(.caption)
                    .foregroundStyle(palette.textSecondary)
            }
            Spacer()
            if isLeader {
                Image(systemName: "crown.fill")
                    .font(.subheadline)
                    .foregroundStyle(palette.warning)
                    .accessibilityLabel("Current leader")
            }
            Image(systemName: "chevron.right")
                .font(.caption.weight(.bold))
                .foregroundStyle(palette.textSecondary.opacity(0.6))
        }
        .padding(.vertical, 4)
        .contentShape(Rectangle())
    }

    private func delete(at offsets: IndexSet) {
        for index in offsets { Roster.delete(context, player: players[index]) }
        Haptics.impact(.rigid)
    }

    private func move(from source: IndexSet, to destination: Int) {
        var reordered = players
        reordered.move(fromOffsets: source, toOffset: destination)
        Roster.reorder(context, players: reordered)
    }
}

#Preview {
    PlayersView()
        .modelContainer(for: Player.self, inMemory: true)
}
