import SwiftUI
import SwiftData

/// Creates a game night: pick a name, optionally bring in people from other game nights.
/// Their name, color and sync preference carry over; scores start fresh.
struct NewGroupSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context
    @Environment(\.palette) private var palette
    @Query(sort: \Player.sortIndex) private var allPlayers: [Player]
    @AppStorage(SettingsKey.activeGroupID) private var activeGroupID = ""

    @State private var name = ""
    @State private var selected = Set<PersistentIdentifier>()
    @FocusState private var nameFocused: Bool

    private var candidates: [Player] { Roster.candidates(allPlayers, excludingGroup: nil) }
    private var trimmedName: String { name.trimmingCharacters(in: .whitespaces) }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Catan – Fridays", text: $name)
                        .font(.title3)
                        .focused($nameFocused)
                } header: {
                    Text("Name")
                } footer: {
                    Text("A game night keeps its own roster, turn order and scores.")
                }

                if !candidates.isEmpty {
                    Section {
                        ForEach(candidates) { player in
                            PersonPickRow(player: player,
                                          isSelected: selected.contains(player.persistentModelID)) {
                                toggle(player)
                            }
                        }
                    } header: {
                        Text("Bring In Players")
                    } footer: {
                        Text("Names and colors carry over. Scores start fresh. You can also add new players later.")
                    }
                }
            }
            .scrollContentBackground(.hidden)
            .background(palette.background.ignoresSafeArea())
            .navigationTitle("New Game Night")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Create") { create() }
                        .fontWeight(.semibold)
                        .disabled(trimmedName.isEmpty)
                }
            }
            .onAppear { nameFocused = true }
        }
    }

    private func toggle(_ player: Player) {
        if selected.contains(player.persistentModelID) {
            selected.remove(player.persistentModelID)
        } else {
            selected.insert(player.persistentModelID)
        }
        Haptics.selection()
    }

    private func create() {
        let group = Roster.createGroup(context, name: trimmedName)
        for player in candidates where selected.contains(player.persistentModelID) {
            Roster.adopt(context, source: player, into: group)
        }
        activeGroupID = group.groupID.uuidString
        Haptics.notify(.success)
        dismiss()
    }
}

/// The plus-button sheet: one tap, then switch between creating a brand-new player and
/// bringing in people from other game nights. Nothing is created until "Add" —
/// Cancel in the corner always backs out cleanly.
struct AddPlayerSheet: View {
    /// The game night gaining players; `nil` is the built-in table.
    let group: PlayerGroup?

    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context
    @Environment(\.palette) private var palette
    @Query(sort: \Player.sortIndex) private var allPlayers: [Player]

    private enum Mode: String, CaseIterable, Identifiable {
        case new = "New Player"
        case existing = "Existing Player"
        var id: String { rawValue }
    }

    @State private var mode: Mode = .new
    @State private var name = ""
    @State private var selected = Set<PersistentIdentifier>()
    @FocusState private var nameFocused: Bool

    private var candidates: [Player] {
        Roster.candidates(allPlayers, excludingGroup: Roster.key(for: group))
    }

    private var defaultName: String {
        "Player \(Roster.members(allPlayers, inGroup: Roster.key(for: group)).count + 1)"
    }

    private var canAdd: Bool {
        switch mode {
        case .new: return true
        case .existing: return !selected.isEmpty
        }
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Picker("Add", selection: $mode) {
                        ForEach(Mode.allCases) { mode in
                            Text(mode.rawValue).tag(mode)
                        }
                    }
                    .pickerStyle(.segmented)
                    .listRowBackground(Color.clear)
                    .listRowInsets(EdgeInsets())
                }

                switch mode {
                case .new:
                    Section {
                        TextField("Name", text: $name, prompt: Text(defaultName))
                            .font(.title3)
                            .textInputAutocapitalization(.words)
                            .focused($nameFocused)
                            .submitLabel(.done)
                            .onSubmit { add() }
                    } footer: {
                        Text("They get the next free color. Tap ⓘ on their row afterwards for avatars, colors and emoji.")
                    }
                case .existing:
                    if candidates.isEmpty {
                        Section {
                            Text("Everyone you've played with is already in this game night. Create a new player instead.")
                                .foregroundStyle(palette.textSecondary)
                        }
                    } else {
                        Section {
                            ForEach(candidates) { player in
                                PersonPickRow(player: player,
                                              isSelected: selected.contains(player.persistentModelID)) {
                                    toggle(player)
                                }
                            }
                        } footer: {
                            Text("Names, colors and avatars carry over. Scores start fresh for this game night.")
                        }
                    }
                }
            }
            .scrollContentBackground(.hidden)
            .background(palette.background.ignoresSafeArea())
            .navigationTitle("Add Player")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(selected.count > 1 && mode == .existing ? "Add \(selected.count)" : "Add") {
                        add()
                    }
                    .fontWeight(.semibold)
                    .disabled(!canAdd)
                }
            }
            .onAppear { nameFocused = true }
        }
        .presentationDetents([.medium, .large])
    }

    private func toggle(_ player: Player) {
        if selected.contains(player.persistentModelID) {
            selected.remove(player.persistentModelID)
        } else {
            selected.insert(player.persistentModelID)
        }
        Haptics.selection()
    }

    private func add() {
        switch mode {
        case .new:
            let trimmed = name.trimmingCharacters(in: .whitespaces)
            Roster.add(context, name: trimmed.isEmpty ? nil : trimmed, group: group)
        case .existing:
            guard !selected.isEmpty else { return }
            for player in candidates where selected.contains(player.persistentModelID) {
                Roster.adopt(context, source: player, into: group)
            }
        }
        Haptics.notify(.success)
        dismiss()
    }
}

/// A checkable person row shared by the two pickers: avatar, name, home game night.
private struct PersonPickRow: View {
    let player: Player
    let isSelected: Bool
    let action: () -> Void

    @Environment(\.palette) private var palette

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.title3)
                    .foregroundStyle(isSelected ? palette.accent : palette.textSecondary.opacity(0.5))

                PlayerAvatarView(player: player, size: 32)

                VStack(alignment: .leading, spacing: 1) {
                    Text(PiDay.decorate(player.name.isEmpty ? "Unnamed" : player.name))
                        .font(.body.weight(.medium))
                        .foregroundStyle(palette.textPrimary)
                    Text("From \(PiDay.decorate(player.group?.name ?? Roster.defaultGroupName))")
                        .font(.caption)
                        .foregroundStyle(palette.textSecondary)
                }
                Spacer()
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .listRowBackground(palette.surface)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}
