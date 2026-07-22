import SwiftUI

/// Snow falls and accumulates until it fills the frame exactly when time runs out. The
/// flakes and the drift respond to how the device is tilted, because that's fun.
///
/// The fill level is driven by elapsed time (authoritative — the drift never lies about
/// the clock); the particles and the drift's bumpy surface are decoration on top. Under
/// Reduce Motion the particles disappear and only the smooth rising drift remains.
struct SnowfallStyle: View {
    @Environment(\.palette) private var palette
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    let model: TimerDisplayModel

    @State private var simulation = SnowSimulation()

    private var usesMotion: Bool { model.isActive && !model.isPreview && !reduceMotion }

    var body: some View {
        GeometryReader { geo in
            TimelineView(.animation(minimumInterval: 1 / 60,
                                    paused: !model.isActive || model.isPreview || reduceMotion)) { context in
                Canvas { canvas, size in
                    let fraction = model.fraction(at: context.date)
                    if !reduceMotion {
                        simulation.step(to: context.date, size: size,
                                        baseFill: 1 - fraction,
                                        gravity: MotionService.shared.gravity,
                                        isPreview: model.isPreview)
                    }

                    drawDrift(canvas: &canvas, size: size, baseFill: 1 - fraction)
                    if !reduceMotion {
                        drawFlakes(canvas: &canvas)
                    }
                }
            }
            .overlay(alignment: .top) {
                Text(model.remaining.clockString)
                    .font(.display(min(max(24, geo.size.width * 0.12), geo.size.height * 0.2)))
                    .monospacedDigit()
                    .foregroundStyle(model.isExpired ? palette.negative : palette.textPrimary)
                    .contentTransition(.numericText())
                    .padding(.top, geo.size.height * 0.06)
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .onAppear { if usesMotion { MotionService.shared.acquire() } }
        .onDisappear { if usesMotion { MotionService.shared.release() } }
        .onChange(of: usesMotion) { was, isNow in
            if isNow { MotionService.shared.acquire() } else if was { MotionService.shared.release() }
        }
    }

    private func drawDrift(canvas: inout GraphicsContext, size: CGSize, baseFill: Double) {
        let columns = simulation.heightfield.isEmpty || reduceMotion
            ? [CGFloat](repeating: 0, count: 32)
            : simulation.heightfield
        let baseline = size.height * (1 - 0.92 * baseFill.clamped(to: 0...1))

        var drift = Path()
        drift.move(to: CGPoint(x: 0, y: size.height))
        for (index, bump) in columns.enumerated() {
            let x = size.width * CGFloat(index) / CGFloat(columns.count - 1)
            drift.addLine(to: CGPoint(x: x, y: max(0, baseline - bump)))
        }
        drift.addLine(to: CGPoint(x: size.width, y: size.height))
        drift.closeSubpath()

        let snow = palette.textPrimary
        canvas.fill(drift, with: .linearGradient(
            Gradient(colors: [snow.opacity(0.85), snow.opacity(0.6)]),
            startPoint: CGPoint(x: 0, y: baseline),
            endPoint: CGPoint(x: 0, y: size.height)))
        canvas.stroke(drift, with: .color(model.playerColor.opacity(0.5)), lineWidth: 1.5)
    }

    private func drawFlakes(canvas: inout GraphicsContext) {
        let snow = palette.textPrimary
        for flake in simulation.flakes {
            let rect = CGRect(x: flake.position.x - flake.size / 2,
                              y: flake.position.y - flake.size / 2,
                              width: flake.size, height: flake.size)
            canvas.fill(Path(ellipseIn: rect), with: .color(snow.opacity(flake.opacity)))
        }
    }
}

/// The particle state, deliberately outside SwiftUI's dependency graph: the Canvas
/// redraws every frame from the TimelineView, so mutating this from `draw` is safe and
/// avoids invalidation storms.
@MainActor
private final class SnowSimulation {
    struct Flake {
        var position: CGPoint
        var velocity: CGVector
        var size: CGFloat
        var opacity: Double
        var wobblePhase: Double
    }

    private(set) var flakes: [Flake] = []
    /// Per-column extra height on top of the time-driven baseline.
    private(set) var heightfield: [CGFloat] = []

    private var lastStep: Date?
    private var size: CGSize = .zero
    private let columnCount = 64

    func step(to date: Date, size: CGSize, baseFill: Double, gravity: CGVector, isPreview: Bool) {
        if self.size != size || flakes.isEmpty {
            seed(size: size, isPreview: isPreview)
        }
        if isPreview { return }

        let dt = min(1 / 20, lastStep.map { date.timeIntervalSince($0) } ?? 1 / 60)
        lastStep = date
        guard dt > 0 else { return }

        let baseline = size.height * (1 - 0.92 * baseFill.clamped(to: 0...1))

        for index in flakes.indices {
            var flake = flakes[index]
            flake.wobblePhase += dt * 2.2
            // Gravity leans the fall with the device; wobble adds per-flake character.
            let speed = 26 + flake.size * 9
            flake.velocity.dx = gravity.dx * speed + sin(flake.wobblePhase) * 9
            flake.velocity.dy = max(8, gravity.dy * speed)
            flake.position.x += flake.velocity.dx * dt
            flake.position.y += flake.velocity.dy * dt

            if flake.position.x < -6 { flake.position.x = size.width + 6 }
            if flake.position.x > size.width + 6 { flake.position.x = -6 }

            // Landing: deposit a bump on the nearest column and respawn at the top.
            let column = columnIndex(for: flake.position.x, width: size.width)
            let surface = max(0, baseline - heightfield[column])
            if flake.position.y >= surface {
                heightfield[column] = min(heightfield[column] + flake.size * 0.55, baseline)
                flake.position = CGPoint(x: CGFloat.random(in: 0...size.width), y: -CGFloat.random(in: 0...40))
                flake.wobblePhase = Double.random(in: 0...(2 * .pi))
            }
            flakes[index] = flake
        }

        relaxDrift(gravity: gravity, dt: dt)
    }

    /// Talus relaxation: steep differences between neighboring columns shed downhill,
    /// biased by tilt so the drift slides toward the low side of the device.
    private func relaxDrift(gravity: CGVector, dt: Double) {
        guard heightfield.count > 1 else { return }
        let slopeLimit: CGFloat = 6
        let tiltBias = gravity.dx * 2.5
        for index in 0..<(heightfield.count - 1) {
            let delta = heightfield[index] - heightfield[index + 1] + tiltBias
            if abs(delta) > slopeLimit {
                let transfer = (abs(delta) - slopeLimit) * 0.3
                if delta > 0 {
                    heightfield[index] -= transfer
                    heightfield[index + 1] += transfer
                } else {
                    heightfield[index] += transfer
                    heightfield[index + 1] -= transfer
                }
            }
        }
        // Old bumps settle slowly so the surface trends back toward the true fill level.
        for index in heightfield.indices {
            heightfield[index] = max(0, heightfield[index] - CGFloat(dt) * 1.2)
        }
    }

    private func seed(size: CGSize, isPreview: Bool) {
        self.size = size
        heightfield = [CGFloat](repeating: 0, count: columnCount)
        let budget = min(140, max(24, Int(size.width * size.height / 3500)))
        flakes = (0..<budget).map { index in
            Flake(position: CGPoint(x: CGFloat.random(in: 0...size.width),
                                    y: isPreview
                                        ? CGFloat.random(in: 0...size.height * 0.6)
                                        : CGFloat.random(in: -size.height...size.height * 0.5)),
                  velocity: .zero,
                  size: CGFloat.random(in: 2...4.5),
                  opacity: Double.random(in: 0.5...0.95),
                  wobblePhase: Double(index) * 0.7)
        }
        if isPreview {
            // A half-built, gently bumpy drift so the picker tile looks alive while frozen.
            for index in heightfield.indices {
                heightfield[index] = 6 + 5 * sin(Double(index) * 0.5)
            }
        }
    }

    private func columnIndex(for x: CGFloat, width: CGFloat) -> Int {
        guard width > 0 else { return 0 }
        let position = Int((x / width) * CGFloat(columnCount - 1))
        return min(max(position, 0), columnCount - 1)
    }
}
