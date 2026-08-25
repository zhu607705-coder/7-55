import { mkdtemp, readFile, rm } from "node:fs/promises";
import { tmpdir } from "node:os";
import path from "node:path";
import { fileURLToPath, pathToFileURL } from "node:url";
import { build } from "esbuild";

const repositoryRoot = path.resolve(path.dirname(fileURLToPath(import.meta.url)), "..");
const rulesPath = path.join(repositoryRoot, "src/scenes/phone/P16_BikeArcade/BikeArcadeRules.ts");
const runtimePath = path.join(repositoryRoot, "src/scenes/phone/P16_BikeArcade/BikeArcadeRuntime.ts");
const scenePath = path.join(repositoryRoot, "src/scenes/phone/P16_BikeArcade/BikeRushScene.ts");
const hostPath = path.join(repositoryRoot, "src/scenes/phone/P16_BikeArcade/EndlessArcadeGameHost.tsx");
const registryPath = path.join(repositoryRoot, "src/scenes/phone/P16_BikeArcade/EndlessChallengeRegistry.ts");

const checks = [];

function check(id, passed, detail) {
  checks.push({ id, passed: Boolean(passed), detail });
}

const [rulesSource, runtimeSource, sceneSource, hostSource, registrySource] = await Promise.all([
  readFile(rulesPath, "utf8"),
  readFile(runtimePath, "utf8"),
  readFile(scenePath, "utf8"),
  readFile(hostPath, "utf8"),
  readFile(registryPath, "utf8")
]);

check(
  "source.explicit-mode",
  /BikeArcadeMode\s*=\s*["']story["']\s*\|\s*["']endless["']/.test(rulesSource),
  "rules expose story and endless modes"
);
check(
  "source.no-random",
  !/Math\.random\s*\(|Phaser\.Math\.RND/.test(`${rulesSource}\n${sceneSource}`),
  "rules and scene contain no ambient random source"
);
check(
  "source.resource-caps",
  [
    "MAX_BIKE_ARCADE_OBSTACLES",
    "MAX_BIKE_ARCADE_IMPACT_PARTICLES",
    "MAX_BIKE_ARCADE_WAVE_HISTORY",
    "BIKE_ARCADE_MAX_OBSTACLE_SPEED"
  ].every((name) => rulesSource.includes(`export const ${name}`)),
  "obstacles, particles, history and speed expose finite caps"
);
check(
  "source.story-bridge",
  runtimeSource.includes("export interface BikeArcadeBridge")
    && runtimeSource.includes("export class BikeArcadeStoryBridgeDispatcher")
    && ["onDistance", "onLives", "onCollision", "onPauseChange", "onFinish"].every((name) => runtimeSource.includes(name))
    && sceneSource.includes('export type { BikeArcadeBridge } from "./BikeArcadeRuntime"'),
  "legacy story bridge callbacks remain available"
);
check(
  "source.endless-bridge-isolation",
  sceneSource.includes('registeredMode === "bike"')
    && sceneSource.includes('this.runConfig.mode === "story"')
    && sceneSource.includes("endlessBridge.publishSnapshot")
    && sceneSource.includes("endlessBridge?.finish")
    && sceneSource.includes("bikeArcadeRunConfig")
    && sceneSource.includes("requires a matching endless bridge")
    && !sceneSource.includes("bike_arcade_completed")
    && !hostSource.includes('registry.set("bikeArcadeBridge"'),
  "endless bike uses the generic run bridge without legacy completion events"
);
check(
  "source.endless-event-namespace",
  [
    "endless_bike_started",
    "endless_bike_progress",
    "endless_bike_lap_completed",
    "endless_bike_near_miss",
    "endless_bike_collision",
    "endless_bike_finished"
  ].every((eventName) => sceneSource.includes(eventName)),
  "endless bike runtime events use the endless_bike namespace"
);
check(
  "source.pool-guard",
  sceneSource.includes("MAX_BIKE_ARCADE_OBSTACLES - this.obstacles.countActive(true)")
    && sceneSource.includes("MAX_BIKE_ARCADE_IMPACT_PARTICLES - this.impactShards.size")
    && sceneSource.includes("this.tweens.killTweensOf(obstacle)"),
  "active obstacles, particles and obstacle tweens remain bounded"
);
check(
  "source.lifecycle-cleanup",
  sceneSource.includes("Phaser.Scenes.Events.SHUTDOWN")
    && sceneSource.includes("Phaser.Scenes.Events.DESTROY")
    && sceneSource.includes('this.input.off("pointerdown"')
    && sceneSource.includes("this.time.removeAllEvents()")
    && sceneSource.includes("this.lifecycle.reset()"),
  "shutdown and destroy detach input, timers and lifecycle state"
);
check(
  "source.registry-single-scene",
  registrySource.includes('path: "./BikeRushScene.ts"')
    && registrySource.includes('sceneKey: "bike-rush"')
    && registrySource.includes("import.meta.glob"),
  "bike dynamically loads the shared BikeRushScene contract"
);
check(
  "source.host-single-instance",
  hostSource.includes("destroyActiveGame();")
    && hostSource.indexOf("destroyActiveGame();") < hostSource.indexOf("new PhaserRuntime.Game")
    && (hostSource.match(/useRef<Phaser\.Game \| null>/g) ?? []).length === 1
    && hostSource.includes('registry.set("bikeArcadeRunConfig"')
    && hostSource.includes('mode: "endless"')
    && hostSource.includes("seed: run.seed"),
  "host destroys the prior game, keeps one game ref and writes the bike run config"
);

const bundleDirectory = await mkdtemp(path.join(tmpdir(), "bike-arcade-validator-"));
try {
  const rulesOutput = path.join(bundleDirectory, "rules.mjs");
  const runtimeOutput = path.join(bundleDirectory, "runtime.mjs");
  await Promise.all([
    build({
      entryPoints: [rulesPath],
      outfile: rulesOutput,
      bundle: true,
      format: "esm",
      platform: "node",
      target: "node20"
    }),
    build({
      entryPoints: [runtimePath],
      outfile: runtimeOutput,
      bundle: true,
      format: "esm",
      platform: "node",
      target: "node20"
    })
  ]);
  const [rules, runtime] = await Promise.all([
    import(`${pathToFileURL(rulesOutput).href}?v=${Date.now()}`),
    import(`${pathToFileURL(runtimeOutput).href}?v=${Date.now()}`)
  ]);

  function buildWaveSequence(seed, mode) {
    let safeLane = 1;
    return Array.from({ length: 256 }, (_, waveIndex) => {
      const distance = mode === "story" ? Math.min(754, waveIndex * 4) : waveIndex * 83;
      const plan = rules.planSeededBikeObstacleWave({
        seed,
        waveIndex,
        mode,
        distance,
        previousSafeLane: safeLane
      });
      const solvable = rules.isBikeObstacleWaveSolvable(plan, safeLane, mode);
      safeLane = plan.safeLane;
      return { plan, solvable };
    });
  }

  const first = buildWaveSequence(755, "endless");
  const replay = buildWaveSequence(755, "endless");
  const alternate = buildWaveSequence(756, "endless");
  const restartedRunState = rules.createBikeArcadeRunResetState();
  restartedRunState.lane = 0;
  restartedRunState.safeLane = 2;
  restartedRunState.waveIndex = 93;
  restartedRunState.waveHistory.push(91, 92, 93);
  Object.assign(restartedRunState, rules.createBikeArcadeRunResetState());
  const coldStartWave = rules.planSeededBikeObstacleWave({
    seed: 755,
    waveIndex: 0,
    mode: "endless",
    distance: 0,
    previousSafeLane: 1
  });
  const restartedFirstWave = rules.planSeededBikeObstacleWave({
    seed: 755,
    waveIndex: restartedRunState.waveIndex,
    mode: "endless",
    distance: 0,
    previousSafeLane: restartedRunState.safeLane
  });
  check(
    "runtime.same-instance-reset",
    restartedRunState.lane === 1
      && restartedRunState.safeLane === 1
      && restartedRunState.waveIndex === 0
      && restartedRunState.waveHistory.length === 0
      && JSON.stringify(restartedFirstWave) === JSON.stringify(coldStartWave),
    "a mutated run state resets to lane 1/1 and reproduces the cold-start first wave"
  );
  check(
    "runtime.seed-replay",
    JSON.stringify(first) === JSON.stringify(replay),
    "same seed reproduces the same 256-wave sequence"
  );
  check(
    "runtime.seed-variation",
    JSON.stringify(first) !== JSON.stringify(alternate),
    "different seeds produce a different wave sequence"
  );
  check(
    "runtime.solvable-waves",
    first.every(({ plan, solvable }) => solvable
      && plan.obstacles.length >= 1
      && plan.obstacles.length < rules.BIKE_ARCADE_LANES
      && plan.obstacles.every((obstacle) => obstacle.lane !== plan.safeLane)),
    "every generated wave leaves at least one reachable lane"
  );

  const storyFinishDistance = rules.advanceBikeDistance(754, 1_000, "story");
  const endlessSecondLapDistance = rules.advanceBikeDistance(754, 1_000, "endless");
  check(
    "runtime.story-755-finish",
    storyFinishDistance === 755
      && rules.shouldFinishBikeArcadeRun("story", storyFinishDistance, 3) === "won",
    "story mode still completes at exactly 755m"
  );
  check(
    "runtime.endless-755-continues",
    endlessSecondLapDistance > 755
      && rules.getBikeArcadeLap(endlessSecondLapDistance) === 2
      && rules.shouldFinishBikeArcadeRun("endless", endlessSecondLapDistance, 3) === null,
    "endless mode crosses 755m and continues into lap two"
  );
  check(
    "runtime.endless-lives-finish",
    rules.shouldFinishBikeArcadeRun("endless", 2_000, 0) === "lost",
    "endless mode settles only after lives are exhausted or the numeric cap is reached"
  );

  const history = Array.from({ length: 200 }, (_, index) => index).reduce(
    (entries, waveIndex) => rules.appendBikeWaveHistory(entries, waveIndex),
    []
  );
  check(
    "runtime.resource-bounds",
    history.length === rules.MAX_BIKE_ARCADE_WAVE_HISTORY
      && rules.bikeObstacleSpeed(rules.BIKE_ARCADE_MAX_DISTANCE, "endless") <= rules.BIKE_ARCADE_MAX_OBSTACLE_SPEED
      && rules.getBikeArcadeTier(rules.BIKE_ARCADE_MAX_DISTANCE) <= rules.BIKE_ARCADE_MAX_TIER,
    "history, speed and difficulty tier remain bounded during long runs"
  );
  check(
    "runtime.near-miss-score",
    rules.scoreBikeNearMiss(2, 2) > rules.scoreBikeNearMiss(1, 1)
      && Number.isSafeInteger(rules.scoreBikeNearMiss(rules.BIKE_ARCADE_MAX_COMBO, rules.BIKE_ARCADE_MAX_TIER)),
    "near-miss combo awards bounded monotonic score"
  );

  const lifecycle = new runtime.BikeArcadeLifecycle(100);
  const normalFrame = lifecycle.consumeFrame(5_000);
  const pausedTransition = lifecycle.setPauseReason("window-blur", true);
  const pausedFrame = lifecycle.consumeFrame(16);
  const resumeTransition = lifecycle.setPauseReason("window-blur", false);
  const resumeFrame = lifecycle.consumeFrame(5_000);
  const postResumeFrame = lifecycle.consumeFrame(5_000);
  check(
    "runtime.delta-guard",
    normalFrame.deltaMs === 100
      && pausedTransition === "paused"
      && pausedFrame.deltaMs === 0
      && resumeTransition === "resume-pending"
      && resumeFrame.deltaMs === 0
      && resumeFrame.resumed === true
      && postResumeFrame.deltaMs === 100,
    "large deltas are capped and the first resumed frame is discarded"
  );

  const storyEvents = [];
  const storyBridge = {
    onDistance: (distance) => storyEvents.push(["distance", distance]),
    onLives: (lives) => storyEvents.push(["lives", lives]),
    onCollision: (event) => storyEvents.push(["collision", event]),
    onMilestone: (milestone) => storyEvents.push(["milestone", milestone]),
    onLaneChanged: (event) => storyEvents.push(["lane_changed", event]),
    onNearMiss: (event) => storyEvents.push(["near_miss", event]),
    onPauseChange: (paused) => storyEvents.push(["pause_changed", paused]),
    onFinish: (result, summary) => storyEvents.push(["finish", result, summary])
  };
  const dispatcher = new runtime.BikeArcadeStoryBridgeDispatcher(storyBridge);
  const collision = { obstacleType: "barrier", lives: 2, invulnerableMs: 900 };
  const summary = { distance: 755, lives: 2, lastMilestone: 755 };
  const accepted = [
    dispatcher.dispatch({ type: "distance", distance: 188 }),
    dispatcher.dispatch({ type: "lives", lives: 2 }),
    dispatcher.dispatch({ type: "collision", event: collision }),
    dispatcher.dispatch({ type: "milestone", milestone: 188 }),
    dispatcher.dispatch({ type: "lane_changed", event: { from: 1, to: 2 } }),
    dispatcher.dispatch({ type: "near_miss", event: { obstacleType: "crowd", lane: 1 } }),
    dispatcher.dispatch({ type: "pause_changed", paused: true }),
    dispatcher.dispatch({ type: "pause_changed", paused: false }),
    dispatcher.dispatch({ type: "finish", result: "won", summary })
  ];
  const rejectedAfterFinish = [
    dispatcher.dispatch({ type: "distance", distance: 755 }),
    dispatcher.dispatch({ type: "finish", result: "won", summary })
  ];
  check(
    "runtime.story-bridge-parity",
    accepted.every(Boolean)
      && rejectedAfterFinish.every((value) => value === false)
      && JSON.stringify(storyEvents) === JSON.stringify([
        ["distance", 188],
        ["lives", 2],
        ["collision", collision],
        ["milestone", 188],
        ["lane_changed", { from: 1, to: 2 }],
        ["near_miss", { obstacleType: "crowd", lane: 1 }],
        ["pause_changed", true],
        ["pause_changed", false],
        ["finish", "won", summary]
      ]),
    "story bridge dispatch preserves callback order, payloads and one-shot finish"
  );
} catch (error) {
  check(
    "runtime.bundle",
    false,
    `bike runtime validation failed: ${error instanceof Error ? error.message : String(error)}`
  );
} finally {
  await rm(bundleDirectory, { recursive: true, force: true });
}

const failures = checks.filter((entry) => !entry.passed);
console.log(`Bike arcade contract summary checks=${checks.length} passed=${checks.length - failures.length} failed=${failures.length}`);
for (const entry of checks) {
  console.log(`- ${entry.passed ? "PASS" : "FAIL"} ${entry.id}: ${entry.detail}`);
}
if (failures.length > 0) {
  process.exitCode = 1;
}
