import { readFile, writeFile } from "node:fs/promises";
import { dirname, resolve } from "node:path";
import { fileURLToPath } from "node:url";
import {
  APPROVED_CHAPTER4_755_BASE_PLATES,
  APPROVED_CHAPTER4_755_SPRITESHEETS,
  APPROVED_CHAPTER4_755_STATE_PLATES,
  CHAPTER4_755_ASSET_ROOT,
  alphaBounds,
  decodePng,
  readPngHeader,
  sha256
} from "./normalize-chapter4-755-assets.mjs";

const repoRoot = resolve(dirname(fileURLToPath(import.meta.url)), "..");
const assetRoot = resolve(repoRoot, "src/assets/rpg/interiors/finale");
const expectedPlateSize = { width: 1672, height: 941 };
const logicalViewport = { width: 960, height: 540 };
const layoutPath = resolve(repoRoot, "src/data/chapter4-three-floor-maze.layout.json");
const layout = JSON.parse(await readFile(layoutPath, "utf8"));

if (layout.schemaVersion !== 2) throw new Error("Chapter 4 layout must use schemaVersion 2.");

const legacySceneDefinitions = [
  ["finale_arrival_arcade", "启真湖至教学楼拱廊", "finale_arrival_arcade.png", "pseudo_2_5d_side", null,
    "只用于启真湖追逐结束后的低机位纸条追踪序幕。",
    ["wet_paper", "student", "rain_drops", "glass_door_pressure"]],
  ["finale_1f_lobby_maxwell", "一楼门厅与迈斯威", "finale_1f_lobby_maxwell.png", "top_down_orthographic", "cell_floor1_maxwell",
    "承担旧版入楼、气流轨迹教学、纸张干燥与整楼复位演出。",
    ["glass_doors", "maxwell_shutter", "warm_air", "wet_floor", "paper_trail"]],
  ["finale_stairwell", "楼梯间", "finale_stairwell.png", "top_down_orthographic", null,
    "历史楼梯间环境参考。", ["floor_doors", "guard_audio_zone"]],
  ["finale_vertical_core", "电梯竖向交通核", "finale_vertical_core.png", "top_down_orthographic", "cell_vertical_core",
    "历史电梯交通核环境参考。", ["elevator_doors", "elevator_car", "service_panel", "floor_indicator"]],
  ["finale_2f_activity", "二楼开放自习与活动区", "finale_2f_activity.png", "top_down_orthographic", "cell_floor2_activity",
    "历史二楼活动区环境参考。", ["activity_equipment", "attendance_board", "paper", "door_labels", "study_lights"]],
  ["finale_final_classroom", "N3-214 智慧教室", "finale_final_classroom.png", "top_down_orthographic", "cell_final_classroom",
    "历史终局教室环境参考。", ["morning_light", "smart_screens", "wall_clock", "scanner", "attendance_board"]],
  ["teaching_building_floor_1", "教学楼 1F · 麦思威与校友廊", "teaching_building_floor_1.png", "top_down_orthographic", "cell_teaching_floor_1",
    "三层正式母图之前的历史教学楼一层图。", ["player", "elevator_selection", "story_hotspots"]],
  ["teaching_building_floor_2", "教学楼 2F · 教室与开放学习区", "teaching_building_floor_2.png", "top_down_orthographic", "cell_teaching_floor_2",
    "三层正式母图之前的历史教学楼二层图。", ["player", "elevator_selection", "story_hotspots"]],
  ["teaching_building_floor_3", "教学楼 3F · 校友荣誉门厅", "teaching_building_floor_3.png", "top_down_orthographic", "cell_teaching_floor_3",
    "三层正式母图之前的历史教学楼三层图。", ["player", "elevator_selection", "story_hotspots"]]
];

const scenes = [];
for (const [id, title, file, projection, temporalCellId, purpose, dynamicLayers] of legacySceneDefinitions) {
  const bytes = await readFile(resolve(assetRoot, file));
  const decoded = readPngHeader(bytes, file);
  assertPlateSize(decoded, file);
  scenes.push({
    id,
    title,
    file,
    projection,
    temporalCellId,
    purpose,
    dynamicLayers,
    sourceSize: expectedPlateSize,
    logicalViewport,
    baseLayerOnly: true,
    sourceFile: `src/assets/rpg/interiors/finale/${file}`,
    sha256: sha256(bytes),
    compatibilityStatus: "legacy_reference"
  });
}

const basePlates = [];
for (const approved of APPROVED_CHAPTER4_755_BASE_PLATES) {
  const bytes = await readFile(resolve(CHAPTER4_755_ASSET_ROOT, approved.destination));
  const decoded = decodePng(bytes, approved.destination);
  assertPlate(decoded, approved.destination);
  const floor = layout.floors.find((candidate) => candidate.storyFloor === approved.floor);
  if (!floor) throw new Error(`Layout floor ${approved.floor} is missing.`);
  basePlates.push({
    id: approved.id,
    floor: approved.floor,
    title: `第四章 7:55 ${approved.floor} 结构母图`,
    file: `chapter4-755/${approved.destination}`,
    sourceFile: `src/assets/rpg/interiors/finale/chapter4-755/${approved.destination}`,
    sourceId: approved.sourceId,
    sourceSha256: approved.sourceSha256,
    sha256: sha256(bytes),
    sourceSize: expectedPlateSize,
    alphaRole: "opaque_base_plate",
    projection: "top_down_orthographic",
    browserConsumer: "ChapterFourTemporalMazeScene",
    calibrationStatus: "approved_user_geometry",
    layoutFloorEntryId: floor.elevator.id,
    collisionProfileId: `${approved.floor.toLowerCase()}_static_v1`
  });
}

const statePhysicalDeltas = {
  a1_2245_opening: [],
  a1_1225_bakery: ["a1_midday_queue_rails"],
  a2_1850_evening: ["a2_room204_disordered_furniture"],
  a3_1850_reference: ["a3_reference_classroom_furniture"],
  a1_2245_maintenance: [],
  a1_0754_blackout: [],
  a2_0754_chase: [],
  a2_202_final_minute: [],
  a1_0755_morning: []
};

const statePlates = [];
for (const approved of APPROVED_CHAPTER4_755_STATE_PLATES) {
  const bytes = await readFile(resolve(CHAPTER4_755_ASSET_ROOT, approved.destination));
  const decoded = decodePng(bytes, approved.destination);
  assertPlate(decoded, approved.destination);
  const floor = layout.floors.find((candidate) => candidate.storyFloor === approved.floor);
  const base = basePlates.find((candidate) => candidate.floor === approved.floor);
  if (!floor || !base) throw new Error(`Missing floor/base contract for ${approved.id}.`);
  statePlates.push({
    id: approved.id,
    floor: approved.floor,
    storyTime: approved.storyTime,
    file: `chapter4-755/${approved.destination}`,
    sourceFile: `src/assets/rpg/interiors/finale/chapter4-755/${approved.destination}`,
    sourceId: approved.sourceId,
    sourceSha256: approved.sourceSha256,
    sha256: sha256(bytes),
    sourceSize: expectedPlateSize,
    sourceCanvas: { width: approved.sourceWidth, height: 941 },
    alphaRole: "opaque_state_plate",
    renderMode: "opaque_full_plate",
    geometryAuthority: base.id,
    collisionProfileId: `${approved.floor.toLowerCase()}_static_v1`,
    physicalDeltaIds: statePhysicalDeltas[approved.id],
    browserConsumer: "ChapterFourTemporalMazeScene",
    calibrationStatus: "approved_floor_geometry_contract",
    normalization: approved.normalization === "byte_copy"
      ? { kind: "byte_copy", copiedColumnX: null }
      : { kind: "append_last_source_column", copiedColumnX: 1670, appendedColumnX: 1671 },
    registrationAnchors: registrationAnchors(floor)
  });
}

const spritesheets = await Promise.all(
  APPROVED_CHAPTER4_755_SPRITESHEETS.map(buildChapter4Sheet)
);
const compatibilityAssets = [await buildLegacyElevatorSheet()];

const manifest = {
  schemaVersion: 3,
  generatedAt: "source-derived",
  runtimeAuthority: "phaser",
  progressionAuthority: "typescript",
  sourceProjectionRule: "interiors_top_down_arrival_only_pseudo_2_5d",
  layoutContract: {
    id: "chapter4_three_floor_maze_layout",
    schemaVersion: layout.schemaVersion,
    sourceFile: "src/data/chapter4-three-floor-maze.layout.json",
    coordinateSystem: layout.coordinateSystem,
    worldSize: layout.worldSize,
    browserConsumer: "ChapterFourTemporalMazeScene",
    calibrationStatus: "approved_for_integration"
  },
  basePlates,
  statePlates,
  spritesheets,
  compatibilityAssets,
  scenes,
  exclusions: {
    generatedStarMaterial: false,
    generatedExteriorClosure: false
  }
};

await writeFile(
  resolve(assetRoot, "finale_environment_manifest.json"),
  `${JSON.stringify(manifest, null, 2)}\n`
);

console.log(
  `built finale environment manifest schema=3 bases=${basePlates.length} states=${statePlates.length} activeChapter4Sheets=${spritesheets.length} compatibilityAssets=${compatibilityAssets.length} legacyScenes=${legacySceneDefinitions.length}`
);

async function buildLegacyElevatorSheet() {
  const file = "teaching_building_elevator_doors.png";
  const bytes = await readFile(resolve(assetRoot, file));
  const decoded = readPngHeader(bytes, file);
  if (decoded.width !== 432 || decoded.height !== 96) {
    throw new Error(`${file} must remain 432x96.`);
  }
  return {
    id: "teaching_building_elevator_doors",
    title: "教学楼单电梯门六档动画",
    file,
    sourceFile: `src/assets/rpg/interiors/finale/${file}`,
    sourceId: "teaching_building_elevator_doors_runtime",
    sourceSize: { width: decoded.width, height: decoded.height },
    alphaRole: decoded.colorType === 6 ? "transparent_sprite_sheet" : "opaque_sprite_sheet",
    sha256: sha256(bytes),
    calibrationStatus: "legacy_runtime_compatible",
    registryStatus: "compatibility_only",
    consumerRegistration: "excluded_from_schema3_active_registry",
    activeChapter4Contract: false,
    frameSize: { width: 72, height: 96 },
    frameCount: 6,
    frames: Array.from({ length: 6 }, (_, index) => ({
      id: `door_${index}`,
      sourceCell: { x: index * 72, y: 0, width: 72, height: 96 },
      sourceRect: { x: index * 72, y: 0, width: 72, height: 96 },
      sourceTrim: { x: index * 72, y: 0, width: 72, height: 96 },
      measuredAlphaBounds: null,
      pivot: { x: index * 72 + 36, y: 96, coordinateSpace: "source_sheet", role: "bottom_center" },
      collisionType: "none",
      collisionBounds: [],
      interactionType: "none",
      interactionBounds: [],
      approximate: false
    }))
  };
}

async function buildChapter4Sheet(approved) {
  const bytes = await readFile(resolve(CHAPTER4_755_ASSET_ROOT, approved.destination));
  const decoded = decodePng(bytes, approved.destination);
  if (decoded.width !== approved.width || decoded.height !== approved.height || decoded.channels !== 4) {
    throw new Error(`${approved.id} must be ${approved.width}x${approved.height} RGBA.`);
  }
  const definitions = sheetFrameDefinitions(approved.id);
  const frames = definitions.map((definition) => buildFrame(decoded, definition, approved.id));
  return {
    id: approved.id,
    title: sheetTitle(approved.id),
    file: `chapter4-755/${approved.destination}`,
    sourceFile: `src/assets/rpg/interiors/finale/chapter4-755/${approved.destination}`,
    sourceId: approved.sourceId,
    sourceSha256: approved.sourceSha256,
    sha256: sha256(bytes),
    sourceSize: { width: decoded.width, height: decoded.height },
    alphaRole: "transparent_sprite_sheet",
    alphaTrimThreshold: 0.05,
    browserConsumer: "ChapterFourTemporalMazeScene",
    calibrationStatus: "explicit_source_trim_contract",
    activeChapter4Contract: true,
    frames,
    ...(approved.id === "chapter4_room204_residual" ? {
      groupInteractionBounds: [{
        id: "a2_room204_residual_group",
        floor: "A2",
        coordinateSpace: "world",
        bounds: { x: 44, y: 556, width: 372, height: 246 },
        requiredMode: "dark",
        observesAllFrameIds: frames.map((frame) => frame.id)
      }]
    } : {}),
    ...(approved.id === "chapter4_room204_furniture" ? {
      roomWorldContract: {
        floor: "A2",
        roomBounds: { x: 32, y: 544, width: 396, height: 270 },
        doorAndCentralAisleMustRemainConnected: true,
        transform: "uniform_scale_only"
      }
    } : {})
  };
}

function buildFrame(decoded, definition, sheetId) {
  const measuredAlphaBounds = alphaBounds(decoded, definition.sourceRect, 13);
  if (definition.id === "empty") {
    if (measuredAlphaBounds !== null) throw new Error(`${sheetId}.empty must remain alpha-empty.`);
  } else if (!measuredAlphaBounds) {
    throw new Error(`${sheetId}.${definition.id} has no alpha >= 5% inside its source rect.`);
  }
  const interactionBounds = definition.interactionBounds === "alpha_trim_plus_10"
    ? [{
        id: `${definition.id}_source_trigger`,
        coordinateSpace: "source_sheet",
        bounds: expandRect(measuredAlphaBounds, 10, decoded.width, decoded.height)
      }]
    : (definition.interactionBounds ?? []);
  return {
    id: definition.id,
    sourceCell: definition.sourceCell ?? null,
    sourceRect: definition.sourceRect,
    sourceTrim: measuredAlphaBounds,
    measuredAlphaBounds,
    pivot: definition.pivot ?? null,
    collisionType: definition.collisionType,
    collisionBounds: definition.collisionBounds ?? [],
    interactionType: definition.interactionType,
    interactionBounds,
    depthBand: definition.depthBand,
    ySort: definition.ySort,
    nonCollidingVisualEffects: true,
    approximate: definition.approximate,
    ...(definition.worldTarget ? { worldTarget: definition.worldTarget } : {})
  };
}

function sheetFrameDefinitions(id) {
  if (id === "chapter4_clock_states") return clockDefinitions();
  if (id === "chapter4_power_panel_states") return powerDefinitions();
  if (id === "chapter4_story_items") return storyItemDefinitions();
  if (id === "chapter4_room204_furniture") return furnitureDefinitions();
  if (id === "chapter4_room204_residual") return residualDefinitions();
  throw new Error(`No frame contract exists for ${id}.`);
}

function clockDefinitions() {
  const names = [
    "blank_face", "2245_missing_hour_hand", "1225_missing_hour_hand",
    "1850_hour_hand_restored", "2245_complete", "0754_calibrated",
    "0755_complete", "gear_stuttering", "gear_running"
  ];
  const columnEdges = [0, 408, 816, 1225];
  const rowEdges = [0, 428, 856, 1284];
  const pivots = [
    [188, 201], [612, 201], [1021, 201],
    [188, 596], [612, 596], [1021, 596],
    [188, 1012], [612, 1012], [1021, 1012]
  ];
  return names.map((id, index) => {
    const row = Math.floor(index / 3);
    const column = index % 3;
    const sourceRect = rectFromEdges(columnEdges, rowEdges, column, row);
    return {
      id,
      sourceCell: sourceRect,
      sourceRect,
      pivot: point(pivots[index], "clock_axis"),
      collisionType: "none",
      collisionBounds: [],
      interactionType: "wall_fixture_trigger",
      interactionBounds: [worldBounds("A1", 940, 30, 122, 120)],
      depthBand: "wall_fixture",
      ySort: false,
      approximate: true
    };
  });
}

function powerDefinitions() {
  const names = ["closed", "open_powered", "open_partial", "open_restored"];
  const columnEdges = [0, 656, 1312];
  const rowEdges = [0, 600, 1199];
  const pivots = [[592, 51], [1218, 52], [588, 637], [1216, 637]];
  return names.map((id, index) => {
    const row = Math.floor(index / 2);
    const column = index % 2;
    const sourceRect = rectFromEdges(columnEdges, rowEdges, column, row);
    return {
      id,
      sourceCell: sourceRect,
      sourceRect,
      pivot: point(pivots[index], "main_box_mount_socket"),
      collisionType: "none",
      collisionBounds: [],
      interactionType: "wall_panel_trigger",
      interactionBounds: [worldBounds("A1", 493, 528, 67, 124)],
      depthBand: "wall_fixture",
      ySort: false,
      approximate: true
    };
  });
}

function storyItemDefinitions() {
  const names = [
    "sign_in_record_paper", "old_clock_hour_hand", "clock_positioning_plate", "short_pry_tool_candidate",
    "lubricating_oil", "final_minute_shard", "electronic_campus_card", "empty"
  ];
  const columnEdges = [0, 384, 768, 1152, 1536];
  const rowEdges = [0, 512, 1024];
  const pivots = [
    [198, 432, "bottom_center"], [460, 415, "assembly_hole"], [963, 292, "plate_center"], [1327, 292, "object_center"],
    [199, 896, "bottle_bottom"], [566, 900, "bottom_center"], [943, 733, "object_center"], null
  ];
  return names.map((id, index) => {
    const row = Math.floor(index / 4);
    const column = index % 4;
    const sourceRect = rectFromEdges(columnEdges, rowEdges, column, row);
    return {
      id,
      sourceCell: sourceRect,
      sourceRect,
      pivot: pivots[index] ? point(pivots[index], pivots[index][2]) : null,
      collisionType: "none",
      collisionBounds: [],
      interactionType: id === "empty" ? "none" : "pickup_or_drop_trigger",
      interactionBounds: id === "empty" ? [] : "alpha_trim_plus_10",
      depthBand: id === "empty" ? "none" : "world_item",
      ySort: id !== "empty",
      approximate: id !== "empty"
    };
  });
}

function furnitureDefinitions() {
  const rows = [
    ["desk_r1c1", [52, 44, 182, 153], [60, 130, 166, 63], [143, 195]],
    ["desk_r1c2", [290, 44, 183, 153], [298, 130, 167, 63], [381, 195]],
    ["desk_r1c3", [528, 44, 182, 153], [536, 130, 166, 63], [619, 195]],
    ["desk_r1c4", [767, 44, 181, 153], [775, 130, 165, 63], [857, 195]],
    ["desk_r2c1", [52, 242, 182, 156], [60, 329, 166, 65], [143, 396]],
    ["desk_r2c2", [290, 242, 183, 156], [298, 329, 167, 65], [381, 396]],
    ["desk_r2c3", [528, 242, 182, 156], [536, 329, 166, 65], [619, 396]],
    ["desk_r2c4", [767, 242, 181, 156], [775, 329, 165, 65], [857, 396]],
    ["desk_r3c1", [52, 443, 182, 154], [60, 529, 166, 64], [143, 595]],
    ["desk_r3c2", [290, 443, 183, 154], [298, 529, 167, 64], [381, 595]],
    ["desk_r3c3", [528, 443, 182, 154], [536, 529, 166, 64], [619, 595]],
    ["desk_r3c4", [767, 443, 181, 154], [775, 529, 165, 64], [857, 595]],
    ["group_table_1", [1056, 34, 439, 178], [1068, 137, 415, 71], [1275, 210]],
    ["group_table_2", [1056, 230, 439, 178], [1068, 333, 415, 71], [1275, 406]],
    ["group_table_3", [1056, 428, 439, 176], [1068, 530, 415, 70], [1275, 602]],
    ["group_table_4", [1056, 624, 439, 175], [1068, 726, 415, 69], [1275, 797]],
    ["chair_r1c1", [61, 633, 124, 151], [69, 708, 108, 72], [123, 782]],
    ["chair_r1c2", [225, 633, 124, 151], [233, 708, 108, 72], [287, 782]],
    ["chair_r1c3", [387, 633, 125, 151], [395, 708, 109, 72], [449, 782]],
    ["chair_r1c4", [552, 633, 124, 151], [560, 708, 108, 72], [614, 782]],
    ["chair_r1c5", [716, 633, 124, 151], [724, 708, 108, 72], [778, 782]],
    ["chair_r1c6", [879, 633, 125, 151], [887, 708, 109, 72], [941, 782]],
    ["chair_r2c1", [61, 815, 124, 152], [69, 891, 108, 72], [123, 965]],
    ["chair_r2c2", [225, 815, 124, 152], [233, 891, 108, 72], [287, 965]],
    ["chair_r2c3", [387, 815, 125, 152], [395, 891, 109, 72], [449, 965]],
    ["chair_r2c4", [552, 815, 124, 152], [560, 891, 108, 72], [614, 965]],
    ["chair_r2c5", [716, 815, 124, 152], [724, 891, 108, 72], [778, 965]],
    ["chair_r2c6", [879, 815, 125, 152], [887, 891, 109, 72], [941, 965]],
    ["podium", [1193, 808, 175, 178], [1205, 893, 151, 89], [1280, 984]]
  ];
  return rows.map(([id, source, collision, pivotValue]) => ({
    id,
    sourceCell: null,
    sourceRect: rect(source),
    pivot: point(pivotValue, "bottom_center"),
    collisionType: "foot_box",
    collisionBounds: [{
      id: `${id}_foot_collision`,
      coordinateSpace: "source_sheet",
      bounds: rect(collision)
    }],
    interactionType: "move_or_place_trigger",
    interactionBounds: [{
      id: `${id}_placement_trigger`,
      coordinateSpace: "source_sheet",
      bounds: expandRect(rect(source), 8, 1536, 1024)
    }],
    depthBand: "world_furniture",
    ySort: true,
    approximate: true
  }));
}

function residualDefinitions() {
  const rows = [
    ["residual_r1c1", [203, 176, 192, 199], [299, 375], [94, 633]],
    ["residual_r1c2", [469, 176, 194, 199], [566, 375], [171, 633]],
    ["residual_r1c3", [875, 176, 193, 200], [972, 376], [289, 633]],
    ["residual_r1c4", [1143, 176, 192, 199], [1239, 375], [366, 633]],
    ["residual_r2c1", [203, 403, 191, 201], [299, 604], [94, 710]],
    ["residual_r2c2", [470, 403, 193, 202], [567, 605], [171, 710]],
    ["residual_r2c3", [875, 403, 193, 201], [972, 604], [289, 710]],
    ["residual_r2c4", [1143, 403, 192, 201], [1239, 604], [366, 710]],
    ["residual_r3c1", [203, 634, 193, 200], [300, 834], [94, 781]],
    ["residual_r3c2", [470, 634, 193, 200], [567, 834], [171, 781]],
    ["residual_r3c3", [875, 634, 194, 200], [972, 834], [289, 781]],
    ["residual_r3c4", [1143, 634, 192, 200], [1239, 834], [366, 781]]
  ];
  return rows.map(([id, source, pivotValue, worldTarget]) => ({
    id,
    sourceCell: null,
    sourceRect: rect(source),
    pivot: point(pivotValue, "bottom_center"),
    collisionType: "none",
    collisionBounds: [],
    interactionType: "shared_dark_observation_group",
    interactionBounds: [{
      id: "a2_room204_residual_group",
      floor: "A2",
      coordinateSpace: "world",
      bounds: { x: 44, y: 556, width: 372, height: 246 }
    }],
    worldTarget: { x: worldTarget[0], y: worldTarget[1], coordinateSpace: "world", floor: "A2" },
    depthBand: "floor_decal",
    ySort: false,
    approximate: true
  }));
}

function registrationAnchors(floor) {
  const stair = floor.stairLandings[0];
  const firstWalkable = floor.walkableRegions[0];
  const secondWalkable = floor.walkableRegions[1];
  return [
    { id: "elevator_center", x: floor.elevator.doorCenter.x, y: floor.elevator.doorCenter.y },
    { id: "stair_northwest", x: stair.bounds.x, y: stair.bounds.y },
    { id: "safe_spawn", x: floor.safeSpawn.x, y: floor.safeSpawn.y },
    { id: `${firstWalkable.id}_center`, x: firstWalkable.x + firstWalkable.width / 2, y: firstWalkable.y + firstWalkable.height / 2 },
    { id: `${secondWalkable.id}_center`, x: secondWalkable.x + secondWalkable.width / 2, y: secondWalkable.y + secondWalkable.height / 2 }
  ];
}

function sheetTitle(id) {
  return {
    chapter4_clock_states: "第四章大厅旧钟状态",
    chapter4_power_panel_states: "第四章配电面板状态",
    chapter4_story_items: "第四章 7:55 剧情道具",
    chapter4_room204_furniture: "第四章 204 教室家具",
    chapter4_room204_residual: "第四章 204 教室深色残影"
  }[id];
}

function assertPlate(decoded, label) {
  if (
    decoded.width !== expectedPlateSize.width
    || decoded.height !== expectedPlateSize.height
    || decoded.channels !== 3
  ) {
    throw new Error(`${label} must remain 1672x941 RGB.`);
  }
}

function assertPlateSize(decoded, label) {
  if (decoded.width !== expectedPlateSize.width || decoded.height !== expectedPlateSize.height) {
    throw new Error(`${label} must remain 1672x941.`);
  }
}

function rect([x, y, width, height]) {
  return { x, y, width, height };
}

function point(value, role) {
  return { x: value[0], y: value[1], coordinateSpace: "source_sheet", role };
}

function rectFromEdges(columns, rows, column, row) {
  return {
    x: columns[column],
    y: rows[row],
    width: columns[column + 1] - columns[column],
    height: rows[row + 1] - rows[row]
  };
}

function worldBounds(floor, x, y, width, height) {
  return { id: `${floor.toLowerCase()}_world_trigger`, floor, coordinateSpace: "world", bounds: { x, y, width, height } };
}

function expandRect(value, amount, maxWidth, maxHeight) {
  const x = Math.max(0, value.x - amount);
  const y = Math.max(0, value.y - amount);
  const right = Math.min(maxWidth, value.x + value.width + amount);
  const bottom = Math.min(maxHeight, value.y + value.height + amount);
  return { x, y, width: right - x, height: bottom - y };
}
