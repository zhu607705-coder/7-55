import fs from 'node:fs';
import assert from 'node:assert/strict';
import {chromium} from '/private/tmp/flc-viewer-qa/node_modules/playwright-core/index.mjs';
const b=await chromium.launch({executablePath:'/Applications/Google Chrome.app/Contents/MacOS/Google Chrome',headless:true}),p=await b.newPage({viewport:{width:1440,height:960}}),rows=[],errors=[];
p.on('pageerror',e=>errors.push(e.message));p.on('console',m=>{if(m.type()==='error')errors.push(m.text());});
const check=(ok,label,details)=>{rows.push({pass:!!ok,label,details});assert.ok(ok,label);};
async function ready(route){await p.goto('http://127.0.0.1:8142/'+route);await p.waitForFunction(()=>flcReview.snapshot().ready);await p.waitForTimeout(300);}
async function shot(name){await p.screenshot({path:'review/'+name+'.png'});}
try{
 await ready('?floor=3&room=studio_1&mode=walk');
 const desks=await p.evaluate(()=>flcReview.desks());const control=desks.filter(d=>d.inFront&&d.distance<3&&d.x>25&&d.x<1415&&d.y>100&&d.y<900).sort((a,b)=>a.distance-b.distance)[0];
 check(!!control,'physical desk controller can be approached at real scale',desks.slice(0,4));await shot('ergonomic_office_walk');
 await p.mouse.click(control.x,control.y);await p.waitForTimeout(150);
 check(await p.evaluate(()=>flcReview.desks().some(d=>d.target===1.10)),'ordinary keypad click starts seated-to-standing lift');
 await p.waitForFunction(()=>flcReview.desks().some(d=>d.height>=1.099),null,{timeout:20000});
 const raised=await p.evaluate(()=>flcReview.desks().find(d=>d.height>=1.099));
 check(raised.partOffsets.filter(p=>p.factor===0).every(p=>Math.abs(p.offset)<.00001),'feet and fixed outer columns stay on the floor');
 check(raised.partOffsets.filter(p=>p.factor===.5).every(p=>Math.abs(p.offset-.185)<.001),'intermediate telescoping columns move half stroke');
 check(raised.partOffsets.filter(p=>p.factor===1).every(p=>Math.abs(p.offset-.37)<.001),'desktop, monitor, keyboard and keypad all move full stroke');await shot('standing_desk_raised');
 check(await p.evaluate(()=>flcReview.canStand(...flcReview.snapshot().position)),'desk lift preserves a safe observer position');
 await p.mouse.click(raised.x,raised.y);await p.waitForFunction(()=>flcReview.desks().every(d=>d.height<.731),null,{timeout:20000});check(true,'same physical controller lowers desk again');
 await p.locator('#overview').click();await p.waitForTimeout(300);
 const chair=(await p.evaluate(()=>flcReview.tools())).find(t=>t.assetId==='office_chair');check(!!chair,'representative ergonomic chair supports close inspection');
 await p.mouse.click(chair.x,chair.y);await p.waitForTimeout(250);check((await p.evaluate(()=>flcReview.snapshot().inspect))==='office_chair','ordinary chair click opens exact-scale geometry inspection');check(await p.evaluate(()=>flcReview.layers().filter(r=>r.visible).every(r=>r.parts.every(m=>m.kind==='floor'||!m.visible))),'chair close view removes surrounding dividers and desks from its sightline');await shot('ergonomic_chair_inspection');
 await p.setViewportSize({width:390,height:844});await p.waitForTimeout(300);check(await p.evaluate(()=>document.documentElement.scrollWidth<=innerWidth),'chair inspection fits mobile viewport');await shot('mobile_chair_inspection');await p.locator('#inspect-exit').click();
 await p.setViewportSize({width:1440,height:960});await ready('?floor=3&mode=walk');check(await p.evaluate(()=>flcReview.snapshot().room==='seminar'),'existing floor-only 3F walk link enters the photo-referenced north area');await p.mouse.move(900,430);await p.mouse.down();await p.mouse.move(900,310,{steps:10});await p.mouse.up();await p.waitForTimeout(200);await shot('north_exhibition_high_windows');
 check(await p.evaluate(()=>flcReview.snapshot().pitch>.25),'ordinary first-person look reveals upper windows and high ceiling');
 await ready('?floor=4');const overview=await p.evaluate(()=>flcReview.snapshot());check(overview.drawCalls<500,'shared instancing keeps complete-floor draw calls bounded',overview);check(errors.length===0,'new furniture and photo area have no page/console errors',errors);
 fs.writeFileSync('review/furniture_browser_validation.json',JSON.stringify({browser:b.version(),checks:rows.length,failures:0,rows},null,2));console.log('Furniture: '+rows.length+' checks passed');
}catch(e){fs.writeFileSync('review/furniture_browser_validation.json',JSON.stringify({checks:rows.length,failures:1,rows,error:String(e),errors},null,2));throw e;}finally{await b.close();}
