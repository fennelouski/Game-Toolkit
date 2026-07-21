import SwiftUI
import SwiftData

struct RootView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.colorScheme) private var systemColorScheme
    @Query private var players: [Player]
    @AppStorage(SettingsKey.appearance) private var appearanceRaw = AppearanceMode.system.rawValue
    /// Remembers the last tab the player was on between launches.
    @AppStorage(SettingsKey.selectedTab) private var selectedTab = 0
    @AppStorage(SettingsKey.onboardingCompleted) private var onboardingCompleted = false

    @State private var themeManager = ThemeManager.shared
    @State private var showOnboarding = false

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

    /// Gives every tab the themed tab bar without repeating the modifiers five times.
    private func themedTab(_ content: some View) -> some View {
        content
            .toolbarBackground(palette.surface, for: .tabBar)
            .toolbarBackground(.visible, for: .tabBar)
    }

    var body: some View {
        TabView(selection: $selectedTab) {
            themedTab(DiceRollerView())
                .tabItem { Label("Dice", systemImage: "dice.fill") }
                .tag(0)

            themedTab(TurnTimerView())
                .tabItem { Label("Timer", systemImage: "timer") }
                .tag(1)

            themedTab(ScorecardView())
                .tabItem { Label("Scores", systemImage: "list.number") }
                .tag(2)

            themedTab(PlayersView())
                .tabItem { Label("Players", systemImage: "person.2.fill") }
                .tag(3)

            themedTab(SettingsView())
                .tabItem { Label("Settings", systemImage: "gearshape.fill") }
                .tag(4)
        }
        .tint(palette.accent)
        .environment(\.palette, palette)
        .animation(.easeInOut(duration: 0.35), value: themeManager.selectedThemeID)
        .preferredColorScheme(appearance.colorScheme)
        #if DEBUG
        // `-ui.externalPreview` renders the TV scoreboard in-app so it can be checked
        // (and screenshotted) without a physical external display.
        .fullScreenCover(isPresented: .constant(ProcessInfo.processInfo.arguments.contains("-ui.externalPreview"))) {
            ExternalScoreboardRoot()
        }
        #endif
        .fullScreenCover(isPresented: $showOnboarding) {
            OnboardingView()
                .environment(\.palette, palette)
                .tint(palette.accent)
                .preferredColorScheme(appearance.colorScheme)
        }
        .task {
            GameThemeService.shared.restoreSelectedThemeIfNeeded()
            #if DEBUG
            if ScreenshotSupport.isEnabled {
                ScreenshotSupport.seed(context, existing: players)
                return
            }
            #endif
            Roster.seedIfNeeded(context, existing: players)
            Roster.adoptPaletteIndices(context, players: players)
            if !onboardingCompleted {
                showOnboarding = true
            }
        }
    }
}

#Preview {
    RootView()
        .modelContainer(for: Player.self, inMemory: true)
}
