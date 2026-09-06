import assert from "node:assert/strict";
import { readFile } from "node:fs/promises";

const content = JSON.parse(await readFile(new URL("../src/data/chapter4-755.content.json", import.meta.url), "utf8"));
const expectedTransitions = [
  ["opening_to_bakery", "hall_clock_inspection", "bakery_hour_hand", "transition_overlay"],
  ["clock_tune_to_evening", "room204_restore", "room204_restore", "transition_overlay"],
  ["clock_tune_to_maintenance", "maintenance_repair", "maintenance_repair", "transition_overlay"],
  ["maintenance_to_blackout", "maintenance_repair", "blackout_light_grid", "transition_overlay"],
  ["blackout_to_chase", "blackout_light_grid", "final_chase", "scene_interaction"],
  ["chase_to_room202", "final_chase", "final_minute_recovery", "scene_interaction"],
  ["room202_to_clock_return", "final_minute_recovery", "return_to_clock", "scene_interaction"],
  ["clock_return_to_morning", "return_to_clock", "morning_checkin", "transition_overlay"],
  ["checkin_to_exterior", "morning_checkin", "exterior_closure", "scene_interaction"]
];

assert.equal(content.contractId, "chapter4-755");
assert.deepEqual(content.orderedPhases, [
  "opening_handoff", "opening_paper_caught", "hall_clock_inspection", "bakery_hour_hand",
  "room204_restore", "maintenance_repair", "blackout_light_grid", "final_chase",
  "final_minute_recovery", "return_to_clock", "morning_checkin", "exterior_closure", "complete"
]);
assert.equal(content.transitionContracts.length, expectedTransitions.length);
assert.deepEqual(
  content.transitionContracts.map(({ id, fromPhase, toPhase, owner }) => [id, fromPhase, toPhase, owner]),
  expectedTransitions
);
assert.equal(content.transitionContracts.filter((entry) => entry.presentationKind === "time_shift").length, 5);
assert.equal(content.transitionContracts.filter((entry) => entry.presentationKind === "world_handoff").length, 4);

const phaseTaskKeys = new Set(content.phaseContracts.flatMap((phase) => phase.taskKeys));
for (const [taskId, task] of Object.entries(content.tasks)) {
  assert.equal(typeof task.label, "string", `${taskId} needs a label`);
  assert(task.label.trim().length > 0, `${taskId} needs a readable label`);
  const expectedHints = taskId === "chapter_complete" || taskId === "acknowledge_exterior_closure" ? 0 : 3;
  assert.equal(task.hints.length, expectedHints, `${taskId} hint count`);
  assert(task.hints.every((hint) => typeof hint === "string" && hint.trim().length > 0), `${taskId} hints must be readable`);
}
for (const taskId of phaseTaskKeys) assert(Object.hasOwn(content.tasks, taskId), `phase task ${taskId} must have copy`);
for (const taskId of ["resolve_a1_investigation", "resolve_a3_archive_chain", "resolve_a2_inserted_puzzles", "resolve_elevator_stop_chain", "cross_chase_stairwell"]) {
  assert(Object.hasOwn(content.tasks, taskId), `${taskId} must remain available when its dependent evidence is ready`);
}

assert.equal(content.guard.finalChase.startGraceMs, 2000);
assert.equal(content.guard.finalChase.guardSpeed, 174);
assert.equal(content.guard.finalChase.playerSpeed, 208);
assert.deepEqual(content.guard.finalChase.states, ["arming", "running", "portal_transfer", "finish_pending", "failure_pending", "complete"]);
assert.equal(content.lightGrid.initialMask, 6);
assert.equal(content.lightGrid.targetMask, 13);
assert.equal(content.lightGrid.maximumSolutionToggles, 3);
assert.equal(content.evidenceContracts.length, 11);
assert.equal(content.room204.groups.length, 4);
assert(content.room204.groups.every((group) => group.mappings.length === 3));

console.log(`Chapter 4 story PASS phases=${content.orderedPhases.length} transitions=5+4 tasks=${Object.keys(content.tasks).length} guard=2s/174.`);
