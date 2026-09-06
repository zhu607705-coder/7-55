import assert from "node:assert/strict";
import { createServer } from "vite";
import content from "../src/data/chapter4-755.content.json" with { type: "json" };

const taskKeys = new Set(content.phaseContracts.flatMap((phase) => phase.taskKeys));
for (const taskKey of taskKeys) assert(Object.hasOwn(content.tasks, taskKey), `${taskKey} must be described`);
assert.equal(content.tasks.acknowledge_exterior_closure.hints.length, 0, "the exterior acknowledgement is a final confirmation, not a hint drawer");
assert.equal(content.tasks.chapter_complete.hints.length, 0);
assert.equal(content.transitionContracts.length, 9);
assert.equal(content.transitionContracts.filter((entry) => entry.owner === "transition_overlay").length, 5);
assert.equal(content.transitionContracts.filter((entry) => entry.owner === "scene_interaction").length, 4);

const server = await createServer({ configFile: false, appType: "custom", logLevel: "error", optimizeDeps: { noDiscovery: true, include: [] }, server: { middlewareMode: true, ws: false } });
try {
  const developer = await server.ssrLoadModule("/src/modules/DeveloperChannel.ts");
  const visible = developer.DEVELOPER_CHECKPOINTS.filter((entry) => entry.chapter === "第四章").map((entry) => entry.id);
  for (const id of ["c4-755-clock-1850-ready", "c4-755-a2-field-records", "c4-755-clock-2245-ready", "c4-755-blackout-0754", "c4-755-chase"]) {
    assert(visible.includes(id), `${id} must remain a visible current gameplay checkpoint`);
  }
  assert(!visible.includes("c4-755-result"), "completion is exercised through the verified closure path, not a forged result checkpoint");
} finally {
  await server.close();
}
console.log(`Chapter 4 task contract PASS tasks=${Object.keys(content.tasks).length} transitions=5+4.`);
