import fs from 'node:fs';
import path from 'node:path';
import { stripTypeScriptTypes } from 'node:module';
import { createHash } from 'node:crypto';
const args=process.argv.slice(2).filter(value=>value!=='--check');
const root=path.resolve(args[0]??path.join(import.meta.dirname,'../..'));
const output=path.resolve(args[1]??path.join(root,'godot_native'));
async function load(file){ const text=fs.readFileSync(path.join(root,file),'utf8'); const js=stripTypeScriptTypes(text,{mode:'transform'}); return {module:await import('data:text/javascript;base64,'+Buffer.from(js).toString('base64')),hash:createHash('sha256').update(text).digest('hex')}; }
const context=await load('src/data/ChapterFourInteractionContent.ts');
const exterior=await load('src/modules/ChapterFourExteriorDoorContract.ts');
const ids=['a2_lecture_room_202_context','a3_report_hall_304_context'];
const entries=context.module.CHAPTER_FOUR_CONTEXT_INTERACTIONS.filter(x=>ids.includes(x.targetId));
let checks=0;
for(const entry of entries) for(const [time,modes] of Object.entries(entry.textByTimeState)) for(const [mode,text] of Object.entries(modes)) {
 if(context.module.selectChapterFourContextInteractionText({targetId:entry.targetId,phase:'room204_restore',timeState:time,mode})!==text)throw Error('source mismatch'); checks++;
 if(context.module.selectChapterFourContextInteractionText({targetId:entry.targetId,phase:'final_chase',timeState:time,mode})!==null)throw Error('source phase gate'); checks++;
}
const data={contexts:entries,door:exterior.module.CHAPTER_FOUR_EXTERIOR_DOOR,presentationMs:exterior.module.CHAPTER_FOUR_EXTERIOR_DOOR_PRESENTATION_MS,sourceHashes:{context:context.hash,exterior:exterior.hash},executedSourceChecks:checks};
const target=path.join(output,'data/native/chapter4-context-source.json'), serialized=JSON.stringify(data,null,2)+'\n';
if(process.argv.includes('--check')){if(fs.readFileSync(target,'utf8')!==serialized)throw Error('C4 context source catalog stale');}
else{fs.mkdirSync(path.dirname(target),{recursive:true});fs.writeFileSync(target,serialized);}
console.log(`C4_CONTEXT_SOURCE ${checks} checks; ${entries.length} authored contexts and exact exterior timing exported`);
