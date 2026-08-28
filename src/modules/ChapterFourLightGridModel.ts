import type { ChapterFourLightZoneId } from "../core/types";
import content from "../data/chapter4-755.content.json";

export interface ChapterFourLightZoneContract {
  id: ChapterFourLightZoneId;
  label: string;
  bit: number;
  adjacentZoneIds: readonly ChapterFourLightZoneId[];
  toggleMask: number;
}

export interface ChapterFourLightGridContract {
  initialMask: number;
  targetMask: number;
  allOnMask: number;
  zones: readonly ChapterFourLightZoneContract[];
  requiredOnZoneIds: readonly ChapterFourLightZoneId[];
  requiredOffZoneIds: readonly ChapterFourLightZoneId[];
  verifiedSolutionZoneIds: readonly ChapterFourLightZoneId[];
  successLocks: boolean;
}

export interface ChapterFourLightGridEvaluation {
  mask: number;
  solved: boolean;
  requiredOnSatisfied: boolean;
  requiredOffSatisfied: boolean;
}

export interface ChapterFourLightGridSolution {
  clickVector: number;
  zoneIds: ChapterFourLightZoneId[];
  resultMask: number;
}

const EXPECTED_ZONE_IDS = Object.freeze([
  "hall",
  "west_corridor",
  "east_corridor",
  "classroom_zone",
  "bakery_back_area"
] as const satisfies readonly ChapterFourLightZoneId[]);

const EXPECTED_TOGGLE_MASKS = Object.freeze([7, 19, 13, 28, 26] as const);
const EXPECTED_REQUIRED_ON_ZONE_IDS = Object.freeze([
  "hall",
  "east_corridor",
  "classroom_zone"
] as const satisfies readonly ChapterFourLightZoneId[]);
const EXPECTED_REQUIRED_OFF_ZONE_IDS = Object.freeze([
  "west_corridor",
  "bakery_back_area"
] as const satisfies readonly ChapterFourLightZoneId[]);
const EXPECTED_SOLUTION_ZONE_IDS = Object.freeze([
  "hall",
  "west_corridor",
  "east_corridor",
  "bakery_back_area"
] as const satisfies readonly ChapterFourLightZoneId[]);

function assertIntegerMask(value: number, label: string, allOnMask: number): void {
  if (!Number.isInteger(value) || value < 0 || value > allOnMask) {
    throw new Error(`chapter4_light_grid_${label}_invalid:${value}`);
  }
}

function normalizeContract(raw: typeof content.lightGrid): ChapterFourLightGridContract {
  if (raw.zones.length !== EXPECTED_ZONE_IDS.length) {
    throw new Error(`chapter4_light_grid_zone_count:${raw.zones.length}`);
  }
  if (raw.initialMask !== 14 || raw.targetMask !== 13 || raw.allOnMask !== 31) {
    throw new Error("chapter4_light_grid_mask_contract_mismatch");
  }
  if (JSON.stringify(raw.requiredOnZoneIds) !== JSON.stringify(EXPECTED_REQUIRED_ON_ZONE_IDS)
    || JSON.stringify(raw.requiredOffZoneIds) !== JSON.stringify(EXPECTED_REQUIRED_OFF_ZONE_IDS)
    || JSON.stringify(raw.verifiedSolutionZoneIds) !== JSON.stringify(EXPECTED_SOLUTION_ZONE_IDS)
    || raw.successLocks !== true) {
    throw new Error("chapter4_light_grid_solution_contract_mismatch");
  }
  const seen = new Set<string>();
  const zones = raw.zones.map((zone, index) => {
    const expectedId = EXPECTED_ZONE_IDS[index];
    if (zone.id !== expectedId || seen.has(zone.id)) {
      throw new Error(`chapter4_light_grid_zone_order:${zone.id}`);
    }
    seen.add(zone.id);
    if (zone.bit !== index || zone.toggleMask !== EXPECTED_TOGGLE_MASKS[index]) {
      throw new Error(`chapter4_light_grid_toggle_contract:${zone.id}`);
    }
    const derivedMask = [zone.id, ...zone.adjacentZoneIds]
      .reduce((mask, zoneId) => {
        const adjacentIndex = EXPECTED_ZONE_IDS.indexOf(zoneId as ChapterFourLightZoneId);
        if (adjacentIndex < 0) throw new Error(`chapter4_light_grid_unknown_adjacent:${zoneId}`);
        return mask | (1 << adjacentIndex);
      }, 0);
    if (derivedMask !== zone.toggleMask) {
      throw new Error(`chapter4_light_grid_adjacency_mask:${zone.id}`);
    }
    return Object.freeze({
      id: zone.id as ChapterFourLightZoneId,
      label: zone.label,
      bit: zone.bit,
      adjacentZoneIds: Object.freeze([...zone.adjacentZoneIds] as ChapterFourLightZoneId[]),
      toggleMask: zone.toggleMask
    });
  });
  assertIntegerMask(raw.initialMask, "initial_mask", raw.allOnMask);
  assertIntegerMask(raw.targetMask, "target_mask", raw.allOnMask);
  return Object.freeze({
    initialMask: raw.initialMask,
    targetMask: raw.targetMask,
    allOnMask: raw.allOnMask,
    zones: Object.freeze(zones),
    requiredOnZoneIds: Object.freeze([...raw.requiredOnZoneIds] as ChapterFourLightZoneId[]),
    requiredOffZoneIds: Object.freeze([...raw.requiredOffZoneIds] as ChapterFourLightZoneId[]),
    verifiedSolutionZoneIds: Object.freeze([...raw.verifiedSolutionZoneIds] as ChapterFourLightZoneId[]),
    successLocks: raw.successLocks
  });
}

export const CHAPTER_FOUR_LIGHT_GRID = normalizeContract(content.lightGrid);

export function normalizeChapterFourLightGridMask(mask: number): number {
  assertIntegerMask(mask, "mask", CHAPTER_FOUR_LIGHT_GRID.allOnMask);
  return mask;
}

export function toggleChapterFourLightZone(
  mask: number,
  zoneId: ChapterFourLightZoneId
): number {
  const normalizedMask = normalizeChapterFourLightGridMask(mask);
  const zone = CHAPTER_FOUR_LIGHT_GRID.zones.find((candidate) => candidate.id === zoneId);
  if (!zone) throw new Error(`chapter4_light_grid_unknown_zone:${zoneId}`);
  return (normalizedMask ^ zone.toggleMask) & CHAPTER_FOUR_LIGHT_GRID.allOnMask;
}

function zoneIsOn(mask: number, zoneId: ChapterFourLightZoneId): boolean {
  const zone = CHAPTER_FOUR_LIGHT_GRID.zones.find((candidate) => candidate.id === zoneId);
  if (!zone) throw new Error(`chapter4_light_grid_unknown_zone:${zoneId}`);
  return (mask & (1 << zone.bit)) !== 0;
}

export function evaluateChapterFourLightGrid(mask: number): ChapterFourLightGridEvaluation {
  const normalizedMask = normalizeChapterFourLightGridMask(mask);
  const requiredOnSatisfied = CHAPTER_FOUR_LIGHT_GRID.requiredOnZoneIds.every(
    (zoneId) => zoneIsOn(normalizedMask, zoneId)
  );
  const requiredOffSatisfied = CHAPTER_FOUR_LIGHT_GRID.requiredOffZoneIds.every(
    (zoneId) => !zoneIsOn(normalizedMask, zoneId)
  );
  return Object.freeze({
    mask: normalizedMask,
    solved: requiredOnSatisfied && requiredOffSatisfied,
    requiredOnSatisfied,
    requiredOffSatisfied
  });
}

export function isChapterFourLightGridSolved(mask: number): boolean {
  return evaluateChapterFourLightGrid(mask).solved;
}

export function applyChapterFourLightGridClickVector(
  initialMask: number,
  clickVector: number
): number {
  let mask = normalizeChapterFourLightGridMask(initialMask);
  assertIntegerMask(clickVector, "click_vector", CHAPTER_FOUR_LIGHT_GRID.allOnMask);
  CHAPTER_FOUR_LIGHT_GRID.zones.forEach((zone, index) => {
    if ((clickVector & (1 << index)) !== 0) mask = toggleChapterFourLightZone(mask, zone.id);
  });
  return mask;
}

export function enumerateChapterFourLightGridSolutions(
  initialMask = CHAPTER_FOUR_LIGHT_GRID.initialMask
): ChapterFourLightGridSolution[] {
  normalizeChapterFourLightGridMask(initialMask);
  const solutions: ChapterFourLightGridSolution[] = [];
  for (let clickVector = 0; clickVector <= CHAPTER_FOUR_LIGHT_GRID.allOnMask; clickVector += 1) {
    const resultMask = applyChapterFourLightGridClickVector(initialMask, clickVector);
    if (!isChapterFourLightGridSolved(resultMask)) continue;
    solutions.push(Object.freeze({
      clickVector,
      zoneIds: CHAPTER_FOUR_LIGHT_GRID.zones
        .filter((_, index) => (clickVector & (1 << index)) !== 0)
        .map((zone) => zone.id),
      resultMask
    }));
  }
  return solutions;
}
