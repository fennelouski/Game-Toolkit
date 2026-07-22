import SwiftUI
import simd

/// A single die rendered as its true polyhedron in a `Canvas` — cube for d6,
/// tetrahedron for d4, octahedron for d8, pentagonal trapezohedron for d10/d100,
/// dodecahedron for d12, icosahedron for d20 — projected with perspective and lit
/// from the top left. d6 shows classic pips; everything else shows numerals
/// (with the tabletop 6./9. underline where they could be confused).
///
/// Rolls replay a precomputed rigid-body tumble (`DieTrajectory`): the die is thrown
/// with a chaotic spin, bounces with kicks on each impact, and springs onto whichever
/// face physics leaves pointing at the viewer — that slot carries the engine's value.
/// At rest, `ambientTilt` leans the whole solid so device motion reveals its sides.
struct DieView: View {
    let value: Int
    let sides: Int
    /// Bump to throw the die; pair with a fresh `tumbleSeed` for a new trajectory.
    var rollTrigger: Int = 0
    var tumbleSeed: UInt64 = 0
    var face: Color = Color(hex: "#F9F4E7")
    var pip: Color = Color(hex: "#2B382F")
    var isLocked: Bool = false
    /// Matches the original app's scale: -1 (Tiny) through 5 (Comically Large).
    var dotSize: Double = 3
    /// Stable per-die ordinal used for the resting tilt.
    var seed: Int = 0
    /// Ambient lean (degrees) from device motion: width tips left/right, height fore/aft.
    var ambientTilt: CGSize = .zero

    @Environment(\.palette) private var palette
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @State private var trajectory: DieTrajectory?
    @State private var rollStart: Date = .distantPast
    @State private var restOrientation: simd_quatd?
    @State private var topSlot: Int = 0
    /// The last tumble's side labels, kept after settling so no face changes value
    /// when the die comes to rest.
    @State private var settledLabels: [Int]?

    /// The solid overdraws its layout cell generously so hops and tumbling
    /// corners never get clipped mid-flight.
    private static let overscan: CGFloat = 2.5

    private var solid: DieSolid { .solid(for: sides) }

    /// A deterministic resting rotation in the range ±3.5°, so dice sit naturally.
    private var restingTilt: Double {
        let hash = (seed &* 2654435761) & 0xFFFF
        return (Double(hash) / 65535.0 - 0.5) * 7
    }

    private var idleOrientation: simd_quatd {
        restOrientation ?? DieTrajectory.restPose(
            solid: solid, slot: min(topSlot, solid.slotCount - 1), restingYawDegrees: restingTilt
        )
    }

    private var ambientOrientation: simd_quatd {
        simd_quatd(angle: Double(ambientTilt.height) * .pi / 180, axis: [1, 0, 0])
            * simd_quatd(angle: -Double(ambientTilt.width) * .pi / 180, axis: [0, 1, 0])
    }

    /// Labels for the die at rest. After a roll these are the tumble's own side
    /// labels, so no face flickers to a new value as the die settles. Before the
    /// first roll they're derived deterministically each render — lazy grids
    /// recycle cells unpredictably, so this must not depend on onAppear.
    private var restLabels: [Int] {
        if let settledLabels, settledLabels.count == solid.slotCount {
            return settledLabels
        }
        return DieTrajectory.restLabels(
            value: value,
            topSlot: min(topSlot, solid.slotCount - 1),
            sides: sides,
            solid: solid,
            seed: tumbleSeed &+ UInt64(truncatingIfNeeded: seed &+ 1)
        )
    }

    var body: some View {
        GeometryReader { geo in
            let size = min(geo.size.width, geo.size.height)
            ZStack {
                TimelineView(.animation(paused: trajectory == nil)) { timeline in
                    Canvas { context, canvasSize in
                        let t = timeline.date.timeIntervalSince(rollStart)
                        let solid = solid
                        var params = DieRenderer.Params(
                            solid: solid,
                            orientation: idleOrientation,
                            hop: 0,
                            labels: restLabels,
                            liveSlot: min(topSlot, solid.slotCount - 1),
                            liveValue: value,
                            sides: sides,
                            faceColor: face,
                            pipColor: pip,
                            dotSize: dotSize
                        )
                        if let trajectory {
                            params.orientation = trajectory.orientation(at: t)
                            params.hop = trajectory.hop(at: t)
                            params.labels = trajectory.sideLabels
                            params.liveSlot = trajectory.settleSlot
                        }
                        params.orientation = simd_normalize(ambientOrientation * params.orientation)
                        DieRenderer.draw(context, size: canvasSize, params: params)
                    }
                }
                .frame(width: size * Self.overscan, height: size * Self.overscan)
                .allowsHitTesting(false)

                lockOverlay(size: size)
            }
            .frame(width: geo.size.width, height: geo.size.height)
        }
        .contentShape(Rectangle())
        .offset(x: ambientTilt.width * 0.5, y: ambientTilt.height * 0.5)
        .saturation(isLocked ? 0.6 : 1)
        .opacity(isLocked ? 0.85 : 1)
        .onChange(of: rollTrigger) { _, _ in startRoll() }
        .onChange(of: sides) { _, _ in
            // The solid may have changed shape entirely; re-seat it.
            trajectory = nil
            restOrientation = nil
            topSlot = 0
            settledLabels = nil
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Die showing \(value), \(isLocked ? "held" : "not held")")
        .accessibilityHint(isLocked ? "Tap to release and include in the next roll"
                                    : "Tap to hold and exclude from the next roll")
        .accessibilityAddTraits(.isButton)
    }

    private func startRoll() {
        guard !reduceMotion else { return }
        let solid = solid
        let new = DieTrajectory.generate(
            seed: tumbleSeed ^ (UInt64(truncatingIfNeeded: seed) &* 0x9E3779B97F4A7C15),
            sides: sides,
            solid: solid,
            startOrientation: idleOrientation,
            restingYawDegrees: restingTilt
        )
        trajectory = new
        rollStart = Date()

        let trigger = rollTrigger
        Task { @MainActor in
            try? await Task.sleep(nanoseconds: UInt64((new.duration + 0.05) * 1_000_000_000))
            guard rollTrigger == trigger, trajectory != nil else { return }
            restOrientation = new.finalOrientation
            topSlot = new.settleSlot
            // Carry the tumble's labels into rest so no visible face changes value.
            settledLabels = new.sideLabels
            trajectory = nil
        }
    }

    @ViewBuilder
    private func lockOverlay(size: CGFloat) -> some View {
        if isLocked {
            let side = size * 0.92
            RoundedRectangle(cornerRadius: side * 0.22, style: .continuous)
                .strokeBorder(palette.accent, lineWidth: max(2, side * 0.05))
                .overlay(alignment: .topTrailing) {
                    Image(systemName: "lock.fill")
                        .font(.system(size: side * 0.15, weight: .bold))
                        .foregroundStyle(palette.accent.readableForeground)
                        .padding(side * 0.055)
                        .background(Circle().fill(palette.accent))
                        .offset(x: side * 0.07, y: -side * 0.07)
                }
                .frame(width: side, height: side)
        }
    }
}

/// Projects and draws one die's polyhedron into a `GraphicsContext`.
enum DieRenderer {
    struct Params {
        var solid: DieSolid
        var orientation: simd_quatd
        var hop: Double
        var labels: [Int]
        /// The slot showing `liveValue` (the settling slot mid-roll, the top slot at rest).
        var liveSlot: Int
        var liveValue: Int
        var sides: Int
        var faceColor: Color
        var pipColor: Color
        var dotSize: Double
    }

    // Pip positions on a 3x3 grid (column, row), 0...2.
    static let pipLayouts: [Int: [(Int, Int)]] = [
        1: [(1, 1)],
        2: [(0, 0), (2, 2)],
        3: [(0, 0), (1, 1), (2, 2)],
        4: [(0, 0), (2, 0), (0, 2), (2, 2)],
        5: [(0, 0), (2, 0), (1, 1), (0, 2), (2, 2)],
        6: [(0, 0), (2, 0), (0, 1), (2, 1), (0, 2), (2, 2)],
    ]

    static func draw(_ context: GraphicsContext, size: CGSize, params: Params) {
        // Pixels per body unit, sized against the layout cell (canvas ÷ overscan)
        // so the cube's face fills ~92% of the cell at rest, like the old flat die.
        let h = size.width * 0.184
        let cameraDistance = 7.0
        let lift = 1 + params.hop * 0.12
        let center = CGPoint(
            x: size.width / 2,
            y: size.height / 2 - CGFloat(params.hop) * h * 1.0
        )
        let light = simd_normalize(simd_double3(-0.35, -0.55, 0.76))

        let rotated = params.solid.vertices.map { params.orientation.act($0) }

        // Grounded shadow cast in the die's own silhouette: the solid's outline,
        // flattened onto the table, drifting and softening while airborne.
        let baseY = size.height / 2 + h * 0.92
        let spread = 1.0 + CGFloat(params.hop) * 0.35
        let shadowHull = convexHull(rotated.map { p in
            CGPoint(
                x: size.width / 2 + CGFloat(p.x) * h * spread,
                y: baseY + CGFloat(p.y) * h * 0.34 * spread
            )
        })
        if shadowHull.count >= 3 {
            context.drawLayer { layer in
                layer.addFilter(.blur(radius: h * (0.14 + CGFloat(params.hop) * 0.20)))
                layer.fill(
                    roundedPolygon(shadowHull, inset: 0.12),
                    with: .color(.black.opacity(0.30 / (1 + params.hop * 1.6)))
                )
            }
        }

        func project(_ p: simd_double3) -> CGPoint {
            let s = cameraDistance / (cameraDistance - p.z) * lift
            return CGPoint(x: center.x + CGFloat(p.x * s) * h, y: center.y + CGFloat(p.y * s) * h)
        }

        // Underfill the whole silhouette so the rounded faces' corner gaps read as
        // darker edge creases instead of holes onto the felt.
        let hull = convexHull(rotated.map(project))
        if hull.count >= 3 {
            context.fill(
                roundedPolygon(hull, inset: 0.08),
                with: .color(params.faceColor.darkened(by: 0.35))
            )
        }

        // A convex solid's viewer-facing faces never overlap, so draw order is free.
        for (faceIndex, faceDef) in params.solid.faces.enumerated() {
            let n = params.orientation.act(faceDef.normal)
            guard n.z > 0.02 else { continue }
            let u = params.orientation.act(faceDef.u)
            let v = params.orientation.act(faceDef.v)
            let c = params.orientation.act(faceDef.center)

            let corners = faceDef.vertexIndices.map {
                project(params.orientation.act(params.solid.vertices[$0]))
            }
            let path = roundedPolygon(corners, inset: 0.16)

            let lambert = simd_dot(n, light)
            let base = lambert >= 0
                ? params.faceColor.lightened(by: lambert * 0.10)
                : params.faceColor.darkened(by: -lambert * 0.16)
            let gradient = Gradient(colors: [
                base.lightened(by: 0.05), base, base.darkened(by: 0.06),
            ])
            let far = corners[corners.count / 2]
            context.fill(
                path,
                with: .linearGradient(gradient, startPoint: corners[0], endPoint: far)
            )
            context.stroke(path, with: .color(.black.opacity(0.16)), lineWidth: max(1, h * 0.03))

            let shade = max(0, -lambert)
            let ink = params.pipColor.darkened(by: shade * 0.15)

            let faceValue = faceIndex == params.liveSlot
                ? params.liveValue
                : (faceIndex < params.labels.count ? params.labels[faceIndex] : params.liveValue)
            if params.sides == 6, params.solid.faces.count == 6, (1...6).contains(faceValue) {
                drawPips(
                    context, value: faceValue, ink: ink, dotSize: params.dotSize,
                    face: faceDef, worldCenter: c, u: u, v: v, project: project
                )
            } else if n.z > 0.30 {
                drawNumeral(
                    context, value: faceValue, ink: ink,
                    underlined: params.sides >= 9 && (faceValue == 6 || faceValue == 9),
                    at: project(c), u: u, v: v,
                    pixelSize: CGFloat(faceDef.inradius) * h,
                    unitsToPixels: h, project: { project(c + $0) }
                )
            }
        }
    }

    private static func drawPips(
        _ context: GraphicsContext, value: Int, ink: Color, dotSize: Double,
        face: DieSolid.Face, worldCenter: simd_double3,
        u: simd_double3, v: simd_double3, project: (simd_double3) -> CGPoint
    ) {
        // Same curve the original used, so every named size looks like it always did.
        let radius = face.inradius / (9.0 - dotSize.clamped(to: DotSize.range) * 1.2)
        let span = face.inradius * 0.52
        for pos in pipLayouts[value] ?? [] {
            let du = (Double(pos.0) - 1) * span
            let dv = (Double(pos.1) - 1) * span
            let pipCenter = worldCenter + u * du + v * dv
            let cp = project(pipCenter)
            // Local projected basis turns the circle into the right ellipse.
            let bu = project(pipCenter + u * radius) - cp
            let bv = project(pipCenter + v * radius) - cp
            let transform = CGAffineTransform(
                a: bu.x, b: bu.y, c: bv.x, d: bv.y, tx: cp.x, ty: cp.y
            )
            let pipPath = Path(ellipseIn: CGRect(x: -1, y: -1, width: 2, height: 2))
                .applying(transform)
            context.fill(pipPath, with: .color(ink))
            context.stroke(
                pipPath,
                with: .color(.black.opacity(0.20)),
                lineWidth: max(0.5, bu.length * 0.08)
            )
        }
    }

    private static func drawNumeral(
        _ context: GraphicsContext, value: Int, ink: Color, underlined: Bool,
        at cp: CGPoint, u: simd_double3, v: simd_double3,
        pixelSize: CGFloat, unitsToPixels h: CGFloat, project: (simd_double3) -> CGPoint
    ) {
        var bu = project(u) - cp
        let bv = project(v) - cp
        // A negative determinant would mirror the glyphs.
        if bu.x * bv.y - bu.y * bv.x < 0 { bu = CGPoint(x: -bu.x, y: -bu.y) }
        var ctx = context
        // Affine approximation of the face plane, scaled by true pixels-per-unit so
        // glyphs foreshorten with the face instead of stretching.
        ctx.transform = CGAffineTransform(
            a: bu.x / h, b: bu.y / h, c: bv.x / h, d: bv.y / h,
            tx: cp.x, ty: cp.y
        )
        let digits = value >= 100 ? 3 : value >= 10 ? 2 : 1
        let fontSize = pixelSize * (digits == 3 ? 0.62 : digits == 2 ? 0.78 : 1.0)
        let text = Text("\(value)")
            .font(.system(size: fontSize, weight: .bold, design: .serif))
            .foregroundColor(ink)
        ctx.draw(text, at: .zero, anchor: .center)
        if underlined {
            let bar = CGRect(
                x: -fontSize * 0.20, y: fontSize * 0.44,
                width: fontSize * 0.40, height: fontSize * 0.07
            )
            ctx.fill(Path(bar), with: .color(ink))
        }
    }

    /// Andrew's monotone chain over a handful of points; returns them in hull order.
    private static func convexHull(_ pts: [CGPoint]) -> [CGPoint] {
        let sorted = pts.sorted { $0.x == $1.x ? $0.y < $1.y : $0.x < $1.x }
        guard sorted.count > 2 else { return sorted }
        func cross(_ o: CGPoint, _ a: CGPoint, _ b: CGPoint) -> CGFloat {
            (a.x - o.x) * (b.y - o.y) - (a.y - o.y) * (b.x - o.x)
        }
        var lower: [CGPoint] = []
        for p in sorted {
            while lower.count >= 2, cross(lower[lower.count - 2], lower[lower.count - 1], p) <= 0 {
                lower.removeLast()
            }
            lower.append(p)
        }
        var upper: [CGPoint] = []
        for p in sorted.reversed() {
            while upper.count >= 2, cross(upper[upper.count - 2], upper[upper.count - 1], p) <= 0 {
                upper.removeLast()
            }
            upper.append(p)
        }
        return Array(lower.dropLast() + upper.dropLast())
    }

    /// A polygon whose corners are rounded by pulling them toward their neighbours.
    private static func roundedPolygon(_ pts: [CGPoint], inset: CGFloat) -> Path {
        var path = Path()
        let n = pts.count
        guard n >= 3 else { return path }
        for i in 0..<n {
            let previous = pts[(i + n - 1) % n]
            let corner = pts[i]
            let next = pts[(i + 1) % n]
            let entry = corner.interpolated(to: previous, by: inset)
            let exit = corner.interpolated(to: next, by: inset)
            if i == 0 { path.move(to: entry) } else { path.addLine(to: entry) }
            path.addQuadCurve(to: exit, control: corner)
        }
        path.closeSubpath()
        return path
    }
}

private extension CGPoint {
    static func - (lhs: CGPoint, rhs: CGPoint) -> CGPoint {
        CGPoint(x: lhs.x - rhs.x, y: lhs.y - rhs.y)
    }

    var length: CGFloat { sqrt(x * x + y * y) }

    func interpolated(to other: CGPoint, by fraction: CGFloat) -> CGPoint {
        CGPoint(x: x + (other.x - x) * fraction, y: y + (other.y - y) * fraction)
    }
}

extension Double {
    func clamped(to range: ClosedRange<Double>) -> Double {
        Swift.min(Swift.max(self, range.lowerBound), range.upperBound)
    }
}

extension Color {
    /// Mixes the color toward white by the given fraction (0...1).
    func lightened(by fraction: Double) -> Color {
        blended(toward: (1, 1, 1), fraction: fraction)
    }

    /// Mixes the color toward black by the given fraction (0...1).
    func darkened(by fraction: Double) -> Color {
        blended(toward: (0, 0, 0), fraction: fraction)
    }

    private func blended(toward target: (Double, Double, Double), fraction: Double) -> Color {
        let ui = UIColor(self)
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        ui.getRed(&r, green: &g, blue: &b, alpha: &a)
        let f = CGFloat(fraction.clamped(to: 0...1))
        return Color(
            .sRGB,
            red: Double(r + (CGFloat(target.0) - r) * f),
            green: Double(g + (CGFloat(target.1) - g) * f),
            blue: Double(b + (CGFloat(target.2) - b) * f),
            opacity: Double(a)
        )
    }
}

/// Names for the dot-size scale, matching the original app.
enum DotSize {
    static let range: ClosedRange<Double> = -1...5

    static func name(for value: Double) -> String {
        switch Int(value.rounded()) {
        case ...(-1): return "Tiny"
        case 0: return "Extra-Small"
        case 1: return "Small"
        case 2: return "Medium"
        case 3: return "Large"
        case 4: return "Extra-Large"
        default: return "Comically Large"
        }
    }
}

#Preview {
    VStack {
        HStack {
            DieView(value: 4, sides: 4)
            DieView(value: 5, sides: 6, seed: 1)
            DieView(value: 7, sides: 8, seed: 2)
        }
        HStack {
            DieView(value: 9, sides: 10, seed: 3)
            DieView(value: 11, sides: 12, seed: 4)
            DieView(value: 20, sides: 20, face: Color(hex: "#9B5DE5"), pip: .white, seed: 5)
        }
    }
    .frame(height: 260)
    .padding()
}
