import type { BikeArcadeObstacleType } from "./BikeArcadeRuntime";

export const BIKE_ARCADE_GOAL = 755;
export const BIKE_ARCADE_MAX_LIVES = 3;
export const BIKE_ARCADE_LANES = 3;
export const BIKE_ARCADE_MILESTONES = [188, 377, 566, 755] as const;
export const BIKE_ARCADE_LANE_CHANGE_MS = 105;
export const BIKE_OBSTACLE_ROW_CLEARANCE_PX = 68;

export type BikeArcadeMilestone = (typeof BIKE_ARCADE_MILESTONES)[number];
export type BikeArcadeLane = 0 | 1 | 2;

export interface BikeObstacleDifficulty {
  minIntervalMs: number;
  maxIntervalMs: number;
  doubleBlockChance: number;
}

export interface BikeObstacleScheduleEntropy {
  safeLane: number;
  density: number;
  blockedLane: number;
  interval: number;
  obstacleTypes: readonly [number, number];
}

export interface BikeObstacleWavePlan {
  distance: number;
  safeLane: BikeArcadeLane;
  spawnDelayMs: number;
  obstacles: ReadonlyArray<{
    lane: BikeArcadeLane;
    type: BikeArcadeObstacleType;
  }>;
}

export interface BikeObstacleWaveInput {
  distance: number;
  previousSafeLane: BikeArcadeLane;
  entropy: BikeObstacleScheduleEntropy;
}

const BIKE_ARCADE_LANE_VALUES: readonly BikeArcadeLane[] = [0, 1, 2];
const BIKE_ARCADE_OBSTACLE_TYPES: readonly BikeArcadeObstacleType[] = [
  "bicycle",
  "barrier",
  "crowd"
];

function clampBikeDistance(distance: number): number {
  if (Number.isNaN(distance)) {
    return 0;
  }
  return Math.min(BIKE_ARCADE_GOAL, Math.max(0, distance));
}

function normalizeEntropy(value: number): number {
  if (!Number.isFinite(value)) {
    return 0;
  }
  return Math.min(0.999_999, Math.max(0, value));
}

function pickByEntropy<T>(values: readonly T[], entropy: number): T {
  return values[Math.floor(normalizeEntropy(entropy) * values.length)];
}

export function moveBikeLane(currentLane: number, direction: -1 | 1): BikeArcadeLane {
  return Math.max(0, Math.min(BIKE_ARCADE_LANES - 1, currentLane + direction)) as BikeArcadeLane;
}

export function advanceBikeDistance(currentDistance: number, deltaMs: number): number {
  const safeDelta = Math.max(0, deltaMs);
  const pace = 0.038 + Math.min(currentDistance, BIKE_ARCADE_GOAL) * 0.000012;
  return Math.min(BIKE_ARCADE_GOAL, currentDistance + safeDelta * pace);
}

export function bikeObstacleSpeed(distance: number): number {
  return 180 + Math.min(BIKE_ARCADE_GOAL, Math.max(0, distance)) * 0.14;
}

export function getCrossedBikeMilestones(
  previousDistance: number,
  nextDistance: number
): BikeArcadeMilestone[] {
  const from = clampBikeDistance(previousDistance);
  const to = clampBikeDistance(nextDistance);
  if (to <= from) {
    return [];
  }
  return BIKE_ARCADE_MILESTONES.filter((milestone) => milestone > from && milestone <= to);
}

export function emitCrossedBikeMilestones(
  previousDistance: number,
  nextDistance: number,
  onMilestone: (milestone: BikeArcadeMilestone) => void
): BikeArcadeMilestone[] {
  const milestones = getCrossedBikeMilestones(previousDistance, nextDistance);
  milestones.forEach((milestone) => onMilestone(milestone));
  return milestones;
}

export function minimumBikeObstacleWaveInterval(distance: number): number {
  const speed = bikeObstacleSpeed(distance);
  const rowClearanceMs = (BIKE_OBSTACLE_ROW_CLEARANCE_PX / speed) * 1000;
  return Math.ceil(rowClearanceMs + BIKE_ARCADE_LANE_CHANGE_MS);
}

export function getBikeObstacleDifficulty(distance: number): BikeObstacleDifficulty {
  const safeDistance = clampBikeDistance(distance);
  const pressure = Math.min(260, safeDistance * 0.22);
  const doubleBlockProgress = Math.max(0, safeDistance - BIKE_ARCADE_MILESTONES[0]) /
    (BIKE_ARCADE_GOAL - BIKE_ARCADE_MILESTONES[0]);
  const solvableFloor = minimumBikeObstacleWaveInterval(safeDistance);

  return {
    minIntervalMs: Math.max(solvableFloor, Math.round(680 - pressure)),
    maxIntervalMs: Math.max(solvableFloor, Math.round(990 - pressure)),
    doubleBlockChance: doubleBlockProgress * 0.62
  };
}

export function planBikeObstacleWave({
  distance,
  previousSafeLane,
  entropy
}: BikeObstacleWaveInput): BikeObstacleWavePlan {
  const safeDistance = clampBikeDistance(distance);
  const difficulty = getBikeObstacleDifficulty(safeDistance);
  const reachableSafeLanes = BIKE_ARCADE_LANE_VALUES.filter(
    (lane) => Math.abs(lane - previousSafeLane) <= 1
  );
  const safeLane = pickByEntropy(reachableSafeLanes, entropy.safeLane);
  const blockedCandidates = BIKE_ARCADE_LANE_VALUES.filter((lane) => lane !== safeLane);
  const blockedLanes = entropy.density < difficulty.doubleBlockChance
    ? blockedCandidates
    : [pickByEntropy(blockedCandidates, entropy.blockedLane)];
  const intervalProgress = normalizeEntropy(entropy.interval);
  const scheduledInterval = difficulty.maxIntervalMs -
    (difficulty.maxIntervalMs - difficulty.minIntervalMs) * intervalProgress;

  return {
    distance: safeDistance,
    safeLane,
    spawnDelayMs: Math.max(
      minimumBikeObstacleWaveInterval(safeDistance),
      Math.round(scheduledInterval)
    ),
    obstacles: blockedLanes.map((lane, index) => ({
      lane,
      type: pickByEntropy(
        BIKE_ARCADE_OBSTACLE_TYPES,
        entropy.obstacleTypes[index] ?? entropy.obstacleTypes[0]
      )
    }))
  };
}

export function isBikeObstacleWaveSolvable(
  plan: BikeObstacleWavePlan,
  previousSafeLane: BikeArcadeLane
): boolean {
  const blockedLanes = plan.obstacles.map((obstacle) => obstacle.lane);
  const uniqueBlockedLanes = new Set(blockedLanes);
  const validSafeLane = BIKE_ARCADE_LANE_VALUES.includes(plan.safeLane);
  const validBlockedLanes = blockedLanes.every((lane) => BIKE_ARCADE_LANE_VALUES.includes(lane));

  return validSafeLane &&
    validBlockedLanes &&
    blockedLanes.length >= 1 &&
    blockedLanes.length <= BIKE_ARCADE_LANES - 1 &&
    uniqueBlockedLanes.size === blockedLanes.length &&
    !uniqueBlockedLanes.has(plan.safeLane) &&
    Math.abs(plan.safeLane - previousSafeLane) <= 1 &&
    Number.isFinite(plan.spawnDelayMs) &&
    plan.spawnDelayMs >= minimumBikeObstacleWaveInterval(plan.distance);
}

export function loseBikeLife(currentLives: number): number {
  return Math.max(0, currentLives - 1);
}
