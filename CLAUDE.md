# Game Toolkit — working notes

SwiftUI board-game companion (dice roller, chess-clock turn timer, scorecard) backed by
SwiftData + CloudKit. iOS 17+, Mac Catalyst, Designed-for-iPad on visionOS. Xcode 26, Swift 5
language mode.

## Commands

```sh
# Build / test (iOS)
xcodebuild -project "Game Toolkit.xcodeproj" -scheme "Game Toolkit" \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro Max' build
xcodebuild -project "Game Toolkit.xcodeproj" -scheme "Game Toolkit" \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro Max' test

# Mac Catalyst
xcodebuild -project "Game Toolkit.xcodeproj" -scheme "Game Toolkit" \
  -destination 'platform=macOS,variant=Mac Catalyst' build

# Screenshots (iPhone + iPad + Mac)
./Scripts/screenshots.sh
```

For simulator installs append `CODE_SIGN_IDENTITY="-" CODE_SIGNING_REQUIRED=NO` — do **not** use
`CODE_SIGNING_ALLOWED=NO`, which produces an unsigned bundle whose sandbox container can't be
created, so the SwiftData store fails with `file-write-create denied` and the app silently falls
back to in-memory.

Mac Catalyst is the opposite: the shipping entitlements include App Sandbox, which ad-hoc signing
**cannot** carry, so local runs need `CODE_SIGNING_ALLOWED=NO` followed by
`codesign --force --deep --sign -`. `Scripts/screenshot-mac.sh` already does this.

The tab bar honours launch arguments, which is what the screenshot script drives:
`-ui.selectedTab 0..4` (Dice/Timer/Scores/Players/Settings), `-showChart`, and `-screenshotMode`
(DEBUG-only demo roster, see `ScreenshotSupport.swift`).

## Conventions and gotchas

- **Adding files needs no project edits.** The target uses a `PBXFileSystemSynchronizedRootGroup`
  (objectVersion 77), so anything under `GameToolkit/` or `GameToolkitTests/` is compiled
  automatically. Only touch `project.pbxproj` for targets or build settings.
- **Keep the schema CloudKit-compatible.** Every stored property on a `@Model` needs a default
  value (or must be optional), relationships must be optional with inverses, and unique
  constraints are not allowed. Breaking this makes `ModelContainer` init throw, which silently
  drops the app into the in-memory fallback in `GameToolkitApp`.
- **`INFOPLIST_KEY_*` only supports an Xcode allowlist.** `UIBackgroundModes` is not on it and is
  silently ignored — hence `Config/Info.plist` as a merge base alongside
  `GENERATE_INFOPLIST_FILE = YES`. Verify plist changes land in the built bundle.
- **`Swift.max` inside numeric extensions.** In an `extension Int`, bare `max` resolves to the
  static `Int.max` property, not the global function. See `Theme.swift`.
- **Platform guards.** Feedback generators and shake detection are iOS-only; `Haptics` and
  `onShake` compile to no-ops elsewhere. Anything reachable only by shaking must also have a
  button or menu item, since Mac and Vision Pro cannot shake.
- **Timer correctness.** `TimerEngine` derives remaining time from `Date` deltas rather than
  counting ticks, so a delayed timer never causes drift. Keep that property.
- Player color is stored as a hex string (`colorHex`); `Color(hex:)` and `.hexString` in
  `Color+Hex.swift` are the only conversion points.
- Tests share the main actor. Don't assert on async engine state after a fixed `Task.sleep` —
  poll instead (see `DiceEngineTests.lockedDiceKeepValues`).

## Environment quirks on this machine

- Simulators shut down spontaneously, and other processes boot their own (`cc-shot-*`,
  `CardOnCue-*`). Never run `simctl shutdown all`; target devices by UDID and re-check the booted
  state between steps.
- The visionOS simulator runtime downloads but never mounts (`simctl runtime list` shows it Ready
  while `mount` does not), so `actool` fails with "Failed to find device type for IBVisionIdiom"
  and native visionOS cannot be built here. Mounting needs elevated privileges — finish via
  Xcode ▸ Settings ▸ Components. This is why Vision Pro ships as Designed-for-iPad.
- CloudKit logs `CKAccountStatusNoAccount` on a simulator without an iCloud account. Expected and
  handled. A `BUG IN CLIENT OF CLOUDKIT ... remote-notification` message means the background
  mode has been lost from the built Info.plist.
