# Game Toolkit Themes — server

The theme repository behind Game Toolkit's "match a board game" feature: a git-backed set of
static JSON documents served from Vercel's CDN. Themes are content, not user data — there is
no database, no accounts, and no analytics.

## API

```
GET /api/v1/index.json          lightweight manifest (id, name, game, tags, previews)
GET /api/v1/themes.json         every full theme document (what the app syncs)
GET /api/v1/themes/:id          one full theme document
GET /api/v1/search?q=wingspan   fuzzy search over names, aliases, and tags
GET /api/v1/games.json          the curated games repository (settings the app uses)
GET /api/v1/games?q=catan       curated games merged with live BoardGameGeek results
```

`/games` layers BoardGameGeek's XML API under our own schema: curated entries win, unknown
games come from BGG (top 10, two upstream calls), and Vercel's edge cache means BGG sees at
most one request per distinct query per cache window — that cache *is* the third-party
caching layer, no database involved. BGG requires registered API access: set `BGG_API_TOKEN`
in the Vercel project env (register at boardgamegeek.com/using_the_xml_api). Without the
token the endpoint serves curated data only. Curated games live in `data/games.json`
(validated by `npm run validate`; `scripts/check-games-api.mjs` self-checks the function
offline in `npm test`).

Everything except `/search` is a static file — CDN-cached with automatic `ETag`s, so clients
revalidate with `If-None-Match` for free. `/search` exists for other clients and for a future
where the dataset outgrows syncing; the iOS app searches **on-device** over the synced list,
so user queries never leave the phone. The search function never logs, stores, or forwards
queries.

## Layout

```
data/themes/*.json    one file per theme — the source of truth, reviewable in PRs
scripts/validate.mjs  schema + WCAG contrast validation (runs in CI and before build)
scripts/build.mjs     emits public/api/v1/** from data/
api/v1/search.js      the only serverless function
public/index.html     landing page and API docs
```

No dependencies. `npm run build` needs only Node 18+.

## Adding a theme

1. Copy an existing file in `data/themes/` to `<slug>.json` (the filename must match `id`).
2. Fill in both `light` and `dark` palettes. Every color role is required; `players` needs at
   least 10 mutually distinguishable colors (borrow a validated set from an existing theme
   unless you have a good reason not to).
3. Name it **descriptively** — "Feathered Meadow", not "Wingspan Theme". The validator rejects
   theme names containing the game's title or claiming to be official. The game's name lives
   only in the `game` association, for search.
4. `npm run validate` — fix anything it reports (it enforces WCAG AA text contrast, legible
   dice, and schema shape).
5. Open a PR. CI runs the same validation; merging to `master` redeploys automatically once
   the Vercel project is connected to the repo.

## Deploying

First time, from `server/`:

```sh
npx vercel --prod    # project name: game-toolkit-themes
```

or connect the repo in the Vercel dashboard with **Root Directory = `server`**. The app
expects the production URL `https://game-toolkit-themes.vercel.app` (see
`GameThemeService.remoteIndexURL`); update that constant if the deployment lives elsewhere.

## Trademarks

Themes are fan-made color schemes *inspired by* each game's look. No artwork, logos, fonts,
or other protected assets are hosted, and nothing here implies affiliation or endorsement.
If a publisher objects to an association, remove the theme's `game` block (or the theme) and
ship the change.
