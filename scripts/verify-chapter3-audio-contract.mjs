import { createHash } from "node:crypto";
import { existsSync, readFileSync } from "node:fs";
import { dirname, join, resolve } from "node:path";
import { fileURLToPath } from "node:url";

const root = resolve(dirname(fileURLToPath(import.meta.url)), "..");
const audioRoot = join(root, "src/assets/audio");
const reportOnly = process.argv.includes("--report-only");

function readJson(path) {
  return JSON.parse(readFileSync(join(root, path), "utf8"));
}

function sha256(path) {
  return createHash("sha256").update(readFileSync(path)).digest("hex");
}

const sceneContracts = [
  {
    id: "canteen",
    content: readJson("src/data/chapter3-canteen.audio.content.json"),
    timeline: readJson("src/data/chapter3-canteen.audio.json"),
    assetPrefix: /^(music|fx)_canteen_/
  },
  {
    id: "theater",
    content: readJson("src/data/chapter3-theater.audio.content.json"),
    timeline: readJson("src/data/chapter3-theater.audio.json"),
    assetPrefix: /^(music|fx)_theater_/
  },
  {
    id: "qizhen",
    content: readJson("src/data/chapter3-qizhen.audio.content.json"),
    timeline: readJson("src/data/chapter3-qizhen.audio.json"),
    assetPrefix: /^(music|fx)_qizhen_/
  }
];
const story = readJson("src/data/chapter3-story-lines.json");
const storyTimeline = readJson("src/data/chapter3-story.audio.json");
const manifestPaths = [
  "src/data/chapter3-canteen.audio.generated.json",
  "src/data/chapter3-theater.audio.generated.json",
  "src/data/chapter3-qizhen.audio.generated.json",
  "src/data/chapter3-qizhen-sfx.audio.generated.json",
  "src/data/chapter3-story.audio.generated.json"
];

const expected = new Map();
const errors = [];
const addExpected = (asset, definition) => {
  if (expected.has(asset)) {
    errors.push(`duplicate asset definition: ${asset}`);
    return;
  }
  expected.set(asset, definition);
};

for (const contract of sceneContracts) {
  for (const kind of ["music", "sfx"]) {
    for (const definition of contract.content[kind] ?? []) {
      addExpected(definition.asset, {
        path: definition.path,
        kind,
        owner: contract.id
      });
    }
  }
  for (const event of Object.values(contract.timeline.events ?? {})) {
    for (const cue of event.cues ?? []) {
      if (!cue.asset) continue;
      if (!contract.assetPrefix.test(cue.asset)) {
        errors.push(`${contract.id} timeline borrows another scene asset: ${cue.asset}`);
      }
      if (!expected.has(cue.asset)) {
        errors.push(`${contract.id} timeline references undefined asset: ${cue.asset}`);
      }
    }
  }
}

const storyKeys = new Set();
const storySubtitles = new Set();
for (const line of story.lines ?? []) {
  if (storyKeys.has(line.key)) errors.push(`duplicate story key: ${line.key}`);
  if (storySubtitles.has(line.subtitleZh)) errors.push(`duplicate story subtitle: ${line.subtitleZh}`);
  storyKeys.add(line.key);
  storySubtitles.add(line.subtitleZh);
  const voice = story.voices?.[line.voiceRole];
  if (!voice || voice.language !== "English") {
    errors.push(`invalid English voice profile: ${line.key}`);
  }
  if (line.voiceRole === "male_narrator" && line.pitch !== voice?.basePitch) {
    errors.push(`Stanley narrator pitch drift: ${line.key}`);
  }
  addExpected(`vo_${line.key}`, {
    path: `chapter3/vo/vo_${line.key}.mp3`,
    kind: "voice",
    owner: line.voiceRole
  });
}

for (const event of Object.values(storyTimeline.events ?? {})) {
  for (const cue of event.cues ?? []) {
    if (cue.subtitleKey && !storyKeys.has(cue.subtitleKey)) {
      errors.push(`story timeline references unknown subtitle key: ${cue.subtitleKey}`);
    }
    if (cue.channel === "voice" && cue.subtitleSurface !== "scene") {
      errors.push(`Chapter 3 voice must use the scene subtitle surface: ${cue.subtitleKey ?? "dynamic"}`);
    }
  }
}

const recorded = new Map();
for (const manifestPath of manifestPaths) {
  const manifest = readJson(manifestPath);
  for (const [asset, metadata] of Object.entries(manifest.assets ?? {})) {
    if (recorded.has(asset)) errors.push(`duplicate generated manifest asset: ${asset}`);
    recorded.set(asset, { ...metadata, manifestPath });
  }
}

const ready = [];
const missing = [];
const unrecorded = [];
const stale = [];
const existingHashes = new Map();
for (const [asset, definition] of expected) {
  const output = join(audioRoot, definition.path);
  const metadata = recorded.get(asset);
  if (!existsSync(output)) {
    missing.push({ asset, ...definition });
    continue;
  }
  const outputHash = sha256(output);
  const duplicate = existingHashes.get(outputHash);
  if (duplicate) errors.push(`duplicate audio bytes: ${asset} and ${duplicate}`);
  existingHashes.set(outputHash, asset);
  if (!metadata) {
    unrecorded.push({ asset, ...definition });
    continue;
  }
  if (metadata.path !== definition.path || (metadata.sha256 && metadata.sha256 !== outputHash)) {
    stale.push({
      asset,
      ...definition,
      recordedPath: metadata.path,
      reason: metadata.path !== definition.path ? "path_mismatch" : "hash_mismatch"
    });
    continue;
  }
  ready.push({ asset, ...definition });
}

for (const [asset, metadata] of recorded) {
  if (!expected.has(asset)) errors.push(`generated manifest contains undefined asset: ${asset} (${metadata.manifestPath})`);
}

const status = errors.length === 0 && missing.length === 0 && unrecorded.length === 0 && stale.length === 0
  ? "complete"
  : "incomplete";
const report = {
  status,
  expected: expected.size,
  ready: ready.length,
  missing,
  unrecorded,
  stale,
  errors,
  voiceContract: {
    narrator: story.voices?.male_narrator,
    system: story.voices?.female_system,
    lines: story.lines?.length ?? 0
  }
};

process.stdout.write(`${JSON.stringify(report, null, 2)}\n`);
if (!reportOnly && status !== "complete") process.exitCode = 1;
