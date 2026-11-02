import fs from 'node:fs';
import assert from 'node:assert/strict';
import {canStand} from '../web/collision.js';
import {chromium} from '/private/tmp/flc-viewer-qa/node_modules/playwright-core/index.mjs';
const layout=JSON.parse(fs.readFileSync('web/assets/layout.json'));
const before=JSON.parse(fs.readFileSync('review/furniture_before_20261102_full_layout.json'));
const rows=[],check=(ok,label,details)=>{rows.push({pass:!!ok,label,details});assert.ok(ok,label);};
for(const f of ['2','4'])check(JSON.stringify(layout.floors[f])===JSON.stringify(before.floors[f]),`${f}F layout and collisions retained`);
for(const floor of Object.keys(layout.floors))for(const room of layout.floors[floor].rooms){
 const old=before.floors[floor].rooms.find(r=>r.id===room.id);
 check(['bounds','door','spawn','sourceRect'].every(k=>JSON.stringify(room[k])===JSON.stringify(old[k])),`${floor}F ${room.id} source geometry and entry retained`);
}
const room=layout.floors['3'].rooms.find(r=>r.id==='pantry'),[x0,z0,x1,z1]=room.bounds;
const inRoom=c=>c.rect&&(c.rect[0]+c.rect[2])/2>x0&&(c.rect[0]+c.rect[2])/2<x1&&(c.rect[1]+c.rect[3])/2>z0&&(c.rect[1]+c.rect[3])/2<z1;
const colliders=layout.floors['3'].colliders.filter(inRoom),sofa=colliders.find(c=>c.id==='Sofa');
const chairs=colliders.filter(c=>c.id==='Meeting chair'),cabinet=colliders.find(c=>c.id==='Pantry cabinets');
check(colliders.filter(c=>c.id==='High stool').length===6,'six stools remain the model capacity, irrespective of concept-image counts');
check(chairs.length===4&&colliders.filter(c=>c.id==='Table').length===2,'two two-seat conversation groups retained');
const gap=Math.min(...chairs.filter(c=>c.rect[0]>sofa.rect[2]).map(c=>c.rect[0]-sofa.rect[2]));
check(gap>=.7,'sofa no longer overlaps conversation chairs and leaves at least0.7m',gap);
check(cabinet.rect[1]-sofa.rect[3]>=.7,'service route behind sofa retains at least0.7m',cabinet.rect[1]-sofa.rect[3]);
const fridge=colliders.find(c=>c.id==='Refrigerator');
check(JSON.stringify(fridge)===JSON.stringify(before.floors['3'].colliders.find(c=>c.id==='Refrigerator')),'far-right refrigerator position and footprint retained');
// Flood-fill the actual observer footprint, rather than checking empty area alone.
const step=.10,nx=Math.ceil((x1-x0)/step),nz=Math.ceil((z1-z0)/step),valid=new Set();
for(let j=0;j<nz;j++)for(let i=0;i<nx;i++){const x=x0+.05+i*step,z=z0+.05+j*step;if(canStand(layout,'3',x,z))valid.add(j*nx+i);}
const start=[Math.round((room.spawn[0]-x0-.05)/step),Math.round((room.spawn[1]-z0-.05)/step)],queue=[start[1]*nx+start[0]],seen=new Set(queue);
check(valid.has(queue[0]),'entry connects to an observer-sized navigation grid');
for(let head=0;head<queue.length;head++){const key=queue[head],i=key%nx,j=Math.floor(key/nx);for(const [dx,dz] of [[1,0],[-1,0],[0,1],[0,-1]]){const a=i+dx,b=j+dz,k=b*nx+a;if(a<0||a>=nx||b<0||b>=nz||!valid.has(k)||seen.has(k))continue;seen.add(k);queue.push(k);}}
for(const [name,x,z] of [['standing table',x0+3.5,z0+2.1],['sofa front',(sofa.rect[0]+sofa.rect[2])/2,sofa.rect[1]-.4],['sink',(x0+x1)/2+.7,z1-1.12],['refrigerator',(fridge.rect[0]+fridge.rect[2])/2,fridge.rect[1]-.4]]){
 const candidates=[...seen].map(k=>[x0+.05+(k%nx)*step,z0+.05+Math.floor(k/nx)*step]);
 check(candidates.some(p=>Math.hypot(p[0]-x,p[1]-z)<.20),`observer can reach ${name} from entry`,[x,z]);
}
const browser=await chromium.launch({executablePath:'/Applications/Google Chrome.app/Contents/MacOS/Google Chrome',headless:true}),errors=[];
try{
 for(const mobile of [false,true]){
  const p=await browser.newPage({viewport:mobile?{width:390,height:844}:{width:1440,height:960},isMobile:mobile,hasTouch:mobile});
  p.on('pageerror',e=>errors.push(e.message));p.on('console',m=>{if(m.type()==='error')errors.push(m.text());});
  for(const id of ['seminar','pantry'])for(const walk of [false,true]){
   await p.goto(`http://127.0.0.1:8142/?floor=3&room=${id}${walk?'&mode=walk':''}`);await p.waitForFunction(()=>flcReview.snapshot().ready&&flcReview.snapshot().drawCalls>0);await p.waitForTimeout(200);
   check(await p.evaluate(()=>document.documentElement.scrollWidth<=innerWidth&&document.documentElement.scrollHeight<=innerHeight),`${id} ${walk?'walk':'overview'} fits ${mobile?'mobile':'desktop'}`);
   await p.screenshot({path:`review/${id}_20261102_${mobile?'mobile':'desktop'}_${walk?'walk':'overview'}.png`});
  }
  const old=await p.evaluate(()=>flcReview.snapshot().position);await p.locator('canvas').focus();await p.keyboard.down('KeyA');await p.waitForTimeout(180);await p.keyboard.up('KeyA');const now=await p.evaluate(()=>flcReview.snapshot().position);
  check(Math.hypot(now[0]-old[0],now[1]-old[1])>.05,'ordinary pantry movement works after furniture regrouping');
  check(await p.evaluate(()=>flcReview.canStand(...flcReview.snapshot().position)),'observer remains outside furniture');await p.close();
 }
 check(errors.length===0,'refined furniture has no page/console errors',errors);
 fs.writeFileSync('review/exhibition_pantry_validation.json',JSON.stringify({checks:rows.length,failures:0,rows,browser:browser.version(),scope:'Local Chrome desktop and mobile emulation; concept images are not inventory or site-survey evidence.'},null,2));console.log(`Exhibition/pantry: ${rows.length} checks passed; sofa-chair clearance ${gap.toFixed(3)}m`);
}catch(error){fs.writeFileSync('review/exhibition_pantry_validation.json',JSON.stringify({checks:rows.length,failures:1,rows,error:String(error),errors},null,2));throw error;}finally{await browser.close();}
