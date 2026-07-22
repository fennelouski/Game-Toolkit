import SwiftUI
import SwiftData

/// Design a monogram avatar: letters, typeface, spread, shape, colors and shadow.
/// A live preview sits on top; saving makes the monogram the player's avatar.
/// The controls are a game-sized port of the Tailor résumé monogram designer.
struct MonogramDesignerSheet: View {
    @Bindable var player: Player
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context
    @Environment(\.palette) private var palette

    @State private var style: PlayerMonogramStyle

    init(player: Player) {
        self.player = player
        _style = State(initialValue: player.monogramStyle ?? PlayerMonogramStyle())
    }

    private var fontDisplayName: String {
        PlayerMonogramStyle.fontOptions.first { $0.name == style.fontName }?.displayName ?? style.fontName
    }

    private var previewText: String {
        style.text.isEmpty ? player.monogramInitials : style.text
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    HStack {
                        Spacer()
                        PlayerMonogramView(
                            style: style,
                            fallbackText: player.monogramInitials,
                            playerFill: player.fill(in: palette),
                            primaryColor: player.color(in: palette),
                            size: 120
                        )
                        Spacer()
                    }
                    .padding(.vertical, 10)
                    .listRowBackground(Color.clear)
                }

                Section("Letters") {
                    TextField("Initials", text: Binding(
                        get: { style.text },
                        set: { style.text = String($0.prefix(3)) }
                    ), prompt: Text("Leave blank to use \(previewText)"))
                    .font(.title3)

                    NavigationLink {
                        fontPicker
                    } label: {
                        LabeledContent("Font", value: fontDisplayName)
                    }
                }

                Section("Shape") {
                    sliderRow("Size", value: $style.fontScale, in: 0.25...0.65)
                    sliderRow("Spread", value: $style.kerning, in: -0.06...0.16)
                    sliderRow("Roundness", value: $style.cornerRadius, in: 0...0.5)
                }

                Section {
                    Picker("Background", selection: Binding(
                        get: { style.backgroundHex != nil },
                        set: { custom in
                            style.backgroundHex = custom
                                ? (style.backgroundHex ?? player.colorHex(in: palette))
                                : nil
                        }
                    )) {
                        Text("Player Colors").tag(false)
                        Text("Custom").tag(true)
                    }
                    .pickerStyle(.segmented)

                    if style.backgroundHex != nil {
                        ColorPicker("Background color", selection: Binding(
                            get: { Color(hex: style.backgroundHex ?? "#000000") },
                            set: { style.backgroundHex = $0.hexString }
                        ))
                    }

                    Toggle("Custom letter color", isOn: Binding(
                        get: { style.textHex != nil },
                        set: { custom in
                            style.textHex = custom ? (style.textHex ?? "#FFFFFF") : nil
                        }
                    ))

                    if style.textHex != nil {
                        ColorPicker("Letter color", selection: Binding(
                            get: { Color(hex: style.textHex ?? "#FFFFFF") },
                            set: { style.textHex = $0.hexString }
                        ))
                    }

                    Toggle("Shadow", isOn: $style.shadowEnabled)
                } header: {
                    Text("Colors")
                } footer: {
                    Text("Player Colors follows this player's gradient, so the monogram recolors with their palette and theme.")
                }
            }
            .scrollContentBackground(.hidden)
            .background(palette.background.ignoresSafeArea())
            .navigationTitle("Monogram")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        player.monogramStyle = style
                        player.avatarKind = .monogram
                        try? context.save()
                        Haptics.notify(.success)
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
        }
    }

    private func sliderRow(_ label: String, value: Binding<Double>, in range: ClosedRange<Double>) -> some View {
        HStack {
            Text(label)
            Slider(value: value, in: range)
        }
    }

    private var fontPicker: some View {
        List {
            ForEach(PlayerMonogramStyle.fontOptions, id: \.name) { option in
                Button {
                    style.fontName = option.name
                } label: {
                    HStack(spacing: 12) {
                        Text(previewText)
                            .font(.custom(option.name, size: 20))
                            .frame(width: 60, alignment: .leading)
                            .lineLimit(1)
                            .minimumScaleFactor(0.5)
                            .foregroundStyle(palette.textPrimary)
                        Text(option.displayName)
                            .foregroundStyle(palette.textPrimary)
                        Spacer()
                        if option.name == style.fontName {
                            Image(systemName: "checkmark")
                                .foregroundStyle(palette.accent)
                        }
                    }
                }
                .listRowBackground(palette.surface)
            }
        }
        .scrollContentBackground(.hidden)
        .background(palette.background.ignoresSafeArea())
        .navigationTitle("Font")
        .navigationBarTitleDisplayMode(.inline)
    }
}
