// Test-only chronological oracle executes the original TypeScript method after
// removing its local type annotations. No source runtime is shipped in Godot.
import fs from 'node:fs';
import path from 'node:path';
import assert from 'node:assert/strict';
import {fileURLToPath} from 'node:url';
const root=process.env.CANTEEN_SOURCE_ROOT||path.resolve(path.dirname(fileURLToPath(import.meta.url)),'../..');
const source=fs.readFileSync(path.join(root,'src/scenes/rpg/CanteenInteriorScene.ts'),'utf8');
let method=source.slice(source.indexOf('  private animatePaperBurst()'),source.indexOf('  private emitPaperChickenBurst('));
method=method.replace('private animatePaperBurst(): void','animatePaperBurst()').replace(/: Phaser\.GameObjects\.Sprite/g,'').replace(/: number/g,'').replace(/: Phaser\.Physics\.Arcade\.StaticBody \| null/g,'').replace(/ as Phaser\.Physics\.Arcade\.StaticBody \| null/g,'');
const names=[...new Set(method.match(/\b(?:CANTEEN_[A-Z_]+|RPG_LOGICAL_WIDTH|RPG_LOGICAL_HEIGHT)\b/g))];
const values=Object.fromEntries(names.map(name=>[name,name]));
values.CANTEEN_PICKUP_WINDOWS=[{},{},{x:790,y:218}];values.CANTEEN_INTERIOR_WORLD={width:1672,height:941};values.RPG_LOGICAL_WIDTH=960;values.RPG_LOGICAL_HEIGHT=540;
const Scene=new Function('Phaser','zoomRpgCameraTo',...names,`return class {${method}}`)({BlendModes:{SCREEN:'screen'}},()=>{},...names.map(n=>values[n]));
const run=(reducedMotion)=>{
 let now=0;const jobs=[],cues=[],animations=[],actors=[],dialogue=[],shakes=[];
 const later=(delay,fn)=>jobs.push({at:now+delay,fn});
 const actor=(kind,x=0,y=0,key='')=>{
  const a={kind,x,y,key,anims:{timeScale:1},at:now,visible:true,alpha:1};actors.push(a);
  for(const name of ['setBlendMode','setScrollFactor','setDepth','setVelocity','setFacing','setDeadzone','stopFollow','startFollow','stop','play','destroy'])a[name]=()=>a;
  a.setPosition=(x,y)=>(a.x=x,a.y=y,a);a.setVisible=v=>(a.visible=v,a);a.setAlpha=v=>(a.alpha=v,a);
  a.setScale=s=>(a.scale=s,a);a.setAngle=v=>(a.angle=v,a);a.setOrigin=(...v)=>(a.origin=v,a);a.setTexture=v=>(a.key=v,a);a.setStrokeStyle=()=>a;
  return a;
 };
 const scene=new Scene();Object.assign(scene,{
  reducedMotion,paperBusy:false,lightNpcSprites:Array.from({length:31},()=>actor('npc')),lightNpcCollisionBodies:[],modeFibers:[],darkOverlay:actor('overlay'),
  player:actor('player',790,260),playerAnimator:actor('animator'),promptText:actor('prompt'),paperFloatTween:{pause(){}},paper:actor('paper'),shadowNpcSprite:actor('shadow'),
  anims:{exists:()=>false,generateFrameNumbers:(key,{start,end})=>Array.from({length:end-start+1},(_,i)=>({key,frame:start+i})),create:a=>animations.push(a)},
  add:Object.fromEntries(['circle','rectangle','text','container','sprite','image'].map(kind=>[kind,(x,y,key)=>actor(kind,x,y,key)])),
  bridge:{emit:id=>cues.push([now,id])},time:{delayedCall:later},
  tweens:{killTweensOf(){},add(spec){const cycles=(spec.yoyo?2:1)*(1+(spec.repeat||0));later(spec.duration*cycles,()=>{for(const target of [].concat(spec.targets))for(const k of ['x','y','scale','alpha','angle'])if(k in spec)target[k]=spec[k];spec.onComplete?.();});}},
  queueDialogue(lines,done,hold){dialogue.push({at:now,lines,hold});later(lines.length*hold,done);},
  emitPaperChickenBurst(){},startDefense(){cues.push([now,'canteen_defense_started']);}
 });
 scene.cameras={main:{...actor('camera'),pan(){},shake:(duration,intensity)=>shakes.push([now,duration,intensity])}};
 scene.animatePaperBurst();while(jobs.length){jobs.sort((a,b)=>a.at-b.at);const job=jobs.shift();now=job.at;job.fn();}
 return {cues,animations,actors,dialogue,shakes};
};
const expected=[[0,'canteen_pickup_ticket_handoff'],[850,'canteen_pickup_cutscene_quiet'],[4030,'canteen_paper_package_wait'],[4930,'canteen_paper_package_shake'],[5980,'canteen_paper_burst_started'],[6500,'canteen_paper_camera_impact'],[9580,'canteen_paper_burst_completed'],[11380,'canteen_defense_started']];
for(const reduced of [false,true]){
 const result=run(reduced);assert.deepEqual(result.cues,expected);
 assert.deepEqual(result.animations.map(a=>[a.frameRate,a.frames.map(f=>f.frame)]),[[3.6,[0,1,2,3,4]],[5.7,[0,1,0,2,3,4]],[15.4,[0,1,2,3,4,5,6,7]]]);
 assert.deepEqual(result.dialogue,[{at:9580,lines:['玩家：那是鸡吗？','系统：现在不是了。'],hold:900}]);
 assert.deepEqual(result.shakes,[[5980,reduced?0:120,.006],[6500,reduced?0:90,.0045]]);
 assert.equal(result.actors.find(a=>a.key==='CANTEEN_SHADOW_AUNTIE_PUSH_KEY').at,2630);
 assert.equal(result.actors.find(a=>a.key==='CANTEEN_PAPER_CHICKEN_SHAKE_KEY').at,4030);
 assert.equal(result.actors.find(a=>a.key==='CANTEEN_PAPER_CHICKEN_BURST_KEY').at,5980);
 assert.equal(result.actors.find(a=>a.key==='CANTEEN_PUSH_CART_SHEET_KEY').at,8040);
}
console.log('PASS original animatePaperBurst: normal/reduced 11380ms, 8 source cues, 3 frame sequences, 2 dialogue lines, 2 shake envelopes, 4 actor admissions');
