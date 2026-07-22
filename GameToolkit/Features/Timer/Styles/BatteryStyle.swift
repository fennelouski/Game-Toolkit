import SwiftUI

/// A power gauge draining from full to empty, with the time inside the cell.
struct BatteryStyle: View {
    @Environment(\.palette) private var palette
    let model: TimerDisplayModel

    private var fillColor: Color {
        if model.isExpired || model.fraction <= 0.1 { return palette.negative }
        if model.fraction <= 0.3 { return palette.warning }
        return palette.positive
    }

    var body: some View {
        GeometryReader { geo in
            let bodyWidth = min(geo.size.width * 0.86, geo.size.height * 1.9)
            let bodyHeight = bodyWidth * 0.46
            let corner = bodyHeight * 0.22
            let inset = bodyHeight * 0.09

            ZStack {
                HStack(spacing: bodyWidth * 0.015) {
                    ZStack {
                        RoundedRectangle(cornerRadius: corner, style: .continuous)
                            .strokeBorder(palette.textPrimary.opacity(0.5), lineWidth: max(2, bodyHeight * 0.045))

                        GeometryReader { cell in
                            RoundedRectangle(cornerRadius: corner - inset, style: .continuous)
                                .fill(fillColor.gradient)
                                .frame(width: max(corner, (cell.size.width) * model.fraction))
                                .animation(.linear(duration: 0.2), value: model.fraction)
                        }
                        .padding(inset)

                        Text(model.remaining.clockString)
                            .font(.display(bodyHeight * 0.42))
                            .monospacedDigit()
                            .minimumScaleFactor(0.4)
                            .lineLimit(1)
                            .foregroundStyle(palette.textPrimary)
                            .contentTransition(.numericText())
                            .padding(.horizontal, inset * 2)
                            .frame(maxWidth: .infinity)
                    }
                    .frame(width: bodyWidth, height: bodyHeight)

                    // Terminal nub.
                    RoundedRectangle(cornerRadius: corner * 0.4, style: .continuous)
                        .fill(palette.textPrimary.opacity(0.5))
                        .frame(width: bodyWidth * 0.045, height: bodyHeight * 0.4)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
        }
    }
}
