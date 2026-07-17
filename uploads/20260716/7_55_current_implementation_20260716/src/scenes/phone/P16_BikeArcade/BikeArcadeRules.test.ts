import { describe, expect, it, vi } from "vitest";
import {
  advanceBikeDistance,
  BIKE_ARCADE_GOAL,
  BIKE_ARCADE_MILESTONES,
  bikeObstacleSpeed,
  emitCrossedBikeMilestones,
  getBikeObstacleDifficulty,
  getCrossedBikeMilestones,
  isBikeObstacleWaveSolvable,
  loseBikeLife,
  minimumBikeObstacleWaveInterval,
  moveBikeLane,
  planBikeObstacleWave,
  type BikeArcadeLane,
  type BikeObstacleScheduleEntropy
} from "./BikeArcadeRules";

describe("BikeArcadeRules", () => {
  it("keeps lane changes inside the three-lane road", () => {
    expect(moveBikeLane(0, -1)).toBe(0);
    expect(moveBikeLane(1, -1)).toBe(0);
    expect(moveBikeLane(1, 1)).toBe(2);
    expect(moveBikeLane(2, 1)).toBe(2);
  });

  it("advances toward 755m without overshooting", () => {
    expect(advanceBikeDistance(0, 1000)).toBeGreaterThan(35);
    expect(advanceBikeDistance(750, 1000)).toBe(BIKE_ARCADE_GOAL);
    expect(advanceBikeDistance(100, -100)).toBe(100);
  });

  it("increases obstacle speed and clamps lives at zero", () => {
    expect(bikeObstacleSpeed(700)).toBeGreaterThan(bikeObstacleSpeed(0));
    expect(loseBikeLife(3)).toBe(2);
    expect(loseBikeLife(0)).toBe(0);
  });

  it("reports every crossed 188/377/566/755 milestone exactly once", () => {
    expect(BIKE_ARCADE_MILESTONES).toEqual([188, 377, 566, 755]);
    expect(getCrossedBikeMilestones(187.9, 188)).toEqual([188]);
    expect(getCrossedBikeMilestones(188, 377)).toEqual([377]);
    expect(getCrossedBikeMilestones(187, 756)).toEqual([188, 377, 566, 755]);
    expect(getCrossedBikeMilestones(566, 566)).toEqual([]);
    expect(getCrossedBikeMilestones(600, 500)).toEqual([]);
  });

  it("emits ordered milestone callbacks for a multi-milestone frame", () => {
    const onMilestone = vi.fn();

    expect(emitCrossedBikeMilestones(180, 570, onMilestone)).toEqual([188, 377, 566]);
    expect(onMilestone.mock.calls).toEqual([[188], [377], [566]]);
  });

  it("raises obstacle density while retaining a solvable timing floor", () => {
    const start = getBikeObstacleDifficulty(0);
    const middle = getBikeObstacleDifficulty(377);
    const finish = getBikeObstacleDifficulty(BIKE_ARCADE_GOAL);

    expect(start.minIntervalMs).toBeGreaterThan(middle.minIntervalMs);
    expect(middle.minIntervalMs).toBeGreaterThan(finish.minIntervalMs);
    expect(start.maxIntervalMs).toBeGreaterThan(finish.maxIntervalMs);
    expect(start.doubleBlockChance).toBeLessThan(middle.doubleBlockChance);
    expect(middle.doubleBlockChance).toBeLessThan(finish.doubleBlockChance);
    expect(finish.minIntervalMs).toBeGreaterThanOrEqual(
      minimumBikeObstacleWaveInterval(BIKE_ARCADE_GOAL)
    );
  });

  it("plans only reachable waves with at least one open lane", () => {
    const lanes: BikeArcadeLane[] = [0, 1, 2];
    const distances = [0, 188, 377, 566, BIKE_ARCADE_GOAL];
    const samples = [0, 0.25, 0.5, 0.75, 0.999];

    for (const previousSafeLane of lanes) {
      for (const distance of distances) {
        for (const sample of samples) {
          const entropy: BikeObstacleScheduleEntropy = {
            safeLane: sample,
            density: sample,
            blockedLane: 1 - sample,
            interval: sample,
            obstacleTypes: [sample, 1 - sample]
          };
          const plan = planBikeObstacleWave({ distance, previousSafeLane, entropy });
          const blockedLanes = plan.obstacles.map((obstacle) => obstacle.lane);

          expect(isBikeObstacleWaveSolvable(plan, previousSafeLane)).toBe(true);
          expect(new Set(blockedLanes).size).toBe(blockedLanes.length);
          expect(blockedLanes).not.toContain(plan.safeLane);
          expect(blockedLanes.length).toBeLessThanOrEqual(2);
          expect(Math.abs(plan.safeLane - previousSafeLane)).toBeLessThanOrEqual(1);
          expect(plan.spawnDelayMs).toBeGreaterThanOrEqual(
            minimumBikeObstacleWaveInterval(distance)
          );
        }
      }
    }
  });

  it("introduces two-lane waves late without changing the reachable corridor", () => {
    const entropy: BikeObstacleScheduleEntropy = {
      safeLane: 0.99,
      density: 0,
      blockedLane: 0.5,
      interval: 1,
      obstacleTypes: [0, 0.99]
    };

    const opening = planBikeObstacleWave({ distance: 0, previousSafeLane: 0, entropy });
    const sprint = planBikeObstacleWave({
      distance: BIKE_ARCADE_GOAL,
      previousSafeLane: opening.safeLane,
      entropy
    });

    expect(opening.obstacles).toHaveLength(1);
    expect(sprint.obstacles).toHaveLength(2);
    expect(sprint.obstacles.map((obstacle) => obstacle.lane)).not.toContain(sprint.safeLane);
    expect(isBikeObstacleWaveSolvable(sprint, opening.safeLane)).toBe(true);
  });
});
