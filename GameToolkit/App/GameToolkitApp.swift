import SwiftUI
import SwiftData

@main
struct GameToolkitApp: App {
    let container: ModelContainer

    init() {
        Self.configureNavigationTypography()
        let schema = Schema([Player.self])
        // Primary configuration syncs through CloudKit automatically when the iCloud
        // entitlement is present (the default `cloudKitDatabase` is `.automatic`).
        do {
            container = try ModelContainer(
                for: schema,
                configurations: [ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)]
            )
        } catch {
            // If the on-disk (or CloudKit) store can't be opened for any reason, fall back to an
            // in-memory store so the app always launches instead of crashing on first run.
            print("⚠️ Falling back to in-memory store: \(error)")
            container = try! ModelContainer(
                for: schema,
                configurations: [ModelConfiguration(schema: schema, isStoredInMemoryOnly: true, cloudKitDatabase: .none)]
            )
        }
    }

    var body: some Scene {
        WindowGroup {
            RootView()
        }
        .modelContainer(container)
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
