import fs from 'node:fs';
import os from 'node:os';
import path from 'node:path';
import http from 'node:http';
import zlib from 'node:zlib';
import crypto from 'node:crypto';
import assert from 'node:assert/strict';
import {prepareWebCompression,verifyWebCompression} from './web_precompress.mjs';
import {createWebServer} from './serve_web.mjs';

const root=fs.mkdtempSync(path.join(os.tmpdir(),'755-http-compression-'));
const sha=bytes=>crypto.createHash('sha256').update(bytes).digest('hex');
let server,checks=0;
const check=(condition,message)=>{checks++;assert.ok(condition,message);};
const reject=(fn,message)=>{checks++;assert.throws(fn,undefined,message);};
const request=(port,url,headers={},method='GET')=>new Promise((resolve,reject)=>{
  const req=http.request({hostname:'127.0.0.1',port,path:url,headers,method},response=>{
    const parts=[];response.on('data',chunk=>parts.push(chunk));response.on('end',()=>resolve({status:response.statusCode,headers:response.headers,body:Buffer.concat(parts)}));
  });req.on('error',reject);req.end();
});
try {
  const raw=Buffer.from('Godot original validated WASM transport bytes.\n'.repeat(25000));
  const chunk='boot/index-wasm-0001-'+sha(raw).slice(0,16)+'.bin';
  const sources=new Map([[chunk,raw],['index.wasm',raw],['index.js',Buffer.from('const test = "read original bytes";\n'.repeat(1800))],['index.html',Buffer.from('<!doctype html><title>Fixture</title>')],['content/chunks/sample-0001-'+sha(raw).slice(0,16)+'.bin',raw],['content/sample-'+sha(raw).slice(0,16)+'.pck',raw],['content/noise.pck',crypto.randomBytes(65536)],['movie.ogv',crypto.randomBytes(1024)]]);
  for(const [file,bytes] of sources){fs.mkdirSync(path.dirname(path.join(root,file)),{recursive:true});fs.writeFileSync(path.join(root,file),bytes);}
  const receipt=prepareWebCompression(root);
  check(receipt.files.length===5,'Only meaningfully smaller eligible formats receive gzip siblings');
  check(receipt.savedBytes>raw.length*3,'Significant original payload reduction');
  check(verifyWebCompression(root,receipt).bytes===receipt.bytes,'Exact receipt verifies');
  for(const [file,bytes] of sources)check(fs.readFileSync(path.join(root,file)).equals(bytes),'Original unchanged: '+file);
  reject(()=>prepareWebCompression(root),'Existing immutable compressed build must not be overwritten');
  const sidecar=receipt.files[0];const sidecarPath=path.join(root,sidecar.file);const valid=fs.readFileSync(sidecarPath);
  fs.writeFileSync(sidecarPath,Buffer.from('corrupt'));reject(()=>verifyWebCompression(root,receipt),'Corrupt gzip rejected');fs.writeFileSync(sidecarPath,valid);
  fs.writeFileSync(path.join(root,'unregistered.gz'),valid);reject(()=>verifyWebCompression(root,receipt),'Unregistered sidecar rejected');fs.unlinkSync(path.join(root,'unregistered.gz'));
  const duplicate=structuredClone(receipt);duplicate.files.push(duplicate.files[0]);reject(()=>verifyWebCompression(root,duplicate),'Duplicate source receipt rejected');
  const unsafe=structuredClone(receipt);unsafe.files[0].source='../outside.js';unsafe.files[0].file='../outside.js.gz';reject(()=>verifyWebCompression(root,unsafe),'Path traversal receipt rejected');
  const original=fs.readFileSync(path.join(root,sidecar.source));fs.writeFileSync(path.join(root,sidecar.source),Buffer.from('stale'));reject(()=>verifyWebCompression(root,receipt),'Stale original rejected');fs.writeFileSync(path.join(root,sidecar.source),original);
  reject(()=>verifyWebCompression(root,null),'Unregistered compression cannot be served as legacy');
  const manifest={files:[...sources].map(([file,bytes])=>({path:file,bytes:bytes.length,sha256:sha(bytes)})),transportCompression:receipt};
  fs.writeFileSync(path.join(root,'build-manifest.json'),JSON.stringify(manifest));
  server=createWebServer({directory:root});await new Promise(resolve=>server.listen(0,'127.0.0.1',resolve));const port=server.address().port;
  const gz=await request(port,'/'+chunk,{'Accept-Encoding':'gzip, br'});
  check(gz.status===200&&gz.headers['content-encoding']==='gzip','HTTP gzip negotiation');
  check(gz.headers.vary==='Accept-Encoding'&&gz.headers['content-type']==='application/wasm','WASM chunks expose correct MIME and Vary');
  check(Number(gz.headers['content-length'])===gz.body.length,'Compressed Content-Length matches transport bytes');
  check(zlib.gunzipSync(gz.body).equals(raw),'Actual HTTP gzip restores every original WASM byte');
  check(gz.headers['cache-control'].includes('immutable'),'Content-addressed chunks immutable');
  const identity=await request(port,'/'+chunk,{'Accept-Encoding':'gzip;q=0'});
  check(identity.status===200&&!identity.headers['content-encoding']&&identity.body.equals(raw),'Explicit gzip rejection serves original bytes');
  const absent=await request(port,'/'+chunk);
  check(!absent.headers['content-encoding']&&absent.body.equals(raw),'Older clients without Accept-Encoding keep identity');
  const weighted=await request(port,'/'+chunk,{'Accept-Encoding':'gzip;q=0.5, identity;q=1'});
  check(!weighted.headers['content-encoding'],'Explicit representation quality preference respected');
  const onlyGzip=await request(port,'/'+chunk,{'Accept-Encoding':'gzip;q=0.5, identity;q=0'});
  check(onlyGzip.headers['content-encoding']==='gzip','Gzip allowed when identity is excluded');
  const none=await request(port,'/'+chunk,{'Accept-Encoding':'gzip;q=0, identity;q=0'});
  check(none.status===406&&none.headers['cache-control']==='no-store','Unacceptable formats report 406 without caching');
  const head=await request(port,'/'+chunk,{'Accept-Encoding':'gzip'},'HEAD');
  check(head.status===200&&head.body.length===0&&head.headers['content-length']===gz.headers['content-length']&&head.headers['content-encoding']==='gzip','HEAD matches selected GET representation');
  const conditional=await request(port,'/'+chunk,{'Accept-Encoding':'gzip','If-None-Match':gz.headers.etag});
  check(conditional.status===304&&conditional.body.length===0&&conditional.headers.vary==='Accept-Encoding','Variant ETag supports 304 with Vary');
  const different=await request(port,'/'+chunk,{'Accept-Encoding':'identity','If-None-Match':gz.headers.etag});
  check(different.status===200&&different.headers.etag!==gz.headers.etag,'Identity never reuses gzip ETag');
  const rangeGzip=await request(port,'/'+chunk,{'Accept-Encoding':'gzip',Range:'bytes=100-199'});
  check(rangeGzip.status===200&&!rangeGzip.headers['content-range']&&zlib.gunzipSync(rangeGzip.body).equals(raw),'Compressed range resets to verified complete 200');
  const rangeIdentity=await request(port,'/movie.ogv',{Range:'bytes=10-19'});
  check(rangeIdentity.status===206&&rangeIdentity.body.equals(sources.get('movie.ogv').subarray(10,20)),'Uncompressed media retain exact byte seeking');
  const badRange=await request(port,'/movie.ogv',{Range:'bytes=99999-'});
  check(badRange.status===416&&badRange.headers['content-range']==='bytes */1024','Unsatisfiable identity range reported correctly');
  const gzipPck=await request(port,'/'+[...sources.keys()].find(file=>file.startsWith('content/sample')),{'Accept-Encoding':'gzip'});
  check(gzipPck.headers['content-type']==='application/octet-stream'&&zlib.gunzipSync(gzipPck.body).equals(raw),'PCK gzip remains decoded-byte identical');
  const js=await request(port,'/index.js?v='+manifest.files.find(f=>f.path==='index.js').sha256,{'Accept-Encoding':'gzip'});
  check(js.headers['cache-control'].includes('immutable')&&js.headers['content-type'].startsWith('text/javascript'),'Verified version-query JS is immutable and executable');
  const oldJs=await request(port,'/index.js?v=wrong');check(oldJs.headers['cache-control']==='no-cache','Mutable or incorrect version query must revalidate');
  const manifestResponse=await request(port,'/build-manifest.json');check(!manifestResponse.headers['content-encoding']&&manifestResponse.headers['cache-control']==='no-cache','Build receipt remains noncyclic and fresh');
  for(const url of ['/../outside','/%2e%2e/outside','/nested/%2e%2e/outside','/%5cetc','/.git/config','/'+chunk+'.gz','/%00','/%ZZ','/missing.bin']) {
    const r=await request(port,url);check(r.status===404&&r.headers['cache-control']==='no-store','Protected missing/path request: '+url);
  }
  fs.symlinkSync(os.tmpdir(),path.join(root,'escape'));const escaped=await request(port,'/escape/no-such-file');check(escaped.status===404,'Symlink path cannot expose outside root');fs.unlinkSync(path.join(root,'escape'));
  const post=await request(port,'/',{},'POST');check(post.status===405&&post.headers.allow==='GET, HEAD','Read-only HTTP methods');
  console.log(JSON.stringify({passed:true,checks,receiptFiles:receipt.files.length,sourceBytes:receipt.sourceBytes,gzipBytes:receipt.bytes,savedBytes:receipt.savedBytes,transport:'real HTTP on an ephemeral loopback port; raw gzip decoded and compared'},null,2));
} finally {if(server)await new Promise(resolve=>server.close(resolve));fs.rmSync(root,{recursive:true,force:true});}
