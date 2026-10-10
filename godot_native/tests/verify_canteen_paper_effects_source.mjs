// Execute the original entry/ghost/route-flash methods; compare native results.
// CANTEEN_EFFECTS_SOURCE_ONLY=1 audits source without starting Godot or a GUI.
import assert from 'node:assert/strict';
import fs from 'node:fs';
import os from 'node:os';
import path from 'node:path';
import {spawnSync} from 'node:child_process';
import {fileURLToPath} from 'node:url';
const root=path.resolve(path.dirname(fileURLToPath(import.meta.url)),'../..');
const sourceRoot=process.env.CANTEEN_SOURCE_ROOT||root;
const source=fs.readFileSync(path.join(sourceRoot,'src/scenes/rpg/CanteenInteriorScene.ts'),'utf8');
const method=(name,next)=>source.slice(source.indexOf(`  private ${name}(`),source.indexOf(`  private ${next}(`));
const methods=method('playEntryPaperEscapeRoute','spawnEntryPaperAfterimage')+method('spawnEntryPaperAfterimage','finishEntryPaperEscape')+method('flashDefenseRoute','animateDefenseVictory');
const clean=methods.replace(/private /g,'').replace(/: readonly Phaser\.Math\.Vector2\[\]/g,'').replace(/: (?:void|number)/g,'');
const Scene=new Function('CANTEEN_PAPER_RUN_KEYS','zoomRpgCameraTo',`return class {${clean}}`)(['run0','run1','run2','run3'],()=>{});
const ease=(name,t)=>({'Sine.easeIn':()=>1-Math.cos(t*Math.PI/2),'Linear':()=>t,'Quad.easeOut':()=>1-(1-t)**2,'Quad.easeInOut':()=>t<.5?2*t*t:1-(-2*t+2)**2/2,'Cubic.easeIn':()=>t**3}[name]||(()=>t))();
function run(reducedMotion){
 let now=0;const jobs=[],tweens=[],ghosts=[],graphics=[],kills=[],routeTweens=[];
 const actor=(x=0,y=0,key='run0')=>{
  const a={x,y,scaleX:1,scaleY:1,angle:0,alpha:1,depth:0,visible:true,active:true,texture:{key}};
  for(const k of ['startFollow','setDeadzone'])a[k]=()=>a;
  a.setScale=(x,y=x)=>(a.scaleX=x,a.scaleY=y,a);a.setAngle=v=>(a.angle=v,a);a.setAlpha=v=>(a.alpha=v,a);
  a.setDepth=v=>(a.depth=v,a);a.setTexture=key=>(a.texture={key},a);a.setTint=v=>(a.tint=v,a);a.destroy=()=>a.active=false;
  return a;
 };
 const scene=new Scene();scene.reducedMotion=reducedMotion;scene.paper=actor(1053,302);
 scene.bridge={emit(){}};scene.cameras={main:actor()};scene.finishEntryPaperEscape=()=>{scene.paper.visible=false;scene.entryPaperRunTimer.remove();};
 const later=(delay,fn)=>jobs.push({at:now+delay,fn});
 scene.time={delayedCall:later,addEvent(spec){const timer={active:true,remove(){this.active=false;}};const next=()=>{if(!timer.active)return;spec.callback();if(timer.active)later(spec.delay,next);};later(spec.delay,next);return timer;}};
 scene.add={image(x,y,key){const a=actor(x,y,key);ghosts.push({at:now,actor:a});return a;},graphics(){
  const g={points:[],dots:[],clear(){this.points=[];this.dots=[];return this;},setDepth(){return this;},setVisible(v){this.visible=v;return this;},setAlpha(v){this.alpha=v;return this;},lineStyle(...v){this.line=v;return this;},beginPath(){return this;},moveTo(x,y){this.points.push([x,y]);return this;},lineTo(x,y){this.points.push([x,y]);return this;},strokePath(){return this;},fillStyle(...v){this.fill=v;return this;},fillCircle(x,y,r){this.dots.push([x,y,r]);return this;}};graphics.push(g);return g;
 }};
 scene.tweens={killTweensOf(target){kills.push(target);for(const tween of tweens)if(tween.spec.targets===target)tween.active=false;},add(spec){
  const starts=Object.fromEntries(['x','y','alpha','scaleX','scaleY','angle'].filter(k=>k in spec).map(k=>[k,spec.targets[k]]));
  const t={at:now,spec,starts,active:true};tweens.push(t);
  if(spec.targets===scene.paper)routeTweens.push({at:now,duration:spec.duration,ease:spec.ease,...Object.fromEntries(['x','y','angle'].filter(k=>k in spec).map(k=>[k,spec[k]]))});
  later(spec.duration,()=>{if(!t.active)return;update(t,1);t.active=false;spec.onComplete?.();});
  return t;
 }};
 const update=(t,q)=>{const p=ease(t.spec.ease,q);for(const k in t.starts)t.spec.targets[k]=t.starts[k]+(t.spec[k]-t.starts[k])*p;};
 const advanceTo=target=>{while(jobs.length){jobs.sort((a,b)=>a.at-b.at);if(jobs[0].at>target)break;const job=jobs.shift();now=job.at;for(const t of tweens)if(t.active)update(t,Math.min(1,(now-t.at)/t.spec.duration));job.fn();}now=target;for(const t of tweens)if(t.active)update(t,Math.min(1,(now-t.at)/t.spec.duration));};
 scene.playEntryPaperEscapeRoute();const interval=reducedMotion?120:78;
 advanceTo(interval*2-.01);assert.equal(ghosts.length,0,'source starts at frame0 but does not spawn until frame2');
 advanceTo(interval*2);assert.equal(ghosts.length,1);const first=ghosts[0],a=first.actor;
 const firstPose={point:[a.x,a.y],angle:a.angle,frame:Number(a.texture.key.at(-1)),scale:a.scaleX,alpha:a.alpha,tint:a.tint.toString(16)};
 const tween=tweens.find(t=>t.spec.targets===a);assert.equal(tween.spec.duration,reducedMotion?90:220);assert.equal(tween.spec.scaleX,.82*.82);assert.equal(tween.spec.scaleY,.82*.82);
 advanceTo(interval*2+tween.spec.duration/2);const half={point:[a.x,a.y],angle:a.angle,frame:firstPose.frame,scale:a.scaleX,alpha:a.alpha,tint:firstPose.tint};
 advanceTo(3000);assert.equal(scene.paper.visible,false,'source removes timer on final exit');
 assert.equal(routeTweens.length,6,'original route keeps six movement tweens plus one hold');
 // Capture exact graphics primitives, then exercise replacement and completion.
 scene.paper.x=700;scene.paper.y=500;
 const route=[{x:710,y:480},{x:650,y:440},{x:600,y:410},{x:590,y:350}];
 scene.flashDefenseRoute(route);const g=graphics[0];
 assert.deepEqual(g.points,[[700,500],...route.map(p=>[p.x,p.y])]);
 assert.deepEqual(g.dots,[[710,480,5],[600,410,5]]);assert.deepEqual(g.line,[5,0x78ddff,.88]);assert.deepEqual(g.fill,[0xdff9ff,.9]);assert.equal(g.alpha,.95);
 const flash=tweens.at(-1);assert.equal(flash.spec.duration,reducedMotion?420:760);
 const contact={reduced:reducedMotion,duration:flash.spec.duration,alpha:g.alpha,lineAlpha:g.alpha*g.line[2],dotAlpha:g.alpha*g.fill[1],width:g.line[0],radius:g.dots[0][2]};
 advanceTo(now+40);scene.paper.x=900;scene.flashDefenseRoute([{x:800,y:700}]);
 assert.equal(graphics.length,1);assert.deepEqual(g.points,[[900,500],[800,700]]);assert.deepEqual(g.dots,[[800,700,5]]);assert.equal(kills.length,2);assert.equal(flash.active,false);
 advanceTo(now+(reducedMotion?420:760));assert.equal(g.visible,false);assert.equal(g.points.length,0);
 return {entry:{reduced:reducedMotion,at:interval*2,pose:firstPose,duration:tween.spec.duration,half},contact};
}
const normal=run(false),reduced=run(true);
assert.match(source,/onTurnaround: \(_exitId, route\) => \{\s*this\.flashDefenseRoute\(route\);\s*this\.cameras\.main\.shake\(this\.reducedMotion \? 0 : 75, 0\.0025\)/);
const defense=fs.readFileSync(path.join(root,'godot_native/scripts/games/canteen_defense.gd'),'utf8');
assert.match(defense,/defense_effects\.advance\(Model\.DT\*1000\)\s*model\.step\([^\n]+\)\s*defense_effects\.observe\(model\)/,'effects observe every authoritative step without replacing it');
assert.match(defense,/offset\+=defense_effects\.camera_offset\(viewport,zoom\)/);
assert.match(defense,/_draw_board\(view,metrics\.offset,metrics\.zoom,view\.size\)/,'each compact camera supplies its own viewport extent');
assert.match(defense,/metrics\.offset\+=defense_effects\.camera_offset\(view\.size,metrics\.zoom\)/,'overview annotations use the same shake as room art');
assert.doesNotMatch(defense,/model\.route_flash\s*=/,'renderer never rewrites source model flash duration');
const sentBranch=defense.slice(defense.indexOf('\tif sent:',defense.indexOf('func _process(')),defense.indexOf('\tif running and not paused:',defense.indexOf('func _process(')));
assert.match(sentBranch,/if paused: return[\s\S]*defense_effects\.advance\(minf\(delta,\.1\)\*1000\)/,'victory hold advances only unpaused presentation time');
assert.doesNotMatch(sentBranch,/model\.step\(/,'victory hold cannot step the terminal model');
const wonBranch=defense.slice(defense.indexOf('elif model.status=="won":'),defense.indexOf('func refresh('));
assert.doesNotMatch(wonBranch,/defense_effects\.reset/,'terminal-tick contact survives into victory');
const effects=fs.readFileSync(path.join(root,'godot_native/scripts/presentation/c3_defense_effects.gd'),'utf8');
assert.doesNotMatch(effects,/run\.\w+\s*=(?!=)|\b(?:randf|randi|seed|randomize)\s*\(/,'effects have no model or global RNG writes');
if(process.env.CANTEEN_EFFECTS_SOURCE_ONLY!=='1'){
 const temp=fs.mkdtempSync(path.join(os.tmpdir(),'canteen-paper-effects-check-'));
 try{
  for(const relative of ['scripts/presentation/c3_paper_art.gd','scripts/presentation/c3_canteen_paper_view.gd','scripts/presentation/c3_scene_session.gd','scripts/presentation/c3_defense_effects.gd','scripts/games/canteen_defense_model.gd','tests/test_canteen_paper_effects.gd','tests/fixtures/canteen_defense.json']){
   const target=path.join(temp,relative);fs.mkdirSync(path.dirname(target),{recursive:true});fs.copyFileSync(path.join(root,'godot_native',relative),target);
  }
  for(const relative of ['data/worlds.json','data/source/chapter3-canteen.content.json']){
   const target=path.join(temp,relative);fs.mkdirSync(path.dirname(target),{recursive:true});fs.copyFileSync(path.join(sourceRoot,'godot_native',relative),target);
  }
  fs.writeFileSync(path.join(temp,'project.godot'),'config_version=5\n[application]\nconfig/name="Canteen paper effects source parity"\n[threading]\nworker_pool/max_threads=1\n');
  const dump=path.join(temp,'effects.json');
  const env={...process.env,CANTEEN_EFFECTS_DUMP:dump,HOME:temp,XDG_CACHE_HOME:path.join(temp,'.cache'),XDG_DATA_HOME:path.join(temp,'.data'),XDG_CONFIG_HOME:path.join(temp,'.config')};
  const result=spawnSync(process.env.GODOT_BIN||'godot',['--headless','--path',temp,'--script','res://tests/test_canteen_paper_effects.gd','--quit-after','8'],{encoding:'utf8',timeout:30000,env});
  const output=(result.stdout||'')+(result.stderr||'');process.stdout.write(output);assert.ifError(result.error);assert.equal(result.status,0);assert.doesNotMatch(output,/SCRIPT ERROR|Parse Error/);assert.match(output,/CANTEEN_PAPER_EFFECTS \d+ checks; 0 failures/);
  const native=JSON.parse(fs.readFileSync(dump,'utf8'));
  const compare=(actual,expected,label)=>{if(typeof expected==='number'){assert.ok(Math.abs(actual-expected)<.0002,`${label}: ${actual} != ${expected}`);}else if(expected&&typeof expected==='object'){for(const key of Object.keys(expected))compare(actual[key],expected[key],`${label}.${key}`);}else assert.equal(actual,expected,label);};
  for(const [i,expected] of [normal,reduced].entries()){compare(native.entry[i],expected.entry,`entry${i}`);compare(native.contacts[i],expected.contact,`contacts${i}`);}
 }finally{fs.rmSync(temp,{recursive:true,force:true});}
}
console.log('PASS original entry timer/frame2, ghost tint/linear geometry, frozen flash/even waypoint dots, repeated-contact replacement,760/420ms fade and75/0ms shake');
