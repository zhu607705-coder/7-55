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
const finalGates = between('    const standaloneGuest = ', '    const renderer = await evaluate(');
const url = 'https://synthetic.invalid/7-55/content/chapter2_013-exact.pck';
const settle = async () => { for (let i = 0; i < 8; i++) await Promise.resolve(); };
const clone = value => structuredClone(value);
function deferred() {
  let resolve, reject;
  const promise = new Promise((yes, no) => { resolve = yes; reject = no; });
  return { promise, resolve, reject };
}

function fixture(pageUrl = 'https://synthetic.invalid/7-55/') {
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
  const context = vm.createContext({ active, errors, network, responses: new Map(), url: pageUrl, URL,
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

for (const [label, page, responseUrl, status, accepted] of [
  ['static session 404 is an explicit guest probe', 'https://synthetic.invalid/7-55/', 'https://synthetic.invalid/api/v1/session', 404, true],
  ['static game asset 404 remains fatal', 'https://synthetic.invalid/7-55/', url, 404, false],
  ['static session 500 remains fatal', 'https://synthetic.invalid/7-55/', 'https://synthetic.invalid/api/v1/session', 500, false],
  ['another origin is not a guest probe', 'https://synthetic.invalid/7-55/', 'https://other.invalid/api/v1/session', 404, false],
  ['integrated session 404 remains fatal', 'https://synthetic.invalid/game/', 'https://synthetic.invalid/api/v1/session', 404, false],
  ['integrated index session 404 remains fatal', 'https://synthetic.invalid/game/index.html', 'https://synthetic.invalid/api/v1/session', 404, false],
]) test(label, () => {
  const f = fixture(page);
  f.network.set(responseUrl, {url: responseUrl, status});
  if (accepted) assert.doesNotThrow(f.finish);
  else assert.throws(f.finish, /no failed HTTP resources/);
});

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

// Execute the runner's independent storage probe, without host status or receipts.
const { createHash, webcrypto } = await import('node:crypto');
const sha = bytes => createHash('sha256').update(bytes).digest('hex');
const cacheProbe = between('async function readContentCache(packs)', 'async function cachedContentEvidence(packs)');
async function probe(pack, rows, whole, denied = false) {
  let closed = false;
  const context = vm.createContext({ ArrayBuffer, Uint8Array, URL, crypto: webcrypto, location: { origin: 'https://synthetic.invalid' },
    indexedDB: { open(name) {
      assert.equal(name, '755-godot-resources-v1');
      if (denied) throw Error('IDB denied');
      const request = {};
      queueMicrotask(() => {
        request.result = { close() { closed = true; }, transaction(storeName, mode) {
          assert.equal(storeName, 'chunks'); assert.equal(mode, 'readonly');
          const tx = {}, reads = [];
          tx.objectStore = () => ({ get(key) { const read = {}; reads.push([key, read]); return read; } });
          queueMicrotask(() => { for (const [key, read] of reads) read.result = rows.get(key); tx.oncomplete(); });
          return tx;
        } };
        request.onsuccess();
      });
      return request;
    } },
    caches: { keys: async () => whole ? ['755-godot-content-v1'] : [], open: async name => {
      assert.equal(name, '755-godot-content-v1');
      return { match: async key => {
        assert.equal(key, `https://synthetic.invalid/.755-content-cache/${pack.sha256}.pck`);
        return new Response(whole);
      } };
    } },
  });
  const result = await vm.runInContext(`${cacheProbe}\nreadContentCache`, context)([pack]);
  assert.equal(closed, !denied);
  return result.packs[0];
}
function storedPack(staticChunks = false) {
  const bytes = new Uint8Array(1048576 + 31).fill(17), pack = { id: 'chapter2_probe', bytes: bytes.length, sha256: sha(bytes) }, rows = new Map();
  if (staticChunks) pack.transportChunks = [];
  for (let offset = 0, index = 0; offset < bytes.length; offset += 1048576, index++) {
    const part = bytes.slice(offset, offset + 1048576), digest = sha(part);
    if (staticChunks) pack.transportChunks.push({ bytes: part.length, sha256: digest, offset });
    rows.set(staticChunks ? 'chunk:' + digest : pack.sha256 + ':' + index, { bytes: part.buffer, digest });
  }
  return { bytes, pack, rows };
}
for (const staticChunks of [false, true]) test(`independent content probe verifies all ${staticChunks ? 'static' : 'ordinary'} IDB bytes and detects a duplicate`, async () => {
  const { bytes, pack, rows } = storedPack(staticChunks);
  const idb = await probe(pack, rows);
  assert.equal(idb.indexedDB.complete, true); assert.equal(idb.indexedDB.sha256, pack.sha256); assert.equal(idb.cacheStorage.present, false);
  const duplicate = await probe(pack, rows, bytes);
  assert.equal(duplicate.indexedDB.complete, true); assert.equal(duplicate.cacheStorage.complete, true);
  assert.equal(!duplicate.indexedDB.complete || !duplicate.cacheStorage.present, false);
});
test('independent probe rejects missing/corrupt IDB data but accepts the SHA-verified whole-cache fallback', async () => {
  const { bytes, pack, rows } = storedPack(); rows.delete(pack.sha256 + ':1');
  assert.equal((await probe(pack, rows)).indexedDB.complete, false);
  const fallback = await probe(pack, rows, bytes);
  assert.equal(fallback.indexedDB.complete, false); assert.equal(fallback.cacheStorage.complete, true);
  const denied = await probe(pack, rows, bytes, true);
  assert.equal(denied.indexedDB.complete, false); assert.equal(denied.cacheStorage.complete, true);
  assert.equal((await probe(pack, rows, bytes.slice(1), true)).cacheStorage.complete, false);
});
test('ordinary local block digests cannot replace the full manifest SHA gate', async () => {
  const { pack, rows } = storedPack(); const row = rows.get(pack.sha256 + ':0');
  new Uint8Array(row.bytes)[0] ^= 1; row.digest = sha(new Uint8Array(row.bytes));
  assert.equal((await probe(pack, rows)).indexedDB.complete, false);
});
test('independent probe accepts valid legacy static-chunk keys without migrating or writing', async () => {
  const { pack, rows } = storedPack(true);
  pack.transportChunks.forEach((chunk, index) => { rows.set(pack.sha256 + ':' + index, rows.get('chunk:' + chunk.sha256)); rows.delete('chunk:' + chunk.sha256); });
  assert.equal((await probe(pack, rows)).indexedDB.complete, true);
});
test('streaming acceptance keeps real reload, zero content network, and items/wallet gates', () => {
  assert.match(runner, /requests\.length === 0, 'ordinary reload makes no C2 HTTP requests/);
  assert.match(runner, /performance\.timeOrigin'\) !== oldDocument/);
  assert.match(runner, /cache-only reload preserves earned items and wallet/);
  assert.match(runner, /!pack\.indexedDB\.complete \|\| pack\.cacheStorage\.present === false/);
});
