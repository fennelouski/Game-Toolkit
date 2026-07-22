import SwiftUI

/// A vessel of water draining as time passes, with a gently rippling surface.
struct WaterClockStyle: View {
    @Environment(\.palette) private var palette
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    let model: TimerDisplayModel

    var body: some View {
        GeometryReader { geo in
            let height = min(geo.size.height * 0.82, geo.size.width * 1.2)
            let width = height * 0.72

            VStack(spacing: height * 0.06) {
                TimelineView(.animation(minimumInterval: reduceMotion ? 1 : 1 / 30,
                                        paused: !model.isActive || model.isPreview)) { context in
                    let fraction = model.fraction(at: context.date)
                    let phase = context.date.timeIntervalSinceReferenceDate

                    ZStack {
                        // Water, clipped to the vessel.
                        Canvas { canvas, size in
                            let level = size.height * (1 - 0.9 * fraction) + size.height * 0.02
                            var water = Path()
                            water.move(to: CGPoint(x: 0, y: size.height))
                            water.addLine(to: CGPoint(x: 0, y: level))
                            if reduceMotion {
                                water.addLine(to: CGPoint(x: size.width, y: level))
                            } else {
                                // Two overlapping sine components make a believable surface.
                                let steps = 32
                                for step in 0...steps {
                                    let x = size.width * CGFloat(step) / CGFloat(steps)
                                    let wave = sin(Double(x) / 26 + phase * 2.2) * 2.4
                                        + sin(Double(x) / 11 - phase * 3.1) * 1.2
                                    water.addLine(to: CGPoint(x: x, y: level + wave))
                                }
                            }
                            water.addLine(to: CGPoint(x: size.width, y: size.height))
                            water.closeSubpath()

                            let gradient = Gradient(colors: [
                                model.playerColor.opacity(0.65), model.playerColor.opacity(0.9),
                            ])
                            canvas.fill(water, with: .linearGradient(
                                gradient,
                                startPoint: CGPoint(x: 0, y: level),
                                endPoint: CGPoint(x: 0, y: size.height)))

                            // Meniscus highlight along the surface.
                            var crest = water
                            crest.closeSubpath()
                            canvas.stroke(water, with: .color(model.playerColor.opacity(0.5)), lineWidth: 1)
                        }
                        .clipShape(VesselShape())

                        VesselShape()
                            .stroke(model.isExpired ? palette.negative : palette.textSecondary.opacity(0.7),
                                    style: StrokeStyle(lineWidth: max(2, height * 0.022), lineCap: .round))
                    }
                    .frame(width: width, height: height)
                }

                Text(model.remaining.clockString)
                    .font(.display(min(28, height * 0.16)))
                    .monospacedDigit()
                    .foregroundStyle(model.isExpired ? palette.negative : palette.textSecondary)
                    .contentTransition(.numericText())
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
        }
    }
}

/// A softly tapered beaker, open at the top.
private struct VesselShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let lip = rect.width * 0.06
        path.move(to: CGPoint(x: rect.minX + lip, y: rect.minY))
        path.addCurve(to: CGPoint(x: rect.minX + rect.width * 0.16, y: rect.maxY - rect.height * 0.06),
                      control1: CGPoint(x: rect.minX, y: rect.minY + rect.height * 0.35),
                      control2: CGPoint(x: rect.minX + rect.width * 0.1, y: rect.maxY - rect.height * 0.3))
        path.addQuadCurve(to: CGPoint(x: rect.maxX - rect.width * 0.16, y: rect.maxY - rect.height * 0.06),
                          control: CGPoint(x: rect.midX, y: rect.maxY + rect.height * 0.05))
        path.addCurve(to: CGPoint(x: rect.maxX - lip, y: rect.minY),
                      control1: CGPoint(x: rect.maxX - rect.width * 0.1, y: rect.maxY - rect.height * 0.3),
                      control2: CGPoint(x: rect.maxX, y: rect.minY + rect.height * 0.35))
        return path
    }
}
