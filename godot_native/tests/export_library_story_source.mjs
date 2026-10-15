// Source-evaluated parity fixture for the exact active LibraryStoryOverlay route.
import fs from 'node:fs';
import vm from 'node:vm';
import crypto from 'node:crypto';
import ts from 'typescript';
import { fileURLToPath } from 'node:url';
const root=fileURLToPath(new URL('../../',import.meta.url));
const read=path=>fs.readFileSync(root+path,'utf8');
const content=JSON.parse(read('src/data/library-finals.content.json'));
const app=read('src/App.tsx');
const overlay=read('src/components/LibraryStoryOverlay.tsx');
const audio=read('src/modules/AudioDirector.ts');
const helpers=audio.slice(audio.indexOf('function visibleGraphemeCount'),audio.indexOf('function toastTone'));
const evalTS=(code,result)=>{
 const js=ts.transpileModule(code,{compilerOptions:{target:ts.ScriptTarget.ES2022,module:ts.ModuleKind.None}}).outputText.replace(/export /g,'');
 const ctx=vm.createContext({Intl,Math,Array,Object,Set,exports:{}}); vm.runInContext(js+`;result=${result};`,ctx,{timeout:1000}); return ctx.result;
};
const maps=evalTS(app.slice(app.indexOf('const LIBRARY_STORY_SEQUENCE_BY_EVENT:'),app.indexOf('function getSnapshot()')),'({eventMap:LIBRARY_STORY_SEQUENCE_BY_EVENT,delays:LIBRARY_STORY_DELAY_BY_EVENT})');
const confirmation=evalTS(overlay.slice(overlay.indexOf('const CONFIRMATION_REQUIRED_SEQUENCES'),overlay.indexOf('/** 第二章')),'Array.from(CONFIRMATION_REQUIRED_SEQUENCES)');
const duration=evalTS(helpers,'textFeedbackDuration');
const sequences=Object.fromEntries(Object.entries(content.storyDialogues).map(([id,lines])=>[id,lines.map((line,index)=>({...line,lineKey:`library_story_${id}_${String(index+1).padStart(2,'0')}`,durationMs:duration(line.text)}))]));
const files=['src/App.tsx','src/components/LibraryStoryOverlay.tsx','src/data/libraryFinalsStory.ts','src/data/library-finals.content.json','src/modules/LibraryFinalsController.ts','src/modules/AudioDirector.ts'];
const fixture={sources:files.map(path=>({path,sha256:crypto.createHash('sha256').update(read(path)).digest('hex')})),...maps,confirmation,sequenceCount:Object.keys(sequences).length,lineCount:Object.values(sequences).reduce((sum,lines)=>sum+lines.length,0),ignoredUnresolvedSequenceIds:['library_route_unlocked'],separateOwner:{sequenceId:'library_friend_contacted',native:'scripts/presentation/c3_scene_session.gd',lineCount:content.library.dialogue022.length},sequences};
if (read('src/data/library-finals.content.json')!==read('godot_native/data/source/library-finals.content.json')) throw Error('Native library source content diverged');
const path=root+'godot_native/tests/fixtures/library_story_source.json';
const serialized=JSON.stringify(fixture,null,2)+'\n';
if(process.argv.includes('--check')) {if(fs.readFileSync(path,'utf8')!==serialized)throw Error('Library story source fixture is stale'); console.log(`Library story source parity: ${fixture.sequenceCount} sequences, ${fixture.lineCount} lines`);} else {fs.writeFileSync(path,serialized); console.log(path);}
