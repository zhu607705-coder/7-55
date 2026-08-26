import { access, readFile, readdir } from "node:fs/promises";
import { dirname, resolve } from "node:path";
import { fileURLToPath } from "node:url";
import {
  APPROVED_CHAPTER4_755_BASE_PLATES,
  APPROVED_CHAPTER4_755_SPRITESHEETS,
  APPROVED_CHAPTER4_755_STATE_PLATES,
  CHAPTER4_755_ASSET_ROOT,
  CHAPTER4_755_CANDIDATE_ROOT,
  alphaBounds,
  decodePng,
  sha256
} from "./normalize-chapter4-755-assets.mjs";

const repoRoot = resolve(dirname(fileURLToPath(import.meta.url)), "..");
const manifest = JSON.parse(await readFile(
  resolve(repoRoot, "src/assets/rpg/interiors/finale/finale_environment_manifest.json"),
  "utf8"
));
const npcManifest = JSON.parse(await readFile(
  resolve(repoRoot, "src/assets/rpg/npcs/finale/finale_npc_manifest.json"),
  "utf8"
));
const layout = JSON.parse(await readFile(
  resolve(repoRoot, "src/data/chapter4-three-floor-maze.layout.json"),
  "utf8"
));
const content = JSON.parse(await readFile(
  resolve(repoRoot, "src/data/chapter4-755.content.json"),
  "utf8"
));
const alumniModule = await readFile(
  resolve(repoRoot, "src/data/ChapterFourAlumniHonorWall.ts"),
  "utf8"
);

const expectedNormalizedHashes = {
  a1_2245_opening: "722c89e62b8b3efdd83deacf7ca90d9950f387c3b05dd813f24ad02f8551d47e",
  a1_1225_bakery: "6400a796a87ad3b98247560e1c9f1bd3b94bc408a9584284f661d7a645383f44",
  a2_202_final_minute: "171f05d4762794ef9d96db04a6c05ff24535a817639a336caea19760ef66a5e1"
};
const expectedPlateIds = [
  "a1_2245_opening",
  "a1_1225_bakery",
  "a2_1850_evening",
  "a3_1850_reference",
  "a1_2245_maintenance",
  "a1_0754_blackout",
  "a2_0754_chase",
  "a2_202_final_minute",
  "a1_0755_morning"
];
const expectedSheetFrames = {
  chapter4_clock_states: [
    "blank_face", "2245_missing_hour_hand", "1225_missing_hour_hand",
    "1850_hour_hand_restored", "2245_complete", "0754_calibrated",
    "0755_complete", "gear_stuttering", "gear_running"
  ],
  chapter4_power_panel_states: ["closed", "open_powered", "open_partial", "open_restored"],
  chapter4_story_items: [
    "sign_in_record_paper", "old_clock_hour_hand", "clock_positioning_plate", "short_pry_tool_candidate",
    "lubricating_oil", "final_minute_shard", "electronic_campus_card", "empty"
  ],
  chapter4_room204_furniture: [
    ...gridNames("desk", 3, 4),
    "group_table_1", "group_table_2", "group_table_3", "group_table_4",
    ...gridNames("chair", 2, 6),
    "podium"
  ],
  chapter4_room204_residual: gridNames("residual", 3, 4)
};
const expectedLegacySceneIds = [
  "finale_arrival_arcade",
  "finale_1f_lobby_maxwell",
  "finale_stairwell",
  "finale_vertical_core",
  "finale_2f_activity",
  "finale_final_classroom",
  "teaching_building_floor_1",
  "teaching_building_floor_2",
  "teaching_building_floor_3"
];
const expectedTask10NpcAssets = [
  {
    id: "cleaning_cart",
    file: "src/assets/rpg/npcs/finale/cleaning_cart_1frame.png",
    frameWidth: 144,
    frameHeight: 128,
    frameCount: 1,
    fps: 1,
    loop: true,
    footAnchor: { x: 0.5, y: 1 },
    sha256: "13521f3e15df3f73cec566c71fdb43042664db7898bea982e20f6837212f08fb"
  },
  {
    id: "cleaner_idle",
    file: "src/assets/rpg/npcs/finale/cleaner_idle_8frame.png",
    frameWidth: 96,
    frameHeight: 128,
    frameCount: 8,
    fps: 6,
    loop: true,
    footAnchor: { x: 0.5, y: 1 },
    sha256: "391f5288aa8acdfa2d6b96efcdf49fbc07d60b2b7b76cf31bb4ea362d45ca203"
  },
  {
    id: "cleaner_push_cart",
    file: "src/assets/rpg/npcs/finale/cleaner_push_cart_8frame.png",
    frameWidth: 192,
    frameHeight: 128,
    frameCount: 8,
    fps: 9,
    loop: true,
    footAnchor: { x: 0.5, y: 1 },
    sha256: "b3149e79622fd89da7eec97c4f9f1aa0bf6fdda4838d93f15ff64b636ab5d4d4"
  },
  {
    id: "cleaner_push_cart_down",
    file: "src/assets/rpg/npcs/finale/cleaner_push_cart_down_8frame.png",
    frameWidth: 192,
    frameHeight: 128,
    frameCount: 8,
    fps: 9,
    loop: true,
    footAnchor: { x: 0.5, y: 1 },
    sha256: "56b17d565581ca697864482cd4cebe1b55d71dd6153c9e6d7197d16b017e1bfb"
  },
  {
    id: "cleaner_push_cart_up",
    file: "src/assets/rpg/npcs/finale/cleaner_push_cart_up_8frame.png",
    frameWidth: 192,
    frameHeight: 128,
    frameCount: 8,
    fps: 9,
    loop: true,
    footAnchor: { x: 0.5, y: 1 },
    sha256: "4ad404ac81f54c121f250ffbaf606f98955106df51796508623e5f350cb262bc"
  },
  {
    id: "guard_walk",
    file: "src/assets/rpg/npcs/finale/guard_walk_8frame.png",
    frameWidth: 96,
    frameHeight: 128,
    frameCount: 8,
    fps: 9,
    loop: true,
    footAnchor: { x: 0.5, y: 1 },
    sha256: "21a66a9887295dd6d00bbce8acf18b637cf4b0364248b7cb83994e8de7c84da2"
  },
  {
    id: "guard_walk_down",
    file: "src/assets/rpg/npcs/finale/guard_walk_down_8frame.png",
    frameWidth: 96,
    frameHeight: 128,
    frameCount: 8,
    fps: 9,
    loop: true,
    footAnchor: { x: 0.5, y: 1 },
    sha256: "f27adc541f0b73f669163d1e4e2e15dec4349a1b07f10069e6cfa875dabe0dc1"
  },
  {
    id: "guard_walk_up",
    file: "src/assets/rpg/npcs/finale/guard_walk_up_8frame.png",
    frameWidth: 96,
    frameHeight: 128,
    frameCount: 8,
    fps: 9,
    loop: true,
    footAnchor: { x: 0.5, y: 1 },
    sha256: "2649d5abba5a7b8c34fad580c8f1148f858b9cdebd639dea2c44c460273bc423"
  }
];
const expectedAlumniPortraits = [
  { id: "chen_jiangong", targetId: "a3_alumni_chen_jiangong", file: "chen_jiangong_v01.png", width: 250 },
  { id: "cheng_kaijia", targetId: "a3_alumni_cheng_kaijia", file: "cheng_kaijia_v01.png", width: 250 },
  { id: "lu_yongxiang", targetId: "a3_alumni_lu_yongxiang", file: "lu_yongxiang_v01.png", width: 256 },
  { id: "su_buqing", targetId: "a3_alumni_su_buqing", file: "su_buqing_v01.png", width: 256 },
  { id: "tan_jiazhen", targetId: "a3_alumni_tan_jiazhen", file: "tan_jiazhen_v01.png", width: 250 },
  { id: "zhu_kezhen", targetId: "a3_alumni_zhu_kezhen", file: "zhu_kezhen_v01.png", width: 256 }
];

assert(manifest.schemaVersion === 3, "finale manifest must use schemaVersion 3");
assert(manifest.layoutContract?.schemaVersion === 2, "manifest layoutContract must bind schema 2");
assert(
  manifest.layoutContract?.sourceFile === "src/data/chapter4-three-floor-maze.layout.json",
  "manifest layoutContract sourceFile mismatch"
);
assertJsonEqual(manifest.layoutContract?.worldSize, { width: 1672, height: 941 }, "manifest worldSize");
assert(Array.isArray(manifest.basePlates), "manifest basePlates must be an array");
assert(Array.isArray(manifest.statePlates), "manifest statePlates must be an array");
assert(Array.isArray(manifest.spritesheets), "manifest spritesheets must be an array");
assert(Array.isArray(manifest.compatibilityAssets), "manifest compatibilityAssets must be an array");
assert(Array.isArray(manifest.scenes), "manifest legacy scenes must be an array");
assert(
  !JSON.stringify(manifest).includes("chapter4_a2_dynamic_structures_v01"),
  "manifest must not register or retain the retired dynamic-structures id"
);

assertJsonEqual(manifest.basePlates.map((entry) => entry.id), ["a1_base", "a2_base", "a3_base"], "base plate ids");
assertJsonEqual(manifest.statePlates.map((entry) => entry.id), expectedPlateIds, "state plate ids");
assertJsonEqual(manifest.scenes.map((entry) => entry.id), expectedLegacySceneIds, "legacy scene ids");
const contentPlateIds = content.time.states.flatMap((state) => state.plateIds);
assertJsonEqual(contentPlateIds, expectedPlateIds, "story/manifest state plate ids");
assert(new Set([...manifest.basePlates, ...manifest.statePlates].map((entry) => entry.id)).size === 12, "base/state plate ids must be unique");
assert(new Set([...manifest.basePlates, ...manifest.statePlates].map((entry) => entry.sourceFile)).size === 12, "base/state plate files must be unique");
const activePlateIds = new Set([...manifest.basePlates, ...manifest.statePlates].map((entry) => entry.id));
assert(
  manifest.scenes.every((entry) => !activePlateIds.has(entry.id)),
  "legacy scenes must not duplicate base/state plate ids"
);

await assertDirectoryExactly(
  resolve(CHAPTER4_755_ASSET_ROOT, "base"),
  APPROVED_CHAPTER4_755_BASE_PLATES.map(({ destination }) => destination.split("/").at(-1)),
  "formal base directory"
);
await assertDirectoryExactly(
  resolve(CHAPTER4_755_ASSET_ROOT, "states"),
  APPROVED_CHAPTER4_755_STATE_PLATES.map(({ destination }) => destination.split("/").at(-1)),
  "formal state directory"
);
await assertDirectoryExactly(
  resolve(CHAPTER4_755_ASSET_ROOT, "sprites"),
  APPROVED_CHAPTER4_755_SPRITESHEETS.map(({ destination }) => destination.split("/").at(-1)),
  "formal sprite directory"
);

const approvedSourceDefinitions = [
  ...APPROVED_CHAPTER4_755_BASE_PLATES,
  ...APPROVED_CHAPTER4_755_STATE_PLATES,
  ...APPROVED_CHAPTER4_755_SPRITESHEETS
];
const approvedSourceAvailability = await Promise.all(approvedSourceDefinitions.map(async (approved) => {
  try {
    await access(resolve(CHAPTER4_755_CANDIDATE_ROOT, approved.source));
    return true;
  } catch {
    return false;
  }
}));
const hasAllApprovedSources = approvedSourceAvailability.every(Boolean);
const hasNoApprovedSources = approvedSourceAvailability.every((available) => !available);
assert(
  hasAllApprovedSources || hasNoApprovedSources,
  "approved provenance sources must be either complete for a full local proof or absent in a clean checkout"
);
const provenanceSourceMode = hasAllApprovedSources ? "full_local_source_proof" : "tracked_contract_proof";

for (const approved of APPROVED_CHAPTER4_755_BASE_PLATES) {
  const entry = manifest.basePlates.find((candidate) => candidate.id === approved.id);
  assert(entry, `manifest base ${approved.id} is missing`);
  const destinationBytes = await readFile(resolve(CHAPTER4_755_ASSET_ROOT, approved.destination));
  const destinationSha256 = sha256(destinationBytes);
  assert(destinationSha256 === approved.sourceSha256, `${approved.id} formal base hash must match its approved source hash`);
  if (hasAllApprovedSources) {
    const sourceBytes = await readFile(resolve(CHAPTER4_755_CANDIDATE_ROOT, approved.source));
    assert(sha256(sourceBytes) === approved.sourceSha256, `${approved.id} approved source hash mismatch`);
    assert(sourceBytes.equals(destinationBytes), `${approved.id} must remain a byte-for-byte approved base`);
  }
  const decoded = decodePng(destinationBytes, approved.destination);
  assertPng(decoded, 1672, 941, 3, approved.destination);
  assert(entry.sourceId === approved.sourceId, `${approved.id} sourceId mismatch`);
  assert(entry.sourceSha256 === approved.sourceSha256, `${approved.id} sourceSha256 mismatch`);
  assert(entry.sha256 === destinationSha256, `${approved.id} output SHA-256 mismatch`);
  assert(entry.alphaRole === "opaque_base_plate", `${approved.id} alphaRole mismatch`);
  assert(entry.browserConsumer === "ChapterFourTemporalMazeScene", `${approved.id} browser consumer mismatch`);
  assert(entry.calibrationStatus === "approved_user_geometry", `${approved.id} calibration status mismatch`);
  assert(entry.collisionProfileId === `${approved.floor.toLowerCase()}_static_v1`, `${approved.id} collision profile mismatch`);
}

for (const approved of APPROVED_CHAPTER4_755_STATE_PLATES) {
  const entry = manifest.statePlates.find((candidate) => candidate.id === approved.id);
  assert(entry, `manifest state ${approved.id} is missing`);
  const destinationBytes = await readFile(resolve(CHAPTER4_755_ASSET_ROOT, approved.destination));
  const destinationSha256 = sha256(destinationBytes);
  const destination = decodePng(destinationBytes, approved.destination);
  assertPng(destination, 1672, 941, 3, approved.destination);
  let source = null;
  let sourceBytes = null;
  if (hasAllApprovedSources) {
    sourceBytes = await readFile(resolve(CHAPTER4_755_CANDIDATE_ROOT, approved.source));
    assert(sha256(sourceBytes) === approved.sourceSha256, `${approved.id} approved source hash mismatch`);
    source = decodePng(sourceBytes, approved.sourceId);
    assertPng(source, approved.sourceWidth, 941, 3, approved.sourceId);
  }
  if (approved.normalization === "byte_copy") {
    assert(destinationSha256 === approved.sourceSha256, `${approved.id} byte-copy output hash differs from source contract`);
    if (sourceBytes) assert(sourceBytes.equals(destinationBytes), `${approved.id} byte-copy output differs from source`);
    assert(entry.sha256 === approved.sourceSha256, `${approved.id} byte-copy hash mismatch`);
  } else {
    assert(
      destinationSha256 === expectedNormalizedHashes[approved.id]
        && entry.sha256 === expectedNormalizedHashes[approved.id],
      `${approved.id} normalized output hash mismatch: manifest=${entry.sha256} file=${destinationSha256}`
    );
    if (source) {
      assertAppendedLastColumn(source, destination, approved.id);
    } else {
      assertTrackedAppendedColumn(destination, approved.id);
    }
    assertJsonEqual(
      entry.normalization,
      { kind: "append_last_source_column", copiedColumnX: 1670, appendedColumnX: 1671 },
      `${approved.id} normalization contract`
    );
  }
  assert(entry.sha256 === destinationSha256, `${approved.id} manifest output SHA-256 mismatch`);
  assert(entry.sourceId === approved.sourceId, `${approved.id} sourceId mismatch`);
  assert(entry.sourceSha256 === approved.sourceSha256, `${approved.id} source SHA-256 mismatch`);
  assertJsonEqual(entry.sourceCanvas, { width: approved.sourceWidth, height: 941 }, `${approved.id} source canvas contract`);
  assert(entry.floor === approved.floor && entry.storyTime === approved.storyTime, `${approved.id} floor/time mismatch`);
  assert(entry.renderMode === "opaque_full_plate", `${approved.id} renderMode mismatch`);
  assert(entry.alphaRole === "opaque_state_plate", `${approved.id} alphaRole mismatch`);
  assert(entry.geometryAuthority === `${approved.floor.toLowerCase()}_base`, `${approved.id} geometryAuthority mismatch`);
  assert(entry.collisionProfileId === `${approved.floor.toLowerCase()}_static_v1`, `${approved.id} collisionProfileId mismatch`);
  assert(Array.isArray(entry.physicalDeltaIds), `${approved.id} physicalDeltaIds missing`);
  for (const deltaId of entry.physicalDeltaIds) {
    assert(layout.physicalDeltas.some((delta) => delta.id === deltaId), `${approved.id} references missing physical delta ${deltaId}`);
  }
  assert(entry.calibrationStatus === "approved_floor_geometry_contract", `${approved.id} calibration status mismatch`);
  assert(entry.registrationAnchors?.length >= 5, `${approved.id} must define at least five registration anchors`);
  assert(new Set(entry.registrationAnchors?.map((anchor) => anchor.id)).size === entry.registrationAnchors?.length, `${approved.id} registration anchor ids repeat`);
}

assert(manifest.spritesheets.length === 5, "schema 3 spritesheets registry must contain exactly five entries");
const activeSheets = manifest.spritesheets;
assertJsonEqual(
  activeSheets.map((sheet) => sheet.id),
  APPROVED_CHAPTER4_755_SPRITESHEETS.map((sheet) => sheet.id),
  "active Chapter 4 sprite sheets"
);
assert(
  activeSheets.every((sheet) => sheet.activeChapter4Contract === true),
  "every schema 3 spritesheet must set activeChapter4Contract=true"
);
assert(
  !activeSheets.some((sheet) => sheet.id.includes("dynamic_structures") || sheet.file.includes("dynamic_structures")),
  "old dynamic-structures sheet must not be active"
);

assert(manifest.compatibilityAssets.length === 1, "manifest must isolate exactly one compatibility asset");
const [legacyElevator] = manifest.compatibilityAssets;
assert(legacyElevator.id === "teaching_building_elevator_doors", "compatibility elevator id mismatch");
assert(legacyElevator.registryStatus === "compatibility_only", "compatibility elevator registry status mismatch");
assert(legacyElevator.consumerRegistration === "excluded_from_schema3_active_registry", "compatibility elevator consumer status mismatch");
assert(legacyElevator.activeChapter4Contract === false, "compatibility elevator must not be active");
assert(legacyElevator.browserConsumer === undefined, "compatibility elevator must not register an active browser consumer");

const activeRuntimeRegistry = [
  manifest.layoutContract,
  ...manifest.basePlates,
  ...manifest.statePlates,
  ...manifest.spritesheets
];
const forbiddenActiveIds = new Set([
  "chapter4_a2_dynamic_structures_v01",
  "teaching_building_elevator_doors"
]);
for (const entry of activeRuntimeRegistry) {
  assert(!forbiddenActiveIds.has(entry?.id), `${entry?.id} must not appear in the schema 3 active registry`);
  assert(entry?.registryStatus !== "reference_only", `${entry?.id} must not be reference-only in the active registry`);
  assert(entry?.registryStatus !== "candidate", `${entry?.id} must not be a candidate in the active registry`);
  if (!entry?.sourceFile) continue;
  assert(!entry.sourceFile.includes("artifacts/"), `${entry.id} registers an artifacts path`);
  assert(!entry.sourceFile.includes("candidate"), `${entry.id} registers a candidate path`);
  assert(!entry.sourceFile.includes("dynamic_structures"), `${entry.id} registers the retired dynamic-structures sheet`);
}

for (const approved of APPROVED_CHAPTER4_755_SPRITESHEETS) {
  const sheet = activeSheets.find((candidate) => candidate.id === approved.id);
  assert(sheet, `${approved.id} sheet is missing`);
  const destinationBytes = await readFile(resolve(CHAPTER4_755_ASSET_ROOT, approved.destination));
  const destinationSha256 = sha256(destinationBytes);
  assert(destinationSha256 === approved.sourceSha256, `${approved.id} formal sheet hash must match its approved source hash`);
  if (hasAllApprovedSources) {
    const sourceBytes = await readFile(resolve(CHAPTER4_755_CANDIDATE_ROOT, approved.source));
    assert(sha256(sourceBytes) === approved.sourceSha256, `${approved.id} source hash mismatch`);
    assert(sourceBytes.equals(destinationBytes), `${approved.id} must remain a byte-for-byte approved sheet`);
  }
  const decoded = decodePng(destinationBytes, approved.destination);
  assertPng(decoded, approved.width, approved.height, 4, approved.destination);
  assert(sheet.sourceId === approved.sourceId, `${approved.id} sourceId mismatch`);
  assert(sheet.sourceSha256 === approved.sourceSha256, `${approved.id} sourceSha256 mismatch`);
  assert(sheet.sha256 === approved.sourceSha256, `${approved.id} output hash mismatch`);
  assert(sheet.alphaRole === "transparent_sprite_sheet", `${approved.id} alphaRole mismatch`);
  assert(sheet.alphaTrimThreshold === 0.05, `${approved.id} alpha threshold mismatch`);
  assertJsonEqual(sheet.frames.map((frame) => frame.id), expectedSheetFrames[approved.id], `${approved.id} frame ids`);
  assert(new Set(sheet.frames.map((frame) => frame.id)).size === sheet.frames.length, `${approved.id} frame ids repeat`);
  for (const frame of sheet.frames) validateFrame(sheet, frame, decoded);
}

const clock = activeSheets.find((sheet) => sheet.id === "chapter4_clock_states");
const power = activeSheets.find((sheet) => sheet.id === "chapter4_power_panel_states");
const storyItems = activeSheets.find((sheet) => sheet.id === "chapter4_story_items");
const furniture = activeSheets.find((sheet) => sheet.id === "chapter4_room204_furniture");
const residual = activeSheets.find((sheet) => sheet.id === "chapter4_room204_residual");
assert(clock.frames.every((frame) => frame.collisionType === "none" && frame.collisionBounds.length === 0), "clock frames must remain non-colliding");
assert(power.frames.every((frame) => frame.collisionType === "none" && frame.collisionBounds.length === 0), "power frames must remain non-colliding");
assert(storyItems.frames.every((frame) => frame.collisionType === "none" && frame.collisionBounds.length === 0), "story items must remain non-colliding");
assert(storyItems.frames.find((frame) => frame.id === "empty")?.sourceTrim === null, "story item empty frame must have null trim");
assert(furniture.frames.every((frame) => frame.sourceCell === null && frame.collisionType === "foot_box" && frame.collisionBounds.length === 1), "all 29 furniture frames need one explicit foot collision");
assert(residual.frames.every((frame) => frame.sourceCell === null && frame.collisionType === "none" && frame.collisionBounds.length === 0), "all 12 residual frames must remain visual-only");
assert(residual.groupInteractionBounds?.length === 1, "residual sheet must expose one group interaction bounds");
assert(residual.groupInteractionBounds?.[0]?.observesAllFrameIds?.length === 12, "residual group must observe all 12 frames at once");

assert(npcManifest.schemaVersion === 1, "finale NPC manifest must use schemaVersion 1");
assert(Array.isArray(npcManifest.animations), "finale NPC manifest animations must be an array");
for (const expected of expectedTask10NpcAssets) {
  const entry = npcManifest.animations?.find((candidate) => candidate.id === expected.id);
  assert(Boolean(entry), `Task10 NPC animation ${expected.id} is missing`);
  if (!entry) continue;
  assertJsonEqual(entry, expected, `Task10 NPC manifest ${expected.id}`);
  const bytes = await readFile(resolve(repoRoot, entry.file));
  assert(sha256(bytes) === expected.sha256, `${expected.id} PNG SHA-256 mismatch`);
  const decoded = decodePng(bytes, entry.file);
  assertPng(
    decoded,
    expected.frameWidth * expected.frameCount,
    expected.frameHeight,
    4,
    entry.file
  );
}

for (const expected of expectedAlumniPortraits) {
  const assetPath = resolve(
    repoRoot,
    "src/assets/rpg/portraits/chapter4/alumni",
    expected.file
  );
  const bytes = await readFile(assetPath);
  assert(bytes.length < 200_000, `${expected.file} must remain below 200 KB for silent RPG preload`);
  const decoded = decodePng(bytes, expected.file);
  assertPng(decoded, expected.width, 384, 4, expected.file);
  const measured = alphaBounds(
    decoded,
    { x: 0, y: 0, width: decoded.width, height: decoded.height },
    1
  );
  assert(measured !== null, `${expected.file} must contain a visible portrait`);
  let transparentPixelCount = 0;
  for (let alphaIndex = 3; alphaIndex < decoded.pixels.length; alphaIndex += 4) {
    if (decoded.pixels[alphaIndex] === 0) transparentPixelCount += 1;
  }
  assert(
    transparentPixelCount >= decoded.width * decoded.height * 0.1,
    `${expected.file} must retain at least 10% fully transparent background pixels`
  );
  assert(decoded.pixels[3] === 0, `${expected.file} top-left corner must remain transparent`);
  assert(alumniModule.includes(`id: "${expected.id}"`), `${expected.id} is missing from the alumni data table`);
  assert(alumniModule.includes(`targetId: "${expected.targetId}"`), `${expected.targetId} is missing from the alumni data table`);
  assert(alumniModule.includes(expected.file), `${expected.file} is not referenced by the alumni data table`);
}

const maintenanceRuntime = layout.maintenanceRuntime;
assertJsonEqual([
  maintenanceRuntime?.cleaningCart?.texture,
  maintenanceRuntime?.cleaner?.animationId,
  maintenanceRuntime?.repairedPush?.animationId,
  maintenanceRuntime?.guard?.animationId
], [
  "cleaning_cart",
  "cleaner_idle",
  "cleaner_push_cart_up",
  "guard_walk"
], "Task10 layout/NPC animation bindings");
const pryTarget = maintenanceRuntime?.targetEntities?.find(
  (target) => target.targetId === "a1_bakery_back_pry_bar"
);
const oilTarget = maintenanceRuntime?.targetEntities?.find(
  (target) => target.targetId === "a1_cleaning_cart_oil_bottle"
);
const gearTarget = maintenanceRuntime?.targetEntities?.find(
  (target) => target.targetId === "a1_hall_clock_gear"
);
const cartTargets = maintenanceRuntime?.targetEntities?.filter((target) => (
  [
    "a1_cleaning_cart_wheel_inspection",
    "a1_cleaning_cart_wheel_cover",
    "a1_cleaning_cart_wheel"
  ].includes(target.targetId)
)) ?? [];
assert(pryTarget?.frame === maintenanceRuntime?.pryBar?.frame, "Task10 pry target and visual must share one story-item frame id");
const pryFrame = storyItems.frames.find((frame) => frame.id === pryTarget?.frame);
const oilFrame = storyItems.frames.find((frame) => frame.id === oilTarget?.frame);
const gearFrames = [gearTarget?.frameBefore, gearTarget?.frameAfter].map(
  (frameId) => clock.frames.find((frame) => frame.id === frameId)
);
assert(Boolean(pryFrame), "Task10 pry frame must exist in chapter4_story_items");
assert(Boolean(oilFrame), "Task10 oil frame must exist in chapter4_story_items");
assert(gearFrames.every(Boolean), "Task10 gear frames must exist in chapter4_clock_states");
assertJsonEqual(maintenanceRuntime?.cleaningCart?.wheelRegion, {
  coordinateSpace: "cleaning_cart_frame_local",
  sourceFrameSize: { width: 144, height: 128 },
  origin: { x: 0.5, y: 1 },
  bounds: { x: 88, y: 91, width: 28, height: 37 },
  visualRole: "programmatic_wheel_cover_and_wheel_interaction"
}, "Task10 cleaning-cart source-local wheel derivation");
assert(cartTargets.length === 3 && cartTargets.every((target) => (
  target.boundsDerivation?.kind === "visible_cleaning_cart_frame_local_region"
  && target.boundsDerivation?.source === "maintenanceRuntime.cleaningCart.wheelRegion"
)), "Task10 cart inspection/cover/wheel targets must derive from the visible cart frame-local region");
assert(
  pryFrame?.interactionBounds?.some((entry) => (
    entry.id === pryTarget?.boundsDerivation?.interactionId
    && entry.coordinateSpace === "source_sheet"
  )),
  "Task10 pry target must bind its visible manifest source interaction"
);
assert(
  oilFrame?.interactionBounds?.some((entry) => (
    entry.id === oilTarget?.boundsDerivation?.interactionId
    && entry.coordinateSpace === "source_sheet"
  )),
  "Task10 oil target must bind its visible manifest source interaction"
);
assert(
  gearTarget?.boundsDerivation?.kind === "visible_clock_frame_manifest_world_interaction"
  && gearFrames.every((frame) => frame?.interactionBounds?.some((entry) => (
    entry.id === gearTarget.boundsDerivation.interactionId
    && entry.coordinateSpace === "world"
    && entry.floor === gearTarget.boundsDerivation.floor
  ))),
  "Task10 gear target must bind both visible clock frames to their A1 manifest interaction"
);

const finalClockRuntime = layout.finalClockRuntime;
const finalClockFrame = clock.frames.find((frame) => frame.id === finalClockRuntime?.clockFrame);
assert(Boolean(finalClockFrame), "Task11 final clock must bind the approved gear_running frame");
assert(
  finalClockFrame?.collisionType === "none" && finalClockFrame?.collisionBounds?.length === 0,
  "Task11 final clock frame must remain visual-only and non-colliding"
);
assert(
  finalClockRuntime?.endpoint?.boundsDerivation?.kind === "visible_programmatic_minute_endpoint_get_bounds"
    && finalClockRuntime.endpoint.boundsDerivation.clockFrame === finalClockRuntime.clockFrame,
  "Task11 minute endpoint must derive from the visible programmatic hand bound to the approved clock frame"
);
assert(
  finalClockRuntime?.endpoint?.installationBounds?.width === 16
    && finalClockRuntime?.endpoint?.installationBounds?.height === 16
    && finalClockRuntime.endpoint.installationBounds.width < 122
    && finalClockRuntime.endpoint.installationBounds.height < 120,
  "Task11 minute endpoint must use its small visible handle bounds and must not reuse the whole clock rectangle"
);

const lightGridRuntime = layout.lightGridRuntime;
assertJsonEqual(
  lightGridRuntime?.panel?.frames,
  power.frames.map((frame) => frame.id),
  "Task11 power-panel layout/manifest frame binding"
);
assert(
  lightGridRuntime?.panel?.boundsDerivation?.spritesheetId === power.id
    && lightGridRuntime.panel.boundsDerivation.interactionId === "a1_world_trigger",
  "Task11 power-panel bounds must retain the approved spritesheet provenance and visible interaction id"
);
assert(
  power.frames.every((frame) => frame.sourceTrim !== null && frame.measuredAlphaBounds !== null),
  "Task11 power-panel states must retain measured alpha provenance for every visible frame"
);

const finalMinuteRuntime = layout.finalMinuteRuntime;
const finalMinuteFrame = storyItems.frames.find((frame) => frame.id === "final_minute_shard");
assert(Boolean(finalMinuteFrame), "Task12 final minute must reuse the approved final_minute_shard frame");
assert(
  finalMinuteFrame?.collisionType === "none"
    && finalMinuteFrame?.collisionBounds?.length === 0
    && finalMinuteFrame?.interactionType === "pickup_or_drop_trigger",
  "Task12 final-minute frame must remain a non-colliding pickup visual"
);
assertJsonEqual({
  targetId: finalMinuteRuntime?.targetId,
  entityId: finalMinuteRuntime?.entityId,
  texture: finalMinuteRuntime?.texture,
  frame: finalMinuteRuntime?.frame,
  pivot: finalMinuteRuntime?.pivot,
  uniformScale: finalMinuteRuntime?.uniformScale,
  collision: finalMinuteRuntime?.collision
}, {
  targetId: "a2_202_projection",
  entityId: "chapter4_final_minute_shard",
  texture: "chapter4_story_items",
  frame: "final_minute_shard",
  pivot: { x: 1353, y: 320 },
  uniformScale: 0.18,
  collision: false
}, "Task12 final-minute layout/manifest binding");
assertJsonEqual(finalMinuteRuntime?.boundsDerivation, {
  kind: "visible_sprite_get_bounds",
  sourceCell: finalMinuteFrame?.sourceCell,
  sourcePivot: {
    x: finalMinuteFrame?.pivot?.x,
    y: finalMinuteFrame?.pivot?.y
  },
  zoneSource: "sprite.getBounds"
}, "Task12 final-minute visible getBounds provenance");
const finalMinuteLeft = Math.floor(
  finalMinuteRuntime.pivot.x
    + (finalMinuteFrame.sourceCell.x - finalMinuteFrame.pivot.x) * finalMinuteRuntime.uniformScale
);
const finalMinuteTop = Math.floor(
  finalMinuteRuntime.pivot.y
    + (finalMinuteFrame.sourceCell.y - finalMinuteFrame.pivot.y) * finalMinuteRuntime.uniformScale
);
const finalMinuteRight = Math.ceil(
  finalMinuteRuntime.pivot.x
    + (finalMinuteFrame.sourceCell.x + finalMinuteFrame.sourceCell.width - finalMinuteFrame.pivot.x)
      * finalMinuteRuntime.uniformScale
);
const finalMinuteBottom = Math.ceil(
  finalMinuteRuntime.pivot.y
    + (finalMinuteFrame.sourceCell.y + finalMinuteFrame.sourceCell.height - finalMinuteFrame.pivot.y)
      * finalMinuteRuntime.uniformScale
);
assertJsonEqual(finalMinuteRuntime?.installationBounds, {
  x: finalMinuteLeft,
  y: finalMinuteTop,
  width: finalMinuteRight - finalMinuteLeft,
  height: finalMinuteBottom - finalMinuteTop
}, "Task12 final-minute sprite.getBounds outward rectangle");
assert(
  finalMinuteFrame?.interactionBounds?.some((entry) => entry.id === "final_minute_shard_source_trigger"),
  "Task12 approved final-minute frame must retain its source pickup interaction evidence"
);

for (const entry of [
  manifest.layoutContract,
  ...manifest.basePlates,
  ...manifest.statePlates,
  ...manifest.scenes
]) {
  if (!entry?.sourceFile) continue;
  assert(!entry.sourceFile.includes("artifacts/"), `${entry.id} registers an artifacts path`);
  assert(!entry.sourceFile.includes("candidate"), `${entry.id} registers a candidate path`);
}
assert(manifest.exclusions?.generatedStarMaterial === false, "manifest must not generate a replacement star material");
assert(manifest.exclusions?.generatedExteriorClosure === false, "manifest must not generate a replacement exterior closure");

console.log(
  `chapter4 7:55 assets PASS schema=3 bases=${manifest.basePlates.length} states=${manifest.statePlates.length} activeSheets=${activeSheets.length} frames=${activeSheets.reduce((sum, sheet) => sum + sheet.frames.length, 0)} normalizedPixelProofs=3 provenanceSourceMode=${provenanceSourceMode} task10NpcAssets=${expectedTask10NpcAssets.length} task10FrameBindings=4 task10SourceDerivations=4 task11ClockFrames=1 task11PowerFrames=4 task11AssetEvidence=file_manifest_contract(no_browser_evidence) task12FinalMinute=approved_frame+visible_getBounds_contract(no_browser_evidence) alumniPortraits=${expectedAlumniPortraits.length}+transparent+referenced`
);

function validateFrame(sheet, frame, decoded) {
  assertRect(frame.sourceRect, decoded.width, decoded.height, `${sheet.id}.${frame.id}.sourceRect`);
  const measured = alphaBounds(decoded, frame.sourceRect, 13);
  assertJsonEqual(frame.measuredAlphaBounds, measured, `${sheet.id}.${frame.id}.measuredAlphaBounds`);
  assertJsonEqual(frame.sourceTrim, measured, `${sheet.id}.${frame.id}.sourceTrim`);
  if (frame.id === "empty") {
    assert(frame.pivot === null, `${sheet.id}.empty pivot must be null`);
  } else {
    assert(frame.sourceTrim !== null, `${sheet.id}.${frame.id} sourceTrim is missing`);
    assert(frame.pivot && Number.isFinite(frame.pivot.x) && Number.isFinite(frame.pivot.y), `${sheet.id}.${frame.id} pivot is missing`);
    if (frame.pivot) {
      assert(
        frame.pivot.x >= frame.sourceRect.x
        && frame.pivot.x <= frame.sourceRect.x + frame.sourceRect.width
        && frame.pivot.y >= frame.sourceRect.y
        && frame.pivot.y <= frame.sourceRect.y + frame.sourceRect.height,
        `${sheet.id}.${frame.id} pivot lies outside sourceRect`
      );
    }
  }
  assert(Array.isArray(frame.collisionBounds), `${sheet.id}.${frame.id} collisionBounds must be explicit`);
  assert(Array.isArray(frame.interactionBounds), `${sheet.id}.${frame.id} interactionBounds must be explicit`);
  for (const collision of frame.collisionBounds ?? []) {
    assert(collision.coordinateSpace === "source_sheet", `${sheet.id}.${frame.id} collision coordinateSpace mismatch`);
    assertRect(collision.bounds, decoded.width, decoded.height, `${sheet.id}.${frame.id}.${collision.id}`);
  }
  for (const interaction of frame.interactionBounds ?? []) {
    if (interaction.coordinateSpace === "source_sheet") {
      assertRect(interaction.bounds, decoded.width, decoded.height, `${sheet.id}.${frame.id}.${interaction.id}`);
    } else if (interaction.coordinateSpace === "world") {
      assert(["A1", "A2", "A3"].includes(interaction.floor), `${sheet.id}.${frame.id} world interaction floor mismatch`);
      assertRect(interaction.bounds, 1672, 941, `${sheet.id}.${frame.id}.${interaction.id}`);
    } else {
      assert(false, `${sheet.id}.${frame.id} interaction coordinateSpace is missing`);
    }
  }
  if (frame.collisionType === "none") {
    assert(frame.collisionBounds.length === 0, `${sheet.id}.${frame.id} non-colliding frame has collision bounds`);
  }
}

function assertAppendedLastColumn(source, destination, label) {
  assert(destination.width === source.width + 1, `${label} destination width must add exactly one column`);
  assert(destination.height === source.height && destination.channels === source.channels, `${label} destination pixel format changed`);
  const sourceStride = source.width * source.channels;
  const destinationStride = destination.width * destination.channels;
  for (let y = 0; y < source.height; y += 1) {
    const sourceRow = source.pixels.subarray(y * sourceStride, (y + 1) * sourceStride);
    const destinationOriginal = destination.pixels.subarray(y * destinationStride, y * destinationStride + sourceStride);
    assert(sourceRow.equals(destinationOriginal), `${label} altered original pixels on row ${y}`);
    const sourceLast = sourceRow.subarray(sourceStride - source.channels);
    const destinationAdded = destination.pixels.subarray(
      y * destinationStride + sourceStride,
      y * destinationStride + sourceStride + source.channels
    );
    assert(sourceLast.equals(destinationAdded), `${label} appended column differs from source column 1670 on row ${y}`);
  }
}

function assertTrackedAppendedColumn(destination, label) {
  assert(destination.width === 1672 && destination.height === 941, `${label} tracked normalized output must be 1672x941`);
  const rowStride = destination.width * destination.channels;
  for (let y = 0; y < destination.height; y += 1) {
    const copiedColumn = destination.pixels.subarray(
      y * rowStride + 1670 * destination.channels,
      y * rowStride + 1671 * destination.channels
    );
    const appendedColumn = destination.pixels.subarray(
      y * rowStride + 1671 * destination.channels,
      y * rowStride + 1672 * destination.channels
    );
    assert(copiedColumn.equals(appendedColumn), `${label} tracked appended column differs from copied column 1670 on row ${y}`);
  }
}

function assertPng(decoded, width, height, channels, label) {
  assert(
    decoded.width === width && decoded.height === height && decoded.channels === channels,
    `${label} must be ${width}x${height} with ${channels} channels; got ${decoded.width}x${decoded.height} with ${decoded.channels}`
  );
}

async function assertDirectoryExactly(directory, expected, label) {
  const actual = (await readdir(directory)).sort();
  assertJsonEqual(actual, [...expected].sort(), label);
}

function assertRect(rect, width, height, label) {
  assert(rect && typeof rect === "object", `${label} must be an object rectangle`);
  if (!rect || typeof rect !== "object") return;
  assert(
    Number.isInteger(rect.x) && Number.isInteger(rect.y)
    && Number.isInteger(rect.width) && Number.isInteger(rect.height),
    `${label} must use integer x/y/width/height`
  );
  assert(
    rect.width > 0 && rect.height > 0
    && rect.x >= 0 && rect.y >= 0
    && rect.x + rect.width <= width
    && rect.y + rect.height <= height,
    `${label} lies outside ${width}x${height}`
  );
  for (const legacy of ["left", "top", "right", "bottom"]) {
    assert(!(legacy in rect), `${label} must not use ${legacy}`);
  }
}

function gridNames(prefix, rows, columns) {
  const names = [];
  for (let row = 1; row <= rows; row += 1) {
    for (let column = 1; column <= columns; column += 1) names.push(`${prefix}_r${row}c${column}`);
  }
  return names;
}

function assertJsonEqual(actual, expected, label) {
  assert(
    JSON.stringify(actual) === JSON.stringify(expected),
    `${label} mismatch: expected ${JSON.stringify(expected)}, got ${JSON.stringify(actual)}`
  );
}

function assert(condition, message) {
  if (!condition) throw new Error(`[chapter4:validate-assets] ${message}`);
}
