import assert from "node:assert/strict";
import { createServer } from "vite";

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
  const initial = createInitialGameState();
  const store = createGameStore({
    ...initial,
    items: { ...initial.items, fishingRod: true, smallCarp: true },
    qizhenLake: {
      ...initial.qizhenLake,
      active: true,
      phase: "swan_exchange",
      mode: "light",
      zone: "swan_cove",
      netCombined: true,
      fishCaught: true
    }
  });
  const events = new EventBus();
  const emitted = [];
  events.subscribe((event) => emitted.push(event));
  const controller = new ChapterThreeQizhenLakeController(store, events);
  assert.equal(controller.feedSwan("smallCarp"), "accepted");
  const state = store.getState();
  assert.equal(state.items.smallCarp, false, "feeding must consume the carp");
  assert.equal(state.items.fishingRod, true, "feeding must preserve the plain rod for final assembly");
  assert.equal(state.items.swanMagnet, true, "feeding must grant the magnet as an independent material");
  assert.equal(state.items.magneticFishingRod, false, "feeding alone must not grant the assembled magnetic rod");
  assert.equal(state.qizhenLake.magneticRodCombined, false, "feeding alone must not mark final assembly");
  assert.equal(state.qizhenLake.phase, "tool_chain", "feeding must leave the independent tool branches open");
  assert(!emitted.some((event) => event.name === "qizhen_final_rig_combined"), "feeding must not publish final assembly");
  console.log("Qizhen swan independent-material PASS: plain rod preserved until final assembly");
} finally {
  await server.close();
}
