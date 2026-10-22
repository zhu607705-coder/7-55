// Offline source-method oracle: no browser, Godot process, imported assets or
// native implementation is used to produce these victory samples.
import assert from 'node:assert/strict';
import fs from 'node:fs';
import path from 'node:path';
import {fileURLToPath} from 'node:url';

const root=path.resolve(path.dirname(fileURLToPath(import.meta.url)),'../..');
const sourceRoot=process.env.CANTEEN_SOURCE_ROOT||root;
const read=relative=>fs.readFileSync(path.join(sourceRoot,relative),'utf8');
const sceneSource=read('src/scenes/rpg/CanteenInteriorScene.ts');
const runtimeSource=read('src/scenes/rpg/CanteenDefenseRuntime.ts');
const content=JSON.parse(read('src/data/chapter3-canteen.content.json'));
function section(source,start,end){
  const at=source.indexOf(start);assert.ok(at>=0,`source method exists: ${start}`);
  const stop=source.indexOf(end,at+start.length);assert.ok(stop>at,`source method ends: ${end}`);
  return source.slice(at,stop);
}
const victory=section(sceneSource,'  private animateDefenseVictory(','  private animateWrongBlock(')
  .replace('private animateDefenseVictory(onComplete: () => void): void','animateDefenseVictory(onComplete)');
const finish=section(sceneSource,'  private finishDefense(): void','  private flashDefenseRoute(')
  .replace('private finishDefense(): void','finishDefense()');
const dialogue=section(sceneSource,'  private queueDialogue(','  private showFeedback(')
  .replace('private queueDialogue(','queueDialogue(').replace('lines: readonly string[]','lines')
  .replace('onComplete?: () => void','onComplete').replace('): void {',') {')
  .replace('private dialogueToneFor(text: string): GameSubtitleTone','dialogueToneFor(text)');
const cue=section(sceneSource,'    if (name === "canteen_defense_completed") {','    if (name === "canteen_exit_dark_clue_read") {');
const destroy=section(runtimeSource,'  destroy(): void {','  getDebugSnapshot(): {')
  .replace('destroy(): void','destroy()').replace(' as Phaser.Physics.Arcade.Body | null | undefined','');
const update=section(runtimeSource,'  update(\n','  pauseAfterFailure(): void {')
  .replace('deltaMs: number','deltaMs').replace('inputDirection: Phaser.Math.Vector2','inputDirection')
  .replace('dashRequested: boolean','dashRequested').replace('): Phaser.Math.Vector2 {',') {');
const constants=Object.fromEntries([...runtimeSource.matchAll(/const ([A-Z_]+) = ([\d_]+);/g)].map(m=>[m[1],Number(m[2].replaceAll('_',''))]));
const startDefense=section(sceneSource,'  private startDefense(): void','  private finishDefense(): void');
const cameraSetup=section(startDefense,'    const camera = this.cameras.main;','    this.defenseRuntime = new CanteenDefenseRuntime(');
const exit=section(sceneSource,'  private beginCanteenExit(): void','  private triggerPointerTarget(')
  .replace('private beginCanteenExit(): void','beginCanteenExit()');
const worldSource=read('src/scenes/rpg/CanteenInteriorModel.ts');
const worldLiteral=worldSource.match(/export const CANTEEN_INTERIOR_WORLD = (\{[\s\S]*?\}) as const;/)[1];
const world=new Function(`return (${worldLiteral})`)();
const doorLiteral=worldSource.match(/export const CANTEEN_SOUTHEAST_EXIT_DOOR = (\{[\s\S]*?\}) as const;/)[1];
const door=new Function(`return (${doorLiteral})`)();
const resolution=read('src/scenes/rpg/RpgRenderResolution.ts');
const logical=['WIDTH','HEIGHT'].map(axis=>Number(resolution.match(new RegExp(`export const RPG_LOGICAL_${axis} = (\\d+);`))[1]));
const doorSource=read('src/scenes/rpg/RpgInteriorDoor.ts');
const doorDuration=Number(section(sceneSource,'    this.exitDoor = new RpgInteriorDoorRuntime(this, {','      depth:').match(/durationMs: (\d+)/)[1]);
const passableProgress=Number(doorSource.match(/const DEFAULT_PASSABLE_PROGRESS = ([\d.]+);/)[1]);
const passableDelay=new Function('reducedMotion','spec','DEFAULT_PASSABLE_PROGRESS',
  section(doorSource,'    const durationMs = reducedMotion','    this.portal =')+'return this.passableDelayMs;');
const expectedCamera={viewport:logical,world:[world.width,world.height],center:[world.width/2,world.height/2],zoom:Math.min(logical[0]/world.width,logical[1]/world.height)*.985,follow:false,deadzone:[0,0]};
const idle='chapter-3-canteen-paper';
const runKey=frame=>`${idle}-run-${frame}`;
class Vector {constructor(){this.x=0;this.y=0;}lengthSq(){return 0;}clone(){return new Vector();}}
const Runtime=new Function('Phaser','PAPER_IDLE_KEY',...Object.keys(constants),`return class { ${update} ${destroy} }`)(
  {Math:{Vector2:Vector}},idle,...Object.values(constants));
const Scene=new Function('canteenContent','DIALOGUE_STEP_MS','RPG_LOGICAL_WIDTH','RPG_LOGICAL_HEIGHT','CANTEEN_INTERIOR_WORLD','CANTEEN_SOUTHEAST_EXIT_DOOR','setRpgLogicalCameraZoom',
  `return class { ${victory} ${finish} ${dialogue} ${exit} startDefenseCamera(){${cameraSetup}} dispatchVictory(){const name='canteen_defense_completed';${cue}} }`)
  (content,2500,...logical,world,door,(_scene,zoom,camera)=>(camera.zoom=zoom,camera));
assert.doesNotMatch(victory,/yoyo|repeat|setTexture|setFlipX/,'victory cannot replace or loop the frozen source pose');
assert.equal(content.blocking.escapeDialogue.length,3,'source has three escape lines');

function sampleCase(reduced,frame){
  let now=0,exitAt=null,updateCount=0,playerExitDuration=0;
  const doorWait=passableDelay.call({},reduced,{durationMs:doorDuration},passableProgress);
  const jobs=[],tweens=[],lines=[];
  const camera={zoom:1,center:[0,0],follow:true,deadzone:[250,150],stopFollow(){this.follow=false;return this;},setDeadzone(x,y){this.deadzone=[x,y];return this;},centerOn(x,y){this.center=[x,y];return this;}};
  const cameraPose=()=>({viewport:logical,world:[world.width,world.height],center:camera.center,zoom:camera.zoom,follow:camera.follow,deadzone:camera.deadzone});
  const initial={point:[816+frame*17,506-frame*9],frame,flip:frame%2===1,angle:[-9,6,-3,9][frame]};
  const paper={active:true,x:0,y:0,scaleX:1.16,scaleY:1.16,angle:0,flipX:false,key:runKey(0),alpha:1,visible:true};
  for(const [method,key] of [['setTexture','key'],['setFlipX','flipX'],['setAngle','angle'],['setVisible','visible'],['setAlpha','alpha']])paper[method]=v=>(paper[key]=v,paper);
  paper.setScale=v=>(paper.scaleX=v,paper.scaleY=v,paper);
  const player={active:true,x:908,y:628,body:{setVelocity(){}},setVelocity(){return this;},setVisible(){return this;},setDepth(){return this;}};
  const actor=()=>({active:true,destroy(){this.active=false;}});
  const runtime=new Runtime();
  Object.assign(runtime,{player,paper,paused:false,completed:false,destroyed:false,elapsedMs:constants.DEFENSE_DURATION_MS-1,
    dashRemainingMs:0,dashCooldownMs:0,paperHitCooldownMs:0,pushSprite:actor(),timerText:actor(),dashText:actor(),
    playerWorldDepth:()=>0,updatePushSprite(){},updateHud(){},updatePaper(){
      updateCount++;paper.x=initial.point[0];paper.y=initial.point[1];paper.key=runKey(frame);paper.flipX=initial.flip;paper.angle=initial.angle;
    },callbacks:{onComplete(){assert.equal(runtime.completed,true);}}});
  // Execute original update, including its terminal ordering and early return.
  runtime.update(1,new Vector(),false);
  assert.equal(updateCount,1);assert.equal(runtime.completed,true);
  const terminal=JSON.stringify(paper);
  runtime.update(100,new Vector(),false);
  assert.equal(updateCount,1);assert.equal(JSON.stringify(paper),terminal,'completed source runtime freezes final paper properties');
  const scene=new Scene();
  Object.assign(scene,{paper,player,reducedMotion:reduced,paperBusy:false,defenseRuntime:runtime,defenseRestartTimer:null,
    defenseRouteGraphics:null,cameras:{main:camera},darkOverlay:{setAlpha(){}},modeFibers:[],paperFloatTween:{pause(){}},
    time:{delayedCall(delay,fn){jobs.push({at:now+delay,fn});}},
    showFeedback(text,tone,durationMs){lines.push({atMs:now,text,tone,durationMs});},
    exitTransitioning:false,dialogueLocked:false,cartPushBusy:false,
    bridge:{getState(){return {};},emit(id){assert.equal(id,'rpg_canteen_leave_requested');exitAt=now;}},
    canLeaveThroughDoor(){return true;},hasModalPanel(){return false;},promptText:{setVisible(){}},
    exitDoor:{passableDelayMs:doorWait,open(){},reject(){assert.fail('earned source exit rejected');},updateActorOcclusion(){}},
    scene:{isActive(){return true;}},updatePlayerWorldDepth(){},
    tweens:{killTweensOf(){},add(spec){
      if(spec.targets===player){
        assert.equal(spec.ease,'Stepped');playerExitDuration=spec.duration;
        jobs.push({at:now+spec.duration,fn:()=>{player.x=spec.x;player.y=spec.y;spec.onUpdate();spec.onComplete();}});
        return;
      }
      assert.equal(spec.targets,paper);assert.equal(spec.ease,'Quad.easeIn');
      const properties=Object.fromEntries(['x','y','scaleX','scaleY','angle'].map(key=>[key,[paper[key],spec[key]]]));
      tweens.push({start:now,duration:spec.duration,properties});
      jobs.push({at:now+spec.duration,fn:()=>spec.onComplete()});
    }}
  });
  function interpolate(at){
    for(const tween of tweens){
      if(tween.done)continue;
      const progress=Math.max(0,Math.min(1,(at-tween.start)/tween.duration));
      for(const [key,[from,to]] of Object.entries(tween.properties))paper[key]=from+(to-from)*progress*progress;
      if(progress===1)tween.done=true;
    }
  }
  function advance(at){
    jobs.sort((a,b)=>a.at-b.at);
    while(jobs.length&&jobs[0].at<=at){const job=jobs.shift();now=job.at;interpolate(now);job.fn();jobs.sort((a,b)=>a.at-b.at);}
    now=at;interpolate(now);
  }
  scene.startDefenseCamera();
  assert.deepEqual(cameraPose(),expectedCamera,'execute original startDefense full-room camera, stopped follow and zero deadzone');
  scene.dispatchVictory();scene.animateDefenseVictory(()=>assert.fail('busy paper starts twice'));
  assert.equal(tweens.length,1,'busy guard suppresses duplicate victory');
  const duration=reduced?160:760,hideAt=reduced?220:1020;
  const times=[0,1,duration/4,duration/2,duration*3/4,duration-1,duration,duration+1,hideAt-1,hideAt,hideAt+1,hideAt+1200,hideAt+2400,hideAt+3600];
  const samples=times.map(atMs=>{
    advance(atMs);runtime.update(17,new Vector(),false);
    assert.deepEqual(cameraPose(),expectedCamera,'flight, hold and all dialogue retain original full-room camera');
    assert.equal(updateCount,1,'runtime cannot overwrite tween during victory/hold/dialogue');
    return {atMs,point:[paper.x,paper.y],scale:[paper.scaleX,paper.scaleY],angle:paper.angle,frame:paper.key===idle?-1:Number(paper.key.at(-1)),flip:paper.flipX,alpha:paper.visible?paper.alpha:0};
  });
  const final=samples.find(s=>s.atMs===duration);
  assert.deepEqual(final.point,[1380,852]);assert.ok(Math.abs(final.scale[0]-.28)<1e-12);assert.ok(Math.abs(final.scale[1]-.84)<1e-12);
  assert.equal(final.angle,86);assert.equal(final.frame,frame);assert.equal(final.flip,initial.flip);
  assert.equal(samples.find(s=>s.atMs===hideAt-1).alpha,1,'full source hold remains visible');
  const hidden=samples.find(s=>s.atMs===hideAt);
  assert.deepEqual([hidden.frame,hidden.flip,hidden.angle,hidden.scale,hidden.alpha],[-1,false,0,[1,1],0],'destroy restores idle transform before hide/dialogue');
  assert.deepEqual(lines.map(l=>[l.atMs,l.durationMs]),[[hideAt,1080],[hideAt+1200,1080],[hideAt+2400,1080]]);
  const exitStartAt=hideAt+3600;
  assert.equal(exitAt,null,'scripted door wait and player exit must complete first');
  advance(exitStartAt+doorWait);
  advance(exitStartAt+doorWait+playerExitDuration);
  assert.equal(exitAt,exitStartAt+doorWait+playerExitDuration);
  assert.deepEqual([player.x,player.y],[door.exitPoint.x,door.exitPoint.y]);
  assert.deepEqual(cameraPose(),expectedCamera,'source keeps full-room shot through actual scripted exit');
  assert.equal(scene.defenseRuntime,null);assert.equal(scene.paperBusy,false);
  return {reduced,initial,durationMs:duration,holdMs:hideAt-duration,hideAtMs:hideAt,lines,exitAtMs:exitStartAt,leaveAtMs:exitAt,samples};
}
const oracle={sourceMethods:['CanteenDefenseRuntime.update','CanteenDefenseRuntime.destroy','CanteenInteriorScene.animateDefenseVictory','CanteenInteriorScene.finishDefense','CanteenInteriorScene.queueDialogue','CanteenInteriorScene.startDefense','CanteenInteriorScene.beginCanteenExit'],camera:expectedCamera,cases:[false,true].flatMap(reduced=>[0,1,2,3].map(frame=>sampleCase(reduced,frame)))};
const fixture=path.join(root,'godot_native/tests/fixtures/canteen_victory_source.json');
if(process.argv.includes('--write'))fs.writeFileSync(fixture,JSON.stringify(oracle,null,2)+'\n');
else assert.deepEqual(JSON.parse(fs.readFileSync(fixture,'utf8')),oracle,'checked-in native fixture remains identical to executed source methods');
console.log('PASS original defense victory: 8 frozen-frame cases, 112 normal/reduced samples, quadratic nonuniform pose, full hold, reset/hide, 3×1200ms dialogue and unchanged source full-room camera through scripted exit; no Godot process launched');
