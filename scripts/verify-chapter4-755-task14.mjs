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
  "c4-755-classrooms-1850",
  "c4-755-elevator-history",
  "c4-755-room204-1850",
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
  "c4-755-classrooms-1850": ["room204_restore", "1850_evening", "A1", "a1_hall_clock"],
  "c4-755-elevator-history": ["room204_restore", "1850_evening", "A1", "a1_main_elevator"],
  "c4-755-room204-1850": ["room204_restore", "1850_evening", "A3", "a3_reference_classroom"],
  "c4-755-maintenance-2245": ["maintenance_repair", "2245_maintenance", "A1", "a1_lobby"],
  "c4-755-blackout-0754": ["blackout_light_grid", "0754_blackout", "A1", "a1_power_panel"],
  "c4-755-chase": ["final_chase", "0754_blackout", "A1", "a1_lobby"],
  "c4-755-final-minute": ["final_minute_recovery", "0754_blackout", "A2", "a2_room_202"],
  "c4-755-return-clock": ["return_to_clock", "0754_blackout", "A2", "a2_room_202"],
  "c4-755-checkin": ["morning_checkin", "0755_morning", "A1", "a1_checkin"],
  "c4-755-closure": ["exterior_closure", "0755_morning", "A1", "a1_exterior"]
};

const REQUIRED_EVIDENCE_FACTS_BY_CHECKPOINT = {
  "c4-755-opening": [],
  "c4-755-hall-clock": [],
  "c4-755-bakery-1225": [],
  "c4-755-classrooms-1850": [
    "bakery_conveyor_direction_observed",
    "bakery_tool_location_observed"
  ],
  "c4-755-elevator-history": [
    "bakery_conveyor_direction_observed",
    "bakery_tool_location_observed",
    "classroom_104_chalk_residual_observed",
    "classroom_105_terminal_replay_checked",
    "elevator_history_observed"
  ],
  "c4-755-room204-1850": [
    "bakery_conveyor_direction_observed",
    "bakery_tool_location_observed",
    "a1_time_route_compared",
    "a3_reference_observed",
    "a3_identity_context_observed"
  ],
  "c4-755-maintenance-2245": [
    "room204_projection_composite_completed",
    "room202_endpoint_inferred",
    "maintenance_incident_linked"
  ],
  "c4-755-blackout-0754": [
    "maintenance_incident_linked",
    "clock_gear_repaired"
  ],
  "c4-755-chase": [
    "light_grid_locked",
    "powered_route_confirmed"
  ],
  "c4-755-final-minute": [
    "powered_route_confirmed",
    "room202_route_reached"
  ],
  "c4-755-return-clock": [
    "room202_route_reached",
    "final_minute_recovered",
    "attendance_record_recovered"
  ],
  "c4-755-checkin": [
    "attendance_record_recovered",
    "final_minute_installed"
  ],
  "c4-755-closure": [
    "attendance_record_recovered",
    "checkin_card_accepted",
    "checkin_paper_accepted",
    "checkin_identity_verified"
  ]
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
const debugSource = source("../src/scenes/rpg/RpgRuntimeDebug.ts");
const audioDirectorSource = source("../src/modules/AudioDirector.ts");
const presentationDirectorSource = source("../src/modules/PresentationDirector.ts");
const controllerSource = source("../src/modules/ChapterFourTemporalMazeController.ts");
const stagePresentationSource = source("../src/modules/ChapterFourStagePresentation.ts");
const transitionPresentationSource = source("../src/modules/ChapterFourTransitionPresentation.ts");
const transitionOverlaySource = source("../src/components/temporal-maze/ChapterFourTransitionOverlay.tsx");
const subtitleLayerSource = source("../src/components/RpgSubtitleLayer.tsx");
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
  /export function getRpgSceneWarmAssets\(/.test(hostSource) && /getChapterFourWarmupPhaseAssets\(phase \?\? "entry"\)/.test(hostSource) && /module\.getRpgSceneWarmAssets\(\s*sceneId,\s*phase === "scene" \? undefined : phase\s*\)/.test(rpgPreloadSource) && !/import\.meta\.glob/.test(rpgPreloadSource) && /export function warmRpgRuntime\(/.test(rpgPreloadSource) && /export function scheduleRpgRuntimeWarmup\(/.test(rpgPreloadSource),
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
  /state\.currentScene !== "timeline_recovery"/.test(appSource) && /scheduleRpgRuntimeWarmup\(\s*state\.rpgScene,\s*state\.rpgScene === "duan_yongping_temporal_maze" \? "entry" : undefined\s*\)/.test(appSource) && /chapter35_recovered_replay_gate_requested[\s\S]*?warmRpgRuntime\("duan_yongping_temporal_maze", "immediate", "entry"\)/.test(prologueGateSource),
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
const exteriorDoorSource = source("../src/modules/ChapterFourExteriorDoorContract.ts");
const closureSessionSource = source("../src/modules/ChapterFourClosureSessionRegistry.ts");
const closurePlaybackSource = source("../src/components/temporal-maze/ChapterFourStarLampPlayback.tsx");
const validationRunnerSource = source("./run-validation-suite.mjs");
const closureComponentSource = source("../src/components/temporal-maze/ChapterFourStarLampClosure.tsx");
const closureWarmAssetsSource = source("../src/scenes/rpg/ChapterFourWarmupAssets.ts");
const mazeProjectionSource = source("../src/modules/ChapterFourMazeProjection.ts");
const runtimeValidatorSource = source("./verify-chapter4-755-runtime.mjs");
const task14ValidatorSource = source("./verify-chapter4-755-task14.mjs");
const ciSource = source("../.github/workflows/web-ci.yml");
const packageSource = source("../package.json");

const taskEntries = Object.entries(content.tasks ?? {});
const activeTaskEntries = taskEntries.filter(([taskId]) => taskId !== "chapter_complete");
const activeHints = activeTaskEntries.flatMap(([, task]) => Array.isArray(task?.hints) ? task.hints : []);
const expectedActiveTaskIds = new Set(
  (content.phaseContracts ?? [])
    .flatMap((contract) => contract?.taskKeys ?? [])
    .filter((taskId) => taskId !== "chapter_complete")
);
assert(
  taskEntries.length === expectedActiveTaskIds.size + 1
    && activeTaskEntries.length === expectedActiveTaskIds.size
    && activeTaskEntries.every(([taskId]) => expectedActiveTaskIds.has(taskId)),
  "Task 14 must define exactly the active phase tasks plus chapter_complete"
);
for (const [taskId, task] of activeTaskEntries) {
  assert(
    Array.isArray(task?.hints)
      && task.hints.length === 3
      && task.hints.every((hint) => typeof hint === "string" && hint.trim().length > 0),
    `${taskId} must expose exactly three non-empty progressive hints`
  );
}
assert(
  activeHints.length === expectedActiveTaskIds.size * 3,
  "Task 14 must expose exactly three hints for every active phase task"
);
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
  /<PhoneShell\b[\s\S]*?showTaskBar=\{activeSurface === "phone"\}/.test(appSource) && /<ActiveRpgGameHost\b[\s\S]*?showTaskBar=\{activeSurface === "rpg"\}/.test(appSource) && /showTaskBar && !fishingSession && !assetLoadBlocked && !canteenExclusiveActive && !chapter4OverlayBlocked/.test(hostSource),
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

const packageJson = JSON.parse(packageSource);
const releaseMatch = validationRunnerSource.match(/\brelease:\s*Object\.freeze\(\[([\s\S]*?)\]\)/);
const releaseKeys = [...(releaseMatch?.[1] ?? "").matchAll(/"([^"]+)"/g)].map(match=>match[1]);
const validatorScripts = new Map([...validationRunnerSource.matchAll(/^\s*(\w+):\s*Object\.freeze\(\{\s*area:\s*"[^"]+",\s*script:\s*"([^"]+)"/gm)].map(match=>[match[1],match[2]]));
const requiredChapterFourKeys = ["chapter4Assets","chapter4Story","chapter4Topology","chapter4Runtime","chapter4Task14"];
const requiredChapterFourScripts = ["chapter4:validate-assets","chapter4:validate-story","chapter4:validate-topology","chapter4:validate-runtime","chapter4:validate-task14"];
const firstBuild = releaseKeys.indexOf("productionBuild");
const gates = ["facingAgnostic","campusMap",...requiredChapterFourKeys];
assert(/run:\s*npm run validate:release\b/.test(ciSource) && packageJson.scripts["validate:release"] === "node scripts/run-validation-suite.mjs release" && releaseKeys.filter(key=>key==="typecheck").length===1 && releaseKeys.indexOf("typecheck")===0 && firstBuild>0 && gates.every(key=>releaseKeys.indexOf(key)>0&&releaseKeys.indexOf(key)<firstBuild) && requiredChapterFourKeys.every((key,index)=>validatorScripts.get(key)===requiredChapterFourScripts[index]) && validatorScripts.get("facingAgnostic")==="verify:rpg-facing-agnostic" && validatorScripts.get("campusMap")==="map:zijingang" && gates.every(key=>Boolean(packageJson.scripts[validatorScripts.get(key)])), "CI release must run one typecheck, campus, facing and five Chapter 4 gates before production builds");
const chapterFourCiBlock = requiredChapterFourKeys.map(key=>{const script=validatorScripts.get(key);return script+"\n"+packageJson.scripts[script]}).join("\n");
assert(!/(?:generate|rebuild|build):chapter4|chapter4:(?:generate|rebuild|build)/.test(chapterFourCiBlock), "CI Chapter 4 validation block must not invoke asset generators");
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
assert(
  audio.events.chapter4_environment_hint_pulse?.cues?.length === 1
    && audio.events.chapter4_environment_hint_pulse.cues[0].panFromEvent === true
    && /createStereoPanner/.test(audioDirectorSource)
    && /payload\?\.pan/.test(audioDirectorSource),
  "adaptive environmental help must use one event-positioned audio cue without adding story facts"
);
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
assert(!Object.keys(audio.events).some((id) => /exterior_closure|acknowledge_exterior/.test(id)), "official exterior closure must keep its visual sequence free of an invented audio cue");
assert(
  /assetId:\s*"canruo_star_lamp_layered_v1"/.test(closureSource)
    && /sequenceId:\s*"chapter4_755_canruo_star_lamp_5800ms_camera_rise_layered_v4"/.test(closureSource)
    && /consumerModule:\s*"src\/components\/temporal-maze\/ChapterFourStarLampClosure\.tsx"/.test(closureSource)
    && /class ChapterFourClosureSessionRegistry/.test(closureSessionSource)
    && /session\.consumed = true/.test(closureSessionSource),
  "closure contract must register the approved lamp consumer and a once-consumed runtime session proof"
);
assert(
  /CHAPTER_FOUR_STAR_LAMP_SAVED_CONFIRMATION_MS\s*=\s*900/.test(closureComponentSource) && /回答已保存/.test(closureComponentSource) && /从此，你将与历史上众多灿若星辰的名字一起，共享'浙大人'这个无上荣光的称号！/.test(closureComponentSource) && /stage === "playback"[\s\S]*?<ChapterFourStarLampPlayback[\s\S]*?onComplete=\{finishPlayback\}/.test(closureComponentSource) && /current === "playback" \? "final" : current/.test(closureComponentSource) && /stage !== "final" \|\| completedRef\.current/.test(closureComponentSource) && /onComplete\(sessionId\)/.test(closureComponentSource) && /renderer\.start\(\{\s*onComplete:\s*completeOnce/.test(closurePlaybackSource) && /frame\.phase === "complete"[\s\S]*?completeOnce\(\)/.test(closurePlaybackSource) && /document\.visibilityState === "hidden"/.test(closurePlaybackSource) && ["lamp_dark.png","lamp_outline.png","lamp_leds.png","lamp_core.png","lamp_glow.png"].every(file=>closurePlaybackSource.includes(file)&&closureWarmAssetsSource.includes(file)) && /closure:\s*Object\.freeze\(\[[\s\S]*?\.\.\.CLOSURE_LAMP_ASSETS/.test(closureWarmAssetsSource) && /getChapterFourWarmupPhaseAssets\(phase \?\? "entry"\)/.test(hostSource),
  "closure UI must preserve saved-only confirmation, complete phase-warmed playback and final acknowledgement"
);
assert(
  /doorwayBounds:\s*Object\.freeze\(\{ x: 767, y: 779, width: 141, height: 94 \}\)/.test(exteriorDoorSource)
    && /frameName:\s*"a1-exterior-door-left"[\s\S]*?hinge:\s*"left"/.test(exteriorDoorSource)
    && /frameName:\s*"a1-exterior-door-right"[\s\S]*?hinge:\s*"right"/.test(exteriorDoorSource)
    && /openedEventName:\s*"rpg_chapter4_exterior_door_opened"/.test(exteriorDoorSource),
  "A1 exterior door contract must retain its measured opening, two hinged leaves and completion event"
);
assert(
  /syncExteriorDoorPresentation\(\)/.test(sceneSource)
    && /storyPresentation = "exterior_door_opening"/.test(sceneSource)
    && /scaleX:\s*contract\.finalLeafScaleX/.test(sceneSource)
    && /safeBridgeEmit\(CHAPTER_FOUR_EXTERIOR_DOOR\.openedEventName/.test(sceneSource)
    && /chapter4ClosurePresentationReady/.test(hostSource)
    && /event\.name !== CHAPTER_FOUR_EXTERIOR_DOOR\.openedEventName/.test(hostSource),
  "the Scene must finish and report the A1 door animation before the Host opens the final lamp overlay"
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
assert(
  /selectChapterFourTransitionPresentation/.test(hostSource)
    && /selectChapterFourTransitionPresentationOwner/.test(hostSource)
    && /const transitionOwner =/.test(hostSource)
    && /presentationOwner:\s*ChapterFourTransitionPresentationOwner/.test(hostSource)
    && /rememberChapterFourTransitionForResume/.test(hostSource)
    && /rpg_chapter4_transition_resumed/.test(hostSource)
    && /data-chapter4-transition-id/.test(hostSource),
  "Host must own typed Chapter 4 transition presentation and interrupted-session recovery"
);
assert(
  /data-transition-step/.test(transitionOverlaySource)
    && /data-transition-surface="rpg-shell"/.test(transitionOverlaySource)
    && /data-transition-step="time_shift"/.test(transitionOverlaySource)
    && /继续行动/.test(transitionOverlaySource)
    && !/startAtHandoff|puzzleHandoff|dialogueGroups|下一步行动|跳过演出/.test(transitionOverlaySource),
  "transition overlay must show one actual time change without duplicating dialogue or task guidance"
);
assert(
  /transitionPresentationOwned/.test(sceneSource)
    && /resultPresentationOwner\(payload\) === "transition_overlay"/.test(sceneSource)
    && /startGraceReady/.test(sceneSource)
    && /if \(blocked\) return;/.test(subtitleLayerSource),
  "Phaser must expose chase handoff grace and suppress duplicate cross-phase feedback with the shared subtitle layer while the Host overlay owns presentation"
);
assert(
  /transitionCount:\s*8/.test(transitionPresentationSource)
    && /overlayCount:\s*4/.test(transitionPresentationSource)
    && /worldHandoffCount:\s*4/.test(transitionPresentationSource)
    && /intentMatchCount:\s*9/.test(transitionPresentationSource)
    && /CHAPTER_FOUR_TRANSITION_RESUME_STORAGE_KEY/.test(transitionPresentationSource)
    && /getChapterFourTransitionPresentationById/.test(transitionPresentationSource)
    && /chapter4_transition_duplicate_match/.test(transitionPresentationSource)
    && /chapter4_transition_world_handoff/.test(transitionPresentationSource)
    && /selectChapterFourTransitionPresentationOwner/.test(transitionPresentationSource),
  "transition selector must validate four time overlays, four in-scene handoffs and nine unique intent matches"
);

for (const token of [
  "committed?:", "applied?:", "activeFloorBounds?:", "runtimeEntities?:", "ordinaryGuard?:", "finalChase?:",
  "lightGrid?:", "room202Door?:", "environmentEvidence?:", "spatialAttestation?:", "contract?:", "developerCheckpoint?:"
]) {
  assert(debugSource.includes(token), `runtime debug schema is missing ${token}`);
}
for (const token of [
  "pendingProjectionSignature", "appliedPlateSignature", "runtimeEntities", "structuredFailures",
  "activeFloorBounds", "finalChaseInsideFinish", "finalChaseContact", "visibleRawDetailIds",
  "hintLevels", "hostPowerPanelSession", "developerCheckpointSource"
]) {
  assert(sceneSource.includes(token), `Scene debug publisher is missing ${token}`);
}
assert(/finally\s*\{\s*unsubscribeAttestation\(\)/.test(hostSource), "Host attestation listener must detach in finally");
assert(/responses\.length !== 1/.test(source("../src/scenes/rpg/RpgInteractionContract.ts")), "attestation must require exactly one producer");
assert(
  /rpg_chapter4_power_panel_attempt_abandoned/.test(hostSource)
    && /!isChapterFourLightGridSolved\(mask\)/.test(hostSource)
    && /event\.name === "rpg_chapter4_power_panel_attempt_abandoned"/.test(sceneSource)
    && /recordVisualHintFailure\("power_route_comparison"\)/.test(sceneSource),
  "closing an unsolved power panel must register one runtime-only adaptive-help attempt"
);

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
    stagePresentationModule,
    transitionPresentationModule,
    visualHintModule
  ] = await Promise.all([
    server.ssrLoadModule("/src/core/GameState.ts"),
    server.ssrLoadModule("/src/core/EventBus.ts"),
    server.ssrLoadModule("/src/modules/DeveloperChannel.ts"),
    server.ssrLoadModule("/src/core/QuestModel.ts"),
    server.ssrLoadModule("/src/modules/SaveController.ts"),
    server.ssrLoadModule("/src/core/StorageKeys.ts"),
    server.ssrLoadModule("/src/scenes/rpg/RpgInteractionContract.ts"),
    server.ssrLoadModule("/src/modules/ChapterFourTemporalMazeController.ts"),
    server.ssrLoadModule("/src/modules/ChapterFourStagePresentation.ts"),
    server.ssrLoadModule("/src/modules/ChapterFourTransitionPresentation.ts"),
    server.ssrLoadModule("/src/modules/ChapterFourVisualHintModel.ts")
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
  const {
    CHAPTER_FOUR_TRANSITION_PRESENTATION_VALIDATION,
    CHAPTER_FOUR_TRANSITION_RESUME_STORAGE_KEY,
    getChapterFourTransitionPresentationById,
    selectChapterFourTransitionPresentation,
    selectChapterFourTransitionPresentationOwner
  } = transitionPresentationModule;
  const {
    CHAPTER_FOUR_VISUAL_HINT_VALIDATION,
    clearChapterFourVisualHintPuzzle,
    createChapterFourVisualHintModel,
    recordChapterFourVisualHintFailure,
    selectChapterFourVisualHintSession,
    validateChapterFourVisualHintContracts
  } = visualHintModule;

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
  assert(
    CHAPTER_FOUR_TRANSITION_PRESENTATION_VALIDATION.transitionCount === 8
      && CHAPTER_FOUR_TRANSITION_PRESENTATION_VALIDATION.overlayCount === 4
      && CHAPTER_FOUR_TRANSITION_PRESENTATION_VALIDATION.worldHandoffCount === 4
      && CHAPTER_FOUR_TRANSITION_PRESENTATION_VALIDATION.intentMatchCount === 9,
    "transition runtime validation must cover four time overlays, four in-scene handoffs and nine intent matches"
  );
  assert(
    CHAPTER_FOUR_VISUAL_HINT_VALIDATION.puzzleCount === 9
      && CHAPTER_FOUR_VISUAL_HINT_VALIDATION.maximumFailureCount === 4
      && validateChapterFourVisualHintContracts(
        new Set(layout.evidenceDetails.map((detail) => detail.id))
      ).puzzleCount === 9,
    "adaptive environmental help contracts must cover nine puzzles and only authored raw details"
  );
  let visualHintState = createChapterFourVisualHintModel();
  const visualHintLevels = [];
  const visualHintCounts = [];
  for (let attempt = 0; attempt < 5; attempt += 1) {
    visualHintState = recordChapterFourVisualHintFailure(
      visualHintState,
      "power_route_comparison"
    );
    const session = selectChapterFourVisualHintSession(
      visualHintState,
      "power_route_comparison"
    );
    visualHintLevels.push(session?.level);
    visualHintCounts.push(session?.failureCount);
  }
  const maximumHintSession = selectChapterFourVisualHintSession(
    visualHintState,
    "power_route_comparison"
  );
  assert(
    sameJson(visualHintLevels, [0, 1, 2, 3, 3])
      && sameJson(visualHintCounts, [1, 2, 3, 4, 4])
      && maximumHintSession?.visualEmphasis === true
      && maximumHintSession?.positionalAudio === true
      && maximumHintSession?.pairedEmphasis === true
      && maximumHintSession?.pairedDetailIds.length === 2,
    "adaptive help must preserve raw state on failure one, then add visual, audio and paired-detail emphasis without exceeding four attempts"
  );
  visualHintState = clearChapterFourVisualHintPuzzle(
    visualHintState,
    "power_route_comparison"
  );
  assert(
    selectChapterFourVisualHintSession(visualHintState, "power_route_comparison") === null,
    "accepted puzzle completion must clear its runtime-only adaptive-help session"
  );
  for (const contract of content.transitionContracts) {
    for (const intentType of contract.intentTypes) {
      const result = {
        accepted: true,
        changed: true,
        intentType,
        previousPhase: contract.fromPhase,
        phase: contract.toPhase
      };
      const plan = selectChapterFourTransitionPresentation(result);
      const owner = selectChapterFourTransitionPresentationOwner(result);
      assert(owner === contract.owner, `${contract.id}:${intentType} must resolve its authored presentation owner`);
      if (contract.presentationKind === "time_shift") {
        assert(
          getChapterFourTransitionPresentationById(contract.id)?.id === contract.id
            && plan?.id === contract.id
            && plan.owner === "transition_overlay"
            && plan.change.kind === "time",
          `${contract.id}:${intentType} must resolve one recoverable time-change card`
        );
      } else {
        assert(
          getChapterFourTransitionPresentationById(contract.id) === null
            && plan === null
            && owner === "scene_interaction",
          `${contract.id}:${intentType} must remain an in-scene world handoff`
        );
      }
    }
  }
  assert(
    CHAPTER_FOUR_TRANSITION_RESUME_STORAGE_KEY === "chapter4_transition_resume_v1"
      && getChapterFourTransitionPresentationById("missing-transition") === null,
    "transition resume storage must use one stable versioned key and reject unknown plans"
  );
  assert(
    selectChapterFourTransitionPresentation({
      accepted: true,
      changed: true,
      intentType: "inspect_hall_clock",
      previousPhase: "hall_clock_inspection",
      phase: "hall_clock_inspection"
    }) === null,
    "an accepted intra-phase interaction must not open the transition overlay"
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
    assert(
      REQUIRED_EVIDENCE_FACTS_BY_CHECKPOINT[id].every((factId) => state.chapter4.factIds.includes(factId)),
      `${id} must seed every producer fact required by its completed evidence consumers`
    );
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
  assert(!closure.chapter4.completed && !closure.chapter4.exteriorClosureAcknowledged, "closure waiting seed must not forge completion or acknowledgement");
  assert(!closure.chapter4.factIds.includes("exterior_closure_acknowledged"), "closure waiting seed must not forge closure proof");
  assert(
    !closure.chapter4.factIds.includes("zhu_two_questions_answered")
      && sameJson(closure.chapter4.zhuQuestionAnswers, { purpose: null, person: null })
      && selectQuestViewModel(closure).steps[0]?.id === "chapter_four_answer_zhu_two_questions",
    "closure waiting seed must begin before the two final answers and expose their real submission task"
  );
  const room204Seed = createDeveloperCheckpointState("c4-755-room204-1850");
  assert(
    room204Seed.chapter4.factIds.includes("a3_reference_observed")
      && !room204Seed.chapter4.factIds.includes("zhu_two_questions_answered")
      && selectQuestViewModel(room204Seed).steps[0]?.id === "chapter_four_solve_misaligned_stair",
    "A3 DEV seed must open the stair after the 303 reference without fabricating final Zhu answers"
  );

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
  assert(unverifiedResultRejected, "c4-755-result must stay unavailable because completion is exercised through the closure seed and a real session proof, not a forged DEV result");

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

console.log(`Chapter 4 7:55 Task 14 PASS assertions=${assertionCount} dev=13+aliases+url+session-only quest=single-objective+three-tier-task-copy adaptiveHelp=0-1-2-3+clamped4 stage=13-phases+6-times transitions=4-time+4-world audio=ambient-owner+positioned-detail+zero-closure feedback=detail-codes+host-lookup debug=committed-applied+entities+guards+grid+door+evidence attestation=single-producer+nonce+scene+bounds+finite+spatial`);
