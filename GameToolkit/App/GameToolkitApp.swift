import SwiftUI
import SwiftData

@main
struct GameToolkitApp: App {
    #if os(iOS) && !targetEnvironment(macCatalyst)
    /// Routes external-display scene sessions (AirPlay mirroring, HDMI) to the scoreboard.
    @UIApplicationDelegateAdaptor(ExternalDisplayAppDelegate.self) private var appDelegate
    #endif

    init() {
        Self.configureNavigationTypography()
    }

    var body: some Scene {
        WindowGroup {
            RootView()
        }
        .modelContainer(AppContainer.shared)
    }

    /// Navigation titles render in the serif display face (New York) app-wide, which is
    /// half of the Hearth design language; the other half is color, which flows through
    /// the palette environment.
    private static func configureNavigationTypography() {
        func serif(_ style: UIFont.TextStyle, weight: UIFont.Weight) -> UIFont {
            let base = UIFont.preferredFont(forTextStyle: style)
            var descriptor = base.fontDescriptor
            if let serifDescriptor = descriptor.withDesign(.serif) {
                descriptor = serifDescriptor
            }
            descriptor = descriptor.addingAttributes([
                .traits: [UIFontDescriptor.TraitKey.weight: weight]
            ])
            return UIFont(descriptor: descriptor, size: 0)
        }

        let appearance = UINavigationBar.appearance()
        appearance.largeTitleTextAttributes = [.font: serif(.largeTitle, weight: .bold)]
        appearance.titleTextAttributes = [.font: serif(.headline, weight: .semibold)]
    }
}
