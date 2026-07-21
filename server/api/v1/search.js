// GET /api/v1/search?q=wingspan — fuzzy search over game names, aliases, theme names, tags.
//
// Privacy contract: the query is used only to compute this response. It is never logged,
// stored, or forwarded — no console output, no analytics, no third parties. (The Game
// Toolkit app searches on-device and doesn't even call this endpoint; it exists for
// other clients and future datasets too large to sync.)
import { readdirSync, readFileSync } from "node:fs";
import { join } from "node:path";

let cachedThemes = null;
function themes() {
  if (!cachedThemes) {
    const dir = join(process.cwd(), "data", "themes");
    cachedThemes = readdirSync(dir)
      .filter((f) => f.endsWith(".json"))
      .sort()
      .map((f) => JSON.parse(readFileSync(join(dir, f), "utf8")));
  }
  return cachedThemes;
}

const normalize = (s) =>
  s.normalize("NFD").replace(/[\u0300-\u036f]/g, "").toLowerCase().trim();

function score(theme, needle) {
  const candidates = [[theme.name, 60]];
  if (theme.game) {
    candidates.push([theme.game.name, 100], [theme.game.slug, 90]);
    for (const alias of theme.game.aliases ?? []) candidates.push([alias, 80]);
  }
  for (const tag of theme.tags ?? []) candidates.push([tag, 40]);

  let best = null;
  for (const [text, weight] of candidates) {
    const haystack = normalize(text);
    let s = null;
    if (haystack === needle) s = weight + 30;
    else if (haystack.startsWith(needle)) s = weight + 15;
    else if (haystack.includes(needle)) s = weight;
    if (s !== null) best = Math.max(best ?? -Infinity, s);
  }
  return best;
}

export default function handler(req, res) {
  const query = normalize(String(req.query.q ?? "")).slice(0, 100);

  let results;
  if (query.length === 0) {
    results = themes();
  } else {
    results = themes()
      .map((t) => [t, score(t, query)])
      .filter(([, s]) => s !== null)
      .sort((a, b) => b[1] - a[1])
      .map(([t]) => t);
  }

  res.setHeader("Cache-Control", "public, s-maxage=3600, stale-while-revalidate=86400");
  res.setHeader("Access-Control-Allow-Origin", "*");
  res.status(200).json({ count: results.length, results });
}
