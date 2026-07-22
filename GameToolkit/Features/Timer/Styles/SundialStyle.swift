import SwiftUI

/// A flat-lay sundial: the gnomon's shadow sweeps from morning (−90°) to evening (+90°)
/// across the timer's budget. Deliberately slow and quiet — it updates once a second.
struct SundialStyle: View {
    @Environment(\.palette) private var palette
    let model: TimerDisplayModel

    var body: some View {
        GeometryReader { geo in
            let diameter = min(geo.size.width, geo.size.height) * 0.94
            let shadowAngle = Angle.degrees(-90 + 180 * model.elapsedFraction)

            ZStack {
                Circle()
                    .fill(palette.surfaceElevated)
                    .overlay {
                        Circle().strokeBorder(
                            model.isExpired ? palette.negative : palette.textSecondary.opacity(0.4),
                            lineWidth: max(1.5, diameter * 0.012))
                    }

                // Ambient sun glow opposite the shadow.
                Circle()
                    .fill(RadialGradient(colors: [palette.warning.opacity(0.16), .clear],
                                         center: .center, startRadius: 0, endRadius: diameter * 0.5))
                    .offset(x: -sin(shadowAngle.radians) * diameter * 0.2,
                            y: cos(shadowAngle.radians) * diameter * 0.2)

                // Hour marks around the rim.
                ForEach(0..<12, id: \.self) { mark in
                    Capsule()
                        .fill(palette.textSecondary.opacity(0.6))
                        .frame(width: diameter * 0.012, height: diameter * 0.06)
                        .offset(y: -diameter * 0.42)
                        .rotationEffect(.degrees(Double(mark) * 30))
                }

                // The shadow: a tapered wedge from the center outward.
                ShadowWedge()
                    .fill(palette.textPrimary.opacity(model.isExpired ? 0.15 : 0.3))
                    .frame(width: diameter, height: diameter)
                    .rotationEffect(shadowAngle)
                    .animation(.linear(duration: 1), value: shadowAngle)

                // Gnomon.
                Triangle()
                    .fill(model.playerColor)
                    .frame(width: diameter * 0.09, height: diameter * 0.14)
                    .offset(y: -diameter * 0.02)
                    .shadow(color: .black.opacity(0.2), radius: 2, y: 2)

                Text(model.remaining.clockString)
                    .font(.display(diameter * 0.11))
                    .monospacedDigit()
                    .foregroundStyle(model.isExpired ? palette.negative : palette.textSecondary)
                    .contentTransition(.numericText())
                    .offset(y: diameter * 0.26)
            }
            .opacity(model.isExpired ? 0.75 : 1)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
        }
    }
}

/// A slim wedge pointing straight down from the center; rotation aims it.
private struct ShadowWedge: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let length = rect.height * 0.42
        path.move(to: CGPoint(x: rect.midX - rect.width * 0.025, y: rect.midY))
        path.addLine(to: CGPoint(x: rect.midX + rect.width * 0.025, y: rect.midY))
        path.addLine(to: CGPoint(x: rect.midX + rect.width * 0.005, y: rect.midY + length))
        path.addLine(to: CGPoint(x: rect.midX - rect.width * 0.005, y: rect.midY + length))
        path.closeSubpath()
        return path
    }
}

private struct Triangle: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.midX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        path.closeSubpath()
        return path
    }
}
