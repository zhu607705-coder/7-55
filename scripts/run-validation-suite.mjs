#!/usr/bin/env node

import { spawnSync } from "node:child_process";
import { performance } from "node:perf_hooks";
import process from "node:process";

const VALIDATORS = Object.freeze({
  typecheck: Object.freeze({ area: "source", script: "typecheck", risk: "TypeScript contract and import integrity" }),
  text: Object.freeze({ area: "generated-text", script: "text:check", risk: "player-facing text inventory freshness" }),
  taskGuidance: Object.freeze({ area: "task-ui", script: "verify:task-guidance", risk: "single owner for persistent route guidance" }),
  developerLevels: Object.freeze({ area: "developer-tools", script: "verify:developer-levels", risk: "checkpoint coverage and unique assignment" }),
  cc98Login: Object.freeze({ area: "chapter-2", script: "verify:cc98-login", risk: "identity gate, lockout and save migration" }),
  interlude: Object.freeze({ area: "chapter-3.5", script: "chapter3:validate-interlude", risk: "parallel evidence order, rejection and save migration" }),
  canteenBike: Object.freeze({ area: "chapter-3", script: "verify:canteen-bike-transition", risk: "bike transition lifecycle and retired-path exclusion" }),
  theaterSpotlight: Object.freeze({ area: "chapter-3", script: "theater:validate-spotlight", risk: "spotlight timing boundaries and failure classification" }),
  qizhenRain: Object.freeze({ area: "chapter-3", script: "qizhen:validate-rain-safety", risk: "weather safety gate, checkpoint resume and save reload" }),
  qizhenFishing: Object.freeze({ area: "chapter-3", script: "qizhen:validate-fishing", risk: "rhythm timing, hold, failure and cancellation" }),
  qizhenSwan: Object.freeze({ area: "chapter-3", script: "qizhen:validate-swan-chase", risk: "pursuit pressure without changing catch or finish authority" }),
  qizhenTools: Object.freeze({ area: "chapter-3", script: "qizhen:validate-tool-branches", risk: "order-independent tool branches and final capture handoff" }),
  pursuitAudio: Object.freeze({ area: "cross-chapter", script: "audio:pursuit:verify", risk: "pursuit audio lifecycle, voice cues and asset integrity" }),
  facingAgnostic: Object.freeze({ area: "cross-chapter", script: "verify:rpg-facing-agnostic", risk: "interactions remain independent of actor facing" }),
  realityMode: Object.freeze({ area: "cross-chapter", script: "verify:rpg-reality-mode-order", risk: "mode-order independence and truthful persistence" }),
  interiorDoors: Object.freeze({ area: "cross-chapter", script: "verify:rpg-interior-doors", risk: "door animation, unobstructed passage and actor occlusion" }),
  chapter4Warmup: Object.freeze({ area: "chapter-4", script: "chapter4:validate-warmup", risk: "asset readiness, retry, cancellation and degradation" }),
  chapter4Guard: Object.freeze({ area: "chapter-4", script: "chapter4:validate-guard-presentation", risk: "guard presentation without progression authority mutation" }),
  chapter4Interactions: Object.freeze({ area: "chapter-4", script: "chapter4:validate-effective-interactions", risk: "optional interactions across floor, mode and phase" }),
  chapter4StarLamp: Object.freeze({ area: "chapter-4", script: "chapter4:validate-star-lamp", risk: "real 3D orbit, delayed ignition, fallback lifecycle and one-time completion proof" }),
  chapter4Assets: Object.freeze({ area: "chapter-4", script: "chapter4:validate-assets", risk: "runtime asset presence, dimensions and active consumers" }),
  chapter4Story: Object.freeze({ area: "chapter-4", script: "chapter4:validate-story", risk: "quest facts, causal gates and save closure" }),
  chapter4Topology: Object.freeze({ area: "chapter-4", script: "chapter4:validate-topology", risk: "walkability, room boundaries and floor transitions" }),
  chapter4Runtime: Object.freeze({ area: "chapter-4", script: "chapter4:validate-runtime", risk: "controller and runtime state-machine invariants" }),
  chapter4CausalFlow: Object.freeze({ area: "chapter-4", script: "chapter4:validate-causal-flow", risk: "cross-phase clue reuse, grouped repetition cap and non-duplicated adaptive help" }),
  chapter4Task14: Object.freeze({ area: "chapter-4", script: "chapter4:validate-task14", risk: "final task and developer-checkpoint contract" }),
  chapter3Audio: Object.freeze({ area: "audio", script: "audio:chapter3:verify", risk: "Chapter 3 manifest, routing and generated audio integrity" }),
  voiceMemos: Object.freeze({ area: "audio", script: "audio:chapter3-interlude-voice-memos:verify", risk: "voice memo files, metadata and scene routing" }),
  campusMap: Object.freeze({ area: "campus-map", script: "map:zijingang", risk: "north-up and side-view projection boundaries" }),
  characterSprites: Object.freeze({ area: "authoring", script: "verify:rpg-character-sprites", risk: "source-to-runtime silhouette, padding and scale integrity" }),
  productionBuild: Object.freeze({ area: "release", script: "build:production:unchecked", risk: "production bundle compilation after the shared typecheck" }),
  browserSmoke: Object.freeze({ area: "release", script: "verify:browser-smoke", risk: "production bundle boot and critical browser route" }),
  singleBuild: Object.freeze({ area: "release", script: "build:single:unchecked", risk: "offline single-file bundle generation" }),
  singleVerify: Object.freeze({ area: "release", script: "verify:single", risk: "offline artifact structure and embedded resources" }),
  qizhenJournal: Object.freeze({ area: "authoring", script: "qizhen:validate-journal", risk: "journal schema, copy and persona references" }),
  stairMaterials: Object.freeze({ area: "authoring", script: "chapter4:validate-stair-materials", risk: "offline Three.js material integrity and provenance" })
});

const SUITE_KEYS = Object.freeze({
  quick: Object.freeze([
    "typecheck",
    "text",
    "taskGuidance",
    "developerLevels"
  ]),
  critical: Object.freeze([
    "typecheck",
    "cc98Login",
    "interlude",
    "canteenBike",
    "theaterSpotlight",
    "qizhenRain",
    "qizhenFishing",
    "qizhenSwan",
    "qizhenTools",
    "pursuitAudio",
    "facingAgnostic",
    "realityMode",
    "interiorDoors",
    "chapter4Warmup",
    "chapter4Guard",
    "chapter4Interactions",
    "chapter4StarLamp",
    "chapter4Story",
    "chapter4Topology",
    "chapter4Runtime",
    "chapter4CausalFlow",
    "chapter4Task14"
  ]),
  extended: Object.freeze([
    "text",
    "taskGuidance",
    "developerLevels",
    "characterSprites",
    "qizhenJournal",
    "stairMaterials"
  ]),
  release: Object.freeze([
    "typecheck",
    "text",
    "taskGuidance",
    "developerLevels",
    "cc98Login",
    "interlude",
    "canteenBike",
    "theaterSpotlight",
    "qizhenRain",
    "qizhenFishing",
    "qizhenSwan",
    "qizhenTools",
    "pursuitAudio",
    "facingAgnostic",
    "realityMode",
    "interiorDoors",
    "chapter4Warmup",
    "chapter4Guard",
    "chapter4Interactions",
    "chapter4StarLamp",
    "chapter4Assets",
    "chapter4Story",
    "chapter4Topology",
    "chapter4Runtime",
    "chapter4CausalFlow",
    "chapter4Task14",
    "chapter3Audio",
    "voiceMemos",
    "campusMap",
    "productionBuild",
    "singleBuild",
    "singleVerify",
    "browserSmoke"
  ])
});

const requestedSuite = process.argv[2] ?? "critical";
const selectedKeys = SUITE_KEYS[requestedSuite];

if (!selectedKeys) {
  console.error(`Unknown validation suite ${JSON.stringify(requestedSuite)}. Expected one of: ${Object.keys(SUITE_KEYS).join(", ")}.`);
  process.exit(2);
}

const selected = selectedKeys.map((key) => VALIDATORS[key]);
const npmCliPath = process.env.npm_execpath;
const npmCommand = npmCliPath
  ? process.execPath
  : process.platform === "win32" ? "npm.cmd" : "npm";
const failures = [];
const startedAt = performance.now();

console.log(`Running ${requestedSuite} validation suite (${selected.length} validators).`);

for (const validator of selected) {
  const validatorStartedAt = performance.now();
  console.log(`\n[${validator.area}] npm run ${validator.script}`);
  console.log(`Risk: ${validator.risk}`);

  const npmArguments = npmCliPath
    ? [npmCliPath, "run", validator.script]
    : ["run", validator.script];
  const result = spawnSync(npmCommand, npmArguments, {
    cwd: process.cwd(),
    env: { ...process.env, CI: process.env.CI ?? "true" },
    stdio: "inherit"
  });

  const elapsedMs = Math.round(performance.now() - validatorStartedAt);
  if (result.error || result.status !== 0) {
    failures.push({
      ...validator,
      status: result.status,
      signal: result.signal,
      error: result.error?.message ?? null,
      elapsedMs
    });
    console.error(`[FAIL] ${validator.script} (${elapsedMs} ms)`);
    continue;
  }

  console.log(`[PASS] ${validator.script} (${elapsedMs} ms)`);
}

const totalMs = Math.round(performance.now() - startedAt);
if (failures.length > 0) {
  console.error(`\n${requestedSuite} validation suite failed: ${failures.length}/${selected.length} validators failed in ${totalMs} ms.`);
  for (const failure of failures) {
    const detail = [
      `status=${failure.status ?? "null"}`,
      failure.signal ? `signal=${failure.signal}` : null,
      failure.error ? `error=${failure.error}` : null,
      `elapsedMs=${failure.elapsedMs}`
    ].filter(Boolean).join(" ");
    console.error(`- ${failure.script}: ${detail}`);
  }
  process.exit(1);
}

console.log(`\n${requestedSuite} validation suite PASS validators=${selected.length} elapsedMs=${totalMs}`);
