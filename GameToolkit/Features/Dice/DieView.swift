import SwiftUI

/// A single die that shows classic pips for six-sided dice and a large numeral otherwise.
/// Faces render like cast resin: layered gradients for a bevel, a grounded drop shadow,
/// and a slight per-die resting tilt so a handful of dice reads as thrown, not typeset.
struct DieView: View {
    let value: Int
    let sides: Int
    let spin: Double
    var face: Color = Color(hex: "#F9F4E7")
    var pip: Color = Color(hex: "#2B382F")
    var isLocked: Bool = false
    /// Matches the original app's scale: -1 (Tiny) through 5 (Comically Large).
    var dotSize: Double = 3
    /// Stable per-die ordinal used for the resting tilt.
    var seed: Int = 0

    @Environment(\.palette) private var palette
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    /// A deterministic resting rotation in the range ±3.5°, so dice sit naturally.
    private var restingTilt: Double {
        let hash = (seed &* 2654435761) & 0xFFFF
        return (Double(hash) / 65535.0 - 0.5) * 7
    }

    var body: some View {
        GeometryReader { geo in
            let size = min(geo.size.width, geo.size.height)
            let shape = RoundedRectangle(cornerRadius: size * 0.22, style: .continuous)
            shape
                .fill(
                    LinearGradient(
                        colors: [face.lightened(by: 0.06), face, face.darkened(by: 0.07)],
                        startPoint: .topLeading, endPoint: .bottomTrailing
                    )
                )
                .overlay {
                    // Bevel: bright top-left edge, shaded bottom-right edge.
                    shape.strokeBorder(
                        LinearGradient(
                            colors: [.white.opacity(0.55), .white.opacity(0.05), .black.opacity(0.18)],
                            startPoint: .topLeading, endPoint: .bottomTrailing
                        ),
                        lineWidth: max(1, size * 0.025)
                    )
                }
                .overlay(faceContent(size: size))
                .overlay(lockOverlay(size: size, shape: shape))
                .shadow(color: .black.opacity(0.30), radius: size * 0.07, y: size * 0.05)
                .shadow(color: .black.opacity(0.12), radius: size * 0.015, y: size * 0.01)
                .frame(width: size, height: size)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .rotationEffect(.degrees(isLocked ? 0 : restingTilt))
        .rotation3DEffect(.degrees(reduceMotion ? 0 : spin), axis: (x: 0.4, y: 1, z: 0.25))
        .animation(reduceMotion ? nil : .easeOut(duration: 0.55), value: spin)
        .saturation(isLocked ? 0.6 : 1)
        .opacity(isLocked ? 0.85 : 1)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Die showing \(value), \(isLocked ? "held" : "not held")")
        .accessibilityHint(isLocked ? "Tap to release and include in the next roll"
                                    : "Tap to hold and exclude from the next roll")
        .accessibilityAddTraits(.isButton)
    }

    @ViewBuilder
    private func lockOverlay(size: CGFloat, shape: RoundedRectangle) -> some View {
        if isLocked {
            shape
                .strokeBorder(palette.accent, lineWidth: max(2, size * 0.05))
                .overlay(alignment: .topTrailing) {
                    Image(systemName: "lock.fill")
                        .font(.system(size: size * 0.15, weight: .bold))
                        .foregroundStyle(palette.accent.readableForeground)
                        .padding(size * 0.055)
                        .background(Circle().fill(palette.accent))
                        .offset(x: size * 0.07, y: -size * 0.07)
                }
        }
    }

    @ViewBuilder
    private func faceContent(size: CGFloat) -> some View {
        if sides == 6, (1...6).contains(value) {
            pips(size: size)
        } else {
            Text("\(value)")
                .font(.system(size: size * 0.48, weight: .bold, design: .serif))
                .minimumScaleFactor(0.3)
                .lineLimit(1)
                .foregroundStyle(pip)
                .padding(size * 0.12)
        }
    }

    // Pip positions on a 3x3 grid (column, row), 0...2.
    private static let layouts: [Int: [(Int, Int)]] = [
        1: [(1, 1)],
        2: [(0, 0), (2, 2)],
        3: [(0, 0), (1, 1), (2, 2)],
        4: [(0, 0), (2, 0), (0, 2), (2, 2)],
        5: [(0, 0), (2, 0), (1, 1), (0, 2), (2, 2)],
        6: [(0, 0), (2, 0), (0, 1), (2, 1), (0, 2), (2, 2)],
    ]

    private func pips(size: CGFloat) -> some View {
        // Same curve the original used, so every named size looks like it always did.
        let pipSize = size / CGFloat(9.0 - dotSize.clamped(to: -1...5) * 1.2)
        let inset = max(pipSize * 0.62, size * 0.2)
        let span = size - inset * 2
        return ZStack {
            ForEach(Array((Self.layouts[value] ?? []).enumerated()), id: \.offset) { _, pos in
                Circle()
                    .fill(
                        // Drilled pips: darker at the top edge, as if recessed.
                        RadialGradient(colors: [pip.lightened(by: 0.05), pip],
                                       center: .init(x: 0.4, y: 0.35),
                                       startRadius: 0, endRadius: pipSize * 0.7)
                    )
                    .overlay {
                        Circle().strokeBorder(.black.opacity(0.25), lineWidth: pipSize * 0.06)
                    }
                    .frame(width: pipSize, height: pipSize)
                    .position(
                        x: inset + span * CGFloat(pos.0) / 2,
                        y: inset + span * CGFloat(pos.1) / 2
                    )
            }
        }
        .frame(width: size, height: size)
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
    HStack {
        DieView(value: 5, sides: 6, spin: 0)
        DieView(value: 3, sides: 6, spin: 0, isLocked: true, seed: 1)
        DieView(value: 20, sides: 20, spin: 0, face: Color(hex: "#9B5DE5"), pip: .white, seed: 2)
    }
    .frame(height: 120)
    .padding()
}
