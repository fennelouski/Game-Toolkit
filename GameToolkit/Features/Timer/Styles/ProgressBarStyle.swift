import SwiftUI

/// A thick draining bar with the time above it. Fixed-length timers only.
struct ProgressBarStyle: View {
    @Environment(\.palette) private var palette
    let model: TimerDisplayModel

    private var isLow: Bool { model.remaining <= 10 && model.remaining > 0 }

    private var fillColor: Color {
        if model.isExpired { return palette.negative }
        if isLow { return palette.warning }
        return model.playerColor
    }

    var body: some View {
        GeometryReader { geo in
            let barHeight = min(max(22, geo.size.height * 0.22), 64)
            VStack(spacing: geo.size.height * 0.08) {
                Text(model.remaining.clockString)
                    .font(.display(min(max(36, geo.size.width * 0.18), geo.size.height * 0.42)))
                    .monospacedDigit()
                    .minimumScaleFactor(0.4)
                    .lineLimit(1)
                    .foregroundStyle(model.isExpired ? palette.negative : palette.textPrimary)
                    .contentTransition(.numericText())

                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: barHeight / 2, style: .continuous)
                        .fill(palette.textPrimary.opacity(0.10))
                    RoundedRectangle(cornerRadius: barHeight / 2, style: .continuous)
                        .fill(fillColor.gradient)
                        .frame(width: max(barHeight, geo.size.width * model.fraction))
                        .animation(.linear(duration: 0.2), value: model.fraction)
                }
                .frame(height: barHeight)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
        }
    }
}
