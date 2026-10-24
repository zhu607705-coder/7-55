#!/usr/bin/env node
import fs from 'node:fs';
import path from 'node:path';
import http from 'node:http';
import {fileURLToPath} from 'node:url';
import {verifyWebCompression} from './web_precompress.mjs';

function quality(header,name) {
  const entries=String(header||'').toLowerCase().split(',').map(value=>{
    const [token,...parameters]=value.trim().split(';');
    const parameter=parameters.find(part=>/^\s*q\s*=/.test(part));
    const q=parameter===undefined?1:Number(parameter.split('=')[1]);
    return {token,q:Number.isFinite(q)&&q>=0&&q<=1?q:0};
  });
  const exact=entries.find(entry=>entry.token===name);
  if(exact)return exact.q;
  const wildcard=entries.find(entry=>entry.token==='*');
  if(name==='identity')return wildcard?.q===0?0:1;
  return wildcard?.q||0;
}
function mime(file) {
  if(/^boot\/index-wasm-\d{4}-[a-f0-9]{16}\.bin$/.test(file))return 'application/wasm';
  return ({'.html':'text/html; charset=utf-8','.js':'text/javascript; charset=utf-8','.mjs':'text/javascript; charset=utf-8','.json':'application/json; charset=utf-8','.wasm':'application/wasm','.pck':'application/octet-stream','.bin':'application/octet-stream','.css':'text/css; charset=utf-8','.svg':'image/svg+xml','.png':'image/png','.webp':'image/webp','.jpg':'image/jpeg','.woff2':'font/woff2','.ogv':'video/ogg','.ogg':'audio/ogg','.mp3':'audio/mpeg','.txt':'text/plain; charset=utf-8'})[path.extname(file)]||'application/octet-stream';
}
export function createWebServer({directory}) {
  const root=fs.realpathSync(directory);
  const manifestPath=path.join(root,'build-manifest.json');
  const manifest=fs.existsSync(manifestPath)?JSON.parse(fs.readFileSync(manifestPath,'utf8')):{};
  const receipt=verifyWebCompression(root,manifest.transportCompression);
  const compressed=new Map((receipt?.files||[]).map(row=>[row.source,row]));
  const recorded=new Map((manifest.files||[]).map(row=>[row.path,row]));
  const server=http.createServer((request,response)=>{
    const error=(status,message)=>{response.writeHead(status,{'Content-Type':'text/plain; charset=utf-8','Cache-Control':'no-store','Vary':'Accept-Encoding'});response.end(request.method==='HEAD'?'':message+'\n');};
    if(!['GET','HEAD'].includes(request.method)){response.setHeader('Allow','GET, HEAD');error(405,'Method not allowed');return;}
    let relative,query,full;
    try {
      const raw=(request.url||'/').split('?')[0];
      const decoded=decodeURIComponent(raw);
      if(!decoded.startsWith('/')||/[\\\x00-\x1f]/.test(decoded)||decoded.split('/').some(part=>part==='..'||part==='.'||part.startsWith('.'))) throw Error('Invalid path');
      relative=decoded.slice(1);if(!relative||relative.endsWith('/'))relative+='index.html';
      if(relative.endsWith('.gz'))throw Error('Transport sidecars are not public routes');
      full=path.resolve(root,relative);
      if(!full.startsWith(root+path.sep))throw Error('Outside root');
      const real=fs.realpathSync(full);
      if(real!==full||!real.startsWith(root+path.sep)||!fs.statSync(full).isFile())throw Error('Not a regular release file');
      query=new URL(request.url,'http://localhost').searchParams;
    } catch {error(404,'Not found');return;}
    const source=recorded.get(relative), gzip=compressed.get(relative);
    const gzipQuality=quality(request.headers['accept-encoding'],'gzip'), identityQuality=quality(request.headers['accept-encoding'],'identity');
    const useGzip=!!gzip&&gzipQuality>0&&gzipQuality>=identityQuality;
    if(!useGzip&&identityQuality===0){error(406,'No acceptable representation');return;}
    const chosen=useGzip?path.join(root,gzip.file):full;
    let stat;try{stat=fs.statSync(chosen);}catch{error(404,'Not found');return;}
    const digest=useGzip?gzip.sha256:source?.sha256;
    const etag=digest?'"'+digest+'-'+(useGzip?'gzip':'identity')+'"':null;
    const immutable=/^(?:boot|content|boot-art|boot-fonts)\//.test(relative)&&/[a-f0-9]{16}/.test(relative)||source&&query.get('v')===source.sha256;
    const headers={'Content-Type':mime(relative),'Content-Length':String(stat.size),'Vary':'Accept-Encoding','Cache-Control':immutable?'public, max-age=31536000, immutable':'no-cache','X-Content-Type-Options':'nosniff','Accept-Ranges':useGzip?'none':'bytes'};
    if(useGzip)headers['Content-Encoding']='gzip';
    if(etag)headers.ETag=etag;
    if(etag&&String(request.headers['if-none-match']||'').split(',').map(s=>s.trim().replace(/^W\//,'')).some(s=>s===etag||s==='*')) {
      delete headers['Content-Length'];response.writeHead(304,headers);response.end();return;
    }
    // Encoded ranges are not decoded PCK ranges: gzip deliberately resets to
    // a complete 200. Identity media keep seeking and ordinary resume support.
    let status=200, start=0, end=stat.size-1;
    if(!useGzip&&request.headers.range&&(!request.headers['if-range']||request.headers['if-range']===etag)) {
      const range=/^bytes=(\d*)-(\d*)$/.exec(request.headers.range);
      if(range&&(range[1]||range[2])) {
        if(range[1]) {start=Number(range[1]);end=range[2]?Math.min(Number(range[2]),end):end;}
        else start=Math.max(0,stat.size-Number(range[2]));
        if(!Number.isSafeInteger(start)||!Number.isSafeInteger(end)||start>end||start>=stat.size) {
          response.setHeader('Content-Range','bytes */'+stat.size);error(416,'Range not satisfiable');return;
        }
        status=206;headers['Content-Range']='bytes '+start+'-'+end+'/'+stat.size;headers['Content-Length']=String(end-start+1);
      }
    }
    response.writeHead(status,headers);
    if(request.method==='HEAD'){response.end();return;}
    const stream=fs.createReadStream(chosen,status===206?{start,end}:{});
    stream.on('error',()=>response.destroy());
    response.on('close',()=>stream.destroy());
    stream.pipe(response);
  });
  server.requestTimeout=15000;server.headersTimeout=10000;
  return server;
}
if(process.argv[1]&&path.resolve(process.argv[1])===fileURLToPath(import.meta.url)) {
  const option=(key,fallback)=>process.argv.find(arg=>arg.startsWith('--'+key+'='))?.slice(key.length+3)??fallback;
  const directory=path.resolve(option('directory','godot_native/exports/web'));
  const host=option('host','127.0.0.1'),port=Number(option('port','5241'));
  if(!Number.isInteger(port)||port<0||port>65535)throw Error('Invalid server port');
  const server=createWebServer({directory});
  server.listen(port,host,()=>console.log(JSON.stringify({directory,host,port:server.address().port,compression:'receipt-verified gzip negotiation'})));
}
