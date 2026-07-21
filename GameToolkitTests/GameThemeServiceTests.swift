import Testing
import Foundation
@testable import Game_Toolkit

// MARK: - Offline-first behavior of the game theme service

@Suite("Game theme service")
@MainActor
struct GameThemeServiceTests {

    /// A URLProtocol that fails every request, simulating no network / dead service.
    final class FailingURLProtocol: URLProtocol {
        override class func canInit(with request: URLRequest) -> Bool { true }
        override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }
        override func startLoading() {
            client?.urlProtocol(self, didFailWithError: URLError(.notConnectedToInternet))
        }
        override func stopLoading() {}
    }

    private func offlineService() -> GameThemeService {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [FailingURLProtocol.self]
        return GameThemeService(session: URLSession(configuration: configuration))
    }

    @Test("Bundled themes are available with no network, ever")
    func bundledThemesLoad() {
        let service = offlineService()
        #expect(service.themes.count >= 8)
        #expect(service.themes.contains { $0.id == "wingspan" })
        #expect(service.themes.contains { $0.id == "catan" })
    }

    @Test("A dead network leaves the theme list intact and never throws to the UI")
    func refreshFailsSilently() async {
        let service = offlineService()
        let before = service.themes.map(\.id)
        await service.refreshIfNeeded()
        #expect(service.themes.map(\.id) == before)
        #expect(!service.isRefreshing)
    }

    @Test("Search matches game names, slugs, aliases, and is typo-tolerant on case")
    func searchMatches() {
        let service = offlineService()
        #expect(service.search("Wingspan").first?.id == "wingspan")
        #expect(service.search("wing span").first?.id == "wingspan")
        #expect(service.search("CATAN").first?.id == "catan")
        #expect(service.search("settlers").first?.id == "catan")
        #expect(service.search("ttr").first?.id == "ticket-to-ride")
        #expect(service.search("frosthaven").first?.id == "gloomhaven")
        #expect(service.search("zzzzz-not-a-game").isEmpty)
    }

    @Test("An empty query lists everything alphabetically")
    func emptyQueryListsAll() {
        let service = offlineService()
        let results = service.search("")
        #expect(results.count == service.themes.count)
        let names = results.map(\.gameDisplayName)
        #expect(names == names.sorted())
    }

    @Test("Bundled game themes keep text readable (WCAG AA) in both variants")
    func bundledThemesHoldContrast() {
        let service = offlineService()
        for theme in service.themes {
            for (tag, p) in [("\(theme.id)/light", theme.light), ("\(theme.id)/dark", theme.dark)] {
                for surface in [p.backgroundHex, p.surfaceHex, p.surfaceElevatedHex] {
                    #expect(ColorMath.contrast(p.textPrimaryHex, surface) >= 4.5,
                            "\(tag): textPrimary on \(surface)")
                    #expect(ColorMath.contrast(p.textSecondaryHex, surface) >= 4.5,
                            "\(tag): textSecondary on \(surface)")
                }
                #expect(ColorMath.contrast(p.dicePipHex, p.diceFaceHex) >= 4.5, "\(tag): pips")
                #expect(p.playerHexes.count >= 10, "\(tag): players")
            }
        }
    }

    /// A manager backed by throwaway defaults so tests never touch real settings.
    private func freshManager() -> ThemeManager {
        let defaults = UserDefaults(suiteName: "test-\(UUID().uuidString)")!
        return ThemeManager(defaults: defaults)
    }

    @Test("Applying a game theme registers it and selects it")
    func applySelects() throws {
        let service = offlineService()
        let manager = freshManager()

        let wingspan = try #require(service.themes.first { $0.id == "wingspan" })
        service.apply(wingspan, in: manager)
        #expect(manager.selectedThemeID == "wingspan")
        #expect(manager.current.id == "wingspan")
        #expect(manager.availableThemes.contains { $0.id == "wingspan" })
    }

    @Test("A stored game-theme selection resolves again after a fresh launch")
    func restoreSelection() {
        let service = offlineService()
        let manager = freshManager()

        // Simulates launch: the stored selection points at a theme not yet registered.
        manager.selectedThemeID = "catan"
        #expect(manager.current.id == BuiltInThemes.defaultTheme.id)

        service.restoreSelectedThemeIfNeeded(in: manager)
        #expect(manager.current.id == "catan")
    }
}
