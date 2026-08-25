import type { RhythmFishingAction, RhythmFishingChartNoteData } from "../../../modules/RhythmFishingEngine";
import { ENDLESS_ARCADE_SCORE_LIMIT } from "../../../core/EndlessArcadeLimits";

export const MAX_FISHING_NOTES_PER_SEGMENT = 28;
export const MAX_BUFFERED_FISHING_SEGMENTS = 2;
export const MAX_FISHING_SEGMENT_HISTORY = 8;
export const MAX_ENDLESS_FISHING_TIER = 13;
export const MAX_ENDLESS_FISHING_SCORE = ENDLESS_ARCADE_SCORE_LIMIT;
export const MAX_ENDLESS_FISHING_COMBO = 1_000_000;

const MIN_ENDLESS_FISHING_SEED = 1;
const MAX_ENDLESS_FISHING_SEED = 0xffff_ffff;
const ENDLESS_FISHING_ACTIONS: readonly RhythmFishingAction[] = ["left", "right"];

export interface EndlessFishingSegment {
  readonly id: string;
  readonly seed: number;
  readonly segmentIndex: number;
  readonly tier: number;
  readonly bpm: number;
  readonly beatSec: number;
  readonly bars: number;
  readonly durationSeconds: number;
  readonly notes: readonly RhythmFishingChartNoteData[];
}

export interface EndlessFishingScoreInput {
  tier: number;
  combo: number;
  judgment: "perfect" | "great" | "good" | "miss";
}

/** Generates one bounded, replayable chart segment from its seed and index. */
export function createEndlessFishingSegment(seed: number, segmentIndex: number): EndlessFishingSegment {
  const normalizedSeed = normalizeFishingSeed(seed);
  const normalizedIndex = clampInteger(segmentIndex, 0, MAX_FISHING_SEGMENT_HISTORY * 100_000);
  const tier = Math.min(MAX_ENDLESS_FISHING_TIER, Math.floor(normalizedIndex / 3) + 1);
  const random = createFishingRng(mixFishingSeed(normalizedSeed, normalizedIndex));
  const bars = Math.min(8, 4 + Math.floor((tier - 1) / 2));
  const bpm = Math.min(156, 96 + (tier - 1) * 5);
  const beatSec = 60 / bpm;
  const noteCount = Math.min(MAX_FISHING_NOTES_PER_SEGMENT, 7 + tier * 2);
  const firstBeat = 4;
  const lastBeat = bars * 4 - 1;
  const middleCount = Math.max(0, noteCount - 2);
  const minGap = tier >= 8 ? 0.5 : 1;
  const notes: RhythmFishingChartNoteData[] = [{ beat: firstBeat, action: "hook" }];
  let previousBeat = firstBeat;

  for (let index = 0; index < middleCount; index += 1) {
    const remaining = middleCount - index;
    const minimumFutureBeat = previousBeat + minGap * (remaining + 1);
    const available = Math.max(0, lastBeat - minimumFutureBeat);
    const expectedGap = Math.max(minGap, (lastBeat - previousBeat) / (remaining + 1));
    const jitter = (random() - 0.5) * Math.min(1, expectedGap * 0.55, available);
    const candidate = previousBeat + expectedGap + jitter;
    const roundedBeat = roundHalfBeat(candidate);
    const maximumBeat = lastBeat - minGap * remaining;
    const beat = Math.min(maximumBeat, Math.max(previousBeat + minGap, roundedBeat));
    const action = ENDLESS_FISHING_ACTIONS[Math.floor(random() * ENDLESS_FISHING_ACTIONS.length)] ?? "left";
    const hold = tier >= 4 && tier < 8 && index < middleCount - 1 && random() < Math.min(0.3, 0.04 * tier)
      ? 1
      : undefined;
    notes.push(hold === undefined ? { beat, action } : { beat, action, hold });
    previousBeat = beat;
  }
  notes.push({ beat: lastBeat, action: "hook" });

  return Object.freeze({
    id: `fishing:${normalizedSeed}:${normalizedIndex}`,
    seed: normalizedSeed,
    segmentIndex: normalizedIndex,
    tier,
    bpm,
    beatSec,
    bars,
    durationSeconds: bars * 4 * beatSec,
    notes: Object.freeze(notes.slice(0, MAX_FISHING_NOTES_PER_SEGMENT)),
  });
}

export function calculateEndlessFishingScore(input: EndlessFishingScoreInput): number {
  const tier = clampInteger(input.tier, 1, MAX_ENDLESS_FISHING_TIER);
  const combo = clampInteger(input.combo, 0, MAX_ENDLESS_FISHING_COMBO);
  const weight = input.judgment === "perfect" ? 100 : input.judgment === "great" ? 70 : input.judgment === "good" ? 40 : 0;
  const rawScore = weight === 0 ? 0 : weight * tier + Math.min(10_000, combo) * tier;
  return Math.min(MAX_ENDLESS_FISHING_SCORE, Math.max(0, Math.trunc(rawScore)));
}

export function appendFishingSegmentHistory<T>(history: readonly T[], next: T): T[] {
  return [...history.slice(-(MAX_FISHING_SEGMENT_HISTORY - 1)), next];
}

export function normalizeFishingSeed(seed: number): number {
  if (!Number.isFinite(seed) || !Number.isSafeInteger(seed)) return MIN_ENDLESS_FISHING_SEED;
  return Math.min(MAX_ENDLESS_FISHING_SEED, Math.max(MIN_ENDLESS_FISHING_SEED, seed >>> 0));
}

function createFishingRng(seed: number): () => number {
  let state = seed >>> 0;
  return () => {
    state = (state + 0x6d2b_79f5) >>> 0;
    let value = state;
    value = Math.imul(value ^ (value >>> 15), value | 1);
    value ^= value + Math.imul(value ^ (value >>> 7), value | 61);
    return ((value ^ (value >>> 14)) >>> 0) / 4_294_967_296;
  };
}

function mixFishingSeed(seed: number, segmentIndex: number): number {
  let mixed = (seed ^ Math.imul(segmentIndex + 1, 0x9e37_79b1)) >>> 0;
  mixed ^= mixed >>> 16;
  mixed = Math.imul(mixed, 0x85eb_ca6b) >>> 0;
  mixed ^= mixed >>> 13;
  return mixed || MIN_ENDLESS_FISHING_SEED;
}

function clampInteger(value: number, minimum: number, maximum: number): number {
  if (!Number.isFinite(value) || !Number.isSafeInteger(value)) return minimum;
  return Math.min(maximum, Math.max(minimum, Math.trunc(value)));
}

function roundHalfBeat(value: number): number {
  return Math.round(value * 2) / 2;
}
