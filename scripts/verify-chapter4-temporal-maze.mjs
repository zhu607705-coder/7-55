import { readFile } from "node:fs/promises";

const topology = JSON.parse(await readFile(
  new URL("../src/data/chapter4-temporal-maze.topology.json", import.meta.url),
  "utf8"
));
const layout = JSON.parse(await readFile(
  new URL("../src/data/chapter4-three-floor-maze.layout.json", import.meta.url),
  "utf8"
));
const content = JSON.parse(await readFile(
  new URL("../src/data/chapter4-755.content.json", import.meta.url),
  "utf8"
));
const finaleManifest = JSON.parse(await readFile(
  new URL(
    "../src/assets/rpg/interiors/finale/finale_environment_manifest.json",
    import.meta.url
  ),
  "utf8"
));

const errors = [];
let assertionCount = 0;
assert(
  !JSON.stringify(layout).includes('"requiredFacing"'),
  "Chapter 4 layout must not declare an interaction-facing requirement"
);
const expectedFloors = ["A1", "A2", "A3"];
const expectedAssets = ["a1_base", "a2_base", "a3_base"];
const expectedCheckpoints = ["c4_a1_lobby", "c4_a2_corridor", "c4_a3_wayfinding"];
const expectedFloorCounts = {
  A1: { collisions: 44, walkable: 7, occlusions: 10 },
  A2: { collisions: 24, walkable: 5, occlusions: 6 },
  A3: { collisions: 63, walkable: 8, occlusions: 2 }
};
const expectedElevators = {
  A1: {
    id: "a1_main_elevator",
    sourceAnnotationId: "a1-ann-001",
    visibleBounds: { x: 742, y: 64, width: 61, height: 83 },
    doorCenter: { x: 772.5, y: 105.5 }
  },
  A2: {
    id: "a2_main_elevator",
    sourceAnnotationId: "a2-ann-001",
    visibleBounds: { x: 758, y: 67, width: 66, height: 69 },
    doorCenter: { x: 791, y: 101.5 }
  },
  A3: {
    id: "a3_main_elevator",
    sourceAnnotationId: "a3-ann-021",
    visibleBounds: { x: 747, y: 47, width: 81, height: 95 },
    doorCenter: { x: 787.5, y: 94.5 }
  }
};
const requiredRouteAssertionIds = [
  "a1_lobby_connects_bakery",
  "a1_clock_connects_transport",
  "a1_final_chase_connects_stair",
  "a2_201_connects_core",
  "a2_204_connects_core",
  "a2_202_connects_core",
  "a2_203_connects_core",
  "a2_open_study_connects_core",
  "a3_reference_classroom_reachable"
];
const forbiddenActiveIds = new Set([
  "a2_partition_west",
  "a2_partition_east",
  "a2_room_203_return_door",
  "a2_schedule_observation",
  "a2_fragment_west",
  "a2_fragment_east",
  "a2_return_window",
  "a3_old_signage",
  "a3_wayfinding_board",
  "a3_bridge_history"
]);
const expectedBakeryRuntimeTargets = [
  {
    targetId: "a1_bakery_inspection_lamp",
    entityId: "chapter4-bakery-inspection-lamp",
    installationBounds: { x: 354, y: 313, width: 39, height: 30 },
    standPosition: { x: 374, y: 390 },
    proximity: 56
  },
  {
    targetId: "a1_bakery_conveyor_edge",
    entityId: "chapter4-bakery-conveyor-edge",
    installationBounds: { x: 286, y: 332, width: 17, height: 29 },
    standPosition: { x: 294, y: 390 },
    proximity: 48
  },
  {
    targetId: "a1_bakery_hour_hand_pickup",
    entityId: "chapter4-bakery-hour-hand-pickup",
    installationBounds: { x: 288, y: 312, width: 34, height: 39 },
    standPosition: { x: 294, y: 390 },
    proximity: 48
  }
];
const expectedMaintenanceRuntimeTargets = [
  {
    targetId: "a1_cleaning_cart_wheel_inspection",
    entityId: "chapter4_cleaning_cart_wheel_inspection",
    installationBounds: { x: 1125, y: 691, width: 19, height: 25 },
    standPosition: { x: 1060, y: 716 },
    proximity: 72,
    boundsDerivation: {
      kind: "visible_cleaning_cart_frame_local_region",
      source: "maintenanceRuntime.cleaningCart.wheelRegion"
    },
    approximate: true
  },
  {
    targetId: "a1_bakery_back_pry_bar",
    entityId: "chapter4_pry_bar_pickup",
    installationBounds: { x: 442, y: 691, width: 32, height: 38 },
    standPosition: { x: 458, y: 758 },
    proximity: 52,
    frame: "short_pry_tool_candidate",
    uniformScale: 0.1,
    boundsDerivation: {
      kind: "visible_story_item_manifest_interaction",
      spritesheetId: "chapter4_story_items",
      interactionId: "short_pry_tool_candidate_source_trigger"
    },
    approximate: true
  },
  {
    targetId: "a1_cleaning_cart_wheel_cover",
    entityId: "chapter4_cleaning_cart_wheel_cover",
    installationBounds: { x: 1125, y: 691, width: 19, height: 25 },
    standPosition: { x: 1060, y: 716 },
    proximity: 72,
    boundsDerivation: {
      kind: "visible_cleaning_cart_frame_local_region",
      source: "maintenanceRuntime.cleaningCart.wheelRegion",
      visualState: "programmatic_open_cover"
    },
    approximate: true
  },
  {
    targetId: "a1_cleaning_cart_oil_bottle",
    entityId: "chapter4_cleaning_cart_oil_bottle",
    installationBounds: { x: 1091, y: 647, width: 22, height: 31 },
    standPosition: { x: 1060, y: 716 },
    proximity: 72,
    frame: "lubricating_oil",
    pivot: { x: 1102, y: 677 },
    uniformScale: 0.08,
    boundsDerivation: {
      kind: "visible_story_item_manifest_interaction",
      spritesheetId: "chapter4_story_items",
      interactionId: "lubricating_oil_source_trigger"
    },
    approximate: true
  },
  {
    targetId: "a1_cleaning_cart_wheel",
    entityId: "chapter4_cleaning_cart_wheel",
    installationBounds: { x: 1125, y: 691, width: 19, height: 25 },
    standPosition: { x: 1060, y: 716 },
    proximity: 72,
    boundsDerivation: {
      kind: "visible_cleaning_cart_frame_local_region",
      source: "maintenanceRuntime.cleaningCart.wheelRegion"
    },
    approximate: true
  },
  {
    targetId: "a1_hall_clock_gear",
    entityId: "chapter4_hall_clock_gear",
    installationBounds: { x: 940, y: 30, width: 122, height: 120 },
    standPosition: { x: 1001, y: 214 },
    proximity: 86,
    frameBefore: "gear_stuttering",
    frameAfter: "gear_running",
    boundsDerivation: {
      kind: "visible_clock_frame_manifest_world_interaction",
      spritesheetId: "chapter4_clock_states",
      interactionId: "a1_world_trigger",
      floor: "A1"
    },
    approximate: false
  }
];
const expectedMorningCheckinRuntimeTargets = [
  {
    targetId: "a1_campus_card_reader",
    entityId: "chapter4_checkin_card_reader",
    installationBounds: { x: 784, y: 607, width: 30, height: 24 },
    standPosition: { x: 799, y: 662 },
    proximity: 72,
    boundsDerivation: {
      kind: "visible_programmatic_card_reader_get_bounds",
      zoneSource: "visibleFixture.getBounds"
    },
    approximate: false
  },
  {
    targetId: "a1_attendance_paper_slot",
    entityId: "chapter4_checkin_attendance_paper_slot",
    installationBounds: { x: 848, y: 606, width: 38, height: 25 },
    standPosition: { x: 867, y: 662 },
    proximity: 72,
    boundsDerivation: {
      kind: "visible_programmatic_paper_slot_get_bounds",
      zoneSource: "visibleFixture.getBounds"
    },
    approximate: false
  }
];
const expectedBakeryCrowdRoutes = [
  ["bakery_student_01", 540, 600, 670, 600, 32, 360],
  ["bakery_student_02", 1120, 600, 990, 600, 28, 420],
  ["bakery_student_03", 540, 710, 660, 710, 34, 300]
];
const expectedRoom204PieceIds = Array.from(
  { length: 12 },
  (_, index) => `desk_pair_${String(index + 1).padStart(2, "0")}`
);
const expectedRoom204SlotIds = Array.from(
  { length: 12 },
  (_, index) => `morning_slot_${String(index + 1).padStart(2, "0")}`
);
const expectedRoom204DeskFrames = [
  "desk_r1c1", "desk_r1c2", "desk_r1c3", "desk_r1c4",
  "desk_r2c1", "desk_r2c2", "desk_r2c3", "desk_r2c4",
  "desk_r3c1", "desk_r3c2", "desk_r3c3", "desk_r3c4"
];
const expectedRoom204ChairFrames = [
  "chair_r1c1", "chair_r1c2", "chair_r1c3", "chair_r1c4", "chair_r1c5", "chair_r1c6",
  "chair_r2c1", "chair_r2c2", "chair_r2c3", "chair_r2c4", "chair_r2c5", "chair_r2c6"
];
const expectedRoom204ResidualFrames = [
  "residual_r1c1", "residual_r1c2", "residual_r1c3", "residual_r1c4",
  "residual_r2c1", "residual_r2c2", "residual_r2c3", "residual_r2c4",
  "residual_r3c1", "residual_r3c2", "residual_r3c3", "residual_r3c4"
];
const expectedRoom204DiscussionTableIds = [
  "group_table_1", "group_table_2", "group_table_3", "group_table_4"
];

assert(topology.schemaVersion === 2, "active topology must use schemaVersion 2");
assert(topology.runtimeStatus === "active_three_floor_755", "active topology runtimeStatus mismatch");
assert(layout.schemaVersion === 2, "three-floor layout must use schemaVersion 2");
assertRectSemantics(topology.coordinateSystem, "topology.coordinateSystem");
assertRectSemantics(layout.coordinateSystem, "layout.coordinateSystem");
assertJsonEqual(topology.worldSize, { width: 1672, height: 941 }, "topology worldSize");
assertJsonEqual(layout.worldSize, topology.worldSize, "layout/topology worldSize");
assert(
  layout.sourceAnnotationContract?.reviewStatus === "approved_for_integration",
  "layout must retain the approved manual annotation source"
);
assert(
  layout.furnitureCollisionDraftContract?.schema === "chapter4-furniture-collision-draft/v1",
  "layout must retain the user browser furniture-collision draft provenance"
);
assertJsonEqual(
  layout.furnitureCollisionDraftContract?.floorDraftCounts,
  { A1: 32, A2: 0, A3: 42 },
  "furniture collision source draft counts"
);
assertJsonEqual(
  layout.furnitureCollisionDraftContract?.importedCollisionCounts,
  { A1: 28, A2: 0, A3: 37 },
  "furniture collision imported counts"
);
assert(
  layout.furnitureCollisionDraftContract?.ignoredClickRectIds?.length === 9,
  "furniture collision import must retain all nine filtered 4x4 click points"
);

assertJsonEqual(topology.floors?.map((floor) => floor.id), expectedFloors, "active topology floors");
assertJsonEqual(topology.floors?.map((floor) => floor.basePlateId), expectedAssets, "active topology base plates");
assertJsonEqual(layout.floors?.map((floor) => floor.storyFloor), expectedFloors, "layout story floors");
assertJsonEqual(layout.floors?.map((floor) => floor.displayFloor), [1, 2, 3], "layout display floors");
assertJsonEqual(layout.floors?.map((floor) => floor.assetId), expectedAssets, "layout base plates");
assertJsonEqual(layout.floors?.map((floor) => floor.checkpoint), expectedCheckpoints, "layout checkpoints");

assert(layout.transportCore?.elevators?.length === 1, "layout must define one logical elevator");
assert(layout.transportCore?.stairs?.length === 1, "layout must define one logical stair");
assertJsonEqual(layout.transportCore?.elevators?.[0]?.storyFloors, expectedFloors, "logical elevator floors");
assertJsonEqual(topology.transport?.elevator?.storyFloors, expectedFloors, "topology elevator floors");
assertJsonEqual(topology.transport?.stair?.storyFloors, expectedFloors, "topology stair floors");

const globalIds = new Map();
const floorByStory = new Map();
for (const floor of layout.floors ?? []) {
  floorByStory.set(floor.storyFloor, floor);
  const label = `layout.${floor.storyFloor}`;
  const counts = expectedFloorCounts[floor.storyFloor];
  assert(counts, `${label} is not an active floor`);
  assert(floor.staticCollisions?.length === counts?.collisions, `${label} collision count mismatch`);
  assert(floor.walkableRegions?.length === counts?.walkable, `${label} walkable count mismatch`);
  assert(floor.foregroundOcclusions?.length === counts?.occlusions, `${label} occlusion count mismatch`);
  assert(
    floor.staticCollisions.filter((collision) => collision.id.includes("_furniture_")).length
      === layout.furnitureCollisionDraftContract.importedCollisionCounts[floor.storyFloor],
    `${label} furniture collision count mismatch`
  );
  registerId(floor.safeSpawn, `${label}.safeSpawn`);
  registerId(floor.elevator, `${label}.elevator`);

  const expectedElevator = expectedElevators[floor.storyFloor];
  assert(floor.elevator?.id === expectedElevator?.id, `${label} floor-specific elevator id mismatch`);
  assert(
    floor.elevator?.sourceAnnotationId === expectedElevator?.sourceAnnotationId,
    `${label} floor-specific elevator annotation mismatch`
  );
  assertJsonEqual(floor.elevator?.visibleBounds, expectedElevator?.visibleBounds, `${label} elevator visibleBounds`);
  assertJsonEqual(floor.elevator?.travelBounds, expectedElevator?.visibleBounds, `${label} elevator travelBounds`);
  assertJsonEqual(floor.elevator?.doorCenter, expectedElevator?.doorCenter, `${label} elevator doorCenter`);
  assert(
    floor.elevator?.standPosition?.x === expectedElevator?.doorCenter.x,
    `${label} elevator stand must use the floor-specific center`
  );
  assert(
    floor.elevator?.arrivalPosition?.x === expectedElevator?.doorCenter.x,
    `${label} elevator arrival must use the floor-specific center`
  );
  assert(floor.elevator?.doorCenter?.x !== 836, `${label} must not restore shared elevator x=836`);

  for (const collision of floor.staticCollisions ?? []) {
    registerId(collision, `${label}.staticCollisions`);
    validateRect(collision, `${label}.${collision.id}`, topology.worldSize);
    assert(
      collision.sourceAnnotationId?.startsWith(`${floor.storyFloor.toLowerCase()}-ann-`),
      `${label}.${collision.id} must retain its manual source annotation`
    );
    assert(
      !collision.id.includes("_furniture_") || collision.width !== 4 || collision.height !== 4,
      `${label}.${collision.id} must not retain a click-only 4x4 draft`
    );
  }
  for (const walkable of floor.walkableRegions ?? []) {
    registerId(walkable, `${label}.walkableRegions`);
    validateRect(walkable, `${label}.${walkable.id}`, topology.worldSize);
    for (const collision of floor.staticCollisions ?? []) {
      assert(
        !rectsOverlap(walkable, collision),
        `${label} required walkable ${walkable.id} overlaps collision ${collision.id}`
      );
    }
  }
  for (const occlusion of floor.foregroundOcclusions ?? []) {
    registerId(occlusion, `${label}.foregroundOcclusions`);
    validateRect(occlusion.maskBounds, `${label}.${occlusion.id}.maskBounds`, topology.worldSize);
    assert(
      occlusion.renderMode === "foot_behind_baseline",
      `${label}.${occlusion.id} must use foot_behind_baseline`
    );
    assert(
      occlusion.baselineY === occlusion.maskBounds.y + occlusion.maskBounds.height,
      `${label}.${occlusion.id} baseline must equal mask bottom`
    );
  }
  for (const anchor of floor.anchors ?? []) {
    registerId(anchor, `${label}.anchors`);
    validateRect(anchor.bounds, `${label}.${anchor.id}.bounds`, topology.worldSize);
    assert(!forbiddenActiveIds.has(anchor.id), `${label} still exposes removed legacy anchor ${anchor.id}`);
  }
  for (const landing of floor.stairLandings ?? []) {
    registerId(landing, `${label}.stairLandings`);
    validateRect(landing.bounds, `${label}.${landing.id}.bounds`, topology.worldSize);
    validateClearPoint(landing.standPosition, floor.staticCollisions, `${label}.${landing.id}.standPosition`, 0);
    validateClearPoint(landing.arrivalPosition, floor.staticCollisions, `${label}.${landing.id}.arrivalPosition`, 0);
  }
  validateClearPoint(floor.safeSpawn, floor.staticCollisions, `${label}.safeSpawn`, 0);
  validateClearPoint(floor.elevator.standPosition, floor.staticCollisions, `${label}.elevator.standPosition`, 0);
  validateClearPoint(floor.elevator.arrivalPosition, floor.staticCollisions, `${label}.elevator.arrivalPosition`, 0);
}

const a1 = floorByStory.get("A1");
const a2 = floorByStory.get("A2");
for (const [collisionId, occlusionId, annotationId] of [
  ["a1_air_wall_north_portrait_west_lip", "a1_foreground_014", "a1-ann-014"],
  ["a1_air_wall_north_portrait_east_lip", "a1_foreground_015", "a1-ann-015"],
  ["a1_air_wall_005", "a1_classroom_partition_face", "a1-ann-005"]
]) {
  const collision = a1?.staticCollisions?.find((entry) => entry.id === collisionId);
  const occlusion = a1?.foregroundOcclusions?.find((entry) => entry.id === occlusionId);
  assert(collision?.sourceAnnotationId === annotationId, `${collisionId} source annotation mismatch`);
  assert(occlusion?.sourceAnnotationId === annotationId, `${occlusionId} source annotation mismatch`);
  assert(collision.x === occlusion.maskBounds.x && collision.width === occlusion.maskBounds.width,
    `${collisionId} must preserve the wall face source span`);
  assert(collision.y === occlusion.baselineY
    && collision.y === occlusion.maskBounds.y + occlusion.maskBounds.height,
    `${collisionId} must stop feet at the wall base, not at its top trim`);
  assert(occlusion.playerRevealAlpha === 0.22, `${occlusionId} covered player reveal`);
  validateClearPoint({ x: collision.x + 22, y: occlusion.maskBounds.y + 28 },
    a1.staticCollisions, `${occlusionId} walk behind top trim`, 0);
}
for (const [floorId, collisionIds] of [
  ["A2", ["a2_air_wall_006", "a2_air_wall_007", "a2_air_wall_010", "a2_air_wall_011"]],
  ["A3", ["a3_air_wall_009", "a3_air_wall_010"]]
]) {
  const floor = floorByStory.get(floorId);
  for (const collisionId of collisionIds) {
    assert(
      floor?.staticCollisions?.some((entry) => entry.id === collisionId),
      `${floorId} north room wall lip ${collisionId} must remain collidable`
    );
  }
}
for (const [collisionId, occlusionId, annotationId] of [
  ["a2_air_wall_020", "a2_foreground_020", "a2-ann-020"],
  ["a2_air_wall_021", "a2_foreground_021", "a2-ann-021"],
  ["a2_air_wall_023", "a2_foreground_023", "a2-ann-023"],
  ["a2_air_wall_024", "a2_foreground_024", "a2-ann-024"],
  ["a2_air_wall_025", "a2_foreground_025", "a2-ann-025"]
]) {
  const collision = a2?.staticCollisions?.find((entry) => entry.id === collisionId);
  const occlusion = a2?.foregroundOcclusions?.find((entry) => entry.id === occlusionId);
  assert(collision?.sourceAnnotationId === annotationId, `${collisionId} source annotation mismatch`);
  assert(occlusion?.sourceAnnotationId === annotationId, `${occlusionId} source annotation mismatch`);
  assertJsonEqual(rectOnly(collision), occlusion?.maskBounds, `${collisionId} must match ${occlusionId}`);
}
assert(
  !a2?.staticCollisions?.some((entry) => entry.id === "a2_air_wall_022"),
  "A2 annotation 022 was not selected as an air wall"
);
const room202FootLimit = a2?.staticCollisions?.find(
  (entry) => entry.id === "a2_air_wall_room202_blackboard_foot_limit"
);
assert(
  room202FootLimit?.sourceAnnotationId === "a2-ann-031",
  "A2 room 202 foot limit must retain the user-marked browser line provenance"
);
assertJsonEqual(
  rectOnly(room202FootLimit),
  { x: 1166, y: 107, width: 432, height: 19 },
  "A2 room 202 blackboard foot-limit collision"
);
assertJsonEqual(
  room202FootLimit?.visualBoundary,
  {
    kind: "foot_box_north_edge",
    provenance: "browser_comment_2026_09_02",
    sourceLineY: 126
  },
  "A2 room 202 user-marked foot boundary"
);
const room202LeftWall = a2?.staticCollisions?.find((entry) => entry.id === "a2_air_wall_009");
const room202RightWall = a2?.staticCollisions?.find((entry) => entry.id === "a2_air_wall_012");
assert(
  room202FootLimit?.x === room202LeftWall?.x + room202LeftWall?.width
    && room202FootLimit.x + room202FootLimit.width === room202RightWall?.x,
  "A2 room 202 foot limit must seal the full clear span between both side walls"
);
assert(
  room202FootLimit.y + room202FootLimit.height === room202FootLimit.visualBoundary.sourceLineY,
  "A2 room 202 player foot-box north edge must stop exactly on the user-marked line"
);
for (const [walkableId, occlusionId, annotationId] of [
  ["a1_walkable_025", "a1_north_portrait_wall_west_front", "a1-ann-025"],
  ["a1_walkable_026", "a1_north_portrait_wall_east_front", "a1-ann-026"]
]) {
  const walkable = a1?.walkableRegions?.find((entry) => entry.id === walkableId);
  const occlusion = a1?.foregroundOcclusions?.find((entry) => entry.id === occlusionId);
  assert(walkable?.sourceAnnotationId === annotationId, `${walkableId} source annotation mismatch`);
  assert(occlusion?.sourceAnnotationId === annotationId, `${occlusionId} source annotation mismatch`);
  assert(occlusion?.coversWalkableRegionId === walkableId, `${occlusionId} must cover ${walkableId}`);
  assertJsonEqual(occlusion?.maskBounds, rectOnly(walkable), `${walkableId} matching foreground crop`);
  for (const collision of a1?.staticCollisions ?? []) {
    assert(!rectsOverlap(walkable, collision), `${walkableId} must stay collision-free behind foreground`);
  }
}
const bakeryDoor = a1?.walkableRegions?.find((entry) => entry.id === "a1_bakery_doorway_02");
assertJsonEqual(
  rectOnly(bakeryDoor),
  { x: 490, y: 514, width: 41, height: 263 },
  "A1 bakery doorway"
);
const frontDeskCounterCollision = a1?.staticCollisions?.find(
  (entry) => entry.id === "a1_air_wall_front_desk_counter"
);
const frontDeskCounterOcclusion = a1?.foregroundOcclusions?.find(
  (entry) => entry.id === "a1_foreground_016"
);
const frontDeskAnchor = a1?.anchors?.find(
  (entry) => entry.id === "a1_front_desk_attendant"
);
assert(
  frontDeskCounterCollision?.sourceAnnotationId === "a1-ann-016",
  "A1 front desk counter collision must retain annotation 016 provenance"
);
assertJsonEqual(
  rectOnly(frontDeskCounterCollision),
  { x: 758, y: 633, width: 179, height: 26 },
  "A1 front desk counter collision"
);
assert(
  frontDeskCounterCollision.x === frontDeskCounterOcclusion?.maskBounds?.x
    && frontDeskCounterCollision.width === frontDeskCounterOcclusion?.maskBounds?.width
    && frontDeskCounterCollision.y >= frontDeskCounterOcclusion?.maskBounds?.y
    && frontDeskCounterCollision.y + frontDeskCounterCollision.height
      === frontDeskCounterOcclusion?.baselineY,
  "A1 front desk collision must cover the annotated counter facade through its occlusion baseline"
);
assert(
  frontDeskCounterCollision.x === frontDeskAnchor?.bounds?.x
    && frontDeskCounterCollision.width === frontDeskAnchor?.bounds?.width
    && frontDeskCounterCollision.y >= frontDeskAnchor?.bounds?.y
    && frontDeskCounterCollision.y + frontDeskCounterCollision.height
      === frontDeskAnchor?.bounds?.y + frontDeskAnchor?.bounds?.height,
  "A1 front desk collision must remain inside the interaction anchor and end at its lower edge"
);
const bakeryCounterCollision = a1?.staticCollisions?.find(
  (entry) => entry.id === "a1_air_wall_bakery_counter"
);
const bakeryCounterOcclusion = a1?.foregroundOcclusions?.find(
  (entry) => entry.id === "a1_foreground_018"
);
assert(
  bakeryCounterCollision?.sourceAnnotationId === "a1-ann-018",
  "A1 bakery counter collision must retain annotation 018 provenance"
);
assertJsonEqual(
  rectOnly(bakeryCounterCollision),
  { x: 80, y: 292, width: 397, height: 90 },
  "A1 bakery counter collision"
);
assert(
  bakeryCounterCollision.x === bakeryCounterOcclusion?.maskBounds?.x
    && bakeryCounterCollision.y === bakeryCounterOcclusion?.maskBounds?.y
    && bakeryCounterCollision.width === bakeryCounterOcclusion?.maskBounds?.width
    && bakeryCounterCollision.y + bakeryCounterCollision.height
      === bakeryCounterOcclusion?.baselineY - 5,
  "A1 bakery counter collision must follow the visible counter and preserve the queue aisle"
);

const classroom104TeachingLineCollision = a1?.staticCollisions?.find(
  (entry) => entry.id === "a1_air_wall_classroom_104_teaching_line"
);
const classroom104BlackboardAnchor = a1?.anchors?.find(
  (entry) => entry.id === "a1_classroom_104_blackboard_residual"
);
assert(
  classroom104TeachingLineCollision?.sourceAnnotationId === "a1-ann-020",
  "A1 classroom 104 teaching-line collision must retain lectern annotation 020 provenance"
);
assertJsonEqual(
  rectOnly(classroom104TeachingLineCollision),
  { x: 1278, y: 229, width: 290, height: 19 },
  "A1 classroom 104 teaching-line collision"
);
const classroom104SouthEdge = (
  classroom104TeachingLineCollision.y + classroom104TeachingLineCollision.height
);
const classroom104FootCenterStopY = (
  classroom104SouthEdge + layout.playerFootBoxContract.worldFootBox.height / 2
);
assert(
  classroom104FootCenterStopY === 255.3125,
  "A1 classroom 104 player foot center must stop at the authored south-side limit"
);
assert(
  classroom104FootCenterStopY - (
    classroom104BlackboardAnchor.bounds.y + classroom104BlackboardAnchor.bounds.height
  ) <= 96,
  "A1 classroom 104 blackboard must remain reachable from the marked teaching line"
);

const bakeryRuntime = layout.bakeryRuntime;
assert(bakeryRuntime?.storyFloor === "A1", "bakery runtime must use A1 source coordinates");
assert(bakeryRuntime?.statePlateId === "a1_1225_bakery", "bakery runtime must bind only the 12:25 plate");
assert(
  bakeryRuntime?.targetEntities?.length === expectedBakeryRuntimeTargets.length,
  "bakery runtime must define exactly three independent targets"
);
expectedBakeryRuntimeTargets.forEach((expected, index) => {
  const target = bakeryRuntime?.targetEntities?.[index];
  assert(target?.targetId === expected.targetId, `bakery target ${index} targetId mismatch`);
  assert(target?.entityId === expected.entityId, `bakery target ${expected.targetId} entityId mismatch`);
  assertJsonEqual(target?.installationBounds, expected.installationBounds, `${expected.targetId} installation bounds`);
  assertJsonEqual(target?.standPosition, expected.standPosition, `${expected.targetId} stand position`);
  assert(target?.proximity === expected.proximity, `${expected.targetId} proximity mismatch`);
  validateRect(target?.installationBounds, `bakeryRuntime.${expected.targetId}.installationBounds`, topology.worldSize);
  validateClearPoint(
    target?.standPosition,
    [
      ...(a1?.staticCollisions ?? []),
      ...(layout.physicalDeltas?.find((delta) => delta.id === "a1_midday_queue_rails")?.collisionBounds ?? [])
    ],
    `bakeryRuntime.${expected.targetId}.standPosition`,
    0
  );
  registerId({ id: target?.targetId }, "layout.bakeryRuntime.targetEntities");
});
const bakeryTargetIds = new Set(bakeryRuntime?.targetEntities?.map((target) => target.targetId) ?? []);
for (const floor of layout.floors ?? []) {
  for (const anchor of floor.anchors ?? []) {
    assert(
      !bakeryTargetIds.has(anchor.id),
      `${anchor.id} must not reuse a baked layout anchor for a Task 8 runtime target`
    );
  }
}
const hourVisual = bakeryRuntime?.targetEntities?.find(
  (target) => target.targetId === "a1_bakery_hour_hand_pickup"
)?.visual;
assertJsonEqual(
  hourVisual && {
    texture: hourVisual.texture,
    frame: hourVisual.frame,
    pivot: hourVisual.pivot,
    uniformScale: hourVisual.uniformScale,
    sourceInteractionBounds: hourVisual.sourceInteractionBounds,
    sourceCell: hourVisual.sourceCell,
    sourcePivot: hourVisual.sourcePivot
  },
  {
    texture: "chapter4_story_items",
    frame: "old_clock_hour_hand",
    pivot: { x: 294, y: 345 },
    uniformScale: 0.1,
    sourceInteractionBounds: { x: 402, y: 92, width: 330, height: 379 },
    sourceCell: { x: 384, y: 0, width: 384, height: 512 },
    sourcePivot: { x: 460, y: 415 }
  },
  "bakery hour-hand visual contract"
);
if (hourVisual) {
  const sourceRight = hourVisual.sourceInteractionBounds.x + hourVisual.sourceInteractionBounds.width;
  const sourceBottom = hourVisual.sourceInteractionBounds.y + hourVisual.sourceInteractionBounds.height;
  const derivedHourBounds = {
    x: Math.floor(
      hourVisual.pivot.x
      + (hourVisual.sourceInteractionBounds.x - hourVisual.sourcePivot.x) * hourVisual.uniformScale
    ),
    y: Math.floor(
      hourVisual.pivot.y
      + (hourVisual.sourceInteractionBounds.y - hourVisual.sourcePivot.y) * hourVisual.uniformScale
    ),
    width: 0,
    height: 0
  };
  const right = Math.ceil(
    hourVisual.pivot.x + (sourceRight - hourVisual.sourcePivot.x) * hourVisual.uniformScale
  );
  const bottom = Math.ceil(
    hourVisual.pivot.y + (sourceBottom - hourVisual.sourcePivot.y) * hourVisual.uniformScale
  );
  derivedHourBounds.width = right - derivedHourBounds.x;
  derivedHourBounds.height = bottom - derivedHourBounds.y;
  assertJsonEqual(
    derivedHourBounds,
    expectedBakeryRuntimeTargets[2].installationBounds,
    "bakery hour-hand outward-rounded runtime bounds"
  );
}
assertJsonEqual(
  bakeryRuntime?.baker,
  {
    textureFile: "src/assets/rpg/npcs/canteen/counter_aunties_2frame.png",
    framePair: 3,
    frames: [6, 7],
    origin: { x: 0.5, y: 1 },
    uniformScale: 0.52,
    position: { x: 260, y: 340 },
    visibleSourceHeight: 80,
    collision: false,
    foregroundOcclusionId: "a1_foreground_018",
    activePhases: ["bakery_hour_hand", "morning_checkin"]
  },
  "bakery baker reuse contract"
);
assert(
  a1?.foregroundOcclusions?.some((occlusion) => occlusion.id === bakeryRuntime?.baker?.foregroundOcclusionId),
  "bakery baker must name an active counter foreground occlusion"
);
assert(
  bakeryRuntime?.crowd?.texture === "student_walk"
  && bakeryRuntime?.crowd?.collisionProfile === "playerFootBoxContract.worldFootBox"
  && bakeryRuntime?.crowd?.origin?.x === 0.5
  && bakeryRuntime?.crowd?.origin?.y === 1
  && bakeryRuntime?.crowd?.displayScale === layout.playerFootBoxContract?.displayScale,
  "bakery crowd must reuse the finale student atlas, Scene origin/scale and player foot collision profile"
);
assert(
  bakeryRuntime?.crowd?.routes?.length === expectedBakeryCrowdRoutes.length,
  "bakery crowd must contain exactly three routes"
);
expectedBakeryCrowdRoutes.forEach(([id, fromX, fromY, toX, toY, speed, pause], index) => {
  const route = bakeryRuntime?.crowd?.routes?.[index];
  assertJsonEqual(
    route && [route.id, route.from.x, route.from.y, route.to.x, route.to.y, route.speed, route.endpointPauseMs],
    [id, fromX, fromY, toX, toY, speed, pause],
    `bakery crowd route ${id}`
  );
  registerId(route, "layout.bakeryRuntime.crowd.routes");
});

const expectedBakeryWalkabilityRoutes = [
  {
    id: "bakery_direct_y560",
    waypoints: [
      { x: 620, y: 560 },
      { x: 560, y: 560 },
      { x: 510.5, y: 560 },
      { x: 477, y: 560 },
      { x: 477, y: 470 },
      { x: 477, y: 390 },
      { x: 374, y: 390 },
      { x: 294, y: 390 }
    ]
  },
  {
    id: "bakery_alternate_y748",
    waypoints: [
      { x: 620, y: 748 },
      { x: 560, y: 748 },
      { x: 510.5, y: 748 },
      { x: 477, y: 748 },
      { x: 477, y: 730 },
      { x: 477, y: 470 },
      { x: 477, y: 390 },
      { x: 374, y: 390 },
      { x: 294, y: 390 }
    ]
  }
];
assertJsonEqual(
  bakeryRuntime?.walkabilityRoutes,
  expectedBakeryWalkabilityRoutes,
  "bakery direct and alternate mapper waypoints"
);
const footBox = layout.playerFootBoxContract?.worldFootBox;
assertJsonEqual(footBox, { width: 19.5, height: 14.625 }, "bakery route player foot box");
const bakeryNpcArcadeBody = deriveArcadeBodyGeometry({
  frameSize: layout.playerFootBoxContract?.frameSize,
  sourceBody: layout.playerFootBoxContract?.sourceFootBox,
  origin: bakeryRuntime?.crowd?.origin,
  displayScale: bakeryRuntime?.crowd?.displayScale
});
assertApprox(bakeryNpcArcadeBody?.leftOffset, -9.75, "bakery NPC Arcade body left offset");
assertApprox(bakeryNpcArcadeBody?.topOffset, -17.225, "bakery NPC Arcade body top offset");
assertApprox(bakeryNpcArcadeBody?.width, 19.5, "bakery NPC Arcade body width");
assertApprox(bakeryNpcArcadeBody?.height, 14.625, "bakery NPC Arcade body height");
assertApprox(bakeryNpcArcadeBody?.rightOffset, 9.75, "bakery NPC Arcade body right offset");
assertApprox(bakeryNpcArcadeBody?.bottomOffset, -2.6, "bakery NPC Arcade body bottom inset");
const queueCollisions = layout.physicalDeltas?.find(
  (delta) => delta.id === "a1_midday_queue_rails"
)?.collisionBounds ?? [];
const fixedAndQueue = [...(a1?.staticCollisions ?? []), ...queueCollisions];
const fixedQueueAndNpcSweeps = [
  ...fixedAndQueue,
  ...(bakeryRuntime?.crowd?.routes ?? []).map((route) => (
    bakeryNpcSweptFootRect(route, bakeryNpcArcadeBody)
  ))
];
for (const route of bakeryRuntime?.walkabilityRoutes ?? []) {
  registerId(route, "layout.bakeryRuntime.walkabilityRoutes");
  assert(
    sampledWaypointRouteIsClear(route.waypoints, fixedQueueAndNpcSweeps, footBox, 2),
    `${route.id} must clear fixed, queue and every crowd collider sweep at 2px sampling`
  );
}
assert(
  (bakeryRuntime?.walkabilityRoutes ?? []).every((route) => (
    route.waypoints[0]?.x === 620
    && Boolean(bakeryDoor)
    && route.waypoints.some((point) => point.x === 510.5 && pointInsideRect(point, bakeryDoor))
    && route.waypoints.some((point) => point.x === 477)
    && route.waypoints.at(-1)?.x === 294
    && route.waypoints.at(-1)?.y === 390
  )),
  "both bakery routes must preserve east gap x=477 and reach the conveyor/hour-hand stand point"
);

const room204AssertionStart = assertionCount;
const room204Runtime = layout.room204Runtime;
assert(room204Runtime?.storyFloor === "A2", "room204 runtime must use A2 source coordinates");
assert(room204Runtime?.statePlateId === "a2_1850_evening", "room204 runtime must bind the 18:50 state plate");
assert(room204Runtime?.approximate === true, "room204 runtime must retain approximate=true calibration status");
assert(room204Runtime?.transform === "uniform_scale_only", "room204 runtime must allow uniform scale only");
assert(room204Runtime?.uniformScale === 0.25, "room204 runtime uniform scale must remain 0.25");
assertJsonEqual(
  room204Runtime?.pairOffsets,
  { desk: { x: 0, y: -28 }, chair: { x: 0, y: 0 } },
  "room204 desk/chair pair offsets"
);
validateRect(room204Runtime?.roomBounds, "room204Runtime.roomBounds", topology.worldSize);
validateRect(room204Runtime?.residualGroupBounds, "room204Runtime.residualGroupBounds", topology.worldSize);
assert(
  rectContainsRect(room204Runtime?.roomBounds, room204Runtime?.residualGroupBounds),
  "room204 residual group bounds must remain inside room bounds"
);

const room204Slots = room204Runtime?.slotTargets ?? [];
const room204Pieces = room204Runtime?.initialPiecePairs ?? [];
const room204Tables = room204Runtime?.discussionTables ?? [];
assert(room204Slots.length === 12, "room204 runtime must define exactly 12 placement slots");
assert(room204Pieces.length === 12, "room204 runtime must define exactly 12 desk/chair pieces");
assert(room204Tables.length === 4, "room204 runtime must define exactly four discussion tables");
assertJsonEqual(room204Slots.map((slot) => slot.slotId), expectedRoom204SlotIds, "room204 slot order");
assertJsonEqual(room204Pieces.map((piece) => piece.pieceId), expectedRoom204PieceIds, "room204 piece order");
assertJsonEqual(room204Tables.map((table) => table.id), expectedRoom204DiscussionTableIds, "room204 table order");
assert(
  new Set(room204Slots.map((slot) => slot.slotId)).size === 12,
  "room204 slot ids must be unique"
);
assert(
  new Set(room204Pieces.map((piece) => piece.pieceId)).size === 12,
  "room204 piece ids must be unique"
);
for (const slot of room204Slots) {
  validateRect(slot.bounds, `room204Runtime.${slot.slotId}.bounds`, topology.worldSize);
  assertJsonEqual(
    slot.bounds && { width: slot.bounds.width, height: slot.bounds.height },
    { width: 20, height: 20 },
    `${slot.slotId} target size`
  );
  assertJsonEqual(
    slot.center,
    slot.bounds && {
      x: slot.bounds.x + slot.bounds.width / 2,
      y: slot.bounds.y + slot.bounds.height / 2
    },
    `${slot.slotId} center/bounds alignment`
  );
  assert(slot.orientation === "up", `${slot.slotId} must accept only the up orientation`);
  assert(slot.approximate === true, `${slot.slotId} must retain approximate=true`);
  assert(
    rectContainsRect(room204Runtime?.roomBounds, slot.bounds),
    `${slot.slotId} must remain inside room204 bounds`
  );
}

assertSetEqual(
  room204Pieces.map((piece) => piece.deskFrame),
  expectedRoom204DeskFrames,
  "room204 desk frame coverage"
);
assertSetEqual(
  room204Pieces.map((piece) => piece.chairFrame),
  expectedRoom204ChairFrames,
  "room204 chair frame coverage"
);
assertSetEqual(
  room204Pieces.map((piece) => piece.residualFrame),
  expectedRoom204ResidualFrames,
  "room204 residual frame coverage"
);
const room204TableById = new Map(room204Tables.map((table) => [table.id, table]));
for (const piece of room204Pieces) {
  assert(piece.approximate === true, `${piece.pieceId} must retain approximate=true`);
  assert(
    piece.angle === 90 || piece.angle === -90,
    `${piece.pieceId} initial angle must be a calibrated +/-90 degrees`
  );
  assert(
    validatePoint(piece.position, `room204Runtime.${piece.pieceId}.position`, topology.worldSize),
    `${piece.pieceId} must define a valid initial position`
  );
  assert(
    pointInsideRect(piece.position, room204Runtime?.roomBounds),
    `${piece.pieceId} initial pivot must remain inside room204 bounds`
  );
  assert(
    room204TableById.get(piece.discussionTableId)?.pieceIds?.includes(piece.pieceId),
    `${piece.pieceId} discussion-table membership must be bidirectional`
  );
}
const tablePieceMembership = [];
for (const table of room204Tables) {
  assert(table.frame === table.id, `${table.id} must bind its matching manifest frame`);
  assert(table.approximate === true, `${table.id} must retain approximate=true`);
  assert(table.angle === 90, `${table.id} calibrated angle must remain 90 degrees`);
  assert(table.pieceIds?.length === 3, `${table.id} must own exactly three movable pairs`);
  assert(
    validatePoint(table.position, `room204Runtime.${table.id}.position`, topology.worldSize),
    `${table.id} must define a valid initial position`
  );
  for (const pieceId of table.pieceIds ?? []) {
    tablePieceMembership.push(pieceId);
    assert(
      expectedRoom204PieceIds.includes(pieceId),
      `${table.id} references unknown piece ${pieceId}`
    );
  }
}
assertSetEqual(tablePieceMembership, expectedRoom204PieceIds, "room204 discussion-table piece partition");
assert(
  tablePieceMembership.length === new Set(tablePieceMembership).size,
  "room204 discussion tables must not share movable pieces"
);

assert(room204Runtime?.podium?.frame === "podium", "room204 podium must bind the podium manifest frame");
assert(room204Runtime?.podium?.fixedAxisReference === true, "room204 podium must remain the fixed axis reference");
assert(room204Runtime?.podium?.approximate === true, "room204 podium must retain approximate=true");
assert(
  validatePoint(room204Runtime?.podium?.position, "room204Runtime.podium.position", topology.worldSize),
  "room204 podium must define a valid fixed position"
);
validateRect(room204Runtime?.podium?.drawerBounds, "room204Runtime.podium.drawerBounds", topology.worldSize);
assertJsonEqual(
  room204Runtime?.walkability?.playerFootBox,
  { width: 19.5, height: 14.625 },
  "room204 walkability player foot box"
);
assertJsonEqual(room204Runtime?.walkability?.sampleSteps, [2, 4], "room204 walkability sample steps");
assertJsonEqual(
  room204Runtime?.walkability?.verticalAisleCenters,
  [132.5, 230, 327.5],
  "room204 vertical aisle centers"
);
assertJsonEqual(
  room204Runtime?.walkability?.verticalRange,
  { fromY: 600, toY: 792 },
  "room204 vertical aisle range"
);
assertJsonEqual(
  room204Runtime?.walkability?.horizontalConnector,
  { y: 647, fromX: 132.5, toX: 327.5 },
  "room204 horizontal connector"
);
assert(
  room204Runtime?.walkability?.verticalAisleCenters?.every((x) => (
    x >= room204Runtime.walkability.horizontalConnector.fromX
    && x <= room204Runtime.walkability.horizontalConnector.toX
  )),
  "room204 horizontal connector must cross all three vertical aisle centers"
);
assert(
  room204Runtime?.walkability?.horizontalConnector?.y >= room204Runtime?.walkability?.verticalRange?.fromY
  && room204Runtime?.walkability?.horizontalConnector?.y <= room204Runtime?.walkability?.verticalRange?.toY,
  "room204 horizontal connector must lie inside the sampled vertical range"
);

const room204FurnitureSheet = finaleManifest.spritesheets?.find(
  (sheet) => sheet.id === "chapter4_room204_furniture"
);
const room204ResidualSheet = finaleManifest.spritesheets?.find(
  (sheet) => sheet.id === "chapter4_room204_residual"
);
assert(Boolean(room204FurnitureSheet), "finale manifest must define chapter4_room204_furniture");
assert(Boolean(room204ResidualSheet), "finale manifest must define chapter4_room204_residual");
assert(room204FurnitureSheet?.activeChapter4Contract === true, "room204 furniture sheet must remain active");
assert(room204ResidualSheet?.activeChapter4Contract === true, "room204 residual sheet must remain active");
const room204FurnitureFrames = new Map(
  (room204FurnitureSheet?.frames ?? []).map((frame) => [frame.id, frame])
);
const room204ResidualFrames = new Map(
  (room204ResidualSheet?.frames ?? []).map((frame) => [frame.id, frame])
);
for (const frameId of [
  ...expectedRoom204DeskFrames,
  ...expectedRoom204ChairFrames,
  ...expectedRoom204DiscussionTableIds,
  "podium"
]) {
  const frame = room204FurnitureFrames.get(frameId);
  assert(Boolean(frame), `room204 furniture manifest frame ${frameId} is missing`);
  assert(frame?.approximate === true, `${frameId} manifest calibration must retain approximate=true`);
  assert(frame?.pivot?.coordinateSpace === "source_sheet", `${frameId} pivot must use source_sheet coordinates`);
  assert(frame?.collisionType === "foot_box", `${frameId} must use a foot_box collision`);
  assert(frame?.collisionBounds?.length === 1, `${frameId} must define exactly one manifest collision bound`);
  const collision = frame?.collisionBounds?.[0];
  assert(collision?.coordinateSpace === "source_sheet", `${frameId} collision must use source_sheet coordinates`);
  if (collision?.bounds && room204FurnitureSheet?.sourceSize) {
    validateRect(
      collision.bounds,
      `finaleManifest.${frameId}.collisionBounds[0]`,
      room204FurnitureSheet.sourceSize
    );
  }
}
room204Pieces.forEach((piece, index) => {
  const residual = room204ResidualFrames.get(piece.residualFrame);
  const slot = room204Slots[index];
  assert(Boolean(residual), `room204 residual manifest frame ${piece.residualFrame} is missing`);
  assert(residual?.approximate === true, `${piece.residualFrame} manifest calibration must retain approximate=true`);
  assert(residual?.collisionType === "none", `${piece.residualFrame} must remain non-colliding`);
  assert(residual?.collisionBounds?.length === 0, `${piece.residualFrame} must not define collision bounds`);
  assertJsonEqual(
    residual?.worldTarget && { x: residual.worldTarget.x, y: residual.worldTarget.y },
    slot?.center,
    `${piece.residualFrame} world target/slot center`
  );
});

const completedPieceSet = new Set(room204Pieces.map((piece) => piece.pieceId));
const hiddenDiscussionTablesAtCompletion = room204Tables.filter((table) => (
  table.pieceIds?.every((pieceId) => completedPieceSet.has(pieceId))
));
assert(
  hiddenDiscussionTablesAtCompletion.length === 4,
  "all four discussion tables must be omitted from completed-state collision geometry"
);
const room204CompletedCollisionEnvelope = [...(floorByStory.get("A2")?.staticCollisions ?? [])];
const podiumCollision = deriveManifestCollisionRect({
  frame: room204FurnitureFrames.get(room204Runtime?.podium?.frame),
  worldPivot: room204Runtime?.podium?.position,
  uniformScale: room204Runtime?.uniformScale,
  angle: 0,
  id: "room204_completed_podium"
});
assert(Boolean(podiumCollision), "room204 fixed podium collider must derive from manifest collisionBounds");
if (podiumCollision) {
  assert(
    rectContainsRect(room204Runtime?.roomBounds, podiumCollision),
    "room204 fixed podium collider must remain inside room bounds"
  );
  room204CompletedCollisionEnvelope.push(podiumCollision);
}
let room204PieceSlotCandidateCount = 0;
for (const slot of room204Slots) {
  for (const piece of room204Pieces) {
    room204PieceSlotCandidateCount += 1;
    for (const [role, frameId] of [["desk", piece.deskFrame], ["chair", piece.chairFrame]]) {
      const offset = room204Runtime?.pairOffsets?.[role];
      const collision = deriveManifestCollisionRect({
        frame: room204FurnitureFrames.get(frameId),
        worldPivot: offset && slot.center
          ? { x: slot.center.x + offset.x, y: slot.center.y + offset.y }
          : null,
        uniformScale: room204Runtime?.uniformScale,
        angle: 0,
        id: `room204_completed_${piece.pieceId}_${slot.slotId}_${role}`
      });
      assert(
        Boolean(collision),
        `${piece.pieceId}/${slot.slotId}/${role} collider must derive from manifest collisionBounds`
      );
      if (collision) {
        assert(
          rectContainsRect(room204Runtime?.roomBounds, collision),
          `${piece.pieceId}/${slot.slotId}/${role} collider must remain inside room bounds`
        );
        room204CompletedCollisionEnvelope.push(collision);
      }
    }
  }
}
assert(
  room204PieceSlotCandidateCount === 144,
  "room204 complete-state envelope must cover all 12x12 legal piece-to-slot candidates"
);
for (const sampleStep of room204Runtime?.walkability?.sampleSteps ?? []) {
  for (const x of room204Runtime?.walkability?.verticalAisleCenters ?? []) {
    assert(
      sampledSegmentIsClear(
        { x, y: room204Runtime.walkability.verticalRange.fromY },
        { x, y: room204Runtime.walkability.verticalRange.toY },
        room204CompletedCollisionEnvelope,
        room204Runtime.walkability.playerFootBox,
        sampleStep
      ),
      `room204 vertical aisle x=${x} must clear every legal complete permutation at ${sampleStep}px sampling`
    );
  }
  assert(
    sampledSegmentIsClear(
      {
        x: room204Runtime.walkability.horizontalConnector.fromX,
        y: room204Runtime.walkability.horizontalConnector.y
      },
      {
        x: room204Runtime.walkability.horizontalConnector.toX,
        y: room204Runtime.walkability.horizontalConnector.y
      },
      room204CompletedCollisionEnvelope,
      room204Runtime.walkability.playerFootBox,
      sampleStep
    ),
    `room204 horizontal connector y=647 must clear every legal complete permutation at ${sampleStep}px sampling`
  );
}
const room204AssertionCount = assertionCount - room204AssertionStart;

const maintenanceRuntime = layout.maintenanceRuntime;
assert(maintenanceRuntime?.storyFloor === "A1", "maintenance runtime must use A1 source coordinates");
assert(maintenanceRuntime?.statePlateId === "a1_2245_maintenance", "maintenance runtime must bind the 22:45 maintenance plate");
assert(maintenanceRuntime?.approximate === true, "maintenance composite calibration must retain approximate=true");
assertJsonEqual(maintenanceRuntime?.pryBar, {
  frame: "short_pry_tool_candidate",
  pivot: { x: 458, y: 710 },
  uniformScale: 0.1,
  approximate: true
}, "maintenance pry-bar visual");
assertJsonEqual(maintenanceRuntime?.cleaningCart, {
  texture: "cleaning_cart",
  position: { x: 1115, y: 716 },
  uniformScale: 0.65,
  visibleBounds: { x: 1088, y: 648, width: 53, height: 68 },
  footBounds: { x: 1089, y: 700, width: 51, height: 16 },
  wheelRegion: {
    coordinateSpace: "cleaning_cart_frame_local",
    sourceFrameSize: { width: 144, height: 128 },
    origin: { x: 0.5, y: 1 },
    bounds: { x: 88, y: 91, width: 28, height: 37 },
    visualRole: "programmatic_wheel_cover_and_wheel_interaction"
  },
  approximate: true
}, "maintenance cleaning-cart runtime");
assertJsonEqual(maintenanceRuntime?.cleaner, {
  animationId: "cleaner_idle",
  position: { x: 1160, y: 716 },
  uniformScale: 0.65,
  footBounds: { x: 1150, y: 708, width: 20, height: 16 },
  approximate: true
}, "maintenance cleaner runtime");
assertJsonEqual(maintenanceRuntime?.repairedPush, {
  animationId: "cleaner_push_cart",
  sourceFrameSize: { width: 192, height: 128 },
  visibleCharacterCrop: { x: 0, y: 0, width: 96, height: 128 },
  flipX: true,
  from: { x: 1138, y: 716 },
  to: { x: 1072, y: 716 },
  durationMs: 900,
  approximate: true
}, "maintenance repaired-cart push");
assertJsonEqual(maintenanceRuntime?.guard && {
  animationId: maintenanceRuntime.guard.animationId,
  position: maintenanceRuntime.guard.position,
  uniformScale: maintenanceRuntime.guard.uniformScale,
  footBox: maintenanceRuntime.guard.footBox,
  initialPreviousWaypointId: maintenanceRuntime.guard.initialPreviousWaypointId,
  initialTargetWaypointId: maintenanceRuntime.guard.initialTargetWaypointId,
  patrolSpeed: maintenanceRuntime.guard.patrolSpeed,
  pursuitSpeed: maintenanceRuntime.guard.pursuitSpeed,
  returnSpeed: maintenanceRuntime.guard.returnSpeed,
  confirmationMs: maintenanceRuntime.guard.confirmationMs,
  sightLossMs: maintenanceRuntime.guard.sightLossMs,
  coneRange: maintenanceRuntime.guard.coneRange,
  coneHalfAngleDegrees: maintenanceRuntime.guard.coneHalfAngleDegrees,
  closeRadius: maintenanceRuntime.guard.closeRadius,
  pauseRangeMs: maintenanceRuntime.guard.pauseRangeMs,
  maxStepMs: maintenanceRuntime.guard.maxStepMs,
  approximate: maintenanceRuntime.guard.approximate
}, {
  animationId: "guard_walk",
  position: { x: 1105, y: 560 },
  uniformScale: 0.65,
  footBox: { width: 20, height: 16 },
  initialPreviousWaypointId: "east_south",
  initialTargetWaypointId: "west_south",
  patrolSpeed: 84,
  pursuitSpeed: 140,
  returnSpeed: 96,
  confirmationMs: 400,
  sightLossMs: 900,
  coneRange: 220,
  coneHalfAngleDegrees: 36,
  closeRadius: 56,
  pauseRangeMs: [1000, 2000],
  maxStepMs: 50,
  approximate: false
}, "maintenance ordinary-guard rules");

assert(
  maintenanceRuntime?.targetEntities?.length === expectedMaintenanceRuntimeTargets.length,
  "maintenance runtime must define exactly six independent targets"
);
expectedMaintenanceRuntimeTargets.forEach((expected, index) => {
  const target = maintenanceRuntime?.targetEntities?.[index];
  assertJsonEqual(target, expected, `maintenance target ${expected.targetId}`);
  validateRect(target?.installationBounds, `maintenanceRuntime.${expected.targetId}.installationBounds`, topology.worldSize);
  validatePoint(target?.standPosition, `maintenanceRuntime.${expected.targetId}.standPosition`, topology.worldSize);
});
const maintenanceTargetIds = maintenanceRuntime?.targetEntities?.map((target) => target.targetId) ?? [];
const maintenanceEntityIds = maintenanceRuntime?.targetEntities?.map((target) => target.entityId) ?? [];
assert(new Set(maintenanceTargetIds).size === 6, "maintenance target ids must be unique inside the runtime group");
assert(new Set(maintenanceEntityIds).size === 6, "maintenance entity ids must be unique inside the runtime group");

const storyItemSheet = finaleManifest.spritesheets?.find((sheet) => sheet.id === "chapter4_story_items");
const clockStateSheet = finaleManifest.spritesheets?.find((sheet) => sheet.id === "chapter4_clock_states");
const storyItemFrames = new Map((storyItemSheet?.frames ?? []).map((frame) => [frame.id, frame]));
const clockStateFrames = new Map((clockStateSheet?.frames ?? []).map((frame) => [frame.id, frame]));
const pryTarget = maintenanceRuntime?.targetEntities?.find(
  (target) => target.targetId === "a1_bakery_back_pry_bar"
);
const oilTarget = maintenanceRuntime?.targetEntities?.find(
  (target) => target.targetId === "a1_cleaning_cart_oil_bottle"
);
assertJsonEqual(
  deriveManifestInteractionRect({
    frame: storyItemFrames.get(maintenanceRuntime?.pryBar?.frame),
    worldPivot: maintenanceRuntime?.pryBar?.pivot,
    uniformScale: maintenanceRuntime?.pryBar?.uniformScale
  }),
  pryTarget?.installationBounds,
  "maintenance pry-bar outward-rounded manifest interaction bounds"
);
assertJsonEqual(
  deriveManifestInteractionRect({
    frame: storyItemFrames.get(oilTarget?.frame),
    worldPivot: oilTarget?.pivot,
    uniformScale: oilTarget?.uniformScale
  }),
  oilTarget?.installationBounds,
  "maintenance oil outward-rounded manifest interaction bounds"
);
const cartWheelDerivedBounds = deriveFrameLocalInteractionRect({
  worldPivot: maintenanceRuntime?.cleaningCart?.position,
  uniformScale: maintenanceRuntime?.cleaningCart?.uniformScale,
  sourceFrameSize: maintenanceRuntime?.cleaningCart?.wheelRegion?.sourceFrameSize,
  origin: maintenanceRuntime?.cleaningCart?.wheelRegion?.origin,
  sourceLocalBounds: maintenanceRuntime?.cleaningCart?.wheelRegion?.bounds
});
for (const targetId of [
  "a1_cleaning_cart_wheel_inspection",
  "a1_cleaning_cart_wheel_cover",
  "a1_cleaning_cart_wheel"
]) {
  const target = maintenanceRuntime?.targetEntities?.find(
    (candidate) => candidate.targetId === targetId
  );
  assertJsonEqual(
    cartWheelDerivedBounds,
    target?.installationBounds,
    `${targetId} outward-rounded visible cleaning-cart frame-local bounds`
  );
}
const gearTarget = maintenanceRuntime?.targetEntities?.find(
  (target) => target.targetId === "a1_hall_clock_gear"
);
for (const frameId of [gearTarget?.frameBefore, gearTarget?.frameAfter]) {
  const frame = clockStateFrames.get(frameId);
  const worldTrigger = frame?.interactionBounds?.find(
    (interaction) => interaction.id === "a1_world_trigger"
      && interaction.floor === "A1"
      && interaction.coordinateSpace === "world"
  );
  assert(Boolean(frame), `maintenance clock frame ${frameId} must exist`);
  assertJsonEqual(worldTrigger?.bounds, gearTarget?.installationBounds, `${frameId} A1 world trigger`);
}

const finalClockRuntime = layout.finalClockRuntime;
assert(finalClockRuntime?.storyFloor === "A1", "Task11 final clock must use A1 source coordinates");
assert(finalClockRuntime?.statePlateId === "a1_2245_maintenance", "Task11 final clock must stay on the committed 22:45 plate until completion");
assert(finalClockRuntime?.clockFrame === "gear_running", "Task11 final clock must reuse the visible repaired-clock frame");
assertJsonEqual(finalClockRuntime?.presentation, {
  lockAtMs: 0,
  minuteHandAtMs: 240,
  paperFlightAtMs: 680,
  commitAtMs: 1040,
  feedbackAtMs: 1160
}, "Task11 final-clock presentation timeline");
validateRect(finalClockRuntime?.endpoint?.installationBounds, "finalClockRuntime.endpoint.installationBounds", topology.worldSize);
validateRect(finalClockRuntime?.endpoint?.visualHandleBounds, "finalClockRuntime.endpoint.visualHandleBounds", topology.worldSize);
validatePoint(finalClockRuntime?.endpoint?.standPosition, "finalClockRuntime.endpoint.standPosition", topology.worldSize);
const initialEndpointCenter = {
  x: finalClockRuntime.clockCenter.x
    + Math.cos(finalClockRuntime.initialAngleDegrees * Math.PI / 180) * finalClockRuntime.minuteHandRadius,
  y: finalClockRuntime.clockCenter.y
    + Math.sin(finalClockRuntime.initialAngleDegrees * Math.PI / 180) * finalClockRuntime.minuteHandRadius
};
assertJsonEqual({
  x: Math.round(initialEndpointCenter.x - finalClockRuntime.endpoint.visualHandleBounds.width / 2),
  y: Math.round(initialEndpointCenter.y - finalClockRuntime.endpoint.visualHandleBounds.height / 2),
  width: finalClockRuntime.endpoint.visualHandleBounds.width,
  height: finalClockRuntime.endpoint.visualHandleBounds.height
}, finalClockRuntime.endpoint.visualHandleBounds, "Task11 programmatic minute endpoint outward bounds");
assert(
  finalClockRuntime?.endpoint?.visualHandleDerivation?.kind === "visible_programmatic_minute_endpoint_get_bounds"
    && finalClockRuntime.endpoint.visualHandleDerivation.clockFrame === finalClockRuntime.clockFrame
    && finalClockRuntime.endpoint.approximate === false,
  "Task13 minute endpoint must document exact visible getBounds derivation"
);
assert(
  finalClockRuntime.endpoint.boundsDerivation?.kind === "visible_clock_face_drop_envelope"
    && finalClockRuntime.endpoint.boundsDerivation.sourceTargetId === "a1_hall_clock"
    && finalClockRuntime.endpoint.boundsDerivation.hudSafeRule === "accept_visible_clock_face",
  "Task11 minute installation must document the visible clock-face drop envelope"
);
assertJsonEqual(
  finalClockRuntime.endpoint.installationBounds,
  gearTarget.installationBounds,
  "Task11 minute installation must accept the full visible clock face"
);
assert(
  finalClockRuntime.endpoint.visualHandleBounds.width < finalClockRuntime.endpoint.installationBounds.width
    && finalClockRuntime.endpoint.visualHandleBounds.height < finalClockRuntime.endpoint.installationBounds.height,
  "Task11 minute visual handle must remain smaller than its accessible drop envelope"
);

const morningCheckinRuntime = layout.morningCheckinRuntime;
assertJsonEqual({
  storyFloor: morningCheckinRuntime?.storyFloor,
  statePlateId: morningCheckinRuntime?.statePlateId,
  approximate: morningCheckinRuntime?.approximate,
  deskCenter: morningCheckinRuntime?.deskCenter
}, {
  storyFloor: "A1",
  statePlateId: "a1_0755_morning",
  approximate: false,
  deskCenter: { x: 819, y: 646 }
}, "Task13 morning check-in runtime identity");
assert(
  morningCheckinRuntime?.targetEntities?.length === expectedMorningCheckinRuntimeTargets.length,
  "Task13 morning check-in must define exactly the card reader and paper slot"
);
expectedMorningCheckinRuntimeTargets.forEach((expected, index) => {
  const target = morningCheckinRuntime?.targetEntities?.[index];
  assertJsonEqual(target, expected, `Task13 morning check-in target ${expected.targetId}`);
  validateRect(
    target?.installationBounds,
    `morningCheckinRuntime.${expected.targetId}.installationBounds`,
    topology.worldSize
  );
  validateClearPoint(
    target?.standPosition,
    a1?.staticCollisions ?? [],
    `morningCheckinRuntime.${expected.targetId}.standPosition`,
    0
  );
  assert(
    !(a1?.staticCollisions ?? []).some((collision) => (
      rectsOverlap(target?.installationBounds, collision)
    )),
    `Task13 visible target ${expected.targetId} must not overlap an A1 air-wall collider`
  );
  const nearestX = Math.max(
    target.installationBounds.x,
    Math.min(target.standPosition.x, target.installationBounds.x + target.installationBounds.width)
  );
  const nearestY = Math.max(
    target.installationBounds.y,
    Math.min(target.standPosition.y, target.installationBounds.y + target.installationBounds.height)
  );
  assert(
    Math.hypot(target.standPosition.x - nearestX, target.standPosition.y - nearestY)
      <= target.proximity,
    `Task13 stand point for ${expected.targetId} must be within its authored 56px interaction range`
  );
});
assert(
  !rectsOverlap(
    morningCheckinRuntime.targetEntities[0].installationBounds,
    morningCheckinRuntime.targetEntities[1].installationBounds
  ),
  "Task13 card reader and paper slot must retain separate exact runtime envelopes"
);

const lightGridRuntime = layout.lightGridRuntime;
assert(lightGridRuntime?.storyFloor === "A1", "Task11 light grid must use A1 source coordinates");
assert(lightGridRuntime?.statePlateId === "a1_0754_blackout", "Task11 light grid must bind the 07:54 blackout plate");
assertJsonEqual(lightGridRuntime?.panel?.installationBounds, { x: 493, y: 528, width: 67, height: 124 }, "Task11 power panel installation bounds");
assertJsonEqual(lightGridRuntime?.panel?.visibleBoxBounds, { x: 505, y: 540, width: 43, height: 100 }, "Task11 power panel visible box bounds");
validateRect(lightGridRuntime?.panel?.installationBounds, "lightGridRuntime.panel.installationBounds", topology.worldSize);
validateRect(lightGridRuntime?.panel?.visibleBoxBounds, "lightGridRuntime.panel.visibleBoxBounds", topology.worldSize);
assert(
  rectContainsRect(lightGridRuntime.panel.installationBounds, lightGridRuntime.panel.visibleBoxBounds),
  "Task11 visible power box must stay inside its exact installation bounds"
);
assertJsonEqual(
  lightGridRuntime?.visualRegions?.map((region) => region.id),
  ["hall", "west_corridor", "east_corridor", "classroom_zone", "bakery_back_area"],
  "Task11 five authored light-region ids"
);
for (const region of lightGridRuntime?.visualRegions ?? []) {
  validateRect(region.bounds, `lightGridRuntime.${region.id}.bounds`, topology.worldSize);
  assert(
    region.nonColliding === true && region.visualOnly === true && region.approximate === true,
    `Task11 light region ${region.id} must remain approximate visual-only non-collision data`
  );
  assert(
    !(floorByStory.get("A1")?.staticCollisions ?? []).some((collision) => collision.id === region.id),
    `Task11 light region ${region.id} must not be registered as an A1 collider`
  );
}
for (let leftIndex = 0; leftIndex < lightGridRuntime.visualRegions.length; leftIndex += 1) {
  for (let rightIndex = leftIndex + 1; rightIndex < lightGridRuntime.visualRegions.length; rightIndex += 1) {
    const leftRegion = lightGridRuntime.visualRegions[leftIndex];
    const rightRegion = lightGridRuntime.visualRegions[rightIndex];
    assert(
      !rectsOverlap(leftRegion.bounds, rightRegion.bounds),
      `Task11 visual light regions ${leftRegion.id} and ${rightRegion.id} must not overlap`
    );
  }
}
assert(lightGridRuntime?.approximate === true, "Task11 light-grid composite calibration must retain approximate=true");

const maintenanceGuardWaypoints = maintenanceRuntime?.guard?.patrolWaypoints ?? [];
assertJsonEqual(maintenanceGuardWaypoints, [
  { id: "stair_north", x: 1001, y: 240, neighborIds: ["west_north", "east_north"] },
  { id: "west_north", x: 588, y: 220, neighborIds: ["stair_north", "west_south"] },
  { id: "east_north", x: 1105, y: 240, neighborIds: ["stair_north", "east_south"] },
  { id: "east_south", x: 1105, y: 560, neighborIds: ["east_north", "west_south"] },
  { id: "west_south", x: 588, y: 560, neighborIds: ["east_south", "west_north"] }
], "maintenance guard waypoint graph");
const maintenanceWaypointById = new Map(
  maintenanceGuardWaypoints.map((waypoint) => [waypoint.id, waypoint])
);
const maintenanceGuardEdgeKeys = new Set();
for (const waypoint of maintenanceGuardWaypoints) {
  validatePoint(waypoint, `maintenanceRuntime.guard.${waypoint.id}`, topology.worldSize);
  assert(!waypoint.neighborIds.includes(waypoint.id), `${waypoint.id} guard waypoint must not self-link`);
  for (const neighborId of waypoint.neighborIds) {
    const neighbor = maintenanceWaypointById.get(neighborId);
    assert(Boolean(neighbor), `${waypoint.id} references missing guard waypoint ${neighborId}`);
    assert(neighbor?.neighborIds?.includes(waypoint.id), `${waypoint.id}<->${neighborId} guard edge must be bidirectional`);
    maintenanceGuardEdgeKeys.add([waypoint.id, neighborId].sort().join("<->"));
  }
}
assert(maintenanceGuardEdgeKeys.size === 5, "maintenance guard graph must contain exactly five unique patrol edges");
for (const edgeKey of maintenanceGuardEdgeKeys) {
  const [fromId, toId] = edgeKey.split("<->");
  const from = maintenanceWaypointById.get(fromId);
  const to = maintenanceWaypointById.get(toId);
  assert(
    sampledSegmentIsClear(
      from,
      to,
      a1?.staticCollisions ?? [],
      maintenanceRuntime.guard.footBox,
      2
    ),
    `maintenance guard edge ${edgeKey} must clear A1 static collisions at 2px sampling`
  );
}
assertJsonEqual(
  maintenanceRuntime?.guard?.position,
  maintenanceWaypointById.get("east_south") && {
    x: maintenanceWaypointById.get("east_south").x,
    y: maintenanceWaypointById.get("east_south").y
  },
  "maintenance guard initial east_south position"
);
assert(
  maintenanceRuntime?.guard?.initialPreviousWaypointId === "east_south"
    && maintenanceRuntime?.guard?.initialTargetWaypointId === "west_south",
  "maintenance guard must begin east_south toward west_south"
);

const finalChaseRuntime = layout.finalChaseRuntime;
assertJsonEqual({
  storyTimeSeconds: finalChaseRuntime?.storyTimeSeconds,
  playerSpeed: finalChaseRuntime?.playerSpeed,
  guardSpeed: finalChaseRuntime?.guardSpeed,
  guardUniformScale: finalChaseRuntime?.guardUniformScale,
  guardFootBox: finalChaseRuntime?.guardFootBox,
  waypointReachDistance: finalChaseRuntime?.waypointReachDistance,
  stableCommittedFramesToArm: finalChaseRuntime?.stableCommittedFramesToArm,
  maxStepMs: finalChaseRuntime?.maxStepMs,
  transportId: finalChaseRuntime?.transportId,
  guardPursuitStoryFloors: finalChaseRuntime?.guardPursuitStoryFloors,
  guardStopsAtTransport: finalChaseRuntime?.guardStopsAtTransport,
  restartCheckpoint: finalChaseRuntime?.restartCheckpoint
}, {
  storyTimeSeconds: 28440,
  playerSpeed: 208,
  guardSpeed: 196,
  guardUniformScale: 0.68,
  guardFootBox: { width: 20.4, height: 15.3 },
  waypointReachDistance: 8,
  stableCommittedFramesToArm: 4,
  maxStepMs: 50,
  transportId: "main_stair",
  guardPursuitStoryFloors: ["A1", "A2"],
  guardStopsAtTransport: "room202_door",
  restartCheckpoint: "c4_a1_lobby"
}, "Task12 final-chase runtime rules");
assertJsonEqual(finalChaseRuntime?.playerStart, { storyFloor: "A1", x: 590, y: 612 }, "Task12 player start");
assertJsonEqual(finalChaseRuntime?.guardSpawn, { storyFloor: "A1", x: 590, y: 724 }, "Task12 guard spawn");
assertJsonEqual(finalChaseRuntime?.guardA2Reentry, { storyFloor: "A2", x: 966, y: 174 }, "Task12 A2 guard re-entry");
assertJsonEqual(
  finalChaseRuntime?.waypoints?.map(({ id, storyFloor, x, y, role }) => ({ id, storyFloor, x, y, role })),
  [
    { id: "a1_front_desk_west", storyFloor: "A1", x: 720, y: 540, role: "route" },
    { id: "a1_lower_hall", storyFloor: "A1", x: 836, y: 540, role: "route" },
    { id: "a1_central", storyFloor: "A1", x: 836, y: 228, role: "route" },
    { id: "a1_stair_approach", storyFloor: "A1", x: 1001, y: 238, role: "route" },
    { id: "a1_main_stair", storyFloor: "A1", x: 1001, y: 214, role: "portal" },
    { id: "a2_main_stair_arrival", storyFloor: "A2", x: 966, y: 214, role: "portal" },
    { id: "a2_core_east", storyFloor: "A2", x: 1100, y: 232, role: "route" },
    { id: "a2_east_south", storyFloor: "A2", x: 1100, y: 400, role: "route" },
    { id: "a2_room202_outer", storyFloor: "A2", x: 1353, y: 400, role: "route" },
    { id: "a2_room203_corner_north", storyFloor: "A2", x: 1310, y: 490, role: "route" },
    { id: "a2_room203_corner_south", storyFloor: "A2", x: 1310, y: 540, role: "route" }
  ],
  "Task12 route waypoints"
);
assertJsonEqual(finalChaseRuntime?.decoyBranches, [
  { id: "a1_bakery_dead_end", storyFloor: "A1", x: 318, y: 648, canAdvance: false },
  { id: "a2_room203_dead_end", storyFloor: "A2", x: 1353, y: 524, canAdvance: false }
], "Task12 non-progressing decoy branches");
const finalChaseGraphNodes = [
  { id: "a1_guard_spawn", storyFloor: "A1", x: finalChaseRuntime?.guardSpawn?.x, y: finalChaseRuntime?.guardSpawn?.y },
  { id: "a1_chase_start", storyFloor: "A1", x: finalChaseRuntime?.playerStart?.x, y: finalChaseRuntime?.playerStart?.y },
  ...(finalChaseRuntime?.waypoints ?? []),
  ...(finalChaseRuntime?.decoyBranches ?? []),
  {
    id: "a2_room202_finish",
    storyFloor: "A2",
    x: finalChaseRuntime?.finishThreshold?.point?.x,
    y: finalChaseRuntime?.finishThreshold?.point?.y
  }
];
const finalChaseGraphNodeById = new Map(finalChaseGraphNodes.map((node) => [node.id, node]));
const finalChaseGraphEdges = [
  ["a1_guard_spawn", "a1_chase_start"],
  ["a1_chase_start", "a1_bakery_dead_end"],
  ["a1_chase_start", "a1_front_desk_west"],
  ["a1_front_desk_west", "a1_lower_hall"],
  ["a1_lower_hall", "a1_central"],
  ["a1_central", "a1_stair_approach"],
  ["a1_stair_approach", "a1_main_stair"],
  ["a2_main_stair_arrival", "a2_core_east"],
  ["a2_core_east", "a2_east_south"],
  ["a2_east_south", "a2_room202_outer"],
  ["a2_room202_outer", "a2_room202_finish"],
  ["a2_east_south", "a2_room203_corner_north"],
  ["a2_room203_corner_north", "a2_room203_corner_south"],
  ["a2_room203_corner_south", "a2_room203_dead_end"]
];
const finalChaseNeighbors = new Map(finalChaseGraphNodes.map((node) => [node.id, new Set()]));
for (const [fromId, toId] of finalChaseGraphEdges) {
  const from = finalChaseGraphNodeById.get(fromId);
  const to = finalChaseGraphNodeById.get(toId);
  assert(Boolean(from), `Task12 final-chase graph references missing node ${fromId}`);
  assert(Boolean(to), `Task12 final-chase graph references missing node ${toId}`);
  assert(from?.storyFloor === to?.storyFloor, `Task12 final-chase edge ${fromId}<->${toId} must stay on one floor`);
  finalChaseNeighbors.get(fromId)?.add(toId);
  finalChaseNeighbors.get(toId)?.add(fromId);
  const floor = floorByStory.get(from?.storyFloor);
  if (from && to && floor) {
    assert(
      sampledSegmentIsClear(from, to, floor.staticCollisions ?? [], finalChaseRuntime.guardFootBox, 0.5),
      `Task12 final-chase edge ${fromId}<->${toId} must clear static collisions for the rendered guard foot box`
    );
  }
}
for (const node of finalChaseGraphNodes) {
  const neighborIds = [...(finalChaseNeighbors.get(node.id) ?? [])];
  for (let fromIndex = 0; fromIndex < neighborIds.length; fromIndex += 1) {
    for (let toIndex = fromIndex + 1; toIndex < neighborIds.length; toIndex += 1) {
      const from = finalChaseGraphNodeById.get(neighborIds[fromIndex]);
      const to = finalChaseGraphNodeById.get(neighborIds[toIndex]);
      const floor = floorByStory.get(node.storyFloor);
      if (!from || !to || !floor) continue;
      const approachDistance = Math.hypot(from.x - node.x, from.y - node.y);
      const departureDistance = Math.hypot(to.x - node.x, to.y - node.y);
      const turnRadius = finalChaseRuntime.waypointReachDistance;
      const approachScale = Math.min(1, turnRadius / approachDistance);
      const departureScale = Math.min(1, turnRadius / departureDistance);
      const approach = {
        x: node.x + (from.x - node.x) * approachScale,
        y: node.y + (from.y - node.y) * approachScale
      };
      const departure = {
        x: node.x + (to.x - node.x) * departureScale,
        y: node.y + (to.y - node.y) * departureScale
      };
      assert(
        sampledSegmentIsClear(
          approach,
          departure,
          floor.staticCollisions ?? [],
          finalChaseRuntime.guardFootBox,
          0.5
        ),
        `Task12 final-chase turn ${from.id}->${node.id}->${to.id} must clear static collisions at the runtime turn radius`
      );
    }
  }
}
assertJsonEqual(finalChaseRuntime?.finishThreshold, {
  targetId: "a2_202_threshold",
  point: { x: 1353, y: 356.5 },
  bounds: { x: 1299, y: 334, width: 108, height: 45 },
  priority: "explicit_door_close"
}, "Task12 finish threshold");
assertJsonEqual(finalChaseRuntime?.room202Door, {
  id: "a2_room202_door",
  barrierBounds: { x: 1298, y: 341, width: 110, height: 29 },
  states: {
    final_chase: { state: "open", collider: false },
    final_minute_recovery: { state: "closed", collider: true },
    return_to_clock: { state: "open", collider: false }
  },
  visual: "procedural_status_only",
  officialClosedDoorSprite: false
}, "Task12 three-state Room202 door contract");

const finalMinuteRuntime = layout.finalMinuteRuntime;
assertJsonEqual({
  storyFloor: finalMinuteRuntime?.storyFloor,
  statePlateId: finalMinuteRuntime?.statePlateId,
  targetId: finalMinuteRuntime?.targetId,
  entityId: finalMinuteRuntime?.entityId,
  texture: finalMinuteRuntime?.texture,
  frame: finalMinuteRuntime?.frame,
  pivot: finalMinuteRuntime?.pivot,
  uniformScale: finalMinuteRuntime?.uniformScale,
  proximity: finalMinuteRuntime?.proximity,
  requiredMode: finalMinuteRuntime?.requiredMode,
  collision: finalMinuteRuntime?.collision
}, {
  storyFloor: "A2",
  statePlateId: "a2_202_final_minute",
  targetId: "a2_202_projection",
  entityId: "chapter4_final_minute_shard",
  texture: "chapter4_story_items",
  frame: "final_minute_shard",
  pivot: { x: 1353, y: 320 },
  uniformScale: 0.18,
  proximity: 112,
  requiredMode: "light",
  collision: false
}, "Task12 final-minute runtime entity contract");
const task12StoryItemSheet = finaleManifest.spritesheets?.find((sheet) => sheet.id === "chapter4_story_items");
const finalMinuteFrame = task12StoryItemSheet?.frames?.find((frame) => frame.id === "final_minute_shard");
const finalMinuteSourceCell = finalMinuteFrame?.sourceCell;
const finalMinuteSourcePivot = finalMinuteFrame?.pivot;
const finalMinuteScale = finalMinuteRuntime?.uniformScale;
const finalMinutePivot = finalMinuteRuntime?.pivot;
const derivedFinalMinuteGetBounds = [
  finalMinuteSourceCell?.x, finalMinuteSourceCell?.y, finalMinuteSourceCell?.width,
  finalMinuteSourceCell?.height, finalMinuteSourcePivot?.x, finalMinuteSourcePivot?.y,
  finalMinuteScale, finalMinutePivot?.x, finalMinutePivot?.y
].every(Number.isFinite) ? {
  x: Math.floor(finalMinutePivot.x + (finalMinuteSourceCell.x - finalMinuteSourcePivot.x) * finalMinuteScale),
  y: Math.floor(finalMinutePivot.y + (finalMinuteSourceCell.y - finalMinuteSourcePivot.y) * finalMinuteScale),
  width: Math.ceil(finalMinutePivot.x + (finalMinuteSourceCell.x + finalMinuteSourceCell.width - finalMinuteSourcePivot.x) * finalMinuteScale)
    - Math.floor(finalMinutePivot.x + (finalMinuteSourceCell.x - finalMinuteSourcePivot.x) * finalMinuteScale),
  height: Math.ceil(finalMinutePivot.y + (finalMinuteSourceCell.y + finalMinuteSourceCell.height - finalMinuteSourcePivot.y) * finalMinuteScale)
    - Math.floor(finalMinutePivot.y + (finalMinuteSourceCell.y - finalMinuteSourcePivot.y) * finalMinuteScale)
} : null;
assertJsonEqual(derivedFinalMinuteGetBounds, finalMinuteRuntime?.installationBounds, "Task12 final-minute sprite.getBounds -> Zone -> layout bounds");
assertJsonEqual(finalMinuteRuntime?.boundsDerivation, {
  kind: "visible_sprite_get_bounds",
  sourceCell: { x: 384, y: 512, width: 384, height: 512 },
  sourcePivot: { x: 566, y: 900 },
  zoneSource: "sprite.getBounds"
}, "Task12 final-minute visible bounds provenance");
assertJsonEqual(finalMinuteRuntime?.recoveryPlayerSpawn, { x: 1453, y: 306 }, "Task12 recovery player spawn");
validateClearPoint(finalMinuteRuntime?.recoveryPlayerSpawn, a2?.staticCollisions ?? [], "Task12 recoveryPlayerSpawn", 0);

assertJsonEqual(layout.dynamicGates, [{
  id: "a2_room202_recovery_barrier",
  storyFloor: "A2",
  bounds: { x: 1298, y: 341, width: 110, height: 29 },
  activePhases: ["final_minute_recovery"],
  collision: true,
  visual: "procedural_status_only",
  officialClosedDoorSprite: false
}], "Task12 recovery-only Room202 dynamic gate");
assertJsonEqual(
  layout.collisionProfiles?.map((profile) => profile.id),
  ["a1_static_v1", "a2_static_v1", "a3_static_v1"],
  "static collision profile ids"
);
assertJsonEqual(
  layout.physicalDeltas?.map((delta) => delta.id),
  [
    "a1_midday_queue_rails",
    "a2_room204_disordered_furniture",
    "a2_room202_recovery_barrier",
    "a3_reference_classroom_furniture"
  ],
  "physical delta ids"
);
assertJsonEqual(
  layout.physicalDeltas?.find((delta) => delta.id === "a2_room202_recovery_barrier"),
  {
    id: "a2_room202_recovery_barrier",
    storyFloor: "A2",
    statePlateIds: ["a2_202_final_minute"],
    activation: "runtime_furniture_visible",
    collisionSource: "finalChaseRuntime.room202Door.barrierBounds",
    worldRoomBounds: { x: 1298, y: 341, width: 110, height: 29 },
    approximate: false
  },
  "Task12 recovery barrier physical delta provenance"
);
for (const delta of layout.physicalDeltas ?? []) {
  registerId(delta, "layout.physicalDeltas");
  assert(expectedFloors.includes(delta.storyFloor), `${delta.id} references inactive floor ${delta.storyFloor}`);
  assert(delta.statePlateIds?.length > 0, `${delta.id} must bind at least one state plate`);
  if (delta.collisionBounds) {
    for (const collision of delta.collisionBounds) {
      registerId(collision, `${delta.id}.collisionBounds`);
      validateRect(collision, `${delta.id}.${collision.id}`, topology.worldSize);
    }
  } else {
    assert(typeof delta.collisionSource === "string", `${delta.id} must define collisionBounds or collisionSource`);
  }
  for (const occlusion of delta.occlusionBounds ?? []) {
    registerId(occlusion, `${delta.id}.occlusionBounds`);
    validateRect(occlusion.maskBounds, `${delta.id}.${occlusion.id}.maskBounds`, topology.worldSize);
    assert(occlusion.baselineY === occlusion.maskBounds.y + occlusion.maskBounds.height, `${occlusion.id} baseline mismatch`);
  }
}

assertJsonEqual(topology.phaseOrder, content.orderedPhases, "topology/content phase order");
assertJsonEqual(
  topology.navigationNetworks?.map((network) => network.id),
  ["a1_public_network", "a2_room_network", "a3_reference_network"],
  "navigation network ids"
);
assertJsonEqual(
  topology.routeAssertions?.map((assertion) => assertion.id),
  requiredRouteAssertionIds,
  "route assertion ids"
);
assertJsonEqual(
  topology.interfloorRouteAssertions?.map((assertion) => assertion.id),
  ["a1_to_a2_to_202_chase", "a2_202_to_a1_clock_return"],
  "interfloor route assertion ids"
);

const topologyNodeById = new Map();
for (const node of topology.navigationNodes ?? []) {
  registerId(node, "topology.navigationNodes");
  assert(expectedFloors.includes(node.storyFloor), `${node.id} references inactive floor ${node.storyFloor}`);
  validatePoint(node.point, `topology.${node.id}`, topology.worldSize);
  topologyNodeById.set(node.id, node);
}
const networkById = new Map();
for (const network of topology.navigationNetworks ?? []) {
  registerId(network, "topology.navigationNetworks");
  validateRect(network.bounds, `topology.${network.id}.bounds`, topology.worldSize);
  assert(Number.isInteger(network.clearancePixels) && network.clearancePixels >= 0, `${network.id} clearance invalid`);
  const floor = floorByStory.get(network.storyFloor);
  assert(floor, `${network.id} references missing floor ${network.storyFloor}`);
  for (const nodeId of network.nodeIds ?? []) {
    const node = topologyNodeById.get(nodeId);
    assert(node?.storyFloor === network.storyFloor, `${network.id} node ${nodeId} floor mismatch`);
    if (node) {
      assert(pointInsideRect(node.point, network.bounds), `${network.id} node ${nodeId} lies outside network bounds`);
      validateClearPoint(node.point, floor?.staticCollisions ?? [], `${network.id}.${nodeId}`, network.clearancePixels);
    }
  }
  networkById.set(network.id, network);
}

for (const route of topology.routeAssertions ?? []) {
  registerId(route, "topology.routeAssertions");
  const network = networkById.get(route.networkId);
  const from = topologyNodeById.get(route.fromNodeId);
  const to = topologyNodeById.get(route.toNodeId);
  assert(network, `${route.id} references missing network ${route.networkId}`);
  assert(network?.nodeIds?.includes(route.fromNodeId), `${route.id} from node is outside its network`);
  assert(network?.nodeIds?.includes(route.toNodeId), `${route.id} to node is outside its network`);
  if (network && from && to) {
    const floor = floorByStory.get(network.storyFloor);
    assert(
      hasGridRoute(network, from.point, to.point, floor?.staticCollisions ?? []),
      `${route.id} has no collision-free route with ${network.clearancePixels}px clearance`
    );
  }
}

for (const route of topology.interfloorRouteAssertions ?? []) {
  registerId(route, "topology.interfloorRouteAssertions");
  assert(route.segments?.length === 3, `${route.id} must contain floor/transport/floor segments`);
  const [first, transport, last] = route.segments ?? [];
  assert(first?.kind === "floor_navigation", `${route.id} first segment must be floor navigation`);
  assert(transport?.kind === "transport" && transport.transportId === "main_stair", `${route.id} must use only main_stair`);
  assert(last?.kind === "floor_navigation", `${route.id} last segment must be floor navigation`);
  const expectedDirection = route.id === "a1_to_a2_to_202_chase"
    ? ["A1", "A2"]
    : ["A2", "A1"];
  assert(
    transport?.fromStoryFloor === expectedDirection[0]
      && transport?.toStoryFloor === expectedDirection[1],
    `${route.id} floor transition mismatch`
  );
  const expectedEndpoints = route.id === "a1_to_a2_to_202_chase"
    ? ["a1_chase_start", "a1_stair_stand", "a2_stair_stand", "a2_202_chase_finish_point"]
    : ["a2_202_chase_finish_point", "a2_stair_stand", "a1_stair_stand", "a1_clock_stand"];
  assertJsonEqual(
    [first?.fromNodeId, first?.toNodeId, last?.fromNodeId, last?.toNodeId],
    expectedEndpoints,
    `${route.id} authored route endpoints`
  );
  for (const [segmentIndex, segment] of [first, last].entries()) {
    if (!segment) continue;
    const network = networkById.get(segment.networkId);
    const from = topologyNodeById.get(segment.fromNodeId);
    const to = topologyNodeById.get(segment.toNodeId);
    const floor = network ? floorByStory.get(network.storyFloor) : null;
    assert(network && from && to, `${route.id} navigation segment ${segmentIndex} references missing contract data`);
    if (!network || !from || !to) continue;
    for (const sampleStep of [2, 4]) {
      assert(
        hasGridRoute(network, from.point, to.point, floor?.staticCollisions ?? [], sampleStep),
        `${route.id} segment ${segmentIndex} has no ${sampleStep}px collision-free route`
      );
    }
  }
}

assert(
  !JSON.stringify(topology.interfloorRouteAssertions).includes("main_elevator"),
  "Task12 chase and return route contracts must never name main_elevator"
);

const activeTopology = { ...topology, supersedes: undefined };
findForbiddenValue(activeTopology, "topology");
assert(
  !hasGridRoute(
    { bounds: { x: 0, y: 0, width: 12, height: 8 }, clearancePixels: 0 },
    { x: 1, y: 4 },
    { x: 10, y: 4 },
    [{ id: "thin_wall_regression", x: 5, y: 0, width: 1, height: 8 }]
  ),
  "4px grid cells must reject a route cut by a 1px half-open wall"
);

if (errors.length) {
  console.error(errors.map((error) => `- ${error}`).join("\n"));
  process.exit(1);
}

console.log(
  `Chapter 4 topology PASS assertions=${assertionCount} schema=2 floors=${topology.floors.length} networks=${topology.navigationNetworks.length} routes=${topology.routeAssertions.length} chaseRoutes=${topology.interfloorRouteAssertions.length} chaseAndReturnTransport=main_stair sampleSteps=2,4 bakeryRoutes=${bakeryRuntime.walkabilityRoutes.length} bakeryNpcCollision=pure_data_arcade_math_contract(no_browser_evidence) room204Assertions=${room204AssertionCount} room204PieceSlotCandidates=${room204PieceSlotCandidateCount} room204Aisles=3+1 sampleSteps=2,4 room204Collision=pure_data_manifest_math_contract(no_browser_evidence) maintenanceGuardEdges=${maintenanceGuardEdgeKeys.size} maintenanceGuardSampleStep=2 maintenanceGuardCollision=pure_data_layout_math_contract(no_browser_evidence) task11MinuteEndpoint=programmatic_visible_bounds task11LightRegions=5_visual_only_noncolliding_no_browser_evidence task12Collision=pure_data_layout_math_contract(no_browser_evidence)`
);

function assert(condition, message) {
  assertionCount += 1;
  if (!condition) errors.push(message);
}

function assertJsonEqual(actual, expected, label) {
  assert(
    JSON.stringify(actual) === JSON.stringify(expected),
    `${label} mismatch: expected ${JSON.stringify(expected)}, got ${JSON.stringify(actual)}`
  );
}

function assertApprox(actual, expected, label, epsilon = 1e-9) {
  assert(
    Number.isFinite(actual) && Math.abs(actual - expected) <= epsilon,
    `${label} mismatch: expected ${expected}, got ${actual}`
  );
}

function assertSetEqual(actual, expected, label) {
  const actualArray = Array.isArray(actual) ? [...actual].sort() : [];
  const expectedArray = [...expected].sort();
  assertJsonEqual(actualArray, expectedArray, label);
}

function assertRectSemantics(value, label) {
  assert(
    value?.origin === "top_left"
    && value?.unit === "source_pixel"
    && value?.rectangleSemantics === "half_open",
    `${label} must use top-left source pixels and half-open rectangles`
  );
}

function registerId(entry, label) {
  const id = entry?.id;
  if (typeof id !== "string" || id.length === 0) {
    errors.push(`${label} contains an entry without an id`);
    return;
  }
  const previous = globalIds.get(id);
  if (previous) errors.push(`${label} duplicates id ${id} already used by ${previous}`);
  else globalIds.set(id, label);
}

function validateRect(rect, label, worldSize) {
  if (!rect || typeof rect !== "object") {
    errors.push(`${label} must be a rectangle`);
    return false;
  }
  for (const key of ["x", "y", "width", "height"]) {
    if (!Number.isInteger(rect[key])) {
      errors.push(`${label}.${key} must be an integer source-pixel number`);
      return false;
    }
  }
  if (
    rect.width <= 0 || rect.height <= 0
    || rect.x < 0 || rect.y < 0
    || rect.x + rect.width > worldSize.width
    || rect.y + rect.height > worldSize.height
  ) {
    errors.push(`${label} lies outside ${worldSize.width}x${worldSize.height}`);
    return false;
  }
  for (const legacy of ["left", "top", "right", "bottom"]) {
    if (legacy in rect) errors.push(`${label} must not use legacy ${legacy} coordinates`);
  }
  return true;
}

function validatePoint(point, label, worldSize) {
  if (!point || !Number.isFinite(point.x) || !Number.isFinite(point.y)) {
    errors.push(`${label} must define finite x/y`);
    return false;
  }
  if (point.x < 0 || point.x >= worldSize.width || point.y < 0 || point.y >= worldSize.height) {
    errors.push(`${label} lies outside ${worldSize.width}x${worldSize.height}`);
    return false;
  }
  return true;
}

function validateClearPoint(point, collisions, label, clearance) {
  if (!validatePoint(point, label, topology.worldSize)) return;
  for (const collision of collisions) {
    const inflated = inflateRect(collision, clearance);
    assert(!pointInsideRect(point, inflated), `${label} overlaps collision ${collision.id} at ${clearance}px clearance`);
  }
}

function hasGridRoute(network, from, to, collisions, step = 4) {
  if (!pointInsideRect(from, network.bounds) || !pointInsideRect(to, network.bounds)) return false;
  const columns = Math.ceil(network.bounds.width / step);
  const rows = Math.ceil(network.bounds.height / step);
  const key = (column, row) => row * columns + column;
  const blockedCells = new Uint8Array(columns * rows);
  const inflatedCollisions = collisions.map((collision) => (
    inflateRect(collision, network.clearancePixels)
  ));
  const cellBounds = (column, row) => {
    const x = network.bounds.x + column * step;
    const y = network.bounds.y + row * step;
    return {
      x,
      y,
      width: Math.min(step, network.bounds.x + network.bounds.width - x),
      height: Math.min(step, network.bounds.y + network.bounds.height - y)
    };
  };
  const blocked = (column, row) => {
    const cellKey = key(column, row);
    if (blockedCells[cellKey] !== 0) return blockedCells[cellKey] === 2;
    const isBlocked = inflatedCollisions.some((collision) => rectsOverlap(cellBounds(column, row), collision));
    blockedCells[cellKey] = isBlocked ? 2 : 1;
    return isBlocked;
  };
  const toGrid = (point) => ({
    column: Math.floor((point.x - network.bounds.x) / step),
    row: Math.floor((point.y - network.bounds.y) / step)
  });
  const start = toGrid(from);
  const goal = toGrid(to);
  if (blocked(start.column, start.row) || blocked(goal.column, goal.row)) return false;
  const seen = new Uint8Array(columns * rows);
  const queue = new Uint32Array(columns * rows);
  const directions = [[-1, 0], [1, 0], [0, -1], [0, 1]];
  let head = 0;
  let tail = 0;
  const startKey = key(start.column, start.row);
  queue[tail] = startKey;
  tail += 1;
  seen[startKey] = 1;
  while (head < tail) {
    const cellKey = queue[head];
    head += 1;
    const row = Math.floor(cellKey / columns);
    const column = cellKey - row * columns;
    if (column === goal.column && row === goal.row) return true;
    for (const [columnDelta, rowDelta] of directions) {
      const nextColumn = column + columnDelta;
      const nextRow = row + rowDelta;
      if (nextColumn < 0 || nextRow < 0 || nextColumn >= columns || nextRow >= rows) continue;
      const nextKey = key(nextColumn, nextRow);
      if (seen[nextKey] || blocked(nextColumn, nextRow)) continue;
      seen[nextKey] = 1;
      queue[tail] = nextKey;
      tail += 1;
    }
  }
  return false;
}

function deriveArcadeBodyGeometry({ frameSize, sourceBody, origin, displayScale }) {
  if (![frameSize?.width, frameSize?.height, sourceBody?.x, sourceBody?.y,
    sourceBody?.width, sourceBody?.height, origin?.x, origin?.y, displayScale]
    .every(Number.isFinite)) return null;
  const leftOffset = displayScale * (sourceBody.x - frameSize.width * origin.x);
  const topOffset = displayScale * (sourceBody.y - frameSize.height * origin.y);
  const width = sourceBody.width * displayScale;
  const height = sourceBody.height * displayScale;
  return {
    leftOffset,
    topOffset,
    width,
    height,
    rightOffset: leftOffset + width,
    bottomOffset: topOffset + height
  };
}

function bakeryNpcSweptFootRect(route, arcadeBody) {
  if (!arcadeBody) {
    return { id: `${route.id}_invalid_arcade_body`, x: 0, y: 0, width: Infinity, height: Infinity };
  }
  const left = Math.min(
    route.from.x + arcadeBody.leftOffset,
    route.to.x + arcadeBody.leftOffset
  );
  const right = Math.max(
    route.from.x + arcadeBody.rightOffset,
    route.to.x + arcadeBody.rightOffset
  );
  const top = Math.min(
    route.from.y + arcadeBody.topOffset,
    route.to.y + arcadeBody.topOffset
  );
  const bottom = Math.max(
    route.from.y + arcadeBody.bottomOffset,
    route.to.y + arcadeBody.bottomOffset
  );
  return {
    id: `${route.id}_swept_foot_collider`,
    x: left,
    y: top,
    width: right - left,
    height: bottom - top
  };
}

function sampledWaypointRouteIsClear(waypoints, collisions, footBox, sampleStep) {
  if (!Array.isArray(waypoints) || waypoints.length < 2) return false;
  const inflatedCollisions = collisions.map((collision) => inflateRectXY(
    collision,
    footBox.width / 2,
    footBox.height / 2
  ));
  for (let index = 0; index < waypoints.length - 1; index += 1) {
    const start = waypoints[index];
    const end = waypoints[index + 1];
    if (!validatePoint(start, `bakeryRoute.waypoints[${index}]`, topology.worldSize)
      || !validatePoint(end, `bakeryRoute.waypoints[${index + 1}]`, topology.worldSize)) {
      return false;
    }
    const distance = Math.hypot(end.x - start.x, end.y - start.y);
    const samples = Math.max(1, Math.ceil(distance / sampleStep));
    for (let sample = 0; sample <= samples; sample += 1) {
      const t = sample / samples;
      const point = {
        x: start.x + (end.x - start.x) * t,
        y: start.y + (end.y - start.y) * t
      };
      if (inflatedCollisions.some((collision) => pointInsideRect(point, collision))) return false;
    }
  }
  return true;
}

function sampledSegmentIsClear(start, end, collisions, footBox, sampleStep) {
  if (![start?.x, start?.y, end?.x, end?.y, footBox?.width, footBox?.height, sampleStep]
    .every(Number.isFinite) || sampleStep <= 0) return false;
  const inflatedCollisions = collisions.map((collision) => inflateRectXY(
    collision,
    footBox.width / 2,
    footBox.height / 2
  ));
  const distance = Math.hypot(end.x - start.x, end.y - start.y);
  const samples = Math.max(1, Math.ceil(distance / sampleStep));
  for (let sample = 0; sample <= samples; sample += 1) {
    const t = sample / samples;
    const point = {
      x: start.x + (end.x - start.x) * t,
      y: start.y + (end.y - start.y) * t
    };
    if (inflatedCollisions.some((collision) => pointInsideRect(point, collision))) return false;
  }
  return true;
}

function deriveManifestInteractionRect({ frame, worldPivot, uniformScale }) {
  const interaction = frame?.interactionBounds?.find(
    (candidate) => candidate.coordinateSpace === "source_sheet"
  );
  const bounds = interaction?.bounds;
  if (![frame?.pivot?.x, frame?.pivot?.y, bounds?.x, bounds?.y,
    bounds?.width, bounds?.height, worldPivot?.x, worldPivot?.y, uniformScale]
    .every(Number.isFinite) || uniformScale <= 0) return null;
  const left = Math.floor(worldPivot.x + (bounds.x - frame.pivot.x) * uniformScale);
  const top = Math.floor(worldPivot.y + (bounds.y - frame.pivot.y) * uniformScale);
  const right = Math.ceil(
    worldPivot.x + (bounds.x + bounds.width - frame.pivot.x) * uniformScale
  );
  const bottom = Math.ceil(
    worldPivot.y + (bounds.y + bounds.height - frame.pivot.y) * uniformScale
  );
  return { x: left, y: top, width: right - left, height: bottom - top };
}

function deriveFrameLocalInteractionRect({
  worldPivot,
  uniformScale,
  sourceFrameSize,
  origin,
  sourceLocalBounds
}) {
  if (![worldPivot?.x, worldPivot?.y, uniformScale,
    sourceFrameSize?.width, sourceFrameSize?.height,
    origin?.x, origin?.y,
    sourceLocalBounds?.x, sourceLocalBounds?.y,
    sourceLocalBounds?.width, sourceLocalBounds?.height]
    .every(Number.isFinite) || uniformScale <= 0) return null;
  const left = worldPivot.x
    + (sourceLocalBounds.x - sourceFrameSize.width * origin.x) * uniformScale;
  const top = worldPivot.y
    + (sourceLocalBounds.y - sourceFrameSize.height * origin.y) * uniformScale;
  const right = left + sourceLocalBounds.width * uniformScale;
  const bottom = top + sourceLocalBounds.height * uniformScale;
  return {
    x: Math.floor(left),
    y: Math.floor(top),
    width: Math.ceil(right) - Math.floor(left),
    height: Math.ceil(bottom) - Math.floor(top)
  };
}

function deriveManifestCollisionRect({ frame, worldPivot, uniformScale, angle, id }) {
  const collision = frame?.collisionBounds?.[0]?.bounds;
  if (![frame?.pivot?.x, frame?.pivot?.y, collision?.x, collision?.y,
    collision?.width, collision?.height, worldPivot?.x, worldPivot?.y,
    uniformScale, angle].every(Number.isFinite) || uniformScale <= 0) return null;
  const radians = angle * Math.PI / 180;
  const cos = Math.cos(radians);
  const sin = Math.sin(radians);
  const localCenterX = (collision.x + collision.width / 2 - frame.pivot.x) * uniformScale;
  const localCenterY = (collision.y + collision.height / 2 - frame.pivot.y) * uniformScale;
  const centerX = worldPivot.x + localCenterX * cos - localCenterY * sin;
  const centerY = worldPivot.y + localCenterX * sin + localCenterY * cos;
  const sourceWidth = collision.width * uniformScale;
  const sourceHeight = collision.height * uniformScale;
  const width = Math.abs(sourceWidth * cos) + Math.abs(sourceHeight * sin);
  const height = Math.abs(sourceWidth * sin) + Math.abs(sourceHeight * cos);
  return {
    id,
    x: centerX - width / 2,
    y: centerY - height / 2,
    width,
    height
  };
}

function inflateRect(rect, amount) {
  return {
    x: rect.x - amount,
    y: rect.y - amount,
    width: rect.width + amount * 2,
    height: rect.height + amount * 2
  };
}

function inflateRectXY(rect, horizontal, vertical) {
  return {
    x: rect.x - horizontal,
    y: rect.y - vertical,
    width: rect.width + horizontal * 2,
    height: rect.height + vertical * 2
  };
}

function rectsOverlap(left, right) {
  return left.x < right.x + right.width
    && left.x + left.width > right.x
    && left.y < right.y + right.height
    && left.y + left.height > right.y;
}

function rectContainsRect(outer, inner) {
  if (!outer || !inner) return false;
  return inner.x >= outer.x
    && inner.y >= outer.y
    && inner.x + inner.width <= outer.x + outer.width
    && inner.y + inner.height <= outer.y + outer.height;
}

function pointInsideRect(point, rect) {
  return point.x >= rect.x
    && point.x < rect.x + rect.width
    && point.y >= rect.y
    && point.y < rect.y + rect.height;
}

function rectOnly(value) {
  return value ? { x: value.x, y: value.y, width: value.width, height: value.height } : value;
}

function findForbiddenValue(value, path) {
  if (typeof value === "string") {
    if (["A4", "B2", "B3"].includes(value) || forbiddenActiveIds.has(value)) {
      errors.push(`${path} contains removed active value ${value}`);
    }
    return;
  }
  if (Array.isArray(value)) {
    value.forEach((entry, index) => findForbiddenValue(entry, `${path}[${index}]`));
    return;
  }
  if (!value || typeof value !== "object") return;
  for (const [key, entry] of Object.entries(value)) findForbiddenValue(entry, `${path}.${key}`);
}
