import SwiftUI

/// Competition-style solve timer: nothing but huge digits, with centiseconds once the
/// clock is under a minute. (The look cube solvers know, minus anyone's trademarks.)
struct SpeedcubeStyle: View {
    @Environment(\.palette) private var palette
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    let model: TimerDisplayModel

    var body: some View {
        GeometryReader { geo in
            TimelineView(.animation(minimumInterval: reduceMotion ? 0.1 : 1 / 60,
                                    paused: !model.isActive || model.isPreview)) { context in
                let seconds = model.isCountUp
                    ? model.elapsed(at: context.date)
                    : model.remaining(at: context.date)
                Text(formatted(seconds))
                    .font(.system(size: fontSize(for: geo.size), weight: .semibold, design: .rounded))
                    .monospacedDigit()
                    .minimumScaleFactor(0.3)
                    .lineLimit(1)
                    .foregroundStyle(digitColor)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
            }
        }
        .padding(.horizontal, 4)
    }

    private var digitColor: Color {
        if model.isExpired { return palette.negative }
        if !model.isActive && !model.isPaused { return palette.textPrimary.opacity(0.45) }
        return palette.textPrimary
    }

    private func fontSize(for size: CGSize) -> CGFloat {
        min(max(40, size.width * 0.24), size.height * 0.7)
    }

    /// `m:ss` above a minute, `SS.cc` centiseconds below it — the solve-timer convention.
    private func formatted(_ seconds: Double) -> String {
        let clamped = max(0, seconds)
        if clamped >= 60 {
            let whole = Int(clamped)
            let tenths = Int(clamped * 10) % 10
            return String(format: "%d:%02d.%d", whole / 60, whole % 60, tenths)
        }
        return String(format: "%05.2f", clamped)
    }
}
