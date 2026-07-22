import SwiftUI

/// A grid of live miniature previews, one per display style, rendered by the real style
/// views with a frozen demo model. Used for the global default (selection is a raw
/// style id) and per-player picks (where `allowsDefault` adds a "Default" tile = nil).
struct TimerStylePickerView: View {
    @Environment(\.palette) private var palette

    /// The selected style's raw value; `nil` means "follow the default".
    @Binding var selection: String?
    /// Whether the current timer mode has a known total (gates fixed-length styles).
    let isFixedLength: Bool
    /// Show a leading "Default" tile representing `nil` (for per-player pickers).
    var allowsDefault = false
    /// The color previews render with; pass the player's color for per-player pickers.
    var previewColor: Color?

    private let columns = [GridItem(.adaptive(minimum: 140), spacing: 12)]

    var body: some View {
        LazyVGrid(columns: columns, spacing: 12) {
            if allowsDefault {
                tile(label: "Default", isSelected: selection == nil, available: true) {
                    Image(systemName: "circle.dashed")
                        .font(.largeTitle)
                        .foregroundStyle(palette.textSecondary)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } action: {
                    selection = nil
                }
            }

            ForEach(TimerDisplayStyle.allCases) { style in
                let available = style.isAvailable(isFixedLength: isFixedLength)
                tile(label: available ? style.displayName : style.unavailableReason,
                     isSelected: selection == style.rawValue,
                     available: available) {
                    TimerStyleView(
                        style: style,
                        model: .preview(color: previewColor ?? palette.playerColor(0)))
                        .allowsHitTesting(false)
                } action: {
                    selection = style.rawValue
                }
                .disabled(!available)
                .accessibilityLabel(style.displayName)
                .accessibilityHint(available ? "" : style.unavailableReason)
            }
        }
    }

    private func tile(label: String, isSelected: Bool, available: Bool,
                      @ViewBuilder content: () -> some View,
                      action: @escaping () -> Void) -> some View {
        Button {
            action()
            Haptics.selection()
        } label: {
            VStack(spacing: 6) {
                content()
                    .frame(height: 96)
                    .frame(maxWidth: .infinity)
                    .background {
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .fill(palette.surface)
                    }
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                    .overlay {
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .strokeBorder(isSelected ? palette.accent : palette.textSecondary.opacity(0.2),
                                          lineWidth: isSelected ? 2.5 : 1)
                    }
                    .overlay(alignment: .topTrailing) {
                        if isSelected {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundStyle(palette.accent)
                                .background(Circle().fill(palette.surface))
                                .padding(6)
                        }
                    }

                Text(label)
                    .font(.caption)
                    .foregroundStyle(isSelected ? palette.textPrimary : palette.textSecondary)
                    .lineLimit(1)
            }
            .opacity(available ? 1 : 0.35)
        }
        .buttonStyle(.plain)
    }
}
