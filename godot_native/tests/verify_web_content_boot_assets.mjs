#!/usr/bin/env node
// Regression for real split-export boot failures: dynamically constructed World
// helpers compile named-constant preloads and read JSON before chapter visibility.
import fs from 'node:fs';
import path from 'node:path';
import assert from 'node:assert/strict';
import { readPack } from '../tools/partition_web_pack.mjs';
import { verifyContentDelivery } from '../tools/web_content_delivery.mjs';

const argument = name => process.argv.find(value => value.startsWith(name + '='))?.slice(name.length + 1);
const directory = argument('--export');
if (!directory) throw new Error('Required --export=split-export-directory');
const required = [
  ...['messages','sports','campus','settings','album','recovery','voice','forum','controls','clock'].map(id => 'ui_assets/phone_icons/'+id+'.svg'),
  'ui_assets/fonts/CampusUISans-Regular.otf',
  'ui_assets/fonts/OFL.txt',
  'ui_assets/fonts/SelectedSans-Regular.otf',
  'ui_assets/fonts/SelectedSans-Bold.otf',
  'ui_assets/fonts/SelectedCoverage-Regular.otf',
  'ui_assets/fonts/SelectedCoverage-Bold.otf',
  'ui_assets/fonts/SelectedBoutique-Regular.ttf',
  'ui_assets/fonts/SELECTED_NOTO_LICENSE.txt',
  'ui_assets/fonts/SELECTED_BOUTIQUE_OFL.txt',
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
// These independent review resources are retained, not attached to Chapter 2
// gameplay. The production entry and validated saves cannot open their scenes.
// Source/native F6/CLI previews use the complete project, not this Web planner.
function verifyRetainedReferences(folder) {
  const delivery = verifyContentDelivery(folder); // Real PCK bytes, all MD5/SHA and exact full-export coverage.
  const receipts = new Map(delivery.inventory.entries.map(entry => [entry.path, entry]));
  const actual = new Map();
  delivery.packs.forEach((pack, index) => {
    const record = index === 0 ? delivery.manifest.core : delivery.manifest.packs[index - 1];
    for (const entry of pack.entries) actual.set(entry.path, { entry, file: path.join(folder, record.file) });
  });
  const checked = [];
  function retained(name) {
    const receipt = receipts.get(name), found = actual.get(name);
    assert.ok(receipt && found, `Retained reference missing from full split export: ${name}`);
    assert.match(receipt.group, /^chapter2_\d+$/, `Review-only source must be deferred, not boot core: ${name}`);
    assert.ok(!delivery.corePack.entries.some(entry => entry.path === name), `Review reference leaked into boot core: ${name}`);
    for (const key of ['bytes', 'md5', 'sha256']) assert.equal(found.entry[key], receipt[key], `Retained reference changed ${key}: ${name}`);
    checked.push(name);
    return found;
  }
  for (const name of ['clean_room.png', 'furniture_atlas.png', 'props_atlas.png', 'manifest.json']) {
    const logical = 'assets/native/dorm_modular/' + name;
    const found = retained(logical + (name.endsWith('.png') ? '.import' : ''));
    const fd = fs.openSync(found.file, 'r');
    const bytes = Buffer.alloc(found.entry.bytes);
    try { assert.equal(fs.readSync(fd, bytes, 0, bytes.length, found.entry.offset), bytes.length); }
    finally { fs.closeSync(fd); }
    if (name.endsWith('.png')) {
      const targets = [...new Set([...bytes.toString('utf8').matchAll(/"res:\/\/(\.godot\/[^"\r\n]+)"/g)].map(match => match[1]))];
      assert.ok(targets.length > 0, `Review source import has no real target: ${logical}`);
      for (const target of targets) retained(target);
    } else assert.equal(JSON.parse(bytes).status, 'candidate_not_production', 'Review-only provenance remains unchanged');
  }
  const reference = argument('--reference-export');
  if (reference) {
    const prior = verifyContentDelivery(reference);
    const identity = entries => entries.map(({ path, bytes, md5, sha256 }) => ({ path, bytes, md5, sha256 })).sort((a, b) => a.path.localeCompare(b.path, 'en'));
    assert.deepEqual(identity(delivery.fullEntries), identity(prior.fullEntries), 'Lossless regrouping must preserve every original resource identity');
  }
  return { checked, fullEntries: delivery.fullEntries.length, originalExportIdentitiesPreserved: Boolean(reference) };
}
const checks = verify(directory);
const retainedReferences = verifyRetainedReferences(directory);
const negative = argument('--negative-export');
if (negative) assert.throws(() => verify(negative), /Known eager boot resource absent|Boot import target deferred/);
console.log(JSON.stringify({ success: true, coreBootResources: checks.length, checked: checks, retainedReferences, priorFailedExportRejected: Boolean(negative) }, null, 2));
