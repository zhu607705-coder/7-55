// Execute source-extracted shipped runner blocks with cached-snapshot sequences.
// Synthetic Node evidence only: no Chrome, Godot, network, save writes or CDP input.
import assert from 'node:assert/strict';
import { readFile } from 'node:fs/promises';
import vm from 'node:vm';
import { test } from 'node:test';
import { waitForBrightnessControl } from '../tools/web_phone_recovery.mjs';

const runner = await readFile(new URL('../tools/verify_web_export.mjs', import.meta.url), 'utf8');
const phone = await readFile(new URL('../tools/web_phone_recovery.mjs', import.meta.url), 'utf8');
const workflow = await readFile(new URL('../../.github/workflows/deploy-pages.yml', import.meta.url), 'utf8');
function between(source, begin, end) {
  const start = source.indexOf(begin), stop = source.indexOf(end, start + begin.length);
  assert(start >= 0 && stop > start, `actual source block: ${begin}`);
  return source.slice(start, stop);
}
const pollSource = between(runner, 'async function poll(', 'async function shaFile(');
const checkSource = between(runner, 'function check(', 'async function persist(');
const sampleSource = between(runner, 'async function mobileSample(', 'async function worldTouches(');
const stoppedSource = between(runner, 'async function assertWorldStopped(', 'async function assertBottomPlaque(');
const factsSource = runner.split('\n').find(line => line.startsWith('const mobileFacts ='));
assert(factsSource);
const claimSource = between(phone, "  await click('HomeWeatherOpen'); await click('WeatherWaterCard');", "  await shot('tiyi-weather-rain');");

const copy = value => structuredClone(value);
function brightnessSample(frame, edit = () => {}) {
  const value = { sampleFrame: frame, documentHidden: false, viewport: { width: 390, height: 844 }, visibleControls: [{ name: 'ControlBrightness', disabled: false, rect: { x: 307, y: 117, width: 57, height: 104 } }] };
  edit(value); return value;
}
function brightnessFixture(sequence) {
  let clock = 0, reads = 0;
  const poll = vm.runInNewContext(`${pollSource}\npoll`, { Date: { now: () => clock }, interval: async ms => { clock += ms; } });
  const h = { poll, snapshot: async () => copy(sequence[Math.min(reads++, sequence.length - 1)]) };
  return { h, get clock() { return clock; }, get reads() { return reads; } };
}
test('brightness waits through cached and not-yet-laid-out frames before using native geometry', async () => {
  const f = brightnessFixture([brightnessSample(10), brightnessSample(11, s => { s.visibleControls = []; }), brightnessSample(12, s => { s.visibleControls[0].rect.height = 0; }), brightnessSample(13)]);
  const result = await waitForBrightnessControl(f.h, 10);
  assert.equal(result.value.sampleFrame, 13); assert.equal(f.reads, 4); assert.equal(f.clock, 300);
  assert.deepEqual(result.slider.rect, { x: 307, y: 117, width: 57, height: 104 });
});
for (const [name, edit] of [
  ['missing', s => { s.visibleControls = []; }],
  ['duplicate', s => { s.visibleControls.push(copy(s.visibleControls[0])); }],
  ['disabled', s => { s.visibleControls[0].disabled = true; }],
  ['zero size', s => { s.visibleControls[0].rect.height = 0; }],
  ['invalid size', s => { s.visibleControls[0].rect.width = NaN; }],
  ['offscreen', s => { s.visibleControls[0].rect.x = 390; }],
  ['hidden document', s => { s.documentHidden = true; }],
  ['cached frame', s => { s.sampleFrame = 10; }],
]) {
  test(`brightness ${name} cannot produce guessed coordinates and expires within the original 20 seconds`, async () => {
    const f = brightnessFixture([brightnessSample(11, edit)]);
    await assert.rejects(waitForBrightnessControl(f.h, 10), /Timeout: fresh native brightness control/);
    assert.equal(f.clock, 20000); assert.equal(f.reads, 200);
  });
}
function worldSample(frame, edit = () => {}) {
  const value = { sampleFrame: frame, state: { native: { chapter: 2, scene: 'dorm_hub', dorm_props: { lamp_03_on: true } }, actOne: { phase: 'movement_ready' }, items: { campusCard: true }, wallet: { balance: 6 } }, world: { scene_id: 'dorm_hub', visible: true, player: { x: 100, y: 200 }, touch_axis: { x: 0, y: 0 }, input: { owners: [], mouseOwned: false, inventoryOwned: false, dormPropActions: 1 } } };
  edit(value); return value;
}
function fixture(sequence) {
  let clock = 0, reads = 0, inputCalls = 0;
  const delays = [], checks = [], samples = [], clicks = [], labels = [];
  const next = async () => copy(sequence[Math.min(reads++, sequence.length - 1)]);
  const context = { Date: { now: () => clock }, Math,
    interval: async delay => { delays.push(delay); clock += delay; },
    snapshot: next, state: value => value?.state,
    report: { checks }, active: { id: 'retina-touch-390', mobileWorld: { samples }, cdp: { send: () => { inputCalls++; throw Error('unexpected duplicate input'); } } },
    click: async name => { clicks.push(name); },
    read: async label => { if (label) labels.push(label); return next(); },
  };
  const helpers = vm.runInNewContext(`${pollSource}\n${checkSource}\nconst mobileDistance=(a,b)=>Math.hypot(a.x-b.x,a.y-b.y);\n${factsSource}\n${sampleSource}\n${stoppedSource}\nconst h={poll,check,id:active.id};\nasync function weatherClaim(){let value;\n${claimSource}\nreturn value;}\n({assertWorldStopped,weatherClaim})`, context);
  return { ...helpers, checks, samples, clicks, labels, delays, get clock() { return clock; }, get reads() { return reads; }, get inputCalls() { return inputCalls; } };
}
const before = () => worldSample(10, value => { value.world.input.inventoryOwned = true; });

test('active Godot Web workflow runs these completion regressions', () => {
  assert.match(workflow, /^\s+node godot_native\/tests\/test_web_input_completion\.mjs\s*$/m);
});

test('world: cached and newer-but-unsettled frames do not acknowledge cancellation', async () => {
  const f = fixture([before(), worldSample(11, s => { s.world.input.inventoryOwned = true; }), worldSample(12), worldSample(13)]);
  const result = await f.assertWorldStopped(before(), 'inventory cancellation');
  assert.equal(result.sampleFrame, 13);
  assert.deepEqual(f.samples.map(s => s.sampleFrame), [12, 13]);
  assert.equal(f.checks.length, 3); assert(f.checks.every(row => row.ok));
  assert.match(f.checks[0].label, /clears pointer owners and axis/);
  assert.match(f.checks[1].label, /stays released in a later engine sample/);
  assert.match(f.checks[2].label, /does not leave stuck movement/);
  assert.deepEqual(f.delays, [100, 100, 500]);
  assert.equal(f.inputCalls, 0);
});

for (const [name, edit] of [
  ['inventory owner', s => { s.world.input.inventoryOwned = true; }],
  ['world owner', s => { s.world.input.owners = [{ index: 1, role: 'stick' }]; }],
  ['mouse owner', s => { s.world.input.mouseOwned = true; }],
  ['nonzero axis', s => { s.world.touch_axis.x = .5; }],
  ['axis exactly at original threshold', s => { s.world.touch_axis.x = .001; }],
  ['only an old completed snapshot', s => { s.sampleFrame = 10; }],
  ['wrong chapter', s => { s.state.native.chapter = 3; }],
  ['wrong native scene', s => { s.state.native.scene = 'campus_bootstrap'; }],
  ['wrong world scene', s => { s.world.scene_id = 'campus_bootstrap'; }],
  ['world has been hidden', s => { s.world.visible = false; }],
]) {
  test(`world: ${name} never settles and fails within the original 5-second budget`, async () => {
    const f = fixture([worldSample(11, edit)]);
    await assert.rejects(f.assertWorldStopped(before(), 'inventory cancellation'), /Timeout:.*completed in the current world/);
    assert.equal(f.clock, 5000); assert.equal(f.reads, 50);
    assert.equal(f.samples.length, 0); assert.equal(f.checks.length, 0);
    assert.equal(f.inputCalls, 0); assert(!f.delays.includes(500));
  });
}

test('world: wrong-context settled frame cannot win over a later correct completion', async () => {
  const f = fixture([worldSample(11, s => { s.state.native.chapter = 3; }), worldSample(12), worldSample(13)]);
  await f.assertWorldStopped(before(), 'inventory cancellation');
  assert.deepEqual(f.samples.map(s => s.sampleFrame), [12, 13]);
  assert.equal(f.inputCalls, 0);
});
test('world: malformed snapshot is not a successful cancellation', async () => {
  const f = fixture([null, {}, worldSample(12), worldSample(13)]);
  await f.assertWorldStopped(before(), 'inventory cancellation');
  assert.deepEqual(f.samples.map(s => s.sampleFrame), [12, 13]);
});
test('world: the existing 500ms player-stability assertion remains a failure gate', async () => {
  const f = fixture([worldSample(11), worldSample(12, s => { s.world.player.x += .5; })]);
  await assert.rejects(f.assertWorldStopped(before(), 'inventory cancellation'), /does not leave stuck movement/);
  assert.equal(f.checks[0].ok, true); assert.equal(f.checks[1].ok, true); assert.equal(f.checks[2].ok, false);
  assert.deepEqual(f.delays, [500]); assert.equal(f.inputCalls, 0);
});
test('world: a later resurfaced owner still fails the upstream continuous-release gate', async () => {
  const f = fixture([worldSample(11), worldSample(12, s => { s.world.input.owners = [{index: 1, role: 'camera'}]; })]);
  await assert.rejects(f.assertWorldStopped(before(), 'inventory cancellation'), /stays released in a later engine sample/);
  assert.equal(f.checks[0].ok, true); assert.equal(f.checks[1].ok, false);
  assert.deepEqual(f.delays, [500]); assert.equal(f.inputCalls, 0);
});
test('world: current original sub-threshold axis tolerance remains accepted', async () => {
  const f = fixture([worldSample(11, s => { s.world.touch_axis.x = .0009; }), worldSample(12)]);
  await f.assertWorldStopped(before(), 'inventory cancellation');
  assert(f.checks.every(row => row.ok));
});
for (const label of ['settings modal before finger release', 'journal modal before finger release', 'orientation resize before finger release']) {
  test(`world: ${label} retains the same world context after its observed transition`, async () => {
    const previous = before();
    previous.world.input.modalVisible = label.includes('modal');
    previous.viewport = { width: 390, height: 844 };
    const next = worldSample(11, s => {
      s.world.input.modalVisible = previous.world.input.modalVisible;
      s.viewport = { width: 844, height: 390 };
      s.world.rect = { x: 10, y: 66, width: 824, height: 240 };
    });
    const after = copy(next); after.sampleFrame = 12;
    const f = fixture([next, after]);
    await f.assertWorldStopped(previous, label);
    assert(f.checks.every(row => row.ok)); assert.equal(f.inputCalls, 0);
  });
}

function weatherSample(edit = () => {}) {
  const value = { state: { native: { chapter: 2, page: 'weather' }, actOne: { exerciseStarted: true, weatherWaterTaken: true }, items: { weatherWater: true } } };
  edit(value); return value;
}
const expectedClicks = ['HomeWeatherOpen', 'WeatherWaterCard'];
test('weather: stale post-click state then both earned facts pass without replaying the tap', async () => {
  const f = fixture([weatherSample(s => { s.state.actOne.weatherWaterTaken = false; s.state.items.weatherWater = false; }), weatherSample()]);
  const result = await f.weatherClaim();
  assert.equal(result.state.actOne.weatherWaterTaken, true); assert.equal(result.state.items.weatherWater, true);
  assert.deepEqual(f.clicks, expectedClicks); assert.deepEqual(f.delays, [100]);
  assert.deepEqual(f.labels, ['C2 original weather rain earned after exercise']);
  assert.equal(f.checks.length, 1); assert.equal(f.checks[0].ok, true);
  assert.match(f.checks[0].label, /original weather drop remains gated behind actual exercise/);
});
for (const [name, edit] of [
  ['missing reward flag', s => { s.state.actOne.weatherWaterTaken = false; }],
  ['missing inventory item', s => { s.state.items.weatherWater = false; }],
  ['exercise not completed', s => { s.state.actOne.exerciseStarted = false; }],
  ['wrong chapter', s => { s.state.native.chapter = 1; }],
  ['wrong phone page', s => { s.state.native.page = 'tiyi'; }],
]) {
  test(`weather: ${name} fails with the original poll default, without another tap`, async () => {
    const f = fixture([weatherSample(edit)]);
    await assert.rejects(f.weatherClaim(), /Timeout: actual weather card claim after exercise completes/);
    assert.equal(f.clock, 20000); assert.equal(f.reads, 200);
    assert.deepEqual(f.clicks, expectedClicks); assert.equal(f.checks.length, 0);
    assert.equal(f.labels.length, 0); assert(f.delays.every(delay => delay === 100));
  });
}
test('weather: malformed snapshot cannot pass but a later real completion can', async () => {
  const f = fixture([null, {}, weatherSample()]);
  await f.weatherClaim(); assert.deepEqual(f.clicks, expectedClicks); assert.equal(f.checks[0].ok, true);
});
test('weather: original final assertion still rejects reward loss after the completion observation', async () => {
  const f = fixture([weatherSample(), weatherSample(s => { s.state.items.weatherWater = false; })]);
  await assert.rejects(f.weatherClaim(), /original weather drop remains gated behind actual exercise/);
  assert.deepEqual(f.clicks, expectedClicks); assert.equal(f.checks[0].ok, false);
});

// This runs the actual 022 handoff wait and Settings input, not a substitute
// State.act path. The mocked snapshots model the content coordinator's pause.
const libraryReadySource = between(runner, 'function libraryContentReady(', 'async function libraryCase(');
const libraryHandoffSource = between(runner, '  // State commits before required content finishes.', ' await saveProgressAndWait(`${active.id} library handoff`)');
const settingsSource = between(runner, 'async function settings()', 'async function importSave(');
function librarySample(edit = () => {}) {
  const value = { state: { native: { chapter: 3, scene: 'campus_bootstrap' }, ui: { libraryFinalsPhase: 'friend_contacted' }, canteenHunt: { active: true, phase: 'tracking' } },
    content: { enabled: true, monolithic: false, blocking: false, readyFamilies: ['chapter2', 'chapter3'] },
    world: { visible: true, scene_id: 'campus_bootstrap' }, visibleControls: [{ name: 'WorldPhoneButton', disabled: false }] };
  edit(value); return value;
}
function libraryFixture(sequence, settingsOpens = true) {
  let clock = 0, reads = 0;
  const keys = [], checks = [], delays = [];
  const context = { Date: { now: () => clock }, bootTimeout: 60000,
    interval: async delay => { delays.push(delay); clock += delay; },
    snapshot: async () => {
      if (keys.length) return { visibleControls: settingsOpens ? [{ text: '导入存档' }] : [] };
      return copy(sequence[Math.min(reads++, sequence.length - 1)]);
    },
    controls: value => value?.visibleControls || [], state: value => value?.state,
    press: async key => { keys.push({ key, at: clock }); }, report: { checks }, active: { id: 'touch-390' },
  };
  const run = vm.runInNewContext(`${pollSource}\n${checkSource}\n${settingsSource}\n${libraryReadySource}\n(async()=>{let value;${libraryHandoffSource}})`, context);
  return { run, keys, checks, delays, get clock() { return clock; }, get reads() { return reads; } };
}
test('library: actual content readiness precedes one F10; no fixed settling sleep', async () => {
  const f = libraryFixture([librarySample(s => { s.content.blocking = true; }), librarySample(s => { s.world.scene_id = 'library_interior'; }), librarySample()]);
  await f.run();
  assert.deepEqual(f.keys, [{ key: 'F10', at: 100 }]); assert.equal(f.reads, 3);
  assert.deepEqual(f.delays, [100]); assert.equal(f.checks.length, 1); assert(f.checks[0].ok);
});
for (const [name, edit] of [
  ['required content remains blocked', s => { s.content.blocking = true; }],
  ['C3 family not ready although not yet blocked', s => { s.content.readyFamilies = ['chapter2']; }],
  ['content status missing', s => { delete s.content; }],
  ['wrong chapter', s => { s.state.native.chapter = 2; }],
  ['old native scene', s => { s.state.native.scene = 'library_interior'; }],
  ['old rendered scene', s => { s.world.scene_id = 'library_interior'; }],
  ['world not visible', s => { s.world.visible = false; }],
  ['disabled phone control', s => { s.visibleControls[0].disabled = true; }],
  ['phone control absent', s => { s.visibleControls = []; }],
]) {
  test(`library: ${name} fails its bounded readiness phase with zero F10`, async () => {
    const f = libraryFixture([librarySample(edit)]);
    const loading = ['required content remains blocked', 'C3 family not ready although not yet blocked', 'content status missing'].includes(name);
    await assert.rejects(f.run(), loading ? /Timeout: library exit C3 content is ready/ : /Timeout: ordinary022 arrival hands off to ready campus and Chapter3/);
    assert.equal(f.clock, loading ? 60000 : 20000); assert.equal(f.reads, loading ? 600 : 201); assert.deepEqual(f.keys, []);
    assert.equal(f.checks.length, 0); assert(f.delays.every(delay => delay === 100));
  });
}
test('library: a cold download longer than 20s does not consume the UI handoff budget', async () => {
  const pending = Array.from({ length: 300 }, () => librarySample(s => { s.content.blocking = true; }));
  const f = libraryFixture([...pending, librarySample()]);
  await f.run();
  assert.deepEqual(f.keys, [{ key: 'F10', at: 30000 }]);
  assert.equal(f.checks.length, 1); assert(f.checks[0].ok);
});
test('library: ready monolithic content still uses the real input path', async () => {
  const f = libraryFixture([librarySample(s => { s.content = { monolithic: true, blocking: false }; })]);
  await f.run(); assert.deepEqual(f.keys, [{ key: 'F10', at: 0 }]);
});
test('library: failed Settings input is never resent and retains its own original 20s deadline', async () => {
  const f = libraryFixture([librarySample()], false);
  await assert.rejects(f.run(), /Timeout: settings opened/);
  assert.deepEqual(f.keys, [{ key: 'F10', at: 0 }]); assert.equal(f.clock, 20000);
});
