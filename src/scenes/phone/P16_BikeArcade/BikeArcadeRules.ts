import type { BikeArcadeObstacleType } from "./BikeArcadeRuntime";
import { ENDLESS_ARCADE_SCORE_LIMIT } from "../../../core/EndlessArcadeLimits";

export const BIKE_ARCADE_GOAL = 755;
export const BIKE_ARCADE_MAX_LIVES = 3;
export const BIKE_ARCADE_LANES = 3;
export const BIKE_ARCADE_MILESTONES = [188, 377, 566, 755] as const;
export const BIKE_ARCADE_LANE_CHANGE_MS = 105;
export const BIKE_OBSTACLE_ROW_CLEARANCE_PX = 68;
export const BIKE_ARCADE_STORY_SEED = 0x0755cafe;
export const BIKE_ARCADE_MAX_DISTANCE = 9_999_999;
export const BIKE_ARCADE_MAX_OBSTACLE_SPEED = 360;
export const BIKE_ARCADE_MAX_TIER = 18;
export const BIKE_ARCADE_MAX_COMBO = 9_999;
export const BIKE_ARCADE_MAX_SCORE = ENDLESS_ARCADE_SCORE_LIMIT;
export const MAX_BIKE_ARCADE_OBSTACLES = 10;
export const MAX_BIKE_ARCADE_IMPACT_PARTICLES = 24;
export const MAX_BIKE_ARCADE_WAVE_HISTORY = 16;

export type BikeArcadeMilestone = (typeof BIKE_ARCADE_MILESTONES)[number];
export type BikeArcadeLane = 0 | 1 | 2;
export type BikeArcadeMode = "story" | "endless";

export interface BikeArcadeRunConfig {
  mode: BikeArcadeMode;
  seed: number;
}

export interface BikeArcadeRunResetState {
  lane: BikeArcadeLane;
  safeLane: BikeArcadeLane;
  waveIndex: number;
  waveHistory: number[];
}

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
  mode?: BikeArcadeMode;
}

export interface SeededBikeObstacleWaveInput {
  distance: number;
  previousSafeLane: BikeArcadeLane;
  mode: BikeArcadeMode;
  seed: number;
  waveIndex: number;
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

function clampEndlessBikeDistance(distance: number): number {
  if (!Number.isFinite(distance)) {
    return 0;
  }
  return Math.min(BIKE_ARCADE_MAX_DISTANCE, Math.max(0, distance));
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

function mixBikeSeed(value: number): number {
  let mixed = value >>> 0;
  mixed = Math.imul(mixed ^ (mixed >>> 16), 0x7feb352d);
  mixed = Math.imul(mixed ^ (mixed >>> 15), 0x846ca68b);
  return (mixed ^ (mixed >>> 16)) >>> 0;
}

function seededBikeFraction(seed: number, salt: number): number {
  return mixBikeSeed((seed >>> 0) ^ Math.imul(salt + 1, 0x9e3779b1)) / 0x1_0000_0000;
}

export function normalizeBikeArcadeSeed(seed: number): number {
  if (!Number.isFinite(seed)) {
    return BIKE_ARCADE_STORY_SEED;
  }
  const normalized = Math.trunc(seed) >>> 0;
  return normalized === 0 ? BIKE_ARCADE_STORY_SEED : normalized;
}

export function createBikeArcadeRunResetState(): BikeArcadeRunResetState {
  return {
    lane: 1,
    safeLane: 1,
    waveIndex: 0,
    waveHistory: []
  };
}

export function createBikeObstacleScheduleEntropy(
  seed: number,
  waveIndex: number
): BikeObstacleScheduleEntropy {
  const normalizedSeed = normalizeBikeArcadeSeed(seed);
  const normalizedWaveIndex = Number.isFinite(waveIndex)
    ? Math.max(0, Math.min(BIKE_ARCADE_MAX_DISTANCE, Math.trunc(waveIndex)))
    : 0;
  const waveSeed = mixBikeSeed(normalizedSeed ^ Math.imul(normalizedWaveIndex + 1, 0x85ebca6b));
  return {
    safeLane: seededBikeFraction(waveSeed, 0),
    density: seededBikeFraction(waveSeed, 1),
    blockedLane: seededBikeFraction(waveSeed, 2),
    interval: seededBikeFraction(waveSeed, 3),
    obstacleTypes: [seededBikeFraction(waveSeed, 4), seededBikeFraction(waveSeed, 5)]
  };
}

export function getBikeArcadeLap(distance: number): number {
  const safeDistance = clampEndlessBikeDistance(distance);
  return Math.floor(safeDistance / BIKE_ARCADE_GOAL) + 1;
}

export function getBikeArcadeLapDistance(distance: number): number {
  const safeDistance = clampEndlessBikeDistance(distance);
  return safeDistance % BIKE_ARCADE_GOAL;
}

export function getBikeArcadeTier(distance: number): number {
  return Math.min(BIKE_ARCADE_MAX_TIER, getBikeArcadeLap(distance));
}

export function moveBikeLane(currentLane: number, direction: -1 | 1): BikeArcadeLane {
  return Math.max(0, Math.min(BIKE_ARCADE_LANES - 1, currentLane + direction)) as BikeArcadeLane;
}

export function advanceBikeDistance(
  currentDistance: number,
  deltaMs: number,
  mode: BikeArcadeMode = "story"
): number {
  const safeDelta = Number.isFinite(deltaMs) ? Math.max(0, deltaMs) : 0;
  if (mode === "story") {
    const pace = 0.038 + Math.min(currentDistance, BIKE_ARCADE_GOAL) * 0.000012;
    return Math.min(BIKE_ARCADE_GOAL, currentDistance + safeDelta * pace);
  }
  const safeDistance = clampEndlessBikeDistance(currentDistance);
  const lapDistance = getBikeArcadeLapDistance(safeDistance);
  const tierPressure = Math.min(BIKE_ARCADE_MAX_TIER - 1, getBikeArcadeTier(safeDistance) - 1);
  const pace = 0.038 + Math.min(lapDistance, BIKE_ARCADE_GOAL) * 0.000012 + tierPressure * 0.0011;
  return Math.min(BIKE_ARCADE_MAX_DISTANCE, safeDistance + safeDelta * pace);
}

export function bikeObstacleSpeed(distance: number, mode: BikeArcadeMode = "story"): number {
  if (mode === "story") {
    return 180 + Math.min(BIKE_ARCADE_GOAL, Math.max(0, distance)) * 0.14;
  }
  const lapDistance = getBikeArcadeLapDistance(distance);
  const tierPressure = (getBikeArcadeTier(distance) - 1) * 6;
  return Math.min(
    BIKE_ARCADE_MAX_OBSTACLE_SPEED,
    180 + Math.min(BIKE_ARCADE_GOAL, lapDistance) * 0.14 + tierPressure
  );
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

export function minimumBikeObstacleWaveInterval(
  distance: number,
  mode: BikeArcadeMode = "story"
): number {
  const speed = bikeObstacleSpeed(distance, mode);
  const rowClearanceMs = (BIKE_OBSTACLE_ROW_CLEARANCE_PX / speed) * 1000;
  return Math.ceil(rowClearanceMs + BIKE_ARCADE_LANE_CHANGE_MS);
}

export function getBikeObstacleDifficulty(
  distance: number,
  mode: BikeArcadeMode = "story"
): BikeObstacleDifficulty {
  const safeDistance = mode === "story" ? clampBikeDistance(distance) : getBikeArcadeLapDistance(distance);
  const tierPressure = mode === "endless" ? (getBikeArcadeTier(distance) - 1) * 9 : 0;
  const pressure = Math.min(310, safeDistance * 0.22 + tierPressure);
  const doubleBlockProgress = Math.max(0, safeDistance - BIKE_ARCADE_MILESTONES[0]) /
    (BIKE_ARCADE_GOAL - BIKE_ARCADE_MILESTONES[0]);
  const solvableFloor = minimumBikeObstacleWaveInterval(distance, mode);

  return {
    minIntervalMs: Math.max(solvableFloor, Math.round(680 - pressure)),
    maxIntervalMs: Math.max(solvableFloor, Math.round(990 - pressure)),
    doubleBlockChance: Math.min(0.78, doubleBlockProgress * 0.62 + tierPressure * 0.002)
  };
}

export function planBikeObstacleWave({
  distance,
  previousSafeLane,
  entropy,
  mode = "story"
}: BikeObstacleWaveInput): BikeObstacleWavePlan {
  const safeDistance = mode === "story" ? clampBikeDistance(distance) : clampEndlessBikeDistance(distance);
  const difficulty = getBikeObstacleDifficulty(safeDistance, mode);
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
      minimumBikeObstacleWaveInterval(safeDistance, mode),
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

export function planSeededBikeObstacleWave({
  distance,
  previousSafeLane,
  mode,
  seed,
  waveIndex
}: SeededBikeObstacleWaveInput): BikeObstacleWavePlan {
  return planBikeObstacleWave({
    distance,
    previousSafeLane,
    mode,
    entropy: createBikeObstacleScheduleEntropy(seed, waveIndex)
  });
}

export function isBikeObstacleWaveSolvable(
  plan: BikeObstacleWavePlan,
  previousSafeLane: BikeArcadeLane,
  mode: BikeArcadeMode = "story"
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
    plan.spawnDelayMs >= minimumBikeObstacleWaveInterval(plan.distance, mode);
}

export function loseBikeLife(currentLives: number): number {
  return Math.max(0, currentLives - 1);
}

export function shouldFinishBikeArcadeRun(
  mode: BikeArcadeMode,
  distance: number,
  lives: number
): "won" | "lost" | null {
  if (lives <= 0) {
    return "lost";
  }
  if (mode === "story" && distance >= BIKE_ARCADE_GOAL) {
    return "won";
  }
  return null;
}

export function scoreBikeNearMiss(combo: number, tier: number): number {
  const safeCombo = Math.max(1, Math.min(BIKE_ARCADE_MAX_COMBO, Math.trunc(combo)));
  const safeTier = Math.max(1, Math.min(BIKE_ARCADE_MAX_TIER, Math.trunc(tier)));
  return Math.min(25_000, 35 + safeCombo * 5 + safeTier * 4);
}

export function appendBikeWaveHistory(
  history: readonly number[],
  waveIndex: number
): number[] {
  const normalizedWaveIndex = Number.isFinite(waveIndex) ? Math.max(0, Math.trunc(waveIndex)) : 0;
  return [...history, normalizedWaveIndex].slice(-MAX_BIKE_ARCADE_WAVE_HISTORY);
}
