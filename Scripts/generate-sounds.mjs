#!/usr/bin/env node
// Generates the bundled timer sound pack with the ElevenLabs sound-effects API.
// Development-time only — the shipping app never talks to the network for sounds.
//
//   ELEVENLABS_API_KEY=... node Scripts/generate-sounds.mjs
//
// Output lands in GameToolkit/Resources/Sounds/*.caf (CAF/IMA4 mono, via afconvert).
// CAF/IMA4 is mandatory, not cosmetic: UNNotificationSound silently falls back to the
// default tone for AAC files, while CAF plays everywhere the timer needs it —
// AVAudioPlayer, local notifications, and AlarmKit. Idempotent: existing .caf files are
// skipped, so re-runs don't burn API credits; delete a file to regenerate it.
//
// Node 20+, no dependencies (matches server/ convention). Requires macOS (afconvert).

import { mkdirSync, existsSync, writeFileSync, rmSync } from "node:fs";
import { execFileSync } from "node:child_process";
import path from "node:path";
import { fileURLToPath } from "node:url";

const KEY = process.env.ELEVENLABS_API_KEY;
if (!KEY) {
  console.error("Set ELEVENLABS_API_KEY to generate sounds. Nothing was changed.");
  process.exit(1);
}

// One distinct character per sound; ids must match TimerSound's raw values.
const SOUNDS = [
  { id: "chime",   duration: 2.5, prompt: "A single warm two-note wind chime, clean decay, no background noise" },
  { id: "gong",    duration: 3.0, prompt: "A soft mallet strike on a small brass gong, gentle sustained ring, no background noise" },
  { id: "buzzer",  duration: 2.0, prompt: "A short friendly game-show buzzer, rounded tone, not harsh, no background noise" },
  { id: "bell",    duration: 2.0, prompt: "A bright hotel desk bell ding, single strike with natural ring-out, no background noise" },
  { id: "chirp",   duration: 2.0, prompt: "Two quick cheerful electronic chirps, like a songbird made of sine waves, no background noise" },
  { id: "drum",    duration: 2.0, prompt: "A quick tight double hit on a wooden hand drum, dry room, no background noise" },
  { id: "whistle", duration: 2.0, prompt: "A short ascending referee slide whistle, playful, no background noise" },
  { id: "klaxon",  duration: 2.5, prompt: "A brief melodic two-tone alert horn, pleasant and rounded, retro arcade feel, no background noise" },
];

const root = path.resolve(path.dirname(fileURLToPath(import.meta.url)), "..");
const outDir = path.join(root, "GameToolkit", "Resources", "Sounds");
const tmpDir = path.join(root, ".tmp-sounds");
mkdirSync(outDir, { recursive: true });
mkdirSync(tmpDir, { recursive: true });

let generated = 0;
for (const sound of SOUNDS) {
  const cafPath = path.join(outDir, `${sound.id}.caf`);
  if (existsSync(cafPath)) {
    console.log(`✓ ${sound.id}.caf exists — skipping`);
    continue;
  }

  console.log(`… generating ${sound.id}`);
  const response = await fetch(
    "https://api.elevenlabs.io/v1/sound-generation?output_format=mp3_44100_128",
    {
      method: "POST",
      headers: { "xi-api-key": KEY, "content-type": "application/json" },
      body: JSON.stringify({
        text: sound.prompt,
        duration_seconds: sound.duration,
        prompt_influence: 0.4,
      }),
    },
  );
  if (!response.ok) {
    console.error(`✗ ${sound.id}: HTTP ${response.status} — ${await response.text()}`);
    process.exitCode = 1;
    continue;
  }

  const mp3Path = path.join(tmpDir, `${sound.id}.mp3`);
  writeFileSync(mp3Path, Buffer.from(await response.arrayBuffer()));

  // CAF container, IMA4 @ 44.1 kHz, mono — ~30 KB per sound.
  execFileSync("afconvert", ["-f", "caff", "-d", "ima4@44100", "-c", "1", mp3Path, cafPath]);
  console.log(`✓ ${sound.id}.caf`);
  generated += 1;
}

rmSync(tmpDir, { recursive: true, force: true });
console.log(generated > 0
  ? `Done: ${generated} new sound(s). They're bundled automatically on the next build.`
  : "Done: nothing to generate.");
