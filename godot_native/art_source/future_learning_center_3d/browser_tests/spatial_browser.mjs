/** Real browser-only acceptance. Never substitute CPU renders or Node mocks. */
import {chromium} from 'playwright';
import fs from 'node:fs';
import path from 'node:path';
import http from 'node:http';
import assert from 'node:assert/strict';
import {execFileSync} from 'node:child_process';
import {fileURLToPath} from 'node:url';
const root=fileURLToPath(new URL('../',import.meta.url)),web=path.join(root,'web'),out=path.join(root,'review/spatial_browser');fs.mkdirSync(out,{recursive:true});
const mime={'.html':'text/html','.js':'text/javascript','.json':'application/json','.css':'text/css','.glb':'model/gltf-binary','.wasm':'application/wasm','.png':'image/png','.jpg':'image/jpeg'};
const server=http.createServer((request,response)=>{let file;try{file=path.resolve(web,'.'+decodeURIComponent(new URL(request.url,'http://local').pathname));if(file===web)file=path.join(web,'index.html');if(!file.startsWith(web+path.sep))throw Error();const stat=fs.statSync(file);if(!stat.isFile())throw Error();response.setHeader('Content-Type',mime[path.extname(file)]||'application/octet-stream');fs.createReadStream(file).pipe(response);}catch{response.writeHead(404);response.end('Not found');}});
let browser;const rows=[],errors=[],captures=[];
const check=(value,label)=>{rows.push({label,pass:!!value});assert.ok(value,label);};
const snapshot=p=>p.evaluate(()=>flcReview.snapshot());
const spatial=p=>p.evaluate(()=>flcReview.spatial());
async function shot(p,name){await p.screenshot({path:path.join(out,name+'.png')});captures.push(name+'.png');}
try{
 await new Promise((resolve,reject)=>server.listen(0,'127.0.0.1',resolve).on('error',reject));const base=`http://127.0.0.1:${server.address().port}`;
 browser=await chromium.launch({headless:true,...(process.env.CHROME_PATH?{executablePath:process.env.CHROME_PATH}:{})});
 const context=await browser.newContext({viewport:{width:1280,height:800}}),p=await context.newPage();p.on('pageerror',e=>errors.push(e.message));
 await p.goto(base+'/?view=building');await p.waitForFunction(()=>window.flcReview?.snapshot().ready,null,{timeout:90000});
 check((await spatial(p)).state.scope==='building','starts in four-layer view');check((await spatial(p)).placeholderVisible,'1F explicitly represented by pending placeholder');check((await spatial(p)).displayFloors.every(f=>f.visible),'all three real floors visible');await shot(p,'four_layers_desktop');
 await p.locator('#floor').selectOption('3');check((await spatial(p)).displayFloors.filter(f=>f.visible).map(f=>f.floor).join()==='3','select floor isolates source floor');check((await spatial(p)).displayFloors.find(f=>f.floor==='3').y===4.05,'collapse returns physical elevation');
 await p.locator('#room').selectOption('xlab');check((await spatial(p)).state.scope==='room','select existing laboratory room');await shot(p,'lab_room_desktop');
 const options=await p.locator('#spatial-object option').evaluateAll(nodes=>nodes.map(n=>n.value).filter(Boolean));check(options.length>0,'existing laboratory workstations inspectable');await p.locator('#spatial-details summary').click();await p.locator('#spatial-object').selectOption(options[0]);check((await spatial(p)).state.scope==='object','object selection enters object state');check((await snapshot(p)).inspect!==null,'object close inspection is active');await shot(p,'lab_object_desktop');await p.locator('#inspect-exit').click();check((await spatial(p)).state.scope==='room','cancel returns to selected room');
 await p.locator('#overview').click();check((await spatial(p)).state.scope==='floor','back room to floor');await p.locator('#overview').click();check((await spatial(p)).state.scope==='building','back floor to expanded building');
 await p.locator('#floor').selectOption('1');check(await p.locator('#walk').isDisabled(),'pending 1F cannot invent walk route');check((await spatial(p)).displayFloors.every(f=>!f.visible),'1F does not show borrowed source floor');await shot(p,'pending_floor_desktop');
 await p.locator('#floor').selectOption('4');check((await spatial(p)).posterCount===3,'three explicitly provisional corridor poster slots');check(await p.locator('#walk').isDisabled(),'office review does not enter office interiors');await shot(p,'office_outline_desktop');
 await p.locator('#floor').selectOption('3');await p.locator('#room').selectOption('studio_1');await p.locator('#walk').click();check((await snapshot(p)).mode==='walk','retained 3F eye-level walk');const before=await snapshot(p);check(await p.evaluate(()=>flcReview.canStand(...flcReview.snapshot().position)),'walk remains collision safe');
 const desks=await p.evaluate(()=>flcReview.desks());const desk=desks.find(d=>d.inFront&&d.distance<3&&d.x>40&&d.x<1240&&d.y>80&&d.y<740);
 if(desk){await p.mouse.click(desk.x,desk.y);await p.waitForTimeout(300);check((await p.evaluate(()=>flcReview.desks())).some(d=>d.target>1),'ordinary desk-control click preserves lift');}else{throw Error('No reachable visible desk control in retained room; acceptance requires manual adjustment of route, not skipping');}
 await p.locator('#overview').click();check((await snapshot(p)).mode==='overview','walk exits to overview');
 for(let i=0;i<5;i++){await p.locator('#explode').click();await p.locator('#floor').selectOption('2');check((await spatial(p)).displayFloors.find(f=>f.floor==='2').y===0,'round trip restores source2F '+i);}
 const mobile=await browser.newContext({viewport:{width:390,height:844},isMobile:true,hasTouch:true}),m=await mobile.newPage();m.on('pageerror',e=>errors.push(e.message));await m.goto(base+'/?view=building');await m.waitForFunction(()=>window.flcReview?.snapshot().ready,null,{timeout:90000});await shot(m,'four_layers_mobile');
 await m.locator('#floor').selectOption('3');await m.locator('#room').selectOption('xlab');await shot(m,'lab_room_mobile');check(await m.evaluate(()=>document.documentElement.scrollWidth<=innerWidth),'mobile has no horizontal page overflow');await m.locator('#overview').tap();check((await spatial(m)).state.scope==='floor','mobile ordinary return');
 await m.locator('#room').selectOption('studio_1');await m.locator('#walk').tap();check(await m.locator('#joystick').isVisible(),'mobile retained joystick');const cdp=await mobile.newCDPSession(m),rect=await m.locator('#joystick').boundingBox(),touch={id:1,x:Math.round(rect.x+rect.width/2),y:Math.round(rect.y+rect.height/2-25)};await cdp.send('Input.dispatchTouchEvent',{type:'touchStart',touchPoints:[touch]});await cdp.send('Input.dispatchTouchEvent',{type:'touchCancel',touchPoints:[]});check((await snapshot(m)).joystick.every(v=>v===0),'cancel clears joystick');await m.locator('#overview').tap();check((await snapshot(m)).mode==='overview','mobile exit after cancelled touch');await shot(m,'mobile_after_cancel');
 check(errors.length===0,'no uncaught browser errors');
 const renderer=await p.evaluate(()=>{const gl=document.querySelector('canvas').getContext('webgl2'),extension=gl.getExtension('WEBGL_debug_renderer_info');return extension?gl.getParameter(extension.UNMASKED_RENDERER_WEBGL):gl.getParameter(gl.RENDERER);});
 fs.writeFileSync(path.join(out,'report.json'),JSON.stringify({passed:true,head:process.env.TEST_HEAD_SHA||null,checkedOut:execFileSync('git',['rev-parse','HEAD'],{cwd:root,encoding:'utf8'}).trim(),tree:execFileSync('git',['rev-parse','HEAD^{tree}'],{cwd:root,encoding:'utf8'}).trim(),checks:rows.length,rows,errors,captures,engine:await browser.version(),renderer,scope:'Actual headless Chromium WebGL and ordinary pointer/touch paths. Not physical mobile/GPU hardware acceptance.'},null,2));
}catch(error){fs.writeFileSync(path.join(out,'report.json'),JSON.stringify({passed:false,rows,errors,captures,error:String(error)},null,2));throw error;}
finally{if(browser)await browser.close();await new Promise(resolve=>server.close(resolve));}
