export type ChapterFourMaintenanceGuardMode =
  | "patrol"
  | "confirming"
  | "pursuit"
  | "returning";

export interface ChapterFourGuardPoint {
  x: number;
  y: number;
}

export interface ChapterFourGuardHalfOpenRect {
  x: number;
  y: number;
  width: number;
  height: number;
}

export interface ChapterFourGuardWaypoint extends ChapterFourGuardPoint {
  id: ChapterFourGuardWaypointId;
  neighborIds: readonly ChapterFourGuardWaypointId[];
}

export type ChapterFourGuardWaypointId =
  | "stair_north"
  | "west_north"
  | "east_north"
  | "east_south"
  | "west_south";

export interface ChapterFourMaintenanceGuardState {
  mode: ChapterFourMaintenanceGuardMode;
  position: ChapterFourGuardPoint;
  heading: ChapterFourGuardPoint;
  previousWaypointId: ChapterFourGuardWaypointId | null;
  targetWaypointId: ChapterFourGuardWaypointId;
  pauseRemainingMs: number;
  visibleForMs: number;
  sightLostForMs: number;
  lastVisiblePosition: ChapterFourGuardPoint | null;
  rngState: number;
}

export interface ChapterFourMaintenanceGuardStepInput {
  deltaMs: number;
  /**
   * Authoritative foot-box centre measured from the runtime body at the start
   * of this step. The pure model predicts intent from that physical position;
   * it does not own an independent scene transform.
   */
  guardPosition: ChapterFourGuardPoint;
  playerPosition: ChapterFourGuardPoint;
  walls: readonly ChapterFourGuardHalfOpenRect[];
}

export interface ChapterFourMaintenanceGuardStepResult {
  state: ChapterFourMaintenanceGuardState;
  desiredVelocity: ChapterFourGuardPoint;
  playerVisible: boolean;
  enteredPursuit: boolean;
  disengaged: boolean;
}

export const CHAPTER_FOUR_MAINTENANCE_GUARD_RULES = Object.freeze({
  confirmationMs: 400,
  sightLossMs: 900,
  coneRange: 220,
  coneHalfAngleDegrees: 36,
  closeRadius: 56,
  patrolSpeed: 84,
  pursuitSpeed: 140,
  returnSpeed: 96,
  pauseMinMs: 1000,
  pauseMaxMs: 2000,
  maxStepMs: 50,
  footBox: Object.freeze({ width: 20, height: 16 })
});

export const CHAPTER_FOUR_MAINTENANCE_PATROL_WAYPOINTS: Readonly<
  Record<ChapterFourGuardWaypointId, ChapterFourGuardWaypoint>
> = Object.freeze({
  stair_north: Object.freeze({
    id: "stair_north",
    x: 1001,
    y: 240,
    neighborIds: Object.freeze(["west_north", "east_north"] as const)
  }),
  west_north: Object.freeze({
    id: "west_north",
    x: 588,
    y: 220,
    neighborIds: Object.freeze(["stair_north", "west_south"] as const)
  }),
  east_north: Object.freeze({
    id: "east_north",
    x: 1105,
    y: 240,
    neighborIds: Object.freeze(["stair_north", "east_south"] as const)
  }),
  east_south: Object.freeze({
    id: "east_south",
    x: 1105,
    y: 560,
    neighborIds: Object.freeze(["east_north", "west_south"] as const)
  }),
  west_south: Object.freeze({
    id: "west_south",
    x: 588,
    y: 560,
    neighborIds: Object.freeze(["east_south", "west_north"] as const)
  })
});

const EPSILON = 1e-7;

export function createChapterFourMaintenanceGuardState(
  seed = 0x7552245
): ChapterFourMaintenanceGuardState {
  return {
    mode: "patrol",
    position: { x: 1105, y: 560 },
    heading: { x: -1, y: 0 },
    previousWaypointId: "east_south",
    targetWaypointId: "west_south",
    pauseRemainingMs: 0,
    visibleForMs: 0,
    sightLostForMs: 0,
    lastVisiblePosition: null,
    rngState: normalizeSeed(seed)
  };
}

export function createChapterFourMaintenanceGuardRecoveryState(
  seed = 0x7552245
): ChapterFourMaintenanceGuardState {
  const state = createChapterFourMaintenanceGuardState(seed);
  return {
    ...state,
    position: { x: 588, y: 220 },
    heading: normalizedDirection({ x: 588, y: 220 }, { x: 1001, y: 240 }),
    previousWaypointId: "west_north",
    targetWaypointId: "stair_north"
  };
}

export function stepChapterFourMaintenanceGuard(
  source: ChapterFourMaintenanceGuardState,
  input: ChapterFourMaintenanceGuardStepInput
): ChapterFourMaintenanceGuardStepResult {
  const totalMs = Math.max(0, Number.isFinite(input.deltaMs) ? input.deltaMs : 0);
  const physicalPosition = finitePointOr(input.guardPosition, source.position);
  let state = {
    ...cloneGuardState(source),
    position: physicalPosition
  };
  const startPosition = { ...state.position };
  let remainingMs = totalMs;
  let playerVisible = canChapterFourGuardSeePlayer(
    state,
    input.playerPosition,
    input.walls
  );
  let enteredPursuit = false;
  let disengaged = false;

  if (remainingMs === 0) {
    return {
      state,
      desiredVelocity: { x: 0, y: 0 },
      playerVisible,
      enteredPursuit,
      disengaged
    };
  }

  while (remainingMs > 0) {
    const stepMs = Math.min(remainingMs, CHAPTER_FOUR_MAINTENANCE_GUARD_RULES.maxStepMs);
    remainingMs -= stepMs;
    const result = stepGuardSlice(state, input.playerPosition, input.walls, stepMs);
    state = result.state;
    playerVisible = result.playerVisible;
    enteredPursuit = enteredPursuit || result.enteredPursuit;
    disengaged = disengaged || result.disengaged;
  }

  return {
    state,
    desiredVelocity: {
      x: (state.position.x - startPosition.x) * 1000 / totalMs,
      y: (state.position.y - startPosition.y) * 1000 / totalMs
    },
    playerVisible,
    enteredPursuit,
    disengaged
  };
}

export function canChapterFourGuardSeePlayer(
  state: Pick<ChapterFourMaintenanceGuardState, "position" | "heading">,
  playerPosition: ChapterFourGuardPoint,
  walls: readonly ChapterFourGuardHalfOpenRect[]
): boolean {
  if (!hasChapterFourGuardLineOfSight(state.position, playerPosition, walls)) return false;
  const dx = playerPosition.x - state.position.x;
  const dy = playerPosition.y - state.position.y;
  const distance = Math.hypot(dx, dy);
  if (distance <= CHAPTER_FOUR_MAINTENANCE_GUARD_RULES.closeRadius) return true;
  if (distance > CHAPTER_FOUR_MAINTENANCE_GUARD_RULES.coneRange || distance <= EPSILON) {
    return false;
  }
  const headingLength = Math.hypot(state.heading.x, state.heading.y);
  if (headingLength <= EPSILON) return false;
  const dot = (
    (dx / distance) * (state.heading.x / headingLength)
    + (dy / distance) * (state.heading.y / headingLength)
  );
  const threshold = Math.cos(
    CHAPTER_FOUR_MAINTENANCE_GUARD_RULES.coneHalfAngleDegrees * Math.PI / 180
  );
  return dot + EPSILON >= threshold;
}

export function hasChapterFourGuardLineOfSight(
  from: ChapterFourGuardPoint,
  to: ChapterFourGuardPoint,
  walls: readonly ChapterFourGuardHalfOpenRect[]
): boolean {
  return !walls.some((wall) => segmentIntersectsHalfOpenRect(from, to, wall));
}

export function chapterFourGuardFootBox(
  footCenter: ChapterFourGuardPoint
): ChapterFourGuardHalfOpenRect {
  const { width, height } = CHAPTER_FOUR_MAINTENANCE_GUARD_RULES.footBox;
  return {
    x: footCenter.x - width / 2,
    y: footCenter.y - height / 2,
    width,
    height
  };
}

export function chapterFourGuardFootContact(
  guardFootCenter: ChapterFourGuardPoint,
  playerFootBounds: ChapterFourGuardHalfOpenRect
): boolean {
  return halfOpenRectsOverlap(chapterFourGuardFootBox(guardFootCenter), playerFootBounds);
}

export function halfOpenRectsOverlap(
  a: ChapterFourGuardHalfOpenRect,
  b: ChapterFourGuardHalfOpenRect
): boolean {
  return a.x < b.x + b.width
    && a.x + a.width > b.x
    && a.y < b.y + b.height
    && a.y + a.height > b.y;
}

function stepGuardSlice(
  source: ChapterFourMaintenanceGuardState,
  playerPosition: ChapterFourGuardPoint,
  walls: readonly ChapterFourGuardHalfOpenRect[],
  deltaMs: number
): Omit<ChapterFourMaintenanceGuardStepResult, "desiredVelocity"> {
  let state = cloneGuardState(source);
  const playerVisible = canChapterFourGuardSeePlayer(state, playerPosition, walls);
  let enteredPursuit = false;
  let disengaged = false;

  if (state.mode === "patrol" || state.mode === "returning") {
    if (playerVisible) {
      state = {
        ...state,
        mode: "confirming",
        visibleForMs: deltaMs,
        sightLostForMs: 0,
        lastVisiblePosition: { ...playerPosition },
        pauseRemainingMs: 0
      };
    } else {
      state = state.mode === "patrol"
        ? advancePatrol(state, deltaMs)
        : advanceReturning(state, deltaMs, walls);
    }
  } else if (state.mode === "confirming") {
    if (!playerVisible) {
      state = {
        ...state,
        mode: "patrol",
        visibleForMs: 0,
        sightLostForMs: 0,
        lastVisiblePosition: null
      };
    } else {
      const visibleForMs = state.visibleForMs + deltaMs;
      state = {
        ...state,
        visibleForMs,
        lastVisiblePosition: { ...playerPosition },
        heading: normalizedDirection(state.position, playerPosition)
      };
      if (visibleForMs + EPSILON >= CHAPTER_FOUR_MAINTENANCE_GUARD_RULES.confirmationMs) {
        state = {
          ...state,
          mode: "pursuit",
          visibleForMs: CHAPTER_FOUR_MAINTENANCE_GUARD_RULES.confirmationMs,
          sightLostForMs: 0
        };
        enteredPursuit = true;
      }
    }
  } else {
    if (playerVisible) {
      state = {
        ...state,
        sightLostForMs: 0,
        lastVisiblePosition: { ...playerPosition }
      };
    } else {
      state = { ...state, sightLostForMs: state.sightLostForMs + deltaMs };
    }
    const pursuitTarget = playerVisible ? playerPosition : state.lastVisiblePosition;
    if (pursuitTarget) {
      state = moveToward(
        state,
        pursuitTarget,
        CHAPTER_FOUR_MAINTENANCE_GUARD_RULES.pursuitSpeed,
        deltaMs
      );
    }
    if (state.sightLostForMs + EPSILON >= CHAPTER_FOUR_MAINTENANCE_GUARD_RULES.sightLossMs) {
      const targetWaypointId = nearestVisibleWaypointId(state.position, walls);
      state = {
        ...state,
        mode: "returning",
        targetWaypointId,
        previousWaypointId: null,
        visibleForMs: 0,
        sightLostForMs: 0,
        pauseRemainingMs: 0
      };
      disengaged = true;
    }
  }

  return { state, playerVisible, enteredPursuit, disengaged };
}

function advancePatrol(
  state: ChapterFourMaintenanceGuardState,
  deltaMs: number
): ChapterFourMaintenanceGuardState {
  if (state.pauseRemainingMs > 0) {
    return { ...state, pauseRemainingMs: Math.max(0, state.pauseRemainingMs - deltaMs) };
  }
  const target = CHAPTER_FOUR_MAINTENANCE_PATROL_WAYPOINTS[state.targetWaypointId];
  const moved = moveToward(
    state,
    target,
    CHAPTER_FOUR_MAINTENANCE_GUARD_RULES.patrolSpeed,
    deltaMs
  );
  if (pointDistance(moved.position, target) > EPSILON) return moved;

  const random = nextRandom(moved.rngState);
  const choices = target.neighborIds.filter((id) => id !== state.previousWaypointId);
  const candidates = choices.length > 0 ? choices : target.neighborIds;
  const nextIndex = Math.min(candidates.length - 1, Math.floor(random.value * candidates.length));
  const nextTarget = candidates[nextIndex] ?? target.neighborIds[0] ?? target.id;
  return {
    ...moved,
    position: { x: target.x, y: target.y },
    previousWaypointId: target.id,
    targetWaypointId: nextTarget,
    pauseRemainingMs: Math.round(
      CHAPTER_FOUR_MAINTENANCE_GUARD_RULES.pauseMinMs
      + random.value * (
        CHAPTER_FOUR_MAINTENANCE_GUARD_RULES.pauseMaxMs
        - CHAPTER_FOUR_MAINTENANCE_GUARD_RULES.pauseMinMs
      )
    ),
    rngState: random.state
  };
}

function advanceReturning(
  state: ChapterFourMaintenanceGuardState,
  deltaMs: number,
  walls: readonly ChapterFourGuardHalfOpenRect[]
): ChapterFourMaintenanceGuardState {
  const target = CHAPTER_FOUR_MAINTENANCE_PATROL_WAYPOINTS[state.targetWaypointId];
  if (!hasChapterFourGuardLineOfSight(state.position, target, walls)) {
    return { ...state, targetWaypointId: nearestVisibleWaypointId(state.position, walls) };
  }
  const moved = moveToward(
    state,
    target,
    CHAPTER_FOUR_MAINTENANCE_GUARD_RULES.returnSpeed,
    deltaMs
  );
  if (pointDistance(moved.position, target) > EPSILON) return moved;
  const random = nextRandom(moved.rngState);
  const nextId = target.neighborIds[Math.min(
    target.neighborIds.length - 1,
    Math.floor(random.value * target.neighborIds.length)
  )] ?? target.id;
  return {
    ...moved,
    mode: "patrol",
    position: { x: target.x, y: target.y },
    previousWaypointId: target.id,
    targetWaypointId: nextId,
    pauseRemainingMs: Math.round(
      CHAPTER_FOUR_MAINTENANCE_GUARD_RULES.pauseMinMs
      + random.value * (
        CHAPTER_FOUR_MAINTENANCE_GUARD_RULES.pauseMaxMs
        - CHAPTER_FOUR_MAINTENANCE_GUARD_RULES.pauseMinMs
      )
    ),
    rngState: random.state,
    visibleForMs: 0,
    sightLostForMs: 0
  };
}

function nearestVisibleWaypointId(
  position: ChapterFourGuardPoint,
  walls: readonly ChapterFourGuardHalfOpenRect[]
): ChapterFourGuardWaypointId {
  const ordered = Object.values(CHAPTER_FOUR_MAINTENANCE_PATROL_WAYPOINTS)
    .map((waypoint) => ({
      waypoint,
      visible: hasChapterFourGuardLineOfSight(position, waypoint, walls),
      distance: pointDistance(position, waypoint)
    }))
    .sort((a, b) => Number(b.visible) - Number(a.visible) || a.distance - b.distance);
  return ordered[0]?.waypoint.id ?? "east_south";
}

function moveToward(
  state: ChapterFourMaintenanceGuardState,
  target: ChapterFourGuardPoint,
  speed: number,
  deltaMs: number
): ChapterFourMaintenanceGuardState {
  const dx = target.x - state.position.x;
  const dy = target.y - state.position.y;
  const distance = Math.hypot(dx, dy);
  if (distance <= EPSILON) return { ...state, position: { ...target } };
  const step = Math.min(distance, speed * deltaMs / 1000);
  const heading = { x: dx / distance, y: dy / distance };
  return {
    ...state,
    heading,
    position: {
      x: state.position.x + heading.x * step,
      y: state.position.y + heading.y * step
    }
  };
}

function segmentIntersectsHalfOpenRect(
  from: ChapterFourGuardPoint,
  to: ChapterFourGuardPoint,
  rect: ChapterFourGuardHalfOpenRect
): boolean {
  if (rect.width <= 0 || rect.height <= 0) return false;
  if (pointInsideHalfOpenRect(from, rect) || pointInsideHalfOpenRect(to, rect)) return true;

  const dx = to.x - from.x;
  const dy = to.y - from.y;
  let tMin = 0;
  let tMax = 1;
  const axes: readonly [number, number, number, number][] = [
    [from.x, dx, rect.x, rect.x + rect.width],
    [from.y, dy, rect.y, rect.y + rect.height]
  ];
  for (const [origin, delta, min, max] of axes) {
    if (Math.abs(delta) <= EPSILON) {
      if (origin < min || origin > max) return false;
      continue;
    }
    const a = (min - origin) / delta;
    const b = (max - origin) / delta;
    tMin = Math.max(tMin, Math.min(a, b));
    tMax = Math.min(tMax, Math.max(a, b));
    if (tMin - tMax > EPSILON) return false;
  }
  const candidates = [
    tMin,
    (tMin + tMax) / 2,
    tMax,
    Math.min(tMax, tMin + EPSILON)
  ];
  return candidates.some((t) => pointInsideHalfOpenRect({
    x: from.x + dx * t,
    y: from.y + dy * t
  }, rect));
}

function pointInsideHalfOpenRect(
  point: ChapterFourGuardPoint,
  rect: ChapterFourGuardHalfOpenRect
): boolean {
  return point.x >= rect.x
    && point.x < rect.x + rect.width
    && point.y >= rect.y
    && point.y < rect.y + rect.height;
}

function normalizedDirection(
  from: ChapterFourGuardPoint,
  to: ChapterFourGuardPoint
): ChapterFourGuardPoint {
  const dx = to.x - from.x;
  const dy = to.y - from.y;
  const length = Math.hypot(dx, dy);
  return length <= EPSILON ? { x: 0, y: 1 } : { x: dx / length, y: dy / length };
}

function pointDistance(a: ChapterFourGuardPoint, b: ChapterFourGuardPoint): number {
  return Math.hypot(a.x - b.x, a.y - b.y);
}

function cloneGuardState(
  state: ChapterFourMaintenanceGuardState
): ChapterFourMaintenanceGuardState {
  return {
    ...state,
    position: { ...state.position },
    heading: { ...state.heading },
    lastVisiblePosition: state.lastVisiblePosition ? { ...state.lastVisiblePosition } : null
  };
}

function finitePointOr(
  candidate: ChapterFourGuardPoint,
  fallback: ChapterFourGuardPoint
): ChapterFourGuardPoint {
  return Number.isFinite(candidate?.x) && Number.isFinite(candidate?.y)
    ? { x: candidate.x, y: candidate.y }
    : { ...fallback };
}

function normalizeSeed(seed: number): number {
  const normalized = Number.isFinite(seed) ? Math.trunc(seed) >>> 0 : 1;
  return normalized === 0 ? 1 : normalized;
}

function nextRandom(seed: number): { state: number; value: number } {
  const state = (Math.imul(seed, 1664525) + 1013904223) >>> 0;
  return { state, value: state / 0x100000000 };
}
