// Dependency-light regression of the shipped runner's actual CDP handlers and
// unblock/retry sequence. Synthetic events do not claim browser/game acceptance.
import assert from 'node:assert/strict';
import { readFile } from 'node:fs/promises';
import { test } from 'node:test';
import vm from 'node:vm';

const runner = await readFile(new URL('../tools/verify_web_export.mjs', import.meta.url), 'utf8');
function between(begin, end) {
  const start = runner.indexOf(begin), stop = runner.indexOf(end, start + begin.length);
  assert(start >= 0 && stop > start, `actual runner block exists: ${begin}`);
  assert.equal(runner.indexOf(begin, start + begin.length), -1, `unambiguous runner block: ${begin}`);
  return runner.slice(start, stop);
}
const unblock = between("  active.faultPhase = 'c2-deferred-unblock-pending';", '  const ready = await poll(async () => {');
const handlerPrefix = '    active.cdp = await connect(target.webSocketDebuggerUrl, ({ method, params }) => {\n';
const eventHandler = between(handlerPrefix, '    });\n    // Confirm durable body observation').slice(handlerPrefix.length);
const checkSource = between('function check(ok, label, details)', 'async function persist()');
const finalGates = between('    check(![...network.values()].some(n => n.status >= 400)', '    const renderer = await evaluate(');
const url = 'https://synthetic.invalid/7-55/content/chapter2_013-exact.pck';
const settle = async () => { for (let i = 0; i < 8; i++) await Promise.resolve(); };
const clone = value => structuredClone(value);
function deferred() {
  let resolve, reject;
  const promise = new Promise((yes, no) => { resolve = yes; reject = no; });
  return { promise, resolve, reject };
}

function fixture() {
  let time = 1000;
  const ack = deferred(), calls = [], errors = [], network = new Map();
  const active = {
    faultPhase: 'c2-required-failure', controlledBlockedUrls: new Set([url]), deferredUrls: new Set([url]),
    streaming: { controlledFailures: [] }, requests: [], requestsById: new Map(),
    cdp: { send(method, params) {
      calls.push({ method, params: clone(params) });
      assert.equal(method, 'Network.setBlockedURLs');
      assert.deepEqual(clone(params), { urls: [] });
      return ack.promise;
    } },
  };
  const context = vm.createContext({ active, errors, network, responses: new Map(),
    delivery: { bootByUrl: new Map(), deferredChunksByUrl: new Map() },
    Date: { now: () => time++ }, report: { checks: [] }, id: 'synthetic-streaming',
    clickControl: async (name, field) => { calls.push({ method: 'clickControl', name, field }); },
  });
  const functions = vm.runInContext(`${checkSource}\nasync function restore(){${unblock}}\nfunction emit(method, params){${eventHandler}}\nfunction finish(){${finalGates}}\n({restore,emit,finish})`, context);
  const request = (requestId, requestUrl = url) => functions.emit('Network.requestWillBeSent', {
    requestId, loaderId: 'document-1', frameId: 'main-frame', request: { url: requestUrl, headers: {} },
  });
  const fail = (requestId, overrides = {}) => functions.emit('Network.loadingFailed', {
    requestId, canceled: false, errorText: '', blockedReason: 'inspector', ...overrides,
  });
  return { active, ack, calls, errors, network, request, fail, ...functions };
}

test('a pending unblock retains exact injected requests; Retry begins only after acknowledgement', async () => {
  const f = fixture(); let restored = false;
  const pending = f.restore().then(() => { restored = true; });
  await settle();
  assert.equal(restored, false);
  assert.equal(f.active.faultPhase, 'c2-deferred-unblock-pending');
  assert.equal(f.active.controlledBlockedUrls.has(url), true);
  assert.equal(f.active.streaming.unblock.acknowledgedAt, undefined);
  assert.equal(f.active.streaming.unblock.retryRequestedAt, undefined);
  assert.deepEqual(f.calls.map(call => call.method), ['Network.setBlockedURLs']);
  f.request('during-disable'); f.fail('during-disable');
  assert.equal(f.active.requestsById.get('during-disable').controlled, true);
  assert.equal(f.active.streaming.controlledFailures.length, 1);
  assert.equal(f.active.streaming.controlledFailures[0].phase, 'c2-deferred-unblock-pending');
  assert.equal(f.active.streaming.controlledFailures[0].requestId, 'during-disable');
  assert.equal(f.errors.length, 0);
  f.ack.resolve({}); await pending;
  assert.equal(restored, true);
  assert.equal(f.active.controlledBlockedUrls.size, 0);
  assert.equal(f.active.faultPhase, 'c2-user-retry-recovery');
  const trace = f.active.streaming.unblock;
  assert(trace.requestedAt < trace.acknowledgedAt && trace.acknowledgedAt < trace.retryRequestedAt);
  assert.deepEqual(f.calls.at(-1), { method: 'clickControl', name: 'RetryRequiredContent', field: 'name' });
  assert.doesNotThrow(f.finish);
});

test('loadingFailed after acknowledgement retains an already observed injected request identity', async () => {
  const f = fixture(), pending = f.restore();
  f.request('observed-before-ack');
  f.ack.resolve({}); await pending;
  f.fail('observed-before-ack', { errorText: 'net::ERR_BLOCKED_BY_CLIENT' });
  assert.equal(f.active.streaming.controlledFailures.length, 1);
  assert.equal(f.active.streaming.controlledFailures[0].phase, 'c2-deferred-unblock-pending');
  assert.equal(f.errors.length, 0);
  assert.doesNotThrow(f.finish);
});

test('a failed unblock fails closed without clearing fault identity or clicking Retry', async () => {
  const f = fixture(), failure = new Error('CDP disable rejected');
  const pending = assert.rejects(f.restore(), error => error === failure);
  f.ack.reject(failure); await pending;
  assert.equal(f.active.controlledBlockedUrls.has(url), true);
  assert.equal(f.active.streaming.unblock.acknowledgedAt, undefined);
  assert.equal(f.active.streaming.unblock.retryRequestedAt, undefined);
  assert.deepEqual(f.calls.map(call => call.method), ['Network.setBlockedURLs']);
});

test('the same URL with an uninjected inspector failure after acknowledgement remains fatal', async () => {
  const f = fixture(), pending = f.restore();
  f.ack.resolve({}); await pending;
  f.request('genuine-after-ack'); f.fail('genuine-after-ack');
  assert.equal(f.active.requestsById.get('genuine-after-ack').controlled, false);
  assert.equal(f.active.streaming.controlledFailures.length, 0);
  assert.equal(f.errors.length, 1);
  assert.throws(f.finish, /no page, runtime, script or uncancelled network errors/);
});

for (const [label, requestUrl, overrides] of [
  ['unlisted URL', `${url}?not-injected=1`, {}],
  ['real network error on injected URL', url, { errorText: 'net::ERR_CONNECTION_RESET', blockedReason: '' }],
  ['unexpected error text with inspector reason', url, { errorText: 'net::ERR_FAILED' }],
  ['non-inspector block', url, { blockedReason: 'csp' }],
]) test(`${label} is not hidden during the pending-disable window`, async () => {
  const f = fixture(), pending = f.restore();
  f.request('unexpected', requestUrl); f.fail('unexpected', overrides);
  assert.equal(f.active.streaming.controlledFailures.length, 0);
  assert.equal(f.errors.length, 1);
  assert.throws(f.finish, /no page, runtime, script or uncancelled network errors/);
  f.ack.resolve({}); await pending;
});

test('an inspector event without an observed request identity remains fatal', () => {
  const f = fixture(); f.fail('unknown-request');
  assert.equal(f.active.streaming.controlledFailures.length, 0);
  assert.equal(f.errors.length, 1);
  assert.throws(f.finish, /no page, runtime, script or uncancelled network errors/);
});

test('a normal successful recovery after unblock still passes the actual network/error gates', async () => {
  const f = fixture(), pending = f.restore();
  f.ack.resolve({}); await pending;
  f.request('successful-retry');
  f.emit('Network.responseReceived', { requestId: 'successful-retry', response: { url, status: 200, mimeType: 'application/octet-stream' } });
  f.emit('Network.loadingFinished', { requestId: 'successful-retry', encodedDataLength: 1234 });
  assert.equal(f.active.requestsById.get('successful-retry').controlled, false);
  assert.equal(f.network.get(url).status, 200);
  assert.equal(f.errors.length, 0);
  assert.doesNotThrow(f.finish);
});

test('a recovered HTTP error still fails the unchanged HTTP gate', async () => {
  const f = fixture(), pending = f.restore();
  f.ack.resolve({}); await pending;
  f.request('bad-http');
  f.emit('Network.responseReceived', { requestId: 'bad-http', response: { url, status: 503 } });
  f.emit('Network.loadingFinished', { requestId: 'bad-http', encodedDataLength: 0 });
  assert.throws(f.finish, /no failed HTTP resources/);
});

test('a runtime error remains fatal even after an accepted injected network failure', () => {
  const f = fixture(); f.request('injected'); f.fail('injected');
  f.emit('Runtime.exceptionThrown', { exceptionDetails: { text: 'real runtime failure' } });
  assert.equal(f.active.streaming.controlledFailures.length, 1);
  assert.equal(f.errors.length, 1);
  assert.throws(f.finish, /no page, runtime, script or uncancelled network errors/);
});
