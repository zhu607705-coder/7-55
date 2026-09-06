import assert from 'node:assert/strict';
import { build } from 'esbuild';
import { readFile } from 'node:fs/promises';
const built = await build({ stdin: { contents: `export * from './src/modules/RhythmFishingEngine.ts';export * from './src/scenes/rpg/QizhenFishingRhythmModel.ts';`, resolveDir: process.cwd() }, bundle: true, format: 'esm', platform: 'node', write: false });
const api = await import(`data:text/javascript;base64,${Buffer.from(built.outputFiles[0].text).toString('base64')}`);
const data = JSON.parse(await readFile('src/data/chapter3-qizhen-fishing.charts.json', 'utf8'));
const ids = ['locker_key','net_frame','fish','paper'];
for (const id of ids) assert.deepEqual(data.charts[id].notes,data.charts.locker_key.notes,`${id} shares the authored rhythm`);
function create(chartId='fish',assist=false,chart) {
 let now=100;
 const events=[];
 const callbacks={onNoteJudged:(n,j,e,t)=>events.push({type:'note',judgment:j,error:e,tension:t}),onHoldBroken:()=>events.push({type:'hold'}),onWarning:()=>{},onCompleted:r=>events.push({type:'complete',result:r}),onFailed:r=>events.push({type:'fail',reason:r})};
 const model=chart?new api.RhythmFishingEngine({chartId,chart,now:()=>now,assist,timing:{...api.LAKE_FISHING_TIMING,beatSec:chart.beatSec},tension:api.LAKE_FISHING_TENSION,events:callbacks}):new api.QizhenFishingRhythmModel({chartId,now:()=>now,assist,events:callbacks});
 model.start();return {model,events,set(t){now=100+t;}};
}
function play(run,{hz=60,stopAfterCast=false,holdThroughRush=false,error=0,shortLift=false}={}){
 const m=run.model,held=new Set();
 const control=(action,on)=>{if(held.has(action)===on)return;on?held.add(action):held.delete(action);m[on?'handlePress':'handleRelease'](action);};
 run.set(0);control('right',true);let castHeldAt=null;
 for(let step=1;step<hz*90;step++){
  const t=step/hz;run.set(t);m.update();
  if(['completed','failed','cancelled'].includes(m.phase))break;
  const dx=m.fishX-m.lineX;
  control('left',dx<-.04);control('right',dx>.04);
  if(m.stage==='casting'){
   if(!m.isHolding&&Math.abs(dx)<.12){control('hook',true);castHeldAt=t;}
   if(m.isHolding&&t-castHeldAt>=.6){control('hook',false);if(stopAfterCast&&m.stage==='count_in')return t;}
  }else{
   const remaining=m.currentNote.timeSec-m.elapsedSec;
   if(remaining<=-error){control('hook',false);}
   else if(m.fishRushing&&!holdThroughRush){control('hook',false);}
   else control('hook',!shortLift||remaining<=.1);
  }
 }
 return run.events.find(e=>e.type==='complete')?.result;
}
for(const id of ids)for(const assist of [false,true]){
 const run=create(id,assist),result=play(run);
 assert(result?.passed&&result.perfect===8&&result.grade==='S',`${id} deliberate control passes: ${JSON.stringify(run.events)}`);
 assert(api.validateLakeFishingResult(result,id),`${id} input replay matches`);
 assert(!api.validateLakeFishingResult({...result,inputs:[]},id));
 assert(!api.validateLakeFishingResult({...result,protocol:'lake-pull-v1'},id));
 assert(!api.validateLakeFishingResult(result,id==='fish'?'paper':'fish'));
 assert(!api.validateLakeFishingResult({...result,perfect:7},id));
 assert(!api.validateLakeFishingResult({...result,inputs:result.inputs.filter(e=>e.action==='hook')},id),'directional history is part of reward validation');
 run.model.update();assert.equal(run.events.filter(e=>e.type==='complete').length,1);
 console.log(`${id} ${assist?'assist':'normal'}: aimed cast, directional tracking, eight lifts, exact replay`);
}
for(const hz of [30,120]){const r=create(),result=play(r,{hz});assert(result?.passed,JSON.stringify({hz,phase:r.model.phase,line:r.model.lineX,fish:r.model.fishX,events:r.events}));assert(api.validateLakeFishingResult(result,'fish'));}
const idle=create();idle.set(60);idle.model.update();assert.equal(idle.model.judgedCount,0);assert.equal(idle.model.phase,'idle');
const oneButton=create();oneButton.model.handlePress('hook');for(let i=0;i<8;i++){oneButton.set((i+1)*2.4);oneButton.model.handleRelease('hook');oneButton.set((i+1)*2.4+.1);oneButton.model.handlePress('hook');}assert.equal(oneButton.model.stage,'casting');assert.equal(oneButton.model.judgedCount,0);
const wrongCast=create();wrongCast.model.handlePress('hook');wrongCast.set(.6);wrongCast.model.handleRelease('hook');assert.equal(wrongCast.model.stage,'casting');assert.equal(wrongCast.model.castAttempts,1);
const cancelled=create();play(cancelled,{stopAfterCast:true});cancelled.model.cancel();cancelled.set(90);cancelled.model.update();assert.equal(cancelled.model.phase,'cancelled');assert(!cancelled.events.some(e=>e.type==='complete'));
const neutral=create();play(neutral,{stopAfterCast:true});neutral.model.handlePress('hook');neutral.model.releaseHeldInputs();assert.equal(neutral.model.isHolding,false);assert.equal(neutral.model.judgedCount,0);
const unattended=create();play(unattended,{stopAfterCast:true});unattended.model.handlePress('hook');unattended.set(60);unattended.model.update();assert.equal(unattended.model.phase,'failed');assert.equal(unattended.events.filter(e=>e.type==='fail').length,1);
const noRest=create();play(noRest,{holdThroughRush:true});assert.equal(noRest.model.phase,'failed','holding through every surge must snap the line');
const tooShort=create();play(tooShort,{shortLift:true});assert(!tooShort.events.find(e=>e.type==='complete')?.result.passed);
for(const [error,expected] of [[.08,'perfect'],[.15,'great'],[.25,'good']]){const r=create();play(r,{error});assert.equal(r.model.notes[0].judgment,expected);}
console.log('Unified tackle fishing PASS: same rules for all four story catches, no single-button shortcut, deterministic replay, retries, cancellation and tension management.');
