import SwiftUI
import SwiftData

struct RootView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.colorScheme) private var systemColorScheme
    @Query private var players: [Player]
    @AppStorage(SettingsKey.appearance) private var appearanceRaw = AppearanceMode.system.rawValue
    /// Remembers the last tab the player was on between launches.
    @AppStorage(SettingsKey.selectedTab) private var selectedTab = 0

    @State private var themeManager = ThemeManager.shared

    private var appearance: AppearanceMode {
        AppearanceMode(rawValue: appearanceRaw) ?? .system
    }

    /// The scheme the app actually renders in: the user's override, else the system's.
    private var effectiveColorScheme: ColorScheme {
        appearance.colorScheme ?? systemColorScheme
    }

    private var palette: ThemePalette {
        themeManager.current.palette(for: effectiveColorScheme)
    }

    var body: some View {
        TabView(selection: $selectedTab) {
            DiceRollerView()
                .tabItem { Label("Dice", systemImage: "dice.fill") }
                .tag(0)

            TurnTimerView()
                .tabItem { Label("Timer", systemImage: "timer") }
                .tag(1)

            ScorecardView()
                .tabItem { Label("Scores", systemImage: "list.number") }
                .tag(2)

            PlayersView()
                .tabItem { Label("Players", systemImage: "person.2.fill") }
                .tag(3)

            SettingsView()
                .tabItem { Label("Settings", systemImage: "gearshape.fill") }
                .tag(4)
        }
        .tint(palette.accent)
        .environment(\.palette, palette)
        .animation(.easeInOut(duration: 0.35), value: themeManager.selectedThemeID)
        .preferredColorScheme(appearance.colorScheme)
        .task {
            #if DEBUG
            if ScreenshotSupport.isEnabled {
                ScreenshotSupport.seed(context, existing: players)
                return
            }
            #endif
            Roster.seedIfNeeded(context, existing: players)
            Roster.adoptPaletteIndices(context, players: players)
        }
    }
}

#Preview {
    RootView()
        .modelContainer(for: Player.self, inMemory: true)
}
