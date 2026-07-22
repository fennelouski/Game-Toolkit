import SwiftUI

/// Everything a display style needs to render one timer. Styles receive this value type
/// and nothing else — they never touch the engine or SwiftData, which is what lets the
/// picker render live previews from a canned model.
struct TimerDisplayModel: Equatable {
    /// Seconds left as of `builtAt`. Zero for count-up.
    var remaining: Double
    /// Seconds used as of `builtAt`.
    var elapsed: Double
    /// Full budget; `nil` for count-up.
    var total: Double?
    var isCountUp: Bool
    var playerName: String
    var playerColor: Color
    var isActive: Bool
    var isPaused: Bool
    var isExpired: Bool
    /// The moment the snapshot was taken; anchors sub-second interpolation.
    var builtAt: Date = .now
    /// Picker tiles set this to freeze animation at a representative instant.
    var isPreview: Bool = false

    var isFixedLength: Bool { total != nil }

    /// Remaining time as a share of the budget, 1 → full, 0 → out of time.
    var fraction: Double {
        guard let total, total > 0 else { return 0 }
        return (remaining / total).clamped(to: 0...1)
    }

    /// Share of the budget already used, 0 → fresh, 1 → out of time.
    var elapsedFraction: Double { isFixedLength ? 1 - fraction : 0 }

    // MARK: - Sub-second interpolation

    /// Wall-clock remaining time for `TimelineView`-driven styles; static while inactive.
    func remaining(at date: Date) -> Double {
        guard isActive, !isPreview else { return remaining }
        return max(0, remaining - date.timeIntervalSince(builtAt))
    }

    func elapsed(at date: Date) -> Double {
        guard isActive, !isPreview else { return elapsed }
        return elapsed + max(0, date.timeIntervalSince(builtAt))
    }

    func fraction(at date: Date) -> Double {
        guard let total, total > 0 else { return 0 }
        return (remaining(at: date) / total).clamped(to: 0...1)
    }

    /// The canned state picker tiles render: a bit past one-third through a minute.
    static func preview(color: Color, name: String = "", total: Double? = 60) -> TimerDisplayModel {
        TimerDisplayModel(remaining: total.map { $0 * 0.62 } ?? 0, elapsed: (total ?? 60) * 0.38,
                          total: total, isCountUp: total == nil, playerName: name,
                          playerColor: color, isActive: true, isPaused: false,
                          isExpired: false, isPreview: true)
    }
}

/// One VoiceOver contract for every style, so purely visual renderings (hourglass,
/// snowfall) are never silent for screen-reader users.
struct TimerStyleAccessibility: ViewModifier {
    let model: TimerDisplayModel

    func body(content: Content) -> some View {
        content
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(label)
    }

    private var label: String {
        let name = model.playerName.isEmpty ? "Timer" : model.playerName
        if model.isExpired { return "\(name), time's up" }
        let time = model.isCountUp
            ? "\(Int(model.elapsed)) seconds elapsed"
            : "\(Int(model.remaining)) seconds remaining"
        let state = model.isActive ? ", running" : (model.isPaused ? ", paused" : "")
        return "\(name), \(time)\(state)"
    }
}
