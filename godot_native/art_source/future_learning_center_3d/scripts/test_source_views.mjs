import fs from 'node:fs';
import assert from 'node:assert/strict';
import {chromium} from '/private/tmp/flc-viewer-qa/node_modules/playwright-core/index.mjs';
const browser=await chromium.launch({executablePath:'/Applications/Google Chrome.app/Contents/MacOS/Google Chrome',headless:true});
const p=await browser.newPage({viewport:{width:1440,height:960}}),rows=[],errors=[];
p.on('pageerror',e=>errors.push(e.message));p.on('console',m=>{if(m.type()==='error')errors.push(m.text());});
const check=(ok,label)=>{rows.push({label,pass:!!ok});assert.ok(ok,label);};
async function ready(route){await p.goto('http://127.0.0.1:8142/'+route);await p.waitForFunction(()=>flcReview.snapshot().ready);await p.waitForTimeout(250);}
async function shot(name){await p.screenshot({path:'review/'+name+'.png'});}
try{
 await ready('?floor=2&room=mechatronics');await shot('mechatronics_overview');await p.locator('#walk').click();await shot('mechatronics_walk');
 check(await p.evaluate(()=>flcReview.snapshot().room==='mechatronics'&&flcReview.canStand(...flcReview.snapshot().position)),'electrical lab starts on a physically safe in-room point');
 await p.locator('#overview').click();await p.waitForTimeout(250);
 const machines=await p.evaluate(()=>flcReview.tools().filter(t=>t.assetId==='printer_h2c'));
 check(machines.length===2,'two source-requested H2C instances are exposed');
 const printer=machines.find(t=>t.inFront&&t.x>30&&t.x<1410&&t.y>90&&t.y<900);
 check(!!printer,'H2C remains visible in room overview');await p.mouse.click(printer.x,printer.y);await p.waitForTimeout(250);
 check((await p.evaluate(()=>flcReview.snapshot().inspect))==='printer_h2c','ordinary H2C geometry click opens inspection');
 check((await p.locator('#tool-dimensions').innerText()).includes('492 × 514 × 626'),'machine inspector exposes all three manufacturer dimensions');await shot('h2c_inspection');await p.locator('#inspect-exit').click();
 for(const [floor,room,name] of [['4','seminar_1','co_creation'],['4','seminar_2','conference_seminar'],['4','seminar_3','interview'],['4','focus','open_office'],['3','seminar','open_discussion'],['3','recording','recording'],['3','pantry','pantry'],['4','storage','storage']]){
  await ready(`?floor=${floor}&room=${room}`);await shot(name+'_overview');await p.locator('#walk').click();
  check(await p.evaluate(()=>flcReview.canStand(...flcReview.snapshot().position)),name+' has a safe ordinary walk entry');await shot(name+'_walk');
 }
 await p.locator('#sources').click();
 check(await p.locator('#requirements-list a').count()===2,'both actually read Feishu requirement sources are available in the viewer');
 check((await p.locator('#sources-dialog').innerText()).includes('大会议室的边界仍待核准'),'missing formal conference geometry is disclosed in the review interface');
 await p.setViewportSize({width:390,height:844});await p.waitForTimeout(200);
 check(await p.locator('#sources-dialog').evaluate(e=>e.getBoundingClientRect().left>=0&&e.getBoundingClientRect().right<=innerWidth&&e.scrollWidth<=e.clientWidth),'source dialog remains readable within mobile viewport');
 await shot('mobile_sources');await p.locator('#sources-dialog .close').click();
 check(errors.length===0,'source-specific views have no page or console errors');
 fs.writeFileSync('review/source_browser_validation.json',JSON.stringify({browser:browser.version(),checks:rows.length,failures:0,rows,errors},null,2));
 console.log('Source views: '+rows.length+' checks passed');
}catch(e){fs.writeFileSync('review/source_browser_validation.json',JSON.stringify({checks:rows.length,failures:1,rows,errors,error:String(e)},null,2));throw e;}finally{await browser.close();}
