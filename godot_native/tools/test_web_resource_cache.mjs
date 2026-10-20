#!/usr/bin/env node
// Transport tests use asynchronous IDB transactions and real independent SHA
// vectors. Actual persistence/engine acceptance is a separate browser check.
import assert from 'node:assert/strict';
import crypto from 'node:crypto';
import fs from 'node:fs';
import vm from 'node:vm';

const source=fs.readFileSync(new URL('../web/content_loader.js',import.meta.url),'utf8');
const hash=bytes=>crypto.createHash('sha256').update(bytes).digest('hex');
const block=1024*1024;
const checks=[];
const check=(value,label)=>{assert.ok(value,label);checks.push(label);};
const payload=Buffer.alloc(block*2+319);for(let i=0;i<payload.length;i++)payload[i]=(i*37+(i>>>11))&255;
const resource={file:'index.pck',bytes:payload.length,sha256:hash(payload)};
function chunked(bytes,file='index.pck') {
  const chunks=[];
  for(let offset=0;offset<bytes.length;offset+=block) {
    const part=bytes.subarray(offset,offset+block),sha256=hash(part);
    chunks.push({file:`boot/${file.replace('.','-')}-${chunks.length}-${sha256.slice(0,16)}.bin`,offset,bytes:part.length,sha256});
  }
  return {file,bytes:bytes.length,sha256:hash(bytes),chunks};
}

function idb(storage,failWrites=false) {
  return {open(){
    const request={};setImmediate(()=>{
      request.result={objectStoreNames:{contains:()=>true},close(){},transaction(name,mode){
        assert.equal(name,'chunks');const transaction={objectStore(){return {
          get:key=>run(()=>storage.get(key)),put:(value,key)=>run(()=>{storage.set(key,structuredClone(value));return key;}),delete:key=>run(()=>storage.delete(key)),
        };}};
        function run(action){const result={};setImmediate(()=>{
          if(failWrites&&mode==='readwrite'){transaction.onabort?.();return;}
          result.result=action();result.onsuccess?.();setImmediate(()=>transaction.oncomplete?.());
        });return result;}
        return transaction;
      }};request.onsuccess?.();
    });return request;
  }};
}
function fixture({stored=new Map(),fetcher,noIDB=false,failWrites=false}={}) {
  const requests=[];
  const context={window:{},document:{baseURI:'http://755-cache.test/7-55/releases/new/'},location:{origin:'http://755-cache.test'},navigator:{},URL,Response,ReadableStream,ArrayBuffer,Uint8Array,Uint32Array,DataView,TextEncoder,
    fetch:async(url,init)=>{requests.push({url,init});return fetcher?fetcher(url,init,requests.length):new Response(payload);},
    ...(noIDB?{}:{indexedDB:idb(stored,failWrites)})};
  vm.runInNewContext(source,context);
  return {api:context.window.Godot755Content,context,requests,stored,cache:context.window.Godot755Content.createResourceCache()};
}
const rangeResponse=(bytes,start)=>new Response(bytes.subarray(start),{status:206,headers:{'Content-Range':`bytes ${start}-${bytes.length-1}/${bytes.length}`}});
function prefix(stored,bytes,count=2){for(let i=0;i<count;i++){const data=Uint8Array.from(bytes.subarray(i*block,(i+1)*block));stored.set(`${hash(bytes)}:${i}`,{bytes:data.buffer,digest:hash(data)});}}

// The pure-JS path is always exercised with crypto entirely absent.
for(const size of [1,55,56,63,64,65,127,128,129,1024,block+71]) {
  const bytes=Buffer.alloc(size,0x61),f=fixture({noIDB:true,fetcher:()=>new Response(bytes)});
  const loaded=await f.cache.load({file:'known.bin',bytes:size,sha256:hash(bytes)});
  assert.deepEqual(Buffer.from(loaded.buffer),bytes);
}
check(true,'Plain HTTP SHA-256 agrees with independent Node vectors across block/padding boundaries');

{
  const f=fixture({fetcher:()=>new Response(new ReadableStream({start(controller){controller.enqueue(Uint8Array.from(payload.subarray(0,block*2)));},pull(controller){controller.error(new Error('interrupted fixture'));}}))});
  await assert.rejects(f.cache.load(resource),/interrupted fixture/);
  check(f.stored.size===2,'Interrupted transfer commits only the two complete 1 MiB transport chunks');
  const resumed=fixture({stored:f.stored,fetcher:(url,init)=>{assert.equal(init.headers.Range,`bytes=${block*2}-`);return rangeResponse(payload,block*2);}});
  const loaded=await resumed.cache.load(resource);
  check(Buffer.from(loaded.buffer).equals(payload)&&loaded.source==='resumed-network'&&loaded.reusedBytes===block*2,'A fresh loader resumes from the durable complete-block offset and verifies the whole resource');
  const reopened=fixture({stored:f.stored,fetcher:()=>{throw new Error('network must be unused');}});
  const reused=await reopened.cache.load(resource,{response:true});
  check(Buffer.from(await reused.response.arrayBuffer()).equals(payload)&&reopened.requests.length===0&&reused.source==='verified-cache','A third loader streams the fully verified cached resource without a network fetch');
}
{
  const stored=new Map();prefix(stored,payload);
  const f=fixture({stored,fetcher:()=>new Response(payload,{headers:{'Content-Encoding':'gzip'}})});
  const loaded=await f.cache.load(resource);
  check(Buffer.from(loaded.buffer).equals(payload)&&loaded.reusedBytes===0,'A Range-ignoring 200/gzip response restarts full decoded hashing and never concatenates the cached prefix twice');
}
for(const headers of [{'Content-Range':`bytes 0-${payload.length-1}/${payload.length}`},{'Content-Range':`bytes ${block*2}-${payload.length-1}/${payload.length}`,'Content-Encoding':'gzip'}]) {
  const stored=new Map();prefix(stored,payload);
  const f=fixture({stored,fetcher:(url,init,sequence)=>{
    if(sequence===1)return new Response(payload.subarray(block*2),{status:206,headers});
    assert.equal(sequence,2);assert.equal(init.headers.Range,undefined);assert.equal(init.cache,'reload');return new Response(payload,{headers:{'Content-Encoding':'gzip'}});
  }});
  const loaded=await f.cache.load(resource);
  check(Buffer.from(loaded.buffer).equals(payload)&&f.requests.length===2&&loaded.reusedBytes===0,'An unusable 206 performs one complete GET fallback, resets the cached prefix and verifies the decoded payload');
}
{
  const stored=new Map();prefix(stored,payload);
  const f=fixture({stored,fetcher:()=>new Response(payload.subarray(block*2),{status:206,headers:{'Content-Range':'bytes 1-2/3'}})});
  await assert.rejects(f.cache.load(resource),/Content range differs/);
  check(f.requests.length===2,'A broken complete-GET fallback stops after two requests instead of looping');
}
{
  const stored=new Map();prefix(stored,payload);
  const f=fixture({stored,fetcher:(url,init,sequence)=>{
    if(sequence===1){assert.equal(init.headers.Range,`bytes=${block*2}-`);throw new TypeError('Failed to fetch: gzip range decoding fixture');}
    assert.equal(sequence,2);assert.equal(init.headers.Range,undefined);assert.equal(init.cache,'reload');
    return new Response(payload,{headers:{'Content-Encoding':'gzip'}});
  }});
  const loaded=await f.cache.load(resource);
  check(f.requests.length===2&&loaded.reusedBytes===0&&Buffer.from(loaded.buffer).equals(payload),'A resumed Range fetch rejected before Response gets one full GET and whole-payload SHA verification');
}
for(const failure of ['reject','http','range']) {
  const stored=new Map();prefix(stored,payload);
  const f=fixture({stored,fetcher:(url,init,sequence)=>{
    if(sequence===1)throw new TypeError('Range decode fixture');
    assert.equal(sequence,2);assert.equal(init.headers.Range,undefined);
    if(failure==='reject')throw new TypeError('Full GET failed fixture');
    if(failure==='http')return new Response('',{status:503});
    return rangeResponse(payload,block*2);
  }});
  await assert.rejects(f.cache.load(resource),failure==='reject'?/Full GET failed fixture/:failure==='http'?/HTTP 503/:/Content range differs/);
  check(f.requests.length===2,'A failed full fallback after a Range fetch rejection propagates without a third attempt: '+failure);
}
{
  const f=fixture({fetcher:()=>{throw new TypeError('Original full GET failed fixture');}});
  await assert.rejects(f.cache.load(resource),/Original full GET failed fixture/);
  check(f.requests.length===1,'An original full GET rejection is not retried by the Range-only recovery');
}
{
  const stored=new Map();prefix(stored,payload);new Uint8Array(stored.get(`${resource.sha256}:1`).bytes)[3]^=255;
  const f=fixture({stored,fetcher:(url,init)=>{assert.equal(init.headers.Range,`bytes=${block}-`);return rangeResponse(payload,block);}});
  const loaded=await f.cache.load(resource);
  check(Buffer.from(loaded.buffer).equals(payload)&&loaded.reusedBytes===block&&stored.size===3,'A corrupt local chunk is removed and fetched again while an intact prefix is retained');
}
{
  const f=fixture({fetcher:()=>{const bytes=Buffer.from(payload);bytes[11]^=1;return new Response(bytes);}});
  await assert.rejects(f.cache.load(resource),/Content digest differs/);
  check(f.stored.size===0,'A full SHA mismatch evicts every quarantined chunk and never returns a usable resource');
}
{
  const f=fixture();await f.cache.load(resource);
  const changed=Buffer.from(payload);changed[0]^=1;
  const next=fixture({stored:f.stored,fetcher:(url,init)=>{assert.equal(init.headers.Range,undefined);return new Response(changed);}});
  const loaded=await next.cache.load({...resource,sha256:hash(changed)});
  check(next.requests.length===1&&loaded.reusedBytes===0&&Buffer.from(loaded.buffer).equals(changed),'A changed full SHA cannot reuse bytes from a previous release with the same filename');
}
{
  const table=chunked(payload),stored=new Map();
  // A partially finished three-worker download can have non-contiguous chunks.
  for(const index of [1,2]){const chunk=table.chunks[index],bytes=Uint8Array.from(payload.subarray(chunk.offset,chunk.offset+chunk.bytes));stored.set(`${table.sha256}:${index}`,{bytes:bytes.buffer,digest:chunk.sha256});}
  const f=fixture({stored,fetcher:(url,init)=>{
    assert.equal(init.headers,undefined);assert.equal(url.endsWith(table.chunks[0].file),true);
    return new Response(payload.subarray(0,block),{headers:{'Content-Encoding':'gzip'}});
  }});
  const loaded=await f.cache.load(table,{response:true});
  check(Buffer.from(await loaded.response.arrayBuffer()).equals(payload)&&f.requests.length===1&&loaded.reusedBytes===payload.length-block,'Static boot chunks reuse non-contiguous durable blocks and fetch only the missing complete gzip-decoded file without Range');
}
{
  const table=chunked(payload),stored=new Map(),bad=Buffer.from(payload.subarray(0,block));bad[4]^=255;
  const f=fixture({stored,fetcher:url=>{const chunk=table.chunks.find(item=>url.endsWith(item.file));return new Response(chunk.offset===0?bad:payload.subarray(chunk.offset,chunk.offset+chunk.bytes));}});
  await assert.rejects(f.cache.load(table),/Chunk digest or size differs/);
  // Other workers may finish their independently valid chunks after rejection.
  await new Promise(resolve=>setTimeout(resolve,20));
  check(!stored.has(`${table.sha256}:0`),'A corrupt static chunk never becomes a durable cache entry or usable boot resource');
}
{
  let active=0,maximum=0;
  const table=chunked(payload),second=chunked(Buffer.from(payload).fill(41),'index.wasm');
  const f=fixture({fetcher:async url=>{
    active++;maximum=Math.max(maximum,active);await new Promise(resolve=>setTimeout(resolve,5));
    const chunk=[...table.chunks,...second.chunks].find(item=>url.endsWith(item.file));
    const bytes=table.chunks.includes(chunk)?payload:Buffer.from(payload).fill(41);
    active--;return new Response(bytes.subarray(chunk.offset,chunk.offset+chunk.bytes));
  }});
  const loaded=await Promise.all([f.cache.load(table),f.cache.load(second)]);
  check(maximum===3&&Buffer.from(loaded[0].buffer).equals(payload),'WASM and core share one three-request concurrency limit across both boot resources');
}
for(const options of [{noIDB:true},{failWrites:true}]) {
  const f=fixture(options),loaded=await f.cache.load(resource);
  check(Buffer.from(loaded.buffer).equals(payload)&&f.cache.snapshot().storage==='unavailable','Unavailable/quota-denied IndexedDB falls back to a verified in-memory transfer');
}
{
  const f=fixture();const manifest={core:resource};
  const core=chunked(payload),wasm=chunked(Buffer.alloc(8),'index.wasm');
  const build={files:[{path:'index.pck',bytes:resource.bytes,sha256:resource.sha256},{path:'index.wasm',bytes:8,sha256:wasm.sha256},...[...core.chunks,...wasm.chunks].map(({file,bytes,sha256})=>({path:file,bytes,sha256}))],bootChunks:{schema:'755-boot-chunks-v1',chunkBytes:block,resources:{'index.pck':core,'index.wasm':wasm}}};
  check(f.api.bootResources(build,manifest,'index').wasm.file==='index.wasm','Boot identities bind current core and engine bytes to their build manifest');
  const wrong=structuredClone(build);wrong.files[0].sha256='0'.repeat(64);
  assert.throws(()=>f.api.bootResources(wrong,manifest,'index'),/Release manifests differ/);
  check(true,'Mixed-version content/build manifests are rejected before boot downloads');
  const wrongChunk=structuredClone(build);wrongChunk.bootChunks.resources['index.wasm'].chunks[0].sha256='0'.repeat(64);
  assert.throws(()=>f.api.bootResources(wrongChunk,manifest,'index'),/Invalid resource chunk identity|Boot chunk versions differ/);
  check(true,'A boot chunk table must match both its resource and the release file inventory');
  const original=f.context.fetch, bytes=Buffer.from('wasm fixture'),response=new Response(bytes);
  const engine={async init(name){assert.equal(name,'index');assert.deepEqual(Buffer.from(await(await f.context.fetch('index.wasm')).arrayBuffer()),bytes);await f.context.fetch('unrelated.txt');return true;}};
  await f.api.initEngine(engine,'index',{file:'index.wasm',bytes:bytes.length,sha256:hash(bytes)},response);
  check(f.context.fetch===original&&f.requests.length===1&&f.requests[0].url==='unrelated.txt','Only the declared WASM URL is intercepted during Engine.init and original fetch is restored');
  await assert.rejects(f.api.initEngine({init(){throw new Error('compile fixture');}},'index',{file:'index.wasm',bytes:bytes.length,sha256:hash(bytes)},new Response(bytes)),/compile fixture/);
  check(f.context.fetch===original,'An initialization error also restores browser fetch');
}
console.log(JSON.stringify({success:true,checks:checks.length,loaderSha256:hash(source),scope:'Asynchronous in-memory IDB transaction fixture; actual IDB/browser/engine acceptance remains separate',details:checks},null,2));
