import SwiftUI
import SwiftData

struct SettingsView: View {
    @Environment(\.modelContext) private var context
    @Query private var players: [Player]

    @AppStorage(SettingsKey.diceCount) private var diceCount = 2
    @AppStorage(SettingsKey.diceSides) private var diceSides = 6
    @AppStorage(SettingsKey.diceShowTotal) private var diceShowTotal = true
    @AppStorage(SettingsKey.diceColorHex) private var diceColorHex = "#E63946"

    @AppStorage(SettingsKey.secondsPerPlayer) private var secondsPerPlayer = 90.0
    @AppStorage(SettingsKey.alarmEnabled) private var alarmEnabled = true
    @AppStorage(SettingsKey.alarmDuration) private var alarmDuration = 3.0

    @AppStorage(SettingsKey.hapticsEnabled) private var hapticsEnabled = true
    @AppStorage(SettingsKey.soundEnabled) private var soundEnabled = true
    @AppStorage(SettingsKey.appearance) private var appearanceRaw = AppearanceMode.system.rawValue

    @State private var showResetAlert = false

    private let sideOptions = [4, 6, 8, 10, 12, 20, 100]
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
                iCloudSection
                diceSection
                timerSection
                feedbackSection
                appearanceSection
                dataSection
                aboutSection
            }
            .navigationTitle("Settings")
            .alert("Reset all scores?", isPresented: $showResetAlert) {
                Button("Reset", role: .destructive) {
                    Roster.resetScores(context, players: players)
                    Haptics.notify(.warning)
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("This clears every round for all players. The roster is kept.")
            }
        }
    }

    // MARK: - Sections

    private var iCloudSection: some View {
        Section {
            HStack(spacing: 12) {
                Image(systemName: iCloudAvailable ? "checkmark.icloud.fill" : "exclamationmark.icloud")
                    .font(.title2)
                    .foregroundStyle(iCloudAvailable ? Color.green : Color.orange)
                VStack(alignment: .leading, spacing: 2) {
                    Text(iCloudAvailable ? "iCloud Sync On" : "iCloud Unavailable")
                        .font(.headline)
                    Text(iCloudAvailable
                         ? "Players and scores sync across your devices."
                         : "Sign in to iCloud in Settings to sync. Your data is still saved on this device.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .padding(.vertical, 2)
        } header: {
            Text("Sync")
        }
    }

    private var diceSection: some View {
        Section("Dice") {
            Stepper("Number of dice: \(diceCount)", value: $diceCount, in: 1...12)

            Picker("Sides", selection: $diceSides) {
                ForEach(sideOptions, id: \.self) { Text("d\($0)").tag($0) }
            }

            Toggle("Show total", isOn: $diceShowTotal)

            VStack(alignment: .leading, spacing: 8) {
                Text("Die color").font(.subheadline)
                LazyVGrid(columns: swatchColumns, spacing: 12) {
                    ForEach(Theme.diceColors, id: \.hex) { entry in
                        diceSwatch(entry.hex, name: entry.name)
                    }
                }
            }
            .padding(.vertical, 4)
        }
    }

    private var timerSection: some View {
        Section("Turn Timer") {
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text("Time per player")
                    Spacer()
                    Text(secondsPerPlayer.clockString)
                        .font(.body.monospacedDigit().weight(.semibold))
                        .foregroundStyle(.secondary)
                }
                Slider(value: $secondsPerPlayer, in: 10...900, step: 5)
            }
            .padding(.vertical, 2)

            Toggle("Play alarm when time runs out", isOn: $alarmEnabled)

            if alarmEnabled {
                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Text("Alarm length")
                        Spacer()
                        Text("\(Int(alarmDuration))s")
                            .foregroundStyle(.secondary)
                    }
                    Slider(value: $alarmDuration, in: 1...10, step: 1)
                }
                .padding(.vertical, 2)
            }
        }
    }

    private var feedbackSection: some View {
        Section("Feedback") {
            Toggle("Haptics", isOn: $hapticsEnabled)
            Toggle("Sound", isOn: $soundEnabled)
        }
    }

    private var appearanceSection: some View {
        Section("Appearance") {
            Picker("Theme", selection: $appearanceRaw) {
                ForEach(AppearanceMode.allCases) { Text($0.label).tag($0.rawValue) }
            }
            .pickerStyle(.segmented)
        }
    }

    private var dataSection: some View {
        Section {
            LabeledContent("Players", value: "\(players.count)")
            LabeledContent("Rounds recorded", value: "\(Roster.roundCount(players))")
            Button("Reset all scores", role: .destructive) { showResetAlert = true }
        } header: {
            Text("Data")
        } footer: {
            Text("Players and scores are stored with SwiftData and mirrored to your private iCloud database.")
        }
    }

    private var aboutSection: some View {
        Section("About") {
            LabeledContent("Version", value: appVersion)
            LabeledContent("Made by", value: "Nathan Fennel")
        }
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
                        .strokeBorder(Color.primary.opacity(selected ? 0.9 : 0.15), lineWidth: selected ? 3 : 1)
                )
                .overlay {
                    if selected {
                        Image(systemName: "checkmark")
                            .font(.subheadline.weight(.black))
                            .foregroundStyle(Color(hex: hex).readableForeground)
                    }
                }
                .accessibilityLabel(name)
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    SettingsView()
        .modelContainer(for: Player.self, inMemory: true)
}
