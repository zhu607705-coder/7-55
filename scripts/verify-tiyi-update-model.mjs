import assert from "node:assert/strict";
import { build } from "esbuild";
import { mkdtemp, rm } from "node:fs/promises";
import { tmpdir } from "node:os";
import path from "node:path";
import { fileURLToPath, pathToFileURL } from "node:url";

// Retained-source controller and save contracts. These are not browser/UI acceptance.
const root = path.resolve(path.dirname(fileURLToPath(import.meta.url)), "..");
const output = await mkdtemp(path.join(tmpdir(), "tiyi-update-model-"));
let checks = 0;
function equal(actual, expected, label) { checks++; assert.deepEqual(actual, expected, label); }
function storage() {
  const values = new Map();
  return { getItem: key => values.get(key) ?? null, setItem: (key, value) => values.set(key, value), removeItem: key => values.delete(key) };
}
try {
  const bundle = path.join(output, "contract.mjs");
  await build({
    stdin: { resolveDir: root, contents: [
      'export * from "./src/modules/TiyiAccessModel.ts";',
      'export { NetworkController } from "./src/modules/NetworkController.ts";',
      'export { ActOneBootstrapController } from "./src/modules/ActOneBootstrapController.ts";',
      'export { LibraryFinalsController } from "./src/modules/LibraryFinalsController.ts";',
      'export { PlantController } from "./src/modules/PlantController.ts";',
      'export { createInitialGameState, createGameStore } from "./src/core/GameState.ts";',
      'export { SaveStore } from "./src/core/SaveStore.ts";',
      'export { GAME_SAVE_KEY } from "./src/core/StorageKeys.ts";',
      'export { EventBus } from "./src/core/EventBus.ts";'
    ].join("\n") }, outfile: bundle, bundle: true, platform: "node", format: "esm", target: "node20"
  });
  const m = await import(pathToFileURL(bundle).href);
  const earlyPhases = ["prologue", "friend_message_required", "system_required", "inventory_required", "system_return_required"];
  const laterPhases = ["movement_required", "reservation_briefing_required", "reservation_required", "movement_ready", "identity_required", "phone_link_required", "controls_required", "item_required", "map_required", "chapter_two_ready", "complete"];
  const stages = ["not_started", "official_entry_found", "package_ready", "installed", "legacy_ready"];
  function context(phase = "movement_required") {
    const state = m.createInitialGameState();
    state.actOne.phase = phase;
    state.actOne.characterNamed = true;
    state.networkMode = "cellular";
    const store = m.createGameStore(state), events = new m.EventBus();
    return { store, events, act: new m.ActOneBootstrapController(store, events), network: new m.NetworkController(store, events), library: new m.LibraryFinalsController(store, events) };
  }
  function load(state, version = 36) {
    const disk = storage();
    disk.setItem(m.GAME_SAVE_KEY, JSON.stringify(version === null ? state : { version, state }));
    return new m.SaveStore(disk).load(m.createInitialGameState());
  }
  for (const phase of [...earlyPhases, ...laterPhases]) for (const stage of stages) for (const mode of ["campus_wifi", "cellular", "offline"]) {
    const state = m.createInitialGameState();
    state.actOne.phase = phase; state.actOne.tiyiUpdateStage = stage; state.networkMode = mode;
    const later = laterPhases.includes(phase), installed = ["installed", "legacy_ready"].includes(stage);
    equal(m.tiyiUpdateRequired(state), later, "only movement and later phases require the new client");
    equal(m.tiyiUpdateInstalled(state), installed, "only installed or explicit legacy receipt counts");
    equal(m.canAccessTiyi(state), mode === "cellular" && (!later || installed), "first and second access gates stay distinct");
  }
  for (const phase of earlyPhases) {
    const c = context(phase), before = c.store.getState();
    equal(c.network.canOpenTiyi(), true, "first encounter still accepts mobile data");
    for (const intent of ["discoverTiyiUpdate", "acquireTiyiUpdate", "installTiyiUpdate"]) equal(c.act[intent](), false, "early phase cannot pre-earn the later update");
    equal(c.store.getState() === before, true, "rejected early update has no state writes");
    equal(c.events.getHistory(), [], "rejected early update emits no completion");
  }
  for (const phase of ["movement_required", "complete"]) {
    const c = context(phase), start = c.store.getState();
    for (let repeat = 0; repeat < 3; repeat++) for (const mode of ["campus_wifi", "cellular", "offline"]) {
      c.network.setMode(mode);
      equal(c.network.canOpenTiyi(), false, "repeated network switches never unlock the second encounter");
      equal(c.store.getState().actOne.tiyiUpdateStage, "not_started", "network cannot award installation");
    }
    equal(c.act.acquireTiyiUpdate(), false, "cannot acquire without the official entry");
    equal(c.act.installTiyiUpdate(), false, "cannot install without an acquired package");
    equal(c.act.startExercise(), false, "direct exercise intent cannot bypass the update");
    equal(c.act.discoverTiyiUpdate(), true, "contact-us entry is controller-owned");
    equal(c.act.discoverTiyiUpdate(), true, "rediscover is idempotent");
    equal(c.store.getState().actOne.tiyiUpdateStage, "official_entry_found", "discovery does not install");
    equal(c.act.installTiyiUpdate(), false, "discovery alone cannot install");
    equal(c.act.acquireTiyiUpdate(), false, "offline acquisition is rejected");
    c.network.setMode("campus_wifi");
    equal(c.act.acquireTiyiUpdate(), true, "Wi-Fi can transfer the simulated package");
    equal(c.act.acquireTiyiUpdate(), true, "reacquire is idempotent");
    equal(c.store.getState().actOne.tiyiUpdateStage, "package_ready", "download is not installation");
    equal(load(c.store.getState()).actOne.tiyiUpdateStage, "package_ready", "reload after leaving at download does not auto-install");
    equal(c.act.startExercise(), false, "package without installation cannot start exercise");
    c.network.setMode("offline");
    equal(c.act.installTiyiUpdate(), true, "already acquired package can be explicitly installed offline");
    equal(c.act.installTiyiUpdate(), true, "reinstall completion is idempotent");
    equal(c.store.getState().actOne.exerciseStarted, false, "install does not complete exercise");
    equal(c.store.getState().items, start.items, "install does not grant rain, plant water or other inventory");
    equal(c.store.getState().flags, start.flags, "install does not mutate C1 puzzle facts");
    equal(c.network.canOpenTiyi(), false, "offline access remains blocked after installation");
    c.network.setMode("cellular");
    equal(c.network.canOpenTiyi(), true, "updated client retains cellular access requirement");
    for (const event of ["tiyi_update_official_entry_found", "tiyi_update_package_acquired", "tiyi_update_installed"]) {
      equal(c.events.getHistory().filter(entry => entry.name === event).length, 1, "each earned update fact emits once");
    }
    if (phase === "movement_required") {
      equal(c.act.collectWeatherWater(), false, "installed client alone grants no C2 rain drop");
      equal(c.act.startExercise(), true, "exercise controller accepts installed client and identity");
      equal(c.act.startExercise(), true, "exercise completion remains idempotent");
      equal(c.events.getHistory().filter(entry => entry.name === "act2_exercise_started").length, 1, "exercise emits once");
      equal(c.act.collectWeatherWater(), true, "C2 rain is available after actual exercise completion intent");
    }
  }
  for (const stage of stages) for (const mode of ["cellular", "campus_wifi", "offline"]) {
    const c = context("complete");
    c.store.setState(state => ({ ...state, networkMode: mode, actOne: { ...state.actOne, tiyiUpdateStage: stage }, ui: { ...state.ui, libraryFinalsPhase: "evidence_gathering", libraryFinalsPuzzle: { ...state.ui.libraryFinalsPuzzle, investigationOpened: true, entranceRecordRead: true, archivedRuleRead: true } } }));
    const allowed = mode === "cellular" && ["installed", "legacy_ready"].includes(stage);
    equal(c.library.setAuditValue("arrivalMinutes", 7), allowed, "direct library edit obeys the same access gate");
    equal(c.library.submitAudit({ arrivalMinutes: 7, publicNoticeFloor: 47, proofCount: 3 }), allowed, "direct library submission cannot bypass update or transport");
    equal(c.store.getState().ui.libraryFinalsPuzzle.presenceProofCollected, allowed, "presence proof requires the authority gate");
    equal(c.store.getState().items.libraryPresenceProof, allowed, "failed access cannot create proof inventory");
  }
  {
    const c = context("prologue");
    c.store.setState(state => ({ ...state, ui: { ...state.ui, libraryFinalsPhase: "evidence_gathering", libraryFinalsPuzzle: { ...state.ui.libraryFinalsPuzzle, investigationOpened: true, entranceRecordRead: true, archivedRuleRead: true } } }));
    equal(m.tiyiUpdateRequired(c.store.getState()), true, "later library domain requires updating even with an inconsistent early actOne phase");
    equal(c.library.setAuditValue("arrivalMinutes", 7), false, "contradictory early phase cannot bypass the library edit gate");
    equal(c.library.submitAudit({ arrivalMinutes: 7, publicNoticeFloor: 47, proofCount: 3 }), false, "contradictory early phase cannot issue presence proof");
    equal(c.act.discoverTiyiUpdate() && c.act.acquireTiyiUpdate() && c.act.installTiyiUpdate(), true, "old later-domain save can recover through the actual update intents");
    equal(c.library.submitAudit({ arrivalMinutes: 7, publicNoticeFloor: 47, proofCount: 3 }), true, "recovered later-domain save uses the same authoritative access rule");
  }
  {
    const c = context("prologue"), plant = new m.PlantController(c.store, c.events);
    c.store.setState(state => ({ ...state, networkMode: "offline", items: { ...state.items, wateredHeadphone: true, fertilizer: true }, ui: { ...state.ui, brightness: 80 } }));
    for (const step of ["water", "light", "fertilize"]) equal(plant.apply(step), "done", "C1 plant remains independent of Tiyi update and network");
    equal(plant.isBloomed(), true, "C1 plant still blooms without installing the later client");
    equal(c.store.getState().actOne.tiyiUpdateStage, "not_started", "plant does not grant installation");
  }
  for (const version of [null, 2, 6, 34, 35]) {
    for (const fact of [null, "exerciseStarted", "weatherWaterTaken"]) {
      const state = m.createInitialGameState();
      state.actOne.phase = "complete"; state.networkMode = "cellular";
      state.flags.tiyiCountTaken = true; state.flags.waterDropTaken = true; state.digits.d2 = "7";
      delete state.actOne.tiyiUpdateStage;
      if (fact) state.actOne[fact] = true;
      const restored = load(state, version);
      equal(restored.actOne.tiyiUpdateStage, fact ? "legacy_ready" : "not_started", "only earned C2 exercise/rain grandfather missing old fields");
      equal(restored.actOne.exerciseStarted, fact === "exerciseStarted", "migration does not fabricate exercise");
      equal(restored.actOne.weatherWaterTaken, fact === "weatherWaterTaken", "migration preserves the existing rain receipt");
      equal(restored.flags.tiyiCountTaken, true, "old C1 digit remains earned");
    }
    for (const stage of stages) {
      const state = m.createInitialGameState(); state.actOne.exerciseStarted = true; state.actOne.tiyiUpdateStage = stage;
      equal(load(state, version).actOne.tiyiUpdateStage, stage, "valid explicit stage is not overwritten by old earned evidence");
    }
  }
  for (const version of [null, 35, 36]) for (const invalid of [null, false, 0, {}, [], "", "INSTALLED", "downloaded"]) {
    const state = m.createInitialGameState(); state.actOne.tiyiUpdateStage = invalid;
    equal(load(state, version), null, "malformed present stage rejects the source save, never silently grants access");
  }
  {
    const state = m.createInitialGameState(); delete state.actOne.tiyiUpdateStage;
    equal(load(state, 36), null, "new-version save must carry its stage field");
    equal(load(m.createInitialGameState(), 37), null, "unknown future version remains rejected");
  }
  for (const stage of stages) {
    const state = m.createInitialGameState(); state.actOne.phase = "movement_required"; state.actOne.tiyiUpdateStage = stage;
    const disk = storage(), saves = new m.SaveStore(disk);
    equal(saves.save(state), true, "ordinary save accepts each legal stage");
    equal(JSON.parse(disk.getItem(m.GAME_SAVE_KEY)).version, 36, "new save carries version 36");
    equal(new m.SaveStore(disk).load(m.createInitialGameState()).actOne.tiyiUpdateStage, stage, "stage survives ordinary save/reload");
  }
  console.log(`Tiyi two-stage source model PASS: ${checks} checks; first-network puzzle, controller-owned update, exercise/library guards, independent C1 plant and strict old/new saves. Not browser or native gameplay acceptance.`);
} finally {
  await rm(output, { recursive: true, force: true });
}
