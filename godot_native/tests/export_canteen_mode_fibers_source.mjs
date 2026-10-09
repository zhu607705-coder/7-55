// Execute the original scene methods and installed Phaser easing/TweenData.
// Test-only source oracle; never loaded by the native game.
import assert from 'node:assert/strict';
import fs from 'node:fs';
import path from 'node:path';
import crypto from 'node:crypto';
import vm from 'node:vm';
import {createRequire} from 'node:module';
import {fileURLToPath} from 'node:url';
const native=path.resolve(path.dirname(fileURLToPath(import.meta.url)),'..');
const flag=process.argv.indexOf('--source-root');
const root=flag<0?path.resolve(native,'..'):path.resolve(process.argv[flag+1]);
const require=createRequire(path.join(root,'package.json'));
const ts=require('typescript');
const getEase=require('phaser/src/tweens/builders/GetEaseFunction');
const TweenData=require('phaser/src/tweens/tween/TweenData');
const files=['src/scenes/rpg/CanteenInteriorScene.ts','src/scenes/rpg/CanteenInteriorModel.ts'];
const sources=files.map(file=>({file,text:fs.readFileSync(path.join(root,file),'utf8')}));
const extracted=[];
function pick(index,kind,name){
 const source=sources[index];const ast=ts.createSourceFile(source.file,source.text,ts.ScriptTarget.Latest,true);const result=[];
 function visit(node){if(kind(node)&&node.name?.getText(ast)===name){result.push(node.getText(ast));extracted.push({path:source.file,name,line:ast.getLineAndCharacterOfPosition(node.getStart(ast)).line+1,sha256:crypto.createHash('sha256').update(node.getText(ast)).digest('hex')});}ts.forEachChild(node,visit);}visit(ast);
 assert.equal(result.length,1,name);return result[0];
}
const code=`const ${pick(1,ts.isVariableDeclaration,'CANTEEN_PICKUP_WINDOWS')};
const CANTEEN_INTERIOR_WORLD={width:1672,height:941};
class Scene {
 constructor(mode,reduced){this.currentMode=mode;this.reducedMotion=reduced;this.configs=[];this.events=[];this.tweens={add:c=>{this.configs.push(c);return c},killTweensOf:()=>{}};this.add=Object.fromEntries(['rectangle','circle'].map(kind=>[kind,(...args)=>({kind,args,alpha:1,setDepth(v){this.depth=v;return this},setAlpha(v){this.alpha=v;return this},setVisible(v){this.visible=v;return this}})]));this.bridge={emit:id=>this.events.push(id)};}
 applyCanteenNpcMode(){} refreshMenuPanel(){}
 ${pick(0,ts.isMethodDeclaration,'createDarkModeLayer')}
 ${pick(0,ts.isMethodDeclaration,'playModeTransition')}
} globalThis.Scene=Scene;`;
const context=vm.createContext({});vm.runInContext(ts.transpileModule(code,{compilerOptions:{target:ts.ScriptTarget.ES2022}}).outputText,context,{timeout:1000});
const copy=x=>JSON.parse(JSON.stringify(x));
const scene=new context.Scene('dark',false);scene.createDarkModeLayer();
const fibers=scene.modeFibers.map((node,index)=>{const c=scene.configs[index];return {point:node.args.slice(0,2),radius:node.args[2],color:node.args[3],fillAlpha:node.args[4],depth:node.depth,visible:node.visible,to:[c.x,c.y],alpha:copy(c.alpha),duration:c.duration,yoyo:c.yoyo,repeat:c.repeat,ease:c.ease};});
assert.equal(fibers.length,4);
function transition(mode,reduced){const s=new context.Scene('light',reduced);s.createDarkModeLayer();s.configs=[];s.playModeTransition(mode);return s.configs.slice(1).map((c,i)=>({index:i,alpha:c.alpha,duration:c.duration,delay:c.delay,ease:c.ease??'Linear'}));}
const modes={normalDark:transition('dark',false),normalLight:transition('light',false),reducedDark:transition('dark',true),reducedLight:transition('light',true)};
const deltas=[0,...Array(128).fill(17)];
const loops=fibers.map(f=>{
 const target={mix:0};const tween={targets:[target],totalTargets:1,isSeeking:true,callbacks:{},emit(){}};
 const td=new TweenData(tween,0,'mix',()=>1,()=>0,null,getEase(f.ease),()=>0,f.duration,f.yoyo,0,f.repeat,0,false,false,null,null);
 td.reset();
 return {samples:deltas.map(delta=>{td.update(delta);return target.mix})};
});
const ease=getEase('Stepped');assert.deepEqual([0,.001,.25,.5,.999,1].map(v=>ease(v)),[0,1,1,1,1,1]);
const result={sourceMethods:extracted,phaserVersion:require('phaser/package.json').version,fibers,modes,deltas,loops};
const target=path.join(native,'tests/fixtures/canteen_mode_fibers_source.json');const serialized=JSON.stringify(result,null,2)+'\n';
if(process.argv.includes('--check')){assert.equal(fs.readFileSync(target,'utf8'),serialized,'mode-fiber source fixture is stale');console.log('Canteen mode-fiber source oracle: four circles, four mode transitions and 516 actual Phaser TweenData samples verified');}
else{fs.writeFileSync(target,serialized);console.log(target);}
