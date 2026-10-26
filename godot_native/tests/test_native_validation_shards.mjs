import test from 'node:test';
import assert from 'node:assert/strict';
import path from 'node:path';
import fs from 'node:fs';
import {spawnSync} from 'node:child_process';
import {createValidationCatalog,PREPARATION_IDS,planValidation} from '../tools/native_validation_plan.mjs';
import {createShardPlan,selectShard,NATIVE_SHARD_COUNT} from '../tools/native_validation_shards.mjs';
import {aggregateNative} from '../tools/native_validation_aggregate.mjs';
import {digest,stageIdentity} from '../tools/native_validation_identity.mjs';
const root=path.resolve(import.meta.dirname,'../..'),catalog=createValidationCatalog(path.join(root,'godot_native'));
const summary=rows=>Object.fromEntries(['not-run','pass','prepared','failed','blocked','deduplicated'].map(s=>[s,rows.filter(r=>r.result===s).length]));
function fixture(){
 const plan=createShardPlan(catalog,root),receiptSha='a'.repeat(64),input='b'.repeat(64),fixtureSha='c'.repeat(64),commit='d'.repeat(40),tree='e'.repeat(40);
 const body={schema:2,input:{sha256:input,count:12},tools:[],jobs:2};const identity={...body,sha256:digest(body)};
 const pass=(stage,selected=true)=>({...stage,label:stage.id,selected,result:'pass',failed:false,status:0,error:null,signal:null,reused:false,
  output:'checks passed',startedAt:'2026-10-25T00:00:00.000Z',finishedAt:'2026-10-25T00:00:00.001Z',durationMs:1,identity:stageIdentity(identity,stage,fixtureSha)});
 const unrun=stage=>({id:stage.id,label:stage.id,selected:false,dependencies:stage.dependencies,exclusive:stage.exclusive,result:'not-run',failed:null,status:null});
 const preparationRows=catalog.map(s=>PREPARATION_IDS.includes(s.id)?pass(s):unrun(s));
 const common={schema:2,project:path.join(root,'godot_native'),gitHead:commit,gitTree:tree,identity,completed:true,inputChangedDuringRun:false,resumable:true,partial:true,fullSuitePassed:false,jobs:2,total:catalog.length,startedAt:'2026-10-25T00:00:00.000Z',finishedAt:'2026-10-25T00:00:01.000Z'};
 const preparationMeta={...common,profile:'prepare',effectiveProfile:'prepare',selected:9,summary:summary(preparationRows)};
 const receipt={schema:'755-native-prepared-bundle-v2',source:{checkedOutCommit:commit,tree,run:'123'},producerAttempt:'1',preparation:{identitySha256:identity.sha256,inputSha256:input,fixtureSha256:fixtureSha}};
 const fragments=plan.shards.map(shard=>{
  const rows=catalog.map(s=>shard.ids.includes(s.id)?pass(s):PREPARATION_IDS.includes(s.id)?s.id==='Native save isolation'?pass(s,false):{...unrun(s),result:'prepared',failed:false,status:0,preparedReceiptSha:receiptSha}:unrun(s));
  return {rows,meta:{...common,profile:'shard',effectiveProfile:'shard',preparedFixtureSha256:fixtureSha,selected:shard.ids.length,summary:summary(rows),shard:{index:shard.index,count:plan.count,planSha256:plan.sha256,ownedIds:shard.ids,run:'123',attempt:'1',producerAttempt:'1',receiptSha,preparationInputSha256:input}}};
 });
 return {root,catalog,preparationRows,preparationMeta,receipt,receiptSha,fragments,expected:{commit,tree,run:'123',attempt:'1',producerAttempt:'1'},statuses:{prepare:'success',contracts:'success',shards:'success',graphics:'success'}};
}
test('bounded deterministic timing-balanced shards own every non-preparation entry exactly once',()=>{
 const a=createShardPlan(catalog,root),b=createShardPlan(catalog,root);assert.deepEqual(a,b);
 assert.deepEqual([...a.preparationIds,...a.shards.flatMap(s=>s.ids)].sort(),catalog.map(s=>s.id).sort());
 const historicalIds=new Set(JSON.parse(fs.readFileSync(new URL('./fixtures/native_validation_baseline_33cc499.json',import.meta.url))).stageIds);
 const historical=createShardPlan(catalog.filter(stage=>historicalIds.has(stage.id)),root);
 assert.ok(Math.max(...historical.shards.map(s=>s.predictedMs))-Math.min(...historical.shards.map(s=>s.predictedMs))<1000,'Historical timing balance only; new dependency groups may have an unavoidable long tail');
 assert.equal(a.shards.find(s=>s.ids.includes('test_buct_haidian.gd')).index,a.shards.find(s=>s.ids.includes('test_buct_rongmao.gd')).index);
 const added={id:'test_new_unknown.gd',command:'godot',args:['--headless'],exclusive:false,dependencies:[]};
 assert.ok(createShardPlan([...catalog,added],root).shards.some(s=>s.ids.includes(added.id)));
 assert.throws(()=>createShardPlan([...catalog,{...added,dependencies:['test_world.gd']}],root),/cross-shard/);
 for(const count of [0,NATIVE_SHARD_COUNT+1,1.5])assert.throws(()=>createShardPlan(catalog,root,{count}),/1\.\./);
 assert.throws(()=>selectShard(catalog,root,NATIVE_SHARD_COUNT),/index/);
});
test('prepare and shard plans are explicit partial evidence; no implicit prerequisite skipping',()=>{
 assert.deepEqual(planValidation(catalog,{profile:'prepare'}).stages.map(s=>s.id),PREPARATION_IDS);
 const p=selectShard(catalog,root,0);assert.equal(p.plan.partial,true);assert.ok(p.plan.rows.every(r=>r.status==='not-run'));
 const run=args=>spawnSync(process.execPath,[path.join(root,'godot_native/tools/validate_native.mjs'),...args],{encoding:'utf8'});
 assert.equal(run(['--shard',`0/${NATIVE_SHARD_COUNT}`,'--plan']).status,0);
 for(const args of [['--shard',`0/${NATIVE_SHARD_COUNT}`],['--shard',`0/${NATIVE_SHARD_COUNT}`,'--resume'],['--profile','prepare','--resume'],['--receipt-sha','bad']])assert.notEqual(run(args).status,0);
});
test('only complete successful exact-source fragments yield full acceptance',()=>{
 const f=fixture(),r=aggregateNative(f);assert.equal(r.meta.fullSuitePassed,true);assert.equal(r.rows.length,catalog.length);assert.equal(r.meta.summary.pass,catalog.length);
});
test('audited identical-script evidence alias is accepted only beside its passing owner',()=>{
 const f=fixture(),part=f.fragments.find(f=>f.rows.find(r=>r.id==='test_buct_rongmao.gd').selected),r=part.rows.find(r=>r.id==='test_buct_rongmao.gd');
 Object.assign(r,{result:'deduplicated',failed:null,equivalentTo:'test_buct_haidian.gd'});part.meta.summary=summary(part.rows);
 assert.equal(aggregateNative(f).meta.summary.deduplicated,1);
 r.equivalentTo='test_world.gd';assert.throws(()=>aggregateNative(f),/deduplication/);
});
test('same producer receipt permits prior successful consumers when only failed jobs are rerun',()=>{
 const f=fixture();f.expected.attempt='2';const replacement=structuredClone(f.fragments[0]);replacement.meta.shard.attempt='2';f.fragments.push(replacement);
 const out=aggregateNative(f);assert.equal(out.meta.fragments[0].attempt,'2');assert.equal(out.meta.fragments[1].attempt,'1');
 replacement.meta.completed=false;assert.throws(()=>aggregateNative(f),/Incomplete\/failed/,'never fall back to old pass after newer failure');
});
const mutations={
 'legacy transport receipt':f=>f.receipt.schema='755-native-prepared-bundle-v1',
 'missing shard':f=>f.fragments.pop(),
 'duplicate same attempt':f=>f.fragments.push(structuredClone(f.fragments[0])),
 'future attempt':f=>f.fragments[0].meta.shard.attempt='2',
 'foreign run':f=>f.fragments[0].meta.shard.run='124',
 'wrong producer':f=>f.fragments[0].meta.shard.producerAttempt='2',
 'wrong receipt':f=>f.fragments[0].meta.shard.receiptSha='f'.repeat(64),
 'wrong tree':f=>f.fragments[0].meta.gitTree='f'.repeat(40),
 'different partition':f=>f.fragments[0].meta.shard.planSha256='f'.repeat(64),
 'input drift':f=>f.fragments[0].meta.inputChangedDuringRun=true,
 'uncertain environment':f=>f.fragments[0].meta.resumable=false,
 'partial claims full':f=>f.fragments[0].meta.fullSuitePassed=true,
 'changed fixtures':f=>f.fragments[0].meta.preparedFixtureSha256='f'.repeat(64),
 'failed producer':f=>f.preparationRows[0].failed=true,
 'missing stage':f=>f.fragments[0].rows.pop(),
 'unselected owned stage':f=>f.fragments[0].rows.find(r=>r.selected).selected=false,
 'not run owned stage':f=>f.fragments[0].rows.find(r=>r.selected).result='not-run',
 'forged pass with script error':f=>f.fragments[0].rows.find(r=>r.selected).output='SCRIPT ERROR: failed',
 'reused old success':f=>f.fragments[0].rows.find(r=>r.selected).reused=true,
 'changed args':f=>f.fragments[0].rows.find(r=>r.selected).args.push('--unexpected'),
 'failed isolation on consumer':f=>f.fragments[0].rows.find(r=>r.id==='Native save isolation').result='prepared',
 'forged stage identity':f=>f.fragments[0].rows.find(r=>r.selected).identity='f'.repeat(64),
 'cancelled runtime':f=>f.statuses.shards='cancelled',
 'skipped graphics':f=>f.statuses.graphics='skipped',
 'failed contracts':f=>f.statuses.contracts='failure'
};
for(const [name,mutate]of Object.entries(mutations))test(`aggregate rejects ${name}`,()=>{const f=fixture();mutate(f);assert.throws(()=>aggregateNative(f));});
test('large full-plan JSON flushes through a real pipe without running the engine',()=>{
 const script=path.join(root,'godot_native/tools/validate_native.mjs');
 const consumer='let value="";process.stdin.on("data",c=>value+=c);process.stdin.on("end",()=>{const plan=JSON.parse(value);if(plan.stages.length!==Number(process.argv[1])||plan.rows.length!==plan.stages.length||plan.stages.some(s=>s.status!=="not-run"))process.exit(2);console.log(plan.stages.length);});';
 const command='set -euo pipefail; "$1" "$2" --plan | "$1" -e "$3" "$4"';
 const result=spawnSync('bash',['-c',command,'755-plan-pipe',process.execPath,script,consumer,String(catalog.length)],{encoding:'utf8',env:{...process.env,GODOT_BIN:'/must-not-run-inspection-engine'}});
 assert.equal(result.status,0,result.stderr);assert.equal(result.stdout.trim(),String(catalog.length));
});
