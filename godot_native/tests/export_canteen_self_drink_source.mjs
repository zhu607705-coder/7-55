// Execute the original source drop/controller/dialogue methods as an independent
// oracle. Never loaded by the native runtime.
import fs from 'node:fs';
import path from 'node:path';
import vm from 'node:vm';
import crypto from 'node:crypto';
import {createRequire} from 'node:module';
import {fileURLToPath} from 'node:url';
const native=path.resolve(path.dirname(fileURLToPath(import.meta.url)),'..');
const flag=process.argv.indexOf('--source-root');
const root=flag<0?path.resolve(native,'..'):path.resolve(process.argv[flag+1]);
const ts=createRequire(path.join(root,'package.json'))('typescript');
const sourceFiles=['src/scenes/rpg/CanteenInteriorScene.ts','src/modules/ChapterThreeCanteenController.ts','src/data/itemCatalog.ts','src/data/chapter3-canteen.content.json'];
const sources=sourceFiles.map(file=>({file,text:fs.readFileSync(path.join(root,file),'utf8')}));
function pick(index,kind,name){
 const ast=ts.createSourceFile(sources[index].file,sources[index].text,ts.ScriptTarget.Latest,true);
 let result=[];function walk(node){if(kind(node)&&node.name?.getText(ast)===name)result.push(node.getText(ast));ts.forEachChild(node,walk);}walk(ast);
 if(result.length!==1)throw Error(`Expected one ${name}, got ${result.length}`);return result[0];
}
const method=(index,name)=>pick(index,ts.isMethodDeclaration,name);
const decl=(index,name)=>'const '+pick(index,ts.isVariableDeclaration,name)+';';
const content=JSON.parse(sources[3].text);
const context=vm.createContext({Phaser:{Math:{Distance:{Between:(a,b,c,d)=>Math.hypot(a-c,b-d)}}}});
const program=`${decl(1,'CANTEEN_SIDE_GAME_PHASES')} ${pick(1,ts.isFunctionDeclaration,'canPlayCanteenSideGames')}
${decl(0,'DIALOGUE_STEP_MS')}
class Scene {
 constructor(){this.state={};this.events=[];this.player={x:500,y:500};this.bridge={getState:()=>this.state,emit:(id,payload)=>this.events.push({id,payload})};this.cameras={main:{getWorldPoint:(x,y)=>({x,y})}};}
 ${method(0,'handleInventoryDrop')} ${method(0,'queueDialogue')}
}
class Controller {
 constructor(state){this.state=state;this.events=[];this.store={getState:()=>this.state,setState:f=>this.state=f(this.state)};this.events={emit:(id,payload)=>this.emitted.push({id,payload})};this.emitted=[];}
 ${method(1,'drinkBadDrink')}
}
globalThis.Scene=Scene;globalThis.Controller=Controller;`;
vm.runInContext(ts.transpileModule(program,{compilerOptions:{target:ts.ScriptTarget.ES2022}}).outputText,context,{timeout:1000});
const geometry=[];
for(const offset of [[0,-24],[58,-24],[-58,-24],[0,34],[0,-82],[58.01,-24],[0,34.01],[0,-82.01],[41,-65],[42,-66],[0,0],[0,41.6]]){
 const scene=new context.Scene();scene.handleInventoryDrop({itemId:'badDrink',canvasX:500+offset[0],canvasY:500+offset[1]});
 geometry.push({offset,accepted:scene.events.some(e=>e.id==='rpg_canteen_bad_drink_requested'),feedback:scene.events.find(e=>e.id==='rpg_item_use_feedback').payload});
}
const eligibility=[];
for(const phase of ['tray_search','drink_mix','menu_order','pickup_search','chase_ready','tracking','entered','exit_blocking','chasing','theater_reached'])for(const active of [true,false])for(const mode of ['light','dark'])for(const owned of [true,false]){
 const state={canteenHunt:{phase,active,mode},items:{badDrink:owned}};const c=new context.Controller(state);
 const accepted=c.drinkBadDrink();const repeated=c.drinkBadDrink();eligibility.push({phase,active,mode,owned,accepted,repeated,remaining:c.state.items.badDrink,events:c.emitted});
}
const scene=new context.Scene();const timers=[];scene.time={delayedCall:(atMs,fn)=>timers.push({atMs,fn})};scene.showFeedback=(text,tone,durationMs)=>{scene.feedback.push({text,tone,durationMs})};scene.dialogueToneFor=text=>text.split('：')[0];scene.feedback=[];scene.queueDialogue(content.drinks.badDrinkConsumed);for(const timer of timers)timer.fn();
if(!sources[2].text.includes('badDrink: object([{ target: "rpg-player", result: "consume" }])'))throw Error('Self target changed');
const result={sources:sources.map(v=>({path:v.file,sha256:crypto.createHash('sha256').update(v.text).digest('hex')})),geometry,eligibility,dialogue:{lines:content.drinks.badDrinkConsumed,atMs:timers.slice(0,-1).map(t=>t.atMs),completeAtMs:timers.at(-1).atMs,durationMs:scene.feedback.map(f=>f.durationMs),lockedAfterComplete:scene.dialogueLocked}};
const target=path.join(native,'tests/fixtures/canteen_self_drink_source.json');const serialized=JSON.stringify(result,null,2)+'\n';
if(process.argv.includes('--check')){if(fs.readFileSync(target,'utf8')!==serialized)throw Error('Self-drink source fixture is stale');console.log('Canteen self-drink source oracle verified');}else{fs.writeFileSync(target,serialized);console.log(target);}
