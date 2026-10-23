#!/usr/bin/env node
// Transport CPU/cache benchmark with actual exported core/WASM bytes. It does
// not measure browser paint, engine startup, WAN throughput or physical phones.
import fs from 'node:fs';
import path from 'node:path';
import vm from 'node:vm';
import crypto from 'node:crypto';
import { performance } from 'node:perf_hooks';

const args=process.argv.slice(2);
const option=(name,fallback)=>args.includes('--'+name)?args[args.indexOf('--'+name)+1]:fallback;
const exportDir=path.resolve(option('export-dir','godot_native/exports/web-object-continuity-final-20261023'));
const loader=path.resolve(option('loader','godot_native/web/content_loader.js'));
const output=option('output');
const nativeCrypto=!args.includes('--no-native-crypto');
const source=fs.readFileSync(loader,'utf8'),manifest=JSON.parse(fs.readFileSync(path.join(exportDir,'build-manifest.json'),'utf8'));
const hash=bytes=>crypto.createHash('sha256').update(bytes).digest('hex');
const rows=[];
function database(storage) {
  return {open(){const request={};setImmediate(()=>{
    request.result={objectStoreNames:{contains:()=>true},close(){},transaction(){const transaction={objectStore(){return {
      get:key=>run(()=>storage.get(key)),put:(value,key)=>run(()=>{storage.set(key,structuredClone(value));return key;}),delete:key=>run(()=>storage.delete(key))
    };}};function run(action){const result={};setImmediate(()=>{result.result=action();result.onsuccess?.();setImmediate(()=>transaction.oncomplete?.());});return result;}return transaction;}};
    request.onsuccess?.();});return request;}};
}
function fixture(storage,table,bytes) {
  let requests=0,networkBytes=0;
  const context={window:{},document:{baseURI:'http://755-benchmark.test/game/'},navigator:{},URL,Response,ReadableStream,ArrayBuffer,Uint8Array,Uint32Array,DataView,setTimeout,AbortController,
    ...(nativeCrypto?{crypto:crypto.webcrypto}:{}),indexedDB:database(storage),fetch:async url=>{
      const part=table.chunks.find(chunk=>url.endsWith(chunk.file));if(!part)throw new Error('Unexpected benchmark URL');
      requests++;networkBytes+=part.bytes;return new Response(bytes.subarray(part.offset,part.offset+part.bytes));
    }};
  vm.runInNewContext(source,context,{filename:loader});
  return {cache:context.window.Godot755Content.createResourceCache(),stats:()=>({requests,networkBytes})};
}
async function sample(label,storage,table,bytes,response=false) {
  const f=fixture(storage,table,bytes),lags=[];
  let last=performance.now();const heartbeat=setInterval(()=>{const now=performance.now();lags.push(now-last);last=now;},8);
  const started=performance.now();
  const loaded=await f.cache.load(table,{response});
  const finished=performance.now();
  // Let the pending heartbeat observe the final synchronous work too.
  await new Promise(resolve=>setTimeout(resolve,10));clearInterval(heartbeat);
  const result=response?Buffer.from(await loaded.response.arrayBuffer()):Buffer.from(loaded.buffer);
  if(hash(result)!==table.sha256)throw new Error('Benchmark bytes differ');
  rows.push({label,file:table.file,bytes:bytes.length,elapsedMs:Math.round((finished-started)*10)/10,maxHeartbeatGapMs:Math.round(Math.max(0,...lags)*10)/10,heartbeatSamples:lags.length,reusedBytes:loaded.reusedBytes,...f.stats()});
}
for(const table of Object.values(manifest.bootChunks.resources)) {
  const bytes=fs.readFileSync(path.join(exportDir,table.file));if(hash(bytes)!==table.sha256)throw new Error('Export byte identity differs');
  const storage=new Map(),response=table.file.endsWith('.wasm');
  await sample('cold',storage,table,bytes,response);
  await sample('warm',storage,table,bytes,response);
  if(!response) {
    const changed=Buffer.from(bytes);changed[1024*1024+13]^=1;
    const next={...table,sha256:hash(changed),chunks:table.chunks.map(part=>{const digest=hash(changed.subarray(part.offset,part.offset+part.bytes));return {...part,sha256:digest,file:part.file.replace(part.sha256.slice(0,16),digest.slice(0,16))};})};
    await sample('synthetic-one-byte-core-update',storage,next,changed,false);
  }
}
const report={schema:'755-resource-cache-benchmark-v1',at:new Date().toISOString(),loader,loaderSha256:hash(source),exportDir,nativeCrypto,node:process.version,scope:'Node transport CPU/heartbeat with real export bytes, asynchronous in-memory IDB and memory fetch; one-byte core update is synthetic, not a playable PCK or network-speed claim',rows};
const json=JSON.stringify(report,null,2)+'\n';if(output){fs.mkdirSync(path.dirname(output),{recursive:true});fs.writeFileSync(output,json);}console.log(json);
