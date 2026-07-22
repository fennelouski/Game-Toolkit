import SwiftUI

/// Renders one timer in the given display style. The single entry point for cards, the
/// full-screen single timer, and the picker's live previews.
struct TimerStyleView: View {
    let style: TimerDisplayStyle
    let model: TimerDisplayModel

    var body: some View {
        Group {
            switch style {
            case .classic: ClassicDigitalStyle(model: model)
            case .speedcube: SpeedcubeStyle(model: model)
            case .analog: AnalogClockStyle(model: model)
            case .progressBar: ProgressBarStyle(model: model)
            case .waterClock: WaterClockStyle(model: model)
            case .snowfall: SnowfallStyle(model: model)
            case .hourglass: HourglassStyle(model: model)
            case .sundial: SundialStyle(model: model)
            case .sunriseSunset: SunriseSunsetStyle(model: model)
            case .battery: BatteryStyle(model: model)
            }
        }
        .modifier(TimerStyleAccessibility(model: model))
    }
}
