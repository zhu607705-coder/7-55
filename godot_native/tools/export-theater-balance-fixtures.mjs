import fs from 'node:fs';
import crypto from 'node:crypto';
import {build} from 'esbuild';
import {playTheaterRoute} from './theater-review-route.mjs';
const built=await build({stdin:{contents:"export * from './src/scenes/rpg/TheaterSpotlightModel.ts';",resolveDir:process.cwd()},bundle:true,platform:'node',format:'esm',write:false});
const model=await import('data:text/javascript;base64,'+Buffer.from(built.outputFiles[0].text).toString('base64'));
const cases=[];
for(let round=0;round<3;round++)for(const attempt of [0,1,2]){
  const result=playTheaterRoute(model,round,attempt);
  if(result.state.status!=='won')throw new Error(`No viable route for act ${round}, attempt ${attempt}`);
  cases.push({proof:result.proof,samples:result.samples,events:result.events});
  if(attempt===0)fs.writeFileSync(`godot_native/tests/fixtures/spotlight_${round}.json`,JSON.stringify(result.proof));
}
fs.writeFileSync('godot_native/tests/fixtures/spotlight_balance_samples.json',JSON.stringify({source:'TheaterSpotlightModel.ts',sourceSha256:crypto.createHash('sha256').update(fs.readFileSync('src/scenes/rpg/TheaterSpotlightModel.ts')).digest('hex'),cases}));
