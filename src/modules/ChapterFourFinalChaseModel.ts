export type ChapterFourFinalChasePhase =
  | "arming"
  | "running"
  | "portal_transfer"
  | "finish_pending"
  | "failure_pending"
  | "complete";

export type ChapterFourFinalChaseFloor = "A1" | "A2";

export interface ChapterFourFinalChasePoint {
  x: number;
  y: number;
}

export type ChapterFourFinalChaseWaypointId =
  | "a1_guard_spawn"
  | "a1_chase_start"
  | "a1_bakery_dead_end"
  | "a1_lower_hall"
  | "a1_central"
  | "a1_main_stair"
  | "a2_main_stair_arrival"
  | "a2_core_east"
  | "a2_east_south"
  | "a2_room202_outer"
  | "a2_room202_finish"
  | "a2_room203_dead_end";

export interface ChapterFourFinalChaseWaypoint extends ChapterFourFinalChasePoint {
  id: ChapterFourFinalChaseWaypointId;
  floor: ChapterFourFinalChaseFloor;
  neighborIds: readonly ChapterFourFinalChaseWaypointId[];
  role: "spawn" | "route" | "portal" | "finish" | "decoy";
}

export interface ChapterFourFinalChaseState {
  phase: ChapterFourFinalChasePhase;
  attempt: number;
  stableCommittedFrames: number;
  floor: ChapterFourFinalChaseFloor;
  guardFloor: ChapterFourFinalChaseFloor;
  guardTargetWaypointId: ChapterFourFinalChaseWaypointId;
  portalApplied: boolean;
  portalRemainingDistance: number;
  finishRequestIssued: boolean;
  failureRequestIssued: boolean;
  elapsedMs: number;
  lastPlayerPosition: ChapterFourFinalChasePoint;
  predictedPlayerPosition: ChapterFourFinalChasePoint;
  guardTargetHoldMs: number;
  contactHoldMs: number;
  contactGraceRemainingMs: number;
  pursuitSpeed: number;
  pursuitBand: "catch_up" | "tracking" | "close";
}

export interface ChapterFourFinalChaseStepInput {
  deltaMs: number;
  committedAndApplied: boolean;
  floor: ChapterFourFinalChaseFloor;
  playerPosition: ChapterFourFinalChasePoint;
  guardPosition: ChapterFourFinalChasePoint;
  playerInsideFinish: boolean;
  playerEnteredMainStair: boolean;
  guardContact: boolean;
}

export interface ChapterFourFinalChaseStepResult {
  state: ChapterFourFinalChaseState;
  desiredGuardVelocity: ChapterFourFinalChasePoint;
  guardVisible: boolean;
  portalRequested: boolean;
  finishRequested: boolean;
  failureRequested: boolean;
  guardPortalArrival: boolean;
  remainingRouteDistance: number;
  guardToPlayerRouteDistance: number;
}

export const CHAPTER_FOUR_FINAL_CHASE_RULES = Object.freeze({
  stableFramesToArm: 4,
  playerSpeed: 208,
  guardSpeed: 196,
  catchUpSpeed: 224,
  closeSpeed: 178,
  catchDistance: 22,
  predictionMs: 320,
  targetHoldMs: 260,
  waypointReachDistance: 34,
  catchUpDistance: 420,
  closeDistance: 120,
  startContactGraceMs: 700,
  portalContactGraceMs: 420,
  contactConfirmMs: 180,
  maxStepMs: 50,
  finishBeforeContact: true,
  transportId: "main_stair" as const,
  restartCheckpoint: "c4_a1_lobby" as const
});

export const CHAPTER_FOUR_FINAL_CHASE_POINTS = Object.freeze({
  playerStart: Object.freeze({ x: 590, y: 612 }),
  guardSpawn: Object.freeze({ x: 590, y: 724 }),
  a1LowerHall: Object.freeze({ x: 836, y: 540 }),
  a1Central: Object.freeze({ x: 836, y: 228 }),
  a1Stair: Object.freeze({ x: 1001, y: 214 }),
  a2Arrival: Object.freeze({ x: 966, y: 214 }),
  a2CoreEast: Object.freeze({ x: 1100, y: 232 }),
  a2EastSouth: Object.freeze({ x: 1100, y: 400 }),
  room202Outer: Object.freeze({ x: 1353, y: 400 }),
  finishThreshold: Object.freeze({ x: 1353, y: 356.5 }),
  finalMinuteSpawn: Object.freeze({ x: 1353, y: 320 }),
  bakeryDeadEnd: Object.freeze({ x: 318, y: 648 }),
  room203DeadEnd: Object.freeze({ x: 1353, y: 524 })
});

const WAYPOINTS: Readonly<Record<ChapterFourFinalChaseWaypointId, ChapterFourFinalChaseWaypoint>> =
  Object.freeze({
    a1_guard_spawn: waypoint("a1_guard_spawn", "A1", CHAPTER_FOUR_FINAL_CHASE_POINTS.guardSpawn, ["a1_chase_start"], "spawn"),
    a1_chase_start: waypoint("a1_chase_start", "A1", CHAPTER_FOUR_FINAL_CHASE_POINTS.playerStart, ["a1_guard_spawn", "a1_bakery_dead_end", "a1_lower_hall"], "route"),
    a1_bakery_dead_end: waypoint("a1_bakery_dead_end", "A1", CHAPTER_FOUR_FINAL_CHASE_POINTS.bakeryDeadEnd, ["a1_chase_start"], "decoy"),
    a1_lower_hall: waypoint("a1_lower_hall", "A1", CHAPTER_FOUR_FINAL_CHASE_POINTS.a1LowerHall, ["a1_chase_start", "a1_central"], "route"),
    a1_central: waypoint("a1_central", "A1", CHAPTER_FOUR_FINAL_CHASE_POINTS.a1Central, ["a1_lower_hall", "a1_main_stair"], "route"),
    a1_main_stair: waypoint("a1_main_stair", "A1", CHAPTER_FOUR_FINAL_CHASE_POINTS.a1Stair, ["a1_central"], "portal"),
    a2_main_stair_arrival: waypoint("a2_main_stair_arrival", "A2", CHAPTER_FOUR_FINAL_CHASE_POINTS.a2Arrival, ["a2_core_east"], "portal"),
    a2_core_east: waypoint("a2_core_east", "A2", CHAPTER_FOUR_FINAL_CHASE_POINTS.a2CoreEast, ["a2_main_stair_arrival", "a2_east_south"], "route"),
    a2_east_south: waypoint("a2_east_south", "A2", CHAPTER_FOUR_FINAL_CHASE_POINTS.a2EastSouth, ["a2_core_east", "a2_room202_outer", "a2_room203_dead_end"], "route"),
    a2_room202_outer: waypoint("a2_room202_outer", "A2", CHAPTER_FOUR_FINAL_CHASE_POINTS.room202Outer, ["a2_east_south", "a2_room202_finish"], "route"),
    a2_room202_finish: waypoint("a2_room202_finish", "A2", CHAPTER_FOUR_FINAL_CHASE_POINTS.finishThreshold, ["a2_room202_outer"], "finish"),
    a2_room203_dead_end: waypoint("a2_room203_dead_end", "A2", CHAPTER_FOUR_FINAL_CHASE_POINTS.room203DeadEnd, ["a2_east_south"], "decoy")
  });

export const CHAPTER_FOUR_FINAL_CHASE_WAYPOINTS = Object.freeze(
  Object.values(WAYPOINTS)
);

export function createChapterFourFinalChaseState(attempt: number): ChapterFourFinalChaseState {
  return {
    phase: "arming",
    attempt: normalizeAttempt(attempt),
    stableCommittedFrames: 0,
    floor: "A1",
    guardFloor: "A1",
    guardTargetWaypointId: "a1_chase_start",
    portalApplied: false,
    portalRemainingDistance: 0,
    finishRequestIssued: false,
    failureRequestIssued: false,
    elapsedMs: 0,
    lastPlayerPosition: { ...CHAPTER_FOUR_FINAL_CHASE_POINTS.playerStart },
    predictedPlayerPosition: { ...CHAPTER_FOUR_FINAL_CHASE_POINTS.playerStart },
    guardTargetHoldMs: 0,
    contactHoldMs: 0,
    contactGraceRemainingMs: CHAPTER_FOUR_FINAL_CHASE_RULES.startContactGraceMs,
    pursuitSpeed: CHAPTER_FOUR_FINAL_CHASE_RULES.guardSpeed,
    pursuitBand: "tracking"
  };
}

export function stepChapterFourFinalChase(
  state: Readonly<ChapterFourFinalChaseState>,
  input: Readonly<ChapterFourFinalChaseStepInput>
): ChapterFourFinalChaseStepResult {
  const slices = chapterFourFinalChaseDeltaSlices(input.deltaMs);
  const deltaMs = slices.reduce((total, slice) => total + slice, 0);
  const predictedPlayerPosition = predictPlayerPosition(state.lastPlayerPosition, input.playerPosition, deltaMs);
  const base = {
    ...state,
    elapsedMs: state.elapsedMs + deltaMs,
    lastPlayerPosition: { ...input.playerPosition },
    predictedPlayerPosition
  };
  if (state.phase === "complete" || state.phase === "finish_pending" || state.phase === "failure_pending") {
    return result(base, ZERO, false, false, false, false, false, 0, 0);
  }

  if (state.phase === "arming") {
    const stableCommittedFrames = input.committedAndApplied
      ? Math.min(CHAPTER_FOUR_FINAL_CHASE_RULES.stableFramesToArm, state.stableCommittedFrames + 1)
      : 0;
    const armed = stableCommittedFrames >= CHAPTER_FOUR_FINAL_CHASE_RULES.stableFramesToArm;
    const next = {
      ...base,
      stableCommittedFrames,
      phase: armed ? "running" as const : "arming" as const
    };
    return result(next, ZERO, armed, false, false, false, false, routeDistanceToFinish(
      input.floor,
      input.playerPosition
    ), distanceBetweenActorsOnGraph(input.floor, input.guardPosition, predictedPlayerPosition));
  }

  if (state.phase === "portal_transfer") {
    if (!state.portalApplied) {
      const velocity = velocityToward(input.guardPosition, CHAPTER_FOUR_FINAL_CHASE_POINTS.a1Stair, state.pursuitSpeed);
      return result(
        { ...base, guardTargetWaypointId: "a1_main_stair" },
        velocity,
        true,
        false,
        false,
        false,
        false,
        state.portalRemainingDistance,
        state.portalRemainingDistance
      );
    }
    const remaining = slices.reduce((distance, slice) => Math.max(
      0,
      distance - CHAPTER_FOUR_FINAL_CHASE_RULES.guardSpeed * slice / 1000
    ), state.portalRemainingDistance);
    const arrived = remaining === 0;
    const next: ChapterFourFinalChaseState = arrived
      ? {
          ...base,
          phase: "running",
          floor: "A2",
          guardFloor: "A2",
          guardTargetWaypointId: "a2_core_east",
          portalRemainingDistance: 0,
          guardTargetHoldMs: CHAPTER_FOUR_FINAL_CHASE_RULES.targetHoldMs,
          contactHoldMs: 0,
          contactGraceRemainingMs: CHAPTER_FOUR_FINAL_CHASE_RULES.portalContactGraceMs
        }
      : { ...base, portalRemainingDistance: remaining };
    return result(next, ZERO, arrived, false, false, false, arrived, remaining, remaining);
  }

  // The 202 threshold wins over guard contact when both become true on the
  // same committed frame. This ordering is part of the chase fairness contract.
  const finishRequestIssued = input.playerInsideFinish ? state.finishRequestIssued : false;
  if (input.floor === "A2" && input.playerInsideFinish && !finishRequestIssued) {
    return result(
      { ...base, phase: "finish_pending", floor: "A2", finishRequestIssued: true },
      ZERO,
      false,
      false,
      true,
      false,
      false,
      0,
      0
    );
  }
  // Reaching the authored stair aperture also wins over a one-frame corner
  // touch. The guard continues through the abstract transfer distance.
  if (input.floor === "A1" && input.playerEnteredMainStair) {
    const remaining = distanceToWaypointThroughGraph(
      "A1",
      input.guardPosition,
      "a1_main_stair"
    );
    return result(
      {
        ...base,
        phase: "portal_transfer",
        floor: "A1",
        guardFloor: "A1",
        guardTargetWaypointId: "a1_main_stair",
        portalApplied: false,
        portalRemainingDistance: remaining
      },
      velocityToward(input.guardPosition, CHAPTER_FOUR_FINAL_CHASE_POINTS.a1Stair, state.pursuitSpeed),
      true,
      true,
      false,
      false,
      false,
      remaining,
      remaining
    );
  }

  const contactGraceRemainingMs = Math.max(0, state.contactGraceRemainingMs - deltaMs);
  let contactHoldMs = 0;
  if (input.guardContact) {
    contactHoldMs = contactGraceRemainingMs === 0
      ? Math.min(CHAPTER_FOUR_FINAL_CHASE_RULES.contactConfirmMs, state.contactHoldMs + deltaMs)
      : 0;
  }
  const failureRequestIssued = contactHoldMs >= CHAPTER_FOUR_FINAL_CHASE_RULES.contactConfirmMs
    ? state.failureRequestIssued
    : false;
  if (contactHoldMs >= CHAPTER_FOUR_FINAL_CHASE_RULES.contactConfirmMs && !failureRequestIssued) {
    return result(
      {
        ...base,
        phase: "failure_pending",
        failureRequestIssued: true,
        contactHoldMs,
        contactGraceRemainingMs
      },
      ZERO,
      false,
      false,
      false,
      true,
      false,
      routeDistanceToFinish(input.floor, input.playerPosition),
      0
    );
  }

  const floor = input.floor;
  const targetHoldRemainingMs = Math.max(0, state.guardTargetHoldMs - deltaMs);
  const guardTargetWaypointId = selectGuardTargetWaypoint(
    floor,
    input.guardPosition,
    predictedPlayerPosition,
    state.guardTargetWaypointId,
    targetHoldRemainingMs
  );
  const target = WAYPOINTS[guardTargetWaypointId];
  const targetChanged = guardTargetWaypointId !== state.guardTargetWaypointId;
  const guardToPlayerRouteDistance = distanceBetweenActorsOnGraph(
    floor,
    input.guardPosition,
    predictedPlayerPosition
  );
  const pursuitBand = guardToPlayerRouteDistance > CHAPTER_FOUR_FINAL_CHASE_RULES.catchUpDistance
    ? "catch_up" as const
    : guardToPlayerRouteDistance < CHAPTER_FOUR_FINAL_CHASE_RULES.closeDistance
      ? "close" as const
      : "tracking" as const;
  const pursuitSpeed = pursuitBand === "catch_up"
    ? CHAPTER_FOUR_FINAL_CHASE_RULES.catchUpSpeed
    : pursuitBand === "close"
      ? CHAPTER_FOUR_FINAL_CHASE_RULES.closeSpeed
      : CHAPTER_FOUR_FINAL_CHASE_RULES.guardSpeed;
  return result(
    {
      ...base,
      floor,
      guardFloor: floor,
      guardTargetWaypointId,
      guardTargetHoldMs: targetChanged
        ? CHAPTER_FOUR_FINAL_CHASE_RULES.targetHoldMs
        : targetHoldRemainingMs,
      contactHoldMs,
      contactGraceRemainingMs,
      pursuitSpeed,
      pursuitBand,
      finishRequestIssued,
      failureRequestIssued
    },
    velocityToward(input.guardPosition, target, pursuitSpeed),
    true,
    false,
    false,
    false,
    false,
    routeDistanceToFinish(floor, input.playerPosition),
    guardToPlayerRouteDistance
  );
}

export function resolveChapterFourFinalChasePortal(
  state: Readonly<ChapterFourFinalChaseState>,
  accepted: boolean
): ChapterFourFinalChaseState {
  if (state.phase !== "portal_transfer" || state.portalApplied) return { ...state };
  return accepted
    ? { ...state, portalApplied: true, floor: "A2" }
    : { ...state, phase: "running", portalApplied: false, portalRemainingDistance: 0 };
}

export function resolveChapterFourFinalChaseFinish(
  state: Readonly<ChapterFourFinalChaseState>,
  accepted: boolean
): ChapterFourFinalChaseState {
  if (state.phase !== "finish_pending") return { ...state };
  return accepted
    ? { ...state, phase: "complete", floor: "A2", guardFloor: "A2" }
    : { ...state, phase: "running", floor: "A2", guardFloor: "A2" };
}

export function resolveChapterFourFinalChaseFailure(
  state: Readonly<ChapterFourFinalChaseState>,
  accepted: boolean
): ChapterFourFinalChaseState {
  if (state.phase !== "failure_pending") return { ...state };
  return accepted ? { ...state, phase: "complete" } : { ...state, phase: "running" };
}

export function isChapterFourFinalChaseAttemptCurrent(
  state: Readonly<ChapterFourFinalChaseState>,
  expectedAttempt: number
): boolean {
  return state.attempt === normalizeAttempt(expectedAttempt);
}

export function chapterFourFinalChaseFootContact(
  guardFootCenter: Readonly<ChapterFourFinalChasePoint>,
  playerFootBounds: Readonly<{ x: number; y: number; width: number; height: number }>,
  catchDistance = CHAPTER_FOUR_FINAL_CHASE_RULES.catchDistance
): boolean {
  const nearestX = clamp(guardFootCenter.x, playerFootBounds.x, playerFootBounds.x + playerFootBounds.width);
  const nearestY = clamp(guardFootCenter.y, playerFootBounds.y, playerFootBounds.y + playerFootBounds.height);
  return Math.hypot(guardFootCenter.x - nearestX, guardFootCenter.y - nearestY) <= catchDistance;
}

export function chapterFourFinalChaseDeltaSlices(deltaMs: number): number[] {
  let remaining = clampDelta(deltaMs);
  const slices: number[] = [];
  while (remaining > 0) {
    const slice = Math.min(CHAPTER_FOUR_FINAL_CHASE_RULES.maxStepMs, remaining);
    slices.push(slice);
    remaining -= slice;
  }
  return slices;
}

function waypoint(
  id: ChapterFourFinalChaseWaypointId,
  floor: ChapterFourFinalChaseFloor,
  point: Readonly<ChapterFourFinalChasePoint>,
  neighborIds: readonly ChapterFourFinalChaseWaypointId[],
  role: ChapterFourFinalChaseWaypoint["role"]
): ChapterFourFinalChaseWaypoint {
  return Object.freeze({ id, floor, x: point.x, y: point.y, neighborIds: Object.freeze([...neighborIds]), role });
}

function selectGuardTargetWaypoint(
  floor: ChapterFourFinalChaseFloor,
  guardPosition: Readonly<ChapterFourFinalChasePoint>,
  playerPosition: Readonly<ChapterFourFinalChasePoint>,
  currentTargetId: ChapterFourFinalChaseWaypointId,
  targetHoldRemainingMs: number
): ChapterFourFinalChaseWaypointId {
  const currentTarget = WAYPOINTS[currentTargetId];
  if (
    currentTarget.floor === floor
    && targetHoldRemainingMs > 0
    && pointDistance(guardPosition, currentTarget) > CHAPTER_FOUR_FINAL_CHASE_RULES.waypointReachDistance
  ) {
    return currentTargetId;
  }
  const guardNode = nearestWaypoint(floor, guardPosition);
  const playerNode = nearestWaypoint(floor, playerPosition);
  if (guardNode.id === playerNode.id) return playerNode.id;
  const path = shortestWaypointPath(guardNode.id, playerNode.id);
  return path[1] ?? playerNode.id;
}

function predictPlayerPosition(
  previous: Readonly<ChapterFourFinalChasePoint>,
  current: Readonly<ChapterFourFinalChasePoint>,
  deltaMs: number
): ChapterFourFinalChasePoint {
  if (deltaMs <= 0) return { ...current };
  const dx = current.x - previous.x;
  const dy = current.y - previous.y;
  const distance = Math.hypot(dx, dy);
  if (distance < 0.001) return { ...current };
  const maximumSampleDistance = CHAPTER_FOUR_FINAL_CHASE_RULES.playerSpeed * deltaMs / 1000 * 1.35;
  const sampleScale = Math.min(1, maximumSampleDistance / distance);
  const leadScale = CHAPTER_FOUR_FINAL_CHASE_RULES.predictionMs / deltaMs;
  return {
    x: current.x + dx * sampleScale * leadScale,
    y: current.y + dy * sampleScale * leadScale
  };
}

function distanceBetweenActorsOnGraph(
  floor: ChapterFourFinalChaseFloor,
  guardPosition: Readonly<ChapterFourFinalChasePoint>,
  playerPosition: Readonly<ChapterFourFinalChasePoint>
): number {
  const guardNode = nearestWaypoint(floor, guardPosition);
  const playerNode = nearestWaypoint(floor, playerPosition);
  const path = shortestWaypointPath(guardNode.id, playerNode.id);
  let distance = pointDistance(guardPosition, guardNode) + pointDistance(playerPosition, playerNode);
  for (let index = 1; index < path.length; index += 1) {
    distance += pointDistance(WAYPOINTS[path[index - 1]], WAYPOINTS[path[index]]);
  }
  return distance;
}

function nearestWaypoint(
  floor: ChapterFourFinalChaseFloor,
  position: Readonly<ChapterFourFinalChasePoint>
): ChapterFourFinalChaseWaypoint {
  const candidates = CHAPTER_FOUR_FINAL_CHASE_WAYPOINTS.filter((entry) => entry.floor === floor);
  return candidates.reduce((best, candidate) => (
    pointDistance(candidate, position) < pointDistance(best, position) ? candidate : best
  ));
}

function shortestWaypointPath(
  fromId: ChapterFourFinalChaseWaypointId,
  toId: ChapterFourFinalChaseWaypointId
): ChapterFourFinalChaseWaypointId[] {
  if (fromId === toId) return [fromId];
  const floor = WAYPOINTS[fromId].floor;
  if (WAYPOINTS[toId].floor !== floor) return [fromId];
  const distances = new Map<ChapterFourFinalChaseWaypointId, number>([[fromId, 0]]);
  const previous = new Map<ChapterFourFinalChaseWaypointId, ChapterFourFinalChaseWaypointId>();
  const open = new Set(
    CHAPTER_FOUR_FINAL_CHASE_WAYPOINTS.filter((entry) => entry.floor === floor).map((entry) => entry.id)
  );
  while (open.size > 0) {
    let current: ChapterFourFinalChaseWaypointId | null = null;
    let currentDistance = Number.POSITIVE_INFINITY;
    for (const candidate of open) {
      const distance = distances.get(candidate) ?? Number.POSITIVE_INFINITY;
      if (distance < currentDistance) {
        current = candidate;
        currentDistance = distance;
      }
    }
    if (!current || currentDistance === Number.POSITIVE_INFINITY) break;
    open.delete(current);
    if (current === toId) break;
    for (const neighborId of WAYPOINTS[current].neighborIds) {
      if (!open.has(neighborId) || WAYPOINTS[neighborId].floor !== floor) continue;
      const candidateDistance = currentDistance + pointDistance(WAYPOINTS[current], WAYPOINTS[neighborId]);
      if (candidateDistance < (distances.get(neighborId) ?? Number.POSITIVE_INFINITY)) {
        distances.set(neighborId, candidateDistance);
        previous.set(neighborId, current);
      }
    }
  }
  if (!distances.has(toId)) return [fromId];
  const path: ChapterFourFinalChaseWaypointId[] = [toId];
  let cursor = toId;
  while (cursor !== fromId) {
    const parent = previous.get(cursor);
    if (!parent) return [fromId];
    path.unshift(parent);
    cursor = parent;
  }
  return path;
}

function distanceToWaypointThroughGraph(
  floor: ChapterFourFinalChaseFloor,
  position: Readonly<ChapterFourFinalChasePoint>,
  targetId: ChapterFourFinalChaseWaypointId
): number {
  const nearest = nearestWaypoint(floor, position);
  const path = shortestWaypointPath(nearest.id, targetId);
  let distance = pointDistance(position, nearest);
  for (let index = 1; index < path.length; index += 1) {
    distance += pointDistance(WAYPOINTS[path[index - 1]], WAYPOINTS[path[index]]);
  }
  return distance;
}

function routeDistanceToFinish(
  floor: ChapterFourFinalChaseFloor,
  playerPosition: Readonly<ChapterFourFinalChasePoint>
): number {
  if (floor === "A1") {
    return distanceToWaypointThroughGraph("A1", playerPosition, "a1_main_stair")
      + distanceToWaypointThroughGraph("A2", CHAPTER_FOUR_FINAL_CHASE_POINTS.a2Arrival, "a2_room202_finish");
  }
  return distanceToWaypointThroughGraph("A2", playerPosition, "a2_room202_finish");
}

function velocityToward(
  from: Readonly<ChapterFourFinalChasePoint>,
  to: Readonly<ChapterFourFinalChasePoint>,
  speed: number = CHAPTER_FOUR_FINAL_CHASE_RULES.guardSpeed
): ChapterFourFinalChasePoint {
  const dx = to.x - from.x;
  const dy = to.y - from.y;
  const distance = Math.hypot(dx, dy);
  if (distance < 0.001) return ZERO;
  const scale = speed / distance;
  return { x: dx * scale, y: dy * scale };
}

function result(
  state: ChapterFourFinalChaseState,
  desiredGuardVelocity: Readonly<ChapterFourFinalChasePoint>,
  guardVisible: boolean,
  portalRequested: boolean,
  finishRequested: boolean,
  failureRequested: boolean,
  guardPortalArrival: boolean,
  remainingRouteDistance: number,
  guardToPlayerRouteDistance: number
): ChapterFourFinalChaseStepResult {
  return {
    state,
    desiredGuardVelocity: { ...desiredGuardVelocity },
    guardVisible,
    portalRequested,
    finishRequested,
    failureRequested,
    guardPortalArrival,
    remainingRouteDistance,
    guardToPlayerRouteDistance
  };
}

function pointDistance(
  a: Readonly<ChapterFourFinalChasePoint>,
  b: Readonly<ChapterFourFinalChasePoint>
): number {
  return Math.hypot(a.x - b.x, a.y - b.y);
}

function normalizeAttempt(value: number): number {
  return Number.isSafeInteger(value) && value >= 0 ? value : 0;
}

function clampDelta(value: number): number {
  return Number.isFinite(value) ? Math.max(0, Math.min(value, 1000)) : 0;
}

function clamp(value: number, minimum: number, maximum: number): number {
  return Math.max(minimum, Math.min(maximum, value));
}

const ZERO = Object.freeze({ x: 0, y: 0 });
