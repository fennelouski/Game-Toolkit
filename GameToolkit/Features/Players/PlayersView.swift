import SwiftUI
import SwiftData

struct PlayersView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \Player.sortIndex) private var players: [Player]
    @State private var editing: Player?

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
                        }
                        .onDelete(perform: delete)
                        .onMove(perform: move)
                    }
                }
            }
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
        HStack(spacing: 14) {
            ZStack {
                Circle().fill(player.color.gradient)
                Text(String(player.name.prefix(1)).uppercased())
                    .font(.headline)
                    .foregroundStyle(player.color.readableForeground)
            }
            .frame(width: 38, height: 38)

            VStack(alignment: .leading, spacing: 2) {
                Text(player.name.isEmpty ? "Unnamed" : player.name)
                    .font(.headline)
                Text("\(player.total) pts · \(player.scores.count) rounds")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Image(systemName: "chevron.right")
                .font(.caption.weight(.bold))
                .foregroundStyle(.tertiary)
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
