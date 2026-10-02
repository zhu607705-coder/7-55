// Build-only recorder executes the original procedural tone functions against a
// fake AudioContext and exports oscillator/envelope instructions, not audio JS.
import fs from 'node:fs';
import path from 'node:path';
import {build} from 'esbuild';
function recorder(){
 const tones=[];let pending;
 const ctx={currentTime:0,state:'running',destination:{},createOscillator(){const tone={waveform:'sine',frequency:[],gain:[]};tones.push(tone);pending=tone;return {get type(){return tone.waveform},set type(v){tone.waveform=v},frequency:{setValueAtTime(value,at){tone.frequency.push({curve:'set',value,at})},exponentialRampToValueAtTime(value,at){tone.frequency.push({curve:'exponential',value,at})}},connect(node){return node},disconnect(){},start(at){tone.start=at},stop(at){tone.stop=at}}},createGain(){const tone=pending;return {gain:{setValueAtTime(value,at){tone.gain.push({curve:'set',value,at})},exponentialRampToValueAtTime(value,at){tone.gain.push({curve:'exponential',value,at})}},connect(node){return node},disconnect(){}}}};
 return {ctx,tones};
}
export async function sourceTones(root){
 const bundle=await build({entryPoints:[path.join(root,'src/scenes/rpg/LakeFishingAudio.ts')],bundle:true,write:false,platform:'node',format:'esm',logLevel:'silent'});
 const lake=await import('data:text/javascript;base64,'+Buffer.from(bundle.outputFiles[0].text).toString('base64'));
 const source=fs.readFileSync(path.join(root,'src/scenes/rpg/CanteenChaseOverlay.tsx'),'utf8');
 const body=source.match(/const at = ctx.currentTime, osc = ctx.createOscillator\(\), gain = ctx.createGain\(\);[\s\S]+?osc.stop\(at \+ \.23\);/);
 if(!body)throw Error('Source ChaseStunt audio function changed');
 const chaseSound=new Function('ctx','kind',body[0]);
 const chase={};for(const kind of ['bell','collision','jump','collect','item','finish']){const r=recorder();chaseSound(r.ctx,kind);chase[kind]=r.tones;}
 const beats=[];for(let beat=0;beat<4;beat++){const r=recorder();lake.scheduleLakeFishingBeat(r.ctx,beat,0,1);const s=recorder();lake.scheduleLakeFishingBeat(s.ctx,beat,0,.6);for(let n=0;n<r.tones.length;n++){const t=r.tones[n];if(t.start!==s.tones[n].start){t.beatFraction=.5;}}beats.push(r.tones);}
 const judgments={};for(const key of ['miss','perfect','great','good']){const r=recorder();lake.scheduleLakeFishingJudgment(r.ctx,key,0);judgments[key]=r.tones;}
 return {sources:['src/scenes/rpg/CanteenChaseOverlay.tsx','src/scenes/rpg/LakeFishingAudio.ts'],chase,beats,judgments};
}
