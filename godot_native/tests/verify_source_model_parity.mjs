// Run from the repository root: node godot_native/tests/verify_source_model_parity.mjs
// Test-only TS reference execution. The shipped Godot game never imports JS.
import {build} from 'esbuild';
import fs from 'node:fs';
import assert from 'node:assert/strict';
async function sourceModule(entry) {
 const output=await build({entryPoints:[entry],bundle:true,platform:'node',format:'esm',write:false});
 return import(`data:text/javascript;base64,${Buffer.from(output.outputFiles[0].text).toString('base64')}`);
}
const fixtures='godot_native/tests/fixtures/';
const fish=await sourceModule('src/modules/RhythmFishingEngine.ts');
for(const id of ['locker_key','net_frame','fish','paper']){
 const result=JSON.parse(fs.readFileSync(`${fixtures}rhythm_${id}.json`,'utf8'));
 assert.equal(fish.validateLakeFishingResult(result,id),true,`Native ${id} trace must pass unchanged original v4 validator`);
 console.log(`PASS Native ${id} trace accepted by original TypeScript v4 validator (${result.grade}, ${result.perfect}/${result.total_notes} perfect)`);
}
const {ChaseStuntModel}=await sourceModule('src/scenes/rpg/canteen-chase/ChaseStuntModel.ts');
const result=JSON.parse(fs.readFileSync(`${fixtures}chase.json`,'utf8'));
const chase=new ChaseStuntModel();chase.start();let tick=0;
for(const event of result.inputs){
 while(tick<event.tick){chase.step(1/120);tick++;}
 if(event.type==='press')chase.press(event.action);
 else if(event.type==='release')chase.release(event.action);
 else chase.releaseControls();
}
while(tick<result.ticks){chase.step(1/120);tick++;}
assert.equal(chase.runState,'won');
for(const key of ['distance','lives','collisions','score','stunts'])assert.equal(chase[key],result[key],`Chase ${key} parity`);
console.log('PASS Native chase trace produces identical original TS distance/lives/collisions/score/stunts');
