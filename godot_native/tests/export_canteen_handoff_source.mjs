import assert from 'node:assert/strict';
import crypto from 'node:crypto';
import fs from 'node:fs';
import path from 'node:path';
import vm from 'node:vm';
import {createRequire} from 'node:module';
import {fileURLToPath} from 'node:url';

// Execute the existing QuestModel function, rather than restating its branches.
const flag=process.argv.indexOf('--source-root');
assert(flag>=0 && process.argv[flag+1], 'Provide --source-root /path/to/original/repository');
const root=path.resolve(process.argv[flag+1]);
const ts=createRequire(path.join(root,'package.json'))('typescript');
const source=fs.readFileSync(path.join(root,'src/core/QuestModel.ts'),'utf8');
const content=fs.readFileSync(path.join(root,'src/data/chapter3-canteen.content.json'),'utf8');
const ast=ts.createSourceFile('QuestModel.ts',source,ts.ScriptTarget.Latest,true);
const found=ast.statements.filter(n=>ts.isFunctionDeclaration(n)&&n.name?.text==='canteenInteriorTask');
assert.equal(found.length,1);
const context=vm.createContext({canteenContent:JSON.parse(content)});
vm.runInContext(ts.transpileModule(found[0].getText(ast)+'\nglobalThis.task=canteenInteriorTask;',{
  compilerOptions:{target:ts.ScriptTarget.ES2022}
}).outputText,context);
const cases=[];
for (const phase of ['tray_search','drink_mix']) {
  for (let flags=0;flags<16;flags++) for(let count=0;count<3;count++) {
    const hunt={active:true,phase,entryPaperEscaped:true,trayTaskStarted:true,
      returnedTrayIds:['tray_blue_01','tray_blue_02','tray_blue_03'],carriedTrayIds:[],queueGapOpened:false,
      queueChallengeSeen:!!(flags&1),drinkShelfRead:!!(flags&2),promoDrinkPlaced:!!(flags&4),
      drinkMixSequence:['blackCoffee','sparklingWater'].slice(0,count)};
    const items={dailySpecialSparklingWater:!!(flags&8)};
    const result=context.task({canteenHunt:hunt,items});
    cases.push({hunt,items,id:result.id.replace('chapter_three_canteen_',''),title:result.label});
  }
}
const menuCases=[];
for(const mode of ['light','dark']) for(const menuDarkClueRead of [false,true]) for(const queueGapOpened of [false,true]) {
  const hunt={...structuredClone(cases[0].hunt),phase:'menu_order',mode,queueChallengeSeen:true,
    drinkShelfRead:true,promoDrinkPlaced:true,queueGapOpened,menuDarkClueRead};
  const items={dailySpecialSparklingWater:false};
  const result=context.task({canteenHunt:hunt,items});
  menuCases.push({hunt,items,mode,id:result.id.replace('chapter_three_canteen_',''),title:result.label,
    detail:result.hints.join('\n')});
}
const pickupCases=[];
for(const mode of ['light','dark']) for(const menuDarkClueRead of [false,true])
  for(const pickupDarkClueRead of [false,true]) for(const orderedMenuOption of ['A','B','C','D','E']) {
    const hunt={...structuredClone(menuCases.at(-1).hunt),phase:'pickup_search',mode,
      menuDarkClueRead,pickupDarkClueRead,orderedMenuOption};
    const items={dailySpecialSparklingWater:false,pickupTicket0755:true};
    const result=context.task({canteenHunt:hunt,items});
    pickupCases.push({hunt,items,mode,id:result.id.replace('chapter_three_canteen_',''),
      title:result.label,detail:result.hints.join('\n')});
  }
// Earlier source facts retain precedence even in an inconsistent phase fixture.
for(const patch of [{entryPaperEscaped:false},{trayTaskStarted:false},{returnedTrayIds:[]},
  {queueGapOpened:false,queueChallengeSeen:false},
  {queueGapOpened:false,drinkShelfRead:false},
  {queueGapOpened:false,promoDrinkPlaced:false},{queueGapOpened:false}]) {
  const hunt={...structuredClone(pickupCases[0].hunt),...patch};
  const items={dailySpecialSparklingWater:false,pickupTicket0755:true};
  const result=context.task({canteenHunt:hunt,items});
  pickupCases.push({hunt,items,mode:hunt.mode,id:result.id.replace('chapter_three_canteen_',''),
    title:result.label,detail:result.hints.join('\n')});
}
const result={provenance:{function:'src/core/QuestModel.ts:canteenInteriorTask',
  line:ast.getLineAndCharacterOfPosition(found[0].getStart(ast)).line+1,
  functionSha256:crypto.createHash('sha256').update(found[0].getText(ast)).digest('hex'),
  contentSha256:crypto.createHash('sha256').update(content).digest('hex')},cases,menuCases,pickupCases};
const output=path.join(path.dirname(fileURLToPath(import.meta.url)),'fixtures/canteen_handoff_source.json');
const serialized='{\n  "provenance": '+JSON.stringify(result.provenance)+',\n  "cases": [\n'+
  result.cases.map(record=>'    '+JSON.stringify(record)).join(',\n')+'\n  ],\n  "menuCases": [\n'+
  result.menuCases.map(record=>'    '+JSON.stringify(record)).join(',\n')+'\n  ],\n  "pickupCases": [\n'+
  result.pickupCases.map(record=>'    '+JSON.stringify(record)).join(',\n')+'\n  ]\n}\n';
if(process.argv.includes('--check')) assert.equal(fs.readFileSync(output,'utf8'),serialized);
else fs.writeFileSync(output,serialized);
console.log(`Canteen handoff source: ${cases.length} drink and ${menuCases.length} menu and ${pickupCases.length} pickup executed-QuestModel fixtures ${process.argv.includes('--check')?'verified':'written'}`);
