import fs from "node:fs";

const topologyPath = new URL("../src/data/chapter4-temporal-maze.topology.json", import.meta.url);
const contentPath = new URL("../src/data/chapter4-temporal-maze.content.json", import.meta.url);
const layoutPath = new URL("../src/data/chapter4-three-floor-maze.layout.json", import.meta.url);
const topology = JSON.parse(fs.readFileSync(topologyPath, "utf8"));
const content = JSON.parse(fs.readFileSync(contentPath, "utf8"));
const errors = [];
let layout = null;

try {
  layout = JSON.parse(fs.readFileSync(layoutPath, "utf8"));
} catch (error) {
  const reason = error instanceof Error ? error.message : String(error);
  errors.push(`three-floor layout is missing or invalid: ${reason}`);
}

const expectedNodes = ["A1", "A2", "A3", "A4", "B2", "B3"];
const expectedPuzzles = [
  "airflow_overlay", "elevator_track_sync", "npc_schedule_route",
  "corridor_bay_reconstruction", "wayfinding_fragment_board",
  "bridge_floor_discrimination", "stair_echo_direction", "multicam_video_edit",
  "echo_action_record", "dual_lift_logistics", "warm_air_balance",
  "route_schedule", "clock_phase_lock"
];
const expectedRuntimeFloors = ["A1", "A2", "A3"];
const forbiddenRuntimeFloors = new Set(["A4", "B2", "B3"]);
const expectedCheckpoints = ["c4_a1_lobby", "c4_a2_corridor", "c4_a3_wayfinding"];
const expectedDynamicGateIds = [
  "a2_partition_west",
  "a2_partition_east",
  "a2_room_203_return_door"
];
const expectedTargetAnchorIds = [
  "a2_schedule_observation",
  "a2_fragment_west",
  "a2_fragment_east",
  "a3_old_signage",
  "a3_wayfinding_board",
  "a3_bridge_history",
  "a2_return_window"
];

function isRecord(value) {
  return value !== null && typeof value === "object" && !Array.isArray(value);
}

function pushDuplicateIdErrors(entries, label) {
  const seenIds = new Set();
  for (const entry of entries) {
    const id = typeof entry?.id === "string" ? entry.id : "";
    if (!id) {
      errors.push(`${label} contains an entry without an id`);
      continue;
    }
    if (seenIds.has(id)) errors.push(`${label} contains duplicate id ${id}`);
    seenIds.add(id);
  }
}

function validateRect(rect, label, worldSize, requireDimensions = false) {
  if (!isRecord(rect)) {
    errors.push(`${label} must be a rectangle`);
    return false;
  }
  const coordinates = ["left", "top", "right", "bottom"];
  for (const coordinate of coordinates) {
    if (!Number.isFinite(rect[coordinate])) {
      errors.push(`${label}.${coordinate} must be a finite number`);
      return false;
    }
  }
  if (rect.left >= rect.right || rect.top >= rect.bottom) {
    errors.push(`${label} must have positive width and height`);
    return false;
  }
  if (
    rect.left < 0 || rect.top < 0
    || rect.right > worldSize.width || rect.bottom > worldSize.height
  ) {
    errors.push(`${label} is outside ${worldSize.width}×${worldSize.height}`);
    return false;
  }
  const width = rect.right - rect.left;
  const height = rect.bottom - rect.top;
  if (requireDimensions) {
    if (rect.width !== width) errors.push(`${label}.width must equal right - left (${width})`);
    if (rect.height !== height) errors.push(`${label}.height must equal bottom - top (${height})`);
  } else {
    if (rect.width !== undefined && rect.width !== width) {
      errors.push(`${label}.width must equal right - left (${width})`);
    }
    if (rect.height !== undefined && rect.height !== height) {
      errors.push(`${label}.height must equal bottom - top (${height})`);
    }
  }
  return true;
}

function validatePoint(point, label, worldSize) {
  if (!isRecord(point) || !Number.isFinite(point.x) || !Number.isFinite(point.y)) {
    errors.push(`${label} must define finite x and y coordinates`);
    return false;
  }
  if (point.x < 0 || point.x >= worldSize.width || point.y < 0 || point.y >= worldSize.height) {
    errors.push(`${label} is outside ${worldSize.width}×${worldSize.height}`);
    return false;
  }
  return true;
}

function rectsOverlap(left, right) {
  return left.left < right.right
    && left.right > right.left
    && left.top < right.bottom
    && left.bottom > right.top;
}

function pointInsideRect(point, rect) {
  return point.x >= rect.left
    && point.x <= rect.right
    && point.y >= rect.top
    && point.y <= rect.bottom;
}

function validateClearPoint(point, collisions, label) {
  for (const collision of collisions) {
    if (isRecord(collision) && pointInsideRect(point, collision)) {
      errors.push(`${label} is inside static collision ${collision.id}`);
    }
  }
}

function findForbiddenRuntimeFloor(value, path = "layout") {
  if (typeof value === "string" && forbiddenRuntimeFloors.has(value)) {
    errors.push(`${path} must not map forbidden runtime floor ${value}`);
    return;
  }
  if (Array.isArray(value)) {
    value.forEach((entry, index) => findForbiddenRuntimeFloor(entry, `${path}[${index}]`));
    return;
  }
  if (!isRecord(value)) return;
  for (const [key, entry] of Object.entries(value)) {
    findForbiddenRuntimeFloor(entry, `${path}.${key}`);
  }
}

if (topology.schemaVersion !== 1) errors.push("schemaVersion must be 1");
if (JSON.stringify(topology.nodes) !== JSON.stringify(expectedNodes)) errors.push("floor nodes do not match A1-A4/B2-B3");
if (new Set(topology.puzzleOrder).size !== 13) errors.push("puzzleOrder must contain 13 unique puzzles");
if (JSON.stringify(topology.puzzleOrder) !== JSON.stringify(expectedPuzzles)) errors.push("puzzleOrder does not match the Chapter 4 specification");

const skybridges = topology.connectors.filter((connector) => connector.kind === "skybridge");
if (skybridges.length !== 1 || JSON.stringify(skybridges[0]?.nodes) !== JSON.stringify(["A3", "B3"])) {
  errors.push("the only skybridge must connect A3 and B3");
}

const stairs = topology.connectors.filter((connector) => connector.kind === "stair");
if (stairs.length !== 2) errors.push("A and B buildings must each define one stair connector");
for (const stair of stairs) {
  if (stair.landingEntry !== "side_fire_door") {
    errors.push(`${stair.id} must place the corridor fire door on the side landing`);
  }
  if (stair.flightEnds !== "open_vertical_continuation") {
    errors.push(`${stair.id} must keep stair-flight ends open to the next level`);
  }
}
const bStair = stairs.find((connector) => connector.id === "b_stair");
if (bStair?.temporalAlignmentPuzzle !== "stair_echo_direction") {
  errors.push("B stair must bind its temporal alignment to stair_echo_direction");
}

const mainElevator = topology.connectors.find((connector) => connector.id === "a_main_elevator");
if (!mainElevator?.boardAllowed || JSON.stringify(mainElevator.nodes) !== JSON.stringify(["A1", "A2", "A3", "A4"])) {
  errors.push("A main elevator must be boardable and connect A1-A4");
}

const elevatorTimeline = content.elevator?.timeline;
if (elevatorTimeline?.correctReplayStartSeconds !== 81811) errors.push("elevator replay must align at 22:43:31");
if (elevatorTimeline?.playerWindowEndSeconds - elevatorTimeline?.playerWindowStartSeconds !== 6) errors.push("elevator player entry window must last 6 seconds");
if (elevatorTimeline?.doorPassableRatio !== 0.82) errors.push("elevator door must become passable at 82 percent open");
if (!(elevatorTimeline?.secondFloorDoorOpenOffsetSeconds > elevatorTimeline?.riseOffsetSeconds)) errors.push("elevator A2 door opening must follow the ascent segment");

const adjacency = new Map(expectedNodes.map((node) => [node, new Set()]));
for (const connector of topology.connectors) {
  for (const from of connector.nodes) {
    for (const to of connector.nodes) {
      if (from !== to) adjacency.get(from)?.add(to);
    }
  }
}
const seen = new Set(["A1"]);
const queue = ["A1"];
while (queue.length) {
  const node = queue.shift();
  for (const next of adjacency.get(node) ?? []) {
    if (seen.has(next)) continue;
    seen.add(next);
    queue.push(next);
  }
}
if (seen.size !== expectedNodes.length) errors.push("building topology is not fully connected");

const roomFloors = new Set(topology.rooms.map((room) => room.floor));
for (const floor of expectedNodes) {
  if (!roomFloors.has(floor)) errors.push(`no authored room exists on ${floor}`);
}

if (layout) {
  const worldSize = layout.worldSize;
  if (layout.schemaVersion !== 1) errors.push("three-floor layout schemaVersion must be 1");
  if (!isRecord(worldSize) || worldSize.width !== 1672 || worldSize.height !== 941) {
    errors.push("three-floor layout worldSize must be 1672×941");
  }

  const floors = Array.isArray(layout.floors) ? layout.floors : [];
  if (floors.length !== 3) errors.push("three-floor layout must define exactly 3 floors");
  if (JSON.stringify(floors.map((floor) => floor.storyFloor)) !== JSON.stringify(expectedRuntimeFloors)) {
    errors.push("three-floor runtime mapping must be exactly A1, A2, A3");
  }
  if (JSON.stringify(floors.map((floor) => floor.displayFloor)) !== JSON.stringify([1, 2, 3])) {
    errors.push("display floors must map one-to-one to 1, 2, 3");
  }
  if (JSON.stringify(floors.map((floor) => floor.checkpoint)) !== JSON.stringify(expectedCheckpoints)) {
    errors.push("three-floor checkpoints must be c4_a1_lobby, c4_a2_corridor, c4_a3_wayfinding");
  }
  findForbiddenRuntimeFloor(layout);

  const elevators = Array.isArray(layout.transportCore?.elevators)
    ? layout.transportCore.elevators
    : [];
  const stairs = Array.isArray(layout.transportCore?.stairs)
    ? layout.transportCore.stairs
    : [];
  if (elevators.length !== 1) errors.push("three-floor layout must define exactly one elevator");
  if (stairs.length !== 1) errors.push("three-floor layout must define exactly one stair");
  const transportEntries = [...elevators, ...stairs];
  pushDuplicateIdErrors(transportEntries, "transportCore");
  if (elevators[0]?.id !== "main_elevator" || elevators[0]?.centerX !== 836) {
    errors.push("the single elevator must be main_elevator centered at x=836");
  }
  if (stairs[0]?.id !== "main_stair") {
    errors.push("the single stair must use id main_stair");
  }
  if (
    Number.isFinite(elevators[0]?.centerX)
    && Number.isFinite(stairs[0]?.left)
    && (stairs[0].left < elevators[0].centerX || stairs[0].left - elevators[0].centerX > 128)
  ) {
    errors.push("main_stair must remain immediately east of main_elevator");
  }
  if (isRecord(worldSize) && Number.isFinite(worldSize.width) && Number.isFinite(worldSize.height)) {
    validateRect(stairs[0], "transportCore.stairs[0]", worldSize);
  }

  const safeRouteEntries = isRecord(layout.safeRoutes)
    ? Object.entries(layout.safeRoutes)
    : [];
  const safeRoutesByFloor = new Map();
  for (const [id, route] of safeRouteEntries) {
    if (!isRecord(route)) {
      errors.push(`safeRoutes.${id} must be a rectangle`);
      continue;
    }
    if (!Number.isInteger(route.displayFloor) || route.displayFloor < 1 || route.displayFloor > 3) {
      errors.push(`safeRoutes.${id}.displayFloor must be 1, 2, or 3`);
      continue;
    }
    if (isRecord(worldSize)) validateRect(route, `safeRoutes.${id}`, worldSize, true);
    const floorRoutes = safeRoutesByFloor.get(route.displayFloor) ?? [];
    floorRoutes.push({ id, ...route });
    safeRoutesByFloor.set(route.displayFloor, floorRoutes);
  }
  if (!Number.isFinite(layout.safeRoutes?.floor2West?.width) || layout.safeRoutes.floor2West.width < 60) {
    errors.push("floor2West safe route must leave at least 60px of continuous visible floor");
  }
  if (!Number.isFinite(layout.safeRoutes?.floor2East?.width) || layout.safeRoutes.floor2East.width < 60) {
    errors.push("floor2East safe route must leave at least 60px of continuous visible floor");
  }
  if (!Number.isFinite(layout.safeRoutes?.floor2South?.height) || layout.safeRoutes.floor2South.height < 96) {
    errors.push("floor2South safe route must leave at least 96px of continuous visible floor");
  }

  const allAnchorIds = [];
  const allLandingIds = [];
  for (const [floorIndex, floor] of floors.entries()) {
    const label = `floors[${floorIndex}]`;
    const staticCollisions = Array.isArray(floor.staticCollisions) ? floor.staticCollisions : [];
    const anchors = Array.isArray(floor.anchors) ? floor.anchors : [];
    const stairLandings = Array.isArray(floor.stairLandings) ? floor.stairLandings : [];
    if (!staticCollisions.length) errors.push(`${label}.staticCollisions must not be empty`);
    if (!anchors.length) errors.push(`${label}.anchors must not be empty`);
    if (!stairLandings.length) errors.push(`${label}.stairLandings must not be empty`);
    pushDuplicateIdErrors(staticCollisions, `${label}.staticCollisions`);
    pushDuplicateIdErrors(anchors, `${label}.anchors`);
    pushDuplicateIdErrors(stairLandings, `${label}.stairLandings`);

    for (const [collisionIndex, collision] of staticCollisions.entries()) {
      if (isRecord(worldSize)) {
        validateRect(collision, `${label}.staticCollisions[${collisionIndex}]`, worldSize);
      }
      for (const route of safeRoutesByFloor.get(floor.displayFloor) ?? []) {
        if (isRecord(collision) && rectsOverlap(collision, route)) {
          errors.push(`${label}.staticCollisions.${collision.id} overlaps safe route ${route.id}`);
        }
      }
    }
    for (const [anchorIndex, anchor] of anchors.entries()) {
      allAnchorIds.push(anchor?.id);
      if (isRecord(worldSize)) {
        validateRect(anchor?.bounds, `${label}.anchors[${anchorIndex}].bounds`, worldSize);
      }
    }
    for (const [landingIndex, landing] of stairLandings.entries()) {
      allLandingIds.push(landing?.id);
      if (isRecord(worldSize)) {
        validateRect(landing?.bounds, `${label}.stairLandings[${landingIndex}].bounds`, worldSize);
        if (validatePoint(landing?.standPosition, `${label}.stairLandings[${landingIndex}].standPosition`, worldSize)) {
          validateClearPoint(
            landing.standPosition,
            staticCollisions,
            `${label}.stairLandings[${landingIndex}].standPosition`
          );
        }
        if (validatePoint(landing?.arrivalPosition, `${label}.stairLandings[${landingIndex}].arrivalPosition`, worldSize)) {
          validateClearPoint(
            landing.arrivalPosition,
            staticCollisions,
            `${label}.stairLandings[${landingIndex}].arrivalPosition`
          );
        }
      }
    }
    const expectedLandingDirections = floor.displayFloor === 1
      ? ["up"]
      : floor.displayFloor === 2
        ? ["down", "up"]
        : ["down"];
    if (JSON.stringify(stairLandings.map((landing) => landing.direction)) !== JSON.stringify(expectedLandingDirections)) {
      errors.push(`${label}.stairLandings must expose ${expectedLandingDirections.join(" then ")}`);
    }
    if (isRecord(worldSize)) {
      if (validatePoint(floor.elevatorStand, `${label}.elevatorStand`, worldSize)) {
        validateClearPoint(floor.elevatorStand, staticCollisions, `${label}.elevatorStand`);
      }
      if (floor.elevatorStand?.x !== elevators[0]?.centerX) {
        errors.push(`${label}.elevatorStand must align with main_elevator`);
      }
      if (validatePoint(floor.safeSpawn, `${label}.safeSpawn`, worldSize)) {
        validateClearPoint(floor.safeSpawn, staticCollisions, `${label}.safeSpawn`);
      }
    }
  }
  pushDuplicateIdErrors(allAnchorIds.map((id) => ({ id })), "floor anchors");
  pushDuplicateIdErrors(allLandingIds.map((id) => ({ id })), "stair landings");
  for (const id of expectedTargetAnchorIds) {
    if (!allAnchorIds.includes(id)) errors.push(`required target anchor ${id} is missing`);
  }

  const dynamicGates = Array.isArray(layout.dynamicGates) ? layout.dynamicGates : [];
  pushDuplicateIdErrors(dynamicGates, "dynamicGates");
  if (JSON.stringify(dynamicGates.map((gate) => gate.id)) !== JSON.stringify(expectedDynamicGateIds)) {
    errors.push(`dynamicGates must be ${expectedDynamicGateIds.join(", ")}`);
  }
  for (const [gateIndex, gate] of dynamicGates.entries()) {
    if (gate?.collisionId !== gate?.id) {
      errors.push(`dynamicGates[${gateIndex}].collisionId must match its visible gate id`);
    }
    if (gate?.kind !== "door" && gate?.kind !== "partition") {
      errors.push(`dynamicGates[${gateIndex}].kind must be door or partition`);
    }
    if (!floors.some((floor) => floor.displayFloor === gate?.displayFloor)) {
      errors.push(`dynamicGates[${gateIndex}] references an unknown display floor`);
    }
    if (isRecord(worldSize)) {
      validateRect(gate?.bounds, `dynamicGates[${gateIndex}].bounds`, worldSize);
    }
  }
}

if (errors.length) {
  console.error(errors.map((error) => `- ${error}`).join("\n"));
  process.exit(1);
}
console.log(
  `Chapter 4 topology valid: ${topology.nodes.length} legacy floors, ${topology.connectors.length} connectors, `
  + `${layout.floors.length} runtime floors, ${topology.puzzleOrder.length} puzzles.`
);
