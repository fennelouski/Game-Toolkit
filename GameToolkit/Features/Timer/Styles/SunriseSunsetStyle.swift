import SwiftUI

/// A day passing in miniature: the sun arcs across a sky whose colors shift dawn → noon
/// → dusk over the timer's budget, setting exactly when time runs out. Expired shows
/// night with stars and a moon sliver. A small digital clock sits in the scene.
struct SunriseSunsetStyle: View {
    @Environment(\.palette) private var palette
    let model: TimerDisplayModel

    /// Sky key moments, each a top→horizon gradient pair derived from palette roles.
    private var skyStops: [(top: Color, horizon: Color)] {
        [
            (Color.lerp(palette.background, palette.accentSecondary, t: 0.3),   // dawn
             Color.lerp(palette.warning, palette.accentSecondary, t: 0.35)),
            (Color.lerp(palette.accent, palette.background, t: 0.35),           // morning
             Color.lerp(palette.accentSecondary, palette.warning, t: 0.25)),
            (Color.lerp(palette.accent, .white, t: 0.25),                       // noon
             Color.lerp(palette.accentSecondary, .white, t: 0.3)),
            (Color.lerp(palette.negative, palette.background, t: 0.45),         // dusk
             Color.lerp(palette.warning, palette.negative, t: 0.5)),
        ]
    }

    private func sky(at progress: Double) -> (top: Color, horizon: Color) {
        let stops = skyStops
        let scaled = progress.clamped(to: 0...1) * Double(stops.count - 1)
        let index = min(Int(scaled), stops.count - 2)
        let t = scaled - Double(index)
        return (Color.lerp(stops[index].top, stops[index + 1].top, t: t),
                Color.lerp(stops[index].horizon, stops[index + 1].horizon, t: t))
    }

    var body: some View {
        GeometryReader { geo in
            let progress = model.elapsedFraction
            let night = model.isExpired
            let colors = sky(at: progress)
            let sunX = 0.1 + 0.8 * progress
            let sunY = 0.82 - 0.62 * sin(progress * .pi)

            ZStack {
                // Sky.
                LinearGradient(
                    colors: night
                        ? [Color.lerp(palette.background, .black, t: 0.5), palette.background]
                        : [colors.top, colors.horizon],
                    startPoint: .top, endPoint: .bottom)

                if night {
                    // A handful of fixed stars and a moon sliver.
                    ForEach(0..<8, id: \.self) { star in
                        Circle()
                            .fill(palette.textPrimary.opacity(0.8))
                            .frame(width: 2.5, height: 2.5)
                            .position(x: geo.size.width * starPositions[star].x,
                                      y: geo.size.height * starPositions[star].y)
                    }
                    MoonSliver()
                        .fill(palette.textPrimary.opacity(0.85))
                        .frame(width: geo.size.width * 0.14, height: geo.size.width * 0.14)
                        .position(x: geo.size.width * 0.72, y: geo.size.height * 0.24)
                } else {
                    // The sun, glowing warmly as it arcs.
                    Circle()
                        .fill(Color.lerp(palette.warning, .white, t: 0.3))
                        .frame(width: geo.size.width * 0.13, height: geo.size.width * 0.13)
                        .shadow(color: palette.warning.opacity(0.8), radius: geo.size.width * 0.05)
                        .position(x: geo.size.width * sunX, y: geo.size.height * sunY)
                        .animation(.linear(duration: 1), value: progress)
                }

                // Ground silhouette.
                GroundShape()
                    .fill(Color.lerp(palette.table, night ? .black : palette.table, t: night ? 0.4 : 0))
                    .frame(height: geo.size.height * 0.22)
                    .frame(maxHeight: .infinity, alignment: .bottom)

                // Digital clock nestled in the scene.
                Text(model.remaining.clockString)
                    .font(.display(min(max(20, geo.size.width * 0.1), geo.size.height * 0.18)))
                    .monospacedDigit()
                    .foregroundStyle(night ? palette.textPrimary : colors.top.readableForeground)
                    .contentTransition(.numericText())
                    .padding(.horizontal, 10).padding(.vertical, 5)
                    .background(Capsule().fill(.black.opacity(0.18)))
                    .position(x: geo.size.width / 2, y: geo.size.height * 0.88)
            }
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        }
    }

    private var starPositions: [CGPoint] {
        [CGPoint(x: 0.12, y: 0.18), CGPoint(x: 0.28, y: 0.32), CGPoint(x: 0.44, y: 0.12),
         CGPoint(x: 0.58, y: 0.28), CGPoint(x: 0.83, y: 0.45), CGPoint(x: 0.9, y: 0.1),
         CGPoint(x: 0.2, y: 0.5), CGPoint(x: 0.66, y: 0.5)]
    }
}

private struct GroundShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.minX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.minY + rect.height * 0.5))
        path.addQuadCurve(to: CGPoint(x: rect.midX, y: rect.minY + rect.height * 0.2),
                          control: CGPoint(x: rect.width * 0.22, y: rect.minY))
        path.addQuadCurve(to: CGPoint(x: rect.maxX, y: rect.minY + rect.height * 0.6),
                          control: CGPoint(x: rect.width * 0.75, y: rect.minY + rect.height * 0.55))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        path.closeSubpath()
        return path
    }
}

private struct MoonSliver: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.addArc(center: CGPoint(x: rect.midX, y: rect.midY), radius: rect.width / 2,
                    startAngle: .degrees(-60), endAngle: .degrees(120), clockwise: false)
        path.addArc(center: CGPoint(x: rect.midX - rect.width * 0.18, y: rect.midY - rect.width * 0.1),
                    radius: rect.width * 0.42,
                    startAngle: .degrees(120), endAngle: .degrees(-60), clockwise: true)
        path.closeSubpath()
        return path
    }
}
