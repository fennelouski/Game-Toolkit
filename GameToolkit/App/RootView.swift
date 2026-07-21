import SwiftUI
import SwiftData

struct RootView: View {
    @Environment(\.modelContext) private var context
    @Query private var players: [Player]
    @AppStorage(SettingsKey.appearance) private var appearanceRaw = AppearanceMode.system.rawValue
    /// Remembers the last tab the player was on between launches.
    @AppStorage(SettingsKey.selectedTab) private var selectedTab = 0

    private var appearance: AppearanceMode {
        AppearanceMode(rawValue: appearanceRaw) ?? .system
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
        .tint(.accentColor)
        .preferredColorScheme(appearance.colorScheme)
        .task {
            #if DEBUG
            if ScreenshotSupport.isEnabled {
                ScreenshotSupport.seed(context, existing: players)
                return
            }
            #endif
            Roster.seedIfNeeded(context, existing: players)
        }
    }
}

#Preview {
    RootView()
        .modelContainer(for: Player.self, inMemory: true)
}
