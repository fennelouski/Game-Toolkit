import SwiftUI

/// The short first-launch tour: what the app does, pick a look, optionally match tonight's
/// game. Every step is skippable, nothing blocks on the network, and it can be re-run from
/// Settings. Content is width-capped so it composes on iPad and Mac, not just phones.
struct OnboardingView: View {
    @Environment(\.palette) private var palette
    @Environment(\.dismiss) private var dismiss
    @AppStorage(SettingsKey.onboardingCompleted) private var onboardingCompleted = false

    @State private var step = OnboardingView.initialStep
    private let stepCount = 3

    /// `-ui.onboardingStep N` jumps straight to a step for screenshots. Debug only.
    private static var initialStep: Int {
        #if DEBUG
        if let value = UserDefaults.standard.string(forKey: "ui.onboardingStep"), let n = Int(value) {
            return min(max(n, 0), 2)
        }
        #endif
        return 0
    }

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                if step > 0 {
                    Button("Back") {
                        withAnimation(.snappy) { step -= 1 }
                    }
                    .foregroundStyle(palette.textSecondary)
                }
                Spacer()
                Button(step == stepCount - 1 ? "Done" : "Skip") { finish() }
                    .fontWeight(.semibold)
                    .foregroundStyle(palette.accent)
            }
            .padding(.horizontal, 20)
            .padding(.top, 16)

            Group {
                switch step {
                case 0: welcomeStep
                case 1: themeStep
                default: gameStep
                }
            }
            .frame(maxWidth: 560)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .padding(.horizontal, 24)

            VStack(spacing: 16) {
                HStack(spacing: 7) {
                    ForEach(0..<stepCount, id: \.self) { index in
                        Capsule()
                            .fill(index == step ? palette.accent : palette.textSecondary.opacity(0.3))
                            .frame(width: index == step ? 22 : 7, height: 7)
                    }
                }
                .accessibilityElement(children: .ignore)
                .accessibilityLabel("Step \(step + 1) of \(stepCount)")

                Button {
                    if step < stepCount - 1 {
                        Haptics.selection()
                        withAnimation(.snappy) { step += 1 }
                    } else {
                        finish()
                    }
                } label: {
                    Text(step == stepCount - 1 ? "Start Playing" : "Continue")
                }
                .buttonStyle(PrimaryButtonStyle())
                .frame(maxWidth: 400)
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 24)
        }
        .background(palette.background.ignoresSafeArea())
        .animation(.snappy, value: step)
    }

    private func finish() {
        Haptics.notify(.success)
        onboardingCompleted = true
        dismiss()
    }

    // MARK: - Steps

    private var welcomeStep: some View {
        VStack(spacing: 24) {
            ZStack {
                FeltSurface(felt: palette.table, cornerRadius: 22)
                HStack(spacing: 16) {
                    DieView(value: 5, sides: 6, spin: 0, face: palette.diceFace, pip: palette.dicePip, seed: 0)
                        .frame(width: 76, height: 76)
                    DieView(value: 3, sides: 6, spin: 0, face: palette.diceFace, pip: palette.dicePip, seed: 5)
                        .frame(width: 76, height: 76)
                }
            }
            .frame(height: 168)
            .accessibilityHidden(true)

            VStack(spacing: 8) {
                Text("Game Toolkit")
                    .font(.display(.largeTitle))
                    .foregroundStyle(palette.textPrimary)
                Text("Everything your table needs on game night.")
                    .font(.body)
                    .foregroundStyle(palette.textSecondary)
            }

            VStack(alignment: .leading, spacing: 14) {
                featureRow("dice.fill", "Roll anything", "Up to 30 dice, 2 to 100 sides. Tap a die to hold it.")
                featureRow("timer", "Time every turn", "A chess clock for the whole table.")
                featureRow("pencil.and.list.clipboard", "Keep score", "Round by round, with charts and a crown for the leader.")
                featureRow("icloud", "Synced", "Players and scores follow you across devices.")
            }
        }
    }

    private func featureRow(_ symbol: String, _ title: String, _ detail: String) -> some View {
        HStack(spacing: 14) {
            Image(systemName: symbol)
                .font(.title3)
                .foregroundStyle(palette.accent)
                .frame(width: 34)
            VStack(alignment: .leading, spacing: 1) {
                Text(title)
                    .font(.headline)
                    .foregroundStyle(palette.textPrimary)
                Text(detail)
                    .font(.caption)
                    .foregroundStyle(palette.textSecondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var themeStep: some View {
        ScrollView {
            VStack(spacing: 18) {
                VStack(spacing: 6) {
                    Text("Which look would you like to start with?")
                        .font(.display(.title))
                        .foregroundStyle(palette.textPrimary)
                        .multilineTextAlignment(.center)
                    Text("The whole app re-colors live. You can change it any time in Settings — or even theme it to the game you're playing.")
                        .font(.subheadline)
                        .foregroundStyle(palette.textSecondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.top, 8)

                ThemeGridPicker()

                AppearancePicker()
            }
        }
        .scrollBounceBehavior(.basedOnSize)
    }

    private var gameStep: some View {
        VStack(spacing: 18) {
            VStack(spacing: 6) {
                Text("What are you playing tonight?")
                    .font(.display(.title2))
                    .foregroundStyle(palette.textPrimary)
                    .multilineTextAlignment(.center)
                Text("Match the app to your game — or skip this and keep your look.")
                    .font(.subheadline)
                    .foregroundStyle(palette.textSecondary)
                    .multilineTextAlignment(.center)
            }
            .padding(.top, 8)

            GameThemeSearchView()
        }
    }
}

/// Light / dark / system, styled for the onboarding and settings screens.
struct AppearancePicker: View {
    @AppStorage(SettingsKey.appearance) private var appearanceRaw = AppearanceMode.system.rawValue

    var body: some View {
        Picker("Appearance", selection: $appearanceRaw) {
            ForEach(AppearanceMode.allCases) { Text($0.label).tag($0.rawValue) }
        }
        .pickerStyle(.segmented)
    }
}

#Preview {
    OnboardingView()
}
