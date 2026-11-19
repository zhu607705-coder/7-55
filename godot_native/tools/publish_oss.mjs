import assert from 'node:assert/strict';
import { createHash } from 'node:crypto';
import { readFile, readdir } from 'node:fs/promises';
import { createRequire } from 'node:module';
import { extname, resolve } from 'node:path';
import { pathToFileURL } from 'node:url';
import { gunzipSync } from 'node:zlib';

const digest = (data) => createHash('sha256').update(data).digest('hex');
const publicFamilies = new Set([
  'phone_bonsai', 'phone_tiyi', 'phone_zjuding', 'chapter2', 'chapter2_campus', 'chapter2_library', 'flc_activity',
]);
const contentTypes = {
  '.html': 'text/html; charset=utf-8',
  '.js': 'text/javascript; charset=utf-8',
  '.json': 'application/json',
  '.wasm': 'application/wasm',
  '.pck': 'application/octet-stream',
  '.bin': 'application/octet-stream',
  '.gz': 'application/gzip',
};

export async function verifyRelease(directory, commit) {
  assert.match(commit, /^[a-f0-9]{40}$/);
  const build = JSON.parse(await readFile(resolve(directory, 'build-manifest.json'), 'utf8'));
  const chapters = JSON.parse(await readFile(resolve(directory, 'content-manifest.json'), 'utf8'));
  assert.equal(build.schema, '7-55-godot-web-release/v1');
  assert.equal(build.sourceCommit, commit, 'Artifact does not match this workflow commit');
  assert.equal(build.sourceDirty, false);
  assert.equal(build.production, true);
  assert.equal(build.releasePolicy?.publicChapterLimit, 2);
  assert.equal(chapters.publicChapterLimit, 2);
  assert(chapters.packs.length && chapters.packs.every((pack) => publicFamilies.has(pack.family)),
    'The public build contains unpublished chapter content');

  const files = new Map(build.files.map((record) => [record.path, record]));
  assert.equal(files.size, build.files.length, 'Duplicate build records');
  const listed = await readdir(directory, { recursive: true, withFileTypes: true });
  const actual = new Set();
  for (const entry of listed) {
    assert(entry.isDirectory() || entry.isFile(), 'Unexpected artifact entry type');
    if (entry.isFile()) actual.add(resolve(entry.parentPath, entry.name));
  }
  for (const [path, record] of files) {
    assert(path.split('/').every((part) => /^[a-zA-Z0-9_.-]+$/.test(part) && part !== '..' && part !== '.'),
      `Invalid build path: ${path}`);
    const filename = resolve(directory, path);
    assert(actual.delete(filename), `Artifact is missing ${path}`);
    const bytes = await readFile(filename);
    assert(bytes.length === record.bytes && digest(bytes) === record.sha256, `Artifact bytes differ: ${path}`);
  }
  actual.delete(resolve(directory, 'build-manifest.json'));
  actual.delete(resolve(directory, '.nojekyll'));
  assert.equal(actual.size, 0, 'Unexpected files in the public artifact');
  for (const path of ['index.html', 'index.js', 'index.wasm', 'index.pck', 'content-manifest.json']) {
    assert(files.has(path), `Missing ${path}`);
  }
  const compressed = new Map();
  for (const { source, file } of build.transportCompression.files) {
    assert(file === source + '.gz' && files.has(source) && files.has(file), 'Invalid gzip mapping');
    const unpacked = gunzipSync(await readFile(resolve(directory, file)));
    assert.equal(digest(unpacked), files.get(source).sha256, `Gzip bytes differ: ${source}`);
    compressed.set(source, file);
  }
  return { directory, files, compressed };
}

async function publicBytes(url) {
  const response = await fetch(url, { redirect: 'error', signal: AbortSignal.timeout(30000) });
  assert(response.ok, `Public OSS check returned ${response.status}: ${url}`);
  return Buffer.from(await response.arrayBuffer());
}

export async function publish(client, release, origin, version, runNumber, readPublic = publicBytes) {
  assert.match(version, /^[a-f0-9]{40}-\d+-\d+$/);
  const prefix = `releases/${version}/`;
  // A rerun of an older workflow may finish after a newer version is live.
  try {
    const previous = await client.head('index.html');
    if (Number(previous.res.headers['x-oss-meta-release-run'] || 0) > runNumber) {
      return { skipped: true };
    }
  } catch (error) {
    if (error.status !== 404) throw error;
  }

  const paths = [...release.files.keys(), 'build-manifest.json'];
  for (let start = 0; start < paths.length; start += 6) {
    await Promise.all(paths.slice(start, start + 6).map(async (path) => {
      const transport = release.compressed.get(path);
      const mime = contentTypes[extname(path)];
      const headers = { 'Cache-Control': 'public, max-age=31536000, immutable' };
      if (mime) headers['Content-Type'] = mime;
      if (transport) headers['Content-Encoding'] = 'gzip';
      await client.put(prefix + path, resolve(release.directory, transport || path), { mime, headers });
    }));
  }
  const sample = ['index.html', 'content-manifest.json', 'index.wasm'];
  for (const path of sample) {
    const bytes = await readPublic(origin + '/' + prefix + path);
    assert.equal(digest(bytes), release.files.get(path).sha256, `Public OSS bytes differ: ${path}`);
  }

  const destination = '/' + prefix + 'index.html';
  const entry = Buffer.from(`<!doctype html><meta charset="utf-8"><title>7:55</title>
<script>location.replace("${destination}" + location.search + location.hash)</script>
<a href="${destination}">进入《7:55》</a>\n`);
  await client.put('index.html', entry, {
    mime: contentTypes['.html'],
    headers: { 'Content-Type': contentTypes['.html'], 'Cache-Control': 'no-store',
      'x-oss-meta-release-run': String(runNumber) },
  });
  assert.deepEqual(await readPublic(origin + '/index.html'), entry, 'OSS root object did not update');
  assert.deepEqual(await readPublic(origin + '/'), entry, 'Set the OSS static website homepage to index.html');
  return { skipped: false, prefix, count: paths.length };
}

async function main() {
  const [, , directory, commit] = process.argv;
  const env = process.env;
  const release = await verifyRelease(directory, commit);
  const hostname = env.OSS_GAME_DOMAIN;
  assert.match(hostname || '', /^[a-z0-9-]+(?:\.[a-z0-9-]+)+$/);
  assert(env.OSS_ACCESS_KEY_ID && env.OSS_ACCESS_KEY_SECRET, 'OSS credentials are missing');
  const OSS = createRequire(import.meta.url)('ali-oss');
  const origin = 'https://' + hostname;
  const client = new OSS({
    accessKeyId: env.OSS_ACCESS_KEY_ID,
    accessKeySecret: env.OSS_ACCESS_KEY_SECRET,
    stsToken: env.OSS_SESSION_TOKEN || undefined,
    bucket: env.OSS_BUCKET,
    region: 'oss-' + env.OSS_REGION,
    endpoint: origin,
    cname: true,
    secure: true,
    authorizationV4: true,
    timeout: 60000,
  });
  const info = await publish(client, release, origin,
    `${commit}-${env.GITHUB_RUN_ID}-${env.GITHUB_RUN_ATTEMPT}`, Number(env.GITHUB_RUN_NUMBER));
  console.log(info.skipped ? 'A newer release is already live.' : `Published ${info.count} objects to ${origin}/`);
}

if (process.argv[1] && import.meta.url === pathToFileURL(process.argv[1]).href) {
  main().catch((error) => {
    // SDK error objects may contain request signing headers.
    console.error([error.code, error.message].filter(Boolean).join(': '));
    process.exitCode = 1;
  });
}
