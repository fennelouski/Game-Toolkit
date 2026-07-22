// GET /api/v1/games?q=wingspan — the games repository: curated games (with the settings
// the app uses: player counts, playtime, suggested seconds per turn, theme link) merged
// with live results from the BoardGameGeek XML API for anything we haven't curated.
//
// Caching contract: responses carry the site-wide Cache-Control from vercel.json
// (s-maxage + stale-while-revalidate), so Vercel's edge caches each distinct query and
// BGG sees at most one upstream call per query per cache window. No database needed.
//
// Privacy contract: the query is used only to compute this response — never logged or
// stored. The only third party contacted is BGG, and only with the query text itself.
//
// BGG requires registered API access (since late 2025): set BGG_API_TOKEN in the Vercel
// project env (register at https://boardgamegeek.com/using_the_xml_api). Without a token
// the endpoint quietly serves the curated repository only.
import { readFileSync } from "node:fs";
import { join } from "node:path";

const BGG = "https://boardgamegeek.com/xmlapi2";
const UPSTREAM_TIMEOUT_MS = 5000;
const MAX_BGG_RESULTS = 10;

let cachedGames = null;
function curated() {
  if (!cachedGames) {
    cachedGames = JSON.parse(
      readFileSync(join(process.cwd(), "data", "games.json"), "utf8")
    );
  }
  return cachedGames;
}

const normalize = (s) =>
  s.normalize("NFD").replace(/[\u0300-\u036f]/g, "").toLowerCase().trim();

const slugify = (s) =>
  normalize(s).replace(/[^a-z0-9]+/g, "-").replace(/^-|-$/g, "");

function matchesCurated(game, needle) {
  return [game.name, game.slug, ...(game.aliases ?? [])].some((text) => {
    const haystack = normalize(text);
    return haystack.includes(needle) || needle.includes(haystack);
  });
}

// --- Minimal BGG XML extraction (the responses are flat; no XML dependency needed) ---

const decodeEntities = (s) =>
  s
    .replace(/&#(\d+);/g, (_, n) => String.fromCharCode(Number(n)))
    .replace(/&quot;/g, '"')
    .replace(/&apos;/g, "'")
    .replace(/&amp;/g, "&");

const itemBlocks = (xml) =>
  [...xml.matchAll(/<item[^>]*\bid="(\d+)"[^>]*>([\s\S]*?)<\/item>/g)].map(
    (m) => [Number(m[1]), m[2]]
  );

const attrValue = (block, tag) =>
  new RegExp(`<${tag}[^>]*\\bvalue="([^"]*)"`).exec(block)?.[1];

const primaryName = (block) =>
  /<name[^>]*type="primary"[^>]*\bvalue="([^"]*)"/.exec(block)?.[1];

async function fetchXML(url) {
  const response = await fetch(url, {
    signal: AbortSignal.timeout(UPSTREAM_TIMEOUT_MS),
    headers: {
      accept: "application/xml",
      authorization: `Bearer ${process.env.BGG_API_TOKEN}`,
    },
  });
  if (!response.ok) throw new Error(`upstream ${response.status}`);
  return response.text();
}

/// Two upstream calls: search for ids, then one batched thing lookup for details.
async function bggGames(query) {
  const searchXML = await fetchXML(
    `${BGG}/search?type=boardgame&query=${encodeURIComponent(query)}`
  );
  const ids = itemBlocks(searchXML).map(([id]) => id).slice(0, MAX_BGG_RESULTS);
  if (ids.length === 0) return [];

  const thingXML = await fetchXML(`${BGG}/thing?id=${ids.join(",")}`);
  const byId = new Map(itemBlocks(thingXML));
  return ids.flatMap((id) => {
    const block = byId.get(id);
    const name = block && primaryName(block);
    if (!name) return [];
    const decoded = decodeEntities(name);
    const int = (tag) => {
      const n = Number(attrValue(block, tag));
      return Number.isInteger(n) && n > 0 ? n : null;
    };
    return [{
      slug: slugify(decoded),
      name: decoded,
      aliases: [],
      bggId: id,
      players: { min: int("minplayers"), max: int("maxplayers") },
      playtimeMinutes: int("playingtime"),
      secondsPerTurn: null,
      themeId: null,
      source: "bgg",
    }];
  });
}

export default async function handler(req, res) {
  const query = normalize(String(req.query.q ?? "")).slice(0, 100);

  const curatedResults = (query
    ? curated().filter((g) => matchesCurated(g, query))
    : curated()
  ).map((g) => ({ ...g, source: "curated" }));

  let remote = [];
  if (query && process.env.BGG_API_TOKEN) {
    try {
      const knownIds = new Set(curatedResults.map((g) => g.bggId));
      remote = (await bggGames(query)).filter((g) => !knownIds.has(g.bggId));
    } catch {
      // BGG down or slow: curated results still answer, and the edge caches recover.
    }
  }

  const results = [...curatedResults, ...remote];
  res.setHeader("Access-Control-Allow-Origin", "*");
  res.status(200).json({ count: results.length, results });
}
