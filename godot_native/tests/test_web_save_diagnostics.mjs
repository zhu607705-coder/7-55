import assert from 'node:assert/strict';
import { createHash } from 'node:crypto';
import { readFileSync } from 'node:fs';
import vm from 'node:vm';
// Execute the actual runner functions with simulated readonly IDB/CDP events.
// This does not launch a browser or prove real persistence timing.
const draft = readFileSync(new URL('../tools/verify_web_export.mjs', import.meta.url), 'utf8');
const source = draft.slice(draft.indexOf('function readOnlySaveProbe('), draft.indexOf('async function waitForPersistedSave('));
const checks = [];
const check = (label, test) => { test(); checks.push(label); };
const settle = async () => { for (let n = 0; n < 12; n++) await Promise.resolve(); };
const content = new Uint8Array([123, 34, 97, 34, 58, 49, 125]);
const digest = createHash('sha256').update(content).digest('hex');
const identity = { token: 6, targetDigest: digest };
function browserFixture(options = {}) {
  let now = 1000, serial = 0, closes = 0, abortedUpgrade = 0, hashCalls = 0;
  const timers = new Map(), calls = [];
  const schedule = (fn, delay) => { const id = ++serial; timers.set(id, { at: now + delay, fn }); return id; };
  const clear = id => timers.delete(id);
  const forbidden = () => { throw new Error('forbidden write or enumeration'); };
  const DateClock = class extends Date { static now() { return now; } };
  const record = options.missing ? undefined : { contents: options.contents ?? content, timestamp: new DateClock(123) };
  const db = {
    close() { closes++; },
    transaction(name, mode) {
      calls.push(['transaction', name, mode, now]); assert.equal(name, 'FILE_DATA'); assert.equal(mode, 'readonly');
      if (options.noStore) throw new Error('missing store');
      const tx = { error: new Error('fake transaction failure'), objectStore(storeName) {
        assert.equal(storeName, 'FILE_DATA');
        return { put: forbidden, delete: forbidden, clear: forbidden, getAll: forbidden, getAllKeys: forbidden, count: forbidden,
          get(key) {
            assert.equal(key, '/userfs/SevenFiftyFiveNative/save.json'); calls.push(['get', key, now]);
            const request = { result: record, error: new Error('fake get failure') };
            schedule(() => {
              if (options.getError) request.onerror?.();
              else request.onsuccess?.();
            }, options.getDelay ?? 20);
            schedule(() => options.abort ? tx.onabort?.() : options.txError ? tx.onerror?.() : tx.oncomplete?.(), (options.getDelay ?? 20) + (options.txDelay ?? 30));
            return request;
          } };
      } };
      return tx;
    }
  };
  const indexedDB = { deleteDatabase: forbidden, databases: forbidden, open(name) {
    assert.equal(name, '/userfs'); calls.push(['open', name, now]);
    const request = { result: db, error: new Error('fake open failure'), transaction: { abort() { abortedUpgrade++; } } };
    if (!options.openPending) schedule(() => {
      if (options.upgrade) request.onupgradeneeded?.();
      else if (options.openError) request.onerror?.();
      else request.onsuccess?.();
    }, options.openDelay ?? 10);
    return request;
  } };
  const context = vm.createContext({ Date: DateClock, performance: { now: () => now - 1000 }, document: { hidden: false }, indexedDB,
    Uint8Array, ArrayBuffer, setTimeout: schedule, clearTimeout: clear, crypto: { subtle: { digest: async (algorithm, bytes) => {
      assert.equal(algorithm, 'SHA-256'); hashCalls++;
      if (options.hashDelay) await new Promise(resolve => schedule(resolve, options.hashDelay));
      return new Uint8Array(createHash('sha256').update(bytes).digest()).buffer;
    } } } });
  vm.runInContext(source, context);
  let result;
  const pending = context.readOnlySaveProbe(identity).then(value => { result = value; });
  const advance = async duration => {
    const end = now + duration;
    while (true) {
      const next = [...timers].filter(([, timer]) => timer.at <= end).sort((a, b) => a[1].at - b[1].at || a[0] - b[0])[0];
      if (!next) break;
      timers.delete(next[0]); now = next[1].at; next[1].fn(); await settle();
    }
    now = end; await settle();
  };
  return { advance, pending, calls, get result() { return result; }, get closes() { return closes; }, get timerCount() { return timers.size; }, get abortedUpgrade() { return abortedUpgrade; }, get hashCalls() { return hashCalls; } };
}
const ordinary = browserFixture({ openDelay: 100, getDelay: 200, txDelay: 300 });
await ordinary.advance(599);
check('diagnostic cannot return before transaction completion', () => assert.equal(ordinary.result, undefined));
await ordinary.advance(1);
check('actual bytes are hashed, not target identity copied as observed digest', () => assert.equal(ordinary.result.sha256, digest));
check('operation timings retain actual open/get/transaction/hash boundaries', () => {
  assert.equal(ordinary.result.timings.started.wallMs, 1000);
  assert.equal(ordinary.result.timings.openSucceeded.wallMs, 1100);
  assert.equal(ordinary.result.timings.getSucceeded.wallMs, 1300);
  assert.equal(ordinary.result.timings.transactionCompleted.wallMs, 1600);
  assert.equal(ordinary.result.timings.hashCompleted.monotonicMs, 600);
});
check('file mtime is separate from actual transaction observation times', () => assert.equal(ordinary.result.fileMtimeMs, 123));
check('one open plus one fixed-key readonly get; no enumeration or writes', () => assert.deepEqual(ordinary.calls.map(call => call[0]), ['open', 'transaction', 'get']));
check('close request is recorded after readonly completion, before hashing', () => { assert.equal(ordinary.result.timings.closeRequested.wallMs, 1600); assert.equal(ordinary.result.closeReason, 'read-transaction-completed'); });
check('normal completion closes connection and clears diagnostic timer', () => { assert.equal(ordinary.closes, 1); assert.equal(ordinary.timerCount, 0); });
for (const [name, options] of Object.entries({ missing: { missing: true }, upgrade: { upgrade: true }, openError: { openError: true }, noStore: { noStore: true }, getError: { getError: true }, txError: { txError: true }, abort: { abort: true }, unsupported: { contents: [1, 2] }, oversized: { contents: new Uint8Array(8 * 1024 * 1024 + 1) } })) {
  const fixture = browserFixture(options); await fixture.advance(100);
  check(`${name} remains a diagnostic outcome, never invented durable success`, () => assert(name === 'missing' ? fixture.result.missing : fixture.result.error));
  check(`${name} does not leave a watchdog timer`, () => assert.equal(fixture.timerCount, 0));
  if (name === 'upgrade') check('unexpected upgrade is aborted, no store or record is created', () => { assert.equal(fixture.abortedUpgrade, 1); assert.equal(fixture.calls.length, 1); });
}
for (const [name, options] of Object.entries({ pendingOpen: { openPending: true }, lateOpen: { openDelay: 10000 }, lateGet: { getDelay: 10000 }, lateHash: { hashDelay: 10000 } })) {
  const fixture = browserFixture(options); await fixture.advance(8000); const before = JSON.stringify(fixture.result);
  check(`${name} resolves with bounded diagnostic error`, () => assert.equal(fixture.result.error, 'diagnostic read limit'));
  await fixture.advance(12000);
  check(`${name} late callback cannot mutate the completed result`, () => assert.equal(JSON.stringify(fixture.result), before));
  check(`${name} leaves no diagnostic timers`, () => assert.equal(fixture.timerCount, 0));
  if (name === 'lateOpen') check('late successful open is closed without issuing a get', () => { assert.equal(fixture.closes, 1); assert.equal(fixture.calls.length, 1); });
}
function controllerFixture(options = {}) {
  let now = 0, current = true; const requests = [];
  const context = vm.createContext({ Date, console }); vm.runInContext(source, context);
  const attempt = { beganAt: 0 }; const session = { cdp: { send(method, params, timeout) {
    if (options.throwSend) throw new Error('destroyed context');
    let resolve, reject; const promise = new Promise((a, b) => { resolve = a; reject = b; });
    requests.push({ method, params, timeout, resolve, reject }); return promise;
  } } };
  const controller = context.createSaveDiagnostics(session, attempt, 5, () => current, () => now);
  const observe = (ms, patch = {}) => { now = ms; return controller.observe({ sampleFrame: 140, documentHidden: false, savePersistence: { token: 6, digest, pending: true, error: '', ...patch } }); };
  const reply = (index, patch = {}) => requests[index].resolve({ result: { value: { ...identity, sha256: 'b'.repeat(64), ...patch } } });
  return { attempt, requests, controller, observe, reply, changeSession() { current = false; } };
}
const flow = controllerFixture();
flow.observe(9999); await settle();
check('ordinary fast save incurs no diagnostic CDP or IDB operation', () => assert.equal(flow.requests.length, 0));
check('observe has no promise for the main poll to await', () => assert.equal(flow.observe(10000), undefined));
await settle();
check('first slow sample is bound to exact token/digest and captured CDP', () => {
  assert.equal(flow.requests.length, 1); assert.equal(flow.requests[0].method, 'Runtime.evaluate');
  assert(flow.requests[0].params.expression.endsWith(`(${JSON.stringify(identity)})`));
});
for (let ms = 11000; ms <= 21000; ms += 100) flow.observe(ms, { error: ms >= 20000 ? 'timeout' : '', pending: ms < 20000 });
await settle();
check('repeated timeout observations never stack on an unfinished probe', () => assert.equal(flow.requests.length, 1));
flow.reply(0); await settle(); flow.observe(21100, { error: 'timeout', pending: false }); await settle();
check('one post-timeout sample can start after the first read completes', () => { assert.equal(flow.requests.length, 2); assert.equal(flow.attempt.diagnostics.probes[1].reason, 'after-production-timeout'); });
flow.reply(1); await settle();
for (let ms = 22000; ms < 30000; ms += 100) flow.observe(ms, { error: 'timeout', pending: false });
await settle();
check('total extra probes are capped at two with no repeated reason', () => assert.equal(flow.requests.length, 2));
check('diagnostic returns do not change target digest or pass/fail authority', () => { assert.equal(flow.attempt.diagnostics.probes[0].targetDigest, digest); assert.equal(flow.attempt.diagnostics.probes[0].result.sha256, 'b'.repeat(64)); assert.equal(flow.attempt.passed, undefined); });
for (const kind of ['stop', 'session', 'token', 'digest']) {
  const fixture = controllerFixture(); fixture.observe(10000); await settle();
  if (kind === 'stop') fixture.controller.stop('wait-finished');
  if (kind === 'session') { fixture.changeSession(); fixture.observe(11000); }
  if (kind === 'token') fixture.observe(11000, { token: 7 });
  if (kind === 'digest') fixture.observe(11000, { digest: 'c'.repeat(64) });
  const before = JSON.stringify(fixture.attempt); fixture.reply(0); await settle(); fixture.observe(22000, { error: 'timeout' }); await settle();
  check(`${kind} boundary rejects late results without next-profile contamination`, () => { assert.equal(JSON.stringify(fixture.attempt), before); assert.equal(fixture.requests.length, 1); });
}
const invalid = controllerFixture();
for (const patch of [{ token: 5 }, { token: NaN }, { digest: 'not-a-hash' }]) invalid.observe(12000, patch);
await settle();
check('old, noninteger, or malformed receipt identities cannot launch a probe', () => assert.equal(invalid.requests.length, 0));
const beforeDispatch = controllerFixture(); beforeDispatch.observe(10000); beforeDispatch.controller.stop('case-ended'); await settle();
check('stop before asynchronous dispatch prevents even a CDP request', () => assert.equal(beforeDispatch.requests.length, 0));
for (const kind of ['cdp-reject', 'identity', 'context']) {
  const fixture = controllerFixture(); fixture.observe(10000); await settle();
  if (kind === 'cdp-reject') fixture.requests[0].reject(new Error('CDP timeout Runtime.evaluate'));
  else if (kind === 'identity') fixture.reply(0, { token: 7 });
  else fixture.requests[0].resolve({ exceptionDetails: { text: 'Execution context was destroyed.' } });
  await settle(); fixture.observe(21000, { error: 'timeout' }); await settle();
  check(`${kind} is caught and cannot alter acceptance or stack a second operation`, () => { assert.equal(fixture.requests.length, 1); assert.equal(fixture.attempt.diagnostics.probes[0].status, 'diagnostic-error'); assert(fixture.attempt.diagnostics.probes[0].error); });
}
const readLimit = controllerFixture(); readLimit.observe(10000); await settle();
readLimit.reply(0, { error: 'diagnostic read limit' }); await settle();
readLimit.observe(21000, { error: 'timeout' }); await settle();
check('browser read error cannot stack a second probe before requested close completes', () => {
  assert.equal(readLimit.requests.length, 1);
  assert.equal(readLimit.attempt.diagnostics.probes[0].status, 'diagnostic-error');
  assert.equal(readLimit.attempt.diagnostics.stopReason, 'diagnostic-read-failed');
});
const thrown = controllerFixture({ throwSend: true }); thrown.observe(10000); await settle();
check('synchronous CDP send failure is also contained', () => assert.equal(thrown.attempt.diagnostics.stopReason, 'diagnostic-operation-failed'));
for (const line of [
  "    if (receipt.error) throw new Error(`Browser save receipt failed: ${receipt.error}`);",
  "    return visible && !receipt.pending && receipt.digest && receipt.acknowledgedDigest === receipt.digest && receipt.digest === value.saveDigest ? value : null;",
  "  }, `${label}: current native save has an exact durable receipt`, 75000);",
  "  check(primary?.sha256 === saved.saveDigest, `${label}: independent readonly IndexedDB primary matches the current native save`, { elapsedMs: Date.now() - began, receipt: saved.savePersistence, primary, diskReadMs: disk.readDurationMs });"
]) {
  check(`strict acceptance and bounded wait contract is retained: ${line.trim().slice(0, 70)}`, () => assert(draft.includes(line)));
}
check('only existing two full-store requests remain, no added getAll/key enumeration', () => {
  assert.equal((draft.match(/\.getAll\(/g) || []).length, 1);
  assert.equal((draft.match(/\.getAllKeys\(/g) || []).length, 1);
});
check('diagnostic source contains no filesystem sync, game save, write or public bridge hooks', () => assert(!/force_fs_sync|syncfs|save_game|__GODOT_755__|\.put\(|\.delete\(|\.clear\(/.test(source)));
check('frame metadata does not expand observation identity and exhaust the original 160-row bound', () => assert(draft.includes('const identity = JSON.stringify([receipt, value?.saveDigest]);')));
// Execute the current dispatch with inert scenario bodies. Adding a focused
// scenario may extend the initializer/else chain without removing an original
// acceptance path. Protect those paths by their actual calls and profile sets.
const dispatchStart = draft.indexOf('    result = await freshCase(');
const dispatchEnd = draft.indexOf("    if (scenarios === 'mobile-world') check(active.mobileWorld", dispatchStart);
assert(dispatchStart >= 0 && dispatchEnd > dispatchStart);
const dispatch = draft.slice(dispatchStart, dispatchEnd);
const selectedExpression = draft.match(/^  const selected = (.+);$/m)?.[1];
assert(selectedExpression);
const baselineProfiles = ['desktop-1280', 'desktop-1440', 'touch-390', 'retina-1440', 'retina-touch-390', 'desktop-1920'];
const focusedProfiles = ['desktop-1280', 'touch-390', 'retina-touch-390'];
for (const scenarios of ['all', 'bike', 'media', 'streaming', 'mobile-world', 'phone-recovery', 'corners', 'checkin', 'words', 'durability', 'durability-switch', 'resource-loading']) {
  const selected = vm.runInNewContext(selectedExpression, { only: 'all', scenarios });
  const expectedProfiles = scenarios === 'streaming' ? ['desktop-1280'] : ['mobile-world', 'phone-recovery'].includes(scenarios) ? focusedProfiles : baselineProfiles;
  check(`${scenarios}: original acceptance profile coverage remains exact`, () => assert.deepEqual(Array.from(selected, row => row[0]), expectedProfiles));
  for (const [id, , , touch] of selected) {
    const calls = [], initialized = [];
    const context = { scenarios, id, touch, fixtureDir: '/explicit-test-fixture', active: { screenshots: [] } };
    for (const name of ['snapshot', 'clickControl', 'clickPoint', 'renderPoint', 'poll', 'check', 'interval', 'screenshot', 'importSave', 'assertLayout', 'settings', 'saveProgressAndWait', 'startStory', 'press']) context[name] = () => {};
    for (const name of ['mobileWorldCase', 'phoneRecoveryCase', 'phoneNavigationCase', 'portableSaveCase', 'cornerNavigationCase', 'checkinPresentationCase', 'libraryCase', 'resourceLoadingCase', 'c1Case', 'legacyCase', 'fixtureCases', 'bikeCase', 'mediaCase', 'durabilityCase', 'durabilitySwitchCase', 'streamingCase']) context[name] = async () => { calls.push(name); return {}; };
    context.freshCase = async focused => { initialized.push(focused); return {}; };
    await vm.runInNewContext(`(async () => { let result; ${dispatch} })()`, context);
    const expected = [];
    if (scenarios === 'mobile-world') expected.push('mobileWorldCase');
    else if (scenarios === 'phone-recovery') expected.push('phoneRecoveryCase');
    else expected.push('portableSaveCase');
    if (scenarios === 'corners') expected.push('cornerNavigationCase');
    if (scenarios === 'checkin') expected.push('checkinPresentationCase');
    if (scenarios === 'resource-loading') expected.push('resourceLoadingCase');
    if (scenarios === 'words') expected.push('c1Case');
    if (id === 'desktop-1280') {
      if (scenarios === 'all') expected.push('legacyCase', 'c1Case', 'fixtureCases');
      if (['all', 'bike'].includes(scenarios)) expected.push('bikeCase');
      if (['all', 'media'].includes(scenarios)) expected.push('mediaCase');
      if (scenarios === 'durability') expected.push('durabilityCase');
      if (scenarios === 'durability-switch') expected.push('durabilitySwitchCase');
      if (scenarios === 'streaming') expected.push('streamingCase');
    } else if (touch && scenarios === 'all') expected.push('c1Case');
    check(`${scenarios}/${id}: original scenario bodies still execute exactly once`, () => {
      assert.deepEqual(initialized, [['mobile-world', 'phone-recovery'].includes(scenarios)]);
      assert.deepEqual(calls, expected);
    });
  }
}
const project = readFileSync(new URL('../project.godot', import.meta.url), 'utf8');
const stateSource = readFileSync(new URL('../scripts/state.gd', import.meta.url), 'utf8');
check('fixed key is grounded in current actual custom user directory and save path', () => { assert(project.includes('config/use_custom_user_dir=true')); assert(project.includes('config/custom_user_dir_name=\"SevenFiftyFiveNative\"')); assert(stateSource.includes('const SAVE_PATH := \"user://save.json\"')); });
console.log(`PASS ${checks.length} pure Node checks; no browser, real IDB, or runtime acceptance executed.`);
