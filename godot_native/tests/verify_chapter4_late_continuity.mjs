#!/usr/bin/env node
// Real campaign-earned C4 saves -> separate entry/Continue processes.
import assert from 'node:assert/strict';
import fs from 'node:fs';
import os from 'node:os';
import path from 'node:path';
import {spawnSync} from 'node:child_process';
import {createNativeTestSandbox} from '../tools/native_test_sandbox.mjs';
const project=path.resolve(import.meta.dirname,'..');
const output=path.resolve(process.env.C4_LATE_OUTPUT||fs.mkdtempSync(path.join(os.tmpdir(),'755-c4-late-continuity-')));
const earned=path.join(output,'earned');fs.mkdirSync(earned,{recursive:true});
const records=[];
function run(label,script,fixture,extra={}){
 const result=spawnSync(process.env.GODOT_BIN||'godot',['--headless','--audio-driver','Dummy','--path',fixture.project,'--script',`res://tests/${script}`],{env:{...fixture.env,...extra},encoding:'utf8',timeout:12*60*1000,maxBuffer:32*1024*1024});
 const outputText=(result.stdout||'')+(result.stderr||'');fs.writeFileSync(path.join(output,label+'.log'),outputText);
 const ok=!result.error&&result.status===0&&!/(?:^|\n)ERROR:|SCRIPT ERROR:|Parse Error:|Failed to load script/.test(outputText);
 records.push({label,ok,status:result.status,error:result.error?.message||null});fs.writeFileSync(path.join(output,'summary.json'),JSON.stringify(records,null,2));
 console.log(`${ok?'PASS':'FAIL'} ${label}`);
 if(!ok){console.error(outputText.slice(-18000));throw Error(`C4 late entry failed: ${label}; evidence ${output}`);}
}
run('earned-campaign','chapter4_late_continuity_recorder.gd',createNativeTestSandbox(project),{C4_LATE_CAPTURE_DIR:earned,CAMPAIGN_REPORT:path.join(output,'campaign.json')});
for(const [scenario,action] of [['stairs','c4_stairs_complete'],['chase','c4_chase_done']]){
 const save=path.join(earned,action+'.json');assert.ok(fs.existsSync(save),`campaign emitted ${action}`);
 for(const [width,height] of [[1280,720],[390,844]]){
  const fixture=createNativeTestSandbox(project);fs.copyFileSync(save,path.join(fixture.userData,'save.json'));
  const label=`${scenario}-${width}x${height}`;
  run(label,'probe_chapter4_late_entry.gd',fixture,{C4_LATE_SCENARIO:scenario,C4_LATE_WIDTH:String(width),C4_LATE_HEIGHT:String(height),C4_LATE_REPORT:path.join(output,label+'.json')});
 }
}
console.log(`C4 late cross-process continuity passed; evidence: ${output}`);
