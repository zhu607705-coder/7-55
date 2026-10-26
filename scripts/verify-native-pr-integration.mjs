#!/usr/bin/env node
/** Verify immutable PR source coexistence before testing real production adapters.
 * Nested projects intentionally keep independent res:// namespaces and saves.
 * This does not turn prototype completion dictionaries into campaign proof.
 */
import fs from 'node:fs';
import path from 'node:path';
import {createNativeTestSandbox} from '../godot_native/tools/native_test_sandbox.mjs';
import crypto from 'node:crypto';
import {spawnSync} from 'node:child_process';
import {collectGodotProjectNamespaces,isExistingLocalGodotResource,appendTestsToGodotProject} from './godot-project-namespaces.mjs';
const root=path.resolve(import.meta.dirname,'..');
const manifest=JSON.parse(fs.readFileSync(path.join(root,'godot_native/docs/PR_INTEGRATION_SOURCES_20261018.json'),'utf8'));
const report={kind:'cross-pr-source-and-runtime-compatibility',base:manifest.base,checks:[],runs:[],notManualPlaythrough:true,physicalMobileTest:false};
let failures=0;
const check=(ok,label)=>{report.checks.push({label,passed:!!ok});if(!ok){failures++;console.error('FAIL '+label);}};
const matchesHash=(file,sha)=>fs.existsSync(file)&&crypto.createHash('sha256').update(fs.readFileSync(file)).digest('hex')===sha;
const sourcePaths=new Set();
for(const source of manifest.sources){
 for(const file of source.source_files){
  check(!sourcePaths.has(file.path),`PR${source.pr}: disjoint source path ${file.path}`);sourcePaths.add(file.path);
  const p=path.join(root,file.path);
  if(file.original_snapshot||file.adapted_sha256||file.reason){
   const snapshot=path.resolve(root,file.original_snapshot||'');
   const snapshotDir=path.join(root,'godot_native/docs/source_snapshots',`pr${source.pr}`)+path.sep;
   check(typeof file.original_snapshot==='string'&&snapshot.startsWith(snapshotDir)&&snapshot.endsWith('.source.txt')&&typeof file.reason==='string'&&file.reason.trim().length>0,`PR${source.pr}: adaptation has a scoped original snapshot and reason ${file.path}`);
   check(snapshot.startsWith(snapshotDir)&&matchesHash(snapshot,file.sha256),`PR${source.pr}: original bytes preserved in snapshot ${file.path}`);
   check(/^[a-f0-9]{64}$/.test(file.adapted_sha256||'')&&matchesHash(p,file.adapted_sha256),`PR${source.pr}: adapted bytes match reviewed hash ${file.path}`);
  }else{
   check(matchesHash(p,file.sha256),`PR${source.pr}: original bytes preserved ${file.path}`);
  }
 }
 check(fs.existsSync(path.join(root,source.project_root,'project.godot')),`PR${source.pr}: separate project root exists`);
}
const sourceCheck=spawnSync(process.execPath,[path.join(root,'godot_native/tests/verify_rain_rescue_native_source.mjs')],{cwd:root,encoding:'utf8'});
check(sourceCheck.status===0,'native rescue adapter provenance and adapted-source hashes');
report.sourceCheckOutput=(sourceCheck.stdout||'')+(sourceCheck.stderr||'');
const projectRoots=[...new Set(manifest.sources.map(s=>s.project_root))];
const namespaceRegression=spawnSync(process.execPath,[path.join(root,'scripts/test-godot-project-namespaces.mjs')],{cwd:root,encoding:'utf8'});
check(namespaceRegression.status===0,'nested project namespace regression including missing-child negative fixture');
report.namespaceRegressionOutput=(namespaceRegression.stdout||'')+(namespaceRegression.stderr||'');
// One project-ID registry composes independent PR previews without array-position ownership.
// A branch may carry either preview or both; present projects are always scanned and tested.
const previewProjects=[
 {project:'godot_native/samples/phone_to_campus/preview',tests:['res://test_transition.gd'],prepare:['godot_native/samples/phone_to_campus/run.mjs','--prepare-only']},
 {project:'godot_native/samples/north_real_plan_preview',tests:['res://tests/test_preview.gd'],prepare:[]},
 {project:'godot_native/samples/paper_rewind',tests:['res://tests/test_paper_rewind.gd','res://tests/test_paper_rewind_input.gd','res://tests/test_paper_rewind_two_hands.gd','res://tests/test_paper_world_3d.gd'],prepare:[]}
].filter(preview=>fs.existsSync(path.join(root,preview.project,'project.godot')));
report.previewProjects=previewProjects.map(({project,tests})=>({project,tests}));
for(const preview of previewProjects){
 if(!preview.prepare.length)continue;
 const prepared=spawnSync(process.execPath,[path.join(root,preview.prepare[0]),...preview.prepare.slice(1)],{cwd:root,encoding:'utf8'});
 check(prepared.status===0,`${preview.project}: verify original font bytes before namespace checks`);
 report.previewPreparation=(report.previewPreparation||[]).concat({project:preview.project,output:(prepared.stdout||'')+(prepared.stderr||'')});
}
const namespaces=collectGodotProjectNamespaces(projectRoots.map(relative=>path.join(root,relative)));
// PR #118 deliberately permits one unauthored idle asset. Require its exact
// guarded load and the real side-art mirror; all other resources stay required.
const optionalLeftIdle='res://assets/rpg/player/player_left_idle.png';
function hasGuardedLeftIdleFallback(text,project){
 const escaped=optionalLeftIdle.replace(/[.*+?^${}()|[\]\\]/g,'\\$&');
 const guard=new RegExp(`^([\\t ]*)if ResourceLoader\\.exists\\(["']${escaped}["']\\):\\r?\\n\\1[\\t ]+player_left_idle\\s*=\\s*load\\(["']${escaped}["']\\)\\s*$`,'m');
 return guard.test(text)
  &&text.split(optionalLeftIdle).length===3
  &&fs.existsSync(path.join(project,'assets/rpg/player/player_side_idle.png'))
  &&/player_side_idle\s*=\s*load\("res:\/\/assets\/rpg\/player\/player_side_idle\.png"\)/.test(text)
  &&/var flip:\s*bool\s*=\s*pose\.flip and direction=="side"/.test(text)
  &&/if flip and player_frames\.get\("left",\[\]\)\.size\(\)==8:\s*\n\s*direction="left";\s*flip=false/.test(text)
  &&/if direction=="side" and player_side_idle!=null:\s*texture=player_side_idle/.test(text)
  &&/return \{[^\n]*"flip_h":flip/.test(text);
}
for(const [project,files] of namespaces){
 const relative=path.relative(root,project).split(path.sep).join('/'),uids=new Map();
 for(const p of files){
  if(p.endsWith('.uid')){const id=fs.readFileSync(p,'utf8').trim();check(!uids.has(id),`${relative}: unique UID ${path.relative(project,p)}`);uids.set(id,p);}
  if(!/\.(gd|tscn|tres)$/.test(p)||/(?:^|\/)(?:tests|tools)\//.test(path.relative(project,p)))continue;
  const text=fs.readFileSync(p,'utf8');
  const references=[...text.matchAll(/(?:preload|load|ResourceLoader\.(?:load|exists))\(\s*["'](res:\/\/[^"']+)["']/g),...text.matchAll(/\bpath="(res:\/\/[^"]+)"/g)];
  for(const m of references){
   if(m[1].includes('%')||!path.extname(m[1]))continue;
   const owner=path.relative(project,p);
   if(relative==='godot_native'&&owner==='scripts/world.gd'&&m[1]===optionalLeftIdle){
    check(hasGuardedLeftIdleFallback(text,project),`${relative}: optional left idle has exists guard and real mirrored side fallback`);
   }else{
    check(isExistingLocalGodotResource(project,m[1]),`${relative}: local resource ${m[1]} from ${owner}`);
   }
  }
 }
}
// Production remains the real entry and original controller-owned chapter path.
const config=fs.readFileSync(path.join(root,'godot_native/project.godot'),'utf8');
check(config.includes('run/main_scene="res://scenes/entry.tscn"'),'formal production entry remains entry.tscn');
const chapter4=fs.readFileSync(path.join(root,'godot_native/scripts/chapters/chapter4.gd'),'utf8');
check(chapter4.includes('chapter4_chase_stair_model.gd')&&!chapter4.includes('chapter4_endless_stair_model.gd'),'unapproved twelve/two-flight replacement cannot impersonate formal chase proof');
const suites=[
 ['godot_native',['test_rain_rescue.gd','test_lake_live_world.gd','test_lake_entry_heading.gd','test_lake_app_routes.gd','test_chapter3.gd','test_lake_shell_input.gd','test_chapter4_post_stair_return.gd','test_endless_stair_integration.gd','test_character_facing.gd','test_qizhen_swan_entrance.gd']],
 ['samples/qizhen-rain-rescue-native',['test_rescue.gd','test_rescue_input.gd']],
 ['examples/qizhen_playable_chase',['test_paddling.gd','test_paddling_cadence.gd','test_paddling_cadence_matrix.gd','test_paddling_geometry.gd','test_playable_chase_model.gd','test_playable_chase_inputs.gd']],
 ['examples/qizhen_large_world',['test_large_world.gd','audit_large_world.gd','test_input_camera.gd','test_route_30hz.gd']],
 ['examples/blender_stair_sample/preview',['test_blender_sample.gd','test_blender_sample_camera_input.gd','test_endless_stair_beam.gd']]
];
const mainTests=fs.readdirSync(path.join(root,'godot_native/tests')).filter(f=>/^test_(?:pr_integration|c3_swan|rain_rescue)/.test(f)&&f.endsWith('.gd'));
appendTestsToGodotProject(suites,'godot_native',mainTests);
// Fail wrong project ownership before any expensive import. No formal tests move to a preview.
for(const [relative,tests] of suites)for(const file of new Set(tests)){
 check(fs.existsSync(path.join(root,relative,'tests',file)),`${relative}: registered runtime test exists ${file}`);
}
for(const preview of previewProjects)for(const file of new Set(preview.tests)){
 check(isExistingLocalGodotResource(path.join(root,preview.project),file),`${preview.project}: registered preview test exists ${file}`);
}
const mode=process.argv.includes('--runtime')?'runtime':process.argv.includes('--examples')?'examples':'static';
function run(relative,label,args){
 const fixture=createNativeTestSandbox(path.join(root,relative));
 const sandbox=fixture.root,env=fixture.env;
 const protectedFiles = relative==='godot_native'?[]:['save.json','save.previous.json','save.json.tmp'].map(name=>{
  const file=path.join(sandbox,'data','SevenFiftyFiveNative',name);fs.mkdirSync(path.dirname(file),{recursive:true});
  const bytes=Buffer.from('integration-isolation-sentinel:'+name+'\n');fs.writeFileSync(file,bytes);return {file,bytes};
 });
 const before=Date.now();const r=spawnSync(process.env.GODOT_BIN||'godot',['--headless','--audio-driver','Dummy','--path',fixture.project,...args],{env,encoding:'utf8',maxBuffer:32*1024*1024,timeout:20*60*1000});
 for(const {file,bytes} of protectedFiles)check(fs.existsSync(file)&&fs.readFileSync(file).equals(bytes),`${relative}: ${label} leaves formal ${path.basename(file)} bytes unchanged`);
 const output=(r.stdout||'')+(r.stderr||'');const passed=!r.error&&r.status===0&&!/(?:^|\n)ERROR:|SCRIPT ERROR:|Parse Error:|TEST FAILED|ASSERTION FAILED/.test(output);
 report.runs.push({project:relative,label,passed,exitCode:r.status,elapsedMs:Date.now()-before,output});
 if(!passed)failures++;
 console.log(`${passed?'PASS':'FAIL'} ${relative}: ${label}`);if(!passed)console.error(output.slice(-16000));
}
if(mode!=='static'&&!failures){
 for(const preview of previewProjects){
  run(preview.project,'fresh process preview import',['--editor','--import','--quit']);
  for(const file of new Set(preview.tests))run(preview.project,file,['--script',file]);
 }
 for(const [relative,tests] of suites){
  if(mode==='examples'&&relative==='godot_native')continue;
  run(relative,'fresh process asset import',['--editor','--import','--quit']);
  for(const file of new Set(tests))run(relative,file,['--script',`res://tests/${file}`]);
 }
}
report.failures=failures;report.staticChecks=report.checks.length;report.mode=mode;
if(process.env.PR_INTEGRATION_REPORT)fs.writeFileSync(process.env.PR_INTEGRATION_REPORT,JSON.stringify(report,null,2)+'\n');
console.log(`PR integration: ${report.staticChecks} static checks, ${report.runs.length} runtime stages, ${failures} failures`);
process.exitCode=failures?1:0;
