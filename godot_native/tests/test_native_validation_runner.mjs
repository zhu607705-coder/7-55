import test from 'node:test';
import assert from 'node:assert/strict';
import fs from 'node:fs';
import os from 'node:os';
import path from 'node:path';
import {spawnSync} from 'node:child_process';
import {scheduleValidation} from '../tools/native_validation_scheduler.mjs';
import {createValidationCatalog, planValidation, PREFLIGHT, NORTH_TARGETED, FIXTURE_WRITERS} from '../tools/native_validation_plan.mjs';
import {snapshotPaths, validationIdentity, stageIdentity, fixtureIdentity, canReuse, PRODUCER_OUTPUTS, inheritedTestOverrides, completedStageIdentity} from '../tools/native_validation_identity.mjs';
const project = path.resolve(import.meta.dirname, '..');
const catalog = createValidationCatalog(project, '/fake/godot');
const item = (id, exclusive = false) => ({id, exclusive});
const tick = async () => {for (let i = 0; i < 20; i++) await Promise.resolve();};
function controlled() {
 const active = new Set(), starts = [], pending = new Map(); let peak = 0;
 return {active, starts, pending, get peak() {return peak;}, run: async stage => {
  active.add(stage.id); starts.push(stage.id); peak = Math.max(peak, active.size);
  if (stage.exclusive) assert.equal(active.size, 1, 'exclusive writer owns the whole project');
  const result = await new Promise((resolve, reject) => pending.set(stage.id, {resolve, reject}));
  active.delete(stage.id); return result;
 }};
}
test('continuous workers fill a released slot before an earlier slow reader ends', async () => {
 const c = controlled(); const done = scheduleValidation(['a','b','c','d'].map(id => item(id)), {jobs: 2, run: c.run});
 await tick(); assert.deepEqual(c.starts, ['a','b']);
 c.pending.get('b').resolve(true); await tick(); assert.deepEqual(c.starts, ['a','b','c']);
 assert.ok(c.active.has('a')); c.pending.get('c').resolve(true); await tick(); assert.deepEqual(c.starts, ['a','b','c','d']);
 c.pending.get('a').resolve(true); c.pending.get('d').resolve(true); const results = await done;
 assert.equal(c.peak, 2); assert.ok([...results.values()].every(r => r.status === 'pass'));
});
test('writers drain preceding readers, stay ordered, and exclude following readers', async () => {
 const c = controlled(); const done = scheduleValidation([item('a'),item('b'),item('writer1',true),item('writer2',true),item('c')], {jobs: 2, run: c.run});
 await tick(); c.pending.get('b').resolve(true); await tick(); assert.deepEqual(c.starts, ['a','b']);
 c.pending.get('a').resolve(true); await tick(); assert.deepEqual(c.starts, ['a','b','writer1']);
 c.pending.get('writer1').resolve(true); await tick(); assert.deepEqual(c.starts, ['a','b','writer1','writer2']);
 c.pending.get('writer2').resolve(true); await tick(); assert.deepEqual(c.starts, ['a','b','writer1','writer2','c']);
 c.pending.get('c').resolve(true); await done;
});
test('ordinary failure continues independent coverage; fail-fast drains in-flight work only', async () => {
 const events = [];
 const results = await scheduleValidation([item('bad'),item('ok'),item('writer',true)], {jobs: 2, run: async s => {events.push(s.id); return s.id !== 'bad';}});
 assert.equal(results.get('bad').status, 'failed'); assert.deepEqual(events, ['bad','ok','writer']);
 const c = controlled(); const done = scheduleValidation([item('a'),item('b'),item('c'),item('writer',true)], {jobs: 2, stopOnFailure: true, run: c.run});
 await tick(); c.pending.get('a').resolve(false); await tick(); assert.deepEqual(c.starts, ['a','b']);
 c.pending.get('b').resolve(true); const stopped = await done;
 assert.equal(stopped.get('c').status, 'not-run'); assert.equal(stopped.get('writer').status, 'not-run');
});
test('thrown runner errors drain current readers and do not launch later writers', async () => {
 const c = controlled(); const error = Error('spawn fault');
 const done = scheduleValidation([item('a'),item('b'),item('writer',true)], {jobs: 2, run: c.run});
 const rejected = assert.rejects(done, /spawn fault/);
 await tick(); c.pending.get('a').reject(error); await tick(); assert.deepEqual(c.starts, ['a','b']);
 c.pending.get('b').resolve(true); await rejected;
});
test('caps 1..4 are enforced and invalid caps are rejected', async () => {
 for (const jobs of [1,2,3,4]) {
  let active = 0, peak = 0;
  await scheduleValidation(Array.from({length: 12}, (_, i) => item(String(i))), {jobs, run: async () => {peak = Math.max(peak, ++active); await tick(); active--;}});
  assert.equal(peak, jobs);
 }
 for (const jobs of [0,5,1.5,NaN]) await assert.rejects(scheduleValidation([], {jobs, run() {}}), /1..4/);
});
test('formal north profiles select exact IDs with mandatory preflight, never BUCT north', () => {
 const targeted = planValidation(catalog, {profile: 'north-targeted'});
 assert.deepEqual(targeted.stages.map(s => s.id), [...PREFLIGHT, ...NORTH_TARGETED]);
 const affected = planValidation(catalog, {profile: 'north'});
 assert.ok(affected.stages.some(s => s.id === 'test_interior_door_collision.gd'));
 assert.ok(!affected.stages.some(s => s.id.includes('buct')));
 assert.ok(affected.rows.every(r => r.status === 'not-run')); assert.equal(affected.partial, true);
});
test('source oracle and early alphabetical consumers close producers before readers', () => {
 for (const id of ['Source oracle tests/verify_source_model_parity.mjs', 'Source oracle tests/verify_canteen_defense_source.mjs', 'test_bike_chase_arrival.gd', 'smoke_canteen_defense_ui.gd', 'test_chapter3.gd', 'test_lake_live_world.gd']) {
  const plan = planValidation(catalog, {profile: 'changed', tests: [id]});
  const ids = plan.stages.map(s => s.id), stage = catalog.find(s => s.id === id);
  for (const dep of stage.dependencies) assert.ok(ids.indexOf(dep) >= 0 && ids.indexOf(dep) < ids.indexOf(id), `${dep} before ${id}`);
 }
 const full = planValidation(catalog);
 const selectedWriters = full.stages.filter(s => FIXTURE_WRITERS.includes(s.id));
 assert.deepEqual(selectedWriters.map(s => s.id), FIXTURE_WRITERS);
 assert.ok(selectedWriters.every(s => s.exclusive));
});
test('failed producers block dependent consumers rather than blessing stale outputs', async () => {
 const plan = planValidation(catalog, {profile: 'changed', tests: ['test_chapter3.gd']});
 const states = new Map(), executed = [];
 await scheduleValidation(plan.stages, {jobs: 2, run: async stage => {
  if (stage.dependencies.some(id => states.get(id) !== 'pass')) {states.set(stage.id, 'blocked'); return false;}
  executed.push(stage.id); const passed = stage.id !== 'test_minigame_models.gd'; states.set(stage.id, passed ? 'pass' : 'failed'); return passed;
 }});
 assert.equal(states.get('test_chapter3.gd'), 'blocked'); assert.ok(!executed.includes('test_chapter3.gd'));
});
test('shared world/state/save and unknown changes conservatively escalate full', () => {
 for (const file of ['godot_native/scripts/world.gd','godot_native/scripts/state.gd','src/core/SaveStore.ts','unknown/new-runtime.gd','godot_native/tests/new_helper.gd','godot_native/tests/helpers/test_world.gd','godot_native/docs/art/art_direction_v1.json']) {
  const plan = planValidation(catalog, {profile: 'changed', changedFiles: [file]});
  assert.equal(plan.effectiveProfile, 'full'); assert.equal(plan.stages.length, catalog.length);
 }
 const narrow = planValidation(catalog, {profile: 'changed', changedFiles: ['godot_native/scripts/objects/north_prop_scene.gd']});
 assert.equal(narrow.partial, true); assert.ok(narrow.stages.some(s => s.id === 'test_world.gd'));
 assert.throws(() => planValidation(catalog, {profile: 'changed'}), /requires/);
 assert.throws(() => planValidation(catalog, {profile: 'changed', tests: ['north']}), /exact stage/);
});
test('raw filter stays diagnostic and cannot claim dependency closure/full completion', () => {
 const p = planValidation(catalog, {filter: /^Source oracle tests\/verify_source_model_parity\.mjs$/});
 assert.equal(p.stages.length, 1); assert.equal(p.partial, true); assert.equal(p.effectiveProfile, 'raw-diagnostic');
 assert.throws(() => planValidation(catalog, {profile: 'north', filter: /north/}), /raw diagnostic/);
});
test('plan/list require no prepared assets, Godot process or writable cache', () => {
 const r = spawnSync(process.execPath, [path.join(project, 'tools/validate_native.mjs'), '--profile','north-targeted','--plan'], {encoding: 'utf8', env: {...process.env, GODOT_BIN: '/does/not/exist'}});
 assert.equal(r.status, 0, r.stderr); const p = JSON.parse(r.stdout);
 assert.equal(p.stages.length, 9); assert.ok(p.stages.every(s => s.status === 'not-run'));
});
test('exact input identity detects edits, new untracked inputs, environment, tool, and producer changes', () => {
 const root = fs.mkdtempSync(path.join(os.tmpdir(), '755-identity-test-'));
 try {
  assert.equal(spawnSync('git', ['init', '-q', root]).status, 0);
  const binary = path.join(root, 'fake-godot'); fs.writeFileSync(binary, '#!/bin/sh\nprintf "4.7.1.test\\n"\n', {mode: 0o755});
  fs.writeFileSync(path.join(root, 'source.gd'), 'original');
  const env = {PATH: process.env.PATH, LANG: 'C'};
  const snapshot = () => validationIdentity(root, {executable: binary, jobs: 2, env});
  const original = snapshot(); assert.equal(snapshot().sha256, original.sha256);
  fs.writeFileSync(path.join(root, 'new-helper.gd'), 'new untracked'); assert.notEqual(snapshot().sha256, original.sha256); fs.unlinkSync(path.join(root, 'new-helper.gd'));
  fs.writeFileSync(path.join(root, 'source.gd'), 'changed'); assert.notEqual(snapshot().sha256, original.sha256); fs.writeFileSync(path.join(root, 'source.gd'), 'original');
  assert.notEqual(validationIdentity(root, {executable: binary, jobs: 2, env: {...env, SOME_OPTION: '1'}}).sha256, original.sha256);
  fs.appendFileSync(binary, '# binary changed\n'); assert.notEqual(snapshot().sha256, original.sha256);
  const stage = {id: 'test_minigame_models.gd', command: binary, args: ['--headless']};
  const beforeFixture = fixtureIdentity(root, stage.id);
  const key = stageIdentity(original, stage, beforeFixture);
  assert.ok(canReuse({result: 'pass', failed: false, identity: key}, key));
  assert.equal(canReuse({label: stage.id, failed: false}, key), false, 'old label-only evidence rejected');
  assert.equal(canReuse({result: 'failed', failed: true, identity: key}, key), false);
  assert.notEqual(stageIdentity(original, {...stage, args: ['--different']}, beforeFixture), key);
  const output = path.join(root, PRODUCER_OUTPUTS[stage.id][0]); fs.mkdirSync(path.dirname(output), {recursive: true}); fs.writeFileSync(output, 'new producer bytes');
  assert.notEqual(stageIdentity(original, stage, fixtureIdentity(root, stage.id)), key, 'stale/missing producer output cannot reuse');
  const p = snapshotPaths(root, ['source.gd']); fs.chmodSync(path.join(root, 'source.gd'), 0o755); assert.notEqual(snapshotPaths(root, ['source.gd']).sha256, p.sha256);
 } finally {fs.rmSync(root, {recursive: true, force: true});}
});
test('catalog preserves every original native regression ID exactly once', () => {
 assert.equal(new Set(catalog.map(s => s.id)).size, catalog.length);
 const expected = fs.readdirSync(path.join(project, 'tests')).filter(f => f.endsWith('.gd') && f !== 'test_save_migration.gd' && /^(?:test_|smoke_)/.test(f));
 assert.deepEqual(catalog.filter(s => s.id.endsWith('.gd')).map(s => s.id).sort(), expected.sort());
});

test('external fixture paths cannot authorize resume by stable path spelling', () => {
 const names = ['WORLD_SCRIPT_PATH','LAMP_SOURCE_FRAMES','C1_LEGACY_VALIDATOR','C1_SAVE_SOURCE','CANTEEN_SOURCE_ROOT','SOURCE_REPO_ROOT'];
 for (const name of names) {
  assert.ok(inheritedTestOverrides(path.dirname(project), {[name]: '/tmp/mutable-input'}).includes(name), name);
  const r = spawnSync(process.execPath, [path.join(project,'tools/validate_native.mjs'),'--resume','--filter','^Native save isolation$'], {
   encoding:'utf8', env:{...process.env, [name]:'/tmp/mutable-input', GODOT_TEST_REPORT:'/tmp/nonexistent-external-override-report.json'}
  });
  assert.notEqual(r.status,0); assert.match(r.stderr,/Resume refused with external/); assert.ok(r.stderr.includes(name));
 }
 assert.deepEqual(inheritedTestOverrides(path.dirname(project), {CI:'true',GITHUB_EVENT_NAME:'pull_request',GITHUB_RUN_ATTEMPT:'1',GITHUB_RUN_ID:'123',GITHUB_SHA:'a'.repeat(40),GITHUB_OUTPUT:'/tmp/step-output',GITHUB_ENV:'/tmp/github-env',GITHUB_PATH:'/tmp/github-path',GITHUB_STEP_SUMMARY:'/tmp/step-summary'}), []);
 assert.deepEqual(inheritedTestOverrides(path.dirname(project), {CODEX_PRIMARY_RUNTIME_ROOT:'/opt/runtime', BROWSER_MANAGEMENT_SOCKET_PATH:'/tmp/socket'}), []);
});

test('hosted browser/account defaults do not serialize native readers or hide real overrides', () => {
 const env = {CI:'true',USER:'runner',CHROME_BIN:'/usr/bin/google-chrome',BUCT_V4_QA_DIR:'/tmp/native-qa',GODOT_TEST_REPORT:'/tmp/native-report.json'};
 assert.deepEqual(inheritedTestOverrides(path.dirname(project), env), []);
 for (const name of ['WORLD_SCRIPT_PATH','LAMP_SOURCE_FRAMES','CANTEEN_SOURCE_ROOT','SOURCE_REPO_ROOT']) {
  assert.deepEqual(inheritedTestOverrides(path.dirname(project), {...env,[name]:'/tmp/mutable-input'}), [name]);
 }
});

test('workspace lock excludes a second process and can be released without stale ownership', async () => {
 const {acquireNativeWorkspaceLock} = await import('../tools/native_validation_lock.mjs');
 const temporary = fs.mkdtempSync(path.join(os.tmpdir(),'755-lock-test-'));
 try {
  const release = acquireNativeWorkspaceLock(temporary,'first');
  const child = spawnSync(process.execPath,['--input-type=module','-e',`import {acquireNativeWorkspaceLock} from ${JSON.stringify(path.join(project,'tools/native_validation_lock.mjs'))}; acquireNativeWorkspaceLock(${JSON.stringify(temporary)},'second');`],{encoding:'utf8'});
  assert.notEqual(child.status,0); assert.match(child.stderr,/workspace is busy/);
  release(); const releaseAgain = acquireNativeWorkspaceLock(temporary,'after release'); releaseAgain();
  assert.equal(fs.existsSync(path.join(temporary,'.validation/runner.lock')),false);
 } finally {fs.rmSync(temporary,{recursive:true,force:true});}
});

test('reader evidence cannot be rebound to fixture bytes changed during execution', () => {
 const identity={sha256:'source-identity'};
 const reader={id:'test_bike_chase_arrival.gd',command:'godot',args:['--headless']};
 assert.throws(()=>completedStageIdentity(identity,reader,'old-fixtures','new-fixtures'),/Fixture inputs changed/);
 assert.equal(completedStageIdentity(identity,reader,'same','same'),stageIdentity(identity,reader,'same'));
 const producer={...reader,id:'test_minigame_models.gd'};
 assert.equal(completedStageIdentity(identity,producer,'before','produced'),stageIdentity(identity,producer,'produced'));
});
