import assert from "node:assert/strict";
import { build } from "esbuild";
import { mkdtemp, readFile, rm } from "node:fs/promises";
import { tmpdir } from "node:os";
import path from "node:path";
import { fileURLToPath, pathToFileURL } from "node:url";

const root = path.resolve(path.dirname(fileURLToPath(import.meta.url)), "..");
const output = await mkdtemp(path.join(tmpdir(), "theater-lobby-validator-"));
try {
  const bundle = path.join(output, "contract.mjs");
  await build({
    stdin: { resolveDir: root, contents: [
      'export * from "./src/core/PhoneChargingStation.ts";',
      'export { PhoneBatteryController } from "./src/modules/PhoneBatteryController.ts";',
      'export { ChapterThreeTheaterController } from "./src/modules/ChapterThreeTheaterController.ts";',
      'export { createInitialGameState, createGameStore } from "./src/core/GameState.ts";',
      'export { SaveStore } from "./src/core/SaveStore.ts";',
      'export { EventBus } from "./src/core/EventBus.ts";'
    ].join("\n") }, outfile: bundle, bundle: true, platform: "node", format: "esm", target: "node20"
  });
  const m = await import(pathToFileURL(bundle).href);
  const initial = m.createInitialGameState();
  initial.runtimeMode = "rpg";
  initial.rpgScene = "theater_interior";
  initial.theaterHunt.active = true;
  initial.theaterHunt.phase = "entry_ticket";
  initial.theaterHunt.mode = "light";
  const store = m.createGameStore(initial), events = new m.EventBus();
  const battery = new m.PhoneBatteryController(store, events);
  const station = m.THEATER_CHARGING_STATION;
  const reject = (changes, point, result, stationId = station.id) => {
    store.setState(() => structuredClone(initial));
    store.setState(s => ({ ...s, ...changes }));
    const before = JSON.stringify(store.getState());
    assert.equal(battery.rechargeAtStation(stationId, point), result);
    assert.equal(JSON.stringify(store.getState()), before, "Rejected charging mutated state");
  };
  reject({runtimeMode: "phone"}, station.stand, "no_power_source");
  reject({rpgScene: "dorm_hub"}, station.stand, "no_power_source");
  reject({ui: {...initial.ui, controlCenterOpen: true}}, station.stand, "no_power_source");
  reject({theaterHunt: {...initial.theaterHunt, active: false}}, station.stand, "no_power_source");
  reject({theaterHunt: {...initial.theaterHunt, mode: "dark"}}, station.stand, "wrong_mode");
  reject({}, {x: 836, y: 820}, "too_far");
  reject({}, {x: NaN, y: 790}, "too_far");
  reject({}, {x: 665, y: Infinity}, "too_far");
  reject({}, station.stand, "no_power_source", "unknown_station");
  store.setState(() => structuredClone(initial));
  const beforeItems = JSON.stringify(store.getState().items);
  assert.equal(battery.rechargeAtStation(station.id, station.stand), "charged");
  assert.equal(store.getState().phoneBattery.percent, 45);
  assert.equal(store.getState().phoneBattery.rechargeCount, 1);
  assert.equal(JSON.stringify(store.getState().items), beforeItems);
  assert.equal(battery.rechargeAtStation(station.id, station.stand), "already_sufficient");
  assert.equal(store.getState().phoneBattery.rechargeCount, 1);
  store.setState(s => ({...s, phoneBattery: {...s.phoneBattery, percent: 87}}));
  assert.equal(battery.rechargeAtStation(station.id, station.stand), "already_sufficient");
  assert.equal(store.getState().phoneBattery.percent, 87, "Charging must not lower an existing battery");
  const values = new Map();
  const saves = new m.SaveStore({getItem:k=>values.get(k)??null,setItem:(k,v)=>values.set(k,v),removeItem:k=>values.delete(k)});
  assert.equal(saves.save(store.getState()), true);
  assert.deepEqual(saves.load(m.createInitialGameState()).phoneBattery, store.getState().phoneBattery);
  store.setState(s => ({...s, phoneBattery: {...s.phoneBattery, percent: 1}}));
  battery.consumeForNetworkSwitch();
  assert.equal(store.getState().phoneBattery.percent, 1, "Reserve must prevent a charging softlock");

  // Ticket production remains a controller transaction in either collection order.
  for (const posterFirst of [true, false]) {
    const seed = structuredClone(initial);
    seed.items.greaseTissue = true;
    seed.theaterHunt.cc98TicketCommissionPhase = "posted";
    seed.networkMode = "cellular";
    const ticketStore = m.createGameStore(seed), ticketBus = new m.EventBus();
    const theater = new m.ChapterThreeTheaterController(ticketStore, ticketBus);
    assert.equal(theater.admitWithTicket(), false);
    assert.equal(theater.submitTicketCode("0832"), false, "Code alone cannot produce a ticket");
    assert.equal(theater.acceptCc98TicketCommission(), true);
    assert.equal(theater.attemptCc98TicketRelease(), "won_first_wave");
    if (posterFirst) assert.equal(theater.cleanPoster(), true);
    assert.equal(theater.submitTicketCode("0832"), true);
    if (!posterFirst) assert.equal(theater.cleanPoster(), true);
    assert.equal(theater.combineTicketHalves(), true);
    assert.equal(theater.combineTicketHalves(), false);
    assert.equal(ticketStore.getState().items.theaterTicketHalfA, false);
    assert.equal(ticketStore.getState().items.theaterTicketHalfB, false);
    assert.equal(ticketStore.getState().items.temporaryTheaterTicket, true);
    assert.equal(theater.admitWithTicket(), true);
    assert.equal(ticketStore.getState().theaterHunt.phase, "program_search");
    assert.equal(ticketStore.getState().items.temporaryTheaterTicket, true);
    assert.equal(ticketBus.getHistory().filter(e=>e.name==="theater_ticket_combined").length, 1);
  }
  const phoneUi = await readFile(path.join(root, "src/components/ControlCenter.tsx"), "utf8");
  assert.ok(!/rechargeAtStation|rechargeFromNearbyPower|startCharging/.test(phoneUi));
  console.log("Theater lobby PASS: 9 charging rejection cases, recharge/idempotency/save/reserve, both ticket acquisition orders, no phone charge action.");
} finally {
  await rm(output, { recursive: true, force: true });
}
