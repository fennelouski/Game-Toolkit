#!/usr/bin/env node
// Validates every theme document in data/themes/ against the schema and the same
// contrast rules the app enforces for its built-in themes. Run in CI and before
// every build so a malformed or unreadable theme can never ship.
import { readdirSync, readFileSync } from "node:fs";
import { join, dirname } from "node:path";
import { fileURLToPath } from "node:url";

const themesDir = join(dirname(fileURLToPath(import.meta.url)), "..", "data", "themes");
const HEX = /^#[0-9A-Fa-f]{6}$/;
const COLOR_ROLES = [
  "background", "surface", "surfaceElevated", "table", "accent", "accentSecondary",
  "textPrimary", "textSecondary", "positive", "negative", "warning", "diceFace", "dicePip",
];
const SUPPORTED_SCHEMA_VERSION = 1;

const failures = [];
const fail = (file, message) => failures.push(`${file}: ${message}`);

// --- WCAG contrast math (mirrors ThemeTests.swift) ---
const linear = (c) => (c <= 0.03928 ? c / 12.92 : ((c + 0.055) / 1.055) ** 2.4);
const luminance = (hex) => {
  const n = parseInt(hex.slice(1), 16);
  const [r, g, b] = [(n >> 16) & 255, (n >> 8) & 255, n & 255].map((v) => linear(v / 255));
  return 0.2126 * r + 0.7152 * g + 0.0722 * b;
};
const contrast = (a, b) => {
  const [la, lb] = [luminance(a), luminance(b)];
  return (Math.max(la, lb) + 0.05) / (Math.min(la, lb) + 0.05);
};

function validatePalette(file, variant, p) {
  if (typeof p !== "object" || p === null) return fail(file, `${variant}: not an object`);
  for (const role of COLOR_ROLES) {
    if (!HEX.test(p[role] ?? "")) fail(file, `${variant}.${role}: expected #RRGGBB, got ${p[role]}`);
  }
  if (!Array.isArray(p.players) || p.players.length < 10) {
    fail(file, `${variant}.players: need at least 10 colors`);
  } else {
    for (const hex of p.players) {
      if (!HEX.test(hex)) fail(file, `${variant}.players: bad hex ${hex}`);
    }
  }
  if (failures.some((f) => f.startsWith(file))) return; // skip contrast on malformed docs

  for (const surface of [p.background, p.surface, p.surfaceElevated]) {
    for (const role of ["textPrimary", "textSecondary"]) {
      const ratio = contrast(p[role], surface);
      if (ratio < 4.5) fail(file, `${variant}: ${role} on ${surface} is ${ratio.toFixed(2)} (< 4.5 WCAG AA)`);
    }
    for (const role of ["positive", "negative", "warning", "accent"]) {
      const ratio = contrast(p[role], surface);
      if (ratio < 3.0) fail(file, `${variant}: ${role} on ${surface} is ${ratio.toFixed(2)} (< 3.0)`);
    }
  }
  if (contrast(p.dicePip, p.diceFace) < 4.5) fail(file, `${variant}: dice pips illegible on the die face`);
  if (contrast(p.diceFace, p.table) < 1.3) fail(file, `${variant}: dice fade into the table`);
}

function validateTheme(file, t) {
  if ((t.schemaVersion ?? 1) > SUPPORTED_SCHEMA_VERSION) {
    fail(file, `schemaVersion ${t.schemaVersion} is newer than this validator understands`);
  }
  if (!/^[a-z0-9-]+$/.test(t.id ?? "")) fail(file, `id must be a kebab-case slug, got ${t.id}`);
  if (file !== `${t.id}.json`) fail(file, `filename must match id (${t.id})`);
  if (!t.name || typeof t.name !== "string") fail(file, "missing name");
  // Trademark hygiene: the theme's own name must be descriptive, not the game's name,
  // and must never claim to be official.
  if (t.game) {
    if (!t.game.name || !t.game.slug) fail(file, "game association needs name and slug");
    if (t.name.toLowerCase().includes(t.game.name.toLowerCase())) {
      fail(file, `theme name "${t.name}" must not contain the game name — use a descriptive name`);
    }
  }
  if (/official|licensed|endorsed/i.test(t.name ?? "")) fail(file, "theme name must not imply endorsement");
  if (t.updatedAt && Number.isNaN(Date.parse(t.updatedAt))) fail(file, `bad updatedAt ${t.updatedAt}`);
  validatePalette(file, "light", t.light);
  validatePalette(file, "dark", t.dark);
}

const files = readdirSync(themesDir).filter((f) => f.endsWith(".json")).sort();
const ids = new Set();
for (const file of files) {
  let doc;
  try {
    doc = JSON.parse(readFileSync(join(themesDir, file), "utf8"));
  } catch (error) {
    fail(file, `invalid JSON: ${error.message}`);
    continue;
  }
  if (ids.has(doc.id)) fail(file, `duplicate id ${doc.id}`);
  ids.add(doc.id);
  validateTheme(file, doc);
}

if (failures.length > 0) {
  console.error(`✗ ${failures.length} problem(s):`);
  for (const f of failures) console.error("  " + f);
  process.exit(1);
}
console.log(`✓ ${files.length} theme(s) valid`);
