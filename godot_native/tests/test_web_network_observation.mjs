// Dependency-light contract tests of the shipped runner's actual source blocks.
// Synthetic CDP events only: no Chrome, HTTP replay, Godot or runtime acceptance.
import assert from 'node:assert/strict';
import { createHash } from 'node:crypto';
import { readFile } from 'node:fs/promises';
import { test } from 'node:test';
import vm from 'node:vm';

const runner = await readFile(new URL('../tools/verify_web_export.mjs', import.meta.url), 'utf8');
const workflow = await readFile(new URL('../../.github/workflows/deploy-pages.yml', import.meta.url), 'utf8');
function between(begin, end) {
  const start = runner.indexOf(begin), stop = runner.indexOf(end, start + begin.length);
  assert(start >= 0 && stop > start, `actual runner block exists: ${begin}`);
  assert.equal(runner.indexOf(begin, start + begin.length), -1, `unambiguous runner block: ${begin}`);
  return runner.slice(start, stop);
}
const helper = between('async function enableNetworkObservation(session)', '\nlet active;');
const setup = between("    await active.cdp.send('Page.enable'); await active.cdp.send('Runtime.enable');", "    if (scenarios === 'mobile-world') await mobileWorldCase();");
// Keep only the real navigation prefix: engine boot/input following it is not
// simulated or claimed as browser proof by this dependency-light test.
const navigatePrefix = between('async function startStory(reload = false)', '  await poll(() => evaluate("document.documentElement.dataset.bootState');
const bodyHandler = between("      if (method === 'Network.loadingFinished' && responses.has(params.requestId))", "      if (method === 'Network.loadingFailed' && !params.canceled)");
const deferredGate = between('    await Promise.all(active.bootBodyJobs);', '    const chunkedOriginals =');
const checkSource = between('function check(ok, label, details)', 'async function persist()');
const capacity = { maxTotalBufferSize: 128 * 1024 * 1024, maxResourceBufferSize: 2 * 1024 * 1024 };
const version = { product: 'Chrome/155.0.8059.39', protocolVersion: '1.3', revision: 'synthetic-revision', jsVersion: 'synthetic-v8' };
const clone = value => structuredClone(value);
const settle = async () => { for (let i = 0; i < 16; i++) await Promise.resolve(); };
function deferred() { let resolve, reject; const promise = new Promise((yes, no) => { resolve = yes; reject = no; }); return { promise, resolve, reject }; }

function networkFixture({ hold, failAt, error = new Error('synthetic CDP failure') } = {}) {
  let clock = 1000, freshCalls = 0;
  const calls = [], forbidden = [];
  const cdp = { send: async (method, params = {}, timeout) => {
    calls.push({ method, params: clone(params), timeout, at: clock++ });
    if (method === failAt) throw error;
    if (method === 'Browser.getVersion') return clone(version);
    if (method === 'Network.configureDurableMessages' && hold) return hold.promise;
    if (['Network.enable', 'Network.configureDurableMessages', 'Page.enable', 'Runtime.enable',
      'Emulation.setDeviceMetricsOverride', 'Emulation.setTouchEmulationEnabled',
      'Browser.setDownloadBehavior', 'Page.navigate', 'Page.reload'].includes(method)) return {};
    forbidden.push(method); throw new Error(`unexpected CDP method: ${method}`);
  } };
  const active = { id: 'touch-390', cdp, downloadDir: '/synthetic-downloads' };
  const context = vm.createContext({ active, Date: { now: () => clock++ }, scenarios: 'all',
    width: 390, height: 844, touch: true, dpr: 1, url: 'https://synthetic.invalid/index.html',
    fetch: () => { forbidden.push('fetch'); throw new Error('HTTP fallback forbidden'); },
    waitForPersistedSave: async () => { calls.push({ method: 'save-before-reload', at: clock++ }); },
    freshCase: async () => { freshCalls++; return context.navigation(false); },
  });
  vm.runInContext(`${helper}\n${navigatePrefix}\n}\nthis.navigation=startStory;\nasync function initialize(){let result;\n${setup}\nreturn result;}\nthis.initialize=initialize; this.enable=enableNetworkObservation;`, context);
  return { active, calls, forbidden, error, initialize: context.initialize,
    enable: () => context.enable(active), reload: () => context.navigation(true),
    get freshCalls() { return freshCalls; }, advance: n => { clock += n; } };
}

test('active workflow executes this test; failure/success evidence retains the actual observation', () => {
  assert.match(workflow, /^\s+node godot_native\/tests\/test_web_network_observation\.mjs\s*$/m);
  assert.match(runner, /finally \{\s*const caseRecord = report\.cases\.at\(-1\);\s*caseRecord\.networkObservation = active\.networkObservation;/);
  assert.match(setup, /await enableNetworkObservation\(active\);/);
  assert.equal((runner.match(/await enableNetworkObservation\(active\)/g) || []).length, 1);
});

test('actual setup acknowledges the fixed-cap durable command before first navigation', async () => {
  const f = networkFixture(); await f.initialize();
  assert.deepEqual(f.calls.map(row => row.method), ['Page.enable', 'Runtime.enable', 'Browser.getVersion', 'Network.enable',
    'Network.configureDurableMessages', 'Emulation.setDeviceMetricsOverride', 'Emulation.setTouchEmulationEnabled',
    'Browser.setDownloadBehavior', 'Page.navigate']);
  const observation = f.active.networkObservation;
  assert.deepEqual(clone(observation.browser), version);
  assert.equal(observation.maxTotalBufferSize, capacity.maxTotalBufferSize);
  assert.equal(observation.maxResourceBufferSize, capacity.maxResourceBufferSize);
  assert.equal(observation.durableMessages, true);
  assert(observation.startedAt < observation.networkEnabledAt && observation.networkEnabledAt < observation.confirmedAt);
  assert.equal(observation.navigations.length, 1);
  assert(observation.confirmedAt < observation.navigations[0].requestedAt);
  assert(observation.navigations[0].requestedAt < observation.navigations[0].acknowledgedAt);
  for (const row of f.calls.filter(row => row.method.startsWith('Network.'))) {
    assert.deepEqual(row.params, capacity); assert.equal(row.timeout, undefined, 'retain the existing CDP timeout');
  }
  assert.equal(f.freshCalls, 1); assert.deepEqual(f.forbidden, []);
});

test('late configuration cannot return, start the case or navigate before its actual acknowledgement', async () => {
  const hold = deferred(), f = networkFixture({ hold }); let finished = false;
  const pending = f.initialize().then(() => { finished = true; });
  await settle(); f.advance(29000); await settle();
  assert.equal(f.active.networkObservation.durableMessages, false);
  assert.equal(f.active.networkObservation.confirmedAt, undefined);
  assert.equal(f.freshCalls, 0); assert.equal(finished, false);
  assert.equal(f.calls.at(-1).method, 'Network.configureDurableMessages');
  assert.equal(f.calls.filter(row => row.method === 'Network.configureDurableMessages').length, 1);
  assert.equal(f.active.networkObservation.navigations.length, 0);
  hold.resolve({}); await pending;
  assert.equal(finished, true); assert.equal(f.freshCalls, 1);
  assert(f.active.networkObservation.confirmedAt < f.active.networkObservation.navigations[0].requestedAt);
  assert.deepEqual(f.forbidden, []);
});

for (const [failAt, message] of [
  ['Browser.getVersion', 'CDP connection closed'],
  ['Network.enable', 'Network.enable rejected'],
  ['Network.configureDurableMessages', "'Network.configureDurableMessages' wasn't found"],
  ['Network.configureDurableMessages', 'CDP timeout Network.configureDurableMessages'],
  ['Network.configureDurableMessages', 'invalid parameters'],
]) test(`${failAt}: ${message} fails closed without navigation, retry or HTTP fallback`, async () => {
  const error = new Error(message), f = networkFixture({ failAt, error });
  await assert.rejects(f.initialize(), failure => {
    assert.match(failure.message, /Required durable network response observation failed:/);
    assert(failure.message.includes(message)); assert.equal(failure.cause, error); return true;
  });
  const observation = f.active.networkObservation;
  assert.equal(observation.error, message); assert(observation.failedAt >= observation.startedAt);
  assert.equal(observation.durableMessages, false); assert.equal(observation.confirmedAt, undefined);
  assert.equal(observation.navigations.length, 0); assert.equal(f.freshCalls, 0);
  assert.equal(f.calls.at(-1).method, failAt);
  assert.equal(f.calls.filter(row => row.method === failAt).length, 1);
  assert.deepEqual(f.forbidden, []);
});

test('late rejected configuration is a failure, not a timeout permission to start', async () => {
  const hold = deferred(), f = networkFixture({ hold });
  const pending = assert.rejects(f.initialize(), /Required durable network response observation failed: disconnected/);
  await settle(); f.advance(30000); assert.equal(f.freshCalls, 0);
  hold.reject(new Error('disconnected')); await pending;
  assert.equal(f.freshCalls, 0); assert.equal(f.active.networkObservation.navigations.length, 0);
  assert.equal(f.calls.filter(row => row.method === 'Network.configureDurableMessages').length, 1);
});

test('ordinary reload retains observation without reconfiguration or replay', async () => {
  const f = networkFixture(); await f.initialize(); await f.reload();
  assert.deepEqual(f.calls.slice(-2).map(row => row.method), ['save-before-reload', 'Page.reload']);
  assert.deepEqual(f.calls.at(-1).params, { ignoreCache: true });
  assert.equal(f.calls.filter(row => row.method === 'Network.configureDurableMessages').length, 1);
  assert.deepEqual(clone(f.active.networkObservation.navigations.map(row => row.method)), ['Page.navigate', 'Page.reload']);
  assert.deepEqual(f.forbidden, []);
});

const bytes = Buffer.from([0, 255, 1, 128, 65, 66, 67]);
const hash = value => createHash('sha256').update(value).digest('hex');
const chunkUrl = 'https://synthetic.invalid/content/chunks/chapter2-0001.bin';
const expected = { bytes: bytes.length, sha256: hash(bytes) };
function bodyFixture({ result = { body: bytes.toString('base64'), base64Encoded: true }, bodyError, hold } = {}) {
  let clock = 2000;
  const calls = [], checks = [], responses = new Map(), requestsById = new Map();
  const active = { bootBodyJobs: [], bootResponses: [], deferredResponses: [], requestsById,
    cdp: { send: async (method, params) => {
      calls.push({ method, params: clone(params) });
      assert.equal(method, 'Network.getResponseBody', 'no fetch/replay/retry command');
      if (bodyError) throw bodyError;
      return hold ? hold.promise : result;
    } } };
  const delivery = { bootByUrl: new Map(), deferredChunksByUrl: new Map([[chunkUrl, expected]]) };
  const context = vm.createContext({ active, delivery, responses, network: new Map(),
    Buffer, hash, Date: { now: () => clock++ }, id: 'retina-touch-390', report: { checks },
    fetch: () => { throw new Error('HTTP fallback forbidden'); } });
  const functions = vm.runInContext(`${checkSource}\nfunction onFinished(method,params){${bodyHandler}}\nasync function verify(){${deferredGate}}\n({onFinished,verify})`, context);
  function emit(overrides = {}) {
    const requestId = `request-${responses.size + 1}`;
    responses.set(requestId, { url: chunkUrl, status: 200, ...overrides });
    requestsById.set(requestId, { at: 1990, range: '' });
    functions.onFinished('Network.loadingFinished', { requestId, encodedDataLength: 100 });
    return active.deferredResponses.at(-1);
  }
  return { active, delivery, checks, calls, emit, verify: functions.verify, advance: n => { clock += n; } };
}

test('actual body handler hashes binary bytes and original deferred loop accepts exact HTTP evidence', async () => {
  const f = bodyFixture(), row = f.emit();
  assert.equal(row.pending, true); await f.verify();
  assert.equal(row.pending, false); assert.equal(row.bytes, bytes.length); assert.equal(row.sha256, hash(bytes));
  assert(row.bodyObservedAt >= row.loadingFinishedAt); assert.equal(row.error, undefined);
  assert.equal(f.checks.length, 1); assert.equal(f.checks[0].ok, true);
  assert.deepEqual(f.calls, [{ method: 'Network.getResponseBody', params: { requestId: 'request-1' } }]);
});

test('plain response text uses actual UTF-8 bytes rather than the expected hash', async () => {
  const text = '实际 response bytes';
  const f = bodyFixture({ result: { body: text, base64Encoded: false } });
  f.delivery.deferredChunksByUrl.set(chunkUrl, { bytes: Buffer.byteLength(text), sha256: hash(text) });
  f.emit(); await f.verify(); assert.equal(f.checks[0].ok, true);
});

test('actual equal-length wrong body bytes cannot inherit the manifest digest', async () => {
  const changed = Buffer.from(bytes); changed[0] = 1;
  const f = bodyFixture({ result: { body: changed.toString('base64'), base64Encoded: true } }), row = f.emit();
  await assert.rejects(f.verify(), /observed deferred chunk passes independent response-byte verification/);
  assert.equal(row.bytes, expected.bytes); assert.equal(row.sha256, hash(changed));
  assert.notEqual(row.sha256, expected.sha256); assert.equal(f.calls.length, 1);
});

test('a malformed successful CDP reply cannot become verified response evidence', async () => {
  const f = bodyFixture({ result: {} }), row = f.emit();
  await assert.rejects(f.verify(), /observed deferred chunk passes independent response-byte verification/);
  assert.equal(row.pending, false); assert(row.error); assert.equal(row.sha256, undefined);
  assert.equal(f.calls.length, 1);
});

test('deferred gate awaits outstanding body evidence and cannot pass on loadingFinished alone', async () => {
  const hold = deferred(), f = bodyFixture({ hold }), row = f.emit(); let finished = false;
  const pending = f.verify().then(() => { finished = true; });
  await settle(); f.advance(10000);
  assert.equal(row.pending, true); assert.equal(finished, false); assert.equal(f.checks.length, 0);
  assert.equal(f.calls.length, 1);
  hold.resolve({ body: bytes.toString('base64'), base64Encoded: true }); await pending;
  assert.equal(finished, true); assert.equal(f.checks[0].ok, true); assert.equal(f.calls.length, 1);
});

for (const message of ['No resource with given identifier found', 'CDP timeout Network.getResponseBody', 'CDP connection closed']) {
  test(`body observation error still fails: ${message}`, async () => {
    const f = bodyFixture({ bodyError: new Error(message) }), row = f.emit();
    await assert.rejects(f.verify(), /observed deferred chunk passes independent response-byte verification/);
    assert.equal(row.error, message); assert.equal(row.pending, false);
    assert(row.bodyFailedAt >= row.loadingFinishedAt); assert.equal(row.sha256, undefined);
    assert.equal(f.checks[0].ok, false); assert.equal(f.calls.length, 1);
  });
}

for (const [name, mutate] of [
  ['missing manifest identity', (row, f) => f.delivery.deferredChunksByUrl.delete(row.url)],
  ['pending', row => { row.pending = true; }],
  ['body error despite matching bytes', row => { row.error = 'lost response'; }],
  ['HTTP partial 206', row => { row.status = 206; }],
  ['HTTP redirect 302', row => { row.status = 302; }],
  ['HTTP error 404', row => { row.status = 404; }],
  ['string status instead of HTTP number', row => { row.status = '200'; }],
  ['Range request', row => { row.range = 'bytes=0-6'; }],
  ['short body', row => { row.bytes--; }],
  ['oversized body', row => { row.bytes++; }],
  ['wrong SHA', row => { row.sha256 = '0'.repeat(64); }],
  ['missing body SHA', row => { delete row.sha256; }],
]) test(`unmodified deferred loop rejects ${name}`, async () => {
  const f = bodyFixture(), row = f.emit(); await Promise.all(f.active.bootBodyJobs);
  mutate(row, f);
  await assert.rejects(f.verify(), /observed deferred chunk passes independent response-byte verification/);
  assert.equal(f.checks[0].ok, false); assert.equal(f.calls.length, 1);
});

test('a verified first chunk does not hide a second invalid response', async () => {
  const f = bodyFixture(); f.emit(); const bad = f.emit(); await Promise.all(f.active.bootBodyJobs);
  bad.sha256 = 'f'.repeat(64);
  await assert.rejects(f.verify(), /observed deferred chunk passes independent response-byte verification/);
  assert.deepEqual(f.checks.map(row => row.ok), [true, false]); assert.equal(f.calls.length, 2);
});
