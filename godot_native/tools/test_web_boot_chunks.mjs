#!/usr/bin/env node
import fs from 'node:fs';
import os from 'node:os';
import path from 'node:path';
import crypto from 'node:crypto';
import assert from 'node:assert/strict';
import { prepareWebCompression, verifyWebCompression } from './web_precompress.mjs';
import { createBootChunks, verifyBootChunks, BOOT_CHUNK_BYTES } from './web_boot_chunks.mjs';

const directory = fs.mkdtempSync(path.join(os.tmpdir(), '755-static-boot-test-'));
const original = {};
for (const [name, bytes] of [['index.pck', 2 * BOOT_CHUNK_BYTES + 37], ['index.wasm', BOOT_CHUNK_BYTES + 19]]) {
  const block = Buffer.alloc(bytes);
  for (let index = 0; index < bytes; index++) block[index] = (index * 31 + Math.floor(index / 251)) & 255;
  fs.writeFileSync(path.join(directory, name), block); original[name] = block;
}
let checks = 0;
function pass(callback) { callback(); checks++; }
function reject(mutator) {
  const changed = structuredClone(manifest); mutator(changed);
  pass(() => assert.throws(() => verifyBootChunks(directory, changed)));
}
const manifest = createBootChunks(directory);
pass(() => assert.equal(verifyBootChunks(directory, manifest).files, 5));
pass(() => assert.deepEqual(manifest.resources['index.pck'].chunks.map(chunk => [chunk.offset, chunk.bytes]), [[0, BOOT_CHUNK_BYTES], [BOOT_CHUNK_BYTES, BOOT_CHUNK_BYTES], [2 * BOOT_CHUNK_BYTES, 37]]));
pass(() => assert.throws(() => createBootChunks(directory), /already exists/));
reject(copy => { copy.resources['index.pck'].chunks[1].offset++; });
reject(copy => { copy.resources['index.pck'].chunks[1].offset = 0; });
reject(copy => { copy.resources['index.pck'].chunks.pop(); });
reject(copy => { copy.resources['index.pck'].chunks[1] = copy.resources['index.pck'].chunks[0]; });
reject(copy => { copy.resources['index.wasm'].chunks[0].file = '../escape.bin'; });
reject(copy => { copy.resources['index.pck'].sha256 = '0'.repeat(64); });
reject(copy => { copy.resources['index.pck'].chunks[2].bytes++; });
const chunk = manifest.resources['index.pck'].chunks[1];
const chunkFile = path.join(directory, chunk.file);
const good = fs.readFileSync(chunkFile);
const bad = Buffer.from(good); bad[33] ^= 1; fs.writeFileSync(chunkFile, bad);
pass(() => assert.throws(() => verifyBootChunks(directory, manifest), /SHA-256 differs/));
fs.writeFileSync(chunkFile, good.subarray(0, good.length - 1));
pass(() => assert.throws(() => verifyBootChunks(directory, manifest), /length differs/));
fs.writeFileSync(chunkFile, good);
const changedOriginal = Buffer.from(original['index.wasm']); changedOriginal[0] ^= 1;
fs.writeFileSync(path.join(directory, 'index.wasm'), changedOriginal);
pass(() => assert.throws(() => verifyBootChunks(directory, manifest), /differs from original/));
fs.writeFileSync(path.join(directory, 'index.wasm'), original['index.wasm']);
const stray = path.join(directory, 'boot', 'unlisted.bin'); fs.writeFileSync(stray, 'unlisted');
pass(() => assert.throws(() => verifyBootChunks(directory, manifest), /Unlisted/));
fs.unlinkSync(stray);
pass(() => assert.equal(verifyBootChunks(directory, manifest).bytes, Object.values(original).reduce((sum, block) => sum + block.length, 0)));
for (const [name, bytes] of Object.entries(original)) pass(() => assert.deepEqual(fs.readFileSync(path.join(directory, name)), bytes));
const compressed = verifyWebCompression(directory, prepareWebCompression(directory));
const verifiedCompressedFiles = compressed.files.map(file => file.file);
pass(() => assert.throws(() => verifyBootChunks(directory, manifest), /Unlisted/));
pass(() => assert.equal(verifyBootChunks(directory, manifest, { verifiedCompressedFiles }).files, 5));
pass(() => assert.throws(() => verifyBootChunks(directory, manifest, { verifiedCompressedFiles: [...verifiedCompressedFiles, 'boot/phantom.bin.gz'] }), /no original/));
const sha256 = crypto.createHash('sha256').update(JSON.stringify(manifest)).digest('hex');
fs.rmSync(directory, { recursive: true });
console.log(JSON.stringify({ success: true, checks, manifestSha256: sha256, scope: 'Static chunk boundaries, exact reconstructed bytes, corruption/gap/overlap/duplicate/omission/extra-file rejection and unchanged original resources.' }, null, 2));
