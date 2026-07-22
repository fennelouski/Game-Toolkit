import SwiftData

/// The app's single ModelContainer, shared by the main scene and the external-display
/// scoreboard so both windows show the same live data.
enum AppContainer {
    static let shared: ModelContainer = {
        let schema = Schema([Player.self, PlayerGroup.self])
        // Primary configuration syncs through CloudKit automatically when the iCloud
        // entitlement is present (the default `cloudKitDatabase` is `.automatic`).
        do {
            return try ModelContainer(
                for: schema,
                configurations: [ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)]
            )
        } catch {
            // If the on-disk (or CloudKit) store can't be opened for any reason, fall back to an
            // in-memory store so the app always launches instead of crashing on first run.
            print("⚠️ Falling back to in-memory store: \(error)")
            return try! ModelContainer(
                for: schema,
                configurations: [ModelConfiguration(schema: schema, isStoredInMemoryOnly: true, cloudKitDatabase: .none)]
            )
        }
    }()
}
