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
    'index.html': Buffer.from('<title>7:55</title>'),
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
    async put(path, source, { headers }) {
      objects.set(path, { bytes: Buffer.isBuffer(source) ? source : await readFile(source), headers });
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
  assert.match(home.toString(), new RegExp(`/releases/${version}/index.html`));
  assert((await publish(oss, release, origin, commit + '-7-2', 7, oss.read)).skipped);
  await assert.rejects(publish(oss, release, origin, commit + '-9-1', 9, async () => Buffer.from('bad')),
    /Public OSS bytes differ/);
  assert.deepEqual(oss.objects.get('index.html').bytes, home);
});
