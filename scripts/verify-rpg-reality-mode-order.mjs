import { build } from "esbuild";
import { mkdtemp, readFile, rm } from "node:fs/promises";
import os from "node:os";
import path from "node:path";
import { fileURLToPath, pathToFileURL } from "node:url";

const root = path.resolve(fileURLToPath(new URL("..", import.meta.url)));
const tempDir = await mkdtemp(path.join(os.tmpdir(), "rpg-reality-mode-order-"));
const bundlePath = path.join(tempDir, "runtime.mjs");
let assertionCount = 0;

function assert(condition, message) {
  assertionCount += 1;
  if (!condition) throw new Error(message);
}

function createHarness(createInitialGameState, createGameStore, EventBus, Controller, configure) {
  const state = createInitialGameState();
  configure(state);
  const store = createGameStore(state);
  const events = new EventBus();
  return { store, events, controller: new Controller(store, events) };
}

function snapshot(store, events) {
  return JSON.stringify({ state: store.getState(), events: events.getHistory() });
}

class MemoryStorage {
  #values = new Map();
  get length() { return this.#values.size; }
  clear() { this.#values.clear(); }
  getItem(key) { return this.#values.has(key) ? this.#values.get(key) : null; }
  key(index) { return [...this.#values.keys()][index] ?? null; }
  removeItem(key) { this.#values.delete(key); }
  setItem(key, value) { this.#values.set(String(key), String(value)); }
}

try {
  await build({
    stdin: {
      contents: [
        'export { createInitialGameState, createGameStore } from "./src/core/GameState.ts";',
        'export { SaveStore } from "./src/core/SaveStore.ts";',
        'export { GAME_SAVE_KEY } from "./src/core/StorageKeys.ts";',
        'export { EventBus } from "./src/core/EventBus.ts";',
        'export { ChapterThreeCanteenController, CANTEEN_EXIT_SEQUENCE } from "./src/modules/ChapterThreeCanteenController.ts";',
        'export { ChapterThreeTheaterController } from "./src/modules/ChapterThreeTheaterController.ts";',
        'export { ChapterThreeQizhenLakeController } from "./src/modules/ChapterThreeQizhenLakeController.ts";',
        'export { ChapterFourTemporalMazeController } from "./src/modules/ChapterFourTemporalMazeController.ts";',
        'export { THEATER_SPOTLIGHT_ROUNDS, getRequiredTheaterSpotlightLockMs } from "./src/scenes/rpg/TheaterSpotlightModel.ts";'
      ].join("\n"),
      resolveDir: root,
      sourcefile: "rpg-reality-mode-order-entry.ts"
    },
    outfile: bundlePath,
    bundle: true,
    format: "esm",
    platform: "node",
    target: "node20"
  });

  const runtime = await import(`${pathToFileURL(bundlePath).href}?v=${Date.now()}`);
  const {
    CANTEEN_EXIT_SEQUENCE,
    ChapterThreeCanteenController,
    ChapterThreeQizhenLakeController,
    ChapterThreeTheaterController,
    ChapterFourTemporalMazeController,
    EventBus,
    GAME_SAVE_KEY,
    SaveStore,
    THEATER_SPOTLIGHT_ROUNDS,
    createGameStore,
    createInitialGameState,
    getRequiredTheaterSpotlightLockMs
  } = runtime;

  const saveAndReload = (state) => {
    const storage = new MemoryStorage();
    const saveStore = new SaveStore(storage);
    assert(saveStore.save(state), "truthful reality-mode state must save");
    const loaded = saveStore.load(createInitialGameState());
    assert(Boolean(loaded), "truthful reality-mode state must reload");
    return loaded;
  };

  const canteenOperationOnly = createInitialGameState();
  canteenOperationOnly.canteenHunt = {
    ...canteenOperationOnly.canteenHunt,
    active: true,
    phase: "chase_ready",
    mode: "light",
    menuDarkClueRead: false,
    pickupDarkClueRead: false,
    identifiedExitIds: [],
    orderedMenuOption: "D",
    blockHits: 3
  };
  const canteenOperationOnlyReloaded = saveAndReload(canteenOperationOnly);
  assert(!canteenOperationOnlyReloaded.canteenHunt.menuDarkClueRead, "save/reload must not infer a menu observation from completed ordering");
  assert(!canteenOperationOnlyReloaded.canteenHunt.pickupDarkClueRead, "save/reload must not infer a pickup observation from completed pickup");
  assert(canteenOperationOnlyReloaded.canteenHunt.identifiedExitIds.length === 0, "save/reload must not infer exit observations from completed blocking");

  const qizhenOperationOnly = createInitialGameState();
  qizhenOperationOnly.qizhenLake = {
    ...qizhenOperationOnly.qizhenLake,
    active: true,
    phase: "tool_chain",
    mode: "light",
    zone: "open_water",
    vehicle: "kayak",
    safeSpawnId: "open_water_entry",
    rodFound: true,
    lockerOpened: true,
    reflectionLocationObserved: false,
    observedFishingSpotIds: []
  };
  const qizhenOperationOnlyReloaded = saveAndReload(qizhenOperationOnly);
  assert(!qizhenOperationOnlyReloaded.qizhenLake.reflectionLocationObserved, "save/reload must not infer the reflection observation from tool-chain progress");
  assert(qizhenOperationOnlyReloaded.qizhenLake.observedFishingSpotIds.length === 0, "save/reload must not infer fishing observations from physical item progress");

  const legacyStorage = new MemoryStorage();
  const legacyState = createInitialGameState();
  legacyState.canteenHunt = {
    ...legacyState.canteenHunt,
    active: true,
    phase: "chase_ready",
    blockHits: 3
  };
  delete legacyState.canteenHunt.menuDarkClueRead;
  delete legacyState.canteenHunt.pickupDarkClueRead;
  delete legacyState.canteenHunt.identifiedExitIds;
  legacyStorage.setItem(GAME_SAVE_KEY, JSON.stringify({ version: 24, state: legacyState, savedAt: 1 }));
  const migratedLegacyState = new SaveStore(legacyStorage).load(createInitialGameState());
  assert(Boolean(migratedLegacyState), "legacy reality-mode state without explicit observation fields must migrate");
  assert(migratedLegacyState.canteenHunt.menuDarkClueRead && migratedLegacyState.canteenHunt.pickupDarkClueRead, "legacy canteen saves may reconstruct missing observation fields for continuity");
  assert(migratedLegacyState.canteenHunt.identifiedExitIds.length === 3, "legacy canteen saves may reconstruct missing exit observations for continuity");

  const assertFactsEqual = (left, right, label) => {
    assert(JSON.stringify(left) === JSON.stringify(right), `${label}: ${JSON.stringify(left)} !== ${JSON.stringify(right)}`);
  };

  const runChapterFourElevatorPair = (observeFirst) => {
    const { store, controller } = createHarness(
      createInitialGameState,
      createGameStore,
      EventBus,
      ChapterFourTemporalMazeController,
      (state) => {
        state.runtimeMode = "rpg";
        state.rpgScene = "duan_yongping_temporal_maze";
        state.rpgCheckpoint = "c4_a1_lobby";
        state.qizhenLake = { ...state.qizhenLake, phase: "complete", active: false };
        state.chapterThreeInterlude = {
          ...state.chapterThreeInterlude,
          phase: "complete",
          replayUnlocked: true,
          completed: true
        };
        state.chapter4 = {
          ...state.chapter4,
          prologueSeen: true,
          phase: "room204_restore",
          mode: observeFirst ? "dark" : "light",
          building: "A",
          floor: "A1",
          roomId: "a1_lobby",
          timeAuthority: "hall_clock",
          timeState: "1850_evening",
          worldTimeSeconds: 67800,
          phoneStatusTimeSeconds: 67800,
          phoneStatusTimeTrusted: true,
          factIds: ["hour_hand_installed"]
        };
      }
    );
    if (observeFirst) {
      assert(controller.resolve755Intent({ type: "observe_elevator_history" }).accepted, "Chapter 4 dark elevator observation must work before any light operation or classroom check");
      assert(!store.getState().chapter4.factIds.includes("elevator_history_calibrated"), "Chapter 4 dark observation must not synthesize light calibration");
      assert(controller.resolve755Intent({ type: "set_mode", mode: "light" }).accepted, "Chapter 4 must allow switching to light after early dark observation");
      assert(controller.resolve755Intent({ type: "calibrate_elevator_history", startSeconds: 81811 }).accepted, "Chapter 4 light calibration must work after dark observation");
    } else {
      assert(controller.resolve755Intent({ type: "calibrate_elevator_history", startSeconds: 81811 }).accepted, "Chapter 4 light elevator calibration must work before any dark observation or classroom check");
      assert(!store.getState().chapter4.factIds.includes("elevator_history_observed"), "Chapter 4 light calibration must not synthesize dark observation");
      assert(controller.resolve755Intent({ type: "set_mode", mode: "dark" }).accepted, "Chapter 4 must allow switching to dark after early light calibration");
      assert(controller.resolve755Intent({ type: "observe_elevator_history" }).accepted, "Chapter 4 dark observation must remain available after light calibration");
    }
    return ["elevator_history_observed", "elevator_history_calibrated"].filter((factId) => (
      store.getState().chapter4.factIds.includes(factId)
    ));
  };

  assertFactsEqual(
    runChapterFourElevatorPair(true),
    runChapterFourElevatorPair(false),
    "Chapter 4 elevator facts must converge without a light/dark precedence rule"
  );

  const runCanteenMenuOrder = (observeFirst) => {
    const { store, controller } = createHarness(
      createInitialGameState,
      createGameStore,
      EventBus,
      ChapterThreeCanteenController,
      (state) => {
        state.canteenHunt = {
          ...state.canteenHunt,
          active: true,
          phase: "menu_order",
          mode: observeFirst ? "dark" : "light",
          menuDarkClueRead: false
        };
      }
    );
    if (observeFirst) {
      assert(controller.inspectMenuClue(), "canteen menu observe-first path must record the dark menu");
      assert(controller.setMode("light"), "canteen menu observe-first path must switch to light for ordering");
      assert(controller.selectMenuOption("D") === "correct", "canteen menu observe-first path must place the correct order");
    } else {
      assert(controller.selectMenuOption("D") === "correct", "canteen menu operation-first path must place the correct order");
      assert(!store.getState().canteenHunt.menuDarkClueRead, "canteen menu operation must not synthesize an observation fact");
      assert(controller.setMode("dark"), "canteen menu operation-first path must allow a later dark observation");
      assert(controller.inspectMenuClue(), "canteen menu operation-first path must record the real later observation");
    }
    const state = store.getState();
    return {
      phase: state.canteenHunt.phase,
      menuDarkClueRead: state.canteenHunt.menuDarkClueRead,
      orderedMenuOption: state.canteenHunt.orderedMenuOption,
      orderAttemptCount: state.canteenHunt.orderAttemptCount,
      pickupTicket0755: state.items.pickupTicket0755
    };
  };

  assertFactsEqual(
    runCanteenMenuOrder(true),
    runCanteenMenuOrder(false),
    "canteen menu pre-save facts must be order-independent"
  );

  const runCanteenPickup = (observeFirst) => {
    const { store, controller } = createHarness(
      createInitialGameState,
      createGameStore,
      EventBus,
      ChapterThreeCanteenController,
      (state) => {
        state.canteenHunt = {
          ...state.canteenHunt,
          active: true,
          phase: "pickup_search",
          mode: observeFirst ? "dark" : "light",
          orderedMenuOption: "D",
          pickupDarkClueRead: false
        };
        state.items.pickupTicket0755 = true;
      }
    );
    if (observeFirst) {
      assert(controller.inspectPickupWindow("3"), "canteen pickup observe-first path must record window 3");
      assert(controller.setMode("light"), "canteen pickup observe-first path must switch to light for ticket use");
      assert(controller.selectPickupWindow("3") === "correct", "canteen pickup observe-first path must accept the ticket");
    } else {
      assert(controller.selectPickupWindow("3") === "correct", "canteen pickup operation-first path must accept the ticket");
      assert(!store.getState().canteenHunt.pickupDarkClueRead, "canteen pickup operation must not synthesize an observation fact");
      assert(controller.setMode("dark"), "canteen pickup operation-first path must allow a later dark observation");
      assert(controller.inspectPickupWindow("3"), "canteen pickup operation-first path must record the real later observation");
    }
    const state = store.getState();
    return {
      phase: state.canteenHunt.phase,
      pickupDarkClueRead: state.canteenHunt.pickupDarkClueRead,
      orderedMenuOption: state.canteenHunt.orderedMenuOption,
      pickupAttemptCount: state.canteenHunt.pickupAttemptCount,
      pickupTicket0755: state.items.pickupTicket0755
    };
  };

  assertFactsEqual(
    runCanteenPickup(true),
    runCanteenPickup(false),
    "canteen pickup pre-save facts must be order-independent"
  );

  const runCanteenExitSequence = (observeFirst) => {
    const { store, controller } = createHarness(
      createInitialGameState,
      createGameStore,
      EventBus,
      ChapterThreeCanteenController,
      (state) => {
        state.canteenHunt = {
          ...state.canteenHunt,
          active: true,
          phase: "exit_blocking",
          mode: observeFirst ? "dark" : "light",
          blockHits: 0,
          identifiedExitIds: []
        };
      }
    );
    if (observeFirst) {
      CANTEEN_EXIT_SEQUENCE.forEach((exitId, index) => {
        assert(controller.inspectExitCart(exitId), `canteen exit observe-first path must record ${exitId}`);
        assert(controller.setMode("light"), `canteen exit observe-first path must switch to light at step ${index + 1}`);
        const result = controller.blockExit(exitId);
        assert(result === (index === CANTEEN_EXIT_SEQUENCE.length - 1 ? "complete" : "correct"), `canteen exit observe-first path must block ${exitId}`);
        if (index < CANTEEN_EXIT_SEQUENCE.length - 1) {
          assert(controller.setMode("dark"), `canteen exit observe-first path must return to dark at step ${index + 1}`);
        }
      });
    } else {
      CANTEEN_EXIT_SEQUENCE.forEach((exitId, index) => {
        const result = controller.blockExit(exitId);
        assert(result === (index === CANTEEN_EXIT_SEQUENCE.length - 1 ? "complete" : "correct"), `canteen exit operation-first path must block ${exitId}`);
      });
      assert(store.getState().canteenHunt.identifiedExitIds.length === 0, "canteen exit operations must not synthesize observation facts");
      assert(controller.setMode("dark"), "canteen completed exit path must allow later dark observation");
      CANTEEN_EXIT_SEQUENCE.forEach((exitId) => {
        assert(controller.inspectExitCart(exitId), `canteen completed exit path must record the real later observation for ${exitId}`);
      });
    }
    const state = store.getState();
    return {
      phase: state.canteenHunt.phase,
      blockHits: state.canteenHunt.blockHits,
      identifiedExitIds: state.canteenHunt.identifiedExitIds
    };
  };

  assertFactsEqual(
    runCanteenExitSequence(true),
    runCanteenExitSequence(false),
    "canteen exit pre-save facts must be order-independent"
  );

  {
    const { store, controller } = createHarness(
      createInitialGameState,
      createGameStore,
      EventBus,
      ChapterThreeCanteenController,
      (state) => {
        state.canteenHunt = {
          ...state.canteenHunt,
          active: true,
          phase: "exit_blocking",
          mode: "light",
          identifiedExitIds: []
        };
      }
    );
    assert(controller.completeDefense(), "canteen real-time defense must complete");
    assert(store.getState().canteenHunt.identifiedExitIds.length === 0, "canteen real-time defense completion must preserve truthful observation facts");
  }

  const runTheaterPropBox = (observeFirst) => {
    const { store, controller } = createHarness(
      createInitialGameState,
      createGameStore,
      EventBus,
      ChapterThreeTheaterController,
      (state) => {
        state.theaterHunt = {
          ...state.theaterHunt,
          active: true,
          phase: "prop_setup",
          mode: observeFirst ? "dark" : "light",
          propGhostRead: false,
          managerHintRead: false,
          propBoxOpened: false
        };
        state.items.temporaryTheaterTicket = true;
      }
    );
    if (observeFirst) {
      assert(controller.inspectPropBox() === "ghost", "theater prop observe-first path must record the ghost");
      assert(controller.setMode("light"), "theater prop observe-first path must switch to light for scanning");
      assert(controller.openPropBoxWithTicket(), "theater prop observe-first path must open the box");
    } else {
      assert(controller.openPropBoxWithTicket(), "theater prop operation-first path must open the box");
      assert(!store.getState().theaterHunt.propGhostRead && !store.getState().theaterHunt.managerHintRead, "theater prop operation must not synthesize observation facts");
      assert(controller.setMode("dark"), "theater opened prop box must allow a later dark observation");
      assert(controller.inspectPropBox() === "ghost", "theater opened prop box must record the real later observation");
    }
    const state = store.getState();
    return {
      phase: state.theaterHunt.phase,
      propBoxOpened: state.theaterHunt.propBoxOpened,
      propGhostRead: state.theaterHunt.propGhostRead,
      managerHintRead: state.theaterHunt.managerHintRead,
      temporaryTheaterTicket: state.items.temporaryTheaterTicket,
      fluorescentBrush: state.items.fluorescentBrush
    };
  };

  assertFactsEqual(
    runTheaterPropBox(true),
    runTheaterPropBox(false),
    "theater prop pre-save facts must be order-independent"
  );

  const runTheaterProgramOrder = (observeFirst) => {
    const { store, controller } = createHarness(
      createInitialGameState,
      createGameStore,
      EventBus,
      ChapterThreeTheaterController,
      (state) => {
        state.theaterHunt = {
          ...state.theaterHunt,
          active: true,
          phase: "program_search",
          mode: observeFirst ? "dark" : "light",
          collectedProgramIds: [],
          programOrder: []
        };
      }
    );
    const collectAll = () => {
      for (const programId of ["opening", "spotlight", "finale"]) {
        assert(controller.collectProgram(programId), `theater must collect ${programId} in light mode`);
      }
    };
    if (observeFirst) {
      assert(controller.readProgramOrder(), "theater dark residual order must be readable before collecting fragments");
      assert(controller.setMode("light"), "theater observe-first route must switch to light for collection");
      collectAll();
    } else {
      collectAll();
      assert(controller.setMode("dark"), "theater collect-first route must switch to dark for the residual order");
      assert(controller.readProgramOrder(), "theater residual order must remain readable after collection");
      assert(controller.setMode("light"), "theater collect-first route must return to light for the physical console");
    }
    assert(
      controller.setProgramOrder(["spotlight", "opening", "finale"]),
      "theater physical console must accept the observed order in light mode"
    );
    assert(controller.submitProgramOrder(), "theater program order must resolve in either mode order");
    const state = store.getState();
    return {
      phase: state.theaterHunt.phase,
      mode: state.theaterHunt.mode,
      collectedProgramIds: state.theaterHunt.collectedProgramIds,
      programOrder: state.theaterHunt.programOrder,
      spotlightRemote: state.items.spotlightRemote,
      theaterProgramOpening: state.items.theaterProgramOpening,
      theaterProgramSpotlight: state.items.theaterProgramSpotlight,
      theaterProgramFinale: state.items.theaterProgramFinale
    };
  };

  assertFactsEqual(
    runTheaterProgramOrder(true),
    runTheaterProgramOrder(false),
    "theater program puzzle terminal facts must be independent of mode order"
  );

  const runQizhenLockerKey = (observeFirst) => {
    const { store, controller } = createHarness(
      createInitialGameState,
      createGameStore,
      EventBus,
      ChapterThreeQizhenLakeController,
      (state) => {
        state.qizhenLake = {
          ...state.qizhenLake,
          active: true,
          phase: "tool_chain",
          mode: observeFirst ? "dark" : "light",
          zone: "open_water",
          vehicle: "kayak",
          boardingTutorialCompleted: true,
          rodFound: true,
          decoyBaitAttached: true,
          observedFishingSpotIds: []
        };
        state.items.fishingRod = true;
      }
    );
    if (observeFirst) {
      assert(controller.observeReflection("qizhen_item_1_reflection") === "accepted", "Qizhen key observe-first path must record the reflection");
      assert(controller.setMode("light"), "Qizhen key observe-first path must switch to light for casting");
      assert(controller.castAt("locker_key") === "accepted", "Qizhen key observe-first path must catch the key");
    } else {
      assert(controller.castAt("locker_key") === "accepted", "Qizhen key operation-first path must catch the key");
      assert(store.getState().qizhenLake.observedFishingSpotIds.length === 0, "Qizhen key catch must not synthesize an observation fact");
      assert(controller.setMode("dark"), "Qizhen caught key must allow a later dark observation");
      assert(controller.observeReflection("qizhen_item_1_reflection") === "accepted", "Qizhen caught key must record the real later observation");
    }
    const state = store.getState();
    return {
      phase: state.qizhenLake.phase,
      observedFishingSpotIds: state.qizhenLake.observedFishingSpotIds,
      rustedLockerKey: state.items.rustedLockerKey,
      rodFound: state.qizhenLake.rodFound,
      decoyBaitAttached: state.qizhenLake.decoyBaitAttached
    };
  };

  assertFactsEqual(
    runQizhenLockerKey(true),
    runQizhenLockerKey(false),
    "Qizhen key pre-save facts must be order-independent"
  );

  {
    const { store, controller } = createHarness(
      createInitialGameState,
      createGameStore,
      EventBus,
      ChapterThreeCanteenController,
      (state) => {
        state.canteenHunt = {
          ...state.canteenHunt,
          active: true,
          phase: "pickup_search",
          mode: "light",
          orderedMenuOption: "D",
          pickupDarkClueRead: false
        };
        state.items.pickupTicket0755 = true;
      }
    );
    assert(controller.selectPickupWindow("3") === "correct", "canteen light-first D pickup must succeed without a dark clue");
    assert(store.getState().canteenHunt.phase === "exit_blocking", "canteen D pickup must advance to exit blocking");
    assert(!store.getState().items.pickupTicket0755, "canteen accepted ticket must be consumed");
  }

  {
    const { store, controller } = createHarness(
      createInitialGameState,
      createGameStore,
      EventBus,
      ChapterThreeCanteenController,
      (state) => {
        state.canteenHunt = {
          ...state.canteenHunt,
          active: true,
          phase: "pickup_search",
          mode: "dark",
          orderedMenuOption: "D"
        };
        state.items.pickupTicket0755 = true;
      }
    );
    assert(controller.selectPickupWindow("3") === "locked", "canteen physical pickup must still reject dark observation");
    assert(store.getState().items.pickupTicket0755, "canteen wrong-mode pickup must retain the ticket");
    assert(controller.inspectPickupWindow("3"), "canteen dark-first observation must remain available");
    assert(controller.setMode("light"), "canteen player must be able to switch to light manually");
    assert(controller.selectPickupWindow("3") === "correct", "canteen dark-first then light operation must succeed");
  }

  {
    const { store, controller } = createHarness(
      createInitialGameState,
      createGameStore,
      EventBus,
      ChapterThreeCanteenController,
      (state) => {
        state.canteenHunt = {
          ...state.canteenHunt,
          active: true,
          phase: "exit_blocking",
          mode: "light",
          identifiedExitIds: []
        };
      }
    );
    CANTEEN_EXIT_SEQUENCE.forEach((exitId, index) => {
      const result = controller.blockExit(exitId);
      assert(result === (index === CANTEEN_EXIT_SEQUENCE.length - 1 ? "complete" : "correct"), `canteen cart ${exitId} must be pushable before observation`);
    });
    assert(store.getState().canteenHunt.phase === "chase_ready", "canteen direct cart sequence must complete");
  }

  {
    const { store, controller } = createHarness(
      createInitialGameState,
      createGameStore,
      EventBus,
      ChapterThreeCanteenController,
      (state) => {
        state.canteenHunt = {
          ...state.canteenHunt,
          active: true,
          phase: "chase_ready",
          mode: "light",
          bikeCodeRead: false
        };
        state.items.greaseTissue = true;
        state.items.cafeteriaWages = true;
        state.wallet.cashCents = 200;
      }
    );
    assert(controller.cleanBikeLock() === "cleaned", "canteen bike lock cleaning must not require bikeCodeRead");
    assert(controller.payForBike() === "paid", "canteen bike payment must not require bikeCodeRead");
    assert(store.getState().wallet.cashCents === 0 && store.getState().canteenHunt.bikePaid, "canteen bike payment must still settle exactly once");
  }

  {
    const { store, controller } = createHarness(
      createInitialGameState,
      createGameStore,
      EventBus,
      ChapterThreeCanteenController,
      (state) => {
        state.canteenHunt = { ...state.canteenHunt, active: true, phase: "tray_search", mode: "dark" };
      }
    );
    assert(controller.enterCanteen(), "canteen re-entry must remain valid");
    assert(store.getState().canteenHunt.mode === "dark", "canteen entry must preserve the selected mode");
    store.setState((state) => ({
      ...state,
      canteenHunt: { ...state.canteenHunt, phase: "exit_blocking", mode: "dark" }
    }));
    assert(controller.prepareDefenseLightMode(), "legacy defense preparation event must remain accepted");
    assert(store.getState().canteenHunt.mode === "dark", "legacy defense preparation must not force light mode");
    assert(controller.completeDefense(), "canteen defense completion must remain accepted");
    assert(store.getState().canteenHunt.mode === "dark", "canteen defense completion must preserve the selected mode");
  }

  {
    const { store, controller } = createHarness(
      createInitialGameState,
      createGameStore,
      EventBus,
      ChapterThreeTheaterController,
      (state) => {
        state.canteenHunt.phase = "theater_reached";
        state.theaterHunt = { ...state.theaterHunt, active: false, mode: "dark" };
      }
    );
    assert(controller.enterTheater(), "theater entry must remain valid");
    assert(store.getState().theaterHunt.mode === "dark", "theater entry must preserve the selected mode");
  }

  {
    const { controller } = createHarness(
      createInitialGameState,
      createGameStore,
      EventBus,
      ChapterThreeTheaterController,
      (state) => {
        state.networkMode = "cellular";
        state.theaterHunt = {
          ...state.theaterHunt,
          active: true,
          phase: "entry_ticket",
          mode: "light",
          ticketCodeRead: false,
          cc98TicketCommissionPhase: "accepted"
        };
      }
    );
    assert(controller.attemptCc98TicketRelease() === "won_first_wave", "theater phone ticket release must not require prior dark observation");
  }

  {
    const { store, controller } = createHarness(
      createInitialGameState,
      createGameStore,
      EventBus,
      ChapterThreeTheaterController,
      (state) => {
        state.theaterHunt = {
          ...state.theaterHunt,
          active: true,
          phase: "prop_setup",
          mode: "light",
          managerHintRead: false
        };
        state.items.temporaryTheaterTicket = true;
      }
    );
    assert(controller.openPropBoxWithTicket(), "theater prop scanner must accept a valid ticket without managerHintRead");
    assert(store.getState().theaterHunt.propBoxOpened, "theater prop box must open after valid light operation");
  }

  {
    const { store, controller } = createHarness(
      createInitialGameState,
      createGameStore,
      EventBus,
      ChapterThreeTheaterController,
      (state) => {
        state.theaterHunt = {
          ...state.theaterHunt,
          active: true,
          phase: "prop_setup",
          mode: "dark",
          managerHintRead: false
        };
        state.items.temporaryTheaterTicket = true;
      }
    );
    assert(!controller.openPropBoxWithTicket(), "theater physical scanner must still reject dark observation");
    assert(controller.inspectPropBox() === "ghost", "theater optional dark prop observation must remain available");
    assert(controller.setMode("light"), "theater player must be able to switch to light manually");
    assert(controller.openPropBoxWithTicket(), "theater dark-first then light ticket operation must succeed");
    assert(!store.getState().items.temporaryTheaterTicket, "theater prop ticket must still be consumed exactly once");
  }

  {
    const { store, controller } = createHarness(
      createInitialGameState,
      createGameStore,
      EventBus,
      ChapterThreeTheaterController,
      (state) => {
        state.theaterHunt = {
          ...state.theaterHunt,
          active: true,
          phase: "spotlight_ready",
          mode: "dark",
          paperDusted: true
        };
        state.items.spotlightRemote = true;
      }
    );
    assert(controller.startSpotlightHunt(), "theater spotlight must start without forcing an observation order");
    assert(store.getState().theaterHunt.mode === "dark", "theater spotlight start must preserve dark mode");
    assert(controller.setMode("light"), "theater player must switch to light before physical spotlight operation");
    const firstRound = THEATER_SPOTLIGHT_ROUNDS[0];
    const firstRequired = getRequiredTheaterSpotlightLockMs(firstRound, 0);
    assert(controller.resolveSpotlightAttempt({
      round: firstRound.round,
      lane: firstRound.lane,
      maxContinuousLockMs: firstRequired,
      beamActivated: true,
      firstBeamAtMs: firstRound.actionMs * 0.25,
      actionMs: firstRound.actionMs,
      submittedAtMs: firstRound.actionMs * 0.75
    }), "theater valid spotlight operation must succeed in light mode");
    assert(store.getState().theaterHunt.mode === "light", "theater spotlight success must not force dark mode for the next round");
    const secondRound = THEATER_SPOTLIGHT_ROUNDS[1];
    const secondRequired = getRequiredTheaterSpotlightLockMs(secondRound, 0);
    assert(!controller.resolveSpotlightAttempt({
      round: secondRound.round,
      lane: "left",
      maxContinuousLockMs: secondRequired,
      beamActivated: true,
      firstBeamAtMs: secondRound.actionMs * 0.25,
      actionMs: secondRound.actionMs,
      submittedAtMs: secondRound.actionMs * 0.75
    }), "theater invalid spotlight operation must still fail");
    assert(store.getState().theaterHunt.mode === "light", "theater spotlight failure must not force dark mode");
  }

  {
    const { store, controller } = createHarness(
      createInitialGameState,
      createGameStore,
      EventBus,
      ChapterThreeTheaterController,
      (state) => {
        state.theaterHunt = { ...state.theaterHunt, active: true, phase: "reversal", mode: "dark", spotlightRound: 3 };
        state.qizhenLake = { ...state.qizhenLake, mode: "dark" };
      }
    );
    assert(controller.completeReversal(), "theater reversal must complete after three spotlight rounds");
    assert(store.getState().theaterHunt.mode === "dark", "theater completion must preserve theater mode");
    assert(store.getState().qizhenLake.mode === "dark", "theater completion must not overwrite lake mode");
  }

  {
    const { store, controller } = createHarness(
      createInitialGameState,
      createGameStore,
      EventBus,
      ChapterThreeQizhenLakeController,
      (state) => {
        state.qizhenLake = { ...state.qizhenLake, active: true, phase: "lake_unlocked", mode: "dark", zone: "dock" };
      }
    );
    assert(controller.enterLake(), "Qizhen lake entry must remain valid");
    assert(store.getState().qizhenLake.mode === "dark", "Qizhen lake entry must preserve the selected mode");
    store.setState((state) => ({
      ...state,
      qizhenLake: {
        ...state.qizhenLake,
        phase: "tool_chain",
        mode: "dark",
        vehicle: "kayak",
        boardingTutorialCompleted: true
      }
    }));
    assert(controller.enterZone("dock") === "accepted", "Qizhen dock return must remain valid");
    assert(store.getState().qizhenLake.mode === "dark", "Qizhen dock return must not force light mode");
  }

  {
    const { store, controller } = createHarness(
      createInitialGameState,
      createGameStore,
      EventBus,
      ChapterThreeQizhenLakeController,
      (state) => {
        state.qizhenLake = {
          ...state.qizhenLake,
          active: true,
          phase: "tool_chain",
          mode: "light",
          zone: "open_water",
          reflectionLocationObserved: false
        };
      }
    );
    assert(controller.findFishingRod() === "accepted", "Qizhen fishing rod must be collectible without prior observation");
    assert(store.getState().items.fishingRod, "Qizhen fishing rod collection must grant the item");
  }

  {
    const { store, events, controller } = createHarness(
      createInitialGameState,
      createGameStore,
      EventBus,
      ChapterThreeQizhenLakeController,
      (state) => {
        state.qizhenLake = {
          ...state.qizhenLake,
          active: true,
          phase: "tool_chain",
          mode: "light",
          zone: "open_water",
          vehicle: "kayak",
          boardingTutorialCompleted: true,
          rodFound: true,
          decoyBaitAttached: true,
          observedFishingSpotIds: []
        };
        state.items.fishingRod = true;
      }
    );
    const beforePrecheck = snapshot(store, events);
    assert(controller.precheckCast("locker_key") === "accepted", "Qizhen correct cast must not require an observed coordinate");
    assert(snapshot(store, events) === beforePrecheck, "Qizhen accepted cast precheck must remain read-only");
    assert(controller.castAt("locker_key") === "accepted", "Qizhen light-first key catch must succeed");
    assert(store.getState().items.rustedLockerKey, "Qizhen key catch must grant the key");
  }

  {
    const { store, events, controller } = createHarness(
      createInitialGameState,
      createGameStore,
      EventBus,
      ChapterThreeQizhenLakeController,
      (state) => {
        state.qizhenLake = {
          ...state.qizhenLake,
          active: true,
          phase: "tool_chain",
          mode: "light",
          zone: "open_water",
          vehicle: "kayak",
          boardingTutorialCompleted: true,
          rodFound: true,
          decoyBaitAttached: true
        };
        state.items.fishingRod = true;
      }
    );
    const beforeWrongTarget = snapshot(store, events);
    assert(controller.precheckCast("fish") === "wrong_item", "Qizhen wrong fishing target must be rejected before rhythm starts");
    assert(snapshot(store, events) === beforeWrongTarget, "Qizhen wrong fishing target must not mutate state or emit events");
  }

  {
    const { store, controller } = createHarness(
      createInitialGameState,
      createGameStore,
      EventBus,
      ChapterThreeQizhenLakeController,
      (state) => {
        state.qizhenLake = {
          ...state.qizhenLake,
          active: true,
          phase: "paper_capture",
          mode: "light",
          zone: "swan_cove",
          vehicle: "kayak",
          boardingTutorialCompleted: true,
          swanFed: true,
          magneticRodCombined: true,
          observedFishingSpotIds: []
        };
        state.items.magneticFishingRod = true;
      }
    );
    assert(controller.precheckCast("paper") === "accepted", "Qizhen final paper precheck must not require an observed coordinate");
    assert(controller.castAt("paper") === "accepted", "Qizhen final paper capture must succeed without prior observation");
    assert(store.getState().qizhenLake.phase === "swan_chase", "Qizhen paper capture must still enter the chase");
  }

  {
    const { store, events, controller } = createHarness(
      createInitialGameState,
      createGameStore,
      EventBus,
      ChapterThreeQizhenLakeController,
      (state) => {
        state.qizhenLake = {
          ...state.qizhenLake,
          active: true,
          phase: "tool_chain",
          mode: "dark",
          zone: "open_water",
          vehicle: "kayak",
          boardingTutorialCompleted: true,
          rodFound: true,
          decoyBaitAttached: true
        };
        state.items.fishingRod = true;
      }
    );
    const beforeWrongMode = snapshot(store, events);
    assert(controller.precheckCast("locker_key") === "wrong_mode", "Qizhen dark observation must still reject physical casting");
    assert(snapshot(store, events) === beforeWrongMode, "Qizhen wrong-mode cast must retain all state and items");
    assert(controller.observeReflection("qizhen_item_1_reflection") === "accepted", "Qizhen dark-first observation must remain available");
    assert(controller.setMode("light") === true, "Qizhen player must switch to light manually");
    assert(controller.castAt("locker_key") === "accepted", "Qizhen dark-first then light cast must succeed");
  }

  {
    const { store, controller } = createHarness(
      createInitialGameState,
      createGameStore,
      EventBus,
      ChapterThreeQizhenLakeController,
      (state) => {
        state.qizhenLake = {
          ...state.qizhenLake,
          active: true,
          phase: "swan_chase",
          mode: "dark",
          zone: "channel",
          vehicle: "kayak"
        };
      }
    );
    assert(controller.recordChaseFailure("validator") === "accepted", "Qizhen chase failure must remain recoverable");
    assert(store.getState().qizhenLake.mode === "dark", "Qizhen chase failure must preserve the selected mode");
  }

  const [
    canteenScene,
    theaterScene,
    qizhenScene,
    ticketCommission,
    rpgHost,
    questModel,
    itemInspectDialog,
    interactionContract
  ] = await Promise.all([
    readFile(path.join(root, "src/scenes/rpg/CanteenInteriorScene.ts"), "utf8"),
    readFile(path.join(root, "src/scenes/rpg/TheaterInteriorScene.ts"), "utf8"),
    readFile(path.join(root, "src/scenes/rpg/QizhenLakeScene.ts"), "utf8"),
    readFile(path.join(root, "src/scenes/phone/P02_CC98/TheaterTicketCommission.tsx"), "utf8"),
    readFile(path.join(root, "src/scenes/rpg/RpgGameHost.tsx"), "utf8"),
    readFile(path.join(root, "src/core/QuestModel.ts"), "utf8"),
    readFile(path.join(root, "src/components/ItemInspectDialog.tsx"), "utf8"),
    readFile(path.join(root, "src/scenes/rpg/RpgInteractionContract.ts"), "utf8")
  ]);
  const canteenPullBack = canteenScene.slice(
    canteenScene.indexOf("const pullBackToEmptyCanteen"),
    canteenScene.indexOf("const showPaperPackage", canteenScene.indexOf("const pullBackToEmptyCanteen"))
  );
  assert(!canteenPullBack.includes("rpg_canteen_final_light_mode_requested") && !canteenPullBack.includes('currentMode = "light"'), "canteen pickup cutscene must not force light mode");
  const theaterPrepare = theaterScene.slice(
    theaterScene.indexOf("private prepareSpotlightAction"),
    theaterScene.indexOf("private startSpotlightTracking")
  );
  assert(!theaterPrepare.includes("rpg_theater_mode_requested"), "theater spotlight preparation must not force light mode");
  assert(!ticketCommission.includes("disabled={!ticketCodeRead}"), "theater phone release button must not be disabled by ticketCodeRead");
  const canteenTargets = canteenScene.slice(
    canteenScene.indexOf("private getActiveTargets"),
    canteenScene.indexOf("private canLeaveThroughDoor")
  );
  assert(canteenTargets.includes('state.canteenHunt.phase === "pickup_search"') && canteenTargets.includes("!state.canteenHunt.menuDarkClueRead"), "canteen ordered menu must remain observable after light operation");
  const theaterPropTrigger = theaterScene.slice(
    theaterScene.indexOf('if (target.kind === "prop")'),
    theaterScene.indexOf('if (target.kind === "scanner")')
  );
  assert(theaterPropTrigger.indexOf('state.theaterHunt.mode === "dark"') < theaterPropTrigger.indexOf("state.theaterHunt.propBoxOpened"), "theater opened prop box must route dark observation before opened-state feedback");
  assert(rpgHost.includes('"spotlight_ready", "spotlight_hunt"'), "theater touch mode toggle must remain available during spotlight hunt");
  assert(rpgHost.includes('"dock_outfitting", "boarding_tutorial", "lake_exploration"'), "Qizhen touch mode toggle must cover outfitting and boarding phases");
  assert(!rpgHost.includes('events.emit("rpg_canteen_toggle_mode")'), "canteen touch mode toggle must not be swallowed by the defense runtime");
  assert(rpgHost.includes('events.emit("rpg_canteen_mode_requested"'), "canteen touch mode toggle must submit the controller-owned mode request directly");
  for (const staleText of [
    "先在深色模式读取二维码",
    "先读取二维码并清洁车锁",
    "先在深色模式读取管理员提示"
  ]) {
    assert(!rpgHost.includes(staleText), `RPG host must remove stale fixed-order guidance: ${staleText}`);
  }
  for (const staleText of ["切回浅色操作，在点餐机", "保持深色观察", "先与 3 号窗口", "切回浅色操作后推动"] ) {
    assert(!questModel.includes(staleText), `quest model must remove stale fixed-order guidance: ${staleText}`);
  }
  assert(!itemInspectDialog.includes("先在深色观察中记录目标"), "fishing rod item copy must describe both modes without imposing an order");
  assert(interactionContract.includes("不表示另一模式的事实必须先写入"), "shared interaction contract must state that requiredMode does not establish precedence");
  assert(!qizhenScene.includes("dock_restore"), "Qizhen dock restoration must not force light mode");
  assert(!qizhenScene.includes("runtime.reflectionLocationObserved && !runtime.rodFound"), "Qizhen fishing rod target must not be hidden by observation state");
  for (const spotId of ["locker_key", "net_frame", "fish", "paper"]) {
    assert(!qizhenScene.includes(`&& runtime.observedFishingSpotIds.includes("${spotId}")`), `Qizhen ${spotId} target must not be hidden by observation state`);
  }
  const precheckedBranch = qizhenScene.slice(
    qizhenScene.indexOf('if (name === "qizhen_fishing_prechecked")'),
    qizhenScene.indexOf('if (name === "qizhen_fishing_precheck_failed")')
  );
  const rejectedBranch = qizhenScene.slice(
    qizhenScene.indexOf('if (name === "qizhen_fishing_precheck_failed")'),
    qizhenScene.indexOf('if (name === "qizhen_fishing_session_result")')
  );
  assert(precheckedBranch.includes("beginFishingSession"), "Qizhen rhythm must begin only after an accepted precheck");
  assert(!rejectedBranch.includes("beginFishingSession") && rejectedBranch.includes("cancelFishingSession"), "Qizhen rejected precheck must cancel without opening a rhythm session");

  console.log(`RPG reality-mode order validation PASS assertions=${assertionCount}`);
} finally {
  await rm(tempDir, { recursive: true, force: true });
}
