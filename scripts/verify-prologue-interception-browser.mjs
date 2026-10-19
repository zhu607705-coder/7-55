import { createServer } from 'vite';
import { build } from 'esbuild';
import { spawn } from 'node:child_process';
import { readFile, writeFile, mkdir, mkdtemp, rm, realpath } from 'node:fs/promises';
import { createHash } from 'node:crypto';
import { tmpdir } from 'node:os';
import path from 'node:path';
const root=process.cwd(), artifacts=process.env.PROLOGUE_BROWSER_ARTIFACT_DIR||'/tmp/codex-755-prologue-interception-browser';
const chrome=process.env.CHROME_BIN||'/Applications/Google Chrome.app/Contents/MacOS/Google Chrome';
const temp=await mkdtemp(path.join(tmpdir(),'755-prologue-input-'));
const failures=[];let checks=0;const results=[];
const check=(ok,message)=>{checks++;if(!ok)failures.push(message);};
const sleep=ms=>new Promise(r=>setTimeout(r,ms));
function contrast(a,b){const lum=c=>{const v=c.match(/[\d.]+/g).slice(0,3).map(Number).map(x=>{x/=255;return x<=.04045?x/12.92:((x+.055)/1.055)**2.4;});return v[0]*.2126+v[1]*.7152+v[2]*.0722;};const x=lum(a),y=lum(b);return(Math.max(x,y)+.05)/(Math.min(x,y)+.05);}
let browser,server,cdp,fixture;
async function createFormalFixture(){
 const bundled=await build({stdin:{contents:`export {createDeveloperCheckpointState} from './src/modules/DeveloperChannel.ts';export {createInitialGameState} from './src/core/GameState.ts';export {SaveStore} from './src/core/SaveStore.ts';export {GAME_SAVE_KEY} from './src/core/StorageKeys.ts';`,resolveDir:root},bundle:true,platform:'node',format:'esm',write:false,logLevel:'silent'});
 const api=await import(`data:text/javascript;base64,${Buffer.from(bundled.outputFiles[0].text).toString('base64')}`);
 const values=new Map(),store=new api.SaveStore({getItem:k=>values.get(k)??null,setItem:(k,v)=>values.set(k,String(v))});
 const state=api.createDeveloperCheckpointState('c1-narrator-block');if(!store.save(state))throw Error('fixture rejected');
 const loaded=store.load(api.createInitialGameState());if(loaded.currentScene!=='ending'||loaded.actOne.phase!=='prologue'||!loaded.flags.checkinDone)throw Error('fixture normalization lost valid C1 entry');
 store.save(loaded);const envelope=values.get(api.GAME_SAVE_KEY);check(JSON.stringify(store.load(api.createInitialGameState()))===JSON.stringify(loaded),'external C1 fixture is stable through real SaveStore validation');
 return {key:api.GAME_SAVE_KEY,envelope,sha256:createHash('sha256').update(envelope).digest('hex')};
}
async function poll(fn,label){for(let i=0;i<200;i++){const r=await fn().catch(()=>null);if(r)return r;await sleep(50);}throw Error('timeout '+label);}
async function connect(url){const ws=new WebSocket(url);await new Promise((r,j)=>{ws.addEventListener('open',r,{once:true});ws.addEventListener('error',j,{once:true});});let seq=0;const pending=new Map();ws.addEventListener('message',e=>{const m=JSON.parse(String(e.data)),p=pending.get(m.id);if(!p)return;pending.delete(m.id);clearTimeout(p.timer);m.error?p.reject(Error(m.error.message)):p.resolve(m.result);});return{send(method,params={}){return new Promise((resolve,reject)=>{const id=++seq,timer=setTimeout(()=>{pending.delete(id);reject(Error('CDP '+method));},20000);pending.set(id,{resolve,reject,timer});ws.send(JSON.stringify({id,method,params}));});},close(){ws.close();}};}
const ev=async(expression)=>{const r=await cdp.send('Runtime.evaluate',{expression,returnByValue:true,awaitPromise:true});if(r.exceptionDetails)throw Error(r.exceptionDetails.text+':'+r.exceptionDetails.exception?.description);return r.result.value;};
const read=()=>ev('JSON.parse(window.render_game_to_text())');
const advance=ms=>ev(`window.advanceTime(${ms}).then(()=>new Promise(r=>setTimeout(r,0)))`);
const key=(type,key,code)=>cdp.send('Input.dispatchKeyEvent',{type,key,code,windowsVirtualKeyCode:key==='ArrowLeft'?37:key==='ArrowRight'?39:key===' '?32:13});
async function click(selector){const p=await ev(`(()=>{const e=document.querySelector(${JSON.stringify(selector)});if(!e)return null;const r=e.getBoundingClientRect();return{x:r.x+r.width/2,y:r.y+r.height/2};})()`);if(!p)throw Error('missing '+selector);await cdp.send('Input.dispatchMouseEvent',{type:'mousePressed',button:'left',clickCount:1,...p});await cdp.send('Input.dispatchMouseEvent',{type:'mouseReleased',button:'left',clickCount:1,...p});await ev('new Promise(r=>setTimeout(r,0))');}
async function snap(name){await writeFile(path.join(artifacts,name+'.png'),Buffer.from((await cdp.send('Page.captureScreenshot',{format:'png'})).data,'base64'));}
async function boot(width,height){
 await cdp.send('Emulation.setDeviceMetricsOverride',{width,height,deviceScaleFactor:1,mobile:false});
 await ev('window.__oldInputTestDocument=true;try{sessionStorage.clear()}catch{}');
 await cdp.send('Page.navigate',{url:`http://127.0.0.1:${server.config.server.port}/`});
 await poll(async()=>{const fresh=await ev('!window.__oldInputTestDocument');const s=fresh?await read():null;return s?.endingGame;},'fresh ending scene');
 await ev('document.fonts.ready.then(()=>true)');await sleep(80);
 check(!(await ev('!!document.querySelector("[data-developer-channel-root]")')),'ordinary saved C1 entry opens without a developer panel');
 await advance(8500);
}
try{
 await mkdir(artifacts,{recursive:true});fixture=await createFormalFixture();
 server=await createServer({server:{host:'127.0.0.1',port:5189,strictPort:true,fs:{allow:[root,await realpath(path.join(root,'node_modules'))]}},logLevel:'error'});await server.listen();
 const profile=path.join(temp,'profile');browser=spawn(chrome,['--headless=new','--no-sandbox','--disable-background-networking','--disable-extensions','--mute-audio','--autoplay-policy=no-user-gesture-required',`--user-data-dir=${profile}`,'--remote-debugging-port=0','about:blank'],{stdio:['ignore','ignore','ignore']});
 const active=await poll(()=>readFile(path.join(profile,'DevToolsActivePort'),'utf8'),'Chrome');
 const target=(await(await fetch(`http://127.0.0.1:${active.split('\n')[0]}/json/list`)).json()).find(t=>t.type==='page');cdp=await connect(target.webSocketDebuggerUrl);
 await cdp.send('Page.enable');await cdp.send('Runtime.enable');
 await cdp.send('Page.addScriptToEvaluateOnNewDocument',{source:`window.__vt_pending=new Set();if(sessionStorage.getItem('interception.fixture.seeded')!=='1'){localStorage.clear();sessionStorage.clear();localStorage.setItem(${JSON.stringify(fixture.key)},${JSON.stringify(fixture.envelope)});sessionStorage.setItem('interception.fixture.seeded','1');}`});
 // Actual untouched startup, stationary miss, paused hint, same-stage continue, and full-clue review.
 await boot(1280,900);await advance(7200);await advance(9000);
 let s=(await read()).endingGame;
 check(s.phase==='failed'&&s.interception.failureReason==='not_moved'&&s.blockedCount===0,'actual browser stationary window misses first target');
 const frozen=JSON.stringify(s.interception.words);await advance(8000);s=(await read()).endingGame;
 check(JSON.stringify(s.interception.words)===frozen&&s.misses===1,'failure prompt freezes actual word bodies');await snap('desktop-first-reason');
 const readingStyle=await ev(`(()=>{const c=getComputedStyle(document.querySelector('.ending-game-subtitle')),m=getComputedStyle(document.querySelector('.ending-intercept-failed')),p=getComputedStyle(document.querySelector('.ending-intercept-failed p'));return{captionBackground:c.backgroundColor,captionColor:c.color,captionShadow:c.boxShadow,modalBackground:m.backgroundColor,reasonColor:p.color};})()`);
 check(contrast(readingStyle.captionBackground,readingStyle.captionColor)>=7&&readingStyle.captionShadow==='none','scene story caption uses high-contrast opaque reading band without notification shadow');
 check(contrast(readingStyle.modalBackground,readingStyle.reasonColor)>=7,'failure explanation remains dark and readable on opaque warm paper');results.push({name:'local reading surfaces',...readingStyle});
 await click('.ending-intercept-failed button');s=(await read()).endingGame;check(s.interception.stage===1&&s.misses===1&&s.phase==='intercept','actual continue button resumes same stage without opening reset');
 await click('.ending-clue-lane button');const before=(await read()).endingGame;await advance(6000);const reviewed=(await read()).endingGame;
 check(reviewed.interception.phase==='review'&&JSON.stringify(before.interception.words)===JSON.stringify(reviewed.interception.words),'actual reread button freezes simulation');await snap('desktop-clue-review');await click('.ending-clue-review button');
 // Real page visibility transition pauses the active game, not a test-only product flag.
 const backgroundPage=await cdp.send('Target.createTarget',{url:'about:blank'});await cdp.send('Target.activateTarget',{targetId:backgroundPage.targetId});await poll(()=>ev('document.hidden'),'actual hidden page');
 const hidden=(await read()).endingGame;await advance(8000);const hiddenAfter=(await read()).endingGame;
 check(hiddenAfter.paused&&JSON.stringify(hidden.interception.words)===JSON.stringify(hiddenAfter.interception.words),'actual hidden tab pauses bodies and misses');await cdp.send('Page.bringToFront');await cdp.send('Target.closeTarget',{targetId:backgroundPage.targetId});await poll(()=>ev('!document.hidden'),'foreground page');
 // Touch drag respects rendered geometry at a scaled 390×844 viewport and cancellation clears ownership.
 await cdp.send('Emulation.setDeviceMetricsOverride',{width:390,height:844,deviceScaleFactor:1,mobile:false});
 await poll(()=>ev('document.querySelector(".phone-frame").getBoundingClientRect().width <= innerWidth-30'),'mobile shell scale');await sleep(50);
 await cdp.send('Emulation.setTouchEmulationEnabled',{enabled:true,maxTouchPoints:1});
 await ev(`window.__pointerEvidence=[];for(const t of ['pointerdown','pointermove','pointercancel','lostpointercapture'])document.addEventListener(t,e=>window.__pointerEvidence.push({type:t,target:e.target.className,x:e.clientX,y:e.clientY}),true);`);
 let rect=await ev('(()=>{const a=document.querySelector(".ending-geo-error-board").getBoundingClientRect(),f=document.querySelector(".ending-intercept-field").getBoundingClientRect();return{bx:a.x+a.width/2,by:a.y+a.height/2,x:f.x,y:f.y,w:f.width,h:f.height};})()');
 check(Math.abs(rect.w/rect.h-430/820)<.002,'rendered logical arena remains uniformly scaled 430×820');
 await cdp.send('Input.dispatchTouchEvent',{type:'touchStart',touchPoints:[{x:rect.bx,y:rect.by,id:1}]});
 await cdp.send('Input.dispatchTouchEvent',{type:'touchMove',touchPoints:[{x:rect.x+rect.w*.9,y:rect.by,id:1}]});await advance(180);
 s=(await read()).endingGame;results.push({name:'scaled touch',rect,boardX:s.interception.boardX,events:await ev('window.__pointerEvidence')});check(s.interception.boardX>215&&s.interception.boardX<=309,'real touch drag moves bounded window without teleport');
 await cdp.send('Input.dispatchTouchEvent',{type:'touchCancel',touchPoints:[]});const cancelledX=s.interception.boardX;await advance(120);
 check(Math.abs((await read()).endingGame.interception.boardX-cancelledX)<.01,'real touch cancellation stops pending movement');
 await snap('mobile-touch-bounds');
 await cdp.send('Emulation.setTouchEmulationEnabled',{enabled:false});
 // Fresh run, real keyboard strategy. Only reads public telemetry; all game actions are dispatched inputs.
 await boot(1280,900);let elapsed=8500,held=null,recoveries=0,keptProbe=false;
 for(let frame=0;frame<2200;frame++){
   const state=await read(),g=state.endingGame;if(!g)break;if(g.phase==='lock')break;
   if(g.phase==='failed'){recoveries++;await click('.ending-intercept-failed button');continue;}
   const v=g.interception,words=v.words.filter(w=>!w.contacted).sort((a,b)=>b.y-a.y),w=words[0];
   let desired=v.boardX;if(w){const wanted=w.target&&(v.stage!==3||w.text===v.missing[0]);desired=wanted?w.x+w.vx*.3:w.x<215?320:110;}
   const next=desired-v.boardX>9?'ArrowRight':desired-v.boardX < -9?'ArrowLeft':null;
   if(next!==held){if(held)await key('keyUp',held,held);if(next)await key('keyDown',next,next);held=next;}
   await advance(50);elapsed+=50;
   const after=(await read()).endingGame;
   // Deliberate same-stage failure after having one coordinate; retain it through actual button.
   if(!keptProbe&&after?.interception.stage===2&&after.interception.collected.length===1){
     if(held){await key('keyUp',held,held);held=null;}
     await key('keyDown','ArrowRight','ArrowRight');await advance(700);await key('keyUp','ArrowRight','ArrowRight');
     for(let i=0;i<180&&(await read()).endingGame.phase!=='failed';i++)await advance(100);
     const failure=(await read()).endingGame;
     if(failure.phase==='failed'){const kept=failure.interception.collected.join();await click('.ending-intercept-failed button');const resumed=(await read()).endingGame;check(kept.length>0&&resumed.interception.collected.join()===kept&&resumed.interception.stage===2,'real browser failure retains collected coordinate on same-stage continue');keptProbe=true;}
   }
 }
 if(held)await key('keyUp',held,held);
 s=(await read()).endingGame;
 check(s?.phase==='lock'&&s.blockedCount===3,'actual keyboard input completes all six target contacts and three stages');
 check(keptProbe,'coordinate retained-progress failure was exercised');
 await snap('desktop-final-lock');
 // Interrupted original final lock must reset; 1390ms cannot commit, full 1400ms can.
 await key('keyDown',' ','Space');await advance(650);await ev('window.dispatchEvent(new Event("blur"))');await advance(900);
 s=(await read()).endingGame;check(s.phase==='lock'&&s.lockProgress===0,'window blur cancels partial final hold');
 await key('keyUp',' ','Space');await key('keyDown',' ','Space');await advance(1390);s=(await read()).endingGame;
 check(s.phase==='lock'&&s.lockProgress<1,'1390ms never passes original 1400ms hold');await advance(30);await key('keyUp',' ','Space');
 check((await read()).endingGame.phase==='caught','full actual keyboard hold enters authored dialogue');await advance(9000);await advance(2000);
 const complete=await read();check(complete.currentScene==='phone_home'&&complete.actOne.phase==='friend_message_required','authored dialogue and whiteout hand off through existing controller');
 const saved=await poll(async()=>{const v=await ev(`JSON.parse(localStorage.getItem(${JSON.stringify(fixture.key)}))`);return v?.state?.currentScene==='phone_home'?v:null;},'ordinary formal save write');
 check(saved.state.currentScene==='phone_home'&&saved.state.actOne.phase==='friend_message_required','ordinary successful C1 action writes formal SaveStore envelope');
 await ev('window.__oldInputTestDocument=true');await cdp.send('Page.reload',{ignoreCache:true});
 const reloaded=await poll(async()=>{if(!(await ev('!window.__oldInputTestDocument')))return null;const v=await read();return v?.currentScene==='phone_home'?v:null;},'real formal save reload');
 check(reloaded.actOne.phase==='friend_message_required','real reload retains C1 completion without re-seeding original fixture');
 results.push({name:'keyboard six-target run',formalSaveReloadRetained:true,fixtureSha256:fixture.sha256,elapsedMs:elapsed,recoveries,keptProgress:true,controllerHandoff:complete.actOne.phase});
 // Mobile viewport recheck and pointer input mapping at left/right bounds.
 await boot(390,844);await advance(1000);
 const layout=await ev('(()=>{const r=document.querySelector(".phone-frame").getBoundingClientRect(),s=document.querySelector(".ending-scene").getBoundingClientRect();return{phone:{x:r.x,y:r.y,w:r.width,h:r.height},scene:{w:s.width,h:s.height},overflow:document.documentElement.scrollWidth>innerWidth};})()');
 check(!layout.overflow&&Math.abs(layout.phone.w/layout.phone.h-.5)<.002,'scaled mobile keeps 1:2 shell and no document overflow');await snap('mobile-clue-reading');
 // Effective old scene negative control uses exact prior source transformed in memory by Vite; no source mutation.
 await cdp.send('Page.navigate',{url:'about:blank'});await server.close();
 const old=await readFile('scripts/fixtures/prologue-interception/ending-before-text-discovery.tsx.source.txt','utf8');
 server=await createServer({server:{host:'127.0.0.1',port:5189,strictPort:true,fs:{allow:[root,await realpath(path.join(root,'node_modules'))]}},logLevel:'error',plugins:[{name:'test-only-original-ending',enforce:'pre',transform(code,id){if(id.split('?')[0].endsWith('/src/scenes/phone/P12_Ending/index.tsx'))return{code:old,map:null};}}]});await server.listen();
 await boot(1280,900);await advance(2800);let legacy=(await read()).endingGame;
 check(!legacy.interception&&legacy.misses===1,'old scene actual no-input path reaches endpoint miss without semantic targets');
 // Three original endpoint catches still reach lock, proving this control actually ran the old path rather than just parse-failing.
 for(let i=0;i<3;i++){
   for(let f=0;f<150;f++){
     legacy=(await read()).endingGame;if(legacy.phase==='lock')break;
     if(legacy.phase==='failed'){await click('.ending-intercept-failed button');continue;}
     const goal=legacy.attempt===1?24:legacy.attempt===2?78:50;
     const d=goal-legacy.paddle.xPercent;const k=d>2?'ArrowRight':d < -2?'ArrowLeft':null;
     if(k)await key('keyDown',k,k);await advance(34);if(k)await key('keyUp',k,k);
   }
   if((await read()).endingGame.phase==='lock')break;
 }
 legacy=(await read()).endingGame;
 check(legacy.phase==='lock'&&legacy.blockedCount===3,'old negative scene remains runnable and completes only its original three endpoint checks');
 results.push({name:'old exact-scene negative',fixtureSha256:createHash('sha256').update(old).digest('hex'),phase:legacy.phase,blockedCount:legacy.blockedCount,semanticTargetModelPresent:!!legacy.interception,effectiveSemanticContractFailure:!legacy.interception});
}catch(e){failures.push(e.stack||String(e));}
finally{cdp?.close();if(browser){browser.kill('SIGTERM');await sleep(200);if(browser.exitCode===null)browser.kill('SIGKILL');}await server?.close();await rm(temp,{recursive:true,force:true});}
const report={passed:!failures.length,checks,failures,results,scope:'headless real app, native Input keyboard/mouse/touch; externally serialized SaveStore fixture through ordinary storage, no product QA route',artifacts};
await mkdir(artifacts,{recursive:true});await writeFile(path.join(artifacts,'browser-report.json'),JSON.stringify(report,null,2)+'\n');
console.log(`Prologue browser: ${checks} checks, ${failures.length} failures; ${artifacts}`);if(failures.length){console.error(failures.join('\n'));process.exitCode=1;}
