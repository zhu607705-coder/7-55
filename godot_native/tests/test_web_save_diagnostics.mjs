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
  "  }, `${label}: current native save has an exact durable receipt`, 30000);",
  "  check(primary?.sha256 === saved.saveDigest, `${label}: independent readonly IndexedDB primary matches the current native save`, { elapsedMs: Date.now() - began, receipt: saved.savePersistence, primary, diskReadMs: disk.readDurationMs });"
]) {
  check(`original acceptance line is byte-preserved: ${line.trim().slice(0, 70)}`, () => assert(draft.includes(line)));
}
check('only existing two full-store requests remain, no added getAll/key enumeration', () => {
  assert.equal((draft.match(/\.getAll\(/g) || []).length, 1);
  assert.equal((draft.match(/\.getAllKeys\(/g) || []).length, 1);
});
check('diagnostic source contains no filesystem sync, game save, write or public bridge hooks', () => assert(!/force_fs_sync|syncfs|save_game|__GODOT_755__|\.put\(|\.delete\(|\.clear\(/.test(source)));
check('frame metadata does not expand observation identity and exhaust the original 160-row bound', () => assert(draft.includes('const identity = JSON.stringify([receipt, value?.saveDigest]);')));
check('all selected original acceptance scenario invocations remain byte-preserved', () => {
  for (const line of [
  "    result = await freshCase(['mobile-world', 'phone-recovery'].includes(scenarios));",
  "    if (scenarios === 'mobile-world') await mobileWorldCase();",
  "    else if (scenarios === 'phone-recovery') active.phoneRecovery = await phoneRecoveryCase({ id, touch, fixtureDir,",
  "    else await portableSaveCase();",
  "      if (scenarios === 'streaming') await streamingCase();",
  "  const selected = [['desktop-1280', 1280, 720, false, 1], ['desktop-1440', 1440, 900, false, 1], ['touch-390', 390, 844, true, 1], ['retina-1440', 1440, 900, false, 2], ['retina-touch-390', 390, 844, true, 3], ['desktop-1920', 1920, 1080, false, 1]].filter(([id]) => (only === 'all' || id === only) && (scenarios !== 'streaming' || id === 'desktop-1280') && (!['mobile-world', 'phone-recovery'].includes(scenarios) || ['desktop-1280', 'touch-390', 'retina-touch-390'].includes(id)));"
]) assert(draft.includes(line));
});
const project = readFileSync(new URL('../project.godot', import.meta.url), 'utf8');
const stateSource = readFileSync(new URL('../scripts/state.gd', import.meta.url), 'utf8');
check('fixed key is grounded in current actual custom user directory and save path', () => { assert(project.includes('config/use_custom_user_dir=true')); assert(project.includes('config/custom_user_dir_name=\"SevenFiftyFiveNative\"')); assert(stateSource.includes('const SAVE_PATH := \"user://save.json\"')); });

// Exercise the actual save target selection, ordinary click orchestration and
// unchanged receipt poll against deterministic snapshots. These are regression
// checks for the acceptance driver, not proof of a real browser click or IDB.
const saveSource = draft.slice(draft.indexOf('async function waitForPersistedSave('), draft.indexOf('async function startStory('));
const pollSource = draft.slice(draft.indexOf('async function poll('), draft.indexOf('async function shaFile('));
const clickSource = draft.slice(draft.indexOf('async function clickPoint('), draft.indexOf('async function canvasGeometry('));
const targetDigest = 'a'.repeat(64), oldDigest = 'b'.repeat(64);
function saveSnapshot(frame, patch = {}) {
  return { sampleFrame: frame, documentHidden: false, viewport: { x: 0, y: 0, width: 1280, height: 720 },
    state: { native: { chapter: 2, mode: 'world', page: 'campus_bootstrap', scene: 'dorm_hub' } },
    visibleControls: [{ name: 'SaveNativeProgress', text: '保存进度', disabled: false, rect: { x: 366, y: 177.5, width: 548, height: 48 } }],
    savePersistence: { token: 3, digest: oldDigest, acknowledgedDigest: oldDigest, pending: false, error: '' }, saveDigest: oldDigest, ...patch };
}
function saveClickFixture(options = {}) {
  let now = 1000, beforeIndex = 0, afterIndex = 0, dispatched = false, lastBefore;
  const clicks = [], events = [], canvasReads = [], delays = [], diskReads = [], accepted = [];
  const active = { fresh: { recording: false, inputs: [] }, touch: !!options.touch };
  active.cdp = { send: async (method, params) => {
    assert(['Input.dispatchMouseEvent', 'Input.dispatchTouchEvent'].includes(method));
    events.push({ method, params, at: now });
    if (['mouseMoved', 'touchStart'].includes(params.type)) { const point = params.touchPoints?.[0] || params; clicks.push({ point: { x: point.x, y: point.y }, at: now }); }
    if (['mouseReleased', 'touchEnd'].includes(params.type)) { dispatched = true; if (options.clickError) throw new Error(options.clickError); }
    return {};
  } };
  const samples = options.samples || [saveSnapshot(1), saveSnapshot(2)];
  const canvas = { x: 0, y: 0, width: 1280, height: 720, pixelWidth: 2560, pixelHeight: 1440, windowWidth: 1280, windowHeight: 720, documentHidden: false, ...options.canvas };
  const DateClock = class extends Date { static now() { return now; } };
  const context = vm.createContext({ Date: DateClock, active, console,
    state: value => value?.state, controls: value => value?.visibleControls || [],
    interval: async ms => { delays.push(ms); now += ms; },
    snapshot: async () => {
      if (!dispatched) {
        lastBefore = structuredClone(typeof options.beforeSnapshot === 'function' ? options.beforeSnapshot(beforeIndex++, now) : samples[Math.min(beforeIndex++, samples.length - 1)]);
        return lastBefore;
      }
      if (options.afterSnapshot) return options.afterSnapshot(afterIndex++, now, lastBefore);
      return saveSnapshot(lastBefore.sampleFrame + 1, { visibleControls: [{ ...lastBefore.visibleControls[0], text: '已保存' }], saveDigest: targetDigest,
        savePersistence: { token: lastBefore.savePersistence.token + 1, digest: targetDigest, acknowledgedDigest: targetDigest, pending: false, error: '' } });
    },
    evaluate: async expression => { assert(expression.includes('getBoundingClientRect()')); canvasReads.push({ at: now, expression, beforeIndex }); return structuredClone(canvas); },
    createSaveDiagnostics: () => ({ observe() {}, stop() {} }),
    readPersistentSaveEntries: async () => { diskReads.push(now); return { entries: [{ key: '/userfs/SevenFiftyFiveNative/save.json', sha256: options.diskDigest || targetDigest }], readDurationMs: 0 }; },
    check: (ok, label) => { assert(ok, label); accepted.push(label); }
  });
  vm.runInContext(pollSource + '\n' + clickSource + '\n' + saveSource, context);
  return { context, active, clicks, events, canvasReads, delays, diskReads, accepted, get now() { return now; }, get beforeReads() { return beforeIndex; } };
}
const stable = saveClickFixture({ samples: [saveSnapshot(10), saveSnapshot(10), saveSnapshot(11)] });
await stable.context.saveProgressAndWait('stable Save');
check('same cached frame cannot satisfy two fresh stable native samples', () => { assert.equal(stable.beforeReads, 3); assert.deepEqual([...stable.active.saveInputs[0].stableSampleFrames], [10, 11]); });
check('one fresh DOM canvas mapping immediately precedes exactly one ordinary click', () => { assert.equal(stable.canvasReads.length, 1); assert.equal(stable.clicks.length, 1); assert.equal(stable.canvasReads[0].at, stable.clicks[0].at); assert.deepEqual(stable.clicks[0].point, { x: 640, y: 201.5 }); });
check('explicit Save keeps provenance even outside fresh-game recording', () => {
  const input = stable.active.saveInputs[0];
  assert.equal(stable.active.fresh.inputs.length, 0); assert.equal(input.uniqueControlMatches, 1);
  assert.equal(input.previousToken, 3); assert.equal(input.text, '保存进度'); assert.equal(input.sampleFrame, 11);
  assert.equal(input.geometryWaitBeganAt, 1000); assert.equal(input.preparedAt, 1200);
  assert.equal(input.dispatchStartedAt, 1200); assert.equal(input.dispatchEndedAt, 1265); assert.equal(input.dispatchCompleted, true);
  assert.equal(input.canvas.pixelWidth, 2560); assert.equal(input.viewport.width, 1280); assert.equal(input.observedContext.scene, 'dorm_hub');
  assert.equal(stable.active.saveAttempts[0].input, input); assert.equal(stable.active.saveAttempts[0].saveInputBeganAt, input.dispatchStartedAt);
});
check('stable-save path adds neither click retry nor fixed settling sleep', () => { assert.equal(stable.clicks.length, 1); assert(stable.delays.every(ms => ms === 100 || ms === 65)); assert.equal(stable.delays.filter(ms => ms === 65).length, 1); });
check('actual mouse helper keeps move/down/up ordering and records every transport acknowledgement', () => {
  const trace = stable.active.saveInputs[0].events;
  assert.deepEqual([...trace].map(event => event.params.type), ['mouseMoved', 'mousePressed', 'mouseReleased']);
  assert.deepEqual([...trace].map(event => event.startedAt), [1200, 1200, 1265]);
  assert(trace.every(event => event.method === 'Input.dispatchMouseEvent' && event.acknowledgedAt === event.endedAt));
  assert.equal(stable.events.length, 3);
});
const moved = saveSnapshot(2); moved.visibleControls[0].rect.y += 100;
const finalMoved = structuredClone(moved); finalMoved.sampleFrame = 3; finalMoved.savePersistence.token = 7;
const moving = saveClickFixture({ samples: [saveSnapshot(1), moved, finalMoved], touch: true, canvas: { x: 20, y: 30, width: 640, height: 360, pixelWidth: 1920, pixelHeight: 1080 } });
await moving.context.saveProgressAndWait('settling menu');
check('changed layout resets stability and maps the final rect, not first visible rect', () => { assert.equal(moving.beforeReads, 3); assert.deepEqual([...moving.active.saveInputs[0].stableSampleFrames], [2, 3]); assert.deepEqual(moving.clicks[0].point, { x: 340, y: 180.75 }); });
check('autosave during geometry preparation becomes baseline, never explicit-save activation', () => { assert.equal(moving.active.saveInputs[0].previousToken, 7); assert.equal(moving.active.saveAttempts[0].previousToken, 7); assert.equal(moving.active.saveAttempts[0].observations[0].receipt.token, 8); });
check('touch provenance and actual scaled canvas are retained without backing-pixel coordinate drift', () => { assert.equal(moving.active.saveInputs[0].touch, true); assert.equal(moving.active.saveInputs[0].canvas.pixelWidth, 1920); assert.equal(moving.active.saveInputs[0].canvas.width, 640); });
check('actual touch helper sends one start/end pair and retains both event boundaries', () => {
  const trace = moving.active.saveInputs[0].events;
  assert.deepEqual([...trace].map(event => event.params.type), ['touchStart', 'touchEnd']);
  assert.equal(trace[0].params.touchPoints.length, 1); assert.equal(trace[1].params.touchPoints.length, 0);
  assert.equal(trace[1].startedAt - trace[0].startedAt, 65); assert(trace.every(event => event.acknowledgedAt === event.endedAt));
});
for (const kind of ['missing', 'duplicate', 'disabled', 'hidden', 'document-hidden', 'nan', 'zero-area', 'offscreen', 'bad-frame', 'bad-token']) {
  const invalid = saveSnapshot(1);
  if (kind === 'missing') invalid.visibleControls = [];
  if (kind === 'duplicate') invalid.visibleControls.push(structuredClone(invalid.visibleControls[0]));
  if (kind === 'disabled') invalid.visibleControls[0].disabled = true;
  if (kind === 'hidden') invalid.visibleControls[0].visible = false;
  if (kind === 'document-hidden') invalid.documentHidden = true;
  if (kind === 'nan') invalid.visibleControls[0].rect.x = NaN;
  if (kind === 'zero-area') invalid.visibleControls[0].rect.width = 0;
  if (kind === 'offscreen') invalid.visibleControls[0].rect.x = 1200;
  if (kind === 'bad-frame') invalid.sampleFrame = undefined;
  if (kind === 'bad-token') invalid.savePersistence.token = NaN;
  const fixture = saveClickFixture({ samples: [invalid, saveSnapshot(2), saveSnapshot(3)] });
  await fixture.context.saveProgressAndWait(kind);
  check(`${kind} save target cannot seed geometry stability or trigger input`, () => { assert.equal(fixture.beforeReads, 3); assert.deepEqual([...fixture.active.saveInputs[0].stableSampleFrames], [2, 3]); assert.equal(fixture.clicks.length, 1); });
}
const stale = saveClickFixture({ samples: [saveSnapshot(22)] });
await assert.rejects(stale.context.saveProgressAndWait('stale geometry'), /fresh native frames/);
check('a frozen cached frame fails within original target-discovery 20s without any click', () => { assert.equal(stale.now, 21000); assert.equal(stale.clicks.length, 0); assert.equal(stale.active.saveInputs[0].failureKind, 'save-control-not-stable'); assert.equal(stale.active.saveAttempts, undefined); });
for (const text of ['已保存', '正在保存…', '保存尚未完成，请稍后重试']) {
  const fixture = saveClickFixture({ beforeSnapshot: index => { const value = saveSnapshot(index + 1); value.visibleControls[0].text = text; return value; } });
  await assert.rejects(fixture.context.saveProgressAndWait('noninitial save label'), /fresh native frames/);
  check(`prior label ${text} is not a fresh explicit-save target even across fresh frames`, () => { assert.equal(fixture.clicks.length, 0); assert.equal(fixture.now, 21000); assert.equal(fixture.active.saveAttempts, undefined); });
}
for (const canvas of [{ width: 0 }, { x: NaN }, { documentHidden: true }, { x: 1000 }, { pixelWidth: 0 }]) {
  const fixture = saveClickFixture({ beforeSnapshot: index => saveSnapshot(index + 1), canvas });
  await assert.rejects(fixture.context.saveProgressAndWait('invalid canvas'), /fresh native frames/);
  check(`unusable DOM canvas ${JSON.stringify(canvas)} never receives a speculative click`, () => { assert.equal(fixture.clicks.length, 0); assert.equal(fixture.now, 21000); });
}
const failedDispatch = saveClickFixture({ clickError: 'CDP input rejected' });
await assert.rejects(failedDispatch.context.saveProgressAndWait('dispatch failure'), /CDP input rejected/);
check('failed single dispatch still records both boundaries and is never retried', () => { const input = failedDispatch.active.saveInputs[0]; assert.equal(failedDispatch.clicks.length, 1); assert.equal(input.dispatchStartedAt, 1100); assert.equal(input.dispatchEndedAt, 1165); assert.equal(input.dispatchCompleted, undefined); assert.equal(input.failureKind, 'save-input-dispatch-failed'); assert.equal(failedDispatch.active.saveAttempts, undefined); });
check('mouse release failure is distinguishable from a failed press without another event', () => { const trace = failedDispatch.active.saveInputs[0].events; assert.equal(trace.length, 3); assert.equal(trace[1].params.type, 'mousePressed'); assert.equal(trace[1].acknowledgedAt, 1100); assert.equal(trace[2].params.type, 'mouseReleased'); assert.equal(trace[2].error, 'CDP input rejected'); assert.equal(trace[2].acknowledgedAt, undefined); assert.equal(trace[2].endedAt, 1165); });
const failedTouch = saveClickFixture({ touch: true, clickError: 'CDP touch release rejected' });
await assert.rejects(failedTouch.context.saveProgressAndWait('touch release failure'), /CDP touch release rejected/);
check('touch release failure retains acknowledged press and failed end, with no retry', () => { const trace = failedTouch.active.saveInputs[0].events; assert.equal(trace.length, 2); assert.equal(trace[0].params.type, 'touchStart'); assert.equal(trace[0].acknowledgedAt, 1100); assert.equal(trace[1].params.type, 'touchEnd'); assert.equal(trace[1].error, 'CDP touch release rejected'); assert.equal(trace[1].endedAt, 1165); assert.equal(failedTouch.clicks.length, 1); });
const noToken = saveClickFixture({ afterSnapshot: (index, now, before) => saveSnapshot(3 + index, { visibleControls: [{ ...before.visibleControls[0], text: '已保存' }] }) });
await assert.rejects(noToken.context.saveProgressAndWait('unacknowledged input'), /no new native save token observed/);
check('old durable digest and old saved label never substitute for a new explicit-save token', () => {
  const attempt = noToken.active.saveAttempts[0]; assert.equal(attempt.failedAt - attempt.beganAt, 30000); assert.equal(attempt.failureKind, 'save-input-not-acknowledged');
  assert.equal(noToken.clicks.length, 1); assert.equal(noToken.accepted.length, 0); assert.equal(noToken.diskReads.length, 1);
});
const pendingSave = saveClickFixture({ afterSnapshot: (index, now) => saveSnapshot(3 + index, { saveDigest: targetDigest, savePersistence: { token: 4, digest: targetDigest, pending: now < 21165, error: now >= 21165 ? 'timeout' : '', acknowledgedDigest: '' } }) });
await assert.rejects(pendingSave.context.saveProgressAndWait('native timeout'), /new native save token observed, but exact persistence acceptance failed.*timeout/);
check('new-token production timeout is distinct and retains the same one 30s receipt window', () => { const attempt = pendingSave.active.saveAttempts[0]; assert.equal(attempt.failureKind, 'save-persistence-not-acknowledged'); assert.equal(attempt.failedAt - attempt.beganAt, 30000); assert.equal(pendingSave.clicks.length, 1); });
const lateToken = saveClickFixture({ afterSnapshot: (index, now) => saveSnapshot(3 + index, { saveDigest: targetDigest, savePersistence: { token: now >= 30165 ? 4 : 3, digest: targetDigest, pending: true, error: '', acknowledgedDigest: '' } }) });
await assert.rejects(lateToken.context.saveProgressAndWait('late native token'), /new native save token observed/);
check('late new token does not start another 30s persistence phase', () => { const attempt = lateToken.active.saveAttempts[0]; assert.equal(attempt.failedAt - attempt.beganAt, 30000); assert.equal(lateToken.clicks.length, 1); });
const wrongDigest = saveClickFixture({ afterSnapshot: index => saveSnapshot(3 + index, { visibleControls: [{ ...saveSnapshot(1).visibleControls[0], text: '已保存' }], saveDigest: targetDigest, savePersistence: { token: 4, digest: targetDigest, acknowledgedDigest: oldDigest, pending: false, error: '' } }) });
await assert.rejects(wrongDigest.context.saveProgressAndWait('wrong receipt hash'), /exact persistence acceptance failed/);
check('new token plus visible saved label cannot bypass exact receipt digest agreement', () => { assert.equal(wrongDigest.accepted.length, 0); assert.equal(wrongDigest.active.saveAttempts[0].failedAt - wrongDigest.active.saveAttempts[0].beganAt, 30000); });
const wrongDisk = saveClickFixture({ diskDigest: oldDigest });
await assert.rejects(wrongDisk.context.saveProgressAndWait('wrong primary hash'), /independent readonly IndexedDB primary/);
check('successful receipt cannot bypass independent primary-file digest agreement', () => assert.equal(wrongDisk.accepted.length, 0));
check('input evidence is serialized for both successful and failed browser cases', () => assert(draft.includes('    caseRecord.saveInputs = active.saveInputs || [];')));
check('save-input repair adds no native save mutation, sync or bridge write', () => {
  const helpers = draft.slice(draft.indexOf('function saveClickCandidate('), draft.indexOf('async function startStory('));
  assert(!/force_fs_sync|syncfs|save_game|__GODOT_755__|setTimeout/.test(helpers));
  assert.equal((helpers.match(/await clickPoint\(/g) || []).length, 1);
});
console.log(`PASS ${checks.length} pure Node checks; no browser, real IDB, or runtime acceptance executed.`);
