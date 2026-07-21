#!/usr/bin/env node
// Emits the static API surface into public/ from data/themes/. Everything the client
// reads is a plain CDN-cached file; only /api/v1/search is a function.
import { execFileSync } from "node:child_process";
import { mkdirSync, readdirSync, readFileSync, writeFileSync } from "node:fs";
import { join, dirname } from "node:path";
import { fileURLToPath } from "node:url";

const root = join(dirname(fileURLToPath(import.meta.url)), "..");

// Never ship an invalid dataset.
execFileSync(process.execPath, [join(root, "scripts", "validate.mjs")], { stdio: "inherit" });

const themesDir = join(root, "data", "themes");
const outDir = join(root, "public", "api", "v1");
mkdirSync(join(outDir, "themes"), { recursive: true });

const themes = readdirSync(themesDir)
  .filter((f) => f.endsWith(".json"))
  .sort()
  .map((f) => JSON.parse(readFileSync(join(themesDir, f), "utf8")));

// Full theme documents, one per id.
for (const theme of themes) {
  writeFileSync(join(outDir, "themes", `${theme.id}.json`), JSON.stringify(theme) + "\n");
}

// The complete list the app syncs.
writeFileSync(join(outDir, "themes.json"), JSON.stringify(themes) + "\n");

// Lightweight manifest: identity plus a three-color preview per variant.
const index = {
  schemaVersion: 1,
  generatedAt: new Date().toISOString(),
  themes: themes.map((t) => ({
    id: t.id,
    name: t.name,
    game: t.game ?? null,
    tags: t.tags ?? [],
    updatedAt: t.updatedAt ?? null,
    preview: {
      light: [t.light.accent, t.light.table, t.light.background],
      dark: [t.dark.accent, t.dark.table, t.dark.background],
    },
  })),
};
writeFileSync(join(outDir, "index.json"), JSON.stringify(index) + "\n");

console.log(`✓ built API for ${themes.length} theme(s) into public/api/v1/`);
