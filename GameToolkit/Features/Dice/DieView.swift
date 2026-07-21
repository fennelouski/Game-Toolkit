import SwiftUI

/// A single die that shows classic pips for six-sided dice and a large numeral otherwise.
struct DieView: View {
    let value: Int
    let sides: Int
    let spin: Double
    var color: Color = Color(hex: "#E63946")
    var isLocked: Bool = false
    /// Matches the original app's scale: -1 (Tiny) through 5 (Comically Large).
    var dotSize: Double = 3

    private var pipColor: Color { color.readableForeground }

    var body: some View {
        GeometryReader { geo in
            let size = min(geo.size.width, geo.size.height)
            RoundedRectangle(cornerRadius: size * 0.2, style: .continuous)
                .fill(color.gradient)
                .overlay(
                    RoundedRectangle(cornerRadius: size * 0.2, style: .continuous)
                        .strokeBorder(.white.opacity(0.25), lineWidth: size * 0.02)
                )
                .overlay(face(size: size))
                .overlay(lockOverlay(size: size))
                .shadow(color: .black.opacity(0.25), radius: size * 0.08, x: 0, y: size * 0.04)
                .frame(width: size, height: size)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .rotation3DEffect(.degrees(spin), axis: (x: 0.4, y: 1, z: 0.25))
        .animation(.easeOut(duration: 0.55), value: spin)
        .saturation(isLocked ? 0.45 : 1)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Die showing \(value), \(isLocked ? "held" : "not held")")
        .accessibilityHint(isLocked ? "Tap to release and include in the next roll"
                                    : "Tap to hold and exclude from the next roll")
        .accessibilityAddTraits(.isButton)
    }

    @ViewBuilder
    private func lockOverlay(size: CGFloat) -> some View {
        if isLocked {
            RoundedRectangle(cornerRadius: size * 0.2, style: .continuous)
                .strokeBorder(Color.accentColor, lineWidth: size * 0.06)
                .overlay(alignment: .topTrailing) {
                    Image(systemName: "lock.fill")
                        .font(.system(size: size * 0.16, weight: .bold))
                        .foregroundStyle(.white)
                        .padding(size * 0.06)
                        .background(Circle().fill(Color.accentColor))
                        .offset(x: size * 0.06, y: -size * 0.06)
                }
        }
    }

    @ViewBuilder
    private func face(size: CGFloat) -> some View {
        if sides == 6, (1...6).contains(value) {
            pips(size: size)
        } else {
            Text("\(value)")
                .font(.system(size: size * 0.5, weight: .heavy, design: .rounded))
                .minimumScaleFactor(0.3)
                .lineLimit(1)
                .foregroundStyle(pipColor)
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
        let pip = size / CGFloat(9.0 - dotSize.clamped(to: -1...5) * 1.2)
        let inset = max(pip * 0.62, size * 0.2)
        let span = size - inset * 2
        return ZStack {
            ForEach(Array((Self.layouts[value] ?? []).enumerated()), id: \.offset) { _, pos in
                Circle()
                    .fill(pipColor)
                    .frame(width: pip, height: pip)
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
        DieView(value: 6, sides: 6, spin: 0, isLocked: true)
        DieView(value: 20, sides: 20, spin: 0, color: Color(hex: "#9B5DE5"))
    }
    .frame(height: 120)
    .padding()
}
