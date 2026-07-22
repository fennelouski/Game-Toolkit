import SwiftUI

/// The one way a player's face is drawn anywhere in the app — roster rows, scorecard
/// header, TV scoreboard, pickers. Renders whichever avatar the player chose (photo,
/// emoji, monogram) and falls back to the classic initial-on-gradient circle.
struct PlayerAvatarView: View {
    @Environment(\.palette) private var palette

    let player: Player
    let size: CGFloat

    var body: some View {
        // A deleted model can still be handed in while its old row animates out;
        // reading its stored properties traps in SwiftData, so draw nothing instead.
        if player.isDeleted {
            Color.clear.frame(width: size, height: size)
        } else {
            face
        }
    }

    @ViewBuilder
    private var face: some View {
        switch player.avatarKind {
        case .photo:
            photoView
        case .emoji:
            ZStack {
                Circle().fill(player.fill(in: palette))
                Text(player.avatarEmoji ?? "🙂")
                    .font(.system(size: size * 0.58))
                    .minimumScaleFactor(0.5)
            }
            .frame(width: size, height: size)
        case .monogram:
            PlayerMonogramView(
                style: player.monogramStyle ?? PlayerMonogramStyle(),
                fallbackText: player.monogramInitials,
                playerFill: player.fill(in: palette),
                primaryColor: player.color(in: palette),
                size: size
            )
        case .initial:
            initialView
        }
    }

    @ViewBuilder
    private var photoView: some View {
        if let data = player.avatarImageData, let image = UIImage(data: data) {
            Image(uiImage: image)
                .resizable()
                .scaledToFill()
                .frame(width: size, height: size)
                .clipShape(Circle())
        } else {
            initialView
        }
    }

    private var initialView: some View {
        let color = player.color(in: palette)
        return ZStack {
            Circle().fill(player.fill(in: palette))
            Text(String((player.name.isEmpty ? "?" : player.name).prefix(1)).uppercased())
                .font(.display(size * 0.42))
                .minimumScaleFactor(0.5)
                .foregroundStyle(color.readableForeground)
        }
        .frame(width: size, height: size)
    }
}

/// Renders a designed monogram at any size. Everything in `PlayerMonogramStyle` is
/// relative to the box, so the same design holds from a 22 pt chip to a TV card.
struct PlayerMonogramView: View {
    let style: PlayerMonogramStyle
    /// Used when the style has no letters yet (initials derived from the name).
    let fallbackText: String
    let playerFill: AnyShapeStyle
    let primaryColor: Color
    let size: CGFloat

    private var text: String {
        let chosen = style.text.isEmpty ? fallbackText : style.text
        return String(chosen.prefix(3))
    }

    private var background: AnyShapeStyle {
        if let hex = style.backgroundHex { return AnyShapeStyle(Color(hex: hex).gradient) }
        return playerFill
    }

    private var textColor: Color {
        if let hex = style.textHex { return Color(hex: hex) }
        if let backgroundHex = style.backgroundHex { return Color(hex: backgroundHex).readableForeground }
        return primaryColor.readableForeground
    }

    var body: some View {
        let shape = RoundedRectangle(cornerRadius: size * style.cornerRadius, style: .continuous)
        letters
            .frame(width: size, height: size)
            .background(background, in: shape)
            .shadow(color: style.shadowEnabled ? .black.opacity(0.35) : .clear,
                    radius: size * 0.06, y: size * 0.03)
    }

    /// Tailor-style position kerning: letters left of center shift right and vice versa,
    /// stronger the farther out — a spread/overlap effect plain tracking can't do.
    private var letters: some View {
        let centerIndex = (Double(text.count) - 1) / 2
        return HStack(spacing: 0) {
            ForEach(Array(text.enumerated()), id: \.offset) { index, character in
                Text(String(character))
                    .font(.custom(style.fontName, size: size * style.fontScale))
                    .foregroundStyle(textColor)
                    .offset(x: style.kerning * size * (centerIndex - Double(index)))
            }
        }
        .lineLimit(1)
        .minimumScaleFactor(0.1)
        .padding(.horizontal, size * 0.06)
        .drawingGroup()
    }
}
