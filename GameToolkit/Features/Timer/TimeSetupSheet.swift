import SwiftUI

/// Lets the player pick a per-turn time budget, either from quick presets or a custom value.
struct TimeSetupSheet: View {
    let currentSeconds: Double
    let onApply: (Double) -> Void

    @Environment(\.dismiss) private var dismiss
    @Environment(\.palette) private var palette
    @State private var minutes: Int
    @State private var seconds: Int

    private let presets: [Double] = [30, 60, 90, 120, 180, 300, 600]
    private let columns = [GridItem(.adaptive(minimum: 90), spacing: 12)]

    init(currentSeconds: Double, onApply: @escaping (Double) -> Void) {
        self.currentSeconds = currentSeconds
        self.onApply = onApply
        _minutes = State(initialValue: Int(currentSeconds) / 60)
        _seconds = State(initialValue: Int(currentSeconds) % 60)
    }

    private var customTotal: Double { Double(minutes * 60 + seconds) }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    Text("Quick presets")
                        .font(.headline)
                    LazyVGrid(columns: columns, spacing: 12) {
                        ForEach(presets, id: \.self) { preset in
                            Button {
                                Haptics.selection()
                                onApply(preset)
                                dismiss()
                            } label: {
                                Text(preset.clockString)
                                    .font(.display(.title3))
                                    .monospacedDigit()
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 16)
                                    .background(
                                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                                            .fill(preset == currentSeconds
                                                  ? AnyShapeStyle(palette.accent.gradient)
                                                  : AnyShapeStyle(palette.surface))
                                    )
                                    .overlay {
                                        if preset != currentSeconds {
                                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                                .strokeBorder(palette.textSecondary.opacity(0.25), lineWidth: 1)
                                        }
                                    }
                                    .foregroundStyle(preset == currentSeconds
                                                     ? palette.accent.readableForeground
                                                     : palette.textPrimary)
                            }
                            .buttonStyle(.plain)
                        }
                    }

                    Divider().padding(.vertical, 4)

                    Text("Custom")
                        .font(.headline)
                    HStack(spacing: 0) {
                        Picker("Minutes", selection: $minutes) {
                            ForEach(0...60, id: \.self) { Text("\($0) min").tag($0) }
                        }
                        .pickerStyle(.wheel)
                        Picker("Seconds", selection: $seconds) {
                            ForEach(0...59, id: \.self) { Text("\($0) sec").tag($0) }
                        }
                        .pickerStyle(.wheel)
                    }
                    .frame(height: 130)

                    Button {
                        onApply(max(5, customTotal))
                        dismiss()
                    } label: {
                        Text("Set \(max(5, Int(customTotal)).clockString)")
                    }
                    .buttonStyle(PrimaryButtonStyle())
                    .disabled(customTotal < 5)
                }
                .padding()
            }
            .background(palette.background.ignoresSafeArea())
            .navigationTitle("Time per Turn")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }
}
