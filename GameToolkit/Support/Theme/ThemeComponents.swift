import SwiftUI

// MARK: - Typography

extension Font {
    /// Serif display face (New York on Apple platforms) for titles, totals, and moments.
    static func display(_ size: CGFloat, weight: Font.Weight = .bold) -> Font {
        .system(size: size, weight: weight, design: .serif)
    }

    /// Serif text style that tracks Dynamic Type.
    static func display(_ style: Font.TextStyle, weight: Font.Weight = .bold) -> Font {
        .system(style, design: .serif).weight(weight)
    }
}

// MARK: - Felt tray

/// The tabletop: a felt surface with a soft lamp-light falloff and a raised rim, used as
/// the stage for the dice and other hero content. Colors derive from the palette so every
/// theme gets its own table.
struct FeltSurface: View {
    var felt: Color
    var cornerRadius: CGFloat = 26

    var body: some View {
        let shape = RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
        shape
            .fill(felt)
            .overlay {
                // Lamp light from above, shade pooling at the bottom.
                shape.fill(
                    LinearGradient(
                        stops: [
                            .init(color: .white.opacity(0.14), location: 0),
                            .init(color: .clear, location: 0.35),
                            .init(color: .black.opacity(0.18), location: 1),
                        ],
                        startPoint: .top, endPoint: .bottom
                    )
                )
            }
            .overlay {
                shape.fill(
                    RadialGradient(
                        colors: [.clear, .black.opacity(0.16)],
                        center: .center, startRadius: 60, endRadius: 420
                    )
                )
            }
            .overlay {
                // Raised rim: dark outer edge, thin highlight inside it.
                shape.strokeBorder(.black.opacity(0.28), lineWidth: 3)
            }
            .overlay {
                shape.inset(by: 3).strokeBorder(.white.opacity(0.10), lineWidth: 1)
            }
            .clipShape(shape)
    }
}

// MARK: - Cards

/// The standard raised surface: a soft card that sits on the table.
struct SurfaceCard<Content: View>: View {
    @Environment(\.palette) private var palette
    var cornerRadius: CGFloat = 20
    @ViewBuilder var content: Content

    var body: some View {
        let shape = RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
        content
            .background {
                shape
                    .fill(palette.surface)
                    .overlay { shape.strokeBorder(.white.opacity(0.25), lineWidth: 0.8).blendMode(.overlay) }
                    .shadow(color: .black.opacity(0.10), radius: 10, y: 5)
                    .shadow(color: .black.opacity(0.06), radius: 1.5, y: 1)
            }
    }
}

// MARK: - Buttons

/// The primary call to action: warm accent fill, serif label, gentle press response.
struct PrimaryButtonStyle: ButtonStyle {
    @Environment(\.palette) private var palette
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    var prominent = true

    func makeBody(configuration: Configuration) -> some View {
        let shape = RoundedRectangle(cornerRadius: 16, style: .continuous)
        configuration.label
            .font(.display(.title3))
            .foregroundStyle(prominent ? palette.accent.readableForeground : palette.textPrimary)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background {
                if prominent {
                    shape
                        .fill(
                            LinearGradient(colors: [palette.accent.opacity(0.92), palette.accent],
                                           startPoint: .top, endPoint: .bottom)
                        )
                        .overlay { shape.strokeBorder(.white.opacity(0.28), lineWidth: 1).blendMode(.overlay) }
                        .shadow(color: palette.accent.opacity(0.35), radius: 8, y: 4)
                } else {
                    shape.fill(palette.textPrimary.opacity(0.08))
                }
            }
            .opacity(configuration.isPressed ? 0.85 : 1)
            .scaleEffect(configuration.isPressed && !reduceMotion ? 0.98 : 1)
            .animation(.easeOut(duration: 0.12), value: configuration.isPressed)
    }
}

// MARK: - Chips

/// A selectable pill used for die sides, view modes, and similar single-choice rows.
struct SelectableChip: View {
    @Environment(\.palette) private var palette
    let label: String
    let isSelected: Bool
    var action: () -> Void

    var body: some View {
        Button {
            Haptics.selection()
            action()
        } label: {
            Text(label)
                .font(.subheadline.weight(.bold))
                .padding(.horizontal, 15)
                .padding(.vertical, 9)
                .background {
                    Capsule().fill(isSelected ? palette.accent : palette.textPrimary.opacity(0.07))
                }
                .overlay {
                    if !isSelected {
                        Capsule().strokeBorder(palette.textSecondary.opacity(0.25), lineWidth: 1)
                    }
                }
                .foregroundStyle(isSelected ? palette.accent.readableForeground : palette.textPrimary)
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}

// MARK: - Theme quick switch

/// A compact toolbar control that shows the active theme and opens the picker in one tap.
struct ThemeSwitcherButton: View {
    @Environment(\.palette) private var palette
    @State private var showingPicker = false

    var body: some View {
        Button {
            Haptics.selection()
            showingPicker = true
        } label: {
            HStack(spacing: -4) {
                Circle().fill(palette.accent).frame(width: 14, height: 14)
                Circle().fill(palette.accentSecondary).frame(width: 14, height: 14)
                Circle().fill(palette.playerColor(4)).frame(width: 14, height: 14)
            }
            .overlay {
                Capsule().strokeBorder(palette.textSecondary.opacity(0.35), lineWidth: 1)
                    .padding(-3)
            }
            .padding(3)
        }
        .accessibilityLabel("Change theme")
        .accessibilityHint("Opens the theme picker")
        .sheet(isPresented: $showingPicker) {
            ThemePickerSheet()
        }
    }
}

/// Grid of live theme previews. Reused by Settings, the toolbar switcher, and onboarding.
struct ThemePickerSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.palette) private var palette
    @AppStorage(SettingsKey.appearance) private var appearanceRaw = AppearanceMode.system.rawValue
    @State private var themeManager = ThemeManager.shared

    private var columns: [GridItem] { [GridItem(.adaptive(minimum: 150), spacing: 14)] }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 18) {
                    Picker("Appearance", selection: $appearanceRaw) {
                        ForEach(AppearanceMode.allCases) { Text($0.label).tag($0.rawValue) }
                    }
                    .pickerStyle(.segmented)

                    LazyVGrid(columns: columns, spacing: 14) {
                        ForEach(themeManager.availableThemes) { theme in
                            ThemePreviewTile(
                                theme: theme,
                                isSelected: theme.id == themeManager.selectedThemeID
                            ) {
                                Haptics.impact(.light)
                                withAnimation(.easeInOut(duration: 0.35)) {
                                    themeManager.select(theme)
                                }
                            }
                        }
                    }
                }
                .padding()
            }
            .background(palette.background.ignoresSafeArea())
            .navigationTitle("Theme")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }.fontWeight(.semibold)
                }
            }
        }
    }
}

/// A miniature light+dark rendering of a theme, used as its swatch in pickers.
struct ThemePreviewTile: View {
    @Environment(\.colorScheme) private var colorScheme
    let theme: AppTheme
    let isSelected: Bool
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                HStack(spacing: 0) {
                    preview(theme.light)
                    preview(theme.dark)
                }
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                .overlay {
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .strokeBorder(isSelected ? theme.palette(for: colorScheme).accent : .gray.opacity(0.3),
                                      lineWidth: isSelected ? 2.5 : 1)
                }

                HStack(spacing: 5) {
                    if isSelected {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.caption)
                            .foregroundStyle(theme.palette(for: colorScheme).accent)
                    }
                    Text(theme.name)
                        .font(.subheadline.weight(isSelected ? .bold : .medium))
                }
            }
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(theme.name) theme")
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }

    private func preview(_ p: ThemePalette) -> some View {
        VStack(alignment: .leading, spacing: 5) {
            RoundedRectangle(cornerRadius: 3)
                .fill(p.textPrimary.opacity(0.85))
                .frame(width: 34, height: 5)
            HStack(spacing: 3) {
                ForEach(0..<3, id: \.self) { i in
                    Circle().fill(p.playerColor(i)).frame(width: 9, height: 9)
                }
            }
            Capsule().fill(p.accent).frame(width: 30, height: 9)
        }
        .padding(8)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background {
            RoundedRectangle(cornerRadius: 7, style: .continuous).fill(p.surface).padding(4)
        }
        .background(p.background)
    }
}
