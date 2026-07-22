# Claude Cowork prompt — App Store Connect setup

Copy everything below the rule into a Claude Cowork session that has browser access and
is signed in to App Store Connect (appstoreconnect.apple.com) as the account owner.
Have the `Screenshots/marketing/` folder and `Docs/AppStore.md` from this repo available
to the session (drag the folder in, or give it the repo).

---

Set up the App Store Connect listing for my app **Game Toolkit**. Everything you need
is in the attached `AppStore.md` (field-by-field values) and the `marketing/` folder
(final screenshots). Work through App Store Connect in the browser; I am already signed
in. Ask me before anything irreversible (submitting for review, answering the content
rights declaration, or anything involving agreements or banking).

1. **Create the app record** (My Apps ▸ + ▸ New App) if it doesn't exist:
   - Platforms: iOS and macOS
   - Name: `Game Toolkit`
   - Primary language: English (U.S.)
   - Bundle ID: `com.nathanfennel.Game-Toolkit`
   - SKU: `game-toolkit-2`
   - Full access.
   If the name is taken, tell me the exact error and suggest 3 alternatives; do not pick
   one yourself.

2. **App Information**: subtitle `Dice, timer & scorecard`, category Utilities
   (secondary Entertainment), content rights answer per the "Content rights" section of
   AppStore.md. Age rating: answer every questionnaire item None/No → 4+.

3. **Pricing**: Free, all territories, no in-app purchases.

4. **App Privacy**: privacy policy URL `https://nathanfennel.com/game-toolkit/privacy`,
   then declare **Data Not Collected**. The reasoning is in AppStore.md if a
   confirmation dialog asks.

5. **Version 2.0 page (iOS)**:
   - Promotional text, description, keywords, support URL, marketing URL, copyright —
     all verbatim from AppStore.md.
   - Screenshots: upload the 10 files listed under "Suggested 10" in AppStore.md from
     `marketing/iphone-6.9/` (6.9" slot) and `marketing/ipad-13/` (13" slot), same
     order. Leave other size slots to auto-scale.
   - Review notes: paste the "App Review notes" block from AppStore.md. No sign-in
     required; leave the demo-account fields empty.

6. **Version 2.0 page (macOS)**: same metadata; screenshots from `marketing/mac/`
   (same 10 picks where available).

7. **Do not submit for review.** Stop when both version pages save cleanly with a
   green "Prepare for Submission" state, then give me a checklist of what remains
   (build upload from Xcode, export compliance is pre-declared via
   ITSAppUsesNonExemptEncryption, final submit button).

Report anything App Store Connect rejects (character limits, image sizes) rather than
improvising replacement copy — the copy limits were pre-checked, so a rejection means
something changed and I want to know.
