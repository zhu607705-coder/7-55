import fs from 'node:fs';
import assert from 'node:assert/strict';
import {chromium} from '/private/tmp/flc-viewer-qa/node_modules/playwright-core/index.mjs';
const browser=await chromium.launch({executablePath:'/Applications/Google Chrome.app/Contents/MacOS/Google Chrome',headless:true});
const p=await browser.newPage({viewport:{width:1440,height:960}}),rows=[],errors=[];
p.on('pageerror',e=>errors.push(e.message));p.on('console',m=>{if(m.type()==='error')errors.push(m.text());});
const check=(ok,label,details)=>{rows.push({pass:!!ok,label,details});assert.ok(ok,label);};
const snapshot=()=>p.evaluate(()=>flcReview.snapshot());
async function ready(route){await p.goto('http://127.0.0.1:8142/'+route);await p.waitForFunction(()=>flcReview.snapshot().ready);await p.waitForTimeout(300);}
async function choose(id){await p.locator('#sources').click();await p.locator('#floor-finish').selectOption(id);await p.locator('#preview-floor-finish').click();await p.waitForTimeout(200);}
try{
 await ready('?floor=3&mode=walk');const material=await p.evaluate(()=>flcReview.floorMaterials());
 check(material.every(f=>f.surfaces.every(m=>m.hasColor&&m.hasNormal&&m.hasRoughness)),'all base floors load actual color/normal/roughness maps',material);
 check(material.every(f=>f.surfaces.every(m=>m.uvSpan[1]-m.uvSpan[0]>20)),'floor textures use repeated meter-space UVs instead of stretching one image across a building');
 check(material.find(f=>f.floor==='2').specialFinishes.some(m=>m.includes('esd_gray_green')),'electrical ESD finish remains separate');
 check(material.find(f=>f.floor==='3').specialFinishes.some(m=>m.includes('studio_charcoal')),'recording finish remains separate');
 await p.keyboard.down('d');await p.waitForTimeout(1400);await p.keyboard.up('d');await p.mouse.move(850,350);await p.mouse.down();await p.mouse.move(850,460,{steps:10});await p.mouse.up();await p.waitForTimeout(200);await p.screenshot({path:'review/floor_warm_gray_walk.png'});const before=await snapshot();
 await choose('light_gray_tile');const after=await snapshot();
 check(after.mode===before.mode&&Math.hypot(...after.position.map((v,i)=>v-before.position[i]))<.001&&Math.abs(after.yaw-before.yaw)<.001&&Math.abs(after.pitch-before.pitch)<.001,'material comparison preserves observer pose, movement mode and camera');
 check((await p.evaluate(()=>flcReview.floorMaterials().find(f=>f.floor==='3').profile))==='light_gray_tile','ordinary sample control changes current-floor finish');
 check(await p.evaluate(()=>flcReview.floorMaterials().find(f=>f.floor==='4').profile)==='warm_gray_fine','preview does not silently change another floor');
 await p.screenshot({path:'review/floor_tile_comparison_walk.png'});
 check((await p.evaluate(()=>flcReview.floorMaterials().find(f=>f.floor==='3').specialFinishes)).some(m=>m.includes('studio_charcoal')),'common-floor preview preserves dedicated room finish');
 await p.reload();await p.waitForFunction(()=>flcReview.snapshot().ready);check(await p.evaluate(()=>flcReview.floorMaterials().find(f=>f.floor==='3').profile)==='light_gray_tile','shared sample deep link restores selected preview');
 await choose('warm_gray_fine');check(await p.evaluate(()=>flcReview.floorMaterials().find(f=>f.floor==='3').surfaces.every(m=>m.material.includes('warm_gray_fine'))),'returning to photo baseline restores imported PBR material');
 const a=await snapshot();await p.keyboard.down('a');await p.waitForTimeout(300);await p.keyboard.up('a');check(Math.hypot(...(await snapshot()).position.map((v,i)=>v-a.position[i]))>.15,'ordinary movement remains available after sample dialog');
 await p.setViewportSize({width:390,height:844});await p.locator('#sources').click();await p.locator('#floor-finish').scrollIntoViewIfNeeded();check(await p.locator('#sources-dialog').evaluate(e=>e.scrollWidth<=e.clientWidth)&&await p.locator('#floor-finish').evaluate(e=>e.getBoundingClientRect().right<=innerWidth),'material choices fit narrow mobile viewport');await p.screenshot({path:'review/mobile_floor_materials.png'});
 check(errors.length===0,'PBR and candidate loads produce zero page/console errors',errors);
 fs.writeFileSync('review/floor_material_browser_validation.json',JSON.stringify({browser:browser.version(),checks:rows.length,failures:0,rows},null,2));console.log('Floor materials: '+rows.length+' checks passed');
}catch(e){fs.writeFileSync('review/floor_material_browser_validation.json',JSON.stringify({checks:rows.length,failures:1,rows,error:String(e),errors},null,2));throw e;}finally{await browser.close();}
