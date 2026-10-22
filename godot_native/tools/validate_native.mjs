import fs from 'node:fs';
import path from 'node:path';
import {createHash} from 'node:crypto';
import {createNativeTestSandbox} from './native_test_sandbox.mjs';
import {spawn,spawnSync} from 'node:child_process';
const project=path.resolve(import.meta.dirname,'..');
const executable=process.env.GODOT_BIN||'godot';
const logs=[];
const filterArgument=process.argv.indexOf('--filter');
if(filterArgument!==-1&&!process.argv[filterArgument+1])throw Error('--filter requires a regular expression matching stage labels');
const filter=filterArgument===-1?null:new RegExp(process.argv[filterArgument+1]);
const report=process.env.GODOT_TEST_REPORT;
const resume=process.argv.includes('--resume');
if(resume&&!report)throw Error('--resume requires GODOT_TEST_REPORT pointing to the completed-stage report');
const jobs=Number(process.env.NATIVE_TEST_JOBS||1);
if(!Number.isInteger(jobs)||jobs<1||jobs>4)throw Error('NATIVE_TEST_JOBS must be 1, 2, 3, or 4');
const pauseFile=process.env.GODOT_TEST_PAUSE_FILE||'/tmp/codex-755-test-pause';
let announcedPause=false;
let matchedStages=0;
if(resume)logs.push(...JSON.parse(fs.readFileSync(report,'utf8')));
const startedAt=new Date().toISOString();
function writeReport(){
 if(!report)return;
 fs.mkdirSync(path.dirname(path.resolve(report)),{recursive:true});
 const temporary=`${report}.${process.pid}.tmp`;
 fs.writeFileSync(temporary,JSON.stringify(logs,null,2));
 fs.renameSync(temporary,report);
}
if(report){
 fs.mkdirSync(path.dirname(path.resolve(report)),{recursive:true});
 const git=(args)=>spawnSync('git',args,{cwd:path.dirname(project),encoding:'utf8',maxBuffer:32*1024*1024}).stdout||'';
 const previous=resume?JSON.parse(fs.readFileSync(`${report}.meta.json`,'utf8')):null;
 const attempt={startedAt,project,executable,jobs,filter:filter?.source||null,
  gitHead:git(['rev-parse','HEAD']).trim(),worktreeStatus:git(['status','--porcelain']),
  worktreeDiffSha256:createHash('sha256').update(git(['diff','--binary','HEAD'])).digest('hex'),
  semantics:'Default sequential order. Optional jobs parallelize independent GD checks between fixture-writer barriers. Each completed stage is atomically persisted. Filtered runs are partial validation; resume retains earlier evidence, so changed runtime code needs affected-stage reruns.'};
 fs.writeFileSync(`${report}.meta.json`,JSON.stringify({...attempt,attempts:[...(previous?.attempts|| (previous?[previous]:[])),attempt]},null,2));
 writeReport();
}
async function run(label,args,command=executable){
 if(filter&&!filter.test(label))return true;
 matchedStages++;
 if(resume&&logs.some(row=>row.label===label&&row.failed===false))return true;
 while(fs.existsSync(pauseFile)){
  if(!announcedPause){console.log(`PAUSED native validation while ${pauseFile} exists`);announcedPause=true;}
  await new Promise(resolve=>setTimeout(resolve,1000));
 }
 const fixture=createNativeTestSandbox(project);
 const env=fixture.env;
 if(command===executable)args=args.map((value,index)=>index>0&&args[index-1]==='--path'?fixture.project:value);
 const timeout=(label==='Godot asset import and editor parse'?20:['test_full_campaign.gd','Formal campaign entry persistence','Chapter 4 late Continue persistence'].includes(label)?12:5)*60*1000;
 const stageStartedAt=new Date().toISOString();
 const start=Date.now();
 const r=await new Promise(resolve=>{
  const child=spawn(command,args,{timeout,env});
  let stdout='',stderr='',error=null,bytes=0;
  const capture=channel=>chunk=>{
   bytes+=Buffer.byteLength(chunk);
   if(bytes>32*1024*1024){error=new Error('Native stage output exceeded 32 MiB');child.kill();return;}
   if(channel==='stdout')stdout+=chunk;else stderr+=chunk;
  };
  child.stdout.setEncoding('utf8').on('data',capture('stdout'));
  child.stderr.setEncoding('utf8').on('data',capture('stderr'));
  child.on('error',value=>{error=value;});
  child.on('close',(status,signal)=>resolve({status,signal,error,stdout,stderr}));
 });
 const text=(r.stdout||'')+(r.stderr||'');
 const failed=r.error||r.status!==0||/(?:^|\n)ERROR:|SCRIPT ERROR:|Parse Error:|Failed to load script|TEST FAILED|ASSERTION FAILED/.test(text);
 const row={label,status:r.status,failed:!!failed,signal:r.signal,error:r.error?.message||null,
  startedAt:stageStartedAt,finishedAt:new Date().toISOString(),durationMs:Date.now()-start,command,args,output:text};
 const previousIndex=logs.findIndex(item=>item.label===label);
 if(previousIndex===-1)logs.push(row);else logs[previousIndex]=row;
 writeReport();
 console.log(`${failed?'FAIL':'PASS'} ${label}`);
 if(failed){console.error(text.slice(-24000));process.exitCode=1;} return !failed;
}
if(!fs.existsSync(path.join(project,'assets/rpg/fonts/fusion_pixel_12px_proportional_zh_hans.ttf')))throw Error('Run node godot_native/tools/sync_source.mjs first');
await run('Native save isolation',[path.join(project,'tests/verify_native_test_sandbox.mjs')],process.execPath);
await run('Godot asset import and editor parse',['--headless','--path',project,'--editor','--import','--quit']);
await run('Native Chinese text revisions',[path.join(project,'tests/verify_zh_text_revisions.mjs')],process.execPath);
await run('Native phone icon source parity',[path.join(project,'tests/verify_phone_icon_source.mjs')],process.execPath);
await run('Native startup',['--headless','--path',project,'--quit-after','15','--','--fresh']);
// These authored regressions generate the fixtures consumed later in the suite.
// Complete surrounding readers first, then run each producer alone in source order.
const fixtureWriters=new Set(['test_canteen_defense.gd','test_minigame_models.gd','test_photo_brightness_consumer.gd']);
let pending=[];
async function flush(){await Promise.all(pending);pending=[];}
for(const f of fs.readdirSync(path.join(project,'tests')).filter(x=>x.endsWith('.gd')&&x!=='test_save_migration.gd'&&(x.startsWith('test_')||x.startsWith('smoke_'))).sort()){
 const args=['--headless','--path',project,'--script',`res://tests/${f}`];
 if(fixtureWriters.has(f)){await flush();await run(f,args);}
 else{pending.push(run(f,args));if(pending.length>=jobs)await flush();}
}
await flush();
await run('Formal campaign entry persistence', [path.join(project,'tests/verify_continuity_entry.mjs')], process.execPath);
await run('Chapter 1 autosave and Continue persistence', [path.join(project,'tests/verify_c1_autosave_resume.mjs')], process.execPath);
await run('Chapter 4 late Continue persistence', [path.join(project,'tests/verify_chapter4_late_continuity.mjs')], process.execPath);
await run('Native Chinese/audio text contract',[path.join(project,'tests/verify_zh_audio_contract.mjs')],process.execPath);
await run('BUCT save-fixture isolation', [path.join(project,'tools/test_buct.mjs'),'--guard-only'],process.execPath);
for(const relative of ['tools/export-save-domains.mjs','tools/export-audio-director.mjs','tools/export-c3-world-source.mjs','tools/export-chapter4-device-source.mjs','tools/export-chapter4-context-source.mjs','tests/export_audio_state_fixtures.mjs','tests/export_chapter3_scene_source.mjs','tests/export_library_story_source.mjs','tests/export_lake_live_source_fixtures.mjs','tests/export_chapter3_narrative_source.mjs','tests/export_library_world_source.mjs','tests/export_canteen_mixer_source.mjs','tests/export_c3_devices_source.mjs','tests/export_c3_canteen_devices_source.mjs','tests/export_c3_bike_world_source.mjs']) {
 const args=[path.join(project,relative),'--check'];
 if(['tests/export_c3_canteen_devices_source.mjs','tests/export_c3_bike_world_source.mjs'].includes(relative))args.push('--source-root',path.dirname(project));
 await run('Source catalog '+relative,args,process.execPath);
}
for(const relative of ['tests/verify_source_model_parity.mjs','tests/verify_canteen_defense_source.mjs','tests/verify_canteen_pickup_source.mjs','tests/verify_canteen_paper_art_source.mjs','tests/verify_canteen_paper_effects_source.mjs','tests/verify_canteen_victory_source.mjs','tests/verify_lake_branch_source.mjs'])await run('Source oracle '+relative,[path.join(project,relative)],process.execPath);
await run('Phone entry source contracts', [path.join(project,'tests/verify_phone_entry_source.py')], 'python3');
await run('Tiyi two-stage source model', [path.join(project,'../scripts/verify-tiyi-update-model.mjs')], process.execPath);
await run('Phone battery source model', [path.join(project,'../scripts/verify-phone-battery-model.mjs')], process.execPath);
await run('Photo brightness source lifecycle', [path.join(project,'tests/verify_photo_consumer_source.mjs')],process.execPath);
await run('Tiyi presence source setter', [path.join(project,'tests/export_tiyi_presence_source.mjs'),'--check'],process.execPath);
await run('Tiyi presence source CLI', [path.join(project,'tests/verify_tiyi_oracle_cli.mjs')],process.execPath);
await run('Canteen objective source handoff', [path.join(project,'tests/export_canteen_handoff_source.mjs'),'--source-root',path.dirname(project),'--check'],process.execPath);
await run('Canteen self-drink source contract', [path.join(project,'tests/export_canteen_self_drink_source.mjs'),'--source-root',path.dirname(project),'--check'],process.execPath);
await run('Canteen mode fibers source contract', [path.join(project,'tests/export_canteen_mode_fibers_source.mjs'),'--source-root',path.dirname(project),'--check'],process.execPath);
await run('Original SaveStore differential', [path.join(project,'tests/verify_save_migration.mjs')],process.execPath);
if(filter&&matchedStages===0)throw Error(`No validation stage matched --filter ${filter.source}`);
if(logs.some(row=>row.failed))process.exitCode=1;
writeReport();
