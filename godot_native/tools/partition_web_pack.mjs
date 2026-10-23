#!/usr/bin/env node
/**
 * Losslessly partition an exported Godot 4.7.1 PCK with official PCKPacker.
 *
 * node partition_web_pack.mjs --input=.../index.pck
 *   --inventory=.../pack-inventory.json --groups=groups.json --output=NEW_DIRECTORY
 * Add --verify-only to independently revalidate an existing output directory.
 * GODOT_BIN selects the same 4.7.1 executable used to export the original pack.
 *
 * groups.json:
 * {"schemaVersion":1,"coreId":"core","groups":[
 *   {"id":"chapter2","paths":["assets/ch2.ogv",".godot/imported/ch2.ctex"]}
 * ]}
 * Paths are exact inventory paths, not globs. Unassigned entries belong to core.
 * Unknown paths, duplicate assignments and empty groups are errors. Every byte
 * stays at its original res:// path. This tool does not infer dependency groups.
 *
 * PCK writing and mounting follow official Godot APIs:
 * https://docs.godotengine.org/en/4.7/classes/class_pckpacker.html
 */
import fs from 'node:fs';
import path from 'node:path';
import os from 'node:os';
import crypto from 'node:crypto';
import { spawnSync } from 'node:child_process';
import { fileURLToPath } from 'node:url';

const helper = fileURLToPath(new URL('./partition_web_pack.gd', import.meta.url));
const digest = (value, algorithm = 'sha256') => crypto.createHash(algorithm).update(value).digest('hex');
const fail = message => { throw new Error(message); };
const json = filename => JSON.parse(fs.readFileSync(filename, 'utf8'));
const writeJson = (filename, value) => fs.writeFileSync(filename, JSON.stringify(value, null, 2) + '\n');
const safePath = value => typeof value === 'string' && value.length > 0 && !value.startsWith('/') && !value.includes('\\') && !/[\x00-\x1f]/.test(value) && value.split('/').every(part => part !== '' && part !== '.' && part !== '..');

function hashFile(filename) {
  const hash = crypto.createHash('sha256');
  const fd = fs.openSync(filename, 'r');
  const buffer = Buffer.alloc(1024 * 1024);
  try { for (let bytes; (bytes = fs.readSync(fd, buffer, 0, buffer.length, null));) hash.update(buffer.subarray(0, bytes)); }
  finally { fs.closeSync(fd); }
  return hash.digest('hex');
}

export function readPack(filename, hashContents = true) {
  const fd = fs.openSync(filename, 'r');
  const fileBytes = fs.fstatSync(fd).size;
  let cursor = 0;
  const read = bytes => {
    if (!Number.isSafeInteger(bytes) || bytes < 0 || cursor + bytes > fileBytes) fail('Truncated PCK directory');
    const buffer = Buffer.alloc(bytes);
    if (fs.readSync(fd, buffer, 0, bytes, cursor) !== bytes) fail('Truncated PCK read');
    cursor += bytes;
    return buffer;
  };
  const u32 = () => read(4).readUInt32LE();
  const u64 = () => {
    const value = Number(read(8).readBigUInt64LE());
    if (!Number.isSafeInteger(value)) fail('PCK integer exceeds safe range');
    return value;
  };
  try {
    if (read(4).toString('ascii') !== 'GDPC') fail('Input is not a Godot PCK');
    const format = u32();
    const engine = [u32(), u32(), u32()].join('.');
    if (![2, 3, 4].includes(format) || engine !== '4.7.1') fail(`Expected Godot 4.7.1 PCK, got ${format}/${engine}`);
    const flags = u32();
    const fileBase = u64();
    if (flags & ~2) fail('Encrypted, sparse or unknown PCK flags are unsupported');
    if (format >= 3) cursor = u64(); else cursor += 64;
    const count = u32();
    if (count < 1 || count > 100_000) fail(`Invalid PCK entry count: ${count}`);
    const entries = [];
    for (let index = 0; index < count; index++) {
      const length = u32();
      if (length < 1 || length > 16_384) fail('Invalid PCK path length');
      const name = read(length).toString('utf8').replace(/\0+$/, '').replace(/^res:\/\//, '');
      if (!safePath(name)) fail(`Unsafe PCK path: ${JSON.stringify(name)}`);
      const offset = fileBase + u64();
      const bytes = u64();
      const md5 = read(16).toString('hex');
      const entryFlags = u32();
      if (!Number.isSafeInteger(offset) || offset + bytes > fileBytes || entryFlags !== 0) fail(`Invalid PCK range/flags: ${name}`);
      entries.push({ path: name, offset, bytes, md5 });
    }
    if (new Set(entries.map(entry => entry.path)).size !== count) fail('Duplicate PCK directory paths');
    if (hashContents) {
      const buffer = Buffer.alloc(1024 * 1024);
      for (const entry of entries) {
        const sha = crypto.createHash('sha256');
        const md5 = crypto.createHash('md5');
        for (let consumed = 0; consumed < entry.bytes;) {
          const wanted = Math.min(buffer.length, entry.bytes - consumed);
          const actual = fs.readSync(fd, buffer, 0, wanted, entry.offset + consumed);
          if (actual !== wanted) fail(`Truncated PCK payload: ${entry.path}`);
          sha.update(buffer.subarray(0, actual));
          md5.update(buffer.subarray(0, actual));
          consumed += actual;
        }
        if (md5.digest('hex') !== entry.md5) fail(`PCK payload MD5 differs from its directory: ${entry.path}`);
        entry.sha256 = sha.digest('hex');
      }
    }
    return { format, engine, flags, count, entries };
  } finally { fs.closeSync(fd); }
}

export function assignGroups(entries, spec) {
  if (spec?.schemaVersion !== 1 || !Array.isArray(spec.groups)) fail('groups JSON must have schemaVersion: 1 and a groups array');
  const coreId = spec.coreId ?? 'core';
  const validId = value => typeof value === 'string' && /^[a-z][a-z0-9_-]{0,63}$/.test(value);
  if (!validId(coreId)) fail('Invalid coreId');
  const byPath = new Map(entries.map(entry => [entry.path, entry]));
  const assigned = new Map();
  const groups = [{ id: coreId, entries: [] }];
  const ids = new Set([coreId]);
  for (const group of spec.groups) {
    if (!validId(group.id) || ids.has(group.id)) fail(`Invalid or duplicate group id: ${group.id}`);
    if (!Array.isArray(group.paths) || group.paths.length === 0) fail(`Group must contain explicit paths: ${group.id}`);
    ids.add(group.id);
    const selected = [];
    for (const name of group.paths) {
      if (!safePath(name) || !byPath.has(name)) fail(`Unknown group path: ${JSON.stringify(name)}`);
      if (assigned.has(name)) fail(`Duplicate assignment for ${name}: ${assigned.get(name)} and ${group.id}`);
      if (name === 'project.binary') fail('project.binary must remain in the boot core');
      assigned.set(name, group.id);
      selected.push(byPath.get(name));
    }
    groups.push({ id: group.id, entries: selected.sort((a, b) => a.path.localeCompare(b.path, 'en')) });
  }
  groups[0].entries = entries.filter(entry => !assigned.has(entry.path)).sort((a, b) => a.path.localeCompare(b.path, 'en'));
  if (groups[0].entries.length === 0) fail('Boot core cannot be empty');
  if (groups.reduce((sum, group) => sum + group.entries.length, 0) !== entries.length) fail('Partition lost input entries');
  return { coreId, groups };
}

function sameEntryContent(actual, expected) {
  return actual.path === expected.path && actual.bytes === expected.bytes && actual.md5 === expected.md5 && actual.sha256 === expected.sha256;
}

export function checkExactCoverage(original, packs) {
  const expected = new Map(original.map(entry => [entry.path, entry]));
  const seen = new Set();
  for (const pack of packs) for (const entry of pack.entries) {
    if (seen.has(entry.path)) fail(`Partition contains duplicate entry: ${entry.path}`);
    const source = expected.get(entry.path);
    if (!source || !sameEntryContent(entry, source)) fail(`Partition payload differs from input: ${entry.path}`);
    seen.add(entry.path);
  }
  const missing = original.filter(entry => !seen.has(entry.path));
  if (missing.length) fail(`Partition omitted ${missing.length} input entries: ${missing.slice(0, 5).map(entry => entry.path).join(', ')}`);
  return true;
}

function runGodot(godot, mode, specFile, reportFile, workDirectory) {
  const projectDirectory = path.join(workDirectory, `isolated-${mode}`);
  fs.mkdirSync(projectDirectory, { recursive: true });
  fs.writeFileSync(path.join(projectDirectory, 'project.godot'), 'config_version=5\n[application]\nconfig/name="755 PCK partition verification"\n[rendering]\nrenderer/rendering_method="gl_compatibility"\n');
  fs.copyFileSync(helper, path.join(projectDirectory, 'worker.gd'));
  const result = spawnSync(godot, ['--headless', '--path', projectDirectory, '--script', 'res://worker.gd', '--', `--mode=${mode}`, `--spec=${specFile}`, `--report=${reportFile}`], { encoding: 'utf8', maxBuffer: 8 * 1024 * 1024, timeout: 600_000 });
  const log = `${result.stdout ?? ''}${result.stderr ?? ''}`;
  fs.writeFileSync(path.join(workDirectory, `godot-${mode}.log`), log);
  if (result.error || result.status !== 0 || /(?:SCRIPT ERROR|ERROR:|Parse Error)/.test(log)) fail(`Godot ${mode} failed; see ${path.join(workDirectory, `godot-${mode}.log`)}: ${result.error?.message ?? `exit ${result.status}`}`);
  const report = json(reportFile);
  if (report.success !== true) fail(`Godot ${mode} did not write a successful verification report`);
  return report;
}

export function main(argv = process.argv.slice(2)) {
  const options = {};
  for (const argument of argv) {
    if (argument === '--verify-only') options.verifyOnly = true;
    else if (/^--(input|inventory|groups|output)=.+/.test(argument)) {
      const separator = argument.indexOf('=');
      const key = argument.slice(2, separator);
      if (options[key]) fail(`Duplicate argument: --${key}`);
      options[key] = path.resolve(argument.slice(separator + 1));
    } else fail(`Unknown argument: ${argument}`);
  }
  for (const required of ['input', 'inventory', 'groups', 'output']) if (!options[required]) fail(`Required argument missing: --${required}=...`);
  if (options.output === path.dirname(options.input)) fail('Output must be a dedicated partition directory, not the source export directory');
  if (fs.existsSync(options.output) && !options.verifyOnly) fail('Output already exists; choose a new directory (existing exports are never overwritten)');
  const godot = process.env.GODOT_BIN || 'godot';
  const version = spawnSync(godot, ['--version'], { encoding: 'utf8', timeout: 30_000 });
  if (version.error || version.status !== 0 || !version.stdout.trim().startsWith('4.7.1.')) fail(`Expected Godot 4.7.1 executable: ${version.error?.message ?? version.stdout.trim()}`);
  const original = readPack(options.input);
  const inventory = json(options.inventory);
  if (inventory.format !== original.format || inventory.engine !== original.engine || inventory.flags !== original.flags || inventory.count !== original.count || !Array.isArray(inventory.entries)) fail('Provided inventory does not describe input PCK');
  const recorded = new Map(inventory.entries.map(entry => [entry.path, entry]));
  if (recorded.size !== original.count) fail('Provided inventory contains duplicate or missing paths');
  for (const entry of original.entries) {
    const reference = recorded.get(entry.path);
    if (!reference || ['offset', 'bytes', 'md5'].some(field => reference[field] !== entry[field])) fail(`Provided inventory differs from input PCK: ${entry.path}`);
  }
  const groupsBytes = fs.readFileSync(options.groups);
  const { coreId, groups } = assignGroups(original.entries, JSON.parse(groupsBytes));
  const input = { filename: path.basename(options.input), bytes: fs.statSync(options.input).size, sha256: hashFile(options.input), format: original.format, engine: original.engine, entries: original.count };
  const work = options.verifyOnly ? fs.mkdtempSync(path.join(os.tmpdir(), '755-pck-verify-')) : `${options.output}.staging-${process.pid}`;
  if (!options.verifyOnly) fs.mkdirSync(work, { recursive: false });
  const packDirectory = options.verifyOnly ? options.output : work;
  const spec = { input: options.input, entries: original.entries, groups: groups.map(group => ({ ...group, output: path.join(packDirectory, `${group.id}.pck`) })) };
  const specFile = path.join(work, 'worker-spec.json');
  writeJson(specFile, spec);
  if (!options.verifyOnly) runGodot(godot, 'build', specFile, path.join(work, 'godot-build-report.json'), work);
  const parsedPacks = groups.map(group => readPack(path.join(packDirectory, `${group.id}.pck`)));
  checkExactCoverage(original.entries, parsedPacks);
  const records = groups.map((group, index) => {
    const parsed = parsedPacks[index];
    const wanted = new Map(group.entries.map(entry => [entry.path, entry]));
    if (wanted.size !== parsed.entries.length || parsed.entries.some(entry => !wanted.has(entry.path) || !sameEntryContent(entry, wanted.get(entry.path)))) fail(`Pack membership differs from explicit group: ${group.id}`);
    const inventoryFile = `${group.id}.inventory.json`;
    if (!options.verifyOnly) writeJson(path.join(packDirectory, inventoryFile), parsed);
    else if (JSON.stringify(json(path.join(packDirectory, inventoryFile))) !== JSON.stringify(parsed)) fail(`Output inventory changed: ${inventoryFile}`);
    return { id: group.id, file: `${group.id}.pck`, bytes: fs.statSync(path.join(packDirectory, `${group.id}.pck`)).size, sha256: hashFile(path.join(packDirectory, `${group.id}.pck`)), entries: parsed.count, payloadBytes: parsed.entries.reduce((sum, entry) => sum + entry.bytes, 0), inventory: inventoryFile, inventorySha256: hashFile(path.join(packDirectory, inventoryFile)) };
  });
  const verified = runGodot(godot, 'verify', specFile, path.join(work, 'godot-verify-report.json'), work);
  if (verified.checkedEntries !== original.count || verified.checkedBytes !== original.entries.reduce((sum, entry) => sum + entry.bytes, 0)) fail('Godot independent mount verification did not check every input byte');
  const manifest = { schemaVersion: 1, kind: 'godot-web-lossless-partition', input, groupsSpecSha256: digest(groupsBytes), coreId, groups: records, totalPackBytes: records.reduce((sum, record) => sum + record.bytes, 0), exactCoverage: true, contentMapSha256: digest(JSON.stringify(original.entries.map(({ path: name, bytes, md5, sha256 }) => ({ path: name, bytes, md5, sha256 })).sort((a, b) => a.path.localeCompare(b.path, 'en')))), verification: { engine: verified.engine, checkedEntries: verified.checkedEntries, checkedBytes: verified.checkedBytes, independentProcess: true } };
  if (options.verifyOnly) {
    if (JSON.stringify(json(path.join(options.output, 'partition-manifest.json'))) !== JSON.stringify(manifest)) fail('Output manifest differs from reverified source, groups or pack bytes');
    fs.rmSync(work, { recursive: true });
  } else {
    // Worker specs contain machine-specific absolute paths, so keep only portable
    // reports/logs; no original resource content is extracted to the host disk.
    fs.rmSync(specFile);
    for (const mode of ['build', 'verify']) fs.rmSync(path.join(work, `isolated-${mode}`), { recursive: true });
    writeJson(path.join(work, 'partition-manifest.json'), manifest);
    fs.renameSync(work, options.output);
  }
  console.log(JSON.stringify({ success: true, verifiedOnly: Boolean(options.verifyOnly), output: options.output, sourceEntries: original.count, totalPackBytes: manifest.totalPackBytes, groups: records.map(({ id, entries, bytes }) => ({ id, entries, bytes })) }, null, 2));
  return manifest;
}

if (process.argv[1] && path.resolve(process.argv[1]) === fileURLToPath(import.meta.url)) {
  try { main(); } catch (error) { console.error(`PCK partition: ${error.message}`); process.exitCode = 1; }
}
