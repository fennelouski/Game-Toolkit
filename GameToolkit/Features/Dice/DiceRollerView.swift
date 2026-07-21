import SwiftUI

struct DiceRollerView: View {
    @AppStorage(SettingsKey.diceCount) private var diceCount = 2
    @AppStorage(SettingsKey.diceSides) private var diceSides = 6
    @AppStorage(SettingsKey.diceShowTotal) private var showTotal = true
    @AppStorage(SettingsKey.diceColorHex) private var diceColorHex = "#E63946"

    @State private var engine = DiceEngine()

    private let sideOptions = [4, 6, 8, 10, 12, 20, 100]
    private var diceColor: Color { Color(hex: diceColorHex) }

    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                diceArea
                controls
            }
            .padding(.horizontal)
            .padding(.bottom, 8)
            .background(Theme.backgroundGradient.ignoresSafeArea())
            .navigationTitle("Dice")
            .navigationBarTitleDisplayMode(.inline)
        }
        .onAppear { engine.configure(count: diceCount, sides: diceSides) }
        .onChange(of: diceCount) { _, new in engine.configure(count: new, sides: diceSides) }
        .onChange(of: diceSides) { _, new in engine.configure(count: diceCount, sides: new) }
        .onShake { engine.roll() }
    }

    // MARK: - Dice area

    private var diceArea: some View {
        ZStack(alignment: .top) {
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 28, style: .continuous)
                        .strokeBorder(diceColor.opacity(0.25), lineWidth: 1)
                )

            GeometryReader { geo in
                let columns = gridColumns(for: engine.dice.count, in: geo.size)
                ScrollView {
                    LazyVGrid(columns: columns, spacing: 16) {
                        ForEach(engine.dice) { die in
                            DieView(value: die.value, sides: engine.sides, spin: die.spin, color: diceColor)
                                .aspectRatio(1, contentMode: .fit)
                        }
                    }
                    .padding(24)
                    .frame(minHeight: geo.size.height)
                }
                .scrollBounceBehavior(.basedOnSize)
            }

            if showTotal {
                totalPill
                    .padding(.top, 14)
            }
        }
        .contentShape(Rectangle())
        .onTapGesture { engine.roll() }
        .scaleEffect(engine.isRolling ? 0.98 : 1)
        .animation(.spring(response: 0.3, dampingFraction: 0.6), value: engine.rollID)
        .overlay(alignment: .bottom) {
            Text("Tap the dice or shake to roll")
                .font(.footnote)
                .foregroundStyle(.secondary)
                .padding(.bottom, 12)
                .opacity(engine.isRolling ? 0 : 1)
        }
    }

    private var totalPill: some View {
        HStack(spacing: 8) {
            Image(systemName: "sum")
                .font(.subheadline.weight(.bold))
            Text("\(engine.total)")
                .font(.title2.weight(.heavy).monospacedDigit())
                .contentTransition(.numericText())
        }
        .foregroundStyle(diceColor.readableForeground)
        .padding(.horizontal, 18)
        .padding(.vertical, 8)
        .background(Capsule().fill(diceColor.gradient))
        .shadow(color: .black.opacity(0.15), radius: 6, y: 3)
        .animation(.snappy, value: engine.total)
    }

    // MARK: - Controls

    private var controls: some View {
        VStack(spacing: 14) {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(sideOptions, id: \.self) { side in
                        sideChip(side)
                    }
                }
                .padding(.horizontal, 2)
            }

            HStack(spacing: 16) {
                Stepper(value: $diceCount, in: 1...12) {
                    HStack(spacing: 6) {
                        Image(systemName: "dice")
                        Text("\(diceCount) dice")
                            .font(.headline)
                            .contentTransition(.numericText())
                    }
                }
                .fixedSize()

                Spacer(minLength: 0)

                Toggle(isOn: $showTotal) {
                    Image(systemName: "sum")
                }
                .toggleStyle(.button)
                .tint(.accentColor)
            }

            Button(action: { engine.roll() }) {
                Label(engine.isRolling ? "Rolling…" : "Roll", systemImage: "dice.fill")
                    .font(.title3.weight(.bold))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .buttonBorderShape(.capsule)
            .disabled(engine.isRolling)
        }
    }

    private func sideChip(_ side: Int) -> some View {
        let selected = side == diceSides
        return Button {
            Haptics.selection()
            diceSides = side
        } label: {
            Text("d\(side)")
                .font(.subheadline.weight(.bold))
                .padding(.horizontal, 16)
                .padding(.vertical, 9)
                .background(
                    Capsule().fill(selected ? AnyShapeStyle(Color.accentColor.gradient) : AnyShapeStyle(.ultraThinMaterial))
                )
                .foregroundStyle(selected ? .white : .primary)
                .overlay(Capsule().strokeBorder(.secondary.opacity(selected ? 0 : 0.2)))
        }
        .buttonStyle(.plain)
    }

    private func gridColumns(for count: Int, in size: CGSize) -> [GridItem] {
        let target = count <= 1 ? 1 : min(count <= 4 ? 2 : (count <= 9 ? 3 : 4), count)
        return Array(repeating: GridItem(.flexible(), spacing: 16), count: max(1, target))
    }
}

#Preview {
    DiceRollerView()
}
