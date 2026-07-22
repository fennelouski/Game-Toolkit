import SwiftUI
import SwiftData
import PhotosUI

/// Rename a player, build their avatar (photo, emoji or monogram), pick up to three
/// colors, and choose their reaction emoji. Edits are written straight through to
/// SwiftData, which autosaves and syncs to iCloud.
struct PlayerEditorSheet: View {
    @Bindable var player: Player
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context
    @Environment(\.palette) private var palette
    @Query private var allPlayers: [Player]

    @State private var showCamera = false
    @State private var showPhotoPicker = false
    @State private var photoItem: PhotosPickerItem?
    @State private var showMonogramDesigner = false
    @State private var photoExpanded = false
    @State private var emojiExpanded = false
    @State private var monogramExpanded = false
    @State private var reactionsExpanded = false

    private let columns = [GridItem(.adaptive(minimum: 52), spacing: 12)]
    private let avatarEmojiSuggestions = ["😀", "😎", "🦊", "🐸", "🐙", "🦄", "🤖", "👾", "🧙‍♂️", "🐲", "🎩", "🌵"]

    private var displayColor: Color { player.color(in: palette) }

    /// True when this person also sits at other game nights, which is when the
    /// sync opt-out actually does something.
    private var hasOtherSeats: Bool {
        guard let personID = player.personID else { return false }
        return allPlayers.contains {
            $0.personID == personID && $0.persistentModelID != player.persistentModelID
        }
    }

    var body: some View {
        NavigationStack {
            Form {
                headerSection
                avatarSection
                colorSection
                reactionSection
                gameNightSection
                scoresSection
            }
            .scrollContentBackground(.hidden)
            .background(palette.background.ignoresSafeArea())
            // Runs on every close path (Done or swipe-down), so edits always reach the
            // person's synced seats in other game nights.
            .onDisappear {
                Roster.propagatePreferences(context, from: player, players: allPlayers)
            }
            .navigationTitle("Edit Player")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        if player.name.trimmingCharacters(in: .whitespaces).isEmpty {
                            player.name = "Player"
                        }
                        try? context.save()
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
            #if os(iOS)
            .fullScreenCover(isPresented: $showCamera) {
                CameraPicker { image in
                    if let data = AvatarImage.downscale(image) {
                        adoptPhoto(data)
                    }
                }
                .ignoresSafeArea()
            }
            #endif
            .photosPicker(isPresented: $showPhotoPicker, selection: $photoItem, matching: .images)
            .onChange(of: photoItem) { _, item in
                guard let item else { return }
                Task {
                    if let data = try? await item.loadTransferable(type: Data.self),
                       let scaled = AvatarImage.downscale(data) {
                        adoptPhoto(scaled)
                    }
                    photoItem = nil
                }
            }
            .sheet(isPresented: $showMonogramDesigner) {
                MonogramDesignerSheet(player: player)
            }
        }
    }

    // MARK: - Header

    private var headerSection: some View {
        Section {
            HStack(spacing: 14) {
                PlayerAvatarView(player: player, size: 56)

                TextField("Name", text: $player.name)
                    .font(.title3)
                    .textInputAutocapitalization(.words)
            }
            .padding(.vertical, 4)
        }
    }

    // MARK: - Avatar

    private var avatarSection: some View {
        Section {
            Button {
                setAvatarKind(.initial)
            } label: {
                kindRow("Initial Letter", systemImage: "a.circle", kind: .initial)
            }
            .buttonStyle(.plain)

            DisclosureGroup(isExpanded: $photoExpanded) {
                photoControls
            } label: {
                kindRow("Photo", systemImage: "person.crop.circle.badge.plus", kind: .photo)
            }

            DisclosureGroup(isExpanded: $emojiExpanded) {
                EmojiField(suggestions: avatarEmojiSuggestions, emoji: avatarEmojiBinding)
            } label: {
                kindRow("Emoji", systemImage: "face.smiling", kind: .emoji)
            }

            DisclosureGroup(isExpanded: $monogramExpanded) {
                Button {
                    showMonogramDesigner = true
                } label: {
                    Label("Design Monogram…", systemImage: "signature")
                }
                if player.avatarKind != .monogram, player.monogramData != nil {
                    Button("Use Monogram") { setAvatarKind(.monogram) }
                }
            } label: {
                kindRow("Monogram", systemImage: "m.square", kind: .monogram)
            }
        } header: {
            Text("Avatar")
        } footer: {
            Text("The avatar appears on the roster, scorecard and TV scoreboard.")
        }
    }

    private func kindRow(_ title: String, systemImage: String, kind: AvatarKind) -> some View {
        HStack {
            Label(title, systemImage: systemImage)
                .foregroundStyle(palette.textPrimary)
            Spacer()
            if player.avatarKind == kind {
                Image(systemName: "checkmark")
                    .fontWeight(.semibold)
                    .foregroundStyle(palette.accent)
            }
        }
        .contentShape(Rectangle())
    }

    @ViewBuilder
    private var photoControls: some View {
        if CameraPicker.isAvailable {
            Button {
                showCamera = true
            } label: {
                Label("Take a Selfie", systemImage: "camera")
            }
        }
        Button {
            showPhotoPicker = true
        } label: {
            Label("Choose from Library", systemImage: "photo.on.rectangle")
        }
        #if canImport(ImagePlayground)
        if #available(iOS 18.2, macCatalyst 18.2, *) {
            ImagePlaygroundAvatarButton(
                playerName: player.name,
                sourceImageData: player.avatarImageData
            ) { data in
                adoptPhoto(data)
            }
        }
        #endif
        if player.avatarImageData != nil {
            if player.avatarKind != .photo {
                Button("Use This Photo") { setAvatarKind(.photo) }
            }
            Button("Remove Photo", role: .destructive) {
                withAnimation(.snappy) {
                    player.avatarImageData = nil
                    if AvatarKind(rawValue: player.avatarKindRaw) == .photo {
                        player.avatarKind = .initial
                    }
                }
                try? context.save()
            }
        }
    }

    private var avatarEmojiBinding: Binding<String?> {
        Binding(
            get: { player.avatarEmoji },
            set: { newValue in
                player.avatarEmoji = newValue
                if newValue != nil {
                    player.avatarKind = .emoji
                } else if AvatarKind(rawValue: player.avatarKindRaw) == .emoji {
                    player.avatarKind = .initial
                }
                try? context.save()
            }
        )
    }

    private func setAvatarKind(_ kind: AvatarKind) {
        withAnimation(.snappy) { player.avatarKind = kind }
        try? context.save()
        Haptics.selection()
    }

    private func adoptPhoto(_ data: Data) {
        withAnimation(.snappy) {
            player.avatarImageData = data
            player.avatarKind = .photo
        }
        try? context.save()
        Haptics.notify(.success)
    }

    // MARK: - Colors

    private var colorSection: some View {
        Section {
            LazyVGrid(columns: columns, spacing: 12) {
                ForEach(palette.playerHexes.indices, id: \.self) { index in
                    swatch(index)
                }
            }
            .padding(.vertical, 4)

            ColorPicker("Custom color", selection: Binding(
                get: { displayColor },
                set: {
                    player.colorHex = $0.hexString
                    player.paletteIndex = nil
                }
            ))

            extraColorRows

            if player.colorHex2 != nil {
                Capsule()
                    .fill(player.fill(in: palette))
                    .frame(height: 22)
                    .padding(.vertical, 2)
                    .accessibilityLabel("Gradient preview")
            }
        } header: {
            Text("Colors")
        } footer: {
            Text(player.paletteIndex == nil
                 ? "Custom colors stay fixed when the theme changes. Add up to three colors to give this player a gradient."
                 : "Palette colors follow the app theme. Add up to three colors to give this player a gradient.")
        }
    }

    @ViewBuilder
    private var extraColorRows: some View {
        if player.colorHex2 == nil {
            Button {
                withAnimation(.snappy) {
                    player.colorHex2 = palette.playerHex((player.paletteIndex ?? 0) + 1)
                }
                try? context.save()
            } label: {
                Label("Add Second Color", systemImage: "plus.circle")
            }
        } else {
            extraColorRow("Second color", keyPath: \.colorHex2) {
                // Dropping the second color also drops the third; the gradient reads
                // in order and can't skip a stop.
                player.colorHex2 = player.colorHex3
                player.colorHex3 = nil
            }
            if player.colorHex3 == nil {
                Button {
                    withAnimation(.snappy) {
                        player.colorHex3 = palette.playerHex((player.paletteIndex ?? 0) + 2)
                    }
                    try? context.save()
                } label: {
                    Label("Add Third Color", systemImage: "plus.circle")
                }
            } else {
                extraColorRow("Third color", keyPath: \.colorHex3) {
                    player.colorHex3 = nil
                }
            }
        }
    }

    private func extraColorRow(_ label: String,
                               keyPath: ReferenceWritableKeyPath<Player, String?>,
                               onRemove: @escaping () -> Void) -> some View {
        HStack {
            ColorPicker(label, selection: Binding(
                get: { Color(hex: player[keyPath: keyPath] ?? "#FFFFFF") },
                set: {
                    player[keyPath: keyPath] = $0.hexString
                }
            ))
            Button {
                withAnimation(.snappy) { onRemove() }
                try? context.save()
                Haptics.impact(.light)
            } label: {
                Image(systemName: "minus.circle.fill")
                    .foregroundStyle(palette.textSecondary)
            }
            .buttonStyle(.borderless)
            .accessibilityLabel("Remove \(label.lowercased())")
        }
    }

    // MARK: - Reactions

    private var reactionSection: some View {
        Section {
            DisclosureGroup(isExpanded: $reactionsExpanded) {
                ForEach(ReactionKind.allCases) { kind in
                    reactionRow(kind)
                }
            } label: {
                HStack {
                    Label("Reaction Emoji", systemImage: "theatermasks")
                        .foregroundStyle(palette.textPrimary)
                    Spacer()
                    Text(ReactionKind.allCases.map(player.reactionEmoji(for:)).joined())
                        .font(.callout)
                }
            }
        } footer: {
            Text("These emoji will star in this player's win, loss and celebration moments.")
        }
    }

    private func reactionRow(_ kind: ReactionKind) -> some View {
        HStack {
            Text(kind.label)
            Spacer()
            Menu {
                ForEach(kind.suggestions, id: \.self) { candidate in
                    Button(candidate) {
                        player.setReactionEmoji(candidate, for: kind)
                        try? context.save()
                    }
                }
                if player.customReactionEmoji(for: kind) != nil {
                    Divider()
                    Button("Reset to \(kind.defaultEmoji)") {
                        player.setReactionEmoji(nil, for: kind)
                        try? context.save()
                    }
                }
            } label: {
                Image(systemName: "chevron.up.chevron.down")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(palette.accent)
            }
            TextField("", text: Binding(
                get: { player.reactionEmoji(for: kind) },
                set: {
                    player.setReactionEmoji($0.firstEmoji, for: kind)
                    try? context.save()
                }
            ))
            .font(.title3)
            .multilineTextAlignment(.center)
            .frame(width: 48)
            .accessibilityLabel("\(kind.label) emoji")
        }
    }

    // MARK: - Game night & scores

    private var gameNightSection: some View {
        Section {
            Toggle("Playing tonight", isOn: Binding(
                get: { !player.isSittingOut },
                set: { player.isSittingOut = !$0 }
            ))
            if hasOtherSeats {
                Toggle("Sync across game nights", isOn: $player.syncsPreferences)
            }
        } header: {
            Text("Game Night")
        } footer: {
            Text(hasOtherSeats
                 ? "Sitting out skips this player in the timer and scorecard without removing them. Syncing keeps their name, colors and avatar the same in every game night they join."
                 : "Sitting out skips this player in the timer and scorecard without removing them.")
        }
    }

    private var scoresSection: some View {
        Section("Scores") {
            LabeledContent("Total", value: "\(player.total) pts")
            LabeledContent("Rounds played", value: "\(player.scores.count)")
            if !player.scores.isEmpty {
                Button("Clear this player's scores", role: .destructive) {
                    player.scores = []
                    try? context.save()
                    Haptics.impact(.rigid)
                }
            }
        }
    }

    private func swatch(_ index: Int) -> some View {
        let hex = palette.playerHex(index)
        let selected = player.paletteIndex.map { $0 % palette.playerHexes.count == index } ?? false
        return Button {
            Haptics.selection()
            player.paletteIndex = index
            // Snapshot the resolved hex for older app versions sharing the CloudKit store.
            player.colorHex = hex
        } label: {
            Circle()
                .fill(Color(hex: hex).gradient)
                .frame(height: 44)
                .overlay(
                    Circle().strokeBorder(Color.primary.opacity(selected ? 0.9 : 0), lineWidth: 3)
                )
                .overlay {
                    if selected {
                        Image(systemName: "checkmark")
                            .font(.headline.weight(.black))
                            .foregroundStyle(Color(hex: hex).readableForeground)
                    }
                }
                .accessibilityLabel("Palette color \(index + 1)")
                .accessibilityAddTraits(selected ? .isSelected : [])
        }
        .buttonStyle(.plain)
    }
}
