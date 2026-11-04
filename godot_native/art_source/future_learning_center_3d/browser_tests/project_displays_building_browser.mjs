/** Real GLB scene acceptance. All state changes use ordinary UI/input events. */
import {chromium} from 'playwright';
import fs from 'node:fs';
import path from 'node:path';
import http from 'node:http';
import assert from 'node:assert/strict';
import {execFileSync} from 'node:child_process';
import {fileURLToPath} from 'node:url';
const root=fileURLToPath(new URL('../',import.meta.url)),web=path.join(root,'web'),out=path.join(root,'review/project_displays_building');
fs.mkdirSync(out,{recursive:true});
const mime={'.html':'text/html','.js':'text/javascript','.json':'application/json','.css':'text/css','.glb':'model/gltf-binary','.wasm':'application/wasm','.png':'image/png','.jpg':'image/jpeg'};
const server=http.createServer((req,res)=>{try{let file=path.resolve(web,'.'+decodeURIComponent(new URL(req.url,'http://local').pathname));if(file===web)file=path.join(web,'index.html');if(!file.startsWith(web+path.sep)||!fs.statSync(file).isFile())throw Error('Invalid path');res.setHeader('Content-Type',mime[path.extname(file)]||'application/octet-stream');fs.createReadStream(file).pipe(res);}catch{res.writeHead(404);res.end('Not found');}});
const report={head:process.env.TEST_HEAD_SHA||null,checkedOut:execFileSync('git',['rev-parse','HEAD'],{cwd:root,encoding:'utf8'}).trim(),tree:execFileSync('git',['rev-parse','HEAD^{tree}'],{cwd:root,encoding:'utf8'}).trim(),scope:'Actual building GLBs in Chromium. Ordinary mouse/touch input; no forced clicks, camera injection, fixture geometry or direct display opening. Mobile is an emulated viewport, not physical hardware.',runs:[]};
const save=()=>fs.writeFileSync(path.join(out,'report.json'),JSON.stringify(report,null,2));
async function bounded(promise,label,ms=15000){let timer;try{return await Promise.race([promise,new Promise((_,reject)=>{timer=setTimeout(()=>reject(Error(label+' exceeded '+ms+' ms')),ms);})]);}finally{clearTimeout(timer);}}
const diag=(p,options={geometry:false})=>bounded(p.evaluate(options=>flcReview.projectDisplays(options),options),'read-only display diagnostics');
const snap=p=>bounded(p.evaluate(()=>flcReview.snapshot()),'scene snapshot');
let browser;
try{
 if(report.head)assert.equal(report.checkedOut,report.head,'Browser acceptance checks out the exact requested head');
 await new Promise(resolve=>server.listen(0,'127.0.0.1',resolve));
 browser=await chromium.launch({headless:true,...(process.env.CHROME_PATH?{executablePath:process.env.CHROME_PATH}:{})});
 for(const [name,viewport,touch] of [['desktop',{width:1280,height:800},false],['mobile',{width:390,height:844},true]]){
  const context=await browser.newContext({viewport,isMobile:touch,hasTouch:touch}),p=await context.newPage(),run={name,passed:false,checks:[],captures:[],errors:[],searches:[],segments:[],phase:'created'};report.runs.push(run);save();
  const phase=label=>{run.phase=label;run.phaseStarted=new Date().toISOString();save();};
  await context.tracing.start({screenshots:true,snapshots:true,sources:true});
  p.on('pageerror',e=>{run.errors.push(e.message);save();});
  const check=(value,label,details={})=>{run.checks.push({label,pass:!!value,...details});save();assert.ok(value,label);};
  const shot=async label=>{const file=name+'-'+label+'.png';await p.screenshot({path:path.join(out,file)});run.captures.push(file);save();};
  const click=async target=>{if(touch)await p.touchscreen.tap(target.x,target.y);else await p.mouse.click(target.x,target.y);};
  const button=async locator=>touch?locator.tap():locator.click();
  const settle=async()=>{
   await p.evaluate(()=>{window.__displayCameraSettled={last:null,count:0};});
   await p.waitForFunction(()=>{const now=flcReview.projectDisplays({geometry:false}).camera,cache=window.__displayCameraSettled,values=[...now.position,...now.quaternion];cache.count=cache.last&&values.every((v,i)=>Math.abs(v-cache.last[i])<.00001)?cache.count+1:0;cache.last=values;return cache.count>=3;},{},{polling:100,timeout:10000});
  };
  const drag=async(dx,dy=0)=>{
   const x=viewport.width*.7,y=viewport.height*.48;
   if(touch){const cdp=await context.newCDPSession(p);await cdp.send('Input.dispatchTouchEvent',{type:'touchStart',touchPoints:[{id:1,x,y}]});for(let i=1;i<=8;i++)await cdp.send('Input.dispatchTouchEvent',{type:'touchMove',touchPoints:[{id:1,x:x+dx*i/8,y:y+dy*i/8}]});await cdp.send('Input.dispatchTouchEvent',{type:'touchEnd',touchPoints:[]});await cdp.detach();}
   else{await p.mouse.move(x,y);await p.mouse.down();await p.mouse.move(x+dx,y+dy,{steps:8});await p.mouse.up();}
   await settle();
  };
  const turn=async()=>{const s=await snap(p);await drag(-(s.mode==='walk'?196:Math.min(120,viewport.width*.3)));};
  const lookDown=async pitch=>{const s=await snap(p);await drag(0,(s.pitch-pitch)/.004);};
  const stepAside=async()=>{
   phase('ordinary short collision-constrained strafe');
   if(touch){const rect=await p.locator('#joystick').boundingBox();assert.ok(rect,'walk joystick exists');const cdp=await context.newCDPSession(p),x=rect.x+rect.width/2,y=rect.y+rect.height/2;await cdp.send('Input.dispatchTouchEvent',{type:'touchStart',touchPoints:[{id:1,x,y}]});await cdp.send('Input.dispatchTouchEvent',{type:'touchMove',touchPoints:[{id:1,x:x+25,y}]});await p.waitForTimeout(350);await cdp.send('Input.dispatchTouchEvent',{type:'touchEnd',touchPoints:[]});await cdp.detach();}
   else{await p.locator('#scene').focus();await p.keyboard.down('KeyD');await p.waitForTimeout(350);await p.keyboard.up('KeyD');}
   check(await p.evaluate(()=>flcReview.canStand(...flcReview.snapshot().position)),'control survey keeps collision-safe position');
  };
  const scan=async(options)=>{
   let cursor=0;
   do{
    phase('geometry page '+JSON.stringify({...options,cursor}));
    const d=await diag(p,{geometry:true,...options,cursor,limit:3});
    run.searches.push({options,cursor,rayCount:d.rayCount,candidates:d.candidateCount,nextCursor:d.nextCursor,visible:d.targets.map(t=>t.id),occluded:d.occluded.length});save();
    const match=options.kind==='control'?d.controls[0]:options.occlusion?d.occluded[0]:d.targets[0];
    if(match)return match;
    cursor=d.nextCursor;
   }while(cursor!==null);
   return null;
  };
  const find=async(kind,exclude=new Set(),options={})=>{
   for(let i=0;i<10;i++){
    phase('survey '+kind+' view '+i);
    const target=await scan({kind,excludeIds:[...exclude],...options});if(target)return target;
    await turn();
   }
   throw Error('No ordinarily visible '+kind+' target after bounded canvas survey');
  };
  const openClose=async(target,label,escape=false)=>{
   // Geometry diagnostics select a point, but only browser input opens the dialog.
   phase(label+' opening');
   assert.ok(target,label+' has an actual visible geometry target');
   const before=await diag(p),s=await snap(p);await click(target);
   await p.locator('#project-display-dialog').waitFor({state:'visible'});
   check((await diag(p)).active===target.id,label+' opens the exact raycast owner',{id:target.id,point:[target.x,target.y],nearest:target.nearest});
   check(await p.locator('#project-display-content a').count()===0,label+' does not invent project URLs');
   await shot(label);
   phase(label+' closing');
   if(escape)await p.keyboard.press('Escape');else await button(p.getByRole('button',{name:'关闭项目展示'}));
   await p.locator('#project-display-dialog').waitFor({state:'hidden'});
   await p.waitForFunction(()=>flcReview.projectDisplays({geometry:false}).active===null);
   const after=await diag(p),a=await snap(p);
   check(after.active===null,label+' clears display ownership');
   check(a.mode===s.mode&&a.room===s.room&&JSON.stringify(a.position)===JSON.stringify(s.position),label+' restores the same walk/room state');
   check(before.camera.position.every((v,i)=>Math.abs(v-after.camera.position[i])<.001)&&before.camera.quaternion.every((v,i)=>Math.abs(v-after.camera.quaternion[i])<.001),label+' retains camera');
   check(a.joystick.every(v=>v===0),label+' clears joystick');
  };
  const load=async query=>{
   phase('load actual building '+query);
   await p.goto('http://127.0.0.1:'+server.address().port+'/?'+query);
   await p.waitForFunction(()=>window.flcReview?.snapshot().ready,null,{timeout:90000});
   const photo=await p.evaluate(()=>flcReview.photoAssets());check(photo.desks.length===40&&photo.errors.length===0,'actual forty-workstation GLBs loaded');
   await settle();
  };
  const segment=async(name,body)=>{
   const result={name,passed:false};run.segments.push(result);phase(name+' start');
   try{await body();result.passed=true;}
   catch(error){result.error=String(error);result.failedPhase=run.phase;save();try{await bounded(shot(name+'-failure'),name+' failure screenshot',5000);}catch(captureError){result.captureError=String(captureError);}}
   finally{save();}
  };
  try{
   await segment('monitor-displays',async()=>{
    await load('floor=3&room=studio_1');
   const first=await find('monitor');await openClose(first,'overview-monitor');
   const second=await find('monitor',new Set([first.id]));await openClose(second,'second-monitor',true);
   check(first.id!==second.id,'different monitor instances retain different owners');
   await button(p.locator('#walk'));check((await snap(p)).mode==='walk','ordinary walk entry');
   const walkScreen=await find('monitor');await openClose(walkScreen,'walk-monitor');
   });
   await segment('desk-control-and-lift',async()=>{
    await load('floor=3&room=studio_1&mode=walk');
   // Search an actual desk-edge control. Require the nearest ray hit to be that control.
   let control;
   // Survey actual control geometry, with normal downward look and a short legal strafe.
   // Yaw-only rotation leaves a fixed anchor's world-space occlusion unchanged.
   for(let position=0;position<2&&!control;position++){
    for(const pitch of [-.14,-.42,-.70]){
     await lookDown(pitch);
     for(let heading=0;heading<8&&!control;heading++){control=await scan({kind:'control'});if(!control)await turn();}
     if(control)break;
    }
    if(!control&&position===0){await lookDown(-.14);await stepAside();}
   }
   check(!!control,'visible reachable desk-edge control located');
   const old=control.target;await click(control);
   await p.waitForFunction(({id,old})=>flcReview.projectDisplays({geometry:false,controls:true,targetId:id}).controls.some(c=>c.target!==old),{id:control.id,old},{timeout:5000});
   check(!await p.locator('#project-display-dialog').isVisible(),'desk-edge control raises desk without opening display');
   // Return the gaze to screen height through ordinary input while the desk moves.
   await lookDown(-.14);
   // Use a fresh projection after the lift has moved the actual instanced screen.
   await p.waitForTimeout(400);
   const lifted=await scan({kind:'monitor',targetId:control.id});
   check(!!lifted,'lifted desk screen remains visible and targetable');
   await openClose(lifted,'lifted-monitor');
   await openClose(await scan({kind:'monitor',targetId:control.id}),'reopened-monitor',true);
   });
   await segment('wall-occlusion',async()=>{
    await load('floor=3&room=studio_1&mode=walk');
   // Walk mode retains full-height walls. Require the same ray to intersect a wall
   // first and the actual display geometry behind it; no artificial blocker is inserted.
   let blocked;
   for(let i=0;i<12&&!blocked;i++){blocked=await scan({kind:'monitor',occlusion:true});if(!blocked)await turn();}
   check(!!blocked,'real wall-occluded display sample located');
   await click(blocked);await p.waitForTimeout(150);
   check(!await p.locator('#project-display-dialog').isVisible(),'foreground wall prevents display opening',{blocked});
   await shot('wall-occlusion');
   });
   await segment('corridor-poster',async()=>{
    await load('floor=4');
   const poster=await find('poster');await openClose(poster,'corridor-poster');
   });
   check(run.errors.length===0,'no uncaught browser errors');
   run.passed=run.segments.every(segment=>segment.passed);phase(run.passed?'passed':'one or more segments failed');
  }catch(error){
   run.failedPhase=run.phase;run.error=String(error);phase('failure recovery');
   // Never run geometry again while diagnosing a timeout. Persist the original failure first.
   try{run.last=await bounded(p.evaluate(()=>flcReview.projectDisplays({geometry:false})),'lightweight failure snapshot',2000);save();}catch(readError){run.failureReadError=String(readError);save();}
   try{await bounded(shot('failure'),'failure screenshot',5000);}catch(shotError){run.failureScreenshotError=String(shotError);save();}
  }finally{
   try{await bounded(context.tracing.stop({path:path.join(out,name+'-trace.zip')}),'trace finalization',10000);}catch(error){run.traceError=String(error);save();}
   try{await bounded(context.close(),'viewport cleanup',10000);}catch(error){run.cleanupError=String(error);save();}
   save();
  }
 }
 assert.ok(report.runs.every(r=>r.passed),'Actual building display acceptance must pass independently for both viewports');
}finally{save();try{if(browser)await bounded(browser.close(),'browser cleanup',10000);}finally{server.close();}}
