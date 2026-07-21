import SwiftUI
import SwiftData

/// Rename a player and pick their color. Edits are written straight through to SwiftData,
/// which autosaves and syncs to iCloud.
struct PlayerEditorSheet: View {
    @Bindable var player: Player
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context

    private let columns = [GridItem(.adaptive(minimum: 52), spacing: 12)]

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    HStack(spacing: 14) {
                        ZStack {
                            Circle().fill(player.color.gradient)
                            Text(String(player.name.prefix(1)).uppercased())
                                .font(.title2.weight(.bold))
                                .foregroundStyle(player.color.readableForeground)
                        }
                        .frame(width: 52, height: 52)

                        TextField("Name", text: $player.name)
                            .font(.title3)
                            .textInputAutocapitalization(.words)
                    }
                    .padding(.vertical, 4)
                }

                Section("Color") {
                    LazyVGrid(columns: columns, spacing: 12) {
                        ForEach(Theme.playerPalette, id: \.self) { hex in
                            swatch(hex)
                        }
                    }
                    .padding(.vertical, 4)

                    ColorPicker("Custom color", selection: Binding(
                        get: { player.color },
                        set: { player.colorHex = $0.hexString }
                    ))
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

    private func swatch(_ hex: String) -> some View {
        let selected = hex.caseInsensitiveCompare(player.colorHex) == .orderedSame
        return Button {
            Haptics.selection()
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
        }
        .buttonStyle(.plain)
    }
}
