// Pure registration/planning/dispatch contracts; no runtime acceptance claim.
import test from 'node:test';
import assert from 'node:assert/strict';
import path from 'node:path';
import fs from 'node:fs';
import os from 'node:os';
import {registerStage,NATIVE_STAGE_REGISTRATIONS} from '../tools/native_validation_registration.mjs';
import {createValidationCatalog,planValidation,PREPARATION_IDS} from '../tools/native_validation_plan.mjs';
import {scheduleValidation} from '../tools/native_validation_scheduler.mjs';
import {createShardPlan,selectShard,stageDescriptor,estimateShard,NATIVE_SHARD_COUNT} from '../tools/native_validation_shards.mjs';
import {digest,stageIdentity} from '../tools/native_validation_identity.mjs';
const project=path.resolve(import.meta.dirname,'..'),root=path.dirname(project);
const legacy=createValidationCatalog(project,'/fake/godot',{registrations:[]});
const baseline=JSON.parse(fs.readFileSync(new URL('./fixtures/native_validation_baseline_33cc499.json',import.meta.url)));
const baselineIds=new Set(baseline.stageIds);
const historicalTimings=JSON.parse(fs.readFileSync(new URL('./fixtures/native_validation_timings_33cc499.json',import.meta.url))).durationMs;
function assertHistoricalSubset(stages,base){
 const subset=stages.filter(stage=>baselineIds.has(stage.id));
 assert.deepEqual(subset.map(stage=>stage.id),baseline.stageIds,'Every historical stage remains, in historical relative order');
 assert.equal(digest(subset.map(stage=>stageDescriptor(stage,base))),baseline.descriptorSha256);
 assert.equal(createShardPlan(subset,base,{count:6,durations:historicalTimings}).sha256,baseline.partitionSha256);
}

const spec=(id,extra={})=>({id,execution:'node',entry:`godot_native/tests/registered/${id}.mjs`,inputs:[`godot_native/tests/registered/${id}.mjs`],outputs:[],dependencies:[],...extra});
const catalog=registrations=>createValidationCatalog(project,'/fake/godot',{registrations});
const tick=async()=>{for(let i=0;i<30;i++)await Promise.resolve();};

test('historical descriptor/partition subset stays unchanged without freezing the live catalog count',()=>{
 const current=createValidationCatalog(project,'/fake/godot');
 assert.equal(current.length,legacy.length+NATIVE_STAGE_REGISTRATIONS.length);
 assert.deepEqual(current.slice(0,legacy.length),legacy);assertHistoricalSubset(legacy,root);
 assert.ok(legacy.every(stage=>!Object.hasOwn(stage,'registration')));
});
test('a new automatically discovered GD stage joins all scheduling without editing the historical golden',()=>{
 const temporary=fs.mkdtempSync(path.join(os.tmpdir(),'755-registration-discovery-'));
 try{
  const temporaryProject=path.join(temporary,'godot_native'),tests=path.join(temporaryProject,'tests');fs.mkdirSync(tests,{recursive:true});
  for(const file of fs.readdirSync(path.join(project,'tests')).filter(file=>file.endsWith('.gd')))fs.writeFileSync(path.join(tests,file),'');
  const id='test_registration_future_discovery.gd';assert.ok(!legacy.some(stage=>stage.id===id));fs.writeFileSync(path.join(tests,id),'');
  const discovered=createValidationCatalog(temporaryProject,'/fake/godot',{registrations:[]});
  assert.equal(discovered.length,legacy.length+1);assertHistoricalSubset(discovered,temporary);
  const full=planValidation(discovered),partition=createShardPlan(full.stages,temporary);
  assert.equal(full.stages.length,discovered.length);assert.equal(partition.shards.flatMap(shard=>shard.ids).filter(value=>value===id).length,1);
  assert.equal(partition.count,NATIVE_SHARD_COUNT);assert.equal(partition.jobs,2);
 }finally{fs.rmSync(temporary,{recursive:true,force:true});}
});
test('registered readers append with one pool slot, explicit I/O and normal worker semantics',()=>{
 const stages=catalog([spec('new_reader',{outputs:[{scope:'sandbox',path:'summary.json'}],durationHintMs:1200})]);
 assert.deepEqual(stages.slice(0,legacy.length),legacy);const stage=stages.at(-1);
 assert.equal(stage.exclusive,false);assert.deepEqual(stage.registration.resources,{slots:1});
 assert.equal(stage.command,process.execPath);assert.deepEqual(stage.args,[path.join(root,stage.registration.entry)]);
 assert.ok(Object.isFrozen(stage.registration));assert.equal(planValidation(stages).stages.length,legacy.length+1);
});
test('execution types resolve fixed commands; Godot application arguments cannot replace --path',()=>{
 for(const [execution,extension,command] of [['godot','gd','/fake/godot'],['python','py','python3'],['bash','sh','bash']]){
  const entry=`godot_native/tests/registered/example.${extension}`;
  const stage=catalog([spec('example',{execution,entry,inputs:[entry],args:['--path','user-argument']})]).at(-1);
  assert.equal(stage.command,command);
  if(execution==='godot')assert.deepEqual(stage.args,['--headless','--path',project,'--script','res://tests/registered/example.gd','--','--path','user-argument']);
 }
});
test('exact requests close explicit reader and preparation prerequisites, with stable appended topology',()=>{
 const stages=catalog([spec('last',{dependencies:['first']}),spec('first',{dependencies:['test_minigame_models.gd']})]);
 assert.deepEqual(stages.slice(legacy.length).map(stage=>stage.id),['first','last']);
 const selected=planValidation(stages,{profile:'changed',tests:['last']}).stages.map(stage=>stage.id);
 for(const id of ['first','last','test_minigame_models.gd',...PREPARATION_IDS.slice(0,5)])assert.ok(selected.includes(id));
 assert.ok(selected.indexOf('first')<selected.indexOf('last'));
});
test('explicit reader dependency components share a shard without changing legacy descriptors',()=>{
 const stages=catalog([spec('child',{dependencies:['parent']}),spec('parent',{dependencies:['test_world.gd']})]);
 const plan=createShardPlan(stages,root),owner=id=>plan.shards.find(shard=>shard.ids.includes(id)).index;
 assert.equal(owner('child'),owner('parent'));assert.equal(owner('parent'),owner('test_world.gd'));
 assert.equal(new Set(plan.shards.flatMap(shard=>shard.ids)).size,stages.length-PREPARATION_IDS.length);
 assert.deepEqual(stages.slice(0,legacy.length).map(stage=>stageDescriptor(stage,root)),legacy.map(stage=>stageDescriptor(stage,root)));
});
test('registration survives actual full/shard plan rows into runner-shaped evidence and identities',()=>{
 const stages=catalog([spec('reader')]),stage=stages.at(-1),partition=createShardPlan(stages,root),owner=partition.shards.find(shard=>shard.ids.includes(stage.id)).index;
 const plans=[planValidation(stages),selectShard(stages,root,owner).plan];
 for(const plan of plans){
  const planned=plan.rows.find(row=>row.id===stage.id),reported={...planned,label:planned.id,result:'pass',command:stage.command,args:stage.args};
  assert.deepEqual(stageDescriptor(reported,root),stageDescriptor(stage,root));
  assert.equal(stageIdentity({sha256:'input'},reported,'fixtures'),stageIdentity({sha256:'input'},stage,'fixtures'));
  assert.notEqual(stageIdentity({sha256:'input'},{...reported,registration:{...reported.registration,inputs:[...reported.registration.inputs,'src/new.ts']}},'fixtures'),stageIdentity({sha256:'input'},stage,'fixtures'));
 }
 assert.ok(planValidation(stages).rows.filter(row=>row.id!==stage.id).every(row=>!Object.hasOwn(row,'registration')));
});
test('duration hints affect only unknown estimates, never coverage or observed timings',()=>{
 const stage=catalog([spec('hint',{durationHintMs:3000})]).at(-1);
 assert.equal(estimateShard([stage],{}),3000);assert.equal(estimateShard([stage],{hint:7000}),7000);
 const stages=catalog([spec('hint',{durationHintMs:3})]);assert.equal(createShardPlan(stages,root).shards.flatMap(shard=>shard.ids).length,stages.length-9);
});
test('unknown and new runtime/helper changes select full coverage with six managed shards',()=>{
 const stages=catalog([spec('reader')]);
 for(const changed of ['src/new-runtime.ts','godot_native/tests/registered/unclassified.gd','unknown/new-file']){
  const selected=planValidation(stages,{profile:'changed',changedFiles:[changed]});assert.equal(selected.effectiveProfile,'full');assert.equal(selected.stages.length,stages.length);
  const sharded=createShardPlan(selected.stages,root);assert.equal(sharded.count,NATIVE_SHARD_COUNT);assert.equal(sharded.jobs,2);assert.ok(sharded.shards.every(shard=>shard.ids.length>0));
 }
});
test('continuous readiness dispatch fills free slots without launching an unfinished dependent',async()=>{
 const stages=catalog([spec('a'),spec('b',{dependencies:['a']}),spec('c')]).slice(legacy.length),starts=[],pending=new Map();
 const done=scheduleValidation(stages,{jobs:2,run:stage=>{starts.push(stage.id);return new Promise(resolve=>pending.set(stage.id,resolve));}});
 await tick();assert.deepEqual(starts,['a','c']);pending.get('c')(true);await tick();assert.deepEqual(starts,['a','c']);
 pending.get('a')(true);await tick();assert.deepEqual(starts,['a','c','b']);pending.get('b')(true);await done;
});
test('failed prerequisites reach the existing report guard before any dependent process launches',async()=>{
 const stages=catalog([spec('bad'),spec('dependent',{dependencies:['bad']}),spec('independent')]).slice(legacy.length),states=new Map(),executed=[];
 await scheduleValidation(stages,{jobs:2,run:async stage=>{
  if(stage.dependencies.some(id=>states.get(id)!=='pass')){states.set(stage.id,'blocked');return false;}
  executed.push(stage.id);await tick();const ok=stage.id!=='bad';states.set(stage.id,ok?'pass':'failed');return ok;
 }});
 assert.equal(states.get('dependent'),'blocked');assert.ok(!executed.includes('dependent'));assert.ok(executed.includes('independent'));
});
test('forward declaration across a new exclusive prerequisite is topologically ordered and drained',async()=>{
 const stages=catalog([spec('dependent',{dependencies:['barrier']}),spec('barrier',{exclusive:true,dependencies:['before']}),spec('before')]).slice(legacy.length);
 assert.deepEqual(stages.map(stage=>stage.id),['before','barrier','dependent']);let active=0;const events=[];
 await scheduleValidation(stages,{jobs:2,run:async stage=>{active++;if(stage.exclusive)assert.equal(active,1);events.push(stage.id);await tick();active--;return true;}});
 assert.deepEqual(events,['before','barrier','dependent']);
});
test('registered workers obey caps 1..4; unsupported resource weights fail closed',async()=>{
 const stages=catalog(Array.from({length:8},(_,i)=>spec(`reader${i}`))).slice(legacy.length);
 for(const jobs of [1,2,3,4]){let active=0,peak=0;await scheduleValidation(stages,{jobs,run:async()=>{peak=Math.max(peak,++active);await tick();active--;return true;}});assert.equal(peak,jobs);}
 for(const slots of [0,2,3,4,NaN])assert.throws(()=>registerStage(spec('weighted',{resources:{slots}})),/Only resources.slots=1/);
});
test('shared writers, unsafe paths, unknown fields, missing deps and cycles are rejected explicitly',()=>{
 for(const outputs of [[{scope:'shared',path:'godot_native/tests/fixtures/new.json'}],[{scope:'sandbox',path:'../escape'}]])assert.throws(()=>registerStage(spec('writer',{outputs})),/Shared outputs\/writers/);
 for(const mutate of [s=>s.entry='../escape.mjs',s=>s.inputs=[],s=>s.inputs.push('../escape'),s=>s.unreviewed=true,s=>s.execution='shell',s=>s.exclusive='yes',s=>s.durationHintMs=0]){const value=spec('invalid');mutate(value);assert.throws(()=>registerStage(value));}
 assert.throws(()=>catalog([spec('test_world.gd')]),/Duplicate/);
 assert.throws(()=>catalog([spec('missing',{dependencies:['unknown']})]),/Unknown dependency/);
 assert.throws(()=>catalog([spec('alias_consumer',{dependencies:['test_buct_rongmao.gd']})]),/test_buct_haidian.gd canonical owner/);
 assert.throws(()=>catalog([spec('a',{dependencies:['b']}),spec('b',{dependencies:['a']})]),/cycle/);
 assert.deepEqual(PREPARATION_IDS,legacy.slice(0,9).map(stage=>stage.id));
});
test('focused registration contract is wired into the existing native contracts job',()=>{
 const workflow=fs.readFileSync(path.join(root,'.github/workflows/godot-native-ci.yml'),'utf8');
 assert.match(workflow,/node --test[^\n]*test_native_validation_registration\.mjs/);
});


test('registered inputs precede prose and exact-test shortcuts; dependency consumers cannot be omitted',()=>{
 const doc=spec('policy_reader');doc.inputs.push('docs/policy.md');
 const direct=spec('test_reader');direct.inputs.push('godot_native/tests/test_world.gd');
 const directory=spec('directory_reader');directory.inputs.push('docs/policies');
 const cases=[
  [[doc],'docs/policy.md'],
  [[direct],'godot_native/tests/test_world.gd'],
  [[directory],'docs/policies/new-policy.md'],
  [[spec('north_consumer',{dependencies:['test_north_independent_props.gd']})],'godot_native/scripts/objects/north_prop_scene.gd'],
  [[spec('last',{dependencies:['first']}),spec('first',{dependencies:['test_world.gd']})],'godot_native/tests/test_world.gd'],
 ];
 for(const [registrations,file] of cases){
  const stages=catalog(registrations),selected=planValidation(stages,{profile:'changed',changedFiles:[file]});
  assert.equal(selected.effectiveProfile,'full');assert.equal(selected.stages.length,stages.length);
  assert.ok(selected.reasons.some(reason=>reason.includes('registered input or dependent reader')));
  assert.equal(createShardPlan(selected.stages,root).count,NATIVE_SHARD_COUNT);
 }
 const unrelated=planValidation(catalog([doc]),{profile:'changed',changedFiles:['docs/unrelated.md']});
 assert.equal(unrelated.stages.length,5);assert.equal(unrelated.effectiveProfile,'changed');
});
