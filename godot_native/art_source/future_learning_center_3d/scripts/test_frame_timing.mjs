import assert from 'node:assert/strict';
import {frameTimeSteps} from '../web/frame_timing.js';
let passed=0;
const check=(ok,message)=>{assert.ok(ok,message);passed++;};
for(const interval of [1000/60,1000,2000]){
 let previous=null,height=.73,now=0,frames=0;
 for(;height<1.10;frames++,now+=interval){
  const step=frameTimeSteps(now,previous);previous=step.previous;
  height+=Math.min(1.10-height,.12*step.deskDt);
  check(step.walkDt<=.05,'walk dt never exceeds 50ms');
 }
 const elapsed=now-interval;
 check(elapsed>=.37/.12*1000-1e-6&&elapsed<=.37/.12*1000+interval,'lift converges within one frame of 3.083s');
 check(height===1.10,'lift ends at exact target');
 console.log(JSON.stringify({intervalMs:interval,elapsedMs:elapsed,frames}));
}
check(frameTimeSteps(2000,0).deskDt===2,'timestamp zero is a valid previous frame');
check(frameTimeSteps(3000,2000).deskDt===1,'one-second foreground frame');
check(frameTimeSteps(62000,2000).deskDt===0,'long suspension is discarded');
check(frameTimeSteps(62000,2000).walkDt===.05,'long frame retains collision clamp');
check(frameTimeSteps(1000,2000).deskDt===0,'backwards clock cannot reverse animation');
check(frameTimeSteps(NaN,2000).deskDt===0,'non-finite interval cannot move furniture');
let hidden=frameTimeSteps(62000,2000,true);
check(hidden.deskDt===0&&hidden.walkDt===0&&hidden.previous===null,'paused frame resets time baseline');
let resumed=frameTimeSteps(92000,hidden.previous);
check(resumed.deskDt===0&&resumed.walkDt===0,'first resumed frame does not catch up');
check(frameTimeSteps(93000,resumed.previous).deskDt===1,'resumed next frame uses active wall time');
console.log(JSON.stringify({passed,scope:'pure frame timing; real animation and input covered by spatial integration'}));
