import fs from 'node:fs';
import path from 'node:path';
export const FIXTURE_WRITERS = ['test_canteen_defense.gd', 'test_minigame_models.gd', 'test_photo_brightness_consumer.gd'];
export const PREFLIGHT = ['Prepared source and media inputs', 'Native save isolation', 'Godot asset import and editor parse', 'Native startup', 'test_all_scripts_parse.gd'];
export const NORTH_TARGETED = ['test_north_generated_objects.gd', 'test_north_independent_props.gd', 'test_north_preview_gate.gd', 'test_north_prop_fail_closed.gd'];
export const NORTH_AFFECTED = ['test_world.gd', 'test_chapter4_contact_movement.gd', 'test_chapter4_phase_world.gd', 'test_world_guard.gd', 'test_chapter4_world.gd', 'test_chapter4_context_exterior.gd', 'test_interior_door_collision.gd', 'test_world_object_picking.gd', 'test_direct_world_input.gd', 'test_direct_world_gestures.gd', 'test_world_input_animation.gd', 'test_world_presentation_lifecycle.gd', 'test_selected_world_native_layer.gd', 'test_mobile_floor_route.gd', 'test_mobile_floor_exact_arrival.gd'];
const DEPENDENCIES = new Map();
function consumers(producer, ids) {for (const id of ids) DEPENDENCIES.set(id, [producer]);}
consumers('test_minigame_models.gd', ['test_bike_chase_arrival.gd', 'test_mobile_bike_chase.gd', 'test_native_chase_integration.gd', 'test_lake_fishing_water.gd', 'test_qizhen_branches.gd', 'Source oracle tests/verify_source_model_parity.mjs']);
consumers('test_canteen_defense.gd', ['smoke_canteen_defense_ui.gd', 'test_canteen_defense_owners.gd', 'test_canteen_defense_world_return.gd', 'test_canteen_paper_effects.gd', 'test_canteen_victory_camera.gd', 'test_canteen_victory_pose.gd', 'test_chapter3_narrative.gd', 'Source oracle tests/verify_canteen_defense_source.mjs', 'Source oracle tests/verify_canteen_paper_effects_source.mjs']);
consumers('test_photo_brightness_consumer.gd', ['Photo brightness source lifecycle']);
DEPENDENCIES.set('test_chapter3.gd', ['test_canteen_defense.gd', 'test_minigame_models.gd']);
const LAKE_PREPARATION = 'Source catalog tests/export_lake_live_source_fixtures.mjs';
consumers(LAKE_PREPARATION, ['test_lake_live_world.gd']);
export function createValidationCatalog(project, executable = 'godot') {
 const stages = [];
 const run = (label, args, command = executable) => stages.push({id: label, label, args, command, exclusive: !label.endsWith('.gd') || FIXTURE_WRITERS.includes(label), dependencies: DEPENDENCIES.get(label) || []});
 run('Prepared source and media inputs', [path.join(project, 'tests/verify_native_prepared_inputs.mjs')], process.execPath);
run('Native save isolation',[path.join(project,'tests/verify_native_test_sandbox.mjs')],process.execPath);
run('Godot asset import and editor parse',['--headless','--path',project,'--editor','--import','--quit']);
run('Native Chinese text revisions',[path.join(project,'tests/verify_zh_text_revisions.mjs')],process.execPath);
run('Native phone icon source parity',[path.join(project,'tests/verify_phone_icon_source.mjs')],process.execPath);
run('Scene orientation browser presentation',[path.join(project,'tools/test_scene_orientation.mjs')],process.execPath);
run('Boot animation browser presentation',[path.join(project,'tools/test_boot_intro.mjs')],process.execPath);
run('Native startup',['--headless','--path',project,'--quit-after','15','--','--fresh']);
for(const f of fs.readdirSync(path.join(project,'tests')).filter(x=>x.endsWith('.gd')&&x!=='test_save_migration.gd'&&(x.startsWith('test_')||x.startsWith('smoke_'))).sort()) {
 run(f,['--headless','--path',project,'--script',`res://tests/${f}`]);
}
run('Formal campaign entry persistence', [path.join(project,'tests/verify_continuity_entry.mjs')], process.execPath);
run('Chapter 1 autosave and Continue persistence', [path.join(project,'tests/verify_c1_autosave_resume.mjs')], process.execPath);
run('Chapter 4 late Continue persistence', [path.join(project,'tests/verify_chapter4_late_continuity.mjs')], process.execPath);
run('Native Chinese/audio text contract',[path.join(project,'tests/verify_zh_audio_contract.mjs')],process.execPath);
run('BUCT save-fixture isolation', [path.join(project,'tools/test_buct.mjs'),'--guard-only'],process.execPath);
for(const relative of ['tools/export-save-domains.mjs','tools/export-audio-director.mjs','tools/export-c3-world-source.mjs','tools/export-chapter4-device-source.mjs','tools/export-chapter4-context-source.mjs','tests/export_audio_state_fixtures.mjs','tests/export_chapter3_scene_source.mjs','tests/export_library_story_source.mjs','tests/export_lake_live_source_fixtures.mjs','tests/export_chapter3_narrative_source.mjs','tests/export_library_world_source.mjs','tests/export_canteen_mixer_source.mjs','tests/export_c3_devices_source.mjs','tests/export_c3_canteen_devices_source.mjs','tests/export_c3_bike_world_source.mjs']) {
 const args=[path.join(project,relative),'--check'];
 if(['tests/export_c3_canteen_devices_source.mjs','tests/export_c3_bike_world_source.mjs'].includes(relative))args.push('--source-root',path.dirname(project));
 run('Source catalog '+relative,args,process.execPath);
}
for(const relative of ['tests/verify_source_model_parity.mjs','tests/verify_canteen_defense_source.mjs','tests/verify_canteen_pickup_source.mjs','tests/verify_canteen_paper_art_source.mjs','tests/verify_canteen_paper_effects_source.mjs','tests/verify_canteen_victory_source.mjs','tests/verify_lake_branch_source.mjs'])run('Source oracle '+relative,[path.join(project,relative)],process.execPath);
run('Phone entry source contracts', [path.join(project,'tests/verify_phone_entry_source.py')], 'python3');
run('Tiyi two-stage source model', [path.join(project,'../scripts/verify-tiyi-update-model.mjs')], process.execPath);
run('Phone battery source model', [path.join(project,'../scripts/verify-phone-battery-model.mjs')], process.execPath);
run('Photo brightness source lifecycle', [path.join(project,'tests/verify_photo_consumer_source.mjs')],process.execPath);
run('Tiyi presence source setter', [path.join(project,'tests/export_tiyi_presence_source.mjs'),'--check'],process.execPath);
run('Tiyi presence source CLI', [path.join(project,'tests/verify_tiyi_oracle_cli.mjs')],process.execPath);
run('Canteen objective source handoff', [path.join(project,'tests/export_canteen_handoff_source.mjs'),'--source-root',path.dirname(project),'--check'],process.execPath);
run('Canteen self-drink source contract', [path.join(project,'tests/export_canteen_self_drink_source.mjs'),'--source-root',path.dirname(project),'--check'],process.execPath);
run('Canteen mode fibers source contract', [path.join(project,'tests/export_canteen_mode_fibers_source.mjs'),'--source-root',path.dirname(project),'--check'],process.execPath);
run('Original SaveStore differential', [path.join(project,'tests/verify_save_migration.mjs')],process.execPath);

 // The old lake --check exporter actually writes. Prepare it before any readers.
 // Existing fixture consumers can sort before their writer; run selected writers
 // first in their authored relative order, then keep reader order stable.
 const order = [...PREFLIGHT, LAKE_PREPARATION, ...FIXTURE_WRITERS];
 return [...order.map(id => stages.find(s => s.id === id)), ...stages.filter(s => !order.includes(s.id))];
}
function northPath(file) {
 return ['godot_native/scripts/objects/north_prop_scene.gd', 'godot_native/scripts/presentation/north_generated_objects.gd', 'godot_native/shaders/north_prop_alpha_cutoff.gdshader', 'godot_native/data/native/north-baseline-objects.json', 'godot_native/data/native/north-generated-objects.json'].includes(file)
   || file.startsWith('godot_native/assets/native/north_objects_20261025/');
}
export function planValidation(catalog, {profile = 'full', tests = [], changedFiles = [], filter = null} = {}) {
 const profiles = ['full', 'preflight', 'north-targeted', 'north', 'changed'];
 if (!profiles.includes(profile)) throw Error(`Unknown profile ${profile}`);
 if (filter && (profile !== 'full' || tests.length || changedFiles.length)) throw Error('--filter is a raw diagnostic; do not combine it with profiles or changed/test selection');
 const byId = new Map(catalog.map(s => [s.id, s]));
 const selected = new Set(); const reasons = []; let effectiveProfile = profile;
 const add = id => {if (!byId.has(id)) throw Error(`Unknown exact stage ID: ${id}`); selected.add(id);};
 if (filter) {
   for (const s of catalog) if (filter.test(s.id)) add(s.id);
   if (!selected.size) throw Error(`No validation stage matched --filter ${filter.source}`);
   effectiveProfile = 'raw-diagnostic'; reasons.push('Raw regex selection: prerequisites and producer closure are NOT guaranteed.');
 } else {
   PREFLIGHT.forEach(add);
   tests.forEach(add);
   if (profile === 'changed' && !tests.length && !changedFiles.length) throw Error('--profile changed requires --test or --changed-file/--changed-since');
   let full = profile === 'full'; let north = profile === 'north';
   if (profile === 'north-targeted') NORTH_TARGETED.forEach(add);
   for (const file of changedFiles) {
     const id = path.posix.basename(file);
     if (file === `godot_native/tests/${id}` && byId.has(id)) add(id);
     else if (northPath(file)) north = true;
     else if (/^(?:docs\/|godot_native\/docs\/).*\.(?:md|txt)$/.test(file) || file === 'progress.md') reasons.push(`Documentation only: ${file}`);
     else {full = true; reasons.push(`Conservative full fallback for shared or unclassified input: ${file}`);}
   }
   if (north) [...NORTH_TARGETED, ...NORTH_AFFECTED].forEach(add);
   if (full) {catalog.forEach(s => add(s.id)); effectiveProfile = 'full';}
   // Small audited dependency manifest, not an inferred giant graph.
   function close(id) {for (const dep of byId.get(id).dependencies) if (!selected.has(dep)) {add(dep); close(dep);}}
   [...selected].forEach(close);
 }
 const stages = catalog.filter(s => selected.has(s.id));
 return {profile, effectiveProfile, partial: selected.size !== catalog.length || !!filter,
   finalAcceptance: 'A full exact-content run is still required; focused profiles are not release acceptance.',
   reasons, stages, rows: catalog.map(s => ({id: s.id, selected: selected.has(s.id), status: 'not-run', dependencies: s.dependencies, exclusive: s.exclusive}))};
}
