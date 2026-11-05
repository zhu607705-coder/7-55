import assert from "node:assert/strict";
import { existsSync } from "node:fs";
import { build } from "esbuild";
assert(existsSync("src/modules/PhoneBatteryPrank.ts"), "low-battery countdown must have a shared lifetime across scene changes");
const built = await build({entryPoints:["src/modules/PhoneBatteryPrank.ts"],bundle:true,format:"esm",platform:"node",write:false});
const { PhoneBatteryPrank } = await import(`data:text/javascript;base64,${Buffer.from(built.outputFiles[0].text).toString("base64")}`);
const model = new PhoneBatteryPrank();
assert.equal(model.consumeReserve(0, 2), false);
assert.equal(model.consumeReserve(100, 1), true);
assert.equal(model.view(100).seconds, 10);
assert.equal(model.consumeReserve(9000, 1), false, "repeated actions must not restart the clock");
assert.equal(model.view(10099).kind, "warning");
assert.equal(model.view(10100).text, "吓吓你的");
assert.equal(model.view(14000), null);
assert.equal(model.consumeReserve(15000, 1), false, "do not repeat the same joke on every action");
model.reset();
assert.equal(model.consumeReserve(20000, 1), true);
model.reset();
assert.equal(model.view(30000), null, "story reset cancels the warning and punchline");
console.log("Battery prank PASS: threshold, exact 10-second boundary, no stacking, cancellation and re-arming.");


// Exercise the retained real consumption controller with the original prank.
const contract = await build({stdin:{resolveDir:process.cwd(),contents:[
  'export { PhoneBatteryController } from "./src/modules/PhoneBatteryController.ts";',
  'export { createInitialGameState, createGameStore } from "./src/core/GameState.ts";',
  'export { EventBus } from "./src/core/EventBus.ts";'
].join("\n")},bundle:true,format:"esm",platform:"node",write:false});
const { PhoneBatteryController, createInitialGameState, createGameStore, EventBus } = await import(`data:text/javascript;base64,${Buffer.from(contract.outputFiles[0].text).toString("base64")}`);
const initial = createInitialGameState(); initial.phoneBattery.percent = 2; initial.ui.brightness = 37;
const store = createGameStore(initial), events = new EventBus(), battery = new PhoneBatteryController(store, events), story = new PhoneBatteryPrank();
let now = 0, triggerCount = 0;
events.subscribe(event => { if (event.name === "phone_battery_reserve_used") { triggerCount++; story.consumeReserve(now, event.payload.percent); } });
assert.equal(battery.consumeForNetworkSwitch(), 1);
assert.equal(story.view(0), null, "arriving at 1% does not start the original prank early");
for (const page of ["phone_home", "wechat", "bonsai", "settings"]) battery.consumeForSceneOpen("phone_home", page);
assert.equal(triggerCount, 0, "ordinary app navigation never triggers the prank");
now = 100;
assert.equal(battery.consumeForNetworkSwitch(), 0, "original next-network-action trigger allows actual depletion to zero");
assert.equal(story.view(now).text, "请在 10秒之内充电，不然手机就会自动关机。");
assert.equal(store.getState().ui.brightness, 37, "prank cannot dim the chosen brightness");
const depleted = structuredClone(store.getState());
for (let index = 0; index < 20; index++) battery.consumeForNetworkSwitch();
assert.equal(triggerCount, 1, "zero-percent actions cannot retrigger or extend the warning");
assert.deepEqual(store.getState(), depleted, "repeated warning-time actions cannot refill or alter story state");
assert.equal(story.view(10099).kind, "warning");
assert.equal(story.view(10100).text, "吓吓你的");
assert.equal(story.view(13599).kind, "joke");
assert.equal(story.view(13600), null, "exact 3.5-second joke expires without shutdown");
assert.deepEqual(store.getState(), depleted, "countdown and punchline are presentation-only");
console.log("Battery prank integration PASS: original prior-1% trigger, free navigation, real zero, no dimming/refill/lock, one-shot lifetime.");
