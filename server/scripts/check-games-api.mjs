#!/usr/bin/env node
// Offline self-check for /api/v1/games: curated matching, BGG XML parsing, dedup, and
// graceful degradation when BGG is down. Stubs fetch — no network, safe for CI.
import assert from "node:assert/strict";
import handler from "../api/v1/games.js";

async function run(q) {
  const out = { headers: {}, body: null, code: null };
  await handler(
    { query: { q } },
    {
      setHeader: (k, v) => (out.headers[k] = v),
      status: (c) => ({ json: (b) => ((out.code = c), (out.body = b)) }),
    }
  );
  return out;
}

// 1. No BGG token → no upstream call at all, curated results answer.
delete process.env.BGG_API_TOKEN;
globalThis.fetch = async () => { throw new Error("must not be called without a token"); };
let out = await run("catan");
assert.equal(out.code, 200);
assert.equal(out.body.results[0].slug, "catan");
assert.equal(out.body.results[0].source, "curated");
assert.equal(out.body.results[0].secondsPerTurn, 90);

// 1b. Token set but BGG down → curated results still answer.
process.env.BGG_API_TOKEN = "test-token";
out = await run("catan");
assert.equal(out.code, 200);
assert.equal(out.body.results[0].source, "curated");

// 2. Empty query → the whole curated repository.
out = await run("");
assert.ok(out.body.count >= 8);
assert.ok(out.body.results.every((g) => g.source === "curated"));

// 3. BGG results parse, curated bggIds dedup, entities decode.
const searchXML = `<items>
  <item type="boardgame" id="13"><name type="primary" value="CATAN"/></item>
  <item type="boardgame" id="2536"><name type="primary" value="Vabanque"/></item>
</items>`;
const thingXML = `<items>
  <item type="boardgame" id="2536">
    <name type="primary" sortindex="1" value="Vabanque &amp; Co&#039;s"/>
    <minplayers value="3"/><maxplayers value="6"/><playingtime value="45"/>
  </item>
  <item type="boardgame" id="13"><name type="primary" value="CATAN"/></item>
</items>`;
let sentAuth = null;
globalThis.fetch = async (url, options) => {
  sentAuth = options.headers.authorization;
  return {
    ok: true,
    text: async () => (String(url).includes("/search") ? searchXML : thingXML),
  };
};
out = await run("catan");
assert.equal(sentAuth, "Bearer test-token");
const bgg = out.body.results.filter((g) => g.source === "bgg");
assert.equal(bgg.length, 1, "curated bggId 13 must be deduped");
assert.equal(bgg[0].name, "Vabanque & Co's");
assert.equal(bgg[0].slug, "vabanque-co-s");
assert.deepEqual(bgg[0].players, { min: 3, max: 6 });
assert.equal(bgg[0].playtimeMinutes, 45);

console.log("✓ games API self-check passed");
