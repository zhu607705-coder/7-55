import fs from "node:fs";
import path from "node:path";
import process from "node:process";
import { fileURLToPath } from "node:url";
import { createServer } from "vite";

const root = path.resolve(path.dirname(fileURLToPath(import.meta.url)), "..");
const read = (relativePath) => fs.readFileSync(path.join(root, relativePath), "utf8");
const readJson = (relativePath) => JSON.parse(read(relativePath));
const failures = [];
let assertions = 0;

function assert(condition, message) {
  assertions += 1;
  if (!condition) failures.push(message);
}

function assertIncludes(source, token, label) {
  assert(source.includes(token), `${label}: missing ${JSON.stringify(token)}`);
}

function parseStringArray(source, name) {
  const match = source.match(new RegExp(
    `const\\s+${name}\\s*=\\s*Object\\.freeze\\(\\[([\\s\\S]*?)\\]\\s+satisfies`
  ));
  assert(Boolean(match), `phase registry: missing ${name}`);
  if (!match) return [];
  return [...match[1].matchAll(/"([^"]+)"/g)].map((entry) => entry[1]);
}

function assertUniqueCoverage(actualGroups, expected, label) {
  const actual = actualGroups.flat();
  const counts = new Map();
  for (const id of actual) counts.set(id, (counts.get(id) ?? 0) + 1);
  assert(
    [...counts.entries()].every(([, count]) => count === 1),
    `${label}: duplicate assignments ${JSON.stringify(
      [...counts.entries()].filter(([, count]) => count !== 1)
    )}`
  );
  assert(
    JSON.stringify([...new Set(actual)].sort()) === JSON.stringify([...expected].sort()),
    `${label}: coverage differs from active manifest`
  );
}

const registry = read("src/scenes/rpg/ChapterFourWarmupAssets.ts");
const scene = read("src/scenes/rpg/ChapterFourTemporalMazeScene.ts");
const host = read("src/scenes/rpg/RpgGameHost.tsx");
const gate = read("src/components/Chapter4PrologueRuntimeGate.tsx");
const app = read("src/App.tsx");
const runtimePreload = read("src/scenes/rpg/RpgRuntimePreload.ts");
const environmentTextures = read("src/scenes/rpg/FinaleEnvironmentTextures.ts");
const npcTextures = read("src/scenes/rpg/FinaleNpcTextures.ts");
const environmentManifest = readJson(
  "src/assets/rpg/interiors/finale/finale_environment_manifest.json"
);
const npcManifest = readJson("src/assets/rpg/npcs/finale/finale_npc_manifest.json");

assertIncludes(
  registry,
  'Object.freeze([\n  "entry",\n  "transport",\n  "maintenance",\n  "closure"',
  "phase order"
);

const entryPlates = parseStringArray(registry, "ENTRY_PLATE_IDS");
const transportPlates = parseStringArray(registry, "TRANSPORT_PLATE_IDS");
const maintenancePlates = parseStringArray(registry, "MAINTENANCE_PLATE_IDS");
const closurePlates = parseStringArray(registry, "CLOSURE_PLATE_IDS");
const entrySheets = parseStringArray(registry, "ENTRY_SPRITESHEET_IDS");
const transportSheets = parseStringArray(registry, "TRANSPORT_SPRITESHEET_IDS");
const maintenanceSheets = parseStringArray(registry, "MAINTENANCE_SPRITESHEET_IDS");
const transportNpcs = parseStringArray(registry, "TRANSPORT_NPC_IDS");
const maintenanceNpcs = parseStringArray(registry, "MAINTENANCE_NPC_IDS");

assert(
  JSON.stringify(entryPlates) === JSON.stringify([
    "a1_base",
    "a1_2245_opening"
  ]),
  "entry: must contain only the A1 base plate and A1 opening state"
);
assert(
  transportPlates.includes("a2_base") && transportPlates.includes("a3_base"),
  "transport: must defer the A2 and A3 base plates until elevator approach"
);
assertUniqueCoverage(
  [entryPlates, transportPlates, maintenancePlates, closurePlates],
  [...environmentManifest.basePlates, ...environmentManifest.statePlates].map((entry) => entry.id),
  "plate phases"
);
assertUniqueCoverage(
  [entrySheets, transportSheets, maintenanceSheets],
  environmentManifest.spritesheets
    .filter((entry) => entry.activeChapter4Contract === true)
    .map((entry) => entry.id),
  "spritesheet phases"
);
assertUniqueCoverage(
  [transportNpcs, maintenanceNpcs],
  npcManifest.animations.map((entry) => entry.id),
  "NPC phases"
);

assertIncludes(registry, "CHAPTER_FOUR_ELEVATOR_TEXTURE_KEY", "entry elevator asset");
assertIncludes(registry, "CHAPTER_FOUR_FRONT_DESK_TEXTURE_KEY", "entry front desk asset");
assertIncludes(registry, "CHAPTER_FOUR_BAKERY_STAFF_TEXTURE_KEY", "transport bakery asset");
assertIncludes(
  registry,
  "...CHAPTER_FOUR_ALUMNI_HONOR_WALL.map",
  "transport alumni portraits"
);
assert(
  registry.indexOf("...CHAPTER_FOUR_ALUMNI_HONOR_WALL.map")
    > registry.indexOf("transport: Object.freeze(["),
  "alumni portraits: must be assigned to transport"
);

for (const forbidden of [
  "preloadFinaleEnvironmentTextures",
  "preloadFinaleNpcTextures",
  "FINALE_ENVIRONMENTS",
  "CHAPTER_FOUR_TEMPORAL_MAZE_WARM_ASSET_URLS"
]) {
  assert(!scene.includes(forbidden), `temporal maze: legacy preload token remains ${forbidden}`);
}
assertIncludes(
  scene,
  "getChapterFourWarmupAssetsThroughPhase(this.preloadedWarmupPhase)",
  "initial cumulative phase preload"
);
assertIncludes(scene, "getChapterFourWarmupPhaseAssets(phase)", "runtime phase asset lookup");
assertIncludes(scene, "queueChapterFourWarmupAsset(this, asset)", "runtime Phaser loader queue");
assertIncludes(scene, "this.load.start()", "runtime Phaser loader start");
assertIncludes(scene, "phaseLoadFailures.set", "runtime phase failure retention");
assertIncludes(scene, "phaseLoadRetryNotBeforeMs.set", "runtime phase retry backoff");
assertIncludes(
  scene,
  "inspectChapterFourWarmupPhaseReadiness",
  "initial preload readiness must inspect actual Phaser textures"
);
assertIncludes(
  scene,
  "runChapterFourWarmupAssetBatch",
  "runtime Phaser warmup must use the executable batching policy"
);
assertIncludes(
  scene,
  "pendingWarmupSettlers",
  "scene shutdown must settle in-flight warmup waits and loaders"
);
assertIncludes(
  scene,
  "rpg_chapter4_warmup_phase_failed",
  "runtime phase failures must be published for visible retry UI"
);
assertIncludes(scene, "retryRequiredWarmupPhase", "runtime phase retry action");
assertIncludes(scene, "scheduleNextWarmupPhase", "one-stage-ahead scheduling");
assert(
  scene.indexOf("if (!this.isWarmupPhaseLoaded(requiredWarmupPhase))")
    < scene.indexOf("const next = selectChapterFourMazeProjection(state);"),
  "projection gate: phase readiness must be checked before selecting/applying a new projection"
);

assertIncludes(host, "getChapterFourWarmupPhaseAssets(phase ?? \"entry\")", "host phase registry");
assertIncludes(host, "rpg_chapter4_warmup_phase_requested", "host phase request subscription");
assertIncludes(gate, '"duan_yongping_temporal_maze", "immediate", "entry"', "prologue entry wait");
assert(
  !gate.includes("preloadRpgGameHost"),
  "prologue gate: raw module preload promise must not create an unhandled rejection path"
);
assertIncludes(
  gate,
  "rpg_chapter4_warmup_phase_failed",
  "prologue gate: phase failure detail must be visible and retryable"
);
assertIncludes(
  app,
  'state.rpgScene === "duan_yongping_temporal_maze" ? "entry" : undefined',
  "phone-side entry-only scheduling"
);

for (const metric of [
  "phaseSnapshots",
  "estimatedTransferBytes",
  "measuredTransferBytes",
  "estimatedDecodedBytes",
  "elapsedMs",
  "failedUrls",
  "constrainedNetwork",
  "lowMemory",
  "degradationReason"
]) {
  assertIncludes(runtimePreload, metric, `warmup metric ${metric}`);
}
assertIncludes(
  runtimePreload,
  "chapterFourWarmupAttemptMetrics",
  "browser preload cache-reuse attempt metrics"
);
assertIncludes(
  runtimePreload,
  "cancelSpeculativePhaseWarmup",
  "browser preload in-flight speculative cancellation"
);
assertIncludes(
  runtimePreload,
  "waitForWarmupIdleSlice",
  "browser preload idle-slice scheduling"
);
assertIncludes(
  runtimePreload,
  "image.decode().then(() => finish(true), () => finish(false))",
  "browser preload decode rejection must count as failure"
);
assertIncludes(environmentTextures, "if (!texture) continue;", "partial frame registration");
assertIncludes(npcTextures, "!scene.textures.exists(asset.id)", "partial NPC animation registration");

const policyPath = path.join(root, "src/scenes/rpg/ChapterFourWarmupLoadPolicy.ts");
assert(fs.existsSync(policyPath), "warmup policy: executable load policy module is required");

if (fs.existsSync(policyPath)) {
  let vite;
  try {
    vite = await createServer({
      appType: "custom",
      logLevel: "silent",
      server: { middlewareMode: true, ws: false }
    });
    const policy = await vite.ssrLoadModule("/src/scenes/rpg/ChapterFourWarmupLoadPolicy.ts");
    const {
      chapterFourWarmupAttemptMetrics,
      inspectChapterFourWarmupPhaseReadiness,
      runChapterFourWarmupAssetBatch,
      selectChapterFourWarmupRetryBlocker
    } = policy;

    const missingOpening = inspectChapterFourWarmupPhaseReadiness(
      ["entry"],
      (key) => key !== "a1_2245_opening"
    );
    assert(
      missingOpening.readyPhases.length === 0
        && missingOpening.missingByPhase.entry.includes("a1_2245_opening"),
      "initial preload failure: a phase with one missing texture must not be marked ready"
    );
    const completeEntry = inspectChapterFourWarmupPhaseReadiness(["entry"], () => true);
    assert(
      JSON.stringify(completeEntry.readyPhases) === JSON.stringify(["entry"])
        && completeEntry.missingByPhase.entry.length === 0,
      "initial preload success: a phase is ready only when every texture exists"
    );

    const fakeAssets = ["one", "two", "three", "four"].map((key) => ({
      key,
      url: `fake://${key}`,
      kind: "image"
    }));
    const requiredLoaded = new Set();
    const requiredResult = await runChapterFourWarmupAssetBatch({
      assets: fakeAssets,
      priority: "required",
      constraints: { constrainedNetwork: true, lowMemory: true },
      isCancelled: () => false,
      isLoaded: (asset) => requiredLoaded.has(asset.key),
      waitForIdle: async () => true,
      loadAsset: async (asset) => {
        requiredLoaded.add(asset.key);
        return true;
      }
    });
    assert(
      requiredResult.ready === true
        && requiredResult.limited === false
        && requiredResult.attemptedKeys.length === 4,
      "required batch: constrained network and low memory must not skip required assets"
    );

    const speculativeLoaded = new Set();
    let speculativeIdleWaits = 0;
    const speculativeResult = await runChapterFourWarmupAssetBatch({
      assets: fakeAssets,
      priority: "speculative",
      constraints: { constrainedNetwork: true, lowMemory: false },
      isCancelled: () => false,
      isLoaded: (asset) => speculativeLoaded.has(asset.key),
      waitForIdle: async () => {
        speculativeIdleWaits += 1;
        return true;
      },
      loadAsset: async (asset) => {
        speculativeLoaded.add(asset.key);
        return true;
      }
    });
    assert(
      speculativeResult.ready === false
        && speculativeResult.limited === true
        && speculativeResult.attemptedKeys.length === 2
        && speculativeIdleWaits === 2,
      "speculative batch: constrained devices must load only two assets through idle slices"
    );

    let cancelled = false;
    const cancelledResult = await runChapterFourWarmupAssetBatch({
      assets: fakeAssets,
      priority: "speculative",
      constraints: { constrainedNetwork: false, lowMemory: false },
      isCancelled: () => cancelled,
      isLoaded: () => false,
      waitForIdle: async () => true,
      loadAsset: async () => {
        cancelled = true;
        return false;
      }
    });
    assert(
      cancelledResult.cancelled === true && cancelledResult.attemptedKeys.length === 1,
      "cancelled batch: cancellation after an in-flight file must settle and stop the next file"
    );

    const failedResult = await runChapterFourWarmupAssetBatch({
      assets: fakeAssets.slice(0, 1),
      priority: "required",
      constraints: { constrainedNetwork: false, lowMemory: false },
      isCancelled: () => false,
      isLoaded: () => false,
      waitForIdle: async () => true,
      loadAsset: async () => false
    });
    assert(
      failedResult.ready === false
        && JSON.stringify(failedResult.failedUrls) === JSON.stringify(["fake://one"]),
      "failed batch: failed URLs must remain visible for retry and debug"
    );

    const blocker = selectChapterFourWarmupRetryBlocker(
      ["entry", "transport", "maintenance"],
      (phase) => phase === "entry",
      new Map([["transport", 2_400], ["maintenance", 9_000]]),
      1_400
    );
    assert(
      blocker?.phase === "transport" && blocker.retryAfterMs === 1_000,
      "retry backoff: the earliest missing prerequisite owns the retry clock"
    );

    const reusedMetrics = chapterFourWarmupAttemptMetrics({
      measuredTransferBytes: 512,
      estimatedDecodedBytes: 2_048,
      transferMeasurement: "measured"
    }, true);
    assert(
      reusedMetrics.measuredTransferBytes === 0
        && reusedMetrics.estimatedDecodedBytes === 0
        && reusedMetrics.transferMeasurement === "unknown",
      "reuse metrics: a reused image must report zero transfer and decode work for this attempt"
    );
  } catch (error) {
    assert(false, `warmup policy executable checks failed: ${error instanceof Error ? error.message : String(error)}`);
  } finally {
    await vite?.close();
  }
}

if (failures.length > 0) {
  console.error(`Chapter 4 warmup phase validation failed (${failures.length}/${assertions}):`);
  for (const failure of failures) console.error(`- ${failure}`);
  process.exitCode = 1;
} else {
  console.log(
    `Chapter 4 warmup phase validation passed: ${assertions} assertions, `
      + `${entryPlates.length + transportPlates.length + maintenancePlates.length + closurePlates.length} plates, `
      + `${entrySheets.length + transportSheets.length + maintenanceSheets.length} spritesheets, `
      + `${transportNpcs.length + maintenanceNpcs.length} NPC animations.`
  );
}
