// Evaluate only the original pure opening-timeline helpers, not a rewritten list.
import fs from 'node:fs';
import vm from 'node:vm';
import ts from 'typescript';
import { fileURLToPath } from 'node:url';
const root=fileURLToPath(new URL('../../',import.meta.url));
const source=fs.readFileSync(root+'src/components/ChapterThreeOpeningOverlay.tsx','utf8');
const helper=source.slice(source.indexOf('const MAX_SIMULATION_STEP_MS'),source.indexOf('function clamp('));
const js=ts.transpileModule(helper,{compilerOptions:{target:ts.ScriptTarget.ES2022,module:ts.ModuleKind.CommonJS}}).outputText;
const lines=JSON.parse(fs.readFileSync(root+'src/data/library-finals.content.json','utf8')).library.dialogue022;
const context=vm.createContext({lines});
vm.runInContext(js+';result={normal:createOpeningBeats(lines,false),reduced:createOpeningBeats(lines,true)}',context,{timeout:1000});
const fixture={source:'src/components/ChapterThreeOpeningOverlay.tsx:createOpeningBeats',...context.result};
const path=root+'godot_native/tests/fixtures/chapter3_scene_source.json';
const serialized=JSON.stringify(fixture,null,2)+'\n';
if(process.argv.includes('--check')) {
  if(fs.readFileSync(path,'utf8')!==serialized) throw Error('Chapter 3 opening source fixture is stale');
  console.log('Chapter 3 native opening fixture matches original TS helper');
} else {fs.writeFileSync(path,serialized);console.log(path);}
