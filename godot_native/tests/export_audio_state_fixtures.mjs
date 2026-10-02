/** Source oracle: evaluate the original PresentationDirector, not a second JS port. */
import fs from 'node:fs';
import path from 'node:path';
import {fileURLToPath} from 'node:url';
import {build} from 'esbuild';
const root=fileURLToPath(new URL('../../',import.meta.url));
const bundle=await build({entryPoints:[path.join(root,'src/modules/PresentationDirector.ts')],bundle:true,write:false,platform:'node',format:'esm',logLevel:'silent'});
const {PresentationDirector}=await import('data:text/javascript;base64,'+Buffer.from(bundle.outputFiles[0].text).toString('base64'));
const oracle=new PresentationDirector();
const states=[];
for(const runtimeMode of ['phone','rpg'])for(const rpgScene of ['duan_yongping_temporal_maze','campus_bootstrap'])for(const phase of ['maintenance_repair','final_chase','final_minute_recovery','other'])for(const repaired of [false,true])for(const chaseAttempt of [0,1]){
 states.push({currentScene:phase==='other'?'phone_home':'clock',runtimeMode,rpgScene,chapter4:{phase,factIds:repaired?['clock_gear_repaired']:[],chaseAttempt}});
}
const cases=[];
for(let i=0;i<states.length;i++)for(let j=0;j<states.length;j++) cases.push({previous:i,next:j,expected:oracle.deriveStateCues(states[i],states[j])});
const serialized=JSON.stringify({source:'src/modules/PresentationDirector.ts',states,cases})+'\n';
const output=path.join(root,'godot_native/tests/fixtures/audio-state-source.json');
if(process.argv.includes('--check')){if(fs.readFileSync(output,'utf8')!==serialized)throw Error('Source PresentationDirector fixtures are stale');}
else fs.writeFileSync(output,serialized);
console.log(`Original PresentationDirector: ${states.length} states, ${cases.length} transition pairs`);
