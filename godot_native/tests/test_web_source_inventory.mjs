// Execute production inventory and verify-only guards against tiny source fixtures.
// No export, browser, PCK acceptance, or asset bytes are simulated as release proof.
import assert from 'node:assert/strict';
import crypto from 'node:crypto';
import fs from 'node:fs';
import os from 'node:os';
import path from 'node:path';
import vm from 'node:vm';
import {test} from 'node:test';
import {bootTypographySources} from '../tools/web_boot_typography.mjs';
import {buttonMaterialSource} from '../tools/web_button_material.mjs';
import {isFlcRuntimePath} from '../tools/web_story_content_policy.mjs';

const build = fs.readFileSync(new URL('../tools/build_web.mjs', import.meta.url), 'utf8');
function section(start, end) {
  const from = build.indexOf(start), to = build.indexOf(end, from);
  assert.ok(from >= 0 && to > from, `Production section missing: ${start}`);
  return build.slice(from, to);
}
// Extract the real functions because importing this CLI would start an export.
const inventoryCode = section('const deliveryTools =', '// Exports are hosting artifacts')
  + section('const oversizedPanorama =', 'function run(')
  + section('function walk(', 'function validatePreset(');
const verifyCode = section('  const recordedPack =', '  for (const file of files) {');
const sha256 = bytes => crypto.createHash('sha256').update(bytes).digest('hex');
function fixture(t) {
  const project = fs.mkdtempSync(path.join(os.tmpdir(), '755-source-inventory-'));
  t.after(() => fs.rmSync(project, {recursive:true, force:true}));
  const context = vm.createContext({fs, path, project, sha256, bootTypographySources, buttonMaterialSource, isFlcRuntimePath,
    relative:file => path.relative(project, file).split(path.sep).join('/')});
  vm.runInContext(inventoryCode, context);
  const write = (name, bytes = 'original') => {
    const file = path.join(project, name);
    fs.mkdirSync(path.dirname(file), {recursive:true});
    fs.writeFileSync(file, bytes);
  };
  for (const name of vm.runInContext("['project.godot', 'export_presets.cfg', ...browserSources, ...deliveryTools]", context)) write(name);
  return {project, write, inventory:() => vm.runInContext('sourceInventory()', context),
    verify(recorded, source) {
      const output = path.join(project, 'exports');
      fs.mkdirSync(output, {recursive:true});
      fs.writeFileSync(path.join(output, 'pack-inventory.json'), JSON.stringify({entries:[]}));
      fs.writeFileSync(path.join(output, 'source-inputs.json'), JSON.stringify({digest:recorded.digest, files:recorded.inventory}));
      vm.runInNewContext(verifyCode, {fs, path, output, pack:{entries:[]}, source});
    }};
}
const runtimeInputs = [
  'shaders/phone_display_grade.gdshader',
  'shaders/north_prop_alpha_cutoff.gdshader',
  'ui_assets/phone_icons/messages.svg',
  'addons/qframework/framework/architecture/architecture.gd',
  'ui_assets/fonts/SelectedSans-Regular.otf',
  'ui_assets/fonts/SelectedCoverage-Regular.otf',
];
for (const name of runtimeInputs) await test(`runtime provenance detects modification, addition and removal: ${name}`, t => {
  const f = fixture(t), empty = f.inventory();
  f.write(name);
  const before = f.inventory();
  assert.ok(before.inventory.some(item => item.path === name), 'Runtime input must be inventoried');
  assert.notEqual(before.digest, empty.digest, 'Addition must change provenance');
  assert.throws(() => f.verify(empty, before), /Published core\/source inventories differ/);
  assert.doesNotThrow(() => f.verify(before, before));
  f.write(name, 'modified'); // Same byte length: hash must detect content, not just size.
  const after = f.inventory();
  assert.notEqual(after.digest, before.digest, 'Modification must change provenance');
  assert.throws(() => f.verify(before, after), /Published core\/source inventories differ/);
  fs.unlinkSync(path.join(f.project, name));
  const removed = f.inventory();
  assert.notEqual(removed.digest, before.digest, 'Removal must change provenance');
  assert.equal(removed.digest, empty.digest);
  assert.throws(() => f.verify(before, removed), /Published core\/source inventories differ/);
});
await test('production exclusions and generated import/UID sidecars do not change source digest', t => {
  const f = fixture(t), before = f.inventory();
  const excluded = ['addons/RodinBridge/plugin.gd', 'addons/qframework/README.md',
    'ui_assets/fonts/SelectedSans-Bold.otf', 'ui_assets/fonts/SelectedCoverage-Bold.otf',
    'campuses/retired/scripts/main.gd', 'assets/rpg/campus/source/master.png'];
  const sidecars = runtimeInputs.flatMap(name => [name + '.import', name + '.uid']);
  for (const name of [...excluded, ...sidecars]) f.write(name);
  const after = f.inventory();
  assert.equal(after.digest, before.digest);
  for (const name of excluded) assert.ok(after.excludedFiles.some(item => item.path === name), name);
  for (const name of sidecars) assert.ok(!after.inventory.some(item => item.path === name), name);
  assert.doesNotThrow(() => f.verify(before, after));
});
await test('existing FLC and explicit browser typography inputs remain included once', t => {
  const f = fixture(t);
  const campus = 'campuses/future_learning_center/scripts/main.gd';
  f.write(campus);
  const source = f.inventory();
  for (const name of [campus, ...bootTypographySources, buttonMaterialSource]) {
    assert.equal(source.inventory.filter(item => item.path === name).length, 1, name);
  }
});
