# Game Toolkit — working notes

SwiftUI board-game companion (dice roller, chess-clock turn timer, scorecard) backed by
SwiftData + CloudKit. iOS 17+, Mac Catalyst, Designed-for-iPad on visionOS. Xcode 26, Swift 5
language mode. `server/` holds the Vercel theme repository (plain Node, no dependencies).

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
`-ui.selectedTab 0..4` (Dice/Timer/Scores/Players/Settings), `-showChart`, `-ui.theme <id>`
(forces a theme, e.g. `hearth`, `gaslight`, or a bundled game theme like `azul`),
`-ui.onboardingStep 0..2` (DEBUG, jumps into the onboarding tour), and `-screenshotMode`
(DEBUG-only demo roster, see `ScreenshotSupport.swift`).

```sh
# Theme server (Node 20+; on this machine node lives at /opt/homebrew/bin, npm has no symlink)
cd server && node scripts/validate.mjs   # schema + WCAG contrast for data/themes/*.json
cd server && node scripts/build.mjs      # emits public/api/v1/** (validates first)
# Deploy: npx vercel --prod   (needs the user's Vercel login; root dir = server)
```

## Theming

- Views read semantic roles from `@Environment(\.palette)` (a `ThemePalette`), injected by
  `RootView` from `ThemeManager.shared` + the effective color scheme. **Never hard-code a
  color in a feature view** — add a role only if truly necessary (schema change ripples to
  the server and tests).
- Built-in palettes are gated by `ThemeContrastTests`: WCAG AA (4.5:1) for text roles, 3:1
  for semantic colors, pairwise ΔE thresholds for player colors under normal vision and
  simulated protanopia/deuteranopia. If a new palette fails, tune it — don't loosen the
  test. The player palettes were produced by a hill-climbing optimizer; reuse an existing
  validated `players` array when authoring new themes unless you re-verify.
- `Player.paletteIndex` (optional, CloudKit-safe) maps players onto the theme palette;
  `colorHex` is both the custom-color storage *and* a compatibility snapshot for older app
  versions sharing the CloudKit store. Resolve display colors via `player.color(in: palette)`.
- Theme JSON is forward-compatible: unknown fields are ignored, `schemaVersion` is checked
  (`isSupported`), required color missing ⇒ decode throws ⇒ theme skipped. The same schema
  is validated server-side by `server/scripts/validate.mjs` (which also rejects theme names
  containing the game's title — trademark hygiene).
- `GameThemeService` must stay offline-first: bundled JSON → cache → optional network, all
  failures silent, and search stays on-device (privacy: queries never leave the phone).
- The serif display face comes from `Font.display(...)` and a `UINavigationBar` appearance
  set once in `GameToolkitApp` — don't set per-view title fonts.

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
- **External-display scoreboard** (`App/ExternalDisplay.swift`, iOS only): AirPlay/HDMI
  screens get a scoreboard window instead of mirroring. This requires
  `UIApplicationSupportsMultipleScenes` in `Config/Info.plist` (which also makes the app
  multi-windowable on iPad — intended). The window is created/destroyed to follow the
  `settings.externalScoreboard` toggle; with no window attached the system mirrors.
  `-ui.externalPreview` (DEBUG) renders the scoreboard in-app since simulators can't
  attach external displays; real AirPlay behavior needs hardware.
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
