# App Store submission guide

Everything needed to fill out App Store Connect for Game Toolkit 2.0, field by field.
Where a value is a judgment call, the reasoning is noted so you can adjust it.

## App information

| Field | Value |
| --- | --- |
| Name | `Game Toolkit` |
| Subtitle (30 chars) | `Dice, timer & scorecard` |
| Bundle ID | `com.nathanfennel.Game-Toolkit` |
| SKU | `game-toolkit-2` (any unique string) |
| Primary language | English (U.S.) |
| Primary category | Utilities |
| Secondary category | Entertainment |
| Price | Free |
| In-app purchases | None |
| Marketing URL | `https://nathanfennel.com/game-toolkit` |
| Support URL | `https://nathanfennel.com/game-toolkit/support` |
| Privacy policy URL | `https://nathanfennel.com/game-toolkit/privacy` |
| Copyright | `© 2026 Nathan Fennel` |

Category note: Game Toolkit is a companion utility, not a game, so it does not belong in
the Games category. Utilities + Entertainment matches how similar scorekeeping apps are
listed.

## Promotional text (170 chars max)

> Real 3D dice, ten clock faces, and a scorecard that syncs across your devices — with
> themes inspired by tonight's game and a live scoreboard on your Apple TV.

(158 characters.)

## Description

> Game Toolkit is the companion for game night: dice, a chess-clock turn timer, and a
> proper scorecard, in one app that looks like it belongs on the table.
>
> DICE THAT FEEL LIKE DICE
> Real 3D dice — cubes, d4s, d8s, d10s, d12s, d20s — that tumble when you roll and
> lean as you tilt your phone. Roll 1 to 30 dice with 2 to 100 sides on a green-felt
> tray. Tap a die to hold it out of the next roll, Yahtzee-style, then shake to roll
> the rest. Build custom dice bags in the Dice Designer and keep them in named boxes.
>
> A CHESS CLOCK FOR TURNS
> Everyone gets a bank of time. Tap a player to start their clock and pause everyone
> else's; an alarm sounds when time runs out. Ten clock faces — classic digits,
> analog, hourglass, water clock, sundial, and more. The timer measures real elapsed
> time, so it never drifts.
>
> A SCORECARD WORTH STARING AT
> Round-by-round scores with running totals and a crown on the leader. Charts show the
> whole table's race or one player's ups and downs. Shake to shuffle turn order.
>
> GAME NIGHTS THAT REMEMBER
> Set up a table for each group you play with — Friday Catan, the family, the office
> crew. Each game night keeps its own roster, avatars, and score history.
>
> A SCOREBOARD ON YOUR TV
> Mirror to an Apple TV and the big screen becomes a live scoreboard — totals,
> last-round points, and the crown — while your phone stays the controller.
>
> THEMED TO TONIGHT'S GAME
> Seven built-in looks, each in light and dark, all contrast-checked — plus color
> palettes inspired by the board game you're playing. Search your game and the whole
> app dresses to match. Themes are purely cosmetic and every feature works offline.
>
> SYNCED, PRIVATE, YOURS
> Players and scores sync between your iPhone, iPad, and Mac through your private
> iCloud database. No account, no ads, no analytics, nothing collected.
>
> Game Toolkit is not affiliated with or endorsed by any board-game publisher. Game
> names appear only so search can find the right palette.

## Keywords (100 chars max)

```
dice,board game,score,scorekeeper,turn timer,chess clock,game night,tabletop,d20,scoreboard,scorepad
```

(100 characters exactly — counted with commas, no spaces.)

## Screenshots

Each device class has 20 marketing candidates in `Screenshots/marketing/` — 13 single-shot
(named after their raw source) and 7 multi-shot fan/pair layouts (`m1`–`m7`). App Store
Connect accepts up to 10 per device class; pick your favorites. Raw undecorated UI shots
live in `Screenshots/<device>/` if you prefer them (Mac listings often favor plain UI).

| Device class | Size | Files |
| --- | --- | --- |
| iPhone 6.9" | 1320×2868 | `Screenshots/marketing/iphone-6.9/*.png` (20 candidates) |
| iPad 13" | 2064×2752 | `Screenshots/marketing/ipad-13/*.png` (20 candidates) |
| Mac | 2560×1600 | `Screenshots/marketing/mac/*.png` (20 candidates) or `Screenshots/mac/*.png` (raw) |
| Apple Vision Pro | — | None needed: Designed-for-iPad apps reuse the iPad screenshots |

Suggested 10, in order: `m1-hero`, `1-dice`, `2-timer`, `3-scores`, `8-players`,
`m2-themes`, `9-timer-hourglass`, `4-chart`, `6-theme-gaslight`, `m4-score-story`.

Regenerate any time with `./Scripts/screenshots.sh` then `python3 Scripts/marketing.py`.

## Age rating

Answer **None / No** to every content question (violence, gambling, etc.) → **4+**.
The dice are game accessories, not gambling: there is no wagering, currency, or payout.
Answer "No" to unrestricted web access and gambling/contests.

## App Privacy (nutrition label)

Declare **Data Not Collected**.

Reasoning, if App Review asks:

- **Players and scores** are stored on-device and mirrored to the user's *private*
  CloudKit database via SwiftData. Apple's definition of "collected" is data
  transmitted off-device that the developer can access; the private database is
  accessible only to the user's Apple Account, not to the developer.
- **Theme search queries** are sent over HTTPS to the theme service without any
  identifier (no account, no device ID, no advertising ID) and are used only to
  service the request, then discarded — which meets Apple's exclusion for data
  "retained only for the period necessary to service the request." Nothing is logged
  by our code; only routine, short-lived infrastructure logs exist at the host.
- There are no third-party SDKs, no analytics, and no ads.

`PrivacyInfo.xcprivacy` in the app bundle already declares: no tracking, no tracking
domains, no collected data types, and the UserDefaults required-reason API
(CA92.1). Keep it in sync if network behavior ever changes.

## Export compliance

`ITSAppUsesNonExemptEncryption = NO` is set in `Config/Info.plist`, so App Store
Connect will not ask the encryption question on upload. The app uses only standard
ATS/HTTPS encryption, which is exempt.

## Content rights

Answer: the app does not contain, show, or access third-party content. Board-game
*names* appear solely as search terms to find independently-authored color palettes
with descriptive names ("Feathered Meadow", not "Wingspan Theme") — nominative use,
with an affiliation disclaimer shown in the app, on the marketing page, and in this
listing's description. No logos, artwork, or other assets from any publisher are
included, and the server's validator rejects any theme whose display name contains
the game's title.

## Capabilities checklist (before archiving)

Both need your Apple Developer account in Xcode ▸ Signing & Capabilities:

1. **iCloud** ▸ CloudKit, container `iCloud.com.nathanfennel.Game-Toolkit`.
2. **Push Notifications** — CloudKit uses silent pushes; the `remote-notification`
   background mode is already in `Config/Info.plist`.

Then: Product ▸ Archive (iOS), and again with the Mac Catalyst destination for the
Mac App Store. Version 2.0, and bump the build number for each upload.

## App Review notes (paste into the Review Notes field)

> No account or sign-in exists; all features are available immediately. iCloud is
> optional — the app is fully functional signed out. The optional game-theme search
> talks to https://game-toolkit-themes.vercel.app/api/v1/ anonymously; if it is
> unreachable the app silently uses its built-in themes. The TV scoreboard feature
> requires AirPlay screen mirroring or an HDMI-connected display: while mirroring,
> the external screen shows a live scoreboard instead of the mirrored phone UI
> (Settings ▸ Apple TV & External Screens toggles this).

## Theme service (already live)

- Production: `https://game-toolkit-themes.vercel.app/api/v1/` (project
  `game-toolkit-themes`, root directory `server/`).
- Deploy updates: `cd server && npx vercel deploy --prod --yes`.
- Add a theme: drop `server/data/themes/<slug>.json` matching the schema, run
  `node scripts/validate.mjs`, deploy. The client needs no update to pick up new
  themes.
