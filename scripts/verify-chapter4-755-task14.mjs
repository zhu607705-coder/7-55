import fs from "node:fs";
import path from "node:path";
import { fileURLToPath } from "node:url";
import { createServer } from "vite";

const errors = [];
let assertionCount = 0;

function assert(condition, message) {
  assertionCount += 1;
  if (!condition) errors.push(message);
}

function sameJson(actual, expected) {
  return JSON.stringify(actual) === JSON.stringify(expected);
}

class MemoryStorage {
  #values = new Map();
  get length() { return this.#values.size; }
  clear() { this.#values.clear(); }
  getItem(key) { return this.#values.has(key) ? this.#values.get(key) : null; }
  key(index) { return [...this.#values.keys()][index] ?? null; }
  removeItem(key) { this.#values.delete(key); }
  setItem(key, value) { this.#values.set(String(key), String(value)); }
}

const STABLE_IDS = [
  "c4-755-opening",
  "c4-755-hall-clock",
  "c4-755-bakery-1225",
  "c4-755-room204-1850",
  "c4-755-maintenance-2245",
  "c4-755-blackout-0754",
  "c4-755-light-grid",
  "c4-755-chase",
  "c4-755-final-minute",
  "c4-755-checkin",
  "c4-755-complete"
];

const EXPECTED_SEEDS = {
  "c4-755-opening": ["opening_handoff", "2245_opening", "A1", "a1_lobby"],
  "c4-755-hall-clock": ["hall_clock_inspection", "2245_opening", "A1", "a1_hall_clock"],
  "c4-755-bakery-1225": ["bakery_hour_hand", "1225_bakery", "A1", "a1_bakery"],
  "c4-755-room204-1850": ["room204_restore", "1850_evening", "A3", "a3_reference_classroom"],
  "c4-755-maintenance-2245": ["maintenance_repair", "2245_maintenance", "A1", "a1_lobby"],
  "c4-755-blackout-0754": ["blackout_light_grid", "0754_blackout", "A1", "a1_lobby"],
  "c4-755-light-grid": ["blackout_light_grid", "0754_blackout", "A1", "a1_power_panel"],
  "c4-755-chase": ["final_chase", "0754_blackout", "A1", "a1_lobby"],
  "c4-755-final-minute": ["final_minute_recovery", "0754_blackout", "A2", "a2_room_202"],
  "c4-755-checkin": ["morning_checkin", "0755_morning", "A1", "a1_checkin"],
  "c4-755-complete": ["exterior_closure", "0755_morning", "A1", "a1_exterior"]
};

const LEGACY_C4_ALIASES = {
  "c4-clock-calibration": "c4-755-opening",
  "c4-prologue": "c4-755-opening",
  "c4-prologue-lake-exit": "c4-755-opening",
  "c4-prologue-arcade": "c4-755-opening",
  "c4-prologue-entrance": "c4-755-opening",
  "c4-prologue-lobby": "c4-755-opening",
  "c4-prologue-closing": "c4-755-opening",
  "c4-prologue-task-card": "c4-755-opening",
  "c4-prologue-done": "c4-755-opening",
  "c4-arrival": "c4-755-opening",
  "c4-airflow": "c4-755-opening",
  "c4-main-elevator": "c4-755-hall-clock",
  "c4-wechat-notice": "c4-755-hall-clock",
  "c4-wechat-elevator-audio": "c4-755-hall-clock",
  "c4-elevator-aligned": "c4-755-hall-clock",
  "c4-a2-arrival": "c4-755-room204-1850",
  "c4-wechat-student-route": "c4-755-room204-1850",
  "c4-a2-schedule-observed": "c4-755-room204-1850",
  "c4-a3-wayfinding": "c4-755-room204-1850",
  "c4-wechat-wayfinding": "c4-755-room204-1850",
  "c4-a2-return-window": "c4-755-room204-1850",
  "c4-stair-echo": "c4-755-maintenance-2245",
  "c4-clock-intro": "c4-755-maintenance-2245",
  "c4-clock-coarse": "c4-755-maintenance-2245",
  "c4-clock-precision": "c4-755-maintenance-2245",
  "c4-clock-release": "c4-755-maintenance-2245"
};

const content = JSON.parse(fs.readFileSync(
  new URL("../src/data/chapter4-755.content.json", import.meta.url),
  "utf8"
));
const audio = JSON.parse(fs.readFileSync(
  new URL("../src/data/chapter4-755.audio.json", import.meta.url),
  "utf8"
));
const source = (relative) => fs.readFileSync(new URL(relative, import.meta.url), "utf8");
const questStripSource = source("../src/components/QuestClueStrip.tsx");
const appSource = source("../src/App.tsx");
const hostSource = source("../src/scenes/rpg/RpgGameHost.tsx");
const sceneSource = source("../src/scenes/rpg/ChapterFourTemporalMazeScene.ts");
const debugSource = source("../src/scenes/rpg/RpgRuntimeDebug.ts");
const audioDirectorSource = source("../src/modules/AudioDirector.ts");
const presentationDirectorSource = source("../src/modules/PresentationDirector.ts");
const closureSource = source("../src/modules/ChapterFourClosureContract.ts");
const mazeProjectionSource = source("../src/modules/ChapterFourMazeProjection.ts");
const runtimeValidatorSource = source("./verify-chapter4-755-runtime.mjs");
const task14ValidatorSource = source("./verify-chapter4-755-task14.mjs");
const ciSource = source("../.github/workflows/web-ci.yml");

const hints = Object.values(content.tasks)
  .map((task) => task?.hint)
  .filter((hint) => typeof hint === "string" && hint.length > 0);
assert(sameJson(hints, [
  "暗色模式里，椅子记得自己原来朝哪边。",
  "锈掉的东西，先别急着讲道理。",
  "不用全亮，能走就行。"
]), "Task 14 must expose exactly the three approved hints");
assert(!Object.prototype.hasOwnProperty.call(content.tasks, "repair_hall_clock"), "removed hall-clock hint task must stay absent");
assert(/\[quest\.id, quest\.objective\]/.test(questStripSource), "QuestClueStrip must reset local state on quest id/objective changes");
assert(/setHintCount\(0\)/.test(questStripSource) && /setOpen\(false\)/.test(questStripSource), "QuestClueStrip must reset hint count and drawer state");
assert(/questIncomplete\s*=\s*quest\.completed\s*<\s*quest\.total/.test(questStripSource), "quest navigation must stay hidden after the current quest is complete");
assert(/hasNavigationHandler\s*=\s*Boolean\(onNavigate\s*\|\|\s*\(router\s*&&\s*quest\.recommendedScene\)\)/.test(questStripSource), "quest navigation must require an executable callback or router target");
assert(/redundantRpgNavigation\s*=\s*variant\s*!==\s*"phone"\s*&&\s*quest\.targetSurface\s*===\s*"rpg"/.test(questStripSource), "RPG task bars must suppress same-surface navigation");
assert(/showNavigation\s*=\s*questIncomplete\s*&&\s*hasNavigationHandler\s*&&\s*!redundantRpgNavigation/.test(questStripSource), "quest navigation visibility must combine completion, handler, and surface guards");
assert(/events\.emit\("quest_navigation_requested",\s*\{\s*questId:\s*quest\.id,\s*targetSurface:\s*quest\.targetSurface,\s*recommendedScene:\s*quest\.recommendedScene\s*\}\)/.test(questStripSource), "quest navigation must emit the stable request envelope");
const navigationEventIndex = questStripSource.indexOf('events.emit("quest_navigation_requested"');
const navigationCallbackIndex = questStripSource.indexOf("if (onNavigate)", navigationEventIndex);
const navigationFallbackIndex = questStripSource.indexOf("else if (router && quest.recommendedScene)", navigationCallbackIndex);
const navigationCloseIndex = questStripSource.indexOf("setOpen(false);", navigationFallbackIndex);
assert(
  navigationEventIndex >= 0
    && navigationCallbackIndex > navigationEventIndex
    && navigationFallbackIndex > navigationCallbackIndex
    && navigationCloseIndex > navigationFallbackIndex,
  "quest navigation must emit first, prefer onNavigate, then fall back to the recommended Scene, and close the drawer"
);
assert(
  /navigationLabel\s*=\s*quest\.targetSurface\s*===\s*"rpg"\s*\?\s*"返回任务现场"\s*:\s*"前往相关界面"/.test(questStripSource)
    && /className="quest-task-navigate"/.test(questStripSource)
    && /\{navigationLabel\}/.test(questStripSource),
  "quest navigation must distinguish returning to the RPG from opening a phone destination"
);
assert(!/quest\.steps/.test(questStripSource), "QuestClueStrip must not read or reveal future quest steps");
assert(
  /showTaskBar=\{state\.rpgScene\s*===\s*"duan_yongping_temporal_maze"\}/.test(appSource),
  "desktop Chapter 4 must mount the shared RPG task bar through its Host without duplicating other scenes"
);
assert(
  /RUNTIME_MANAGED_DYNAMIC_COLLISION_IDS[\s\S]*?"a1_guard_chase_body"[\s\S]*?"a2_guard_chase_body"/.test(sceneSource)
    && /RUNTIME_MANAGED_DYNAMIC_COLLISION_IDS\.has\(projectedId\)/.test(sceneSource),
  "the plate contract must recognize both runtime-managed final-chase guard bodies"
);
assert(
  /automaticThresholdTarget[\s\S]*?payload\.targetId === thresholdContract\.id[\s\S]*?state\.chapter4\.phase === "final_chase"[\s\S]*?this\.currentFloor === 2[\s\S]*?this\.finalChaseInsideFinish[\s\S]*?this\.finalChaseState\?\.phase === "finish_pending"[\s\S]*?isChapterFour755TargetStateActive\(state, thresholdContract\)/.test(sceneSource),
  "the automatic 202 finish threshold must answer spatial attestation only from the real A2 finish-pending runtime"
);
assert(
  /private configureCameraForCurrentFloor\(\): void \{[\s\S]*?this\.physics\.world\.setBounds\(\s*floor\.offsetX,\s*0,\s*FLOOR_SIZE\.width,\s*FLOOR_SIZE\.height,\s*true,\s*true,\s*true,\s*true\s*\)[\s\S]*?this\.cameras\.main\.setBounds\(floor\.offsetX, 0, FLOOR_SIZE\.width, FLOOR_SIZE\.height\)/.test(sceneSource),
  "every active Chapter 4 floor must apply matching four-sided physics and camera bounds"
);
assert(/setCollideWorldBounds\(true\)/.test(sceneSource), "the Chapter 4 player must collide with the active floor world bounds");
assert(
  !mazeProjectionSource.includes('collisionIds.push("a1_blackout_service_barrier")'),
  "the projection must not advertise a blackout service barrier without an authoritative runtime entity"
);

const chapterFourCiCommands = [
  "npm run chapter4:validate-assets",
  "npm run chapter4:validate-story",
  "npm run chapter4:validate-topology",
  "npm run chapter4:validate-runtime",
  "npm run chapter4:validate-task14"
];
const campusCiIndex = ciSource.indexOf("npm run map:zijingang");
const facingCiIndex = ciSource.indexOf("npm run verify:rpg-facing-agnostic");
const typecheckCiIndex = ciSource.indexOf("npm run typecheck");
const chapterFourCiIndexes = chapterFourCiCommands.map((command) => ciSource.indexOf(command));
assert(
  campusCiIndex >= 0
    && facingCiIndex > campusCiIndex
    && typecheckCiIndex >= 0
    && chapterFourCiIndexes.every((index) => index >= 0)
    && facingCiIndex < chapterFourCiIndexes[0]
    && chapterFourCiIndexes.every((index, position) => position === 0 || chapterFourCiIndexes[position - 1] < index)
    && chapterFourCiIndexes.at(-1) < typecheckCiIndex,
  "CI must run the global facing contract and five read-only Chapter 4 gates after the campus contract and before typecheck"
);
const chapterFourCiBlock = ciSource.slice(chapterFourCiIndexes[0], typecheckCiIndex);
assert(!/(?:generate|rebuild|build):chapter4|chapter4:(?:generate|rebuild|build)/.test(chapterFourCiBlock), "CI Chapter 4 validation block must not invoke asset generators");
assert(/server:\s*\{\s*middlewareMode:\s*true,\s*ws:\s*false\s*\}/.test(runtimeValidatorSource), "runtime validator must disable the Vite WebSocket server");
assert(/server:\s*\{\s*middlewareMode:\s*true,\s*ws:\s*false\s*\}/.test(task14ValidatorSource), "Task 14 validator must disable the Vite WebSocket server");

const expectedAudioEvents = [
  "chapter4_time_swap_committed",
  "chapter4_bakery_conveyor_stop",
  "room204_drawer_opened",
  "maintenance_cart_roll_started",
  "clock_gear_repaired",
  "blackout_committed",
  "power_zone_toggled",
  "final_chase_started",
  "final_chase_failed",
  "final_chase_succeeded",
  "final_minute_installed",
  "morning_checkin_card_accepted",
  "morning_checkin_paper_accepted",
  "morning_checkin_completed",
  "chapter4_755_scene_closed"
];
assert(audio.version === 1, "Task 14 audio timeline version must be 1");
assert(sameJson(Object.keys(audio.events), expectedAudioEvents), "Task 14 audio timeline event set/order changed");
const audioAssetNames = new Set();
const audioRoot = new URL("../src/assets/audio/", import.meta.url);
const pendingAudioDirs = [fileURLToPath(audioRoot)];
while (pendingAudioDirs.length > 0) {
  const directory = pendingAudioDirs.pop();
  for (const entry of fs.readdirSync(directory, { withFileTypes: true })) {
    const entryPath = path.join(directory, entry.name);
    if (entry.isDirectory()) pendingAudioDirs.push(entryPath);
    else if (entry.name.endsWith(".mp3")) audioAssetNames.add(entry.name.slice(0, -4));
  }
}
for (const [eventId, event] of Object.entries(audio.events)) {
  assert(Array.isArray(event.cues) && event.cues.length > 0, `${eventId} must define cues`);
  for (const cue of event.cues ?? []) {
    assert(["music", "sfx", "voice", "text"].includes(cue.channel), `${eventId} has an invalid channel`);
    if (cue.asset) assert(audioAssetNames.has(cue.asset), `${eventId} references missing ${cue.asset}.mp3`);
  }
}
assert(!Object.keys(audio.events).some((id) => /exterior_closure|acknowledge_exterior/.test(id)), "official exterior closure must have zero audio cues while reference is null");
assert(/CHAPTER_FOUR_APPROVED_CLOSURE_REFERENCE[\s\S]*?= null/.test(closureSource), "closure reference must remain null");
assert(/chapter4-755\.audio\.json/.test(audioDirectorSource) && /chapter4-755\.audio\.json/.test(presentationDirectorSource), "both directors must import the Task 14 timeline");
assert(!/chapterFourClockGearSfxUrl|CHAPTER_FOUR_CLOCK_GEAR_SFX|playHallClockGearSfx/.test(sceneSource), "Scene must not directly replay the time-swap gear SFX");
assert(/maintenance_patrol_warning/.test(sceneSource) && !Object.prototype.hasOwnProperty.call(audio.events, "maintenance_patrol_warning"), "patrol warning must remain a domain event without an invented audio mapping");

for (const token of [
  "committed?:", "applied?:", "activeFloorBounds?:", "runtimeEntities?:", "ordinaryGuard?:", "finalChase?:",
  "lightGrid?:", "room202Door?:", "spatialAttestation?:", "contract?:", "developerCheckpoint?:"
]) {
  assert(debugSource.includes(token), `runtime debug schema is missing ${token}`);
}
for (const token of [
  "pendingProjectionSignature", "appliedPlateSignature", "runtimeEntities", "structuredFailures",
  "activeFloorBounds", "finalChaseInsideFinish", "finalChaseContact", "hostPowerPanelSession", "developerCheckpointSource"
]) {
  assert(sceneSource.includes(token), `Scene debug publisher is missing ${token}`);
}
assert(/finally\s*\{\s*unsubscribeAttestation\(\)/.test(hostSource), "Host attestation listener must detach in finally");
assert(/responses\.length !== 1/.test(source("../src/scenes/rpg/RpgInteractionContract.ts")), "attestation must require exactly one producer");

const server = await createServer({
  configFile: false,
  appType: "custom",
  logLevel: "error",
  optimizeDeps: { noDiscovery: true, include: [] },
  server: { middlewareMode: true, ws: false }
});

try {
  const [
    gameStateModule,
    eventBusModule,
    developerModule,
    questModule,
    saveControllerModule,
    storageKeysModule,
    interactionModule
  ] = await Promise.all([
    server.ssrLoadModule("/src/core/GameState.ts"),
    server.ssrLoadModule("/src/core/EventBus.ts"),
    server.ssrLoadModule("/src/modules/DeveloperChannel.ts"),
    server.ssrLoadModule("/src/core/QuestModel.ts"),
    server.ssrLoadModule("/src/modules/SaveController.ts"),
    server.ssrLoadModule("/src/core/StorageKeys.ts"),
    server.ssrLoadModule("/src/scenes/rpg/RpgInteractionContract.ts")
  ]);
  const { createGameStore, createInitialGameState } = gameStateModule;
  const { EventBus } = eventBusModule;
  const {
    DEVELOPER_CHECKPOINTS,
    applyDeveloperCheckpoint,
    applyDeveloperCheckpointFromUrl,
    createDeveloperCheckpointState,
    restoreDeveloperBackup
  } = developerModule;
  const { selectQuestViewModel } = questModule;
  const { SaveController } = saveControllerModule;
  const {
    DEVELOPER_ACTIVE_KEY,
    DEVELOPER_BACKUP_KEY,
    DEVELOPER_SOURCE_KEY
  } = storageKeysModule;
  const {
    CHAPTER_FOUR_755_SCENE_KEY,
    getChapterFour755TargetContract,
    resolveChapterFour755SpatialAttestationTarget,
    revalidateChapterFour755SpatialAttestation
  } = interactionModule;

  const visibleC4Ids = DEVELOPER_CHECKPOINTS
    .filter((entry) => entry.chapter === "第四章")
    .map((entry) => entry.id);
  assert(sameJson(visibleC4Ids, STABLE_IDS), "visible Chapter 4 DEV entries must be exactly the 11 stable IDs");
  for (const id of STABLE_IDS) {
    const state = createDeveloperCheckpointState(id);
    const [phase, timeState, floor, roomId] = EXPECTED_SEEDS[id];
    assert(state.chapter4.phase === phase, `${id} phase must be ${phase}`);
    assert(state.chapter4.timeState === timeState, `${id} timeState must be ${timeState}`);
    assert(state.chapter4.floor === floor && state.chapter4.roomId === roomId, `${id} floor/room seed is invalid`);
    assert(state.runtimeMode === "rpg" && state.rpgScene === "duan_yongping_temporal_maze", `${id} must enter the browser-native Chapter 4 runtime`);
    assert(state.ui.controlCenterOpen === false && state.ui.inventoryOpen === false && state.ui.selectedItem === null, `${id} must close transient UI`);
    const quest = selectQuestViewModel(state);
    assert(quest.total === 1 && (quest.completed === 0 || quest.completed === 1) && quest.steps.length === 1, `${id} must expose one 0/1 or 1/1 objective`);
  }
  const complete = createDeveloperCheckpointState("c4-755-complete");
  assert(complete.chapter4.checkinCardAccepted && complete.chapter4.checkinPaperAccepted, "complete waiting seed must include both accepted check-in parts");
  assert(!complete.chapter4.completed && !complete.chapter4.exteriorClosureAcknowledged, "complete waiting seed must not forge completion or acknowledgement");
  assert(!complete.chapter4.factIds.includes("exterior_closure_acknowledged"), "complete waiting seed must not forge closure proof");

  for (const [legacy, stable] of Object.entries(LEGACY_C4_ALIASES)) {
    assert(sameJson(createDeveloperCheckpointState(legacy), createDeveloperCheckpointState(stable)), `${legacy} must alias ${stable}`);
  }
  let unknownRejected = false;
  try { createDeveloperCheckpointState("c4-755-unknown"); } catch (error) {
    unknownRejected = String(error).includes("unknown_developer_checkpoint:c4-755-unknown");
  }
  assert(unknownRejected, "unknown direct DEV checkpoint must throw explicitly");

  const unknownStore = createGameStore(createInitialGameState());
  const unknownBefore = sameJson(unknownStore.getState(), createInitialGameState());
  const unknownStorage = new MemoryStorage();
  const unknownUrlResult = applyDeveloperCheckpointFromUrl(
    unknownStore,
    { search: "?devCheckpoint=c4-755-unknown&scene=phone_home" },
    unknownStorage
  );
  assert(unknownBefore && unknownUrlResult === null, "unknown URL checkpoint must be rejected without legacy fallback");
  assert(sameJson(unknownStore.getState(), createInitialGameState()) && unknownStorage.length === 0, "unknown URL checkpoint must be zero-write");

  const disabledStore = createGameStore(createInitialGameState());
  const disabledStorage = new MemoryStorage();
  const disabledResult = applyDeveloperCheckpointFromUrl(
    disabledStore,
    { search: "?dev=0&devCheckpoint=c4-755-chase" },
    disabledStorage
  );
  assert(disabledResult === null && disabledStorage.length === 0, "dev=0 must block URL seed and session writes");
  assert(sameJson(disabledStore.getState(), createInitialGameState()), "dev=0 must leave GameState unchanged");

  const session = new MemoryStorage();
  const firstStore = createGameStore(createInitialGameState());
  applyDeveloperCheckpoint(firstStore, "c4-755-light-grid", session, "panel");
  assert(session.getItem(DEVELOPER_ACTIVE_KEY) === "c4-755-light-grid" && session.getItem(DEVELOPER_SOURCE_KEY) === "panel", "DEV active id/source must be session-only metadata");
  const refreshedStore = createGameStore(createInitialGameState());
  const restoredId = applyDeveloperCheckpointFromUrl(refreshedStore, { search: "" }, session);
  assert(restoredId === null && refreshedStore.getState().chapter4.roomId === "a1_power_panel", "refresh must reapply the active session seed without a direct URL");

  const formalStorage = new MemoryStorage();
  const saveEvents = new EventBus();
  const saveController = new SaveController(refreshedStore, saveEvents, formalStorage, session);
  assert(saveController.saveNow() === false && formalStorage.length === 0, "manual save must not persist a DEV seed to formal storage");
  assert(saveEvents.getHistory().some((event) => event.name === "game_save_failed" && event.payload?.reason === "developer_checkpoint_session"), "manual DEV save rejection must be observable");
  assert(session.getItem(DEVELOPER_BACKUP_KEY) !== null, "first DEV jump must preserve a session backup");
  assert(restoreDeveloperBackup(refreshedStore, session), "DEV restore action must recover the pre-jump state");
  assert(session.getItem(DEVELOPER_ACTIVE_KEY) === null && session.getItem(DEVELOPER_SOURCE_KEY) === null, "DEV restore must clear active id/source metadata");

  const prepared = resolveChapterFour755SpatialAttestationTarget("a1_hall_clock");
  assert(prepared !== null, "static hall-clock target must resolve an attestation context");
  if (prepared) {
    const request = {
      requestId: "task14-request",
      attestationId: "task14-attestation",
      sceneKey: CHAPTER_FOUR_755_SCENE_KEY,
      committedPhase: "hall_clock_inspection",
      targetId: prepared.context.targetId,
      entityId: prepared.context.entityId,
      bounds: { ...prepared.context.bounds }
    };
    const response = {
      ...request,
      appliedPhase: "hall_clock_inspection",
      appliedPlateSignature: "task14-plate-signature",
      playerFootPoint: {
        x: request.bounds.x + request.bounds.width / 2,
        y: request.bounds.y + request.bounds.height / 2
      }
    };
    const valid = revalidateChapterFour755SpatialAttestation({
      request,
      responses: [response],
      target: prepared.contract,
      claimedSpatial: { distance: "within_range" }
    });
    assert(valid.accepted, "one matching synchronous Scene producer must pass attestation");
    assert(revalidateChapterFour755SpatialAttestation({ request, responses: [], target: prepared.contract, claimedSpatial: { distance: "within_range" } }).reason === "no_response", "no active Scene response must reject");
    assert(revalidateChapterFour755SpatialAttestation({ request, responses: [response, response], target: prepared.contract, claimedSpatial: { distance: "within_range" } }).reason === "multiple_responses", "a second producer must reject");
    assert(revalidateChapterFour755SpatialAttestation({ request, responses: [{ ...response, attestationId: "wrong" }], target: prepared.contract, claimedSpatial: { distance: "within_range" } }).reason === "mismatched_nonce", "mismatched nonce must reject");
    assert(!revalidateChapterFour755SpatialAttestation({ request, responses: [{ ...response, playerFootPoint: { x: 0, y: 0 } }], target: prepared.contract, claimedSpatial: { distance: "within_range" } }).accepted, "self-reported valid spatial booleans must reject when physical coordinates disagree");
    assert(revalidateChapterFour755SpatialAttestation({ request, responses: [{ ...response, playerFootPoint: { x: Number.NaN, y: 0 } }], target: prepared.contract, claimedSpatial: { distance: "within_range" } }).reason === "invalid_player", "non-finite player coordinates must reject");
    assert(!revalidateChapterFour755SpatialAttestation({ request, responses: [{ ...response, sceneKey: "second-producer-scene" }], target: prepared.contract, claimedSpatial: { distance: "within_range" } }).accepted, "wrong Scene response must reject");
    const wrongBounds = { ...response, bounds: { ...response.bounds, x: response.bounds.x + 1 } };
    assert(!revalidateChapterFour755SpatialAttestation({ request, responses: [wrongBounds], target: prepared.contract, claimedSpatial: { distance: "within_range" } }).accepted, "mismatched exact bounds must reject");
    assert(getChapterFour755TargetContract("a1_hall_clock")?.proximity === prepared.contract.proximity, "attestation must use the shared registry proximity");
    assert(!Object.prototype.hasOwnProperty.call(prepared.contract, "requiredFacing"), "interaction contracts must not expose a facing requirement");
  }
  const threshold = resolveChapterFour755SpatialAttestationTarget("a2_202_threshold");
  assert(threshold && !Object.prototype.hasOwnProperty.call(threshold.contract, "requiredFacing"), "automatic 202 threshold attestation must be facing agnostic");
  if (threshold) {
    const request = {
      requestId: "task14-threshold-request",
      attestationId: "task14-threshold-attestation",
      sceneKey: CHAPTER_FOUR_755_SCENE_KEY,
      committedPhase: "final_chase",
      targetId: threshold.context.targetId,
      entityId: threshold.context.entityId,
      bounds: { ...threshold.context.bounds }
    };
    const response = {
      ...request,
      appliedPhase: "final_chase",
      appliedPlateSignature: "task14-threshold-plate-signature",
      playerFootPoint: {
        x: request.bounds.x + request.bounds.width / 2,
        y: request.bounds.y + request.bounds.height / 2
      }
    };
    assert(revalidateChapterFour755SpatialAttestation({
      request,
      responses: [response],
      target: threshold.contract,
      claimedSpatial: { distance: "within_range" }
    }).accepted, "automatic 202 threshold attestation must accept the player inside its exact bounds without facing data");
  }
} catch (error) {
  errors.push(error instanceof Error ? error.stack ?? error.message : String(error));
} finally {
  await server.close();
}

if (errors.length > 0) {
  console.error(`Chapter 4 7:55 Task 14 validation failed (${errors.length} error${errors.length === 1 ? "" : "s"}):`);
  for (const error of errors) console.error(`- ${error}`);
  process.exit(1);
}

console.log(`Chapter 4 7:55 Task 14 PASS assertions=${assertionCount} dev=11+aliases+url+session-only quest=single-objective+three-hints audio=existing-assets+zero-closure debug=committed-applied+entities+guards+grid+door+failures attestation=single-producer+nonce+scene+bounds+finite+spatial`);
