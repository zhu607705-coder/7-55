#!/usr/bin/env node
import assert from 'node:assert/strict';
import fs from 'node:fs';
import os from 'node:os';
import path from 'node:path';
import {createHash} from 'node:crypto';
import {spawnSync} from 'node:child_process';
import {createNativeTestSandbox} from '../tools/native_test_sandbox.mjs';
const project=path.resolve(import.meta.dirname,'..');
const output=path.resolve(process.env.C1_SAVE_OUTPUT||fs.mkdtempSync(path.join(os.tmpdir(),'755-c1-autosave-')));fs.mkdirSync(output,{recursive:true});
const source=process.env.C1_SAVE_SOURCE?path.resolve(process.env.C1_SAVE_SOURCE):null;
const original=source?fs.readFileSync(source):null;
const digest=bytes=>createHash('sha256').update(bytes).digest('hex');
const results=[];
for(const mode of ['fresh',...(source?['copied']:[])]){
 const fixture=createNativeTestSandbox(project);
 if(mode==='copied'){
  fs.writeFileSync(path.join(fixture.userData,'save.json'),original);
  const legacy=spawnSync('git',['show','0592269fb2d72944eef8c5aadf72a612cf99ea0f:godot_native/scripts/state.gd'],{cwd:path.dirname(project),encoding:'utf8'});
  assert.equal(legacy.status,0,legacy.stderr);fs.writeFileSync(path.join(fixture.project,'legacy_cached_state.gd'),legacy.stdout);
 }
 for(const phase of ['input','restart-continue']){
  const label=`${mode}-${phase}`;
  const run=spawnSync(process.env.GODOT_BIN||'godot',['--headless','--audio-driver','Dummy','--path',fixture.project,'--script','res://tests/test_c1_autosave_resume.gd'],{encoding:'utf8',timeout:90000,maxBuffer:8*1024*1024,env:{...fixture.env,C1_SAVE_REPORT:path.join(output,label+'.json'),C1_RELOAD_ONLY:phase==='restart-continue'?'1':'0',C1_LEGACY_VALIDATOR:mode==='copied'&&phase==='input'?'res://legacy_cached_state.gd':''}});
  const text=(run.stdout||'')+(run.stderr||'');fs.writeFileSync(path.join(output,label+'.log'),text);
  const ok=!run.error&&run.status===0&&!/(?:^|\n)ERROR:|SCRIPT ERROR:|Parse Error:/.test(text);
  results.push({label,ok,status:run.status,error:run.error?.message||null});fs.writeFileSync(path.join(output,'summary.json'),JSON.stringify({source,sourceSha256:original?digest(original):null,results},null,2));
  console.log(`${ok?'PASS':'FAIL'} ${label}`);if(!ok){console.error(text.slice(-18000));throw Error(`C1 autosave regression failed; evidence ${output}`);}
 }
}
if(source)assert.deepEqual(fs.readFileSync(source),original,'read-only source save must remain byte-identical');
console.log(`C1 autosave and independent Continue passed; evidence: ${output}`);
