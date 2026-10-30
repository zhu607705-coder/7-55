#!/usr/bin/env node
// Small in-memory transport fixtures. This proves the JS loader contract, not
// Godot resource mounting, story continuity, physical devices or network speed.
import assert from 'node:assert/strict';
import crypto from 'node:crypto';
import fs from 'node:fs';
import vm from 'node:vm';
import { fileURLToPath } from 'node:url';

const filename = fileURLToPath(new URL('../web/content_loader.js', import.meta.url));
const source = fs.readFileSync(filename, 'utf8');
const digest = bytes => crypto.createHash('sha256').update(bytes).digest('hex');
const checks = [];
const origin = 'https://game.example.test';
const baseURI = `${origin}/7-55/releases/aaaaaaaaaaaa-bbbbbbbbbbbbbbbb/`;
const body = name => new TextEncoder().encode(`tiny actual payload: ${name}\n`);
function pack(id, family) {
  const bytes = body(id), sha256 = digest(bytes);
  return { id, family, file: `content/${id}-${sha256.slice(0, 16)}.pck`, bytes: bytes.byteLength, sha256 };
}
const packs = [pack('chapter2_a', 'chapter2'), pack('chapter2_b', 'chapter2'), pack('chapter3_a', 'chapter3'), pack('chapter4_a', 'chapter4')];
const manifest = {
  schema: '755-web-content-v1', engine: '4.7.1',
  core: { file: 'index.pck', bytes: 4, sha256: digest(new Uint8Array([1, 2, 3, 4])) },
  packs, backgroundOrder: ['chapter2', 'chapter3', 'chapter35', 'chapter4'],
};
const snapshot = host => JSON.parse(host.snapshot());
const record = (host, id) => snapshot(host).packs.find(item => item.id === id);
const request = (host, ...ids) => host.request(JSON.stringify(ids));
const retry = (host, ...ids) => host.retry(JSON.stringify(ids));
const turn = () => new Promise(resolve => setImmediate(resolve));
async function until(predicate, label) {
  // Real WebCrypto and the loader's timer yields need elapsed time, not a
  // machine-dependent number of immediate-loop turns on a busy CI worker.
  const deadline = performance.now() + 5000;
  while (!predicate()) {
    if (performance.now() >= deadline) throw new Error(`Timed out waiting for ${label}`);
    await new Promise(resolve => setTimeout(resolve, 1));
  }
}
async function quiet() { for (let index = 0; index < 5; index++) await turn(); }
function response(id, overrides = {}) { return new Response(body(id), { status: 200, ...overrides }); }
function deferred() { let resolve, reject; const promise = new Promise((yes, no) => { resolve = yes; reject = no; }); return { promise, resolve, reject }; }
function idb(storage) {
  return {open(){const request={};setImmediate(()=>{
    request.result={objectStoreNames:{contains:()=>true},close(){},transaction(){const transaction={objectStore(){return {
      get:key=>run(()=>storage.get(key)),put:(value,key)=>run(()=>{storage.set(key,structuredClone(value));return key;}),delete:key=>run(()=>storage.delete(key))
    };}};function run(action){const result={};setImmediate(()=>{result.result=action();result.onsuccess?.();setImmediate(()=>transaction.oncomplete?.());});return result;}return transaction;}};request.onsuccess?.();});return request;}};
}
function chunkedPack(bytes,id='chapter2_large',family='chapter2') {
  const sha256=digest(bytes),transportChunks=[];
  for(let offset=0;offset<bytes.length;offset+=1048576){const part=bytes.subarray(offset,offset+1048576),sha256=digest(part);transportChunks.push({file:`content/chunks/${id}-${String(transportChunks.length+1).padStart(4,'0')}-${sha256.slice(0,16)}.bin`,offset,bytes:part.length,sha256});}
  return {id,family,file:`content/${id}-${sha256.slice(0,16)}.pck`,bytes:bytes.length,sha256,transportChunks};
}
function fixture(options = {}) {
  const events = [], requests = [], copies = [], raf = [], visibilityListeners = new Set();
  const documentBase = options.baseURI || baseURI;
  const stored = options.stored || new Map();
  const chunks = options.chunks || new Map();
  const cacheEvents = [];
  const store = {
    async match(key) { cacheEvents.push(['match', key]); return stored.get(key)?.clone() || null; },
    async put(key, value) { cacheEvents.push(['put', key]); if (options.cachePutFails) throw new Error('Quota fixture'); stored.set(key, value.clone()); },
    async delete(key) { cacheEvents.push(['delete', key]); return stored.delete(key); },
  };
  const context = {
    window: {}, document: { baseURI: documentBase, hidden: false,
      addEventListener: (name, fn) => { if (name === 'visibilitychange') visibilityListeners.add(fn); },
      removeEventListener: (name, fn) => { if (name === 'visibilitychange') visibilityListeners.delete(fn); } }, location: { origin },
    navigator: { connection: { saveData: Boolean(options.saveData) } },
    URL, Response, TextEncoder, TextDecoder, setTimeout, AbortController, ArrayBuffer, Uint8Array, Uint32Array, DataView, ReadableStream,
    crypto: options.crypto || (options.noCrypto ? {} : crypto.webcrypto),
    ...(options.idb?{indexedDB:idb(chunks)}:{}),
    requestAnimationFrame: callback => { raf.push(callback); return raf.length; },
    fetch: async (url, init) => {
      const info = { url, init, sequence: requests.length + 1 };
      requests.push(info);
      if (options.fetch) return options.fetch(info);
      const found = packs.find(item => url === new URL(item.file, documentBase).href);
      assert.ok(found, `Unexpected network URL: ${url}`);
      return response(found.id);
    },
    ...(options.noCache ? {} : { caches: { open: async name => { assert.equal(name, '755-godot-content-v1'); return store; } } }),
  };
  vm.runInNewContext(options.source||source, context, { filename, timeout: 1000 });
  const api = context.window.Godot755Content;
  const engine = { copyToFS: (name, buffer) => {
    if (options.copyFails) throw new Error('MEMFS fixture failed');
    copies.push({ name, bytes: Buffer.from(new Uint8Array(buffer)) });
  } };
  const host = api.create({ manifest: structuredClone(options.manifest||manifest), engine });
  host.install((id, name, error) => events.push({ id, name, error }));
  return { api, host, events, requests, copies, raf, stored, chunks, cacheEvents, store, visibilityListeners,
    setHidden(value) { context.document.hidden = value; for (const listener of visibilityListeners) listener(); },
    async frame() { assert.ok(raf.length, 'A frame must have been scheduled'); const callbacks = raf.splice(0); for (const callback of callbacks) callback(); await quiet(); } };
}
function check(name, value) { assert.ok(value, name); checks.push(name); }

// Creation, installation, first-chapter input and the first optional frame never
// request a deferred resource. This is a transport test, not a paint benchmark.
{
  const f = fixture();
  await quiet();
  check('Creating and installing the loader does not fetch core or any deferred PCK', f.requests.length === 0 && f.copies.length === 0);
  f.host.startPrefetch();
  await quiet();
  check('Scheduling prefetch does not start a network request before a frame', f.requests.length === 0);
  await f.frame();
  check('The first scheduled frame leaves first-chapter rendering/input ahead of deferred requests', f.requests.length === 0 && snapshot(f.host).background === false);
  await f.frame();
  await until(() => f.events.length === 1, 'first background mount request');
  check('Two scheduled frames enable the first chapter-ordered background pack', f.requests.length === 1 && f.requests[0].url === new URL(packs[0].file, baseURI).href && f.requests[0].init.priority === 'low');
  check('A downloaded pack waits for native mount acknowledgement before requesting another', snapshot(f.host).active === packs[0].id && record(f.host, packs[0].id).status === 'mounting' && f.requests.length === 1);
  check('No JavaScript cache entry is created before native acknowledgement', f.cacheEvents.filter(event => event[0] === 'put').length === 0);
  f.host.dispose();
}

// Explicit foreground demand cancels optional transfer before its completion;
// even a transport that resolves late must not reach MEMFS or the native callback.
{
  const held = deferred();
  const f = fixture({ fetch: info => info.sequence === 1 ? held.promise : response(packs.find(item => info.url.endsWith(item.file)).id) });
  f.host.startPrefetch(); await f.frame(); await f.frame();
  await until(() => f.requests.length === 1, 'held background request');
  request(f.host, packs[3].id, packs[3].id);
  await until(() => f.events.length === 1, 'foreground after cancellation');
  check('Foreground demand aborts optional in-flight work and starts required content at high priority', f.requests[0].init.signal.aborted && f.events[0].id === packs[3].id && f.requests[1].init.priority === 'high');
  check('Optional cancellation returns its record to idle without a visible transport error', record(f.host, packs[0].id).status === 'idle' && record(f.host, packs[0].id).error === '' && f.events.length === 1);
  held.resolve(response(packs[0].id)); await quiet();
  check('A late response from cancelled optional work never copies stale bytes or emits a callback', f.copies.length === 1 && f.copies[0].bytes.equals(Buffer.from(body(packs[3].id))) && f.events.length === 1);
  f.host.setPrefetchFamilies('[]');
  await f.host.acknowledge(packs[3].id, true, '');
  check('Foreground mounting completes normally after preemption', record(f.host, packs[3].id).status === 'mounted' && snapshot(f.host).active === '');
  f.host.dispose();
}

// Visibility/window cancellation and upgrading the same pending optional pack
// to an explicit requirement are distinct from cancelling unrelated work.
for (const kind of ['hidden', 'window', 'same-required']) {
  const held = deferred();
  const f = fixture({fetch: () => held.promise});
  f.host.startPrefetch(); await f.frame(); await f.frame();
  await until(() => f.requests.length === 1, 'optional request');
  if (kind === 'hidden') f.setHidden(true);
  if (kind === 'window') f.host.setPrefetchFamilies('[]');
  if (kind === 'same-required') { request(f.host, packs[0].id); f.setHidden(true); }
  if (kind === 'same-required') {
    check('Requiring the already active pack preserves its transfer even when the page becomes hidden', !f.requests[0].init.signal.aborted && snapshot(f.host).active === packs[0].id);
    held.resolve(response(packs[0].id)); await until(() => f.events.length === 1, 'upgraded requirement');
    await f.host.acknowledge(packs[0].id, true, '');
  } else {
    await until(() => snapshot(f.host).active === '', 'cancel optional ' + kind);
    check('Optional transfer aborts with no error on ' + kind, f.requests[0].init.signal.aborted && f.events.length === 0 && record(f.host, packs[0].id).status === 'idle');
    held.resolve(response(packs[0].id)); await quiet();
    check('Late optional response remains inert after ' + kind, f.copies.length === 0 && f.events.length === 0);
  }
  f.host.dispose();
}

// Test-only introspection proves host-owned bytes are released; it does not
// imply that a PCK already copied into the engine can be unmounted by this host.
{
  const instrumented = source.replace('return host;', 'host.retainedBytesForTest = () => [...records.values()].reduce((sum, record) => sum + (record.buffer?.byteLength || 0), 0); return host;');
  const f = fixture({source: instrumented}); request(f.host, packs[0].id);
  await until(() => f.events.length === 1, 'dispose mounting candidate');
  check('A mount candidate holds its verified transport bytes until native acknowledgement', f.host.retainedBytesForTest() === packs[0].bytes);
  f.host.dispose();
  check('Disposing during mounting releases host buffers and active record immediately', f.host.retainedBytesForTest() === 0 && snapshot(f.host).active === '' && record(f.host, packs[0].id).status === 'idle');
  await f.host.acknowledge(packs[0].id, true, ''); request(f.host, packs[2].id); await quiet();
  check('Late acknowledgement and requests after disposal cannot cache, remount or restart work', f.cacheEvents.filter(item => item[0] === 'put').length === 0 && f.requests.length === 1 && f.host.retainedBytesForTest() === 0);
}

// A verified 1 MiB chunk survives optional cancellation and is reusable after
// a new page/loader, while the currently partial response is discarded.
{
  const bytes = Buffer.alloc(1048576 * 4 + 57);
  for (let i=0; i<bytes.length; i++) bytes[i]=(i*29+(i>>>10)+(i>>>20)*17)&255;
  const large = chunkedPack(bytes), held = deferred();
  const smallManifest = {...manifest,packs:[large,packs[3]]};
  const f = fixture({manifest:smallManifest,idb:true,noCache:true,fetch:info=>{
    if (info.url.endsWith(packs[3].file)) return response(packs[3].id);
    const chunk=large.transportChunks.find(item=>info.url.endsWith(item.file));
    return chunk.offset===0 ? new Response(bytes.subarray(0,1048576)) : held.promise;
  }});
  f.host.startPrefetch();await f.frame();await f.frame();
  await until(()=>f.chunks.has('chunk:'+large.transportChunks[0].sha256),'durable optional chunk');
  request(f.host,packs[3].id);await until(()=>f.events.length===1,'foreground after chunk cancellation');
  check('Chunked optional transfer cancels sibling requests while preserving the verified complete chunk', f.events[0].id===packs[3].id && f.requests.filter(item=>item.url.includes('/chunks/')).every(item=>item.init.signal.aborted) && f.chunks.has('chunk:'+large.transportChunks[0].sha256));
  f.host.dispose();
  const reopened=fixture({manifest:smallManifest,idb:true,chunks:f.chunks,noCache:true,fetch:info=>{
    const chunk=large.transportChunks.find(item=>info.url.endsWith(item.file));
    assert.ok(chunk);return new Response(bytes.subarray(chunk.offset,chunk.offset+chunk.bytes));
  }});
  request(reopened.host,large.id);await until(()=>reopened.events.length===1,'resumed chunked mount');
  check('A new loader requests only missing chunks and verifies the final PCK before copying it', reopened.requests.length===large.transportChunks.length-1 && reopened.copies[0].bytes.equals(bytes) && record(reopened.host,large.id).source==='resumed-network');
  check('Deferred static chunks use complete hash-named GETs without Range headers', reopened.requests.every(item=>item.url.includes('/content/chunks/') && item.init.headers===undefined));
  reopened.host.dispose();
}

// Hash checks use real WebCrypto. A same-length substitution must not reach
// MEMFS, and recovery requires the explicit user retry method.
{
  const bad = body(packs[0].id); bad[0] ^= 0xff;
  const f = fixture({ fetch: info => info.sequence === 1 ? new Response(bad) : response(packs[0].id) });
  request(f.host, packs[0].id);
  await until(() => f.events.length === 1, 'digest rejection');
  check('A same-length SHA-256 mismatch is rejected before engine copy or mounting', f.copies.length === 0 && record(f.host, packs[0].id).status === 'error' && /digest differs/.test(f.events[0].error));
  check('Integrity failure evicts any cached response instead of persisting corrupt bytes', f.cacheEvents.some(event => event[0] === 'delete') && !f.cacheEvents.some(event => event[0] === 'put'));
  request(f.host, packs[0].id); await quiet();
  check('An ordinary repeated request does not hide an integrity failure with an automatic retry', f.requests.length === 1 && record(f.host, packs[0].id).attempts === 1);
  retry(f.host, packs[0].id);
  await until(() => f.events.length === 2, 'user integrity retry');
  check('An explicit user retry downloads a fresh complete pack and reaches mounting once', f.requests.length === 2 && record(f.host, packs[0].id).attempts === 2 && record(f.host, packs[0].id).status === 'mounting' && f.copies.length === 1);
  await f.host.acknowledge(packs[0].id, true, '');
  check('Only the successful retried native mount is committed to cache', record(f.host, packs[0].id).status === 'mounted' && f.cacheEvents.filter(event => event[0] === 'put').length === 1);
  f.host.dispose();
}

// Truncation/overflow are checked while reading, independently of WebCrypto.
for (const kind of ['truncated', 'overflow']) {
  let cancelled = 0, reads = 0;
  const bytes = kind === 'truncated' ? body(packs[0].id).slice(0, -1) : new Uint8Array(packs[0].bytes + 1);
  const f = fixture({ noCrypto: true, fetch: () => ({ ok: true, status: 200, body: { getReader: () => ({ read: async () => reads++ === 0 ? { done: false, value: bytes } : { done: true }, cancel: async () => { cancelled++; } }) } }) });
  request(f.host, packs[0].id);
  await until(() => f.events.length === 1, `${kind} rejection`);
  check(`A ${kind} streamed response is rejected without WebCrypto before engine copy/cache`, f.copies.length === 0 && record(f.host, packs[0].id).status === 'error' && /Incomplete content|Content size differs/.test(f.events[0].error) && !f.cacheEvents.some(event => event[0] === 'put'));
  if (kind === 'overflow') check('An overflowing stream reader is explicitly cancelled', cancelled === 1);
  f.host.dispose();
}

// A transport without a streaming body still enforces its declared byte count.
{
  const f = fixture({ fetch: () => ({ ok: true, status: 200, body: null, arrayBuffer: async () => new Uint8Array(1).buffer }) });
  request(f.host, packs[0].id); await until(() => f.events.length === 1, 'arrayBuffer size rejection');
  check('The arrayBuffer fallback also rejects a wrong byte count before MEMFS', f.copies.length === 0 && /Content size differs|Incomplete content/.test(f.events[0].error));
  f.host.dispose();
}

// Native verification remains authoritative when WebCrypto is unavailable on
// plain-IP HTTP. Copying a file alone is never permission to cache it.
{
  const f = fixture({ noCrypto: true });
  request(f.host, packs[0].id); await until(() => f.events.length === 1, 'native verification candidate');
  check('Without WebCrypto, the candidate waits for native validation with no cache write', f.copies.length === 1 && record(f.host, packs[0].id).status === 'mounting' && !f.cacheEvents.some(event => event[0] === 'put'));
  await f.host.acknowledge(packs[0].id, false, 'native digest/mount rejected');
  check('A rejected native digest/mount never caches the candidate and remains a visible error', record(f.host, packs[0].id).status === 'error' && record(f.host, packs[0].id).error === 'native digest/mount rejected' && !f.cacheEvents.some(event => event[0] === 'put') && f.cacheEvents.some(event => event[0] === 'delete'));
  f.host.dispose();
}

// A verified mounted cache entry is reusable by a new loader at the same origin,
// even if the new page is running under a different immutable release path.
{
  const f = fixture(); request(f.host, packs[0].id);
  await until(() => f.events.length === 1, 'cache producer candidate');
  await f.host.acknowledge(packs[0].id, true, '');
  const key = `${origin}/.755-content-cache/${packs[0].sha256}.pck`;
  check('Accepted native mounting caches bytes under the full content digest, independent of release URL', f.stored.has(key));
  f.host.dispose();
  const reuse = fixture({ stored: f.stored, baseURI: `${origin}/7-55/releases/cccccccccccc-dddddddddddddddd/`, fetch: () => { throw new Error('Unexpected cache-miss network'); } });
  request(reuse.host, packs[0].id); await until(() => reuse.events.length === 1, 'verified cache reuse');
  check('A fresh loader at a different release path verifies and copies cached bytes without network', reuse.requests.length === 0 && reuse.copies.length === 1 && record(reuse.host, packs[0].id).source === 'verified-cache');
  await reuse.host.acknowledge(packs[0].id, true, '');
  check('Reusing verified cache does not rewrite the same cache entry', record(reuse.host, packs[0].id).status === 'mounted' && !reuse.cacheEvents.some(event => event[0] === 'put'));
  reuse.host.dispose();
}

// HTTP and MEMFS errors remain retryable, visible transport failures. Cache
// capacity failure after a real native mount must not undo that mounted state.
{
  const f = fixture({ fetch: info => info.sequence === 1 ? new Response('', { status: 503 }) : response(packs[0].id) });
  request(f.host, packs[0].id); await until(() => f.events.length === 1, 'HTTP rejection');
  check('HTTP failure reports its status without copying, caching or auto-retrying', f.events[0].error === 'HTTP 503' && f.copies.length === 0 && f.requests.length === 1 && record(f.host, packs[0].id).status === 'error');
  retry(f.host, packs[0].id); await until(() => f.events.length === 2, 'HTTP user retry');
  check('The explicit retry clears the HTTP failure and produces one fresh mount candidate', record(f.host, packs[0].id).attempts === 2 && f.copies.length === 1 && f.events[1].error === '');
  f.host.dispose();
  const failedCopy = fixture({ copyFails: true });
  request(failedCopy.host, packs[0].id); await until(() => failedCopy.events.length === 1, 'MEMFS rejection');
  check('MEMFS copy failure cannot report a mount candidate or persist the response', failedCopy.events[0].name === '' && /MEMFS fixture failed/.test(failedCopy.events[0].error) && !failedCopy.cacheEvents.some(event => event[0] === 'put'));
  failedCopy.host.dispose();
  const quota = fixture({ cachePutFails: true });
  request(quota.host, packs[0].id); await until(() => quota.events.length === 1, 'quota candidate');
  await quota.host.acknowledge(packs[0].id, true, '');
  check('Cache quota failure after native mount does not revert an accepted mounted pack', record(quota.host, packs[0].id).status === 'mounted' && snapshot(quota.host).active === '');
  quota.host.dispose();
}

{
  const f = fixture({ noCache: true, noCrypto: true });
  request(f.host, packs[0].id); await until(() => f.events.length === 1, 'plain-IP transport candidate');
  await f.host.acknowledge(packs[0].id, true, '');
  check('Without CacheStorage or WebCrypto the loader still waits for and accepts native verification', record(f.host, packs[0].id).status === 'mounted' && f.requests.length === 1 && f.cacheEvents.length === 0);
  f.host.dispose();
}

{
  const f = fixture({ saveData: true });
  f.host.startPrefetch(); await f.frame(); await f.frame(); await quiet();
  check('saveData suppresses optional background downloads after both scheduled frames', snapshot(f.host).saveData && snapshot(f.host).background && f.requests.length === 0);
  request(f.host, packs[2].id); await until(() => f.events.length === 1, 'saveData foreground demand');
  check('saveData still permits an explicitly required foreground chapter at high priority', f.requests.length === 1 && f.requests[0].init.priority === 'high' && f.requests[0].url === new URL(packs[2].file, baseURI).href);
  await f.host.acknowledge(packs[2].id, true, ''); await quiet();
  check('Completing explicit foreground work does not restart saveData background traffic', f.requests.length === 1 && snapshot(f.host).active === '');
  f.host.dispose();
}

// Malformed metadata must not become a network request. Actual PCK membership
// and full-export coverage are separately proved by the packaging tools.
{
  const f = fixture();
  const escape = structuredClone(manifest); escape.packs[0].file = '../escape.pck';
  assert.throws(() => f.api.validate(escape), /Invalid content path/);
  const huge = structuredClone(manifest); huge.packs[0].bytes = 24_000_001;
  assert.throws(() => f.api.validate(huge), /Invalid content group/);
  check('Escaping paths and oversized deferred packs are rejected before any fetch', f.requests.length === 0);
  f.host.dispose();
}

// Optional work is bounded to one next-chapter family. Explicit old-save or
// navigation requirements still outrank that window, including while hidden.
{
  const f = fixture();
  f.host.startPrefetch(); await f.frame(); await f.frame();
  await until(() => f.events.length === 1, 'first lookahead part');
  await f.host.acknowledge(packs[0].id, true, '');
  await until(() => f.events.length === 2, 'second lookahead part');
  await f.host.acknowledge(packs[1].id, true, ''); await quiet();
  check('Finishing the next chapter does not fetch or mount all later chapters', f.requests.length === 2 && snapshot(f.host).active === '' && record(f.host, packs[2].id).status === 'idle');
  f.setHidden(true); f.host.setPrefetchFamilies(JSON.stringify(['chapter3'])); await quiet();
  check('A hidden page defers new optional requests when the lookahead advances', f.requests.length === 2);
  f.setHidden(false); await until(() => f.events.length === 3, 'visible lookahead resumes');
  check('Returning to visibility resumes precisely the next family', f.events[2].id === packs[2].id);
  await f.host.acknowledge(packs[2].id, true, '');
  f.host.setPrefetchFamilies('[]'); f.setHidden(true); request(f.host, packs[3].id);
  await until(() => f.events.length === 4, 'explicit demand beyond lookahead');
  check('Explicit required content bypasses optional lookahead and visibility limits', f.events[3].id === packs[3].id && f.requests[3].init.priority === 'high');
  await f.host.acknowledge(packs[3].id, true, '');
  f.host.setPrefetchFamilies('["chapter2","chapter4"]');
  check('An invalid multi-chapter window is rejected', snapshot(f.host).prefetchFamilies.length === 0);
  f.host.dispose(); check('Disposal removes its visibility listener', f.visibilityListeners.size === 0);
}

// Optional FLC is explicitly recognized but is not added to story prefetch.
{
 const optional=structuredClone(manifest);
 optional.packs[0].family='flc_activity';
 const f=fixture({manifest:optional});
 check('Approved FLC family passes transport manifest validation', Boolean(f.host));
 check('Optional activity is absent from ordinary story background order', !optional.backgroundOrder.includes('flc_activity'));
}

console.log(JSON.stringify({
  success: true, checks: checks.length, loaderSha256: digest(source),
  scope: 'Node VM with real SHA-256 and tiny in-memory browser/cache/fetch/engine fixtures; no real video, network download, story mutation or native mounting',
  details: checks,
}, null, 2));
