/** Actual WebGL photo integration; Node geometry tests do not replace this. */
import {chromium} from 'playwright';
import fs from 'node:fs';
import path from 'node:path';
import http from 'node:http';
import assert from 'node:assert/strict';
import {fileURLToPath} from 'node:url';
const root=fileURLToPath(new URL('../',import.meta.url)),web=path.join(root,'web'),out=path.join(root,'review/photo_scene_browser');fs.mkdirSync(out,{recursive:true});
const mime={'.html':'text/html','.js':'text/javascript','.json':'application/json','.css':'text/css','.glb':'model/gltf-binary','.wasm':'application/wasm','.png':'image/png','.jpg':'image/jpeg'};
const server=http.createServer((req,res)=>{try{let f=path.resolve(web,'.'+decodeURIComponent(new URL(req.url,'http://local').pathname));if(f===web)f=path.join(web,'index.html');if(!f.startsWith(web+path.sep)||!fs.statSync(f).isFile())throw Error();res.setHeader('Content-Type',mime[path.extname(f)]||'application/octet-stream');fs.createReadStream(f).pipe(res);}catch{res.writeHead(404);res.end();}});
const rows=[],errors=[],timingDiagnostics=[];let browser;const contexts=[];
const check=(value,label)=>{rows.push({pass:!!value,label});assert.ok(value,label);};
const snapshot=page=>page.evaluate(()=>flcReview.snapshot()),photos=page=>page.evaluate(()=>flcReview.photoAssets());
try{
 await new Promise((resolve,reject)=>server.listen(0,'127.0.0.1',resolve).on('error',reject));const base=`http://127.0.0.1:${server.address().port}`;
 browser=await chromium.launch({headless:true,...(process.env.CHROME_PATH?{executablePath:process.env.CHROME_PATH}:{})});
 for(const mobile of [false,true]){
  const context=await browser.newContext({viewport:mobile?{width:390,height:844}:{width:1280,height:800},isMobile:mobile,hasTouch:mobile});contexts.push(context);await context.tracing.start({screenshots:true,snapshots:true,sources:true});
  try{
  const p=await context.newPage();p.on('pageerror',e=>errors.push(e.message));
  await p.addInitScript(()=>{
   const d={events:[],observerRaf:[],active:false};window.__photoTiming=d;
   const state=()=>({timeMs:performance.now(),hidden:document.hidden,focused:document.hasFocus()});
   for(const type of ['visibilitychange','blur','focus','pagehide','pageshow']){
    const target=type==='visibilitychange'?document:window;
    target.addEventListener(type,()=>{d.events.push({type,...state()});if(d.events.length>32)d.events.shift();});
   }
   window.__startPhotoTiming=()=>{d.active=true;d.observerRaf=[];d.before=state();let previous=null;const sample=now=>{if(!d.active)return;d.observerRaf.push({timeMs:now,gapMs:previous===null?0:now-previous,hidden:document.hidden,focused:document.hasFocus()});if(d.observerRaf.length>64)d.observerRaf.shift();previous=now;requestAnimationFrame(sample);};requestAnimationFrame(sample);return d.before;};
  });
  await p.goto(base+'/?floor=3&room=studio_1&mode=walk');await p.waitForFunction(()=>flcReview?.snapshot().ready,null,{timeout:90000});
  const info=await photos(p);check(info.desks.length===40,'forty photo desktops '+mobile);check(info.static.length===7,'four original bindings plus two seats and one workshop composition '+mobile);for(const id of ['rest/pantry-sofa','pantry/photo_pantry_grey_roundfront_appliance','pantry/photo_pantry_white_cleartop_appliance','pantry/fridge'])check(info.static.filter(s=>s.binding===id).length===1,'original binding retained once '+id+' '+mobile);check(info.errors.length===0,'all photo assets decoded '+mobile);
  check(info.pending.some(item=>item.id==='hardware-304'),'unmapped hardware remains pending '+mobile);
  await p.screenshot({path:path.join(out,`studio-${mobile?'mobile':'desktop'}.png`)});
  if(!mobile){
   const desks=await p.evaluate(()=>flcReview.desks()),desk=desks.find(d=>d.inFront&&d.distance<3&&d.x>40&&d.x<1240&&d.y>80&&d.y<740);check(!!desk,'ordinary visible desk controller');
   await p.evaluate(()=>window.__startPhotoTiming());
   await p.mouse.click(desk.x,desk.y);await p.waitForTimeout(3600);
   const lift=await p.evaluate(()=>{window.__photoTiming.active=false;return {desks:flcReview.desks(),diagnostics:{...window.__photoTiming,after:{timeMs:performance.now(),hidden:document.hidden,focused:document.hasFocus(),snapshot:flcReview.snapshot()}}};});
   timingDiagnostics.push({viewport:'desktop',...lift.diagnostics,desks:lift.desks.map(({height,target})=>({height,target}))});
   check(lift.desks.some(d=>Math.abs(d.height-1.10)<.001),'desk reaches standing height');
   check((await p.evaluate(()=>flcReview.desks())).every(d=>d.partOffsets.every(part=>Math.abs(part.offset-(d.height-.73)*part.factor)<1e-4)),'all photo and authored parts follow lift factors');
  }
  await p.locator('#overview')[mobile?'tap':'click']();check((await snapshot(p)).mode==='overview','ordinary walk exit '+mobile);
  await p.locator('#spatial-details summary')[mobile?'tap':'click']();const id=await p.locator('#spatial-object option').evaluateAll(options=>options.find(o=>o.value&&o.textContent.includes('工位'))?.value);check(!!id,'desk object has stable selectable ID '+mobile);
  for(let i=0;i<3;i++){
   await p.locator('#spatial-object').selectOption(id);check((await snapshot(p)).inspect!==null,'desk close view '+mobile+'/'+i);
   await p.locator('#inspect-exit')[mobile?'tap':'click']();check((await snapshot(p)).inspect===null,'ordinary close view exit '+mobile+'/'+i);
  }
  await p.locator('#room').selectOption('pantry');await p.screenshot({path:path.join(out,`pantry-${mobile?'mobile':'desktop'}.png`)});
  check(await p.evaluate(()=>document.documentElement.scrollWidth<=innerWidth),'no horizontal overflow '+mobile);
  }catch(error){errors.push(`${mobile?'mobile':'desktop'} acceptance: ${error}`);}
  finally{await context.tracing.stop({path:path.join(out,`trace-${mobile?'mobile':'desktop'}.zip`)}).catch(()=>{});await context.close();}
 }
 // All optional assets absent: authored furniture must still support walking.
 const fallback=await browser.newContext({viewport:{width:1280,height:800}});contexts.push(fallback);await fallback.route('**/assets/models/photo*/**',route=>route.abort());const f=await fallback.newPage();f.on('pageerror',e=>errors.push(e.message));await f.goto(base+'/?floor=3&room=studio_1&mode=walk');await f.waitForFunction(()=>flcReview?.snapshot().ready,null,{timeout:90000});
 check((await photos(f)).desks.length===0&&(await snapshot(f)).mode==='walk','missing photo assets retain authored walkable scene');
 await fallback.unroute('**/assets/models/photo*/**');await f.reload();await f.waitForFunction(()=>flcReview?.snapshot().ready,null,{timeout:90000});check((await photos(f)).desks.length===40,'reload recovers photo assets after network failure');
 check(errors.length===0,'zero uncaught browser errors');fs.writeFileSync(path.join(out,'report.json'),JSON.stringify({passed:true,head:process.env.TEST_HEAD_SHA||null,rows,errors,timingDiagnostics,scope:'Actual Chromium WebGL desktop/simulated mobile. Not physical-device acceptance.'},null,2));
}catch(error){fs.writeFileSync(path.join(out,'report.json'),JSON.stringify({passed:false,rows,errors,timingDiagnostics,error:String(error)},null,2));throw error;}
finally{for(const c of contexts)await c.close().catch(()=>{});await browser?.close();await new Promise(resolve=>server.close(resolve));}
