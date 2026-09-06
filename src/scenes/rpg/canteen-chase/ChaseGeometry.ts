export type ChaseObstacleKind = "barrier" | "bicycle" | "crowd" | "cone" | "car" | "runner";

export interface ChaseObstacle {
  id: string;
  distance: number;
  lane: number;
  kind: ChaseObstacleKind;
  crossingSide: -1 | 1;
}

export const VISIBLE_DISTANCE = 96;

const STAGE_OBSTACLE_KINDS: readonly (readonly ChaseObstacleKind[])[] = [
  ["bicycle", "cone", "runner", "bicycle"],
  ["runner", "crowd", "bicycle", "cone"],
  ["barrier", "cone", "barrier", "car"],
  ["bicycle", "runner", "cone", "crowd"]
];

// Two occupied lanes leave one visibly open route. Every neighbouring opening
// is one lane away; the final 29m remain clear for the braking handoff.
export const CHASE_HAZARD_BEATS = Object.freeze([
  42, 68, 94, 120, 146, 172,
  204, 227, 250, 273, 296, 319, 342, 365,
  394, 412, 430, 448, 466, 484, 502, 520, 538, 556,
  579, 594, 609, 624, 639, 654, 669, 684, 699, 714, 726
].map((distance, index) => ({ distance, openLane: [0, 1, 2, 1][index % 4] })));

const AUTHORED_OBSTACLES: readonly ChaseObstacle[] = CHASE_HAZARD_BEATS.flatMap((beat, index) => {
  const stage = beat.distance < 188 ? 0 : beat.distance < 377 ? 1 : beat.distance < 566 ? 2 : 3;
  const kinds = STAGE_OBSTACLE_KINDS[stage];
  return [0, 1, 2].filter((lane) => lane !== beat.openLane).map((lane, slot) => ({
    id: `rush-${index}-${lane}`, distance: beat.distance, lane,
    kind: kinds[(index + slot) % kinds.length],
    crossingSide: (lane < beat.openLane ? -1 : 1) as -1 | 1
  }));
});

export function obstaclesBetween(start: number, end: number): ChaseObstacle[] {
  return AUTHORED_OBSTACLES.filter((obstacle) => obstacle.distance >= start && obstacle.distance <= end);
}

export function visibleObstacles(distance: number): ChaseObstacle[] {
  return obstaclesBetween(distance + 0.01, distance + VISIBLE_DISTANCE)
    .sort((left, right) => right.distance - left.distance);
}

export interface RoadPoint {
  x: number;
  y: number;
  scale: number;
  opacity: number;
}

export function projectRoadPoint(distanceAhead: number, lane: number): RoadPoint {
  const depth = Math.max(0, Math.min(1, 1 - distanceAhead / VISIBLE_DISTANCE));
  const perspective = depth * depth;
  return {
    x: 480 + (lane - 1) * (36 + perspective * 210),
    y: 138 + perspective * 362,
    scale: 0.16 + perspective * 1.12,
    opacity: 0.26 + perspective * 0.74
  };
}

export interface ObstaclePoint extends RoadPoint {
  crossingSide: -1 | 1;
}

export type ChasePedestrianKind = "phoneWalker" | "chattingPair" | "soyMilk" | "bikePusher";

export interface ChasePedestrian {
  id: string;
  distance: number;
  side: -1 | 1;
  kind: ChasePedestrianKind;
  /** 0..1 lateral jitter inside the sidewalk band, never on the road. */
  laneOffset: number;
  /** 0 | 1 animation phase offset so neighbours do not swap frames in sync. */
  phase: number;
}

export const PEDESTRIAN_START_DISTANCE = 30;
export const PEDESTRIAN_INTERVAL = 52;

const PEDESTRIAN_KINDS: readonly ChasePedestrianKind[] = [
  "phoneWalker",
  "chattingPair",
  "soyMilk",
  "bikePusher"
];

// One featured kind per milestone band (start / 188 / 377 / 566) so the
// narrator line for a segment always matches pedestrians visible in it.
const BAND_FEATURED_KIND: readonly ChasePedestrianKind[] = [
  "phoneWalker",
  "chattingPair",
  "soyMilk",
  "bikePusher"
];

function pedestrianBand(distance: number): number {
  if (distance < 188) return 0;
  if (distance < 377) return 1;
  if (distance < 566) return 2;
  return 3;
}

// Sidewalk pedestrians are decorative only: deterministic per world slot,
// anchored to the roadside, and never part of the collision set.
export function pedestrianAt(index: number): ChasePedestrian | null {
  const hash = Math.imul(index + 37, 22695477) >>> 0;
  // Sparse deterministic gaps preserve readable sidewalk space.
  if ((hash >>> 3) % 4 === 0) return null;
  const distance = PEDESTRIAN_START_DISTANCE + index * PEDESTRIAN_INTERVAL;
  const featured = BAND_FEATURED_KIND[pedestrianBand(distance)];
  const kind = (hash >>> 6) % 3 === 0 ? featured : PEDESTRIAN_KINDS[(hash >>> 8) % PEDESTRIAN_KINDS.length];
  return {
    id: `ped-${index}`,
    distance,
    side: (hash & 1) === 0 ? -1 : 1,
    kind,
    laneOffset: ((hash >>> 12) % 100) / 100,
    phase: (hash >>> 17) & 1
  };
}

export function visiblePedestrians(distance: number): ChasePedestrian[] {
  const first = Math.max(0, Math.ceil((distance + 0.01 - PEDESTRIAN_START_DISTANCE) / PEDESTRIAN_INTERVAL));
  const last = Math.max(first - 1, Math.floor((distance + VISIBLE_DISTANCE - PEDESTRIAN_START_DISTANCE) / PEDESTRIAN_INTERVAL));
  const result: ChasePedestrian[] = [];
  for (let index = last; index >= first; index -= 1) {
    const pedestrian = pedestrianAt(index);
    if (pedestrian) result.push(pedestrian);
  }
  return result;
}

export function projectObstaclePoint(obstacle: ChaseObstacle, distanceAhead: number): ObstaclePoint {
  if (obstacle.kind !== "runner") {
    return {
      ...projectRoadPoint(distanceAhead, obstacle.lane),
      crossingSide: obstacle.crossingSide
    };
  }
  const depth = Math.max(0, Math.min(1, 1 - distanceAhead / VISIBLE_DISTANCE));
  const crossingProgress = Math.max(0, Math.min(1, (depth - 0.32) / 0.62));
  const easedProgress = crossingProgress * crossingProgress * (3 - 2 * crossingProgress);
  const roadsideLane = obstacle.crossingSide < 0 ? -1.25 : 3.25;
  const movingLane = roadsideLane + (obstacle.lane - roadsideLane) * easedProgress;
  return {
    ...projectRoadPoint(distanceAhead, movingLane),
    crossingSide: obstacle.crossingSide
  };
}
