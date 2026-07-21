import SwiftUI

/// A single die that shows classic pips for six-sided dice and a large numeral otherwise.
struct DieView: View {
    let value: Int
    let sides: Int
    let spin: Double
    var color: Color = Color(hex: "#E63946")

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
                .shadow(color: .black.opacity(0.25), radius: size * 0.08, x: 0, y: size * 0.04)
                .frame(width: size, height: size)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .rotation3DEffect(.degrees(spin), axis: (x: 0.4, y: 1, z: 0.25))
        .animation(.easeOut(duration: 0.55), value: spin)
    }

    @ViewBuilder
    private func face(size: CGFloat) -> some View {
        if sides == 6, (1...6).contains(value) {
            pips(size: size)
        } else {
            Text("\(value)")
                .font(.system(size: size * 0.5, weight: .heavy, design: .rounded))
                .minimumScaleFactor(0.4)
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
        let pip = size * 0.16
        let inset = size * 0.24
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

#Preview {
    HStack {
        DieView(value: 5, sides: 6, spin: 0)
        DieView(value: 20, sides: 20, spin: 0, color: Color(hex: "#9B5DE5"))
    }
    .frame(height: 120)
    .padding()
}
