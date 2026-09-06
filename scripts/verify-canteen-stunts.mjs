import assert from 'node:assert/strict';
import { build } from 'esbuild';
const out=await build({entryPoints:['src/scenes/rpg/canteen-chase/ChaseStuntModel.ts'],bundle:true,platform:'node',format:'esm',write:false});
const {ChaseStuntModel,visibleStuntObstacles}=await import(`data:text/javascript;base64,${Buffer.from(out.outputFiles[0].text).toString('base64')}`);
const idle=new ChaseStuntModel();idle.update(5000);assert.equal(idle.distance,0);idle.start();idle.press('right');idle.update(200);assert(idle.lane>1&&idle.lane<2,'steering is continuous');idle.release('right');idle.setPaused(true);const pos=idle.distance;idle.update(3000);assert.equal(idle.distance,pos);
const jumper=new ChaseStuntModel();jumper.start();jumper.press('jump');jumper.update(500);jumper.release('jump');jumper.update(200);assert(jumper.airHeight>0.6,'charged release lifts the bicycle');const initial=jumper.airHeight;jumper.press('jump');jumper.release('jump');assert.equal(jumper.airHeight,initial,'cannot double jump');jumper.update(2000);assert.equal(jumper.airHeight,0);
const ringing=new ChaseStuntModel();ringing.start();ringing.update(1800);ringing.press('bell');assert(ringing.bellCooldown>0);assert(ringing.clearedObstacleIds.size>0,'bell clears nearby soft hazards');const cleared=ringing.clearedObstacleIds.size;ringing.press('bell');assert.equal(ringing.clearedObstacleIds.size,cleared);assert(visibleStuntObstacles(90).some(o=>o.kind==='barrier'));
let events=[];const unattended=new ChaseStuntModel(e=>events.push(e));unattended.start();for(let i=0;i<3000&&unattended.runState==='running';i++)unattended.update(20);assert.equal(unattended.runState,'lost','unattended driving cannot win');assert.equal(events.filter(e=>e.type==='finish').length,1);unattended.update(10000);assert.equal(events.filter(e=>e.type==='finish').length,1);unattended.restart();assert.equal(unattended.distance,0);assert.equal(unattended.lives,3);
console.log('Canteen stunt model PASS: continuous steering, jump physics, cooldown, real hazard clearing, pause, terminal once and retry');
for(const hz of [30,60,120]){
 const m=new ChaseStuntModel();m.start();const held=new Set();
 const control=(a,on)=>{if(held.has(a)===on)return;on?held.add(a):held.delete(a);m[on?'press':'release'](a);};
 for(let step=0;step<hz*100&&m.runState==='running';step++){
  const obstacles=visibleStuntObstacles(m.distance).filter(o=>!m.clearedObstacleIds.has(o.id));const next=Math.min(...obstacles.map(o=>o.distance));const group=obstacles.filter(o=>o.distance===next);const open=[0,1,2].filter(l=>!group.some(o=>o.lane===l));
  const target=open.length?open.reduce((a,b)=>Math.abs(a-m.lane)<Math.abs(b-m.lane)?a:b):m.lane;
  control('left',target<m.lane-.05);control('right',target>m.lane+.05);
  const danger=group.some(o=>Math.abs(o.lane-m.lane)<.45),seconds=(next-m.distance)/m.speed;
  if(m.airHeight===0&&danger&&seconds<.95)control('jump',true);
  if(m.charge>0&&seconds<.42)control('jump',false);
  if(m.bellCooldown===0&&seconds<1.7){control('bell',true);control('bell',false);}
  if(m.powerup){control('item',true);control('item',false);}
  m.update(1000/hz);
 }
 assert.equal(m.runState,'won',`playable at ${hz}Hz distance=${m.distance} stunts=${m.stunts}`);assert.equal(m.distance,755);assert(m.stunts>=3);console.log(`${hz} Hz complete: lives ${m.lives}, stunts ${m.stunts}, time ${m.elapsedSeconds.toFixed(2)}s`);
}
const itemRun=new ChaseStuntModel();itemRun.start();itemRun.update(2100);assert.equal(itemRun.powerup,'tray');itemRun.press('item');itemRun.release('item');assert.equal(itemRun.shield,true);assert.equal(itemRun.powerup,null);itemRun.update(1500);assert.equal(itemRun.lives,3);assert.equal(itemRun.shield,false,'tray is consumed by one collision');
console.log('Pickup -> item activation -> single-hit protection PASS');
const gustRun=new ChaseStuntModel();gustRun.start();gustRun.press('left');
for(let i=0;i<2400&&gustRun.distance<152&&gustRun.runState==='running';i++){if(gustRun.bellCooldown<=0){gustRun.press('bell');gustRun.release('bell');}gustRun.update(10);}
assert.equal(gustRun.powerup,'gust','left route reaches the wind pickup');gustRun.press('item');assert(gustRun.boostSeconds>=3.1);assert.equal(gustRun.powerup,null);console.log('Optional ramp/left route -> gust pickup -> boost PASS');
