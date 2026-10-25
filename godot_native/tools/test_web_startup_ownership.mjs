#!/usr/bin/env node
// Exercise the production planner against import/remap units. It must delay
// chapter-owned bytes without evicting real boot preloads or losing resources.
import fs from 'node:fs';
import path from 'node:path';
import os from 'node:os';
import crypto from 'node:crypto';
import assert from 'node:assert/strict';
import { spawnSync } from 'node:child_process';
import { fileURLToPath } from 'node:url';

const project = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..');
const temporary = fs.mkdtempSync(path.join(os.tmpdir(), '755-startup-ownership-'));
const expected = new Map();
const records = new Map([['project.binary', Buffer.from('controlled ownership fixture, not an engine export')]]);
function resource(logical, family, remap = false) {
  let metadata;
  if (remap) {
    const payload = '.godot/exported/ownership-fixture/lake_assembly_parts.scn';
    metadata = Buffer.from(`[remap]\npath="res://${payload}"\n`);
  } else metadata = fs.readFileSync(path.join(project, logical + '.import'));
  const unit = logical + (remap ? '.remap' : '.import');
  records.set(unit, metadata); expected.set(unit, family);
  const targets = [...new Set([...metadata.toString().matchAll(/"res:\/\/(\.godot\/[^"\r\n]+)"/g)].map(match => match[1]))];
  assert.ok(targets.length, `Fixture has an actual import/remap target: ${logical}`);
  for (const target of targets) {
    // Resource bytes do not affect classification. Metadata is real; the
    // partition test separately verifies engine mounts and original hashes.
    records.set(target, Buffer.from('controlled resource payload: ' + logical));
    expected.set(target, family);
  }
}
try {
  for (const name of ['lake_memory_a', 'lake_memory_b', 'paper_left', 'paper_middle', 'paper_right'])
    resource(`assets/ui/photo-evidence/chapter35_live_${name}.webp`, 'chapter35');
  for (const name of ['campus_crescent_after_rain', 'campus_qizhen_dock_morning', 'campus_zijingang_gate_cloudy', 'life_bike_basket_raincoat', 'life_canteen_queue', 'life_study_room_late_snack'])
    resource(`assets/ui/photo-evidence/campus-life/${name}.webp`, 'chapter2');
  for (const name of ['manual_control', 'movement_puzzle', 'search'])
    resource(`assets/audio/act-one/music/music_act2_${name}.mp3`, 'chapter2');
  for (const name of ['music_prologue_blackout', 'music_narrator_chase'])
    resource(`assets/audio/act-one/music/${name}.mp3`, 'core');
  for (const name of ['assets/ui/dorm_room.png', 'assets/native/dorm_cabinet/web_atlas_source.png', 'assets/native/dorm_cabinet/cabinet_opening_frames.png', 'assets/ui/cc98/theater_755_student_play_poster_v01.png', 'assets/rpg/player/player_down_0.png', 'assets/rpg/player/player_side_idle.png'])
    resource(name, 'chapter2');
  resource('assets/native/theater_chest_20261023/prop_chest_overhead_body_v2.png', 'chapter3');
  resource('scenes/objects/lake_assembly_parts.tscn', 'chapter35', true);
  records.set('scenes/theater/funhouse_stage_editable.scn', Buffer.from('retained source scene'));
  expected.set('scenes/theater/funhouse_stage_editable.scn', 'chapter3');
  resource('assets/rpg/interiors/finale/chapter4-755/sprites/chapter4_power_panel_states_v01.png', 'chapter4');
  for (const direction of ['', '_up', '_down'])
    resource(`assets/rpg/npcs/finale/guard_walk${direction}_8frame.png`, 'chapter4');
  // Force the planner to inspect this real late-loaded script. Its art must
  // stay delayed after preload was replaced by configure-time load(ART_PATH).
  records.set('scripts/ui/chapter4_power_panel.gd', Buffer.from('classification fixture; planner reads checked-in GDScript'));
  // A later asset with a real transitive boot preload must still be core.
  resource('assets/rpg/interiors/finale/chapter4-755/props/chapter4_a3_archive_film_v01.png', 'core');
  resource('assets/native/kayak/hull.svg', 'core');
  resource('assets/native/north_objects_20261025/student_desk.png', 'chapter4');
  resource('assets/native/north_objects_20261025/wall_face.png', 'chapter4');
  resource('assets/ui/tiyi_main.png', 'core');
  records.set('assets/unknown_owner.bin', Buffer.from('retain unknown ownership'));
  expected.set('assets/unknown_owner.bin', 'core');
  let offset = 0;
  const entries = [...records].map(([name, bytes]) => {
    const entry = { path: name, offset, bytes: bytes.length, md5: crypto.createHash('md5').update(bytes).digest('hex') };
    offset += bytes.length; return entry;
  });
  const input = path.join(temporary, 'payload.bin'), inventory = path.join(temporary, 'inventory.json'), output = path.join(temporary, 'groups.json');
  fs.writeFileSync(input, Buffer.concat([...records.values()]));
  fs.writeFileSync(inventory, JSON.stringify({ entries }));
  const run = spawnSync(process.execPath, [path.join(project, 'tools/plan_web_content.mjs'), '--input', input, '--inventory', inventory, '--output', output], { encoding: 'utf8' });
  assert.equal(run.status, 0, run.stderr + run.stdout);
  const plan = JSON.parse(fs.readFileSync(output));
  const report = JSON.parse(fs.readFileSync(output.replace('.json', '.report.json')));
  const owners = new Map();
  for (const group of plan.groups) for (const name of group.paths) {
    assert.ok(records.has(name), `Planner invented a resource: ${name}`);
    assert.ok(!owners.has(name), `Resource assigned twice: ${name}`);
    owners.set(name, group.id.replace(/_\d+$/, ''));
  }
  for (const [name, family] of expected) assert.equal(owners.get(name) ?? 'core', family, `Wrong lifecycle ownership: ${name}`);
  assert.equal(report.groups.reduce((sum, group) => sum + group.count, 0), entries.length, 'Every source entry retains one owner');
  assert.equal(report.totalPayloadBytes, offset, 'Planning never removes source bytes');
  assert.ok(report.startupPromotions.some(entry => entry.logicalPath.endsWith('chapter4_a3_archive_film_v01.png')), 'Real transitive preload wins over late-chapter classification');
  assert.ok(report.unresolved.some(entry => entry.path === 'assets/unknown_owner.bin'), 'Unknown resource is reported and retained');
  for (const late of ['scripts/ui/chapter3_phone_pages.gd', 'scripts/presentation/library_story_host.gd', 'scripts/presentation/c3_scene_host.gd', 'scripts/presentation/c3_narrative_host.gd'])
    assert.ok(!report.startupParsedScripts.includes(late), `Deferred host pulled back into boot: ${late}`);
  console.log(JSON.stringify({ success: true, checkedOwnershipEntries: expected.size, inputEntries: entries.length, checks: ['Chapter 2/3/3.5/4 import units delayed together', 'Scene remap and exported payload delayed together', 'First-chapter audio and real hard preloads stay core', 'Runtime-loaded power art stays Chapter 4', 'Later presentation hosts stay outside boot parsing', 'Unknown entries and all original byte counts retained'] }, null, 2));
} finally { fs.rmSync(temporary, { recursive: true, force: true }); }
