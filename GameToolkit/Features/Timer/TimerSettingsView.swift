import SwiftUI
import SwiftData

/// Every timer option in one place. Reached from the Timer tab's gear button (a sheet)
/// and from the main Settings tab (a push) — same view, two entry points.
struct TimerSettingsView: View {
    @Environment(\.palette) private var palette
    @Query(sort: \Player.sortIndex) private var players: [Player]

    @AppStorage(SettingsKey.timerMode) private var modeRaw = TimerMode.chessClock.rawValue
    @AppStorage(SettingsKey.timerScope) private var scopeRaw = TimerScope.perPlayer.rawValue
    @AppStorage(SettingsKey.timerTapBehavior) private var tapBehaviorRaw = TapBehavior.pause.rawValue
    @AppStorage(SettingsKey.secondsPerPlayer) private var chessSeconds = 90.0
    @AppStorage(SettingsKey.timerCountdownSeconds) private var countdownSeconds = 300.0
    @AppStorage(SettingsKey.timerAutoSwitchSeconds) private var autoSwitchSeconds = 30.0
    @AppStorage(SettingsKey.timerEndActions) private var endActionsRaw = TimerEndActions([.haptics, .sound]).rawValue
    @AppStorage(SettingsKey.timerSwitchActions) private var switchActionsRaw = TimerEndActions([.haptics]).rawValue
    @AppStorage(SettingsKey.timerHapticIntensity) private var hapticIntensity = 1.0
    @AppStorage(SettingsKey.timerSoundID) private var soundID = TimerSound.default.rawValue
    @AppStorage(SettingsKey.alarmDuration) private var alarmDuration = 3.0
    @AppStorage(SettingsKey.timerColorPulseTarget) private var colorPulseTargetRaw = ColorPulseTarget.expiredPlayer.rawValue
    @AppStorage(SettingsKey.timerAutoResetDelay) private var autoResetDelay = -1.0
    @AppStorage(SettingsKey.timerSystemAlarm) private var systemAlarmEnabled = false
    @AppStorage(SettingsKey.timerLiveActivity) private var liveActivityEnabled = true
    @AppStorage(SettingsKey.timerStyleID) private var styleID = TimerDisplayStyle.classic.rawValue

    @State private var showingTimeSheet = false
    @State private var showingAuthorizationHint = false

    private var mode: TimerMode { TimerMode(rawValue: modeRaw) ?? .chessClock }
    private var usesSharedSlot: Bool {
        mode.supportsScope && TimerScope(rawValue: scopeRaw) == .single
    }

    private let autoResetChoices: [(label: String, value: Double)] = [
        ("Off", -1), ("Instantly", 0), ("1 second", 1), ("5 seconds", 5),
        ("10 seconds", 10), ("30 seconds", 30), ("1 minute", 60),
    ]

    var body: some View {
        Form {
            modeSection
            if mode != .countUp { timeSection }
            if !usesSharedSlot && mode != .autoSwitch { tapSection }
            if mode != .countUp { endActionsSection }
            if mode == .autoSwitch { switchActionsSection }
            if mode != .countUp { autoResetSection }
            displayStyleSection
            lockScreenSection
            if !players.isEmpty { playersSection }
        }
        .scrollContentBackground(.hidden)
        .background(palette.background.ignoresSafeArea())
        .navigationTitle("Timer Settings")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showingTimeSheet) {
            TimeSetupSheet(currentSeconds: currentDuration.wrappedValue) { seconds in
                currentDuration.wrappedValue = seconds
            }
            .presentationDetents([.medium, .large])
        }
        .alert("System Alarms Not Allowed", isPresented: $showingAuthorizationHint) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("Allow alarms or notifications for Game Toolkit in the Settings app to ring the system alarm when a timer ends.")
        }
    }

    // MARK: - Sections

    private var modeSection: some View {
        Section {
            Group {
                Picker("Mode", selection: $modeRaw) {
                    ForEach(TimerMode.allCases) { mode in
                        Label(mode.label, systemImage: mode.symbolName).tag(mode.rawValue)
                    }
                }

                if mode.supportsScope {
                    Picker("Timers", selection: $scopeRaw) {
                        ForEach(TimerScope.allCases) { Text($0.label).tag($0.rawValue) }
                    }
                    .pickerStyle(.segmented)
                }
            }
            .listRowBackground(palette.surface)
        } header: {
            Text("Timer")
        } footer: {
            Text(modeFooter)
        }
    }

    private var modeFooter: String {
        switch mode {
        case .chessClock:
            return "Each player has their own bank of time. Tap a player to start their clock and stop everyone else's."
        case .countdown:
            return "Counts down from a set time."
        case .countUp:
            return "Counts up from zero — see how long turns or games really take."
        case .autoSwitch:
            return "Every turn has the same length; when it ends, the clock jumps to the next player automatically. Great for fast-paced games."
        }
    }

    private var currentDuration: Binding<Double> {
        switch mode {
        case .chessClock: return $chessSeconds
        case .countdown: return $countdownSeconds
        case .autoSwitch: return $autoSwitchSeconds
        case .countUp: return .constant(0)
        }
    }

    private var timeSection: some View {
        Section {
            Button {
                showingTimeSheet = true
            } label: {
                HStack {
                    Text(mode == .autoSwitch ? "Time per turn" : (mode == .chessClock ? "Time per player" : "Duration"))
                        .foregroundStyle(palette.textPrimary)
                    Spacer()
                    Text(currentDuration.wrappedValue.clockString)
                        .font(.body.monospacedDigit().weight(.semibold))
                        .foregroundStyle(palette.accent)
                }
            }
            .listRowBackground(palette.surface)
        }
    }

    private var tapSection: some View {
        Section {
            Picker("Tapping the running timer", selection: $tapBehaviorRaw) {
                ForEach(TapBehavior.allCases) { Text($0.label).tag($0.rawValue) }
            }
            .pickerStyle(.menu)
            .listRowBackground(palette.surface)
        } footer: {
            Text("Tapping any other player always hands the clock to them.")
        }
    }

    private var endActionsSection: some View {
        Section {
            Group {
                Toggle("Flash the screen", isOn: actionBinding(.flashScreen, in: $endActionsRaw))
                Toggle("Pulse a player's color", isOn: actionBinding(.colorPulse, in: $endActionsRaw))
                if actions($endActionsRaw).contains(.colorPulse) {
                    Picker("Pulse color", selection: $colorPulseTargetRaw) {
                        ForEach(ColorPulseTarget.allCases) { Text($0.label).tag($0.rawValue) }
                    }
                }

                Toggle("Vibrate", isOn: actionBinding(.haptics, in: $endActionsRaw))
                if actions($endActionsRaw).contains(.haptics) {
                    VStack(alignment: .leading, spacing: 6) {
                        HStack {
                            Text("Vibration strength")
                            Spacer()
                            Text("\(Int(hapticIntensity * 100))%")
                                .foregroundStyle(palette.textSecondary)
                        }
                        Slider(value: $hapticIntensity, in: 0.3...1.0)
                    }
                    .padding(.vertical, 2)
                }

                if TorchService.isAvailable {
                    Toggle("Flash the flashlight", isOn: actionBinding(.flashlight, in: $endActionsRaw))
                }

                Toggle("Play a sound", isOn: actionBinding(.sound, in: $endActionsRaw))
                if actions($endActionsRaw).contains(.sound) {
                    soundPicker
                    VStack(alignment: .leading, spacing: 6) {
                        HStack {
                            Text("Sound length")
                            Spacer()
                            Text("\(Int(alarmDuration))s")
                                .foregroundStyle(palette.textSecondary)
                        }
                        Slider(value: $alarmDuration, in: 1...10, step: 1)
                    }
                    .padding(.vertical, 2)
                }

                Toggle("Ring the system alarm", isOn: $systemAlarmEnabled)
                    .onChange(of: systemAlarmEnabled) { _, enabled in
                        guard enabled else { return }
                        Task {
                            if await !SystemAlarmService.shared.requestAuthorizationIfNeeded() {
                                systemAlarmEnabled = false
                                showingAuthorizationHint = true
                            }
                        }
                    }
            }
            .listRowBackground(palette.surface)
        } header: {
            Text("When Time Runs Out")
        } footer: {
            Text(systemAlarmEnabled
                 ? "The system alarm rings even if you leave the app or lock the screen."
                 : "Tip: the system alarm can ring even if you leave the app.")
        }
    }

    private var switchActionsSection: some View {
        Section {
            Group {
                Toggle("Flash the screen", isOn: actionBinding(.flashScreen, in: $switchActionsRaw))
                Toggle("Pulse the next player's color", isOn: actionBinding(.colorPulse, in: $switchActionsRaw))
                Toggle("Vibrate", isOn: actionBinding(.haptics, in: $switchActionsRaw))
                if TorchService.isAvailable {
                    Toggle("Flash the flashlight", isOn: actionBinding(.flashlight, in: $switchActionsRaw))
                }
                Toggle("Play a sound", isOn: actionBinding(.sound, in: $switchActionsRaw))
            }
            .listRowBackground(palette.surface)
        } header: {
            Text("On Every Turn Change")
        }
    }

    private var autoResetSection: some View {
        Section {
            Picker("Reset after time runs out", selection: $autoResetDelay) {
                ForEach(autoResetChoices, id: \.value) { Text($0.label).tag($0.value) }
            }
            .listRowBackground(palette.surface)
        } footer: {
            Text("Winds the clocks back to full automatically once a timer ends.")
        }
    }

    private var displayStyleSection: some View {
        Section {
            TimerStylePickerView(
                selection: Binding(get: { styleID }, set: { styleID = $0 ?? TimerDisplayStyle.classic.rawValue }),
                isFixedLength: mode.isFixedLength
            )
            .listRowBackground(palette.surface)
        } header: {
            Text("Display Style")
        } footer: {
            Text("Players can pick their own style and sound too — touch and hold a timer, or use the list below.")
        }
    }

    @ViewBuilder
    private var lockScreenSection: some View {
        #if os(iOS) && !targetEnvironment(macCatalyst)
        Section {
            Toggle("Show timer on the Lock Screen", isOn: $liveActivityEnabled)
                .listRowBackground(palette.surface)
        } header: {
            Text("Lock Screen")
        } footer: {
            Text("A Live Activity keeps the running timer on your Lock Screen and in the Dynamic Island.")
        }
        #endif
    }

    private var playersSection: some View {
        Section {
            ForEach(players) { player in
                NavigationLink {
                    PlayerTimerOptionsView(player: player, isFixedLength: mode.isFixedLength)
                } label: {
                    HStack(spacing: 10) {
                        Circle().fill(player.color(in: palette)).frame(width: 12, height: 12)
                        Text(PiDay.decorate(player.name))
                            .foregroundStyle(palette.textPrimary)
                        Spacer()
                        Text(playerSummary(player))
                            .font(.caption)
                            .foregroundStyle(palette.textSecondary)
                    }
                }
                .listRowBackground(palette.surface)
            }
        } header: {
            Text("Per-Player Style & Sound")
        }
    }

    private func playerSummary(_ player: Player) -> String {
        let style = player.timerStyleID.flatMap(TimerDisplayStyle.init(rawValue:))?.displayName
        let sound = player.timerSoundID.flatMap(TimerSound.init(rawValue:))?.displayName
        switch (style, sound) {
        case (nil, nil): return "Default"
        case let (style?, nil): return style
        case let (nil, sound?): return sound
        case let (style?, sound?): return "\(style) · \(sound)"
        }
    }

    private var soundPicker: some View {
        Picker("Sound", selection: $soundID) {
            ForEach(TimerSound.available) { sound in
                Text(sound.displayName).tag(sound.rawValue)
            }
        }
        .onChange(of: soundID) { _, id in
            AudioManager.shared.preview(TimerSound.resolve(id))
        }
    }

    // MARK: - Option-set plumbing

    private func actions(_ raw: Binding<Int>) -> TimerEndActions {
        TimerEndActions(rawValue: raw.wrappedValue)
    }

    private func actionBinding(_ action: TimerEndActions, in raw: Binding<Int>) -> Binding<Bool> {
        Binding(
            get: { TimerEndActions(rawValue: raw.wrappedValue).contains(action) },
            set: { isOn in
                var set = TimerEndActions(rawValue: raw.wrappedValue)
                if isOn { set.insert(action) } else { set.remove(action) }
                raw.wrappedValue = set.rawValue
            }
        )
    }
}

/// Per-player display style and alarm sound, both defaulting to the global choice.
struct PlayerTimerOptionsView: View {
    @Environment(\.palette) private var palette
    @Environment(\.modelContext) private var context
    @Query(sort: \Player.sortIndex) private var allPlayers: [Player]
    @Bindable var player: Player
    let isFixedLength: Bool

    var body: some View {
        Form {
            Section("Display Style") {
                TimerStylePickerView(
                    selection: $player.timerStyleID,
                    isFixedLength: isFixedLength,
                    allowsDefault: true,
                    previewColor: player.color(in: palette)
                )
                .listRowBackground(palette.surface)
            }

            Section {
                soundRow(name: "Default", id: nil)
                ForEach(TimerSound.available) { sound in
                    soundRow(name: sound.displayName, id: sound.rawValue)
                }
            } header: {
                Text("Alarm Sound")
            } footer: {
                Text("Plays when \(player.name.isEmpty ? "this player" : PiDay.decorate(player.name))'s time runs out.")
            }
        }
        .scrollContentBackground(.hidden)
        .background(palette.background.ignoresSafeArea())
        // Runs on every close path (Done or swipe-down), so timer style and sound follow
        // the person to their synced seats in other game nights, like colors do.
        .onDisappear {
            Roster.propagatePreferences(context, from: player, players: allPlayers)
        }
        .navigationTitle(PiDay.decorate(player.name))
        .navigationBarTitleDisplayMode(.inline)
    }

    private func soundRow(name: String, id: String?) -> some View {
        Button {
            player.timerSoundID = id
            if let id { AudioManager.shared.preview(TimerSound.resolve(id)) }
            Haptics.selection()
        } label: {
            HStack {
                Text(name).foregroundStyle(palette.textPrimary)
                Spacer()
                if player.timerSoundID == id {
                    Image(systemName: "checkmark").foregroundStyle(palette.accent)
                }
            }
        }
        .listRowBackground(palette.surface)
    }
}

#Preview {
    NavigationStack { TimerSettingsView() }
        .modelContainer(for: Player.self, inMemory: true)
}
