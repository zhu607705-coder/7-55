export type ChaseObstacleKind = "barrier" | "bicycle" | "crowd" | "cone" | "car" | "runner";

export interface ChaseObstacle {
  id: string;
  distance: number;
  lane: number;
  kind: ChaseObstacleKind;
  crossingSide: -1 | 1;
}

export const OBSTACLE_START_DISTANCE = 78;
export const OBSTACLE_INTERVAL = 66;
export const VISIBLE_DISTANCE = 220;

const OBSTACLE_KINDS: readonly ChaseObstacleKind[] = [
  "barrier",
  "bicycle",
  "crowd",
  "cone",
  "car",
  "runner"
];

export function obstacleAt(index: number): ChaseObstacle {
  const hash = Math.imul(index + 11, 1103515245) >>> 0;
  return {
    id: `rush-${index}`,
    distance: OBSTACLE_START_DISTANCE + index * OBSTACLE_INTERVAL,
    lane: (hash >>> 8) % 3,
    kind: OBSTACLE_KINDS[(hash >>> 16) % OBSTACLE_KINDS.length],
    crossingSide: (hash & 1) === 0 ? -1 : 1
  };
}

export function obstaclesBetween(start: number, end: number): ChaseObstacle[] {
  const first = Math.max(0, Math.ceil((start - OBSTACLE_START_DISTANCE) / OBSTACLE_INTERVAL));
  const last = Math.max(first - 1, Math.floor((end - OBSTACLE_START_DISTANCE) / OBSTACLE_INTERVAL));
  const result: ChaseObstacle[] = [];
  for (let index = first; index <= last; index += 1) result.push(obstacleAt(index));
  return result;
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
    x: 480 + (lane - 1) * (44 + perspective * 260),
    y: 148 + perspective * 350,
    scale: 0.18 + perspective * 1.28,
    opacity: 0.32 + perspective * 0.68
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

export const PEDESTRIAN_START_DISTANCE = 14;
export const PEDESTRIAN_INTERVAL = 24;

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
  // Leave deterministic gaps so the sidewalk never reads as a solid wall.
  if ((hash >>> 3) % 5 === 0) return null;
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
