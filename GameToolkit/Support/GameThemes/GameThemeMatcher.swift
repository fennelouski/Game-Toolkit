import Foundation

/// Guesses which board game a game night is named after — "Catan – Fridays" wears Catan's
/// colors on its gallery card. Matching is deliberately conservative: a game's name, slug,
/// or alias must appear as a whole word (or word run) inside the group name, so
/// "Grassroots League" never matches Root. The longest match wins.
///
/// Runs entirely on-device over the already-known theme list (bundled + cached);
/// a group name is never used as a network query.
enum GameThemeMatcher {
    static func theme(for groupName: String, in themes: [AppTheme]) -> AppTheme? {
        let words = normalizedWords(groupName)
        guard !words.isEmpty else { return nil }

        var best: (theme: AppTheme, weight: Int)?
        for theme in themes {
            guard let game = theme.game else { continue }
            for candidate in [game.name, game.slug] + game.aliases {
                let needle = normalizedWords(candidate)
                guard !needle.isEmpty, containsRun(words, needle) else { continue }
                // Longest matched text wins: "Terraforming Mars" beats its "mars" alias,
                // and a longer game name beats a shorter one embedded in it.
                let weight = needle.reduce(0) { $0 + $1.count }
                if weight > (best?.weight ?? 0) { best = (theme, weight) }
            }
        }
        return best?.theme
    }

    /// Lowercased, diacritic-folded words; punctuation and dashes separate words, so
    /// "ticket-to-ride" and "Ticket to Ride!" normalize identically.
    static func normalizedWords(_ text: String) -> [String] {
        text.folding(options: [.diacriticInsensitive, .caseInsensitive], locale: nil)
            .components(separatedBy: CharacterSet.alphanumerics.inverted)
            .filter { !$0.isEmpty }
    }

    /// Whether `needle` appears in `haystack` as a consecutive run of whole words.
    private static func containsRun(_ haystack: [String], _ needle: [String]) -> Bool {
        guard haystack.count >= needle.count, !needle.isEmpty else { return false }
        return (0...(haystack.count - needle.count)).contains { start in
            Array(haystack[start..<(start + needle.count)]) == needle
        }
    }
}
