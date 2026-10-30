// Offline design analysis, not an implementation or acceptance of the game.
// Enumerates the finite sketch, checks geometry and searches legal transitions.
import assert from 'node:assert/strict';
import { createHash } from 'node:crypto';
import { readFile, writeFile } from 'node:fs/promises';
import { fileURLToPath } from 'node:url';

const campus = new URL('../', import.meta.url);
const read = async name => readFile(new URL(name, campus), 'utf8');
const digest = text => createHash('sha256').update(text).digest('hex');
const raw = await read('design/puzzle_campaign.v1.json');
const spec = JSON.parse(raw);
const sourcesRaw = await read('design/transcript_sources.v1.json');
const sources = JSON.parse(sourcesRaw);
const level = id => spec.levels.find(entry => entry.id === id);
let assertions = 0;
function check(value, message) {
  assertions++;
  assert.ok(value, message);
}

check(spec.status === 'design_only', 'The sketch must not claim runtime delivery');
check(spec.roomSequenceIsMandatory === false, 'The suggested route must not lock floor access');
check(spec.observationIsCompletionGate === false, 'Reading is not a completion event');
const floors = new Map();
const sourceHashes = {};
for (const n of [2, 3, 4]) {
  const text = await read(`data/floor_${n}.json`);
  floors.set(n, JSON.parse(text));
  sourceHashes[`data/floor_${n}.json`] = digest(text);
}
let anchors = 0;
const sourceIds = new Set(sources.clips.map(clip => clip.id));
for (const entry of spec.levels) {
  const data = floors.get(entry.floor);
  check(data.rooms.some(room => room.id === entry.room), `${entry.id}: missing room`);
  for (const id of entry.anchors) {
    const object = data.objects.find(item => item.id === id);
    check(object && object.room === entry.room, `${entry.id}: missing or misplaced anchor ${id}`);
    anchors++;
  }
  for (const id of entry.sources) check(sourceIds.has(id), `${entry.id}: missing source ${id}`);
}
const localRootArg = process.argv.indexOf('--source-root');
let transcriptHashChecks = 0;
if (localRootArg >= 0) {
  const root = process.argv[localRootArg + 1];
  check(Boolean(root) && !root.startsWith('--'), '--source-root needs a path');
  for (const clip of sources.clips) {
    const text = await readFile(`${root}/${clip.relativePath}`, 'utf8');
    check(digest(text) === clip.sha256, `${clip.id}: local transcript has changed`);
    const lines = text.split('\n').slice(clip.lineStart - 1, clip.lineEnd).join('\n');
    check(lines.includes(`**${clip.start}–`), `${clip.id}: source start is not traceable`);
    check(lines.includes(`–${clip.end}**`), `${clip.id}: source end is not traceable`);
    transcriptHashChecks++;
  }
}

// L1 is a deliberately pinned summary of the inspected, existing source. It
// measures the search space; only the Godot suite can test its actual execution.
const drive = level('L1').model;
const driveSource = await read(drive.sourceFile);
check(digest(driveSource) === drive.sourceSha256, 'Workbench source changed; reread before reusing the summary');
sourceHashes[drive.sourceFile] = digest(driveSource);
let driveStates = 0;
const driveSolutions = [];
for (const gear of drive.gears) for (const belt of drive.belts) for (const tension of drive.tensions) {
  driveStates++;
  if (gear === 1 && belt === 2 && tension === 1) driveSolutions.push({ gear, belt, tension });
}
check(driveStates === 36 && driveSolutions.length === 1, 'Current one-way workbench summary drifted');

const EPS = 1e-9;
const subtract = (a, b) => [a[0] - b[0], a[1] - b[1]];
const cross = (a, b) => a[0] * b[1] - a[1] * b[0];
const dot = (a, b) => a[0] * b[0] + a[1] * b[1];
function intersects(a, b, c, d) {
  const r = subtract(b, a), s = subtract(d, c), q = subtract(c, a);
  const den = cross(r, s);
  if (Math.abs(den) < EPS) {
    if (Math.abs(cross(q, r)) > EPS) return false;
    const length = dot(r, r);
    if (length < EPS) return Math.hypot(...subtract(a, c)) < EPS;
    const t0 = dot(q, r) / length, t1 = t0 + dot(s, r) / length;
    return Math.max(Math.min(t0, t1), 0) <= Math.min(Math.max(t0, t1), 1) + EPS;
  }
  const t = cross(q, s) / den, u = cross(q, r) / den;
  return t >= -EPS && t <= 1 + EPS && u >= -EPS && u <= 1 + EPS;
}
function targetCorners(model) {
  const [x, y] = model.target, h = model.targetHalfSize;
  return [[x - h, y - h], [x + h, y - h], [x + h, y + h], [x - h, y + h]];
}
function optics(model, panels, light) {
  const corners = targetCorners(model);
  return {
    shaded: corners.every(point => panels.some(([a, b]) => intersects(light, point, a, b))),
    viewClear: corners.every(point => panels.every(([a, b]) => !intersects(model.camera, point, a, b)))
  };
}
// Conservative AABB sweep for the toy carriage. Panels in this sketch are
// axis aligned; no perspective, height or rendered pixels are inferred here.
function sweepHitsPanel(from, to, panel, radius) {
  const [a, b] = panel;
  const low = [0, 1].map(i => Math.min(a[i], b[i]) - radius);
  const high = [0, 1].map(i => Math.max(a[i], b[i]) + radius);
  let enter = 0, leave = 1;
  for (const axis of [0, 1]) {
    const delta = to[axis] - from[axis];
    if (Math.abs(delta) < EPS) {
      if (from[axis] < low[axis] || from[axis] > high[axis]) return false;
    } else {
      const t0 = (low[axis] - from[axis]) / delta;
      const t1 = (high[axis] - from[axis]) / delta;
      enter = Math.max(enter, Math.min(t0, t1));
      leave = Math.min(leave, Math.max(t0, t1));
      if (enter > leave + EPS) return false;
    }
  }
  return enter <= leave + EPS;
}

const shade = level('L2').model;
const lightSolutions = {};
const shadeResults = [];
for (const [condition, light] of Object.entries(shade.lights)) {
  lightSolutions[condition] = [];
  for (const [pose, panel] of Object.entries(shade.poses)) {
    const result = optics(shade, [panel], light);
    shadeResults.push({ condition, pose, ...result });
    if (result.shaded && result.viewClear) lightSolutions[condition].push(pose);
  }
}
check(JSON.stringify(lightSolutions) === JSON.stringify({ A: ['E'], B: ['W'] }), 'L2 opposing light cases must require changed placement');
check(!optics(shade, [shade.poses.S], shade.lights.A).viewClear, 'L2 front board should visibly obstruct the camera');
check(!lightSolutions.A.some(pose => lightSolutions.B.includes(pose)), 'L2 one board must not accidentally solve the fixed two-sided final');

const order = level('L3').model;
const stateKey = state => `${state.pose}:${state.railIndex}`;
function deliveredAndClear(state) {
  const result = optics(order, [order.poses[state.pose]], order.light);
  return state.railIndex === order.rail.length - 1 && result.shaded && result.viewClear;
}
function transitions(state, fixedPose = false) {
  const results = [];
  if (!fixedPose) {
    const nextPose = state.pose === 'shade' ? 'park' : 'shade';
    const panel = order.poses[state.pose], nextPanel = order.poses[nextPose];
    const displacement = subtract(nextPanel[0], panel[0]);
    const carriage = order.rail[state.railIndex];
    if (!sweepHitsPanel(carriage, subtract(carriage, displacement), panel, order.carriageRadius)) {
      results.push({ action: nextPose, state: { ...state, pose: nextPose } });
    }
  }
  for (const step of [1, -1]) {
    const to = state.railIndex + step;
    if (to < 0 || to >= order.rail.length) continue;
    if (sweepHitsPanel(order.rail[state.railIndex], order.rail[to], order.poses[state.pose], order.carriageRadius)) continue;
    results.push({ action: step > 0 ? 'advance' : 'reverse', state: { ...state, railIndex: to } });
  }
  return results;
}
function search(start, fixedPose = false) {
  const queue = [{ state: start, path: [] }], seen = new Map([[stateKey(start), start]]);
  let witness = null;
  for (let i = 0; i < queue.length; i++) {
    const { state, path } = queue[i];
    if (deliveredAndClear(state) && witness === null) witness = [...path, 'trial'];
    for (const next of transitions(state, fixedPose)) {
      if (seen.has(stateKey(next.state))) continue;
      seen.set(stateKey(next.state), next.state);
      queue.push({ state: next.state, path: [...path, next.action] });
    }
  }
  return { states: [...seen.values()], witness };
}
const orderSearch = search(order.initial);
check(orderSearch.witness !== null, 'L3 must have a legal solution');
check(search(order.initial, true).witness === null, 'L3 cannot be solved by feeding through the closed panel');
check(search({ pose: 'park', railIndex: 0 }, true).witness === null, 'L3 leaving the panel parked should fail the image condition');
for (const state of orderSearch.states) {
  check(search(state).witness !== null, `L3 soft lock at ${stateKey(state)}`);
}

const stable = level('L4').model;
function combinations(values, maxCount) {
  const result = [[]];
  for (const value of values) for (const prior of result.slice()) {
    if (prior.length < maxCount) result.push([...prior, value]);
  }
  return result;
}
const layouts = combinations(Object.keys(stable.slots), stable.panelCount);
function assessLayout(model, slots) {
  const panels = slots.map(slot => model.slots[slot]);
  const cases = Object.fromEntries(Object.entries(model.lights).map(([id, light]) => [id, optics(model, panels, light)]));
  const feedClear = panels.every(panel => !sweepHitsPanel(model.feed[0], model.feed[1], panel, model.carriageRadius));
  return { slots, cases, feedClear, pass: feedClear && Object.values(cases).every(result => result.shaded && result.viewClear) };
}
const stableResults = layouts.map(slots => assessLayout(stable, slots));
const stableSolutions = stableResults.filter(result => result.pass);
check(layouts.length === 11, 'L4 enumeration must include empty, single and two-panel states');
check(stableSolutions.length === 1 && stableSolutions[0].slots.join(',') === 'E,W', 'L4 expected opposing-side solution is missing or bypassed');
check(!assessLayout(stable, ['N']).feedClear, 'L4 rear panel must block physical feeding');
check(!assessLayout(stable, ['S']).cases.A.viewClear, 'L4 front panel must block camera visibility');
// The transfer changes the fixture, not the map or the slot identity test.
const rotate = ([x, y]) => [-y, x];
const rotated = { ...stable, camera: rotate(stable.camera), lights: Object.fromEntries(Object.entries(stable.lights).map(([k, p]) => [k, rotate(p)])), feed: stable.feed.map(rotate) };
const rotatedSolutions = layouts.filter(slots => assessLayout(rotated, slots).pass);
check(rotatedSolutions.length === 1 && rotatedSolutions[0].join(',') === 'N,S', 'Rotating the fixture must transfer the geometry rule');

// Proposed receipt policy, evaluated here as a design counterexample only.
// In the game, receipt creation must be controller-owned after real trials.
const current = { assemblyId: 'demo-kit', configurationRevision: 4, fixtureRevision: 2 };
const receipt = (condition, override = {}) => ({ ...current, condition, passed: true, ...override });
function accepts(records, feedPassed, viewClear) {
  if (!feedPassed || !viewClear) return false;
  return stable.requiredConditions.every(condition => records.some(record =>
    record.passed && record.condition === condition &&
    record.assemblyId === current.assemblyId &&
    record.configurationRevision === current.configurationRevision &&
    record.fixtureRevision === current.fixtureRevision));
}
const receiptScenarios = [
  ['same setup, both cases', [receipt('A'), receipt('B')], true, true, true],
  ['two different configurations', [receipt('A', { configurationRevision: 3 }), receipt('B')], true, true, false],
  ['old camera/light fixture', [receipt('A', { fixtureRevision: 1 }), receipt('B')], true, true, false],
  ['different portable kit', [receipt('A', { assemblyId: 'other-kit' }), receipt('B')], true, true, false],
  ['same case repeated', [receipt('A'), receipt('A')], true, true, false],
  ['failed case', [receipt('A'), receipt('B', { passed: false })], true, true, false],
  ['observation only', [], true, true, false],
  ['cancelled before second result', [receipt('A')], true, true, false],
  ['feeding blocked', [receipt('A'), receipt('B')], false, true, false],
  ['camera blocked', [receipt('A'), receipt('B')], true, false, false]
].map(([name, records, feed, view, expected]) => {
  const actual = accepts(records, feed, view);
  check(actual === expected, `Completion policy: ${name}`);
  return { name, expected, actual };
});

const report = {
  schema: '755.flc.puzzle-design-verification.v1',
  status: 'finite_design_model_passed_not_runtime_acceptance',
  generatedAt: new Date().toISOString(),
  baselineCommit: spec.baselineCommit,
  designSha256: digest(raw), sourceLedgerSha256: digest(sourcesRaw), sourceHashes,
  assertions, anchorReferences: anchors, selectedTranscriptFilesChecked: transcriptHashChecks,
  L1: { method: 'static summary pinned to inspected source hash; no Godot execution', configurations: driveStates, solutions: driveSolutions, returnTargetNotImplementedOrVerified: true },
  L2: { configurationsPerLight: Object.keys(shade.poses).length, cases: lightSolutions, results: shadeResults },
  L3: { reachableStates: orderSearch.states.length, statesWithPathToGoalWithoutReset: orderSearch.states.length, shortestWitnessIncludingTrial: orderSearch.witness, permanentlyClosedFails: true, permanentlyParkedFails: true },
  L4: { configurations: layouts.length, solutions: stableSolutions.map(result => result.slots), rotatedFixtureSolutions: rotatedSolutions, results: stableResults },
  receiptScenarios,
  limits: spec.limits,
  unverified: ['actual room placement', 'Godot input and collision', 'continuous or height-dependent optics', 'NPC navigation', 'undo and persisted state implementation', 'chapter integration', 'human clarity and playtime', 'voice delivery']
};
if (process.argv.includes('--write')) {
  await writeFile(new URL('design/verification.json', campus), JSON.stringify(report, null, 2) + '\n');
}
console.log(JSON.stringify({ status: report.status, assertions, anchorReferences: anchors, transcriptFilesChecked: transcriptHashChecks, L1Configurations: driveStates, L2Cases: lightSolutions, L3ReachableStates: orderSearch.states.length, L3Witness: orderSearch.witness, L4Solutions: report.L4.solutions, receiptCases: receiptScenarios.length, report: process.argv.includes('--write') ? fileURLToPath(new URL('design/verification.json', campus)) : 'not written; pass --write to regenerate' }, null, 2));
