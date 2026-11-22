import assert from 'node:assert/strict';
import { createHash } from 'node:crypto';
import { mkdtemp, readFile, rm, writeFile } from 'node:fs/promises';
import { tmpdir } from 'node:os';
import { join } from 'node:path';
import test from 'node:test';
import { gzipSync, gunzipSync } from 'node:zlib';
import { publish, verifyRelease } from '../tools/publish_oss.mjs';

const commit = 'a'.repeat(40);
const origin = 'https://755.zjuxlab.com';

async function fixture(t, family = 'chapter2') {
  const directory = await mkdtemp(join(tmpdir(), '755-oss-'));
  t.after(() => rm(directory, { recursive: true, force: true }));
  const files = {
    'index.html': Buffer.from('<!doctype html><html><head><title>7:55</title></head><body><script src="index.js"></script></body></html>'),
    'index.js': Buffer.from('console.log(755)'),
    'index.wasm': Buffer.from('web assembly'),
    'index.pck': Buffer.from('main pack'),
    'content-manifest.json': Buffer.from(JSON.stringify({ publicChapterLimit: 2, packs: [{ family }] })),
  };
  files['index.wasm.gz'] = gzipSync(files['index.wasm']);
  const records = [];
  for (const [path, data] of Object.entries(files)) {
    await writeFile(join(directory, path), data);
    records.push({ path, bytes: data.length, sha256: createHash('sha256').update(data).digest('hex') });
  }
  await writeFile(join(directory, 'build-manifest.json'), JSON.stringify({
    schema: '7-55-godot-web-release/v1', sourceCommit: commit, sourceDirty: false, production: true,
    releasePolicy: { publicChapterLimit: 2 }, files: records,
    transportCompression: { files: [{ source: 'index.wasm', file: 'index.wasm.gz' }] },
  }));
  return directory;
}

function bucket() {
  const objects = new Map();
  return {
    objects,
    async head(path) {
      if (!objects.has(path)) throw Object.assign(new Error('Missing object'), { status: 404 });
      return { res: { headers: objects.get(path).headers } };
    },
    async put(path, source, { headers, timeout }) {
      objects.set(path, { bytes: Buffer.isBuffer(source) ? source : await readFile(source), headers, timeout });
    },
    async read(url) {
      const path = new URL(url).pathname.slice(1) || 'index.html';
      const value = objects.get(path);
      assert(value, `No public object: ${path}`);
      return value.headers['Content-Encoding'] === 'gzip' ? gunzipSync(value.bytes) : value.bytes;
    },
  };
}

test('verifies a public artifact and refuses later chapters, dirty bytes and unlisted files', async (t) => {
  const directory = await fixture(t);
  assert.equal((await verifyRelease(directory, commit)).compressed.get('index.wasm'), 'index.wasm.gz');
  await assert.rejects(verifyRelease(await fixture(t, 'chapter3'), commit), /unpublished chapter/);
  await assert.rejects(verifyRelease(directory, 'b'.repeat(40)), /workflow commit/);
  await writeFile(join(directory, 'internal-data.json'), '{}');
  await assert.rejects(verifyRelease(directory, commit), /Unexpected files/);
  await writeFile(join(directory, 'index.wasm'), 'different');
  await assert.rejects(verifyRelease(directory, commit), /Artifact bytes differ/);
});

test('serves gzip with the original MIME type and promotes only after assets match', async (t) => {
  const release = await verifyRelease(await fixture(t), commit);
  const oss = bucket();
  const version = commit + '-8-1';
  const result = await publish(oss, release, origin, version, 8, oss.read);
  const wasm = oss.objects.get(result.prefix + 'index.wasm');
  assert.equal(wasm.headers['Content-Encoding'], 'gzip');
  assert.equal(wasm.headers['Content-Type'], 'application/wasm');
  const home = oss.objects.get('index.html').bytes;
  assert.equal(wasm.timeout, 180000);
  assert.equal(oss.objects.get('index.html').headers['Cache-Control'], 'no-store');
  const publicEntry = home.toString();
  const versionEntry = oss.objects.get(result.prefix + 'index.html').bytes.toString();
  assert.equal(publicEntry, versionEntry.replace('<head>', `<head>\n  <base href="/${result.prefix}">`));
  assert.doesNotMatch(publicEntry, /location\.replace|http-equiv=["']refresh/);
  const pageUrl = new URL('/?playtest=1#start', origin);
  const base = new URL(publicEntry.match(/<base href="([^"]+)">/)[1], pageUrl);
  assert.equal(new URL('index.js', base).href, origin + '/' + result.prefix + 'index.js');
  assert((await publish(oss, release, origin, commit + '-7-2', 7, oss.read)).skipped);
  await assert.rejects(publish(oss, release, origin, commit + '-9-1', 9, async () => Buffer.from('bad')),
    /Public OSS bytes differ/);
  assert.deepEqual(oss.objects.get('index.html').bytes, home);
});

test('retries a timed-out PUT with identical bytes and verifies public assets before promotion', async (t) => {
  const release = await verifyRelease(await fixture(t), commit);
  const oss = bucket();
  const originalPut = oss.put;
  const version = commit + '-10-1';
  const wasmKey = `releases/${version}/index.wasm`;
  const attempts = [], waits = [];
  oss.put = async (path, source, options) => {
    // The object reached OSS, but the response was lost. Repeating this exact
    // object is safe; restarting publication or promoting early is not.
    await originalPut(path, source, options);
    if (path === wasmKey) {
      attempts.push({ source, options, bytes: Buffer.from(oss.objects.get(path).bytes) });
      if (attempts.length < 3) throw Object.assign(new Error('Response timeout for 180000ms'), {
        name: 'ResponseTimeoutError', status: -1,
      });
    }
  };
  let manifestReads = 0;
  const read = async (url) => {
    if (url.endsWith('/content-manifest.json') && ++manifestReads === 1) {
      throw Object.assign(new Error('Service unavailable'), { status: 503 });
    }
    return oss.read(url);
  };
  const result = await publish(oss, release, origin, version, 10, read, { wait: async (delay) => {
    assert(!oss.objects.has('index.html'), 'The public entry must not move while assets are being retried');
    waits.push(delay);
  } });
  assert.equal(result.skipped, false);
  assert.equal(attempts.length, 3);
  assert.deepEqual(attempts[0], attempts[1]);
  assert.deepEqual(attempts[1], attempts[2]);
  assert.deepEqual(waits, [1000, 2000, 1000]);
  assert.equal(manifestReads, 2);
  assert.equal(oss.objects.get('index.html').headers['x-oss-meta-release-run'], '10');
});

test('exhausted network retries preserve the previous public entry', async (t) => {
  const release = await verifyRelease(await fixture(t), commit);
  const oss = bucket();
  const home = Buffer.from('previous accepted entry');
  oss.objects.set('index.html', { bytes: home, headers: { 'x-oss-meta-release-run': '11' } });
  const originalPut = oss.put;
  let attempts = 0;
  const waits = [];
  oss.put = async (path, source, options) => {
    if (path.endsWith('/index.pck')) {
      attempts++;
      throw Object.assign(new Error('Connection reset'), { code: 'ECONNRESET' });
    }
    return originalPut(path, source, options);
  };
  await assert.rejects(publish(oss, release, origin, commit + '-12-1', 12, oss.read,
    { wait: async (delay) => waits.push(delay) }), /Connection reset/);
  assert.equal(attempts, 3);
  assert.deepEqual(waits, [1000, 2000]);
  assert.deepEqual(oss.objects.get('index.html').bytes, home);
});

test('authorization, malformed requests and integrity mismatches fail without retries', async (t) => {
  const release = await verifyRelease(await fixture(t), commit);
  for (const status of [400, 403]) {
    const oss = bucket();
    const originalPut = oss.put;
    let attempts = 0;
    oss.put = async (path, source, options) => {
      if (path.endsWith('/index.pck')) {
        attempts++;
        throw Object.assign(new Error(`Permanent HTTP ${status}`), { status });
      }
      return originalPut(path, source, options);
    };
    await assert.rejects(publish(oss, release, origin, commit + '-13-1', 13, oss.read,
      { wait: async () => assert.fail('Permanent errors must not be retried') }), /Permanent HTTP/);
    assert.equal(attempts, 1);
    assert(!oss.objects.has('index.html'));
  }
  const oss = bucket();
  let reads = 0;
  await assert.rejects(publish(oss, release, origin, commit + '-14-1', 14,
    async () => { reads++; return Buffer.from('different release bytes'); },
    { wait: async () => assert.fail('Integrity failures must not be retried') }), /Public OSS bytes differ/);
  assert.equal(reads, 1);
  assert(!oss.objects.has('index.html'));
});

test('retries fetch transport failures and a lost promotion response without changing the release', async (t) => {
  const release = await verifyRelease(await fixture(t), commit);
  const oss = bucket();
  const originalPut = oss.put;
  let promotions = 0, assetReads = 0;
  const entries = [], waits = [];
  oss.put = async (path, source, options) => {
    await originalPut(path, source, options);
    if (path === 'index.html') {
      entries.push(Buffer.from(oss.objects.get(path).bytes));
      if (++promotions === 1) throw Object.assign(new Error('Response lost after PUT'), {
        name: 'ResponseTimeoutError', status: -1,
      });
    }
  };
  t.mock.method(globalThis, 'fetch', async (url) => {
    if (url.endsWith('/content-manifest.json')) {
      assetReads++;
      if (assetReads === 1) throw new TypeError('fetch failed', { cause: Object.assign(new Error('reset'), { code: 'ECONNRESET' }) });
      if (assetReads === 2) return new Response('Try later', { status: 503 });
    }
    return new Response(await oss.read(url), { status: 200 });
  });
  const result = await publish(oss, release, origin, commit + '-15-1', 15, undefined,
    { wait: async (delay) => waits.push(delay) });
  assert.equal(result.skipped, false);
  assert.equal(assetReads, 3);
  assert.equal(promotions, 2);
  assert.deepEqual(entries[0], entries[1]);
  assert.deepEqual(waits, [1000, 2000, 1000]);
  assert.equal(oss.objects.get('index.html').timeout, 180000);
});
