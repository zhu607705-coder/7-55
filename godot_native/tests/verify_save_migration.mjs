#!/usr/bin/env node
/** Real SaveStore.load + SaveStore.save vs native decode. All saves are isolated. */
import fs from 'node:fs';
import assert from 'node:assert/strict';
import path from 'node:path';
import os from 'node:os';
import { gunzipSync } from 'node:zlib';
import { fileURLToPath } from 'node:url';
import { spawnSync } from 'node:child_process';
import { createServer } from 'vite';
const root=path.resolve(path.dirname(fileURLToPath(import.meta.url)),'../..');
const temporary=fs.mkdtempSync(path.join(os.tmpdir(),'755-save-differential-'));
const server=await createServer({root,configFile:false,appType:'custom',logLevel:'error',optimizeDeps:{noDiscovery:true,include:[]},server:{middlewareMode:true,ws:false}});
const copy=x=>structuredClone(x);
const fixtures=[];
try {
  const {SaveStore}=await server.ssrLoadModule('/src/core/SaveStore.ts');
  const {createInitialGameState}=await server.ssrLoadModule('/src/core/GameState.ts');
  const initial=createInitialGameState();
  assert.deepEqual(JSON.parse(fs.readFileSync(path.join(root,'godot_native/data/initial_state.json'),'utf8')),initial,'Native default state is stale');
  const storageAdapter=map=>({getItem:key=>map.has(key)?map.get(key):null,setItem:(key,value)=>map.set(key,value),removeItem:key=>map.delete(key)});
  function oracle(payload) {
    const memory=new Map([['seven_fifty_five_state',typeof payload==='string'?payload:JSON.stringify(payload)]]);
    const store=new SaveStore(storageAdapter(memory));
    const loaded=store.load(copy(initial));
    if(!loaded)return null;
    store.save(loaded);
    return JSON.parse(memory.get('seven_fifty_five_state')).state;
  }
  function add(id,payload,assertions={}) {fixtures.push({id,payload,expected:oracle(payload),assertions});}
  function stateCase(id,version,mutate,assertions={}) {const state=copy(initial);mutate(state);add(id,{version,state},assertions);}
  for(let version=2;version<=35;version++) {
    add('version_'+version+'_fresh',{version,state:copy(initial)});
    stateCase('version_'+version+'_explicit_completed',version,s=>{s.chapter4.completed=true;s.chapter4.phase='complete';},version<25?{legacy_completed:true}:{not_completed:true});
    stateCase('version_'+version+'_malformed_nesting',version,s=>{s.actOne=7;s.phoneBattery=[];s.chapter4={lightGrid:'x',zhuQuestionAnswers:[]};s.ui={libraryFinalsPuzzle:4};s.qizhenLake={journal:{mainPhoto:{recipe:[]},optionalPhotos:[7]}};});
  }
  const checkpoints=JSON.parse(gunzipSync(fs.readFileSync(path.join(root,'godot_native/data/native/developer_checkpoints.json.gz')))).checkpoints;
  for(const entry of checkpoints) add('checkpoint_'+entry.id+'_v35',{version:35,state:entry.state});
  if(process.argv.includes('--exhaustive')) for(const entry of checkpoints) for(let version=2;version<35;version++) add('checkpoint_'+entry.id+'_v'+version,{version,state:entry.state});
  else for(const entry of checkpoints.filter(x=>x.id.startsWith('c4'))) for(const version of [24,25,28,29,30,31,32,33,34]) add('checkpoint_'+entry.id+'_v'+version,{version,state:entry.state});
  for(const floor of ['A2','A3']) stateCase('false_transport_'+floor,35,s=>{s.chapter4={...s.chapter4,prologueSeen:true,phase:'room204_restore',floor,roomId:floor==='A2'?'a2_room204':'a3_wayfinding',factIds:[]};},{no_elevator:true,no_stair:true,floor:'A1'});
  const elevator=['classroom_104_chalk_residual_observed','classroom_105_terminal_replay_checked','elevator_history_observed','elevator_history_calibrated'];
  const opening=['opening_paper_at_noticeboard','opening_paper_caught','external_time_rejected','hall_clock_inspected','bakery_conveyor_lamp_inspected','bakery_conveyor_direction_observed','bakery_tool_location_observed','bakery_hour_hand_exposed','bakery_hour_hand_collected','hour_hand_installed'];
  for(const floor of ['A2','A3']) stateCase('true_elevator_'+floor+'_no_stair',35,s=>{s.chapter4={...s.chapter4,prologueSeen:true,phase:'room204_restore',floor,roomId:'a3_wayfinding',factIds:[...opening,...elevator,'a3_reference_observed']};},{elevator:true,no_stair:true,floor:'A3'});
  stateCase('true_stair_A2',35,s=>{s.chapter4={...s.chapter4,prologueSeen:true,phase:'room204_restore',floor:'A2',roomId:'a2_corridor',factIds:[...opening,...elevator,'a3_reference_observed','misaligned_stair_solved']};},{elevator:true,stair:true,floor:'A2'});
  stateCase('remote_phone_rain_interlude',35,s=>{s.phoneBattery={percent:4,lowPowerMode:true,rechargeCount:9};s.qizhenLake={...s.qizhenLake,active:true,phase:'rain_recovery',rainSafetyPromptSeen:true,weatherAdjustmentRequested:true,vehicle:'kayak',zone:'dock',safeSpawnId:'dock_kayak'};s.chapterThreeInterlude={...s.chapterThreeInterlude,phase:'evidence_collection',photoFrameIds:['paper_right','paper_left'],voiceClipOrder:['broadcast','lake'],networkRecordId:'record_0755',recoveryOpened:true};});
  stateCase('malformed_optional_primitive',35,s=>{s.canteenHunt.phase='pickup_search';s.items=[];});
  stateCase('unicode_room_trim',35,s=>{s.chapter4={...s.chapter4,prologueSeen:true,phase:'room204_restore',floor:'A2',roomId:'\u00a0a2_room204\ufeff',factIds:[...opening,...elevator,'a3_reference_observed','misaligned_stair_solved']};});
  stateCase('transient_ui',35,s=>{s.ui.controlCenterOpen=true;s.ui.inventoryOpen=true;s.ui.selectedItem='campusCard';s.items.campusCard=true;},{transient_clean:true});
  for(const value of [null,[],3,true,'oops','{"version":35,"state":', '{"version":35}', '{"version":36,"state":{}}','{"version":1,"state":{}}']) add('invalid_'+fixtures.length,value);
  for(const input of ['{"version":35,"state":{},}','{"version":035,"state":{}}','{"version":35.,"state":{}}','{"version":35,"state":{"a":[1,]}}','{"version":35,"state":{"a":"raw\nnewline"}}','{"version":35,"state":{"a":"\\q"}}'])add('strict_json_'+fixtures.length,input);
  add('legacy_unversioned',copy(initial));
  for(const version of ['35',' 35 ','\u00a035\u00a0','\ufeff35\u3000','0x23','0b100011','0o43',[35],[[35]]]) add('coerced_version_'+JSON.stringify(version),{version,state:copy(initial)});
  for(const value of [null,7,true,'bad',[],{},['wrong'],[{id:'bad'}]]) stateCase('invalid_arrays_'+JSON.stringify(value),35,s=>{s.chapter4.factIds=value;s.chapter4.room204Placements=value;s.qizhenLake.observedFishingSpotIds=value;s.ui.libraryFinalsPuzzle.clueIds=value;s.ui.homeAppOrder=value;});
  let seed=75535; const random=()=>{seed=(Math.imul(seed,1664525)+1013904223)>>>0;return seed/4294967296;};
  const choices=[null,true,false,0,-1,1.5,999999,'','false','unknown',[],{},[null],['bad',7]];
  function fuzz(value){if(random()<.11)return copy(choices[Math.floor(random()*choices.length)]);if(value&&typeof value==='object'){if(Array.isArray(value))return value.map(fuzz);return Object.fromEntries(Object.entries(value).filter(()=>random()>.03).map(([k,v])=>[k,fuzz(v)]));}return value;}
  for(let index=0;index<100;index++)add('deterministic_malformed_'+index,{version:2+index%34,state:fuzz(copy(initial))});
  let completed=oracle({version:24,state:{...initial,chapter4:{completed:true,phase:'complete'}}});
  const saveSource=fs.readFileSync(path.join(root,'src/core/SaveStore.ts'),'utf8');
  const gateBlock=saveSource.match(/const CHAPTER_FOUR_ROOM204_GATE_PROOF_FACTS = Object\.freeze\(\[([\s\S]*?)\]/)[1];
  const gateFacts=[...gateBlock.matchAll(/"([^"]+)"/g)].map(m=>m[1]);
  completed.chapter4.factIds=[...new Set([...completed.chapter4.factIds,...gateFacts,'zhu_two_questions_answered','exterior_closure_acknowledged'])];
  const purpose=saveSource.match(/VALID_CHAPTER_FOUR_ZHU_PURPOSE_ANSWERS[^\n]*\[\s*"([^"]+)"/)[1];
  const person=saveSource.match(/VALID_CHAPTER_FOUR_ZHU_PERSON_ANSWERS[^\n]*\[\s*"([^"]+)"/)[1];
  Object.assign(completed.chapter4,{phase:'complete',completed:true,exteriorClosureAcknowledged:true,zhuQuestionAnswers:{purpose,person}});
  if(!oracle({version:35,state:completed}).chapter4.completed)throw new Error('Actual source completion fixture is not complete');
  add('actual_v35_completed',{version:35,state:completed},{completed:true,stair:true,elevator:true});
  fs.writeFileSync(path.join(temporary,'fixtures.json'),JSON.stringify({initial,fixtures}));
  await server.close();
  const invocation=spawnSync(process.env.GODOT_BIN||'godot',['--headless','--path',path.join(root,'godot_native'),'--script','res://tests/test_save_migration.gd','--','--fresh',path.join(temporary,'fixtures.json')],{encoding:'utf8',maxBuffer:32*1024*1024,timeout:20*60*1000,env:{...process.env,XDG_DATA_HOME:path.join(temporary,'data'),XDG_CONFIG_HOME:path.join(temporary,'config'),HOME:path.join(temporary,'home')}});
  process.stdout.write(invocation.stdout||'');process.stderr.write(invocation.stderr||'');
  if(invocation.error)throw invocation.error;
  if(invocation.status!==0)throw new Error('Native differential tests failed ('+invocation.status+'); fixtures retained in '+temporary);
  console.log('Original SaveStore differential: '+fixtures.length+' cases PASS (temporary fixtures: '+temporary+')');
} finally {await server.close();}
