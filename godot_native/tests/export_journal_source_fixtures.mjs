// Bundles the unmodified source pure model into temporary storage and records
// deterministic cross-engine expectations. No browser/Godot runtime is shipped.
import {build} from 'esbuild';
import {mkdtemp,writeFile,rm} from 'node:fs/promises';
import {tmpdir} from 'node:os';
import {join,resolve} from 'node:path';
import {pathToFileURL} from 'node:url';
const dir=await mkdtemp(join(tmpdir(),'qizhen-journal-source-'));
try {
  await build({stdin:{contents:`export * from './src/modules/QizhenJournalModel.ts'; export * from './src/scenes/rpg/QizhenLakeModel.ts';`,resolveDir:resolve('.'),loader:'ts'},bundle:true,platform:'node',format:'esm',outfile:join(dir,'source.mjs')});
  const m=await import(pathToFileURL(join(dir,'source.mjs')));
  const captures=[];
  for (const [spotId,x,y,speed,roll,heading,gone] of [
    ['lake_center',836,470,0,0,0,false],['dock',700,620,90,.18,-Math.PI/8,false],
    ['reflection',1290,350,91,.181,Math.PI*7/4,false],['reflection',1290,350,0,0,0,false],
    ['swan_cove',900,420,0,0,1,false],['swan_cove',700,560,0,0,-5,false],['swan_cove',800,500,-91,-.19,9,true]
  ]) {
    const input={kayakX:x,kayakY:y,heading};
    if(spotId==='swan_cove') input.swanDistance=gone?'gone':Math.hypot(x-1160,y-400);
    if(spotId==='reflection') input.rippleVisible=Math.max(0,Math.min(1,1-Math.abs(speed)/240-Math.abs(roll)/1.2));
    const recipe=m.buildQizhenPhotoRecipe(spotId,input);
    const tags=m.derivePhotoTags({recipe,speed,roll});
    captures.push({spotId,x,y,speed,roll,heading,gone,recipe,tags});
  }
  const projections=[];
  for(const seed of [1,2,755,2147483647,4294967295]) {
    const j=m.createInitialJournalState();
    j.status='open';j.threadSeed=seed;j.threadId='qizhen-journal-'+seed;
    j.mainTitleId='title_makeshift_boat';j.mainStatusId='status_still_afloat';
    for(const [index,spot] of ['lake_center','dock','reflection','swan_cove'].entries()) {
      const c=captures.find(c=>c.spotId===spot);
      const photo={id:m.photoIdFor(spot,755+index),spotId:spot,capturedAtSeconds:755+index,recipe:c.recipe,tags:c.tags};
      if(spot==='lake_center')j.mainPhoto=photo;else j.optionalPhotos[spot]=photo;
      j.publishedSpotIds.push(spot);
    }
    const input={capsizeCount:seed%3,dockCollisionCount:seed%7,swanAlertLevel:seed%4};
    projections.push({journal:j,input,expected:m.projectJournalThread(j,input)});
  }
  const fixture={captures,projections};
  await writeFile('godot_native/tests/fixtures/qizhen_journal.json',JSON.stringify(fixture,null,2)+'\n');
  console.log('Exported original TypeScript journal recipes/tags + 5 complete seeded thread projections');
} finally {await rm(dir,{recursive:true,force:true});}
