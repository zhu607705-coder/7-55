// Test-only original runtime oracle. No browser/Phaser runtime ships in Godot.
import {build} from 'esbuild';
import fs from 'node:fs';
import assert from 'node:assert/strict';
import {createRequire} from 'node:module';
const require=createRequire(import.meta.url);
const Vector2=require('../../node_modules/phaser/src/math/Vector2.js');
const RandomDataGenerator=require('../../node_modules/phaser/src/math/random-data-generator/RandomDataGenerator.js');
const fixture=JSON.parse(fs.readFileSync('godot_native/tests/fixtures/canteen_defense.json','utf8'));
const snapshots=JSON.parse(fs.readFileSync('godot_native/tests/fixtures/canteen_defense_snapshots.json','utf8'));
globalThis.__DefensePhaser={Math:{Vector2,RND:new RandomDataGenerator([fixture.seed]),Clamp:(v,a,b)=>Math.min(b,Math.max(a,v)),Linear:(a,b,t)=>a+(b-a)*t,Distance:{Between:(x,y,a,b)=>Math.hypot(x-a,y-b),Squared:(x,y,a,b)=>(x-a)**2+(y-b)**2}},Textures:{FilterMode:{NEAREST:0}}};
const bundle=await build({entryPoints:['src/scenes/rpg/CanteenDefenseRuntime.ts'],bundle:true,format:'esm',platform:'node',write:false,plugins:[{name:'native-oracle',setup(b){
 b.onResolve({filter:/^phaser$/},()=>({path:'phaser',namespace:'oracle'}));
 b.onResolve({filter:/RpgRenderResolution$/},()=>({path:'resolution',namespace:'oracle'}));
 b.onLoad({filter:/.*/,namespace:'oracle'},a=>({contents:a.path==='phaser'?'export default globalThis.__DefensePhaser;':'export const getRpgLogicalCameraZoom=()=>1;',loader:'js'}));
}}]});
const {CanteenDefenseRuntime}=await import('data:text/javascript;base64,'+Buffer.from(bundle.outputFiles[0].text).toString('base64'));
class Actor{
 constructor(x=0,y=0){this.x=x;this.y=y;this.angle=0;this.scale=1;this.active=true;}
 setPosition(x,y){this.x=x;this.y=y;return this;}
 setVelocity(x,y){this.vx=x;this.vy=y;return this;}
 setAngle(a){this.angle=a;return this;}
 setScale(s){this.scale=s;return this;}
 setOrigin(){return this;} setDepth(){return this;} setVisible(){return this;} setAlpha(){return this;} setTexture(){return this;} setFlipX(){return this;} setFrame(){return this;} setText(){return this;}setColor(){return this;}
 getBounds(){const angle=this.angle*Math.PI/180,w=(Math.abs(Math.cos(angle))*64+Math.abs(Math.sin(angle))*50)*this.scale,h=(Math.abs(Math.sin(angle))*64+Math.abs(Math.cos(angle))*50)*this.scale;return {left:this.x-w/2,top:this.y-h/2,right:this.x+w/2,bottom:this.y+h/2};}
}
const scene={textures:{get:()=>({setFilter(){}})},add:{sprite:(x,y)=>new Actor(x,y),text:()=>new Actor()},cameras:{main:{}}};
const player=new Actor();
Object.defineProperty(player,'body',{get:()=>({x:player.x-9.75,y:player.y+24.375,width:19.5,height:14.625,bottom:player.y+39})});
const paper=new Actor();let won=false,failed=false,turnarounds=0;
const runtime=new CanteenDefenseRuntime(scene,player,paper,{onComplete:()=>won=true,onFailure:()=>failed=true,onTurnaround:()=>turnarounds++});
let maxError=0;
for(let i=0;i<fixture.inputs.length;i++){
 const input=fixture.inputs[i],snap=snapshots[i];
 player.setPosition(...snap.player); // native collision-integrated position, before source scene.update
 runtime.update(1000/60,new Vector2(input.x,input.y),input.dash);
 const error=Math.hypot(paper.x-snap.paper[0],paper.y-snap.paper[1]);maxError=Math.max(maxError,error);
 assert.ok(error<0.2,`Paper position diverged at tick${i+1}: ${error}`);
 assert.equal(runtime.currentExit,snap.exit,`Seeded exit parity tick${i+1}`);
 assert.equal(runtime.routeIndex,snap.route_index,`BFS waypoint parity tick${i+1}`);
 assert.equal(turnarounds,snap.turnarounds,`Cart-paper turnaround parity tick${i+1}`);
 assert.ok(Math.abs(runtime.dashRemainingMs-snap.dash_remaining)<1e-6,`Dash duration parity tick${i+1}`);
 assert.ok(Math.abs(runtime.dashCooldownMs-snap.dash_cooldown)<1e-6,`Dash cooldown parity tick${i+1}`);
 assert.equal(failed,false);
}
// Source repeated addition may remain a few picoseconds below 60,000; native uses integer ticks.
if(!won)runtime.update(1e-6,new Vector2(0,0),false);
assert.equal(won,true);assert.equal(turnarounds,fixture.turnarounds);
console.log(`PASS Original CanteenDefenseRuntime: 3600 input ticks, ${turnarounds} interceptions, matching seeded exits/BFS/dash timings; max float position difference ${maxError.toFixed(5)}px`);
console.log('NOTE Player coordinates are supplied from native collision integration; this oracle does not claim Phaser-vs-Godot corner-separation equivalence.');
