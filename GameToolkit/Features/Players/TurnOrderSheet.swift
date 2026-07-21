import SwiftUI

/// Shuffles the roster into a random turn order. The original app surfaced this by shaking the
/// scorecard; it's now also reachable from the menu so it's actually discoverable.
struct TurnOrderSheet: View {
    let players: [Player]
    @Environment(\.dismiss) private var dismiss
    @Environment(\.palette) private var palette
    @State private var order: [Player] = []

    var body: some View {
        NavigationStack {
            List {
                Section {
                    ForEach(Array(order.enumerated()), id: \.element.id) { index, player in
                        HStack(spacing: 14) {
                            ZStack {
                                Circle().fill(player.color(in: palette).gradient)
                                Text("\(index + 1)")
                                    .font(.headline.weight(.bold))
                                    .foregroundStyle(player.color(in: palette).readableForeground)
                            }
                            .frame(width: 34, height: 34)

                            Text(PiDay.decorate(player.name.isEmpty ? "Unnamed" : player.name))
                                .font(.headline)
                        }
                        .padding(.vertical, 2)
                    }
                } footer: {
                    Text("Shake the device on the Scores tab to shuffle again.")
                }
            }
            .navigationTitle("Turn Order")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button {
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.75)) {
                            order.shuffle()
                        }
                        Haptics.impact(.medium)
                    } label: {
                        Label("Shuffle", systemImage: "shuffle")
                    }
                }
            }
        }
        .onAppear {
            order = players.shuffled()
            Haptics.notify(.success)
        }
    }
}
