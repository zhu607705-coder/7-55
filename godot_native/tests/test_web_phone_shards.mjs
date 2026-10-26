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
