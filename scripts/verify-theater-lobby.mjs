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
  assert.equal(typeof battery.rechargeAtStation, "undefined", "Theater no longer exposes charging authority");
  store.setState(s => ({ ...s, phoneBattery: { percent: 1 } }));
  assert.equal(battery.consumeForNetworkSwitch(), 0, "The last percent is consumed");
  assert.equal(battery.consumeForNetworkSwitch(), 0, "Zero battery remains usable without a charger");

  // Ticket production remains a controller transaction in either collection order.
  for (const posterFirst of [true, false]) {
    const seed = structuredClone(initial);
    seed.phoneBattery.percent = 0;
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
  console.log("Theater lobby PASS: no charging authority, floor0, both ticket acquisition orders at zero battery, no phone charge action.");
} finally {
  await rm(output, { recursive: true, force: true });
}
