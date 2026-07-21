import SwiftUI
import SwiftData

struct TurnTimerView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \Player.sortIndex) private var players: [Player]
    @AppStorage(SettingsKey.secondsPerPlayer) private var secondsPerPlayer = 90.0
    @AppStorage(SettingsKey.alarmDuration) private var alarmDuration = 3.0

    @Environment(\.palette) private var palette
    @State private var engine = TimerEngine()
    @State private var showingTimeSheet = false

    private let columns = [GridItem(.adaptive(minimum: 156), spacing: 14)]

    var body: some View {
        NavigationStack {
            ZStack {
                palette.background.ignoresSafeArea()

                VStack(spacing: 12) {
                    statusBar
                    GeometryReader { geo in
                        ScrollView {
                            LazyVGrid(columns: columns, spacing: 14) {
                                ForEach(engine.slots) { slot in
                                    PlayerTimerCard(
                                        slot: slot,
                                        color: color(for: slot),
                                        fraction: fraction(for: slot),
                                        isActive: engine.activeID == slot.id,
                                        isExpired: engine.expiredID == slot.id
                                    )
                                    .onTapGesture { engine.toggle(slot.id) }
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
                        }
                        .scrollBounceBehavior(.basedOnSize)
                    }
                }
            }
            .navigationTitle("Turn Timer")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button { showingTimeSheet = true } label: {
                        Label(secondsPerPlayer.clockString, systemImage: "clock.arrow.circlepath")
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button(role: .destructive) {
                        engine.resetAll(to: secondsPerPlayer)
                    } label: {
                        Label("Reset", systemImage: "arrow.counterclockwise")
                    }
                }
            }
            .sheet(isPresented: $showingTimeSheet) {
                TimeSetupSheet(currentSeconds: secondsPerPlayer) { seconds in
                    secondsPerPlayer = seconds
                    engine.resetAll(to: seconds)
                }
                .presentationDetents([.medium])
            }
        }
        .onAppear {
            engine.alarmDuration = alarmDuration
            engine.sync(with: players, defaultSeconds: secondsPerPlayer)
        }
        .onChange(of: players.count) { _, _ in
            engine.sync(with: players, defaultSeconds: secondsPerPlayer)
        }
        .onChange(of: alarmDuration) { _, new in engine.alarmDuration = new }
    }

    /// Resolves a slot's display color through the theme, falling back to the snapshot hex
    /// if the player has since been deleted.
    private func color(for slot: TimerEngine.Slot) -> Color {
        if let player = players.first(where: { $0.persistentModelID == slot.id }) {
            return player.color(in: palette)
        }
        return Color(hex: slot.colorHex)
    }

    private func fraction(for slot: TimerEngine.Slot) -> Double {
        guard engine.perPlayerSeconds > 0 else { return 0 }
        return (slot.remaining / engine.perPlayerSeconds).clamped(to: 0...1)
    }

    private var statusBar: some View {
        Group {
            if let activeID = engine.activeID, let slot = engine.slots.first(where: { $0.id == activeID }) {
                Label("\(PiDay.decorate(slot.name))'s turn", systemImage: "hourglass")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(color(for: slot).readableForeground)
                    .padding(.horizontal, 16).padding(.vertical, 8)
                    .background(Capsule().fill(color(for: slot).gradient))
            } else if engine.expiredID != nil {
                Label("Time's up!", systemImage: "bell.fill")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(palette.negative.readableForeground)
                    .padding(.horizontal, 16).padding(.vertical, 8)
                    .background(Capsule().fill(palette.negative.gradient))
            } else {
                Text("Tap a player to start their clock")
                    .font(.subheadline)
                    .foregroundStyle(palette.textSecondary)
                    .padding(.vertical, 8)
            }
        }
        .animation(.easeInOut, value: engine.activeID)
    }
}

private struct PlayerTimerCard: View {
    @Environment(\.palette) private var palette
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    let slot: TimerEngine.Slot
    let color: Color
    /// Remaining time as a share of the full budget, 0...1, drawn as the gauge line.
    let fraction: Double
    let isActive: Bool
    let isExpired: Bool

    private var isLow: Bool { slot.remaining <= 10 && slot.remaining > 0 }

    private var timeColor: Color {
        if isExpired { return palette.negative }
        if isLow { return palette.warning }
        return palette.textPrimary
    }

    var body: some View {
        VStack(spacing: 8) {
            HStack(spacing: 8) {
                Circle().fill(color).frame(width: 12, height: 12)
                Text(PiDay.decorate(slot.name))
                    .font(.headline)
                    .foregroundStyle(palette.textPrimary)
                    .lineLimit(1)
                Spacer(minLength: 0)
                if isActive {
                    Image(systemName: "play.fill")
                        .foregroundStyle(color)
                        .symbolEffect(.pulse, options: .repeating, isActive: !reduceMotion)
                }
                if isExpired {
                    Image(systemName: "bell.fill").foregroundStyle(palette.negative)
                }
            }

            Text(slot.remaining.clockString)
                .font(.display(44))
                .monospacedDigit()
                .foregroundStyle(timeColor)
                .contentTransition(.numericText())
                .frame(maxWidth: .infinity)

            // Remaining-time gauge: drains left to right in the player's color.
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule().fill(palette.textPrimary.opacity(0.10))
                    Capsule()
                        .fill(isExpired ? palette.negative : color)
                        .frame(width: max(6, geo.size.width * fraction))
                        .opacity(slot.remaining > 0 || isExpired ? 1 : 0.4)
                }
            }
            .frame(height: 5)
            .animation(.linear(duration: 0.2), value: fraction)
        }
        .padding(16)
        .frame(minHeight: 118)
        .background {
            let shape = RoundedRectangle(cornerRadius: 20, style: .continuous)
            shape
                .fill(palette.surface)
                .overlay { shape.strokeBorder(.white.opacity(0.25), lineWidth: 0.8).blendMode(.overlay) }
                .overlay {
                    shape.strokeBorder(isActive ? color : palette.textSecondary.opacity(0.15),
                                       lineWidth: isActive ? 2.5 : 1)
                }
                .shadow(color: isActive ? color.opacity(0.35) : .black.opacity(0.08),
                        radius: isActive ? 12 : 8, y: 4)
        }
        .scaleEffect(isActive && !reduceMotion ? 1.03 : 1)
        .contentShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(slot.name), \(Int(slot.remaining)) seconds remaining\(isActive ? ", running" : "")")
        .accessibilityHint(isActive ? "Tap to pause" : "Tap to start this player's clock")
        .accessibilityAddTraits(.isButton)
    }
}

#Preview {
    TurnTimerView()
        .modelContainer(for: Player.self, inMemory: true)
}
