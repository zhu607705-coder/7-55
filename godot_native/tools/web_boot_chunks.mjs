// Static complete files, rather than HTTP Range, survive hosts that gzip the
// original PCK/WASM. The original engine artifacts remain byte-identical.
import fs from 'node:fs';
import path from 'node:path';
import crypto from 'node:crypto';

export const BOOT_CHUNK_SCHEMA = '755-boot-chunks-v1';
export const BOOT_CHUNK_BYTES = 1024 * 1024;
const resources = ['index.pck', 'index.wasm'];
const sha256 = bytes => crypto.createHash('sha256').update(bytes).digest('hex');
const filename = (resource, index, digest) => `boot/${resource.replaceAll('.', '-')}-${String(index + 1).padStart(4, '0')}-${digest.slice(0, 16)}.bin`;
function readExact(fd, bytes, offset) {
  for (let read = 0; read < bytes.length;) {
    const actual = fs.readSync(fd, bytes, read, bytes.length - read, offset + read);
    if (!actual) throw new Error('Truncated boot resource');
    read += actual;
  }
}

export function createBootChunks(directory) {
  const folder = path.join(directory, 'boot');
  if (fs.existsSync(folder)) throw new Error('Boot chunk output already exists; preserve it and build a new candidate');
  fs.mkdirSync(folder);
  const result = { schema: BOOT_CHUNK_SCHEMA, chunkBytes: BOOT_CHUNK_BYTES, resources: {} };
  for (const name of resources) {
    const file = path.join(directory, name);
    const bytes = fs.statSync(file).size;
    if (!Number.isSafeInteger(bytes) || bytes < 1) throw new Error(`Empty or invalid boot resource: ${name}`);
    const hash = crypto.createHash('sha256');
    const chunks = [];
    const fd = fs.openSync(file, 'r');
    try {
      for (let offset = 0; offset < bytes; offset += BOOT_CHUNK_BYTES) {
        const block = Buffer.alloc(Math.min(BOOT_CHUNK_BYTES, bytes - offset));
        readExact(fd, block, offset); hash.update(block);
        const digest = sha256(block);
        const target = filename(name, chunks.length, digest);
        fs.writeFileSync(path.join(directory, target), block, { flag: 'wx' });
        chunks.push({ file: target, offset, bytes: block.length, sha256: digest });
      }
    } finally { fs.closeSync(fd); }
    result.resources[name] = { file: name, bytes, sha256: hash.digest('hex'), chunks };
  }
  verifyBootChunks(directory, result);
  return result;
}

export function verifyBootChunks(directory, manifest, { verifiedCompressedFiles = [] } = {}) {
  if (!manifest || manifest.schema !== BOOT_CHUNK_SCHEMA || manifest.chunkBytes !== BOOT_CHUNK_BYTES
    || !manifest.resources || JSON.stringify(Object.keys(manifest.resources).sort()) !== JSON.stringify(resources.slice().sort())) throw new Error('Invalid static boot chunk manifest');
  const declared = new Set();
  let chunkBytes = 0;
  for (const name of resources) {
    const resource = manifest.resources[name];
    if (!resource || resource.file !== name || !Number.isSafeInteger(resource.bytes) || resource.bytes < 1 || !/^[a-f0-9]{64}$/.test(resource.sha256)
      || !Array.isArray(resource.chunks) || resource.chunks.length !== Math.ceil(resource.bytes / BOOT_CHUNK_BYTES)) throw new Error(`Invalid boot resource metadata: ${name}`);
    const original = path.join(directory, name);
    if (!fs.lstatSync(original).isFile() || fs.statSync(original).size !== resource.bytes) throw new Error(`Original boot resource length differs: ${name}`);
    const fd = fs.openSync(original, 'r');
    const reassembled = crypto.createHash('sha256');
    let offset = 0;
    try {
      for (let index = 0; index < resource.chunks.length; index++) {
        const chunk = resource.chunks[index];
        const size = Math.min(BOOT_CHUNK_BYTES, resource.bytes - offset);
        if (!chunk || chunk.offset !== offset || chunk.bytes !== size || !/^[a-f0-9]{64}$/.test(chunk.sha256)
          || chunk.file !== filename(name, index, chunk.sha256) || declared.has(chunk.file)) throw new Error(`Boot chunk has a gap, overlap, duplicate or invalid path: ${name} #${index}`);
        declared.add(chunk.file);
        const file = path.join(directory, chunk.file);
        if (!fs.lstatSync(file).isFile() || fs.statSync(file).size !== size) throw new Error(`Boot chunk length differs: ${chunk.file}`);
        const block = fs.readFileSync(file);
        if (sha256(block) !== chunk.sha256) throw new Error(`Boot chunk SHA-256 differs: ${chunk.file}`);
        const expected = Buffer.alloc(size); readExact(fd, expected, offset);
        if (!block.equals(expected)) throw new Error(`Boot chunk differs from original artifact at ${name}:${offset}`);
        reassembled.update(block); offset += size; chunkBytes += size;
      }
    } finally { fs.closeSync(fd); }
    if (offset !== resource.bytes || reassembled.digest('hex') !== resource.sha256) throw new Error(`Reassembled boot resource SHA-256/coverage differs: ${name}`);
  }
  const allowed = new Set(verifiedCompressedFiles.filter(file => file.startsWith('boot/')));
  if ([...allowed].some(file => !file.endsWith('.gz') || !declared.has(file.slice(0, -3)))) throw new Error('Compressed boot companion has no original chunk');
  const actual = fs.readdirSync(path.join(directory, 'boot'), { withFileTypes: true }).map(item => {
    if (!item.isFile() || item.isSymbolicLink()) throw new Error(`Unexpected boot chunk entry: ${item.name}`);
    return `boot/${item.name}`;
  }).filter(file => !allowed.has(file)).sort();
  if (JSON.stringify(actual) !== JSON.stringify([...declared].sort())) throw new Error('Unlisted or missing static boot chunk file');
  return { schema: BOOT_CHUNK_SCHEMA, files: declared.size, bytes: chunkBytes, exactCoverage: true, resourceCount: resources.length };
}
