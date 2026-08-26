import { build } from "esbuild";
import { mkdtemp, rm } from "node:fs/promises";
import os from "node:os";
import path from "node:path";
import { fileURLToPath, pathToFileURL } from "node:url";

const root = path.resolve(fileURLToPath(new URL("..", import.meta.url)));
const tempDir = await mkdtemp(path.join(os.tmpdir(), "qizhen-rain-safety-"));
const bundlePath = path.join(tempDir, "runtime.mjs");

try {
  await build({
    stdin: {
      contents: [
        'export { ChapterThreeQizhenLakeController } from "./src/modules/ChapterThreeQizhenLakeController.ts";',
        'export { createInitialGameState } from "./src/core/GameState.ts";',
        'export { selectCampusWeather } from "./src/modules/CampusWeatherModel.ts";',
        'export { createDeveloperCheckpointState } from "./src/modules/DeveloperChannel.ts";',
        'export { QIZHEN_DOCK_AFTER_RAIN_PUDDLES, QIZHEN_LAKE_WORLD, QIZHEN_LAKE_ZONES, isQizhenAfterRainPuddleFootHit } from "./src/scenes/rpg/QizhenLakeModel.ts";',
        'export { default as qizhenContent } from "./src/data/chapter3-qizhen-lake.content.json";'
      ].join("\n"),
      resolveDir: root,
      sourcefile: "qizhen-rain-safety-entry.ts"
    },
    outfile: bundlePath,
    bundle: true,
    format: "esm",
    platform: "node",
    target: "node20"
  });
  const {
    ChapterThreeQizhenLakeController,
    QIZHEN_DOCK_AFTER_RAIN_PUDDLES,
    QIZHEN_LAKE_WORLD,
    QIZHEN_LAKE_ZONES,
    createInitialGameState,
    isQizhenAfterRainPuddleFootHit,
    qizhenContent,
    selectCampusWeather,
    createDeveloperCheckpointState
  } =
    await import(`${pathToFileURL(bundlePath).href}?v=${Date.now()}`);

  const events = [];
  const eventBus = { emit: (name, payload) => events.push({ name, payload }) };
  const makeStore = (state) => ({
    getState: () => state,
    setState: (update) => { state = typeof update === "function" ? update(state) : update; }
  });
  const state = createInitialGameState();
  state.qizhenLake = {
    ...state.qizhenLake,
    active: true,
    phase: "boarding_tutorial",
    zone: "dock",
    vehicle: "on_foot",
    kayakEquipped: true,
    leftPaddleEquipped: true,
    rightPaddleEquipped: true,
    weatherAdjustmentRequested: false,
    rainSafetyCleared: false
  };
  const store = makeStore(state);
  const controller = new ChapterThreeQizhenLakeController(store, eventBus);

  if (selectCampusWeather(store.getState()).boatingAllowed !== false) {
    throw new Error("light rain must block boating before safety clearance");
  }
  if (controller.boardKayak() !== "locked" || store.getState().qizhenLake.vehicle !== "on_foot") {
    throw new Error("controller must reject boarding while the rain hold is active");
  }
  if (!events.some((event) => event.name === "qizhen_kayak_board_rejected")) {
    throw new Error("rain rejection must emit visible feedback");
  }
  if (controller.requestDockSafetyClearance() !== "accepted"
    || !store.getState().qizhenLake.weatherAdjustmentRequested
    || store.getState().qizhenLake.rainSafetyCleared
    || selectCampusWeather(store.getState()).condition !== "light_rain") {
    throw new Error("safety officer must submit the weather request without clearing the rain hold");
  }
  if (controller.boardKayak() !== "locked") {
    throw new Error("boarding must stay blocked until the weather app executes the request");
  }
  store.setState((current) => ({ ...current, runtimeMode: "phone", currentScene: "weather" }));
  if (controller.applyDockWeatherAdjustment() !== "accepted"
    || !store.getState().qizhenLake.rainSafetyCleared
    || selectCampusWeather(store.getState()).condition !== "overcast"
    || selectCampusWeather(store.getState()).label !== "多云") {
    throw new Error("weather app must clear the rain hold and publish the overcast projection");
  }
  store.setState((current) => ({ ...current, runtimeMode: "rpg", currentScene: "phone_home" }));
  if (controller.boardKayak() !== "accepted" || store.getState().qizhenLake.vehicle !== "kayak") {
    throw new Error("boarding must resume after weather adjustment");
  }

  const incomplete = createInitialGameState();
  incomplete.qizhenLake = {
    ...incomplete.qizhenLake,
    active: true,
    phase: "dock_outfitting",
    zone: "dock",
    vehicle: "on_foot"
  };
  const incompleteStore = makeStore(incomplete);
  const incompleteController = new ChapterThreeQizhenLakeController(incompleteStore, eventBus);
  if (incompleteController.requestDockSafetyClearance() !== "locked"
    || incompleteStore.getState().qizhenLake.weatherAdjustmentRequested
    || incompleteStore.getState().qizhenLake.rainSafetyCleared) {
    throw new Error("safety officer must keep the rain hold when equipment is incomplete");
  }
  const bypass = createInitialGameState();
  bypass.runtimeMode = "phone";
  bypass.currentScene = "weather";
  bypass.qizhenLake = {
    ...bypass.qizhenLake,
    active: true,
    phase: "boarding_tutorial",
    zone: "dock",
    vehicle: "on_foot",
    kayakEquipped: true,
    leftPaddleEquipped: true,
    rightPaddleEquipped: true,
    weatherAdjustmentRequested: false,
    rainSafetyCleared: false
  };
  const bypassStore = makeStore(bypass);
  const bypassController = new ChapterThreeQizhenLakeController(bypassStore, eventBus);
  if (bypassController.applyDockWeatherAdjustment() !== "locked"
    || bypassStore.getState().qizhenLake.rainSafetyCleared) {
    throw new Error("weather app must reject adjustment without the safety officer request");
  }
  const rainCheckpoint = createDeveloperCheckpointState("c3-qizhen-rain-hold");
  const controlCheckpoint = createDeveloperCheckpointState("c3-qizhen-weather-control");
  const overcastCheckpoint = createDeveloperCheckpointState("c3-qizhen-overcast");
  if (rainCheckpoint.runtimeMode !== "rpg"
    || !rainCheckpoint.qizhenLake.kayakEquipped
    || rainCheckpoint.qizhenLake.weatherAdjustmentRequested
    || selectCampusWeather(rainCheckpoint).condition !== "light_rain") {
    throw new Error("rain-hold developer checkpoint must seed equipped rainy dock state");
  }
  if (controlCheckpoint.runtimeMode !== "phone"
    || controlCheckpoint.currentScene !== "weather"
    || !controlCheckpoint.qizhenLake.weatherAdjustmentRequested
    || controlCheckpoint.qizhenLake.rainSafetyCleared) {
    throw new Error("weather-control developer checkpoint must seed the requested phone-app state");
  }
  if (overcastCheckpoint.runtimeMode !== "rpg"
    || !overcastCheckpoint.qizhenLake.rainSafetyCleared
    || selectCampusWeather(overcastCheckpoint).label !== "多云") {
    throw new Error("overcast developer checkpoint must seed the cleared dock state");
  }
  if (QIZHEN_DOCK_AFTER_RAIN_PUDDLES.length !== 4) {
    throw new Error("overcast dock must expose four authored after-rain puddles");
  }
  const puddleBoundsIntersect = (puddle, collision) => {
    const left = puddle.x - puddle.width / 2;
    const right = puddle.x + puddle.width / 2;
    const top = puddle.y - puddle.height / 2;
    const bottom = puddle.y + puddle.height / 2;
    return left < collision.right && right > collision.left && top < collision.bottom && bottom > collision.top;
  };
  for (const puddle of QIZHEN_DOCK_AFTER_RAIN_PUDDLES) {
    if (puddle.width <= 0 || puddle.height <= 0
      || puddle.x - puddle.width / 2 < 0
      || puddle.y - puddle.height / 2 < 0
      || puddle.x + puddle.width / 2 > QIZHEN_LAKE_WORLD.width
      || puddle.y + puddle.height / 2 > QIZHEN_LAKE_WORLD.height) {
      throw new Error(`after-rain puddle leaves source bounds: ${puddle.id}`);
    }
    if (QIZHEN_LAKE_ZONES.dock.onFootCollisions.some((collision) => puddleBoundsIntersect(puddle, collision))) {
      throw new Error(`after-rain puddle overlaps blocked dock geometry: ${puddle.id}`);
    }
    if (!isQizhenAfterRainPuddleFootHit(puddle, puddle.x, puddle.y)
      || isQizhenAfterRainPuddleFootHit(puddle, puddle.x + puddle.width, puddle.y)) {
      throw new Error(`after-rain puddle foot-point hit test drifted: ${puddle.id}`);
    }
  }
  if (qizhenContent.dock.afterRainProof !== "这是下过雨的证明") {
    throw new Error("after-rain puddle feedback copy must stay exact");
  }
  console.log("Qizhen rain safety PASS assertions=19 gate=controller-owned weather=shared-selector workflow=safety-to-app developer-checkpoints=3 puddles=4+walkable+foot-hit feedback=event-backed");
} finally {
  await rm(tempDir, { recursive: true, force: true });
}
