import SwiftUI

/// Search the game-theme repository and re-skin the app to match tonight's game.
/// Purely cosmetic: applying a theme never changes any feature. Works fully offline
/// against the bundled and cached theme lists.
struct GameThemeSearchView: View {
    @Environment(\.palette) private var palette
    @Environment(\.colorScheme) private var colorScheme
    @State private var service = GameThemeService.shared
    @State private var themeManager = ThemeManager.shared
    @State private var query = ""

    /// Called after a theme is applied (e.g. so onboarding can advance).
    var onApply: (() -> Void)? = nil

    private var results: [AppTheme] { service.search(query) }

    var body: some View {
        VStack(spacing: 14) {
            searchField

            if results.isEmpty {
                VStack(spacing: 8) {
                    Image(systemName: "magnifyingglass")
                        .font(.title2)
                        .foregroundStyle(palette.textSecondary.opacity(0.6))
                    Text("No matching game yet")
                        .font(.headline)
                        .foregroundStyle(palette.textPrimary)
                    Text("More games arrive over time — and every built-in theme always works.")
                        .font(.caption)
                        .foregroundStyle(palette.textSecondary)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 30)
            } else {
                ScrollView {
                    LazyVStack(spacing: 10) {
                        ForEach(results) { theme in
                            resultRow(theme)
                        }
                    }
                    .padding(.bottom, 8)
                }
                .scrollBounceBehavior(.basedOnSize)
            }

            Text("Fan-made color schemes inspired by each game's look. Not affiliated with or endorsed by any publisher.")
                .font(.caption2)
                .foregroundStyle(palette.textSecondary.opacity(0.8))
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
        .task { await service.refreshIfNeeded() }
    }

    private var searchField: some View {
        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(palette.textSecondary)
            TextField("Search a game — Catan, Wingspan…", text: $query)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .foregroundStyle(palette.textPrimary)
            if !query.isEmpty {
                Button {
                    query = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(palette.textSecondary.opacity(0.7))
                }
                .accessibilityLabel("Clear search")
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 11)
        .background {
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(palette.surface)
                .overlay {
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .strokeBorder(palette.textSecondary.opacity(0.25), lineWidth: 1)
                }
        }
    }

    private func resultRow(_ theme: AppTheme) -> some View {
        let variant = theme.palette(for: colorScheme)
        let isActive = themeManager.selectedThemeID == theme.id
        return Button {
            Haptics.impact(.light)
            withAnimation(.easeInOut(duration: 0.35)) {
                service.apply(theme)
            }
            onApply?()
        } label: {
            HStack(spacing: 12) {
                // Three-color preview chip of the theme being offered.
                HStack(spacing: -5) {
                    Circle().fill(variant.accent).frame(width: 22, height: 22)
                    Circle().fill(variant.table).frame(width: 22, height: 22)
                    Circle().fill(variant.playerColor(4)).frame(width: 22, height: 22)
                }
                .overlay { Capsule().strokeBorder(palette.textSecondary.opacity(0.3), lineWidth: 0.8).padding(-2) }

                VStack(alignment: .leading, spacing: 1) {
                    Text(theme.gameDisplayName)
                        .font(.headline)
                        .foregroundStyle(palette.textPrimary)
                    Text(theme.name)
                        .font(.caption)
                        .foregroundStyle(palette.textSecondary)
                }
                Spacer()
                if isActive {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(palette.accent)
                        .accessibilityLabel("Active theme")
                }
            }
            .padding(12)
            .background {
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(palette.surface)
                    .overlay {
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .strokeBorder(isActive ? palette.accent : palette.textSecondary.opacity(0.18),
                                          lineWidth: isActive ? 2 : 1)
                    }
            }
            .contentShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(theme.gameDisplayName), \(theme.name) theme")
        .accessibilityAddTraits(isActive ? .isSelected : [])
    }
}

#Preview {
    GameThemeSearchView()
        .padding()
}
