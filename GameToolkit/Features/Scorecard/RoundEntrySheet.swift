import SwiftUI
import SwiftData

/// Enters or edits every player's score for a single round.
struct RoundEntrySheet: View {
    let players: [Player]
    let round: Int
    let onSave: ([Int]) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var values: [Int]
    @FocusState private var focusedField: Int?

    init(players: [Player], round: Int, onSave: @escaping ([Int]) -> Void) {
        self.players = players
        self.round = round
        self.onSave = onSave
        _values = State(initialValue: players.map { $0.score(inRound: round) })
    }

    private var roundTotal: Int { values.reduce(0, +) }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    ForEach(Array(players.enumerated()), id: \.element.id) { index, player in
                        row(index: index, player: player)
                    }
                } header: {
                    Text("Scores for round \(round + 1)")
                } footer: {
                    Text("Round total: \(roundTotal)")
                        .contentTransition(.numericText())
                }
            }
            .navigationTitle("Round \(round + 1)")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        onSave(values)
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button("Done") { focusedField = nil }
                }
            }
        }
    }

    private func row(index: Int, player: Player) -> some View {
        HStack(spacing: 12) {
            Circle()
                .fill(player.color.gradient)
                .frame(width: 14, height: 14)

            Text(PiDay.decorate(player.name.isEmpty ? "Unnamed" : player.name))
                .font(.body.weight(.medium))
                .lineLimit(1)

            Spacer(minLength: 8)

            TextField("0", value: binding(for: index), format: .number)
                .keyboardType(.numbersAndPunctuation)
                .multilineTextAlignment(.trailing)
                .font(.title3.weight(.semibold).monospacedDigit())
                .frame(width: 70)
                .focused($focusedField, equals: index)

            Stepper("", value: binding(for: index))
                .labelsHidden()
        }
    }

    private func binding(for index: Int) -> Binding<Int> {
        Binding(
            get: { index < values.count ? values[index] : 0 },
            set: { newValue in
                guard index < values.count else { return }
                values[index] = newValue
            }
        )
    }
}
