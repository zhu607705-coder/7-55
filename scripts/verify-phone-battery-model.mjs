import assert from "node:assert/strict";
import { build } from "esbuild";
import { mkdtemp, readFile, rm } from "node:fs/promises";
import { tmpdir } from "node:os";
import path from "node:path";
import { fileURLToPath, pathToFileURL } from "node:url";

// Executed retained-source model/save contracts, not browser or native input.
const root = path.resolve(path.dirname(fileURLToPath(import.meta.url)), "..");
const output = await mkdtemp(path.join(tmpdir(), "phone-battery-model-"));
let checks = 0;
function equal(actual, expected, label) { checks++; assert.deepEqual(actual, expected, label); }
function storage() {
  const values = new Map();
  return { values, getItem: key => values.get(key) ?? null, setItem: (key, value) => values.set(key, value), removeItem: key => values.delete(key) };
}
try {
  const bundle = path.join(output, "contract.mjs");
  await build({
    stdin: { resolveDir: root, contents: [
      'export { PhoneBatteryController, getPhoneSceneBatteryCost } from "./src/modules/PhoneBatteryController.ts";',
      'export { PlantController } from "./src/modules/PlantController.ts";',
      'export { FlagController } from "./src/modules/FlagController.ts";',
      'export { NetworkController } from "./src/modules/NetworkController.ts";',
      'export { createInitialGameState, createGameStore } from "./src/core/GameState.ts";',
      'export { SceneRouter } from "./src/core/SceneRouter.ts";',
      'export { SaveStore } from "./src/core/SaveStore.ts";',
      'export { GAME_SAVE_KEY, GAME_SAVE_BACKUP_KEY } from "./src/core/StorageKeys.ts";',
      'export { EventBus } from "./src/core/EventBus.ts";'
    ].join("\n") }, outfile: bundle, bundle: true, platform: "node", format: "esm", target: "node20"
  });
  const m = await import(pathToFileURL(bundle).href);
  const initial = m.createInitialGameState();
  equal(initial.phoneBattery, { percent: 17 }, "new game retains initial battery without charging state");
  equal(initial.ui.brightness, 65, "new game relative brightness leaves the >=80 plant puzzle unsolved");
  equal("homeDeskReturnScene" in initial.ui, false, "new game has no retired charging route");
  equal(initial.flags.plantLit, false, "initial brightness does not itself grant a story fact");
  const scenes = ["alarm", "desktop", "phone_home", "settings", "wechat", "cc98", "zjuding", "tiyi", "weather", "photos", "timeline_recovery", "voice_memos", "campus_card", "checkin", "bonsai", "clock", "ending"];
  for (const percent of [0, 1, 17, 100]) {
    const seed = m.createInitialGameState();
    seed.phoneBattery = { percent };
    seed.ui.brightness = 37;
    seed.ui.musicPlaying = true;
    const store = m.createGameStore(seed), events = new m.EventBus();
    const battery = new m.PhoneBatteryController(store, events);
    const before = store.getState();
    for (const scene of scenes) {
      equal(m.getPhoneSceneBatteryCost(scene), 0, `${scene}: navigation remains free`);
      for (let repeat = 0; repeat < 3; repeat++) equal(battery.consumeForSceneOpen("phone_home", scene), percent, `${percent}% survives repeated app open`);
    }
    equal(store.getState() === before, true, "free app opens perform no state write");
    equal(events.getHistory(), [], "free app opens emit no battery warnings");
    const router = new m.SceneRouter(store, events, (from, to) => battery.consumeForSceneOpen(from, to));
    for (let repeat = 0; repeat < 3; repeat++) {
      for (const scene of ["phone_home", "wechat", "bonsai", "settings", "tiyi", "desktop"]) {
        equal(router.goTo(scene), true, "ordinary navigation remains accepted even at zero");
        router.back();
        equal(store.getState().phoneBattery, seed.phoneBattery, "app/home/reopen/back preserves battery");
      }
    }
    equal(store.getState().ui.brightness, 37, "navigation preserves chosen brightness");
    equal(store.getState().ui.musicPlaying, true, "navigation never suspends music at zero");
    equal(store.getState().flags, seed.flags, "navigation never bypasses puzzle flags");
    equal(store.getState().items, seed.items, "navigation never changes inventory");
    equal(typeof battery.rechargeAtStation, "undefined", "theater charging authority is removed");
    equal(typeof battery.beginHomeDeskCharging, "undefined", "desk charging authority is removed");
    equal(typeof battery.setLowPowerMode, "undefined", "low power authority is removed");
    for (let remaining = percent; remaining >= 0; remaining--) {
      const next = Math.max(0, remaining - 1);
      equal(battery.consumeForNetworkSwitch(), next, "consumption decreases to zero without reserve or recovery");
      equal(store.getState().ui.brightness, 37, "depletion cannot dim manually chosen brightness");
      equal(store.getState().ui.musicPlaying, true, "depletion cannot suspend music");
    }
    const atZero = store.getState();
    const historyLength = events.getHistory().length;
    for (let repeat = 0; repeat < 20; repeat++) equal(battery.consumeForNetworkSwitch(), 0, "repeated zero-percent actions stay usable");
    equal(store.getState() === atZero, true, "zero-percent consume has no redundant state write");
    equal(events.getHistory().length, historyLength, "zero-percent actions produce no charging or shutdown warnings");
    const network = new m.NetworkController(store, events);
    for (const mode of ["cellular", "campus_wifi", "cellular"]) {
      network.setMode(mode);
      equal(store.getState().networkMode, mode, "network still changes at zero without a recharge prerequisite");
    }
    equal(store.getState().flags, seed.flags, "depletion never grants plant or story flags");
  }

  for (const version of [34, 35, 36, null]) for (const percent of [0, 1, 17, 100]) for (const lowPowerMode of [false, true]) for (const brightness of [0, 20, 33, 37, 45, 80, 100]) {
    const seed = m.createInitialGameState();
    seed.currentScene = "bonsai";
    seed.phoneBattery = { percent, lowPowerMode, rechargeCount: 3 };
    seed.ui.brightness = brightness;
    seed.ui.homeDeskReturnScene = null;
    const disk = storage(), saves = new m.SaveStore(disk);
    disk.setItem(m.GAME_SAVE_KEY, JSON.stringify(version === null ? seed : { version, state: seed }));
    const imported = saves.load(m.createInitialGameState());
    equal(imported.phoneBattery, { percent }, "migration preserves battery and strips retired fields");
    equal(imported.ui.brightness, brightness, "ambiguous legacy/manual brightness is preserved, never blindly raised");
    equal("homeDeskReturnScene" in imported.ui, false, "migration drops retired desk routing state");
    equal(imported.flags, seed.flags, "legacy battery migration does not grant story facts");
    equal(saves.save(imported), true, "migrated battery can be saved");
    const reloaded = new m.SaveStore(disk).load(m.createInitialGameState());
    equal(reloaded.phoneBattery, { percent }, "second write/reload retains battery including zero");
    equal(reloaded.ui.brightness, brightness, "second reload preserves manual brightness");
  }

  for (const page of ["phone_home", "bonsai"]) {
    for (const version of [35, 36, null]) {
      const seed = m.createInitialGameState(), disk = storage();
      seed.currentScene = "desktop";
      seed.ui.homeDeskReturnScene = page;
      seed.phoneBattery = { percent: 0, lowPowerMode: true, rechargeCount: 1 };
      disk.setItem(m.GAME_SAVE_KEY, JSON.stringify(version === null ? seed : { version, state: seed }));
      const migrated = new m.SaveStore(disk).load(m.createInitialGameState());
      equal(migrated.currentScene, page, "old charging desk resumes its real phone page without wake replay");
      equal(migrated.phoneBattery.percent, 0, "old charging desk migration cannot recharge");
      equal("homeDeskReturnScene" in migrated.ui, false, "legacy route is retired after migration");
    }
    for (const patch of [{ runtimeMode: "rpg" }, { flags: { ...initial.flags, checkinDone: true } }, { actOne: { ...initial.actOne, phase: "friend_message_required" } }]) {
      const seed = { ...m.createInitialGameState(), ...patch }, disk = storage();
      seed.currentScene = "desktop";
      seed.ui.homeDeskReturnScene = page;
      disk.setItem(m.GAME_SAVE_KEY, JSON.stringify({ version: 36, state: seed }));
      equal(new m.SaveStore(disk).load(m.createInitialGameState()).currentScene, "desktop", "stale desk marker cannot redirect other runtime or chapter contexts");
    }
  }

  for (const invalid of [-1, 101, 1.5, "0", null, undefined, NaN, Infinity]) {
    const seed = m.createInitialGameState(), disk = storage();
    seed.phoneBattery.percent = invalid;
    disk.setItem(m.GAME_SAVE_KEY, JSON.stringify({ version: 36, state: seed }));
    equal(new m.SaveStore(disk).load(m.createInitialGameState()).phoneBattery.percent, 17, "invalid battery uses validated default");
  }
  for (const invalidPatch of [{ lowPowerMode: "true" }, { lowPowerMode: null }, { rechargeCount: -1 }, { rechargeCount: 1.5 }, { rechargeCount: "2" }, { rechargeCount: null }]) {
    const seed = m.createInitialGameState(), disk = storage();
    seed.phoneBattery = { percent: 9, ...invalidPatch };
    disk.setItem(m.GAME_SAVE_KEY, JSON.stringify({ version: 36, state: seed }));
    equal(new m.SaveStore(disk).load(m.createInitialGameState()), null, "malformed legacy state is not silently trusted");
  }
  {
    const disk = storage(), saves = new m.SaveStore(disk);
    const first = m.createInitialGameState(); first.phoneBattery.percent = 1;
    const second = m.createInitialGameState(); second.phoneBattery.percent = 0;
    equal(saves.save(first), true, "first snapshot writes"); equal(saves.save(second), true, "second snapshot writes");
    disk.setItem(m.GAME_SAVE_KEY, "broken-json");
    equal(saves.load(m.createInitialGameState()).phoneBattery.percent, 1, "validated backup still recovers without charging");
  }
  {
    const seed = m.createInitialGameState(); seed.phoneBattery.percent = 0;
    const store = m.createGameStore(seed), events = new m.EventBus(), plant = new m.PlantController(store, events);
    equal(plant.apply("light"), "missing_requirement", "normal starting brightness cannot bypass original light predicate");
    const flags = new m.FlagController(store, events);
    flags.setUi("brightness", 79);
    equal(plant.apply("light"), "missing_requirement", "79 stays below the unchanged plant threshold");
    flags.setUi("brightness", 80);
    equal(plant.apply("light"), "done", "manual80 satisfies the original light predicate");
    equal(store.getState().ui.brightnessUserAdjusted, true, "source manual setter records brightness intent");
    equal(plant.isBloomed(), false, "brightness alone never bypasses water and fertilizer gates");
    equal(plant.apply("water"), "missing_requirement", "water prerequisite remains at zero battery");
    equal(plant.apply("fertilize"), "missing_requirement", "fertilizer prerequisite remains at zero battery");
    store.setState(s => ({ ...s, items: { ...s.items, wateredHeadphone: true, fertilizer: true } }));
    equal(plant.apply("water"), "done", "original water step remains usable at zero battery");
    equal(plant.apply("fertilize"), "done", "original fertilizer step remains usable at zero battery");
    equal(plant.isBloomed(), true, "only all authored predicates complete the plant");
  }

  // Actual component markup, not browser input acceptance.
  {
    const legacy = (brightness = 100) => {
      const seed = m.createInitialGameState(); seed.ui.brightness = brightness;
      for (const key of ["brightnessRevision", "brightnessUserAdjusted", "brightnessLegacy100Repaired"]) delete seed.ui[key];
      return seed;
    };
    const read = seed => {
      const disk = storage(); disk.setItem(m.GAME_SAVE_KEY, JSON.stringify({ version: 36, state: seed }));
      return new m.SaveStore(disk).load(m.createInitialGameState());
    };
    const corrected = read(legacy());
    equal(corrected.ui.brightness, 65, "raw unmarked100 opening corrects before defaults erase absence");
    equal(corrected.ui.brightnessLegacy100Repaired, true, "source correction retains a durable receipt");
    equal(read(corrected).ui.brightness, 65, "source correction is stable on second load");
    for (const brightness of [0, 20, 33, 45, 50, 65, 79, 80, 99]) equal(read(legacy(brightness)).ui.brightness, brightness, "other legacy relative settings remain unchanged");
    for (const key of ["plantLit", "plantWatered", "plantFertilized", "flowerBloomed", "flowerEightTaken", "checkinDone"]) {
      const seed = legacy(); seed.flags[key] = true;
      equal(read(seed).ui.brightness, 100, "earned plant/checkin progress excludes source repair");
    }
    const historicalManual = legacy(); historicalManual.native = { log: [{ text: "屏幕亮度已调整。", time: "2026-11-04" }] };
    equal(read(historicalManual).ui.brightness, 100, "positive old manual log preserves100");
    const store = m.createGameStore(corrected); new m.FlagController(store, new m.EventBus()).setUi("brightness", 100);
    equal(read(store.getState()).ui.brightness, 100, "new manual100 survives source reload");
    equal(read(store.getState()).ui.brightnessUserAdjusted, true, "manual intent survives source normalization");
    const partial = legacy(); partial.ui.brightnessRevision = 1;
    equal(read(partial), null, "partial marker cannot bypass correction safely");
    for (const patch of [{ brightnessRevision: 2 }, { brightnessUserAdjusted: "true" }, { brightnessLegacy100Repaired: 1 }]) {
      const seed = m.createInitialGameState(); Object.assign(seed.ui, patch);
      equal(read(seed), null, "malformed brightness provenance rejects");
    }
  }

  const uiBundle = path.join(output, "battery-ui.cjs");
  await build({
    stdin: { resolveDir: root, contents: [
      'export { WakeScene } from "./src/scenes/phone/P01_Desktop/index.tsx";',
      'export { ControlCenter } from "./src/components/ControlCenter.tsx";',
      'export { StatusBar } from "./src/components/StatusBar.tsx";',
      'export { createElement } from "react";',
      'export { renderToStaticMarkup } from "react-dom/server";'
    ].join("\n") }, outfile: uiBundle, bundle: true, platform: "node", format: "cjs", target: "node20",
    loader: { ".png": "dataurl", ".css": "empty" },
    plugins: [{ name: "isolated-battery-ui", setup(build) {
      build.onResolve({ filter: /\/modules\/(GameKit|Sfx|VoicePlayer)$/ }, args => ({ path: args.path.split("/").at(-1), namespace: "battery-ui-test" }));
      build.onLoad({ filter: /.*/, namespace: "battery-ui-test" }, args => ({ contents: args.path === "GameKit"
        ? "export const kit = {};"
        : "export function playSfx(){}; export function playVo(){};", loader: "js" }));
    } }]
  });
  const ui = (await import(pathToFileURL(uiBundle).href)).default;
  for (const percent of [0, 1, 17, 100]) {
    const seed = m.createInitialGameState(); seed.phoneBattery.percent = percent; seed.ui.controlCenterOpen = true;
    const props = { state: seed, events: new m.EventBus(), router: new m.SceneRouter(m.createGameStore(seed), new m.EventBus()) };
    for (const Component of [ui.WakeScene, ui.ControlCenter, ui.StatusBar]) {
      const html = ui.renderToStaticMarkup(ui.createElement(Component, props));
      equal(/充电|补电|低电量模式|DeskDockContact|PutPhoneOnDesk|DeskChargingStatus/.test(html), false, "actual phone markup has no removed charging controls or tutorial");
      equal(html.includes(`${percent}%`), true, "actual battery display includes zero");
    }
    const control = ui.renderToStaticMarkup(ui.createElement(ui.ControlCenter, props));
    equal(control.includes('aria-valuemax="100"'), true, "brightness remains adjustable to100 even at zero");
  }
  for (const relative of ["src/App.tsx", "src/scenes/rpg/RpgGameHost.tsx", "src/scenes/rpg/TheaterInteriorScene.ts", "src/scenes/rpg/TheaterInteriorModel.ts"]) {
    const source = await readFile(path.join(root, relative), "utf8");
    equal(/rpg_theater_charge_requested|THEATER_CHARGING_STATION|kind === "charger"/.test(source), false, `${relative}: no runtime recharging route remains`);
  }
  console.log(`Phone battery source model PASS: ${checks} checks; decreasing floor0, free navigation/network at zero, normal startup brightness, legacy migration/backup, plant gates and actual component markup. Not browser or native acceptance.`);
} finally {
  await rm(output, { recursive: true, force: true });
}
