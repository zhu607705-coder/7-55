#!/usr/bin/env node
// Pure contract tests. These execute the actual runner's dispatch, not a browser.
import assert from 'node:assert/strict';
import {readFileSync} from 'node:fs';
import {test} from 'node:test';
import {phoneRecoveryCase} from '../tools/web_phone_recovery.mjs';
import {PHONE_GROUPS, PHONE_COVERAGE, phoneGroups, phoneCoverage, phoneInputs, runPhoneRecoveryGroups, assertPhoneCoverage, assertPhoneShardUnion} from '../tools/web_phone_shards.mjs';

await test('default all retains the original ordered three flows and all nine labels', async () => {
  const seen = [], callbacks = Object.fromEntries(PHONE_GROUPS.map(group => [group, async () => { seen.push(group); }]));
  await runPhoneRecoveryGroups(undefined, callbacks);
  assert.deepEqual(seen, ['charging','c1-tiyi','c2-tiyi']);
  assert.equal(phoneCoverage().length,9); assert.equal(new Set(phoneCoverage()).size,9);
  const source = readFileSync(new URL('../tools/web_phone_recovery.mjs', import.meta.url), 'utf8');
  const emitted = [...source.matchAll(/evidence\.coverage\.push\(([^;]+)\);/g)].flatMap(match => [...match[1].matchAll(/'([^']+)'/g)].map(row=>row[1]));
  assert.deepEqual(emitted, phoneCoverage());
  assert.match(source,/const group = h\.group === undefined \? 'all' : h\.group/);
  assert.match(source,/await runPhoneRecoveryGroups\(group, \{/);
  // The C2 import remains followed by every actual step in the same callback.
  const c2 = source.slice(source.indexOf("'c2-tiyi': async () => {"));
  let last = 0;
  for (const operation of ["before_c2_tiyi_update.json", "TiyiContact", "TiyiAcquireUpdate", "TiyiInstallUpdate", "saveProgressAndWait('installed Tiyi before reload')", 'startStory(true)', 'point <= 10', 'WeatherWaterCard', "evidence.coverage.push('C2 repeated"]) {
    const at = c2.indexOf(operation); assert.ok(at > last, `${operation} must remain in original order`); last = at;
  }
  assert.match(source,/h\.interval\(2400\)/);
  assert.match(source,/Date\.now\(\) - began >= 2200/);
  assert.match(source,/real desktop charge completes', 12000/);
});

for (const group of PHONE_GROUPS) await test(`actual runner enters only the ${group} import boundary`, async () => {
  const expected = {charging:'compat-c1-battery-0-v35.json','c1-tiyi':'before_c1_tiyi_digit.json','c2-tiyi':'before_c2_tiyi_update.json'}[group];
  let recorded, imported; const stop = new Error('synthetic stop at actual ordinary-file input');
  await assert.rejects(phoneRecoveryCase({group, fixtureDir:'/synthetic', record(value){recorded=value;}, async importSave(file){imported=file;throw stop;}}),error=>error===stop);
  assert.equal(imported,`/synthetic/${expected}`);
  assert.equal(recorded.group,group);assert.equal(recorded.completed,false);assert.deepEqual(recorded.coverage,[]);
  const seen=[];await runPhoneRecoveryGroups(group,Object.fromEntries(PHONE_GROUPS.map(name=>[name,async()=>seen.push(name)])));
  assert.deepEqual(seen,[group]);assert.deepEqual(phoneCoverage(group),PHONE_COVERAGE[group]);
});

await test('unknown groups and incomplete callback maps fail before input', async () => {
  for (const group of ['',null,'none','charging,c1-tiyi','ALL','__proto__']) {
    assert.throws(()=>phoneGroups(group));
    let called=false;await assert.rejects(phoneRecoveryCase({group,record(){called=true;}}));assert.equal(called,false);
  }
  const callbacks=Object.fromEntries(PHONE_GROUPS.map(group=>[group,async()=>{}]));
  for (const bad of [{}, {...callbacks, extra:async()=>{}}, {...callbacks, charging:null}]) await assert.rejects(runPhoneRecoveryGroups('all',bad));
  const seen=[];
  await assert.rejects(runPhoneRecoveryGroups('all',{charging:async()=>{seen.push('charging');throw Error('failed');},'c1-tiyi':async()=>seen.push('c1'),'c2-tiyi':async()=>seen.push('c2')}));
  assert.deepEqual(seen,['charging']);
});

const row=group=>({group,completed:true,coverage:phoneCoverage(group),inputs:[{method:'ordinaryTouchTap'}]});
await test('coverage requires every exact label once, completion and actual input evidence', () => {
  for (const group of ['all',...PHONE_GROUPS]) {
    assertPhoneCoverage(row(group),group);
    for (const mutate of [r=>r.coverage.pop(),r=>r.coverage.push(r.coverage[0]),r=>r.coverage[0]+=' unchecked',r=>r.completed=false,r=>r.completed='true',r=>r.inputs=[],r=>r.group='other']) {
      const bad=row(group);mutate(bad);assert.throws(()=>assertPhoneCoverage(bad,group));
    }
  }
});
await test('aggregate rejects missing, duplicate, extra, mixed or partial phone groups', () => {
  const valid=()=>PHONE_GROUPS.map(row);assertPhoneShardUnion(valid());assertPhoneShardUnion(valid().reverse());
  for (const bad of [valid().slice(1),[...valid(),row('charging')],[row('charging'),row('charging'),row('c2-tiyi')],[row('all'),row('c1-tiyi'),row('c2-tiyi')]]) assert.throws(()=>assertPhoneShardUnion(bad));
  const bad=valid();bad[2].coverage.pop();assert.throws(()=>assertPhoneShardUnion(bad));
});
await test('each selected group requires its complete distinct exact-source input identities', () => {
  const input=filename=>({filename,sha256:'a'.repeat(64)});
  const fixtures={variants:[input('zero'),input('one')],earned:{firstTiyi:input('first'),secondTiyi:input('second')}};
  assert.deepEqual(phoneInputs(fixtures).map(x=>x.filename),['zero','one','first','second']);
  assert.deepEqual(phoneInputs(fixtures,'charging').map(x=>x.filename),['zero','one']);
  assert.deepEqual(phoneInputs(fixtures,'c1-tiyi').map(x=>x.filename),['first']);
  assert.deepEqual(phoneInputs(fixtures,'c2-tiyi').map(x=>x.filename),['second']);
  for (const mutate of [x=>x.variants.pop(),x=>x.variants.push(input('extra')),x=>x.variants[1]=x.variants[0],x=>delete x.earned.secondTiyi,x=>x.earned.firstTiyi.sha256='bad']) {const bad=structuredClone(fixtures);mutate(bad);assert.throws(()=>phoneInputs(bad));}
});

const readyC2 = () => ({sampleFrame:20, documentHidden:false,
  state:{native:{chapter:2}}, viewport:{width:390,height:844},
  content:{enabled:true,blocking:false,manifestError:'',requiredIds:[],readyFamilies:['chapter2'],packs:[{id:'chapter2_001',family:'chapter2',status:'ready',error:''}]},
  world:{visible:true,scene_id:'dorm_hub',backgroundPlate:{ready:true},input:{modalVisible:false,geometryAvailable:true}},
  visibleControls:[{name:'WorldPhoneButton',disabled:false,rect:{x:334,y:788,width:44,height:44}}]});
const syntheticPoll = async (fn, label, timeout) => {
  assert.equal(timeout,180000,'content uses the existing bounded boot timeout, not the ordinary 20s input timeout');
  for(let i=0;i<3;i++){const value=await fn();if(value)return value;}
  throw Error(`synthetic timeout: ${label}`);
};
await test('cold C2 sends no phone input until required packs and a fresh real world are ready',async()=>{
  const pending=readyC2();pending.sampleFrame=10;pending.content.blocking=true;pending.content.readyFamilies=[];pending.content.packs[0].status='requested';pending.world.scene_id='';pending.world.backgroundPlate.ready=false;
  let reads=0, inputs=0, recorded;
  const stop=Error('stop after the single real phone tap');
  await assert.rejects(phoneRecoveryCase({group:'c2-tiyi',touch:true,bootTimeout:180000,fixtureDir:'/synthetic',record(value){recorded=value;},
    async importSave(){},async snapshot(){reads++;assert.equal(inputs,0);return reads<3?pending:readyC2();},
    poll:syntheticPoll,async clickControl(name){assert.equal(name,'WorldPhoneButton');assert.equal(reads,3);inputs++;throw stop;}}),error=>error===stop);
  assert.equal(inputs,1);assert.equal(recorded.completed,false);assert.deepEqual(recorded.coverage,[]);
  assert.equal(recorded.contentWait.sampleFrame,20);assert.equal(recorded.contentWait.timeoutMs,180000);
  assert.deepEqual(recorded.contentWait.requiredIds,[],'successful engine clears transient waiters');
  assert.deepEqual(recorded.contentWait.chapter2Ids,['chapter2_001']);
});
for(const [label,change] of [
  ['blocking overlay',s=>s.content.blocking=true],['incomplete required pack',s=>s.content.packs[0].status='requested'],
  ['missing family pack',s=>s.content.packs=[]],['unready active required pack',s=>s.content.requiredIds=['unknown']],['missing required-ID observation',s=>delete s.content.requiredIds],
  ['family not mounted',s=>s.content.readyFamilies=[]],['wrong chapter',s=>s.state.native.chapter=1],
  ['world not restored',s=>s.world.scene_id=''],['background absent',s=>s.world.backgroundPlate.ready=false],
  ['modal input owner',s=>s.world.input.modalVisible=true],['touch geometry absent',s=>s.world.input.geometryAvailable=false],
  ['stale frame',s=>s.sampleFrame=10],['hidden document',s=>s.documentHidden=true],
  ['disabled button',s=>s.visibleControls[0].disabled=true],['duplicate button',s=>s.visibleControls.push(structuredClone(s.visibleControls[0]))],
  ['out of bounds button',s=>s.visibleControls[0].rect.x=390]
]) await test(`cold C2 ${label} times out without dispatch or partial success`,async()=>{
  const pending=readyC2();change(pending);let inputs=0,recorded,reads=0;
  await assert.rejects(phoneRecoveryCase({group:'c2-tiyi',touch:true,bootTimeout:180000,fixtureDir:'/synthetic',record(value){recorded=value;},async importSave(){},
    async snapshot(){reads++;return reads===1?{...readyC2(),sampleFrame:10}:pending;},poll:syntheticPoll,async clickControl(){inputs++;}}),/synthetic timeout/);
  assert.equal(inputs,0);assert.equal(recorded.completed,false);assert.deepEqual(recorded.coverage,[]);
});
for(const kind of ['manifest','pack']) await test(`cold C2 ${kind} errors fail before any tap, with no retry`,async()=>{
  const broken=readyC2();if(kind==='manifest')broken.content.manifestError='hash mismatch';else broken.content.packs[0].error='hash mismatch';
  let polls=0,inputs=0;
  await assert.rejects(phoneRecoveryCase({group:'c2-tiyi',touch:true,bootTimeout:180000,fixtureDir:'/synthetic',record(){},async importSave(){},async snapshot(){return broken;},
    async poll(fn){polls++;return fn();},async clickControl(){inputs++;}}),/C2 phone content failed:.*hash mismatch/);
  assert.equal(polls,1);assert.equal(inputs,0);
});
await test('phone readiness does not globally block save imports or the streaming fault scenario',()=>{
  const source=readFileSync(new URL('../tools/verify_web_export.mjs',import.meta.url),'utf8');
  assert.match(source,/phoneRecoveryCase\(\{ id, touch, fixtureDir, bootTimeout, group:/);
  const importer=source.slice(source.indexOf('async function importSave('),source.indexOf('async function importSave(')+4500);
  assert.doesNotMatch(importer,/waitForC2PhoneWorld/);
});
