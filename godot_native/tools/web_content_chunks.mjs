// Deferred resources keep their original PCK bytes and paths. Only a pack that
// cannot fit the ordinary target receives static, independently cached slices.
import fs from 'node:fs';
import path from 'node:path';
import crypto from 'node:crypto';

export const CONTENT_PACK_TARGET = 6_000_000;
export const CONTENT_PACK_LIMIT = 24_000_000;
export const CONTENT_CHUNK_BYTES = 1024 * 1024;
export const CONTENT_PACK_POLICY = Object.freeze({ targetBytes: CONTENT_PACK_TARGET, hardLimitBytes: CONTENT_PACK_LIMIT, oversized: 'single-resource', transportChunkBytes: CONTENT_CHUNK_BYTES });
const digest = bytes => crypto.createHash('sha256').update(bytes).digest('hex');
const filename = (id, index, hash) => `content/chunks/${id}-${String(index + 1).padStart(4, '0')}-${hash.slice(0, 16)}.bin`;
function readExact(fd, bytes, offset) {
  for (let read = 0; read < bytes.length;) {
    const actual = fs.readSync(fd, bytes, read, bytes.length - read, offset + read);
    if (!actual) throw new Error('Truncated deferred content PCK');
    read += actual;
  }
}
function originalFile(directory, pack) {
  if (!pack || !/^[a-z][a-z0-9_]*$/.test(pack.id) || !Number.isSafeInteger(pack.bytes) || pack.bytes < 1 || pack.bytes > CONTENT_PACK_LIMIT || !/^[a-f0-9]{64}$/.test(pack.sha256) || pack.file !== `content/${pack.id}-${pack.sha256.slice(0, 16)}.pck`) throw new Error('Invalid deferred content identity');
  const original = path.join(directory, pack.file);
  const stat = fs.lstatSync(original);
  if (!stat.isFile() || stat.isSymbolicLink() || stat.size !== pack.bytes) throw new Error(`Deferred content original length/type differs: ${pack.id}`);
  return original;
}

export function createContentChunks(directory, packs) {
  const folder = path.join(directory, 'content/chunks');
  if (fs.existsSync(folder) || packs.some(pack => Object.hasOwn(pack, 'transportChunks'))) throw new Error('Deferred content chunk output already exists');
  const result = packs.map(pack => ({ ...pack }));
  for (const pack of result) {
    const original = originalFile(directory, pack);
    if (pack.bytes <= CONTENT_PACK_TARGET) continue;
    fs.mkdirSync(folder, { recursive: true });
    const fd = fs.openSync(original, 'r');
    const hash = crypto.createHash('sha256');
    const chunks = [];
    try {
      for (let offset = 0; offset < pack.bytes; offset += CONTENT_CHUNK_BYTES) {
        const block = Buffer.alloc(Math.min(CONTENT_CHUNK_BYTES, pack.bytes - offset));
        readExact(fd, block, offset); hash.update(block);
        const sha256 = digest(block);
        const file = filename(pack.id, chunks.length, sha256);
        fs.writeFileSync(path.join(directory, file), block, { flag: 'wx' });
        chunks.push({ file, offset, bytes: block.length, sha256 });
      }
    } finally { fs.closeSync(fd); }
    if (hash.digest('hex') !== pack.sha256) throw new Error(`Deferred content original hash differs: ${pack.id}`);
    // Do not use `chunks`: older loaders interpret that name as boot-only data.
    pack.transportChunks = chunks;
  }
  verifyContentChunks(directory, result);
  return result;
}

export function verifyContentChunks(directory, packs, { requireLargePacks = true, verifiedCompressedFiles = [] } = {}) {
  const declared = new Set();
  let bytes = 0, packCount = 0;
  for (const pack of packs) {
    const present = Object.hasOwn(pack, 'transportChunks');
    if (!present) {
      if (requireLargePacks && pack.bytes > CONTENT_PACK_TARGET) throw new Error(`Oversized content pack lacks transport chunks: ${pack.id}`);
      continue;
    }
    if (pack.bytes <= CONTENT_PACK_TARGET || !Array.isArray(pack.transportChunks) || pack.transportChunks.length !== Math.ceil(pack.bytes / CONTENT_CHUNK_BYTES)) throw new Error(`Invalid deferred content chunk count/target: ${pack.id}`);
    const original = originalFile(directory, pack);
    const fd = fs.openSync(original, 'r');
    const reassembled = crypto.createHash('sha256');
    let offset = 0;
    try {
      for (let index = 0; index < pack.transportChunks.length; index++) {
        const chunk = pack.transportChunks[index];
        const size = Math.min(CONTENT_CHUNK_BYTES, pack.bytes - offset);
        if (!chunk || chunk.offset !== offset || chunk.bytes !== size || !/^[a-f0-9]{64}$/.test(chunk.sha256) || chunk.file !== filename(pack.id, index, chunk.sha256) || declared.has(chunk.file)) throw new Error(`Deferred content chunk gap, overlap or identity differs: ${pack.id} #${index}`);
        declared.add(chunk.file);
        const file = path.join(directory, chunk.file);
        const stat = fs.lstatSync(file);
        if (!stat.isFile() || stat.isSymbolicLink() || stat.size !== size) throw new Error(`Deferred content chunk length/type differs: ${chunk.file}`);
        const block = fs.readFileSync(file);
        if (digest(block) !== chunk.sha256) throw new Error(`Deferred content chunk SHA-256 differs: ${chunk.file}`);
        const expected = Buffer.alloc(size); readExact(fd, expected, offset);
        if (!block.equals(expected)) throw new Error(`Deferred content chunk differs from original PCK: ${pack.id}:${offset}`);
        reassembled.update(block); offset += size; bytes += size;
      }
    } finally { fs.closeSync(fd); }
    if (offset !== pack.bytes || reassembled.digest('hex') !== pack.sha256) throw new Error(`Reassembled deferred content hash/coverage differs: ${pack.id}`);
    packCount++;
  }
  const allowed = new Set(verifiedCompressedFiles.filter(file => file.startsWith('content/chunks/')));
  if ([...allowed].some(file => !file.endsWith('.gz') || !declared.has(file.slice(0, -3)))) throw new Error('Compressed content companion has no original chunk');
  const folder = path.join(directory, 'content/chunks');
  const actual = fs.existsSync(folder) ? fs.readdirSync(folder, { withFileTypes: true }).map(entry => {
    if (!entry.isFile() || entry.isSymbolicLink()) throw new Error(`Unexpected deferred content chunk entry: ${entry.name}`);
    return `content/chunks/${entry.name}`;
  }).filter(file => !allowed.has(file)).sort() : [];
  if (JSON.stringify(actual) !== JSON.stringify([...declared].sort())) throw new Error('Unlisted or missing deferred content chunk file');
  return { files: declared.size, bytes, packCount, exactCoverage: true };
}
