import assert from "node:assert/strict";
import { EventEmitter } from "node:events";
import { build } from "esbuild";
const built = await build({entryPoints:["src/scenes/rpg/ChapterFourGuardPresentation.ts"],bundle:true,platform:"node",format:"esm",write:false,
  plugins:[{name:"image-urls",setup(b){b.onResolve({filter:/\.png$/},a=>({path:a.path,namespace:"image"}));b.onLoad({filter:/.*/,namespace:"image"},()=>({contents:'export default "fixture.png"'}));}}]});
const {presentGuardCapture}=await import(`data:text/javascript;base64,${Buffer.from(built.outputFiles[0].text).toString("base64")}`);
function fixture(){
  const events=new EventEmitter(), callbacks=[];
  let active=true, resumed=0, completed=0;
  const physics={world:{},pause(){},resume(){assert(this.world,"must not resume a destroyed physics world");resumed++;}};
  // Phaser shuts down physics before application shutdown listeners run.
  events.on("shutdown",()=>{physics.world=null;active=false;});
  const scene={events,physics,sys:{isActive:()=>active},time:{delayedCall(ms,callback){assert.equal(ms,5200);const timer={removed:false,remove(){this.removed=true}};callbacks.push({callback,timer});return timer;}}};
  return {scene,callbacks,events,start(){presentGuardCapture(scene,{emit(){}},()=>completed++);},counts:()=>({resumed,completed})};
}
const normal=fixture();
for(let i=0;i<4;i++){normal.start();normal.callbacks.at(-1).callback();assert.equal(normal.events.listenerCount("shutdown"),1,"completed captures must detach their shutdown callback");}
assert.deepEqual(normal.counts(),{resumed:4,completed:4});
assert.doesNotThrow(()=>normal.events.emit("shutdown"),"entering stairs after capture must not resume destroyed physics");
for(const event of ["shutdown","destroy"]){const f=fixture();f.start();f.events.emit(event);assert(f.callbacks[0].timer.removed);f.callbacks[0].callback();assert.deepEqual(f.counts(),{resumed:0,completed:0},"cancelled capture cannot submit an old retry");}
console.log("Guard capture lifecycle PASS: repeated catches, shutdown/destroy cancellation and stale timer suppression.");
