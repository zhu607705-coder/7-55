/** Actual WebGL photo integration; Node geometry tests do not replace this. */
import {chromium} from 'playwright';
import fs from 'node:fs';
import path from 'node:path';
import http from 'node:http';
import assert from 'node:assert/strict';
import {fileURLToPath} from 'node:url';
const root=fileURLToPath(new URL('../',import.meta.url)),web=path.join(root,'web'),out=path.join(root,'review/workstation_browser');fs.mkdirSync(out,{recursive:true});
const mime={'.html':'text/html','.js':'text/javascript','.json':'application/json','.css':'text/css','.glb':'model/gltf-binary','.wasm':'application/wasm','.png':'image/png','.jpg':'image/jpeg'};
const server=http.createServer((req,res)=>{try{let f=path.resolve(web,'.'+decodeURIComponent(new URL(req.url,'http://local').pathname));if(f===web)f=path.join(web,'index.html');if(!f.startsWith(web+path.sep)||!fs.statSync(f).isFile())throw Error();res.setHeader('Content-Type',mime[path.extname(f)]||'application/octet-stream');fs.createReadStream(f).pipe(res);}catch{res.writeHead(404);res.end();}});
const rows=[],errors=[];let browser;const contexts=[];
const check=(value,label)=>{rows.push({pass:!!value,label});assert.ok(value,label);};
const snapshot=page=>page.evaluate(()=>flcReview.snapshot()),photos=page=>page.evaluate(()=>flcReview.photoAssets());
try{
 await new Promise((resolve,reject)=>server.listen(0,'127.0.0.1',resolve).on('error',reject));const base=`http://127.0.0.1:${server.address().port}`;
 browser=await chromium.launch({headless:true,...(process.env.CHROME_PATH?{executablePath:process.env.CHROME_PATH}:{})});
 for(const mobile of [false,true]){
  const context=await browser.newContext({viewport:mobile?{width:390,height:844}:{width:1280,height:800},isMobile:mobile,hasTouch:mobile});contexts.push(context);await context.tracing.start({screenshots:true,snapshots:true,sources:true});
  try{
  const p=await context.newPage();p.on('pageerror',e=>errors.push(e.message));await p.goto(base+'/?floor=3&room=studio_1&mode=walk');await p.waitForFunction(()=>flcReview?.snapshot().ready,null,{timeout:90000});
  await p.locator('#overview')[mobile?'tap':'click']();
  const original=await snapshot(p);
  for(let cycle=0;cycle<3;cycle++){
   await p.locator('#workstation-review')[mobile?'tap':'click']();
   const state=await p.evaluate(()=>flcReview.workstation());check(state.anchor==='flc/f3/object/office_desk008','stable real desk anchor');check(!state.settings.tools,'tools default off each entry');check(state.panelParts===2,'actual photo panel parts loaded');
   check(await p.evaluate(()=>flcReview.layers().find(f=>f.floor==='3').parts.some(m=>m.visible&&m.kind==='wall')),'architecture retained around review desk');
   await p.locator('#review-width').selectOption('.675');check((await p.evaluate(()=>flcReview.workstation())).settings.width===.675,'ordinary width selection');
   for(const id of ['review-height','review-depth']){const slider=p.locator('#'+id),box=await slider.boundingBox();if(mobile)await p.touchscreen.tap(box.x+box.width*.7,box.y+box.height/2);else await p.mouse.click(box.x+box.width*.7,box.y+box.height/2);}
   await p.locator('#review-tools').check();check((await p.evaluate(()=>flcReview.workstation())).settings.tools,'ordinary candidate checkbox');
   await p.locator('#review-lift')[mobile?'tap':'click']();await p.waitForFunction(()=>flcReview.workstation().height>1.099);check((await p.evaluate(()=>flcReview.workstation())).tools.length===3,'three actual candidate instances');
   await p.screenshot({path:path.join(out,`workstation-${mobile?'mobile':'desktop'}-${cycle}.png`)});
   await p.locator('#inspect-exit')[mobile?'tap':'click']();check((await snapshot(p)).inspect===null,'ordinary exit restores scene');check(await p.evaluate(()=>flcReview.workstation()===null),'temporary review disposed');
   check(await p.evaluate(()=>flcReview.desks().every(d=>d.height<.731)),'review-only lift restored');
  }
  check((await snapshot(p)).room===original.room,'same real room restored');
  await p.locator('#room').selectOption('pantry');await p.screenshot({path:path.join(out,`pantry-${mobile?'mobile':'desktop'}.png`)});
  check(await p.evaluate(()=>document.documentElement.scrollWidth<=innerWidth),'no horizontal overflow '+mobile);
  }catch(error){errors.push(`${mobile?'mobile':'desktop'} acceptance: ${error}`);}
  finally{await context.tracing.stop({path:path.join(out,`trace-${mobile?'mobile':'desktop'}.zip`)}).catch(()=>{});await context.close();}
 }
 // All optional assets absent: authored furniture must still support walking.
 const fallback=await browser.newContext({viewport:{width:1280,height:800}});contexts.push(fallback);await fallback.route('**/assets/models/photo*/**',route=>route.abort());const f=await fallback.newPage();f.on('pageerror',e=>errors.push(e.message));await f.goto(base+'/?floor=3&room=studio_1&mode=walk');await f.waitForFunction(()=>flcReview?.snapshot().ready,null,{timeout:90000});
 check((await photos(f)).desks.length===0&&(await snapshot(f)).mode==='walk','missing photo assets retain authored walkable scene');await f.locator('#overview').click();await f.locator('#workstation-review').click();check(await f.locator('#review-width').isDisabled(),'missing photo panel disables size controls');await f.locator('#inspect-exit').click();
 await fallback.unroute('**/assets/models/photo*/**');await f.reload();await f.waitForFunction(()=>flcReview?.snapshot().ready,null,{timeout:90000});check((await photos(f)).desks.length===40,'reload recovers photo assets after network failure');
 await f.locator('#floor').selectOption('4');await f.locator('#room').selectOption('seminar_1');const foreign=await snapshot(f);await f.locator('#workstation-review').click();await f.locator('#inspect-exit').click();check((await snapshot(f)).floor===foreign.floor&&(await snapshot(f)).room===foreign.room,'foreign-floor navigation restored by ordinary buttons');
 await fallback.route('**/review_candidates/short_metal_extension/**',route=>route.abort());await f.reload();await f.waitForFunction(()=>flcReview?.snapshot().ready,null,{timeout:90000});await f.locator('#workstation-review').click();check(await f.locator('#review-tools').isDisabled(),'partial tool library disables candidate toggle');check((await f.evaluate(()=>flcReview.workstation())).tools.length===0,'partial library shows no half-set');await f.locator('#inspect-exit').click();
 check(errors.length===0,'zero uncaught browser errors');fs.writeFileSync(path.join(out,'report.json'),JSON.stringify({passed:true,head:process.env.TEST_HEAD_SHA||null,rows,errors,scope:'Actual Chromium WebGL desktop/simulated mobile. Not physical-device acceptance.'},null,2));
}catch(error){fs.writeFileSync(path.join(out,'report.json'),JSON.stringify({passed:false,rows,errors,error:String(error)},null,2));throw error;}
finally{for(const c of contexts)await c.close().catch(()=>{});await browser?.close();await new Promise(resolve=>server.close(resolve));}
