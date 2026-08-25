import { readFile } from "node:fs/promises";
import { mkdtemp, rm } from "node:fs/promises";
import { tmpdir } from "node:os";
import path from "node:path";
import { fileURLToPath, pathToFileURL } from "node:url";
import ts from "typescript";
import { build } from "esbuild";
import { runEndlessArcadeLongRunValidation } from "./verify-endless-arcade-long-run.mjs";

const repositoryRoot = path.resolve(path.dirname(fileURLToPath(import.meta.url)), "..");

const sourcePaths = Object.freeze({
  packageJson: "package.json",
  ci: ".github/workflows/web-ci.yml",
  types: "src/core/types.ts",
  gameState: "src/core/GameState.ts",
  saveStore: "src/core/SaveStore.ts",
  featureAccess: "src/core/FeatureAccess.ts",
  phoneHomeApps: "src/core/PhoneHomeApps.ts",
  sceneRouter: "src/core/SceneRouter.ts",
  storageKeys: "src/core/StorageKeys.ts",
  main: "src/main.tsx",
  developerChannel: "src/modules/DeveloperChannel.ts",
  arcadeAudio: "src/data/endless-arcade.audio.json",
  phoneHome: "src/scenes/phone/P13_PhoneHome/index.tsx",
  arcadePage: "src/scenes/phone/P16_BikeArcade/index.tsx",
  arcadeEvents: "src/scenes/phone/P16_BikeArcade/EndlessArcadeSceneEvents.ts",
  arcadeHost: "src/scenes/phone/P16_BikeArcade/EndlessArcadeGameHost.tsx",
  arcadeRuntime: "src/scenes/phone/P16_BikeArcade/EndlessArcadeRuntime.ts",
  fishingScene: "src/scenes/phone/P16_BikeArcade/EndlessFishingScene.ts",
  spotlightScene: "src/scenes/phone/P16_BikeArcade/EndlessSpotlightScene.ts",
  rhythmEngine: "src/modules/RhythmFishingEngine.ts",
  arcadeCss: "src/styles/scenes/p16-bike-arcade.css",
  viteEnv: "src/vite-env.d.ts",
  registry: "src/scenes/phone/P16_BikeArcade/EndlessChallengeRegistry.ts",
  controller: "src/modules/EndlessArcadeController.ts",
  fishingRules: "src/scenes/phone/P16_BikeArcade/EndlessFishingRules.ts",
  spotlightRules: "src/scenes/phone/P16_BikeArcade/EndlessSpotlightRules.ts",
  bikeRules: "src/scenes/phone/P16_BikeArcade/BikeArcadeRules.ts",
  bikeRuntime: "src/scenes/phone/P16_BikeArcade/BikeArcadeRuntime.ts",
  bikeScene: "src/scenes/phone/P16_BikeArcade/BikeRushScene.ts",
  qizhenFishing: "src/scenes/rpg/QizhenFishingRhythmModel.ts",
  theaterSpotlight: "src/scenes/rpg/TheaterSpotlightModel.ts",
  theaterController: "src/modules/ChapterThreeTheaterController.ts",
  chapterFourController: "src/modules/ChapterFourTemporalMazeController.ts"
});

const GROUP_LABELS = Object.freeze({
  entry: "validator entry",
  state: "GameState defaults",
  access: "completion receipt and access gate",
  save: "SaveStore migration and receipt recovery",
  registry: "three-mode registry",
  controller: "attempt controller",
  rules: "deterministic endless rules and resource bounds",
  longrun: "30-minute deterministic offline simulations",
  phone: "phone entry and route protection",
  compatibility: "story-mode compatibility",
  delivery: "delivery wiring"
});

const checks = [];

function recordCheck(group, id, passed, message) {
  checks.push({ group, id, passed: Boolean(passed), message });
}

async function readSource(key, group, required = true) {
  const relativePath = sourcePaths[key];
  try {
    const source = await readFile(path.join(repositoryRoot, relativePath), "utf8");
    if (required) recordCheck(group, `file.${key}`, true, `${relativePath} exists`);
    return source;
  } catch (error) {
    if (required) {
      recordCheck(
        group,
        `file.${key}`,
        false,
        `${relativePath} is required (${error instanceof Error ? error.code ?? error.message : String(error)})`
      );
    }
    return null;
  }
}

function matches(source, pattern) {
  return typeof source === "string" && pattern.test(source);
}

function includesAll(source, values) {
  return typeof source === "string" && values.every((value) => source.includes(value));
}

function sameMembers(actual, expected) {
  if (actual.length !== expected.length) return false;
  const left = [...actual].sort();
  const right = [...expected].sort();
  return left.every((value, index) => value === right[index]);
}

function extractTypeUnionMembers(source, typeName) {
  if (typeof source !== "string") return [];
  const declaration = new RegExp(`(?:export\\s+)?type\\s+${typeName}\\s*=([\\s\\S]*?);`).exec(source);
  if (!declaration) return [];
  return [...declaration[1].matchAll(/["']([^"']+)["']/g)].map((match) => match[1]);
}

function extractFunctionBlock(source, functionName) {
  if (typeof source !== "string") return null;
  const sourceFile = ts.createSourceFile(
    "endless-validator-source.ts",
    source,
    ts.ScriptTarget.Latest,
    true,
    ts.ScriptKind.TS
  );
  let declaration = null;
  function visit(node) {
    if (
      declaration === null
      && ts.isFunctionDeclaration(node)
      && node.name?.text === functionName
      && node.body
    ) {
      declaration = node;
      return;
    }
    ts.forEachChild(node, visit);
  }
  visit(sourceFile);
  if (declaration === null || !declaration.body) return null;
  return source.slice(declaration.getStart(sourceFile), declaration.body.end);
}

function assertFunctionExtractorIntegrity() {
  const sample = [
    "function extractorTarget(value: string): { text: string } {",
    "  // } inside a line comment must stay inert",
    "  /* } inside a block comment must stay inert */",
    "  const literal = \"}\";",
    "  const template = `value:${value}}`;",
    "  return { text: literal + template };",
    "}",
    "function extractorAfter(): void {}"
  ].join("\n");
  const extracted = extractFunctionBlock(sample, "extractorTarget");
  const passed = extracted !== null
    && extracted.startsWith("function extractorTarget")
    && extracted.includes(": { text: string }")
    && extracted.includes('const literal = "}";')
    && extracted.includes("const template = `value:${value}}`;")
    && extracted.includes("return { text: literal + template };")
    && !extracted.includes("extractorAfter");
  if (!passed) {
    throw new Error("TypeScript AST function extractor self-test failed");
  }
}

assertFunctionExtractorIntegrity();

function hasFiniteResourceLimit(source, subjectPattern) {
  if (typeof source !== "string") return false;
  const constantPattern = new RegExp(
    `(?:MAX|LIMIT|CAP)[A-Z0-9_]*(?:${subjectPattern})[A-Z0-9_]*\\s*=\\s*[1-9][0-9_]*`,
    "i"
  );
  return constantPattern.test(source);
}

function validateRuleSource({ id, source, seedSymbol, resourcePattern }) {
  recordCheck(
    "rules",
    `${id}.explicit-seed`,
    matches(source, new RegExp(`\\b${seedSymbol}\\b`, "i")),
    `${id} rules must accept or derive content from an explicit deterministic seed`
  );
  recordCheck(
    "rules",
    `${id}.no-math-random`,
    typeof source === "string" && !/Math\.random\s*\(/.test(source),
    `${id} rules must not call Math.random()`
  );
  recordCheck(
    "rules",
    `${id}.resource-limit`,
    hasFiniteResourceLimit(source, resourcePattern),
    `${id} rules must export a finite resource limit constant for ${resourcePattern.toLowerCase()}`
  );
}

const sources = {};
for (const key of [
  "packageJson",
  "types",
  "gameState",
  "saveStore",
  "featureAccess",
  "phoneHomeApps",
  "sceneRouter",
  "storageKeys",
  "main",
  "developerChannel",
  "arcadeAudio",
  "phoneHome",
  "arcadePage",
  "arcadeEvents",
  "arcadeHost",
  "arcadeRuntime",
  "fishingScene",
  "spotlightScene",
  "rhythmEngine",
  "arcadeCss",
  "viteEnv",
  "bikeRules",
  "bikeRuntime",
  "bikeScene",
  "qizhenFishing",
  "theaterSpotlight",
  "theaterController",
  "chapterFourController"
]) {
  sources[key] = await readSource(key, "entry");
}
for (const key of ["registry", "controller", "fishingRules", "spotlightRules"]) {
  sources[key] = await readSource(key, key === "registry" ? "registry" : key === "controller" ? "controller" : "rules");
}
sources.ci = await readSource("ci", "delivery");

let packageJson = null;
if (sources.packageJson !== null) {
  try {
    packageJson = JSON.parse(sources.packageJson);
    recordCheck("entry", "package-json.parse", true, "package.json is valid JSON");
  } catch (error) {
    recordCheck(
      "entry",
      "package-json.parse",
      false,
      `package.json must be valid JSON (${error instanceof Error ? error.message : String(error)})`
    );
  }
}
recordCheck(
  "entry",
  "package-json.script",
  packageJson?.scripts?.["endless:validate"] === "node scripts/verify-endless-arcade.mjs",
  "package.json must register endless:validate as node scripts/verify-endless-arcade.mjs"
);

recordCheck(
  "state",
  "types.postgame-state",
  matches(sources.types, /export\s+interface\s+PostgameState\b/),
  "types.ts must export PostgameState"
);
recordCheck(
  "state",
  "types.endless-state",
  matches(sources.types, /export\s+interface\s+EndlessArcadeState\b/),
  "types.ts must export EndlessArcadeState"
);
recordCheck(
  "state",
  "types.game-state-fields",
  matches(sources.types, /\bpostgame\s*:\s*PostgameState\b/)
    && matches(sources.types, /\bendlessArcade\s*:\s*EndlessArcadeState\b/),
  "GameState must own postgame and endlessArcade fields"
);
recordCheck(
  "state",
  "defaults.postgame",
  matches(sources.gameState, /\bpostgame\s*:\s*\{[\s\S]{0,500}\bcompletionReceipt\s*:\s*null/),
  "createInitialGameState() must default postgame.completionReceipt to null"
);
recordCheck(
  "state",
  "defaults.endless-arcade",
  matches(sources.gameState, /\bendlessArcade\s*:\s*\{[\s\S]{0,1400}/)
    && includesAll(sources.gameState, ["fishing", "spotlight", "bike"]),
  "createInitialGameState() must initialize records for fishing, spotlight and bike"
);
recordCheck(
  "state",
  "defaults.safe-numeric-records",
  matches(sources.gameState, /\battemptCount\s*:\s*0/)
    && matches(sources.gameState, /\bbestScore\s*:\s*0/)
    && matches(sources.gameState, /\bbestProgress\s*:\s*0/)
    && matches(sources.gameState, /\bbestCombo\s*:\s*0/),
  "new endless records must start with zeroed finite counters"
);

const completionSelector = extractFunctionBlock(sources.featureAccess, "selectMainStoryCompleted");
recordCheck(
  "access",
  "receipt.literal",
  [
    sources.types,
    sources.gameState,
    sources.saveStore,
    sources.featureAccess,
    sources.chapterFourController
  ]
    .some((source) => typeof source === "string" && source.includes("chapter4_closure_v1")),
  "the formal completion receipt chapter4_closure_v1 must be declared in active source"
);
recordCheck(
  "access",
  "receipt.controller-write",
  includesAll(sources.chapterFourController, ["postgame", "completionReceipt"])
    && (sources.chapterFourController?.includes("chapter4_closure_v1") === true
      || /RECEIPT/.test(sources.chapterFourController ?? "")),
  "the Chapter 4 controller must write the formal receipt in its verified completion transaction"
);
recordCheck(
  "access",
  "selector.export",
  matches(sources.featureAccess, /export\s+function\s+selectMainStoryCompleted\s*\(/),
  "FeatureAccess must export selectMainStoryCompleted(state)"
);
recordCheck(
  "access",
  "selector.receipt-authority",
  includesAll(completionSelector, ["completionReceipt"])
    && (completionSelector?.includes("chapter4_closure_v1") === true || /RECEIPT/.test(completionSelector ?? "")),
  "selectMainStoryCompleted must require the validated completion receipt"
);
recordCheck(
  "access",
  "selector.legacy-bike-independent",
  completionSelector !== null && !/bikeArcade|bike_arcade/.test(completionSelector),
  "legacy bikeArcade fields must not participate in the main-story completion selector"
);
recordCheck(
  "access",
  "feature-access.endless-field",
  matches(sources.types, /\bendlessChallenge\s*:\s*boolean\b/)
    && matches(sources.featureAccess, /\bendlessChallenge\b/),
  "FeatureAccess must expose endlessChallenge"
);
recordCheck(
  "access",
  "feature-access.selector-use",
  matches(sources.featureAccess, /endlessChallenge\s*=\s*selectMainStoryCompleted\s*\(/)
    || matches(sources.featureAccess, /endlessChallenge\s*:\s*selectMainStoryCompleted\s*\(/),
  "selectFeatureAccess must derive endlessChallenge from selectMainStoryCompleted"
);
recordCheck(
  "access",
  "route.endless-gate",
  matches(
    sources.featureAccess,
    /scene\s*===\s*["']bike_arcade["'][\s\S]{0,120}return\s+access\.endlessChallenge/
  ),
  "canEnterScene(bike_arcade) must use access.endlessChallenge"
);

recordCheck(
  "save",
  "version.chapter-four-fixed",
  matches(sources.saveStore, /const\s+CHAPTER_FOUR_755_SAVE_VERSION\s*=\s*25\s*;/),
  "SaveStore must freeze CHAPTER_FOUR_755_SAVE_VERSION at 25"
);
recordCheck(
  "save",
  "version.postgame-boundary",
  matches(
    sources.saveStore,
    /const\s+(?:POSTGAME|ENDLESS_ARCADE)[A-Z0-9_]*SAVE_VERSION\s*=\s*26\s*;/
  ),
  "SaveStore must declare a postgame/endless save boundary at version 26"
);
recordCheck(
  "save",
  "version.current",
  matches(sources.saveStore, /const\s+SAVE_VERSION\s*=\s*(?:26|[A-Z0-9_]*POSTGAME[A-Z0-9_]*|[A-Z0-9_]*ENDLESS[A-Z0-9_]*)\s*;/),
  "SAVE_VERSION must advance to the postgame version"
);
recordCheck(
  "save",
  "state.normalizers",
  includesAll(sources.saveStore, ["normalizePostgame", "normalizeEndlessArcade"]),
  "SaveStore must normalize postgame and endlessArcade independently"
);
const postgameNormalizer = extractFunctionBlock(sources.saveStore, "normalizePostgame");
recordCheck(
  "save",
  "receipt.exact-validation",
  postgameNormalizer !== null
    && includesAll(postgameNormalizer, ["completionReceipt"])
    && (postgameNormalizer.includes("chapter4_closure_v1") || /RECEIPT/.test(postgameNormalizer))
    && /null/.test(postgameNormalizer),
  "normalizePostgame must preserve only the exact approved receipt and clear other values to null"
);
recordCheck(
  "save",
  "receipt.canonical-complete-recovery",
  includesAll(sources.saveStore, ["completionReceipt", "exteriorClosureAcknowledged"])
    && matches(sources.saveStore, /phase\s*:\s*["']complete["']/)
    && matches(sources.saveStore, /completed\s*:\s*true/),
  "a valid receipt must restore the canonical completed Chapter 4 state"
);
const chapterFourNormalizer = extractFunctionBlock(sources.saveStore, "normalizeChapterFour");
recordCheck(
  "save",
  "chapter-four.migration-threshold",
  chapterFourNormalizer !== null
    && chapterFourNormalizer.includes("CHAPTER_FOUR_755_SAVE_VERSION")
    && !/envelopeVersion\s*<\s*SAVE_VERSION/.test(chapterFourNormalizer),
  "Chapter 4 migration must use the frozen Chapter 4 threshold instead of SAVE_VERSION"
);
const legacyChapterThreeDetector = extractFunctionBlock(sources.saveStore, "isLegacyChapterThreeState");
recordCheck(
  "save",
  "legacy-bike-scene.version-boundary",
  legacyChapterThreeDetector !== null
    && legacyChapterThreeDetector.includes("bike_arcade")
    && legacyChapterThreeDetector.includes("envelopeVersion")
    && /envelopeVersion\s*</.test(legacyChapterThreeDetector),
  "legacy currentScene=bike_arcade inference must be bounded by an envelope version"
);
recordCheck(
  "save",
  "legacy-bike.no-unlock-receipt",
  completionSelector !== null
    && !completionSelector.includes("bikeArcade")
    && postgameNormalizer !== null
    && !postgameNormalizer.includes("bikeArcade"),
  "legacy bikeArcade progress may not synthesize a formal completion receipt"
);
recordCheck(
  "save",
  "endless-record-sanitize",
  matches(sources.saveStore, /Number\.isFinite/)
    && matches(sources.saveStore, /Number\.isSafeInteger|Number\.isInteger/)
    && sources.saveStore?.includes("endlessArcade") === true,
  "endless record values must be sanitized as finite integers before restore"
);

const registeredModes = extractTypeUnionMembers(sources.types, "EndlessChallengeModeId");
recordCheck(
  "registry",
  "types.mode-union",
  sameMembers(registeredModes, ["fishing", "spotlight", "bike"]),
  `EndlessChallengeModeId must contain exactly fishing, spotlight and bike (received ${registeredModes.join(", ") || "none"})`
);
recordCheck(
  "registry",
  "registry.export",
  matches(
    sources.registry,
    /export\s+(?:const|function)\s+(?:ENDLESS_[A-Z0-9_]*(?:REGISTRY|CHALLENGE|MODE)[A-Z0-9_]*|endless[A-Za-z0-9]*(?:Registry|Challenge|Mode)[A-Za-z0-9]*)/
  ),
  "EndlessChallengeRegistry must export the canonical mode registry"
);
recordCheck(
  "registry",
  "registry.all-modes",
  includesAll(sources.registry, ["fishing", "spotlight", "bike"]),
  "the registry must define fishing, spotlight and bike entries"
);
recordCheck(
  "registry",
  "registry.lazy-loaders",
  (
    matches(sources.registry, /import\s*\(\s*["'].+EndlessFishingScene["']\s*\)/)
      && matches(sources.registry, /import\s*\(\s*["'].+EndlessSpotlightScene["']\s*\)/)
      && matches(sources.registry, /import\s*\(\s*["'].+BikeRushScene["']\s*\)/)
  ) || (
    sources.registry?.includes("import.meta.glob") === true
      && includesAll(sources.registry, [
        "./EndlessFishingScene.ts",
        "./EndlessSpotlightScene.ts",
        "./BikeRushScene.ts",
        "runtime_unavailable"
      ])
  ),
  "each mode must use an explicit lazy scene loader or an explicit lazy import.meta.glob module contract"
);

recordCheck(
  "controller",
  "controller.export",
  matches(sources.controller, /export\s+class\s+EndlessArcadeController\b/),
  "EndlessArcadeController must be exported"
);
for (const methodName of ["startAttempt", "settleAttempt", "cancelAttempt"]) {
  recordCheck(
    "controller",
    `controller.method.${methodName}`,
    matches(sources.controller, new RegExp(`\\b${methodName}\\s*\\(`)),
    `EndlessArcadeController must implement ${methodName}()`
  );
}
recordCheck(
  "controller",
  "controller.explicit-seed",
  matches(sources.controller, /\bseed\b/i) && !matches(sources.controller, /Math\.random\s*\(/),
  "startAttempt must derive an explicit deterministic seed without Math.random()"
);
recordCheck(
  "controller",
  "controller.run-id",
  matches(sources.controller, /\brunId\b/),
  "attempt start, settle and cancel contracts must carry a runId"
);
recordCheck(
  "controller",
  "controller.settle-once",
  matches(sources.controller, /(?:settled|active)[A-Za-z0-9_]*Run|new\s+(?:Set|Map)\s*</)
    && matches(sources.controller, /\.has\s*\(|\.delete\s*\(|runId\s*!==|!==\s*[^;\n]*runId/),
  "settleAttempt must reject duplicate or stale run IDs"
);
recordCheck(
  "controller",
  "controller.summary-sanitize",
  matches(sources.controller, /Number\.isFinite/)
    && matches(sources.controller, /Number\.isSafeInteger|Number\.isInteger/),
  "settleAttempt must reject non-finite and unsafe summary values"
);
recordCheck(
  "controller",
  "controller.state-boundary",
  sources.controller?.includes("endlessArcade") === true
    && !/state\.bikeArcade|\.bikeArcade\s*=/.test(sources.controller ?? ""),
  "EndlessArcadeController must write only the endlessArcade state lane"
);

validateRuleSource({
  id: "fishing",
  source: sources.fishingRules,
  seedSymbol: "seed",
  resourcePattern: "NOTE|HISTORY|SEGMENT"
});
validateRuleSource({
  id: "spotlight",
  source: sources.spotlightRules,
  seedSymbol: "seed",
  resourcePattern: "PATH|POINT|OBJECT|HISTORY"
});
validateRuleSource({
  id: "bike",
  source: sources.bikeRules,
  seedSymbol: "seed",
  resourcePattern: "OBSTACLE|PARTICLE|OBJECT|HISTORY"
});
recordCheck(
  "rules",
  "bike.explicit-mode",
  matches(sources.bikeRules, /["']story["']/) && matches(sources.bikeRules, /["']endless["']/),
  "bike rules must distinguish story and endless modes"
);
recordCheck(
  "rules",
  "bike.strict-run-config",
  includesAll(sources.arcadeHost, ["bikeArcadeRunConfig", 'mode: "endless"', "seed: run.seed"])
    && includesAll(sources.bikeScene, [
      "bikeArcadeRunConfig",
      "requires a matching endless bridge",
      "Story bike runtime rejected a non-story"
    ]),
  "bike host and scene must exchange and strictly validate one deterministic run config"
);
recordCheck(
  "rules",
  "bike.story-dispatcher",
  includesAll(sources.bikeRuntime, [
    "BikeArcadeBridge",
    "BikeArcadeStoryBridgeDispatcher",
    "onDistance",
    "onLives",
    "onCollision",
    "onFinish"
  ]) && sources.bikeScene?.includes("storyDispatcher.dispatch") === true,
  "story bike callbacks must pass through the executable compatibility dispatcher"
);
recordCheck(
  "rules",
  "bike.single-game-host",
  (sources.arcadeHost?.match(/useRef<Phaser\.Game \| null>/g) ?? []).length === 1
    && sources.arcadeHost?.includes("destroyActiveGame();") === true
    && sources.arcadeHost.indexOf("destroyActiveGame();") < sources.arcadeHost.indexOf("new PhaserRuntime.Game"),
  "the endless host must destroy the prior game before creating one replacement canvas"
);

async function validateFishingRuleRuntime() {
  if (sources.fishingRules === null) {
    recordCheck("rules", "fishing.runtime", false, "fishing runtime checks need EndlessFishingRules.ts");
    return;
  }
  const bundleDir = await mkdtemp(path.join(tmpdir(), "endless-fishing-validator-"));
  try {
    const output = path.join(bundleDir, "rules.mjs");
    await build({
      entryPoints: [path.join(repositoryRoot, sourcePaths.fishingRules)],
      outfile: output,
      bundle: true,
      format: "esm",
      platform: "node",
      target: "node20"
    });
    const rules = await import(`${pathToFileURL(output).href}?v=${Date.now()}`);
    const first = rules.createEndlessFishingSegment(755, 6);
    const replay = rules.createEndlessFishingSegment(755, 6);
    const alternate = rules.createEndlessFishingSegment(756, 6);
    const replayable = JSON.stringify(first) === JSON.stringify(replay);
    const differentiated = JSON.stringify(first) !== JSON.stringify(alternate);
    const bounded = [0, 1, 6, 18, 999].every((index) => {
      const segment = rules.createEndlessFishingSegment(755, index);
      const notes = segment.notes;
      return Number.isFinite(segment.durationSeconds)
        && Number.isFinite(segment.beatSec)
        && notes.length >= 2
        && notes.length <= rules.MAX_FISHING_NOTES_PER_SEGMENT
        && notes[0].action === "hook"
        && notes.at(-1).action === "hook"
        && notes.every((note, noteIndex) => noteIndex === 0 || note.beat > notes[noteIndex - 1].beat)
        && notes.every((note, noteIndex) => noteIndex === notes.length - 1
          || notes[noteIndex + 1].beat - note.beat >= (note.hold ?? 0));
    });
    const history = Array.from({ length: 20 }, (_, index) => index).reduce(
      (entries, next) => rules.appendFishingSegmentHistory(entries, next),
      []
    );
    const boundedHistory = history.length === rules.MAX_FISHING_SEGMENT_HISTORY;
    recordCheck("rules", "fishing.runtime-determinism", replayable && differentiated, "fishing seed and segment index must replay exactly and vary across seeds");
    recordCheck("rules", "fishing.runtime-bounds", bounded, "generated fishing segments must have ordered bounded notes and terminal hooks");
    recordCheck("rules", "fishing.runtime-history", boundedHistory, "fishing segment history must remain bounded");
  } catch (error) {
    const message = error instanceof Error ? error.message : String(error);
    recordCheck("rules", "fishing.runtime", false, `fishing runtime generation failed (${message})`);
  } finally {
    await rm(bundleDir, { recursive: true, force: true });
  }
}

async function validateBikeRuleRuntime() {
  if (sources.bikeRules === null) {
    recordCheck("rules", "bike.runtime-reset", false, "bike runtime checks need BikeArcadeRules.ts");
    return;
  }
  const bundleDir = await mkdtemp(path.join(tmpdir(), "endless-bike-validator-"));
  try {
    const output = path.join(bundleDir, "rules.mjs");
    await build({
      entryPoints: [path.join(repositoryRoot, sourcePaths.bikeRules)],
      outfile: output,
      bundle: true,
      format: "esm",
      platform: "node",
      target: "node20"
    });
    const rules = await import(`${pathToFileURL(output).href}?v=${Date.now()}`);
    const restarted = rules.createBikeArcadeRunResetState();
    restarted.lane = 0;
    restarted.safeLane = 2;
    restarted.waveIndex = 12;
    restarted.waveHistory.push(10, 11, 12);
    Object.assign(restarted, rules.createBikeArcadeRunResetState());
    const coldWave = rules.planSeededBikeObstacleWave({
      seed: 755,
      waveIndex: 0,
      mode: "endless",
      distance: 0,
      previousSafeLane: 1
    });
    const restartedWave = rules.planSeededBikeObstacleWave({
      seed: 755,
      waveIndex: restarted.waveIndex,
      mode: "endless",
      distance: 0,
      previousSafeLane: restarted.safeLane
    });
    recordCheck(
      "rules",
      "bike.runtime-reset",
      restarted.lane === 1
        && restarted.safeLane === 1
        && restarted.waveIndex === 0
        && restarted.waveHistory.length === 0
        && JSON.stringify(restartedWave) === JSON.stringify(coldWave),
      "restarting a mutated bike run must restore lane 1/1 and the cold-start seeded first wave"
    );
  } catch (error) {
    const message = error instanceof Error ? error.message : String(error);
    recordCheck("rules", "bike.runtime-reset", false, `bike restart validation failed (${message})`);
  } finally {
    await rm(bundleDir, { recursive: true, force: true });
  }
}

class MemoryStorage {
  #entries = new Map();

  get length() {
    return this.#entries.size;
  }

  clear() {
    this.#entries.clear();
  }

  getItem(key) {
    return this.#entries.has(key) ? this.#entries.get(key) : null;
  }

  key(index) {
    return [...this.#entries.keys()][index] ?? null;
  }

  removeItem(key) {
    this.#entries.delete(key);
  }

  setItem(key, value) {
    this.#entries.set(key, String(value));
  }
}

async function validateDeveloperSeedRuntime() {
  if (sources.developerChannel === null || sources.storageKeys === null) {
    recordCheck("phone", "dev.seed-runtime", false, "developer seed runtime checks need DeveloperChannel.ts and StorageKeys.ts");
    return;
  }
  const bundleDir = await mkdtemp(path.join(tmpdir(), "endless-seed-validator-"));
  try {
    const developerOutput = path.join(bundleDir, "developer-channel.mjs");
    const storageKeysOutput = path.join(bundleDir, "storage-keys.mjs");
    await Promise.all([
      build({
        entryPoints: [path.join(repositoryRoot, sourcePaths.developerChannel)],
        outfile: developerOutput,
        bundle: true,
        format: "esm",
        platform: "node",
        target: "node20"
      }),
      build({
        entryPoints: [path.join(repositoryRoot, sourcePaths.storageKeys)],
        outfile: storageKeysOutput,
        bundle: true,
        format: "esm",
        platform: "node",
        target: "node20"
      })
    ]);
    const developer = await import(`${pathToFileURL(developerOutput).href}?v=${Date.now()}`);
    const storageKeys = await import(`${pathToFileURL(storageKeysOutput).href}?v=${Date.now()}`);
    const storage = new MemoryStorage();

    storage.setItem(storageKeys.DEVELOPER_ACTIVE_KEY, "postgame-fishing-fail");
    storage.setItem(storageKeys.DEVELOPER_ENDLESS_ARCADE_SEED_KEY, "{}");
    const missingFieldFallback = developer.readEndlessArcadeDeveloperSeed(storage);

    storage.setItem(storageKeys.DEVELOPER_ENDLESS_ARCADE_SEED_KEY, JSON.stringify({
      boot: "game_over",
      mode: "fishing",
      summary: {
        mode: "fishing",
        score: "bad-score",
        progress: 6,
        tier: 4,
        combo: 19,
        durationMs: 61_200
      }
    }));
    const stringValueFallback = developer.readEndlessArcadeDeveloperSeed(storage);

    storage.setItem(storageKeys.DEVELOPER_ACTIVE_KEY, "postgame-bike-lap2");
    storage.setItem(storageKeys.DEVELOPER_ENDLESS_ARCADE_SEED_KEY, JSON.stringify({
      boot: "running",
      mode: "bike",
      bikeStartDistance: "lap-two"
    }));
    const bikeFallback = developer.readEndlessArcadeDeveloperSeed(storage);

    storage.setItem(storageKeys.DEVELOPER_ACTIVE_KEY, "postgame-bike-fail");
    storage.setItem(storageKeys.DEVELOPER_ENDLESS_ARCADE_SEED_KEY, JSON.stringify({
      boot: "game_over",
      mode: "bike",
      bikeStartDistance: 812.9,
      summary: {
        mode: "bike",
        score: 3_000_000_000,
        progress: 2_500_000_000,
        tier: 2_000_000,
        combo: 3_000_000,
        durationMs: 999_999_999,
        status: "x".repeat(80)
      }
    }));
    const normalized = developer.readEndlessArcadeDeveloperSeed(storage);

    recordCheck(
      "phone",
      "dev.seed-fallback-missing-fields",
      missingFieldFallback?.boot === "game_over"
        && missingFieldFallback.mode === "fishing"
        && missingFieldFallback.summary?.score === 9_240
        && missingFieldFallback.summary?.durationMs === 61_200,
      "empty postgame seed JSON must fall back to the checkpoint's authored game-over seed"
    );
    recordCheck(
      "phone",
      "dev.seed-fallback-invalid-values",
      stringValueFallback?.boot === "game_over"
        && stringValueFallback.mode === "fishing"
        && stringValueFallback.summary?.combo === 19
        && bikeFallback?.boot === "running"
        && bikeFallback.mode === "bike"
        && bikeFallback.bikeStartDistance === 790,
      "string-valued or non-finite postgame fields must fall back to the checkpoint seed, including bike start distance"
    );
    recordCheck(
      "phone",
      "dev.seed-normalize-large-values",
      normalized?.boot === "game_over"
        && normalized.mode === "bike"
        && normalized.bikeStartDistance === 812
        && normalized.summary?.score === 2_000_000_000
        && normalized.summary?.progress === 2_000_000_000
        && normalized.summary?.tier === 1_000_000
        && normalized.summary?.combo === 1_000_000
        && normalized.summary?.durationMs === 86_400_000
        && normalized.summary?.status?.length === 48,
      "finite oversized postgame numbers must normalize to the runtime clamps instead of crashing or rendering an empty shell"
    );
  } catch (error) {
    const message = error instanceof Error ? error.message : String(error);
    recordCheck("phone", "dev.seed-runtime", false, `developer seed runtime validation failed (${message})`);
  } finally {
    await rm(bundleDir, { recursive: true, force: true });
  }
}

async function validateArcadeEventRuntime() {
  if (sources.arcadeEvents === null) {
    recordCheck("phone", "p16.runtime-events", false, "P16 runtime event checks need EndlessArcadeSceneEvents.ts");
    return;
  }
  const bundleDir = await mkdtemp(path.join(tmpdir(), "endless-events-validator-"));
  try {
    const output = path.join(bundleDir, "bike-arcade-events.mjs");
    await build({
      entryPoints: [path.join(repositoryRoot, sourcePaths.arcadeEvents)],
      outfile: output,
      bundle: true,
      format: "esm",
      platform: "node",
      target: "node20"
    });
    const sceneEvents = await import(`${pathToFileURL(output).href}?v=${Date.now()}`);
    const calls = [];
    const eventBus = {
      emit(eventName, payload) {
        calls.push({ eventName, payload });
      }
    };

    const confirmRunning = sceneEvents.emitEndlessArcadeConfirmExitPause(eventBus, "running", "bike");
    const confirmPaused = sceneEvents.emitEndlessArcadeConfirmExitPause(eventBus, "paused", "bike");
    sceneEvents.emitEndlessArcadeRuntimeErrorPause(eventBus, "spotlight");
    const resumePendingPaused = sceneEvents.consumePendingEndlessArcadeResume(true, "paused");
    const resumePendingRunning = sceneEvents.consumePendingEndlessArcadeResume(resumePendingPaused.pending, "running");
    const resumePendingRunningTwice = sceneEvents.consumePendingEndlessArcadeResume(resumePendingRunning.pending, "running");
    const closeOnce = sceneEvents.createEndlessArcadeClosedEmitter(eventBus);
    const firstClose = closeOnce();
    const secondClose = closeOnce();

    const confirmCall = calls[0];
    const errorCall = calls[1];
    const closeCalls = calls.filter((entry) => entry.eventName === "endless_arcade_closed");

    recordCheck(
      "phone",
      "p16.confirm-exit-stop-event",
      confirmRunning === true
        && confirmPaused === false
        && confirmCall?.eventName === "endless_arcade_runtime_paused"
        && confirmCall?.payload?.mode === "bike"
        && confirmCall?.payload?.reason === "player",
      "confirm-exit must publish one paused stop cue only when leaving an actively running run"
    );
    recordCheck(
      "phone",
      "p16.error-stop-event",
      errorCall?.eventName === "endless_arcade_runtime_paused"
        && errorCall?.payload?.mode === "spotlight"
        && errorCall?.payload?.reason === "runtime_error",
      "runtime errors must publish a reusable paused stop cue with reason runtime_error"
    );
    recordCheck(
      "phone",
      "p16.confirm-exit-resume-pending",
      resumePendingPaused.pending === true
        && resumePendingPaused.shouldEmit === false
        && resumePendingRunning.pending === false
        && resumePendingRunning.shouldEmit === true
        && resumePendingRunningTwice.pending === false
        && resumePendingRunningTwice.shouldEmit === false,
      "confirm-exit keep-playing must hold a pending resume across paused/loading states and consume it exactly once on real running"
    );
    recordCheck(
      "phone",
      "p16.cleanup-close-event",
      firstClose === true
        && secondClose === false
        && closeCalls.length === 1
        && closeCalls[0]?.payload === undefined,
      "scene cleanup must emit exactly one endless_arcade_closed event even if cleanup paths repeat"
    );
  } catch (error) {
    const message = error instanceof Error ? error.message : String(error);
    recordCheck("phone", "p16.runtime-events", false, `P16 runtime event validation failed (${message})`);
  } finally {
    await rm(bundleDir, { recursive: true, force: true });
  }
}

async function validateInputLifecycleRuntime() {
  if (sources.arcadeRuntime === null || sources.rhythmEngine === null) {
    recordCheck(
      "phone",
      "p16.input-lifecycle-runtime",
      false,
      "input lifecycle runtime checks need EndlessArcadeRuntime.ts and RhythmFishingEngine.ts"
    );
    return;
  }
  const bundleDir = await mkdtemp(path.join(tmpdir(), "endless-input-lifecycle-validator-"));
  try {
    const runtimeOutput = path.join(bundleDir, "endless-runtime.mjs");
    const rhythmOutput = path.join(bundleDir, "rhythm-engine.mjs");
    await Promise.all([
      build({
        entryPoints: [path.join(repositoryRoot, sourcePaths.arcadeRuntime)],
        outfile: runtimeOutput,
        bundle: true,
        format: "esm",
        platform: "node",
        target: "node20"
      }),
      build({
        entryPoints: [path.join(repositoryRoot, sourcePaths.rhythmEngine)],
        outfile: rhythmOutput,
        bundle: true,
        format: "esm",
        platform: "node",
        target: "node20"
      })
    ]);
    const runtime = await import(`${pathToFileURL(runtimeOutput).href}?v=${Date.now()}`);
    const rhythm = await import(`${pathToFileURL(rhythmOutput).href}?v=${Date.now()}`);

    let releaseCount = 0;
    const released = runtime.releaseEndlessArcadeSceneControls({
      releaseEndlessControls() {
        releaseCount += 1;
      }
    });
    const absentRelease = runtime.releaseEndlessArcadeSceneControls(null);
    recordCheck(
      "phone",
      "p16.neutral-release-dispatch",
      released === true && absentRelease === false && releaseCount === 1,
      "host-to-scene neutral release dispatch must be executable, optional and exactly once per request"
    );

    let cleanupCount = 0;
    const cleaned = runtime.cleanupEndlessArcadeScene({
      cleanupEndlessScene() {
        cleanupCount += 1;
      }
    });
    const absentCleanup = runtime.cleanupEndlessArcadeScene(null);
    recordCheck(
      "phone",
      "p16.scene-cleanup-dispatch",
      cleaned === true && absentCleanup === false && cleanupCount === 1,
      "host-to-scene cleanup dispatch must execute before Phaser destruction and remain optional for shared scenes"
    );

    const lifecycleSlot = { current: 0 };
    let activeTicket = true;
    const strictProbeEpoch = runtime.beginEndlessArcadeLifecycleEpoch(lifecycleSlot);
    const realMountEpoch = runtime.beginEndlessArcadeLifecycleEpoch(lifecycleSlot);
    if (runtime.isCurrentEndlessArcadeLifecycleEpoch(lifecycleSlot, strictProbeEpoch)) {
      activeTicket = false;
    }
    const ticketSurvivedProbe = activeTicket;
    if (runtime.isCurrentEndlessArcadeLifecycleEpoch(lifecycleSlot, realMountEpoch)) {
      activeTicket = false;
    }
    recordCheck(
      "phone",
      "p16.strictmode-ticket-lifecycle",
      ticketSurvivedProbe === true && activeTicket === false,
      "StrictMode probe cleanup must not cancel the first real fishing ticket, while the current lifecycle cleanup still cancels it"
    );

    const holdChart = {
      durationSeconds: 3,
      notes: [{ beat: 1, action: "left", hold: 1 }]
    };
    const holdTiming = {
      beatSec: 1,
      leadSec: 1,
      assistLeadSec: 1,
      perfectMs: 70,
      greatMs: 130,
      goodMs: 190,
      assistGoodMs: 230,
      holdReleaseSlackSec: 0.08
    };
    const holdTension = {
      initial: 50,
      min: 0,
      max: 100,
      perfectRecover: 4,
      greatShift: 3,
      goodShift: 7,
      missPenalty: 14,
      wrongActionPenalty: 16,
      holdBreakPenalty: 12,
      warnLow: 20,
      warnHigh: 80,
      passMin: 15,
      passMax: 85,
      failSustainMs: 350,
      assistFailSustainMs: 700
    };

    let now = 0;
    let holdBrokenCount = 0;
    const engine = new rhythm.RhythmFishingEngine({
      chartId: "neutral-release",
      chart: holdChart,
      now: () => now,
      timing: holdTiming,
      tension: holdTension,
      events: {
        onNoteJudged() {},
        onHoldBroken() { holdBrokenCount += 1; },
        onWarning() {},
        onCompleted() {},
        onFailed() {}
      }
    });
    engine.start();
    now = 1;
    engine.handlePress("left");
    const heldBeforeRelease = engine.notes[0]?.holding === true;
    const tensionBeforeRelease = engine.tension;
    engine.releaseHeldInputs();
    recordCheck(
      "phone",
      "p16.fishing-neutral-hold-release",
      heldBeforeRelease
        && engine.notes[0]?.holding === false
        && holdBrokenCount === 0
        && engine.tension === tensionBeforeRelease,
      "fishing lifecycle release must clear an active hold without a hold-break event or tension penalty"
    );

    let earlyReleaseNow = 0;
    let earlyReleaseBrokenCount = 0;
    let earlyReleaseCompletedCount = 0;
    const earlyReleaseEngine = new rhythm.RhythmFishingEngine({
      chartId: "early-release",
      chart: holdChart,
      now: () => earlyReleaseNow,
      timing: holdTiming,
      tension: holdTension,
      events: {
        onNoteJudged() {},
        onHoldBroken() { earlyReleaseBrokenCount += 1; },
        onWarning() {},
        onCompleted() { earlyReleaseCompletedCount += 1; },
        onFailed() {}
      }
    });
    earlyReleaseEngine.start();
    earlyReleaseNow = 1;
    earlyReleaseEngine.handlePress("left");
    earlyReleaseNow = 1.2;
    earlyReleaseEngine.handleRelease("left");
    earlyReleaseNow = 3;
    earlyReleaseEngine.update();
    recordCheck(
      "phone",
      "p16.fishing-early-hold-release-completes",
      earlyReleaseEngine.judgedCount === earlyReleaseEngine.totalNotes
        && earlyReleaseEngine.notes[0]?.judgment === "miss"
        && earlyReleaseEngine.notes[0]?.holding === false
        && earlyReleaseBrokenCount === 1
        && earlyReleaseCompletedCount === 1
        && earlyReleaseEngine.phase === "completed",
      "an early gameplay release must count the already-judged hold once, apply one hold-break, and still complete the segment without a soft lock"
    );
  } catch (error) {
    const message = error instanceof Error ? error.stack ?? error.message : String(error);
    recordCheck(
      "phone",
      "p16.input-lifecycle-runtime",
      false,
      `input lifecycle runtime validation failed (${message})`
    );
  } finally {
    await rm(bundleDir, { recursive: true, force: true });
  }
}

let longRunReport = null;

async function validateLongRunRuntime() {
  try {
    longRunReport = await runEndlessArcadeLongRunValidation({ repositoryRoot });
    for (const check of longRunReport.checks) {
      recordCheck("longrun", check.id, check.passed, check.message);
    }
  } catch (error) {
    const message = error instanceof Error ? error.stack ?? error.message : String(error);
    recordCheck("longrun", "longrun.execution", false, `30-minute offline simulation failed (${message})`);
  }
}

await Promise.all([
  validateFishingRuleRuntime(),
  validateBikeRuleRuntime(),
  validateDeveloperSeedRuntime(),
  validateArcadeEventRuntime(),
  validateInputLifecycleRuntime(),
  validateLongRunRuntime()
]);
recordCheck(
  "rules",
  "rules.safe-integers",
  [sources.fishingRules, sources.spotlightRules, sources.bikeRules]
    .every((source) => matches(source, /Number\.isFinite|Number\.isSafeInteger|Math\.(?:min|max|trunc)/)),
  "all endless rule modules must bound generated or accumulated numeric values"
);

const phoneHomeRemoval = extractFunctionBlock(sources.phoneHomeApps, "canRemovePhoneHomeApp");
recordCheck(
  "phone",
  "home.fixed-slot",
  phoneHomeRemoval !== null
    && /appId\s*===\s*["']bike_arcade["'][\s\S]{0,80}return\s+false/.test(phoneHomeRemoval),
  "bike_arcade must be a fixed, non-removable phone-home slot"
);
recordCheck(
  "phone",
  "home.hidden-normalization",
  sources.phoneHomeApps?.includes("normalizeHiddenPhoneHomeAppIds") === true
    && phoneHomeRemoval !== null
    && !/appId\s*===\s*["']bike_arcade["'][\s\S]{0,80}return\s+true/.test(phoneHomeRemoval),
  "hidden-app normalization must restore the fixed bike_arcade slot"
);
recordCheck(
  "phone",
  "p13.unified-access",
  sources.phoneHome?.includes("access.endlessChallenge") === true
    && !/bikeArcadeUnlocked\s*&&\s*access\./.test(sources.phoneHome ?? ""),
  "P13 must derive bike_arcade availability from access.endlessChallenge only"
);
recordCheck(
  "phone",
  "p13.icon-contract",
  includesAll(sources.phoneHome, ["bike_arcade", "7:55", "游戏"]),
  "P13 must retain the bike_arcade slot, 7:55 icon copy and 游戏 label"
);
recordCheck(
  "phone",
  "p16.unified-access",
  (sources.arcadePage?.includes("access.endlessChallenge") === true
    || sources.arcadePage?.includes("selectMainStoryCompleted") === true)
    && !/state\.bikeArcade\.unlocked/.test(sources.arcadePage ?? ""),
  "P16 must reject entry through the same postgame authority and ignore legacy bike unlock"
);
recordCheck(
  "phone",
  "router.shared-gate",
  sources.sceneRouter?.includes("canEnterScene") === true
    && sources.sceneRouter?.includes("feature_access_denied") === true,
  "SceneRouter must keep canEnterScene as the route authority"
);
recordCheck(
  "phone",
  "dev.postgame-checkpoints",
  [
    "postgame-phone-home",
    "postgame-endless-hub",
    "postgame-fishing-start",
    "postgame-fishing-fail",
    "postgame-spotlight-start",
    "postgame-spotlight-fail",
    "postgame-bike-lap2",
    "postgame-bike-fail",
    'chapter: "寻人篇"',
    "DEVELOPER_ENDLESS_ARCADE_SEED_KEY"
  ].every((value) => sources.developerChannel?.includes(value) === true),
  "DeveloperChannel must expose the eight session-only postgame checkpoints and their endless runtime seed storage"
);
recordCheck(
  "phone",
  "dev.runtime-snapshot",
  sources.main?.includes("endlessArcadeRuntime: getEndlessArcadeDebugSnapshot()") === true
    && includesAll(sources.arcadePage, [
      "setEndlessArcadeDebugSnapshot",
      "clearEndlessArcadeDebugSnapshot",
      "endless_arcade_runtime_resumed"
    ])
    && sources.arcadeEvents?.includes("endless_arcade_runtime_paused") === true,
  "render_game_to_text must expose the endless arcade runtime snapshot and P16 must publish pause/resume diagnostics"
);
recordCheck(
  "phone",
  "dev.seed-sanitize",
  includesAll(sources.developerChannel, [
    "normalizeEndlessRunSummary",
    "Number.isFinite(candidate.score)",
    "Number.isFinite(candidate.durationMs)",
    "Math.trunc(bikeStartDistance)",
    "return fallback"
  ]),
  "DeveloperChannel must sanitize postgame seeds and fall back to the checkpoint contract on bad or stale JSON"
);
recordCheck(
  "phone",
  "p16.settlement-error-entry",
  includesAll(sources.arcadePage, [
    "const enterRuntimeError = useCallback(",
    'enterRuntimeError(\n          status.summary.mode,\n          new EndlessArcadeRuntimeError("boot_failed", status.summary.mode, "挑战结算票据已失效")',
    'enterRuntimeError(\n          status.summary.mode,\n          new EndlessArcadeRuntimeError("boot_failed", status.summary.mode, "挑战结算数据无效")'
  ]),
  "both game-over settlement early returns must funnel through the shared runtime error entry"
);

const pauseActiveGameBlock = extractFunctionBlock(sources.arcadeHost, "pauseActiveGame");
const neutralReleaseIndex = pauseActiveGameBlock?.indexOf("releaseActiveControls()") ?? -1;
const scenePauseIndex = pauseActiveGameBlock?.indexOf("game.scene.pause") ?? -1;
recordCheck(
  "phone",
  "p16.pause-releases-input-first",
  neutralReleaseIndex >= 0
    && scenePauseIndex > neutralReleaseIndex
    && sources.arcadeHost?.includes("releaseEndlessArcadeSceneControls(sceneRef.current)") === true
    && sources.arcadeHost?.includes('window.addEventListener("pagehide", handlePageHide)') === true,
  "host pause and pagehide paths must neutrally release the active scene before Phaser is paused"
);

recordCheck(
  "phone",
  "p16.pointer-lifecycle-fallback",
  includesAll(sources.arcadePage, [
    'window.addEventListener("pointerup", handlePointerUp)',
    'window.addEventListener("pointercancel", handlePointerCancel)',
    'window.addEventListener("blur", handleLifecycleRelease)',
    'window.addEventListener("pagehide", handleLifecycleRelease)',
    'document.addEventListener("visibilitychange", handleVisibilityChange)',
    'typeof target.setPointerCapture === "function"',
    'typeof target.releasePointerCapture === "function"',
    "releaseAllTouchInputsNeutral"
  ])
    && (extractFunctionBlock(sources.arcadePage, "trySetPointerCapture")?.includes("try {") ?? false),
  "touch controls and spotlight aim must retain a capability-safe global release fallback for pointer and lifecycle loss"
);

const bikeTouchMarkup = /<nav className="endless-arcade-touch-controls is-bike"[\s\S]*?>([\s\S]*?)<\/nav>/.exec(
  sources.arcadePage ?? ""
)?.[1] ?? "";
const runningTouchBranches = sources.arcadePage?.match(/phase === "running" && selectedMode ===/g) ?? [];
recordCheck(
  "phone",
  "p16.running-only-touch-bars",
  runningTouchBranches.length === 3
    && (bikeTouchMarkup.match(/<button\b/g) ?? []).length === 2
    && !bikeTouchMarkup.includes('beginTouchControl("primary"')
    && sources.arcadeCss?.includes(".endless-arcade-touch-controls.is-bike") === true
    && sources.arcadeCss?.includes("grid-template-columns: repeat(2, 1fr)") === true,
  "touch bars must render only while running, and bike must expose exactly two working lane controls"
);

recordCheck(
  "phone",
  "p16.spotlight-inspection-hook",
  sources.spotlightScene?.includes("window.render_endless_spotlight_to_text =") === true
    && sources.spotlightScene?.includes("window.advanceTime = advanceTime") === true
    && !sources.spotlightScene?.includes("window.render_game_to_text =")
    && sources.viteEnv?.includes("render_endless_spotlight_to_text?:") === true
    && sources.main?.includes("endlessArcadeRuntime: getEndlessArcadeDebugSnapshot()") === true,
  "spotlight inspection must keep advanceTime on a dedicated hook without replacing the application render_game_to_text snapshot"
);

recordCheck(
  "phone",
  "p16.scene-destroy-cleanup",
  [sources.fishingScene, sources.spotlightScene].every((source) => includesAll(source, [
    "Phaser.Scenes.Events.SHUTDOWN",
    "Phaser.Scenes.Events.DESTROY",
    "if (this.cleanupComplete) return",
    "this.cleanupComplete = true",
    "cleanupEndlessScene()"
  ]))
    && sources.arcadeHost?.includes("cleanupEndlessArcadeScene(sceneRef.current)") === true,
  "fishing and spotlight must run one idempotent cleanup through Host teardown, scene shutdown and direct Phaser destruction"
);

recordCheck(
  "phone",
  "p16.strictmode-lifecycle-guard",
  includesAll(sources.arcadePage, [
    "beginEndlessArcadeLifecycleEpoch(lifecycleEpochRef)",
    "isCurrentEndlessArcadeLifecycleEpoch(lifecycleEpochRef, epoch)",
    "queueMicrotask"
  ])
    && sources.arcadeRuntime?.includes("beginEndlessArcadeLifecycleEpoch") === true
    && sources.arcadeRuntime?.includes("isCurrentEndlessArcadeLifecycleEpoch") === true,
  "P16 must keep the executable lifecycle epoch guard that protects the first StrictMode fishing settlement ticket"
);

recordCheck(
  "compatibility",
  "fishing.story-api",
  includesAll(sources.qizhenFishing, [
    "QizhenFishingRhythmModel",
    "QIZHEN_FISHING_TIMING",
    "QIZHEN_FISHING_TENSION",
    '"locker_key"',
    '"net_frame"',
    '"fish"',
    '"paper"'
  ]),
  "the four authored Qizhen charts and story model API must remain available"
);
recordCheck(
  "compatibility",
  "fishing.monotonic-clock",
  sources.qizhenFishing?.includes("now: () => number") === true
    && !/Date\.now\s*\(/.test(sources.qizhenFishing ?? ""),
  "story fishing timing must keep the injected monotonic clock contract"
);
recordCheck(
  "compatibility",
  "spotlight.story-api",
  includesAll(sources.theaterSpotlight, [
    "THEATER_SPOTLIGHT_ROUNDS",
    "THEATER_SPOTLIGHT_SEQUENCE",
    "getTheaterSpotlightAssist",
    "getRequiredTheaterSpotlightLockMs"
  ]),
  "the authored three-round theater spotlight API must remain available"
);
recordCheck(
  "compatibility",
  "spotlight.story-controller",
  sources.theaterController?.includes("validateSpotlightAttempt") === true
    || sources.theaterController?.includes("validateTheaterSpotlightAttempt") === true,
  "the Chapter 3 theater controller must retain an explicit spotlight validation path"
);
recordCheck(
  "compatibility",
  "bike.story-goal",
  matches(sources.bikeRules, /BIKE_ARCADE_GOAL\s*=\s*755/)
    && includesAll(sources.bikeRules, ["advanceBikeDistance", "getCrossedBikeMilestones", "planBikeObstacleWave"]),
  "the original 755m story goal, milestones and solvable wave API must remain"
);
recordCheck(
  "compatibility",
  "bike.story-finish-event",
  sources.bikeRuntime?.includes('onFinish: (result: "won" | "lost"') === true
    && sources.bikeRuntime?.includes("BikeArcadeStoryBridgeDispatcher") === true
    && sources.bikeScene?.includes('type: "finish"') === true
    && sources.bikeScene?.includes("BIKE_ARCADE_GOAL") === true,
  "BikeRushScene must preserve the original won/lost story completion contract"
);

recordCheck(
  "delivery",
  "ci.endless-validator",
  sources.ci?.includes("npm run endless:validate") === true,
  "Web CI must run npm run endless:validate before typecheck and build"
);
if (sources.ci !== null && sources.ci.includes("npm run endless:validate")) {
  const endlessIndex = sources.ci.indexOf("npm run endless:validate");
  const typecheckIndex = sources.ci.indexOf("npm run typecheck");
  recordCheck(
    "delivery",
    "ci.order",
    typecheckIndex >= 0 && endlessIndex < typecheckIndex,
    "the endless validator must run before typecheck"
  );
} else {
  recordCheck("delivery", "ci.order", false, "CI ordering can be checked after endless:validate is wired");
}
recordCheck(
  "delivery",
  "audio.timeline",
  includesAll(sources.arcadeAudio, [
    "endless_arcade_runtime_requested",
    "endless_arcade_runtime_paused",
    "endless_arcade_runtime_resumed",
    "endless_arcade_runtime_finished",
    "endless_arcade_hub_returned",
    "endless_arcade_closed"
  ]),
  "endless arcade audio routing must cover start, pause, resume, finish, hub return and scene close"
);

const failures = checks.filter((check) => !check.passed);
const passed = checks.length - failures.length;
const groupOrder = Object.keys(GROUP_LABELS);

console.log("Endless arcade extractor self-test PASS object-return+comment+string+template-braces");
for (const line of longRunReport?.outputLines ?? []) console.log(line);
console.log(`Endless arcade contract summary checks=${checks.length} passed=${passed} failed=${failures.length}`);
for (const group of groupOrder) {
  const groupChecks = checks.filter((check) => check.group === group);
  const groupFailures = groupChecks.filter((check) => !check.passed);
  console.log(
    `- ${GROUP_LABELS[group]}: checks=${groupChecks.length}`
      + ` passed=${groupChecks.length - groupFailures.length}`
      + ` failed=${groupFailures.length}`
  );
}

if (failures.length > 0) {
  console.error("Endless arcade contract FAIL. Outstanding implementation gaps:");
  for (const failure of failures) {
    console.error(`- [${failure.group}/${failure.id}] ${failure.message}`);
  }
  process.exitCode = 1;
} else {
  console.log("Endless arcade contract PASS");
}
