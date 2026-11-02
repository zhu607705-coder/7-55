import fs from 'node:fs';
import assert from 'node:assert/strict';
import crypto from 'node:crypto';
import {chromium} from '/private/tmp/flc-viewer-qa/node_modules/playwright-core/index.mjs';
const rows=[],check=(ok,label,details)=>{rows.push({pass:!!ok,label,details});assert.ok(ok,label);};
const catalog=JSON.parse(fs.readFileSync('web/assets/generated_furniture_catalog.json'));
const batch=JSON.parse(fs.readFileSync('pipeline/hi3d/batch_20261102.json'));
check(batch.assets.length===3&&batch.assets.every(a=>a.status==='succeeded'&&a.actualPoints===45)&&batch.actualTotalPoints===135,'exactly three approved successful45point jobs; no extra generation');
for(const a of batch.assets){
 const receipt=JSON.parse(fs.readFileSync(`sources/models/hi3d/${a.asset}/source_receipt.json`));
 check(receipt.taskId===a.taskId&&receipt.files.length===2&&receipt.files.every(f=>crypto.createHash('sha256').update(fs.readFileSync(`sources/models/hi3d/${a.asset}/${f.file}`)).digest('hex')===f.sha256),`${a.asset}: both original downloads preserved with exact hashes`);
}
for(const [id,a] of Object.entries(catalog.assets)){
 const manifest=JSON.parse(fs.readFileSync('web/assets/'+a.folder+'/manifest.json'));
 check(manifest.levels[2].triangles<manifest.levels[0].triangles*.4&&manifest.levels[1].triangles<manifest.levels[0].triangles*.8,`${id}: real polygon reductions at both distances`,manifest.levels.map(l=>l.triangles));
 check(manifest.levels.every(l=>l.boundsEncodingErrorM<.001&&l.textures.every(t=>Math.max(...t.size)<=1024/2**l.level)&&crypto.createHash('sha256').update(fs.readFileSync('web/assets/'+a.folder+'/'+l.file)).digest('hex')===l.sha256),`${id}: decoded envelope, texture budget and exact output hashes validated`);
}
const sofa=JSON.parse(fs.readFileSync('web/assets/models/hi3d/rest_sofa_metric/manifest.json'));check(sofa.levels[0].materials.every(m=>m.metallicFactor===0&&m.roughnessFactor>=.8&&m.baseColorTexture),'sofa uses its color texture with authored matte dielectric upholstery');
const split=JSON.parse(fs.readFileSync('review/building_split_validation.json')),layout=JSON.parse(fs.readFileSync('web/assets/layout.json'));
for(const slot of split.staticSlots){
 const cfg=catalog.slots[slot.id],m=JSON.parse(fs.readFileSync('web/assets/'+catalog.assets[cfg.asset].folder+'/manifest.json')),size=m.levels[0].size.map(v=>v*cfg.uniformScale);
 check(size[0]<=slot.target[0]+.003&&size[2]<=slot.target[1]+(slot.id.startsWith('display_table_')?.108:.003),`${slot.id}: calibrated model fits reserved furniture envelope`,size);
 const scale=cfg.uniformScale;check(m.levels.every(l=>l.size[0]*scale<=slot.target[0]+.007&&l.size[2]*scale<=slot.target[1]+(slot.id.startsWith('display_table_')?.108:.007)),`${slot.id}: all LOD silhouettes fit the reserved envelope with at most7mm edge tolerance`);
 check(slot.worldBoundsErrorM<.00001,`${slot.id}: authored failure fallback has unchanged world placement`);
}
const b=await chromium.launch({executablePath:'/Applications/Google Chrome.app/Contents/MacOS/Google Chrome',headless:true}),errors=[];
async function ready(p,room){await p.goto('http://127.0.0.1:8142/?floor=3&room='+room);await p.waitForFunction(()=>flcReview.snapshot().ready&&flcReview.snapshot().drawCalls>0);await p.waitForTimeout(180);}
async function inspect(p,id,width){
 for(const [x,y] of [[0,0],[-30,-35],[30,-35],[-40,-50],[45,-40],[0,-45],[-10,10]]){
  const t=(await p.evaluate(()=>flcReview.tools())).find(t=>t.assetId===id);const scale=width/1440;await p.mouse.click(t.x+x*scale,t.y+y*scale);await p.waitForTimeout(120);
  const value=await p.evaluate(()=>flcReview.snapshot().inspect);if(value===id)return;if(value){await p.locator('#inspect-exit').click();await p.waitForTimeout(100);}
 }
 throw Error('No visible pointer target found for '+id);
}
try{
 for(const mobile of [false,true]){
  const width=mobile?390:1440,p=await b.newPage({viewport:{width,height:mobile?844:960},isMobile:mobile,hasTouch:mobile});
  p.on('pageerror',e=>errors.push(e.message));p.on('console',m=>{if(m.type()==='error')errors.push(m.text());});
  for(const [room,id] of [['seminar','display_table_150'],['seminar','silver_exhibit'],['pantry','pantry_sofa']]){
   await ready(p,room);const assets=await p.evaluate(()=>flcReview.generatedAssets());check(assets.length===6,`${mobile?'mobile':'desktop'} ${id}: all six placements load from three paid source assets`);
   const before=await p.evaluate(()=>flcReview.snapshot());await inspect(p,id,width);
   check(await p.evaluate(id=>flcReview.snapshot().inspect===id&&flcReview.generatedAssets().find(a=>a.slot===id).level===0,id),`${mobile?'mobile':'desktop'} ${id}: ordinary pointer opens actual highest-detail model`);
   check((await p.locator('#tool-dimensions').innerText()).includes('比例参照'),`${id}: dimensions explicitly describe a model reference`);
   await p.screenshot({path:`review/hi3d_${id}_${mobile?'mobile':'front'}.png`});
   if(!mobile){await p.mouse.move(900,400);await p.mouse.down();await p.mouse.move(1280,410,{steps:16});await p.mouse.up();await p.waitForTimeout(160);await p.screenshot({path:`review/hi3d_${id}_reverse.png`});}
   check(await p.evaluate(()=>document.documentElement.scrollWidth<=innerWidth),`${id}: inspection fits ${width}px viewport`);
   await p.locator('#inspect-exit').click();const after=await p.evaluate(()=>flcReview.snapshot());check(after.inspect===null&&after.room===before.room&&JSON.stringify(after.position)===JSON.stringify(before.position),`${id}: return restores original room and observer position`);
  }
  await ready(p,'seminar');await p.screenshot({path:`review/hi3d_north_${mobile?'mobile':'overview'}.png`});await p.locator('#walk').click();await p.waitForTimeout(120);await p.screenshot({path:`review/hi3d_north_${mobile?'mobile_':''}walk.png`});
  await ready(p,'pantry');await p.screenshot({path:`review/hi3d_pantry_${mobile?'mobile':'overview'}.png`});await p.locator('#walk').click();await p.waitForTimeout(120);await p.screenshot({path:`review/hi3d_pantry_${mobile?'mobile_':''}walk.png`});
  await p.close();
 }
 check(errors.length===0,'all real Hi3D desktop/mobile routes have zero page or console errors',errors);
 for(const fault of ['silver','catalog']){
  const p=await b.newPage({viewport:{width:1280,height:800}}),pageErrors=[];p.on('pageerror',e=>pageErrors.push(e.message));
  await p.route(fault==='silver'?'**/models/hi3d/silver_covered_exhibit/lod1.draco.glb':'**/generated_furniture_catalog.json',r=>r.abort());await ready(p,'seminar');
  const assets=await p.evaluate(()=>flcReview.generatedAssets());check(fault==='silver'?assets.length===5&&!assets.some(a=>a.slot==='silver_exhibit'):assets.length===0,`${fault} download failure keeps authored furniture fallback without blocking other models`);
  await p.locator('#walk').click();await p.locator('canvas').focus();await p.keyboard.down('KeyW');await p.waitForTimeout(200);await p.keyboard.up('KeyW');
  check(await p.evaluate(()=>flcReview.snapshot().mode==='walk'&&flcReview.canStand(...flcReview.snapshot().position))&&pageErrors.length===0,`${fault} fallback remains walkable with no uncaught error`);await p.close();
 }
 fs.writeFileSync('review/hi3d_asset_validation.json',JSON.stringify({browser:b.version(),checks:rows.length,failures:0,rows},null,2)+'\n');console.log('Hi3D assets: '+rows.length+' checks passed');
}catch(e){fs.writeFileSync('review/hi3d_asset_validation.json',JSON.stringify({checks:rows.length,failures:1,rows,error:String(e),errors},null,2)+'\n');throw e;}finally{await b.close();}
