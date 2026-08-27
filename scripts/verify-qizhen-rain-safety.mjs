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
        'export { SaveStore } from "./src/core/SaveStore.ts";',
        'export { selectCampusWeather } from "./src/modules/CampusWeatherModel.ts";',
        'export { getQizhenWeatherMinimumMoves, isQizhenWeatherCloudAligned, moveQizhenWeatherCloud, QIZHEN_WEATHER_CLOUD_INITIAL } from "./src/modules/QizhenWeatherControlModel.ts";',
        'export { createDeveloperCheckpointState } from "./src/modules/DeveloperChannel.ts";',
        'export { QIZHEN_DOCK_AFTER_RAIN_PUDDLES, QIZHEN_DOCK_RAIN_EFFECT_PROFILE, QIZHEN_DOCK_RAIN_SPLASH_SITES, QIZHEN_LAKE_WORLD, QIZHEN_LAKE_ZONES, isQizhenAfterRainPuddleFootHit } from "./src/scenes/rpg/QizhenLakeModel.ts";',
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
    QIZHEN_DOCK_RAIN_EFFECT_PROFILE,
    QIZHEN_DOCK_RAIN_SPLASH_SITES,
    QIZHEN_LAKE_WORLD,
    QIZHEN_LAKE_ZONES,
    createInitialGameState,
    getQizhenWeatherMinimumMoves,
    isQizhenAfterRainPuddleFootHit,
    isQizhenWeatherCloudAligned,
    moveQizhenWeatherCloud,
    QIZHEN_WEATHER_CLOUD_INITIAL,
    SaveStore,
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
  // Desktop split keeps runtimeMode=rpg while the player focuses the phone pane.
  store.setState((current) => ({ ...current, runtimeMode: "rpg", currentScene: "weather" }));
  if (controller.beginDockWeatherAdjustment() !== "accepted"
    || store.getState().qizhenLake.weatherControlAttempts !== 1) {
    throw new Error("focused desktop phone pane must begin one persisted cloud calibration attempt");
  }
  let cloudOffsets = QIZHEN_WEATHER_CLOUD_INITIAL;
  cloudOffsets = moveQizhenWeatherCloud(cloudOffsets, 0, 1);
  cloudOffsets = moveQizhenWeatherCloud(cloudOffsets, 0, 1);
  cloudOffsets = moveQizhenWeatherCloud(cloudOffsets, 1, 1);
  cloudOffsets = moveQizhenWeatherCloud(cloudOffsets, 1, 1);
  cloudOffsets = moveQizhenWeatherCloud(cloudOffsets, 2, 1);
  cloudOffsets = moveQizhenWeatherCloud(cloudOffsets, 2, 1);
  if (!isQizhenWeatherCloudAligned(cloudOffsets) || getQizhenWeatherMinimumMoves() !== 6) {
    throw new Error("cloud calibration model must resolve in six deterministic moves");
  }
  if (controller.applyDockWeatherAdjustment({ moves: 6, cloudOffsets }) !== "accepted"
    || !store.getState().qizhenLake.rainSafetyCleared
    || store.getState().qizhenLake.weatherControlBestMoves !== 6
    || selectCampusWeather(store.getState()).condition !== "overcast"
    || selectCampusWeather(store.getState()).label !== "多云") {
    throw new Error("weather app must clear the rain hold and publish the overcast projection");
  }
  store.setState((current) => ({ ...current, runtimeMode: "rpg", currentScene: "phone_home" }));
  if (controller.boardKayak() !== "accepted" || store.getState().qizhenLake.vehicle !== "kayak") {
    throw new Error("boarding must resume after weather adjustment");
  }
  const stored = new Map();
  const memoryStorage = {
    get length() { return stored.size; },
    clear: () => stored.clear(),
    getItem: (key) => stored.get(key) ?? null,
    key: (index) => [...stored.keys()][index] ?? null,
    removeItem: (key) => stored.delete(key),
    setItem: (key, value) => stored.set(key, String(value))
  };
  const saveStore = new SaveStore(memoryStorage);
  if (!saveStore.save(store.getState())) {
    throw new Error("weather calibration progress must produce a persistent snapshot");
  }
  const reloaded = saveStore.load(createInitialGameState());
  if (!reloaded
    || reloaded.qizhenLake.weatherControlAttempts !== 1
    || reloaded.qizhenLake.weatherControlBestMoves !== 6
    || !reloaded.qizhenLake.rainSafetyCleared) {
    throw new Error("weather calibration attempt, best moves, and completion must survive save reload");
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
  if (bypassController.applyDockWeatherAdjustment({ moves: 6, cloudOffsets }) !== "locked"
    || bypassStore.getState().qizhenLake.rainSafetyCleared) {
    throw new Error("weather app must reject adjustment without the safety officer request");
  }
  bypass.qizhenLake.weatherAdjustmentRequested = true;
  const invalidStore = makeStore(bypass);
  const invalidController = new ChapterThreeQizhenLakeController(invalidStore, eventBus);
  if (invalidController.beginDockWeatherAdjustment() !== "accepted"
    || invalidController.applyDockWeatherAdjustment({ moves: 5, cloudOffsets }) !== "locked"
    || invalidStore.getState().qizhenLake.rainSafetyCleared) {
    throw new Error("controller must reject an impossible cloud calibration summary");
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
  const unlockedBeforeEntry = createDeveloperCheckpointState("c3-qizhen-gate");
  unlockedBeforeEntry.runtimeMode = "phone";
  unlockedBeforeEntry.currentScene = "zjuding";
  unlockedBeforeEntry.rpgCheckpoint = "campus_qizhen_transition_stop";
  const unlockedBeforeEntryStore = makeStore(unlockedBeforeEntry);
  const unlockedBeforeEntryController = new ChapterThreeQizhenLakeController(unlockedBeforeEntryStore, eventBus);
  if (unlockedBeforeEntryController.resumeEnteredMapLocation()
    || unlockedBeforeEntryStore.getState().runtimeMode !== "phone"
    || unlockedBeforeEntryStore.getState().rpgCheckpoint !== "campus_qizhen_transition_stop") {
    throw new Error("location confirmation alone must keep the first Qizhen map-entry page visible");
  }
  const enteredGate = createDeveloperCheckpointState("c3-qizhen-gate");
  enteredGate.runtimeMode = "phone";
  enteredGate.currentScene = "zjuding";
  const enteredGateStore = makeStore(enteredGate);
  const enteredGateController = new ChapterThreeQizhenLakeController(enteredGateStore, eventBus);
  if (!enteredGateController.resumeEnteredMapLocation()
    || enteredGateStore.getState().runtimeMode !== "rpg"
    || enteredGateStore.getState().rpgScene !== "campus_qizhen_loop"
    || enteredGateStore.getState().rpgCheckpoint !== "campus_qizhen_gate") {
    throw new Error("campus map must resume the already-entered Qizhen gate checkpoint");
  }
  const enteredLake = createDeveloperCheckpointState("c3-qizhen-open-water");
  enteredLake.runtimeMode = "phone";
  enteredLake.currentScene = "zjuding";
  const enteredLakeFacts = JSON.stringify(enteredLake.qizhenLake);
  const enteredLakeStore = makeStore(enteredLake);
  const enteredLakeController = new ChapterThreeQizhenLakeController(enteredLakeStore, eventBus);
  if (!enteredLakeController.resumeEnteredMapLocation()
    || enteredLakeStore.getState().runtimeMode !== "rpg"
    || enteredLakeStore.getState().rpgScene !== "qizhen_lake"
    || enteredLakeStore.getState().rpgCheckpoint !== "qizhen_open_water"
    || JSON.stringify(enteredLakeStore.getState().qizhenLake) !== enteredLakeFacts
    || !events.some((event) => event.name === "qizhen_rpg_resumed")) {
    throw new Error("campus map must resume the exact entered lake checkpoint without changing lake progress");
  }
  if (QIZHEN_DOCK_AFTER_RAIN_PUDDLES.length !== 4) {
    throw new Error("overcast dock must expose four authored after-rain puddles");
  }
  if (QIZHEN_DOCK_RAIN_EFFECT_PROFILE.farStreakCount !== 64
    || QIZHEN_DOCK_RAIN_EFFECT_PROFILE.nearStreakCount !== 36
    || QIZHEN_DOCK_RAIN_EFFECT_PROFILE.mistBandCount !== 3
    || QIZHEN_DOCK_RAIN_EFFECT_PROFILE.wetSheenCount !== QIZHEN_DOCK_AFTER_RAIN_PUDDLES.length
    || QIZHEN_DOCK_RAIN_EFFECT_PROFILE.splashCount !== QIZHEN_DOCK_RAIN_SPLASH_SITES.length
    || QIZHEN_DOCK_RAIN_SPLASH_SITES.length !== 18) {
    throw new Error("rain effect profile must preserve two streak layers, mist, wet sheen, and eighteen lake splashes");
  }
  const dockWaterAreas = QIZHEN_LAKE_ZONES.dock.waterAreas;
  for (const site of QIZHEN_DOCK_RAIN_SPLASH_SITES) {
    if (site.width <= 0 || !dockWaterAreas.some((water) => (
      site.x >= water.left && site.x <= water.right && site.y >= water.top && site.y <= water.bottom
    ))) {
      throw new Error(`rain splash leaves dock water: ${site.x},${site.y}`);
    }
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
  console.log("Qizhen rain safety PASS assertions=50 gate=controller-owned weather=shared-selector cloud-calibration=3-bands+6-min-moves+save-reload developer-checkpoints=3 map-resume=first-entry-boundary+gate+lake-checkpoint rain-effects=64+36-streaks+3-mist+4-sheen+18-splashes puddles=4+walkable+foot-hit feedback=event-backed");
} finally {
  await rm(tempDir, { recursive: true, force: true });
}
