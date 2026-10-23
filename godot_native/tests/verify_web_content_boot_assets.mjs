#!/usr/bin/env node
// Check actual startup dependencies and scene-owned import units. Scene-only
// art must remain byte-identical and available at the ordinary content gate,
// without making a fresh phone load pay for future world objects.
import fs from 'node:fs';
import path from 'node:path';
import assert from 'node:assert/strict';
import crypto from 'node:crypto';
import { fileURLToPath } from 'node:url';
import { readPack } from '../tools/partition_web_pack.mjs';
import { verifyContentDelivery } from '../tools/web_content_delivery.mjs';
import { verifyWebCompression } from '../tools/web_precompress.mjs';

const argument = name => process.argv.find(value => value.startsWith(name + '='))?.slice(name.length + 1);
const directory = argument('--export');
if (!directory) throw new Error('Required --export=split-export-directory');
const required = [
  ...['messages','sports','campus','settings','album','recovery','voice','forum','controls','clock'].map(id => 'ui_assets/phone_icons/'+id+'.svg'),
  'ui_assets/fonts/MorningNote-Regular.ttf',
  'ui_assets/fonts/MorningNote-Medium.ttf',
  'ui_assets/fonts/OFL.txt','ui_assets/fonts/MORNING_NOTE_OFL.txt',
  'assets/rpg/fonts/fusion_pixel_12px_proportional_zh_hans.ttf',
  'assets/rpg/fonts/licenses/FUSION_PIXEL_FONT_OFL.txt',
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
    const npcs = JSON.parse(text(byPath.get('assets/rpg/npcs/finale/finale_npc_manifest.json')));
    assert.ok(Array.isArray(npcs.animations), 'Eager PhaseLayers NPC JSON parses with expected animations');
    return checks;
  } finally { fs.closeSync(fd); }
}
function verifyDeferredWorldAssets(folder, delivery) {
  const actual = new Map();
  delivery.packs.forEach((pack, index) => {
    const record = index === 0 ? { id: 'core', ...delivery.manifest.core } : delivery.manifest.packs[index - 1];
    for (const entry of pack.entries) actual.set(entry.path, { entry, group: record.id, file: path.join(folder, record.file) });
  });
  function text(name) {
    const found = actual.get(name);
    assert.ok(found, `Required scene descriptor missing: ${name}`);
    const buffer = Buffer.alloc(found.entry.bytes);
    const fd = fs.openSync(found.file, 'r');
    try { assert.equal(fs.readSync(fd, buffer, 0, buffer.length, found.entry.offset), buffer.length); }
    finally { fs.closeSync(fd); }
    return buffer.toString('utf8');
  }
  const checked = new Set();
  const payloads = new Map();
  function asset(logical, family) {
    logical = logical.replace(/^res:\/\//, '');
    const imported = actual.has(logical + '.import') ? logical + '.import' : actual.has(logical + '.remap') ? logical + '.remap' : logical;
    const found = actual.get(imported);
    assert.ok(found, `Scene resource missing from split export: ${logical}`);
    assert.match(found.group, new RegExp(`^${family}_\\d+$`), `Scene-only resource leaked into wrong pack: ${logical}`);
    checked.add(logical);
    if (!/\.(?:import|remap)$/.test(imported)) return;
    const targets = [...new Set([...text(imported).matchAll(/"res:\/\/(\.godot\/[^"\r\n]+)"/g)].map(match => match[1]))];
    assert.ok(targets.length, `Scene resource has no packed import payload: ${logical}`);
    for (const target of targets) {
      const payload = actual.get(target);
      assert.ok(payload, `Scene import payload missing: ${logical} -> ${target}`);
      assert.match(payload.group, new RegExp(`^${family}_\\d+$`), `Scene import payload not in its admitted family: ${target}`);
      payloads.set(target, payload.entry.bytes);
    }
  }
  const layout = JSON.parse(text('data/native/canteen-object-layout.json'));
  for (const entry of Object.values(layout.assets)) asset(entry.texture, 'chapter3');
  asset('assets/native/mixer/components.json', 'chapter3');
  const components = JSON.parse(text('assets/native/mixer/components.json')).components;
  for (const component of Object.values(components)) asset(component.path, 'chapter3');
  for (const name of ['drink_machine_press_4f.png', 'drink_fountain_body.png', 'drink_fountain_paddle.png']) asset('assets/native/canteen_animation/' + name, 'chapter3');
  for (const name of ['assets/rpg/interiors/library_interior.png', 'assets/rpg/npcs/library/front_desk_staff_2frame.png', 'assets/rpg/props/library_front_desk_stamp_v01.png']) asset(name, 'chapter2');
  for (const name of ['manual_control', 'movement_puzzle', 'search']) asset(`assets/audio/act-one/music/music_act2_${name}.mp3`, 'chapter2');
  for (const name of ['campus_crescent_after_rain', 'campus_qizhen_dock_morning', 'campus_zijingang_gate_cloudy', 'life_bike_basket_raincoat', 'life_canteen_queue', 'life_study_room_late_snack']) asset(`assets/ui/photo-evidence/campus-life/${name}.webp`, 'chapter2');
  for (const name of ['assets/ui/dorm_room.png', 'assets/native/dorm_cabinet/web_atlas_source.png', 'assets/native/dorm_cabinet/cabinet_opening_frames.png', 'assets/ui/cc98/theater_755_student_play_poster_v01.png', 'assets/rpg/player/player_down_0.png', 'assets/rpg/player/player_side_idle.png']) asset(name, 'chapter2');
  for (const name of ['lake_memory_a', 'lake_memory_b', 'paper_left', 'paper_middle', 'paper_right']) asset(`assets/ui/photo-evidence/chapter35_live_${name}.webp`, 'chapter35');
  asset('scenes/objects/lake_assembly_parts.tscn', 'chapter35');
  asset('scenes/theater/funhouse_stage_editable.scn', 'chapter3');
  asset('assets/native/theater_chest_20261023/prop_chest_overhead_body_v2.png', 'chapter3');
  asset('assets/rpg/interiors/finale/chapter4-755/sprites/chapter4_power_panel_states_v01.png', 'chapter4');
  for (const direction of ['', '_up', '_down']) asset(`assets/rpg/npcs/finale/guard_walk${direction}_8frame.png`, 'chapter4');
  asset('assets/rpg/interiors/finale/chapter4-755/sprites/chapter4_a2_room204_furniture_v02.png', 'chapter4');
  return { checked: [...checked].sort(), resources: checked.size, importedPayloads: payloads.size, deferredResourceBytes: [...payloads.values()].reduce((sum, bytes) => sum + bytes, 0) };
}
// Historical, explicitly non-production samples can retain these resources.
// Production story-only exports exclude them and their anonymous Godot payloads.
function verifyRetainedReferenceSample(folder, delivery) {
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
  return { checked };
}
function dormReviewIdentity() {
  const project = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..');
  const sources = new Set([
    ...['clean_room.png', 'furniture_atlas.png', 'props_atlas.png', 'manifest.json'].map(name => 'assets/native/dorm_modular/' + name),
    'scenes/dorm_modular_preview.tscn', 'scenes/objects/dorm_modular_candidate.tscn',
    'scripts/objects/dorm_modular_preview.gd', 'scripts/objects/dorm_practice_paper.gd',
  ]);
  const imported = new Map();
  function visit(directory) {
    if (!fs.existsSync(directory)) return;
    for (const item of fs.readdirSync(directory, { withFileTypes: true })) {
      const filename = path.join(directory, item.name);
      assert.ok(!item.isSymbolicLink(), `Unexpected review-source symlink: ${filename}`);
      if (item.isDirectory()) { visit(filename); continue; }
      const logical = path.relative(project, filename).split(path.sep).join('/');
      if (logical.endsWith('.import')) {
        for (const match of fs.readFileSync(filename, 'utf8').matchAll(/"res:\/\/(\.godot\/[^"\r\n]+)"/g)) imported.set(match[1], logical.slice(0, -7));
      } else if (!logical.endsWith('.uid')) sources.add(logical);
    }
  }
  visit(path.join(project, 'assets/native/dorm_modular'));
  const hashes = new Map([...sources].map(logical => [crypto.createHash('md5').update(`res://${logical}`).digest('hex'), logical]));
  return {
    sourceResources: sources.size,
    owner(name) {
      name = name.replace(/^res:\/\//, '');
      if (name.startsWith('assets/native/dorm_modular/')) return name;
      for (const logical of sources) if (name === logical || name.startsWith(logical + '.')) return logical;
      if (imported.has(name)) return imported.get(name);
      // Godot's import variants and compiled text resources use the complete
      // original res:// path MD5; export IDs and payload basenames may vary.
      const key = name.match(/^\.godot\/imported\/[^/]+-([a-f0-9]{32})(?:\.|$)/)?.[1]
        || name.match(/^\.godot\/exported\/[^/]+\/export-([a-f0-9]{32})-/)?.[1];
      return key ? hashes.get(key) ?? null : null;
    },
  };
}
function assertDormReviewAbsent(entries, identity) {
  for (const entry of entries) {
    const owner = identity.owner(entry.path);
    assert.ok(!owner, `Review-only dorm resource leaked into production PCK: ${entry.path} <- ${owner}`);
  }
}
function verifyReleaseResourcePolicy(folder) {
  // Always retain real pack bytes, MD5/SHA validation and exact full coverage.
  const build = JSON.parse(fs.readFileSync(path.join(folder, 'build-manifest.json'), 'utf8'));
  const compressed = verifyWebCompression(folder, build.transportCompression);
  const delivery = verifyContentDelivery(folder, { verifiedCompressedFiles: compressed?.files.map(file => file.file) ?? [] });
  let policy;
  if (build.production === true && build.storyOnly === true) {
    assert.ok(Number.isSafeInteger(build.initialPayloadBytes) && build.initialPayloadBytes <= 80_000_000,
      'Story-only startup exceeds the measured 80 MB budget; keep later-scene assets deferred');
    const identity = dormReviewIdentity();
    // Small negative controls prove anonymous payloads cannot evade the policy
    // merely by omitting logical .png/.tscn resource names. They are fixtures,
    // separate from the real full-export inventory checked immediately below.
    const md5 = logical => crypto.createHash('md5').update('res://' + logical).digest('hex');
    for (const leaked of [
      'assets/native/dorm_modular/clean_room.png.import',
      `.godot/imported/renamed.png-${md5('assets/native/dorm_modular/clean_room.png')}.ctex`,
      `.godot/exported/12345/export-${md5('scenes/objects/dorm_modular_candidate.tscn')}-anonymous.scn`,
      `.godot/exported/54321/export-${md5('scripts/objects/dorm_practice_paper.gd')}-anonymous.gdc`,
    ]) assert.throws(() => assertDormReviewAbsent([{ path: leaked }], identity), /Review-only dorm resource leaked/);
    assertDormReviewAbsent([{ path: `.godot/imported/normal.png-${md5('assets/rpg/interiors/library_floor.png')}.ctex` }], identity);
    assertDormReviewAbsent(delivery.fullEntries, identity);
    policy = { mode: 'production_story_only_excludes_dorm_review', excludedSourceResources: identity.sourceResources, checkedActualPackEntries: delivery.fullEntries.length, anonymousPayloadNegativeControls: 4 };
  } else {
    assert.equal(build.production, false, 'Retained-reference samples must explicitly declare non-production');
    assert.equal(build.storyOnly, false, 'Retained-reference samples must explicitly declare non-story-only');
    policy = { mode: 'non_production_retained_reference_sample', ...verifyRetainedReferenceSample(folder, delivery) };
  }
  const reference = argument('--reference-export');
  if (reference) {
    const priorBuild = JSON.parse(fs.readFileSync(path.join(reference, 'build-manifest.json'), 'utf8'));
    const priorCompressed = verifyWebCompression(reference, priorBuild.transportCompression);
    const prior = verifyContentDelivery(reference, { verifiedCompressedFiles: priorCompressed?.files.map(file => file.file) ?? [] });
    const identity = entries => entries.map(({ path, bytes, md5, sha256 }) => ({ path, bytes, md5, sha256 })).sort((a, b) => a.path.localeCompare(b.path, 'en'));
    assert.deepEqual(identity(delivery.fullEntries), identity(prior.fullEntries), 'Lossless regrouping must preserve every original resource identity');
  }
  return { ...policy, fullEntries: delivery.fullEntries.length, originalExportIdentitiesPreserved: Boolean(reference), sceneOwnedResources: verifyDeferredWorldAssets(folder, delivery) };
}
const checks = verify(directory);
const referencePolicy = verifyReleaseResourcePolicy(directory);
const negative = argument('--negative-export');
if (negative) assert.throws(() => { verify(negative); verifyReleaseResourcePolicy(negative); }, /Known eager boot resource absent|Boot import target deferred|Scene-only resource leaked|Scene import payload|Scene resource missing/);
console.log(JSON.stringify({ success: true, coreBootResources: checks.length, checked: checks, referencePolicy, priorFailedExportRejected: Boolean(negative) }, null, 2));
