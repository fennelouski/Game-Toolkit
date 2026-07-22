import SwiftUI
import SwiftData

/// The game-night collection: once someone has more than a handful of tables, the switcher
/// chip opens this masonry gallery instead of a flat menu. Every game night is a collectible
/// card — color banner, avatar cluster, running rounds — so the shelf grows with them.
struct GroupGallerySheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context
    @Environment(\.palette) private var palette
    @Environment(\.colorScheme) private var colorScheme
    @Query(sort: \Player.sortIndex) private var allPlayers: [Player]
    @Query(sort: \PlayerGroup.createdAt) private var groups: [PlayerGroup]
    @AppStorage(SettingsKey.activeGroupID) private var activeGroupID = ""

    @State private var showNewGroup = false
    @State private var renaming: PlayerGroup?
    @State private var renameText = ""
    @State private var deleting: PlayerGroup?

    var body: some View {
        NavigationStack {
            ScrollView {
                MasonryLayout(minColumnWidth: 165, spacing: 14) {
                    card(for: nil, index: 0)
                    ForEach(Array(groups.enumerated()), id: \.element.persistentModelID) { index, group in
                        card(for: group, index: index + 1)
                    }
                    newGroupCard(index: groups.count + 1)
                }
                .padding()

                Text("\(groups.count + 1) tables and counting")
                    .font(.caption.weight(.medium))
                    .foregroundStyle(palette.textSecondary)
                    .padding(.bottom, 12)
            }
            .background(palette.background.ignoresSafeArea())
            .navigationTitle("Game Nights")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }.fontWeight(.semibold)
                }
            }
            .sheet(isPresented: $showNewGroup) {
                NewGroupSheet()
            }
            .alert("Rename Game Night", isPresented: Binding(
                get: { renaming != nil },
                set: { if !$0 { renaming = nil } }
            )) {
                TextField("Name", text: $renameText)
                Button("Save") {
                    let trimmed = renameText.trimmingCharacters(in: .whitespaces)
                    if let group = renaming, !trimmed.isEmpty {
                        group.name = trimmed
                        try? context.save()
                    }
                    renaming = nil
                }
                Button("Cancel", role: .cancel) { renaming = nil }
            }
            .alert("Delete \(deleting?.name ?? "")?", isPresented: Binding(
                get: { deleting != nil },
                set: { if !$0 { deleting = nil } }
            )) {
                Button("Delete", role: .destructive) {
                    if let group = deleting {
                        if activeGroupID == group.groupID.uuidString { activeGroupID = "" }
                        Roster.deleteGroup(context, group: group)
                        Haptics.impact(.rigid)
                    }
                    deleting = nil
                }
                Button("Cancel", role: .cancel) { deleting = nil }
            } message: {
                Text("This removes the game night and its players and scores. The same people in other game nights are kept.")
            }
        }
    }

    // MARK: - Cards

    /// One table's card; `nil` is the built-in table, which can't be renamed or deleted.
    ///
    /// When the group's name names a known board game ("Catan – Fridays"), the card wears
    /// that game's palette — the matched palettes are contrast-validated as a set, so text,
    /// banner and avatars all re-dress together via the environment.
    private func card(for group: PlayerGroup?, index: Int) -> some View {
        let key = Roster.key(for: group)
        let members = Roster.members(allPlayers, inGroup: key)
        let name = group?.name ?? Roster.defaultGroupName
        let gameTheme = GameThemeMatcher.theme(for: name, in: GameThemeService.shared.themes)
        return Button {
            activeGroupID = key
            Haptics.impact(.light)
            dismiss()
        } label: {
            GroupCardLabel(
                name: name,
                isBuiltIn: group == nil,
                members: members,
                isActive: activeGroupID == key,
                wearsGameColors: gameTheme != nil
            )
        }
        .environment(\.palette, gameTheme?.palette(for: colorScheme) ?? palette)
        .buttonStyle(CollectibleCardStyle())
        .contextMenu {
            if let group {
                Button {
                    renameText = group.name
                    renaming = group
                } label: {
                    Label("Rename…", systemImage: "pencil")
                }
                Button(role: .destructive) {
                    deleting = group
                } label: {
                    Label("Delete Game Night…", systemImage: "trash")
                }
            }
        }
        .modifier(PopIn(index: index))
        .accessibilityLabel("\(group?.name ?? Roster.defaultGroupName), \(members.count) players")
        .accessibilityAddTraits(activeGroupID == key ? .isSelected : [])
        .accessibilityHint("Makes this the game night in play")
    }

    /// The always-last card that grows the collection.
    private func newGroupCard(index: Int) -> some View {
        Button {
            Haptics.impact(.light)
            showNewGroup = true
        } label: {
            VStack(spacing: 10) {
                Image(systemName: "plus.circle.fill")
                    .font(.system(size: 30))
                    .foregroundStyle(palette.accent)
                Text("New Game Night")
                    .font(.display(.headline))
                    .foregroundStyle(palette.textPrimary)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 26)
            .background {
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .strokeBorder(palette.accent.opacity(0.55),
                                  style: StrokeStyle(lineWidth: 1.6, dash: [7, 5]))
                    .background(
                        RoundedRectangle(cornerRadius: 20, style: .continuous)
                            .fill(palette.accent.opacity(0.06))
                    )
            }
        }
        .buttonStyle(CollectibleCardStyle())
        .modifier(PopIn(index: index))
        .accessibilityHint("Creates a game night with its own roster and scores")
    }
}

/// The face of one collectible card: member-color banner, name, avatar cluster, record.
/// A card that guessed its board game (`wearsGameColors`) renders from that game's palette
/// (injected via the environment) and flies the game's accents instead of seat colors.
private struct GroupCardLabel: View {
    let name: String
    let isBuiltIn: Bool
    let members: [Player]
    let isActive: Bool
    var wearsGameColors = false

    @Environment(\.palette) private var palette

    private var rounds: Int { Roster.roundCount(members) }

    private var record: String {
        if members.isEmpty { return "No players yet" }
        let players = members.count == 1 ? "1 player" : "\(members.count) players"
        return rounds == 0 ? players : "\(players) · \(rounds) rounds"
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            banner

            HStack(alignment: .firstTextBaseline, spacing: 6) {
                if isBuiltIn {
                    Image(systemName: "house.fill")
                        .font(.caption)
                        .foregroundStyle(palette.textSecondary)
                }
                Text(PiDay.decorate(name))
                    .font(.display(.title3))
                    .foregroundStyle(palette.textPrimary)
                    .multilineTextAlignment(.leading)
                    .lineLimit(3)
            }

            if !members.isEmpty {
                avatarCluster
            }

            Text(record)
                .font(.caption.weight(.medium))
                .foregroundStyle(palette.textSecondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background {
            let shape = RoundedRectangle(cornerRadius: 20, style: .continuous)
            shape
                .fill(palette.surface)
                .overlay { shape.strokeBorder(.white.opacity(0.25), lineWidth: 0.8).blendMode(.overlay) }
                .overlay {
                    if isActive {
                        shape.strokeBorder(palette.accent, lineWidth: 2.5)
                    } else if wearsGameColors {
                        // Many themes share one validated player-color set, so the game
                        // identity needs more than the banner: a soft accent edge.
                        shape.strokeBorder(palette.accent.opacity(0.4), lineWidth: 1.2)
                    }
                }
                .shadow(color: .black.opacity(0.10), radius: 10, y: 5)
                .shadow(color: .black.opacity(0.06), radius: 1.5, y: 1)
        }
        .overlay(alignment: .topTrailing) {
            if isActive {
                Image(systemName: "checkmark.seal.fill")
                    .font(.title3)
                    .foregroundStyle(palette.accent)
                    .background(Circle().fill(palette.surface).padding(3))
                    .offset(x: 6, y: -6)
                    .accessibilityLabel("Tonight's table")
            }
        }
    }

    /// A little pennant of the table's colors — game-dressed cards fly their game's
    /// accents, others their seats' colors, and empty tables the accent alone.
    private var banner: some View {
        HStack(spacing: 3) {
            if wearsGameColors {
                Capsule().fill(palette.accent.gradient).frame(height: 6)
                Capsule().fill(palette.accentSecondary.gradient).frame(height: 6)
            } else if members.isEmpty {
                Capsule().fill(palette.accent.opacity(0.35)).frame(height: 6)
            } else {
                ForEach(members.prefix(6)) { member in
                    Capsule().fill(member.color(in: palette).gradient).frame(height: 6)
                }
            }
        }
        .accessibilityHidden(true)
    }

    /// Overlapping faces, four to a row, with a "+N" chip when the table runs deep.
    private var avatarCluster: some View {
        let shown = Array(members.prefix(7))
        let overflow = members.count - shown.count
        let rows: [[Player]] = stride(from: 0, to: shown.count, by: 4).map {
            Array(shown[$0..<min($0 + 4, shown.count)])
        }
        return VStack(alignment: .leading, spacing: 6) {
            ForEach(Array(rows.enumerated()), id: \.offset) { rowIndex, row in
                HStack(spacing: -8) {
                    ForEach(row) { member in
                        PlayerAvatarView(player: member, size: 34)
                            .background(Circle().fill(palette.surface).padding(-1.5))
                    }
                    if rowIndex == rows.count - 1 && overflow > 0 {
                        Text("+\(overflow)")
                            .font(.caption.weight(.bold))
                            .foregroundStyle(palette.textSecondary)
                            .frame(width: 34, height: 34)
                            .background(Circle().fill(palette.textPrimary.opacity(0.08)))
                            .background(Circle().fill(palette.surface).padding(-1.5))
                    }
                }
            }
        }
        .accessibilityHidden(true)
    }
}

/// A springy press so the cards feel like game pieces, not list rows.
private struct CollectibleCardStyle: ButtonStyle {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed && !reduceMotion ? 0.96 : 1)
            .opacity(configuration.isPressed ? 0.9 : 1)
            .animation(.spring(response: 0.28, dampingFraction: 0.7), value: configuration.isPressed)
    }
}

/// Staggered entrance: cards land on the shelf one after another.
private struct PopIn: ViewModifier {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    let index: Int
    @State private var shown = false

    func body(content: Content) -> some View {
        content
            .opacity(shown ? 1 : 0)
            .scaleEffect(shown ? 1 : 0.85)
            .onAppear {
                guard !shown else { return }
                guard !reduceMotion else { shown = true; return }
                withAnimation(.spring(response: 0.38, dampingFraction: 0.72)
                    .delay(Double(min(index, 12)) * 0.05)) {
                    shown = true
                }
            }
    }
}

#Preview {
    GroupGallerySheet()
        .modelContainer(for: Player.self, inMemory: true)
}
