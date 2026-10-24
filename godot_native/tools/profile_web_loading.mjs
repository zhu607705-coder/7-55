#!/usr/bin/env node
// Measures a real release in a disposable Chromium profile. Inputs are ordinary
// pointer/key actions; this never writes the read-only gameplay bridge or saves.
import fs from 'node:fs/promises';
import path from 'node:path';
import os from 'node:os';
import {spawn} from 'node:child_process';
import {createHash} from 'node:crypto';

const opt = (key, fallback) => process.argv.find(x => x.startsWith(`--${key}=`))?.slice(key.length + 3) ?? fallback;
const url = opt('url', 'http://127.0.0.1:5241/');
const output = path.resolve(opt('output', '/tmp/755-loading-profile.json'));
const mobile = opt('viewport', 'desktop') === 'mobile';
const width = mobile ? 390 : 1440, height = mobile ? 844 : 900, dpr = mobile ? 3 : 1;
const mbps = Number(opt('mbps', '20')), latency = Number(opt('latency', '60'));
const cpuRate = Number(opt('cpu-rate', '1'));
if (!Number.isFinite(cpuRate) || cpuRate < 1 || cpuRate > 20) throw new Error('--cpu-rate must be between 1 and 20');
const sampleMs = Number(opt('sample-ms', '8000'));
const passNames = opt('passes', 'cold,warm-restart').split(',');
if (!passNames.length || passNames.some(name => !['cold', 'warm-restart'].includes(name)) || passNames[0] !== 'cold') throw new Error('Measure cold before a same-profile warm restart');
const chrome = opt('chrome', '/Applications/Google Chrome.app/Contents/MacOS/Google Chrome');
const pause = ms => new Promise(resolve => setTimeout(resolve, ms));
const sha = value => createHash('sha256').update(value).digest('hex');
const owned = await fs.mkdtemp(path.join(os.tmpdir(), '755-perf-browser-'));
const profile = path.join(owned, 'profile');
const report = {schema:'755-web-loading-profile-v1', startedAt:new Date().toISOString(), url,
  environment:{width,height,dpr,mobile,mbps,latencyMs:latency,cpuRate,chrome,headless:true},
  limitations:['The recorded URL is loaded with CDP network emulation; timings depend on its server and this host.',
    'CPU slowdown is a browser simulation, not a measurement of a particular phone.',
    'Animation-frame cadence is browser scheduling, not a GPU frame profiler or physical phone result.',
    'Warm run restarts Chromium using the same isolated profile; user saves and browser are untouched.'], passes:[]};
await fs.mkdir(path.dirname(output),{recursive:true});
report.runnerSha256 = sha(await fs.readFile(new URL(import.meta.url)));
const manifestBytes = await (await fetch(new URL('build-manifest.json',url))).arrayBuffer();
const manifest = JSON.parse(Buffer.from(manifestBytes));
report.export = {manifestSha256:sha(Buffer.from(manifestBytes)),engine:manifest.engine,sourceCommit:manifest.sourceCommit,
  initialPayloadBytes:manifest.initialPayloadBytes,core:manifest.pack,sourceInputSha256:manifest.sourceInputSha256};
async function poll(fn,label,timeout=180000){const t=Date.now();let last;while(Date.now()-t<timeout){try{const v=await fn();if(v)return v;}catch(e){last=e.message;}await pause(100);}throw new Error(`Timeout ${label}: ${last||''}`);}
async function connect(url, event){
  const ws=new WebSocket(url);await new Promise((r,j)=>{ws.addEventListener('open',r,{once:true});ws.addEventListener('error',j,{once:true});});
  let seq=0;const pending=new Map();
  ws.addEventListener('message',e=>{const m=JSON.parse(String(e.data));if(m.method){event(m);return;}const p=pending.get(m.id);if(p){clearTimeout(p.timer);pending.delete(m.id);m.error?p.reject(new Error(m.error.message)):p.resolve(m.result);}});
  return {send(method,params={}){return new Promise((resolve,reject)=>{const id=++seq;const timer=setTimeout(()=>{pending.delete(id);reject(new Error(method+' timeout'));},30000);pending.set(id,{resolve,reject,timer});ws.send(JSON.stringify({id,method,params}));});},close(){for(const p of pending.values()){clearTimeout(p.timer);p.reject(new Error('CDP closed'));}pending.clear();ws.close();}};
}
async function run(label){
  const row={label,requests:[],errors:[],metrics:{}};report.passes.push(row);
  const stderrPath=output.replace(/\.json$/,`-${label}-chrome.log`);const fd=await fs.open(stderrPath,'w');
  // Remove only Chromium's generated discovery file in our own profile so a
  // restart cannot read a stale debugging port before the new browser writes it.
  await fs.rm(path.join(profile,'DevToolsActivePort'),{force:true});
  const child=spawn(chrome,['--headless=new','--no-sandbox','--disable-background-networking','--disable-extensions','--disable-sync','--disable-default-apps',`--user-data-dir=${profile}`,'--remote-debugging-port=0','about:blank'],{stdio:['ignore','ignore',fd.fd]});await fd.close();
  let closed=false;const closing=new Promise(resolve=>child.once('close',()=>{closed=true;resolve();}));let cdp;
  try{
    const port=(await poll(()=>fs.readFile(path.join(profile,'DevToolsActivePort'),'utf8'),'Chrome port')).split('\n')[0];
    const targets=await (await fetch(`http://127.0.0.1:${port}/json/list`)).json();const byId=new Map();
    cdp=await connect(targets.find(t=>t.type==='page').webSocketDebuggerUrl,({method,params:p})=>{
      if(method==='Network.requestWillBeSent'){const r={url:p.request.url,requestId:p.requestId,startedAt:Date.now(),timestamp:p.timestamp};row.requests.push(r);byId.set(p.requestId,r);}
      const r=byId.get(p.requestId);
      if(method==='Network.responseReceived'&&r)Object.assign(r,{status:p.response.status,fromDiskCache:!!p.response.fromDiskCache,fromServiceWorker:!!p.response.fromServiceWorker});
      if(method==='Network.loadingFinished'&&r)Object.assign(r,{finishedAt:Date.now(),encodedDataLength:p.encodedDataLength});
      if(method==='Network.loadingFailed'&&r){r.failure=p.errorText;r.cancelled=!!p.canceled;}
      if(method==='Runtime.exceptionThrown')row.errors.push({type:'exception',text:p.exceptionDetails.exception?.description||p.exceptionDetails.text});
      if(method==='Runtime.consoleAPICalled'&&p.type==='error')row.errors.push({type:'console',text:p.args.map(x=>x.value??x.description??'').join(' ')});
    });
    const evaluate=async expression=>{const r=await cdp.send('Runtime.evaluate',{expression,returnByValue:true,awaitPromise:true});if(r.exceptionDetails)throw new Error(r.exceptionDetails.text);return r.result.value;};
    const snapshot=()=>evaluate('window.__GODOT_755__?.snapshot?.()??null');
    const tap=async(x,y)=>{if(mobile){await cdp.send('Input.dispatchTouchEvent',{type:'touchStart',touchPoints:[{x,y,id:1}]});await pause(65);await cdp.send('Input.dispatchTouchEvent',{type:'touchEnd',touchPoints:[]});}else{await cdp.send('Input.dispatchMouseEvent',{type:'mousePressed',button:'left',clickCount:1,x,y});await pause(65);await cdp.send('Input.dispatchMouseEvent',{type:'mouseReleased',button:'left',clickCount:1,x,y});}};
    const press=async()=>{await cdp.send('Input.dispatchKeyEvent',{type:'keyDown',key:'Enter',code:'Enter',windowsVirtualKeyCode:13});await pause(65);await cdp.send('Input.dispatchKeyEvent',{type:'keyUp',key:'Enter',code:'Enter',windowsVirtualKeyCode:13});};
    const clickText=async text=>{const found=await poll(async()=>{const s=await snapshot();const c=s?.visibleControls?.find(c=>c.text===text&&!c.disabled);return c?{s,c}:null;},text,20000);const g=await evaluate('(()=>{const r=document.getElementById("canvas").getBoundingClientRect();return{x:r.x,y:r.y,width:r.width,height:r.height};})()');const v=found.s.viewport;const r=found.c.rect;await tap(g.x+(r.x+r.width/2)/(v.width??v.size?.x)*g.width,g.y+(r.y+r.height/2)/(v.height??v.size?.y)*g.height);await pause(350);};
    await cdp.send('Page.enable');await cdp.send('Runtime.enable');await cdp.send('Network.enable');await cdp.send('Performance.enable');
    await cdp.send('Emulation.setCPUThrottlingRate',{rate:cpuRate});
    await cdp.send('Emulation.setDeviceMetricsOverride',{width,height,deviceScaleFactor:dpr,mobile});await cdp.send('Emulation.setTouchEmulationEnabled',{enabled:mobile,maxTouchPoints:5});
    await cdp.send('Network.emulateNetworkConditions',{offline:false,latency,downloadThroughput:mbps*1000000/8,uploadThroughput:mbps*1000000/8,connectionType:'wifi'});
    await cdp.send('Page.addScriptToEvaluateOnNewDocument',{source:`(()=>{const p=window.__755Perf={frames:[],longTasks:[]};let last;function frame(now){if(last!==undefined&&p.frames.length<30000)p.frames.push([now,now-last]);last=now;requestAnimationFrame(frame);}requestAnimationFrame(frame);try{new PerformanceObserver(list=>{for(const e of list.getEntries())p.longTasks.push({start:e.startTime,duration:e.duration});}).observe({type:'longtask',buffered:true});}catch{}})();`});
    row.startedAt=Date.now();await cdp.send('Page.navigate',{url});
    await poll(()=>evaluate('document.documentElement.dataset.bootState==="ready"'),'ready');row.readyMs=Date.now()-row.startedAt;
    row.metrics.ready=(await cdp.send('Performance.getMetrics')).metrics;
    const point=await evaluate('(()=>{const b=document.getElementById("start-game");const r=b.getBoundingClientRect();return{x:r.x+r.width/2,y:r.y+r.height/2};})()');
    await tap(point.x,point.y);await poll(()=>evaluate('document.documentElement.dataset.bootState==="running"'),'running',60000);await pause(500);await evaluate('document.getElementById("canvas").focus()');await press();
    let s=await poll(async()=>{const v=await snapshot();return v?.state?.native?v:null;},'native main',60000);row.mainMs=Date.now()-row.startedAt;
    if(s.state.native.page==='alarm'){await clickText('开始游戏');await clickText('关闭');await clickText('……再睡5分钟……');await clickText('进入手机主界面');}
    s=await poll(async()=>{const v=await snapshot();return v?.state?.native?.page==='phone_home'?v:null;},'phone home',20000);
    row.sampleStart=await evaluate('performance.now()');row.metrics.sampleStart=(await cdp.send('Performance.getMetrics')).metrics;
    await pause(sampleMs);
    row.metrics.sampleEnd=(await cdp.send('Performance.getMetrics')).metrics;
    row.observation=await evaluate('({perf:window.__755Perf,memory:performance.memory?{used:performance.memory.usedJSHeapSize,total:performance.memory.totalJSHeapSize,limit:performance.memory.jsHeapSizeLimit}:null,navigation:performance.getEntriesByType("navigation").map(e=>e.toJSON()),time:performance.now()})');
    s=await snapshot();row.runtime={engine:s.engine,version:s.version,page:s.state.native.page,content:s.content,viewport:s.viewport};
    const frames=row.observation.perf.frames.filter(x=>x[0]>=row.sampleStart).map(x=>x[1]).sort((a,b)=>a-b);
    const percentile=p=>frames[Math.min(frames.length-1,Math.floor(frames.length*p))]??null;
    row.cadence={samples:frames.length,p50Ms:percentile(.5),p95Ms:percentile(.95),p99Ms:percentile(.99),over50ms:frames.filter(x=>x>50).length};
    const atReady=row.startedAt+row.readyMs;
    row.bootTransfer={requests:row.requests.filter(x=>x.startedAt<=atReady).length,encodedBytes:row.requests.filter(x=>x.finishedAt<=atReady).reduce((s,x)=>s+(x.encodedDataLength||0),0),chunkRequests:row.requests.filter(x=>new URL(x.url).pathname.includes('/boot/')&&x.startedAt<=atReady).length};
    row.passed=row.errors.length===0&&s.engine==='Godot'&&s.version==='4.7.1-stable (official)';
    console.log(`${label}: ready ${row.readyMs}ms, main ${row.mainMs}ms, boot transfer ${row.bootTransfer.encodedBytes}B, ${row.bootTransfer.chunkRequests} chunks; rAF p95 ${row.cadence.p95Ms}ms`);
  }catch(e){row.error=e.stack;row.passed=false;throw e;}
  finally{
    try{await cdp?.send('Browser.close');}catch{}cdp?.close();
    await Promise.race([closing,pause(2000)]);if(!closed){child.kill('SIGTERM');await Promise.race([closing,pause(2000)]);}if(!closed){child.kill('SIGKILL');await Promise.race([closing,pause(3000)]);}if(!closed)throw new Error('Owned browser failed to close');
    await fs.writeFile(output,JSON.stringify(report,null,2)+'\n');
  }
}
try{for(const name of passNames)await run(name);report.passed=report.passes.every(x=>x.passed);}
catch(e){report.error=e.stack;process.exitCode=1;}
finally{report.finishedAt=new Date().toISOString();await fs.rm(owned,{recursive:true,force:true});report.ownedProfileRemoved=true;await fs.writeFile(output,JSON.stringify(report,null,2)+'\n');}
