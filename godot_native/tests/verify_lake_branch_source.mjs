// Regenerate source expectations, then test the native controller in a fresh profile.
// The temporary root may be workspace-backed; actual save-path checks remain fail-closed.
import assert from 'node:assert/strict';
import {randomUUID} from 'node:crypto';
import {spawnSync} from 'node:child_process';
import {mkdirSync,rmSync,writeFileSync,readFileSync,existsSync} from 'node:fs';
import {createNativeTestSandbox} from '../tools/native_test_sandbox.mjs';
import {dirname,join,resolve} from 'node:path';
import {fileURLToPath} from 'node:url';
const root=resolve(dirname(fileURLToPath(import.meta.url)),'../..');
const saveNames=['save.json','save.previous.json','save.json.tmp'];
function fixture(prefix='755-lake-source-parity-') {
  const isolated=createNativeTestSandbox(join(root,'godot_native'),prefix);
  const sandbox=isolated.root,userData=isolated.userData;
  const nonce=randomUUID(),receipt=join(sandbox,'.lake-test-fixture.json');
  writeFileSync(receipt,JSON.stringify({schema:'lake-test-fixture-v1',nonce,user_data_dir:userData}));
  return {...isolated,sandbox,nonce,receipt,env:{...isolated.env,GODOT_LAKE_TEST_NONCE:nonce}};
}
function invoke(fixture) {
  const env=fixture.env;
  return spawnSync(process.env.GODOT_BIN||'godot',['--headless','--path',fixture.project,'--script','res://tests/test_qizhen_branches.gd','--','--fresh'],{cwd:root,env,encoding:'utf8',timeout:120000,maxBuffer:8*1024*1024});
}
// All rejection probes use disposable fixtures, never ordinary player directories.
const invalid=['undeclared','mismatch','relative','non_test_location','wrong_temp_root','missing_receipt','mismatched_receipt'];
const cases=[...invalid.map(kind=>({kind,populated:false})),...invalid.map(kind=>({kind,populated:true})),...saveNames.map(kind=>({kind,populated:true}))];
for(const {kind,populated} of cases) {
  const f=fixture(kind==='non_test_location'?'ordinary-profile-':'755-lake-source-parity-');
  try {
    if(kind==='undeclared')delete f.env.GODOT_TEST_USER_DATA_DIR;
    if(kind==='mismatch')f.env.GODOT_TEST_USER_DATA_DIR=f.userData+'-other';
    if(kind==='relative')f.env.GODOT_TEST_USER_DATA_DIR='data/SevenFiftyFiveNative';
    if(kind==='wrong_temp_root') {
      f.env.TMPDIR=join(f.sandbox,'another-temporary-root');mkdirSync(f.env.TMPDIR);
      f.env.TEMP=f.env.TMPDIR;f.env.TMP=f.env.TMPDIR;
    }
    if(kind==='missing_receipt')rmSync(f.receipt);
    if(kind==='mismatched_receipt')f.env.GODOT_LAKE_TEST_NONCE=randomUUID();
    const sentinels=new Map();
    for(const name of saveNames)if(populated&&(invalid.includes(kind)||kind===name)) {
      const bytes=Buffer.from(`Untouched ${kind} ${name}\n`);
      writeFileSync(join(f.userData,name),bytes);sentinels.set(name,bytes);
    }
    const result=invoke(f);if(result.error)throw result.error;
    const output=(result.stdout||'')+(result.stderr||'');
    assert.equal(result.status,2,`${kind}: expected fail-closed exit; got ${result.status}\n${output}`);
    assert.match(output,/LAKE_TEST_ISOLATION_REQUIRED/);
    assert.doesNotMatch(output,/Qizhen source branch parity:|SCRIPT ERROR:|Parse Error:/);
    for(const name of saveNames) {
      const path=join(f.userData,name);
      if(sentinels.has(name))assert.deepEqual(readFileSync(path),sentinels.get(name),`${kind}: changed ${name}`);
      else assert.equal(existsSync(path),false,`${kind}: created ${name}`);
    }
    console.log(`PASS lake save guard ${kind} (${populated?'sentinel saves':'empty profile'}): fixture bytes unchanged`);
  } finally {rmSync(f.sandbox,{recursive:true,force:true});}
}
const f=fixture();
try {
  const generated=spawnSync(process.execPath,['godot_native/tests/export_lake_branch_source_fixtures.mjs'],{cwd:root,env:f.env,encoding:'utf8',timeout:120000,maxBuffer:8*1024*1024});
  const generatedOutput=(generated.stdout||'')+(generated.stderr||'');process.stdout.write(generatedOutput);
  if(generated.error||generated.status!==0)throw new Error(`Source fixture generation failed: ${generated.error||generated.status}`);
  const result=invoke(f);const output=(result.stdout||'')+(result.stderr||'');process.stdout.write(output);
  if(result.error||result.status!==0||/(?:^|\n)ERROR:|SCRIPT ERROR:|Parse Error:/.test(output))throw new Error(`Lake source parity failed: ${result.error||result.status}`);
} finally {rmSync(f.sandbox,{recursive:true,force:true});}
