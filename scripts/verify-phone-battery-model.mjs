import assert from "node:assert/strict";
import { build } from "esbuild";
import { mkdtemp, rm } from "node:fs/promises";
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
      'export * from "./src/core/PhoneChargingStation.ts";',
      'export { PlantController } from "./src/modules/PlantController.ts";',
      'export { createInitialGameState, createGameStore } from "./src/core/GameState.ts";',
      'export { SceneRouter } from "./src/core/SceneRouter.ts";',
      'export { SaveStore } from "./src/core/SaveStore.ts";',
      'export { GAME_SAVE_KEY, GAME_SAVE_BACKUP_KEY } from "./src/core/StorageKeys.ts";',
      'export { EventBus } from "./src/core/EventBus.ts";'
    ].join("\n") }, outfile: bundle, bundle: true, platform: "node", format: "esm", target: "node20"
  });
  const m = await import(pathToFileURL(bundle).href);
  const scenes = ["alarm", "desktop", "phone_home", "settings", "wechat", "cc98", "zjuding", "tiyi", "weather", "photos", "timeline_recovery", "voice_memos", "campus_card", "checkin", "bonsai", "clock", "ending"];
  for (const percent of [0, 1, 17]) for (const lowPowerMode of [false, true]) {
    const initial = m.createInitialGameState();
    initial.phoneBattery = { percent, lowPowerMode, rechargeCount: 3 };
    initial.ui.brightness = 37;
    const store = m.createGameStore(initial), events = new m.EventBus();
    const battery = new m.PhoneBatteryController(store, events);
    const before = store.getState();
    for (const scene of scenes) {
      equal(m.getPhoneSceneBatteryCost(scene, lowPowerMode), 0, `${scene}: navigation cost is zero in either mode`);
      for (let repeat = 0; repeat < 3; repeat++) equal(battery.consumeForSceneOpen("phone_home", scene), percent, `${percent}% survives repeated app open`);
    }
    equal(store.getState() === before, true, "free app opens perform no state write");
    equal(events.getHistory(), [], "free app opens emit no drain, reserve-prank or warning events");
    const router = new m.SceneRouter(store, events, (from, to) => battery.consumeForSceneOpen(from, to));
    for (let repeat = 0; repeat < 3; repeat++) {
      for (const scene of ["phone_home", "wechat", "bonsai", "settings", "tiyi", "desktop"]) {
        equal(router.goTo(scene), true, "ordinary C1 navigation is accepted");
        equal(store.getState().phoneBattery, initial.phoneBattery, "router app/home/reopen preserves battery and mode");
        router.back();
        equal(store.getState().phoneBattery, initial.phoneBattery, "router back preserves battery and mode");
      }
    }
    equal(store.getState().ui.brightness, 37, "navigation never changes chosen brightness");
    equal(store.getState().flags, initial.flags, "navigation never bypasses puzzle flags");
    equal(store.getState().items, initial.items, "navigation never changes inventory");
    equal(events.getHistory().some(event => event.name.startsWith("phone_battery_")), false, "ordinary router navigation does not simulate battery depletion");
  }

  for (const lowPowerMode of [false, true]) {
    const initial = m.createInitialGameState();
    initial.phoneBattery.lowPowerMode = lowPowerMode;
    const store = m.createGameStore(initial), events = new m.EventBus();
    const battery = new m.PhoneBatteryController(store, events);
    equal(battery.consumeForNetworkSwitch(), 16, "explicit network switching retains its original one-percent cost");
    equal(events.getHistory().filter(event => event.name === "phone_battery_changed").at(-1).payload.reason, "network_switch", "network cost retains its own event identity");
    store.setState(state => ({ ...state, phoneBattery: { ...state.phoneBattery, percent: 1 } }));
    equal(battery.consumeForNetworkSwitch(), 1, "explicit network switching retains the existing one-percent reserve");
  }

  const modes = [false, true];
  for (const percent of [0, 1]) for (const lowPowerMode of modes) {
    const initial = m.createInitialGameState();
    initial.currentScene = "bonsai";
    initial.phoneBattery = { percent, lowPowerMode, rechargeCount: 3 };
    initial.ui.brightness = 37;
    const disk = storage(), saves = new m.SaveStore(disk);
    equal(saves.save(initial), true, "ordinary source save commits a zero/one-percent state");
    const first = new m.SaveStore(disk).load(m.createInitialGameState());
    equal(first.phoneBattery, initial.phoneBattery, "new SaveStore instance reload preserves zero/one, mode and recharge count");
    equal(first.ui.brightness, 37, "save round-trip preserves selected brightness");
    equal(first.flags, initial.flags, "save round-trip does not grant plant or other flags");
    equal(first.items, initial.items, "save round-trip preserves inventory");
    equal(saves.save(first), true, "loaded low-battery state can be saved again");
    equal(new m.SaveStore(disk).load(m.createInitialGameState()).phoneBattery, initial.phoneBattery, "second write/reload does not silently reset to initial17");
    for (const version of [34, 35, null]) {
      const source = version === null ? initial : { version, state: initial };
      disk.values.clear(); disk.setItem(m.GAME_SAVE_KEY, JSON.stringify(source));
      const imported = new m.SaveStore(disk).load(m.createInitialGameState());
      equal(imported.phoneBattery, initial.phoneBattery, "ordinary legacy/versioned source envelope preserves zero/one battery");
      equal(imported.ui.brightness, 37, "source import does not raise brightness or light the plant");
      equal(imported.flags.flowerBloomed, false, "source import retains the original plant progression gate");
    }
  }

  for (const invalid of [-1, 101, 1.5, "0", null, undefined, NaN, Infinity]) {
    const initial = m.createInitialGameState(), disk = storage();
    const corrupted = { ...initial, phoneBattery: { ...initial.phoneBattery, percent: invalid } };
    disk.setItem(m.GAME_SAVE_KEY, JSON.stringify({ version: 35, state: corrupted }));
    equal(new m.SaveStore(disk).load(initial).phoneBattery.percent, 17, "invalid range/type/nonfinite battery still uses the validated default");
  }
  for (const percent of [0, 100]) {
    const initial = m.createInitialGameState(), disk = storage();
    disk.setItem(m.GAME_SAVE_KEY, JSON.stringify({ version: 35, state: { ...initial, phoneBattery: { ...initial.phoneBattery, percent } } }));
    equal(new m.SaveStore(disk).load(initial).phoneBattery.percent, percent, "both valid battery bounds remain inclusive");
  }

  function deskCase(percent = 1, lowPowerMode = true) {
    let time = 0, focused = true, hidden = false, observers = 0;
    const initial = m.createInitialGameState();
    initial.currentScene = "desktop";
    initial.phoneBattery = { percent, lowPowerMode, rechargeCount: 0 };
    initial.ui.brightness = 37;
    const store = m.createGameStore(initial), events = new m.EventBus();
    const subscribe = store.subscribe;
    store.subscribe = listener => { observers++; const stop = subscribe(listener); return () => { observers--; stop(); }; };
    const battery = new m.PhoneBatteryController(store, events, () => time, () => focused && !hidden);
    return { store, events, battery, initial, advance: (value, receipt) => {
        if (!receipt) { time += value; return; }
        while (value > 0) { const step = Math.min(100, value); time += step; value -= step; battery.getHomeDeskChargingProgress(receipt); }
      },
      focus: value => { focused = value; }, hidden: value => { hidden = value; }, observers: () => observers };
  }
  for (const percent of [0, 1, 2, 17]) for (const lowPowerMode of [false, true]) {
    const h = deskCase(percent, lowPowerMode);
    equal(h.battery.consumeForNetworkSwitch(), Math.min(percent, Math.max(1, percent - 1)), "network switch cannot charge a zero-percent save; positive reserve remains one");
  }
  for (const percent of [0, 1, 17, 45, 87]) for (const lowPowerMode of [false, true]) {
    const h = deskCase(percent, lowPowerMode), before = structuredClone(h.store.getState());
    const receipt = h.battery.beginHomeDeskCharging();
    if (percent >= 45 && !lowPowerMode) {
      equal(receipt, "already_sufficient", "sufficient and normal-mode battery needs no recharge");
      equal(h.store.getState(), before, "no-op recharge changes no state");
      continue;
    }
    equal(typeof receipt, "object", "physical early desk can start even at zero without items/coins/C2");
    equal(h.observers(), 1, "one runtime lifecycle observer belongs to the live receipt");
    h.advance(500, receipt);
    equal(h.battery.beginHomeDeskCharging() === receipt, true, "duplicate contact reuses the same receipt, not restart or cancel");
    equal(h.battery.completeHomeDeskCharging({ ...receipt }), "invalid_receipt", "copied/forged receipt has no authority");
    h.battery.cancelHomeDeskCharging({ ...receipt });
    equal(h.battery.getHomeDeskChargingProgress(receipt), 500 / 2200, "forged cancellation cannot cancel real owner");
    h.advance(1699, receipt);
    equal(h.battery.completeHomeDeskCharging(receipt), "too_early", "2199ms does not grant battery");
    equal(h.store.getState(), before, "early completion leaves every persisted field unchanged");
    h.advance(1, receipt);
    equal(h.battery.completeHomeDeskCharging(receipt), "charged", "2200ms valid receipt completes exactly once");
    equal(h.store.getState().phoneBattery, { percent: Math.max(percent, 45), lowPowerMode: false, rechargeCount: 1 }, "recovery clears low power without reducing a high battery");
    equal(h.store.getState().ui.brightness, before.ui.brightness, "charge never raises or restores brightness automatically");
    equal(h.store.getState().flags, before.flags, "charge does not light or grow the plant");
    equal(h.store.getState().items, before.items, "charge consumes no required item");
    equal(h.store.getState().wallet, before.wallet, "charge is not coin-gated");
    equal(h.battery.completeHomeDeskCharging(receipt), "invalid_receipt", "duplicate completion cannot recharge twice");
    equal(h.events.getHistory().filter(event => event.name === "phone_battery_recharged").length, 1, "one receipt produces one recharge event");
    equal(h.observers(), 0, "successful receipt removes its lifecycle observer");
  }
  {
    const h = deskCase(); const receipt = h.battery.beginHomeDeskCharging();
    h.advance(60000);
    equal(h.battery.getHomeDeskChargingProgress(receipt), 100 / 2200, "stalled foreground frame accrues at most the original theater100ms cap");
    equal(h.battery.getHomeDeskChargingProgress(receipt), 100 / 2200, "duplicate observation at same clock adds no time");
    equal(h.battery.completeHomeDeskCharging(receipt), "too_early", "one resumed frame cannot instantly finish charging");
    h.advance(2100, receipt);
    equal(h.battery.completeHomeDeskCharging(receipt), "charged", "continuous sampled foreground timeline can finish after stalled interval");
  }
  const interruptions = {
    explicit: h => h.battery.cancelHomeDeskCharging(),
    unmountCleanupIntent: h => h.battery.cancelHomeDeskCharging(),
    pickup: h => h.battery.takePhoneFromDesk(),
    pageRoundTrip: h => { h.store.setState(s => ({ ...s, currentScene: "phone_home" })); h.store.setState(s => ({ ...s, currentScene: "desktop" })); },
    modalRoundTrip: h => { h.store.setState(s => ({ ...s, ui: { ...s.ui, controlCenterOpen: true } })); h.store.setState(s => ({ ...s, ui: { ...s.ui, controlCenterOpen: false } })); },
    replacedSave: h => h.store.setState(s => structuredClone(s)),
    changedFlags: h => h.store.setState(s => ({ ...s, flags: { ...s.flags } })),
    changedBattery: h => h.store.setState(s => ({ ...s, phoneBattery: { ...s.phoneBattery } })),
    blur: h => { h.focus(false); equal(h.battery.getHomeDeskChargingProgress(h.receipt), null, "blur invalidates owner before foreground returns"); h.focus(true); },
    hidden: h => { h.hidden(true); equal(h.battery.getHomeDeskChargingProgress(h.receipt), null, "hidden page invalidates owner before visible again"); h.hidden(false); }
  };
  for (const [name, interrupt] of Object.entries(interruptions)) {
    const h = deskCase(); h.receipt = h.battery.beginHomeDeskCharging(); h.advance(1000);
    interrupt(h); h.advance(2200);
    equal(h.battery.completeHomeDeskCharging(h.receipt), "invalid_receipt", `${name}: stale completion rejected`);
    equal(h.store.getState().phoneBattery, h.initial.phoneBattery, `${name}: no partial/unattended charge gain`);
    equal(h.observers(), 0, `${name}: observer released`);
  }
  for (const mutation of [
    s => ({ ...s, runtimeMode: "rpg" }), s => ({ ...s, currentScene: "phone_home" }),
    s => ({ ...s, actOne: { ...s.actOne, phase: "friend_message_required" } }),
    s => ({ ...s, flags: { ...s.flags, checkinDone: true } }),
    s => ({ ...s, ui: { ...s.ui, controlCenterOpen: true } }),
    s => ({ ...s, theaterHunt: { ...s.theaterHunt, active: true } })
  ]) {
    const h = deskCase(); h.store.setState(mutation);
    equal(h.battery.beginHomeDeskCharging(), "no_power_source", "early station rejects wrong chapter/page/mode/modal/checkin context");
    equal(h.battery.rechargeAtStation(m.HOME_DESK_CHARGING_STATION.id, { x: 0, y: 0 }), "no_power_source", "home station cannot forge theater's immediate route");
  }
  {
    const h = deskCase(); h.focus(false);
    equal(h.battery.beginHomeDeskCharging(), "no_power_source", "cannot begin while unfocused");
    h.focus(true); h.hidden(true);
    equal(h.battery.beginHomeDeskCharging(), "no_power_source", "cannot begin while hidden");
  }
  {
    const h = deskCase(); const receipt = h.battery.beginHomeDeskCharging();
    h.store.setState(s => ({ ...s, ui: { ...s.ui, brightness: 41 } })); h.advance(2200, receipt);
    equal(h.battery.completeHomeDeskCharging(receipt), "charged", "ordinary UI updates do not impersonate a replaced save");
    equal(h.store.getState().ui.brightness, 41, "latest manually selected brightness is preserved");
  }
  for (const page of ["phone_home", "bonsai"]) {
    const h = deskCase(0); h.store.setState(s => ({ ...s, currentScene: page }));
    equal(h.battery.prepareHomeDeskReturn(page), true, "early phone page can be put down without chapter travel");
    const router = new m.SceneRouter(h.store, h.events, (from, to) => h.battery.consumeForSceneOpen(from, to));
    equal(router.goTo("desktop"), true, "putdown enters the existing real desktop");
    equal(h.battery.hasHomeDeskReturn(), true, "returned desk suppresses the original wake sequence");
    h.store.setState(s => ({ ...s, ui: { ...s.ui, controlCenterOpen: true } }));
    equal(h.battery.hasHomeDeskReturn(), true, "modal opening does not replay wake presentation");
    h.store.setState(s => ({ ...s, ui: { ...s.ui, controlCenterOpen: false } }));
    const receipt = h.battery.beginHomeDeskCharging(), disk = storage(), saves = new m.SaveStore(disk);
    equal(saves.save(h.store.getState()), true, "ordinary save during charge stores navigation but not a live receipt");
    const restored = new m.SaveStore(disk).load(m.createInitialGameState());
    equal(restored.currentScene, "desktop", "reload stays on real desk");
    equal(restored.ui.homeDeskReturnScene, page, "reload preserves the valid early return page");
    equal(restored.phoneBattery.percent, 0, "unfinished charge does not survive save as energy gain");
    h.store.setState(() => restored); h.advance(2200);
    equal(h.battery.completeHomeDeskCharging(receipt), "invalid_receipt", "save replacement rejects original receipt");
    const resumed = new m.PhoneBatteryController(h.store, h.events);
    equal(resumed.hasHomeDeskReturn(), true, "new controller resumes desk without replaying wake");
    equal(resumed.completeHomeDeskCharging(receipt), "invalid_receipt", "fresh controller cannot accept earlier session");
    equal(resumed.takePhoneFromDesk(), page, "pickup returns to the actual prior page");
    equal(h.store.getState().ui.homeDeskReturnScene, null, "pickup retires saved navigation context");
    equal(h.store.getState().flags, restored.flags, "putdown/reload/pickup do not reset puzzle flags");
  }
  for (const version of [35, 36]) for (const field of [undefined, "phone_home", "bonsai", null, "ending", 0, {}, false]) {
    const initial = m.createInitialGameState(), disk = storage(); initial.currentScene = "desktop";
    if (field === undefined) delete initial.ui.homeDeskReturnScene; else initial.ui.homeDeskReturnScene = field;
    disk.setItem(m.GAME_SAVE_KEY, JSON.stringify({ version, state: initial }));
    const restored = new m.SaveStore(disk).load(m.createInitialGameState());
    const valid = field === null || field === "phone_home" || field === "bonsai" || (field === undefined && version === 35);
    equal(restored !== null, valid, "strict36 requires desk field; old35 missing defaults null; explicit invalid enum is rejected");
    if (valid) equal(restored.ui.homeDeskReturnScene, field ?? null, "valid return navigation survives normalization");
  }
  for (const mutation of [
    s => ({ ...s, runtimeMode: "rpg" }), s => ({ ...s, currentScene: "settings" }),
    s => ({ ...s, actOne: { ...s.actOne, phase: "friend_message_required" } }),
    s => ({ ...s, flags: { ...s.flags, checkinDone: true } })
  ]) {
    const initial = m.createInitialGameState(), disk = storage(); initial.currentScene = "desktop"; initial.ui.homeDeskReturnScene = "bonsai";
    disk.setItem(m.GAME_SAVE_KEY, JSON.stringify({ version: 36, state: mutation(initial) }));
    equal(new m.SaveStore(disk).load(m.createInitialGameState()).ui.homeDeskReturnScene, null, "source import discards stale/non-C1 desk navigation");
  }
  for (const percent of [0, 45, 87]) {
    const h = deskCase(percent); h.store.setState(s => ({ ...s, runtimeMode: "rpg", rpgScene: "theater_interior", theaterHunt: { ...s.theaterHunt, active: true, mode: "light" } }));
    equal(h.battery.rechargeAtStation(m.THEATER_CHARGING_STATION.id, m.THEATER_CHARGING_STATION.stand), "charged", "existing valid theater recharge also exits low power");
    equal(h.store.getState().phoneBattery.percent, Math.max(45, percent), "theater recharge never reduces battery");
    equal(h.store.getState().phoneBattery.lowPowerMode, false, "theater recharge clears low power");
    equal(h.store.getState().ui.brightness, 37, "theater recharge preserves brightness");
  }
  {
    const h = deskCase(); h.store.setState(s => ({ ...s, flags: { ...s.flags, plantWatered: true, plantFertilized: true } }));
    const receipt = h.battery.beginHomeDeskCharging(); h.advance(2200, receipt); h.battery.completeHomeDeskCharging(receipt);
    const plant = new m.PlantController(h.store, h.events);
    equal(plant.apply("light"), "missing_requirement", "recovery alone cannot solve plant light");
    equal(h.store.getState().flags.flowerBloomed, false, "recovery alone never blooms the plant");
    h.store.setState(s => ({ ...s, ui: { ...s.ui, brightness: 79 } }));
    equal(plant.apply("light"), "missing_requirement", "79 remains below original manual threshold");
    h.store.setState(s => ({ ...s, ui: { ...s.ui, brightness: 80 } }));
    equal(plant.apply("light"), "done", "player can manually choose80 after recovery");
    equal(h.store.getState().flags.flowerBloomed, true, "only original three-step plant controller grants bloom");
  }

  // Render actual scene/component markup with the real controller injected in
  // place of the global singleton. This is adapter structure, not DOM input,
  // screenshots or browser focus/visibility acceptance.
  const uiBundle = path.join(output, "desk-ui.cjs");
  globalThis.__batteryUiKit = {};
  await build({
    stdin: { resolveDir: root, contents: [
      'export { WakeScene } from "./src/scenes/phone/P01_Desktop/index.tsx";',
      'export { PutPhoneOnDesk } from "./src/scenes/phone/P01_Desktop/EarlyDeskCharging.tsx";',
      'export { createElement } from "react";',
      'export { renderToStaticMarkup } from "react-dom/server";'
    ].join("\n") }, outfile: uiBundle, bundle: true, platform: "node", format: "cjs", target: "node20",
    loader: { ".png": "dataurl", ".css": "empty" },
    plugins: [{ name: "isolated-real-battery-controller", setup(build) {
      build.onResolve({ filter: /\/modules\/(GameKit|Sfx|VoicePlayer)$/ }, args => ({ path: args.path.split("/").at(-1), namespace: "desk-ui-test" }));
      build.onLoad({ filter: /.*/, namespace: "desk-ui-test" }, args => ({ contents: args.path === "GameKit"
        ? "export const kit = globalThis.__batteryUiKit;"
        : "export function playSfx(){}; export function playVo(){};", loader: "js" }));
    } }]
  });
  const ui = (await import(pathToFileURL(uiBundle).href)).default;
  for (const page of [null, "phone_home", "bonsai"]) {
    const h = deskCase(); h.store.setState(s => ({ ...s, ui: { ...s.ui, homeDeskReturnScene: page } }));
    globalThis.__batteryUiKit.battery = h.battery;
    const props = { state: h.store.getState(), events: h.events, router: new m.SceneRouter(h.store, h.events) };
    const html = ui.renderToStaticMarkup(ui.createElement(ui.WakeScene, props));
    equal(html.includes("……再睡5分钟……"), page === null, "real P01 markup retains first wake but not returned/reloaded wake");
    equal(html.includes('data-testid="DeskPhonePickup"'), page !== null, "real returned desktop exposes physical phone pickup");
    equal(html.includes('data-testid="DeskDockContact"'), true, "real early desktop renders a separate charging contact");
    equal(html.includes('class="early-desk-dock-art"'), true, "charging contact is accompanied by supplied physical object art");
    equal(html.includes('data-testid="DeskChargingStatus"'), true, "charging status is separate from art and contact");
  }
  {
    const h = deskCase(); h.store.setState(s => ({ ...s, currentScene: "bonsai" })); globalThis.__batteryUiKit.battery = h.battery;
    const props = () => ({ state: h.store.getState(), events: h.events, router: new m.SceneRouter(h.store, h.events) });
    equal(ui.renderToStaticMarkup(ui.createElement(ui.PutPhoneOnDesk, props())).includes('data-testid="PutPhoneOnDesk"'), true, "C1 has the small return-to-desk affordance");
    h.store.setState(s => ({ ...s, theaterHunt: { ...s.theaterHunt, active: true } }));
    equal(ui.renderToStaticMarkup(ui.createElement(ui.PutPhoneOnDesk, props())), "", "later chapter cannot expose the early desk affordance");
  }
  delete globalThis.__batteryUiKit;
  console.log(`Phone battery source model PASS: ${checks} checks; free navigation, network reserve, zero/one save/import, early2200ms charging receipt/lifecycle, desktop return reload and plant gates. Not browser or native gameplay acceptance.`);
} finally {
  await rm(output, { recursive: true, force: true });
}
