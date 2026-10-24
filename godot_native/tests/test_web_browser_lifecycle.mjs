// Actual runner helpers, synthetic lifecycle events, and ordinary Node children.
// No Chrome, display, Godot save, or browser acceptance is executed here.
import assert from 'node:assert/strict';
import { EventEmitter, once } from 'node:events';
import { spawn } from 'node:child_process';
import { readFile, mkdtemp, mkdir, rm, access, open } from 'node:fs/promises';
import path from 'node:path';
import { tmpdir } from 'node:os';
import vm from 'node:vm';
import { test, afterEach } from 'node:test';

const runner = await readFile(new URL('../tools/verify_web_export.mjs', import.meta.url), 'utf8');
const begin = runner.indexOf('function createBrowserLifecycle('), end = runner.indexOf('async function browserCase(', begin);
assert(begin > 0 && end > begin, 'extract the actual shipped runner helpers');
const timers = new Set();
const trackedTimeout = (callback, delay) => { const timer = setTimeout(() => { timers.delete(timer); callback(); }, delay); timers.add(timer); return timer; };
const trackedClear = timer => { timers.delete(timer); clearTimeout(timer); };
const helpers = vm.runInNewContext(`${runner.slice(begin, end)}\n({createBrowserLifecycle, cleanupBrowserLifecycle, finishBrowserCase})`, { path, tmpdir, rm, Date, setTimeout: trackedTimeout, clearTimeout: trackedClear });
const { createBrowserLifecycle, cleanupBrowserLifecycle, finishBrowserCase } = helpers;
afterEach(() => assert.equal(timers.size, 0, 'every lifecycle wait timer is cleared or expired'));
function fixture(onKill = () => {}, directory = path.join(tmpdir(), '755-godot-web-browser-mocked')) {
  const child = new EventEmitter(); child.pid = 12345; child.exitCode = null;
  const signals = [], removed = [];
  child.kill = signal => { signals.push(signal); onKill(signal, child); return true; };
  const lifecycle = createBrowserLifecycle(directory); lifecycle.attach(child);
  const close = () => { child.exitCode = 0; child.emit('exit', 0, null); child.emit('close', 0, null); };
  const remove = async (directory, options) => {
    assert(lifecycle.closed, 'a real close event must precede removal');
    assert.equal(directory, path.resolve(lifecycle.evidence.ownedTemp));
    assert.equal(options.recursive, true); assert.equal(options.force, true);
    assert.equal(options.maxRetries, 3); assert.equal(options.retryDelay, 100);
    removed.push(directory);
  };
  return { child, lifecycle, signals, removed, close, cleanupOptions: { remove, termWaitMs: 20, killWaitMs: 30 } };
}

test('same-tick listeners retain spawn, error, exit and close times and PID', async () => {
  const f = fixture();
  for (const type of ['spawn', 'error', 'exit', 'close']) assert.equal(f.child.listenerCount(type), 1);
  f.child.emit('spawn'); f.child.emit('error', Object.assign(new Error('test event'), { code: 'EIO' })); f.close();
  assert.deepEqual(Array.from(f.lifecycle.evidence.events, row => row.type), ['spawn', 'error', 'exit', 'close']);
  assert.equal(f.lifecycle.evidence.pid, 12345);
  assert(f.lifecycle.evidence.events.every(row => Number.isFinite(row.at) && row.at >= f.lifecycle.evidence.spawnRequestedAt));
  await cleanupBrowserLifecycle(f.lifecycle, f.cleanupOptions);
  assert.deepEqual(f.signals, []); assert.equal(f.removed.length, 1);
});
test('TERM waits for delayed close instead of racing directory removal', async () => {
  const f = fixture((signal, child) => { assert.equal(signal, 'SIGTERM'); setTimeout(() => child.emit('close', 0, null), 5); });
  await cleanupBrowserLifecycle(f.lifecycle, f.cleanupOptions);
  assert.deepEqual(f.signals, ['SIGTERM']); assert.equal(f.removed.length, 1);
  assert(f.lifecycle.evidence.closedAt <= f.lifecycle.evidence.cleanup.removeStartedAt);
});
test('exit is not close; retain the directory while stdio is still open', async () => {
  const f = fixture((signal, child) => { child.exitCode = 0; child.emit('exit', 0, null); setTimeout(() => child.emit('close', 0, null), 25); });
  const cleanup = cleanupBrowserLifecycle(f.lifecycle, f.cleanupOptions);
  assert.equal(f.removed.length, 0); assert.equal(f.lifecycle.closed, false);
  await cleanup;
  assert.deepEqual(f.signals, ['SIGTERM'], 'do not signal a PID that already exited');
  assert.equal(f.removed.length, 1);
});
test('ignored TERM escalates to KILL, then awaits close', async () => {
  const f = fixture((signal, child) => { if (signal === 'SIGKILL') setTimeout(() => child.emit('close', null, signal), 5); });
  await cleanupBrowserLifecycle(f.lifecycle, f.cleanupOptions);
  assert.deepEqual(f.signals, ['SIGTERM', 'SIGKILL']); assert.equal(f.removed.length, 1);
});
test('never-close is a bounded cleanup failure and never removes the profile', async () => {
  const f = fixture();
  await assert.rejects(cleanupBrowserLifecycle(f.lifecycle, f.cleanupOptions), /did not close/);
  assert.deepEqual(f.signals, ['SIGTERM', 'SIGKILL']); assert.equal(f.removed.length, 0);
  assert.match(f.lifecycle.evidence.cleanup.error.message, /retained/);
  assert.equal(f.lifecycle.evidence.cleanup.removedAt, undefined);
});
test('exit without close also fails closed instead of deleting a live stdio profile', async () => {
  const f = fixture(); f.child.emit('exit', 0, null);
  await assert.rejects(cleanupBrowserLifecycle(f.lifecycle, f.cleanupOptions), /did not close/);
  assert.deepEqual(f.signals, []); assert.equal(f.removed.length, 0);
});
test('spawn error is handled and recorded; later close permits owned cleanup', async () => {
  const f = fixture(); f.child.pid = undefined;
  f.child.emit('error', Object.assign(new Error('spawn ENOENT'), { code: 'ENOENT' }));
  f.child.emit('close', -2, null);
  await cleanupBrowserLifecycle(f.lifecycle, f.cleanupOptions);
  assert.equal(f.lifecycle.evidence.events[0].code, 'ENOENT'); assert.equal(f.removed.length, 1);
});
test('synchronous spawn failure has no child and can remove only its owned directory', async () => {
  const lifecycle = createBrowserLifecycle(path.join(tmpdir(), '755-godot-web-browser-unstarted'));
  lifecycle.evidence.spawnSynchronousError = 'invalid executable';
  let removed = false;
  await cleanupBrowserLifecycle(lifecycle, { remove: async () => { removed = true; } });
  assert(removed); assert.equal(lifecycle.child, null);
});
test('actual browserCase synchronous spawn exception still persists its primary evidence', async () => {
  const primary = new Error('synchronous spawn exception'), cases = []; let persisted, removed;
  const directory = path.join(tmpdir(), '755-godot-web-browser-sync-error');
  const bodyEnd = runner.indexOf('\ntry {\n  const selected =', end);
  assert(bodyEnd > end);
  const context = vm.createContext({ path, tmpdir, Date, setTimeout: trackedTimeout, clearTimeout: trackedClear, output: directory,
    open: async () => ({ fd: 2, close: async () => {} }), existsSync: () => false,
    mkdtemp: async () => directory, spawn: () => { throw primary; }, chrome: 'mock-not-launched', chromeArgs: [],
    rm: async target => { removed = target; }, report: { cases },
    snapshot: async () => { throw new Error('no CDP session'); },
    persist: async () => { persisted = JSON.parse(JSON.stringify(cases)); } });
  vm.runInContext(`${runner.slice(begin, end)}\nlet active;\n${runner.slice(end, bodyEnd)}`, context);
  await assert.rejects(context.browserCase('mock-case', 1, 1, false), error => error === primary);
  assert.equal(removed, directory); assert.equal(persisted[0].error, primary.stack);
  assert.equal(persisted[0].browserLifecycle.spawnSynchronousError, primary.message);
  assert.equal(persisted[0].passed, false);
});
test('owned-path guard rejects other roots and user profiles', async () => {
  for (const directory of [tmpdir(), path.join(tmpdir(), 'unrelated-profile'), path.join(tmpdir(), 'outside', '755-godot-web-browser-no')]) {
    const f = fixture(() => {}, directory); f.close();
    await assert.rejects(cleanupBrowserLifecycle(f.lifecycle, f.cleanupOptions), /Refusing cleanup/);
    assert.equal(f.removed.length, 0);
  }
});
test('rm failure is not ignored and its evidence includes the original code', async () => {
  const f = fixture(); f.close();
  const error = Object.assign(new Error('profile still not empty'), { code: 'ENOTEMPTY' });
  await assert.rejects(cleanupBrowserLifecycle(f.lifecycle, { ...f.cleanupOptions, remove: async () => { throw error; } }), value => value === error);
  assert.equal(f.lifecycle.evidence.cleanup.error.code, 'ENOTEMPTY');
});
test('functional error survives simultaneous cleanup failure and evidence is persisted', async () => {
  const f = fixture(); f.close(); const primary = new Error('real save timeout'), cleanup = Object.assign(new Error('cannot remove'), { code: 'ENOTEMPTY' });
  const caseRecord = { passed: false, error: primary.stack, saveAttempts: [{ token: 6, error: 'timeout' }] }; let persisted;
  const wrapped = async () => {
    try { throw primary; }
    finally { await finishBrowserCase({ lifecycle: f.lifecycle, caseRecord, primaryError: primary, cleanupOptions: { ...f.cleanupOptions, remove: async () => { throw cleanup; } }, persistEvidence: async () => { persisted = JSON.parse(JSON.stringify(caseRecord)); } }); }
  };
  await assert.rejects(wrapped(), value => value === primary);
  assert.equal(persisted.error, primary.stack); assert.equal(persisted.saveAttempts[0].token, 6);
  assert.equal(persisted.cleanupErrors[0].code, 'ENOTEMPTY'); assert.equal(persisted.passed, false);
});
test('cleanup-only failure keeps functional evidence but makes the gate fail', async () => {
  const f = fixture(); f.close(); const error = new Error('rm failed'); const caseRecord = { passed: true, saved: { actualHash: 'abc' } }; let persisted;
  await assert.rejects(finishBrowserCase({ lifecycle: f.lifecycle, caseRecord, cleanupOptions: { ...f.cleanupOptions, remove: async () => { throw error; } }, persistEvidence: async () => { persisted = JSON.parse(JSON.stringify(caseRecord)); } }), value => value === error);
  assert.equal(persisted.passed, false); assert.equal(persisted.functionalPassedBeforeCleanup, true); assert.equal(persisted.saved.actualHash, 'abc');
});
test('CDP close error cannot skip browser shutdown, removal or persistence', async () => {
  const f = fixture(); f.close(); const caseRecord = { passed: true }; let persisted = false;
  await assert.rejects(finishBrowserCase({ lifecycle: f.lifecycle, caseRecord, cdp: { close() { throw new Error('CDP close failed'); } }, cleanupOptions: f.cleanupOptions, persistEvidence: async () => { persisted = true; } }), /CDP close failed/);
  assert.equal(f.removed.length, 1); assert(persisted); assert.equal(caseRecord.cleanupErrors[0].stage, 'cdp-close');
});
test('persistence error remains red; it cannot mask an earlier primary error', async () => {
  const f = fixture(); f.close(); const primary = new Error('game failure'); const record = { passed: false, error: primary.stack };
  await finishBrowserCase({ lifecycle: f.lifecycle, caseRecord: record, primaryError: primary, cleanupOptions: f.cleanupOptions, persistEvidence: async () => { throw new Error('evidence write failed'); } });
  assert.equal(record.error, primary.stack); assert.equal(record.cleanupErrors[0].stage, 'persist-evidence');
  const clean = fixture(); clean.close();
  await assert.rejects(finishBrowserCase({ lifecycle: clean.lifecycle, caseRecord: { passed: true }, cleanupOptions: clean.cleanupOptions, persistEvidence: async () => { throw new Error('evidence write failed'); } }), /evidence write failed/);
});
test('cleanup success preserves functional success and writes terminal lifecycle evidence', async () => {
  const f = fixture(); f.close(); const caseRecord = { passed: true }; let persisted;
  await finishBrowserCase({ lifecycle: f.lifecycle, caseRecord, cleanupOptions: f.cleanupOptions, persistEvidence: async () => { persisted = JSON.parse(JSON.stringify(caseRecord)); } });
  assert.equal(persisted.passed, true); assert(persisted.browserLifecycle.cleanup.removedAt); assert.equal(caseRecord.cleanupErrors, undefined);
});
test('protocol shutdown waits for the real close before considering signal fallback', async () => {
  const f = fixture(); const caseRecord = { passed: true }; let persisted;
  const cdp = { async send(method) { assert.equal(method, 'Browser.close'); setTimeout(f.close, 5); }, close() {} };
  await finishBrowserCase({ lifecycle: f.lifecycle, caseRecord, cdp, cleanupOptions: f.cleanupOptions, persistEvidence: async () => { persisted = JSON.parse(JSON.stringify(caseRecord)); } });
  assert.deepEqual(f.signals, []); assert.equal(f.removed.length, 1);
  assert(persisted.passed); assert(persisted.browserLifecycle.closedAt <= persisted.browserLifecycle.cleanup.removeStartedAt);
});
test('multiple close waiters settle and remove their timers', async () => {
  const f = fixture(); const first = f.lifecycle.waitForClose(100), second = f.lifecycle.waitForClose(100); f.close();
  assert.deepEqual(await Promise.all([first, second]), [true, true]);
});
test('startup deadlines, bounded save wait, scenarios, and durable acceptance remain intact', () => {
  assert(runner.includes('async function poll(fn, label, timeout = 20000)'));
  assert(runner.includes("poll(() => readFile(path.join(profile, 'DevToolsActivePort'), 'utf8'), 'isolated Chromium starts', 60000)"));
  assert(runner.includes('`${label}: current native save has an exact durable receipt`, 75000)'));
  assert(runner.includes("if (receipt.error) throw new Error(`Browser save receipt failed: ${receipt.error}`)"));
  assert(runner.includes('return visible && !receipt.pending && receipt.digest && receipt.acknowledgedDigest === receipt.digest && receipt.digest === value.saveDigest ? value : null;'));
  for (const id of ['desktop-1280', 'desktop-1440', 'touch-390', 'retina-1440', 'retina-touch-390', 'desktop-1920']) assert(runner.includes(`['${id}',`));
  assert(runner.includes("await streamingCase()")); assert(runner.includes('await mobileWorldCase()')); assert(runner.includes('await phoneRecoveryCase('));
  assert(runner.indexOf('lifecycle.evidence.portReadyAt = Date.now()') > runner.indexOf("const target = targets.find(t => t.type === 'page')"), 'port ready means an actual page target was received');
  assert(!runner.includes("await interval(200); if (child.exitCode"), 'the old signal/delete race is absent');
});

test('ordinary real Node child finishes delayed shutdown writes before owned directory removal', async () => {
  const directory = await mkdtemp(path.join(tmpdir(), '755-godot-web-browser-node-'));
  await mkdir(path.join(directory, 'profile'));
  const lifecycle = createBrowserLifecycle(directory);
  const script = `const fs=require('node:fs'),path=require('node:path'),root=process.argv[1];const timer=setInterval(()=>fs.writeFileSync(path.join(root,'profile','live'),'live'),5);process.on('SIGTERM',()=>{clearInterval(timer);setTimeout(()=>{fs.writeFileSync(path.join(root,'profile','shutdown'),'finished');process.exit(0)},40)});process.stderr.write('ready');`;
  const child = spawn(process.execPath, ['-e', script, directory], { stdio: ['ignore', 'ignore', 'pipe'] }); lifecycle.attach(child);
  try {
    await once(child.stderr, 'data');
    await cleanupBrowserLifecycle(lifecycle, { remove: async (directory, options) => { assert(lifecycle.closed); assert.equal(await readFile(path.join(directory, 'profile', 'shutdown'), 'utf8'), 'finished'); await rm(directory, options); } });
    await assert.rejects(access(directory), { code: 'ENOENT' });
    assert.equal(lifecycle.evidence.events.at(-1).type, 'close');
  } finally {
    if (!lifecycle.closed) { child.kill('SIGKILL'); await lifecycle.waitForClose(3000); }
    if (lifecycle.closed) await rm(directory, { recursive: true, force: true, maxRetries: 3, retryDelay: 100 });
  }
});
test('ordinary real Node child ignoring TERM is killed and observed closed before removal', async () => {
  const directory = await mkdtemp(path.join(tmpdir(), '755-godot-web-browser-node-kill-'));
  const lifecycle = createBrowserLifecycle(directory);
  const child = spawn(process.execPath, ['-e', "process.on('SIGTERM',()=>{});setInterval(()=>{},100);process.stderr.write('ready')"], { stdio: ['ignore', 'ignore', 'pipe'] }); lifecycle.attach(child);
  try {
    await once(child.stderr, 'data');
    await cleanupBrowserLifecycle(lifecycle, { termWaitMs: 30, killWaitMs: 3000 });
    assert.deepEqual(Array.from(lifecycle.evidence.cleanup.signals, row => row.signal), ['SIGTERM', 'SIGKILL']);
    assert.equal(lifecycle.evidence.events.at(-1).signal, 'SIGKILL');
    await assert.rejects(access(directory), { code: 'ENOENT' });
  } finally {
    if (!lifecycle.closed) { child.kill('SIGKILL'); await lifecycle.waitForClose(3000); }
    if (lifecycle.closed) await rm(directory, { recursive: true, force: true, maxRetries: 3, retryDelay: 100 });
  }
});
test('file-backed browser diagnostics retain stderr and real close before owned profile removal', async () => {
  const directory = await mkdtemp(path.join(tmpdir(), '755-godot-web-browser-file-log-'));
  const logRoot = await mkdtemp(path.join(tmpdir(), '755-browser-log-evidence-'));
  const filename = path.join(logRoot, 'stderr.log');
  const file = await open(filename, 'w');
  const lifecycle = createBrowserLifecycle(directory);
  const child = spawn(process.execPath, ['-e', "process.stderr.write('complete diagnostic\\n');"], { stdio: ['ignore', 'ignore', file.fd] });
  lifecycle.attach(child); await file.close();
  try {
    assert(await lifecycle.waitForClose(3000), 'observe the actual child close event');
    await cleanupBrowserLifecycle(lifecycle);
    assert.equal(await readFile(filename, 'utf8'), 'complete diagnostic\n');
    assert(lifecycle.evidence.closedAt <= lifecycle.evidence.cleanup.removeStartedAt);
    await assert.rejects(access(directory), { code: 'ENOENT' });
  } finally {
    if (!lifecycle.closed) { child.kill('SIGKILL'); await lifecycle.waitForClose(3000); }
    if (lifecycle.closed) await rm(directory, { recursive: true, force: true });
    await rm(logRoot, { recursive: true, force: true });
  }
});

// Replay the actual CI race: the render snapshot still owns two fingers after
// CDP dispatch, then the engine consumes cancellation in a later frame.
function cancellationFixture(frames, later) {
  const start = runner.indexOf('async function assertWorldStopped(');
  const finish = runner.indexOf('async function assertBottomPlaque(', start);
  assert(start > 0 && finish > start);
  const active = { id: 'cancel-fixture', mobileWorld: { samples: [] } };
  let reads = 0;
  const context = vm.createContext({ active, Date, state: value => value?.state,
    snapshot: async () => frames[Math.min(reads++, frames.length - 1)],
    poll: async (read, label, timeout) => {
      assert.equal(timeout, 5000, 'cancellation must have a finite deadline');
      for (let i = 0; i < 6; i++) { const value = await read(); if (value) return value; }
      throw new Error(`Timeout: ${label}`);
    },
    mobileSample: async () => later,
    mobileFacts: () => 'unchanged fixture facts',
    mobileDistance: (a, b) => Math.hypot(a.x - b.x, a.y - b.y),
    check: (ok, label) => assert.ok(ok, label)
  });
  vm.runInContext(runner.slice(start, finish), context);
  return { run: context.assertWorldStopped, active, reads: () => reads };
}
function cancellationFrame(frame, owners = [], x = 10, axis = 0) {
  return { sampleFrame: frame, state: {native: {chapter: 2, scene: 'dorm_hub'}}, world: {scene_id: 'dorm_hub', visible: true, player: {x, y: 10}, touch_axis: {x: axis, y: 0}, input: { owners, mouseOwned: false, inventoryOwned: false } } };
}
test('cancellation waits for consumed input, retaining the actual queued-frame evidence', async () => {
  const fingers = [{index: 1, role: 'camera'}, {index: 2, role: 'camera'}];
  const f = cancellationFixture([cancellationFrame(562, fingers), cancellationFrame(563, fingers), cancellationFrame(566)], cancellationFrame(572));
  await f.run(cancellationFrame(562, fingers), 'direct-two-finger-cancel');
  assert.equal(f.reads(), 3);
  assert.deepEqual(Array.from(f.active.mobileWorld.cancellations[0].samples, row => row.frame), [563, 566]);
  assert.equal(f.active.mobileWorld.cancellations[0].endFrame, 566);
});
test('cancellation fails when actual owners or axis never clear', async () => {
  for (const stuck of [cancellationFrame(566, [{index: 1, role: 'camera'}]), cancellationFrame(566, [], 10, 1), cancellationFrame(562)]) {
    const f = cancellationFixture([stuck], cancellationFrame(572));
    await assert.rejects(f.run(cancellationFrame(562), 'stuck-cancel'), /Timeout:/);
  }
});
test('a cleared snapshot from another chapter or world cannot acknowledge current cancellation', async () => {
  for (const edit of [s => s.state.native.chapter = 3, s => s.state.native.scene = 'campus_bootstrap', s => s.world.scene_id = 'campus_bootstrap', s => s.world.visible = false]) {
    const changed = cancellationFrame(566); edit(changed);
    const f = cancellationFixture([changed], cancellationFrame(572));
    await assert.rejects(f.run(cancellationFrame(562), 'wrong-context'), /Timeout:/);
  }
});
test('a later moving actor or resurfaced pointer still fails cancellation acceptance', async () => {
  for (const later of [cancellationFrame(572, [], 15), cancellationFrame(572, [{index: 2, role: 'camera'}])]) {
    const f = cancellationFixture([cancellationFrame(566)], later);
    await assert.rejects(f.run(cancellationFrame(562), 'unstable-cancel'), /stuck movement|stays released/);
  }
});

test('slow browser startup has a bounded host deadline and failed startup still closes before cleanup', async () => {
  const directory = path.join(tmpdir(), '755-godot-web-browser-slow-start');
  const cases = []; let persisted, removed, requestedTimeout;
  const primary = new Error('Timeout: isolated Chromium starts');
  const child = new EventEmitter(); child.pid = 12400; child.exitCode = null;
  child.kill = signal => { child.exitCode = 0; child.emit('exit', 0, signal); child.emit('close', 0, signal); return true; };
  const bodyEnd = runner.indexOf('\ntry {\n  const selected =', end);
  const context = vm.createContext({ path, tmpdir, Date, setTimeout: trackedTimeout, clearTimeout: trackedClear, output: directory,
    open: async () => ({fd: 2, close: async () => {}}), existsSync: () => false,
    mkdtemp: async () => directory, mkdir: async () => {}, spawn: () => child, chrome: 'mock-not-launched', chromeArgs: [],
    readFile: async () => { throw Object.assign(new Error('not ready'), {code: 'ENOENT'}); },
    poll: async (read, label, timeout) => { requestedTimeout = timeout; assert.equal(label, 'isolated Chromium starts'); await assert.rejects(read(), {code: 'ENOENT'}); throw primary; },
    rm: async target => { assert.equal(child.exitCode, 0); removed = target; }, report: {cases},
    snapshot: async () => { throw new Error('no CDP session'); },
    persist: async () => { persisted = JSON.parse(JSON.stringify(cases)); }
  });
  vm.runInContext(`${runner.slice(begin, end)}\nlet active;\n${runner.slice(end, bodyEnd)}`, context);
  await assert.rejects(context.browserCase('mock-case', 1, 1, false), error => error === primary);
  assert.equal(requestedTimeout, 60000); assert.equal(removed, directory);
  assert.equal(persisted[0].passed, false); assert.equal(persisted[0].error, primary.stack);
  assert(persisted[0].browserLifecycle.closedAt <= persisted[0].browserLifecycle.cleanup.removeStartedAt);
});

function optionalFailureFixture(failures, frames, advance = () => {}) {
  const start = runner.indexOf('async function observeOptionalBackgroundFailure(');
  const end = runner.indexOf('async function streamingCase(', start);
  assert(start > 0 && end > start);
  const active = {streaming: {controlledFailures: failures}}; let reads = 0;
  const context = vm.createContext({active,
    snapshot: async () => frames[Math.min(reads++, frames.length - 1)],
    poll: async (read, label, timeout) => {
      assert.equal(timeout, 30000);
      for (let i = 0; i < 5; i++) { advance(label, i, active); const value = await read(); if (value) return value; }
      throw new Error(`Timeout: ${label}`);
    },
    check: (ok, label) => assert.ok(ok, label)
  });
  vm.runInContext(runner.slice(start, end), context);
  return {run: context.observeOptionalBackgroundFailure, reads: () => reads};
}
const optionalMissing = {content: {blocking: false, packs: [{status: 'missing'}]}};
const optionalError = {content: {blocking: false, packs: [{status: 'error'}]}};
test('streaming waits for both current-document HTTP failure and the native error callback', async () => {
  const f = optionalFailureFixture([{requestAt: 10}], [optionalMissing, optionalMissing, optionalError], (label, i, active) => {
    if (label.startsWith('current document') && i === 2) active.streaming.controlledFailures.push({requestAt: 110});
  });
  assert.equal(await f.run(100), optionalError); assert.equal(f.reads(), 3);
});
test('old-document failure or a missing native callback cannot pass streaming acceptance', async () => {
  for (const failures of [[{requestAt: 10}], [{requestAt: 110}]]) {
    const f = optionalFailureFixture(failures, [optionalMissing]);
    await assert.rejects(f.run(100), /Timeout:/);
  }
});
test('an optional failure that blocks the actual game still fails immediately', async () => {
  const f = optionalFailureFixture([{requestAt: 110}], [{content: {blocking: true, packs: [{status: 'error'}]}}]);
  await assert.rejects(f.run(100), /optional background failure/); assert.equal(f.reads(), 1);
});
