#!/usr/bin/env node
// Executes the shipped private transport against a fake DOM/IndexedDB. Nothing
// here opens a browser, writes a database, or creates a progression authority.
import assert from 'node:assert/strict';
import fs from 'node:fs';
import path from 'node:path';
import vm from 'node:vm';
import { createHash } from 'node:crypto';

const platformPath = path.resolve(import.meta.dirname, '../scripts/platform/web_platform.gd');
const platform = fs.readFileSync(platformPath, 'utf8');
const marker = 'JavaScriptBridge.eval("""';
const start = platform.indexOf(marker);
const end = platform.indexOf('""", true)', start + marker.length);
assert(start >= 0 && end > start, 'private browser transport exists in WebPlatform.setup');
const literal = platform.slice(start + marker.length, end);
// GDScript multiline strings process escapes before JavaScript sees them.
const script = literal.replace(/\\(u[0-9a-fA-F]{4}|U[0-9a-fA-F]{6}|[\\"'nrtbfv0])/g, (_, escape) => {
  if (escape[0] === 'u' || escape[0] === 'U') return String.fromCodePoint(parseInt(escape.slice(1), 16));
  return ({ '\\': '\\', '"': '"', "'": "'", n: '\n', r: '\r', t: '\t', b: '\b', f: '\f', v: '\v', 0: '\0' })[escape];
});
const report = { schema: '755-web-save-transport-test-v1', source: platformPath,
  sourceSha256: createHash('sha256').update(platform).digest('hex'),
  transportSha256: createHash('sha256').update(script).digest('hex'),
  semantics: 'Real inline transport; deterministic clock and simulated read-only IndexedDB. No actual save or database is modified.',
  checks: [], passed: false };
const SAVE_DEADLINE_MS = 60000;
const savePath = '/userfs/SevenFiftyFiveNative/save.json';
function check(label, run) { run(); report.checks.push({ label, passed: true }); }
async function settle() { for (let i = 0; i < 12; i++) await Promise.resolve(); }

function fixture(options = {}) {
  let now = 0, serial = 0, reads = 0, closes = 0, upgradeAborts = 0;
  const tasks = new Map(), listeners = new Map(), transactions = [], opened = [], events = [];
  const bytes = options.bytes ?? new TextEncoder().encode('{"fixture":"transport-only"}');
  const later = (callback, delay = 0) => { const id = ++serial; tasks.set(id, { due: now + Number(delay), callback }); return id; };
  const cancel = id => tasks.delete(id);
  const window = {
    addEventListener(name, fn) { if (!listeners.has(name)) listeners.set(name, new Set()); listeners.get(name).add(fn); },
    removeEventListener(name, fn) { listeners.get(name)?.delete(fn); }
  };
  const document = { hidden: false, body: { appendChild() {} },
    addEventListener() {}, removeEventListener() {},
    createElement: () => ({ addEventListener() {}, remove() {}, click() {} }) };
  const forbidden = () => { throw new Error('Transport attempted a forbidden database write'); };
  const event = target => ({ target, preventDefault() {} });
  const database = {
    objectStoreNames: { contains: name => name === 'FILE_DATA' && options.mode !== 'missing-store' },
    close() { closes++; },
    transaction(names, mode) {
      transactions.push({ names, mode });
      assert.equal(mode, 'readonly', 'all backing-store transactions must be read-only');
      const tx = { error: null, objectStore(name) {
        assert.equal(name, 'FILE_DATA');
        if (options.mode === 'missing-store') throw new Error('simulated missing FILE_DATA');
        return { put: forbidden, add: forbidden, delete: forbidden, clear: forbidden, get(key) {
          const request = { result: undefined, error: null }; reads++;
          const delay = options.readDelays?.[reads - 1] ?? options.readDelay ?? 0;
          later(() => {
            if (options.mode === 'read-error') {
              request.error = new Error('simulated read failure'); tx.error = request.error;
              request.onerror?.(event(request)); tx.onerror?.(event(tx));
            }
            else if (options.mode === 'abort') { tx.error = new Error('simulated transaction abort'); tx.onabort?.(event(tx)); }
            else {
              request.result = options.mode === 'missing' ? undefined : { contents: bytes };
              request.onsuccess?.(event(request));
              later(() => tx.oncomplete?.(event(tx)), 0);
            }
          }, delay);
          events.push({ type: 'get', key, at: now });
          return request;
        } };
      } };
      return tx;
    }
  };
  const indexedDB = options.mode === 'unavailable' ? undefined : { open(name) {
    opened.push(name);
    const request = { result: undefined, error: null, transaction: { abort() { upgradeAborts++; } } };
    later(() => {
      if (options.mode === 'open-pending') return;
      if (options.mode === 'open-error') { request.error = new Error('simulated open failure'); request.onerror?.(event(request)); }
      else if (options.mode === 'new-database') request.onupgradeneeded?.(event(request));
      else { request.result = database; request.onsuccess?.(event(request)); }
    }, options.openDelay ?? 0);
    return request;
  } };
  class ClockDate extends Date { constructor(...args) { super(...(args.length ? args : [now])); } static now() { return now; } }
  const context = { window, document, indexedDB, setTimeout: later, clearTimeout: cancel,
    setInterval(callback, delay) { let id; const tick = () => { callback(); id = later(tick, delay); }; id = later(tick, delay); return id; },
    clearInterval: cancel, Date: ClockDate, performance: { now: () => now },
    Uint8Array, ArrayBuffer, TextDecoder, TextEncoder, console,
    localStorage: { getItem: () => null } };
  Object.assign(window, context);
  vm.runInNewContext(script, context, { filename: platformPath + ':private-transport', timeout: 1000 });
  const host = window.__GODOT_755_HOST__;
  assert.equal(typeof host?.watchSave, 'function', 'real private watchSave is installed');
  assert.equal(typeof host.finishSave, 'function', 'real private finishSave is installed');
  const calls = [];
  function watch(token) { host.watchSave(token, savePath, (...args) => calls.push({ at: now, args })); }
  async function advance(duration) {
    const target = now + duration;
    for (let count = 0; count < 20000; count++) {
      await settle();
      const next = [...tasks].filter(([, task]) => task.due <= target).sort((a, b) => a[1].due - b[1].due || a[0] - b[0])[0];
      if (!next) { if (now === target) return; now = target; continue; }
      now = Math.max(now, next[1].due); tasks.delete(next[0]); next[1].callback();
    }
    throw new Error('Mock clock exceeded its bounded task budget');
  }
  function guarded() {
    let prevented = false;
    const event = { preventDefault() { prevented = true; }, returnValue: undefined };
    for (const callback of listeners.get('beforeunload') || []) callback(event);
    return prevented || event.returnValue !== undefined;
  }
  return { host, calls, watch, advance, guarded, transactions, opened, events, bytes,
    get closes() { return closes; }, get upgradeAborts() { return upgradeAborts; }, get pendingTimers() { return tasks.size; } };
}

try {
  const delayed = fixture({ readDelay: 900 }); delayed.watch(1);
  check('pending save protects page unload immediately', () => assert(delayed.guarded()));
  await delayed.advance(899);
  check('delayed backing-store read cannot report bytes or success early', () => assert.equal(delayed.calls.length, 0));
  await delayed.advance(1);
  check('read gives exact unparsed bytes to native hashing without WebCrypto', () => {
    assert(delayed.calls.length > 0); const args = delayed.calls[0].args;
    assert.equal(args[0], 1); assert.deepEqual(new Uint8Array(args[1]), delayed.bytes); assert.equal(args[2], '');
  });
  check('read alone cannot clear the pending unload guard', () => assert(delayed.guarded()));
  check('transport uses only the fixed userfs database and read-only transactions', () => {
    assert(delayed.opened.length > 0); assert(delayed.opened.every(name => name === '/userfs'));
    assert(delayed.transactions.every(tx => tx.mode === 'readonly'));
    assert(delayed.events.every(event => event.key === savePath));
  });
  delayed.host.finishSave(1, true);
  check('native digest acceptance retires the unload guard', () => assert.equal(delayed.guarded(), false));
  const finishedCalls = delayed.calls.length; await delayed.advance(30000);
  check('accepted save stops later polling callbacks', () => assert.equal(delayed.calls.length, finishedCalls));
  delayed.host.dispose();

  for (const mode of ['unavailable', 'open-error', 'missing-store', 'new-database', 'read-error', 'abort']) {
    const failed = fixture({ mode }); failed.watch(10); await failed.advance(SAVE_DEADLINE_MS + 1000);
    check(`${mode} never acknowledges saved bytes and reports failure`, () => {
      assert(failed.calls.some(call => call.args[1] == null && typeof call.args[2] === 'string' && call.args[2].length > 0));
      assert(!failed.calls.some(call => call.args[1] != null));
    });
    check(`${mode} retains page-unload protection`, () => assert(failed.guarded()));
    if (mode === 'new-database') check('opening a nonexistent backing database aborts its upgrade instead of creating a save store', () => {
      assert.equal(failed.upgradeAborts, 1); assert.equal(failed.transactions.length, 0);
    });
    failed.host.dispose();
  }

  for (const [label, bytes] of [['untyped-contents', [1, 2]], ['oversized-contents', new Uint8Array(8 * 1024 * 1024 + 1)]]) {
    const invalid = fixture({ bytes }); invalid.watch(11); await invalid.advance(1000);
    check(`${label} is rejected without presenting a durable acknowledgement`, () => {
      assert(invalid.calls.some(call => call.args[1] == null && call.args[2])); assert(invalid.guarded());
    });
    invalid.host.dispose();
  }
  const subarray = new Uint8Array([99, 1, 2, 3, 99]).subarray(1, 4);
  const offset = fixture({ bytes: subarray }); offset.watch(12); await offset.advance(0);
  check('typed-array observation preserves its exact offset and length', () => assert.deepEqual(new Uint8Array(offset.calls[0].args[1]), new Uint8Array([1, 2, 3])));
  offset.host.dispose();

  for (const invalidPath of ['/tmp/save.json', '/userfs/../save.json', '/userfs/profile/save.previous.json']) {
    const invalid = fixture(); invalid.host.watchSave(13, invalidPath, (...args) => invalid.calls.push({ args })); await invalid.advance(1000);
    check(`invalid observed path is rejected before any database access: ${invalidPath}`, () => {
      assert.equal(invalid.opened.length, 0); assert(invalid.calls.some(call => call.args[1] == null && call.args[2])); assert(invalid.guarded());
    });
    invalid.host.dispose();
  }

  const missing = fixture({ mode: 'missing' }); missing.watch(20); await missing.advance(SAVE_DEADLINE_MS - 1);
  check('missing entry remains pending until the bounded timeout', () => {
    assert(!missing.calls.some(call => call.args[2])); assert(missing.guarded());
  });
  await missing.advance(1001);
  check('missing entry reaches an explicit timeout rather than silent success', () => {
    assert(missing.calls.some(call => call.args[1] == null && call.args[2])); assert(missing.guarded());
  });
  missing.host.dispose();

  for (const [label, options] of [['open-never-settles', { mode: 'open-pending' }], ['get-settles-after-deadline', { readDelay: SAVE_DEADLINE_MS + 5000 }]]) {
    const stalled = fixture(options); stalled.watch(21); await stalled.advance(SAVE_DEADLINE_MS - 1);
    check(`${label} has no premature completion`, () => assert.equal(stalled.calls.length, 0));
    await stalled.advance(1);
    check(`${label} reaches its watchdog deadline even with an unresolved database operation`, () => {
      assert.equal(stalled.calls.length, 1); assert.equal(stalled.calls[0].args[1], null);
      assert(stalled.calls[0].args[2]); assert(stalled.guarded());
    });
    await stalled.advance(10000);
    check(`${label} cannot acknowledge a late result after timeout`, () => {
      assert.equal(stalled.calls.length, 1); assert(stalled.guarded());
    });
    stalled.host.dispose();
  }

  const superseded = fixture({ readDelays: [800, 100] }); superseded.watch(30); await superseded.advance(0);
  superseded.watch(31); await superseded.advance(1200);
  check('late earlier read cannot call back into the newer save generation', () => {
    assert(superseded.calls.length > 0); assert(superseded.calls.every(call => call.args[0] === 31));
  });
  superseded.host.finishSave(30, true);
  check('old native acceptance cannot clear a newer pending save', () => assert(superseded.guarded()));
  superseded.host.finishSave(31, false);
  check('native digest rejection keeps unload protection', () => assert(superseded.guarded()));
  superseded.watch(32); await superseded.advance(1000); superseded.host.finishSave(32, true);
  check('a successful retry can clear an earlier failed save guard', () => assert.equal(superseded.guarded(), false));
  superseded.host.dispose();

  const disposed = fixture({ readDelay: 800 }); disposed.watch(40); await disposed.advance(0); disposed.host.dispose();
  await disposed.advance(30000);
  check('dispose suppresses already in-flight callbacks and retires the unload listener', () => {
    assert.equal(disposed.calls.length, 0); assert.equal(disposed.guarded(), false); assert.equal(disposed.pendingTimers, 0);
  });
  report.passed = true;
} catch (error) { report.error = error.stack; process.exitCode = 1; }
const reportArg = process.argv.find(arg => arg.startsWith('--report='));
if (reportArg) { const destination = path.resolve(reportArg.slice('--report='.length)); fs.mkdirSync(path.dirname(destination), { recursive: true }); fs.writeFileSync(destination, JSON.stringify(report, null, 2) + '\n'); }
console.log(`WEB_SAVE_TRANSPORT: ${report.checks.length} checks; ${report.passed ? 'PASS' : 'FAIL'}`);
if (report.error) console.error(report.error);
