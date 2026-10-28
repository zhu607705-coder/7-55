import fs from 'node:fs';
import os from 'node:os';
import path from 'node:path';
import {fileURLToPath} from 'node:url';
import {createNativeTestSandbox} from './native_test_sandbox.mjs';
import {acquireNativeWorkspaceLock} from './native_validation_lock.mjs';
import {fileDigest} from './native_validation_identity.mjs';
import {startValidationProcess,joinValidationProcesses} from './managed_validation_process.mjs';

export const MEDIA_CLIPS=['rpg/cinematics/chapter4-prologue/chapter35_to_chapter4_h3_transition','rpg/cinematics/qizhen-rain-rescue/qizhen_rain_rescue_hailuo23_v01'];
export async function prepareImportAndMedia({root=path.resolve(import.meta.dirname,'../..'),installMedia=false,executable=process.env.GODOT_BIN||'godot',launch=startValidationProcess}={}) {
  root=path.resolve(root);const project=path.join(root,'godot_native');
  const release=acquireNativeWorkspaceLock(project,'isolated media conversion and strict preliminary import');
  const temporary=fs.mkdtempSync(path.join(os.tmpdir(),'755-import-media-')),media=path.join(temporary,'media');
  const sandbox=createNativeTestSandbox(project,'755-preliminary-import-');
  const logs=path.join(project,'exports/verification/import-media');
  const handles=[];let aborted;
  const cancel=signal=>{aborted ||= Error(`Preparation cancelled: ${signal}`);for(const handle of handles)handle.stop(aborted.message);};
  const onInt=()=>cancel('SIGINT'),onTerm=()=>cancel('SIGTERM');process.once('SIGINT',onInt);process.once('SIGTERM',onTerm);
  const began=Date.now();
  try {
    fs.mkdirSync(logs,{recursive:true});
    const converter='tools/convert_media.sh',inputs=[converter,...MEDIA_CLIPS.map(name=>`assets/${name}.mp4`)];
    const hashes=new Map(inputs.map(relative=>[relative,fileDigest(path.join(project,relative))]));
    for(const relative of inputs){const target=path.join(media,relative);fs.mkdirSync(path.dirname(target),{recursive:true});fs.copyFileSync(path.join(project,relative),target);if(fileDigest(target)!==hashes.get(relative))throw Error(`Copied media input changed: ${relative}`);}
    // The temporary converter has its own workspace lock and outputs. It cannot
    // publish OGVs while Godot is reading the original project/import cache.
    handles.push(launch(executable,['--headless','--path',project,'--editor','--import','--quit'],{cwd:root,env:sandbox.env,logFile:path.join(logs,'preliminary-import.log'),strictGodot:true}));
    const mediaCommand=installMedia?'"$1" "$2" && NODE_BIN="$1" bash "$3"':'NODE_BIN="$1" bash "$3"';
    handles.push(launch('bash',['-c',mediaCommand,'755-isolated-media',process.execPath,path.join(root,'scripts/ensure-ci-media-tools.mjs'),path.join(media,converter)],{cwd:root,env:process.env,logFile:path.join(logs,'isolated-media.log')}));
    const processes=await joinValidationProcesses(handles);if(aborted)throw aborted;
    for(const [relative,hash] of hashes)if(fileDigest(path.join(project,relative))!==hash)throw Error(`Media source changed during preparation: ${relative}`);
    const receiptPath=path.join(media,'.validation/media-prepared.json');
    const receipt=JSON.parse(fs.readFileSync(receiptPath,'utf8'));
    if(receipt.converterSha256!==hashes.get(converter) || receipt.reports.length!==MEDIA_CLIPS.length)throw Error('Unexpected isolated conversion receipt');
    for(const [index,name] of MEDIA_CLIPS.entries()){
      const row=receipt.reports[index],input=`assets/${name}.mp4`,output=`assets/${name}.ogv`;
      if(row.input!==input || row.output!==output || row.sourceSha256!==hashes.get(input) || row.fullStreamValidation!==true || row.outputSha256!==fileDigest(path.join(media,output)))throw Error(`Invalid complete media output: ${name}`);
    }
    // No partial output is a success: publish the receipt last, only after both
    // children have closed. The original formal import/parse still runs next.
    for(const name of MEDIA_CLIPS){const relative=`assets/${name}.ogv`,target=path.join(project,relative),staged=`${target}.validated-${process.pid}.tmp`;fs.copyFileSync(path.join(media,relative),staged);fs.renameSync(staged,target);}
    fs.copyFileSync(receiptPath,path.join(project,'.validation/media-prepared.json'));
    const result={schema:1,elapsedMs:Date.now()-began,processes,isolatedOutputs:true,preliminaryImportPassed:true,formalImportStillRequired:true,sourceHashes:Object.fromEntries(hashes),reports:receipt.reports};
    fs.writeFileSync(path.join(logs,'preparation.json'),JSON.stringify(result,null,2)+'\n');return result;
  } finally {
    for(const handle of handles)await handle.stopAndJoin();
    process.removeListener('SIGINT',onInt);process.removeListener('SIGTERM',onTerm);
    fs.rmSync(temporary,{recursive:true,force:true});fs.rmSync(sandbox.root,{recursive:true,force:true});release();
  }
}
if(process.argv[1] && path.resolve(process.argv[1])===fileURLToPath(import.meta.url)){
  if(process.argv.slice(2).some(arg=>arg!=='--install-media'))throw Error('Usage: prepare_import_media.mjs [--install-media]');
  console.log(JSON.stringify(await prepareImportAndMedia({installMedia:process.argv.includes('--install-media')}),null,2));
}
