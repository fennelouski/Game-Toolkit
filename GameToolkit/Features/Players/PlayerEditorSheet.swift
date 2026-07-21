import SwiftUI
import SwiftData

/// Rename a player and pick their color. Edits are written straight through to SwiftData,
/// which autosaves and syncs to iCloud.
struct PlayerEditorSheet: View {
    @Bindable var player: Player
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context
    @Environment(\.palette) private var palette

    private let columns = [GridItem(.adaptive(minimum: 52), spacing: 12)]

    private var displayColor: Color { player.color(in: palette) }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    HStack(spacing: 14) {
                        ZStack {
                            Circle().fill(displayColor.gradient)
                            Text(String(player.name.prefix(1)).uppercased())
                                .font(.title2.weight(.bold))
                                .foregroundStyle(displayColor.readableForeground)
                        }
                        .frame(width: 52, height: 52)

                        TextField("Name", text: $player.name)
                            .font(.title3)
                            .textInputAutocapitalization(.words)
                    }
                    .padding(.vertical, 4)
                }

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
                } header: {
                    Text("Color")
                } footer: {
                    Text(player.paletteIndex == nil
                         ? "Custom colors stay fixed when the theme changes."
                         : "Palette colors follow the app theme.")
                }

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
