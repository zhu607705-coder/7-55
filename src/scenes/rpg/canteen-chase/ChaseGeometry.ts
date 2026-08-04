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
