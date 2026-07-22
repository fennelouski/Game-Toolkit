import SwiftUI
import SwiftData

struct SettingsView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.palette) private var palette
    @Query private var players: [Player]

    @AppStorage(SettingsKey.diceCount) private var diceCount = 2
    @AppStorage(SettingsKey.diceSides) private var diceSides = 6
    @AppStorage(SettingsKey.diceShowTotal) private var diceShowTotal = true
    @AppStorage(SettingsKey.diceColorHex) private var diceColorHex = Theme.themeDiceColor
    @AppStorage(SettingsKey.diceDotSize) private var dotSize = 3.0
    @AppStorage(SettingsKey.piDayEnabled) private var piDayEnabled = true

    @AppStorage(SettingsKey.timerMode) private var timerModeRaw = TimerMode.chessClock.rawValue

    @AppStorage(SettingsKey.hapticsEnabled) private var hapticsEnabled = true
    @AppStorage(SettingsKey.soundEnabled) private var soundEnabled = true
    @AppStorage(SettingsKey.appearance) private var appearanceRaw = AppearanceMode.system.rawValue
    @AppStorage(SettingsKey.externalScoreboard) private var externalScoreboard = true

    @State private var themeManager = ThemeManager.shared
    @State private var showResetAlert = false
    @State private var showResetNamesAlert = false
    @State private var showGameSearch = false
    @State private var showOnboarding = false

    private let swatchColumns = [GridItem(.adaptive(minimum: 46), spacing: 12)]

    private var iCloudAvailable: Bool { FileManager.default.ubiquityIdentityToken != nil }

    private var appVersion: String {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "—"
        let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "—"
        return "\(version) (\(build))"
    }

    var body: some View {
        NavigationStack {
            Form {
                themeSection
                iCloudSection
                diceSection
                timerSection
                externalDisplaySection
                feedbackSection
                funSection
                dataSection
                aboutSection
            }
            .scrollContentBackground(.hidden)
            .background(palette.background.ignoresSafeArea())
            .navigationTitle("Settings")
            .sheet(isPresented: $showGameSearch) {
                NavigationStack {
                    GameThemeSearchView()
                        .padding()
                        .background(palette.background.ignoresSafeArea())
                        .navigationTitle("Match a Game")
                        .navigationBarTitleDisplayMode(.inline)
                        .toolbar {
                            ToolbarItem(placement: .confirmationAction) {
                                Button("Done") { showGameSearch = false }.fontWeight(.semibold)
                            }
                        }
                }
            }
            .fullScreenCover(isPresented: $showOnboarding) {
                OnboardingView()
            }
            .alert("Reset all scores?", isPresented: $showResetAlert) {
                Button("Reset", role: .destructive) {
                    Roster.resetScores(context, players: players)
                    Haptics.notify(.warning)
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("This clears every round for all players. The roster is kept.")
            }
            .alert("Reset player names?", isPresented: $showResetNamesAlert) {
                Button("Reset", role: .destructive) {
                    Roster.resetNames(context, players: players)
                    Haptics.notify(.warning)
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("Renames everyone back to Player 1, Player 2, and so on. Scores are kept.")
            }
        }
    }

    // MARK: - Sections

    private var themeSection: some View {
        Section {
            ThemeGridPicker()
                .listRowBackground(palette.surface)

            Button {
                showGameSearch = true
            } label: {
                Label("Match a Board Game…", systemImage: "magnifyingglass")
                    .foregroundStyle(palette.accent)
            }
            .listRowBackground(palette.surface)

            Picker("Appearance", selection: $appearanceRaw) {
                ForEach(AppearanceMode.allCases) { Text($0.label).tag($0.rawValue) }
            }
            .pickerStyle(.segmented)
            .listRowBackground(palette.surface)
        } header: {
            Text("Theme")
        } footer: {
            Text("Themes recolor the whole app, including player colors. Every feature works with every theme, online or offline.")
        }
    }

    private var iCloudSection: some View {
        Section {
            HStack(spacing: 12) {
                Image(systemName: iCloudAvailable ? "checkmark.icloud.fill" : "exclamationmark.icloud")
                    .font(.title2)
                    .foregroundStyle(iCloudAvailable ? palette.positive : palette.warning)
                VStack(alignment: .leading, spacing: 2) {
                    Text(iCloudAvailable ? "iCloud Sync On" : "iCloud Unavailable")
                        .font(.headline)
                    Text(iCloudAvailable
                         ? "Players and scores sync across your devices."
                         : "Sign in to iCloud in Settings to sync. Your data is still saved on this device.")
                        .font(.caption)
                        .foregroundStyle(palette.textSecondary)
                }
            }
            .padding(.vertical, 2)
            .listRowBackground(palette.surface)
        } header: {
            Text("Sync")
        }
    }

    private var diceSection: some View {
        Section("Dice") {
            Group {
                NavigationLink {
                    DiceDesignerView()
                } label: {
                    Label {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Dice Designer")
                            Text("Custom bags, boxes, and die colors")
                                .font(.caption)
                                .foregroundStyle(palette.textSecondary)
                        }
                    } icon: {
                        Image(systemName: "bag.fill")
                            .foregroundStyle(palette.accent)
                    }
                }

                Stepper("Number of dice: \(diceCount)", value: $diceCount, in: 1...30)

                Stepper("Sides per die: \(diceSides)", value: $diceSides, in: 2...100)

                Toggle("Show total", isOn: $diceShowTotal)

                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Text("Dot size")
                        Spacer()
                        Text(DotSize.name(for: dotSize))
                            .foregroundStyle(palette.textSecondary)
                    }
                    Slider(value: $dotSize, in: DotSize.range, step: 1)
                }
                .padding(.vertical, 2)

                VStack(alignment: .leading, spacing: 8) {
                    Text("Die color").font(.subheadline)
                    LazyVGrid(columns: swatchColumns, spacing: 12) {
                        themeDiceSwatch
                        ForEach(Theme.diceColors, id: \.hex) { entry in
                            diceSwatch(entry.hex, name: entry.name)
                        }
                    }
                }
                .padding(.vertical, 4)
            }
            .listRowBackground(palette.surface)
        }
    }

    private var timerSection: some View {
        Section("Turn Timer") {
            NavigationLink {
                TimerSettingsView()
            } label: {
                LabeledContent("Timer",
                               value: (TimerMode(rawValue: timerModeRaw) ?? .chessClock).label)
            }
            .listRowBackground(palette.surface)
        }
    }

    @ViewBuilder
    private var externalDisplaySection: some View {
        #if os(iOS) && !targetEnvironment(macCatalyst)
        Section {
            Toggle("TV scoreboard", isOn: $externalScoreboard)
                .listRowBackground(palette.surface)
        } header: {
            Text("Apple TV & External Screens")
        } footer: {
            Text("While mirroring to an Apple TV or a connected screen, show everyone a big live scoreboard instead of a copy of your phone. Turn off to mirror normally.")
        }
        #endif
    }

    private var feedbackSection: some View {
        Section("Feedback") {
            Group {
                Toggle("Haptics", isOn: $hapticsEnabled)
                Toggle("Sound", isOn: $soundEnabled)
            }
            .listRowBackground(palette.surface)
        }
    }

    @ViewBuilder
    private var funSection: some View {
        if PiDay.isToday {
            Section {
                Toggle("Happy π Day!", isOn: $piDayEnabled)
                    .listRowBackground(palette.surface)
            } footer: {
                Text("Every P becomes π — today only.")
            }
        }
    }

    private var dataSection: some View {
        Section {
            Group {
                LabeledContent("Players", value: "\(players.count)")
                LabeledContent("Rounds recorded", value: "\(Roster.roundCount(players))")
                Button("Reset dice settings", role: .destructive) { resetDiceSettings() }
                Button("Reset player names", role: .destructive) { showResetNamesAlert = true }
                Button("Reset all scores", role: .destructive) { showResetAlert = true }
            }
            .listRowBackground(palette.surface)
        } header: {
            Text("Data")
        } footer: {
            Text("Players and scores are stored with SwiftData and mirrored to your private iCloud database.")
        }
    }

    private func resetDiceSettings() {
        diceCount = 2
        diceSides = 6
        diceShowTotal = true
        diceColorHex = Theme.themeDiceColor
        dotSize = 3
        Haptics.notify(.success)
    }

    private var aboutSection: some View {
        Section("About") {
            Group {
                Button("Show Welcome Tour") { showOnboarding = true }
                LabeledContent("Version", value: appVersion)
                LabeledContent("Made by", value: "Nathan Fennel")
            }
            .listRowBackground(palette.surface)
        }
    }

    // MARK: - Die color swatches

    /// The default: dice take their colors from the active theme.
    private var themeDiceSwatch: some View {
        let selected = diceColorHex == Theme.themeDiceColor
        return Button {
            Haptics.selection()
            diceColorHex = Theme.themeDiceColor
        } label: {
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(palette.diceFace)
                .frame(height: 40)
                .overlay {
                    Circle()
                        .fill(palette.dicePip)
                        .frame(width: 10, height: 10)
                }
                .overlay(
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .strokeBorder(palette.textPrimary.opacity(selected ? 0.9 : 0.15),
                                      lineWidth: selected ? 3 : 1)
                )
                .overlay {
                    if selected {
                        Image(systemName: "checkmark")
                            .font(.subheadline.weight(.black))
                            .foregroundStyle(palette.diceFace.readableForeground)
                            .offset(x: 12, y: -10)
                    }
                }
                .accessibilityLabel("Theme dice")
                .accessibilityAddTraits(selected ? .isSelected : [])
        }
        .buttonStyle(.plain)
    }

    private func diceSwatch(_ hex: String, name: String) -> some View {
        let selected = hex.caseInsensitiveCompare(diceColorHex) == .orderedSame
        return Button {
            Haptics.selection()
            diceColorHex = hex
        } label: {
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(Color(hex: hex).gradient)
                .frame(height: 40)
                .overlay(
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .strokeBorder(palette.textPrimary.opacity(selected ? 0.9 : 0.15),
                                      lineWidth: selected ? 3 : 1)
                )
                .overlay {
                    if selected {
                        Image(systemName: "checkmark")
                            .font(.subheadline.weight(.black))
                            .foregroundStyle(Color(hex: hex).readableForeground)
                    }
                }
                .accessibilityLabel(name)
                .accessibilityAddTraits(selected ? .isSelected : [])
        }
        .buttonStyle(.plain)
    }
}

/// The inline theme grid used in Settings; the sheet version is `ThemePickerSheet`.
struct ThemeGridPicker: View {
    @State private var themeManager = ThemeManager.shared

    private let columns = [GridItem(.adaptive(minimum: 140), spacing: 12)]

    var body: some View {
        LazyVGrid(columns: columns, spacing: 12) {
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
        .padding(.vertical, 6)
    }
}

#Preview {
    SettingsView()
        .modelContainer(for: Player.self, inMemory: true)
}
