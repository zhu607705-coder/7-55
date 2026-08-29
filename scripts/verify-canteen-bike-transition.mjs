import { readFile, readdir } from "node:fs/promises";
import path from "node:path";
import { fileURLToPath } from "node:url";

const repositoryRoot = path.resolve(path.dirname(fileURLToPath(import.meta.url)), "..");
const manifestRelativePath = "docs/assets/minimax-h3-canteen-755-theater/manifest.json";
const rejectedResultsRelativePath = "docs/assets/minimax-hailuo23-generation-20260822/task-results.json";
const manifestDirectory = path.dirname(path.join(repositoryRoot, manifestRelativePath));
const verifierRelativePath = "scripts/verify-canteen-bike-transition.mjs";

const runtimePaths = Object.freeze({
  controller: "src/modules/ChapterThreeCanteenController.ts",
  chaseOverlay: "src/scenes/rpg/CanteenChaseOverlay.tsx",
  host: "src/scenes/rpg/RpgGameHost.tsx",
  sharedRig: "src/scenes/rpg/canteen-chase/ChaseRiderRig.ts",
  chaseRenderer: "src/scenes/rpg/canteen-chase/ChaseThreeRenderer.ts",
  timeline: "src/scenes/rpg/canteen-chase/CanteenBikeTransitionTimeline.ts",
  transitionRenderer: "src/scenes/rpg/canteen-chase/CanteenBikeTransitionRenderer.ts",
  transitionOverlay: "src/scenes/rpg/CanteenBikeTransitionOverlay.tsx",
  transitionMedia: "src/scenes/rpg/canteen-chase/CanteenBikeTransitionMedia.ts"
});

const expectedTimelineSegments = Object.freeze({
  startGate: Object.freeze([
    ["O1", 0, 9],
    ["O2", 10, 40],
    ["O3", 41, 70],
    ["O4", 71, 90]
  ]),
  finishGate: Object.freeze([
    ["E1", 0, 9],
    ["E2", 10, 39],
    ["E3", 40, 90],
    ["E4", 91, 120],
    ["E5", 121, 132]
  ])
});

const checks = [];

function recordCheck(id, passed, message) {
  checks.push({ id, passed: Boolean(passed), message });
}

function sameMembers(actual, expected) {
  if (actual.length !== expected.length) return false;
  const left = [...actual].sort();
  const right = [...expected].sort();
  return left.every((value, index) => value === right[index]);
}

function compact(source) {
  return source.replace(/\s+/g, " ").trim();
}

function extractMethodBlock(source, methodName) {
  const methodMatch = new RegExp(`\\b${methodName}\\s*\\(`).exec(source);
  if (!methodMatch) return null;
  const openBrace = source.indexOf("{", methodMatch.index + methodMatch[0].length);
  if (openBrace < 0) return null;
  let depth = 0;
  for (let index = openBrace; index < source.length; index += 1) {
    if (source[index] === "{") depth += 1;
    if (source[index] === "}") {
      depth -= 1;
      if (depth === 0) return source.slice(methodMatch.index, index + 1);
    }
  }
  return null;
}

async function readRequiredText(relativePath, checkId) {
  try {
    const source = await readFile(path.join(repositoryRoot, relativePath), "utf8");
    recordCheck(checkId, true, `${relativePath} exists`);
    return source;
  } catch (error) {
    recordCheck(
      checkId,
      false,
      `${relativePath} is required (${error instanceof Error ? error.code ?? error.message : String(error)})`
    );
    return null;
  }
}

async function readOptionalText(relativePath) {
  try {
    return await readFile(path.join(repositoryRoot, relativePath), "utf8");
  } catch {
    return null;
  }
}

async function readJson(relativePath, checkId) {
  const source = await readRequiredText(relativePath, `${checkId}.file`);
  if (source === null) return null;
  try {
    const value = JSON.parse(source);
    recordCheck(`${checkId}.json`, true, `${relativePath} is valid JSON`);
    return value;
  } catch (error) {
    recordCheck(
      `${checkId}.json`,
      false,
      `${relativePath} is invalid JSON (${error instanceof Error ? error.message : String(error)})`
    );
    return null;
  }
}

async function readOptionalJson(relativePath, checkId) {
  const source = await readOptionalText(relativePath);
  if (source === null) return null;
  try {
    const value = JSON.parse(source);
    recordCheck(`${checkId}.json`, true, `${relativePath} is valid JSON when present`);
    return value;
  } catch (error) {
    recordCheck(
      `${checkId}.json`,
      false,
      `${relativePath} is invalid JSON (${error instanceof Error ? error.message : String(error)})`
    );
    return null;
  }
}

function validateManifestGate(gateName, gate, expectedFrames, expectedSegments) {
  recordCheck(
    `manifest.timeline.${gateName}.frames`,
    gate?.frames === expectedFrames,
    `${gateName} must declare exactly ${expectedFrames} frames (received ${String(gate?.frames)})`
  );

  const segments = Array.isArray(gate?.segments) ? gate.segments : [];
  recordCheck(
    `manifest.timeline.${gateName}.segment-count`,
    segments.length === expectedSegments.length,
    `${gateName} must contain ${expectedSegments.length} ordered segments (received ${segments.length})`
  );

  let nextFrame = 0;
  let inclusiveFrameCount = 0;
  for (let index = 0; index < expectedSegments.length; index += 1) {
    const [expectedId, expectedStart, expectedEnd] = expectedSegments[index];
    const segment = segments[index];
    const matches = segment?.id === expectedId
      && segment?.frameStart === expectedStart
      && segment?.frameEnd === expectedEnd;
    recordCheck(
      `manifest.timeline.${gateName}.${expectedId}`,
      matches,
      `${expectedId} must cover F${String(expectedStart).padStart(3, "0")}–F${String(expectedEnd).padStart(3, "0")}`
    );
    if (segment && Number.isInteger(segment.frameStart) && Number.isInteger(segment.frameEnd)) {
      if (segment.frameStart !== nextFrame) nextFrame = Number.NaN;
      if (segment.frameEnd >= segment.frameStart) {
        inclusiveFrameCount += segment.frameEnd - segment.frameStart + 1;
        if (!Number.isNaN(nextFrame)) nextFrame = segment.frameEnd + 1;
      }
    }
  }

  recordCheck(
    `manifest.timeline.${gateName}.continuity`,
    inclusiveFrameCount === expectedFrames && nextFrame === expectedFrames,
    `${gateName} segment ranges must be contiguous and total ${expectedFrames} inclusive frames`
  );

  const expectedDuration = expectedFrames / 24;
  recordCheck(
    `manifest.timeline.${gateName}.duration`,
    Number.isFinite(gate?.durationSeconds)
      && Math.abs(gate.durationSeconds - expectedDuration) <= 0.000001,
    `${gateName} duration must equal ${expectedFrames}/24 seconds`
  );
}

function getPngDimensions(buffer) {
  const signature = Buffer.from([137, 80, 78, 71, 13, 10, 26, 10]);
  if (buffer.length < 24 || !buffer.subarray(0, 8).equals(signature)) return null;
  return {
    width: buffer.readUInt32BE(16),
    height: buffer.readUInt32BE(20)
  };
}

async function validateAnchorFiles(manifest) {
  const declaredAnchors = [
    ...(Array.isArray(manifest?.existingAnchors) ? manifest.existingAnchors : []),
    ...(Array.isArray(manifest?.plannedAnchors) ? manifest.plannedAnchors : []),
    ...(Array.isArray(manifest?.offlineQaSubjects)
      ? manifest.offlineQaSubjects.map((anchorPath) => ({ path: anchorPath, status: "offline-qa" }))
      : [])
  ];
  let inspected = 0;
  const oversized = [];
  const invalidPng = [];

  for (const anchor of declaredAnchors) {
    if (typeof anchor?.path !== "string") continue;
    try {
      const buffer = await readFile(path.join(manifestDirectory, anchor.path));
      const dimensions = getPngDimensions(buffer);
      inspected += 1;
      if (!dimensions) {
        invalidPng.push(anchor.path);
      } else if (dimensions.width > 5760 || dimensions.height > 5760) {
        oversized.push(`${anchor.path}=${dimensions.width}x${dimensions.height}`);
      }
    } catch (error) {
      if (anchor.status !== "capture_pending") {
        invalidPng.push(`${anchor.path} (${error instanceof Error ? error.code ?? error.message : String(error)})`);
      }
    }
  }

  recordCheck(
    "anchors.physical-png",
    invalidPng.length === 0,
    invalidPng.length === 0
      ? `all ${inspected} present declared anchors are readable PNG files`
      : `unreadable or invalid declared PNG anchors: ${invalidPng.join(", ")}`
  );
  recordCheck(
    "anchors.physical-max-5760",
    oversized.length === 0,
    oversized.length === 0
      ? `${inspected} present declared anchors are at most 5760x5760`
      : `oversized anchors: ${oversized.join(", ")}`
  );
  return inspected;
}

async function collectSourceFiles(directory, ignoredAbsolutePaths = new Set()) {
  let entries;
  try {
    entries = await readdir(directory, { withFileTypes: true });
  } catch {
    return [];
  }
  const nested = await Promise.all(entries.map(async (entry) => {
    const absolutePath = path.join(directory, entry.name);
    if (ignoredAbsolutePaths.has(absolutePath)) return [];
    if (entry.isDirectory()) return collectSourceFiles(absolutePath, ignoredAbsolutePaths);
    return [".ts", ".tsx", ".js", ".mjs", ".json"].includes(path.extname(entry.name))
      ? [absolutePath]
      : [];
  }));
  return nested.flat();
}

async function scanActiveFiles(forbiddenNames) {
  const ignored = new Set([
    path.join(repositoryRoot, verifierRelativePath),
    path.join(repositoryRoot, "src/integrations/godot")
  ]);
  const files = [
    ...(await collectSourceFiles(path.join(repositoryRoot, "src"), ignored)),
    ...(await collectSourceFiles(path.join(repositoryRoot, "scripts"), ignored)),
    path.join(repositoryRoot, "package.json"),
    path.join(repositoryRoot, "vite.config.ts")
  ];
  const matches = [];
  for (const absolutePath of files) {
    let source;
    try {
      source = await readFile(absolutePath, "utf8");
    } catch {
      continue;
    }
    for (const forbiddenName of forbiddenNames) {
      if (source.includes(forbiddenName)) {
        matches.push(`${path.relative(repositoryRoot, absolutePath)} -> ${forbiddenName}`);
      }
    }
  }
  return matches;
}

function containsFormal700Handoff(source) {
  if (!source) return [];
  const matches = [];
  const patterns = [
    /\b(?:distance|distanceMeters|meter|meters)\b[^\n]{0,100}(?:===?|>=|<=|>|<)\s*700\b/i,
    /\b(?:handoff|transition|gate|media)[A-Za-z0-9_]*\b[^\n]{0,80}(?::|=)\s*700\b/i,
    /\b700\b[^\n]{0,100}\b(?:formal[_-]?handoff|media[_-]?handoff|start[_-]?transition|finish[_-]?transition)\b/i
  ];
  for (const [lineIndex, line] of source.split("\n").entries()) {
    if (patterns.some((pattern) => pattern.test(line))) {
      matches.push(`${lineIndex + 1}:${line.trim()}`);
    }
  }
  return matches;
}

function segmentObjectContains(source, id, frameStart, frameEnd) {
  if (!source) return false;
  const idIndex = source.search(new RegExp(`["']${id}["']`));
  if (idIndex < 0) return false;
  const window = source.slice(Math.max(0, idIndex - 180), idIndex + 360);
  return new RegExp(`frameStart\\s*:\\s*${frameStart}\\b`).test(window)
    && new RegExp(`frameEnd\\s*:\\s*${frameEnd}\\b`).test(window);
}

// Generation manifests and rejected-output archives are review evidence, not
// runtime dependencies. Validate them when a local art archive is present,
// while keeping the formal repository validator runnable without docs/assets.
const manifest = await readOptionalJson(manifestRelativePath, "manifest");
const rejectedResults = await readOptionalJson(rejectedResultsRelativePath, "rejected-media");

let inspectedAnchorCount = 0;
let rejectedMediaCount = 0;

if (manifest) {
  const authority = manifest.runtimeAuthority;
  recordCheck(
    "manifest.authority.payment",
    authority?.payment === "ChapterThreeCanteenController.payForBike",
    "payment authority must remain ChapterThreeCanteenController.payForBike"
  );
  recordCheck(
    "manifest.authority.ride-start",
    authority?.rideStart === "ChapterThreeCanteenController.startChase",
    "ride-start authority must be ChapterThreeCanteenController.startChase"
  );
  recordCheck(
    "manifest.authority.distance-lives",
    authority?.distanceAndLives === "CanteenChaseOverlay plus ChapterThreeCanteenController.resolveChaseAttempt",
    "distance and lives must stay under the chase overlay and controller"
  );
  recordCheck(
    "manifest.authority.arrival",
    authority?.arrival === "ChapterThreeCanteenController.completeChase",
    "theater arrival authority must remain ChapterThreeCanteenController.completeChase"
  );
  recordCheck(
    "manifest.authority.generated-media",
    authority?.generatedMediaOwnsProgress === false,
    "generated media must not own progress"
  );

  recordCheck(
    "manifest.timeline.fps",
    manifest.timeline?.fps === 24,
    `timeline must run at 24 FPS (received ${String(manifest.timeline?.fps)})`
  );
  validateManifestGate("startGate", manifest.timeline?.startGate, 91, expectedTimelineSegments.startGate);
  validateManifestGate("finishGate", manifest.timeline?.finishGate, 133, expectedTimelineSegments.finishGate);

  const ride = manifest.timeline?.playableRide;
  recordCheck(
    "manifest.ride.complete-0-755",
    ride?.distanceStartMeters === 0 && ride?.distanceEndMeters === 755,
    "the playable ride must remain the complete 0–755m interval"
  );
  recordCheck(
    "manifest.ride.700-debug-only",
    Array.isArray(ride?.debugOnlyMeters)
      && ride.debugOnlyMeters.length === 1
      && ride.debugOnlyMeters[0] === 700,
    "700m must be declared once and only as a debug-only distance"
  );

  const allAnchors = [
    ...(Array.isArray(manifest.existingAnchors) ? manifest.existingAnchors : []),
    ...(Array.isArray(manifest.plannedAnchors) ? manifest.plannedAnchors : [])
  ];
  const uploadAnchors = allAnchors.filter((anchor) => anchor?.hailuoUpload === true);
  recordCheck(
    "manifest.hailuo.upload-anchors",
    sameMembers(uploadAnchors.map((anchor) => anchor.id), ["A8", "A11"]),
    `A8 and A11 must be the only Hailuo upload anchors (received ${uploadAnchors.map((anchor) => anchor.id).join(", ") || "none"})`
  );

  const tasks = Array.isArray(manifest.hailuoTasks) ? manifest.hailuoTasks : [];
  recordCheck(
    "manifest.hailuo.task-set",
    sameMembers(tasks.map((task) => task?.id), ["M1", "M2"]),
    `Hailuo task set must be M1 and M2 (received ${tasks.map((task) => task?.id).join(", ") || "none"})`
  );
  for (const [taskId, anchorId] of [["M1", "A8"], ["M2", "A11"]]) {
    const task = tasks.find((candidate) => candidate?.id === taskId);
    const anchor = uploadAnchors.find((candidate) => candidate?.id === anchorId);
    recordCheck(
      `manifest.hailuo.${taskId}.frames`,
      task?.selectedFrames?.start === 0
        && task?.selectedFrames?.end === 29
        && task?.selectedFrames?.fps === 24,
      `${taskId} must select F000–F029 at 24 FPS`
    );
    recordCheck(
      `manifest.hailuo.${taskId}.input`,
      typeof anchor?.path === "string" && task?.input === anchor.path && anchor?.hailuoTask === taskId,
      `${taskId} must use ${anchorId} as its only uploaded first frame`
    );
  }

  const maximum = manifest.maxAcceptedCanvas;
  const declaredSizes = [
    ["maxAcceptedCanvas", maximum],
    ["imageContract.sceneSize", manifest.imageContract?.sceneSize],
    ["imageContract.subjectMaxSize", manifest.imageContract?.subjectMaxSize],
    ...allAnchors
      .filter((anchor) => Number.isFinite(anchor?.width) || Number.isFinite(anchor?.height))
      .map((anchor) => [`anchor ${anchor.id}`, anchor])
  ];
  const invalidDeclaredSizes = declaredSizes.filter(([, size]) => (
    !Number.isFinite(size?.width)
    || !Number.isFinite(size?.height)
    || size.width <= 0
    || size.height <= 0
    || size.width > 5760
    || size.height > 5760
  ));
  recordCheck(
    "manifest.anchor-max-5760",
    maximum?.width === 5760
      && maximum?.height === 5760
      && invalidDeclaredSizes.length === 0,
    invalidDeclaredSizes.length === 0
      ? "all declared canvas dimensions are positive and at most 5760x5760"
      : `invalid declared dimensions: ${invalidDeclaredSizes.map(([label]) => label).join(", ")}`
  );
  inspectedAnchorCount = await validateAnchorFiles(manifest);

  const invalidAnchor = allAnchors.find((anchor) => anchor?.id === "A755-invalid");
  recordCheck(
    "manifest.old-755.disabled",
    invalidAnchor?.path === "anchors/picture_05_chase_755m_1920x1080.png"
      && invalidAnchor?.status === "rejected-horizontal-theater-step"
      && invalidAnchor?.hailuoUpload === false
      && tasks.every((task) => task?.input !== invalidAnchor.path),
    "the old picture_05 755m anchor must remain rejected, non-uploadable and unused by M1/M2"
  );
  recordCheck(
    "manifest.old-755.superseded",
    Array.isArray(manifest.supersedes)
      && manifest.supersedes.includes("picture_05_chase_755m_as-generation-anchor"),
    "the manifest must explicitly supersede picture_05 as a generation anchor"
  );
}

const rejectedAssetNames = [];
if (rejectedResults) {
  const rawRejected = (Array.isArray(rejectedResults.tasks) ? rejectedResults.tasks : [])
    .filter((task) => ["canteen_mount_to_chase", "chase_finish_to_theater"].includes(task?.purpose));
  const assembledRejected = (Array.isArray(rejectedResults.assembled_outputs)
    ? rejectedResults.assembled_outputs
    : []).filter((output) => output?.user_acceptance === "rejected");
  rejectedMediaCount = rawRejected.length + assembledRejected.length;

  recordCheck(
    "rejected-media.raw-status",
    rawRejected.length === 2
      && rawRejected.every((task) => task?.visual_status === "rejected_by_user")
      && rawRejected.every((task) => task?.integration_allowed !== true),
    "both legacy canteen transition clips must remain rejected_by_user and may not allow integration"
  );
  recordCheck(
    "rejected-media.assembled-integration",
    assembledRejected.length >= 2
      && assembledRejected.every((output) => output?.integration_allowed === false),
    "every user-rejected assembled output must declare integration_allowed=false"
  );
  recordCheck(
    "rejected-media.runtime-integration",
    rejectedResults.runtime_integration === false,
    "the rejected legacy package must keep runtime_integration=false"
  );

  for (const item of [...rawRejected, ...assembledRejected]) {
    if (typeof item?.output === "string") rejectedAssetNames.push(path.basename(item.output));
    if (typeof item?.file === "string") rejectedAssetNames.push(path.basename(item.file));
  }
}

const activeForbiddenNames = [
  "picture_05_chase_755m_1920x1080.png",
  ...rejectedAssetNames
];
const activeForbiddenMatches = await scanActiveFiles(activeForbiddenNames);
recordCheck(
  "runtime.forbidden-media-imports",
  activeForbiddenMatches.length === 0,
  activeForbiddenMatches.length === 0
    ? "no active source, package or generation script references the disabled 755 anchor or rejected media"
    : `active forbidden media references: ${activeForbiddenMatches.join("; ")}`
);

const controllerSource = await readRequiredText(runtimePaths.controller, "runtime.controller.file");
const chaseOverlaySource = await readRequiredText(runtimePaths.chaseOverlay, "runtime.chase-overlay.file");
const hostSource = await readRequiredText(runtimePaths.host, "runtime.host.file");
const sharedRigSource = await readRequiredText(runtimePaths.sharedRig, "runtime.shared-rig.file");
const chaseRendererSource = await readRequiredText(runtimePaths.chaseRenderer, "runtime.chase-renderer.file");
const timelineSource = await readRequiredText(runtimePaths.timeline, "runtime.timeline.file");
const transitionRendererSource = await readRequiredText(
  runtimePaths.transitionRenderer,
  "runtime.transition-renderer.file"
);
const transitionOverlaySource = await readRequiredText(
  runtimePaths.transitionOverlay,
  "runtime.transition-overlay.file"
);
const transitionMediaSource = await readOptionalText(runtimePaths.transitionMedia);

if (controllerSource) {
  const payForBike = extractMethodBlock(controllerSource, "payForBike");
  const startChase = extractMethodBlock(controllerSource, "startChase");
  const resolveChaseAttempt = extractMethodBlock(controllerSource, "resolveChaseAttempt");
  const completeChase = extractMethodBlock(controllerSource, "completeChase");
  recordCheck(
    "runtime.controller.payment-gate",
    payForBike !== null
      && !/phase\s*:\s*["']chasing["']/.test(payForBike)
      && !/emit\s*\(\s*["']canteen_chase_started["']/.test(payForBike),
    "payForBike() must keep phase=chase_ready and must not emit canteen_chase_started"
  );
  recordCheck(
    "runtime.controller.payment-idempotent",
    payForBike !== null
      && /canteenHunt\.bikePaid/.test(payForBike)
      && /return\s+["']paid["']/.test(payForBike),
    "payForBike() must return paid without a second charge when bikePaid is already true"
  );
  recordCheck(
    "runtime.controller.start-chase",
    startChase !== null
      && /phase\s*:\s*["']chasing["']/.test(startChase)
      && /emit\s*\(\s*["']canteen_chase_started["']/.test(startChase),
    "startChase() must be the only payment-to-ride phase transition and emit canteen_chase_started"
  );
  recordCheck(
    "runtime.controller.victory-authority",
    resolveChaseAttempt !== null
      && /attempt\.mode\s*===\s*["']story["']/.test(resolveChaseAttempt)
      && /distance\s*===\s*CANTEEN_CHASE_GOAL/.test(resolveChaseAttempt)
      && /lives\s*>\s*0/.test(resolveChaseAttempt),
    "resolveChaseAttempt() must require story mode, exactly 755m through CANTEEN_CHASE_GOAL, and lives > 0"
  );
  recordCheck(
    "runtime.controller.arrival-authority",
    completeChase !== null
      && /phase\s*:\s*["']theater_reached["']/.test(completeChase)
      && /rpgCheckpoint\s*:\s*["']campus_theater_junction["']/.test(completeChase),
    "completeChase() must remain the theater_reached and campus_theater_junction writer"
  );
}

if (chaseOverlaySource) {
  const oldContinuationSymbols = [
    "onContinue",
    "onContinueRef",
    "theaterTransitionedRef",
    "theaterTransitionTimerRef",
    "enterTheater",
    "scheduleTheaterEntry"
  ].filter((symbol) => new RegExp(`\\b${symbol}\\b`).test(chaseOverlaySource));
  recordCheck(
    "runtime.chase-overlay.no-old-continuation",
    oldContinuationSymbols.length === 0,
    oldContinuationSymbols.length === 0
      ? "the old 900ms theater continuation is absent"
      : `remove old theater continuation symbols: ${oldContinuationSymbols.join(", ")}`
  );
  recordCheck(
    "runtime.chase-overlay.exact-run-start",
    /distance\s*:\s*0\b/.test(chaseOverlaySource)
      && /lives\s*:\s*MAX_LIVES\b/.test(chaseOverlaySource)
      && /lane\s*:\s*1\b/.test(chaseOverlaySource)
      && /GOAL_DISTANCE\s*=\s*755\b/.test(chaseOverlaySource),
    "the chase runtime must initialize at distance 0, goal 755, lives 3 and lane 1"
  );
}

if (hostSource) {
  const hostCompact = compact(hostSource);
  const startSelector = /const canteenStartTransitionActive\s*=/.test(hostSource)
    && hostCompact.includes('state.canteenHunt.phase === "chase_ready"')
    && /canteenStartTransitionActive[\s\S]{0,260}canteenHunt\.bikePaid/.test(hostSource);
  const rideSelector = /const canteenChaseRunActive\s*=/.test(hostSource)
    && hostCompact.includes('state.canteenHunt.phase === "chasing"')
    && /canteenChaseRunActive[\s\S]{0,260}!state\.canteenHunt\.chaseCompleted/.test(hostSource);
  const finishSelector = /const canteenFinishTransitionActive\s*=/.test(hostSource)
    && /canteenFinishTransitionActive[\s\S]{0,360}state\.canteenHunt\.chaseCompleted/.test(hostSource)
    && /canteenFinishTransitionActive[\s\S]{0,420}chaseBestDistance\s*>=\s*755/.test(hostSource);
  recordCheck(
    "runtime.host.start-selector",
    startSelector,
    "RpgGameHost must declare the chase_ready + bikePaid start-transition selector"
  );
  recordCheck(
    "runtime.host.ride-selector",
    rideSelector,
    "RpgGameHost must declare the chasing + !chaseCompleted ride selector"
  );
  recordCheck(
    "runtime.host.finish-selector",
    finishSelector,
    "RpgGameHost must declare the completed 755m finish-transition selector"
  );
  recordCheck(
    "runtime.host.mutually-exclusive-layer",
    /\bcanteenExclusiveActive\b/.test(hostSource)
      && /data-canteen-handoff\s*=/.test(hostSource)
      && /<CanteenBikeTransitionOverlay\b/.test(hostSource)
      && /stage\s*=\s*["']start["']/.test(hostSource)
      && /stage\s*=\s*["']finish["']/.test(hostSource),
    "RpgGameHost must render one start, ride or finish layer and expose data-canteen-handoff"
  );
  recordCheck(
    "runtime.host.controller-endpoints",
    /canteenController\.startChase\s*\(/.test(hostSource)
      && /canteenController\.resolveChaseAttempt\s*\(/.test(hostSource)
      && /canteenController\.completeChase\s*\(/.test(hostSource),
    "RpgGameHost must connect start, ride and finish completion to the three controller methods"
  );
}

if (sharedRigSource) {
  const requiredRigMembers = [
    "bicycleRoot",
    "riderRoot",
    "rightHand",
    "rightFoot",
    "rightGrip",
    "rightBrakeLever",
    "crank",
    "rightPedal",
    "chain"
  ];
  const missingMembers = requiredRigMembers.filter((member) => !new RegExp(`\\b${member}\\b`).test(sharedRigSource));
  recordCheck(
    "runtime.shared-rig.contract",
    /\bcreateChaseRiderRig\b/.test(sharedRigSource) && missingMembers.length === 0,
    missingMembers.length === 0
      ? "shared rider rig exports the canonical builder and macro pivots"
      : `shared rider rig is missing: ${missingMembers.join(", ")}`
  );
  const ridePoseStart = sharedRigSource.indexOf('if (pose === "ride")');
  const standPoseStart = sharedRigSource.indexOf('if (pose === "stand_left")', ridePoseStart);
  const ridePoseSource = ridePoseStart >= 0 && standPoseStart > ridePoseStart
    ? sharedRigSource.slice(ridePoseStart, standPoseStart)
    : "";
  recordCheck(
    "runtime.shared-rig.ride-ik-authority",
    /CHASE_RIDER_GEAR_RATIO\s*=\s*2\.6\b/.test(sharedRigSource)
      && /rig\.crank\.rotation\.x\s*=\s*pedalPhase/.test(ridePoseSource)
      && /enforceChaseRiderContactConstraints\(rig\)/.test(ridePoseSource)
      && !/rig\.(?:leftLeg|rightLeg)\.rotation\.x\s*=/.test(ridePoseSource),
    "ride pose must let crank contacts plus two-bone IK own the hip-knee-foot chain"
  );
  recordCheck(
    "runtime.shared-rig.pedal-ankle-orientation",
    /function\s+alignPedalFootOrientation\s*\(/.test(sharedRigSource)
      && /foot\.quaternion\.copy\(parentWorldQuaternion\.invert\(\)\.multiply\(bicycleWorldQuaternion\)\)/.test(sharedRigSource)
      && /foot\.position\.add\(pedalInParent\.sub\(currentContactInParent\)\)/.test(sharedRigSource)
      && /rig\.leftFoot\.rotation\.set\(0,\s*0,\s*0\)/.test(sharedRigSource)
      && /rig\.rightFoot\.rotation\.set\(0,\s*0,\s*0\)/.test(sharedRigSource)
      && /measureChaseRiderFootOrientationError/.test(sharedRigSource),
    "pedal-bound shoes must stay aligned with the bicycle while preserving sole contact"
  );
}

if (chaseRendererSource) {
  recordCheck(
    "runtime.chase-renderer.shared-rig",
    /\bcreateChaseRiderRig\b/.test(chaseRendererSource)
      && !/\bfunction\s+buildRider\s*\(/.test(chaseRendererSource),
    "ChaseThreeRenderer must consume createChaseRiderRig() and remove its local buildRider()"
  );
  recordCheck(
    "runtime.chase-renderer.distance-driven-pedals",
    /CHASE_RIDER_GEAR_RATIO/.test(chaseRendererSource)
      && /distanceDelta\s*\*\s*WORLD_PER_METER\s*\/\s*CHASE_RIDER_WHEEL_RADIUS/.test(chaseRendererSource)
      && /crankDelta\s*=\s*wheelSpin\s*\/\s*CHASE_RIDER_GEAR_RATIO/.test(chaseRendererSource)
      && /pedalPhaseRadians\s*=\s*\(this\.pedalPhaseRadians\s*\+\s*crankDelta\)\s*%\s*TWO_PI/.test(chaseRendererSource)
      && /chasePedalCadenceRpm/.test(chaseRendererSource),
    "live crank phase and cadence must derive from traveled distance through one gear ratio"
  );
  recordCheck(
    "runtime.chase-renderer.stable-steering",
    /function\s+frameResponse\s*\(/.test(chaseRendererSource)
      && /\bsmoothedLaneVelocity\b/.test(chaseRendererSource)
      && /frameResponse\(LANE_POSITION_RESPONSE,\s*deltaSeconds\)/.test(chaseRendererSource)
      && /frameResponse\(LANE_VELOCITY_RESPONSE,\s*deltaSeconds\)/.test(chaseRendererSource)
      && /frameResponse\(STEERING_RESPONSE,\s*deltaSeconds\)/.test(chaseRendererSource)
      && /frameResponse\(CAMERA_FOLLOW_RESPONSE,\s*deltaSeconds\)/.test(chaseRendererSource)
      && !/\blateralLag\b/.test(chaseRendererSource),
    "lane position, steering and camera follow must use frame-rate-independent responses without additive camera counter-shift"
  );
}

if (timelineSource) {
  recordCheck(
    "runtime.timeline.fps",
    /\bTRANSITION_FPS\b[^\n=]*=\s*24\b/.test(timelineSource),
    "the runtime transition timeline must export TRANSITION_FPS=24"
  );
  for (const [gateName, segments] of Object.entries(expectedTimelineSegments)) {
    for (const [id, frameStart, frameEnd] of segments) {
      recordCheck(
        `runtime.timeline.${gateName}.${id}`,
        segmentObjectContains(timelineSource, id, frameStart, frameEnd),
        `runtime ${id} must cover F${String(frameStart).padStart(3, "0")}–F${String(frameEnd).padStart(3, "0")}`
      );
    }
  }
}

if (transitionRendererSource) {
  recordCheck(
    "runtime.transition-renderer.shared-rig",
    /\bcreateChaseRiderRig\b/.test(transitionRendererSource),
    "CanteenBikeTransitionRenderer must use the same shared rider rig as the chase"
  );
}

if (transitionOverlaySource) {
  recordCheck(
    "runtime.transition-overlay.finish-once",
    /\bfinishOnce\b/.test(transitionOverlaySource)
      && /\bonComplete\b/.test(transitionOverlaySource)
      && /\btimeout\b/.test(transitionOverlaySource),
    "the transition overlay must converge ended/fallback paths through finishOnce() and onComplete"
  );
}

const presentationSources = [
  [runtimePaths.timeline, timelineSource],
  [runtimePaths.transitionRenderer, transitionRendererSource],
  [runtimePaths.transitionOverlay, transitionOverlaySource],
  [runtimePaths.transitionMedia, transitionMediaSource]
];
const forbiddenPresentationAuthority = ["GameStore", "SaveStore", "resolveChaseAttempt", "completeChase"];
const presentationAuthorityViolations = presentationSources.flatMap(([relativePath, source]) => {
  if (!source) return [];
  return forbiddenPresentationAuthority
    .filter((symbol) => new RegExp(`\\b${symbol}\\b`).test(source))
    .map((symbol) => `${relativePath} -> ${symbol}`);
});
recordCheck(
  "runtime.generated-media.presentation-only",
  presentationAuthorityViolations.length === 0,
  presentationAuthorityViolations.length === 0
    ? "timeline, renderer, overlay and optional media adapter contain no direct progress authority"
    : `presentation code must not reference controller or save authority: ${presentationAuthorityViolations.join("; ")}`
);

const formal700Sources = [
  [runtimePaths.controller, controllerSource],
  [runtimePaths.chaseOverlay, chaseOverlaySource],
  [runtimePaths.host, hostSource],
  [runtimePaths.timeline, timelineSource],
  [runtimePaths.transitionRenderer, transitionRendererSource],
  [runtimePaths.transitionOverlay, transitionOverlaySource]
];
const formal700Matches = formal700Sources.flatMap(([relativePath, source]) => (
  containsFormal700Handoff(source).map((match) => `${relativePath}:${match}`)
));
recordCheck(
  "runtime.no-formal-700m-handoff",
  formal700Matches.length === 0,
  formal700Matches.length === 0
    ? "700m does not appear in a runtime presentation handoff condition"
    : `formal 700m handoff candidates: ${formal700Matches.join("; ")}`
);

const failures = checks.filter((check) => !check.passed);
const passed = checks.length - failures.length;
const uploadIds = manifest
  ? [...(manifest.existingAnchors ?? []), ...(manifest.plannedAnchors ?? [])]
    .filter((anchor) => anchor?.hailuoUpload === true)
    .map((anchor) => anchor.id)
    .join(",")
  : "unavailable";

console.log(
  `Canteen bike transition contract summary fps=${String(manifest?.timeline?.fps ?? "?")}`
  + ` startFrames=${String(manifest?.timeline?.startGate?.frames ?? "?")}`
  + ` finishFrames=${String(manifest?.timeline?.finishGate?.frames ?? "?")}`
  + ` hailuoUploads=${uploadIds || "none"}`
  + ` inspectedAnchors=${inspectedAnchorCount}`
  + ` rejectedMedia=${rejectedMediaCount}`
);

if (failures.length > 0) {
  console.error(`Canteen bike transition contract FAIL checks=${checks.length} passed=${passed} failed=${failures.length}`);
  for (const failure of failures) {
    console.error(`- [${failure.id}] ${failure.message}`);
  }
  process.exitCode = 1;
} else {
  console.log(`Canteen bike transition contract PASS checks=${checks.length} passed=${passed} failed=0`);
}
