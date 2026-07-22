import SwiftUI

extension Color {
    /// Creates a color from a hex string such as `#FF6B6B`, `FF6B6B`, `#FFF`, or `#AARRGGBB`.
    init(hex rawHex: String) {
        let hex = rawHex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var value: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&value)

        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (value >> 8 & 0xF) * 17, (value >> 4 & 0xF) * 17, (value & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, value >> 16 & 0xFF, value >> 8 & 0xFF, value & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (value >> 24 & 0xFF, value >> 16 & 0xFF, value >> 8 & 0xFF, value & 0xFF)
        default:
            (a, r, g, b) = (255, 77, 150, 255) // sensible fallback blue
        }

        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }

    /// A `#RRGGBB` representation of the color.
    var hexString: String {
        let ui = UIColor(self)
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        ui.getRed(&r, green: &g, blue: &b, alpha: &a)
        return String(format: "#%02X%02X%02X",
                      Int(round(r * 255)), Int(round(g * 255)), Int(round(b * 255)))
    }

    /// Linear RGBA blend between two colors (iOS 17 has no `Color.mix`).
    static func lerp(_ from: Color, _ to: Color, t: Double) -> Color {
        let clamped = t.clamped(to: 0...1)
        var fr: CGFloat = 0, fg: CGFloat = 0, fb: CGFloat = 0, fa: CGFloat = 0
        var tr: CGFloat = 0, tg: CGFloat = 0, tb: CGFloat = 0, ta: CGFloat = 0
        UIColor(from).getRed(&fr, green: &fg, blue: &fb, alpha: &fa)
        UIColor(to).getRed(&tr, green: &tg, blue: &tb, alpha: &ta)
        return Color(.sRGB,
                     red: Double(fr) + (Double(tr) - Double(fr)) * clamped,
                     green: Double(fg) + (Double(tg) - Double(fg)) * clamped,
                     blue: Double(fb) + (Double(tb) - Double(fb)) * clamped,
                     opacity: Double(fa) + (Double(ta) - Double(fa)) * clamped)
    }

    /// A readable foreground (black or white) for text drawn on top of this color.
    var readableForeground: Color {
        let ui = UIColor(self)
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        ui.getRed(&r, green: &g, blue: &b, alpha: &a)
        let luminance = 0.299 * r + 0.587 * g + 0.114 * b
        return luminance > 0.6 ? .black : .white
    }
}
