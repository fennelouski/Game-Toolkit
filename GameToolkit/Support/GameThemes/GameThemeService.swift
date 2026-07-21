import Foundation
import Observation

/// Fetches and caches game-inspired themes from the theme repository, with a bundled
/// snapshot so search works offline and on day one.
///
/// Design rules, in order:
/// - The UI never waits on the network; everything reads from memory.
/// - Search runs entirely on-device over the known theme list, so queries never leave
///   the phone. The only network traffic is anonymous GETs for static JSON.
/// - Every failure is silent. If the service is unreachable — or retired years from
///   now — the bundled and previously-cached themes keep working forever.
@MainActor
@Observable
final class GameThemeService {
    static let shared = GameThemeService()

    /// Every game theme currently known: bundled + cached + freshly fetched.
    private(set) var themes: [AppTheme] = []
    /// True while a background refresh is running; the UI may show a subtle hint, never a blocker.
    private(set) var isRefreshing = false

    private let remoteIndexURL = URL(string: "https://game-toolkit-themes.vercel.app/api/v1/themes.json")
    private let session: URLSession
    private var hasRefreshed = false

    init(session: URLSession? = nil) {
        if let session {
            self.session = session
        } else {
            // Ephemeral: no cookies, no credential store; we only ever GET public JSON.
            let configuration = URLSessionConfiguration.ephemeral
            configuration.timeoutIntervalForRequest = 10
            configuration.requestCachePolicy = .reloadRevalidatingCacheData
            self.session = URLSession(configuration: configuration)
        }
        themes = Self.loadBundledThemes()
        mergeCachedThemes()
    }

    // MARK: - Search

    /// Case- and diacritic-insensitive fuzzy match over game names, aliases, theme names,
    /// and tags. Runs locally; the query never leaves the device.
    func search(_ query: String) -> [AppTheme] {
        let needle = Self.normalize(query)
        guard !needle.isEmpty else { return themes.sorted { $0.gameDisplayName < $1.gameDisplayName } }

        return themes.compactMap { theme -> (AppTheme, Int)? in
            guard let score = Self.matchScore(theme, needle: needle) else { return nil }
            return (theme, score)
        }
        .sorted { $0.1 == $1.1 ? $0.0.gameDisplayName < $1.0.gameDisplayName : $0.1 > $1.1 }
        .map(\.0)
    }

    private static func matchScore(_ theme: AppTheme, needle: String) -> Int? {
        var candidates: [(String, Int)] = [(theme.name, 60)]
        if let game = theme.game {
            candidates.append((game.name, 100))
            candidates.append((game.slug, 90))
            candidates.append(contentsOf: game.aliases.map { ($0, 80) })
        }
        candidates.append(contentsOf: theme.tags.map { ($0, 40) })

        var best: Int?
        for (text, weight) in candidates {
            let haystack = normalize(text)
            let score: Int?
            if haystack == needle { score = weight + 30 }
            else if haystack.hasPrefix(needle) { score = weight + 15 }
            else if haystack.contains(needle) { score = weight }
            else { score = nil }
            if let score { best = max(best ?? .min, score) }
        }
        return best
    }

    private static func normalize(_ text: String) -> String {
        text.folding(options: [.diacriticInsensitive, .caseInsensitive], locale: nil)
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }

    // MARK: - Applying

    /// Makes a game theme selectable and selects it.
    func apply(_ theme: AppTheme) {
        apply(theme, in: .shared)
    }

    func apply(_ theme: AppTheme, in manager: ThemeManager) {
        manager.register(theme)
        manager.select(theme)
    }

    /// Re-registers previously used game themes after launch so a stored selection
    /// resolves. Called once from the root view.
    func restoreSelectedThemeIfNeeded() {
        restoreSelectedThemeIfNeeded(in: .shared)
    }

    func restoreSelectedThemeIfNeeded(in manager: ThemeManager) {
        let selectedID = manager.selectedThemeID
        guard BuiltInThemes.theme(id: selectedID) == nil,
              let theme = themes.first(where: { $0.id == selectedID }) else { return }
        manager.register(theme)
    }

    // MARK: - Refresh

    /// Fetches the remote theme list once per launch, quietly merging anything new.
    func refreshIfNeeded() async {
        guard !hasRefreshed, !isRefreshing, let url = remoteIndexURL else { return }
        isRefreshing = true
        defer { isRefreshing = false }

        do {
            var request = URLRequest(url: url)
            if let etag = storedETag {
                request.setValue(etag, forHTTPHeaderField: "If-None-Match")
            }
            let (data, response) = try await session.data(for: request)
            guard let http = response as? HTTPURLResponse else { return }
            if http.statusCode == 304 { hasRefreshed = true; return }
            guard http.statusCode == 200 else { return }

            let fetched = try Self.decoder.decode([AppTheme].self, from: data)
            merge(fetched.filter(\.isSupported))
            try? data.write(to: Self.cacheFileURL, options: .atomic)
            storedETag = http.value(forHTTPHeaderField: "ETag")
            hasRefreshed = true
        } catch {
            // Offline, rate-limited, or the service is gone: the bundled themes carry on.
        }
    }

    // MARK: - Storage

    private static var decoder: JSONDecoder {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }

    private static func loadBundledThemes() -> [AppTheme] {
        guard let url = Bundle.main.url(forResource: "bundled-game-themes", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let bundled = try? decoder.decode([AppTheme].self, from: data) else {
            return []
        }
        return bundled.filter(\.isSupported)
    }

    private static var cacheFileURL: URL {
        let directory = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("GameThemes", isDirectory: true)
        try? FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        return directory.appendingPathComponent("cached-themes.json")
    }

    private func mergeCachedThemes() {
        guard let data = try? Data(contentsOf: Self.cacheFileURL),
              let cached = try? Self.decoder.decode([AppTheme].self, from: data) else { return }
        merge(cached.filter(\.isSupported))
    }

    /// Newer documents replace older copies of the same theme id.
    private func merge(_ incoming: [AppTheme]) {
        for theme in incoming {
            if let index = themes.firstIndex(where: { $0.id == theme.id }) {
                themes[index] = theme
            } else {
                themes.append(theme)
            }
        }
    }

    private var storedETag: String? {
        get { UserDefaults.standard.string(forKey: "gameThemes.etag") }
        set { UserDefaults.standard.set(newValue, forKey: "gameThemes.etag") }
    }
}

extension AppTheme {
    /// What to show in game-search results: the game when there is one, else the theme name.
    var gameDisplayName: String { game?.name ?? name }
}
