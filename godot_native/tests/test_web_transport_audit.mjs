import assert from 'node:assert/strict';
import {test} from 'node:test';
import {createHash} from 'node:crypto';
import {setTimeout as delay} from 'node:timers/promises';
import {startTransportAudit} from '../tools/web_transport_audit.mjs';
const hash = s => createHash('sha256').update(s).digest('hex');
const resource = n => ({url:`http://fixture/${n}`, bytes:3, sha256:hash('abc')});
function fixture(overrides={}) {
  const assets=[], checks=[];
  const options={resources:[resource(1),resource(2),resource(3)],locate:url=>({relativePath:url.split('/').at(-1),local:url}),
    check(ok,label){checks.push({ok,label});assert.ok(ok,label);},shaFile:async()=>hash('abc'),exists:()=>true,
    onAsset:(a,i)=>{assets[i]=a;},fetchImpl:async()=>new Response('abc'),...overrides};
  return {...startTransportAudit(options),assets,checks};
}
test('all entries retain independent HTTP, manifest, and local byte checks with bounded overlap',async()=>{
  let active=0,maximum=0;
  const audit=fixture({fetchImpl:async()=>{active++;maximum=Math.max(maximum,active);await delay(15);active--;return new Response('abc');}});
  const result=await audit.completion;
  assert.equal(result.error,undefined);assert.equal(maximum,2);assert.equal(active,0);
  assert.equal(audit.assets.length,3);assert.equal(audit.checks.length,12);
  assert.deepEqual(audit.assets.map(a=>a.relativePath),['1','2','3']);assert.equal(audit.evidence.completed,3);
});
for(const [name,options] of [
  ['HTTP failure',{fetchImpl:async()=>new Response('abc',{status:404})}],
  ['wrong transport bytes',{fetchImpl:async()=>new Response('bad')}],
  ['wrong length',{fetchImpl:async()=>new Response('abcd')}],
  ['missing local file',{exists:()=>false}],
  ['wrong local bytes',{shaFile:async()=>hash('bad')}],
  ['unsafe location',{locate:()=>{throw Error('unsafe path');}}]
])test(name+' cannot become a passing audit',async()=>{const a=fixture(options);assert.ok((await a.completion).error);assert.ok(a.evidence.completed<3);});
test('cancellation aborts and drains every live response',async()=>{
  let active=0;
  const audit=fixture({fetchImpl:async(_url,{signal})=>{active++;try{await delay(10000,null,{signal});return new Response('abc');}finally{active--;}}});
  audit.cancel(Error('browser failed'));assert.match((await audit.completion).error.message,/browser failed|aborted/);assert.equal(active,0);assert.equal(audit.assets.length,0);
});
test('a hung HTTP transfer has its own diagnostic deadline and drains peers',async()=>{
  let active=0;
  const audit=fixture({timeoutMs:15,fetchImpl:async(_url,{signal})=>{active++;try{await delay(10000,null,{signal});return new Response('abc');}finally{active--;}}});
  assert.ok((await audit.completion).error);assert.equal(active,0);
});
test('a body stream error cannot be mistaken for complete content',async()=>{
  const audit=fixture({fetchImpl:async()=>({status:200,body:(async function*(){yield Buffer.from('a');throw Error('broken body');})()})});
  assert.match((await audit.completion).error.message,/broken body/);assert.equal(audit.evidence.completed,0);
});
test('invalid concurrency fails before making requests',()=>{for(const concurrency of [0,5,1.5])assert.throws(()=>fixture({concurrency}));});
