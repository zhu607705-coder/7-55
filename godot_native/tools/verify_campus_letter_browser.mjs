#!/usr/bin/env node
// Ordinary pointer/touch acceptance. Runtime state is read only for observations.
import {createRequire} from 'node:module';
import fs from 'node:fs';
import path from 'node:path';
const require=createRequire(import.meta.url);
const {chromium}=require(process.env.PLAYWRIGHT_MODULE||'playwright');
const touch=process.argv.includes('--touch');
const out=path.resolve(import.meta.dirname,'../exports/verification/campus-letter');
fs.mkdirSync(out,{recursive:true});
const browser=await chromium.launch({headless:true,channel:'chrome'});
const page=await browser.newPage(touch?{viewport:{width:844,height:390},isMobile:true,hasTouch:true,deviceScaleFactor:1}:{viewport:{width:1280,height:720}});
const errors=[];
page.on('pageerror',e=>errors.push(String(e)));
page.on('console',m=>{if(m.type()==='error')errors.push(m.text())});
await page.goto(process.env.CAMPUS_LETTER_URL||'http://127.0.0.1:8795');
await page.waitForFunction(()=>window.campusLetterReady&&window.campusLetterObjects,null,{timeout:60000});
const pause=(ms=350)=>page.waitForTimeout(ms);const state=()=>page.evaluate(()=>window.campusLetterObjects);const status=()=>page.evaluate(()=>window.campusLetterStatus);
const cdp=touch?await page.context().newCDPSession(page):null;const scale=390/720,off=(844-1280*scale)/2;
const pt=(p,id=0)=>({x:off+p[0]*scale,y:p[1]*scale,id,radiusX:2,radiusY:2,force:1});
const send=(type,touchPoints)=>cdp.send('Input.dispatchTouchEvent',{type,touchPoints});
const click=async p=>{if(p.some(v=>!Number.isFinite(v)||v<0)||p[0]>1280||p[1]>720)throw Error('Target outside logical view '+p);if(!touch){await page.mouse.click(...p);await pause();return;}await send('touchStart',[pt(p)]);await pause(50);await send('touchEnd',[]);await pause()};
const drag=async(a,b)=>{if(!touch){await page.mouse.move(...a);await page.mouse.down();await page.mouse.move(...b,{steps:14});await page.mouse.up();await pause();return;}await send('touchStart',[pt(a)]);for(let i=1;i<=14;i++){await send('touchMove',[pt([a[0]+(b[0]-a[0])*i/14,a[1]+(b[1]-a[1])*i/14])]);await pause(12)}await send('touchEnd',[]);await pause()};
const target=async id=>(await state()).points[id];const shot=async n=>{await pause();await page.screenshot({path:path.join(out,(touch?'mobile3d-':'')+n+'.png')})};
const walk=async(dx,dy,ms)=>{const p=(await state()).ui.joystick;if(!touch){await page.mouse.move(...p);await page.mouse.down();await page.mouse.move(p[0]+dx,p[1]+dy,{steps:3});await pause(ms);await page.mouse.up();await pause();return;}await send('touchStart',[pt(p)]);await send('touchMove',[pt([p[0]+dx,p[1]+dy])]);await pause(ms);await send('touchEnd',[]);await pause()};
function project(p,s){const [x,y,z]=s.player,[yaw,pitch]=s.look;const d=[p[0]-x,p[1]-y-s.eye_height,p[2]-z];const c=Math.cos(yaw),si=Math.sin(yaw),cp=Math.cos(pitch),sp=Math.sin(pitch);const xx=c*d[0]-si*d[2],yy=si*sp*d[0]+cp*d[1]+c*sp*d[2],zz=si*cp*d[0]-sp*d[1]+c*cp*d[2];const f=720/(2*Math.tan(33*Math.PI/180));return [640+xx/-zz*f,360-yy/-zz*f]}
async function lookAt(p){for(let i=0;i<4;i++){const s=await state(),d=[p[0]-s.player[0],p[1]-s.player[1]-s.eye_height,p[2]-s.player[2]];let dyaw=Math.atan2(-d[0],-d[2])-s.look[0];while(dyaw>Math.PI)dyaw-=Math.PI*2;while(dyaw<-Math.PI)dyaw+=Math.PI*2;const dp=Math.atan2(d[1],Math.hypot(d[0],d[2]))-s.look[1];if(Math.abs(dyaw)<.015&&Math.abs(dp)<.015)return;const dx=Math.max(-380,Math.min(380,-dyaw/.003)),dy=Math.max(-220,Math.min(220,-dp/.003));await drag([640,220],[640+dx,220+dy]);}}
const expect=async(id)=>{let s=await status();if(!s.complete.includes(id))throw Error(id+' incomplete '+JSON.stringify({s,objects:await state()}));console.log('COMPLETE',id)};
await click((await state()).ui.library);await shot('library-first-person');await click(await target('seat3'));await shot('library-refusal');await click(await target('terminal'));await drag(await target('card'),await target('scanner'));await click(await target('seat3'));console.log('library sit',await status());await shot('library-playing');await walk(0,38,400);await lookAt([4.5,1.22,3.1]);await click(await target('terminal'));await expect('library');
await click((await state()).ui.bridge);await shot('bridge-first-person');await drag(await target('weight0'),await target('paper'));console.log('bridge rejection',await status());await click((await state()).ui.restart);await click(await target('paper'));let p=await target('left');await drag(p,[p[0]+95,p[1]]);p=await target('right');await drag(p,[p[0]-95,p[1]]);for(let i=0;i<3;i++)await drag(await target('weight'+i),await target('paper'));await expect('bridge');await shot('bridge-playing');await walk(0,-38,420);await lookAt([0,1.3,.055]);await shot('bridge-detail');
await click((await state()).ui.liuhu);await shot('lake-first-person');let h=await target('horizontal');await drag(h,[h[0]-95/.7,h[1]]);let v=await target('vertical');await drag(v,[v[0],v[1]+52/.7]);for(let i=0;i<2;i++)await click(await target('record'+i));await walk(-38,0,650);await click(await target('record2'));await expect('liuhu');await shot('lake-playing');
await click((await state()).ui.light);await shot('light-first-person');let s=await state();await drag(s.points.lamp,project([0,.65,3.4],s));console.log('lamp aligned',(await state()).state);await walk(-25,-29,1450);await pause(400);console.log('waiting',(await state()).player,(await state()).state);
await lookAt([-4,.935,2.7]);await click(await target('letter'));console.log('picked',await status());await lookAt([-2,1.19,3.04]);await click(await target('mailbox'));await expect('light');await shot('light-complete');
const beforeOverview=(await state()).player;await click((await state()).ui.overview);await shot('light-overview');await click((await state()).ui.overview);await shot('first-person-return');if((await state()).overview||(await state()).player.some((v,i)=>Math.abs(v-beforeOverview[i])>.01))throw Error('Overview did not preserve first-person position');
if(touch){await page.setViewportSize({width:390,height:844});await pause(400);await page.screenshot({path:path.join(out,'mobile3d-portrait.png')});}
fs.writeFileSync(path.join(out,touch?'3d-touch-check.json':'3d-browser-check.json'),JSON.stringify({input:touch?'Chrome emulated touch':'desktop mouse',errors,complete:(await status()).complete,actions:'All four first-person Chrome-emulated touch paths, scene joystick walking, camera look, pickup, failure recovery, overview and return'},null,2));await browser.close();console.log({errors});if(errors.length)throw Error('Browser errors: '+errors.join(' | '));
