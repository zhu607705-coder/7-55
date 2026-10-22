// Run unmodified controller/pressure modules and the exact original Scene methods.
import {createServer} from 'vite';
import ts from 'typescript';
import {readFile,writeFile} from 'node:fs/promises';
const server=await createServer({configFile:false,appType:'custom',logLevel:'error',optimizeDeps:{noDiscovery:true,include:[]},server:{middlewareMode:true,ws:false}});
try {
  const [pressure,{createGameStore,createInitialGameState},{EventBus},{ChapterThreeQizhenLakeController}]=await Promise.all([
    server.ssrLoadModule('/src/modules/QizhenSwanChasePressureModel.ts'),server.ssrLoadModule('/src/core/GameState.ts'),server.ssrLoadModule('/src/core/EventBus.ts'),server.ssrLoadModule('/src/modules/ChapterThreeQizhenLakeController.ts')]);
  const trace=[]; let state=pressure.createQizhenSwanChasePressureState(680);
  for(let i=0;i<1200;i++) {
    const input={deltaMs:[0,8.33333333333,16,50,100,250][i%6],elapsedSeconds:i*0.025,actualGap:104+(i%91)*3.8,catchDistance:104,nearDistance:150,farDistance:360,catchReady:i>=160,progressRatio:i/1000,playerY:480+Math.sin(i/13)*160};
    const expected=pressure.stepQizhenSwanChasePressure(state,input);trace.push({source:state,input,expected});state=expected.state;
  }
  const qKeys=['active','phase','zone','vehicle','boardingStrokeCount','boardingLastSide','boardingTutorialCompleted','capsizeCount','safeSpawnId','chaseDistance','chaseBestDistance','chaseAttempts','magneticAttachmentBroken','transitionReady'];
  const project=s=>({qizhenLake:Object.fromEntries(qKeys.map(k=>[k,s.qizhenLake[k]])),rpgCheckpoint:s.rpgCheckpoint});
  const tutorials=[];
  for(const sequence of [['left','right','left','right'],['left','left','reverse_right','right','left','right','left'],['reverse_left','reverse_right','left','right','left','right']]) {
    const fresh=createInitialGameState();fresh.qizhenLake={...fresh.qizhenLake,active:true,phase:'boarding_tutorial',zone:'dock',vehicle:'on_foot',rainSafetyCleared:true,kayakEquipped:true,leftPaddleEquipped:true,rightPaddleEquipped:true};
    const store=createGameStore(fresh),controller=new ChapterThreeQizhenLakeController(store,new EventBus());const steps=[];
    controller.boardKayak(); const initial=project(store.getState());
    for(const stroke of sequence) {const reverse=stroke.startsWith('reverse_'),side=stroke.replace('reverse_','');const result=controller.recordPaddleStroke(side,reverse?'reverse':'forward');steps.push({side,reverse,result,expected:project(store.getState())});}
    tutorials.push({sequence,initial,steps});
  }
  const source=await readFile('src/scenes/rpg/QizhenLakeScene.ts','utf8');
  const ast=ts.createSourceFile('QizhenLakeScene.ts',source,ts.ScriptTarget.Latest,true,ts.ScriptKind.TS);
  const cls=ast.statements.find(s=>ts.isClassDeclaration(s)&&s.name?.text==='QizhenLakeScene');
  const methods=['updateSwanChase','resetChaseSwan'].map(name=>cls.members.find(m=>m.name?.getText(ast)===name).getText(ast));
  const constants=[...source.matchAll(/^const SWAN_CHASE_[A-Z_]+ = [^;]+;/gm)].map(m=>m[0]).join('\n');
  const compiled=ts.transpileModule(constants+'\nclass Oracle {\n'+methods.join('\n')+'\n}',{compilerOptions:{target:ts.ScriptTarget.ES2022}}).outputText;
  const Oracle=new Function('createQizhenSwanChasePressureState','stepQizhenSwanChasePressure','Phaser','QIZHEN_LAKE_WORLD',compiled+'\nreturn Oracle;')(pressure.createQizhenSwanChasePressureState,pressure.stepQizhenSwanChasePressure,{Math:{Clamp:(x,a,b)=>Math.min(b,Math.max(a,x)),Linear:(a,b,t)=>a+(b-a)*t}},{width:1672});
  const pursuits=[];
  for(const mode of ['stationary','westward']) {
    const instance=new Oracle(); instance.player={x:1280,y:680,setVelocity(){}}; instance.time={now:0}; instance.chaseSwan={update(){}};instance.reducedMotion=false;instance.emitDomain=()=>{};instance.playSwanChaseCue=()=>{};instance.triggerSwanCatch=()=>{instance.chaseFailing=true};instance.resetChaseSwan();
    const frames=[];let progress=0;
    for(let frame=0;frame<720;frame++) {
      if(mode==='westward') instance.player.x=Math.max(180,1280-frame*4);
      const old=instance.lastChaseProgressSent;instance.time.now+=1000/60;
      instance.updateSwanChase(1/60,{chaseDistance:progress});
      if(instance.lastChaseProgressSent!==old)progress=Math.min(1000,Math.max(0,Math.round(instance.lastChaseProgressSent)));
      frames.push({x:instance.player.x,y:instance.player.y,delta:1/60,swan:[instance.chaseSwanX,instance.chaseSwanY],speed:instance.chaseSwanSpeed,gap:instance.chaseActualGap,intensity:instance.chaseIntensity,pressure:instance.chasePressureState,progress,finished:instance.chaseCompleting,caught:instance.chaseFailing});
      if(instance.chaseCompleting||instance.chaseFailing)break;
    }
    pursuits.push({mode,frames});
  }
  await writeFile('godot_native/tests/fixtures/lake_live_source.json',JSON.stringify({source:'Unmodified ChapterThreeQizhenLakeController, QizhenSwanChasePressureModel and exact QizhenLakeScene.updateSwanChase/resetChaseSwan method bodies',qKeys,trace,tutorials,pursuits},null,2)+'\n');
  console.log(`Source live lake: ${trace.length} pressure cases, ${tutorials.length} tutorial traces, ${pursuits.map(p=>p.mode+':'+p.frames.length).join(', ')}`);
}finally{await server.close()}
