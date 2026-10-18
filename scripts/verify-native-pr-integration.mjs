#!/usr/bin/env node
/** Verify immutable PR source coexistence before testing real production adapters.
 * Nested projects intentionally keep independent res:// namespaces and saves.
 * This does not turn prototype completion dictionaries into campaign proof.
 */
import fs from 'node:fs';
import path from 'node:path';
import os from 'node:os';
import crypto from 'node:crypto';
import {spawnSync} from 'node:child_process';
const root=path.resolve(import.meta.dirname,'..');
const manifest=JSON.parse(fs.readFileSync(path.join(root,'godot_native/docs/PR_INTEGRATION_SOURCES_20261018.json'),'utf8'));
const report={kind:'cross-pr-source-and-runtime-compatibility',base:manifest.base,checks:[],runs:[],notManualPlaythrough:true,physicalMobileTest:false};
let failures=0;
const check=(ok,label)=>{report.checks.push({label,passed:!!ok});if(!ok){failures++;console.error('FAIL '+label);}};
const sourcePaths=new Set();
for(const source of manifest.sources){
 for(const file of source.source_files){
  check(!sourcePaths.has(file.path),`PR${source.pr}: disjoint source path ${file.path}`);sourcePaths.add(file.path);
  const p=path.join(root,file.path);
  check(fs.existsSync(p)&&crypto.createHash('sha256').update(fs.readFileSync(p)).digest('hex')===file.sha256,`PR${source.pr}: original bytes preserved ${file.path}`);
 }
 check(fs.existsSync(path.join(root,source.project_root,'project.godot')),`PR${source.pr}: separate project root exists`);
}
const sourceCheck=spawnSync(process.execPath,[path.join(root,'godot_native/tests/verify_rain_rescue_native_source.mjs')],{cwd:root,encoding:'utf8'});
check(sourceCheck.status===0,'native rescue adapter provenance and adapted-source hashes');
report.sourceCheckOutput=(sourceCheck.stdout||'')+(sourceCheck.stderr||'');
const projectRoots=[...new Set(manifest.sources.map(s=>s.project_root))];
function walk(dir){return fs.readdirSync(dir,{withFileTypes:true}).flatMap(e=>e.name==='.godot'?[]:e.isDirectory()?walk(path.join(dir,e.name)):[path.join(dir,e.name)]);}
for(const relative of projectRoots){
 const project=path.join(root,relative),uids=new Map();
 for(const p of walk(project)){
  if(p.endsWith('.uid')){const id=fs.readFileSync(p,'utf8').trim();check(!uids.has(id),`${relative}: unique UID ${path.relative(project,p)}`);uids.set(id,p);}
  if(!/\.(gd|tscn|tres)$/.test(p)||/(?:^|\/)(?:tests|tools)\//.test(path.relative(project,p)))continue;
  const text=fs.readFileSync(p,'utf8');
  const references=[...text.matchAll(/(?:preload|load|ResourceLoader\.(?:load|exists))\(\s*["'](res:\/\/[^"']+)["']/g),...text.matchAll(/\bpath="(res:\/\/[^"]+)"/g)];
  for(const m of references){
   if(m[1].includes('%')||!path.extname(m[1]))continue;
   const target=path.resolve(project,m[1].slice(6));
   check(target.startsWith(project+path.sep)&&fs.existsSync(target),`${relative}: local resource ${m[1]} from ${path.relative(project,p)}`);
  }
 }
}
// Production remains the real entry and original controller-owned chapter path.
const config=fs.readFileSync(path.join(root,'godot_native/project.godot'),'utf8');
check(config.includes('run/main_scene="res://scenes/entry.tscn"'),'formal production entry remains entry.tscn');
const chapter4=fs.readFileSync(path.join(root,'godot_native/scripts/chapters/chapter4.gd'),'utf8');
check(chapter4.includes('chapter4_chase_stair_model.gd')&&!chapter4.includes('chapter4_endless_stair_model.gd'),'unapproved twelve/two-flight replacement cannot impersonate formal chase proof');
const suites=[
 ['godot_native',['test_rain_rescue.gd','test_lake_live_world.gd','test_lake_entry_heading.gd','test_lake_app_routes.gd','test_chapter3.gd','test_lake_shell_input.gd','test_chapter4_post_stair_return.gd','test_endless_stair_integration.gd']],
 ['samples/qizhen-rain-rescue-native',['test_rescue.gd','test_rescue_input.gd']],
 ['examples/qizhen_playable_chase',['test_paddling.gd','test_paddling_cadence.gd','test_paddling_cadence_matrix.gd','test_paddling_geometry.gd','test_playable_chase_model.gd','test_playable_chase_inputs.gd']],
 ['examples/qizhen_large_world',['test_large_world.gd','audit_large_world.gd','test_input_camera.gd','test_route_30hz.gd']],
 ['examples/blender_stair_sample/preview',['test_blender_sample.gd','test_blender_sample_camera_input.gd','test_endless_stair_beam.gd']]
];
const mainTests=fs.readdirSync(path.join(root,'godot_native/tests')).filter(f=>/^test_(?:pr_integration|c3_swan|rain_rescue)/.test(f)&&f.endsWith('.gd'));
suites[0][1].push(...mainTests);
const mode=process.argv.includes('--runtime')?'runtime':process.argv.includes('--examples')?'examples':'static';
function run(relative,label,args){
 const sandbox=fs.mkdtempSync(path.join(os.tmpdir(),'755-pr-integration-'));
 for(const dir of ['home','data','config','cache','state'])fs.mkdirSync(path.join(sandbox,dir));
 const env={...process.env,HOME:path.join(sandbox,'home'),XDG_DATA_HOME:path.join(sandbox,'data'),XDG_CONFIG_HOME:path.join(sandbox,'config'),XDG_CACHE_HOME:path.join(sandbox,'cache'),XDG_STATE_HOME:path.join(sandbox,'state'),GODOT_TEST_USER_DATA_DIR:path.join(sandbox,'data','SevenFiftyFiveNative'),GODOT_SILENCE_ROOT_WARNING:'1'};
 const protectedFiles = relative==='godot_native'?[]:['save.json','save.previous.json','save.json.tmp'].map(name=>{
  const file=path.join(sandbox,'data','SevenFiftyFiveNative',name);fs.mkdirSync(path.dirname(file),{recursive:true});
  const bytes=Buffer.from('integration-isolation-sentinel:'+name+'\n');fs.writeFileSync(file,bytes);return {file,bytes};
 });
 const before=Date.now();const r=spawnSync(process.env.GODOT_BIN||'godot',['--headless','--audio-driver','Dummy','--path',path.join(root,relative),...args],{env,encoding:'utf8',maxBuffer:32*1024*1024,timeout:20*60*1000});
 for(const {file,bytes} of protectedFiles)check(fs.existsSync(file)&&fs.readFileSync(file).equals(bytes),`${relative}: ${label} leaves formal ${path.basename(file)} bytes unchanged`);
 const output=(r.stdout||'')+(r.stderr||'');const passed=!r.error&&r.status===0&&!/(?:^|\n)ERROR:|SCRIPT ERROR:|Parse Error:|TEST FAILED|ASSERTION FAILED/.test(output);
 report.runs.push({project:relative,label,passed,exitCode:r.status,elapsedMs:Date.now()-before,output});
 if(!passed)failures++;
 console.log(`${passed?'PASS':'FAIL'} ${relative}: ${label}`);if(!passed)console.error(output.slice(-16000));
}
if(mode!=='static'&&!failures){
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
