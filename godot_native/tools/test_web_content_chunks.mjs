#!/usr/bin/env node
// Byte-level positive and corruption controls. Real PCK mount/coverage remains
// the independent partition tool's responsibility, not a synthetic fixture.
import fs from 'node:fs';
import os from 'node:os';
import path from 'node:path';
import crypto from 'node:crypto';
import assert from 'node:assert/strict';
import { CONTENT_CHUNK_BYTES, CONTENT_PACK_TARGET, CONTENT_PACK_LIMIT, createContentChunks, verifyContentChunks } from './web_content_chunks.mjs';
import { prepareWebCompression, verifyWebCompression } from './web_precompress.mjs';
import { contentSizeException } from './web_content_delivery.mjs';

const directory = fs.mkdtempSync(path.join(os.tmpdir(), '755-content-chunks-'));
const hash = bytes => crypto.createHash('sha256').update(bytes).digest('hex');
const clone = value => JSON.parse(JSON.stringify(value));
const checks = [];
try {
  fs.mkdirSync(path.join(directory, 'content'));
  const pack = (id, bytes) => {
    const data = Buffer.alloc(bytes);
    for (let at = 0; at < bytes; at++) data[at] = (at * 17 + (at >>> 16)) % 251;
    const sha256 = hash(data), file = `content/${id}-${sha256.slice(0, 16)}.pck`;
    fs.writeFileSync(path.join(directory, file), data);
    return { id, family: 'chapter2', file, bytes, sha256 };
  };
  const small = pack('chapter2_001', 83), large = pack('chapter2_002', CONTENT_PACK_TARGET + 17);
  const records = createContentChunks(directory, [small, large]);
  assert.equal(Object.hasOwn(records[0], 'transportChunks'), false);
  assert.equal(records[1].transportChunks.length, 6);
  assert.equal(records[1].transportChunks[0].bytes, CONTENT_CHUNK_BYTES);
  assert.deepEqual(verifyContentChunks(directory, records), { files: 6, bytes: large.bytes, packCount: 1, exactCoverage: true });
  assert.equal(hash(fs.readFileSync(path.join(directory, large.file))), large.sha256);
  assert.equal(Object.hasOwn(large, 'transportChunks'), false);
  checks.push('Only oversized PCKs get 1 MiB slices; original bytes and caller records remain unchanged');
  assert.throws(() => createContentChunks(directory, [small, large]), /already exists/);
  checks.push('Existing chunk output cannot be overwritten');

  const malformed = [
    chunks => { chunks[1].offset++; },
    chunks => { chunks[1].offset--; },
    chunks => { chunks[0].bytes--; },
    chunks => { chunks[0].file = 'content/chunks/../escape.bin'; },
    chunks => { chunks[0].file = 'https://example.invalid/chunk.bin'; },
    chunks => { chunks[1] = { ...chunks[0] }; },
    chunks => { chunks.reverse(); },
    chunks => { chunks.pop(); },
  ];
  for (const change of malformed) {
    const altered = clone(records); change(altered[1].transportChunks);
    assert.throws(() => verifyContentChunks(directory, altered), /chunk/);
  }
  const omitted = clone(records); delete omitted[1].transportChunks;
  assert.throws(() => verifyContentChunks(directory, omitted), /lacks transport/);
  const unnecessary = clone(records); unnecessary[0].transportChunks = [];
  assert.throws(() => verifyContentChunks(directory, unnecessary), /count\/target/);
  checks.push('Gaps, overlap, wrong lengths, unsafe paths, duplicate/reordered/omitted chunks and small-pack mirrors fail');

  const chunk = records[1].transportChunks[0], chunkPath = path.join(directory, chunk.file);
  const original = fs.readFileSync(chunkPath), corrupted = Buffer.from(original); corrupted[17] ^= 1;
  fs.writeFileSync(chunkPath, corrupted);
  assert.throws(() => verifyContentChunks(directory, records), /SHA-256 differs/);
  fs.writeFileSync(chunkPath, original);
  const forged = clone(records), forgedHash = hash(corrupted);
  const forgedName = chunk.file.replace(chunk.sha256.slice(0, 16), forgedHash.slice(0, 16));
  forged[1].transportChunks[0] = { ...chunk, file: forgedName, sha256: forgedHash };
  fs.renameSync(chunkPath, path.join(directory, forgedName));
  fs.writeFileSync(path.join(directory, forgedName), corrupted);
  assert.throws(() => verifyContentChunks(directory, forged), /differs from original PCK/);
  fs.renameSync(path.join(directory, forgedName), chunkPath); fs.writeFileSync(chunkPath, original);
  checks.push('A damaged slice and a forged self-consistent slice both fail against the original PCK');

  const extra = path.join(directory, 'content/chunks/unlisted.bin'); fs.writeFileSync(extra, 'x');
  assert.throws(() => verifyContentChunks(directory, records), /Unlisted/); fs.unlinkSync(extra);
  fs.symlinkSync(chunkPath, extra);
  assert.throws(() => verifyContentChunks(directory, records), /Unexpected/); fs.unlinkSync(extra);
  const linked = chunkPath + '.saved'; fs.renameSync(chunkPath, linked); fs.symlinkSync(linked, chunkPath);
  assert.throws(() => verifyContentChunks(directory, records), /length\/type/);
  fs.unlinkSync(chunkPath); fs.renameSync(linked, chunkPath);
  checks.push('Extra directory entries and symlinks fail exact on-disk coverage');

  const one = [{ path: 'assets/large.bin', bytes: large.bytes - 128, sha256: 'a'.repeat(64) }];
  assert.deepEqual(contentSizeException(large, one), { reason: 'single-resource', ...one[0] });
  assert.equal(contentSizeException(small, one), null);
  assert.throws(() => contentSizeException(large, [...one, ...one]), /single-resource/);
  assert.throws(() => contentSizeException({ ...large, bytes: CONTENT_PACK_LIMIT + 1 }, one), /single-resource/);
  checks.push('Only a single resource can exceed the 6 MB target; the 24 MB hard ceiling remains');
  const compressed = verifyWebCompression(directory, prepareWebCompression(directory));
  const verifiedCompressedFiles = compressed.files.map(file => file.file);
  assert.throws(() => verifyContentChunks(directory, records), /Unlisted/);
  assert.equal(verifyContentChunks(directory, records, { verifiedCompressedFiles }).files, 6);
  assert.throws(() => verifyContentChunks(directory, records, { verifiedCompressedFiles: [...verifiedCompressedFiles, 'content/chunks/phantom.bin.gz'] }), /no original/);
  checks.push('Only independently verified compressed companions coexist with exact chunk coverage');
  fs.rmSync(path.join(directory, 'content/chunks'), { recursive: true });
  assert.deepEqual(verifyContentChunks(directory, [small, large], { requireLargePacks: false }), { files: 0, bytes: 0, packCount: 0, exactCoverage: true });
  checks.push('Legacy manifests without transport extensions retain full-PCK verification support');
  console.log(JSON.stringify({ success: true, checks: checks.length, details: checks }, null, 2));
} finally { fs.rmSync(directory, { recursive: true, force: true }); }
