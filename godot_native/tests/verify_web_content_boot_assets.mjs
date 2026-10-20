#!/usr/bin/env node
// Regression for real split-export boot failures: dynamically constructed World
// helpers compile named-constant preloads and read JSON before chapter visibility.
import fs from 'node:fs';
import path from 'node:path';
import assert from 'node:assert/strict';
import { readPack } from '../tools/partition_web_pack.mjs';

const argument = name => process.argv.find(value => value.startsWith(name + '='))?.slice(name.length + 1);
const directory = argument('--export');
if (!directory) throw new Error('Required --export=split-export-directory');
const required = [
  'assets/native/canteen_animation/drink_machine_press_4f.png',
  'assets/native/canteen_animation/drink_fountain_body.png',
  'assets/native/canteen_animation/drink_fountain_paddle.png',
  'assets/native/canteen_objects/canteen_drink_dispenser.png',
  'assets/native/mixer/components.json',
  'assets/rpg/npcs/finale/finale_npc_manifest.json',
];
function verify(folder) {
  const filename = path.join(folder, 'index.pck');
  const pack = readPack(filename);
  const byPath = new Map(pack.entries.map(entry => [entry.path, entry]));
  const checks = [];
  const fd = fs.openSync(filename, 'r');
  const text = entry => { const bytes = Buffer.alloc(entry.bytes); assert.equal(fs.readSync(fd, bytes, 0, bytes.length, entry.offset), bytes.length); return bytes.toString('utf8'); };
  function asset(logical) {
    const entry = byPath.get(logical) || byPath.get(logical + '.import');
    assert.ok(entry, `Known eager boot resource absent from actual core: ${logical}`);
    if (entry.path.endsWith('.import')) {
      const targets = [...text(entry).matchAll(/"res:\/\/(\.godot\/[^"\r\n]+)"/g)].map(match => match[1]);
      assert.ok(targets.length, `Import has no packed target: ${logical}`);
      for (const target of targets) assert.ok(byPath.has(target), `Boot import target deferred: ${target}`);
    }
    checks.push(logical);
    return entry;
  }
  try {
    for (const logical of required) asset(logical);
    const components = JSON.parse(text(byPath.get('assets/native/mixer/components.json'))).components;
    for (const component of Object.values(components)) asset(component.path.replace(/^res:\/\//, ''));
    const npcs = JSON.parse(text(byPath.get('assets/rpg/npcs/finale/finale_npc_manifest.json')));
    assert.ok(Array.isArray(npcs.animations), 'Eager PhaseLayers NPC JSON parses with expected animations');
    return checks;
  } finally { fs.closeSync(fd); }
}
const checks = verify(directory);
const negative = argument('--negative-export');
if (negative) assert.throws(() => verify(negative), /Known eager boot resource absent|Boot import target deferred/);
console.log(JSON.stringify({ success: true, coreBootResources: checks.length, checked: checks, priorFailedExportRejected: Boolean(negative) }, null, 2));
