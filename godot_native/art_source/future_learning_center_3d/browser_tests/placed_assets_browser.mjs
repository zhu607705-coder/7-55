/** Actual Chromium/WebGL acceptance of permanent preview placements.
 * Read-only diagnostics observe the scene. Actions use ordinary UI input.
 * This is not Godot gameplay, CPU-render or physical-mobile acceptance.
 */
import {chromium} from 'playwright';
import fs from 'node:fs';
import path from 'node:path';
import http from 'node:http';
import assert from 'node:assert/strict';
import {execFileSync} from 'node:child_process';
import {fileURLToPath} from 'node:url';

const root=fileURLToPath(new URL('../',import.meta.url));
const web=path.join(root,'web'),out=path.join(root,'review/placed_assets_browser');
fs.mkdirSync(out,{recursive:true});
const mime={'.html':'text/html','.js':'text/javascript','.json':'application/json','.css':'text/css','.glb':'model/gltf-binary','.wasm':'application/wasm','.png':'image/png','.jpg':'image/jpeg'};
const server=http.createServer((request,response)=>{
 try{
  let file=path.resolve(web,'.'+decodeURIComponent(new URL(request.url,'http://local').pathname));
  if(file===web)file=path.join(web,'index.html');
  if(!file.startsWith(web+path.sep)||!fs.statSync(file).isFile())throw Error('Not found');
  response.setHeader('Content-Type',mime[path.extname(file)]||'application/octet-stream');
  fs.createReadStream(file).pipe(response);
 }catch{response.writeHead(404);response.end('Not found');}
});
const rows=[],errors=[],captures=[],diagnostics=[];
let browser,base;
const check=(value,label,detail={})=>{rows.push({pass:!!value,label,...detail});assert.ok(value,label);};
const snapshot=page=>page.evaluate(()=>flcReview.snapshot());
const ready=page=>page.waitForFunction(()=>window.flcReview?.snapshot().ready&&window.flcReview.snapshot().renderedFrames>0,null,{timeout:90000});
const click=(page,id,mobile)=>page.locator(id)[mobile?'tap':'click']();
async function shot(page,label){const file=label+'.png';await page.screenshot({path:path.join(out,file)});captures.push(file);}
async function runCase(name,mobile,run){
 let context,page;
 try{
  context=await browser.newContext({viewport:mobile?{width:390,height:844}:{width:1280,height:800},isMobile:mobile,hasTouch:mobile});
  await context.tracing.start({screenshots:true,snapshots:true,sources:true});
  page=await context.newPage();page.on('pageerror',error=>errors.push(`${name}: ${error.message}`));
  await run(page,context);
 }catch(error){
  errors.push(`${name}: ${error.stack||error}`);
  if(page){await shot(page,name+'-failure').catch(()=>{});try{diagnostics.push({case:name,snapshot:await snapshot(page)});}catch{}}
 }finally{
  if(context){await context.tracing.stop({path:path.join(out,`trace-${name}.zip`)}).catch(()=>{});await context.close();}
 }
}
const config=JSON.parse(fs.readFileSync(path.join(web,'assets/photo_scene_config.json')));
const expectedBindings=['rest/photo-room-composition','xlab/workshop-candidate'];
const placed=page=>page.evaluate(()=>flcReview.placedAssets());
function identity(items){
 return items.filter(item=>expectedBindings.includes(item.id)).map(item=>({id:item.id,parts:item.parts.map(part=>({asset:part.asset,geometryUUIDs:part.geometryUUIDs,materialUUIDs:part.materialUUIDs}))}));
}
async function inspectAndReturn(page,item,mobile){
 const before=await snapshot(page);
 if(!await page.locator('#spatial-details').evaluate(node=>node.open))await click(page,'#spatial-details summary',mobile);
 await page.locator('#spatial-object').selectOption(item.spatialId);
 check((await snapshot(page)).inspect!==null,`${item.id}: ordinary object selector enters close view`);
 await shot(page,`${mobile?'mobile':'desktop'}-${item.id.replaceAll('/','-')}-inspect`);
 await click(page,'#inspect-exit',mobile);
 const after=await snapshot(page);
 check(after.inspect===null&&after.floor===before.floor&&after.room===before.room,`${item.id}: ordinary exit restores floor and room`);
}
async function rendererEvidence(page,label){
 const info=await page.evaluate(()=>{
  const canvas=document.querySelector('#scene'),gl=canvas.getContext('webgl2')||canvas.getContext('webgl');
  if(!gl)return null;
  const extension=gl.getExtension('WEBGL_debug_renderer_info');
  return {renderer:gl.getParameter(extension?extension.UNMASKED_RENDERER_WEBGL:gl.RENDERER),contextLost:gl.isContextLost(),width:canvas.width,height:canvas.height,snapshot:flcReview.snapshot()};
 });
 diagnostics.push({case:label,webgl:info});
 check(info&&!info.contextLost&&info.width>0&&info.height>0&&info.snapshot.drawCalls>0,`${label}: actual live WebGL draw calls`);
}
const expectedParts=Object.fromEntries(config.bindings.filter(b=>expectedBindings.includes(b.id)).map(b=>[b.id,b.parts.map(p=>p.asset)]));
// Independent acceptance inventory: do not derive preservation promises from config.
const loungeRequired={lounge_single_corrected:3,lounge_loose_cushion:1};
function checkVending(items,label){
 const visible=items.filter(i=>i.floor==='3'&&i.visible&&i.triangles>0);
 check(new Set(visible.flatMap(i=>i.sourceNames)).size>=29,`${label}: original vending geometry remains rendered`);
 check(visible.some(i=>i.collider?.id==='Vending machine'&&JSON.stringify(i.collider.rect)===JSON.stringify([9.654190751445087,40.20126086956522,10.504190751445089,40.95126086956522])),`${label}: original vending collision retained`);
}
const originalBindings=[];
async function residentCase(page,mobile){
 await page.goto(base+'/?view=building');await ready(page);
 const initial=await placed(page);
 for(const id of [...originalBindings,...expectedBindings])check(initial.filter(item=>item.id===id).length===1,`${id}: exactly one permanent binding, original bindings retained`);
 for(const id of expectedBindings){
  const item=initial.find(item=>item.id===id);
  check(item.visible&&item.floor==='3',`${id}: visible by default on authored 3F`);
  check(item.room===(id.startsWith('rest/')?'pantry':'xlab'),`${id}: correct source room semantics`);
  check(item.parts.length===new Set(expectedParts[id]).size,`${id}: all distinct component assets loaded`);
  check(expectedParts[id].every(asset=>item.parts.some(part=>part.asset===asset&&part.geometryUUIDs.length>0&&part.materialUUIDs.length>0)),`${id}: actual geometry and materials for every component`);
  check(JSON.stringify([...item.placementAssets].sort())===JSON.stringify([...expectedParts[id]].sort()),`${id}: exact authored component multiplicities, including two carts`);
 }
 await shot(page,`${mobile?'mobile':'desktop'}-resident-building`);
 await rendererEvidence(page,mobile?'mobile-default':'desktop-default');
 const cartGeometry=initial.find(item=>item.id==='xlab/workshop-candidate').parts.find(part=>part.asset==='photo_workshop_green_tool_cart').geometryUUIDs;
 check(cartGeometry.length===2*new Set(cartGeometry).size,'two carts reuse each LOD source geometry exactly twice');
 const lounge=initial.find(i=>i.id==='rest/photo-room-composition');for(const [asset,count] of Object.entries(loungeRequired))check(lounge.placementAssets.filter(id=>id===asset).length===count,'preserved lounge inventory '+asset);
 const seats=lounge.parts.find(p=>p.asset==='lounge_single_corrected');check(seats.geometryUUIDs.length===3*new Set(seats.geometryUUIDs).size,'three equal seats share the identical source geometry');
 const resources=identity(initial);
 await page.locator('#floor').selectOption('3');
 for(const room of ['pantry','xlab']){
  await page.locator('#room').selectOption(room);
  const inRoom=(await placed(page)).filter(item=>expectedBindings.includes(item.id)&&item.room===room);
  check(inRoom.every(item=>item.visible),`${room}: permanent assets visible through ordinary room navigation`);
  await shot(page,`${mobile?'mobile':'desktop'}-${room}-resident`);
  for(const item of inRoom)for(let cycle=0;cycle<2;cycle++)await inspectAndReturn(page,item,mobile);
  if(room==='pantry'){
   checkVending(await page.evaluate(()=>flcReview.retainedRoomFurniture()),'loaded pantry');
   await click(page,'#walk',mobile);
   check((await snapshot(page)).mode==='walk','ordinary pantry walk entry');
   await shot(page,`${mobile?'mobile':'desktop'}-pantry-walk`);
   const blocked=await page.evaluate(()=>{
    const route=[[11.35,37.15],[11.35,41],[14.67,41],[16.134,41],[15.2,41],[15.2,36.9],[11.35,36.9]],bad=[];
    for(let i=1;i<route.length;i++){const a=route[i-1],b=route[i],n=Math.ceil(Math.hypot(b[0]-a[0],b[1]-a[1])/.07);for(let k=0;k<=n;k++){const x=a[0]+(b[0]-a[0])*k/n,z=a[1]+(b[1]-a[1])*k/n;if(!flcReview.canStand(x,z))bad.push([x,z]);}}return bad;
   });
   check(blocked.length===0,'runtime pantry complete circulation loop is clear',{blocked});
   await click(page,'#overview',mobile);
  }
  if(room==='xlab'){
   const label=await page.locator('#spatial-object option').allTextContents();
   check(label.some(text=>text.includes('候选')), 'laboratory placement remains explicitly a candidate');
   check((await page.evaluate(()=>flcReview.photoAssets())).pending.some(item=>item.id==='hardware-304'),'unknown 304 mapping stays pending');
   await click(page,'#walk',mobile);
   check((await snapshot(page)).mode==='walk','ordinary laboratory walk entry');
   check(await page.evaluate(()=>flcReview.canStand(...flcReview.snapshot().position)),'laboratory walk entry is collision safe');
   const route=await page.evaluate(()=>{
    const points=[[19.508381502890174,20.31513043478261],[19.508381502890174,14],[19.508381502890174,41],[24.1,41],[24.1,14]],blocked=[];let tested=0;
    for(let i=1;i<points.length;i++){
     const a=points[i-1],b=points[i],steps=Math.ceil(Math.hypot(b[0]-a[0],b[1]-a[1])/.1);
     for(let n=0;n<=steps;n++){const x=a[0]+(b[0]-a[0])*n/steps,z=a[1]+(b[1]-a[1])*n/steps;tested++;if(!flcReview.canStand(x,z))blocked.push([x,z]);}
    }
    return {tested,blocked};
   });
   check(route.blocked.length===0,'runtime candidate aisle samples stay passable at 0.1 m spacing',route);
   check(await page.evaluate(()=>!flcReview.canStand(24.9,18)&&!flcReview.canStand(24.9,22)),'both permanent cart bodies block walking');
   const samples=await page.evaluate(()=>{
    const room=flcReview.spatial().catalog.floors['3'].rooms.find(room=>room.sourceRoomId==='xlab');
    return {bounds:room.bounds,position:flcReview.snapshot().position};
   });
   diagnostics.push({case:mobile?'mobile-lab-route':'desktop-lab-route',...samples});
   if(mobile){
    check(await page.locator('#joystick').isVisible(),'mobile laboratory exposes ordinary joystick');
    const rect=await page.locator('#joystick').boundingBox(),cdp=await page.context().newCDPSession(page);
    await cdp.send('Input.dispatchTouchEvent',{type:'touchStart',touchPoints:[{id:1,x:Math.round(rect.x+rect.width/2),y:Math.round(rect.y+rect.height/2-20)}]});
    await cdp.send('Input.dispatchTouchEvent',{type:'touchCancel',touchPoints:[]});
    check((await snapshot(page)).joystick.every(value=>value===0),'mobile touch cancellation releases laboratory movement');
   }else{
    await page.keyboard.down('w');await page.waitForTimeout(250);await page.keyboard.up('w');
    check(await page.evaluate(()=>flcReview.canStand(...flcReview.snapshot().position)),'ordinary laboratory movement remains collision safe');
   }
   await click(page,'#overview',mobile);
   check((await snapshot(page)).mode==='overview','ordinary laboratory walk exit');
  }
 }
 check(JSON.stringify(identity(await placed(page)))===JSON.stringify(resources),'repeat inspection preserves resident geometry and material identities');
 await page.locator('#floor').selectOption('4');
 check((await placed(page)).filter(item=>expectedBindings.includes(item.id)).every(item=>!item.visible),'3F placements do not leak onto 4F');
 await page.locator('#floor').selectOption('3');await page.locator('#room').selectOption('pantry');
 check((await placed(page)).filter(item=>item.id==='rest/photo-room-composition').every(item=>item.visible),'floor round trip restores permanent lounge seats');
 check(await page.evaluate(()=>document.documentElement.scrollWidth<=innerWidth),'viewport has no horizontal document overflow');
 await rendererEvidence(page,mobile?'mobile-final':'desktop-final');
}
async function fallbackCase(page,context,kind){
 const lounge=kind==='lounge',pattern=lounge?'**/models/photo_living/photo_pantry_counter/**':'**/models/photo_workshop/photo_workshop_green_tool_cart/**';
 await context.route(pattern,route=>route.abort());
 await page.goto(base+`/?floor=3&room=${lounge?'pantry':'xlab'}&mode=walk`);await ready(page);
 const items=await placed(page),missing=lounge?'rest/photo-room-composition':'xlab/workshop-candidate';
 check(!items.some(item=>item.id===missing),`${kind} failure: no half-loaded composition`);
 check(items.some(item=>item.id===(lounge?'xlab/workshop-candidate':'rest/photo-room-composition')),`${kind} failure: independent composition remains loaded`);
 for(const id of originalBindings)check(items.some(item=>item.id===id),`${kind} failure: retain original binding ${id}`);
 check((await snapshot(page)).mode==='walk'&&await page.evaluate(()=>flcReview.canStand(...flcReview.snapshot().position)),`${kind} failure: authored scene remains walkable`);
 if(lounge)checkVending(await page.evaluate(()=>flcReview.retainedRoomFurniture()),'atomic fallback');
 await shot(page,`${kind}-missing-asset-fallback`);
 await click(page,'#overview',false);
 await page.locator('#room').selectOption(lounge?'xlab':'pantry');
 await inspectAndReturn(page,(await placed(page)).find(item=>item.id===(lounge?'xlab/workshop-candidate':'rest/photo-room-composition')),false);
 await rendererEvidence(page,`${kind}-fallback`);
 await context.unroute(pattern);await page.reload();await ready(page);
 check((await placed(page)).some(item=>item.id===missing),`${kind} recovery: reload restores complete composition`);
}
const report={scope:'Actual Chromium WebGL desktop and simulated mobile, ordinary UI input; not physical-device or formal Godot gameplay acceptance.',head:process.env.TEST_HEAD_SHA||null,rows,errors,captures,diagnostics};
try{
 report.checkedOut=execFileSync('git',['rev-parse','HEAD'],{cwd:root,encoding:'utf8'}).trim();
 report.tree=execFileSync('git',['rev-parse','HEAD^{tree}'],{cwd:root,encoding:'utf8'}).trim();
 if(report.head)check(report.checkedOut===report.head,'checked-out head exactly matches requested acceptance SHA');
 await new Promise((resolve,reject)=>{server.once('error',reject);server.listen(0,'127.0.0.1',resolve);});
 base=`http://127.0.0.1:${server.address().port}`;
 browser=await chromium.launch({headless:true,...(process.env.CHROME_PATH?{executablePath:process.env.CHROME_PATH}:{})});
 report.engine=await browser.version();
 for(const mobile of [false,true])await runCase(mobile?'mobile':'desktop',mobile,page=>residentCase(page,mobile));
 for(const kind of ['lounge','laboratory'])await runCase(`${kind}-fallback`,false,(page,context)=>fallbackCase(page,context,kind));
 check(errors.length===0,'all viewport and fallback cases completed without uncaught errors');
 report.passed=true;
}catch(error){report.passed=false;report.error=String(error);process.exitCode=1;}
finally{
 fs.writeFileSync(path.join(out,'report.json'),JSON.stringify(report,null,2));
 await browser?.close();
 if(server.listening)await new Promise(resolve=>server.close(resolve));
}
