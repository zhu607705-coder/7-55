// Build-time packaging only. Godot controllers and resource paths are unchanged.
import fs from 'node:fs';
import path from 'node:path';
import crypto from 'node:crypto';
import { spawnSync } from 'node:child_process';
import { fileURLToPath } from 'node:url';
import { main as partition, readPack, checkExactCoverage } from './partition_web_pack.mjs';

const planner = fileURLToPath(new URL('./plan_web_content.mjs', import.meta.url));
export const CONTENT_SCHEMA = '755-web-content-v1';
export const CONTENT_PACK_LIMIT = 24_000_000;
const backgroundOrder = ['chapter2', 'chapter3', 'chapter35', 'chapter4'];
const digest = bytes => crypto.createHash('sha256').update(bytes).digest('hex');
const json = filename => JSON.parse(fs.readFileSync(filename, 'utf8'));
const writeJson = (filename, value) => fs.writeFileSync(filename, JSON.stringify(value, null, 2) + '\n');
const family = id => id.replace(/_\d+$/, '');
export function fileSha256(filename) {
  const hash = crypto.createHash('sha256');
  const fd = fs.openSync(filename, 'r');
  const buffer = Buffer.alloc(1024 * 1024);
  try { for (let bytes; (bytes = fs.readSync(fd, buffer, 0, buffer.length, null));) hash.update(buffer.subarray(0, bytes)); }
  finally { fs.closeSync(fd); }
  return hash.digest('hex');
}
const contentMapDigest = entries => digest(JSON.stringify(entries.map(({ path: name, bytes, md5, sha256 }) => ({ path: name, bytes, md5, sha256 })).sort((a, b) => a.path.localeCompare(b.path, 'en'))));
const safeContentFile = name => /^content\/[a-z][a-z0-9_-]*-[0-9a-f]{16}\.pck$/.test(name);

export function createContentDelivery({ exportDirectory, intermediateDirectory }) {
  if (fs.existsSync(intermediateDirectory)) throw new Error('Content build intermediate directory already exists; previous proof is never overwritten');
  fs.mkdirSync(intermediateDirectory, { recursive: true });
  const fullFile = path.join(intermediateDirectory, 'index-full.pck');
  fs.renameSync(path.join(exportDirectory, 'index.pck'), fullFile);
  const full = readPack(fullFile);
  const inventoryFile = path.join(intermediateDirectory, 'full-pack-inventory.json');
  writeJson(inventoryFile, full);
  const groupsFile = path.join(intermediateDirectory, 'groups.json');
  const planned = spawnSync(process.execPath, [planner, `--input=${fullFile}`, `--inventory=${inventoryFile}`, `--output=${groupsFile}`, '--startup=conservative'], { encoding: 'utf8', maxBuffer: 4 * 1024 * 1024 });
  fs.writeFileSync(path.join(intermediateDirectory, 'planner.log'), `${planned.stdout ?? ''}${planned.stderr ?? ''}`);
  if (planned.error || planned.status !== 0) throw new Error(`Content planner failed: ${planned.error?.message ?? planned.stderr}`);
  const partitionDirectory = path.join(intermediateDirectory, 'partition');
  const result = partition([`--input=${fullFile}`, `--inventory=${inventoryFile}`, `--groups=${groupsFile}`, `--output=${partitionDirectory}`]);
  fs.mkdirSync(path.join(exportDirectory, 'content'));
  const coreGroup = result.groups.find(group => group.id === result.coreId);
  if (!coreGroup) throw new Error('Partition did not produce its declared core');
  fs.copyFileSync(path.join(partitionDirectory, coreGroup.file), path.join(exportDirectory, 'index.pck'), fs.constants.COPYFILE_FICLONE);
  const core = { file: 'index.pck', bytes: coreGroup.bytes, sha256: coreGroup.sha256 };
  const packs = result.groups.filter(group => group.id !== result.coreId).map(group => {
    if (group.bytes > CONTENT_PACK_LIMIT) throw new Error(`Content pack exceeds the ${CONTENT_PACK_LIMIT}-byte budget: ${group.id}`);
    const file = `content/${group.id}-${group.sha256.slice(0, 16)}.pck`;
    fs.copyFileSync(path.join(partitionDirectory, group.file), path.join(exportDirectory, file), fs.constants.COPYFILE_FICLONE);
    return { id: group.id, family: family(group.id), file, bytes: group.bytes, sha256: group.sha256 };
  });
  const manifest = { schema: CONTENT_SCHEMA, engine: '4.7.1', core, packs, backgroundOrder };
  writeJson(path.join(exportDirectory, 'content-manifest.json'), manifest);
  const owned = new Map();
  const groupInventories = result.groups.map(group => {
    const inventory = json(path.join(partitionDirectory, group.inventory));
    for (const entry of inventory.entries) {
      if (owned.has(entry.path)) throw new Error(`Duplicate partition entry: ${entry.path}`);
      owned.set(entry.path, group.id);
    }
    return { id: group.id, file: group.id === result.coreId ? 'index.pck' : packs.find(pack => pack.id === group.id).file, entries: group.entries, bytes: group.bytes, sha256: group.sha256 };
  });
  const contentInventory = {
    schema: '755-web-content-inventory-v1', coreId: result.coreId,
    full: { format: full.format, engine: full.engine, flags: full.flags, count: full.count, bytes: fs.statSync(fullFile).size, sha256: fileSha256(fullFile), inventorySha256: digest(JSON.stringify(full.entries)), contentMapSha256: contentMapDigest(full.entries) },
    groups: groupInventories,
    entries: full.entries.map(entry => ({ ...entry, group: owned.get(entry.path) })),
    verification: result.verification,
  };
  writeJson(path.join(exportDirectory, 'content-inventory.json'), contentInventory);
  return verifyContentDelivery(exportDirectory);
}

export function verifyContentDelivery(exportDirectory) {
  const manifest = json(path.join(exportDirectory, 'content-manifest.json'));
  const inventory = json(path.join(exportDirectory, 'content-inventory.json'));
  if (manifest.schema !== CONTENT_SCHEMA || manifest.engine !== '4.7.1' || inventory.schema !== '755-web-content-inventory-v1') throw new Error('Invalid Godot content manifest/inventory schema');
  if (manifest.core?.file !== 'index.pck' || !Array.isArray(manifest.packs) || !Array.isArray(inventory.entries) || !Array.isArray(inventory.groups)) throw new Error('Invalid Godot content manifest shape');
  if (JSON.stringify(manifest.backgroundOrder) !== JSON.stringify(backgroundOrder)) throw new Error('Content background order differs from the story chapter order');
  if (inventory.full?.engine !== '4.7.1' || inventory.full.count !== inventory.entries.length || contentMapDigest(inventory.entries) !== inventory.full.contentMapSha256) throw new Error('Complete-export inventory lost or changed a resource');
  const original = inventory.entries.map(({ group, ...entry }) => entry);
  if (digest(JSON.stringify(original)) !== inventory.full.inventorySha256) throw new Error('Complete-export inventory does not match its original SHA-256');
  const records = [{ id: inventory.coreId, ...manifest.core }, ...manifest.packs];
  if (typeof inventory.coreId !== 'string' || new Set(records.map(record => record.id)).size !== records.length || new Set(records.map(record => record.file)).size !== records.length) throw new Error('Duplicate content pack id or file');
  const parsed = [];
  for (const record of records) {
    if (!/^[a-z][a-z0-9_-]{0,63}$/.test(record.id) || !Number.isSafeInteger(record.bytes) || record.bytes < 1 || !/^[0-9a-f]{64}$/.test(record.sha256)) throw new Error('Invalid content pack metadata');
    if (record.id !== inventory.coreId && (!safeContentFile(record.file) || record.file !== `content/${record.id}-${record.sha256.slice(0, 16)}.pck` || record.family !== family(record.id) || record.bytes > CONTENT_PACK_LIMIT)) throw new Error(`Invalid or oversized deferred content pack: ${record.id}`);
    const file = path.join(exportDirectory, record.file);
    if (fs.statSync(file).size !== record.bytes || fileSha256(file) !== record.sha256) throw new Error(`Content pack hash/size differs from manifest: ${record.file}`);
    const pack = readPack(file);
    const declared = inventory.groups.find(group => group.id === record.id);
    if (!declared || declared.file !== record.file || declared.bytes !== record.bytes || declared.sha256 !== record.sha256 || declared.entries !== pack.count) throw new Error(`Content pack differs from complete-export group receipt: ${record.id}`);
    const wanted = inventory.entries.filter(entry => entry.group === record.id);
    const membership = new Set(wanted.map(entry => entry.path));
    if (wanted.length !== pack.count || pack.entries.some(entry => !membership.has(entry.path))) throw new Error(`Content pack membership changed: ${record.id}`);
    parsed.push(pack);
  }
  if (inventory.groups.length !== records.length || inventory.entries.some(entry => !records.some(record => record.id === entry.group))) throw new Error('Content group receipt contains unknown or omitted groups');
  checkExactCoverage(original, parsed);
  const actualContentPacks = fs.readdirSync(path.join(exportDirectory, 'content')).filter(name => name.endsWith('.pck')).map(name => `content/${name}`).sort();
  if (JSON.stringify(actualContentPacks) !== JSON.stringify(manifest.packs.map(pack => pack.file).sort())) throw new Error('Unlisted or missing PCK in published content directory');
  return { manifest, inventory, corePack: parsed[0], fullEntries: original, packs: parsed, deferredPackLimit: CONTENT_PACK_LIMIT };
}
