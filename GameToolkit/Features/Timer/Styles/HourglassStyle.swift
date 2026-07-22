import SwiftUI

/// Sand runs from the top bulb to the bottom one over the timer's budget — as a small
/// granular simulation: both sand surfaces stay level as the device tilts, grains fall
/// from the neck, and the bottom pile grows where they land and slumps when it gets too
/// steep. Fill levels are driven by elapsed time (authoritative — the physics never lies
/// about the clock); the grains are decoration. Reduce Motion (and platforms without an
/// accelerometer's fun) get the calm flat-level rendering.
struct HourglassStyle: View {
    @Environment(\.palette) private var palette
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    let model: TimerDisplayModel

    @State private var simulation = SandSimulation()

    private var isLive: Bool { model.isActive && !model.isPreview && !reduceMotion }

    var body: some View {
        GeometryReader { geo in
            let height = min(geo.size.height * 0.9, geo.size.width * 1.4)
            let width = height * 0.62

            TimelineView(.animation(minimumInterval: reduceMotion ? 1 : 1 / 60,
                                    paused: !model.isActive || model.isPreview)) { context in
                let fraction = model.fraction(at: context.date)
                let size = CGSize(width: width, height: height)

                ZStack {
                    Canvas { canvas, _ in
                        if isLive {
                            simulation.step(to: context.date, size: size, fraction: fraction,
                                            gravity: MotionService.shared.gravity)
                        }
                        drawSand(canvas: &canvas, size: size, fraction: fraction,
                                 tilt: isLive ? MotionService.shared.gravity : CGVector(dx: 0, dy: 1),
                                 phase: context.date.timeIntervalSinceReferenceDate)
                    }
                    .frame(width: width, height: height)

                    HourglassFrame()
                        .stroke(model.isExpired ? palette.negative : palette.textSecondary.opacity(0.7),
                                style: StrokeStyle(lineWidth: max(2, height * 0.02),
                                                   lineCap: .round, lineJoin: .round))
                        .frame(width: width, height: height)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
            }
        }
        .onAppear { if isLive { MotionService.shared.acquire() } }
        .onDisappear { if isLive { MotionService.shared.release() } }
        .onChange(of: isLive) { was, isNow in
            if isNow { MotionService.shared.acquire() } else if was { MotionService.shared.release() }
        }
    }

    // MARK: - Drawing

    private func drawSand(canvas: inout GraphicsContext, size: CGSize,
                          fraction: Double, tilt: CGVector, phase: TimeInterval) {
        let sand = model.playerColor
        let half = size.height / 2
        // Sand surfaces stay level in the real world: screen slope = gx / gy, clamped
        // so extreme tilts can't sweep the surface out of the bulb.
        let slope = min(max(tilt.dx / max(0.3, tilt.dy), -0.9), 0.9)

        // Top bulb: a tilted surface with a drain dip in the middle, clipped to the bulb.
        if fraction > 0 {
            let level = half * 0.96 - half * 0.82 * fraction
            var top = Path()
            top.move(to: CGPoint(x: 0, y: size.height))
            let steps = 24
            for step in 0...steps {
                let x = size.width * CGFloat(step) / CGFloat(steps)
                let centered = x - size.width / 2
                // The dip: sand funnels toward the neck while draining.
                let dip = model.isActive ? max(0, half * 0.06 * (1 - abs(centered) / (size.width * 0.25))) : 0
                top.addLine(to: CGPoint(x: x, y: level + centered * slope + dip))
            }
            top.addLine(to: CGPoint(x: size.width, y: size.height))
            top.closeSubpath()
            var clipped = canvas
            clipped.clip(to: HourglassBulb(isTop: true).path(in: CGRect(origin: .zero, size: size)))
            clipped.fill(top, with: .color(sand.opacity(0.9)))
        }

        // Bottom bulb: the simulated pile (or a flat level when not live).
        var bottom = Path()
        let baseline = simulation.baseline(for: fraction, height: size.height)
        bottom.move(to: CGPoint(x: 0, y: size.height))
        let columns = isLive && !simulation.heightfield.isEmpty
            ? simulation.heightfield
            : [CGFloat](repeating: 0, count: 24)
        for (index, bump) in columns.enumerated() {
            let x = size.width * CGFloat(index) / CGFloat(columns.count - 1)
            let centered = x - size.width / 2
            let levelTilt = isLive ? 0 : centered * slope   // static fallback stays flat
            bottom.addLine(to: CGPoint(x: x, y: baseline + levelTilt - bump))
        }
        bottom.addLine(to: CGPoint(x: size.width, y: size.height))
        bottom.closeSubpath()
        var clippedBottom = canvas
        clippedBottom.clip(to: HourglassBulb(isTop: false).path(in: CGRect(origin: .zero, size: size)))
        clippedBottom.fill(bottom, with: .color(sand))

        // The stream and airborne grains.
        if model.isActive && fraction > 0 && !model.isExpired {
            if isLive {
                for grain in simulation.grains {
                    canvas.fill(Path(ellipseIn: CGRect(x: grain.position.x - grain.size / 2,
                                                       y: grain.position.y - grain.size / 2,
                                                       width: grain.size, height: grain.size)),
                                with: .color(sand.opacity(grain.opacity)))
                }
            } else {
                let flicker = reduceMotion ? 0.85 : 0.7 + 0.3 * sin(phase * 18)
                var stream = Path()
                stream.addRoundedRect(in: CGRect(x: size.width / 2 - max(0.75, size.width * 0.015),
                                                 y: half * 0.96,
                                                 width: max(1.5, size.width * 0.03),
                                                 height: size.height * 0.42),
                                      cornerSize: CGSize(width: 1, height: 1))
                canvas.fill(stream, with: .color(sand.opacity(flicker)))
            }
        }
    }
}

/// Grain + pile state for the live hourglass, mirroring `SnowSimulation`'s design:
/// mutated from the Canvas draw closure (outside SwiftUI's dependency graph), with a
/// time-driven baseline so the pile always tells the truth about the clock.
@MainActor
private final class SandSimulation {
    struct Grain {
        var position: CGPoint
        var velocity: CGVector
        var size: CGFloat
        var opacity: Double
    }

    private(set) var grains: [Grain] = []
    /// Per-column extra pile height above the time-driven fill baseline.
    private(set) var heightfield: [CGFloat] = []

    private var lastStep: Date?
    private var size: CGSize = .zero
    private let columnCount = 48

    /// Screen-space y of the bottom pile's fill level for the current fraction.
    func baseline(for fraction: Double, height: CGFloat) -> CGFloat {
        height - (height / 2) * 0.82 * (1 - fraction.clamped(to: 0...1))
    }

    func step(to date: Date, size: CGSize, fraction: Double, gravity: CGVector) {
        if self.size != size {
            self.size = size
            heightfield = [CGFloat](repeating: 0, count: columnCount)
            grains = []
        }
        let dt = min(1 / 20, lastStep.map { date.timeIntervalSince($0) } ?? 1 / 60)
        lastStep = date
        guard dt > 0 else { return }

        let neck = CGPoint(x: size.width / 2, y: size.height / 2)
        let floor = baseline(for: fraction, height: size.height)

        // Emit a few grains per frame from the neck while sand remains.
        if fraction > 0, grains.count < 60 {
            for _ in 0..<2 {
                grains.append(Grain(
                    position: CGPoint(x: neck.x + .random(in: -1.5...1.5), y: neck.y),
                    velocity: CGVector(dx: .random(in: -6...6), dy: .random(in: 20...50)),
                    size: .random(in: 1.5...3),
                    opacity: .random(in: 0.6...1)))
            }
        }

        let fall = 140 + size.height * 0.2
        grains = grains.compactMap { grain in
            var grain = grain
            grain.velocity.dx += gravity.dx * fall * dt
            grain.velocity.dy += max(0.2, gravity.dy) * fall * dt
            grain.position.x += grain.velocity.dx * dt
            grain.position.y += grain.velocity.dy * dt

            let column = columnIndex(for: grain.position.x)
            if grain.position.y >= floor - heightfield[column] {
                // Landed: become pile. The pile only keeps bumps above the baseline —
                // time owns the baseline itself.
                heightfield[column] = min(heightfield[column] + grain.size * 0.4, size.height * 0.18)
                return nil
            }
            return grain.position.y > size.height ? nil : grain
        }

        relaxPile(gravity: gravity, dt: dt)
    }

    /// Talus slumping: too-steep neighbors shed downhill, biased by tilt, and old bumps
    /// slowly settle into the (time-driven) baseline.
    private func relaxPile(gravity: CGVector, dt: Double) {
        guard heightfield.count > 1 else { return }
        let slopeLimit: CGFloat = 5
        let tiltBias = gravity.dx * 3
        for index in 0..<(heightfield.count - 1) {
            let delta = heightfield[index] - heightfield[index + 1] + tiltBias
            if abs(delta) > slopeLimit {
                let transfer = (abs(delta) - slopeLimit) * 0.35
                if delta > 0 {
                    heightfield[index] -= transfer
                    heightfield[index + 1] += transfer
                } else {
                    heightfield[index] += transfer
                    heightfield[index + 1] -= transfer
                }
            }
        }
        for index in heightfield.indices {
            heightfield[index] = max(0, heightfield[index] - CGFloat(dt) * 1.5)
        }
    }

    private func columnIndex(for x: CGFloat) -> Int {
        guard size.width > 0 else { return 0 }
        return min(max(Int((x / size.width) * CGFloat(columnCount - 1)), 0), columnCount - 1)
    }
}

/// One bulb of the hourglass, used as a clip shape for the sand.
struct HourglassBulb: Shape {
    let isTop: Bool

    func path(in rect: CGRect) -> Path {
        let half = rect.height / 2
        let neck = rect.width * 0.06
        let midX = rect.midX
        var path = Path()

        if isTop {
            path.move(to: CGPoint(x: rect.minX, y: rect.minY))
            path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
            path.addCurve(to: CGPoint(x: midX + neck, y: rect.minY + half * 0.96),
                          control1: CGPoint(x: rect.maxX, y: rect.minY + half * 0.55),
                          control2: CGPoint(x: midX + neck * 3, y: rect.minY + half * 0.8))
            path.addLine(to: CGPoint(x: midX - neck, y: rect.minY + half * 0.96))
            path.addCurve(to: CGPoint(x: rect.minX, y: rect.minY),
                          control1: CGPoint(x: midX - neck * 3, y: rect.minY + half * 0.8),
                          control2: CGPoint(x: rect.minX, y: rect.minY + half * 0.55))
        } else {
            path.move(to: CGPoint(x: rect.minX, y: rect.maxY))
            path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
            path.addCurve(to: CGPoint(x: midX + neck, y: rect.maxY - half * 0.96),
                          control1: CGPoint(x: rect.maxX, y: rect.maxY - half * 0.55),
                          control2: CGPoint(x: midX + neck * 3, y: rect.maxY - half * 0.8))
            path.addLine(to: CGPoint(x: midX - neck, y: rect.maxY - half * 0.96))
            path.addCurve(to: CGPoint(x: rect.minX, y: rect.maxY),
                          control1: CGPoint(x: midX - neck * 3, y: rect.maxY - half * 0.8),
                          control2: CGPoint(x: rect.minX, y: rect.maxY - half * 0.55))
        }
        path.closeSubpath()
        return path
    }
}

/// The glass outline: both bulbs plus top and bottom caps.
struct HourglassFrame: Shape {
    func path(in rect: CGRect) -> Path {
        var path = HourglassBulb(isTop: true).path(in: rect)
        path.addPath(HourglassBulb(isTop: false).path(in: rect))
        path.move(to: CGPoint(x: rect.minX - rect.width * 0.06, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX + rect.width * 0.06, y: rect.minY))
        path.move(to: CGPoint(x: rect.minX - rect.width * 0.06, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.maxX + rect.width * 0.06, y: rect.maxY))
        return path
    }
}
