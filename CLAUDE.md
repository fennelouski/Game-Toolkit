# Game Toolkit — working notes

SwiftUI board-game companion (dice roller, chess-clock turn timer, scorecard) backed by
SwiftData + CloudKit. iOS 17+, Xcode 26, Swift 5 language mode.

## Commands

```sh
# Build
xcodebuild -project "Game Toolkit.xcodeproj" -scheme "Game Toolkit" \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro' build

# Test (19 Swift Testing tests across 3 suites)
xcodebuild -project "Game Toolkit.xcodeproj" -scheme "Game Toolkit" \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro' test
```

To install and drive the app in a simulator, append
`CODE_SIGN_IDENTITY="-" CODE_SIGNING_REQUIRED=NO` — do **not** use `CODE_SIGNING_ALLOWED=NO`,
which produces an unsigned bundle whose sandbox container can't be created, so the SwiftData
store fails with `file-write-create denied` and the app silently falls back to in-memory.

The tab bar honours a launch argument, which is handy for screenshots:
`xcrun simctl launch <device> com.nathanfennel.Game-Toolkit -ui.selectedTab 2`
(0 Dice, 1 Timer, 2 Scores, 3 Players, 4 Settings).

## Conventions and gotchas

- **Adding files needs no project edits.** The target uses a `PBXFileSystemSynchronizedRootGroup`
  (objectVersion 77), so anything dropped under `GameToolkit/` or `GameToolkitTests/` is compiled
  automatically. Only touch `project.pbxproj` to add targets or build settings.
- **Keep the schema CloudKit-compatible.** Every stored property on a `@Model` needs a default
  value (or must be optional), relationships must be optional with inverses, and unique
  constraints are not allowed. Breaking this makes `ModelContainer` init throw, which silently
  drops the app into the in-memory fallback in `GameToolkitApp`.
- **`INFOPLIST_KEY_*` only supports an Xcode allowlist.** `UIBackgroundModes` is not on it and is
  silently ignored — that is why `Config/Info.plist` exists as a merge base alongside
  `GENERATE_INFOPLIST_FILE = YES`. Verify plist changes actually land in the built bundle.
- **`Swift.max` inside numeric extensions.** In an `extension Int`, bare `max` resolves to the
  static `Int.max` property, not the global function. See `Theme.swift`.
- **Timer correctness.** `TimerEngine` derives remaining time from `Date` deltas rather than
  counting ticks, so a delayed or coalesced timer never causes drift. Keep that property if you
  change it.
- Player color is stored as a hex string (`colorHex`); `Color(hex:)` and `.hexString` in
  `Color+Hex.swift` are the only conversion points.

## Verification expectations

CloudKit logs `CKAccountStatusNoAccount` on a simulator that isn't signed into iCloud. That is
expected and handled — the app keeps working locally and Settings shows "iCloud Unavailable".
A `BUG IN CLIENT OF CLOUDKIT ... remote-notification` message means the background mode has been
lost from the built Info.plist.
