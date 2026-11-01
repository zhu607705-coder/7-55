import fs from 'node:fs';
import assert from 'node:assert/strict';
import {canStand} from '../web/collision.js';
import {chromium} from '/private/tmp/flc-viewer-qa/node_modules/playwright-core/index.mjs';
const layout=JSON.parse(fs.readFileSync('web/assets/layout.json')),before=JSON.parse(fs.readFileSync('review/north_density_before_layout.json'));
const room=layout.floors['3'].rooms.find(r=>r.id==='seminar'),[x0,z0,x1,z1]=room.bounds,rows=[];
const inside=c=>c.rect&&(c.rect[0]+c.rect[2])/2>x0&&(c.rect[0]+c.rect[2])/2<x1&&(c.rect[1]+c.rect[3])/2>z0&&(c.rect[1]+c.rect[3])/2<z1;
const solids=layout.floors['3'].colliders.filter(inside),stands=solids.filter(c=>c.id==='Mobile exhibition tabletop'),low=solids.find(c=>c.id==='Rounded discussion display table'),right=stands.reduce((a,b)=>a.rect[0]>b.rect[0]?a:b);
const check=(ok,label,details)=>{rows.push({pass:!!ok,label,details});assert.ok(ok,label);};
function occupied(rects){let n=0;const step=.025;for(let z=z0;z<z1;z+=step)for(let x=x0;x<x1;x+=step)if(rects.some(c=>x>=c.rect[0]&&x<c.rect[2]&&z>=c.rect[1]&&z<c.rect[3]))n++;return n*step*step;}
check(JSON.stringify(before.bounds)===JSON.stringify(room.bounds),'north room outline and scale are retained');
check(stands.length===4&&!!low,'four mobile high tables and one rounded low table follow the photo');
check(solids.filter(c=>c.id==='White high stool seat').length===2,'two photographed white high stools have physical proxies');
const clearance=right.rect[0]-low.rect[2];check(clearance>=1.0,'right-side visitor route retains at least one meter between furniture envelopes',clearance);
const px=(right.rect[0]+low.rect[2])/2;
const route=[];for(let z=room.spawn[1];z>=z0+2.70;z-=.05)route.push([px,z]);check(route.every(p=>canStand(layout,'3',...p)),'visitor route is traversable at every5cm sample',{samples:route.length});
const frontPoint=[(low.rect[0]+low.rect[2])/2,low.rect[3]+.35];check(canStand(layout,'3',...frontPoint),'foreground display can be approached without entering furniture');
const baselineArea=occupied(before.colliders),newArea=occupied(solids);check(newArea>baselineArea,'photo-based furnishings occupy more floor area', {baselineArea,newArea});
const browser=await chromium.launch({executablePath:'/Applications/Google Chrome.app/Contents/MacOS/Google Chrome',headless:true}),p=await browser.newPage({viewport:{width:1440,height:960}}),errors=[];
p.on('pageerror',e=>errors.push(e.message));p.on('console',m=>{if(m.type()==='error')errors.push(m.text());});
const ready=async()=>{await p.goto('http://127.0.0.1:8142/?floor=3&mode=walk');await p.waitForFunction(()=>flcReview.snapshot().ready);await p.waitForTimeout(200);};
try{
 await ready();await p.screenshot({path:'review/north_density_after_walk.png'});let snap=await p.evaluate(()=>flcReview.snapshot());check(snap.mode==='walk'&&snap.horizontalFov<=82.01,'walk lens has a bounded horizontal field of view',snap);
 await p.locator('#overview').click();await p.waitForTimeout(200);await p.screenshot({path:'review/north_density_after_overview.png'});
 await p.setViewportSize({width:2560,height:1080});await p.locator('#walk').click();snap=await p.evaluate(()=>flcReview.snapshot());check(snap.horizontalFov<=82.01&&snap.horizontalFov>=81.9,'ultrawide screen does not expand the first-person lens beyond82degrees',snap);
 await p.setViewportSize({width:390,height:844});await p.waitForTimeout(200);snap=await p.evaluate(()=>flcReview.snapshot());check(snap.verticalFov<=60.01&&snap.verticalFov>=59.9,'portrait walk retains a usable vertical field of view');await p.screenshot({path:'review/north_density_mobile_walk.png'});
 const a=snap.position;await p.keyboard.down('d');await p.waitForTimeout(500);await p.keyboard.up('d');snap=await p.evaluate(()=>flcReview.snapshot());check(Math.hypot(...snap.position.map((v,i)=>v-a[i]))>.35,'ordinary movement works beside the denser display group');check(await p.evaluate(()=>flcReview.canStand(...flcReview.snapshot().position)),'ordinary movement remains outside furniture');
 check(errors.length===0,'north composition and camera checks have no page/console errors',errors);
 const report={checks:rows.length,failures:0,rows,roomArea:(x1-x0)*(z1-z0),baselineOccupiedArea:baselineArea,occupiedArea:newArea,mainRouteClearance:clearance,scope:'photo-based local furnishings and lens refinement; no surveyed room-dimension claim'};fs.writeFileSync('review/north_density_validation.json',JSON.stringify(report,null,2));console.log('North density: '+rows.length+' checks passed; clearance '+clearance.toFixed(3)+'m');
}catch(e){fs.writeFileSync('review/north_density_validation.json',JSON.stringify({checks:rows.length,failures:1,rows,error:String(e),errors},null,2));throw e;}finally{await browser.close();}
