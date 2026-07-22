# Game Toolkit

A companion app for board and tabletop games: roll dice, run a turn timer, and keep score —
with everything synced across your devices through iCloud.

Version 2.0 is a complete SwiftUI rebuild of the original 2015 Objective-C app. Version 2.1
adds the **Hearth** design language — felt, paper, and serif type instead of stock SwiftUI —
plus a full theming system with board-game-inspired themes served from a tiny Vercel
backend ([`server/`](server/)).

## Platforms

| Platform | How |
| --- | --- |
| iPhone, iPad | Native, iOS 17+ |
| Mac | Mac Catalyst (a real Mac app, sandboxed for the Mac App Store) |
| Apple Vision Pro | Runs as a Designed-for-iPad app |

## Features

| Screen | What it does |
| --- | --- |
| **Dice** | 1–30 dice, any number of sides from 2 to 100. Animated tumble roll, haptics, running total, eight die colors, seven dot sizes. **Tap a die to hold it** so it sits out the next roll (Yahtzee-style); shake or press Roll to throw the rest. |
| **Timer** | Chess-clock turn timer. Tap a player to start their clock and stop everyone else's; tap again to pause. Alarm sounds when someone runs out. |
| **Scores** | Round-by-round scorecard with running totals, a crown on the leader, and per-round editing. Charts show either everyone's cumulative totals or one player's round-by-round scores. Shake to shuffle the turn order. |
| **Players** | Manage the shared roster — rename, recolor, reorder, delete. Used by both the timer and the scorecard. |
| **Settings** | Theme picker, dice and timer defaults, alarm length, haptics and sound, light/dark/system appearance, TV scoreboard toggle, reset actions, and live iCloud sync status. |
| **TV scoreboard** | Mirror to an Apple TV (or plug into any screen) and the big screen becomes a live, theme-aware scoreboard instead of a copy of your phone — totals, last-round deltas, and a crown on the leader. Toggle off in Settings to mirror normally. iPhone/iPad only. |

## Theming

Every screen reads a small set of **semantic color roles** (background, surface, table,
accent, text, dice, an ordered 10-color player palette, …) from a `ThemePalette` in the
SwiftUI environment — no view touches a literal color. Six built-in themes ship in the app
(each with light *and* dark variants): **Hearth** (the default — deep green felt, parchment,
clay), Meadow, Table Rules, Gaslight, Toolbox (the 2.0 look), and High Contrast.

- **Contrast is enforced by tests.** `ThemeContrastTests` fails the build if any text/surface
  pair drops below WCAG AA (4.5:1), semantic colors below 3:1, or if any two player colors
  become hard to tell apart — including under simulated protanopia and deuteranopia.
- **Players follow the theme.** `Player.paletteIndex` maps a player onto the palette, so the
  roster (and the score chart) recolors when the theme changes; explicitly chosen custom
  colors are stored as hex and never overridden.
- **Game themes.** Search "what are you playing tonight" (onboarding, Settings, or the
  toolbar swatch) and the app re-skins to match — eight game-inspired themes ship in the
  bundle and more sync quietly from the [theme repository](server/). Search runs entirely
  on-device; queries never leave the phone. Themes are purely cosmetic: **no feature is ever
  gated by a theme, a game, or the network**, and the app works fully offline forever.
- The chosen theme syncs across devices through iCloud's key-value store.

To add a game theme, see [`server/README.md`](server/README.md) — one JSON file, one PR;
CI validates schema and contrast.

Every feature of the original app is present. Shake gestures (roll dice, shuffle turn order) only
exist on iPhone and iPad, so each one also has a button or menu item for Mac and Vision Pro.

## Requirements

- iOS 17.0+ / macOS 14.0+ (Catalyst)
- Xcode 26, Swift 5 language mode

## Architecture

- **SwiftUI** throughout — no storyboards, xibs, or view controllers.
- **SwiftData** for persistence, mirrored to the user's **private CloudKit database**. The
  `Player` model is CloudKit-compatible by construction: every property has a default value and
  there are no unique constraints.
- **Swift Charts** for the score graphs (replacing the original's OpenGL `GTGraphView`).
- **Observation** (`@Observable`) for the dice and timer engines. The timer computes elapsed time
  from wall-clock deltas, so it never drifts even if a tick is late.
- The Xcode project uses a **file-system-synchronized group**, so any file added under
  `GameToolkit/` is picked up automatically — no `project.pbxproj` editing required.

### Graceful degradation

`GameToolkitApp` creates its `ModelContainer` with CloudKit enabled and falls back to an
in-memory store if the on-disk store cannot be opened. The app always launches, and works fully
offline or when signed out of iCloud — it simply stops syncing until iCloud is available again.
Settings reports the current state.

## Project layout

```
GameToolkit/
  App/         GameToolkitApp (ModelContainer setup), RootView (tabs), OnboardingView
  Models/      Player (@Model), Roster (roster + round operations)
  Features/
    Dice/      DiceEngine, DieView, DiceRollerView
    Timer/     TimerEngine, TurnTimerView, TimeSetupSheet
    Scorecard/ ScorecardView, RoundEntrySheet, ScoreChartView
    Players/   PlayersView, PlayerEditorSheet, TurnOrderSheet
    Settings/  SettingsView
  Support/
    Theme/     ThemeModels (ThemePalette/AppTheme), BuiltInThemes, ThemeManager,
               ThemeComponents (FeltSurface, buttons, chips, theme pickers)
    GameThemes/ GameThemeService (offline-first fetch/cache/search), GameThemeSearchView
    Color+Hex, Theme (legacy palettes), Haptics, AudioManager, ShakeDetector,
    SettingsKey, ScreenshotSupport (DEBUG only)
  Resources/   Assets.xcassets, alarm sound, bundled game themes, PrivacyInfo.xcprivacy
GameToolkitTests/   57 Swift Testing tests across 11 suites
server/             Theme repository for Vercel (static JSON API + search function)
Config/Info.plist   Base plist (background modes); all other keys are generated
Scripts/            Screenshot automation
Screenshots/        Generated App Store screenshots
Design/             Source artwork, plus a ready-made visionOS layered icon
```

## Build and test

```sh
# Build for the simulator
xcodebuild -project "Game Toolkit.xcodeproj" -scheme "Game Toolkit" \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro Max' build

# Run the tests
xcodebuild -project "Game Toolkit.xcodeproj" -scheme "Game Toolkit" \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro Max' test

# Mac Catalyst
xcodebuild -project "Game Toolkit.xcodeproj" -scheme "Game Toolkit" \
  -destination 'platform=macOS,variant=Mac Catalyst' build
```

## Screenshots

```sh
./Scripts/screenshots.sh        # iPhone + iPad + Mac
./Scripts/screenshots.sh ios    # just iPhone and iPad
python3 Scripts/marketing.py    # captioned App Store marketing images
```

Output lands in `Screenshots/` at exact App Store sizes — iPhone 6.9" (1320×2868),
iPad 13" (2064×2752), Mac (2560×1600). Demo data comes from a `-screenshotMode` launch argument
that is compiled only into Debug builds, so it can never ship. `Scripts/marketing.py`
(needs Pillow) composites the raw screenshots into captioned marketing images in
`Screenshots/marketing/`, sized for App Store Connect.

## Before submitting to the App Store

**See [`Docs/AppStore.md`](Docs/AppStore.md)** for the complete listing, field by field —
name, subtitle, description, keywords, screenshot mapping, age rating, privacy answers,
export compliance, and review notes. The supporting pages are live:

- Marketing URL: <https://nathanfennel.com/game-toolkit>
- Support URL: <https://nathanfennel.com/game-toolkit/support>
- Privacy policy URL: <https://nathanfennel.com/game-toolkit/privacy>
- Theme service: `https://game-toolkit-themes.vercel.app/api/v1/` (deployed; redeploy with
  `cd server && npx vercel deploy --prod --yes`)

The code, entitlements, icons, and privacy manifest are in place. Two things need your Apple
Developer account, which cannot be automated here:

1. **iCloud** capability with CloudKit, container `iCloud.com.nathanfennel.Game-Toolkit`.
2. **Push Notifications** capability — CloudKit uses silent pushes to signal changes. The matching
   `remote-notification` background mode is already declared in `Config/Info.plist`.

Vision Pro needs no extra work: the app ships there as a Designed-for-iPad app and reuses the
iPad screenshots. If you would rather ship a **native** visionOS app, the platform install on
this machine is incomplete (the simulator runtime downloads but never mounts, which needs
elevated privileges). Finish it via Xcode ▸ Settings ▸ Components, then set
`SUPPORTED_PLATFORMS` to include `xros xrsimulator`, set `SUPPORTS_XR_DESIGNED_FOR_IPHONE_IPAD`
to `NO`, add `7` to `TARGETED_DEVICE_FAMILY`, and move
`Design/visionOS-AppIcon/AppIconVision.solidimagestack` into `Assets.xcassets` (a layered icon is
already prepared).

## Notes on the rebuild

The original app stored player names in `NSUserDefaults` under obfuscated keys and never
persisted scores at all — closing the app lost the game. Scores are now first-class, durable, and
synced. Roughly 1.3 MB of dead Objective-C was removed, including `BRReferenceManager`, which
belonged to an entirely different app.
