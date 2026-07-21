import SwiftUI

struct DiceRollerView: View {
    @AppStorage(SettingsKey.diceCount) private var diceCount = 2
    @AppStorage(SettingsKey.diceSides) private var diceSides = 6
    @AppStorage(SettingsKey.diceShowTotal) private var showTotal = true
    @AppStorage(SettingsKey.diceColorHex) private var diceColorHex = Theme.themeDiceColor
    @AppStorage(SettingsKey.diceDotSize) private var dotSize = 3.0

    @Environment(\.palette) private var palette
    @State private var engine = DiceEngine()

    private let sideOptions = [4, 6, 8, 10, 12, 20, 100]

    /// The die face follows the theme unless the user picked an explicit color in Settings.
    private var faceColor: Color {
        diceColorHex == Theme.themeDiceColor ? palette.diceFace : Color(hex: diceColorHex)
    }

    private var pipColor: Color {
        diceColorHex == Theme.themeDiceColor ? palette.dicePip : Color(hex: diceColorHex).readableForeground
    }

    /// Every theme sets its own table through the palette's `table` role.
    private var feltColor: Color { palette.table }

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
            }
        }
        .onAppear { engine.configure(count: diceCount, sides: diceSides) }
        .onChange(of: diceCount) { _, new in engine.configure(count: new, sides: diceSides) }
        .onChange(of: diceSides) { _, new in engine.configure(count: diceCount, sides: new) }
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
                                sides: engine.sides,
                                spin: die.spin,
                                face: faceColor,
                                pip: pipColor,
                                isLocked: die.isLocked,
                                dotSize: dotSize,
                                seed: index
                            )
                            .aspectRatio(1, contentMode: .fit)
                            // Dice stay hand-sized even in a big Mac window or on iPad.
                            .frame(maxWidth: 220, maxHeight: 220)
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
        .scaleEffect(engine.isRolling ? 0.985 : 1)
        .animation(.spring(response: 0.3, dampingFraction: 0.6), value: engine.rollID)
        .overlay(alignment: .bottom) {
            Text(engine.lockedCount > 0
                 ? "\(engine.lockedCount) held · shake to roll the rest"
                 : "Tap a die to hold it · shake to roll")
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
            Text("\(engine.total)")
                .font(.display(.title3))
                .monospacedDigit()
                .contentTransition(.numericText())
        }
        .foregroundStyle(palette.background)
        .padding(.horizontal, 16)
        .padding(.vertical, 7)
        .background(Capsule().fill(palette.textPrimary))
        .shadow(color: .black.opacity(0.25), radius: 5, y: 2)
        .animation(.snappy, value: engine.total)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Total \(engine.total)")
    }

    // MARK: - Controls

    private var controls: some View {
        VStack(spacing: 12) {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(sideOptions, id: \.self) { side in
                        SelectableChip(label: "d\(side)", isSelected: side == diceSides) {
                            diceSides = side
                        }
                    }
                    if !sideOptions.contains(diceSides) {
                        SelectableChip(label: "d\(diceSides)", isSelected: true) {}
                    }
                }
                .padding(.horizontal, 2)
            }

            HStack(spacing: 12) {
                countStepper

                Spacer(minLength: 0)

                Button {
                    Haptics.selection()
                    showTotal.toggle()
                } label: {
                    Image(systemName: "sum")
                        .font(.body.weight(.bold))
                        .foregroundStyle(showTotal ? palette.accent.readableForeground : palette.textPrimary)
                        .frame(width: 40, height: 40)
                        .background {
                            Circle().fill(showTotal ? palette.accent : palette.textPrimary.opacity(0.07))
                        }
                }
                .buttonStyle(.plain)
                .accessibilityLabel(showTotal ? "Hide total" : "Show total")
            }

            Button(action: { engine.roll() }) {
                Label(engine.isRolling ? "Rolling…" : "Roll", systemImage: "dice.fill")
            }
            .buttonStyle(PrimaryButtonStyle())
            .disabled(engine.isRolling || !engine.hasUnlockedDice)
            .accessibilityHint("Rolls every die that is not held")
        }
    }

    private var countStepper: some View {
        HStack(spacing: 14) {
            stepButton("minus") { diceCount = max(1, diceCount - 1) }
                .disabled(diceCount <= 1)

            Text("\(diceCount) \(diceCount == 1 ? "die" : "dice")")
                .font(.headline)
                .monospacedDigit()
                .contentTransition(.numericText())
                .frame(minWidth: 64)

            stepButton("plus") { diceCount = min(30, diceCount + 1) }
                .disabled(diceCount >= 30)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(Capsule().fill(palette.textPrimary.opacity(0.07)))
        .accessibilityElement(children: .contain)
    }

    private func stepButton(_ symbol: String, action: @escaping () -> Void) -> some View {
        Button {
            Haptics.selection()
            withAnimation(.snappy) { action() }
        } label: {
            Image(systemName: symbol)
                .font(.subheadline.weight(.bold))
                .foregroundStyle(palette.textPrimary)
                .frame(width: 32, height: 32)
                .contentShape(Circle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(symbol == "plus" ? "Add a die" : "Remove a die")
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

#Preview {
    DiceRollerView()
}
