// Execute the original TS mixer methods with a recording Phaser surface. No
// source code is imported by the shipped game; this is an independent oracle.
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
const sourcePath='src/scenes/rpg/CanteenInteriorScene.ts';
const source=fs.readFileSync(path.join(root,sourcePath),'utf8');
const ast=ts.createSourceFile(sourcePath,source,ts.ScriptTarget.Latest,true);
const names=['openMixerPanel','handleMixerPointer','closeMixerPanel','refreshMixerPanel'];
const methods=[];
function walk(node){
 if(ts.isMethodDeclaration(node)&&names.includes(node.name?.getText(ast)))methods.push(node.getText(ast));
 ts.forEachChild(node,walk);
}
walk(ast);
if(methods.length!==names.length)throw Error('Source mixer method topology changed');
const content=JSON.parse(fs.readFileSync(path.join(root,'src/data/chapter3-canteen.content.json'),'utf8'));
function makeNode(type,args=[]){
 const node={type,args,children:[],draws:[],destroyed:false};
 for(const method of ['setScrollFactor','setDepth','setStrokeStyle','setOrigin','setFillStyle','setText','setColor'])node[method]=(...values)=>{node[method.slice(3)]=values;return node;};
 node.add=children=>{node.children.push(...children);return node;};
 node.destroy=()=>{node.destroyed=true;};
 node.fillStyle=(color,alpha)=>{node.fill=[color,alpha];return node;};
 node.fillRect=(...rect)=>{node.draws.push({color:node.fill[0],alpha:node.fill[1],rect});return node;};
 node.lineStyle=()=>node;node.lineBetween=()=>node;
 return node;
}
const shuffled=[];
const context=vm.createContext({canteenContent:content,toRpgLogicalScreenPoint:(_self,x,y)=>({x,y}),Phaser:{Utils:{Array:{Shuffle:()=>shuffled.slice()}}}});
const program=`class SourceMixer { constructor(state) { this.state=state;this.events=[];this.feedback=[];this.mixerPanel=null;this.mixerButtonOrder=[];this.add={container:(...a)=>record('container',a),rectangle:(...a)=>record('rectangle',a),text:(...a)=>record('text',a),graphics:()=>record('graphics')};this.bridge={getState:()=>this.state,emit:(id,payload)=>this.events.push({id,payload})}; } hasModalPanel(){return this.mixerPanel!==null;} showFeedback(...values){this.feedback.push(values);} ${methods.join('\n')} }; globalThis.SourceMixer=SourceMixer;`;
context.record=makeNode;
vm.runInContext(ts.transpileModule(program,{compilerOptions:{target:ts.ScriptTarget.ES2022}}).outputText,context,{timeout:1000});
const recipe=['blackCoffee','sparklingWater','lemonTea'];
function permutations(values){return values.length?values.flatMap((item,i)=>permutations(values.filter((_,j)=>i!==j)).map(tail=>[item,...tail])):[[]];}
const orders=permutations(recipe).map(input=>{
 shuffled.splice(0,3,...input);
 const state={items:Object.fromEntries(recipe.map(id=>[id,true])),canteenHunt:{drinkMixSequence:[],drinkShelfRead:false}};
 const scene=new context.SourceMixer(state);scene.openMixerPanel();
 const initial=Array.from(scene.mixerButtonOrder);
 state.items[initial[0]]=false;state.canteenHunt.drinkMixSequence=[initial[0]];scene.refreshMixerPanel();
 const refreshed=Array.from(scene.mixerButtonOrder);
 scene.closeMixerPanel();
 return {input,order:initial,refreshOrder:refreshed,closedOrder:Array.from(scene.mixerButtonOrder),partialAfterClose:state.canteenHunt.drinkMixSequence};
});
shuffled.splice(0,3,'lemonTea','blackCoffee','sparklingWater');
const state={items:{blackCoffee:true,sparklingWater:false,lemonTea:true},canteenHunt:{drinkMixSequence:['lemonTea','blackCoffee'],drinkShelfRead:false}};
const scene=new context.SourceMixer(state);scene.openMixerPanel();
function snapshot(){
 const nodes=scene.mixerPanel.children;
 return {order:Array.from(scene.mixerButtonOrder),texts:nodes.filter(n=>n.type==='text').map(n=>({x:n.args[0],y:n.args[1],text:n.args[2],style:n.args[3]})),layers:nodes.find(n=>n.type==='graphics').draws.slice(1)};
}
const unread=snapshot();
scene.handleMixerPointer({x:690,y:405}); // Missing sparkling water stays visible.
const missing={events:scene.events.slice(),feedback:scene.feedback.slice()};
scene.handleMixerPointer({x:270,y:405});
const pour=scene.events.slice();
state.canteenHunt.drinkShelfRead=true;scene.refreshMixerPanel();
const read=snapshot();
scene.handleMixerPointer({x:480,y:100});
const outsideKeepsOpen=scene.mixerPanel!==null;
scene.handleMixerPointer({x:754,y:75});
const exitCloses=scene.mixerPanel===null;
const fixture={source:sourcePath,sourceSha256:crypto.createHash('sha256').update(source).digest('hex'),orders,unread,read,missing,pour,outsideKeepsOpen,exitCloses};
const target=path.join(native,'tests/fixtures/canteen_mixer_source.json');
const serialized=JSON.stringify(fixture,null,2)+'\n';
if(process.argv.includes('--check')){
 if(fs.readFileSync(target,'utf8')!==serialized)throw Error('Canteen mixer source fixture is stale');
 console.log('Canteen mixer fixture matches executed original TypeScript methods');
}else{fs.writeFileSync(target,serialized);console.log(target);}
