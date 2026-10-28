import test from 'node:test';
import assert from 'node:assert/strict';
import fs from 'node:fs';
import path from 'node:path';
import os from 'node:os';
import {prepareImportAndMedia,MEDIA_CLIPS} from '../tools/prepare_import_media.mjs';
import {fileDigest} from '../tools/native_validation_identity.mjs';
import {startValidationProcess,joinValidationProcesses} from '../tools/managed_validation_process.mjs';

const tick=async()=>{for(let i=0;i<20;i++)await Promise.resolve();};
function fixture(){
 const root=fs.mkdtempSync(path.join(os.tmpdir(),'755-preparation-test-')),project=path.join(root,'godot_native');
 for(const relative of ['tools/convert_media.sh',...MEDIA_CLIPS.map(name=>`assets/${name}.mp4`)]){const file=path.join(project,relative);fs.mkdirSync(path.dirname(file),{recursive:true});fs.writeFileSync(file,relative);}
 fs.writeFileSync(path.join(project,'project.godot'),'[application]\nconfig/name="Synthetic preparation fixture"\n');
 return {root,project};
}
function fakeLaunch(context){return (command,args,options)=>{
 let resolve,reject,closed=false;const completion=new Promise((a,b)=>{resolve=a;reject=b;});completion.catch(()=>{});
 const handle={command,args,options,completion,finish(){closed=true;resolve({status:0});},stop(reason){closed=true;reject(Error(reason));},async stopAndJoin(){if(!closed)this.stop('cleanup');await Promise.allSettled([completion]);}};
 if(command==='bash'){
  const converter=args.at(-1),media=path.dirname(path.dirname(converter));context.media=media;
  const reports=MEDIA_CLIPS.map(name=>{const input=`assets/${name}.mp4`,output=`assets/${name}.ogv`;fs.writeFileSync(path.join(media,output),'whole validated output');return {input,output,sourceSha256:fileDigest(path.join(media,input)),outputSha256:fileDigest(path.join(media,output)),fullStreamValidation:true};});
  fs.mkdirSync(path.join(media,'.validation'));fs.writeFileSync(path.join(media,'.validation/media-prepared.json'),JSON.stringify({converterSha256:fileDigest(converter),reports}));
 }
 context.handles.push(handle);return handle;
};}
test('two preparation children overlap but validated media publish only after both close',async()=>{
 const f=fixture(),context={handles:[]};try{
  const promise=prepareImportAndMedia({...f,launch:fakeLaunch(context)});assert.equal(context.handles.length,2);
  assert.equal(context.handles[0].options.strictGodot,true);assert.equal(context.handles[0].args.includes(f.project),true);
  assert.notEqual(context.media,f.project);assert.ok(!context.media.startsWith(f.project+path.sep));
  context.handles[1].finish();await tick();
  assert.equal(fs.existsSync(path.join(f.project,`assets/${MEDIA_CLIPS[0]}.ogv`)),false);
  assert.equal(fs.existsSync(path.join(f.project,'.validation/media-prepared.json')),false);
  context.handles[0].finish();const result=await promise;
  assert.equal(result.formalImportStillRequired,true);assert.equal(result.isolatedOutputs,true);
  for(const row of result.reports)assert.equal(fileDigest(path.join(f.project,row.output)),row.outputSha256);
  assert.equal(fs.existsSync(context.media),false);assert.equal(fs.existsSync(path.join(f.project,'.validation/runner.lock')),false);
 }finally{fs.rmSync(f.root,{recursive:true,force:true});}
});
for(const failure of ['import','media','source-drift','bad-output','bad-receipt','launch'])test(`preparation ${failure} cannot publish or leave a running peer`,async()=>{
 const f=fixture(),context={handles:[]};try{
  const launch=fakeLaunch(context);const promise=prepareImportAndMedia({...f,launch:(...args)=>{if(failure==='launch'&&context.handles.length===1)throw Error('launch failed');return launch(...args);}});
  if(failure==='import')context.handles[0].stop('import failed');
  else if(failure==='media')context.handles[1].stop('media failed');
  else if(failure!=='launch'){
   if(failure==='source-drift')fs.appendFileSync(path.join(f.project,`assets/${MEDIA_CLIPS[0]}.mp4`),'changed');
   if(failure==='bad-output')fs.appendFileSync(path.join(context.media,`assets/${MEDIA_CLIPS[0]}.ogv`),'changed');
   if(failure==='bad-receipt')fs.writeFileSync(path.join(context.media,'.validation/media-prepared.json'),'{}');
   context.handles.forEach(handle=>handle.finish());
  }
  await assert.rejects(promise);await Promise.allSettled(context.handles.map(handle=>handle.completion));
  assert.equal(fs.existsSync(path.join(f.project,'.validation/media-prepared.json')),false);
  assert.equal(fs.existsSync(path.join(f.project,`assets/${MEDIA_CLIPS[0]}.ogv`)),false);
  assert.equal(fs.existsSync(path.join(f.project,'.validation/runner.lock')),false);
 }finally{fs.rmSync(f.root,{recursive:true,force:true});}
});
test('managed child rejects zero-exit Godot errors and joins a failed peer',async()=>{
 const root=fs.mkdtempSync(path.join(os.tmpdir(),'755-managed-child-test-'));try{

  // The actual lightweight Node process also exercises descriptor closure and
  // delayed stdout before close; no Godot/browser/full-suite process is launched.
  const failed=startValidationProcess(process.execPath,['-e','console.log("ERROR: strict diagnostic")'],{logFile:path.join(root,'error.log'),strictGodot:true});
  await assert.rejects(failed.completion,/Validation child failed/);await failed.stopAndJoin();
  let stopped=false;const peer={completion:new Promise((resolve,reject)=>{setTimeout(()=>resolve({}),50);}),stop(){stopped=true;}};
  await assert.rejects(joinValidationProcesses([failed,peer]));assert.equal(stopped,true);
 }finally{fs.rmSync(root,{recursive:true,force:true});}
});
test('fresh export closes before controller launch; join precedes any build success return',()=>{
 const source=fs.readFileSync(new URL('../tools/build_web.mjs',import.meta.url),'utf8');
 const exported=source.indexOf("runGodot('export'"),started=source.indexOf('fixtureProcess = startValidationProcess'),packing=source.indexOf('if (!monolithic) createContentDelivery'),joined=source.indexOf('child = await fixtureProcess.completion;');
 assert.ok(exported<started&&started<packing&&packing<joined);
 assert.match(source,/finally \{\s+if \(fixtureProcess\) await fixtureProcess.stopAndJoin\(\)/);
 assert.match(source,/if \(!args.includes\('--skip-import'\)\) runGodot\('import'/,'formal import remains');
});
test('cancellation joins both preparation children and removes locks without a receipt',async()=>{
 const f=fixture(),context={handles:[]};try{
  const promise=prepareImportAndMedia({...f,launch:fakeLaunch(context)});process.emit('SIGTERM');
  await assert.rejects(promise,/cancelled|Sibling/);await Promise.allSettled(context.handles.map(handle=>handle.completion));
  assert.equal(fs.existsSync(path.join(f.project,'.validation/media-prepared.json')),false);
  assert.equal(fs.existsSync(path.join(f.project,'.validation/runner.lock')),false);
 }finally{fs.rmSync(f.root,{recursive:true,force:true});}
});
test('managed cancellation terminates its own child and rejects instead of reporting pass',async()=>{
 const root=fs.mkdtempSync(path.join(os.tmpdir(),'755-managed-cancel-'));try{
  const child=startValidationProcess(process.execPath,['-e','setTimeout(()=>{},60000)'],{logFile:path.join(root,'cancel.log'),graceMs:50});
  child.stop('synthetic caller cancellation');await assert.rejects(child.completion,/synthetic caller cancellation/);await child.stopAndJoin();
 }finally{fs.rmSync(root,{recursive:true,force:true});}
});
for(const leaderExit of ['cancel','success'])test(`managed group drains a SIGTERM-ignoring descendant after leader ${leaderExit}`,async()=>{
 const root=fs.mkdtempSync(path.join(os.tmpdir(),'755-managed-descendant-')),ready=path.join(root,'ready'),pidFile=path.join(root,'pid');
 const grandchild=`const fs=require('fs');process.on('SIGTERM',()=>{});fs.writeFileSync(${JSON.stringify(ready)},'ready');setInterval(()=>{},1000);`;
 const program=`const {spawn}=require('child_process'),fs=require('fs');const c=spawn(process.execPath,['-e',${JSON.stringify(grandchild)}],{stdio:['ignore',1,2]});fs.writeFileSync(${JSON.stringify(pidFile)},String(c.pid));${leaderExit==='success'?`const t=setInterval(()=>{if(fs.existsSync(${JSON.stringify(ready)})){clearInterval(t);process.exit(0);}},5);`:'setInterval(()=>{},1000);'}`;
 let pid;try{
  const child=startValidationProcess(process.execPath,['-e',program],{logFile:path.join(root,'group.log'),graceMs:25});
  for(let i=0;i<400&&!fs.existsSync(ready);i++)await new Promise(r=>setTimeout(r,5));
  assert.equal(fs.existsSync(ready),true,'descendant is running and ignoring TERM');pid=Number(fs.readFileSync(pidFile));
  if(leaderExit==='cancel')child.stop('synthetic group cancellation');
  await assert.rejects(child.completion,/cancellation|live descendants/);await child.stopAndJoin();
  let state;try{state=fs.readFileSync(`/proc/${pid}/stat`,'utf8').split(') ')[1][0];}catch(e){if(e.code!=='ENOENT')throw e;}
  assert.ok(state===undefined||state==='Z','no live descendant remains after join');
 }finally{
  if(pid)try{process.kill(pid,'SIGKILL');}catch(e){if(e.code!=='ESRCH')throw e;}
  fs.rmSync(root,{recursive:true,force:true});
 }
});
test('a later sibling failure never signals an already-settled process group',async()=>{
 const root=fs.mkdtempSync(path.join(os.tmpdir(),'755-managed-settled-'));const originalKill=process.kill;let signals=0;
 try{
  const child=startValidationProcess(process.execPath,['-e',''],{logFile:path.join(root,'success.log'),graceMs:10});await child.completion;
  process.kill=()=>{signals++;return true;};child.stop('late sibling failure');await child.stopAndJoin();await new Promise(r=>setTimeout(r,30));
  assert.equal(signals,0,'settled process IDs/groups must not be signalled or scheduled for escalation');
 }finally{process.kill=originalKill;fs.rmSync(root,{recursive:true,force:true});}
});
