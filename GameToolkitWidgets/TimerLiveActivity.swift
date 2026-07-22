import ActivityKit
import WidgetKit
import SwiftUI

/// The Lock Screen / Dynamic Island rendering of a running turn timer. The system draws
/// the ticking clock itself from the date anchors, so this stays live with no updates.
struct TimerLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: TimerActivityAttributes.self) { context in
            LockScreenTimerView(state: context.state)
                .activityBackgroundTint(Color.black.opacity(0.55))
                .activitySystemActionForegroundColor(.white)
        } dynamicIsland: { context in
            DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    HStack(spacing: 6) {
                        Circle()
                            .fill(context.state.playerTint)
                            .frame(width: 10, height: 10)
                        Text(context.state.playerName)
                            .font(.headline)
                            .lineLimit(1)
                    }
                    .padding(.leading, 4)
                }
                DynamicIslandExpandedRegion(.trailing) {
                    TimerClockText(state: context.state)
                        .font(.title2.weight(.semibold))
                        .monospacedDigit()
                        .frame(maxWidth: 90)
                        .foregroundStyle(context.state.playerTint)
                }
            } compactLeading: {
                Circle()
                    .fill(context.state.playerTint)
                    .frame(width: 12, height: 12)
            } compactTrailing: {
                TimerClockText(state: context.state)
                    .monospacedDigit()
                    .frame(maxWidth: 52)
                    .foregroundStyle(context.state.playerTint)
            } minimal: {
                Image(systemName: context.state.isPaused ? "pause.fill" : "timer")
                    .foregroundStyle(context.state.playerTint)
            }
            .keylineTint(context.state.playerTint)
        }
    }
}

private struct LockScreenTimerView: View {
    let state: TimerActivityAttributes.ContentState

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 6) {
                    Circle().fill(state.playerTint).frame(width: 10, height: 10)
                    Text(state.playerName)
                        .font(.headline)
                        .lineLimit(1)
                }
                Text(state.isPaused ? "Paused" : (state.startDate != nil ? "Counting up" : "Time remaining"))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            TimerClockText(state: state)
                .font(.system(size: 38, weight: .semibold, design: .rounded))
                .monospacedDigit()
                .multilineTextAlignment(.trailing)
                .foregroundStyle(state.playerTint)
                .frame(maxWidth: 130)
        }
        .padding(16)
        .foregroundStyle(.white)
    }
}

/// The ticking (or frozen) clock. `Text(timerInterval:)` keeps counting system-side.
private struct TimerClockText: View {
    let state: TimerActivityAttributes.ContentState

    var body: some View {
        if state.isPaused, let remaining = state.pausedRemaining {
            Text(clockString(remaining))
        } else if let end = state.endDate {
            Text(timerInterval: Date.now...max(Date.now, end), countsDown: true)
        } else if let start = state.startDate {
            Text(timerInterval: start...Date.distantFuture, countsDown: false)
        } else {
            Text("--:--")
        }
    }

    private func clockString(_ seconds: TimeInterval) -> String {
        let total = max(0, Int(seconds.rounded(.up)))
        return String(format: "%d:%02d", total / 60, total % 60)
    }
}

private extension TimerActivityAttributes.ContentState {
    /// The player's color; the widget can't reach the app's theme environment, so it
    /// decodes the hex snapshot carried in the state.
    var playerTint: Color {
        let hex = colorHex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var value: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&value)
        guard hex.count == 6 else { return .accentColor }
        return Color(.sRGB,
                     red: Double(value >> 16 & 0xFF) / 255,
                     green: Double(value >> 8 & 0xFF) / 255,
                     blue: Double(value & 0xFF) / 255)
    }
}
