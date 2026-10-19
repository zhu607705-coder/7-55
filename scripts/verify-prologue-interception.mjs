import { createServer } from 'vite';
import { readFileSync, writeFileSync } from 'node:fs';
import { createHash } from 'node:crypto';
import ts from 'typescript';
const failures = []; let checks = 0;
const check = (condition, message) => { checks++; if (!condition) failures.push(message); };
const server = await createServer({ configFile: false, appType: 'custom', logLevel: 'error', optimizeDeps: {noDiscovery: true, include: []}, server: {middlewareMode:true,ws:false} });
const stages = JSON.parse(readFileSync('src/data/prologue-interception.content.json','utf8')).stages;
const report = {checks:0, failures:[], negativeControl:{}, runs:[], sourceHashes:{}};
try {
  const m = await server.ssrLoadModule('/src/scenes/phone/P12_Ending/InterceptionModel.ts');
  const { createInterceptionState:create, stepInterception:step, continueInterception:resume, sweepRectangles:sweep, WINDOW_BODY:board } = m;
  check(stages.length===3 && stages.reduce((n,s)=>n+s.targets.length,0)===6,'three semantic gates require six authored target words');
  check(JSON.stringify(stages.map(s=>s.targets))===JSON.stringify([['等'],['经度','纬度'],['旁白','还没','说完']]),'target literals and authored order preserved');
  check(!stages[0].ordered&&!stages[1].ordered&&stages[2].ordered,'only third stage imposes order');
  const a = {x:215,y:400,width:80,height:48,angle:0}, b={x:215,y:658,width:164,height:58,angle:0};
  const contact=sweep(a,0,500,b);
  check(contact && contact.time>0 && contact.time<1 && contact.ny===-1,'swept rectangle detects a whole-frame tunneling pass before terminal position');
  check(!sweep({...a,x:20},0,500,b),'a separated side lane does not become an endpoint hit');
  check(sweep({...a,x:94},0,500,b),'visible rectangle edge contact counts even with centers outside half-board');
  check(sweep(a,0,500,{...b,angle:6})?.nx!==0,'tilted board returns actual non-axis-aligned collision normal');
  check(sweep({...a,x:50,y:658},300,0,b)?.nx===-1,'horizontal side contact returns side normal');
  check(!sweep(a,0,-200,b),'word moving away cannot hit board');
  check(sweep({...a,x:400},0,500,b,200,0),'moving board participates in relative swept collision');
  let s=create();
  const clueTotal=stages[0].fragments.reduce((n,t)=>n+m.clueDuration(t),0);
  step(s,clueTotal-50); check(s.phase==='clue'&&s.words.length===0,'first full clue pass emits no falling target or penalty');
  step(s,100); check(s.phase==='playing'&&s.failures===0,'clues reveal play without awarding a target');
  step(s,400); const before=JSON.stringify(s.words), time=s.elapsedMs;
  m.toggleClueReview(s); step(s,10000,{direction:1});
  check(s.phase==='review'&&JSON.stringify(s.words)===before&&s.elapsedMs===time,'complete clue reread freezes bodies and time');
  m.toggleClueReview(s); check(s.phase==='playing','review returns exact active stage');
  const seed=(word,stage=0)=>{
    const n=create(); Object.assign(n,{phase:'playing',stage,clueIndex:3,nextSpawnMs:999999});
    n.words=[{id:1,text:word,target:stages[stage].targets.includes(word),x:215,y:590,vx:0,vy:300,width:m.wordWidth(word),height:48,angle:0,contacted:false}]; return n;
  };
  s=seed('等'); step(s,180);
  check(s.collected.join()==='等'&&s.words[0].vy<0&&s.ring!==null,'actual word contact retains word and reflects on contact');
  const reboundY=s.words[0].y;step(s,250);check(s.words[0].y<reboundY,'retained last-stage word visibly rebounds during handoff rather than freezing at contact'); check(s.collected.length===1,'one retained instance cannot count twice');
  check(s.completedStages===0,'contact does not instantly increment controller stage before presentation handoff');
  step(s,700); check(s.completedStages===1&&s.stage===1&&s.phase==='clue','one target hands off exactly one semantic stage');
  s=seed('走'); s.words[0].demonstration=true; step(s,180); check(s.failures===0&&s.collected.length===0&&s.words[0].vy<0,'untouched initial window passively demonstrates bounce without penalty or target');
  s=seed('走'); s.words[0].demonstration=true; s.moved=true; step(s,180); check(s.failure==='wrong_word','actively intercepting a background demonstration still gives semantic feedback');
  s=seed('走'); step(s,180); check(s.phase==='hint'&&s.failure==='wrong_word'&&s.collected.length===0,'wrong semantic word freezes at collision');
  const frozen=JSON.stringify(s.words); step(s,10000,{direction:1}); check(JSON.stringify(s.words)===frozen&&s.failures===1,'hint remains frozen and cannot accumulate failures');
  s=seed('纬度',1); step(s,180); check(s.collected[0]==='纬度'&&s.phase==='playing','second stage accepts reversed coordinate order');
  s.words=[{...s.words[0],id:2,text:'经度',y:590,vy:300,contacted:false}]; step(s,180); check(s.phase==='stage_complete','unordered coordinate set completes only after both');
  s=seed('还没',2); step(s,180); check(s.phase==='hint'&&s.failure==='wrong_order'&&!s.collected.length,'third stage rejects wrong original sentence order');
  s=seed('旁白',2); step(s,180); s.words=[{...s.words[0],id:2,text:'说完',y:590,vy:300,contacted:false}]; step(s,180);
  check(s.phase==='hint'&&s.collected.join()==='旁白','wrong order preserves already recovered sentence prefix');
  const stage=s.stage; resume(s); check(s.phase==='playing'&&s.stage===stage&&s.collected.join()==='旁白'&&s.words.length===0,'continue safely respawns only missing words in same stage');
  s.words=[{...seed('还没',2).words[0],text:'还没'}]; step(s,180); check(s.collected.join()==='旁白,还没','continuation accepts next required fragment');
  s=seed('走'); s.words[0].x=60; s.words[0].y=760; step(s,100); check(s.failures===0,'unblocked distractor may leave without penalty');
  s=seed('等'); s.words[0].x=60; s.words[0].y=770; step(s,20); check(s.failure==='not_moved','stationary target miss explains unmoved window');
  resume(s); s.moved=true; s.words=[{...seed('等').words[0],x:60,y:770}]; step(s,20); check(s.failure==='wrong_side','moved window on wrong side gets distinct feedback');
  for (let i=0;i<5;i++){ resume(s); s.words=[{...seed('等').words[0],x:60,y:770}]; step(s,20); }
  check(s.failures>=7&&s.stage===0&&!s.collected.length,'unlimited same-stage continues never auto-pass or restart opening');
  check(m.failureHint(s).includes('落点助视')&&m.failureHint(s).includes('等'),'third hint names missing target and offers optional assist');
  for(const input of [{direction:-1},{direction:1}]){ const x=create(); step(x,3000,input); const extent=82*Math.cos(Math.PI/30)+29*Math.sin(Math.PI/30); check(x.boardX-extent>=18-1e-8&&x.boardX+extent<=412+1e-8,'full tilted board remains inside source arena'); }
  s=create(); step(s,500,{targetX:0}); check(s.boardX>=18+82&&s.boardX!==0,'pointer target obeys continuous speed and bounds');
  s=create(); step(s,100,{targetX:0}); check(Math.abs(s.boardX-215)<=44.001&&Math.abs(s.boardAngle)<=6.001,'pointer cannot teleport, tilt limited to six degrees');
  // No-input run is an actual production-model negative, including all initial geometry.
  s=create(); let passiveBounce=false;for(let i=0;i<1400;i++){step(s,10);passiveBounce ||= s.words.some(w=>w.demonstration&&w.contacted);}
  check(passiveBounce,'real initial spawn timing visibly bounces background before target-miss prompt freezes');
  check(s.phase==='hint'&&s.failure==='not_moved'&&s.completedStages===0&&!s.collected.length,'stationary initial window cannot accidentally collect first edge-lane target');
  // Use only legal continuous movement; avoid lower distractors and aim at next required body.
  s=create(); let elapsed=0, recoveries=0, lastStages=0;
  while(s.phase!=='complete'&&elapsed<180000){
    if(s.phase==='hint'){recoveries++;resume(s);}
    const next=s.words.filter(w=>!w.contacted).sort((a,b)=>b.y-a.y)[0];
    const wanted=next && next.target && (!stages[s.stage].ordered||next.text===m.missingTargets(s)[0]);
    const targetX=next ? wanted ? next.x+next.vx*.3 : next.x<215 ? 320 : 110 : s.boardX;
    step(s,10,{targetX}); elapsed+=10;
    if(s.completedStages!==lastStages){check(s.completedStages===lastStages+1,'normal input crosses one proof gate at a time');lastStages=s.completedStages;}
  }
  check(s.phase==='complete'&&s.completedStages===3&&s.collected.join()==='旁白,还没,说完','normal continuous input finishes all semantic targets in order');
  check(elapsed>=35000&&elapsed<=110000,`observation plus actual input remains a readable minute-scale sequence (${elapsed}ms)`);
  report.runs.push({name:'normal-continuous-input',elapsedMs:elapsed,recoveries,completedStages:s.completedStages});
  const {createGameStore}=await server.ssrLoadModule('/src/core/GameState.ts');
  const {createDeveloperCheckpointState}=await server.ssrLoadModule('/src/modules/DeveloperChannel.ts');
  const {ActOneBootstrapController}=await server.ssrLoadModule('/src/modules/ActOneBootstrapController.ts');
  const {EventBus}=await server.ssrLoadModule('/src/core/EventBus.ts');
  const store=createGameStore(createDeveloperCheckpointState('c1-narrator-block')),controller=new ActOneBootstrapController(store,new EventBus());
  const unchanged=JSON.stringify(store.getState());
  for(const proof of [{interceptedCount:2,lockHeldMs:1400,failed:false},{interceptedCount:3,lockHeldMs:1399,failed:false},{interceptedCount:3,lockHeldMs:1400,failed:true}]){
    check(!controller.completeNarratorIntervention(proof)&&JSON.stringify(store.getState())===unchanged,'real controller rejects incomplete or failed proof without changing save state');
  }
  check(controller.completeNarratorIntervention({interceptedCount:s.completedStages,lockHeldMs:1400,failed:false})&&store.getState().actOne.phase==='friend_message_required','real controller accepts model three-stage proof plus original hold contract');

  // Effective old-algorithm control: execute the original fixture's path and actual terminal-hit predicate.
  const old=readFileSync('scripts/fixtures/prologue-interception/ending-before-text-discovery.tsx.source.txt','utf8');
  const pathText=old.slice(old.indexOf('function narratorPath('),old.indexOf('function toRuntimeSnapshot('));
  const oldPath=new Function('clamp',ts.transpile(pathText+'\nreturn narratorPath;', {target:ts.ScriptTarget.ES2022})) (m.clamp);
  const endpoint=oldPath(0,1);
  const predicate=old.match(/if \(Math\.abs\(runtime\.paddleX - runtime\.orbX\) <= hitRange\)/)?.[0];
  check(Boolean(predicate),'negative control extracts exact old endpoint decision rather than mirroring new model');
  const oldDecision=new Function('runtime','hitRange',`${predicate} return true; return false;`);
  const oldFalsePositive=oldDecision({paddleX:endpoint.x,orbX:endpoint.x},19);
  const oldContactIgnored=!oldDecision({paddleX:50,orbX:endpoint.x},19);
  const negativeFailures=[];
  if(oldFalsePositive)negativeFailures.push('old endpoint position awards contact without any swept collision');
  if(oldContactIgnored)negativeFailures.push('old later endpoint ignores an earlier real contact at center');
  if(!old.includes('missingTargets'))negativeFailures.push('old implementation cannot retain semantic missing targets');
  check(createHash('sha256').update(old).digest('hex')==='971d56b6b770e1c4bf3335781225f56bb97245b47983f53226af3fe15cd9d654','old oracle bytes are fixed independently of new implementation');
  check(negativeFailures.length===3,'old algorithm fails three substantive collision/semantic contracts');
  report.negativeControl={fixtureSha256:createHash('sha256').update(old).digest('hex'),effectiveFailures:negativeFailures,source:'exact old path and terminal predicate executed'};
  for(const file of ['src/data/prologue-interception.content.json','src/scenes/phone/P12_Ending/InterceptionModel.ts','src/scenes/phone/P12_Ending/index.tsx','src/scenes/phone/P12_Ending/EndingRuntime.ts','src/styles/scenes/p12-ending.css'])report.sourceHashes[file]=createHash('sha256').update(readFileSync(file)).digest('hex');
} finally {await server.close();}
report.checks=checks;report.failures=failures;report.passed=!failures.length;
const output=process.env.PROLOGUE_INTERCEPTION_REPORT||'/tmp/codex-755-prologue-interception-model.json';writeFileSync(output,JSON.stringify(report,null,2)+'\n');
console.log(`Prologue text interception: ${checks} checks, ${failures.length} failures; ${output}`);
if(failures.length){console.error(failures.join('\n'));process.exitCode=1;}
