import SwiftUI
import SwiftData

/// Settings ▸ Dice Designer: build custom dice bags, organize them into named
/// dice boxes, and customize each die's shape and colors. Bags appear as chips
/// on the Dice tab next to the classic d4…d100 options.
struct DiceDesignerView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.palette) private var palette
    @Query(sort: \DiceBag.sortIndex) private var bags: [DiceBag]
    @State private var showGameSearch = false

    /// Custom bags grouped by their dice box, boxes alphabetical, default box first.
    private var boxes: [(name: String, bags: [DiceBag])] {
        let grouped = Dictionary(grouping: bags) {
            $0.boxName.isEmpty ? DiceBag.defaultBox : $0.boxName
        }
        return grouped
            .sorted {
                if $0.key == DiceBag.defaultBox { return true }
                if $1.key == DiceBag.defaultBox { return false }
                return $0.key.localizedCaseInsensitiveCompare($1.key) == .orderedAscending
            }
            .map { (name: $0.key, bags: $0.value) }
    }

    var body: some View {
        List {
            Section {
                Button {
                    showGameSearch = true
                } label: {
                    Label {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Start from a Game…")
                                .foregroundStyle(palette.textPrimary)
                            Text("Search a board game and get a starter bag in its colors")
                                .font(.caption)
                                .foregroundStyle(palette.textSecondary)
                        }
                    } icon: {
                        Image(systemName: "magnifyingglass")
                            .foregroundStyle(palette.accent)
                    }
                }
                .listRowBackground(palette.surface)
            }

            ForEach(boxes, id: \.name) { box in
                Section {
                    ForEach(box.bags) { bag in
                        NavigationLink {
                            BagEditorView(bag: bag)
                        } label: {
                            VStack(alignment: .leading, spacing: 6) {
                                Text(bag.name.isEmpty ? "Untitled" : bag.name)
                                    .font(.headline)
                                BagPreviewStrip(dice: bag.dice)
                            }
                        }
                        .listRowBackground(palette.surface)
                    }
                    .onDelete { offsets in
                        for offset in offsets { context.delete(box.bags[offset]) }
                    }
                } header: {
                    Label(box.name, systemImage: "shippingbox")
                }
            }

            if bags.isEmpty {
                Section {
                    Text("Your bags appear on the Dice tab under the ⚙ dice button. Tap + to sew your first one.")
                        .font(.callout)
                        .foregroundStyle(palette.textSecondary)
                        .listRowBackground(palette.surface)
                }
            }
        }
        .scrollContentBackground(.hidden)
        .background(palette.background.ignoresSafeArea())
        .navigationTitle("Dice Designer")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    addBag()
                } label: {
                    Label("New Bag", systemImage: "plus")
                }
            }
        }
        .sheet(isPresented: $showGameSearch) {
            NavigationStack {
                GameStarterBagView { name, dice in
                    let bag = DiceBag(
                        name: name,
                        dice: dice,
                        sortIndex: (bags.map(\.sortIndex).max() ?? -1) + 1
                    )
                    context.insert(bag)
                    Haptics.notify(.success)
                    showGameSearch = false
                }
                .padding()
                .background(palette.background.ignoresSafeArea())
                .navigationTitle("Start from a Game")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Cancel") { showGameSearch = false }
                    }
                }
            }
        }
    }

    private func addBag() {
        let bag = DiceBag(
            name: "New Bag",
            dice: [DieSpec(), DieSpec()],
            sortIndex: (bags.map(\.sortIndex).max() ?? -1) + 1
        )
        context.insert(bag)
        Haptics.impact(.light)
    }

}

/// Search the game-theme repository and spin a starter dice bag out of any game's
/// colors — a fast, fun way to kit the app out for tonight's table. Works fully
/// offline against the bundled and cached theme lists; queries never leave the phone.
struct GameStarterBagView: View {
    @Environment(\.palette) private var palette
    @Environment(\.colorScheme) private var colorScheme
    @State private var service = GameThemeService.shared
    @State private var query = ""

    /// Called with the bag name and starter dice when the user picks a game.
    var onPick: (String, [DieSpec]) -> Void

    private var results: [AppTheme] { service.search(query) }

    var body: some View {
        VStack(spacing: 14) {
            HStack(spacing: 8) {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(palette.textSecondary)
                TextField("Search for a board game", text: $query)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
            }
            .padding(10)
            .background(RoundedRectangle(cornerRadius: 12).fill(palette.surface))

            if results.isEmpty {
                VStack(spacing: 8) {
                    Image(systemName: "bag")
                        .font(.title2)
                        .foregroundStyle(palette.textSecondary.opacity(0.6))
                    Text("No matching game yet")
                        .font(.headline)
                        .foregroundStyle(palette.textPrimary)
                    Text("More games arrive over time — you can always build a bag from scratch.")
                        .font(.caption)
                        .foregroundStyle(palette.textSecondary)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 30)
                Spacer()
            } else {
                ScrollView {
                    LazyVStack(spacing: 10) {
                        ForEach(results) { theme in
                            resultRow(theme)
                        }
                    }
                    .padding(.bottom, 8)
                }
                .scrollBounceBehavior(.basedOnSize)
            }

            Text("Fan-made color schemes inspired by each game's look. Not affiliated with or endorsed by any publisher.")
                .font(.caption2)
                .foregroundStyle(palette.textSecondary.opacity(0.8))
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
        .task { await service.refreshIfNeeded() }
    }

    private func resultRow(_ theme: AppTheme) -> some View {
        let dice = starterDice(for: theme)
        return Button {
            onPick(theme.gameDisplayName, dice)
        } label: {
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 6) {
                    Text(theme.gameDisplayName)
                        .font(.headline)
                        .foregroundStyle(palette.textPrimary)
                    BagPreviewStrip(dice: dice)
                }
                Spacer()
                Image(systemName: "plus.circle.fill")
                    .font(.title3)
                    .foregroundStyle(palette.accent)
            }
            .padding(12)
            .background(RoundedRectangle(cornerRadius: 14).fill(palette.surface))
        }
        .buttonStyle(.plain)
    }

    /// A starter set in the game's colors: a pair in the theme's dice colors plus
    /// one die per leading player color. A jumping-off point, not a rulebook.
    private func starterDice(for theme: AppTheme) -> [DieSpec] {
        let themePalette = theme.palette(for: colorScheme)
        var dice = [
            DieSpec(sides: 6, faceHex: themePalette.diceFaceHex, pipHex: themePalette.dicePipHex),
            DieSpec(sides: 6, faceHex: themePalette.diceFaceHex, pipHex: themePalette.dicePipHex),
        ]
        for hex in themePalette.playerHexes.prefix(3) {
            dice.append(DieSpec(
                sides: 6,
                faceHex: hex,
                pipHex: Color(hex: hex).readableForeground.hexString
            ))
        }
        return dice
    }
}

/// A miniature render of every die in a bag, using the real polyhedra.
struct BagPreviewStrip: View {
    let dice: [DieSpec]

    @Environment(\.palette) private var palette

    var body: some View {
        HStack(spacing: 5) {
            ForEach(dice.prefix(8)) { spec in
                DieView(
                    value: min(spec.sides, 99),
                    sides: spec.sides,
                    face: spec.faceHex.map { Color(hex: $0) } ?? palette.diceFace,
                    pip: spec.pipHex.map { Color(hex: $0) } ?? palette.dicePip,
                    dotSize: 1
                )
                .frame(width: 30, height: 30)
            }
            if dice.count > 8 {
                Text("+\(dice.count - 8)")
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(palette.textSecondary)
            }
        }
    }
}

/// Edits one custom bag: its name, which dice box it lives in, and every die's
/// shape and colors.
struct BagEditorView: View {
    @Bindable var bag: DiceBag
    @Environment(\.palette) private var palette

    private let sideOptions = [4, 6, 8, 10, 12, 20, 100]

    var body: some View {
        Form {
            Section {
                HStack(spacing: 6) {
                    Spacer()
                    BagPreviewStrip(dice: bag.dice)
                    Spacer()
                }
                .listRowBackground(Color.clear)
            }

            Section("Bag") {
                Group {
                    TextField("Bag name", text: $bag.name)
                    TextField("Dice box", text: $bag.boxName, prompt: Text(DiceBag.defaultBox))
                }
                .listRowBackground(palette.surface)
            }

            Section {
                ForEach(Array(bag.dice.enumerated()), id: \.element.id) { index, spec in
                    dieRow(spec: spec, index: index)
                        .listRowBackground(palette.surface)
                }
                .onDelete { offsets in
                    var dice = bag.dice
                    dice.remove(atOffsets: offsets)
                    bag.dice = dice
                }
                .onMove { source, destination in
                    var dice = bag.dice
                    dice.move(fromOffsets: source, toOffset: destination)
                    bag.dice = dice
                }

                Group {
                    Button {
                        var dice = bag.dice
                        let template = dice.last
                        dice.append(DieSpec(
                            sides: template?.sides ?? 6,
                            faceHex: template?.faceHex,
                            pipHex: template?.pipHex
                        ))
                        bag.dice = dice
                        Haptics.impact(.light)
                    } label: {
                        Label("Add Die", systemImage: "plus")
                    }

                    Button {
                        let template = bag.dice.last
                        var dice = bag.dice
                        dice.append(contentsOf: sideOptions.map {
                            DieSpec(sides: $0, faceHex: template?.faceHex, pipHex: template?.pipHex)
                        })
                        bag.dice = dice
                        Haptics.impact(.light)
                    } label: {
                        Label("Add Full Polyset (d4–d100)", systemImage: "plus.square.on.square")
                    }
                }
                .listRowBackground(palette.surface)
            } header: {
                Text("Dice")
            } footer: {
                Text("Colors default to the current theme. Swipe to remove a die; drag to reorder.")
            }
        }
        .scrollContentBackground(.hidden)
        .background(palette.background.ignoresSafeArea())
        .navigationTitle(bag.name.isEmpty ? "Bag" : bag.name)
        .navigationBarTitleDisplayMode(.inline)
    }

    @ViewBuilder
    private func dieRow(spec: DieSpec, index: Int) -> some View {
        HStack(spacing: 12) {
            DieView(
                value: min(spec.sides, 99),
                sides: spec.sides,
                face: spec.faceHex.map { Color(hex: $0) } ?? palette.diceFace,
                pip: spec.pipHex.map { Color(hex: $0) } ?? palette.dicePip,
                dotSize: 1
            )
            .frame(width: 40, height: 40)

            Menu {
                ForEach(sideOptions, id: \.self) { side in
                    Button("d\(side)") { updateDie(at: index) { $0.sides = side } }
                }
            } label: {
                Text("d\(spec.sides)")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(palette.accent)
                    .frame(minWidth: 44)
            }

            Spacer(minLength: 0)

            ColorPicker(
                "Face color",
                selection: Binding(
                    get: { spec.faceHex.map { Color(hex: $0) } ?? palette.diceFace },
                    set: { color in updateDie(at: index) { $0.faceHex = color.hexString } }
                ),
                supportsOpacity: false
            )
            .labelsHidden()

            ColorPicker(
                "Number color",
                selection: Binding(
                    get: { spec.pipHex.map { Color(hex: $0) } ?? palette.dicePip },
                    set: { color in updateDie(at: index) { $0.pipHex = color.hexString } }
                ),
                supportsOpacity: false
            )
            .labelsHidden()

            Button {
                updateDie(at: index) {
                    $0.faceHex = nil
                    $0.pipHex = nil
                }
            } label: {
                Image(systemName: "arrow.counterclockwise")
                    .font(.footnote)
            }
            .buttonStyle(.borderless)
            .accessibilityLabel("Reset colors to theme")
        }
    }

    private func updateDie(at index: Int, _ mutate: (inout DieSpec) -> Void) {
        var dice = bag.dice
        guard dice.indices.contains(index) else { return }
        mutate(&dice[index])
        bag.dice = dice
    }
}

#Preview {
    NavigationStack {
        DiceDesignerView()
    }
    .modelContainer(for: [Player.self, DiceBag.self], inMemory: true)
}
