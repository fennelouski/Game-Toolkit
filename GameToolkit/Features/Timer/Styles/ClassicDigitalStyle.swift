import SwiftUI

/// The original look: big serif digits over a thin drain gauge.
struct ClassicDigitalStyle: View {
    @Environment(\.palette) private var palette
    let model: TimerDisplayModel

    private var isLow: Bool {
        model.isFixedLength && model.remaining <= 10 && model.remaining > 0
    }

    private var timeColor: Color {
        if model.isExpired { return palette.negative }
        if isLow { return palette.warning }
        return palette.textPrimary
    }

    private var timeText: String {
        model.isCountUp ? model.elapsed.clockStringRoundedDown : model.remaining.clockString
    }

    var body: some View {
        GeometryReader { geo in
            VStack(spacing: geo.size.height * 0.08) {
                Text(timeText)
                    .font(.display(min(max(44, geo.size.width * 0.26), geo.size.height * 0.6)))
                    .monospacedDigit()
                    .minimumScaleFactor(0.4)
                    .lineLimit(1)
                    .foregroundStyle(timeColor)
                    .contentTransition(.numericText())
                    .frame(maxWidth: .infinity)

                if model.isFixedLength {
                    // Remaining-time gauge: drains left to right in the player's color.
                    GeometryReader { gauge in
                        ZStack(alignment: .leading) {
                            Capsule().fill(palette.textPrimary.opacity(0.10))
                            Capsule()
                                .fill(model.isExpired ? palette.negative : model.playerColor)
                                .frame(width: max(6, gauge.size.width * model.fraction))
                                .opacity(model.remaining > 0 || model.isExpired ? 1 : 0.4)
                        }
                    }
                    .frame(height: 5)
                    .animation(.linear(duration: 0.2), value: model.fraction)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
        }
    }
}

extension Double {
    /// `mm:ss` rounding down — a count-up clock shows `0:00` for the first second.
    var clockStringRoundedDown: String {
        Int(self.rounded(.down)).clockString
    }
}
