// Focused BUCT checks. Every Godot process gets a new disposable save directory.
import assert from 'node:assert/strict';
import fs from 'node:fs';
import os from 'node:os';
import path from 'node:path';
import {spawnSync} from 'node:child_process';
import {pathToFileURL} from 'node:url';

if(process.platform!=='linux')throw new Error('NATIVE_TEST_PLATFORM_REQUIRED: XDG-isolated native tests require Linux; refusing to launch Godot');

const project=path.resolve(import.meta.dirname,'..');
const executable=process.env.GODOT_BIN||'godot';
const saveNames=['save.json','save.previous.json','save.json.tmp'];
if(!process.argv.includes('--guard-only')) {
 await import('../tests/verify_buct_haidian_source.mjs');
 await import('../tests/verify_buct_haidian_east_roads_source.mjs');
 await import('../tests/verify_buct_student_source.mjs');
 await import('../tests/verify_buct_changping_source.mjs');
 await import('../tests/verify_buct_chaoyang_walkability_source.mjs');
 await import('../tests/verify_buct_ambient_squirrel_source.mjs');
 await import('../../scripts/check-buct-changping-east-road.mjs');
 await import('../../scripts/check-buct-changping-liuhu.mjs');
}
if(process.argv.includes('--source-only'))process.exit(0);
function sandbox() {
 const root=fs.mkdtempSync(path.join(os.tmpdir(),'755-native-check-'));
 for(const folder of ['data','config','cache','state','tmp','runtime','evidence'])fs.mkdirSync(path.join(root,folder));
 const userData=path.join(root,'data','SevenFiftyFiveNative');
 fs.mkdirSync(userData);
 return {root,userData,env:{...process.env,BUCT_EAST_ROAD_OUTPUT:path.join(root,'evidence'),BUCT_LIUHU_OUTPUT:path.join(root,'evidence'),TMPDIR:path.join(root,'tmp'),TEMP:path.join(root,'tmp'),TMP:path.join(root,'tmp'),XDG_RUNTIME_DIR:path.join(root,'runtime'),XDG_DATA_HOME:path.join(root,'data'),XDG_CONFIG_HOME:path.join(root,'config'),XDG_CACHE_HOME:path.join(root,'cache'),XDG_STATE_HOME:path.join(root,'state'),GODOT_TEST_USER_DATA_DIR:userData,GODOT_SILENCE_ROOT_WARNING:'1'}};
}
function invoke(fixture,script) {
 const result=spawnSync(executable,['--headless','--path',project,'--script',`res://tests/${script}`,'--','--fresh'],{env:fixture.env,encoding:'utf8',timeout:5*60*1000,maxBuffer:8*1024*1024});
 if(result.error)throw result.error;
 return {...result,text:(result.stdout||'')+(result.stderr||'')};
}
for(const platform of ['darwin','win32'])for(const runner of ['test_buct.mjs','validate_native.mjs']) {
 const code=`Object.defineProperty(process,'platform',{value:${JSON.stringify(platform)}});await import(${JSON.stringify(pathToFileURL(path.join(project,'tools',runner)).href)});`;
 const result=spawnSync(process.execPath,['--input-type=module','-e',code],{encoding:'utf8',timeout:10000,env:{...process.env,GODOT_BIN:'must-not-launch-without-isolation'}});
 if(result.error)throw result.error;
 assert.equal(result.status,1);
 assert.match(result.stderr,/NATIVE_TEST_PLATFORM_REQUIRED/);
 assert.doesNotMatch(result.stderr,/ENOENT/);
 console.log(`PASS ${runner} rejects unsupported ${platform} before launching Godot`);
}
// These rejection probes never use the real user's directories, even when
// simulating a manual invocation without the declaration or with a bad path.
const invalidDeclarations=['undeclared','mismatch','relative','non_test_location'];
const cases=[...invalidDeclarations.map(kind=>({kind,populated:false})),...invalidDeclarations.map(kind=>({kind,populated:true})),...saveNames.map(kind=>({kind,populated:true}))];
for(const {kind,populated} of cases) {
 const fixture=sandbox();
 if(kind==='undeclared')delete fixture.env.GODOT_TEST_USER_DATA_DIR;
 if(kind==='mismatch')fixture.env.GODOT_TEST_USER_DATA_DIR=fixture.userData+'-other';
 if(kind==='relative')fixture.env.GODOT_TEST_USER_DATA_DIR='data/SevenFiftyFiveNative';
 if(kind==='non_test_location') {
  fixture.env.XDG_DATA_HOME=path.join(fixture.root,'ordinary-profile');
  fixture.userData=path.join(fixture.env.XDG_DATA_HOME,'SevenFiftyFiveNative');
  fs.mkdirSync(fixture.userData,{recursive:true});
  fixture.env.GODOT_TEST_USER_DATA_DIR=fixture.userData;
 }
 const sentinels=new Map();
 for(const name of saveNames) {
  if(populated&&(invalidDeclarations.includes(kind)||kind===name)) {
   const bytes=Buffer.from(`Untouched ${kind} ${name}\n`);
   fs.writeFileSync(path.join(fixture.userData,name),bytes);sentinels.set(name,bytes);
  }
 }
 const result=invoke(fixture,'test_buct_entry.gd');
 assert.equal(result.status,2,`${kind}: expected fail-closed exit, got ${result.status}\n${result.text}`);
 assert.match(result.text,/BUCT_TEST_ISOLATION_REQUIRED/,kind);
 assert.doesNotMatch(result.text,/BUCT_ENTRY:|SCRIPT ERROR:|Parse Error:/,kind);
 for(const name of saveNames) {
  const file=path.join(fixture.userData,name);
  if(sentinels.has(name))assert.deepEqual(fs.readFileSync(file),sentinels.get(name),`${kind}: changed ${name}`);
  else assert.equal(fs.existsSync(file),false,`${kind}: created ${name}`);
 }
 console.log(`PASS BUCT save guard ${kind} (${populated?'sentinel saves':'empty profile'}): fixture bytes unchanged`);
}
if(!process.argv.includes('--guard-only')) {
 for(const script of ['test_buct_source_layers.gd','test_buct_student_maps.gd','test_buct_student_pin_layout.gd','test_buct_playable.gd','test_buct_chaoyang_walkability.gd','test_buct_roads_l_integration.gd','test_buct_court_north.gd','test_buct_ambient_squirrel.gd','test_buct_haidian.gd','test_buct_entry.gd','test_buct_changping_east_road.gd','test_buct_changping_liuhu.gd','test_buct_changping_south_bridge_water.gd','test_buct_haidian_east_roads.gd']) {
  const fixture=sandbox();const result=invoke(fixture,script);
  process.stdout.write(result.text);
  assert.equal(result.status,0,`${script} failed; sandbox retained at ${fixture.root}`);
  assert.doesNotMatch(result.text,/(?:^|\n)ERROR:|SCRIPT ERROR:|Parse Error:|leaked|still in use at exit/);
  console.log(`PASS ${script} (isolated saves: ${fixture.userData})`);
 }
}
