import test from 'node:test';
import assert from 'node:assert/strict';
import fs from 'node:fs';
import os from 'node:os';
import path from 'node:path';
import {createRequire} from 'node:module';
import {spawnSync} from 'node:child_process';
const require=createRequire(import.meta.url),Cache=require('../tools/media_conversion_cache.cjs');
const fixture=()=>fs.mkdtempSync(path.join(os.tmpdir(),'755-media-cache-test-'));
const expected=()=>Cache.identity({sourceSha256:'a'.repeat(64),converterSha256:'b'.repeat(64),tools:{ffmpeg:{sha256:'c'.repeat(64),version:'fixed'},ffprobe:{sha256:'d'.repeat(64),version:'fixed'}},maxBytes:2000});
test('only complete exact-source/tool/config cache entries are hits',()=>{
 const root=fixture();try {
  const source=path.join(root,'input'),cache=path.join(root,'cache'),e=expected();fs.writeFileSync(source,'complete derived bytes');
  assert.equal(Cache.read(cache,e).hit,false);Cache.write(cache,e,source,{quality:8,attempts:[{quality:8,bytes:22}]});
  assert.equal(Cache.read(cache,e).hit,true);
  for(const other of [{...e,sourceSha256:'e'.repeat(64)},{...e,converterSha256:'e'.repeat(64)},{...e,helperSha256:'e'.repeat(64)},{...e,maxBytes:1500},{...e,tools:{...e.tools,ffmpeg:{sha256:'e'.repeat(64),version:'changed'}}}])assert.equal(Cache.read(cache,other).hit,false);
  const hit=Cache.read(cache,e);fs.writeFileSync(hit.output,'corrupt');assert.equal(Cache.read(cache,e).hit,false);
  Cache.write(cache,e,source,{quality:8,attempts:[{quality:8,bytes:22}]});fs.unlinkSync(hit.receipt);assert.equal(Cache.read(cache,e).hit,false);
  assert.throws(()=>Cache.read('relative',e),/absolute/);
 }finally{fs.rmSync(root,{recursive:true,force:true});}
});
test('converter warm hit still probes full streams and regenerates corrupt bytes',()=>{
 const root=fixture();try {
  const tools=path.join(root,'tools');fs.mkdirSync(tools);
  for(const name of ['convert_media.sh','media_conversion_cache.cjs'])fs.copyFileSync(new URL('../tools/'+name,import.meta.url),path.join(tools,name));
  const encoder=path.join(root,'ffmpeg'),probe=path.join(root,'ffprobe'),count=path.join(root,'encode-count'),probes=path.join(root,'probe-count');
  fs.writeFileSync(encoder,`#!/usr/bin/env node\nconst fs=require('node:fs');if(process.argv.includes('-version')){console.log('fixed encoder');process.exit(0)}fs.appendFileSync(process.env.ENCODE_COUNT,'1');fs.writeFileSync(process.argv.at(-1),'OGV whole stream');\n`,{mode:0o755});
  fs.writeFileSync(probe,`#!/usr/bin/env node\nconst fs=require('node:fs');if(process.argv.includes('-version')){console.log('fixed probe');process.exit(0)}fs.appendFileSync(process.env.PROBE_COUNT,'1');console.log(JSON.stringify({format:{duration:'1'},streams:[{codec_type:'video',codec_name:process.argv.at(-1).endsWith('.ogv')?'theora':'h264',width:16,height:16,avg_frame_rate:'1/1',r_frame_rate:'1/1',nb_read_frames:fs.readFileSync(process.argv.at(-1),'utf8')==='INVALID_STREAM'?'0':'1'}]}));\n`,{mode:0o755});
  const input=path.join(root,'source.mp4'),output=path.join(root,'result.ogv'),cache=path.join(root,'cache');fs.writeFileSync(input,'source bytes');
  const run=()=>{const r=spawnSync('bash',[path.join(tools,'convert_media.sh'),`--input=${input}`,`--output=${output}`],{encoding:'utf8',env:{...process.env,NODE_BIN:process.execPath,FFMPEG_BIN:encoder,FFPROBE_BIN:probe,MEDIA_CONVERSION_CACHE_DIR:cache,ENCODE_COUNT:count,PROBE_COUNT:probes}});assert.equal(r.status,0,r.stderr);return JSON.parse(r.stdout.trim());};
  assert.equal(run().cacheStatus,'miss');assert.equal(fs.readFileSync(count,'utf8').length,1);
  assert.equal(run().cacheStatus,'hit');assert.equal(fs.readFileSync(count,'utf8').length,1);assert.equal(fs.readFileSync(probes,'utf8').length,4,'source and every output still fully probed on each attempt');
  const key=fs.readdirSync(cache)[0];fs.writeFileSync(path.join(cache,key,'output.ogv'),'broken');assert.match(run().cacheStatus,/rejected/);assert.equal(fs.readFileSync(count,'utf8').length,2);
  const outputFile=path.join(cache,key,'output.ogv'),receiptFile=path.join(cache,key,'receipt.json');fs.writeFileSync(outputFile,'INVALID_STREAM');const record=JSON.parse(fs.readFileSync(receiptFile));record.outputSha256=Cache.fileHash(outputFile);record.bytes=fs.statSync(outputFile).size;fs.writeFileSync(receiptFile,JSON.stringify(record));
  assert.match(run().cacheStatus,/rejected stream/);assert.equal(fs.readFileSync(count,'utf8').length,3,'even self-consistent cache metadata cannot bypass full stream validation');
  fs.writeFileSync(input,'new source');assert.equal(run().cacheStatus,'miss');assert.equal(fs.readFileSync(count,'utf8').length,4);
  fs.appendFileSync(encoder,'// new encoder build\n');assert.equal(run().cacheStatus,'miss');assert.equal(fs.readFileSync(count,'utf8').length,5);
 }finally{fs.rmSync(root,{recursive:true,force:true});}
});
