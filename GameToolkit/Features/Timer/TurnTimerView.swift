import SwiftUI
import SwiftData

struct TurnTimerView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \Player.sortIndex) private var players: [Player]
    @AppStorage(SettingsKey.secondsPerPlayer) private var secondsPerPlayer = 90.0
    @AppStorage(SettingsKey.alarmDuration) private var alarmDuration = 3.0

    @State private var engine = TimerEngine()
    @State private var showingTimeSheet = false

    private let columns = [GridItem(.adaptive(minimum: 150), spacing: 14)]

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.backgroundGradient.ignoresSafeArea()

                VStack(spacing: 12) {
                    statusBar
                    GeometryReader { geo in
                        ScrollView {
                            LazyVGrid(columns: columns, spacing: 14) {
                                ForEach(engine.slots) { slot in
                                    PlayerTimerCard(
                                        slot: slot,
                                        isActive: engine.activeID == slot.id,
                                        isExpired: engine.expiredID == slot.id
                                    )
                                    .onTapGesture { engine.toggle(slot.id) }
                                }
                            }
                            .padding(.horizontal)
                            .padding(.vertical, 8)
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

    private var statusBar: some View {
        Group {
            if let activeID = engine.activeID, let slot = engine.slots.first(where: { $0.id == activeID }) {
                Label("\(PiDay.decorate(slot.name))'s turn", systemImage: "hourglass")
                    .foregroundStyle(Color(hex: slot.colorHex).readableForeground)
                    .padding(.horizontal, 16).padding(.vertical, 8)
                    .background(Capsule().fill(Color(hex: slot.colorHex).gradient))
            } else if engine.expiredID != nil {
                Label("Time's up!", systemImage: "bell.fill")
                    .foregroundStyle(.white)
                    .padding(.horizontal, 16).padding(.vertical, 8)
                    .background(Capsule().fill(Color.red.gradient))
            } else {
                Text("Tap a player to start their clock")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .padding(.vertical, 8)
            }
        }
        .animation(.easeInOut, value: engine.activeID)
    }
}

private struct PlayerTimerCard: View {
    let slot: TimerEngine.Slot
    let isActive: Bool
    let isExpired: Bool

    private var color: Color { Color(hex: slot.colorHex) }
    private var isLow: Bool { slot.remaining <= 10 && slot.remaining > 0 }

    var body: some View {
        VStack(spacing: 10) {
            HStack(spacing: 8) {
                Circle().fill(color).frame(width: 12, height: 12)
                Text(PiDay.decorate(slot.name))
                    .font(.headline)
                    .lineLimit(1)
                Spacer(minLength: 0)
                if isActive {
                    Image(systemName: "play.fill").foregroundStyle(color)
                }
            }

            Text(slot.remaining.clockString)
                .font(.system(size: 46, weight: .heavy, design: .rounded))
                .monospacedDigit()
                .foregroundStyle(isExpired ? Color.red : (isLow ? Color.orange : Color.primary))
                .contentTransition(.numericText())
                .frame(maxWidth: .infinity)
        }
        .frame(minHeight: 110)
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(.ultraThinMaterial)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .strokeBorder(isActive ? color : Color.secondary.opacity(0.15),
                              lineWidth: isActive ? 3 : 1)
        )
        .overlay(alignment: .topTrailing) {
            if isExpired {
                Image(systemName: "bell.fill")
                    .foregroundStyle(.red)
                    .padding(10)
            }
        }
        .scaleEffect(isActive ? 1.03 : 1)
        .shadow(color: isActive ? color.opacity(0.4) : .clear, radius: 12)
    }
}

#Preview {
    TurnTimerView()
        .modelContainer(for: Player.self, inMemory: true)
}
