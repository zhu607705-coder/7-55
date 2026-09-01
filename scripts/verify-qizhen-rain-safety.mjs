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
        'export { ChapterThreeQizhenLakeController, selectQizhenEntranceAccess } from "./src/modules/ChapterThreeQizhenLakeController.ts";',
        'export { createInitialGameState } from "./src/core/GameState.ts";',
        'export { SaveStore } from "./src/core/SaveStore.ts";',
        'export { GAME_SAVE_KEY } from "./src/core/StorageKeys.ts";',
        'export { selectCampusWeather } from "./src/modules/CampusWeatherModel.ts";',
        'export { createQizhenWeatherControlFrame, getQizhenWeatherMinimumMoves, isQizhenWeatherCloudAligned, isValidQizhenWeatherControlSummary, stepQizhenWeatherControl, QIZHEN_WEATHER_CLOUD_INITIAL, QIZHEN_WEATHER_STABLE_REQUIRED_MS } from "./src/modules/QizhenWeatherControlModel.ts";',
        'export { createDeveloperCheckpointState } from "./src/modules/DeveloperChannel.ts";',
        'export { QIZHEN_DOCK_AFTER_RAIN_PUDDLES, QIZHEN_DOCK_RAIN_EFFECT_PROFILE, QIZHEN_DOCK_RAIN_SPLASH_SITES, QIZHEN_LAKE_WORLD, QIZHEN_LAKE_ZONES, isQizhenAfterRainPuddleFootHit } from "./src/scenes/rpg/QizhenLakeModel.ts";',
        'export { QIZHEN_RAIN_RESCUE_ROUTE, QIZHEN_RAIN_RESCUE_REDUCED_ROUTE_INDICES, getQizhenRainRescueDurationMs } from "./src/scenes/rpg/QizhenRainRescuePresentation.ts";',
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
    GAME_SAVE_KEY,
    QIZHEN_DOCK_AFTER_RAIN_PUDDLES,
    QIZHEN_DOCK_RAIN_EFFECT_PROFILE,
    QIZHEN_DOCK_RAIN_SPLASH_SITES,
    QIZHEN_LAKE_WORLD,
    QIZHEN_LAKE_ZONES,
    QIZHEN_RAIN_RESCUE_REDUCED_ROUTE_INDICES,
    QIZHEN_RAIN_RESCUE_ROUTE,
    QIZHEN_WEATHER_STABLE_REQUIRED_MS,
    createQizhenWeatherControlFrame,
    createInitialGameState,
    getQizhenWeatherMinimumMoves,
    getQizhenRainRescueDurationMs,
    isQizhenAfterRainPuddleFootHit,
    isQizhenWeatherCloudAligned,
    isValidQizhenWeatherControlSummary,
    QIZHEN_WEATHER_CLOUD_INITIAL,
    SaveStore,
    stepQizhenWeatherControl,
    qizhenContent,
    selectCampusWeather,
    selectQizhenEntranceAccess,
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
    rainWarningSeen: false,
    rainRescueCompleted: false,
    weatherAdjustmentRequested: false,
    rainSafetyCleared: false
  };
  const store = makeStore(state);
  const controller = new ChapterThreeQizhenLakeController(store, eventBus);

  for (let keywordMask = 0; keywordMask < 7; keywordMask += 1) {
    const access = selectQizhenEntranceAccess({
      ...state.qizhenLake,
      phase: "location_search",
      bridgeClueFound: (keywordMask & 1) !== 0,
      reflectionClueFound: (keywordMask & 2) !== 0,
      lakeClueFound: (keywordMask & 4) !== 0
    });
    if (access.visible || access.available || access.keywordsCollected) {
      throw new Error(`Qizhen entrance must stay hidden before all keywords are collected: mask=${keywordMask}`);
    }
  }
  const collectedEntrance = selectQizhenEntranceAccess({
    ...state.qizhenLake,
    phase: "location_search",
    bridgeClueFound: true,
    reflectionClueFound: true,
    lakeClueFound: true
  });
  if (!collectedEntrance.visible || collectedEntrance.available || !collectedEntrance.keywordsCollected) {
    throw new Error("all three keywords must reveal the locked Qizhen entrance without opening it early");
  }
  const unlockedEntrance = selectQizhenEntranceAccess({
    ...state.qizhenLake,
    phase: "lake_unlocked",
    bridgeClueFound: false,
    reflectionClueFound: false,
    lakeClueFound: false
  });
  if (!unlockedEntrance.visible || !unlockedEntrance.available) {
    throw new Error("already-progressed or migrated lake states must keep the Qizhen entrance available");
  }

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
    || !store.getState().qizhenLake.rainWarningSeen
    || store.getState().qizhenLake.rainRescueCompleted
    || store.getState().qizhenLake.weatherAdjustmentRequested
    || store.getState().qizhenLake.rainSafetyCleared
    || selectCampusWeather(store.getState()).condition !== "light_rain") {
    throw new Error("teacher warning must record the rain hold without opening the weather control");
  }
  if (controller.beginDockWeatherAdjustment() !== "inactive") {
    throw new Error("weather control must stay unavailable before the forced-launch rescue");
  }
  if (controller.boardKayak() !== "accepted"
    || store.getState().qizhenLake.vehicle !== "on_foot"
    || !events.some((event) => event.name === "qizhen_rain_forced_launch_started")) {
    throw new Error("second boarding attempt must start the visible forced-launch sequence without boarding");
  }
  if (controller.completeRainRescue() !== "accepted"
    || store.getState().qizhenLake.phase !== "rain_recovery"
    || store.getState().rpgScene !== "dorm_hub"
    || store.getState().rpgCheckpoint !== "dorm_spawn"
    || !store.getState().qizhenLake.rainRescueCompleted
    || !store.getState().qizhenLake.weatherAdjustmentRequested
    || store.getState().items.hairDryer) {
    throw new Error("forced-launch rescue must return the player to the dorm without granting the dryer");
  }
  const sceneBeforeBlockedReturn = store.getState().rpgScene;
  if (controller.enterLake() !== false
    || store.getState().rpgScene !== sceneBeforeBlockedReturn
    || store.getState().qizhenLake.phase !== "rain_recovery") {
    throw new Error("returning to the lake before weather adjustment must remain blocked without replaying the capsize");
  }
  store.setState((current) => ({ ...current, currentScene: "weather" }));
  if (controller.beginDockWeatherAdjustment() !== "locked") {
    throw new Error("weather control must require the dorm hair dryer after rescue");
  }
  store.setState((current) => ({ ...current, currentScene: "phone_home" }));
  if (controller.collectHairDryer() !== "accepted" || !store.getState().items.hairDryer) {
    throw new Error("the dorm desk interaction must grant the real hair dryer item");
  }
  // Desktop split keeps runtimeMode=rpg while the player focuses the phone pane.
  store.setState((current) => ({ ...current, runtimeMode: "rpg", currentScene: "weather" }));
  if (controller.beginDockWeatherAdjustment() !== "accepted"
    || store.getState().qizhenLake.weatherControlAttempts !== 1) {
    throw new Error("focused desktop phone pane must begin one persisted cloud calibration attempt");
  }
  const advanceWeatherControl = (frame, directions, durationMs) => {
    let next = frame;
    for (let elapsed = 0; elapsed < durationMs; elapsed += 20) {
      next = stepQizhenWeatherControl(next, directions, Math.min(20, durationMs - elapsed));
    }
    return next;
  };
  let weatherFrame = createQizhenWeatherControlFrame();
  weatherFrame = advanceWeatherControl(weatherFrame, [-1, 1, 1], 1150);
  weatherFrame = advanceWeatherControl(weatherFrame, [0, 1, 1], 250);
  weatherFrame = advanceWeatherControl(weatherFrame, [0, 0, 1], 160);
  weatherFrame = advanceWeatherControl(weatherFrame, [0, 0, 0], 1000);
  const cloudOffsets = weatherFrame.positions;
  const validWeatherSummary = {
    moves: 3,
    cloudOffsets,
    controlledBands: [true, true, true],
    stableMs: weatherFrame.stableMs,
    elapsedMs: weatherFrame.elapsedMs
  };
  if (!isQizhenWeatherCloudAligned(cloudOffsets)
    || weatherFrame.stableMs !== QIZHEN_WEATHER_STABLE_REQUIRED_MS
    || getQizhenWeatherMinimumMoves() !== 3
    || !isValidQizhenWeatherControlSummary(validWeatherSummary)) {
    throw new Error("continuous cloud calibration must counter the leftward wind and stabilize all three bands");
  }
  if (controller.applyDockWeatherAdjustment({ ...validWeatherSummary, stableMs: 999 }) !== "locked"
    || store.getState().qizhenLake.rainSafetyCleared) {
    throw new Error("controller must reject a cloud calibration that was not stable for one second");
  }
  if (controller.applyDockWeatherAdjustment(validWeatherSummary) !== "accepted"
    || !store.getState().qizhenLake.rainSafetyCleared
    || store.getState().items.hairDryer
    || store.getState().qizhenLake.phase !== "boarding_tutorial"
    || store.getState().qizhenLake.weatherControlBestMoves !== 3
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
    || reloaded.qizhenLake.weatherControlBestMoves !== 3
    || !reloaded.qizhenLake.rainWarningSeen
    || !reloaded.qizhenLake.rainRescueCompleted
    || !reloaded.qizhenLake.rainSafetyCleared
    || reloaded.items.hairDryer) {
    throw new Error("warning, rescue, calibration, completion, and dryer consumption must survive save reload");
  }

  const legacyState = createInitialGameState();
  legacyState.qizhenLake = {
    ...legacyState.qizhenLake,
    active: true,
    phase: "boarding_tutorial",
    zone: "dock",
    vehicle: "on_foot",
    kayakEquipped: true,
    leftPaddleEquipped: true,
    rightPaddleEquipped: true,
    weatherAdjustmentRequested: true,
    rainSafetyCleared: false
  };
  const legacyStored = new Map();
  const legacyStorage = {
    get length() { return legacyStored.size; },
    clear: () => legacyStored.clear(),
    getItem: (key) => legacyStored.get(key) ?? null,
    key: (index) => [...legacyStored.keys()][index] ?? null,
    removeItem: (key) => legacyStored.delete(key),
    setItem: (key, value) => legacyStored.set(key, String(value))
  };
  legacyStorage.setItem(GAME_SAVE_KEY, JSON.stringify({ version: 29, state: legacyState, savedAt: 1 }));
  const migratedLegacy = new SaveStore(legacyStorage).load(createInitialGameState());
  if (!migratedLegacy
    || migratedLegacy.qizhenLake.phase !== "rain_recovery"
    || !migratedLegacy.qizhenLake.rainWarningSeen
    || !migratedLegacy.qizhenLake.rainRescueCompleted
    || !migratedLegacy.qizhenLake.weatherAdjustmentRequested
    || !migratedLegacy.items.hairDryer) {
    throw new Error("v29 pending weather saves must migrate into a recoverable dryer-ready state");
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
    || incompleteStore.getState().qizhenLake.rainWarningSeen
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
    phase: "rain_recovery",
    zone: "dock",
    vehicle: "on_foot",
    kayakEquipped: true,
    leftPaddleEquipped: true,
    rightPaddleEquipped: true,
    rainWarningSeen: true,
    rainRescueCompleted: false,
    weatherAdjustmentRequested: true,
    rainSafetyCleared: false
  };
  const bypassStore = makeStore(bypass);
  const bypassController = new ChapterThreeQizhenLakeController(bypassStore, eventBus);
  if (bypassController.applyDockWeatherAdjustment(validWeatherSummary) !== "locked"
    || bypassStore.getState().qizhenLake.rainSafetyCleared) {
    throw new Error("weather app must reject adjustment without the rescue and hair dryer");
  }
  bypass.qizhenLake.rainRescueCompleted = true;
  bypass.items.hairDryer = true;
  const invalidStore = makeStore(bypass);
  const invalidController = new ChapterThreeQizhenLakeController(invalidStore, eventBus);
  if (invalidController.beginDockWeatherAdjustment() !== "accepted"
    || invalidController.applyDockWeatherAdjustment({
      ...validWeatherSummary,
      controlledBands: [true, true, false]
    }) !== "locked"
    || invalidStore.getState().qizhenLake.rainSafetyCleared) {
    throw new Error("controller must reject an impossible cloud calibration summary");
  }
  const rainCheckpoint = createDeveloperCheckpointState("c3-qizhen-rain-hold");
  const rescueCheckpoint = createDeveloperCheckpointState("c3-qizhen-rescue-dorm");
  const dryerCheckpoint = createDeveloperCheckpointState("c3-qizhen-hair-dryer");
  const controlCheckpoint = createDeveloperCheckpointState("c3-qizhen-weather-control");
  const overcastCheckpoint = createDeveloperCheckpointState("c3-qizhen-overcast");
  if (rainCheckpoint.runtimeMode !== "rpg"
    || !rainCheckpoint.qizhenLake.kayakEquipped
    || rainCheckpoint.qizhenLake.rainWarningSeen
    || rainCheckpoint.qizhenLake.weatherAdjustmentRequested
    || selectCampusWeather(rainCheckpoint).condition !== "light_rain") {
    throw new Error("rain-hold developer checkpoint must seed equipped rainy dock state");
  }
  if (rescueCheckpoint.runtimeMode !== "rpg"
    || rescueCheckpoint.rpgScene !== "dorm_hub"
    || rescueCheckpoint.qizhenLake.phase !== "rain_recovery"
    || !rescueCheckpoint.qizhenLake.rainRescueCompleted
    || rescueCheckpoint.items.hairDryer) {
    throw new Error("rescue-dorm developer checkpoint must seed the pre-pickup desk state");
  }
  if (dryerCheckpoint.runtimeMode !== "rpg"
    || dryerCheckpoint.rpgScene !== "dorm_hub"
    || !dryerCheckpoint.items.hairDryer
    || !dryerCheckpoint.qizhenLake.weatherAdjustmentRequested) {
    throw new Error("hair-dryer developer checkpoint must seed the collected dorm state");
  }
  if (controlCheckpoint.runtimeMode !== "phone"
    || controlCheckpoint.currentScene !== "weather"
    || !controlCheckpoint.qizhenLake.weatherAdjustmentRequested
    || !controlCheckpoint.qizhenLake.rainRescueCompleted
    || !controlCheckpoint.items.hairDryer
    || controlCheckpoint.qizhenLake.phase !== "rain_recovery"
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
  if (qizhenContent.dock.safetyRainBlock !== "值班老师：现在天气不能下水。你要坚持，可以继续靠近码头试试。"
    || qizhenContent.dock.rainReturnBlocked !== "值班老师：这么不长记性，还想要再成一次落汤鸡不成。"
    || !qizhenContent.dock.forcedLaunch
    || !qizhenContent.dock.forcedCapsize
    || !qizhenContent.dock.forcedRescue) {
    throw new Error("teacher force-launch hint, repeat-entry rejection, and rescue copy must remain event-backed");
  }
  const reducedRescueRoute = QIZHEN_RAIN_RESCUE_REDUCED_ROUTE_INDICES.map(
    (index) => QIZHEN_RAIN_RESCUE_ROUTE[index]
  );
  if (QIZHEN_RAIN_RESCUE_ROUTE.length !== 6
    || QIZHEN_RAIN_RESCUE_REDUCED_ROUTE_INDICES.length !== 3
    || reducedRescueRoute.some((point, index) => (
      !point || (index > 0 && point.side === reducedRescueRoute[index - 1]?.side)
    ))
    || !QIZHEN_RAIN_RESCUE_ROUTE.every((point, index) => (
      point.side === (index % 2 === 0 ? "left" : "right")
      && point.intensity > 0
      && dockWaterAreas.some((water) => (
        point.x >= water.left && point.x <= water.right && point.y >= water.top && point.y <= water.bottom
      ))
    ))) {
    throw new Error("forced-launch presentation must keep six alternating in-water strokes and a reduced-motion route");
  }
  if (getQizhenRainRescueDurationMs(false) < 7000
    || getQizhenRainRescueDurationMs(false) > 8000
    || getQizhenRainRescueDurationMs(true) > 2500) {
    throw new Error("forced-launch presentation duration must remain extended while reduced motion stays concise");
  }
  console.log("Qizhen rain safety PASS gate=hidden-until-3-keywords+teacher-warning+six-stroke-forced-launch+dramatic-capsize+cinematic-rescue+dorm-dryer+repeat-entry-block weather=shared-selector cloud-calibration=continuous-left-wind+6-keys+3-bands+1s-stability+dryer-consume+save-reload migration=v29-recoverable developer-checkpoints=5 map-resume=first-entry-boundary+gate+lake-checkpoint rain-effects=64+36-streaks+3-mist+4-sheen+18-splashes puddles=4+walkable+foot-hit feedback=event-backed");
} finally {
  await rm(tempDir, { recursive: true, force: true });
}
