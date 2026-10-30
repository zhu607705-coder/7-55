// No production autoloads or saves. Import once; independent room suites run in parallel.
import fs from 'node:fs';
import os from 'node:os';
import path from 'node:path';
import {spawn, spawnSync} from 'node:child_process';
const native=path.resolve(import.meta.dirname,'../../..');
const engine=process.env.GODOT_BIN||'godot';
const version=spawnSync(engine,['--version'],{encoding:'utf8'});
if(version.status!==0||!version.stdout.trim().startsWith('4.7.1.'))throw Error('Godot 4.7.1 required');
const root=fs.mkdtempSync(path.join(os.tmpdir(),'755-flc-puzzles-'));
const project=path.join(root,'project');fs.mkdirSync(project);
const env={...process.env};
for(const name of ['XDG_DATA_HOME','XDG_CONFIG_HOME','XDG_CACHE_HOME','XDG_STATE_HOME']){env[name]=path.join(root,name);fs.mkdirSync(env[name]);}
const copied=new Set();
function copy(relative){
 if(copied.has(relative))return;copied.add(relative);
 let source=path.join(native,relative);
 if(!fs.existsSync(source)&&relative.startsWith('assets/rpg/'))source=path.join(native,'../src',relative);
 const target=path.join(project,relative);fs.mkdirSync(path.dirname(target),{recursive:true});fs.copyFileSync(source,target);
 if(relative.endsWith('.gd'))for(const [,dep] of fs.readFileSync(source,'utf8').matchAll(/["']res:\/\/([^"'\n]+)["']/g))if(!dep.includes('%')&&(fs.existsSync(path.join(native,dep))||dep.startsWith('assets/rpg/')))copy(dep);
}
const campus='campuses/future_learning_center';
const suites=['flex','collab','focus','storage','assembly','rail','rules','puzzles_integration','floor'];
for(const suite of suites)copy(`${campus}/tests/test_${suite}.gd`);
for(const name of fs.readdirSync(path.join(native,campus,'scripts/puzzles')))if(name.endsWith('.gd'))copy(`${campus}/scripts/puzzles/${name}`);
for(const floor of [2,3,4]){
 const relative=`${campus}/data/floor_${floor}.json`;copy(relative);
 const data=JSON.parse(fs.readFileSync(path.join(native,relative),'utf8'));
 for(const row of [...data.modules,...data.objects,...(data.atriums||[]),...(data.atrium?[data.atrium]:[])])for(const key of ['path','source'])if(row[key]?.startsWith('res://'))copy(row[key].slice(6));
}
for(const facing of ['down','up','side'])for(let i=0;i<8;i++)copy(`assets/rpg/player/player_${facing}_${i}.png`);
fs.writeFileSync(path.join(project,'project.godot'),'config_version=5\n[application]\nconfig/name="FLC isolated puzzle checks"\n[rendering]\nrenderer/rendering_method="gl_compatibility"\n');
function run(args){return new Promise((resolve,reject)=>{
 const child=spawn(engine,['--headless','--audio-driver','Dummy','--path',project,...args],{env});let log='';
 for(const stream of [child.stdout,child.stderr])stream.on('data',chunk=>log+=chunk);
 const timeout=setTimeout(()=>child.kill('SIGTERM'),120000);
 child.on('error',reject);child.on('close',code=>{clearTimeout(timeout);if(code!==0||/SCRIPT ERROR:|Parse Error:|(?:^|\n)ERROR:/.test(log))reject(Error(log));else resolve(log)});
});}
try{
 await run(['--editor','--import','--quit']);
 // Three workers avoid launching every renderer/import cache simultaneously.
 const pending=[...suites];
 await Promise.all(Array.from({length:3},async()=>{while(pending.length){const suite=pending.shift();const log=await run(['--script',`res://${campus}/tests/test_${suite}.gd`,'--','--with-view']);console.log(log.trim());}}));
 console.log('PASS FLC 4F isolated suites; production autoloads absent.');
}finally{fs.rmSync(root,{recursive:true,force:true});}
