import SwiftUI
import SwiftData

@main
struct GameToolkitApp: App {
    let container: ModelContainer

    init() {
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
                configurations: [ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)]
            )
        }
    }

    var body: some Scene {
        WindowGroup {
            RootView()
        }
        .modelContainer(container)
    }
}
