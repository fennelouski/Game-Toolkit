import SwiftUI
import SwiftData

struct PlayersView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.palette) private var palette
    @Query(sort: \Player.sortIndex) private var allPlayers: [Player]
    @Query(sort: \PlayerGroup.createdAt) private var groups: [PlayerGroup]
    @AppStorage(SettingsKey.activeGroupID) private var activeGroupID = ""

    @State private var editing: Player?
    @State private var showNewGroup = false
    @State private var showAddPlayer = false
    @State private var showRenameGroup = false
    @State private var showDeleteGroup = false
    @State private var showGallery = false
    @State private var renameText = ""

    private var activeGroup: PlayerGroup? {
        groups.first { $0.groupID.uuidString == activeGroupID }
    }
    private var activeGroupName: String {
        activeGroup?.name ?? Roster.defaultGroupName
    }
    private var members: [Player] { Roster.members(allPlayers, inGroup: activeGroupID) }
    private var playing: [Player] { members.filter { !$0.isSittingOut } }

    private var rounds: Int { Roster.roundCount(playing) }
    private var leadingTotal: Int? {
        guard rounds > 0 else { return nil }
        return playing.map(\.total).max()
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                groupBar
                if members.isEmpty {
                    emptyState
                } else {
                    List {
                        ForEach(members) { player in
                            row(player)
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
                    if !members.isEmpty { EditButton() }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        Haptics.impact(.light)
                        showAddPlayer = true
                    } label: {
                        Label("Add Player", systemImage: "plus")
                    }
                }
            }
            .sheet(item: $editing) { player in
                PlayerEditorSheet(player: player)
            }
            .sheet(isPresented: $showNewGroup) {
                NewGroupSheet()
            }
            .sheet(isPresented: $showAddPlayer) {
                AddPlayerSheet(group: activeGroup)
            }
            .sheet(isPresented: $showGallery) {
                GroupGallerySheet()
            }
            .alert("Rename Game Night", isPresented: $showRenameGroup) {
                TextField("Name", text: $renameText)
                Button("Save") {
                    let trimmed = renameText.trimmingCharacters(in: .whitespaces)
                    if let group = activeGroup, !trimmed.isEmpty {
                        group.name = trimmed
                        try? context.save()
                    }
                }
                Button("Cancel", role: .cancel) {}
            }
            .alert("Delete \(activeGroupName)?", isPresented: $showDeleteGroup) {
                Button("Delete", role: .destructive) {
                    if let group = activeGroup {
                        Roster.deleteGroup(context, group: group)
                        activeGroupID = ""
                        Haptics.impact(.rigid)
                    }
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("This removes the game night and its \(members.count) players and scores. The same people in other game nights are kept.")
            }
        }
    }

    // MARK: - Game night bar

    /// A menu can hold a handful of tables; past that the collection deserves a shelf.
    private var usesGallery: Bool { groups.count + 1 > 4 }

    /// The switcher chip: which table is set up tonight, plus who's actually playing.
    /// With more than four tables it opens the masonry gallery instead of a flat menu.
    private var groupBar: some View {
        HStack(spacing: 12) {
            Group {
                if usesGallery {
                    Button {
                        Haptics.impact(.light)
                        showGallery = true
                    } label: {
                        switcherChip
                    }
                    .accessibilityHint("Opens your game night collection")
                } else {
                    Menu {
                        Picker("Game Night", selection: $activeGroupID) {
                            Label(Roster.defaultGroupName, systemImage: "house").tag("")
                            ForEach(groups) { group in
                                Text(group.name).tag(group.groupID.uuidString)
                            }
                        }
                        Divider()
                        Button {
                            showNewGroup = true
                        } label: {
                            Label("New Game Night…", systemImage: "plus")
                        }
                        if let group = activeGroup {
                            Button {
                                renameText = group.name
                                showRenameGroup = true
                            } label: {
                                Label("Rename…", systemImage: "pencil")
                            }
                            Button(role: .destructive) {
                                showDeleteGroup = true
                            } label: {
                                Label("Delete Game Night…", systemImage: "trash")
                            }
                        }
                    } label: {
                        switcherChip
                    }
                    .accessibilityHint("Switch, create, rename or delete game nights")
                }
            }
            .accessibilityLabel("Game night: \(activeGroupName)")

            Spacer()

            if !members.isEmpty {
                Text(playing.count == members.count
                     ? "\(members.count) playing"
                     : "\(playing.count) of \(members.count) playing")
                    .font(.caption.weight(.medium))
                    .foregroundStyle(palette.textSecondary)
            }
        }
        .padding(.horizontal)
        .padding(.top, 2)
        .padding(.bottom, 8)
        .animation(.snappy, value: playing.count)
    }

    private var switcherChip: some View {
        HStack(spacing: 6) {
            Image(systemName: "person.3.fill")
                .font(.caption)
            Text(PiDay.decorate(activeGroupName))
                .font(.subheadline.weight(.semibold))
                .lineLimit(1)
            Image(systemName: usesGallery ? "square.grid.2x2.fill" : "chevron.up.chevron.down")
                .font(.caption2.weight(.bold))
        }
        .foregroundStyle(palette.accent.readableForeground)
        .padding(.horizontal, 14)
        .padding(.vertical, 8)
        .background(Capsule().fill(palette.accent.gradient))
    }

    private var emptyState: some View {
        ContentUnavailableView {
            Label("No Players", systemImage: "person.2")
        } description: {
            Text("Add players to \(activeGroupName) to use the timer and scorecard.")
        } actions: {
            Button("Add Player") { showAddPlayer = true }
                .buttonStyle(.borderedProminent)
        }
    }

    // MARK: - Rows

    /// Tonight's roster works like a checklist: tapping a row marks the player in or out,
    /// the info button opens the full editor.
    ///
    /// During swipe-to-delete, SwiftUI re-renders the outgoing row after the model is
    /// already gone from the context, and reading a deleted model's stored properties
    /// traps inside SwiftData — so a dead player renders as nothing instead.
    @ViewBuilder
    private func row(_ player: Player) -> some View {
        if player.isDeleted || player.modelContext == nil {
            EmptyView()
        } else {
            liveRow(player)
        }
    }

    private func liveRow(_ player: Player) -> some View {
        let color = player.color(in: palette)
        let isLeader = rounds > 0 && !player.isSittingOut && player.total == leadingTotal
        return HStack(spacing: 14) {
            Button {
                togglePresence(player)
            } label: {
                HStack(spacing: 14) {
                    Image(systemName: player.isSittingOut ? "circle" : "checkmark.circle.fill")
                        .font(.title3)
                        .foregroundStyle(player.isSittingOut ? palette.textSecondary.opacity(0.5) : color)

                    PlayerAvatarView(player: player, size: 40)

                    VStack(alignment: .leading, spacing: 2) {
                        Text(PiDay.decorate(player.name.isEmpty ? "Unnamed" : player.name))
                            .font(.headline)
                            .foregroundStyle(palette.textPrimary)
                        Text(player.isSittingOut
                             ? "Sitting out"
                             : "\(player.total) pts · \(player.scores.count) rounds")
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
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("\(player.name.isEmpty ? "Unnamed" : player.name), \(player.isSittingOut ? "sitting out" : "playing")")
            .accessibilityHint(player.isSittingOut ? "Tap to join the game" : "Tap to sit out")

            Button {
                editing = player
            } label: {
                Image(systemName: "info.circle")
                    .font(.body)
                    .foregroundStyle(palette.accent)
            }
            .buttonStyle(.borderless)
            .accessibilityLabel("Edit \(player.name.isEmpty ? "player" : player.name)")
        }
        .padding(.vertical, 4)
        .opacity(player.isSittingOut ? 0.55 : 1)
        .contextMenu {
            Button {
                togglePresence(player)
            } label: {
                Label(player.isSittingOut ? "Joins the Game" : "Sits Out",
                      systemImage: player.isSittingOut ? "person.fill.checkmark" : "moon.zzz")
            }
            Button {
                editing = player
            } label: {
                Label("Edit Player", systemImage: "pencil")
            }
            Button(role: .destructive) {
                Roster.delete(context, player: player)
                Haptics.impact(.rigid)
            } label: {
                Label("Remove from Game Night", systemImage: "trash")
            }
        }
    }

    private func togglePresence(_ player: Player) {
        withAnimation(.snappy) {
            player.isSittingOut.toggle()
        }
        try? context.save()
        Haptics.selection()
    }

    private func delete(at offsets: IndexSet) {
        for index in offsets { Roster.delete(context, player: members[index]) }
        Haptics.impact(.rigid)
    }

    private func move(from source: IndexSet, to destination: Int) {
        var reordered = members
        reordered.move(fromOffsets: source, toOffset: destination)
        Roster.reorder(context, players: reordered)
    }
}

#Preview {
    PlayersView()
        .modelContainer(for: Player.self, inMemory: true)
}
