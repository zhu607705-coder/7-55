#!/usr/bin/env node
// Deterministic real-loader tests with synthetic bytes and a virtual clock.
// They prove scheduling, not WAN throughput, Godot FPS or physical-device RAM.
import assert from 'node:assert/strict';
import {test} from 'node:test';
import fs from 'node:fs';
import vm from 'node:vm';
import crypto from 'node:crypto';

const source=fs.readFileSync(new URL('../web/content_loader.js',import.meta.url),'utf8');
const hash=bytes=>crypto.createHash('sha256').update(bytes).digest('hex');
const block=1024*1024;
function fixture({chunked=true,bytes=block*3+129,loader=source,bodyFallback=false,noCrypto=false}={}) {
  const data=Buffer.alloc(bytes);for(let i=0;i<bytes;i++)data[i]=(i*37+(i>>>10))&255;
  const pack={id:'chapter2_fixture',family:'chapter2',bytes,sha256:hash(data)};
  pack.file=`content/${pack.id}-${pack.sha256.slice(0,16)}.pck`;
  if(chunked)pack.transportChunks=Array.from({length:Math.ceil(bytes/block)},(_,i)=>{
    const part=data.subarray(i*block,(i+1)*block),sha256=hash(part);
    return {file:`content/chunks/${pack.id}-${String(i+1).padStart(4,'0')}-${sha256.slice(0,16)}.bin`,offset:i*block,bytes:part.length,sha256};
  });
  const manifest={schema:'755-web-content-v1',core:{file:'index.pck',bytes:1,sha256:hash('c')},packs:[pack],backgroundOrder:['chapter2']};
  let time=1,timerId=0,active=0,maximum=0,fail=false;
  const timers=new Map(),frames=[],listeners=new Map(),events=[],requests=[],copies=[],samples=[];
  const listen=(name,fn)=>{if(!listeners.has(name))listeners.set(name,new Set());listeners.get(name).add(fn);};
  const unlisten=(name,fn)=>listeners.get(name)?.delete(fn);
  const fire=name=>{for(const fn of listeners.get(name)||[])fn();};
  const document={baseURI:'http://budget.test/game/',hidden:false,addEventListener:listen,removeEventListener:unlisten};
  const connection={saveData:false,addEventListener:listen,removeEventListener:unlisten};
  const navigator={onLine:true,connection};
  const context={window:{addEventListener:listen,removeEventListener:unlisten},document,navigator,location:{origin:'http://budget.test'},
    URL,Response,ReadableStream,AbortController,ArrayBuffer,Uint8Array,Uint32Array,DataView,crypto:noCrypto?{}:crypto.webcrypto,performance:{now:()=>time},
    setTimeout(fn,delay=0){const id=++timerId;timers.set(id,{at:time+Math.max(0,delay),fn});return id;},clearTimeout:id=>timers.delete(id),
    requestAnimationFrame:fn=>{frames.push(fn);return frames.length;},
    fetch:async(url,init)=>{
      requests.push({at:time,url,signal:init.signal,priority:init.priority});
      if(fail)throw Error('offline fixture');
      active++;maximum=Math.max(maximum,active);let ended=false;
      const end=()=>{if(!ended){ended=true;active--;}};
      init.signal.addEventListener('abort',end,{once:true});
      const chunk=pack.transportChunks?.find(chunk=>url.endsWith(chunk.file));
      const bytes=chunk?data.subarray(chunk.offset,chunk.offset+chunk.bytes):data;
      // A server/browser may supply a whole body in one read. The loader must
      // still split its own copying and hashing work, without trusting size.
      const response=new Response(bytes),reader=response.body.getReader();
      return {ok:true,status:200,headers:response.headers,
        body:bodyFallback?null:{getReader:()=>({async read(){const item=await reader.read();if(item.done)end();return item;},async cancel(){end();await reader.cancel();}})},
        async arrayBuffer(){const out=await new Response(bytes).arrayBuffer();end();return out;}};
    }};
  vm.runInNewContext(loader,context);
  const host=context.window.Godot755Content.create({manifest,engine:{copyToFS(path,buffer){copies.push({at:time,bytes:Buffer.from(buffer),path});}}});
  host.install((id,path,error)=>events.push({id,path,error,at:time}));
  const snapshot=()=>JSON.parse(host.snapshot());
  async function step(ms=16,frame=true) {
    time+=ms;
    if(frame)for(const callback of frames.splice(0))callback(time);
    for(const [id,timer]of [...timers])if(timer.at<=time){timers.delete(id);timer.fn();}
    for(let i=0;i<3;i++)await new Promise(resolve=>setImmediate(resolve));
    await new Promise(resolve=>setTimeout(resolve,1));
    samples.push({at:time,bytes:snapshot().backgroundBudget?.consumedBytes||0});
  }
  async function until(predicate,maxMs=30000){const until=time+maxMs;while(!predicate()){assert(time<until,'bounded scheduler completion');await step();}}
  return {host,events,copies,requests,samples,snapshot,step,until,data,pack,timers,listeners,
    now:()=>time,maximum:()=>maximum,active:()=>active,
    demand:()=>host.request(JSON.stringify([pack.id])),
    start:async()=>{host.startPrefetch();await step();await step();},
    hidden(value){document.hidden=value;fire('visibilitychange');},
    online(value){navigator.onLine=value;fire(value?'online':'offline');},
    saveData(value){connection.saveData=value;fire('change');},
    fail(value){fail=value;}};
}

test('background consumes bounded slices with a ramp, while foreground keeps three workers',async()=>{
  const background=fixture();await background.start();await background.until(()=>background.events.length>0);
  assert.equal(background.maximum(),1);assert.equal(background.events[0].error,'');assert.deepEqual(background.copies[0].bytes,background.data);
  const budget=background.snapshot().backgroundBudget;
  assert.equal(budget.consumedBytes,background.data.length);assert.equal(budget.sliceBytes,65536);
  assert(background.now()>7000,'3 MiB cannot be consumed in an unbudgeted burst');
  for(const sample of background.samples){const later=background.samples.find(x=>x.at>=sample.at+1000);if(later)assert(later.bytes-sample.bytes<=budget.targetBytesPerSecond+budget.sliceBytes*2);}
  await background.host.acknowledge(background.pack.id,true,'');background.host.dispose();
  const foreground=fixture();foreground.demand();await foreground.until(()=>foreground.events.length>0);
  assert.equal(foreground.maximum(),3);assert.deepEqual(foreground.copies[0].bytes,foreground.data);foreground.host.dispose();
});

for(const bodyFallback of [false,true])test(`ordinary pack uses the same budget, body fallback=${bodyFallback}`,async()=>{
  const f=fixture({chunked:false,bytes:block,bodyFallback});await f.start();await f.until(()=>f.events.length>0);
  assert.equal(f.maximum(),1);assert(f.now()>3000);assert.deepEqual(f.copies[0].bytes,f.data);f.host.dispose();
});

test('same-pack foreground promotion wakes a pending budget immediately without restarting',async()=>{
  const f=fixture({chunked:false});await f.start();await f.until(()=>f.snapshot().backgroundBudget.consumedBytes>=65536);
  const before=f.now();f.demand();await f.until(()=>f.events.length>0,1000);
  assert(f.now()-before<1000);assert.equal(f.requests.length,1);assert.equal(f.events[0].error,'');f.host.dispose();
});

test('a long frame pauses optional consumption, then stable frames resume without banked burst',async()=>{
  const f=fixture({chunked:false});await f.start();await f.until(()=>f.snapshot().backgroundBudget.consumedBytes>=65536);
  await f.step(16);await f.step(80);const before=f.snapshot().backgroundBudget.consumedBytes;
  assert.equal(f.snapshot().backgroundBudget.framePressure,true);
  for(let i=0;i<10;i++)await f.step(16);
  assert.equal(f.snapshot().backgroundBudget.consumedBytes,before);
  await f.until(()=>f.snapshot().backgroundBudget.consumedBytes>before,1000);
  assert(f.snapshot().backgroundBudget.consumedBytes-before<=65536);f.host.dispose();
});

for(const constraint of ['hidden','online','saveData'])test(`changing ${constraint} cancels optional work and resumes only when allowed`,async()=>{
  const f=fixture();await f.start();await f.until(()=>f.requests.length>0);
  f[constraint](constraint==='online'?false:true);await f.step();assert(f.requests[0].signal.aborted);assert.equal(f.events.length,0);
  const before=f.requests.length;for(let i=0;i<20;i++)await f.step();assert.equal(f.requests.length,before);
  f[constraint](constraint==='online'?true:false);await f.until(()=>f.requests.length>before);
  f.host.dispose();await f.step();assert.equal(f.active(),0);assert.equal(f.timers.size,0);
  assert([...f.listeners.values()].every(set=>set.size===0));
});

test('offline and saveData do not block foreground demand or turn failure into readiness',async()=>{
  const f=fixture({bytes:99});f.online(false);f.saveData(true);await f.start();assert.equal(f.requests.length,0);
  f.fail(true);f.demand();await f.until(()=>f.events.length>0);
  assert.match(f.events[0].error,/offline fixture/);assert.equal(f.copies.length,0);
  f.fail(false);f.host.retry(JSON.stringify([f.pack.id]));await f.until(()=>f.copies.length>0);
  assert.equal(f.requests.at(-1).priority,'high');assert.deepEqual(f.copies[0].bytes,f.data);f.host.dispose();
});

test('ordinary HTTP without WebCrypto remains verified and interruptible',async()=>{
  const f=fixture({chunked:false,bytes:block,noCrypto:true});await f.start();await f.until(()=>f.events.length>0);
  assert.equal(f.events[0].error,'');assert.deepEqual(f.copies[0].bytes,f.data);assert(f.now()>3000);f.host.dispose();
});

test('persistent low FPS defers optional work, but never blocks explicit foreground input',async()=>{
  const f=fixture({chunked:false});await f.start();await f.until(()=>f.snapshot().backgroundBudget.consumedBytes>=65536);await f.step();
  const before=f.snapshot().backgroundBudget.consumedBytes;
  for(let i=0;i<20;i++)await f.step(50);
  assert.equal(f.snapshot().backgroundBudget.consumedBytes,before);
  f.demand();await f.until(()=>f.events.length>0,1000);assert.equal(f.requests.length,1);assert.equal(f.events[0].error,'');f.host.dispose();
});
