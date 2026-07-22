import Testing
import Foundation
@testable import Game_Toolkit

// MARK: - Guessing the game behind a game-night name

@Suite("Game theme matcher")
@MainActor
struct GameThemeMatcherTests {

    /// The bundled theme list — the same data the gallery matches against offline.
    private var themes: [AppTheme] {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = []
        return GameThemeService(session: URLSession(configuration: configuration)).themes
    }

    @Test("A game name inside a group name matches, whatever the trimmings")
    func matchesEmbeddedNames() {
        #expect(GameThemeMatcher.theme(for: "Catan – Fridays", in: themes)?.id == "catan")
        #expect(GameThemeMatcher.theme(for: "CATAN!!!", in: themes)?.id == "catan")
        #expect(GameThemeMatcher.theme(for: "Wingspan Wednesdays", in: themes)?.id == "wingspan")
        #expect(GameThemeMatcher.theme(for: "Tuesday Ticket to Ride Club", in: themes)?.id == "ticket-to-ride")
    }

    @Test("Aliases and slugs count too")
    func matchesAliases() {
        #expect(GameThemeMatcher.theme(for: "Settlers of Catan Sundays", in: themes)?.id == "catan")
        #expect(GameThemeMatcher.theme(for: "TTR Thursdays", in: themes)?.id == "ticket-to-ride")
        #expect(GameThemeMatcher.theme(for: "Frosthaven Party", in: themes)?.id == "gloomhaven")
        #expect(GameThemeMatcher.theme(for: "ticket-to-ride league", in: themes)?.id == "ticket-to-ride")
    }

    @Test("Only whole words match — no substring surprises")
    func noSubstringMatches() {
        // "Root" is a bundled game; buried inside another word it must not trigger.
        #expect(GameThemeMatcher.theme(for: "Grassroots League", in: themes) == nil)
        #expect(GameThemeMatcher.theme(for: "Root Cellar Crew", in: themes)?.id == "root")
    }

    @Test("Ordinary game nights match nothing")
    func plainNamesStayPlain() {
        #expect(GameThemeMatcher.theme(for: "Family Game Night", in: themes) == nil)
        #expect(GameThemeMatcher.theme(for: "Office Lunch Crew", in: themes) == nil)
        #expect(GameThemeMatcher.theme(for: "", in: themes) == nil)
    }

    @Test("The longest match wins over a short alias")
    func longestMatchWins() {
        // "Terraforming Mars Mondays" hits both the full name and the "mars" alias;
        // either way the same theme must win, driven by the longer text.
        #expect(GameThemeMatcher.theme(for: "Terraforming Mars Mondays", in: themes)?.id == "terraforming-mars")
        #expect(GameThemeMatcher.theme(for: "Mars Mondays", in: themes)?.id == "terraforming-mars")
    }
}
