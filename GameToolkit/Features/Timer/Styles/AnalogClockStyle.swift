import SwiftUI

/// A clock face whose hands sweep the timer: the minute hand maps the full budget onto
/// one revolution, the thin second hand in the player's color ticks the seconds.
struct AnalogClockStyle: View {
    @Environment(\.palette) private var palette
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    let model: TimerDisplayModel

    var body: some View {
        GeometryReader { geo in
            let diameter = min(geo.size.width, geo.size.height)
            TimelineView(.animation(minimumInterval: reduceMotion ? 1 : 1 / 30,
                                    paused: !model.isActive || model.isPreview)) { context in
                let seconds = model.isCountUp
                    ? model.elapsed(at: context.date)
                    : model.remaining(at: context.date)
                dial(diameter: diameter, seconds: reduceMotion ? seconds.rounded() : seconds)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
            }
        }
    }

    private func dial(diameter: CGFloat, seconds: Double) -> some View {
        ZStack {
            Circle()
                .fill(palette.surfaceElevated)
                .overlay {
                    Circle().strokeBorder(
                        model.isExpired ? palette.negative : palette.textSecondary.opacity(0.35),
                        lineWidth: max(1.5, diameter * 0.012))
                }

            // 60 ticks, every fifth one heavier.
            ForEach(0..<60, id: \.self) { tick in
                let major = tick % 5 == 0
                Capsule()
                    .fill(palette.textSecondary.opacity(major ? 0.8 : 0.35))
                    .frame(width: major ? diameter * 0.014 : diameter * 0.007,
                           height: major ? diameter * 0.07 : diameter * 0.04)
                    .offset(y: -diameter * 0.44)
                    .rotationEffect(.degrees(Double(tick) * 6))
            }

            hand(length: diameter * 0.26, width: diameter * 0.03,
                 color: palette.textPrimary, turns: minuteTurns(seconds: seconds))
            hand(length: diameter * 0.38, width: diameter * 0.012,
                 color: model.playerColor, turns: seconds / 60, tail: diameter * 0.08)

            Circle()
                .fill(model.playerColor)
                .frame(width: diameter * 0.055, height: diameter * 0.055)
        }
        .frame(width: diameter, height: diameter)
    }

    /// One face revolution spans the whole budget (count-up borrows a 60-minute face).
    private func minuteTurns(seconds: Double) -> Double {
        guard let total = model.total, total > 0 else { return seconds / 3600 }
        return seconds / total
    }

    private func hand(length: CGFloat, width: CGFloat, color: Color,
                      turns: Double, tail: CGFloat = 0) -> some View {
        Capsule()
            .fill(color)
            .frame(width: width, height: length + tail)
            .offset(y: -(length - tail) / 2)
            .rotationEffect(.radians(turns * 2 * .pi))
            .shadow(color: .black.opacity(0.15), radius: 1, y: 1)
    }
}
