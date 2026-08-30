import fs from "node:fs";
import path from "node:path";
import { createHash } from "node:crypto";
import { fileURLToPath } from "node:url";

const EXPECTED_PHASES = [
  "opening_handoff",
  "opening_paper_caught",
  "hall_clock_inspection",
  "bakery_hour_hand",
  "room204_restore",
  "maintenance_repair",
  "blackout_light_grid",
  "final_chase",
  "final_minute_recovery",
  "return_to_clock",
  "morning_checkin",
  "exterior_closure",
  "complete"
];
const EXPECTED_AUTHORITIES = ["external_evidence", "hall_clock"];
const EXPECTED_TIME_STATES = [
  ["2245_opening", 81900, 28523, false],
  ["1225_bakery", 44700, 44700, true],
  ["1850_evening", 67800, 67800, true],
  ["2245_maintenance", 81900, 81900, true],
  ["0754_blackout", 28440, 28440, true],
  ["0755_morning", 28500, 28500, true]
];
const EXPECTED_ZONE_IDS = [
  "hall",
  "west_corridor",
  "east_corridor",
  "classroom_zone",
  "bakery_back_area"
];
const EXPECTED_ZONE_LABELS = ["大厅", "西走廊", "东走廊", "教室区", "面包店后场"];
const EXPECTED_GUARD_MODES = ["absent", "patrol", "chase"];
const EXPECTED_PHASE_TIME = {
  opening_handoff: ["external_evidence", "2245_opening"],
  opening_paper_caught: ["external_evidence", "2245_opening"],
  hall_clock_inspection: ["external_evidence", "2245_opening"],
  bakery_hour_hand: ["hall_clock", "1225_bakery"],
  room204_restore: ["hall_clock", "1850_evening"],
  maintenance_repair: ["hall_clock", "2245_maintenance"],
  blackout_light_grid: ["hall_clock", "0754_blackout"],
  final_chase: ["hall_clock", "0754_blackout"],
  final_minute_recovery: ["hall_clock", "0754_blackout"],
  return_to_clock: ["hall_clock", "0754_blackout"],
  morning_checkin: ["hall_clock", "0755_morning"],
  exterior_closure: ["hall_clock", "0755_morning"],
  complete: ["hall_clock", "0755_morning"]
};
const EXPECTED_PHASE_GUARD = {
  maintenance_repair: "patrol",
  final_chase: "chase"
};
const EXPECTED_ITEM_STEPS = [
  ["catch_attendance_paper", "attendanceRecordPaper", "a1_noticeboard_paper", "grant"],
  ["reject_external_submission", "attendanceRecordPaper", "external_submission_diagnostic", "retain"],
  ["collect_hour_hand", "oldClockHourHand", "a1_bakery_hour_hand_pickup", "grant"],
  ["install_hour_hand", "oldClockHourHand", "a1_hall_clock_hour_hand_socket", "consume"],
  ["collect_positioning_plate", "clockPositioningPlate", "a2_room204_podium_drawer", "grant"],
  ["install_positioning_plate", "clockPositioningPlate", "a1_hall_clock_positioning_plate_slot", "consume"],
  ["open_cart_wheel_cover", "shortPryBar", "a1_cleaning_cart_wheel_cover", "consume"],
  ["lubricate_cart_wheel", "universalLubricatingOil", "a1_cleaning_cart_wheel", "consume"],
  ["minute_theft", "attendanceRecordPaper", "a1_hall_clock_minute_endpoint", "consume"],
  ["collect_final_minute", "finalMinute", "a2_202_projection", "grant"],
  ["restore_attendance_paper", "attendanceRecordPaper", "a2_202_projection", "grant"],
  ["install_final_minute", "finalMinute", "a1_hall_clock_minute_endpoint", "consume"],
  ["read_campus_card", "campusCard", "a1_campus_card_reader", "retain"],
  ["submit_attendance_paper", "attendanceRecordPaper", "a1_attendance_paper_slot", "retain"]
];
const REQUIRED_ATOMIC_FIELDS = [
  "phase",
  "timeAuthority",
  "timeState",
  "worldTimeSeconds",
  "phoneStatusTimeSeconds",
  "phoneStatusTimeTrusted",
  "activePlateId",
  "availableTargetIds",
  "rpgCheckpoint"
];
const EXPECTED_OPENING_INTENTS = [
  "complete_prologue_handoff",
  "complete_opening_paper_flight",
  "catch_attendance_paper",
  "resolve_external_time_rejection",
  "inspect_hall_clock",
  "resolve_hall_clock_inspection",
  "pull_hall_clock"
];
const EXPECTED_BAKERY_INTENTS = [
  "inspect_bakery_conveyor_lamp",
  "complete_bakery_conveyor_stop",
  "collect_hour_hand",
  "install_hour_hand"
];
const EXPECTED_BAKERY_TARGET_IDS = [
  "a1_bakery_inspection_lamp",
  "a1_bakery_conveyor_edge",
  "a1_bakery_hour_hand_pickup",
  "a1_hall_clock_hour_hand_socket"
];
const EXPECTED_BAKERY_FACTS = [
  "bakery_conveyor_lamp_inspected",
  "bakery_hour_hand_exposed",
  "bakery_hour_hand_collected",
  "hour_hand_installed"
];
const EXPECTED_BAKERY_TIMELINE = [0, 120, 360, 520, 700];
const EXPECTED_BAKERY_REFRESH_IDS = [
  "lamp_uninspected",
  "lamp_inspected_stop_incomplete",
  "hour_hand_exposed",
  "hour_hand_collected",
  "hour_hand_installed"
];
const EXPECTED_BAKERY_CUES = [
  "chapter4_bakery_approach",
  "chapter4_bakery_conveyor_stop",
  "chapter4_bakery_hour_hand_revealed"
];
const EXPECTED_ROOM204_TASK_KEYS = [
  "resolve_a1_investigation",
  "verify_a1_classrooms",
  "observe_elevator_history",
  "calibrate_elevator_history",
  "resolve_a3_archive_chain",
  "observe_a3_reference",
  "answer_zhu_two_questions",
  "solve_misaligned_stair",
  "observe_room204_residual",
  "restore_room204",
  "watch_room204_projection",
  "collect_positioning_plate",
  "resolve_a2_inserted_puzzles",
  "install_positioning_plate"
];
const EXPECTED_ROOM204_FACTS = [
  "classroom_104_chalk_residual_observed",
  "classroom_105_terminal_replay_checked",
  "elevator_history_observed",
  "elevator_history_calibrated",
  "a1_duty_board_reconstructed",
  "a3_archive_film_retrieved",
  "a3_media_alignment_completed",
  "a3_reference_observed",
  "zhu_two_questions_answered",
  "misaligned_stair_solved",
  "room204_residual_observed",
  "room204_restored",
  "room204_projection_completed",
  "positioning_plate_collected",
  "a2_positioning_plate_calibrated",
  "a2_power_topology_recovered",
  "a2_evacuation_route_confirmed",
  "positioning_plate_installed"
];
const EXPECTED_MAINTENANCE_TASK_KEYS = [
  "inspect_cart_wheel",
  "open_cart_wheel_cover",
  "lubricate_cart_wheel",
  "turn_clock_to_0755"
];
const EXPECTED_MAINTENANCE_TARGET_IDS = [
  "a1_cleaning_cart_wheel_inspection",
  "a1_bakery_back_pry_bar",
  "a1_cleaning_cart_wheel_cover",
  "a1_cleaning_cart_oil_bottle",
  "a1_cleaning_cart_wheel",
  "a1_hall_clock_gear"
];
const EXPECTED_MAINTENANCE_FACTS = [
  "cart_wheel_inspected",
  "cart_wheel_cover_opened",
  "cart_wheel_repaired",
  "clock_gear_repaired"
];
const EXPECTED_TASK_KEYS_BY_ACTIVE_PHASE = Object.freeze({
  opening_handoff: ["catch_opening_paper"],
  opening_paper_caught: ["inspect_hall_clock"],
  hall_clock_inspection: ["pull_hall_clock"],
  bakery_hour_hand: ["explore_bakery", "collect_hour_hand", "install_hour_hand"],
  room204_restore: EXPECTED_ROOM204_TASK_KEYS,
  maintenance_repair: EXPECTED_MAINTENANCE_TASK_KEYS,
  blackout_light_grid: ["solve_light_grid"],
  final_chase: ["reach_lecture_202"],
  final_minute_recovery: ["collect_final_minute"],
  return_to_clock: ["return_via_main_stair", "install_final_minute"],
  morning_checkin: ["complete_checkin", "read_campus_card", "submit_attendance_paper"],
  exterior_closure: ["acknowledge_exterior_closure"]
});

const defaultContentPath = fileURLToPath(
  new URL("../src/data/chapter4-755.content.json", import.meta.url)
);
const task7H3AssetPath = fileURLToPath(new URL(
  "../src/assets/rpg/cinematics/chapter4-prologue/chapter35_to_chapter4_h3_transition.mp4",
  import.meta.url
));
const task7H3ManifestPath = fileURLToPath(new URL(
  "../src/data/chapter4-prologue-h3.asset.json",
  import.meta.url
));
const task7H3RuntimeMusicPath = fileURLToPath(new URL(
  "../src/assets/audio/chapter4/prologue/music_ch4_prologue_h3_44s.mp3",
  import.meta.url
));
const TASK7_H3_SHA256 = "d5cb9e9a91ef778337f5eeef74fad59643ca1f393607f993d7e5fc8196678aff";
const TASK7_H3_SIZE_BYTES = 8282814;
const TASK7_H3_MEDIA_SOURCE_TYPE = "video/mp4; codecs=\"avc1.640028\"";
const TASK7_H3_RUNTIME_MUSIC_SHA256 = "0b8e5a0eb47f431af5d96f13b9bbff07580419b1641de9e6637fa59d7c4685c6";
const task7RuntimeSourcePaths = Object.freeze({
  timeline: fileURLToPath(new URL(
    "../src/scenes/rpg/chapter4-prologue/PrologueTimeline.ts",
    import.meta.url
  )),
  overlay: fileURLToPath(new URL(
    "../src/scenes/rpg/Chapter4PrologueOverlay.tsx",
    import.meta.url
  )),
  viteConfig: fileURLToPath(new URL(
    "../vite.config.ts",
    import.meta.url
  )),
  viteEnv: fileURLToPath(new URL(
    "../src/vite-env.d.ts",
    import.meta.url
  )),
  app: fileURLToPath(new URL(
    "../src/App.tsx",
    import.meta.url
  )),
  prologueGate: fileURLToPath(new URL(
    "../src/components/Chapter4PrologueRuntimeGate.tsx",
    import.meta.url
  )),
  rpgRuntimePreload: fileURLToPath(new URL(
    "../src/scenes/rpg/RpgRuntimePreload.ts",
    import.meta.url
  )),
  timelineRecovery: fileURLToPath(new URL(
    "../src/scenes/phone/P20_TimelineRecovery/index.tsx",
    import.meta.url
  )),
  interludeController: fileURLToPath(new URL(
    "../src/modules/ChapterThreePhoneInterludeController.ts",
    import.meta.url
  )),
  host: fileURLToPath(new URL(
    "../src/scenes/rpg/RpgGameHost.tsx",
    import.meta.url
  )),
  rpgCss: fileURLToPath(new URL(
    "../src/styles/rpg.css",
    import.meta.url
  )),
  scene: fileURLToPath(new URL(
    "../src/scenes/rpg/ChapterFourTemporalMazeScene.ts",
    import.meta.url
  )),
  quest: fileURLToPath(new URL(
    "../src/core/QuestModel.ts",
    import.meta.url
  )),
  controller: fileURLToPath(new URL(
    "../src/modules/ChapterFourTemporalMazeController.ts",
    import.meta.url
  )),
  stagePresentation: fileURLToPath(new URL(
    "../src/modules/ChapterFourStagePresentation.ts",
    import.meta.url
  )),
  closureContract: fileURLToPath(new URL(
    "../src/modules/ChapterFourClosureContract.ts",
    import.meta.url
  )),
  saveStore: fileURLToPath(new URL(
    "../src/core/SaveStore.ts",
    import.meta.url
  )),
  interaction: fileURLToPath(new URL(
    "../src/scenes/rpg/RpgInteractionContract.ts",
    import.meta.url
  )),
  room204Model: fileURLToPath(new URL(
    "../src/scenes/rpg/ChapterFourRoom204Model.ts",
    import.meta.url
  )),
  guardModel: fileURLToPath(new URL(
    "../src/modules/ChapterFourGuardModel.ts",
    import.meta.url
  )),
  lightGridModel: fileURLToPath(new URL(
    "../src/modules/ChapterFourLightGridModel.ts",
    import.meta.url
  )),
  finalChaseModel: fileURLToPath(new URL(
    "../src/modules/ChapterFourFinalChaseModel.ts",
    import.meta.url
  )),
  powerPanel: fileURLToPath(new URL(
    "../src/components/temporal-maze/ChapterFourPowerPanelGame.tsx",
    import.meta.url
  )),
  powerPanelCss: fileURLToPath(new URL(
    "../src/styles/chapter4-755.css",
    import.meta.url
  )),
  types: fileURLToPath(new URL(
    "../src/core/types.ts",
    import.meta.url
  ))
});

function parseContentPath(argv) {
  let selected = defaultContentPath;
  for (let index = 0; index < argv.length; index += 1) {
    const argument = argv[index];
    if (argument === "--content") {
      const value = argv[index + 1];
      if (!value || value.startsWith("--")) {
        throw new Error("--content requires a JSON file path");
      }
      selected = path.resolve(value);
      index += 1;
      continue;
    }
    if (argument.startsWith("--content=")) {
      const value = argument.slice("--content=".length);
      if (!value) throw new Error("--content requires a JSON file path");
      selected = path.resolve(value);
      continue;
    }
    throw new Error(`unknown argument: ${argument}`);
  }

  return selected;
}

function isRecord(value) {
  return typeof value === "object" && value !== null && !Array.isArray(value);
}

function sameArray(actual, expected) {
  return Array.isArray(actual)
    && actual.length === expected.length
    && actual.every((value, index) => value === expected[index]);
}

function nonEmptyString(value) {
  return typeof value === "string" && value.trim().length > 0;
}

function setEquals(actual, expected) {
  return actual.size === expected.size && [...expected].every((value) => actual.has(value));
}

function parseIsoBmffBoxes(bytes, start = 0, end = bytes.length) {
  const boxes = [];
  let offset = start;
  while (offset + 8 <= end) {
    let size = bytes.readUInt32BE(offset);
    const type = bytes.subarray(offset + 4, offset + 8).toString("ascii");
    let headerSize = 8;
    if (size === 1) {
      if (offset + 16 > end) return null;
      const extendedSize = bytes.readBigUInt64BE(offset + 8);
      if (extendedSize > BigInt(Number.MAX_SAFE_INTEGER)) return null;
      size = Number(extendedSize);
      headerSize = 16;
    } else if (size === 0) {
      size = end - offset;
    }
    if (size < headerSize || offset + size > end) return null;
    boxes.push({
      type,
      payloadStart: offset + headerSize,
      end: offset + size
    });
    offset += size;
  }
  return offset === end ? boxes : null;
}

function scanForbiddenTerminal(value, errors, valuePath = "content") {
  if (typeof value === "number" && value === 28800) {
    errors.push(`${valuePath} contains forbidden legacy terminal second 28800`);
    return;
  }
  if (typeof value === "string") {
    if (/08:00/i.test(value)) {
      errors.push(`${valuePath} contains forbidden legacy terminal time 08:00`);
    }
    if (/b2[-_\s]?0?4/i.test(value)) {
      errors.push(`${valuePath} contains forbidden legacy terminal room B2-04`);
    }
    return;
  }
  if (Array.isArray(value)) {
    value.forEach((entry, index) => scanForbiddenTerminal(entry, errors, `${valuePath}[${index}]`));
    return;
  }
  if (!isRecord(value)) return;
  for (const [key, entry] of Object.entries(value)) {
    scanForbiddenTerminal(entry, errors, `${valuePath}.${key}`);
  }
}

function findReachableMask(initialMask, targetMask, toggleMasks) {
  const queue = [{ mask: initialMask, path: [] }];
  const visited = new Set([initialMask]);
  while (queue.length > 0) {
    const current = queue.shift();
    if (current.mask === targetMask) return current.path;
    for (let index = 0; index < toggleMasks.length; index += 1) {
      const nextMask = current.mask ^ toggleMasks[index];
      if (visited.has(nextMask)) continue;
      visited.add(nextMask);
      queue.push({ mask: nextMask, path: [...current.path, index] });
    }
  }
  return null;
}

function readTask7RuntimeSources(errors) {
  const sources = {};
  for (const [id, sourcePath] of Object.entries(task7RuntimeSourcePaths)) {
    try {
      sources[id] = fs.readFileSync(sourcePath, "utf8");
    } catch (error) {
      errors.push(`Task 7 runtime source ${id} cannot be read: ${error instanceof Error ? error.message : String(error)}`);
    }
  }
  return sources;
}

function validateTask7H3Asset(errors) {
  let bytes;
  let manifest;
  let runtimeMusicBytes;
  try {
    bytes = fs.readFileSync(task7H3AssetPath);
  } catch (error) {
    errors.push(`Task 7 H3 transition asset cannot be read: ${error instanceof Error ? error.message : String(error)}`);
    return;
  }
  try {
    manifest = JSON.parse(fs.readFileSync(task7H3ManifestPath, "utf8"));
  } catch (error) {
    errors.push(`Task 7 H3 transition manifest cannot be read: ${error instanceof Error ? error.message : String(error)}`);
    return;
  }
  try {
    runtimeMusicBytes = fs.readFileSync(task7H3RuntimeMusicPath);
  } catch (error) {
    errors.push(`Task 7 H3 runtime music cannot be read: ${error instanceof Error ? error.message : String(error)}`);
  }

  const sha256 = createHash("sha256").update(bytes).digest("hex");
  const runtimeMusicSha256 = runtimeMusicBytes
    ? createHash("sha256").update(runtimeMusicBytes).digest("hex")
    : "";
  const topLevelBoxes = parseIsoBmffBoxes(bytes);
  const moovBox = topLevelBoxes?.find((box) => box.type === "moov");
  const moovChildren = moovBox
    ? parseIsoBmffBoxes(bytes, moovBox.payloadStart, moovBox.end)
    : null;
  if (bytes.length !== TASK7_H3_SIZE_BYTES
    || sha256 !== TASK7_H3_SHA256
    || topLevelBoxes?.[0]?.type !== "ftyp"
    || !topLevelBoxes.some((box) => box.type === "moof")
    || !topLevelBoxes.some((box) => box.type === "mdat")
    || !moovChildren?.some((box) => box.type === "mvex")) {
    errors.push("Task 7 H3 transition MP4 must match the checked-in fragmented 960x540 silent asset with valid ftyp/moov/mvex/moof/mdat boxes");
  }
  if (!isRecord(manifest)
    || manifest.version !== 1
    || manifest.assetId !== "chapter35_to_chapter4_h3_transition"
    || manifest.sourcePath !== "src/assets/rpg/cinematics/chapter4-prologue/chapter35_to_chapter4_h3_transition.mp4"
    || manifest.width !== 960
    || manifest.height !== 540
    || manifest.frameRate !== 24
    || manifest.frameCount !== 1052
    || manifest.durationMs !== 43833.333
    || manifest.taskCardAtMs !== 43834
    || manifest.videoCodec !== "h264"
    || manifest.pixelFormat !== "yuv420p"
    || manifest.audioTracks !== 0
    || manifest.containerMode !== "fragmented_mp4"
    || manifest.mediaSourceType !== TASK7_H3_MEDIA_SOURCE_TYPE
    || manifest.sha256 !== TASK7_H3_SHA256
    || manifest.runtimeAudioAuthority !== "src/data/chapter4-prologue.audio.json"
    || manifest.runtimeMusicPath !== "src/assets/audio/chapter4/prologue/music_ch4_prologue_h3_44s.mp3"
    || manifest.runtimeMusicDurationMs !== 44000
    || manifest.runtimeMusicBitRate !== 64306
    || manifest.runtimeMusicSha256 !== TASK7_H3_RUNTIME_MUSIC_SHA256
    || runtimeMusicSha256 !== TASK7_H3_RUNTIME_MUSIC_SHA256) {
    errors.push("Task 7 H3 transition manifest must preserve the verified silent-video contract and the exact 44-second runtime music path, duration, bitrate and hash");
  }
  const expectedInputs = [
    [1, "img2video-31233a69-f533-4741-afe6-7ccfdf06ba25.mp4", "3bc8b7b37f36fc34054e818a4dd2e62fc84f26147596e72c9dd6a31de7fbeb0e"],
    [2, "flying-paper-arcade.mp4", "1a0432d4e4eaa8748e86c6560987ac1283adb2b87a6711026d2e13afc9361c89"],
    [3, "09532bd73d59913e21df487ca7ee1629_raw.mp4", "c80bfa3da25109673f0f1965e243719e18f6a35c3778687ffda0e060eb05043e"]
  ];
  if (!Array.isArray(manifest?.inputs)
    || manifest.inputs.length !== expectedInputs.length
    || expectedInputs.some(([order, fileName, inputSha256], index) => {
      const input = manifest.inputs[index];
      return !isRecord(input)
        || input.order !== order
        || input.fileName !== fileName
        || input.sha256 !== inputSha256;
    })
    || !sameArray(manifest?.sceneCutsMs, [0, 6708, 13667, 23542, 28750, 33417, 41042, 43834])) {
    errors.push("Task 7 H3 transition manifest must lock the approved three-clip order and scene cuts");
  }
}

function validateTask7RuntimeSources(errors) {
  const sources = readTask7RuntimeSources(errors);
  const timeline = sources.timeline ?? "";
  const overlay = sources.overlay ?? "";
  const viteConfig = sources.viteConfig ?? "";
  const viteEnv = sources.viteEnv ?? "";
  const app = sources.app ?? "";
  const prologueGate = sources.prologueGate ?? "";
  const rpgRuntimePreload = sources.rpgRuntimePreload ?? "";
  const timelineRecovery = sources.timelineRecovery ?? "";
  const interludeController = sources.interludeController ?? "";
  const host = sources.host ?? "";
  const rpgCss = sources.rpgCss ?? "";
  const scene = sources.scene ?? "";
  const quest = sources.quest ?? "";
  const controller = sources.controller ?? "";
  const stagePresentation = sources.stagePresentation ?? "";
  const closureContract = sources.closureContract ?? "";
  const saveStore = sources.saveStore ?? "";
  const interaction = sources.interaction ?? "";
  const room204Model = sources.room204Model ?? "";
  const guardModel = sources.guardModel ?? "";
  const lightGridModel = sources.lightGridModel ?? "";
  const finalChaseModel = sources.finalChaseModel ?? "";
  const powerPanel = sources.powerPanel ?? "";
  const powerPanelCss = sources.powerPanelCss ?? "";
  const types = sources.types ?? "";
  const controllerResolverStart = controller.indexOf("  resolve755Intent(");
  const controllerResolverEnd = controller.indexOf("\n  /**\n   * Applies the phase", controllerResolverStart);
  const controllerIntentResolver = controllerResolverStart >= 0
    && controllerResolverEnd > controllerResolverStart
    ? controller.slice(controllerResolverStart, controllerResolverEnd)
    : "";

  const taskCardMatch = timeline.match(/export const PROLOGUE_TASK_CARD_AT\s*=\s*(\d+)\s*;/);
  if (Number(taskCardMatch?.[1]) !== 43834) {
    errors.push("Task 7 prologue task card must be fixed at 43834ms for the joined H3 transition");
  }
  const phasesBlock = timeline.match(/export const PROLOGUE_PHASES\s*=\s*\[([\s\S]*?)\]\s*as const;/)?.[1] ?? "";
  const activePhaseIds = [...phasesBlock.matchAll(/id:\s*"([^"]+)"/g)].map((match) => match[1]);
  if (!sameArray(activePhaseIds, ["snap", "lake_exit", "arcade", "entrance", "lobby", "closing"])) {
    errors.push("Task 7 prologue active phases must cover the complete joined H3 transition");
  }
  const beatBlock = timeline.match(/export const PROLOGUE_BEATS[\s\S]*?=\s*\[([\s\S]*?)\];/)?.[1] ?? "";
  const numericBeatTimes = [...beatBlock.matchAll(/at:\s*(\d+)/g)].map((match) => Number(match[1]));
  if (numericBeatTimes.some((at) => at > 43834)
    || !/chapter4_prologue_wet_floor/.test(beatBlock)
    || !/at:\s*29450,\s*cueEvent:\s*"chapter4_prologue_cleaner_line"/.test(beatBlock)
    || !/at:\s*36000,\s*cueEvent:\s*"chapter4_prologue_guard_line"/.test(beatBlock)
    || !/chapter4_prologue_broadcast_static/.test(beatBlock)
    || !/chapter4_prologue_lights_out/.test(beatBlock)) {
    errors.push("Task 7 prologue beats must align the cleaner and guard voice repair with the joined H3 lobby and closing scenes");
  }
  if (!/runtime\.elapsedMs\s*=\s*Math\.min\(PROLOGUE_TASK_CARD_AT/.test(overlay)
    || !/runtime\.elapsedMs\s*=\s*PROLOGUE_TASK_CARD_AT\s*;/.test(overlay)) {
    errors.push("Task 7 prologue advance and skip paths must both clamp to PROLOGUE_TASK_CARD_AT");
  }
  if (/getProloguePortrait|key:\s*"cleaner"|key:\s*"guard"/.test(overlay)) {
    errors.push("Task 7 fallback portrait branch must remain limited to the departing student");
  }
  if (!/import\s+h3TransitionSource\s+from\s+["'][^"']*chapter35_to_chapter4_h3_transition\.mp4\?chapter4-h3-embedded["']\s*;/.test(overlay)
    || (overlay.match(/chapter35_to_chapter4_h3_transition\.mp4\?chapter4-h3-embedded/g) ?? []).length !== 1
    || !/<video/.test(overlay)
    || !/\bmuted\b/.test(overlay)
    || !/\bplaysInline\b/.test(overlay)
    || !/onError=\{markVideoFailed\}/.test(overlay)
    || !/createEmbeddedVideoMediaSource\(\s*chunks,\s*H3_TRANSITION_MIME_TYPE,\s*abortController\.signal\s*\)/.test(overlay)
    || !/data-h3-source=/.test(overlay)
    || !/<canvas/.test(overlay)
    || !/prefersReducedMotion/.test(overlay)) {
    errors.push("Task 7 overlay must play the silent H3 asset through a single-file-safe source and preserve the canvas fallback");
  }
  if (!/const\s+CHAPTER4_H3_EMBEDDED_QUERY\s*=\s*["']chapter4-h3-embedded["']\s*;/.test(viteConfig)
    || !/const\s+CHAPTER4_H3_BASE64_CHUNK_SIZE\s*=\s*256\s*\*\s*1024\s*;/.test(viteConfig)
    || !/defineConfig,\s*normalizePath,\s*type\s+Plugin/.test(viteConfig)
    || !/const\s+CHAPTER4_H3_SOURCE_PATH\s*=\s*normalizePath\(resolve\([\s\S]*?["']src\/assets\/rpg\/cinematics\/chapter4-prologue\/chapter35_to_chapter4_h3_transition\.mp4["'][\s\S]*?\)\)\s*;/.test(viteConfig)
    || !/function\s+embedChapter4H3AsChunks\(\):\s*Plugin\s*\{/.test(viteConfig)
    || !/name:\s*["']embed-chapter4-h3-as-chunks["'][\s\S]*?apply:\s*["']build["'][\s\S]*?enforce:\s*["']pre["'][\s\S]*?load\(id\)/.test(viteConfig)
    || !/const\s+filePath\s*=\s*normalizePath\(id\.slice\(0,\s*queryIndex\)\)\s*;/.test(viteConfig)
    || !/query\.has\(CHAPTER4_H3_EMBEDDED_QUERY\)/.test(viteConfig)
    || !/filePath\s*!==\s*CHAPTER4_H3_SOURCE_PATH/.test(viteConfig)
    || !/this\.addWatchFile\(filePath\)/.test(viteConfig)
    || !/readFileSync\(filePath\)\.toString\(["']base64["']\)/.test(viteConfig)
    || !/for\s*\(let\s+offset\s*=\s*0;\s*offset\s*<\s*base64\.length;\s*offset\s*\+=\s*CHAPTER4_H3_BASE64_CHUNK_SIZE\)/.test(viteConfig)
    || !/chunks\.push\(base64\.slice\(offset,\s*offset\s*\+\s*CHAPTER4_H3_BASE64_CHUNK_SIZE\)\)/.test(viteConfig)
    || !/kind:\s*["']embedded_chunks["'][\s\S]*?chunks/.test(viteConfig)
    || !viteConfig.includes('mimeType: "video/mp4; codecs=\\"avc1.640028\\""')
    || (viteConfig.match(/embedChapter4H3AsChunks\(\)/g) ?? []).length !== 2
    || !/plugins:\s*\[\s*embedChapter4H3AsChunks\(\),\s*react\(\),\s*viteSingleFile/.test(viteConfig)
    || !/\}\s*:\s*\{\s*plugins:\s*\[react\(\)\]/.test(viteConfig)) {
    errors.push("Task 7 single-file build must pre-embed only the queried H3 MP4 as independent 256KiB base64 chunks while normal Vite keeps the direct asset URL");
  }
  if (!/declare\s+module\s+["']\*\?chapter4-h3-embedded["']/.test(viteEnv)
    || !/const\s+source:\s*string\s*\|\s*\{[\s\S]*?kind:\s*["']embedded_chunks["'];[\s\S]*?chunks:\s*string\[\];[\s\S]*?\}/.test(viteEnv)
    || !viteEnv.includes('mimeType: "video/mp4; codecs=\\"avc1.640028\\"";')) {
    errors.push("Task 7 H3 query module must type normal Vite output as a URL string and single-file output as embedded chunks");
  }

  const preloadFunction = rpgRuntimePreload.match(
    /export function preloadRpgGameHost\(\): Promise<RpgGameHostModule>\s*\{([\s\S]*?)\n\}/
  )?.[1] ?? "";
  if (!/^type\s+RpgGameHostModule\s*=\s*typeof\s+import\(["']\.\/RpgGameHost["']\)\s*;/m.test(rpgRuntimePreload)
    || !/^let\s+rpgGameHostModulePromise:\s*Promise<RpgGameHostModule>\s*\|\s*null\s*=\s*null\s*;/m.test(rpgRuntimePreload)
    || (preloadFunction.match(/import\(["']\.\/RpgGameHost["']\)/g) ?? []).length !== 1
    || !/if\s*\(!rpgGameHostModulePromise\)\s*\{\s*rpgGameHostModulePromise\s*=\s*import\(["']\.\/RpgGameHost["']\)\.catch\(\(error:\s*unknown\)\s*=>\s*\{\s*rpgGameHostModulePromise\s*=\s*null\s*;\s*throw\s+error\s*;\s*\}\)\s*;\s*\}\s*return\s+rpgGameHostModulePromise\s*;/.test(preloadFunction)) {
    errors.push("Task 7 RPG preload must cache one shared RpgGameHost dynamic-import Promise and clear the cache after rejection so a later retry can start a new import");
  }
  if (!/import\s*\{\s*preloadRpgGameHost\s*\}\s*from\s*["']\.\/scenes\/rpg\/RpgRuntimePreload["']\s*;/.test(app)
    || !/const\s+RpgGameHost\s*=\s*lazy\(\(\)\s*=>\s*preloadRpgGameHost\(\)\.then\(\(module\)\s*=>\s*\(\{\s*default:\s*module\.RpgGameHost\s*\}\)\)\s*\)\s*;/.test(app)
    || /lazy\(\(\)\s*=>\s*import\(["'][^"']*RpgGameHost["']\)/.test(app)) {
    errors.push("Task 7 App lazy boundary must reuse preloadRpgGameHost instead of creating a second RpgGameHost import Promise");
  }

  const startReplayStart = timelineRecovery.indexOf("  function startReplay()");
  const startReplayEnd = timelineRecovery.indexOf("\n\n  function rejectDecoy", startReplayStart);
  const startReplayBlock = startReplayStart >= 0 && startReplayEnd > startReplayStart
    ? timelineRecovery.slice(startReplayStart, startReplayEnd)
    : "";
  const destinationReplayStart = timelineRecovery.indexOf("{destinationVerified ? (");
  const destinationReplayEnd = timelineRecovery.indexOf("        {feedback ?", destinationReplayStart);
  const destinationReplayBlock = destinationReplayStart >= 0 && destinationReplayEnd > destinationReplayStart
    ? timelineRecovery.slice(destinationReplayStart, destinationReplayEnd)
    : "";
  const recoveredReplayMutationStart = interludeController.indexOf("  startRecoveredReplay():");
  const recoveredReplayMutationEnd = interludeController.indexOf("\n\n  private recordNetworkFact", recoveredReplayMutationStart);
  const recoveredReplayMutation = recoveredReplayMutationStart >= 0
    && recoveredReplayMutationEnd > recoveredReplayMutationStart
    ? interludeController.slice(recoveredReplayMutationStart, recoveredReplayMutationEnd)
    : "";
  const recoveredReplayStateWriteIndex = recoveredReplayMutation.indexOf("this.store.setState(");
  const recoveredReplayGateEventIndex = recoveredReplayMutation.indexOf(
    'this.events.emit("chapter35_recovered_replay_gate_requested"'
  );
  if (/preloadRpgGameHost|RpgRuntimePreload|rpgRuntimeStatus|prepareRpgRuntime/.test(timelineRecovery)
    || !/kit\.chapterThreeInterlude\.startRecoveredReplay\(\)/.test(startReplayBlock)
    || (timelineRecovery.match(/kit\.chapterThreeInterlude\.startRecoveredReplay\(\)/g) ?? []).length !== 1
    || /runtimeMode\s*:/.test(timelineRecovery)
    || !/destinationVerified\s*\?/.test(destinationReplayBlock)
    || !/onClick=\{startReplay\}/.test(destinationReplayBlock)
    || recoveredReplayStateWriteIndex < 0
    || recoveredReplayGateEventIndex <= recoveredReplayStateWriteIndex
    || !/chapterThreeInterlude:\s*\{[\s\S]*?phase:\s*["']replay_ready["'][\s\S]*?replayUnlocked:\s*true/.test(recoveredReplayMutation)
    || !/this\.events\.emit\(["']chapter35_recovered_replay_gate_requested["'],\s*\{\s*destinationId:\s*["']duan_yongping_a1["']\s*\}\s*\)/.test(recoveredReplayMutation)
    || /preloadRpgGameHost|runtimeMode\s*:|chapter35_recovered_replay_requested|\b(?:audio|music)\b/i.test(recoveredReplayMutation)
    || !/chapter35_recovered_replay_gate_requested[\s\S]*?void\s+warmRpgRuntime\(\s*["']duan_yongping_temporal_maze["'],\s*["']immediate["'],\s*["']entry["']\s*\)/.test(prologueGate)) {
    errors.push("Task 7 P20 must avoid mount-time preload, expose replay only after the correct destination, and let the controller commit replay_ready before the App gate starts preload");
  }

  if (!/const\s+H3_TRANSITION_IS_EMBEDDED\s*=\s*typeof\s+h3TransitionSource\s*!==\s*["']string["']\s*;/.test(overlay)
    || !/const\s+H3_TRANSITION_URL\s*=\s*typeof\s+h3TransitionSource\s*===\s*["']string["']\s*\?\s*h3TransitionSource\s*:\s*["']["']\s*;/.test(overlay)
    || !/const\s+H3_TRANSITION_CHUNKS\s*=\s*typeof\s+h3TransitionSource\s*===\s*["']string["']\s*\?\s*null\s*:\s*h3TransitionSource\.chunks\s*;/.test(overlay)
    || !/useState\(\s*H3_TRANSITION_IS_EMBEDDED\s*\?\s*["']["']\s*:\s*H3_TRANSITION_URL\s*\)/.test(overlay)
    || !overlay.includes('"video/mp4; codecs=\\"avc1.640028\\""')
    || !/const\s+EMBEDDED_VIDEO_CHUNK_SIZE\s*=\s*256\s*\*\s*1024\s*;/.test(overlay)
    || !/const\s+EMBEDDED_VIDEO_CONVERSION_TIMEOUT_MS\s*=\s*20000\s*;/.test(overlay)
    || !/EMBEDDED_VIDEO_WORKER_SOURCE/.test(overlay)
    || !/const\s+chunk\s*=\s*event\.data\s*&&\s*event\.data\.chunk\s*;/.test(overlay)
    || !/atob\(chunk\)/.test(overlay)
    || !/new ArrayBuffer\(binary\.length\)/.test(overlay)
    || !/new Uint8Array\(buffer\)/.test(overlay)
    || !/self\.postMessage\(\s*\{\s*ok:\s*true,\s*buffer,\s*final:\s*Boolean\(event\.data\.final\)\s*\},\s*\[buffer\]\s*\)/.test(overlay)
    || !/\|\s*\{\s*ok:\s*true;\s*buffer:\s*ArrayBuffer;\s*final:\s*boolean\s*\}/.test(overlay)
    || !/new Worker\(workerScriptUrl\)/.test(overlay)
    || !/function\s+createEmbeddedVideoMediaSource\(\s*chunks:\s*readonly\s+string\[\],\s*mimeType:\s*string,\s*signal:\s*AbortSignal\s*\):\s*EmbeddedVideoMediaSource/.test(overlay)
    || !/typeof\s+MediaSource\s*===\s*["']undefined["']\s*\|\|\s*!MediaSource\.isTypeSupported\(mimeType\)/.test(overlay)
    || !/chunks\.some\(\(chunk,\s*index\)\s*=>\s*\([\s\S]*?chunk\.length\s*%\s*4\s*!==\s*0[\s\S]*?index\s*<\s*chunks\.length\s*-\s*1\s*&&\s*chunk\.length\s*!==\s*EMBEDDED_VIDEO_CHUNK_SIZE/.test(overlay)
    || !/const\s+mediaSource\s*=\s*new MediaSource\(\)\s*;/.test(overlay)
    || !/const\s+videoObjectUrl\s*=\s*URL\.createObjectURL\(mediaSource\)\s*;/.test(overlay)
    || !/let\s+nextChunkIndex\s*=\s*0\s*;/.test(overlay)
    || !/let\s+inFlightFinal\s*=\s*false\s*;/.test(overlay)
    || !/let\s+appendedFinal\s*=\s*false\s*;/.test(overlay)
    || !/const\s+chunk\s*=\s*chunks\[nextChunkIndex\]\s*;/.test(overlay)
    || !/inFlightFinal\s*=\s*nextChunkIndex\s*===\s*chunks\.length\s*-\s*1\s*;/.test(overlay)
    || !/nextChunkIndex\s*\+=\s*1\s*;/.test(overlay)
    || !/worker\.postMessage\(\s*\{\s*chunk,\s*final:\s*inFlightFinal\s*\}\s*\)/.test(overlay)
    || !/event\.data\.buffer\s+instanceof\s+ArrayBuffer\)\s*\|\|\s*event\.data\.final\s*!==\s*inFlightFinal/.test(overlay)
    || !/!sourceBuffer\s*\|\|\s*sourceBuffer\.updating[\s\S]*?sourceBuffer\.appendBuffer\(event\.data\.buffer\)/.test(overlay)
    || !/sourceBuffer\s*=\s*mediaSource\.addSourceBuffer\(mimeType\)\s*;/.test(overlay)
    || !/sourceBuffer\.addEventListener\(["']updateend["'],\s*handleUpdateEnd\)/.test(overlay)
    || !/if\s*\(appendedFinal\)[\s\S]*?nextChunkIndex\s*!==\s*chunks\.length[\s\S]*?finish\(\)[\s\S]*?sendNextChunk\(\)/.test(overlay)
    || !/mediaSource\.readyState\s*!==\s*["']open["'][\s\S]*?mediaSource\.endOfStream\(\)/.test(overlay)
    || !/mediaSource\.addEventListener\(["']sourceopen["'],\s*handleSourceOpen,\s*\{\s*once:\s*true\s*\}\)/.test(overlay)
    || /dataUrl\.slice\(/.test(overlay)
    || /new Blob\((?:parts|buffers)\b/.test(overlay)
    || /URL\.createObjectURL\(blob\)/.test(overlay)
    || /self\.postMessage\(\s*\{\s*ok:\s*true,\s*(?:blob|videoObjectUrl)\b/.test(overlay)
    || /\|\s*\{\s*ok:\s*true;\s*(?:blob:\s*Blob|videoObjectUrl:\s*string)/.test(overlay)) {
    errors.push("Task 7 embedded H3 source must use a supported MediaSource pipeline with transferable worker buffers, serial SourceBuffer appends, and endOfStream after the final fragment");
  }
  if ((overlay.match(/signal\.aborted/g) ?? []).length < 2
    || !/signal\.addEventListener\(["']abort["'],\s*handleAbort,\s*\{\s*once:\s*true\s*\}\)/.test(overlay)
    || !/let\s+detached\s*=\s*false\s*;/.test(overlay)
    || !/if\s*\(detached\)\s*return\s*;\s*detached\s*=\s*true\s*;/.test(overlay)
    || !/worker\.onmessage\s*=\s*null\s*;/.test(overlay)
    || !/worker\.onerror\s*=\s*null\s*;/.test(overlay)
    || !/worker\.onmessageerror\s*=\s*null\s*;/.test(overlay)
    || !/worker\.onmessageerror\s*=\s*\(\)\s*=>\s*\{\s*rejectOnce\(new Error\(["']h3_transition_worker_message_error["']\)\)\s*;/.test(overlay)
    || !/worker\.terminate\(\)/.test(overlay)
    || !/URL\.revokeObjectURL\(workerScriptUrl\)/.test(overlay)
    || !/mediaSource\.removeEventListener\(["']sourceopen["'],\s*handleSourceOpen\)/.test(overlay)
    || !/mediaSource\.removeEventListener\(["']sourceclose["'],\s*handleSourceClose\)/.test(overlay)
    || !/sourceBuffer\?\.removeEventListener\(["']updateend["'],\s*handleUpdateEnd\)/.test(overlay)
    || !/sourceBuffer\?\.removeEventListener\(["']error["'],\s*handleSourceBufferError\)/.test(overlay)
    || !/signal\.removeEventListener\(["']abort["'],\s*handleAbort\)/.test(overlay)
    || !/let\s+disposed\s*=\s*false\s*;/.test(overlay)
    || !/const\s+dispose\s*=\s*\(\)\s*=>\s*\{\s*if\s*\(disposed\)\s*return\s*;\s*disposed\s*=\s*true\s*;/.test(overlay)
    || !/if\s*\(!settled\)[\s\S]*?rejectOnce\([\s\S]*?\)\s*;[\s\S]*?else\s*\{\s*detachPipeline\(\)\s*;/.test(overlay)
    || !/sourceBuffer\?\.updating\)\s*sourceBuffer\.abort\(\)/.test(overlay)
    || !/URL\.revokeObjectURL\(videoObjectUrl\)/.test(overlay)
    || !/return\s*\{\s*url:\s*videoObjectUrl,\s*ready,\s*dispose\s*\}\s*;/.test(overlay)) {
    errors.push("Task 7 embedded H3 MediaSource handle must idempotently dispose worker, listeners, SourceBuffer state, worker URL and video URL");
  }
  if (!/if\s*\(!H3_TRANSITION_IS_EMBEDDED\s*\|\|\s*prefersReducedMotion\s*\|\|\s*runtimeRef\.current\.cardShown\)\s*return\s*;/.test(overlay)
    || !/setVideoSource\(embeddedMedia\.url\)/.test(overlay)
    || !/window\.setTimeout\(\(\)\s*=>\s*\{\s*if\s*\(conversionFinished\)\s*return\s*;\s*abortController\.abort\(\)\s*;\s*embeddedMedia\.dispose\(\)\s*;\s*setVideoSource\(["']["']\)\s*;\s*markVideoFailed\(\)\s*;\s*\},\s*EMBEDDED_VIDEO_CONVERSION_TIMEOUT_MS\)/.test(overlay)
    || !/void\s+embeddedMedia\.ready[\s\S]*?embeddedMedia\.dispose\(\)[\s\S]*?setVideoSource\(["']["']\)[\s\S]*?markVideoFailed\(\)/.test(overlay)
    || !/return\s*\(\)\s*=>\s*\{[\s\S]*?abortController\.abort\(\)[\s\S]*?embeddedMedia\.dispose\(\)/.test(overlay)
    || (overlay.match(/window\.clearTimeout\(conversionTimeout\)/g) ?? []).length < 3) {
    errors.push("Task 7 embedded H3 MediaSource setup must skip reduced motion and abort, dispose, clear its URL, and fall back after the 20-second timeout");
  }
  const staticFallbackStart = overlay.indexOf("function drawStaticPrologueFallback(");
  const staticFallbackEnd = overlay.indexOf("\n}\n\nfunction createInitialFiredBeats", staticFallbackStart);
  const staticFallback = staticFallbackStart >= 0 && staticFallbackEnd > staticFallbackStart
    ? overlay.slice(staticFallbackStart, staticFallbackEnd + 2)
    : "";
  if (!/const\s+useH3Video\s*=\s*!prefersReducedMotion\s*&&\s*!videoFailed\s*;/.test(overlay)
    || /(?:import\s+\{?\s*PrologueRenderer|new PrologueRenderer\(|PrologueVisualAssets)/.test(overlay)
    || /(?:rendererRef|lastFallbackRenderAtRef|FALLBACK_RENDER_INTERVAL_MS)/.test(overlay)
    || (overlay.match(/drawStaticPrologueFallback\(/g) ?? []).length !== 2
    || !/function\s+drawStaticPrologueFallback\(canvas:\s*HTMLCanvasElement\):\s*void\s*\{/.test(staticFallback)
    || !/const\s+width\s*=\s*960\s*;\s*const\s+height\s*=\s*540\s*;/.test(staticFallback)
    || !/canvas\.width\s*!==\s*width\)\s*canvas\.width\s*=\s*width/.test(staticFallback)
    || !/canvas\.height\s*!==\s*height\)\s*canvas\.height\s*=\s*height/.test(staticFallback)
    || !/context\.clearRect\(0,\s*0,\s*width,\s*height\)/.test(staticFallback)
    || !/context\.createLinearGradient\(0,\s*0,\s*0,\s*height\)/.test(staticFallback)
    || (staticFallback.match(/sky\.addColorStop\(/g) ?? []).length < 3
    || !/context\.fillRect\(0,\s*352,\s*width,\s*188\)/.test(staticFallback)
    || !/context\.fillRect\(640,\s*92,\s*250,\s*260\)/.test(staticFallback)
    || !/for\s*\(let\s+row\s*=\s*0;\s*row\s*<\s*3;\s*row\s*\+=\s*1\)[\s\S]*?for\s*\(let\s+column\s*=\s*0;\s*column\s*<\s*4;\s*column\s*\+=\s*1\)[\s\S]*?context\.fillRect\(670\s*\+\s*column\s*\*\s*48,\s*126\s*\+\s*row\s*\*\s*58,\s*22,\s*18\)/.test(staticFallback)
    || !/context\.save\(\)[\s\S]*?context\.translate\(480,\s*306\)[\s\S]*?context\.rotate\(-0\.08\)[\s\S]*?context\.fillRect\(-36,\s*-24,\s*72,\s*48\)[\s\S]*?context\.restore\(\)/.test(staticFallback)
    || /(?:new Image\(|drawImage\()/.test(staticFallback)
    || !/useEffect\(\(\)\s*=>\s*\{\s*const\s+canvas\s*=\s*canvasRef\.current\s*;\s*if\s*\(!canvas\)\s*return\s*;\s*if\s*\(useH3Video\)\s*\{\s*const\s+context\s*=\s*canvas\.getContext\(["']2d["']\)\s*;\s*context\?\.clearRect\(0,\s*0,\s*canvas\.width,\s*canvas\.height\)\s*;\s*return\s*;\s*\}\s*drawStaticPrologueFallback\(canvas\)\s*;\s*\},\s*\[prefersReducedMotion,\s*useH3Video\]\)/.test(overlay)) {
    errors.push("Task 7 canvas fallback must stay a one-shot 960x540 geometric drawing and keep PrologueRenderer image assets out of the active overlay bundle and frame loop");
  }

  const appGateOpenCount = (app.match(/<Chapter4PrologueRuntimeGate\b/g) ?? []).length;
  const appGateCloseCount = (app.match(/<\/Chapter4PrologueRuntimeGate>/g) ?? []).length;
  if (!/import\s*\{\s*Chapter4PrologueRuntimeGate\s*\}\s*from\s*["']\.\/components\/Chapter4PrologueRuntimeGate["']\s*;/.test(app)
    || appGateOpenCount !== 3
    || appGateCloseCount !== 3
    || !/if\s*\(state\.runtimeMode\s*===\s*["']rpg["']\)[\s\S]*?if\s*\(desktopGameplay\)[\s\S]*?<Chapter4PrologueRuntimeGate[\s\S]*?<(?:RpgGameHost|ActiveRpgGameHost)/.test(app)
    || (app.match(/<Chapter4PrologueRuntimeGate\s+store=\{gameStore\}\s+events=\{eventBus\}>/g) ?? []).length !== 3
    || /Chapter4PrologueOverlay|complete_prologue_handoff/.test(app)) {
    errors.push("Task 7 App must make Chapter4PrologueRuntimeGate the root owner across desktop RPG, single-surface RPG and phone branches");
  }

  const gateTimeoutStart = prologueGate.indexOf("  const armTimeoutGuard = useCallback(");
  const gateTimeoutEnd = prologueGate.indexOf("\n\n  useEffect", gateTimeoutStart);
  const gateTimeoutBlock = gateTimeoutStart >= 0 && gateTimeoutEnd > gateTimeoutStart
    ? prologueGate.slice(gateTimeoutStart, gateTimeoutEnd)
    : "";
  const gateCompleteStart = prologueGate.indexOf("  const completePrologue = useCallback(");
  const gateCompleteEnd = prologueGate.indexOf("\n\n  const active", gateCompleteStart);
  const gateCompleteBlock = gateCompleteStart >= 0 && gateCompleteEnd > gateCompleteStart
    ? prologueGate.slice(gateCompleteStart, gateCompleteEnd)
    : "";
  const gateChildrenIndex = prologueGate.indexOf("{children}");
  const gateOverlayConditionalIndex = prologueGate.indexOf("{active ? (", gateChildrenIndex);
  if (!/const\s+Chapter4PrologueGateBlockedContext\s*=\s*createContext\(false\)\s*;/.test(prologueGate)
    || !/export function useChapter4PrologueGateBlocked\(\):\s*boolean\s*\{\s*return\s+useContext\(Chapter4PrologueGateBlockedContext\)\s*;\s*\}/.test(prologueGate)
    || !/<Chapter4PrologueGateBlockedContext\.Provider\s+value=\{active\}>/.test(prologueGate)
    || gateChildrenIndex < 0
    || gateOverlayConditionalIndex <= gateChildrenIndex
    || !/<div\s+ref=\{contentRef\}[\s\S]*?className=\{`chapter4-prologue-app-content\$\{active\s*\?\s*["'] is-blocked["']\s*:\s*["']["']\}`\}[\s\S]*?aria-hidden=\{active\s*\?\s*["']true["']\s*:\s*undefined\}[\s\S]*?>\s*\{children\}\s*<\/div>\s*\{active\s*\?/.test(prologueGate)
    || !/if\s*\(active\)\s*content\.setAttribute\(["']inert["'],\s*["']["']\)\s*;\s*else\s*content\.removeAttribute\(["']inert["']\)/.test(prologueGate)
    || !/const\s+active\s*=\s*eligible\s*\|\|\s*requested\s*\|\|\s*held\s*;\s*activeRef\.current\s*=\s*active\s*;/.test(prologueGate)
    || (prologueGate.match(/<Chapter4PrologueOverlay\b/g) ?? []).length !== 1
    || !/onComplete=\{completePrologue\}/.test(prologueGate)) {
    errors.push("Task 7 App gate must always retain its children and block the lower runtime through context, inert, aria-hidden and the overlay layer while active");
  }

  if (!/const\s+HANDOFF_TIMEOUT_MS\s*=\s*20_000\s*;/.test(prologueGate)
    || !/window\.setTimeout\(\(\)\s*=>\s*\{\s*if\s*\(requestIdRef\.current\s*!==\s*requestId\)\s*return\s*;[\s\S]*?setStatus\(["']failed["']\)[\s\S]*?\},\s*HANDOFF_TIMEOUT_MS\)/.test(gateTimeoutBlock)
    || /setHeld\(false\)|setRequested\(false\)|requestIdRef\.current\s*=\s*null/.test(gateTimeoutBlock)
    || !/if\s*\(status\s*===\s*["']pending["']\s*\|\|\s*status\s*===\s*["']waiting_ready["']\s*\|\|\s*status\s*===\s*["']ready["']\)\s*return\s*;/.test(gateCompleteBlock)
    || !/if\s*\(current\.chapter4\.prologueSeen\)\s*\{[\s\S]*?requestIdRef\.current\s*=\s*requestId[\s\S]*?setStatus\(["']waiting_ready["']\)[\s\S]*?armTimeoutGuard\(requestId\)[\s\S]*?events\.emit\(["']rpg_chapter4_755_live_ready_retry_requested["'],\s*\{\s*requestId\s*\}\)[\s\S]*?return\s*;/.test(gateCompleteBlock)
    || !/requestIdRef\.current\s*=\s*requestId[\s\S]*?setStatus\(["']pending["']\)[\s\S]*?controller\.resolve755Intent\(\{\s*type:\s*["']complete_prologue_handoff["']\s*\}\)[\s\S]*?if\s*\(!result\.accepted\)[\s\S]*?setStatus\(["']failed["']\)[\s\S]*?setStatus\(["']waiting_ready["']\)[\s\S]*?armTimeoutGuard\(requestId\)/.test(gateCompleteBlock)
    || !/new\s+ChapterFourTemporalMazeController\(store,\s*events\)/.test(prologueGate)) {
    errors.push("Task 7 App gate must own controller submission and a retryable 20-second timeout that leaves the lower runtime mounted");
  }

  if (!/function\s+isOpeningHandoffCommitted\(state:\s*GameState\):\s*boolean\s*\{[\s\S]*?state\.chapter4\.prologueSeen[\s\S]*?state\.chapter4\.phase\s*===\s*["']opening_handoff["'][\s\S]*?state\.rpgScene\s*===\s*["']duan_yongping_temporal_maze["']/.test(prologueGate)
    || !/const\s+initialResumeRef\s*=\s*useRef\(resumeOpeningHandoff\)\s*;/.test(prologueGate)
    || !/const\s+initialElapsedRef\s*=\s*useRef\(\s*initialResumeRef\.current\s*\?\s*PROLOGUE_TASK_CARD_AT\s*:\s*getDeveloperChapter4PrologueOffset\(\)\s*\)/.test(prologueGate)
    || !/useState\(eligible\s*\|\|\s*resumeOpeningHandoff\)/.test(prologueGate)
    || !/useState<HandoffStatus>\(\s*resumeOpeningHandoff\s*\?\s*["']waiting_ready["']\s*:\s*["']idle["']\s*\)/.test(prologueGate)
    || !/if\s*\(!resumeOpeningHandoff\s*\|\|\s*!initialResumeRef\.current\)\s*return\s*;[\s\S]*?requestIdRef\.current\s*=\s*requestId[\s\S]*?setHeld\(true\)[\s\S]*?setStatus\(["']waiting_ready["']\)[\s\S]*?armTimeoutGuard\(requestId\)[\s\S]*?void\s+warmRpgRuntime\(\s*["']duan_yongping_temporal_maze["'],\s*["']immediate["'],\s*["']entry["']\s*\)/.test(prologueGate)
    || !/initialElapsedMs=\{initialElapsedRef\.current\}/.test(prologueGate)) {
    errors.push("Task 7 App gate must restore a reloaded committed opening_handoff directly at the 43834ms task card while the RPG runtime boots underneath");
  }

  if (!/event\.name\s*!==\s*["']chapter35_recovered_replay_gate_requested["'][\s\S]*?requestIdRef\.current\s*=\s*createRequestId\(\)[\s\S]*?setRequested\(true\)[\s\S]*?setHeld\(true\)[\s\S]*?void\s+warmRpgRuntime\(\s*["']duan_yongping_temporal_maze["'],\s*["']immediate["'],\s*["']entry["']\s*\)/.test(prologueGate)
    || !/event\.name\s*!==\s*["']rpg_chapter4_755_live_ready["']/.test(prologueGate)
    || !/phase\s*!==\s*["']opening_handoff["']/.test(prologueGate)
    || !/appliedPlateId\s*!==\s*["']a1_2245_opening["']/.test(prologueGate)
    || !/event\.payload\?\.contractReady\s*!==\s*true/.test(prologueGate)
    || !/const\s+expectedRequestId\s*=\s*requestIdRef\.current[\s\S]*?const\s+receivedRequestId[\s\S]*?if\s*\(!expectedRequestId\)\s*return[\s\S]*?if\s*\(receivedRequestId\s*!==\s*expectedRequestId\)[\s\S]*?events\.emit\(["']rpg_chapter4_755_live_ready_retry_requested["'],\s*\{\s*requestId:\s*expectedRequestId\s*\}\)[\s\S]*?return\s*;/.test(prologueGate)
    || !/setStatus\(["']ready["']\)[\s\S]*?window\.setTimeout\(\(\)\s*=>\s*\{[\s\S]*?setRequested\(false\)[\s\S]*?setHeld\(false\)[\s\S]*?events\.emit\(["']rpg_chapter4_755_handoff_released["'],\s*\{\s*requestId:\s*expectedRequestId,[\s\S]*?appliedPlateId[\s\S]*?\}\)[\s\S]*?\},\s*80\)/.test(prologueGate)
    || !/event\.name\s*===\s*["']rpg_chapter4_755_live_ready_retry_requested["'][\s\S]*?event\.payload\?\.requestId[\s\S]*?this\.publishLiveReady\(true,\s*requestId\)/.test(scene)
    || !/private\s+publishLiveReady\(force\s*=\s*false,\s*requestId\?:\s*string\):\s*void/.test(scene)
    || !/\.\.\.\(requestId\s*\?\s*\{\s*requestId\s*\}\s*:\s*\{\}\)/.test(scene)) {
    errors.push("Task 7 live-ready handshake must round-trip the App gate requestId through the Scene retry echo before the 80ms release");
  }

  const phaserClearIndex = host.indexOf("clearRpgCanvasHost(host);");
  const phaserGameIndex = host.indexOf("new Phaser.Game(", phaserClearIndex);
  const phaserMountEffectStart = host.lastIndexOf("useEffect(() => {", phaserClearIndex);
  const phaserMountEffectEnd = host.indexOf("\n\n  useEffect", phaserGameIndex);
  const phaserMountEffect = phaserMountEffectStart >= 0 && phaserMountEffectEnd > phaserMountEffectStart
    ? host.slice(phaserMountEffectStart, phaserMountEffectEnd)
    : "";
  if (!/import\s*\{\s*useChapter4PrologueGateBlocked\s*\}\s*from\s*["']\.\.\/\.\.\/components\/Chapter4PrologueRuntimeGate["']\s*;/.test(host)
    || (host.match(/useChapter4PrologueGateBlocked/g) ?? []).length !== 2
    || !/const\s+prologueGateBlocked\s*=\s*useChapter4PrologueGateBlocked\(\)\s*;\s*const\s+inputBlocked\s*=\s*inputBlockedProp\s*\|\|\s*prologueGateBlocked\s*;\s*const\s+keyboardBlocked\s*=\s*keyboardBlockedProp\s*\|\|\s*prologueGateBlocked\s*;/.test(host)
    || /Chapter4PrologueOverlay|HANDOFF_TIMEOUT|HandoffStatus|phaserMountAllowed|RpgGameRuntimeHost|prologueEligible|prologueActive|chapter4Prologue(?:Held|Handoff|Request|Timeout|Release)|rpg_chapter4_755_live_ready|rpg_chapter4_755_handoff_released/.test(host)
    || (host.match(/complete_prologue_handoff/g) ?? []).length !== 1
    || !/if\s*\(intent\.type\s*===\s*["']complete_prologue_handoff["']\)\s*\{[\s\S]*?chapter4ResolvedRequestIdsRef\.current\.add\(requestId\)[\s\S]*?rejectRequest\(\s*["']invalid_intent["'][\s\S]*?App gate[\s\S]*?\)\s*;\s*return\s*;\s*\}[\s\S]*?let\s+trustedIntent/.test(host)
    || !/clearRpgCanvasHost\(host\)\s*;[\s\S]*?new Phaser\.Game\(/.test(phaserMountEffect)
    || /prologueGateBlocked|if\s*\(!phaserMountAllowed\)/.test(phaserMountEffect)
    || !/\},\s*\[bridge,\s*store,\s*theaterRuntimePort\]\);/.test(phaserMountEffect)) {
    errors.push("Task 7 RpgGameHost must stay mounted, consume only the App-gate blocked context, and reject complete_prologue_handoff in its generic intent listener");
  }

  const appGateCss = rpgCss.match(/\.chapter4-prologue-app-gate\s*\{([\s\S]*?)\}/)?.[1] ?? "";
  const embeddedAppGateCss = rpgCss.match(/\.chapter4-prologue-app-gate\.is-embedded\s*\{([\s\S]*?)\}/)?.[1] ?? "";
  const appContentCss = rpgCss.match(/\.chapter4-prologue-app-content\s*\{([\s\S]*?)\}/)?.[1] ?? "";
  const blockedAppContentCss = rpgCss.match(/\.chapter4-prologue-app-content\.is-blocked\s*\{([\s\S]*?)\}/)?.[1] ?? "";
  const handoffLayerCss = rpgCss.match(/\.chapter4-prologue-handoff-layer\s*\{([\s\S]*?)\}/)?.[1] ?? "";
  if (!/height:\s*var\(--app-viewport-height,\s*100vh\)\s*;/.test(appGateCss)
    || !/overflow:\s*hidden\s*;/.test(appGateCss)
    || !/position:\s*relative\s*;/.test(appGateCss)
    || !/width:\s*100vw\s*;/.test(appGateCss)
    || !/height:\s*100%\s*;/.test(embeddedAppGateCss)
    || !/min-height:\s*0\s*;/.test(embeddedAppGateCss)
    || !/width:\s*100%\s*;/.test(embeddedAppGateCss)
    || !/height:\s*100%\s*;/.test(appContentCss)
    || !/pointer-events:\s*none\s*;/.test(blockedAppContentCss)
    || !/user-select:\s*none\s*;/.test(blockedAppContentCss)
    || !/inset:\s*0\s*;/.test(handoffLayerCss)
    || !/position:\s*absolute\s*;/.test(handoffLayerCss)
    || !/z-index:\s*200\s*;/.test(handoffLayerCss)
    || !/className=\{`chapter4-prologue-app-gate\$\{embedded\s*\?\s*["'] is-embedded["']\s*:\s*["']["']\}`\}/.test(prologueGate)
    || !/className=\{`rpg-stage chapter4-prologue-handoff-layer\$\{embedded\s*\?\s*["'] is-embedded["']\s*:\s*["']["']\}`\}/.test(prologueGate)) {
    errors.push("Task 7 App gate CSS must keep the retained runtime bounded and pointer-blocked under an absolute z-index 200 handoff layer");
  }

  const handshakeBlock = host.match(/const CHAPTER_FOUR_755_PRESENTATION_HANDSHAKE_INTENTS\s*=\s*new Set\(\[([\s\S]*?)\]\);/)?.[1] ?? "";
  const suppressedHandshakeIntents = [...handshakeBlock.matchAll(/"([^"]+)"/g)].map((match) => match[1]);
  if (!sameArray(suppressedHandshakeIntents, [
    ...EXPECTED_OPENING_INTENTS.filter((intent) => intent !== "complete_prologue_handoff"),
    "inspect_bakery_conveyor_lamp",
    "complete_bakery_conveyor_stop",
    "talk_to_a1_front_desk_attendant",
    "talk_to_chapter_four_support_npc",
    "inspect_alumni_figure",
    "complete_zhu_two_questions",
    "observe_classroom_104_chalk_residual",
    "check_classroom_105_terminal_replay",
    "observe_elevator_history",
    "calibrate_elevator_history",
    "observe_a3_reference",
    "inspect_chapter_four_context",
    "complete_inserted_puzzle",
    "complete_misaligned_stair",
    "observe_room204_residual",
    "place_room204_piece",
    "complete_room204_projection",
    "collect_positioning_plate",
    "install_positioning_plate",
    "begin_final_clock_drag",
    "complete_minute_theft",
    "open_power_panel",
    "toggle_light_zone",
    "lock_light_grid",
    "acknowledge_exterior_closure"
  ])) {
    errors.push("Host handshake suppression must contain exactly the Chapter 4 Scene/overlay-owned presentations");
  }

  const task7LiveReadyBlock = scene.match(/const TASK7_LIVE_READY_TARGET_IDS[\s\S]*?new Set\(\[([\s\S]*?)\]\);/)?.[1] ?? "";
  const task7LiveReadyIds = [...task7LiveReadyBlock.matchAll(/"([^"]+)"/g)].map((match) => match[1]);
  if (!sameArray(task7LiveReadyIds, ["a1_noticeboard_paper", "a1_hall_clock"])) {
    errors.push("Task 7 live-ready contract must still contain only paper and hall clock");
  }
  const task9ActionableBlock = scene.match(/export const TASK9_ACTIONABLE_TARGET_IDS[\s\S]*?new Set\(\[([\s\S]*?)\]\);/)?.[1] ?? "";
  const task9ActionableIds = [...task9ActionableBlock.matchAll(/"([^"]+)"/g)]
    .map((match) => match[1])
    .filter((id) => id !== "a2_room204_slot_");
  if (!sameArray(task9ActionableIds, [
    "a1_noticeboard_paper",
    "a1_hall_clock",
    ...EXPECTED_BAKERY_TARGET_IDS,
    "a1_front_desk_attendant",
    "a2_elevator_attendant",
    "a3_reference_teacher",
    "a3_alumni_su_buqing",
    "a3_alumni_zhu_kezhen",
    "a3_alumni_lu_yongxiang",
    "a3_alumni_chen_jiangong",
    "a3_alumni_tan_jiazhen",
    "a3_alumni_cheng_kaijia",
    "a1_classroom_104_blackboard_residual",
    "a1_classroom_105_lectern_terminal",
    "a3_reference_classroom_layout",
    "a2_room204_residual_group",
    "a2_room204_podium_drawer",
    "a1_hall_clock_positioning_plate_slot"
  ]) || !/startsWith\("a2_room204_slot_"\)/.test(task9ActionableBlock)) {
    errors.push("Task 9 Scene actionable target allowlist must include the front desk, A2 safety officer, A3 teacher, both classroom gates, A3 reference, A2 residual, positioning plate, and all 12 Room204 slot targets");
  }
  const task10ActionableBlock = scene.match(
    /export const TASK10_ACTIONABLE_TARGET_IDS[\s\S]*?export const TASK11_ACTIONABLE_TARGET_IDS/
  )?.[0] ?? "";
  const task10ActionableIds = [...task10ActionableBlock.matchAll(/"([^"]+)"/g)]
    .map((match) => match[1]);
  if (!/\.\.\.TASK9_ACTIONABLE_TARGET_IDS/.test(task10ActionableBlock)
    || !sameArray(task10ActionableIds, EXPECTED_MAINTENANCE_TARGET_IDS)) {
    errors.push("Task 10 Scene actionable target allowlist must extend Task 9 with exactly the six maintenance targets");
  }
  const task11ActionableBlock = scene.match(
    /export const TASK11_ACTIONABLE_TARGET_IDS[\s\S]*?export const TASK12_ACTIONABLE_TARGET_IDS/
  )?.[0] ?? "";
  const task11ActionableIds = [...task11ActionableBlock.matchAll(/"([^"]+)"/g)]
    .map((match) => match[1]);
  if (!/\.\.\.TASK10_ACTIONABLE_TARGET_IDS/.test(task11ActionableBlock)
    || !sameArray(task11ActionableIds, ["a1_hall_clock_minute_endpoint", "a1_power_panel"])
    || /a2_202_threshold|a2_202_projection|a1_campus_card_reader|a1_attendance_paper_slot/.test(task11ActionableBlock)) {
    errors.push("Task 11 Scene actionable target allowlist must add only the minute endpoint and power panel while Task12+ targets stay closed");
  }
  const task12ActionableBlock = scene.match(
    /export const TASK12_ACTIONABLE_TARGET_IDS[\s\S]*?export const TASK13_ACTIONABLE_TARGET_IDS/
  )?.[0] ?? "";
  const task12ActionableIds = [...task12ActionableBlock.matchAll(/"([^"]+)"/g)]
    .map((match) => match[1]);
  if (!/\.\.\.TASK11_ACTIONABLE_TARGET_IDS/.test(task12ActionableBlock)
    || !sameArray(task12ActionableIds, ["a2_202_projection"])
    || /a2_202_threshold|a1_campus_card_reader|a1_attendance_paper_slot/.test(task12ActionableBlock)
  ) {
    errors.push("Task 12 Scene actionable target allowlist must add only the final-minute runtime entity while threshold remains automatic");
  }
  const task13ActionableBlock = scene.match(
    /export const TASK13_ACTIONABLE_TARGET_IDS[\s\S]*?const MAINTENANCE_RUNTIME_TARGET_IDS/
  )?.[0] ?? "";
  const task13ActionableIds = [...task13ActionableBlock.matchAll(/"([^"]+)"/g)]
    .map((match) => match[1]);
  if (!/\.\.\.TASK12_ACTIONABLE_TARGET_IDS/.test(task13ActionableBlock)
    || !sameArray(task13ActionableIds, ["a1_campus_card_reader", "a1_attendance_paper_slot"])
    || /a2_202_threshold/.test(task13ActionableBlock)
    || !/resolveProjectedTargets\(\)[\s\S]*?!TASK13_ACTIONABLE_TARGET_IDS\.has\(targetId\)/.test(scene)
    || !/resolveActionableTargets\(\)[\s\S]*?TASK13_ACTIONABLE_TARGET_IDS\.has\(target\.contract\.id\)/.test(scene)) {
    errors.push("Task 13 Scene actionable target allowlist must extend Task12 with exactly the card reader and paper slot");
  }
  const realityTargetProjectionBlock = scene.match(
    /private resolveProjectedTargets\(\)[\s\S]*?private resolveActionableTargets\(\)/
  )?.[0] ?? "";
  if (/requiredMode !== undefined && requiredMode !== mode\) return \[\]/.test(realityTargetProjectionBlock)) {
    errors.push("Chapter 4 must keep mode-specific targets projected so players can investigate in any order and receive mode correction without losing the puzzle point");
  }
  const realityPresentationBlock = scene.match(
    /private refreshProjectedTargetVisuals\(\)[\s\S]*?private createElevatorVisuals\(\)/
  )?.[0] ?? "";
  const realityAtmosphereBlock = scene.match(
    /private createRealityModeVisuals\([\s\S]*?private retryRequiredWarmupPhase\(\)/
  )?.[0] ?? "";
  if (!/private syncRealityModeVisuals/.test(realityAtmosphereBlock)
    || !/0x082846, 0\.3/.test(realityAtmosphereBlock)
    || !/0xffe2a6, 0\.07/.test(realityAtmosphereBlock)
    || !/mode === "dark" \? 1 : 0/.test(realityAtmosphereBlock)
    || !/mode === "light" \? 1 : 0/.test(realityAtmosphereBlock)
    || !/modeActive \? 1 : 0\.22/.test(realityPresentationBlock)
    || !/mode === "light"/.test(realityPresentationBlock)
    || !/0x67ddff/.test(realityPresentationBlock)
    || !/0xffd36f/.test(realityPresentationBlock)) {
    errors.push("Chapter 4 must render distinct dark and light atmospheres while keeping opposite-mode puzzle markers visible in a dormant state");
  }
  const room204PieceResolverBlock = scene.match(
    /private resolveNearbyRoom204PieceId\(\)[\s\S]*?private selectRoom204Piece/
  )?.[0] ?? "";
  if (!/state\.chapter4\.mode !== "light"/.test(room204PieceResolverBlock)) {
    errors.push("Room 204 physical furniture pieces must not remain interactive in dark observation mode");
  }
  const storyTargetInteractionBlock = scene.match(
    /private storySpatialResult[\s\S]*?private handleTravelInteraction/
  )?.[0] ?? "";
  if (!/private playerFootPoint[\s\S]*?body\?\.center\.x[\s\S]*?body\?\.center\.y/.test(scene)
    || !/private storySpatialResult[\s\S]*?playerFootPoint\(floor\)[\s\S]*?pointDistanceToRect\(localPlayer, target\.bounds\)[\s\S]*?target\.contract\.proximity/.test(storyTargetInteractionBlock)
    || !/const spatial\s*=\s*this\.storySpatialResult\(storyTarget\)/.test(storyTargetInteractionBlock)
    || /spatial\s*:\s*\{\s*distance\s*:\s*"within_range"/.test(storyTargetInteractionBlock)) {
    errors.push("Task 7 Scene spatial checks must derive from the real player foot body and target geometry");
  }
  if (!/private handleTravelInteraction\(\): void \{[\s\S]*?OPENING_PHASES\.has\(this\.projection\.phase\)/.test(scene)
    || !/const nearbyTravelCandidate\s*=\s*this\.projection\.phase\s*&&\s*OPENING_PHASES\.has\(this\.projection\.phase\)/.test(scene)) {
    errors.push("Task 7 opening phases must reject elevator and stair travel before request submission");
  }
  if (!/createExternalTimeOverlay/.test(scene)
    || !/setScrollFactor\(0\)\.setDepth\(12500\)/.test(scene)
    || !/"22:45"/.test(scene)
    || !/"07:55:23"/.test(scene)
    || !/"不可信"/.test(scene)) {
    errors.push("Task 7 external-time rejection must render a visible locked close-up with both clock readings");
  }
  if (!/rpg_chapter4_story_input_lock_changed/.test(scene)
    || !/rpg_chapter4_story_input_lock_changed/.test(host)
    || !/const locked = event\.payload\?\.locked === true[\s\S]*?setChapter4InteractionBlocked\(locked\)/.test(host)) {
    errors.push("Task 7 presentation lock must disable Host story controls while Scene timers continue");
  }
  const inspectionBlock = scene.match(/private beginHallClockInspection\(\)[\s\S]*?private beginFirstHallClockPullPresentation/)?.[0] ?? "";
  if (/时针缺失|时针轴为空|缺少时针/.test(inspectionBlock)
    || !/能被拨动，但响应方向和幅度都不对/.test(inspectionBlock)) {
    errors.push("Task 7 first clock inspection must say the clock moves incorrectly without revealing the missing hour hand");
  }

  if (!/chapter4-755\.content\.json/.test(quest)
    || !/chapterFour755Content\.phaseContracts/.test(quest)
    || !/contract\.taskKeys/.test(quest)
    || !/state\.chapter4\.factIds/.test(quest)
    || !/state\.items\.oldClockHourHand/.test(quest)
    || !/steps:\s*\[\{/.test(quest)
    || !/chapterFourLegacyQuest/.test(quest)) {
    errors.push("Task 7 QuestModel must select one current 7:55 task from phase taskKeys and facts/items with a legacy fallback");
  }
  const openingLocations = controller.match(/opening_handoff:\s*\[([\s\S]*?)\],\s*opening_paper_caught:/)?.[1] ?? "";
  const handoffTransition = controller.match(/this\.transition\(state, "opening_handoff", \{([\s\S]*?)\}\)/)?.[1] ?? "";
  if (/a1_hall_clock/.test(openingLocations)
    || !/roomId:\s*"a1_lobby"/.test(handoffTransition)
    || !/checkpoint:\s*"c4_a1_lobby"/.test(handoffTransition)) {
    errors.push("Task 7 controller must converge opening_handoff to the A1 lobby before the paper flight");
  }
  const locationNormalizer = saveStore.match(/function normalizeChapterFour755Location[\s\S]*?function normalizeChapterFourRoom204Placements/)?.[0] ?? "";
  if (!/phase === "opening_handoff"[\s\S]*roomId:\s*"a1_lobby"/.test(locationNormalizer)) {
    errors.push("Task 7 SaveStore must hydrate opening_handoff into the A1 lobby");
  }
  const paperTarget = interaction.match(/a1_noticeboard_paper:[\s\S]*?a1_hall_clock:/)?.[0] ?? "";
  if (!/roomIds:\s*\["a1_lobby",\s*"a1_hall_clock"\]/.test(paperTarget)) {
    errors.push("Task 7 paper target must tolerate the prior A1 hall-clock room alias during live compatibility");
  }

  const runtimeBakeryTargetBlock = interaction.match(/a1_bakery_inspection_lamp:[\s\S]*?a1_hall_clock_hour_hand_socket:/)?.[0] ?? "";
  for (const [targetId, entityId] of [
    ["a1_bakery_inspection_lamp", "chapter4-bakery-inspection-lamp"],
    ["a1_bakery_conveyor_edge", "chapter4-bakery-conveyor-edge"],
    ["a1_bakery_hour_hand_pickup", "chapter4-bakery-hour-hand-pickup"]
  ]) {
    if (!runtimeBakeryTargetBlock.includes(targetId)
      || !runtimeBakeryTargetBlock.includes(entityId)
      || !new RegExp(`${targetId}:[\\s\\S]*?runtimeEntityTarget\\(`).test(runtimeBakeryTargetBlock)) {
      errors.push(`Task 8 interaction target ${targetId} must be an independent runtime entity`);
    }
  }
  const runtimeInstallationsBlock = interaction.match(
    /const CHAPTER_FOUR_755_RUNTIME_TARGET_INSTALLATIONS[\s\S]*?const CHAPTER_FOUR_755_CALIBRATED_RUNTIME_TARGET_IDS/
  )?.[0] ?? "";
  const runtimeResolverBlock = interaction.match(
    /export function resolveChapterFour755RuntimeEntityTarget[\s\S]*?export function isChapterFour755RuntimeBounds/
  )?.[0] ?? "";
  if (!/chapterFourLayout\.bakeryRuntime\.targetEntities/.test(runtimeInstallationsBlock)
    || !/targetId:\s*entry\.targetId[\s\S]*?entityId:\s*entry\.entityId[\s\S]*?bounds:\s*entry\.installationBounds/.test(runtimeInstallationsBlock)
    || !/CHAPTER_FOUR_755_RUNTIME_TARGET_INSTALLATIONS\.get\(targetId\)/.test(runtimeResolverBlock)
    || !/target\.boundsSource\.entityId\s*!==\s*entityId/.test(runtimeResolverBlock)
    || !/installation\.entityId\s*!==\s*entityId/.test(runtimeResolverBlock)
    || !/sameHalfOpenWorldRect\(bounds, installation\.bounds\)/.test(runtimeResolverBlock)
    || !/const resolvedBounds\s*=\s*installation\.bounds/.test(runtimeResolverBlock)) {
    errors.push("Task 8/9 runtime resolver must bind every targetId/entityId pair to the exact registered layout bounds");
  }
  if (!/bakery_conveyor_available[\s\S]*?!hasChapterFourFact\(state, "bakery_hour_hand_exposed"\)/.test(runtimeBakeryTargetBlock)) {
    errors.push("Task 8 conveyor edge must remain projectable before the hour hand is exposed");
  }
  if (!/hour_hand_pickup_available[\s\S]*?bakery_conveyor_lamp_inspected[\s\S]*?bakery_hour_hand_exposed/.test(runtimeBakeryTargetBlock)) {
    errors.push("Task 8 hour-hand pickup must require both lamp and exposed facts");
  }

  const room204Installations = runtimeInstallationsBlock.match(
    /\["a2_room204_residual_group"[\s\S]*?\.\.\.Object\.entries\(ROOM204_SLOT_LAYOUTS\)[\s\S]*?\}\)\n\]/
  )?.[0] ?? runtimeInstallationsBlock;
  if (!/"a2_room204_residual_group"[\s\S]*?ROOM204_RESIDUAL_GROUP_RUNTIME_ENTITY_ID[\s\S]*?ROOM204_RESIDUAL_GROUP_BOUNDS/.test(room204Installations)
    || !/"a2_room204_podium_drawer"[\s\S]*?ROOM204_PODIUM_DRAWER_RUNTIME_ENTITY_ID[\s\S]*?ROOM204_PODIUM_LAYOUT\.drawerBounds/.test(room204Installations)
    || !/Object\.entries\(ROOM204_SLOT_LAYOUTS\)[\s\S]*?targetId[\s\S]*?room204SlotRuntimeEntityId\(typedSlotId\)[\s\S]*?bounds:\s*slot\.bounds/.test(room204Installations)) {
    errors.push("Task 9 residual, podium drawer and 12 slot runtime targets must register targetId/entityId/exact Room204 layout bounds in the shared resolver");
  }
  if (!/const ROOM204_LAYOUT\s*=\s*mazeLayout\.room204Runtime/.test(room204Model)
    || !/ROOM204_RESIDUAL_GROUP_BOUNDS[\s\S]*?ROOM204_LAYOUT\.residualGroupBounds/.test(room204Model)
    || !/ROOM204_PODIUM_LAYOUT[\s\S]*?ROOM204_LAYOUT\.podium/.test(room204Model)
    || !/ROOM204_SLOT_LAYOUTS[\s\S]*?ROOM204_LAYOUT\.slotTargets/.test(room204Model)) {
    errors.push("Task 9 runtime target bounds must be sourced from chapter4-three-floor-maze.layout.json through the pure Room204 model");
  }

  if (!/result\.detailCode[\s\S]*?CHAPTER_FOUR_755_INTENT_DETAILS\[result\.detailCode\]/.test(host)
    || !/chapterFour755DetailKeys\.length !== CHAPTER_FOUR_755_INTENT_DETAIL_CODES\.length/.test(host)
    || !/bakery_lamp_required/.test(controller)
    || !/"bakery_lamp_required"[\s\S]*?"reason"[\s\S]*?"nextAction"/.test(JSON.stringify(content.intentFeedback?.details ?? {}))) {
    errors.push("Task 8/9 Host must resolve controller detailCode through the complete content-owned feedback table");
  }
  const detailCodeDeclaration = controller.match(
    /CHAPTER_FOUR_755_INTENT_DETAIL_CODES\s*=\s*Object\.freeze\(\[([\s\S]*?)\]\s*as const\)/
  )?.[1] ?? "";
  const declaredDetailCodes = [...detailCodeDeclaration.matchAll(/"([^"]+)"/g)]
    .map((match) => match[1]);
  const feedbackDetails = isRecord(content.intentFeedback?.details)
    ? content.intentFeedback.details
    : {};
  if (declaredDetailCodes.length === 0
    || !setEquals(new Set(declaredDetailCodes), new Set(Object.keys(feedbackDetails)))
    || Object.values(feedbackDetails).some((detail) => (
      !isRecord(detail) || !nonEmptyString(detail.reason) || !nonEmptyString(detail.nextAction)
    ))) {
    errors.push("Task 9 intent feedback must cover every declared detailCode with a non-empty reason and next action");
  }
  if (!/reason === "locked"[\s\S]*?detailCode:\s*detailCode \?\? \(chapter[\s\S]*?lockedDetailForIntent\(state, chapter, intent\)/.test(controllerIntentResolver)
    || !/const byIssue:\s*Record<typeof issue, ChapterFour755IntentDetailCode>\s*=\s*\{[\s\S]*?unknown_piece:\s*"room204_unknown_piece"[\s\S]*?unknown_slot:\s*"room204_unknown_slot"[\s\S]*?invalid_orientation:\s*"room204_invalid_orientation"[\s\S]*?duplicate_piece:\s*"room204_duplicate_piece"[\s\S]*?occupied_slot:\s*"room204_slot_occupied"[\s\S]*?already_placed:\s*"room204_piece_already_placed"/.test(controller)) {
    errors.push("Task 9 every locked result must receive an automatic detailCode and every Room204 issue must have an explicit mapping");
  }
  if (!/phaseCount:\s*13/.test(stagePresentation)
    || !/timeStateCount:\s*6/.test(stagePresentation)
    || !/assertExactUniqueIds\(PHASE_IDS, Object\.keys\(PHASE_COPY\), 13/.test(stagePresentation)
    || !/assertExactUniqueIds\(TIME_STATE_IDS, Object\.keys\(TIME_STATE_COPY\), 6/.test(stagePresentation)
    || !/现场 22:45 · 手机 07:55:23 未同步/.test(stagePresentation)
    || !/旧钟 22:45 · 维修时段 · 手机已同步/.test(stagePresentation)
    || !/selectChapterFourStagePresentation/.test(stagePresentation)) {
    errors.push("Task 7-13 stage selector must cover 13 phases, 6 time states and distinguish both 22:45 contexts");
  }
  for (const factId of EXPECTED_BAKERY_FACTS.slice(0, 3)) {
    if (!controller.includes(`"${factId}"`)) {
      errors.push(`Task 8 controller is missing fact ${factId}`);
    }
    if (!saveStore.includes(`"${factId}"`)) {
      errors.push(`Task 8 SaveStore is missing persisted fact ${factId}`);
    }
  }
  if (!/case "complete_bakery_conveyor_stop"[\s\S]*?bakery_conveyor_lamp_inspected[\s\S]*?appendFact\(chapter, "bakery_hour_hand_exposed"\)/.test(controller)) {
    errors.push("Task 8 completion intent must write exposed only after the lamp fact");
  }
  if (!/case "collect_hour_hand"[\s\S]*?bakery_hour_hand_collected[\s\S]*?withItem\(state, "oldClockHourHand", true\)/.test(controller)) {
    errors.push("Task 8 pickup must atomically write collected and grant oldClockHourHand");
  }
  if (!/case "install_hour_hand"[\s\S]*?transition\(state, "room204_restore"[\s\S]*?hour_hand_installed[\s\S]*?withItem\(state, "oldClockHourHand", false\)/.test(controller)) {
    errors.push("Task 8 install must consume the hand and atomically transition to room204_restore");
  }
  if (!/hour_hand_installed"\)\) facts\.add\("bakery_hour_hand_collected"\)/.test(saveStore)
    || !/bakery_hour_hand_collected"\)\) facts\.add\("bakery_hour_hand_exposed"\)/.test(saveStore)
    || !/bakery_hour_hand_exposed"\)\) facts\.add\("bakery_conveyor_lamp_inspected"\)/.test(saveStore)) {
    errors.push("Task 8 SaveStore must restore the installed -> collected -> exposed -> lamp causal chain");
  }
  if (!/contract\.id\s*===\s*"bakery_hour_hand"[\s\S]*?bakery_hour_hand_collected[\s\S]*?bakery_hour_hand_exposed/.test(quest)) {
    errors.push("Task 8 QuestModel must select inspect, collect and install from persisted bakery state");
  }
  if (!/getBounds\(\)[\s\S]*?Math\.floor\(bounds\.left[\s\S]*?Math\.ceil\(bounds\.right/.test(scene)
    || !/Math\.floor\(bounds\.top\)[\s\S]*?Math\.ceil\(bounds\.bottom\)/.test(scene)) {
    errors.push("Task 8 runtime target bounds must outward-round actual GameObject getBounds()");
  }
  if (!/visual\.texture,[\s\S]*?visual\.frame[\s\S]*?setScale\(visual\.uniformScale\)/.test(scene)) {
    errors.push("Task 8 hour hand must render from the formal story-item frame with uniform manifest scale");
  }
  for (const offset of EXPECTED_BAKERY_TIMELINE.slice(1)) {
    if (!scene.includes(`scheduleStoryPresentation(${offset},`)) {
      errors.push(`Task 8 Scene is missing the ${offset}ms bakery beat`);
    }
  }
  for (const cue of EXPECTED_BAKERY_CUES) {
    if (!scene.includes(`"${cue}"`)) errors.push(`Task 8 Scene is missing domain cue ${cue}`);
  }
  const bakeryRollbackBlock = scene.match(
    /private rollbackBakeryConveyorStopToCommittedState[\s\S]*?private destroyBakeryRuntime/
  )?.[0] ?? "";
  if (!/selectChapterFour755BakeryCommittedRuntimeState\(this\.bridge\.getState\(\)\)/.test(bakeryRollbackBlock)
    || !/paintBakeryInspectionLamp\(committed\.lampLit\)/.test(bakeryRollbackBlock)
    || !/else this\.resumeBakeryActivity\(\)/.test(bakeryRollbackBlock)
    || !/revealBakeryHourHand\(committed\.hourHandVisible/.test(bakeryRollbackBlock)
    || !/storyRetryNotBeforeMs[\s\S]*?STORY_RETRY_DELAY_MS/.test(bakeryRollbackBlock)) {
    errors.push("Task 8 Scene rollback must restore lamp/activity/pickup/glint from committed state before delayed retry");
  }
  if (!/timedOutIntentType\s*===\s*"complete_bakery_conveyor_stop"[\s\S]*?rollbackBakeryConveyorStopToCommittedState/.test(scene)
    || !/!resultAccepted\(payload\)[\s\S]*?pending\.intentType\s*===\s*"complete_bakery_conveyor_stop"[\s\S]*?rollbackBakeryConveyorStopToCommittedState/.test(scene)
    || !/case "complete_bakery_conveyor_stop"[\s\S]*?!hasChapterFourFact\(state, "bakery_hour_hand_exposed"\)[\s\S]*?rollbackBakeryConveyorStopToCommittedState/.test(scene)) {
    errors.push("Task 8 Scene must route stop-completion timeout, rejection and missing committed fact through rollback");
  }
  if (!/setOrigin\(\s*BAKERY_RUNTIME\.crowd\.origin\.x,\s*BAKERY_RUNTIME\.crowd\.origin\.y\s*\)[\s\S]*?setScale\(BAKERY_RUNTIME\.crowd\.displayScale\)/.test(scene)) {
    errors.push("Task 8 Scene crowd must consume the layout-authored origin and display scale used by topology math");
  }
  if (!/destroyBakeryRuntime[\s\S]*?bakeryCrowdCollider\?\.destroy\(\)[\s\S]*?bakeryConveyorTween\?\.remove\(\)[\s\S]*?bakeryHourHandGlintTween\?\.remove\(\)/.test(scene)) {
    errors.push("Task 8 Scene must destroy bakery colliders and tweens on teardown or plate change");
  }
  const proximityHintBlock = scene.match(/private refreshProximity\(\)[\s\S]*?private isStoryInputLocked/)?.[0] ?? "";
  if (!/acceptedItem\s*!==\s*undefined[\s\S]*?acceptedItem\s*!==\s*null[\s\S]*?把对应道具拖到/.test(proximityHintBlock)) {
    errors.push("Task 8 item-only clock socket must show drag guidance without a Space prompt");
  }
  const itemDropBlock = scene.match(/private handleInventoryDrop[\s\S]*?private emitDropFeedback/)?.[0] ?? "";
  if (!/missed_target/.test(itemDropBlock)
    || !/wrong_item/.test(itemDropBlock)
    || !/a1_hall_clock_hour_hand_socket/.test(itemDropBlock)
    || !/type:\s*"install_hour_hand"/.test(itemDropBlock)) {
    errors.push("Task 8 visible socket drop must distinguish missed/wrong item and submit install_hour_hand");
  }

  const room204SlotContractsBlock = interaction.match(
    /const ROOM204_SLOT_CONTRACTS[\s\S]*?const ROOM204_INTERACTION_TARGETS/
  )?.[0] ?? "";
  const room204InteractionTargetsBlock = interaction.match(
    /const ROOM204_INTERACTION_TARGETS[\s\S]*?export const CHAPTER_FOUR_755_INTERACTION_TARGETS/
  )?.[0] ?? "";
  if (/acceptedPieceId/.test(interaction)
    || /\bpieceId\s*:/.test(room204SlotContractsBlock)
    || /\bpieceId\s*:/.test(room204InteractionTargetsBlock)) {
    errors.push("Task 9 slot contracts must not bind a slot to a predetermined pieceId or acceptedPieceId");
  }
  if (!/ROOM204_ALLOWED_ORIENTATION[^\n]*=\s*"up"/.test(room204Model)
    || !/ROOM204_PIECE_IDS\.has\(candidate\.pieceId/.test(room204Model)
    || !/ROOM204_SLOT_IDS\.has\(candidate\.slotId/.test(room204Model)
    || !/candidate\.orientation\s*!==\s*ROOM204_ALLOWED_ORIENTATION/.test(room204Model)
    || !/placements\.find\(\(placement\)\s*=>\s*placement\.pieceId\s*===\s*pieceId\)/.test(room204Model)
    || !/placements\.some\(\(placement\)\s*=>\s*placement\.slotId\s*===\s*slotId\)/.test(room204Model)
    || /canonicalCompletePlacements|content\.room204/.test(room204Model)) {
    errors.push("Task 9 pure model must accept any known unique piece in any known empty slot with orientation up, independent of the recovery-only canonical mapping");
  }

  const a3ReferenceTargetBlock = interaction.match(
    /a3_reference_classroom_layout:[\s\S]*?a2_room204_residual_group:/
  )?.[0] ?? "";
  const room204ResidualTargetBlock = interaction.match(
    /a2_room204_residual_group:[\s\S]*?\.\.\.ROOM204_INTERACTION_TARGETS/
  )?.[0] ?? "";
  if (!/requiredMode:\s*"light"/.test(a3ReferenceTargetBlock)
    || !/roomIds:\s*\["a3_reference_classroom",\s*"a3_wayfinding"\]/.test(a3ReferenceTargetBlock)) {
    errors.push("Task 9 A3 reference must be a light-mode interaction available through both approved A3 room aliases");
  }
  if (!/requiredMode:\s*"dark"/.test(room204ResidualTargetBlock)
    || !/roomIds:\s*\["a2_corridor",\s*"a2_room204",\s*"a2_room_204"\]/.test(room204ResidualTargetBlock)) {
    errors.push("Task 9 A2 residual group must be a dark-mode interaction available through all approved Room204 aliases");
  }

  for (const factId of EXPECTED_ROOM204_FACTS) {
    if (!types.includes(`| "${factId}"`)) {
      errors.push(`Task 9 ChapterFourFactId is missing ${factId}`);
    }
    if (!controller.includes(`"${factId}"`)) {
      errors.push(`Task 9 controller is missing fact ${factId}`);
    }
    if (!saveStore.includes(`"${factId}"`)) {
      errors.push(`Task 9 SaveStore is missing persisted fact ${factId}`);
    }
  }
  const room204FactOrderBlock = saveStore.match(
    /const CHAPTER_FOUR_ROOM204_FACT_ORDER\s*=\s*\[([\s\S]*?)\]\s*as const/
  )?.[1] ?? "";
  const room204PersistedFactOrder = [...room204FactOrderBlock.matchAll(/"([^"]+)"/g)]
    .map((match) => match[1]);
  if (!sameArray(room204PersistedFactOrder, EXPECTED_ROOM204_FACTS)) {
    errors.push("Task 9 SaveStore fact order must preserve observation, restoration, projection, collection and installation causality");
  }
  const room204SaveClosureBlock = saveStore.match(
    /function normalizeChapterFourRoom204Closure[\s\S]*?function normalizeChapterThreeInterlude/
  )?.[0] ?? "";
  if (!/isRoom204PlacementSetComplete\(placements\)/.test(room204SaveClosureBlock)
    || !/complete\s*&&\s*hasBothObservations[\s\S]*?facts\.add\("room204_restored"\)/.test(room204SaveClosureBlock)
    || !/!facts\.has\("room204_restored"\)[\s\S]*?facts\.delete\("room204_projection_completed"\)/.test(room204SaveClosureBlock)
    || !/!facts\.has\("room204_projection_completed"\)[\s\S]*?facts\.delete\("positioning_plate_collected"\)/.test(room204SaveClosureBlock)) {
    errors.push("Task 9 SaveStore must revalidate complete unique placements and preserve restored -> projection -> positioning-plate closure");
  }

  const room204ControllerBlock = controller.match(
    /case "observe_a3_reference"[\s\S]*?case "collect_short_pry_bar"/
  )?.[0] ?? "";
  const room204FinalizeHelper = controller.match(
    /function finalizeRoom204Facts\([\s\S]*?\n\}/
  )?.[0] ?? "";
  if (!/case "place_room204_piece"[\s\S]*?resolveRoom204Placement\(chapter\.room204Placements/.test(room204ControllerBlock)
    || (room204ControllerBlock.match(/finalizeRoom204Facts\(/g) ?? []).length < 3
    || !/isRoom204PlacementSetComplete\(placements\)/.test(room204FinalizeHelper)
    || !/next\.includes\("a3_reference_observed"\)/.test(room204FinalizeHelper)
    || !/next\.includes\("room204_residual_observed"\)/.test(room204FinalizeHelper)
    || !/next\.push\("room204_restored"\)/.test(room204FinalizeHelper)) {
    errors.push("Task 9 controller must route placement through the pure unique-piece/unique-slot model and commit restored only after both observations");
  }
  if (!/\|\s*\{\s*type:\s*"complete_room204_projection"\s*\}/.test(controller)
    || !/case "complete_room204_projection"[\s\S]*?hasExactKeys\(value, \["type"\]\)/.test(controller)
    || !/case "complete_room204_projection"[\s\S]*?room204_restored[\s\S]*?isRoom204PlacementSetComplete\(chapter\.room204Placements\)[\s\S]*?appendFact\(chapter, "room204_projection_completed"\)/.test(room204ControllerBlock)) {
    errors.push("Task 9 complete_room204_projection must be an exact-key, controller-owned completion intent gated by both observations, restoration and complete placements");
  }
  if (!/case "collect_positioning_plate"[\s\S]*?room204_projection_completed[\s\S]*?appendFact\(chapter, "positioning_plate_collected"\)[\s\S]*?withItem\(state, "clockPositioningPlate", true\)/.test(room204ControllerBlock)
    || !/case "install_positioning_plate"[\s\S]*?room204_projection_completed[\s\S]*?positioning_plate_collected[\s\S]*?transition\(state, "maintenance_repair"[\s\S]*?withItem\(state, "clockPositioningPlate", false\)/.test(room204ControllerBlock)) {
    errors.push("Task 9 positioning plate collection and installation must be controller-owned atomic fact/item transactions after projection completion");
  }

  const room204QuestBlock = quest.match(
    /contract\.id\s*===\s*"room204_restore"[\s\S]*?return contract\.taskKeys\.includes/
  )?.[0] ?? "";
  const groupedRoom204TaskKeys = [
    "resolve_a1_investigation",
    "resolve_a3_archive_chain",
    "solve_misaligned_stair",
    "resolve_a2_inserted_puzzles",
    "restore_room204",
    "watch_room204_projection",
    "collect_positioning_plate",
    "install_positioning_plate"
  ];
  if (groupedRoom204TaskKeys.some((taskKey) => !room204QuestBlock.includes(`"${taskKey}"`))
    || !/!facts\.has\("classroom_104_chalk_residual_observed"\)[\s\S]*?\|\|\s*!facts\.has\("classroom_105_terminal_replay_checked"\)/.test(room204QuestBlock)
    || !/!facts\.has\("elevator_history_observed"\)[\s\S]*?\|\|\s*!facts\.has\("elevator_history_calibrated"\)[\s\S]*?\|\|\s*!facts\.has\("a1_duty_board_reconstructed"\)/.test(room204QuestBlock)
    || !/!facts\.has\("zhu_two_questions_answered"\)[\s\S]*?\|\|\s*!facts\.has\("a3_archive_film_retrieved"\)[\s\S]*?\|\|\s*!facts\.has\("a3_media_alignment_completed"\)/.test(room204QuestBlock)
    || !/!facts\.has\("a2_positioning_plate_calibrated"\)[\s\S]*?\|\|\s*!facts\.has\("a2_power_topology_recovered"\)[\s\S]*?\|\|\s*!facts\.has\("a2_evacuation_route_confirmed"\)/.test(room204QuestBlock)
    || !/!facts\.has\("a3_reference_observed"\)[\s\S]*?\|\|\s*!facts\.has\("room204_residual_observed"\)[\s\S]*?\|\|\s*!facts\.has\("room204_restored"\)/.test(room204QuestBlock)
    || !/facts\.has\("room204_projection_completed"\)/.test(room204QuestBlock)
    || !/facts\.has\("positioning_plate_collected"\)/.test(room204QuestBlock)) {
    errors.push("Task 9 QuestModel must expose grouped A1/A3/A2 objectives while keeping each investigation group and paired light/dark observations order-independent");
  }

  const maintenanceTargetBlock = interaction.match(
    /a1_cleaning_cart_wheel_inspection:[\s\S]*?a1_hall_clock_minute_endpoint:/
  )?.[0] ?? "";
  if (!/chapterFourLayout\.maintenanceRuntime\.targetEntities/.test(runtimeInstallationsBlock)) {
    errors.push("Task 10 runtime resolver must register maintenance entities from the authoritative layout");
  }
  for (const targetId of EXPECTED_MAINTENANCE_TARGET_IDS) {
    if (!maintenanceTargetBlock.includes(`${targetId}:`)
      || !new RegExp(`${targetId}:[\\s\\S]*?runtimeEntityTarget\\(`).test(maintenanceTargetBlock)) {
      errors.push(`Task 10 interaction target ${targetId} must be an independent runtime entity`);
    }
  }
  const maintenanceAliasMatches = maintenanceTargetBlock.match(
    /\["a1_lobby",\s*"a1_hall_clock",\s*"a1_bakery",\s*"a1_cleaning_cart"\]/g
  ) ?? [];
  if (maintenanceAliasMatches.length !== 6) {
    errors.push("Task 10 all six targets must accept the four approved A1 room aliases");
  }
  if (!/a1_cleaning_cart_wheel_inspection:[\s\S]*?cart_wheel_inspection_available[\s\S]*?!hasChapterFourFact\(state, "cart_wheel_inspected"\)/.test(maintenanceTargetBlock)
    || !/a1_bakery_back_pry_bar:[\s\S]*?pry_bar_granted_by_diagnosis[\s\S]*?\(\)\s*=>\s*false/.test(maintenanceTargetBlock)
    || !/a1_cleaning_cart_wheel_cover:[\s\S]*?cart_wheel_inspected[\s\S]*?"shortPryBar"/.test(maintenanceTargetBlock)
    || !/a1_cleaning_cart_oil_bottle:[\s\S]*?oil_granted_by_diagnosis[\s\S]*?\(\)\s*=>\s*false/.test(maintenanceTargetBlock)
    || !/a1_cleaning_cart_wheel:[\s\S]*?cart_wheel_cover_opened[\s\S]*?"universalLubricatingOil"/.test(maintenanceTargetBlock)
    || !/a1_hall_clock_gear:[\s\S]*?clock_gear_repaired_with_linkage[\s\S]*?\(\)\s*=>\s*false/.test(maintenanceTargetBlock)) {
    errors.push("Task 10 registry must expose diagnosis, cover and linked lubrication while closing legacy pickup/second-oil targets");
  }
  const minuteEndpointBlock = interaction.match(
    /a1_hall_clock_minute_endpoint:[\s\S]*?a1_power_panel:/
  )?.[0] ?? "";
  if (!/\["maintenance_repair",\s*"return_to_clock"\]/.test(minuteEndpointBlock)
    || !/state\.chapter4\.phase\s*===\s*"maintenance_repair"[\s\S]*?clock_gear_repaired[\s\S]*?attendanceRecordPaper[\s\S]*?!hasChapterFourFact\(state, "paper_temporarily_out_of_inventory"\)/.test(minuteEndpointBlock)
    || !/state\.chapter4\.phase\s*===\s*"return_to_clock"[\s\S]*?state\.chapter4\.floor\s*===\s*"A1"[\s\S]*?final_minute_recovered[\s\S]*?!hasChapterFourFact\(state, "final_minute_installed"\)[\s\S]*?finalMinute[\s\S]*?attendanceRecordPaper/.test(minuteEndpointBlock)
    || !/maintenance_repair:\s*null/.test(minuteEndpointBlock)
    || !/return_to_clock:\s*"finalMinute"/.test(minuteEndpointBlock)) {
    errors.push("Task 13 minute endpoint must preserve the no-item maintenance drag and accept finalMinute only after returning to A1");
  }

  for (const factId of EXPECTED_MAINTENANCE_FACTS) {
    if (!types.includes(`| "${factId}"`)) errors.push(`Task 10 ChapterFourFactId is missing ${factId}`);
    if (!controller.includes(`"${factId}"`)) errors.push(`Task 10 controller is missing fact ${factId}`);
    if (!saveStore.includes(`"${factId}"`)) errors.push(`Task 10 SaveStore is missing persisted fact ${factId}`);
  }
  const maintenanceControllerBlock = controllerIntentResolver.match(
    /case "inspect_cart_wheel"[\s\S]*?case "trigger_minute_theft"/
  )?.[0] ?? "";
  if (!/case "inspect_cart_wheel"[\s\S]*?chapter4_maintenance_diagnosis_requested[\s\S]*?acceptReadOnly/.test(maintenanceControllerBlock)
    || !/case "complete_maintenance_diagnosis"[\s\S]*?wheel_sound\s*===\s*"latch"[\s\S]*?clock_jam\s*===\s*"gear_offset"[\s\S]*?oil_trace\s*===\s*"oil_shortage"/.test(maintenanceControllerBlock)
    || !/case "complete_maintenance_diagnosis"[\s\S]*?appendFact\(chapter, "cart_wheel_inspected"\)[\s\S]*?shortPryBar:\s*true[\s\S]*?universalLubricatingOil:\s*true/.test(maintenanceControllerBlock)
    || !/case "collect_short_pry_bar"[\s\S]*?reject\("locked"\)/.test(maintenanceControllerBlock)
    || !/case "open_cart_wheel_cover"[\s\S]*?cart_wheel_inspected[\s\S]*?withItem\(state, "shortPryBar", false\)/.test(maintenanceControllerBlock)
    || !/case "collect_lubricating_oil"[\s\S]*?reject\("locked"\)/.test(maintenanceControllerBlock)
    || !/case "lubricate_cart_wheel"[\s\S]*?appendFact\(chapter, "cart_wheel_repaired"\)[\s\S]*?repairedFacts\.push\("clock_gear_repaired"\)[\s\S]*?withItem\(state, "universalLubricatingOil", false\)/.test(maintenanceControllerBlock)
    || !/case "lubricate_clock_gear"[\s\S]*?reject\("locked"\)/.test(maintenanceControllerBlock)) {
    errors.push("Task 10 controller must implement diagnosis, prepared tools, cover opening and one linked lubrication transaction");
  }
  const gearControllerBlock = maintenanceControllerBlock.match(
    /case "lubricate_cart_wheel"[\s\S]*?case "lubricate_clock_gear"/
  )?.[0] ?? "";
  if (!/this\.patchChapter\(state/.test(gearControllerBlock)
    || /transition\(state, "blackout_light_grid"/.test(gearControllerBlock)) {
    errors.push("Task 10 gear repair must remain in maintenance_repair and must not start blackout");
  }
  const patrolRecoveryBlock = maintenanceControllerBlock.match(
    /case "recover_from_maintenance_patrol"[\s\S]*?case "trigger_minute_theft"/
  )?.[0] ?? "";
  if (!/chapter\.phase\s*!==\s*"maintenance_repair"[\s\S]*?chapter\.guardMode\s*!==\s*"patrol"/.test(patrolRecoveryBlock)
    || !/rpgCheckpoint:\s*"c4_a1_lobby"/.test(patrolRecoveryBlock)
    || !/floor:\s*"A1"[\s\S]*?roomId:\s*"a1_lobby"/.test(patrolRecoveryBlock)
    || !/inventoryOpen:\s*false[\s\S]*?selectedItem:\s*null/.test(patrolRecoveryBlock)
    || /fail_chase|chaseAttempt\s*:/.test(patrolRecoveryBlock)) {
    errors.push("Task 10 ordinary patrol capture must use its independent progress-preserving recovery intent");
  }
  const minuteTheftControllerBlock = controllerIntentResolver.match(
    /case "trigger_minute_theft"[\s\S]*?case "begin_final_clock_drag"/
  )?.[0] ?? "";
  if (!/return reject\("locked"\)/.test(minuteTheftControllerBlock)
    || /accept\(|transition\(state, "blackout_light_grid"/.test(minuteTheftControllerBlock)) {
    errors.push("Task 11 controller must keep trigger_minute_theft as a zero-write locked compatibility intent");
  }

  const maintenanceFactOrderBlock = saveStore.match(
    /const CHAPTER_FOUR_MAINTENANCE_FACT_ORDER\s*=\s*\[([\s\S]*?)\]\s*as const/
  )?.[1] ?? "";
  const persistedMaintenanceFactOrder = [...maintenanceFactOrderBlock.matchAll(/"([^"]+)"/g)]
    .map((match) => match[1]);
  if (!sameArray(persistedMaintenanceFactOrder, EXPECTED_MAINTENANCE_FACTS)) {
    errors.push("Task 10 SaveStore maintenance fact order must preserve inspect, cover, wheel and gear causality");
  }
  const maintenanceSaveClosureBlock = saveStore.match(
    /function normalizeChapterFourMaintenanceClosure[\s\S]*?function normalizeChapterThreeInterlude/
  )?.[0] ?? "";
  if (!/clock_gear_repaired"\)\)\s*facts\.add\("cart_wheel_repaired"\)/.test(maintenanceSaveClosureBlock)
    || !/cart_wheel_repaired"\)\)\s*facts\.add\("cart_wheel_cover_opened"\)/.test(maintenanceSaveClosureBlock)
    || !/cart_wheel_cover_opened"\)\)\s*facts\.add\("cart_wheel_inspected"\)/.test(maintenanceSaveClosureBlock)
    || !/CHAPTER_FOUR_POST_MAINTENANCE_PHASES\.has\(phase\)/.test(maintenanceSaveClosureBlock)) {
    errors.push("Task 10 SaveStore must restore maintenance causal closure without advancing the phase");
  }
  const maintenanceLocationBlock = saveStore.match(
    /if \(phase === "maintenance_repair"\)[\s\S]*?if \(phase === "final_chase"\)/
  )?.[0] ?? "";
  if (!/"a1_lobby"[\s\S]*?"a1_hall_clock"[\s\S]*?"a1_bakery"[\s\S]*?"a1_cleaning_cart"/.test(maintenanceLocationBlock)
    || !/roomIds\.has\(savedRoomId\)\s*\?\s*savedRoomId\s*:\s*"a1_lobby"/.test(maintenanceLocationBlock)) {
    errors.push("Task 10 SaveStore must normalize illegal maintenance locations to A1 lobby");
  }
  const maintenanceItemBlocks = saveStore.match(
    /if \(phase === "maintenance_repair"\)\s*\{[\s\S]*?\n\s*\}/g
  ) ?? [];
  const maintenanceItemBlock = maintenanceItemBlocks.at(-1) ?? "";
  if (!/const diagnosisCompleted\s*=\s*hasFact\("cart_wheel_inspected"\)/.test(maintenanceItemBlock)
    || !/items\.shortPryBar\s*=\s*savedItems\.shortPryBar[\s\S]*?!cartWheelCoverOpened/.test(maintenanceItemBlock)
    || !/items\.universalLubricatingOil\s*=\s*diagnosisCompleted[\s\S]*?!hasFact\("clock_gear_repaired"\)[\s\S]*?savedItems\.universalLubricatingOil\s*\|\|\s*cartWheelRepaired/.test(maintenanceItemBlock)) {
    errors.push("Task 10 SaveStore must preserve diagnosed tools and consume them at their final uses");
  }

  const maintenanceQuestBlock = quest.match(
    /contract\.id\s*===\s*"maintenance_repair"[\s\S]*?return contract\.taskKeys\.includes/
  )?.[0] ?? "";
  const maintenanceQuestPositions = EXPECTED_MAINTENANCE_TASK_KEYS.map(
    (taskKey) => maintenanceQuestBlock.indexOf(`"${taskKey}"`)
  );
  if (maintenanceQuestPositions.some((position) => position < 0)
    || maintenanceQuestPositions.some((position, index) => index > 0 && position <= maintenanceQuestPositions[index - 1])) {
    errors.push("Task 10 QuestModel must expose exactly one next objective across the maintenance chain");
  }

  const maintenanceCreationBlock = scene.match(
    /private createMaintenanceRuntime[\s\S]*?private ensureMorningCheckinRuntime/
  )?.[0] ?? "";
  if (!/MAINTENANCE_RUNTIME\.targetEntities/.test(maintenanceCreationBlock)
    || !/"chapter4_story_items"[\s\S]*?pry\.frame[\s\S]*?pry\.uniformScale/.test(maintenanceCreationBlock)
    || !/oilDefinition\.frame[\s\S]*?oilDefinition\.uniformScale/.test(maintenanceCreationBlock)
    || !/this\.physics\.add\.sprite[\s\S]*?cart\.texture/.test(maintenanceCreationBlock)
    || !/cleaner\.animationId[\s\S]*?configureMaintenanceFootBody/.test(maintenanceCreationBlock)
    || !/maintenanceCoverVisual/.test(maintenanceCreationBlock)) {
    errors.push("Task 10 Scene must create six runtime targets plus the authored maintenance visuals and bodies");
  }
  if (!/createMaintenanceTargetZone[\s\S]*?this\.add\.zone/.test(maintenanceCreationBlock)
    || !/deriveStoryItemManifestInteractionBounds[\s\S]*?getChapterFour755ManifestFrame[\s\S]*?interaction\.bounds/.test(maintenanceCreationBlock)
    || !/deriveVisibleFrameLocalBounds[\s\S]*?sourceLocalBounds[\s\S]*?sprite\.originX/.test(maintenanceCreationBlock)
    || !/deriveClockManifestInteractionBounds[\s\S]*?hallClockStateSprite[\s\S]*?coordinateSpace === "world"/.test(maintenanceCreationBlock)
    || !/outwardPhaseRuntimeBounds[\s\S]*?getBounds\(\)[\s\S]*?Math\.floor\(bounds\.left[\s\S]*?Math\.ceil\(bounds\.right/.test(scene)
    || !/validateMaintenanceRuntimeBounds[\s\S]*?definition\.installationBounds/.test(maintenanceCreationBlock)
    || /const bounds = definition\.installationBounds[\s\S]*?phaseRuntimeTargets\.set/.test(maintenanceCreationBlock)) {
    errors.push("Task 10 Scene must derive six target Zones from visible sprites/source contracts before outward layout comparison");
  }
  const maintenancePushBlock = maintenanceCreationBlock.match(
    /private startOrRestoreMaintenancePush[\s\S]*?private createMaintenanceGuardRuntime/
  )?.[0] ?? "";
  if (!/this\.maintenancePushCompleted \|\| this\.maintenancePushTween/.test(maintenancePushBlock)
    || !/maintenanceCart\.disableBody\(false, true\)[\s\S]*?maintenanceCart\.destroy\(\)[\s\S]*?maintenanceCart = null/.test(maintenancePushBlock)
    || !/MAINTENANCE_RUNTIME\.repairedPush\.animationId/.test(maintenancePushBlock)
    || !/targets:\s*this\.maintenanceCleaner/.test(maintenancePushBlock)
    || /targets:\s*\[[^\]]*maintenanceCart/.test(maintenancePushBlock)
    || !/MAINTENANCE_RUNTIME\.repairedPush\.animationId/.test(maintenanceCreationBlock)
    || !/duration:\s*MAINTENANCE_RUNTIME\.repairedPush\.durationMs/.test(maintenanceCreationBlock)
    || !/maintenanceObstacleCollider\?\.destroy\(\)/.test(maintenanceCreationBlock)) {
    errors.push("Task 10 repaired wheel must destroy the independent cart and move only the combined 900ms push sprite once");
  }
  if (!/this\.physics\.add\.collider\(\s*this\.maintenanceGuard,\s*this\.staticObstacles/.test(maintenanceCreationBlock)
    || !/this\.physics\.add\.overlap\(\s*this\.player,\s*this\.maintenanceGuard/.test(maintenanceCreationBlock)
    || !/maintenanceGuardVision\s*=\s*this\.add\.graphics/.test(maintenanceCreationBlock)
    || !/maintenanceGuardAlert\s*=\s*this\.add\.text[\s\S]*?"!"/.test(maintenanceCreationBlock)
    || !/mode\s*!==\s*"pursuit"[\s\S]*?chapterFourGuardFootContact/.test(maintenanceCreationBlock)
    || !/type:\s*"recover_from_maintenance_patrol"/.test(maintenanceCreationBlock)) {
    errors.push("Task 10 Scene must render a non-colliding ordinary guard warning and capture only on pursuit foot overlap");
  }
  const maintenanceGuardUpdateBlock = maintenanceCreationBlock.match(
    /private updateMaintenanceGuard[\s\S]*?private paintMaintenanceGuardVision/
  )?.[0] ?? "";
  if (!/maintenanceGuardFootPoint/.test(maintenanceGuardUpdateBlock)
    || !/guardPosition:\s*\{\s*x:\s*guardFoot\.x,\s*y:\s*guardFoot\.y\s*\}/.test(maintenanceGuardUpdateBlock)
    || !/setVelocity\(next\.desiredVelocity\.x, next\.desiredVelocity\.y\)/.test(maintenanceGuardUpdateBlock)
    || /this\.maintenanceGuard\s*\.?\s*setPosition\(/.test(maintenanceGuardUpdateBlock)
    || !/chapterFourGuardFootContact[\s\S]*?guardBody\.center\.x/.test(maintenanceCreationBlock)) {
    errors.push("Task 10 guard must feed the actual Arcade foot back into the pure model and apply velocity without frame-by-frame teleporting");
  }
  if (!/createChapterFourMaintenanceGuardRecoveryState/.test(maintenanceCreationBlock)
    || !/floor\.offsetX\s*\+\s*836,\s*716/.test(maintenanceCreationBlock)
    || !/position:\s*\{\s*x:\s*588,\s*y:\s*220\s*\}/.test(guardModel)
    || !/targetWaypointId:\s*"stair_north"/.test(guardModel)) {
    errors.push("Task 10 accepted patrol recovery must reset player and guard to the authored safe route");
  }
  const maintenanceSpaceBlock = storyTargetInteractionBlock;
  if (!["inspect_cart_wheel", "collect_short_pry_bar", "collect_lubricating_oil"].every(
    (intentType) => maintenanceSpaceBlock.includes(`type: "${intentType}"`)
  ) || ["open_cart_wheel_cover", "lubricate_cart_wheel", "lubricate_clock_gear", "trigger_minute_theft"].some(
    (intentType) => maintenanceSpaceBlock.includes(`type: "${intentType}"`)
  ) || !/acceptedItem[\s\S]*?拖动道具/.test(maintenanceSpaceBlock)) {
    errors.push("Task 10 Space must handle only wheel inspection/pry/oil while cover/wheel/gear remain drag-only");
  }
  const maintenanceDropBlock = scene.match(
    /private handleInventoryDrop[\s\S]*?private emitDropFeedback/
  )?.[0] ?? "";
  if (!["open_cart_wheel_cover", "lubricate_cart_wheel", "lubricate_clock_gear"].every(
    (intentType) => maintenanceDropBlock.includes(`type: "${intentType}"`)
  ) || !/missed_target/.test(maintenanceDropBlock)
    || !/wrong_item/.test(maintenanceDropBlock)) {
    errors.push("Task 10 drag-only targets must submit measured runtime envelopes and explicit drop feedback");
  }
  if (!/destroyPhaseRuntime[\s\S]*?maintenancePushTween\?\.stop\(\)[\s\S]*?maintenanceObstacleCollider\?\.destroy\(\)[\s\S]*?maintenanceGuardWallCollider\?\.destroy\(\)[\s\S]*?maintenanceGuardPlayerOverlap\?\.destroy\(\)/.test(scene)) {
    errors.push("Task 10 Scene teardown must destroy the maintenance tween, colliders and overlap");
  }

  const finalClockControllerBlock = controllerIntentResolver.match(
    /case "begin_final_clock_drag"[\s\S]*?case "open_power_panel"/
  )?.[0] ?? "";
  if (!/case "begin_final_clock_drag"[\s\S]*?clock_gear_repaired[\s\S]*?attendanceRecordPaper[\s\S]*?return acceptReadOnly\(\)/.test(finalClockControllerBlock)
    || !/case "complete_minute_theft"[\s\S]*?chapter\.mode !== "light"[\s\S]*?return reject\("wrong_mode"\)/.test(finalClockControllerBlock)
    || !/case "complete_minute_theft"[\s\S]*?transition\(state, "blackout_light_grid"[\s\S]*?paper_temporarily_out_of_inventory[\s\S]*?attendanceRecordPaper", false[\s\S]*?CHAPTER_FOUR_LIGHT_GRID\.initialMask[\s\S]*?roomId:\s*"a1_lobby"[\s\S]*?checkpoint:\s*"c4_a1_lobby"/.test(finalClockControllerBlock)) {
    errors.push("Task 11 controller must separate a strict zero-write final-clock begin from the light-mode-revalidated atomic 07:54 blackout completion transaction");
  }
  const powerControllerBlock = controllerIntentResolver.match(
    /case "open_power_panel"[\s\S]*?case "reach_202_threshold"/
  )?.[0] ?? "";
  if (!/case "open_power_panel"[\s\S]*?paper_temporarily_out_of_inventory[\s\S]*?return acceptReadOnly\(\)/.test(powerControllerBlock)
    || !/case "toggle_light_zone"[\s\S]*?toggleChapterFourLightZone\(previousMask, intent\.zoneId\)[\s\S]*?power_zone_toggled/.test(powerControllerBlock)
    || !/case "lock_light_grid"[\s\S]*?isChapterFourLightGridSolved[\s\S]*?targetMask[\s\S]*?zhu_two_questions_answered[\s\S]*?light_grid_locked[\s\S]*?canruo_star_lamp_primed[\s\S]*?transition\(state, "final_chase"[\s\S]*?locked:\s*true[\s\S]*?power_grid_locked/.test(powerControllerBlock)) {
    errors.push("Task 11 controller must use the shared pure grid model for open, toggle, unique-target lock and final-chase commit");
  }

  const finalClockSceneBlock = scene.match(
    /private ensureFinalClockRuntime[\s\S]*?private createLightGridRuntime/
  )?.[0] ?? "";
  if (!/finalClockEndpointHandle\.getBounds\(\)/.test(finalClockSceneBlock)
    || !/Math\.floor\(visibleBounds\.left/.test(finalClockSceneBlock)
    || !/Math\.ceil\(visibleBounds\.right/.test(finalClockSceneBlock)
    || !/begin_final_clock_drag/.test(finalClockSceneBlock)
    || !/complete_minute_theft/.test(finalClockSceneBlock)
    || !/presentation\.paperFlightAtMs/.test(finalClockSceneBlock)
    || !/presentation\.commitAtMs/.test(finalClockSceneBlock)
    || !/rollbackMinuteTheftToCommittedState/.test(finalClockSceneBlock)) {
    errors.push("Task 11 Scene must derive the endpoint from visible getBounds, run the authored clock/paper timeline, and roll back rejected or timed-out presentation state");
  }
  const task11SceneLifecycleBlock = scene.match(
    /private ensureFinalClockRuntime[\s\S]*?private preferredDestinationForFloor/
  )?.[0] ?? "";
  if (!/pointerupoutside/.test(task11SceneLifecycleBlock)
    || !/pointer\.wasCanceled[\s\S]*?rollbackMinuteTheftToCommittedState/.test(task11SceneLifecycleBlock)
    || !/FINAL_CLOCK_DRAG_SAFETY_TIMEOUT_MS[\s\S]*?rollbackMinuteTheftToCommittedState/.test(task11SceneLifecycleBlock)
    || !/private finishFinalClockDrag[\s\S]*?finalClockDragSafetyTimer\?\.remove\(false\)[\s\S]*?beginMinuteTheftPresentation/.test(task11SceneLifecycleBlock)
    || !/private rollbackMinuteTheftToCommittedState[\s\S]*?finalClockDragSafetyTimer\?\.remove\(false\)[\s\S]*?storyPresentation = "idle"[\s\S]*?syncStoryInputLock\(\)/.test(task11SceneLifecycleBlock)
    || !/private destroyFinalClockRuntime[\s\S]*?off\("pointerupoutside"[\s\S]*?finalClockDragSafetyTimer\?\.remove\(false\)[\s\S]*?finalClockDragActive = false/.test(task11SceneLifecycleBlock)
    || !/private destroyPhaseRuntime[\s\S]*?destroyTask11Runtime\(reason\)/.test(scene)) {
    errors.push("Task 11 final-clock pointer release, cancellation, safety timeout, phase change and teardown must clear timers, pointer listeners and the Host input lock without residual runtime state");
  }
  const finalClockDomCancelBlock = scene.match(
    /private readonly handleFinalClockDomPointerDown[\s\S]*?private finishFinalClockDrag/
  )?.[0] ?? "";
  if (!/this\.game\.canvas[\s\S]*?addEventListener\([\s\S]*?"pointerdown"/.test(task11SceneLifecycleBlock)
    || !/handleFinalClockDomPointerCancel[\s\S]*?finalClockDragActive[\s\S]*?event\.pointerId !== this\.finalClockDragDomPointerId[\s\S]*?rollbackMinuteTheftToCommittedState/.test(finalClockDomCancelBlock)
    || !/installFinalClockDomCancelListener[\s\S]*?addEventListener\([\s\S]*?"pointercancel"/.test(finalClockDomCancelBlock)
    || !/removeFinalClockDomCancelListener[\s\S]*?removeEventListener\([\s\S]*?"pointercancel"/.test(finalClockDomCancelBlock)
    || !/private finishFinalClockDrag[\s\S]*?removeFinalClockDomCancelListener\(\)/.test(task11SceneLifecycleBlock)
    || !/private rollbackMinuteTheftToCommittedState[\s\S]*?removeFinalClockDomCancelListener\(\)/.test(task11SceneLifecycleBlock)
    || !/private destroyFinalClockRuntime[\s\S]*?removeFinalClockDomCancelListener\(\)[\s\S]*?removeEventListener\([\s\S]*?"pointerdown"/.test(task11SceneLifecycleBlock)) {
    errors.push("Task 11 must subscribe to native pointercancel on the current Phaser canvas, match only the active DOM pointer id, roll back immediately, and remove final-clock DOM listeners on every end path");
  }
  if (!/private isStoryInputLocked\(\)[\s\S]*?finalClockDragActive/.test(scene)
    || !/private beginAcceptedFinalClockDrag[\s\S]*?finalClockDragActive = true[\s\S]*?syncStoryInputLock\(\)/.test(scene)
    || !/allowScenePointer[\s\S]*?finalClockDragActive[\s\S]*?storyPresentation === "idle"[\s\S]*?pendingStoryRequest === null/.test(scene)
    || !/chapter4OverlayBlocked\s*=\s*chapter4InteractionBlocked\s*\|\|\s*chapter4PowerPanelOpen/.test(host)
    || !/chapter4PhaserInputBlocked[\s\S]*?chapter4InteractionBlocked && !chapter4ScenePointerAllowed/.test(host)
    || !/chapter4PhaserKeyboardBlocked[\s\S]*?chapter4InteractionBlocked && !chapter4SceneKeyboardAllowed/.test(host)
    || !/setChapter4ScenePointerAllowed\(locked && event\.payload\?\.allowScenePointer === true\)/.test(host)
    || !/setChapter4SceneKeyboardAllowed\(locked && event\.payload\?\.allowSceneKeyboard === true\)/.test(host)
    || !/setRpgKeyboardEnabled\(game, !keyboardBlocked && !chapter4PhaserKeyboardBlocked\)/.test(host)
    || !/showTaskBar[\s\S]*?!chapter4OverlayBlocked/.test(host)
    || !/photoSessionOpen \|\| chapter4OverlayBlocked \? null/.test(host)
    || !/chapter4MazeUiActive && !chapter4OverlayBlocked/.test(host)
    || !/!chapter4OverlayBlocked\s*&&\s*!fishingSession\s*&&\s*!photoSessionOpen[\s\S]*?<RpgInventoryDock/.test(host)) {
    errors.push("Task 11 final-clock drag and minute-theft presentation must keep Scene movement plus Host task, system, mode and inventory controls locked");
  }
  if (!/allowScenePointer[\s\S]*?this\.alumniPanel !== null/.test(scene)
    || !/allowSceneKeyboard\s*=\s*locked && this\.alumniPanel !== null/.test(scene)
    || !/actionButton[\s\S]*?setInteractive[\s\S]*?advanceAlumniPanel/.test(scene)
    || !/confirmButton[\s\S]*?setInteractive[\s\S]*?advanceAlumniPanel/.test(scene)) {
    errors.push("A3 alumni modal must keep Scene pointer/keyboard input available and provide explicit pointer confirmation controls");
  }
  const lifecycleCleanupBlock = scene.match(
    /this\.pendingMoveTimer\?\.remove\(false\)[\s\S]*?clearRpgRuntimeDebugState\(\)/
  )?.[0] ?? "";
  if (!/destroyTask12Runtime\("scene_shutdown"\)/.test(lifecycleCleanupBlock)) {
    errors.push("Task 11-12 Scene shutdown must explicitly clear all final chase, minute and door runtime objects before the Phaser Scene instance can be reused");
  }
  const lightGridSceneBlock = scene.match(
    /private createLightGridRuntime[\s\S]*?private destroyTask11Runtime/
  )?.[0] ?? "";
  if (!/LIGHT_GRID_RUNTIME\.visualRegions/.test(lightGridSceneBlock)
    || !/lightGrid(?:Visual)?Overlays\.set/.test(lightGridSceneBlock)
    || !/this\.add\.zone/.test(lightGridSceneBlock)
    || /physics\.add/.test(lightGridSceneBlock)) {
    errors.push("Task 11 Scene must render the five lighting regions as visual overlays and keep the exact power panel interaction out of physics collision");
  }

  if (/Phaser|GameStore|document\.|window\.|HTMLElement/.test(lightGridModel)
    || !/EXPECTED_TOGGLE_MASKS[\s\S]*?7, 19, 13, 28, 26/.test(lightGridModel)
    || !/enumerateChapterFourLightGridSolutions/.test(lightGridModel)
    || !/applyChapterFourLightGridClickVector/.test(lightGridModel)
    || !/isChapterFourLightGridSolved/.test(lightGridModel)) {
    errors.push("Task 11 light-grid model must remain a pure 32-state XOR/evaluation/enumeration module independent from Phaser, stores and DOM");
  }
  if (!/interface ChapterFourPowerPanelSession[\s\S]*?runtimeTarget/.test(host)
    || !/(?:trustedIntent|intent)\.type === "open_power_panel"[\s\S]*?setChapter4PowerPanelSession/.test(host)
    || !/rpg_chapter4_power_panel_open_state_changed/.test(host)
    || !/<ChapterFourPowerPanelGame/.test(host)
    || !/chapter4PowerPanelOpen/.test(host)
    || !/chapter4PowerPanelPendingRequestRef\.current !== null/.test(host)
    || !/runtimeTarget:\s*session\.runtimeTarget/.test(host)
    || !/rpg_chapter4_755_intent_requested/.test(host)) {
    errors.push("Task 11 Host must cache the accepted panel session, lock shared controls, mount one React panel, and notify the Scene of the modal input lock");
  }
  if (!/CHAPTER_FOUR_LIGHT_GRID\.zones\.map/.test(powerPanel)
    || !/POWER_PANEL_CONNECTIONS[\s\S]*?zone\.adjacentZoneIds/.test(powerPanel)
    || !/POWER_PANEL_ZONE_ORDER\.map/.test(powerPanel)
    || !/<line[\s\S]*?x1=\{from\.x\}[\s\S]*?y2=\{to\.y\}/.test(powerPanel)
    || !/aria-pressed/.test(powerPanel)
    || !/event\.key === "Escape"/.test(powerPanel)
    || !/isChapterFourLightGridSolved\(mask\)/.test(powerPanel)
    || !/locked \|\| pending \|\| !solved/.test(powerPanel)
    || !/onLock\(\)/.test(powerPanel)
    || !/canRetryLock[\s\S]*?lastAutoLockMaskRef\.current === mask/.test(powerPanel)
    || !/aria-label="重试锁定配电结果"[\s\S]*?onClick=\{onLock\}/.test(powerPanel)
    || /verifiedSolutionZoneIds|clickVector/.test(powerPanel)) {
    errors.push("Task 11 React power panel must draw the exact adjacency graph, expose five accessible state lights, keep unlocked Escape and automatic solved locking, and avoid revealing the answer");
  }
  if (!/POWER_PANEL_ZONE_POSITIONS[\s\S]*?hall:[\s\S]*?column:\s*2,\s*row:\s*1/.test(powerPanel)
    || !/west_corridor:[\s\S]*?column:\s*1,\s*row:\s*2/.test(powerPanel)
    || !/east_corridor:[\s\S]*?column:\s*3,\s*row:\s*2/.test(powerPanel)
    || !/bakery_back_area:[\s\S]*?column:\s*1,\s*row:\s*3/.test(powerPanel)
    || !/classroom_zone:[\s\S]*?column:\s*3,\s*row:\s*3/.test(powerPanel)
    || !/POWER_PANEL_CONNECTIONS[\s\S]*?zone\.adjacentZoneIds/.test(powerPanel)
    || !/chapter4-power-panel__connections/.test(powerPanel)
    || !/style=\{\{\s*left:\s*`\$\{position\.x\}%`,\s*top:\s*`\$\{position\.y\}%`\s*\}\}/.test(powerPanel)
    || !/focusInDirection/.test(powerPanel)
    || /focusByDelta/.test(powerPanel)
    || !/\.chapter4-power-panel__grid\s*\{[\s\S]*?display:\s*block[\s\S]*?height:\s*232px/.test(powerPanelCss)
    || !/\.chapter4-power-panel__grid button\s*\{[\s\S]*?position:\s*absolute/.test(powerPanelCss)
    || !/\.chapter4-power-panel__connections\s*\{[\s\S]*?position:\s*absolute/.test(powerPanelCss)) {
    errors.push("Task 11 power panel must render the five authored zones from the shared adjacency graph and keep spatial keyboard navigation");
  }

  if (/^\s*import\s/m.test(finalChaseModel)
    || /Phaser|GameStore|document\.|window\.|HTMLElement/.test(finalChaseModel)) {
    errors.push("Task 12 final-chase model must remain a pure module independent from Phaser, stores and DOM");
  }
  if (!/"arming"[\s\S]*?"running"[\s\S]*?"portal_transfer"[\s\S]*?"finish_pending"[\s\S]*?"failure_pending"[\s\S]*?"complete"/.test(finalChaseModel)
    || !/stableFramesToArm:\s*4/.test(finalChaseModel)
    || !/playerSpeed:\s*208/.test(finalChaseModel)
    || !/guardSpeed:\s*196/.test(finalChaseModel)
    || !/maxStepMs:\s*50/.test(finalChaseModel)
    || !/transportId:\s*"main_stair"/.test(finalChaseModel)
    || !/playerStart:[\s\S]*?x:\s*590,\s*y:\s*612/.test(finalChaseModel)
    || !/guardSpawn:[\s\S]*?x:\s*590,\s*y:\s*724/.test(finalChaseModel)
    || !/finishThreshold:[\s\S]*?x:\s*1353,\s*y:\s*356\.5/.test(finalChaseModel)
    || !/if \(input\.floor === "A2" && input\.playerInsideFinish[^)]*\)[\s\S]*?if \(input\.guardContact[^)]*\)/.test(finalChaseModel)) {
    errors.push("Task 12 pure final-chase model must encode the six phases, four-frame arming, exact speeds/points, main-stair portal and finish-before-contact ordering");
  }
  const task12ControllerBlock = controllerIntentResolver.match(
    /case "traverse_main_stair"[\s\S]*?case "read_campus_card"/
  )?.[0] ?? "";
  if (!/case "traverse_main_stair"[\s\S]*?intent\.expectedAttempt !== chapter\.chaseAttempt[\s\S]*?chapter\.phase === "final_chase"[\s\S]*?fromFloor === "A1"[\s\S]*?toFloor === "A2"[\s\S]*?chapter\.phase === "return_to_clock"[\s\S]*?fromFloor === "A2"[\s\S]*?toFloor === "A1"/.test(task12ControllerBlock)
    || !/case "reach_202_threshold"[\s\S]*?intent\.expectedAttempt !== chapter\.chaseAttempt[\s\S]*?"final_minute_recovery"[\s\S]*?roomId:\s*"a2_room_202"[\s\S]*?checkpoint:\s*"c4_a2_room202"/.test(task12ControllerBlock)
    || !/case "fail_chase"[\s\S]*?intent\.expectedAttempt !== chapter\.chaseAttempt[\s\S]*?chaseAttempt:\s*chapter\.chaseAttempt \+ 1[\s\S]*?checkpoint:\s*"c4_a1_lobby"/.test(task12ControllerBlock)
    || !/case "collect_final_minute"[\s\S]*?"final_minute_recovered"[\s\S]*?"finalMinute", true[\s\S]*?"attendanceRecordPaper", true[\s\S]*?"return_to_clock"[\s\S]*?roomId:\s*"a2_room_202"/.test(task12ControllerBlock)) {
    errors.push("Task 12 controller must own attempt-checked stair traversal, atomic finish/fail/final-minute transactions and the A2 recovery position");
  }
  if (!/case "reach_202_threshold"[\s\S]*?\["expectedAttempt"\]/.test(controller)
    || !/case "fail_chase"[\s\S]*?hasExactKeys\(value, \["type", "expectedAttempt"\]\)/.test(controller)
    || !/case "traverse_main_stair"[\s\S]*?hasExactKeys\(value, \["type", "fromFloor", "toFloor", "expectedAttempt"\]\)/.test(controller)) {
    errors.push("Task 12 intent parser must require exact expectedAttempt fields for finish, failure and main-stair transfer");
  }
  if (!/phase === "final_chase"[\s\S]*?return \{ floor: "A1", roomId: "a1_lobby" \}/.test(saveStore)
    || !/phase === "final_minute_recovery"[\s\S]*?return \{ floor: "A2", roomId: "a2_room_202" \}/.test(saveStore)
    || !/phase === "return_to_clock"[\s\S]*?savedFloor === "A2"[\s\S]*?"a2_room_202"[\s\S]*?floor:\s*"A1"/.test(saveStore)
    || !/roomId === "a2_lecture_202" \? "a2_room_202"/.test(saveStore)
    || !/chapter\.phase === "final_chase"\) return "c4_a1_lobby"/.test(saveStore)
    || !/chapter\.phase === "final_minute_recovery"\) return "c4_a2_room202"/.test(saveStore)) {
    errors.push("Task 12 SaveStore must restart chase at A1, restore recovery inside A2-202, preserve either return floor, migrate the legacy room id and select matching checkpoints");
  }
  if (!/const taskKey = selectChapterFour755TaskKey\(state, contract\)/.test(quest)
    || !/steps:\s*\[\{[\s\S]*?id:\s*`chapter_four_\$\{taskKey\}`/.test(quest)) {
    errors.push("Task 12 QuestModel must continue exposing exactly the one current content-owned return objective");
  }
  const task12TargetBlock = interaction.match(
    /a2_202_projection:\s*runtimeEntityTarget\([\s\S]*?\n\s*\),/
  )?.[0] ?? "";
  if (!/"a2_202_projection"[\s\S]*?finalMinuteRuntime[\s\S]*?entityId/.test(task12TargetBlock)
    || !/\["final_minute_recovery"\]/.test(task12TargetBlock)
    || /layoutAnchorTarget/.test(task12TargetBlock)) {
    errors.push("Task 12 final-minute target must be a closed-by-default runtime entity, never a static layout anchor");
  }
  const task12SceneRuntimeBlock = scene.match(
    /private ensureFinalChaseRuntime[\s\S]*?private syncPhaseSideEffects/
  )?.[0] ?? "";
  if (!/createChapterFourFinalChaseState\(state\.chapter4\.chaseAttempt\)/.test(task12SceneRuntimeBlock)
    || !/setVisible\(false\)/.test(task12SceneRuntimeBlock)
    || !/committedAndApplied[\s\S]*?projectionSignature === this\.pendingProjectionSignature[\s\S]*?appliedPlateIds/.test(task12SceneRuntimeBlock)
    || !/stepChapterFourFinalChase\(runtime/.test(task12SceneRuntimeBlock)
    || !/chapterFourFinalChaseFootContact/.test(task12SceneRuntimeBlock)
    || !/playerEnteredMainStair/.test(task12SceneRuntimeBlock)
    || !/expectedAttempt:\s*committed\.chapter4\.chaseAttempt/.test(task12SceneRuntimeBlock)) {
    errors.push("Task 12 Scene must arm only from four committed/applied frames, feed actual feet into the pure model, recognize the real main stair and attach current attempt tokens to finish/failure");
  }
  if (!/const movementSpeed = this\.bridge\.getState\(\)\.chapter4\.phase === "final_chase"[\s\S]*?CHAPTER_FOUR_FINAL_CHASE_RULES\.playerSpeed/.test(scene)
    || !/phase === "final_chase" \|\| phase === "return_to_clock"[\s\S]*?\u4e3b\u697c\u68af/.test(scene)
    || !/authoredStairTransfer[\s\S]*?type:\s*"traverse_main_stair"[\s\S]*?expectedAttempt:\s*state\.chapter4\.chaseAttempt/.test(scene)) {
    errors.push("Task 12 Scene must apply the 208px/s chase speed, lock the elevator and submit only attempt-checked main-stair transfers in chase/return");
  }
  if (!/FINAL_MINUTE_RUNTIME\.texture[\s\S]*?FINAL_MINUTE_RUNTIME\.frame[\s\S]*?sprite\.getBounds\(\)[\s\S]*?Math\.floor\(measured\.left[\s\S]*?Math\.ceil\(measured\.right[\s\S]*?this\.add\.zone/.test(task12SceneRuntimeBlock)
    || !/ensureRoom202RecoveryBarrier[\s\S]*?FINAL_CHASE_RUNTIME\.room202Door\.barrierBounds[\s\S]*?this\.physics\.add\.existing\(zone, true\)[\s\S]*?this\.physics\.add\.collider\(this\.player, zone\)/.test(task12SceneRuntimeBlock)) {
    errors.push("Task 12 Scene must derive the final-minute Zone from the visible sprite and create the recovery-only Room202 barrier from authoritative layout bounds");
  }
  if (!/private destroyFinalMinuteRuntime[\s\S]*?phaseRuntimeTargets\.delete[\s\S]*?finalMinuteTargetZone\?\.destroy\(\)[\s\S]*?finalMinuteSprite\?\.destroy\(\)/.test(task12SceneRuntimeBlock)
    || !/private destroyRoom202RecoveryBarrier[\s\S]*?room202DoorCollider\?\.destroy\(\)[\s\S]*?room202DoorBarrier\?\.destroy\(\)[\s\S]*?room202DoorVisual\?\.destroy\(\)[\s\S]*?room202DoorLabel\?\.destroy\(\)/.test(task12SceneRuntimeBlock)
    || !/private destroyChaseRuntime[\s\S]*?chaseGuardStaticCollider\?\.destroy\(\)[\s\S]*?chaseGuardPlateCollider\?\.destroy\(\)[\s\S]*?chaseGuard\?\.destroy\(\)[\s\S]*?finalChaseState = null/.test(task12SceneRuntimeBlock)
    || !/private destroyTask12Runtime[\s\S]*?destroyChaseRuntime\(\)[\s\S]*?destroyFinalMinuteRuntime[\s\S]*?destroyRoom202RecoveryBarrier/.test(task12SceneRuntimeBlock)
    || !/destroyTask12Runtime\("scene_shutdown"\)/.test(scene)) {
    errors.push("Task 12 shutdown/destroy must clear guard colliders/sprite/state, final-minute sprite/Zone/registry and every procedural door object");
  }
  if (!/timedOutIntentType === "reach_202_threshold"[\s\S]*?resolveChapterFourFinalChaseFinish\(this\.finalChaseState, false\)/.test(scene)
    || !/timedOutIntentType === "fail_chase"[\s\S]*?resolveChapterFourFinalChaseFailure\(this\.finalChaseState, false\)/.test(scene)
    || !/target\.contract\.id === "a1_hall_clock_minute_endpoint"[\s\S]*?itemId === "finalMinute"[\s\S]*?type:\s*"install_final_minute"/.test(scene)) {
    errors.push("Task 12 timeout paths must release pending finish/failure handshakes, and Task13 must submit the finalMinute drop through the visible minute endpoint");
  }

  const task13ControllerBlock = controllerIntentResolver.match(
    /case "install_final_minute"[\s\S]*?case "acknowledge_exterior_closure"[\s\S]*?\n\s*\}/
  )?.[0] ?? "";
  if (!/case "install_final_minute"[\s\S]*?chapter\.phase !== "return_to_clock"[\s\S]*?chapter\.floor !== "A1"[\s\S]*?final_minute_recovered[\s\S]*?finalMinute[\s\S]*?attendanceRecordPaper[\s\S]*?campusCard[\s\S]*?transition\(state, "morning_checkin"[\s\S]*?final_minute_installed[\s\S]*?"finalMinute", false[\s\S]*?roomId:\s*"a1_checkin"/.test(task13ControllerBlock)
    || !/case "read_campus_card"[\s\S]*?phase !== "morning_checkin"[\s\S]*?roomId !== "a1_checkin"[\s\S]*?acceptCheckinTarget\(state, "card"\)/.test(task13ControllerBlock)
    || !/case "submit_attendance_paper"[\s\S]*?phase !== "morning_checkin"[\s\S]*?roomId !== "a1_checkin"[\s\S]*?acceptCheckinTarget\(state, "paper"\)/.test(task13ControllerBlock)
    || !/cardAccepted && paperAccepted[\s\S]*?transition\(state, "exterior_closure"[\s\S]*?roomId:\s*"a1_exterior"/.test(controller)) {
    errors.push("Task 13 controller must atomically install the final minute, accept both retained check-in items in either order and enter the unacknowledged exterior wait");
  }
  if (!/case "acknowledge_exterior_closure"[\s\S]*?closureSessionVerifier\.reference[\s\S]*?closureProofMatchesReference\(intent\.proof, reference\)[\s\S]*?verifyCompletedSession\(intent\.proof\)/.test(controller)
    || !/proof:\s*ChapterFourClosureSessionProof/.test(controller)
    || !/hasExactKeys\(value, \["type", "proof"\]\)/.test(controller)
    || !/CHAPTER_FOUR_APPROVED_CLOSURE_REFERENCE:[\s\S]*?= null/.test(closureContract)
    || !/verifyCompletedSession:[\s\S]*?=> false/.test(closureContract)
    || /syncExteriorClosureAcknowledgement/.test(scene)
    || /requestStoryIntent\(\{\s*type:\s*"acknowledge_exterior_closure"\s*\}\)/.test(scene)) {
    errors.push("Task 13 exterior completion must require an exact approved consumer session proof and remain locked while the official reference is absent");
  }

  const task13SceneRuntimeBlock = scene.match(
    /private ensureMorningCheckinRuntime[\s\S]*?private ensureFinalChaseRuntime/
  )?.[0] ?? "";
  if (!/MORNING_CHECKIN_RUNTIME\.targetEntities\.find/.test(task13SceneRuntimeBlock)
    || !/fixture\.getBounds\(\)/.test(task13SceneRuntimeBlock)
    || !/this\.add\.zone[\s\S]*?zone\.getBounds\(\)/.test(task13SceneRuntimeBlock)
    || !/rectEquals\(derived, bounds\)/.test(task13SceneRuntimeBlock)
    || !/rectEquals\(measuredZone, bounds\)/.test(task13SceneRuntimeBlock)
    || !/phaseRuntimeTargets\.set\(targetId[\s\S]*?entityId:\s*installation\.entityId[\s\S]*?boundsObject:\s*zone/.test(task13SceneRuntimeBlock)
    || !/morningCheckinVisuals\.clear\(\)/.test(task13SceneRuntimeBlock)) {
    errors.push("Task 13 Scene must derive each visible check-in fixture getBounds into one exact Zone/registry envelope and clear every object on teardown");
  }
  const task13TargetBlock = interaction.match(
    /a1_campus_card_reader:\s*runtimeEntityTarget[\s\S]*?a1_attendance_paper_slot:\s*runtimeEntityTarget[\s\S]*?\n\s*\)/
  )?.[0] ?? "";
  if (!/chapterFourLayout\.morningCheckinRuntime/.test(interaction)
    || !/\["a1_checkin"\]/.test(task13TargetBlock)
    || !/campus_card_checkin_available[\s\S]*?!state\.chapter4\.checkinCardAccepted[\s\S]*?!hasChapterFourFact\(state, "checkin_card_accepted"\)/.test(task13TargetBlock)
    || !/attendance_paper_checkin_available[\s\S]*?!state\.chapter4\.checkinPaperAccepted[\s\S]*?!hasChapterFourFact\(state, "checkin_paper_accepted"\)/.test(task13TargetBlock)) {
    errors.push("Task 13 registry must source both exact 56/up check-in targets from morningCheckinRuntime and expose them only in a1_checkin");
  }
  if (!/normalizeChapterFourCheckinClosure/.test(saveStore)
    || !/saved\.checkinCardAccepted === true[\s\S]*?savedFactIds\.includes\("checkin_card_accepted"\)/.test(saveStore)
    || !/phase === "morning_checkin" && savedCardAccepted && savedPaperAccepted[\s\S]*?phase = "exterior_closure"/.test(saveStore)
    || !/facts\.delete\("exterior_closure_acknowledged"\)/.test(saveStore)
    || !/const savedCompletionVerified = envelopeVersion >= CHAPTER_FOUR_CLOSURE_SAVE_VERSION[\s\S]*?savedPhase === "complete"[\s\S]*?saved\.completed === true[\s\S]*?saved\.exteriorClosureAcknowledged === true[\s\S]*?savedCardAccepted[\s\S]*?savedPaperAccepted[\s\S]*?savedLightGridForCompletion\.locked === true[\s\S]*?savedLightGridForCompletion\.mask === 13/.test(saveStore)
    || !/const savedClaimsCompletion = saved\.completed === true[\s\S]*?savedPhase === "complete"[\s\S]*?saved\.exteriorClosureAcknowledged === true[\s\S]*?savedFactIds\.includes\("exterior_closure_acknowledged"\)/.test(saveStore)
    || !/let phase: ChapterFourPhase = savedCompletionVerified[\s\S]*?: savedPhase === "complete" && savedClaimsCompletion[\s\S]*?\? "exterior_closure"[\s\S]*?: savedPhase/.test(saveStore)
    || !/const completed = savedCompletionVerified/.test(saveStore)
    || !/items\.campusCard = true/.test(saveStore)) {
    errors.push("Task 13 SaveStore must synchronize check-in booleans/facts/items, auto-close a complete morning pair and accept completion only from a coherent v32 closure");
  }
  if (!/contract\.id === "return_to_clock"[\s\S]*?floor === "A1"[\s\S]*?"install_final_minute"[\s\S]*?"return_via_main_stair"/.test(quest)
    || !/contract\.id === "morning_checkin"[\s\S]*?checkin_card_accepted[\s\S]*?checkin_paper_accepted[\s\S]*?"submit_attendance_paper"[\s\S]*?"read_campus_card"[\s\S]*?"complete_checkin"/.test(quest)) {
    errors.push("Task 13 QuestModel must expose one A2/A1 return objective and only the remaining check-in action");
  }

  if (/^\s*import\s/m.test(guardModel)
    || /Phaser|GameStore|document\.|window\.|HTMLElement/.test(guardModel)
    || /fail_chase|final_chase/.test(guardModel)) {
    errors.push("Task 10 ordinary patrol model must remain pure and independent from Phaser, stores, DOM and final chase");
  }
  if (!/"patrol"[\s\S]*?"confirming"[\s\S]*?"pursuit"[\s\S]*?"returning"/.test(guardModel)
    || !/confirmationMs:\s*400/.test(guardModel)
    || !/sightLossMs:\s*900/.test(guardModel)
    || !/coneRange:\s*220/.test(guardModel)
    || !/coneHalfAngleDegrees:\s*36/.test(guardModel)
    || !/closeRadius:\s*56/.test(guardModel)
    || !/patrolSpeed:\s*84/.test(guardModel)
    || !/pursuitSpeed:\s*140/.test(guardModel)
    || !/returnSpeed:\s*96/.test(guardModel)
    || !/maxStepMs:\s*50/.test(guardModel)
    || !/guardPosition:\s*ChapterFourGuardPoint/.test(guardModel)
    || !/desiredVelocity:\s*ChapterFourGuardPoint/.test(guardModel)
    || !/finitePointOr\(input\.guardPosition, source\.position\)/.test(guardModel)
    || !/hasChapterFourGuardLineOfSight/.test(guardModel)
    || !/chapterFourGuardFootContact/.test(guardModel)) {
    errors.push("Task 10 pure patrol model must encode the approved modes, timing, speeds, LOS and foot contact");
  }
}

function validate(content) {
  const errors = [];
  const timeStatePlateIdsById = new Map();
  if (!isRecord(content)) return ["content root must be an object"];
  if (content.schemaVersion !== 1) errors.push("schemaVersion must be 1");
  if (content.contractId !== "chapter4-755") errors.push("contractId must be chapter4-755");
  if (content.chapterId !== "chapter_four") errors.push("chapterId must be chapter_four");
  if (!sameArray(content.orderedPhases, EXPECTED_PHASES)) {
    errors.push("orderedPhases must exactly match the approved 13-phase 7:55 sequence");
  }

  const time = content.time;
  if (!isRecord(time)) {
    errors.push("time must be an object");
  } else {
    if (!sameArray(time.authorities, EXPECTED_AUTHORITIES)) {
      errors.push("time.authorities must be external_evidence then hall_clock");
    }
    if (!sameArray(time.stateOrder, EXPECTED_TIME_STATES.map(([id]) => id))) {
      errors.push("time.stateOrder does not match the approved time states");
    }
    if (!Array.isArray(time.states) || time.states.length !== EXPECTED_TIME_STATES.length) {
      errors.push("time.states must contain exactly six entries");
    } else {
      EXPECTED_TIME_STATES.forEach(([id, worldSeconds, phoneSeconds, trusted], index) => {
        const state = time.states[index];
        if (!isRecord(state)) {
          errors.push(`time.states[${index}] must be an object`);
          return;
        }
        if (state.id !== id) errors.push(`time.states[${index}].id must be ${id}`);
        if (state.worldTimeSeconds !== worldSeconds) {
          errors.push(`time state ${id} worldTimeSeconds must be ${worldSeconds}`);
        }
        if (state.phoneStatusTimeSeconds !== phoneSeconds) {
          errors.push(`time state ${id} phoneStatusTimeSeconds must be ${phoneSeconds}`);
        }
        if (state.phoneStatusTimeTrusted !== trusted) {
          errors.push(`time state ${id} phoneStatusTimeTrusted must be ${trusted}`);
        }
        if (!Array.isArray(state.plateIds)
          || state.plateIds.length === 0
          || state.plateIds.some((plateId) => !nonEmptyString(plateId))) {
          errors.push(`time state ${id} must define non-empty plateIds`);
        } else if (new Set(state.plateIds).size !== state.plateIds.length) {
          errors.push(`time state ${id} plateIds must not contain duplicates`);
        } else {
          timeStatePlateIdsById.set(id, new Set(state.plateIds));
        }
      });
    }
    const opening = time.opening;
    if (!isRecord(opening)
      || opening.authority !== "external_evidence"
      || opening.timeState !== "2245_opening"
      || opening.externalEvidenceSeconds !== 81900
      || opening.frozenPhoneStatusSeconds !== 28523
      || opening.phoneStatusTimeTrusted !== false) {
      errors.push("time.opening must preserve external 22:45 and frozen untrusted 07:55:23");
    }
    const firstPull = time.firstHallClockPull;
    if (!isRecord(firstPull)
      || firstPull.fromAuthority !== "external_evidence"
      || firstPull.toAuthority !== "hall_clock"
      || firstPull.fromTimeState !== "2245_opening"
      || firstPull.toTimeState !== "1225_bakery"
      || firstPull.trigger !== "pull_hall_clock"
      || firstPull.atomic !== true) {
      errors.push("time.firstHallClockPull must atomically switch authority and time state");
    }
    if (!Array.isArray(time.atomicTransitionFields)) {
      errors.push("time.atomicTransitionFields must be an array");
    } else {
      for (const field of REQUIRED_ATOMIC_FIELDS) {
        if (!time.atomicTransitionFields.includes(field)) {
          errors.push(`time.atomicTransitionFields is missing ${field}`);
        }
      }
    }
    const completion = time.completion;
    if (!isRecord(completion)
      || completion.authority !== "hall_clock"
      || completion.timeState !== "0755_morning"
      || completion.worldTimeSeconds !== 28500
      || completion.phoneStatusTimeSeconds !== 28500
      || completion.phoneStatusTimeTrusted !== true) {
      errors.push("time.completion must be hall_clock 28500/28500/trusted=true");
    }
  }

  const openingHandshake = content.openingHandshake;
  if (!isRecord(openingHandshake)
    || !sameArray(openingHandshake.intentOrder, EXPECTED_OPENING_INTENTS)) {
    errors.push("openingHandshake.intentOrder must preserve the seven controller-owned opening gates");
  } else {
    const paper = openingHandshake.paper;
    if (!isRecord(paper)
      || paper.frame !== "chapter4_story_items/sign_in_record_paper"
      || paper.startDistanceMeters !== 4
      || paper.noticeboardDistanceMeters !== 6
      || paper.settledFact !== "opening_paper_at_noticeboard"
      || paper.caughtFact !== "opening_paper_caught") {
      errors.push("openingHandshake.paper must settle the formal paper frame at the noticeboard before catch");
    }
    const rejection = openingHandshake.externalTimeRejection;
    if (!isRecord(rejection)
      || rejection.externalSeconds !== 81900
      || rejection.frozenPhoneSeconds !== 28523
      || rejection.phoneStatusTimeTrusted !== false
      || rejection.resolvedFact !== "external_time_rejected") {
      errors.push("openingHandshake.externalTimeRejection must reject 07:55:23 against external 22:45");
    }
    const inspection = openingHandshake.hallClockInspection;
    if (!isRecord(inspection)
      || inspection.requiredMode !== "light"
      || inspection.missingHandFrame !== "chapter4_clock_states/2245_missing_hour_hand"
      || inspection.gearFrame !== "chapter4_clock_states/gear_stuttering"
      || inspection.resolvedFact !== "hall_clock_inspected") {
      errors.push("openingHandshake.hallClockInspection must resolve the missing hand and stuttering gear in light mode");
    }
    if (!sameArray(openingHandshake.firstPullFrames, [
      "chapter4_clock_states/gear_stuttering",
      "chapter4_clock_states/1225_missing_hour_hand"
    ])) {
      errors.push("openingHandshake.firstPullFrames must use the committed 22:45-to-12:25 clock frames");
    }
  }

  const bakeryHandshake = content.bakeryHandshake;
  if (!isRecord(bakeryHandshake)) {
    errors.push("bakeryHandshake must define the Task 8 controller/presentation recovery contract");
  } else {
    if (!sameArray(bakeryHandshake.intentOrder, EXPECTED_BAKERY_INTENTS)) {
      errors.push("bakeryHandshake.intentOrder must preserve inspect, stop completion, pickup and install order");
    }
    if (bakeryHandshake.preLampConveyorCorrection !== "先点亮烤箱旁的检修灯，让传送带停一下。") {
      errors.push("bakeryHandshake must preserve the approved pre-lamp conveyor correction");
    }
    if (!isRecord(bakeryHandshake.targetIds)
      || !sameArray([
        bakeryHandshake.targetIds.lamp,
        bakeryHandshake.targetIds.conveyorEdge,
        bakeryHandshake.targetIds.hourHandPickup,
        bakeryHandshake.targetIds.hourHandSocket
      ], EXPECTED_BAKERY_TARGET_IDS)) {
      errors.push("bakeryHandshake.targetIds must bind the three runtime entities and visible clock socket");
    }
    if (!sameArray(bakeryHandshake.factOrder, EXPECTED_BAKERY_FACTS)) {
      errors.push("bakeryHandshake.factOrder must preserve the recoverable Task 8 causal chain");
    }
    const timeline = Array.isArray(bakeryHandshake.timeline) ? bakeryHandshake.timeline : [];
    if (!sameArray(timeline.map((beat) => beat?.atMs), EXPECTED_BAKERY_TIMELINE)
      || timeline[timeline.length - 1]?.event !== "complete_bakery_conveyor_stop") {
      errors.push("bakeryHandshake.timeline must commit the 0/120/360/520/700ms stop sequence");
    }
    const refreshMatrix = Array.isArray(bakeryHandshake.refreshMatrix)
      ? bakeryHandshake.refreshMatrix
      : [];
    if (!sameArray(refreshMatrix.map((row) => row?.id), EXPECTED_BAKERY_REFRESH_IDS)
      || refreshMatrix[0]?.conveyor !== "moving"
      || refreshMatrix[1]?.resume !== "replay"
      || refreshMatrix[2]?.pickup !== "visible"
      || refreshMatrix[3]?.pickup !== "hidden"
      || refreshMatrix[4]?.resume !== "1850_evening") {
      errors.push("bakeryHandshake.refreshMatrix must cover uninspected, replay, exposed, collected and installed restores");
    }
    if (!sameArray(bakeryHandshake.domainCues, EXPECTED_BAKERY_CUES)) {
      errors.push("bakeryHandshake.domainCues must contain only the three Task 8 bakery direction cues");
    }
  }

  const tasks = isRecord(content.tasks) ? content.tasks : null;
  if (!tasks) {
    errors.push("tasks must be an object");
  } else {
    const activeTaskEntries = Object.entries(tasks).filter(([taskKey]) => taskKey !== "chapter_complete");
    if (Object.keys(tasks).length !== 37 || activeTaskEntries.length !== 36) {
      errors.push("tasks must contain 36 active tasks plus chapter_complete");
    }
    for (const [taskKey, task] of Object.entries(tasks)) {
      if (!isRecord(task) || !nonEmptyString(task.label)) {
        errors.push(`tasks.${taskKey}.label must be a non-empty string`);
      }
      const expectedHintCount = taskKey === "chapter_complete" ? 0 : 3;
      if (isRecord(task)
        && (!Array.isArray(task.hints)
          || task.hints.length !== expectedHintCount
          || task.hints.some((hint) => !nonEmptyString(hint)))) {
        errors.push(`tasks.${taskKey}.hints must contain exactly ${expectedHintCount} non-empty hints`);
      }
    }
    const activeHintCount = activeTaskEntries.reduce(
      (count, [, task]) => count + (Array.isArray(task?.hints) ? task.hints.length : 0),
      0
    );
    if (activeHintCount !== 108) {
      errors.push("tasks must expose the full 108-hint active contract");
    }
    const room204PlayerCopy = [
      tasks.restore_room204?.label,
      ...(Array.isArray(tasks.restore_room204?.hints) ? tasks.restore_room204.hints : [])
    ].filter(nonEmptyString).join("\n");
    if (/(?:家具|桌椅).{0,8}(?:朝向|旋转|转向|朝上|朝下|向左|向右)|(?:朝向|旋转|转向).{0,8}(?:家具|桌椅)/.test(room204PlayerCopy)) {
      errors.push("tasks.restore_room204 must not expose player-facing direction or rotation requirements");
    }
    if (!isRecord(tasks.explore_bakery) || !/面包坊/.test(tasks.explore_bakery.label)) {
      errors.push("tasks.explore_bakery must direct the first-pull objective to the bakery");
    }
  }
  const dialogues = isRecord(content.dialogues) ? content.dialogues : null;
  if (!dialogues) {
    errors.push("dialogues must be an object");
  } else {
    for (const [dialogueId, lines] of Object.entries(dialogues)) {
      if (!Array.isArray(lines) || lines.length === 0) {
        errors.push(`dialogues.${dialogueId} must contain at least one line`);
        continue;
      }
      lines.forEach((line, index) => {
        if (!isRecord(line) || !nonEmptyString(line.speaker) || !nonEmptyString(line.text)) {
          errors.push(`dialogues.${dialogueId}[${index}] must define speaker and text`);
        }
      });
    }
    const firstInspection = Array.isArray(dialogues["hall_clock.first_inspection"])
      ? dialogues["hall_clock.first_inspection"].map((line) => line?.text ?? "").join("\n")
      : "";
    if (!/能被拨动/.test(firstInspection)
      || !/不会按你的动作走/.test(firstInspection)
      || /时针缺失|时针轴为空|缺少时针/.test(firstInspection)) {
      errors.push("hall_clock.first_inspection must reveal only that the clock moves incorrectly");
    }
  }

  if (!Array.isArray(content.phaseContracts) || content.phaseContracts.length !== EXPECTED_PHASES.length) {
    errors.push("phaseContracts must contain exactly one contract per ordered phase");
  } else {
    content.phaseContracts.forEach((phase, index) => {
      if (!isRecord(phase) || phase.id !== EXPECTED_PHASES[index]) {
        errors.push(`phaseContracts[${index}] must describe ${EXPECTED_PHASES[index]}`);
        return;
      }
      if (!EXPECTED_AUTHORITIES.includes(phase.timeAuthority)) {
        errors.push(`phase ${phase.id} has an invalid timeAuthority`);
      }
      if (!EXPECTED_TIME_STATES.some(([id]) => id === phase.timeState)) {
        errors.push(`phase ${phase.id} has an invalid timeState`);
      }
      const expectedTime = EXPECTED_PHASE_TIME[phase.id];
      if (!expectedTime
        || phase.timeAuthority !== expectedTime[0]
        || phase.timeState !== expectedTime[1]) {
        errors.push(`phase ${phase.id} must atomically use ${expectedTime?.[0]} / ${expectedTime?.[1]}`);
      }
      if (!EXPECTED_GUARD_MODES.includes(phase.guardMode)) {
        errors.push(`phase ${phase.id} has an invalid guardMode`);
      }
      const expectedGuard = EXPECTED_PHASE_GUARD[phase.id] ?? "absent";
      if (phase.guardMode !== expectedGuard) {
        errors.push(`phase ${phase.id} guardMode must be ${expectedGuard}`);
      }
      // A time state lists every visual plate available at that clock reading.
      // A phase renders one non-empty subset because several 07:54 phases use
      // different floors while sharing the same authoritative time state.
      if (!Array.isArray(phase.floorPlateIds)
        || phase.floorPlateIds.length === 0
        || phase.floorPlateIds.some((plateId) => !nonEmptyString(plateId))) {
        errors.push(`phase ${phase.id}.floorPlateIds must be a non-empty string array`);
      } else if (new Set(phase.floorPlateIds).size !== phase.floorPlateIds.length) {
        errors.push(`phase ${phase.id}.floorPlateIds must not contain duplicates`);
      } else {
        const availablePlateIds = timeStatePlateIdsById.get(phase.timeState);
        if (!availablePlateIds) {
          errors.push(`phase ${phase.id}.floorPlateIds cannot resolve time state ${phase.timeState}`);
        } else {
          for (const plateId of phase.floorPlateIds) {
            if (!availablePlateIds.has(plateId)) {
              errors.push(`phase ${phase.id}.floorPlateIds contains ${plateId}, which is outside ${phase.timeState}`);
            }
          }
        }
      }
      if (!Array.isArray(phase.taskKeys) || phase.taskKeys.length === 0) {
        errors.push(`phase ${phase.id} must reference at least one task key`);
      } else if (tasks) {
        for (const taskKey of phase.taskKeys) {
          if (!Object.prototype.hasOwnProperty.call(tasks, taskKey)) {
            errors.push(`phase ${phase.id} references missing task ${taskKey}`);
          }
        }
      }
      const expectedTaskKeys = EXPECTED_TASK_KEYS_BY_ACTIVE_PHASE[phase.id];
      if (expectedTaskKeys && !sameArray(phase.taskKeys, expectedTaskKeys)) {
        errors.push(`phase ${phase.id}.taskKeys must preserve the implemented Task 7-11 next-objective order`);
      }
      if (!Array.isArray(phase.dialogueIds)) {
        errors.push(`phase ${phase.id}.dialogueIds must be an array`);
      } else if (dialogues) {
        for (const dialogueId of phase.dialogueIds) {
          if (!Object.prototype.hasOwnProperty.call(dialogues, dialogueId)) {
            errors.push(`phase ${phase.id} references missing dialogue ${dialogueId}`);
          }
        }
      }
    });
  }

  const room204 = content.room204;
  if (!isRecord(room204)) {
    errors.push("room204 must be an object");
  } else {
    if (room204.referenceTargetId !== "a3_reference_classroom_layout") {
      errors.push("room204.referenceTargetId must point to the A3 reference classroom");
    }
    if (room204.residualGroupTargetId !== "a2_room204_residual_group") {
      errors.push("room204.residualGroupTargetId must point to the grouped A2 residual");
    }
    const pieceIds = Array.isArray(room204.pieceIds) ? room204.pieceIds : [];
    const slotIds = Array.isArray(room204.slotIds) ? room204.slotIds : [];
    if (pieceIds.length !== 12 || new Set(pieceIds).size !== 12) {
      errors.push("room204.pieceIds must contain 12 unique pieces");
    }
    if (slotIds.length !== 12 || new Set(slotIds).size !== 12) {
      errors.push("room204.slotIds must contain 12 unique slots");
    }
    if (room204.canonicalUse !== "save_recovery_only") {
      errors.push("room204.canonicalUse must restrict the canonical mapping to save recovery");
    }
    if (room204.gameplayRule !== "any_unique_piece_to_any_unique_empty_slot_orientation_up") {
      errors.push("room204.gameplayRule must accept any unique piece in any unique empty slot with orientation up");
    }
    if (!Array.isArray(room204.canonicalCompletePlacements)
      || room204.canonicalCompletePlacements.length !== 12) {
      errors.push("room204.canonicalCompletePlacements must contain 12 recovery placements");
    } else {
      const canonicalPieces = new Set();
      const canonicalSlots = new Set();
      room204.canonicalCompletePlacements.forEach((placement, index) => {
        if (!isRecord(placement)
          || !pieceIds.includes(placement.pieceId)
          || !slotIds.includes(placement.slotId)
          || placement.orientation !== "up") {
          errors.push(`room204.canonicalCompletePlacements[${index}] is invalid`);
          return;
        }
        canonicalPieces.add(placement.pieceId);
        canonicalSlots.add(placement.slotId);
      });
      if (canonicalPieces.size !== 12 || canonicalSlots.size !== 12) {
        errors.push("room204.canonicalCompletePlacements must use every piece and slot once");
      }
    }
  }

  const maintenance = content.maintenance;
  if (!isRecord(maintenance)
    || !sameArray(maintenance.orderedActions, [
      "inspect_cart_wheel",
      "complete_maintenance_diagnosis",
      "open_cart_wheel_cover",
      "lubricate_cart_wheel"
    ])
    || maintenance.inspectionFact !== "cart_wheel_inspected"
    || !sameArray(maintenance.preparedItems, ["shortPryBar", "universalLubricatingOil"])
    || maintenance.diagnosisAnswers?.wheel_sound !== "latch"
    || maintenance.diagnosisAnswers?.clock_jam !== "gear_offset"
    || maintenance.diagnosisAnswers?.oil_trace !== "oil_shortage"
    || maintenance.pryBarFinalUse !== "open_cart_wheel_cover"
    || !sameArray(
      Array.isArray(maintenance.oilUses)
        ? maintenance.oilUses.map((use) => `${use?.targetId}:${use?.inventoryEffect}:${use?.factIds?.join("+")}`)
        : [],
      [
        "a1_cleaning_cart_wheel:consume:cart_wheel_repaired+clock_gear_repaired"
      ]
    )
    || maintenance.gearRepairKeepsPhase !== "maintenance_repair"
    || maintenance.nextTask !== "把旧钟拨向 07:55") {
    errors.push("maintenance must preserve diagnosis, two physical actions and Task11 handoff");
  }
  if (!isRecord(content.tasks)
    || content.tasks.turn_clock_to_0755?.label !== "把旧钟拨向 07:55"
    || content.tasks.solve_light_grid?.label !== "让必要路线亮起"
    || content.tasks.reach_lecture_202?.label !== "前往 202"
    || content.tasks.collect_final_minute?.label !== "取回最后一分钟"
    || content.tasks.return_via_main_stair?.label !== "沿主楼梯回到一楼旧钟"
    || content.tasks.install_final_minute?.label !== "把最后一分钟装回旧钟") {
    errors.push("Task 11-12 quest copy must use the exact clock, necessary-route, 202, recovery, main-stair return and old-clock labels");
  }

  const patrol = isRecord(content.guard) && isRecord(content.guard.patrol)
    ? content.guard.patrol
    : null;
  if (!patrol
    || patrol.mode !== "patrol"
    || patrol.restartPolicy !== "maintenance_safe_checkpoint"
    || patrol.canDisengageAfterSightLoss !== true
    || patrol.preserveStoryItems !== true
    || !sameArray(patrol.states, ["patrol", "confirming", "pursuit", "returning"])
    || patrol.confirmationMs !== 400
    || patrol.sightLossMs !== 900
    || patrol.coneRange !== 220
    || patrol.coneHalfAngleDegrees !== 36
    || patrol.closeRadius !== 56
    || patrol.patrolSpeed !== 84
    || patrol.pursuitSpeed !== 140
    || patrol.returnSpeed !== 96
    || !sameArray(patrol.pauseRangeMs, [1000, 2000])
    || patrol.maxStepMs !== 50
    || patrol.captureIntent !== "recover_from_maintenance_patrol") {
    errors.push("guard.patrol must define the independent ordinary-patrol timing, geometry, speeds and recovery intent");
  }

  const lightGrid = content.lightGrid;
  if (!isRecord(lightGrid)) {
    errors.push("lightGrid must be an object");
  } else {
    const zones = Array.isArray(lightGrid.zones) ? lightGrid.zones : [];
    if (zones.length !== 5) errors.push("lightGrid.zones must contain exactly five zones");
    const zoneById = new Map();
    zones.forEach((zone, index) => {
      if (!isRecord(zone)) {
        errors.push(`lightGrid.zones[${index}] must be an object`);
        return;
      }
      if (zone.id !== EXPECTED_ZONE_IDS[index] || zone.label !== EXPECTED_ZONE_LABELS[index]) {
        errors.push(`lightGrid.zones[${index}] must be ${EXPECTED_ZONE_IDS[index]} / ${EXPECTED_ZONE_LABELS[index]}`);
      }
      if (zone.bit !== index) errors.push(`lightGrid zone ${zone.id} must use bit ${index}`);
      if (zoneById.has(zone.id)) errors.push(`lightGrid contains duplicate zone ${zone.id}`);
      zoneById.set(zone.id, zone);
    });
    const toggleMasks = [];
    for (const zoneId of EXPECTED_ZONE_IDS) {
      const zone = zoneById.get(zoneId);
      if (!zone) continue;
      if (!Array.isArray(zone.adjacentZoneIds)
        || zone.adjacentZoneIds.some((adjacentId) => !EXPECTED_ZONE_IDS.includes(adjacentId) || adjacentId === zoneId)) {
        errors.push(`lightGrid zone ${zoneId} has invalid adjacency`);
        continue;
      }
      let computedMask = 1 << zone.bit;
      for (const adjacentId of zone.adjacentZoneIds) {
        const adjacent = zoneById.get(adjacentId);
        if (!adjacent) {
          errors.push(`lightGrid zone ${zoneId} references missing adjacent zone ${adjacentId}`);
          continue;
        }
        if (!Array.isArray(adjacent.adjacentZoneIds) || !adjacent.adjacentZoneIds.includes(zoneId)) {
          errors.push(`lightGrid adjacency ${zoneId}<->${adjacentId} must be symmetric`);
        }
        computedMask |= 1 << adjacent.bit;
      }
      if (zone.toggleMask !== computedMask) {
        errors.push(`lightGrid zone ${zoneId} toggleMask must be ${computedMask}`);
      }
      toggleMasks.push(zone.toggleMask);
    }
    for (const [key, value] of [["initialMask", lightGrid.initialMask], ["targetMask", lightGrid.targetMask], ["allOnMask", lightGrid.allOnMask]]) {
      if (!Number.isInteger(value) || value < 0 || value > 31) {
        errors.push(`lightGrid.${key} must be an integer mask from 0 to 31`);
      }
    }
    if (lightGrid.initialMask !== 14) errors.push("lightGrid.initialMask must use the revised arrangement mask 14");
    if (lightGrid.allOnMask !== 31) errors.push("lightGrid.allOnMask must be 31");
    if (lightGrid.targetMask === lightGrid.allOnMask) {
      errors.push("lightGrid target must reject the all-on state");
    }
    const requiredOn = new Set(Array.isArray(lightGrid.requiredOnZoneIds) ? lightGrid.requiredOnZoneIds : []);
    const requiredOff = new Set(Array.isArray(lightGrid.requiredOffZoneIds) ? lightGrid.requiredOffZoneIds : []);
    if (!setEquals(requiredOn, new Set(["hall", "east_corridor", "classroom_zone"]))) {
      errors.push("lightGrid.requiredOnZoneIds must define the hall-to-classroom route");
    }
    if (!setEquals(requiredOff, new Set(["west_corridor", "bakery_back_area"]))) {
      errors.push("lightGrid.requiredOffZoneIds must keep off-route zones dark");
    }
    let requiredMask = 0;
    for (const zoneId of requiredOn) {
      const zone = zoneById.get(zoneId);
      if (zone) requiredMask |= 1 << zone.bit;
    }
    if (lightGrid.targetMask !== requiredMask) {
      errors.push(`lightGrid.targetMask must be ${requiredMask}`);
    }
    const reachable = toggleMasks.length === 5
      ? findReachableMask(lightGrid.initialMask, lightGrid.targetMask, toggleMasks)
      : null;
    if (!reachable) errors.push("lightGrid target is not reachable from initialMask");
    const verifiedSolution = Array.isArray(lightGrid.verifiedSolutionZoneIds)
      ? lightGrid.verifiedSolutionZoneIds
      : [];
    if (!sameArray(verifiedSolution, ["hall", "west_corridor", "east_corridor", "bakery_back_area"])) {
      errors.push("lightGrid.verifiedSolutionZoneIds must match the revised four-toggle solution");
    }
    let replayMask = lightGrid.initialMask;
    for (const zoneId of verifiedSolution) {
      const zone = zoneById.get(zoneId);
      if (!zone) {
        errors.push(`lightGrid verified solution references unknown zone ${zoneId}`);
        continue;
      }
      replayMask ^= zone.toggleMask;
    }
    if (replayMask !== lightGrid.targetMask) {
      errors.push("lightGrid.verifiedSolutionZoneIds does not reach targetMask");
    }
    if (lightGrid.successLocks !== true) errors.push("lightGrid success must lock later toggles");
  }

  const guard = content.guard;
  if (!isRecord(guard)) {
    errors.push("guard must be an object");
  } else {
    if (!sameArray(guard.modes, EXPECTED_GUARD_MODES)) {
      errors.push("guard.modes must be absent, patrol, chase");
    }
    if (!isRecord(guard.patrol)
      || guard.patrol.mode !== "patrol"
      || guard.patrol.canDisengageAfterSightLoss !== true
      || guard.patrol.preserveStoryItems !== true) {
      errors.push("guard.patrol must preserve story items and allow sight-loss disengagement");
    }
    if (!isRecord(guard.finalChase)
      || guard.finalChase.mode !== "chase"
      || guard.finalChase.runtimeModel !== "ChapterFourFinalChaseModel"
      || !sameArray(guard.finalChase.states, [
        "arming", "running", "portal_transfer", "finish_pending", "failure_pending", "complete"
      ])
      || guard.finalChase.armingCommittedFrames !== 4
      || guard.finalChase.playerSpeed !== 208
      || guard.finalChase.guardSpeed !== 196
      || guard.finalChase.maxStepMs !== 50
      || guard.finalChase.transportId !== "main_stair"
      || guard.finalChase.finishPriority !== "finish_before_contact_same_frame"
      || guard.finalChase.attemptToken !== "expectedAttempt"
      || guard.finalChase.restartPolicy !== "chase_only"
      || guard.finalChase.restartCheckpoint !== "c4_a1_lobby"
      || guard.finalChase.canDisengageAfterSightLoss !== false) {
      errors.push("guard.finalChase must bind the pure six-state Task12 model, exact timing/speeds, main-stair portal, finish priority and attempt-checked chase-only restart");
    }
  }

  const itemSequence = Array.isArray(content.itemSequence) ? content.itemSequence : [];
  if (itemSequence.length !== EXPECTED_ITEM_STEPS.length) {
    errors.push(`itemSequence must contain ${EXPECTED_ITEM_STEPS.length} ordered operations`);
  }
  EXPECTED_ITEM_STEPS.forEach(([id, itemId, targetId, inventoryEffect], index) => {
    const step = itemSequence[index];
    if (!isRecord(step)
      || step.id !== id
      || step.itemId !== itemId
      || step.targetId !== targetId
      || step.inventoryEffect !== inventoryEffect) {
      errors.push(`itemSequence[${index}] must be ${id}/${itemId}/${targetId}/${inventoryEffect}`);
    }
    if (isRecord(step) && !EXPECTED_PHASES.includes(step.phase)) {
      errors.push(`itemSequence step ${step.id} has an invalid phase`);
    }
  });
  const positioningGrant = itemSequence.find((step) => step?.id === "collect_positioning_plate");
  if (!isRecord(positioningGrant)
    || !sameArray(positioningGrant.requiresFacts, [
      "a3_reference_observed",
      "room204_residual_observed",
      "room204_restored",
      "room204_projection_completed"
    ])) {
    errors.push("positioning plate must require the A3 reference, A2 residual, restored furniture, and completed projection");
  }
  const paperCatch = itemSequence.find((step) => step?.id === "catch_attendance_paper");
  if (!isRecord(paperCatch)
    || !sameArray(paperCatch.requiresFacts, ["opening_paper_at_noticeboard"])) {
    errors.push("attendance paper catch must require the settled noticeboard fact");
  }
  const oilSteps = itemSequence.filter((step) => step?.itemId === "universalLubricatingOil");
  if (oilSteps.length !== 1
    || oilSteps[0]?.targetId !== "a1_cleaning_cart_wheel"
    || oilSteps[0]?.inventoryEffect !== "consume"
    || !sameArray(oilSteps[0]?.stateResults, ["cart_wheel_repaired", "clock_gear_repaired"])) {
    errors.push("diagnosed lubricating oil must be consumed by the linked cart-wheel and clock-gear repair");
  }
  const campusCardSteps = itemSequence.filter((step) => step?.itemId === "campusCard");
  if (campusCardSteps.length !== 1
    || campusCardSteps[0]?.targetId !== "a1_campus_card_reader"
    || campusCardSteps[0]?.inventoryEffect !== "retain") {
    errors.push("campusCard must be retained when read by the check-in card reader");
  }
  if (itemSequence.some((step) => step?.itemId === "campusCard" && step?.inventoryEffect === "consume")) {
    errors.push("campusCard must never be consumed");
  }

  const checkin = content.checkin;
  if (!isRecord(checkin) || !Array.isArray(checkin.acceptedTargets) || checkin.acceptedTargets.length !== 2) {
    errors.push("checkin.acceptedTargets must contain exactly the card reader and paper slot");
  } else {
    const [cardTarget, paperTarget] = checkin.acceptedTargets;
    if (!isRecord(cardTarget)
      || cardTarget.targetId !== "a1_campus_card_reader"
      || cardTarget.itemId !== "campusCard"
      || cardTarget.inventoryEffect !== "retain") {
      errors.push("check-in card reader must retain campusCard");
    }
    if (!isRecord(paperTarget)
      || paperTarget.targetId !== "a1_attendance_paper_slot"
      || paperTarget.itemId !== "attendanceRecordPaper"
      || paperTarget.inventoryEffect !== "retain") {
      errors.push("check-in paper slot must retain the signed attendanceRecordPaper");
    }
    if (checkin.orderIndependent !== true || checkin.completionRequiresBoth !== true) {
      errors.push("check-in parts must be order-independent and both required");
    }
  }

  const completion = content.completionInvariants;
  const requiredCompletionFacts = new Set([
    "final_minute_installed",
    "checkin_card_accepted",
    "checkin_paper_accepted",
    "exterior_closure_acknowledged"
  ]);
  const completionFacts = new Set(
    isRecord(completion) && Array.isArray(completion.requiredFactIds)
      ? completion.requiredFactIds
      : []
  );
  if (!isRecord(completion)
    || completion.phase !== "complete"
    || completion.completed !== true
    || completion.timeAuthority !== "hall_clock"
    || completion.timeState !== "0755_morning"
    || completion.worldTimeSeconds !== 28500
    || completion.phoneStatusTimeSeconds !== 28500
    || completion.phoneStatusTimeTrusted !== true
    || completion.guardMode !== "absent"
    || completion.lightGridLocked !== true
    || completion.chapterThreeInterludeCompleted !== true
    || completion.campusCardInventoryEffect !== "retain"
    || completion.attendanceRecordPaperInventoryEffect !== "retain"
    || ![...requiredCompletionFacts].every((factId) => completionFacts.has(factId))) {
    errors.push("completionInvariants must preserve the complete 07:55 trusted check-in contract");
  }

  scanForbiddenTerminal(content, errors);
  return errors;
}

let contentPath;
try {
  contentPath = parseContentPath(process.argv.slice(2));
} catch (error) {
  console.error(`Chapter 4 7:55 story validation failed: ${error instanceof Error ? error.message : String(error)}`);
  process.exit(1);
}

let content;
try {
  content = JSON.parse(fs.readFileSync(contentPath, "utf8"));
} catch (error) {
  console.error(`Chapter 4 7:55 story validation failed: cannot read ${contentPath}: ${error instanceof Error ? error.message : String(error)}`);
  process.exit(1);
}

const errors = validate(content);
validateTask7H3Asset(errors);
validateTask7RuntimeSources(errors);
if (errors.length > 0) {
  console.error(`Chapter 4 7:55 story validation failed (${errors.length} error${errors.length === 1 ? "" : "s"}):`);
  errors.forEach((error) => console.error(`- ${error}`));
  process.exit(1);
}

console.log(`Chapter 4 7:55 story contract valid: ${EXPECTED_PHASES.length} phases, ${EXPECTED_TIME_STATES.length} time states, 5 light zones, ${EXPECTED_ITEM_STEPS.length} item operations, Task 7/8/9/10/11/12/13 runtime gates verified; exterior completion blocked without official reference.`);
