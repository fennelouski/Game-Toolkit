# Game Toolkit

A companion app for board and tabletop games: roll dice, run a turn timer, and keep score —
with everything synced across your devices through iCloud.

Version 2.0 is a complete SwiftUI rebuild of the original 2015 Objective-C app.

## Features

| Screen | What it does |
| --- | --- |
| **Dice** | Roll 1–12 dice from d4 to d100. Animated tumble, haptics, running total, eight die colors. Tap the dice or shake the device to roll. |
| **Timer** | Chess-clock turn timer. Tap a player to start their clock and stop everyone else's; tap again to pause. Alarm sounds when someone runs out. |
| **Scores** | A round-by-round scorecard with running totals, a crown on the leader, and a cumulative Swift Charts graph. Tap any round to edit it. |
| **Players** | Manage the shared roster — rename, recolor, reorder, delete. Used by both the timer and the scorecard. |
| **Settings** | Dice and timer defaults, alarm length, haptics and sound toggles, light/dark/system theme, and live iCloud sync status. |

## Requirements

- iOS 17.0 or later (iPhone and iPad)
- Xcode 26 / Swift 5.0 language mode

## Architecture

- **SwiftUI** throughout — no storyboards, xibs, or view controllers.
- **SwiftData** for persistence, mirrored to the user's **private CloudKit database**. The
  `Player` model is CloudKit-compatible by construction: every property has a default value and
  there are no unique constraints.
- **Swift Charts** for the score graph (replacing the original's OpenGL-based `GTGraphView`).
- **Observation** (`@Observable`) for the dice and timer engines. The timer computes elapsed time
  from wall-clock deltas, so it never drifts even if a tick is late.
- The Xcode project uses a **file-system-synchronized group**, so any file added under
  `GameToolkit/` is picked up automatically — there is no need to edit `project.pbxproj`.

### Graceful degradation

`GameToolkitApp` creates its `ModelContainer` with CloudKit enabled, and falls back to an
in-memory store if the on-disk store cannot be opened. The app always launches, and it works
fully offline or when the user is signed out of iCloud — it simply stops syncing until iCloud
is available again. The Settings screen reports the current state.

## Project layout

```
GameToolkit/
  App/         GameToolkitApp (ModelContainer setup), RootView (tabs)
  Models/      Player (@Model), Roster (roster + round operations)
  Features/
    Dice/      DiceEngine, DieView, DiceRollerView
    Timer/     TimerEngine, TurnTimerView, TimeSetupSheet
    Scorecard/ ScorecardView, RoundEntrySheet, ScoreChartView
    Players/   PlayersView, PlayerEditorSheet
    Settings/  SettingsView
  Support/     Color+Hex, Theme, Haptics, AudioManager, ShakeDetector, SettingsKey
  Resources/   Assets.xcassets, alarm sound, PrivacyInfo.xcprivacy
GameToolkitTests/   Swift Testing suites for scoring, roster and formatting logic
Config/Info.plist   Base plist (background modes); all other keys are generated
Design/             Source artwork (app icon, splash screens, PSD/SVG)
```

## Build and test

```sh
# Build for the simulator
xcodebuild -project "Game Toolkit.xcodeproj" -scheme "Game Toolkit" \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro' build

# Run the unit tests
xcodebuild -project "Game Toolkit.xcodeproj" -scheme "Game Toolkit" \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro' test
```

## Enabling iCloud sync

The code and entitlements are already in place. To sync on real devices, the app's App ID needs
these capabilities in the Apple Developer portal (Xcode's automatic signing can add them):

1. **iCloud** with CloudKit, using the container `iCloud.com.nathanfennel.Game-Toolkit`.
2. **Push Notifications** — CloudKit uses silent pushes to tell the app that data changed. The
   matching `remote-notification` background mode is already declared in `Config/Info.plist`.

Without those, the app still builds and runs; it just keeps data on-device only.

## Notes on the rebuild

The original app stored player names in `NSUserDefaults` under obfuscated keys and never
persisted scores at all — closing the app lost the game. Scores are now first-class, durable,
and synced. Roughly 1.3 MB of dead Objective-C was removed in the rewrite, including
`BRReferenceManager`, which belonged to an entirely different app.
