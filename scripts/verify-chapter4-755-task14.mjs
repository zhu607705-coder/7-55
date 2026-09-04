import fs from "node:fs";
import path from "node:path";
import { spawnSync } from "node:child_process";
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

const PROLOGUE_IDS = [
  "c4-prologue",
  "c4-prologue-lake-exit",
  "c4-prologue-arcade",
  "c4-prologue-entrance",
  "c4-prologue-lobby",
  "c4-prologue-closing",
  "c4-prologue-task-card"
];

const INTERLUDE_IDS = [
  "c3-interlude-reboot",
  "c3-interlude-journal",
  "c3-interlude-photos",
  "c3-interlude-voice",
  "c3-interlude-network",
  "c3-interlude-timeline",
  "c3-interlude-destination",
  "c3-interlude-replay"
];

const PROLOGUE_OFFSETS = {
  "c4-prologue": 0,
  "c4-prologue-lake-exit": 6708,
  "c4-prologue-arcade": 13667,
  "c4-prologue-entrance": 23542,
  "c4-prologue-lobby": 28750,
  "c4-prologue-closing": 33417,
  "c4-prologue-task-card": 43834
};

const GAMEPLAY_IDS = [
  "c4-755-opening",
  "c4-755-hall-clock",
  "c4-755-bakery-1225",
  "c4-755-clock-1850-ready",
  "c4-755-classrooms-1850",
  "c4-755-elevator-history",
  "c4-755-room204-1850",
  "c4-755-a2-field-records",
  "c4-755-clock-2245-ready",
  "c4-755-maintenance-2245",
  "c4-755-blackout-0754",
  "c4-755-chase",
  "c4-755-final-minute",
  "c4-755-return-clock",
  "c4-755-checkin",
  "c4-755-closure"
];

const EXPECTED_SEEDS = {
  "c4-755-opening": ["opening_handoff", "2245_opening", "A1", "a1_lobby"],
  "c4-755-hall-clock": ["hall_clock_inspection", "2245_opening", "A1", "a1_hall_clock"],
  "c4-755-bakery-1225": ["bakery_hour_hand", "1225_bakery", "A1", "a1_bakery"],
  "c4-755-clock-1850-ready": ["room204_restore", "1225_bakery", "A1", "a1_hall_clock"],
  "c4-755-classrooms-1850": ["room204_restore", "1850_evening", "A1", "a1_hall_clock"],
  "c4-755-elevator-history": ["room204_restore", "1850_evening", "A1", "a1_main_elevator"],
  "c4-755-room204-1850": ["room204_restore", "1850_evening", "A3", "a3_reference_classroom"],
  "c4-755-a2-field-records": ["room204_restore", "1850_evening", "A2", "a2_corridor"],
  "c4-755-clock-2245-ready": ["maintenance_repair", "1850_evening", "A1", "a1_hall_clock"],
  "c4-755-maintenance-2245": ["maintenance_repair", "2245_maintenance", "A1", "a1_lobby"],
  "c4-755-blackout-0754": ["blackout_light_grid", "0754_blackout", "A1", "a1_power_panel"],
  "c4-755-chase": ["final_chase", "0754_blackout", "A1", "a1_lobby"],
  "c4-755-final-minute": ["final_minute_recovery", "0754_blackout", "A2", "a2_room_202"],
  "c4-755-return-clock": ["return_to_clock", "0754_blackout", "A2", "a2_room_202"],
  "c4-755-checkin": ["morning_checkin", "0755_morning", "A1", "a1_checkin"],
  "c4-755-closure": ["exterior_closure", "0755_morning", "A1", "a1_exterior"]
};

const LEGACY_C4_ALIASES = {
  "c4-clock-calibration": "c4-755-opening",
  "c4-755-light-grid": "c4-755-blackout-0754",
  "c4-755-complete": "c4-755-closure",
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
const layout = JSON.parse(fs.readFileSync(
  new URL("../src/data/chapter4-three-floor-maze.layout.json", import.meta.url),
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
const rpgPreloadSource = source("../src/scenes/rpg/RpgRuntimePreload.ts");
const prologueGateSource = source("../src/components/Chapter4PrologueRuntimeGate.tsx");
const sceneSource = source("../src/scenes/rpg/ChapterFourTemporalMazeScene.ts");
const playerTextureSource = source("../src/scenes/rpg/RpgPlayerTextures.ts");
const debugSource = source("../src/scenes/rpg/RpgRuntimeDebug.ts");
const audioDirectorSource = source("../src/modules/AudioDirector.ts");
const presentationDirectorSource = source("../src/modules/PresentationDirector.ts");
const controllerSource = source("../src/modules/ChapterFourTemporalMazeController.ts");
const stagePresentationSource = source("../src/modules/ChapterFourStagePresentation.ts");
const room204ModelSource = source("../src/scenes/rpg/ChapterFourRoom204Model.ts");

const clockRegistration = layout.finalClockRuntime?.visualRegistration;
assert(
  sameJson(layout.finalClockRuntime?.clockCenter, { x: 996, y: 63 })
    && sameJson(clockRegistration?.axis, { x: 996, y: 63 }),
  "hall-clock mechanics and sprite pivot must share the measured A1 state-plate axis"
);
assert(
  clockRegistration?.sourceFrameFaceRadius === 108
    && clockRegistration?.statePlateFaceRadius === 37
    && Math.abs(clockRegistration?.uniformScale - (37 / 108)) < 1e-9
    && clockRegistration?.framePivotRole === "clock_axis"
    && clockRegistration?.approximate === false,
  "hall-clock visual scale must be derived from the measured sprite and state-plate face radii"
);
assert(
  /const registration = FINAL_CLOCK_RUNTIME\.visualRegistration/.test(sceneSource)
    && /setPosition\(floor\.offsetX \+ registration\.axis\.x, registration\.axis\.y\)/.test(sceneSource)
    && /setScale\(registration\.uniformScale\)/.test(sceneSource)
    && !/target\.bounds\.width \/ frame\.realWidth/.test(sceneSource),
  "hall-clock sprite must use its visual registration instead of fitting the interaction rectangle"
);
assert(
  /getRpgSceneWarmAssetUrls\([\s\S]*?sceneId: RpgSceneId,[\s\S]*?phase\?: ChapterFourWarmupPhase/.test(hostSource)
    && /RPG_SCENE_WARM_ASSET_URLS:[\s\S]*?campus_bootstrap:[\s\S]*?duan_yongping_temporal_maze:/.test(hostSource)
    && /module\.getRpgSceneWarmAssets\([\s\S]*?sceneId,[\s\S]*?phase === "scene" \? undefined : phase/.test(rpgPreloadSource)
    && !/import\.meta\.glob/.test(rpgPreloadSource)
    && /export function warmRpgRuntime\(/.test(rpgPreloadSource)
    && /export function scheduleRpgRuntimeWarmup\(/.test(rpgPreloadSource),
  "RPG warmup must reuse one explicit Scene preload asset registry plus immediate and idle entry points"
);
assert(
  /publishPreloadedRpgGameHostModule\(module\)/.test(rpgPreloadSource)
    && /subscribePreloadedRpgGameHostModule/.test(appSource)
    && /const ActiveRpgGameHost = resolvedRpgGameHost \?\? RpgGameHost/.test(appSource)
    && (appSource.match(/<ActiveRpgGameHost/g) ?? []).length === 2,
  "a completed warmup must publish the resolved Host so entering RPG avoids the first React.lazy Suspense flash"
);
assert(
  /state\.currentScene === "timeline_recovery"/.test(appSource)
    && /scheduleRpgRuntimeWarmup\([\s\S]*?state\.rpgScene,[\s\S]*?"duan_yongping_temporal_maze" \? "entry" : undefined/.test(appSource)
    && /chapter35_recovered_replay_gate_requested[\s\S]*?warmRpgRuntime\("duan_yongping_temporal_maze", "immediate", "entry"\)/.test(prologueGateSource),
  "phone play must idle-warm its pending RPG while the 3.5 destination gate keeps Chapter 4 warmup behind replay confirmation"
);
assert(
  /connection\?\.saveData === true/.test(rpgPreloadSource)
    && /effectiveType === "slow-2g"/.test(rpgPreloadSource)
    && /requestIdleCallback/.test(rpgPreloadSource)
    && /window\.setTimeout\(start, 180\)/.test(rpgPreloadSource),
  "RPG warmup must preserve save-data and Safari-compatible idle fallbacks"
);
const closureSource = source("../src/modules/ChapterFourClosureContract.ts");
const mazeProjectionSource = source("../src/modules/ChapterFourMazeProjection.ts");
const runtimeValidatorSource = source("./verify-chapter4-755-runtime.mjs");
const task14ValidatorSource = source("./verify-chapter4-755-task14.mjs");
const ciSource = source("../.github/workflows/web-ci.yml");
const validationSuiteSource = source("./run-validation-suite.mjs");

const taskEntries = Object.entries(content.tasks ?? {});
const activeTaskEntries = taskEntries.filter(([taskId]) => taskId !== "chapter_complete");
const activeHints = activeTaskEntries.flatMap(([, task]) => Array.isArray(task?.hints) ? task.hints : []);
assert(taskEntries.length === 40 && activeTaskEntries.length === 39, "Task 14 must define 39 active tasks plus chapter_complete");
for (const [taskId, task] of activeTaskEntries) {
  assert(
    Array.isArray(task?.hints)
      && task.hints.length === 3
      && task.hints.every((hint) => typeof hint === "string" && hint.trim().length > 0),
    `${taskId} must expose exactly three non-empty progressive hints`
  );
}
assert(activeHints.length === 117, "Task 14 must expose the complete 117-hint contract");
assert(
  Array.isArray(content.tasks?.chapter_complete?.hints)
    && content.tasks.chapter_complete.hints.length === 0,
  "chapter_complete must expose zero hints"
);
const room204PlayerCopy = [
  content.tasks?.restore_room204?.label,
  ...(content.tasks?.restore_room204?.hints ?? [])
].filter(Boolean).join("\n");
assert(
  !/(?:家具|桌椅).{0,8}(?:朝向|旋转|转向|朝上|朝下|向左|向右)|(?:朝向|旋转|转向).{0,8}(?:家具|桌椅)/.test(room204PlayerCopy),
  "Room204 player copy must not require facing or rotation input"
);
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
  !/triggerObjective|quest-task-local-progress|has-chapter-four-context/.test(questStripSource)
    && /variant === "phone" \? \(open \? "收起任务" : "任务"\) : quest\.objective/.test(questStripSource),
  "collapsed Chapter 4 task bar must use the same objective-only status layout as every other chapter"
);
assert(
  /showTaskBar=\{activeSurface\s*===\s*"rpg"\}/.test(appSource)
    && !/import\s+\{\s*QuestTaskBar\s*\}/.test(appSource)
    && !/<QuestTaskBar/.test(appSource),
  "desktop RPG scenes, including Chapter 4, must mount the shared task bar only through their Host"
);
assert(
  /RUNTIME_MANAGED_DYNAMIC_COLLISION_IDS[\s\S]*?"a1_guard_chase_body"[\s\S]*?"a2_guard_chase_body"[\s\S]*?"a2_room204_disordered_furniture"[\s\S]*?"a2_room202_recovery_barrier"/.test(sceneSource)
    && /RUNTIME_MANAGED_DYNAMIC_COLLISION_IDS\.has\(projectedId\)/.test(sceneSource),
  "the plate contract must recognize runtime-managed guard and authored furniture collision bodies"
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
  /export function getRpgPlayerVisualContainmentInsets[\s\S]*?RPG_PLAYER_FRAME_WIDTH[\s\S]*?RPG_PLAYER_FOOT_WORLD_WIDTH[\s\S]*?RPG_PLAYER_FRAME_HEIGHT[\s\S]*?RPG_PLAYER_FOOT_BOTTOM_INSET[\s\S]*?RPG_PLAYER_FOOT_WORLD_HEIGHT/.test(playerTextureSource),
  "the shared player contract must derive visual-containment insets from its frame, scale and fixed foot box"
);
assert(
  /getRpgPlayerVisualContainmentInsets\(\)[\s\S]*?playerBody\.setBoundsRectangle\(new Phaser\.Geom\.Rectangle\([\s\S]*?floor\.offsetX \+ visualInsets\.left[\s\S]*?visualInsets\.top[\s\S]*?FLOOR_SIZE\.width - visualInsets\.left - visualInsets\.right[\s\S]*?FLOOR_SIZE\.height - visualInsets\.top - visualInsets\.bottom/.test(sceneSource),
  "the Chapter 4 player body must use a per-floor custom boundary that keeps the complete visual frame inside the source plate"
);
assert(
  !mazeProjectionSource.includes('collisionIds.push("a1_blackout_service_barrier")'),
  "the projection must not advertise a blackout service barrier without an authoritative runtime entity"
);

const releaseValidatorKeys = [
  '"typecheck"',
  '"facingAgnostic"',
  '"chapter4Assets"',
  '"chapter4Story"',
  '"chapter4Topology"',
  '"chapter4Runtime"',
  '"chapter4Task14"',
  '"campusMap"',
  '"productionBuild"',
  '"singleBuild"',
  '"singleVerify"',
  '"browserSmoke"'
];
const releaseSuiteBlock = validationSuiteSource.match(/release:\s*Object\.freeze\(\[([\s\S]*?)\]\)\s*\}\);/)?.[1] ?? "";
const releaseValidatorIndexes = releaseValidatorKeys.map((key) => releaseSuiteBlock.indexOf(key));
assert(
  /run:\s*npm run validate:release/.test(ciSource)
    && releaseValidatorIndexes.every((index) => index >= 0)
    && releaseValidatorIndexes.every((index, position) => position === 0 || releaseValidatorIndexes[position - 1] < index),
  "CI must call the canonical release suite, which must run typecheck, facing, five Chapter 4 gates, campus, builds, artifact verification and single-file browser smoke in order"
);
const chapterFourValidatorCatalog = validationSuiteSource.slice(
  validationSuiteSource.indexOf("chapter4Assets:"),
  validationSuiteSource.indexOf("chapter3Audio:")
);
assert(!/(?:generate|rebuild|build):chapter4|chapter4:(?:generate|rebuild|build)/.test(chapterFourValidatorCatalog), "release-suite Chapter 4 validators must not invoke asset generators");
assert(/server:\s*\{\s*middlewareMode:\s*true,\s*ws:\s*false\s*\}/.test(runtimeValidatorSource), "runtime validator must disable the Vite WebSocket server");
assert(/server:\s*\{\s*middlewareMode:\s*true,\s*ws:\s*false\s*\}/.test(task14ValidatorSource), "Task 14 validator must disable the Vite WebSocket server");

const expectedAudioEvents = [
  "chapter4_time_swap_committed",
  "chapter4_bakery_conveyor_stop",
  "room204_drawer_opened",
  "maintenance_cart_wheel_stuck",
  "maintenance_cart_wheel_repaired",
  "maintenance_cart_roll_started",
  "clock_stutter_started",
  "clock_stable_started",
  "clock_gear_repaired",
  "blackout_committed",
  "power_zone_toggled",
  "power_grid_locked",
  "final_chase_started",
  "final_chase_failed",
  "final_chase_succeeded",
  "final_minute_installed",
  "morning_checkin_card_accepted",
  "morning_checkin_paper_accepted",
  "morning_checkin_completed",
  "chapter4_environment_hint_pulse",
  "chapter4_755_scene_closed"
];
assert(audio.version === 1, "Task 14 audio timeline version must be 1");
assert(sameJson(Object.keys(audio.events), expectedAudioEvents), "Task 14 audio timeline event set/order changed");
const audioAssetPaths = new Map();
const audioRoot = new URL("../src/assets/audio/", import.meta.url);
const pendingAudioDirs = [fileURLToPath(audioRoot)];
while (pendingAudioDirs.length > 0) {
  const directory = pendingAudioDirs.pop();
  for (const entry of fs.readdirSync(directory, { withFileTypes: true })) {
    const entryPath = path.join(directory, entry.name);
    if (entry.isDirectory()) pendingAudioDirs.push(entryPath);
    else if (entry.name.endsWith(".mp3")) audioAssetPaths.set(entry.name.slice(0, -4), entryPath);
  }
}
for (const [eventId, event] of Object.entries(audio.events)) {
  assert(Array.isArray(event.cues) && event.cues.length > 0, `${eventId} must define cues`);
  for (const cue of event.cues ?? []) {
    assert(["music", "sfx", "voice", "text", "ambient"].includes(cue.channel), `${eventId} has an invalid channel`);
    if (cue.asset) assert(audioAssetPaths.has(cue.asset), `${eventId} references missing ${cue.asset}.mp3`);
    if (cue.channel === "ambient") {
      assert(typeof cue.owner === "string" && cue.owner.trim().length > 0, `${eventId} ambient cue must declare an owner`);
      assert(["play", "stop"].includes(cue.action), `${eventId} ambient cue must declare play or stop`);
      if (cue.action === "play") {
        assert(Boolean(cue.asset) && cue.loop === true, `${eventId} ambient play cue must use a looped asset`);
      }
    }
  }
}
const sceneClosedAmbientStop = audio.events.chapter4_755_scene_closed?.cues?.find((cue) => (
  cue.channel === "ambient" && cue.owner === "chapter4_clock" && cue.action === "stop"
));
assert(Boolean(sceneClosedAmbientStop), "scene_closed must stop the chapter4_clock ambient owner");
const expectedDetailAudio = {
  sfx_ch4_cart_wheel_stuck: [450, 2500],
  sfx_ch4_cart_wheel_repaired: [450, 2500],
  sfx_ch4_clock_stutter_loop: [800, 4000],
  sfx_ch4_clock_tick_loop: [800, 4000]
};
for (const [asset, [minimumMs, maximumMs]] of Object.entries(expectedDetailAudio)) {
  const assetPath = audioAssetPaths.get(asset);
  assert(Boolean(assetPath), `${asset}.mp3 must exist`);
  if (!assetPath) continue;
  const probe = spawnSync("ffprobe", [
    "-v", "error",
    "-show_entries", "format=duration",
    "-of", "default=noprint_wrappers=1:nokey=1",
    assetPath
  ], { encoding: "utf8" });
  const durationMs = Number.parseFloat(probe.stdout.trim()) * 1000;
  assert(probe.status === 0 && Number.isFinite(durationMs), `${asset}.mp3 must be readable by ffprobe`);
  assert(durationMs >= minimumMs && durationMs <= maximumMs, `${asset}.mp3 duration must be ${minimumMs}-${maximumMs}ms, got ${durationMs}`);
}
assert(!Object.keys(audio.events).some((id) => /exterior_closure|acknowledge_exterior/.test(id)), "official exterior closure must retain zero audio cues");
assert(
  /CHAPTER_FOUR_APPROVED_CLOSURE_REFERENCE:[\s\S]*?Object\.freeze\(\{[\s\S]*?sequenceId:\s*"chapter4_755_canruo_star_lamp_5800ms_camera_rise_layered_v4"[\s\S]*?rendererModule:\s*"src\/components\/temporal-maze\/ChapterFourStarLampThreeRenderer\.ts"/.test(closureSource),
  "closure reference must register the approved original-artwork camera-orbit sequence"
);
assert(/chapter4-755\.audio\.json/.test(audioDirectorSource) && /chapter4-755\.audio\.json/.test(presentationDirectorSource), "both directors must import the Task 14 timeline");
assert(!/chapterFourClockGearSfxUrl|CHAPTER_FOUR_CLOCK_GEAR_SFX|playHallClockGearSfx/.test(sceneSource), "Scene must not directly replay the time-swap gear SFX");
assert(/maintenance_patrol_warning/.test(sceneSource) && !Object.prototype.hasOwnProperty.call(audio.events, "maintenance_patrol_warning"), "patrol warning must remain a domain event without an invented audio mapping");
assert(
  /CHAPTER_FOUR_755_INTENT_DETAIL_CODES\s*=\s*Object\.freeze\(\[/.test(controllerSource)
    && /reason === "locked"[\s\S]*?detailCode:\s*detailCode \?\? \(chapter[\s\S]*?lockedDetailForIntent\(state, chapter, intent\)/.test(controllerSource),
  "every controller-owned locked result must receive an automatic detailCode"
);
assert(
  /const byIssue:\s*Record<typeof issue, ChapterFour755IntentDetailCode>\s*=\s*\{[\s\S]*?unknown_piece:\s*"room204_unknown_piece"[\s\S]*?unknown_slot:\s*"room204_unknown_slot"[\s\S]*?invalid_orientation:\s*"room204_invalid_orientation"[\s\S]*?duplicate_piece:\s*"room204_duplicate_piece"[\s\S]*?occupied_slot:\s*"room204_slot_occupied"[\s\S]*?already_placed:\s*"room204_piece_already_placed"/.test(controllerSource),
  "Room204 placement issues must map exhaustively to player-facing detail codes"
);
assert(
  /result\.detailCode[\s\S]*?CHAPTER_FOUR_755_INTENT_DETAILS\[result\.detailCode\]/.test(hostSource)
    && /chapterFour755DetailKeys\.length !== CHAPTER_FOUR_755_INTENT_DETAIL_CODES\.length/.test(hostSource),
  "Host must look up detailCode copy and validate the complete feedback table"
);
assert(
  /Room204PlacementIssue[\s\S]*?"unknown_piece"[\s\S]*?"unknown_slot"[\s\S]*?"invalid_orientation"[\s\S]*?"duplicate_piece"[\s\S]*?"occupied_slot"/.test(room204ModelSource),
  "Room204 pure model must retain its structured placement issues"
);
assert(
  /phaseCount:\s*13/.test(stagePresentationSource)
    && /timeStateCount:\s*6/.test(stagePresentationSource)
    && /现场 22:45 · 手机 07:55:23 未同步/.test(stagePresentationSource)
    && /旧钟 22:45 · 维修时段 · 手机已同步/.test(stagePresentationSource),
  "stage presentation selector must lock 13 phases, 6 time states and two distinct 22:45 states"
);

for (const token of [
  "committed?:", "applied?:", "activeFloorBounds?:", "runtimeEntities?:", "ordinaryGuard?:", "finalChase?:",
  "lightGrid?:", "room202Door?:", "spatialAttestation?:", "contract?:", "developerCheckpoint?:",
  "visualBounds?:", "movementBounds?:"
]) {
  assert(debugSource.includes(token), `runtime debug schema is missing ${token}`);
}
for (const token of [
  "pendingProjectionSignature", "appliedPlateSignature", "runtimeEntities", "structuredFailures",
  "activeFloorBounds", "finalChaseInsideFinish", "finalChaseContact", "hostPowerPanelSession", "developerCheckpointSource",
  "playerVisualBounds", "playerMovementBounds"
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
    interactionModule,
    controllerModule,
    stagePresentationModule
  ] = await Promise.all([
    server.ssrLoadModule("/src/core/GameState.ts"),
    server.ssrLoadModule("/src/core/EventBus.ts"),
    server.ssrLoadModule("/src/modules/DeveloperChannel.ts"),
    server.ssrLoadModule("/src/core/QuestModel.ts"),
    server.ssrLoadModule("/src/modules/SaveController.ts"),
    server.ssrLoadModule("/src/core/StorageKeys.ts"),
    server.ssrLoadModule("/src/scenes/rpg/RpgInteractionContract.ts"),
    server.ssrLoadModule("/src/modules/ChapterFourTemporalMazeController.ts"),
    server.ssrLoadModule("/src/modules/ChapterFourStagePresentation.ts")
  ]);
  const { createGameStore, createInitialGameState } = gameStateModule;
  const { EventBus } = eventBusModule;
  const {
    DEVELOPER_CHECKPOINTS,
    applyDeveloperCheckpoint,
    applyDeveloperCheckpointFromUrl,
    createDeveloperCheckpointState,
    getDeveloperChapter4PrologueOffset,
    markDeveloperChapter4PrologueTaskCardConfirmed,
    restoreDeveloperBackup
  } = developerModule;
  const { selectQuestViewModel } = questModule;
  const { SaveController } = saveControllerModule;
  const {
    DEVELOPER_ACTIVE_KEY,
    DEVELOPER_BACKUP_KEY,
    DEVELOPER_CHAPTER4_PROLOGUE_OFFSET_KEY,
    DEVELOPER_CHAPTER4_TASK_CARD_CONFIRMED_KEY,
    DEVELOPER_SOURCE_KEY
  } = storageKeysModule;
  const {
    CHAPTER_FOUR_755_SCENE_KEY,
    getChapterFour755TargetContract,
    resolveChapterFour755SpatialAttestationTarget,
    revalidateChapterFour755SpatialAttestation
  } = interactionModule;
  const {
    CHAPTER_FOUR_755_INTENT_DETAIL_CODES,
    ChapterFourTemporalMazeController
  } = controllerModule;
  const {
    CHAPTER_FOUR_STAGE_PRESENTATION_VALIDATION,
    selectChapterFourStagePresentation
  } = stagePresentationModule;

  assert(
    sameJson(
      [...CHAPTER_FOUR_755_INTENT_DETAIL_CODES].sort(),
      Object.keys(content.intentFeedback.details).sort()
    ),
    "content feedback details must cover every exported detailCode exactly once"
  );
  assert(
    Object.values(content.intentFeedback.details).every((detail) => (
      typeof detail.reason === "string" && detail.reason.trim().length > 0
        && typeof detail.nextAction === "string" && detail.nextAction.trim().length > 0
    )),
    "every detailCode must provide a non-empty reason and next action"
  );
  assert(
    CHAPTER_FOUR_STAGE_PRESENTATION_VALIDATION.phaseCount === 13
      && CHAPTER_FOUR_STAGE_PRESENTATION_VALIDATION.timeStateCount === 6,
    "stage presentation runtime validation must cover 13 phases and 6 time states"
  );

  const visibleChapterThreeHalfIds = DEVELOPER_CHECKPOINTS
    .filter((entry) => entry.chapter === "3.5章")
    .map((entry) => entry.id);
  assert(
    sameJson(visibleChapterThreeHalfIds, [...INTERLUDE_IDS, ...PROLOGUE_IDS]),
    "visible Chapter 3.5 DEV entries must contain the recovery interlude followed by the H3 teaching-building transition"
  );
  const visibleC4Ids = DEVELOPER_CHECKPOINTS
    .filter((entry) => entry.chapter === "第四章")
    .map((entry) => entry.id);
  assert(sameJson(visibleC4Ids, GAMEPLAY_IDS), "visible Chapter 4 DEV entries must contain only the canonical gameplay IDs");
  for (const id of GAMEPLAY_IDS) {
    const state = createDeveloperCheckpointState(id);
    const [phase, timeState, floor, roomId] = EXPECTED_SEEDS[id];
    assert(state.chapter4.phase === phase, `${id} phase must be ${phase}`);
    assert(state.chapter4.timeState === timeState, `${id} timeState must be ${timeState}`);
    assert(state.chapter4.floor === floor && state.chapter4.roomId === roomId, `${id} floor/room seed is invalid`);
    assert(state.runtimeMode === "rpg" && state.rpgScene === "duan_yongping_temporal_maze", `${id} must enter the browser-native Chapter 4 runtime`);
    assert(state.ui.controlCenterOpen === false && state.ui.inventoryOpen === false && state.ui.selectedItem === null, `${id} must close transient UI`);
    const quest = selectQuestViewModel(state);
    assert(quest.total === 1 && (quest.completed === 0 || quest.completed === 1) && quest.steps.length === 1, `${id} must expose one 0/1 or 1/1 objective`);
    assert(selectChapterFourStagePresentation(state) !== null, `${id} must resolve a stage presentation`);
  }
  const openingPresentation = selectChapterFourStagePresentation(createDeveloperCheckpointState("c4-755-opening"));
  const maintenancePresentation = selectChapterFourStagePresentation(createDeveloperCheckpointState("c4-755-maintenance-2245"));
  assert(
    openingPresentation?.timeStateLabel === "现场 22:45 · 手机 07:55:23 未同步"
      && maintenancePresentation?.timeStateLabel === "旧钟 22:45 · 维修时段 · 手机已同步"
      && openingPresentation.timeSource !== maintenancePresentation.timeSource
      && openingPresentation.trustState !== maintenancePresentation.trustState,
    "the two 22:45 stages must remain visibly and semantically distinct"
  );
  const lockedStore = createGameStore(createDeveloperCheckpointState("c4-755-opening"));
  const lockedController = new ChapterFourTemporalMazeController(lockedStore, new EventBus());
  const lockedResult = lockedController.resolve755Intent({ type: "trigger_minute_theft" });
  assert(
    lockedResult.reason === "locked"
      && typeof lockedResult.detailCode === "string"
      && CHAPTER_FOUR_755_INTENT_DETAIL_CODES.includes(lockedResult.detailCode),
    "a controller-owned locked result must expose a declared detailCode"
  );
  const finalMinuteRecovery = createDeveloperCheckpointState("c4-755-final-minute");
  assert(
    finalMinuteRecovery.chapter4.factIds.includes("room202_route_reached")
      && !finalMinuteRecovery.chapter4.factIds.includes("final_minute_recovered")
      && !finalMinuteRecovery.items.finalMinute,
    "final-minute seed must represent a completed 202 arrival without forging the pickup"
  );
  const returnClock = createDeveloperCheckpointState("c4-755-return-clock");
  assert(
    returnClock.items.finalMinute
      && returnClock.items.attendanceRecordPaper
      && returnClock.items.campusCard
      && returnClock.chapter4.factIds.includes("final_minute_recovered")
      && !returnClock.chapter4.factIds.includes("final_minute_installed"),
    "return-clock seed must carry the recovered minute, attendance paper and campus card without forging installation"
  );
  const closure = createDeveloperCheckpointState("c4-755-closure");
  assert(closure.chapter4.checkinCardAccepted && closure.chapter4.checkinPaperAccepted, "closure waiting seed must include both accepted check-in parts");
  assert(
    [
      "a3_identity_context_observed",
      "attendance_record_recovered",
      "checkin_identity_verified"
    ].every((factId) => closure.chapter4.factIds.includes(factId)),
    "closure waiting seed must retain the three raw identity prerequisites consumed by the exterior questions"
  );
  assert(!closure.chapter4.completed && !closure.chapter4.exteriorClosureAcknowledged, "closure waiting seed must not forge completion or acknowledgement");
  assert(
    !closure.chapter4.factIds.includes("zhu_two_questions_answered")
      && closure.chapter4.zhuQuestionAnswers.purpose === null
      && closure.chapter4.zhuQuestionAnswers.person === null,
    "closure waiting seed must open before the exterior questions and must not forge either answer"
  );
  assert(!closure.chapter4.factIds.includes("exterior_closure_acknowledged"), "closure waiting seed must not forge closure proof");

  for (const id of PROLOGUE_IDS) {
    const previewState = createDeveloperCheckpointState(id);
    assert(!previewState.chapter4.prologueSeen && previewState.chapterThreeInterlude.phase === "replay_ready", `${id} must remain an independent prologue preview seed`);
    const previewStorage = new MemoryStorage();
    const previewStore = createGameStore(createInitialGameState());
    applyDeveloperCheckpoint(previewStore, id, previewStorage, "panel");
    assert(previewStorage.getItem(DEVELOPER_ACTIVE_KEY) === id, `${id} must retain its own active checkpoint identity`);
    assert(previewStorage.getItem(DEVELOPER_CHAPTER4_PROLOGUE_OFFSET_KEY) === String(PROLOGUE_OFFSETS[id]), `${id} must persist its authored replay offset`);
    assert(getDeveloperChapter4PrologueOffset(previewStorage) === PROLOGUE_OFFSETS[id], `${id} must restore its authored replay offset`);
  }

  const taskCardStorage = new MemoryStorage();
  const taskCardStore = createGameStore(createInitialGameState());
  applyDeveloperCheckpoint(taskCardStore, "c4-prologue-task-card", taskCardStorage, "panel");
  assert(!taskCardStore.getState().chapter4.prologueSeen, "task-card DEV entry must show the task card before confirmation");
  const taskCardBeforeConfirmationReload = createGameStore(createInitialGameState());
  applyDeveloperCheckpointFromUrl(taskCardBeforeConfirmationReload, { search: "" }, taskCardStorage);
  assert(!taskCardBeforeConfirmationReload.getState().chapter4.prologueSeen, "unconfirmed task-card reload must stay on the task card");
  markDeveloperChapter4PrologueTaskCardConfirmed(taskCardStorage);
  assert(taskCardStorage.getItem(DEVELOPER_CHAPTER4_TASK_CARD_CONFIRMED_KEY) === "1", "task-card confirmation must be session-scoped");
  const taskCardAfterConfirmationReload = createGameStore(createInitialGameState());
  applyDeveloperCheckpointFromUrl(taskCardAfterConfirmationReload, { search: "" }, taskCardStorage);
  assert(
    taskCardAfterConfirmationReload.getState().chapter4.prologueSeen
      && taskCardAfterConfirmationReload.getState().chapter4.phase === "opening_handoff"
      && taskCardAfterConfirmationReload.getState().chapter4.floor === "A1"
      && taskCardAfterConfirmationReload.getState().chapter4.roomId === "a1_lobby",
    "confirmed task-card reload must enter the canonical A1 opening seed"
  );
  const taskCardUrl = { search: "?devCheckpoint=c4-prologue-task-card&dev=1" };
  const taskCardUrlStorage = new MemoryStorage();
  const taskCardUrlFirstStore = createGameStore(createInitialGameState());
  applyDeveloperCheckpointFromUrl(taskCardUrlFirstStore, taskCardUrl, taskCardUrlStorage);
  assert(!taskCardUrlFirstStore.getState().chapter4.prologueSeen, "first task-card URL load must show the task card");
  markDeveloperChapter4PrologueTaskCardConfirmed(taskCardUrlStorage);
  const taskCardUrlReloadStore = createGameStore(createInitialGameState());
  applyDeveloperCheckpointFromUrl(taskCardUrlReloadStore, taskCardUrl, taskCardUrlStorage);
  assert(
    taskCardUrlReloadStore.getState().chapter4.prologueSeen
      && taskCardUrlReloadStore.getState().chapter4.phase === "opening_handoff",
    "confirmed task-card URL reload must restore A1 even when the query remains in the address bar"
  );

  for (const [legacy, stable] of Object.entries(LEGACY_C4_ALIASES)) {
    assert(sameJson(createDeveloperCheckpointState(legacy), createDeveloperCheckpointState(stable)), `${legacy} must alias ${stable}`);
  }
  let unknownRejected = false;
  try { createDeveloperCheckpointState("c4-755-unknown"); } catch (error) {
    unknownRejected = String(error).includes("unknown_developer_checkpoint:c4-755-unknown");
  }
  assert(unknownRejected, "unknown direct DEV checkpoint must throw explicitly");
  let unverifiedResultRejected = false;
  try { createDeveloperCheckpointState("c4-755-result"); } catch (error) {
    unverifiedResultRejected = String(error).includes("unknown_developer_checkpoint:c4-755-result");
  }
  assert(unverifiedResultRejected, "c4-755-result must stay unavailable until a verified completed consumer state exists");

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
  assert(session.getItem(DEVELOPER_ACTIVE_KEY) === "c4-755-blackout-0754" && session.getItem(DEVELOPER_SOURCE_KEY) === "panel", "legacy light-grid URL must normalize to the canonical session-only checkpoint metadata");
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

console.log(`Chapter 4 7:55 Task 14 PASS assertions=${assertionCount} dev=16+aliases+url+session-only quest=single-objective+117-hints stage=13-phases+6-times audio=ambient-owner+detail-assets+zero-closure feedback=detail-codes+host-lookup debug=committed-applied+entities+guards+grid+door+failures attestation=single-producer+nonce+scene+bounds+finite+spatial`);
