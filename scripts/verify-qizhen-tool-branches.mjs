import { createServer } from "vite";

const errors = [];
let assertionCount = 0;

function assert(condition, message) {
  assertionCount += 1;
  if (!condition) errors.push(message);
}

function snapshot(value) {
  return JSON.stringify(value);
}

function permutations(values) {
  if (values.length <= 1) return [values];
  return values.flatMap((value, index) => (
    permutations(values.filter((_, candidateIndex) => candidateIndex !== index))
      .map((tail) => [value, ...tail])
  ));
}

const server = await createServer({
  configFile: false,
  appType: "custom",
  logLevel: "error",
  optimizeDeps: { noDiscovery: true, include: [] },
  server: { middlewareMode: true, ws: false }
});

try {
  const [gameStateModule, eventBusModule, controllerModule] = await Promise.all([
    server.ssrLoadModule("/src/core/GameState.ts"),
    server.ssrLoadModule("/src/core/EventBus.ts"),
    server.ssrLoadModule("/src/modules/ChapterThreeQizhenLakeController.ts")
  ]);
  const { createGameStore, createInitialGameState } = gameStateModule;
  const { EventBus } = eventBusModule;
  const { ChapterThreeQizhenLakeController } = controllerModule;

  function createFixture() {
    const initial = createInitialGameState();
    const store = createGameStore({
      ...initial,
      items: {
        ...initial.items,
        fishingRod: true
      },
      qizhenLake: {
        ...initial.qizhenLake,
        active: true,
        phase: "tool_chain",
        mode: "light",
        zone: "open_water",
        vehicle: "kayak",
        rodFound: true,
        decoyBaitAttached: true,
        boardingTutorialCompleted: true
      }
    });
    return {
      store,
      controller: new ChapterThreeQizhenLakeController(store, new EventBus())
    };
  }

  const branches = {
    locker: ({ store, controller }) => {
      store.setState((state) => ({
        ...state,
        qizhenLake: { ...state.qizhenLake, zone: "dock" }
      }));
      assert(controller.castAt("locker_key") === "accepted", "locker branch must catch the key");
      assert(controller.useItemAt("qizhen_use_item_1", "rustedLockerKey") === "accepted", "locker branch must open the locker");
      const state = store.getState();
      assert(state.items.nylonCord && state.qizhenLake.lockerOpened, "locker branch must grant nylon cord");
    },
    raft: ({ store, controller }) => {
      store.setState((state) => ({
        ...state,
        qizhenLake: { ...state.qizhenLake, zone: "channel" }
      }));
      assert(controller.castAt("net_frame") === "accepted", "raft branch must catch the broken net frame");
      assert(store.getState().items.brokenNetFrame, "raft branch must grant the broken net frame");
    },
    swan: ({ store, controller }) => {
      store.setState((state) => ({
        ...state,
        qizhenLake: { ...state.qizhenLake, zone: "swan_cove" }
      }));
      assert(controller.completeSwanBranch() === "accepted", "swan branch must resolve from the cove");
      assert(store.getState().items.swanMagnet, "swan branch must grant the magnet");
    }
  };

  for (const order of permutations(Object.keys(branches))) {
    const fixture = createFixture();
    for (const branchId of order) {
      const before = snapshot(fixture.store.getState());
      branches[branchId](fixture);
      assert(snapshot(fixture.store.getState()) !== before, `${order.join("→")} ${branchId} must commit state`);
      assert(fixture.store.getState().qizhenLake.phase === "tool_chain", `${order.join("→")} must stay in tool_chain until assembly`);
    }
    const beforeWrongAssembly = snapshot(fixture.store.getState());
    assert(
      fixture.controller.combineItems(["nylonCord", "brokenNetFrame", "fishingRod"]) === "wrong_item",
      `${order.join("→")} incomplete assembly must reject`
    );
    assert(snapshot(fixture.store.getState()) === beforeWrongAssembly, `${order.join("→")} incomplete assembly must be zero-write`);
    assert(
      fixture.controller.combineItems(["swanMagnet", "fishingRod", "brokenNetFrame", "nylonCord"]) === "accepted",
      `${order.join("→")} complete assembly must accept regardless of item order`
    );
    const completed = fixture.store.getState();
    assert(completed.qizhenLake.phase === "paper_capture", `${order.join("→")} must advance to paper_capture`);
    assert(completed.qizhenLake.magneticRodCombined && completed.items.magneticFishingRod, `${order.join("→")} must grant the final rig`);
    assert(
      !completed.items.nylonCord && !completed.items.brokenNetFrame && !completed.items.swanMagnet && !completed.items.fishingRod,
      `${order.join("→")} must consume all four components`
    );
  }

  if (errors.length > 0) {
    console.error(`Qizhen tool-branch validation failed (${errors.length}/${assertionCount})`);
    errors.forEach((error) => console.error(`- ${error}`));
    process.exitCode = 1;
  } else {
    console.log(`Qizhen tool-branch validation PASS permutations=6 assertions=${assertionCount}`);
  }
} finally {
  await server.close();
}
