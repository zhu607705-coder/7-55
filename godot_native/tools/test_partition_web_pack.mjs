#!/usr/bin/env node
// Focused real-engine positive and negative controls for the PCK partition tool.
import fs from 'node:fs';
import path from 'node:path';
import os from 'node:os';
import assert from 'node:assert/strict';
import { spawnSync } from 'node:child_process';
import { fileURLToPath } from 'node:url';
import { readPack, assignGroups, checkExactCoverage } from './partition_web_pack.mjs';

const godot = process.env.GODOT_BIN || 'godot';
const directory = fs.mkdtempSync(path.join(os.tmpdir(), '755-pck-partition-test-'));
const tool = fileURLToPath(new URL('./partition_web_pack.mjs', import.meta.url));
const helper = fileURLToPath(new URL('./partition_web_pack.gd', import.meta.url));
const checks = [];
function run(executable, args, expectSuccess = true) {
  const result = spawnSync(executable, args, { encoding: 'utf8', timeout: 120_000, maxBuffer: 1024 * 1024 });
  assert.equal(Boolean(!result.error && result.status === 0), expectSuccess, `${executable}: ${result.error?.message ?? ''}\n${result.stdout}\n${result.stderr}`);
  return result;
}
try {
  fs.writeFileSync(path.join(directory, 'project.godot'), 'config_version=5\n[application]\nconfig/name="Partition test fixture"\n');
  const source = path.join(directory, 'source.pck');
  fs.writeFileSync(path.join(directory, 'fixture.gd'), `extends SceneTree
func _initialize() -> void:
\tvar packer := PCKPacker.new()
\tassert(packer.pck_start(${JSON.stringify(source)}) == OK)
\tfor name: String in ["project.binary", "start.txt", "chapter2/后续.txt", "empty.bin"]:
\t\tvar bytes := PackedByteArray() if name == "empty.bin" else (name + "\\nlossless fixture\\n").to_utf8_buffer()
\t\tassert(packer.add_file_from_buffer("res://" + name, bytes) == OK)
\tassert(packer.flush() == OK)
\tquit(0)
`);
  run(godot, ['--headless', '--path', directory, '--script', 'res://fixture.gd']);
  const inventory = readPack(source);
  assert.equal(inventory.engine, '4.7.1', 'The fixture is produced by the pinned actual engine');
  const wrongVersion = path.join(directory, 'wrong-version.pck');
  const wrongHeader = fs.readFileSync(source);
  wrongHeader.writeUInt32LE(2, 16); // PCK header patch version, not resource bytes.
  fs.writeFileSync(wrongVersion, wrongHeader);
  assert.throws(() => readPack(wrongVersion), /Expected Godot 4\.7\.1 PCK/);
  checks.push('Actual 4.7.1 PCK accepted; a former 4.7.2 header is rejected');
  fs.writeFileSync(path.join(directory, 'inventory.json'), JSON.stringify(inventory));
  const groups = { schemaVersion: 1, coreId: 'core', groups: [{ id: 'chapter2', paths: ['chapter2/后续.txt'] }] };
  fs.writeFileSync(path.join(directory, 'groups.json'), JSON.stringify(groups));
  const output = path.join(directory, 'output');
  const args = [tool, `--input=${source}`, `--inventory=${path.join(directory, 'inventory.json')}`, `--groups=${path.join(directory, 'groups.json')}`, `--output=${output}`];
  run(process.execPath, args);
  const manifest = JSON.parse(fs.readFileSync(path.join(output, 'partition-manifest.json')));
  assert.equal(manifest.verification.checkedEntries, 4);
  assert.equal(manifest.groups.find(group => group.id === 'core').entries, 3);
  assert.equal(manifest.groups.find(group => group.id === 'chapter2').entries, 1);
  checks.push('Official PCKPacker, default core, Unicode path and zero-byte file preserve all four entries');
  run(process.execPath, [...args, '--verify-only']);
  checks.push('Fresh Godot process mounts all output packs and independently checks every MD5/SHA-256');
  run(process.execPath, args, false);
  checks.push('Existing output directory cannot be overwritten');
  assert.throws(() => assignGroups(inventory.entries, { ...groups, groups: [...groups.groups, { id: 'chapter3', paths: ['chapter2/后续.txt'] }] }), /Duplicate assignment/);
  assert.throws(() => assignGroups(inventory.entries, { ...groups, groups: [{ id: 'missing', paths: ['not-in-original.txt'] }] }), /Unknown group path/);
  assert.throws(() => assignGroups(inventory.entries, { ...groups, groups: [{ id: 'bad', paths: ['project.binary'] }] }), /boot core/);
  assert.throws(() => assignGroups(inventory.entries, { ...groups, groups: [{ id: '../escape', paths: ['start.txt'] }] }), /Invalid or duplicate/);
  checks.push('Duplicate assignment, unknown entry, project.binary eviction and path-like group IDs rejected');
  const core = readPack(path.join(output, 'core.pck'));
  assert.throws(() => checkExactCoverage(inventory.entries, [core]), /omitted 1 input entries/);
  checks.push('Omitting a complete deferred pack fails exact-coverage validation');

  // Independent engine negative control: mount only core, but demand all source
  // entries. No source PCK is mounted and the missing Unicode entry cannot be
  // found through the isolated project's real file system.
  const negative = path.join(directory, 'negative');
  fs.mkdirSync(negative);
  fs.writeFileSync(path.join(negative, 'project.godot'), 'config_version=5\n[application]\nconfig/name="Missing partition negative control"\n');
  fs.copyFileSync(helper, path.join(negative, 'worker.gd'));
  fs.writeFileSync(path.join(negative, 'spec.json'), JSON.stringify({ entries: inventory.entries, groups: [{ id: 'core', output: path.join(output, 'core.pck'), entries: core.entries }] }));
  const result = run(godot, ['--headless', '--path', negative, '--script', 'res://worker.gd', '--', '--mode=verify', `--spec=${path.join(negative, 'spec.json')}`, `--report=${path.join(negative, 'report.json')}`], false);
  assert.match(result.stderr + result.stdout, /Partition entry missing after independent mount: chapter2\/后续.txt/);
  checks.push('Godot itself rejects a deliberately omitted deferred pack, independently of Node inventory checks');

  const corrupt = path.join(directory, 'corrupt.pck');
  fs.copyFileSync(path.join(output, 'core.pck'), corrupt);
  const mutable = core.entries.find(entry => entry.bytes > 0);
  const fd = fs.openSync(corrupt, 'r+');
  fs.writeSync(fd, Buffer.from([255]), 0, 1, mutable.offset);
  fs.closeSync(fd);
  assert.throws(() => readPack(corrupt), /payload MD5 differs/);
  checks.push('One-byte payload corruption fails directory MD5 verification');
  console.log(JSON.stringify({ success: true, checks: checks.length, details: checks, engine: manifest.verification.engine }, null, 2));
} finally { fs.rmSync(directory, { recursive: true, force: true }); }
