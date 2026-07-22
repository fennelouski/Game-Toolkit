import SwiftUI
import SwiftData

/// The Timer tab: hosts all four timer modes — a grid of per-player cards, or one big
/// shared timer — rendered in the user's chosen display style, with the effects overlay
/// and system integrations (Live Activity, system alarm) wired to the engine's events.
struct TurnTimerView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.palette) private var palette
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Query(sort: \Player.sortIndex) private var players: [Player]

    @AppStorage(SettingsKey.activeGroupID) private var activeGroupID = ""
    @AppStorage(SettingsKey.timerMode) private var modeRaw = TimerMode.chessClock.rawValue
    @AppStorage(SettingsKey.timerScope) private var scopeRaw = TimerScope.perPlayer.rawValue
    @AppStorage(SettingsKey.timerTapBehavior) private var tapBehaviorRaw = TapBehavior.pause.rawValue
    @AppStorage(SettingsKey.secondsPerPlayer) private var chessSeconds = 90.0
    @AppStorage(SettingsKey.timerCountdownSeconds) private var countdownSeconds = 300.0
    @AppStorage(SettingsKey.timerAutoSwitchSeconds) private var autoSwitchSeconds = 30.0
    @AppStorage(SettingsKey.timerAutoResetDelay) private var autoResetDelay = -1.0
    @AppStorage(SettingsKey.timerSoundID) private var soundID = TimerSound.default.rawValue
    @AppStorage(SettingsKey.timerStyleID) private var styleID = TimerDisplayStyle.classic.rawValue

    @State private var engine = TimerEngine()
    @State private var effects = TimerEffects()
    @State private var showingTimeSheet = false
    @State private var showingSettings = false
    @State private var customizingPlayer: Player?

    private let columns = [GridItem(.adaptive(minimum: 156), spacing: 14)]

    private var mode: TimerMode { TimerMode(rawValue: modeRaw) ?? .chessClock }

    /// Tonight's clocks: the active game night's members who aren't sitting out.
    private var roster: [Player] { Roster.playing(players, inGroup: activeGroupID) }
    /// Changes when the roster's composition changes — switching game nights, adding or
    /// removing players, or someone sitting out — so the engine can re-sync its slots.
    private var rosterIDs: [PersistentIdentifier] { roster.map(\.persistentModelID) }

    private var configuration: TimerConfiguration {
        TimerConfiguration(
            mode: mode,
            scope: TimerScope(rawValue: scopeRaw) ?? .perPlayer,
            tapBehavior: TapBehavior(rawValue: tapBehaviorRaw) ?? .pause,
            chessSeconds: chessSeconds,
            countdownSeconds: countdownSeconds,
            autoSwitchSeconds: autoSwitchSeconds,
            autoResetDelay: autoResetDelay
        )
    }

    var body: some View {
        NavigationStack {
            ZStack {
                palette.background.ignoresSafeArea()

                VStack(spacing: 12) {
                    statusBar
                    if configuration.usesSharedSlot {
                        singleTimerLayout
                    } else {
                        gridLayout
                    }
                }

                // The effects overlay: screen flash / color pulse. Never intercepts touches.
                Rectangle()
                    .fill(effects.overlayColor)
                    .opacity(effects.overlayOpacity)
                    .ignoresSafeArea()
                    .allowsHitTesting(false)
            }
            .navigationTitle(mode == .countUp ? "Stopwatch" : "Turn Timer")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                if mode != .countUp {
                    ToolbarItem(placement: .topBarLeading) {
                        Button { showingTimeSheet = true } label: {
                            Label(configuration.slotBudget?.clockString ?? "",
                                  systemImage: "clock.arrow.circlepath")
                        }
                    }
                }
                ToolbarItemGroup(placement: .topBarTrailing) {
                    Button(role: .destructive) {
                        engine.reset()
                        Haptics.impact(.rigid)
                    } label: {
                        Label("Reset", systemImage: "arrow.counterclockwise")
                    }
                    Button { showingSettings = true } label: {
                        Label("Timer Settings", systemImage: "gearshape")
                    }
                }
            }
            .sheet(isPresented: $showingTimeSheet) {
                TimeSetupSheet(currentSeconds: configuration.slotBudget ?? 90) { seconds in
                    applyDuration(seconds)
                }
                .presentationDetents([.medium])
            }
            .sheet(isPresented: $showingSettings) {
                NavigationStack {
                    TimerSettingsView()
                        .toolbar {
                            ToolbarItem(placement: .confirmationAction) {
                                Button("Done") { showingSettings = false }.fontWeight(.semibold)
                            }
                        }
                }
            }
            .sheet(item: $customizingPlayer) { player in
                NavigationStack {
                    PlayerTimerOptionsView(player: player, isFixedLength: mode.isFixedLength)
                        .toolbar {
                            ToolbarItem(placement: .confirmationAction) {
                                Button("Done") { customizingPlayer = nil }.fontWeight(.semibold)
                            }
                        }
                }
            }
        }
        .onAppear {
            effects.reduceMotion = reduceMotion
            engine.configure(configuration)
            engine.sync(with: roster)
        }
        .onChange(of: configuration) { _, config in
            engine.configure(config)
            engine.sync(with: roster)
        }
        .onChange(of: rosterIDs) { _, _ in engine.sync(with: roster) }
        .onChange(of: reduceMotion) { _, value in effects.reduceMotion = value }
        .onChange(of: engine.lastEvent) { _, stamped in
            guard let stamped else { return }
            effects.handle(stamped.event, players: players, palette: palette)
            syncSystemIntegrations()
        }
        .onChange(of: engine.activeID) { _, _ in syncSystemIntegrations() }
        .onChange(of: engine.pausedID) { _, _ in syncSystemIntegrations() }
    }

    // MARK: - Layouts

    private var gridLayout: some View {
        GeometryReader { geo in
            ScrollView {
                LazyVGrid(columns: columns, spacing: 14) {
                    ForEach(engine.slots) { slot in
                        TimerSlotCard(
                            slot: slot,
                            model: displayModel(for: slot),
                            style: style(for: slot),
                            fill: fill(for: slot)
                        )
                        .onTapGesture {
                            engine.handleTap(on: slot.id)
                            Haptics.impact(.medium)
                        }
                        .contextMenu {
                            if case let .player(pid) = slot.id,
                               let player = players.first(where: { $0.persistentModelID == pid }) {
                                Button {
                                    customizingPlayer = player
                                } label: {
                                    Label("Style & Sound…", systemImage: "paintbrush")
                                }
                            }
                        }
                    }
                }
                .padding(.horizontal)
                .padding(.vertical, 8)
                // Keeps cards hand-sized and clustered in wide windows.
                .frame(maxWidth: 880)
                .frame(maxWidth: .infinity)
                // Centers the cards when there are only a few, instead of
                // stranding them at the top of a tall screen.
                .frame(minHeight: geo.size.height, alignment: .center)
                .animation(.spring(response: 0.35, dampingFraction: 0.7), value: engine.activeID)
                .animation(.spring(response: 0.4, dampingFraction: 0.75),
                           value: engine.lastEvent?.id)
            }
            .scrollBounceBehavior(.basedOnSize)
        }
    }

    private var singleTimerLayout: some View {
        VStack(spacing: 20) {
            if let slot = engine.slots.first {
                TimerStyleView(style: style(for: slot), model: displayModel(for: slot))
                    .frame(maxWidth: 560, maxHeight: .infinity)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        engine.handleTap(on: slot.id)
                        Haptics.impact(.medium)
                    }

                Button {
                    if engine.isRunning {
                        engine.pause()
                    } else {
                        engine.start()
                    }
                    Haptics.impact(.medium)
                } label: {
                    Label(engine.isRunning ? "Pause" : (engine.isPaused ? "Resume" : "Start"),
                          systemImage: engine.isRunning ? "pause.fill" : "play.fill")
                        .frame(maxWidth: 280)
                }
                .buttonStyle(PrimaryButtonStyle())
                .disabled(engine.slots.first?.isExpired == true)
                .padding(.bottom, 24)
            }
        }
        .padding(.horizontal)
    }

    private var statusBar: some View {
        Group {
            if let activeID = engine.activeID, let slot = engine.slot(for: activeID) {
                Label(slot.name.isEmpty ? "Running" : "\(PiDay.decorate(slot.name))'s turn",
                      systemImage: mode == .countUp ? "stopwatch" : "hourglass")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(color(for: slot).readableForeground)
                    .padding(.horizontal, 16).padding(.vertical, 8)
                    .background(Capsule().fill(color(for: slot).gradient))
            } else if engine.isPaused {
                Label("Paused", systemImage: "pause.fill")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(palette.textSecondary)
                    .padding(.vertical, 8)
            } else if engine.expiredID != nil {
                Label("Time's up!", systemImage: "bell.fill")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(palette.negative.readableForeground)
                    .padding(.horizontal, 16).padding(.vertical, 8)
                    .background(Capsule().fill(palette.negative.gradient))
            } else {
                Text(idleHint)
                    .font(.subheadline)
                    .foregroundStyle(palette.textSecondary)
                    .padding(.vertical, 8)
            }
        }
        .animation(.easeInOut, value: engine.activeID)
    }

    private var idleHint: String {
        if configuration.usesSharedSlot { return "Tap the timer to start" }
        switch mode {
        case .autoSwitch: return "Tap a player to start the rotation"
        case .countUp: return "Tap a player to start their stopwatch"
        default: return "Tap a player to start their clock"
        }
    }

    // MARK: - Slot helpers

    private func displayModel(for slot: TimerEngine.Slot) -> TimerDisplayModel {
        TimerDisplayModel(
            remaining: slot.remaining,
            elapsed: slot.elapsed,
            total: slot.budget,
            isCountUp: slot.budget == nil,
            playerName: slot.name,
            playerColor: color(for: slot),
            isActive: engine.activeID == slot.id,
            isPaused: engine.pausedID == slot.id,
            isExpired: engine.expiredID == slot.id || slot.isExpired
        )
    }

    private func style(for slot: TimerEngine.Slot) -> TimerDisplayStyle {
        .resolve(playerChoice: player(for: slot)?.timerStyleID,
                 defaultChoice: styleID,
                 isFixedLength: mode.isFixedLength)
    }

    private func player(for slot: TimerEngine.Slot) -> Player? {
        guard case let .player(pid) = slot.id else { return nil }
        return players.first(where: { $0.persistentModelID == pid })
    }

    /// Resolves a slot's display color through the theme, falling back to the snapshot hex
    /// if the player has since been deleted; the shared timer uses the accent.
    private func color(for slot: TimerEngine.Slot) -> Color {
        if let player = player(for: slot) { return player.color(in: palette) }
        if case .player = slot.id { return Color(hex: slot.colorHex) }
        return palette.accent
    }

    /// The player's gradient for the card dot; same fallbacks as `color(for:)`.
    private func fill(for slot: TimerEngine.Slot) -> AnyShapeStyle {
        if let player = player(for: slot) { return player.fill(in: palette) }
        return AnyShapeStyle(color(for: slot).gradient)
    }

    private func applyDuration(_ seconds: Double) {
        switch mode {
        case .chessClock: chessSeconds = seconds
        case .countdown: countdownSeconds = seconds
        case .autoSwitch: autoSwitchSeconds = seconds
        case .countUp: break
        }
    }

    // MARK: - System integrations

    /// Keeps the system alarm and the Live Activity in step with the engine. Called on
    /// every start/pause/turn-change/expiry; both services debounce internally.
    private func syncSystemIntegrations() {
        let activeSlot = engine.activeID.flatMap(engine.slot(for:))

        Task {
            if let slot = activeSlot, slot.budget != nil {
                await SystemAlarmService.shared.schedule(
                    endDate: Date().addingTimeInterval(slot.remaining),
                    label: slot.name.isEmpty ? "Timer" : slot.name,
                    sound: alarmSound(for: slot))
            } else {
                await SystemAlarmService.shared.cancel()
            }
        }

        #if canImport(ActivityKit) && os(iOS) && !targetEnvironment(macCatalyst)
        if let slot = activeSlot {
            LiveActivityService.shared.startOrUpdate(.init(
                playerName: slot.name.isEmpty ? "Timer" : slot.name,
                colorHex: colorHex(for: slot),
                endDate: slot.budget != nil ? Date().addingTimeInterval(slot.remaining) : nil,
                startDate: slot.budget == nil ? Date().addingTimeInterval(-slot.elapsed) : nil,
                isPaused: false,
                pausedRemaining: nil,
                isExpired: false))
        } else if let pausedID = engine.pausedID, let slot = engine.slot(for: pausedID) {
            LiveActivityService.shared.startOrUpdate(.init(
                playerName: slot.name.isEmpty ? "Timer" : slot.name,
                colorHex: colorHex(for: slot),
                endDate: nil,
                startDate: nil,
                isPaused: true,
                pausedRemaining: slot.budget != nil ? slot.remaining : slot.elapsed,
                isExpired: false))
        } else {
            LiveActivityService.shared.end()
        }
        #endif
    }

    private func colorHex(for slot: TimerEngine.Slot) -> String {
        if let player = player(for: slot) { return player.colorHex(in: palette) }
        if case .player = slot.id { return slot.colorHex }
        return palette.accent.hexString
    }

    private func alarmSound(for slot: TimerEngine.Slot) -> TimerSound {
        TimerSound.resolve(player(for: slot)?.timerSoundID ?? soundID)
    }
}

/// Card chrome around one player's timer: name, activity indicators, surface, and the
/// active-player glow. The timer face itself comes from the display-style system.
private struct TimerSlotCard: View {
    @Environment(\.palette) private var palette
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    let slot: TimerEngine.Slot
    let model: TimerDisplayModel
    let style: TimerDisplayStyle
    /// The player's gradient; matches `model.playerColor` for single-color players.
    let fill: AnyShapeStyle

    var body: some View {
        VStack(spacing: 8) {
            HStack(spacing: 8) {
                Circle().fill(fill).frame(width: 12, height: 12)
                Text(PiDay.decorate(slot.name))
                    .font(.headline)
                    .foregroundStyle(palette.textPrimary)
                    .lineLimit(1)
                Spacer(minLength: 0)
                if model.isPaused {
                    Image(systemName: "pause.fill")
                        .foregroundStyle(palette.textSecondary)
                }
                if model.isActive {
                    Image(systemName: "play.fill")
                        .foregroundStyle(model.playerColor)
                        .symbolEffect(.pulse, options: .repeating, isActive: !reduceMotion)
                }
                if model.isExpired {
                    Image(systemName: "bell.fill").foregroundStyle(palette.negative)
                }
            }

            TimerStyleView(style: style, model: model)
                .frame(minHeight: 84)
        }
        .padding(16)
        .frame(minHeight: 118)
        .background {
            let shape = RoundedRectangle(cornerRadius: 20, style: .continuous)
            shape
                .fill(palette.surface)
                .overlay { shape.strokeBorder(.white.opacity(0.25), lineWidth: 0.8).blendMode(.overlay) }
                .overlay {
                    shape.strokeBorder(model.isActive ? model.playerColor : palette.textSecondary.opacity(0.15),
                                       lineWidth: model.isActive ? 2.5 : 1)
                }
                .shadow(color: model.isActive ? model.playerColor.opacity(0.35) : .black.opacity(0.08),
                        radius: model.isActive ? 12 : 8, y: 4)
        }
        .scaleEffect(model.isActive && !reduceMotion ? 1.03 : 1)
        .contentShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(accessibilityText)
        .accessibilityHint(model.isActive ? "Tap to pause" : "Tap to start this player's clock")
        .accessibilityAddTraits(.isButton)
    }

    private var accessibilityText: String {
        let time = model.isCountUp
            ? "\(Int(model.elapsed)) seconds elapsed"
            : "\(Int(model.remaining)) seconds remaining"
        let state = model.isActive ? ", running" : (model.isPaused ? ", paused" : "")
        return "\(slot.name), \(time)\(state)"
    }
}

#Preview {
    TurnTimerView()
        .modelContainer(for: Player.self, inMemory: true)
}
