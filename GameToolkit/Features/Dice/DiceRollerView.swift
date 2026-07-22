import SwiftUI
import SwiftData

struct DiceRollerView: View {
    @AppStorage(SettingsKey.diceCount) private var diceCount = 2
    @AppStorage(SettingsKey.diceSides) private var diceSides = 6
    @AppStorage(SettingsKey.diceShowTotal) private var showTotal = true
    @AppStorage(SettingsKey.diceColorHex) private var diceColorHex = Theme.themeDiceColor
    @AppStorage(SettingsKey.diceDotSize) private var dotSize = 3.0
    @AppStorage(SettingsKey.diceSelectedBag) private var selectedBagID = ""

    @Environment(\.palette) private var palette
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.scenePhase) private var scenePhase
    @Query(sort: \DiceBag.sortIndex) private var customBags: [DiceBag]
    @State private var engine = DiceEngine()
    @State private var motion = MotionTiltMonitor()
    @State private var showSetup = false

    /// The dice loaded from the selected bag, or nil for classic uniform mode.
    private var activeBag: (name: String, dice: [DieSpec])? {
        guard !selectedBagID.isEmpty else { return nil }
        if let custom = customBags.first(where: { $0.selectionID == selectedBagID }) {
            let dice = custom.dice
            if !dice.isEmpty { return (custom.name, dice) }
        }
        return nil
    }

    /// The die face follows the theme unless the user picked an explicit color in Settings.
    private var faceColor: Color {
        diceColorHex == Theme.themeDiceColor ? palette.diceFace : Color(hex: diceColorHex)
    }

    private var pipColor: Color {
        diceColorHex == Theme.themeDiceColor ? palette.dicePip : Color(hex: diceColorHex).readableForeground
    }

    private func faceColor(for die: DiceEngine.Die) -> Color {
        die.faceHex.map { Color(hex: $0) } ?? faceColor
    }

    private func pipColor(for die: DiceEngine.Die) -> Color {
        if let hex = die.pipHex { return Color(hex: hex) }
        if let faceHex = die.faceHex { return Color(hex: faceHex).readableForeground }
        return pipColor
    }

    /// Every theme sets its own table through the palette's `table` role.
    private var feltColor: Color { palette.table }

    private func applyConfiguration() {
        if let bag = activeBag {
            engine.configure(bag: bag.dice)
        } else {
            engine.configure(count: diceCount, sides: diceSides)
        }
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 14) {
                diceTray
                controls
                    .frame(maxWidth: 640)
            }
            .padding(.horizontal)
            .padding(.bottom, 8)
            .background(palette.background.ignoresSafeArea())
            .navigationTitle("Dice")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    ThemeSwitcherButton()
                }
                if engine.lockedCount > 0 {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button {
                            engine.unlockAll()
                        } label: {
                            Label("Release \(engine.lockedCount)", systemImage: "lock.open.fill")
                        }
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showSetup = true
                    } label: {
                        Label("Set Up Dice", systemImage: "slider.horizontal.3")
                    }
                }
            }
            .sheet(isPresented: $showSetup) {
                DiceSetupSheet()
                    .presentationDetents([.medium, .large])
                    .presentationDragIndicator(.visible)
            }
        }
        .onAppear {
            applyConfiguration()
            if !reduceMotion { motion.start() }
        }
        .onDisappear { motion.stop() }
        .onChange(of: diceCount) { _, _ in if activeBag == nil { applyConfiguration() } }
        .onChange(of: diceSides) { _, _ in if activeBag == nil { applyConfiguration() } }
        .onChange(of: selectedBagID) { _, _ in applyConfiguration() }
        .onChange(of: scenePhase) { _, phase in
            if phase == .active {
                if !reduceMotion { motion.start() }
            } else {
                motion.stop()
            }
        }
        .onShake { engine.roll() }
    }

    // MARK: - Dice tray

    private var diceTray: some View {
        ZStack(alignment: .top) {
            FeltSurface(felt: feltColor)

            GeometryReader { geo in
                let columns = gridColumns(for: engine.dice.count)
                ScrollView {
                    LazyVGrid(columns: columns, spacing: 14) {
                        ForEach(Array(engine.dice.enumerated()), id: \.element.id) { index, die in
                            DieView(
                                value: die.value,
                                sides: die.sides,
                                rollTrigger: die.rollTrigger,
                                tumbleSeed: die.tumbleSeed,
                                face: faceColor(for: die),
                                pip: pipColor(for: die),
                                isLocked: die.isLocked,
                                dotSize: dotSize,
                                seed: index,
                                ambientTilt: ambientTilt(for: index)
                            )
                            .aspectRatio(1, contentMode: .fit)
                            // Dice stay hand-sized even in a big Mac window or on iPad.
                            .frame(maxWidth: 220, maxHeight: 220)
                            .onTapGesture(count: 2) { engine.roll() }
                            .onTapGesture { engine.toggleLock(die.id) }
                        }
                    }
                    .padding(22)
                    .padding(.top, showTotal ? 30 : 0)
                    .frame(minHeight: geo.size.height, alignment: .center)
                }
                .scrollBounceBehavior(.basedOnSize)
            }

            if showTotal {
                totalBadge
                    .padding(.top, 14)
            }
        }
        // Double-tapping the felt (or a die) rolls; single-tapping a die still holds it.
        .onTapGesture(count: 2) { engine.roll() }
        .overlay(alignment: .bottom) {
            Text(engine.lockedCount > 0
                 ? "\(engine.lockedCount) held · double-tap or shake to roll the rest"
                 : "Tap a die to hold it · double-tap or shake to roll")
                .font(.footnote)
                .foregroundStyle(feltColor.readableForeground.opacity(0.75))
                .padding(.bottom, 10)
                .opacity(engine.isRolling ? 0 : 1)
        }
    }

    private var totalBadge: some View {
        HStack(spacing: 7) {
            Text("TOTAL")
                .font(.caption2.weight(.semibold))
                .kerning(1.2)
                .opacity(0.7)
            // The result is decided at the throw, so hide it until the dice have
            // visibly landed — no spoilers while they're still tumbling.
            if engine.isRolling {
                Image(systemName: "ellipsis")
                    .font(.title3.weight(.bold))
                    .symbolEffect(.variableColor.iterative)
            } else {
                Text("\(engine.total)")
                    .font(.display(.title3))
                    .monospacedDigit()
                    .contentTransition(.numericText())
            }
        }
        .foregroundStyle(palette.background)
        .padding(.horizontal, 16)
        .padding(.vertical, 7)
        .background(Capsule().fill(palette.textPrimary))
        .shadow(color: .black.opacity(0.25), radius: 5, y: 2)
        .animation(.snappy, value: engine.total)
        .animation(.snappy, value: engine.isRolling)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(engine.isRolling ? "Rolling" : "Total \(engine.total)")
    }

    // MARK: - Controls

    private var controls: some View {
        Button(action: { engine.roll() }) {
            Label(engine.isRolling ? "Rolling…" : "Roll", systemImage: "dice.fill")
        }
        .buttonStyle(PrimaryButtonStyle())
        .disabled(engine.isRolling || !engine.hasUnlockedDice)
        .accessibilityHint("Rolls every die that is not held")
    }

    /// Each die follows the device tilt at a slightly different strength, so the
    /// handful shifts with parallax instead of moving in lockstep.
    private func ambientTilt(for index: Int) -> CGSize {
        guard !reduceMotion else { return .zero }
        let depth = 0.85 + Double((index * 37) % 30) / 100
        return CGSize(width: motion.rollDegrees * depth, height: motion.pitchDegrees * depth)
    }

    /// Keeps the dice roughly square as the count grows.
    private func gridColumns(for count: Int) -> [GridItem] {
        let target: Int
        switch count {
        case 0...1: target = 1
        case 2...4: target = 2
        case 5...9: target = 3
        case 10...16: target = 4
        case 17...25: target = 5
        default: target = 6
        }
        return Array(repeating: GridItem(.flexible(), spacing: 14), count: max(1, min(target, count)))
    }
}

/// Everything about the throw in one sheet, common things first: which die,
/// how many, then the total badge and the user's own bags.
struct DiceSetupSheet: View {
    @AppStorage(SettingsKey.diceCount) private var diceCount = 2
    @AppStorage(SettingsKey.diceSides) private var diceSides = 6
    @AppStorage(SettingsKey.diceShowTotal) private var showTotal = true
    @AppStorage(SettingsKey.diceSelectedBag) private var selectedBagID = ""

    @Environment(\.palette) private var palette
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \DiceBag.sortIndex) private var customBags: [DiceBag]

    private let sideOptions = [4, 6, 8, 10, 12, 20, 100]
    private var bags: [DiceBag] { customBags.filter { !$0.dice.isEmpty } }
    private var usingBag: Bool {
        !selectedBagID.isEmpty && bags.contains { $0.selectionID == selectedBagID }
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Die") {
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 76), spacing: 8)], spacing: 8) {
                        ForEach(sideOptions, id: \.self) { side in
                            SelectableChip(
                                label: "d\(side)",
                                isSelected: !usingBag && side == diceSides
                            ) {
                                selectedBagID = ""
                                diceSides = side
                            }
                        }
                        if !usingBag, !sideOptions.contains(diceSides) {
                            SelectableChip(label: "d\(diceSides)", isSelected: true) {}
                        }
                    }
                    .listRowBackground(palette.surface)
                }

                Section {
                    Stepper(value: $diceCount, in: 1...30) {
                        Text("\(diceCount) \(diceCount == 1 ? "die" : "dice")")
                            .font(.headline)
                            .monospacedDigit()
                            .contentTransition(.numericText())
                    }
                    .disabled(usingBag)
                    .opacity(usingBag ? 0.4 : 1)

                    Toggle("Show total", isOn: $showTotal)
                }
                .listRowBackground(palette.surface)

                Section {
                    ForEach(bags) { bag in
                        Button {
                            Haptics.selection()
                            selectedBagID = selectedBagID == bag.selectionID ? "" : bag.selectionID
                        } label: {
                            HStack {
                                Text(bag.name.isEmpty ? "Untitled" : bag.name)
                                    .foregroundStyle(palette.textPrimary)
                                Spacer()
                                Text("\(bag.dice.count) dice")
                                    .font(.footnote)
                                    .foregroundStyle(palette.textSecondary)
                                if selectedBagID == bag.selectionID {
                                    Image(systemName: "checkmark")
                                        .fontWeight(.semibold)
                                        .foregroundStyle(palette.accent)
                                }
                            }
                        }
                        .listRowBackground(palette.surface)
                    }

                    NavigationLink {
                        DiceDesignerView()
                    } label: {
                        Label(bags.isEmpty ? "Create a Dice Set…" : "Edit Dice Sets…",
                              systemImage: bags.isEmpty ? "plus.circle" : "paintbrush")
                            .foregroundStyle(palette.accent)
                    }
                    .listRowBackground(palette.surface)
                } header: {
                    Text("Dice Sets")
                } footer: {
                    Text(bags.isEmpty
                         ? "Build a set of dice — mixed sizes and colors — and it will appear here, ready to roll."
                         : "Tap a set to roll with it, or tap again to go back to a single kind of die.")
                }
            }
            .scrollContentBackground(.hidden)
            .background(palette.background.ignoresSafeArea())
            .navigationTitle("Set Up Dice")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }.fontWeight(.semibold)
                }
            }
        }
    }
}

#Preview {
    DiceRollerView()
}
