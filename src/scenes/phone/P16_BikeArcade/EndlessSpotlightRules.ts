import { ENDLESS_ARCADE_SCORE_LIMIT } from "../../../core/EndlessArcadeLimits";

export type EndlessSpotlightLane = "left" | "center" | "right";

export const MAX_SPOTLIGHT_PATH_POINTS = 10;
export const MAX_SPOTLIGHT_DECOY_POINTS = 8;
export const MAX_SPOTLIGHT_HISTORY = 10;
export const MAX_ENDLESS_SPOTLIGHT_TIER = 13;
export const MAX_ENDLESS_SPOTLIGHT_SCORE = ENDLESS_ARCADE_SCORE_LIMIT;

const LANES: readonly EndlessSpotlightLane[] = ["left", "center", "right"];

export interface EndlessSpotlightPoint {
  readonly x: number;
  readonly y: number;
}

export interface EndlessSpotlightWave {
  readonly id: string;
  readonly seed: number;
  readonly waveIndex: number;
  readonly tier: number;
  readonly lane: EndlessSpotlightLane;
  readonly previewMs: number;
  readonly actionMs: number;
  readonly requiredLockMs: number;
  readonly beamRadius: number;
  readonly pathPoints: readonly EndlessSpotlightPoint[];
  readonly decoyPathPoints: readonly EndlessSpotlightPoint[];
}

export function createEndlessSpotlightWave(seed: number, waveIndex: number): EndlessSpotlightWave {
  const normalizedSeed = normalizeSpotlightSeed(seed);
  const normalizedIndex = clampSpotlightInteger(waveIndex, 0, MAX_SPOTLIGHT_HISTORY * 100_000);
  const tier = Math.min(MAX_ENDLESS_SPOTLIGHT_TIER, Math.floor(normalizedIndex / 3) + 1);
  const random = createSpotlightRng(mixSpotlightSeed(normalizedSeed, normalizedIndex));
  const lane = LANES[Math.floor(random() * LANES.length)] ?? "center";
  const pointCount = Math.min(MAX_SPOTLIGHT_PATH_POINTS, 4 + Math.floor((tier - 1) / 2));
  const previewJitterMs = mixSpotlightSeed(normalizedSeed, 0) % 41;
  const previewMs = Math.max(500, 930 - previewJitterMs - (tier - 1) * 32);
  const actionMs = Math.max(1_350, 3_300 - (tier - 1) * 130);
  const requiredLockMs = Math.min(1_050, 260 + tier * 48);
  const beamRadius = Math.max(30, 68 - tier * 2);
  const laneX = lane === "left" ? -130 : lane === "right" ? 130 : 0;
  const pathPoints = buildSpotlightPath(random, pointCount, laneX, 88);
  const decoyLaneX = lane === "left" ? 130 : lane === "right" ? -130 : random() < 0.5 ? -130 : 130;
  const decoyPathPoints = tier >= 3
    ? buildSpotlightPath(random, Math.min(MAX_SPOTLIGHT_DECOY_POINTS, pointCount), decoyLaneX, 76)
    : [];
  return Object.freeze({
    id: `spotlight:${normalizedSeed}:${normalizedIndex}`,
    seed: normalizedSeed,
    waveIndex: normalizedIndex,
    tier,
    lane,
    previewMs,
    actionMs,
    requiredLockMs,
    beamRadius,
    pathPoints: Object.freeze(pathPoints),
    decoyPathPoints: Object.freeze(decoyPathPoints),
  });
}

export function scoreEndlessSpotlight(tier: number, lockedMs: number, combo: number): number {
  const safeTier = clampSpotlightInteger(tier, 1, MAX_ENDLESS_SPOTLIGHT_TIER);
  const safeLock = clampSpotlightInteger(lockedMs, 0, 60_000);
  const safeCombo = clampSpotlightInteger(combo, 0, 1_000_000);
  return Math.min(
    MAX_ENDLESS_SPOTLIGHT_SCORE,
    Math.max(0, Math.trunc(safeTier * (safeLock * 3 + Math.min(10_000, safeCombo) * 90)))
  );
}

export function appendSpotlightHistory<T>(history: readonly T[], next: T): T[] {
  return [...history.slice(-(MAX_SPOTLIGHT_HISTORY - 1)), next];
}

export function normalizeSpotlightSeed(seed: number): number {
  if (!Number.isFinite(seed) || !Number.isSafeInteger(seed)) return 1;
  return Math.min(0xffff_ffff, Math.max(1, seed >>> 0));
}

function buildSpotlightPath(
  random: () => number,
  pointCount: number,
  destinationX: number,
  destinationY: number,
): EndlessSpotlightPoint[] {
  const points: EndlessSpotlightPoint[] = [];
  for (let index = 0; index < pointCount; index += 1) {
    const progress = index / Math.max(1, pointCount - 1);
    const sideWobble = index === pointCount - 1 ? 0 : (random() - 0.5) * 86;
    points.push(Object.freeze({
      x: Math.round(-160 + (destinationX + 160) * progress + sideWobble),
      y: Math.round(-128 + (destinationY + 128) * progress + (random() - 0.5) * 28),
    }));
  }
  points[points.length - 1] = Object.freeze({ x: destinationX, y: destinationY });
  return points;
}

function createSpotlightRng(seed: number): () => number {
  let state = seed >>> 0;
  return () => {
    state = (state + 0x6d2b_79f5) >>> 0;
    let value = state;
    value = Math.imul(value ^ (value >>> 15), value | 1);
    value ^= value + Math.imul(value ^ (value >>> 7), value | 61);
    return ((value ^ (value >>> 14)) >>> 0) / 4_294_967_296;
  };
}

function mixSpotlightSeed(seed: number, index: number): number {
  let mixed = (seed ^ Math.imul(index + 1, 0x9e37_79b1)) >>> 0;
  mixed ^= mixed >>> 16;
  mixed = Math.imul(mixed, 0x85eb_ca6b) >>> 0;
  mixed ^= mixed >>> 13;
  return mixed || 1;
}

function clampSpotlightInteger(value: number, minimum: number, maximum: number): number {
  if (!Number.isFinite(value) || !Number.isSafeInteger(value)) return minimum;
  return Math.min(maximum, Math.max(minimum, Math.trunc(value)));
}
