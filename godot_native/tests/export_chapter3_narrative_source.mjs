// Execute the original scene queue methods with a deterministic read-only timer.
// Do not mirror the native queue's algorithm as its own oracle.
import fs from 'node:fs';
import vm from 'node:vm';
import crypto from 'node:crypto';
import ts from 'typescript';
import { fileURLToPath } from 'node:url';
const root=fileURLToPath(new URL('../../',import.meta.url));
const read=p=>fs.readFileSync(root+p,'utf8');
const data=id=>JSON.parse(read(`src/data/${id}.json`));
const sourcePaths=['src/scenes/rpg/CanteenInteriorScene.ts','src/scenes/rpg/TheaterInteriorScene.ts','src/scenes/rpg/QizhenLoopScene.ts','src/modules/AudioDirector.ts','src/data/chapter3-canteen.content.json','src/data/chapter3-theater.content.json','src/data/chapter3-qizhen-lake.content.json','src/data/maps/zijingang-campus-loop-runtime.json'];
const canteen=data('chapter3-canteen.content'),theater=data('chapter3-theater.content'),lake=data('chapter3-qizhen-lake.content');
for(const id of ['chapter3-canteen.content','chapter3-theater.content','chapter3-qizhen-lake.content'])if(read(`src/data/${id}.json`)!==read(`godot_native/data/source/${id}.json`))throw Error(`Copied source drift: ${id}`);
function method(path,name){const text=read(path),file=ts.createSourceFile(path,text,ts.ScriptTarget.Latest,true);let found;function visit(node){if(ts.isMethodDeclaration(node)&&node.name.getText(file)===name)found=node.getText(file);ts.forEachChild(node,visit)}visit(file);if(!found)throw Error(name);return found}
const audio=read('src/modules/AudioDirector.ts');
const helpers=audio.slice(audio.indexOf('function visibleGraphemeCount'),audio.indexOf('function toastTone')).replaceAll('export ','');
function queue(kind,lines,step){
 const path=sourcePaths[kind==='canteen'?0:kind==='theater'?1:2];
 const name=kind==='approach'?'queueTransitionSubtitles':'queueDialogue';
 const constants=[...read(path).matchAll(/^const (DIALOGUE_STEP_MS|TRANSITION_[A-Z_]+) = (\d+);/gm)].map(m=>`const ${m[1]}=${m[2]};`).join('\n');
 const script=`${helpers}\n${constants}\nclass Original {${method(path,name)}};const owner=new Original();owner.time={delayedCall(at,fn){timers.push({at,fn})}};owner.dialogueToneFor=()=>'';owner.dialogueSpeakerFor=()=>undefined;owner.flushPendingFeedback=()=>{};owner.animateTicketCombine=()=>{};owner.showFeedback=owner.emitSubtitle=(text,tone,durationMs)=>out.push({text,atMs:now,durationMs});owner.${name}(${kind==='approach'?'visual,lines':'lines,()=>{complete=now},step'});timers.sort((a,b)=>a.at-b.at);for(const timer of timers){now=timer.at;timer.fn()}`;
 const ctx=vm.createContext({Intl,Math,Array,Object,Set,lines,visual:lake.locationSearch.approachTransition.visualBeats,step,timers:[],out:[],now:0,complete:null,exports:{}});
 vm.runInContext(ts.transpileModule(script,{compilerOptions:{target:ts.ScriptTarget.ES2022,module:ts.ModuleKind.None}}).outputText,ctx,{timeout:1000});
 return {lines:ctx.out,completeAtMs:ctx.complete};
}
const groups={
 canteen_tray_intro:queue('canteen',canteen.tray.introDialogue),
 canteen_tray_complete:queue('canteen',[canteen.tray.correctReturn,...canteen.tray.completionDialogue]),
 canteen_tray_done:queue('canteen',[canteen.tray.afterCompletion]),
 canteen_tray_return:queue('canteen',[canteen.tray.correctReturn]),
 canteen_queue:queue('canteen',canteen.drinks.queueDialogue),
 canteen_bad_drink:queue('canteen',canteen.drinks.badDrinkConsumed),
 canteen_queue_shift:queue('canteen',canteen.drinks.queueShiftDialogue),
 canteen_order_correct:queue('canteen',canteen.menu.correct),
 canteen_order_wrong:queue('canteen',canteen.menu.wrongGeneric),
 canteen_pickup_clue:queue('canteen',[canteen.pickup.darkClueRead]),
 canteen_escape:queue('canteen',canteen.blocking.escapeDialogue,1200),
 theater_entry:queue('theater',theater.entryDialogue),
 theater_printed:queue('theater',[theater.ticket.ticketPrinted]),
 theater_combined:queue('theater',theater.ticket.combinedDialogue),
 theater_admission:queue('theater',theater.ticket.admissionDialogue),
 theater_wrong_order:queue('theater',theater.program.wrongDialogue),
 theater_prop_ghost:queue('theater',[theater.prop.ghost,theater.prop.managerHint]),
 theater_console:queue('theater',[theater.program.consolePrompt,theater.program.consoleState]),
 theater_reversal_before:queue('theater',theater.spotlight.endingDialogue.slice(0,2)),
 theater_reversal_after:queue('theater',theater.spotlight.endingDialogue.slice(2)),
 qizhen_approach:queue('approach',lake.locationSearch.dialogue)
};
const fixture={sources:sourcePaths.map(path=>({path,sha256:crypto.createHash('sha256').update(read(path)).digest('hex')})),groups,approach:lake.locationSearch.approachTransition,route:data('maps/zijingang-campus-loop-runtime').qizhen.approachTransition};
const output=root+'godot_native/tests/fixtures/chapter3_narrative_source.json',serialized=JSON.stringify(fixture,null,2)+'\n';
if(process.argv.includes('--check')){if(read('godot_native/tests/fixtures/chapter3_narrative_source.json')!==serialized)throw Error('C3 source queue fixture stale');console.log(`C3 original scene queues: ${Object.keys(groups).length} groups verified`)}else{fs.writeFileSync(output,serialized);console.log(output)}
