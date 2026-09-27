import SwiftData
import SwiftUI

/// Shares the persistent store, including recovery state, across both displays.
@MainActor
@Observable
final class AppContainer {
    static let shared = AppContainer()
    private(set) var container: ModelContainer?
    private let configuration: ModelConfiguration

    init(configuration: ModelConfiguration = ModelConfiguration()) {
        self.configuration = configuration
        load()
    }

    func load() {
        guard container == nil else { return }
        do {
            container = try ModelContainer(
                for: Schema([Player.self, PlayerGroup.self, DiceBag.self]),
                configurations: [configuration]
            )
        } catch {
            // Preserve the original store; a temporary store would silently lose new scores.
            container = nil
        }
    }
}

struct StoredContent<Content: View>: View {
    @ViewBuilder var content: () -> Content

    var body: some View {
        if let container = AppContainer.shared.container {
            content().modelContainer(container)
        } else {
            ContentUnavailableView {
                Label("Saved Games Unavailable", systemImage: "externaldrive.badge.exclamationmark")
            } description: {
                Text("Your saved data could not be opened. It has not been deleted. Check available storage, then try again.")
            } actions: {
                Button("Try Again") { AppContainer.shared.load() }
                Link("Contact Support", destination: URL(string: "https://nathanfennel.com/contact")!)
            }
        }
    }
}
