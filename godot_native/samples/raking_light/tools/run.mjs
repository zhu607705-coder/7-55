#!/usr/bin/env node
// Isolated headless checks. No claim of rendered/mobile acceptance.
import fs from 'node:fs';
import os from 'node:os';
import path from 'node:path';
import {spawnSync} from 'node:child_process';
const project=path.resolve(import.meta.dirname,'..');
const engine=process.env.GODOT_BIN||'godot';
const version=spawnSync(engine,['--version'],{encoding:'utf8'});
if(version.status!==0||!version.stdout.startsWith('4.7.1.'))throw Error('Pinned Godot 4.7.1 required');
const dir=fs.mkdtempSync(path.join(os.tmpdir(),'755-raking-light-'));
const copy=path.join(dir,'project');
fs.cpSync(project,copy,{recursive:true,filter:p=>!['.godot','build'].includes(path.basename(p))&&!['.uid','.import'].includes(path.extname(p))});
const env={...process.env};
for(const [key,name]of Object.entries({XDG_DATA_HOME:'data',XDG_CONFIG_HOME:'config',XDG_CACHE_HOME:'cache',XDG_STATE_HOME:'state'})){env[key]=path.join(dir,name);fs.mkdirSync(env[key],{recursive:true});}
const sentinel=path.join(env.XDG_DATA_HOME,'SevenFiftyFiveNative');fs.mkdirSync(sentinel);
for(const name of ['save.json','save.previous.json','save.json.tmp'])fs.writeFileSync(path.join(sentinel,name),'untouched:'+name);
const report={engine:version.stdout.trim(),rendered:false,physicalPhone:false,stages:[]};
function run(name,args){const r=spawnSync(engine,['--headless','--audio-driver','Dummy','--path',copy,...args],{env,encoding:'utf8',timeout:180000});const out=(r.stdout||'')+(r.stderr||'');const ok=r.status===0&&!/(?:^|\n)ERROR:|SCRIPT ERROR:|Parse Error:|TEST FAILED/.test(out);report.stages.push({name,ok,out});console.log(`${ok?'PASS':'FAIL'} ${name}`);if(!ok)throw Error(out);}
try{
 run('clean import',['--editor','--import','--quit']);
 for(const file of fs.readdirSync(path.join(copy,'tests')).filter(p=>p.startsWith('test_')&&p.endsWith('.gd')&&!p.includes('render')))run(file,['--script','res://tests/'+file]);
 run('ordinary startup',['--quit-after','5']);
 for(const name of ['save.json','save.previous.json','save.json.tmp'])if(fs.readFileSync(path.join(sentinel,name),'utf8')!=='untouched:'+name)throw Error('Formal save touched');
 report.formalSaveSentinelsUnchanged=true;
 fs.mkdirSync(path.join(project,'build'),{recursive:true});fs.writeFileSync(path.join(project,'build','test-report.json'),JSON.stringify(report,null,2));
}finally{fs.rmSync(dir,{recursive:true,force:true});}
