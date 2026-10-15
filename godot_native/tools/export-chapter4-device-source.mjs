import fs from 'node:fs';
import path from 'node:path';
import vm from 'node:vm';
import { createRequire } from 'node:module';
const args = process.argv.slice(2).filter(value=>value!=='--check');
const checkOnly = process.argv.includes('--check');
const root = path.resolve(args[0] || new URL('../../',import.meta.url).pathname);
const destination = path.resolve(args[1] || new URL('../',import.meta.url).pathname);
const require = createRequire(path.join(root,'package.json'));
const ts = require('typescript');
const files = {
 model: 'src/modules/ChapterFourInsertedPuzzleModel.ts',
 game: 'src/components/temporal-maze/ChapterFourInsertedPuzzleGame.tsx',
 preview: 'src/components/temporal-maze/ChapterFourPuzzlePreview.tsx',
 assets: 'src/scenes/rpg/ChapterFourInsertedPuzzleAssets.ts'
};
let hooks = [], hookIndex = 0;
const react = {useEffect(){},useRef(){return {current:null}},useMemo(fn){return fn()},useId(){return 'source-oracle'},useState(value){const i=hookIndex++; if (!(i in hooks)) hooks[i]=structuredClone(value);return [hooks[i],next=>{hooks[i]=typeof next==='function'?next(hooks[i]):next}];}};
const jsx = (type,props,key)=>({type,props:props||{},key});
function compile(source,name,dependencies={}) {
 const output=ts.transpileModule(source,{compilerOptions:{module:ts.ModuleKind.CommonJS,jsx:ts.JsxEmit.ReactJSX,target:ts.ScriptTarget.ES2022}}).outputText;
 const exports={};
 vm.runInNewContext(output,{exports,require(name){if(name==='react')return react;if(name==='react/jsx-runtime')return {jsx,jsxs:jsx,Fragment:'fragment'};if(name.endsWith('.png'))return {default:'res://assets/'+name.split('/assets/')[1]};for(const [suffix,obj] of Object.entries(dependencies)) if(name.endsWith(suffix))return obj;throw Error('Unexpected source dependency '+name)},Object,console},{filename:name});
 return exports;
}
const model=compile(fs.readFileSync(path.join(root,files.model),'utf8'),files.model);
const nativePreview=compile(fs.readFileSync(path.join(root,files.preview),'utf8'),files.preview,{ChapterFourInsertedPuzzleModel:model});
const assets=compile(fs.readFileSync(path.join(root,files.assets),'utf8'),files.assets);
const game=compile(fs.readFileSync(path.join(root,files.game),'utf8')+'\nexport { DUTY_LABELS, EVACUATION_LABELS, POWER_EDGE_LABELS, ObservationTrace, PuzzleControls };',files.game,{ChapterFourInsertedPuzzleModel:model,ChapterFourInsertedPuzzleAssets:assets,ChapterFourPuzzlePreview:{ChapterFourPuzzlePreview:(props)=>jsx('source-preview',props)}});
function expand(node){if(Array.isArray(node))return node.flatMap(expand);if(node===null||node===undefined||typeof node==='boolean')return [];if(typeof node!=='object')return [node];if(typeof node.type==='function')return expand(node.type(node.props));return [{...node,children:expand(node.props.children)}]}
function flatten(node){return expand(node).flatMap(n=>typeof n==='object'?[n,...flatten(n.children)]:[n])}
function all(node){const out=[];function walk(n){if(Array.isArray(n))return n.forEach(walk);if(!n||typeof n!=='object')return;out.push(n);(n.children||[]).forEach(walk)}walk(expand(node));return out}
function text(node){if(Array.isArray(node))return node.map(text).join('');if(typeof node==='object'&&node)return text(node.children||node.props?.children);return node==null||typeof node==='boolean'?'':String(node)}
function render(id,props={}){hookIndex=0;return expand(game.ChapterFourInsertedPuzzleGame({puzzleId:id,mode:'light',completed:false,prerequisiteReady:true,pending:false,feedback:null,onSubmit(){},onClose(){},...props}));}
const first=render('duty_board');
const defaults=all(first).find(n=>n.type==='source-preview').props.state;
const traces={};const options={};const ranges={};const axes={};
for(const id of model.CHAPTER_FOUR_INSERTED_PUZZLE_IDS){
 traces[id]=all(game.ObservationTrace({puzzleId:id})).filter(n=>n.type==='li').map(text);
 hooks=[];render(id);
 const controls=game.PuzzleControls({puzzleId:id,pending:false,...defaults,setDutyOrder(){},setArchiveYearBand(){},setArchiveFloor(){},setArchivePurpose(){},setMediaAlignment(){},setCalibration(){},setPowerEdges(){},setEvacuationOrder(){}});
 if(controls.props.ranges){ranges[id]=controls.props.ranges;axes[id]=controls.props.labels;}
 if(id==='archive_index')for(const label of all(controls).filter(n=>n.type==='label')){const select=all(label).find(n=>n.type==='select');const key=['年代','楼层','用途'].indexOf(text(label).slice(0,2));options[['yearBand','floor','purpose'][key]]=all(select).filter(n=>n.type==='option').map(n=>({value:n.props.value,label:text(n)}));}
}
const runtime={definitions:model.CHAPTER_FOUR_INSERTED_PUZZLES,registration:model.CHAPTER_FOUR_DEVICE_REGISTRATION,defaults:JSON.parse(JSON.stringify(defaults)),traces,labels:{...game.DUTY_LABELS,...game.EVACUATION_LABELS,...Object.fromEntries(options.purpose.filter(x=>x.value).map(x=>[x.value,x.label]))},edges:game.POWER_EDGE_LABELS,options,ranges,axes,assets:assets.CHAPTER_FOUR_INSERTED_PUZZLE_ASSET_BY_ID};
const correct={duty_board:{order:['classroom_104','classroom_105','main_elevator']},archive_index:{yearBand:'1991_1998',floor:'A3',purpose:'wayfinding'},media_alignment:{xOffset:2,yOffset:-1,rotationQuarterTurns:1},positioning_calibration:{horizontal:-2,vertical:1,pressure:3},power_topology:{edgeIds:Object.keys(game.POWER_EDGE_LABELS).slice(0,5)},evacuation_route:{order:['lecture_202_door','east_corridor','transport_core','main_stair_down']}};
const wrong={duty_board:{order:defaults.dutyOrder},archive_index:{yearBand:'1977_1984',floor:'A1',purpose:'attendance'},media_alignment:defaults.mediaAlignment,positioning_calibration:defaults.calibration,power_topology:{edgeIds:Object.keys(game.POWER_EDGE_LABELS).slice(2)},evacuation_route:{order:defaults.evacuationOrder}};
function sourceProjection(id,state){
 const tree=expand(nativePreview.ChapterFourPuzzlePreview({puzzleId:id,state}));
 const result={caption:text(all(tree).find(n=>n.type==='output'))};
 function translate(value){const match=/translate\(\s*(-?[\d.]+)(?:px)?[ ,]+(-?[\d.]+)(?:px)?\s*\)/.exec(value||'');return match?[Number(match[1]),Number(match[2])]:[0,0]}
 function walk(nodes,parent=[0,0]){
  for(const n of nodes){if(!n||typeof n!=='object')continue;const a=translate(n.props.transform),b=translate(n.props.style?.transform);const position=[parent[0]+a[0]+b[0],parent[1]+a[1]+b[1]];
   const part=n.props['data-preview-part'];
   if(part==='film-position'||part==='calibration-stage')result.position=position;
   if(part==='film-rotation')result.rotation=Number(/rotate\((-?[\d.]+)deg\)/.exec(n.props.style.transform)[1]);
   if(part==='calibration-press'){result.pressY=position[1]+Number(all(n).find(c=>c.type==='rect').props.y);result.pressure=state.calibration.pressure;}
   walk(n.children||[],position);
  }
 }
 walk(tree);
 if(id==='power_topology')result.edges=all(tree).filter(n=>n.props?.['data-connected']).map(n=>n.props['data-preview-edge']);
 if(id==='duty_board'||id==='evacuation_route')result.order=all(tree).filter(n=>n.props?.['data-preview-order']).map(n=>n.props['data-preview-order']);
 if(id==='archive_index')result.rows=all(tree).filter(n=>n.props?.['data-preview-index']!==undefined).map(n=>{const texts=all(n).filter(c=>c.type==='text');return text(texts[1]);});
 return result;
}
const fixtures={sourceFiles:files,cases:[],sourceControlChecks:0};
function sourceCheck(value,message){fixtures.sourceControlChecks++;if(!value)throw Error(message)}
function actButton(tree,match){const b=all(tree).find(n=>n.type==='button'&&match(n));sourceCheck(!!b,'Source control exists');sourceCheck(!b.props.disabled,'Source control enabled');b.props.onClick();}
function setSourceAnswer(id,answer,props){
 let tree=render(id,props);
 const state=()=>all(render(id,props)).find(n=>n.type==='source-preview').props.state;
 if(id==='duty_board'||id==='evacuation_route'){
  const key=id==='duty_board'?'dutyOrder':'evacuationOrder';
  for(let target=0;target<answer.order.length;target++){
   let index=state()[key].indexOf(answer.order[target]);
   while(index>target){actButton(tree,n=>n.props['aria-label']===runtime.labels[answer.order[target]]+'上移');tree=render(id,props);index--;}
  }
 }else if(id==='archive_index'){
  for(const [key,label] of [['yearBand','年代'],['floor','楼层'],['purpose','用途']]){
   const owner=all(tree).find(n=>n.type==='label'&&text(n).startsWith(label));
   const select=all(owner).find(n=>n.type==='select');sourceCheck(!select.props.disabled,'Source select enabled');select.props.onChange({target:{value:answer[key]}});tree=render(id,props);
  }
 }else if(id==='power_topology'){
  for(const edge of [...state().powerEdges]){actButton(tree,n=>text(n)===runtime.edges[edge]);tree=render(id,props);}
  for(const edge of answer.edgeIds){actButton(tree,n=>text(n)===runtime.edges[edge]);tree=render(id,props);}
 }else{
  const key=id==='media_alignment'?'mediaAlignment':'calibration';
  for(const axis of Object.keys(runtime.ranges[id])){
   while(state()[key][axis]!==answer[axis]){
    const increase=state()[key][axis]<answer[axis],rotation=axis==='rotationQuarterTurns',pressure=axis==='pressure',vertical=axis==='yOffset'||axis==='vertical';
    const direction=rotation?(increase?'顺时针':'逆时针'):pressure?(increase?'压下':'抬起'):vertical?(increase?'向下':'向上'):(increase?'向右':'向左');
    const label=runtime.axes[id][axis]+direction+(rotation?'90°':pressure?'1档':'1格');
    actButton(tree,n=>n.props['aria-label']===label);tree=render(id,props);
   }
  }
 }
 return tree;
}
for(const id of model.CHAPTER_FOUR_INSERTED_PUZZLE_IDS){
 const right={puzzleId:id,...correct[id]},bad={puzzleId:id,...wrong[id]};
 sourceCheck(model.isChapterFourInsertedPuzzleAnswer(right)&&model.isChapterFourInsertedPuzzleAnswerCorrect(right),'Source correct oracle '+id);
 sourceCheck(model.isChapterFourInsertedPuzzleAnswer(bad)&&!model.isChapterFourInsertedPuzzleAnswerCorrect(bad),'Source wrong oracle '+id);
 hooks=[];let submitted=null,closed=false;const props={onSubmit(answer){submitted=structuredClone(answer)},onClose(){closed=true}};
 let tree=render(id,props);
 if(id==='archive_index'||id==='power_topology')sourceCheck(all(tree).find(n=>n.type==='button'&&text(n)==='提交结果').props.disabled,'Source incomplete disabled '+id);
 tree=setSourceAnswer(id,bad,props);
 const wrongDraft=structuredClone(hooks);
 const previewWrong=sourceProjection(id,all(tree).find(n=>n.type==='source-preview').props.state);
 actButton(tree,n=>text(n)==='提交结果');
 sourceCheck(JSON.stringify(submitted)===JSON.stringify(bad),'Source UI emits expected wrong draft '+id);
 sourceCheck(!model.isChapterFourInsertedPuzzleAnswerCorrect(submitted),'Source UI wrong rejected '+id);
 tree=render(id,{...props,feedback:'source rejection'});
 sourceCheck(JSON.stringify(hooks)===JSON.stringify(wrongDraft),'Source rejection preserves adjusted draft '+id);
 tree=setSourceAnswer(id,right,props);actButton(tree,n=>text(n)==='提交结果');
 sourceCheck(JSON.stringify(submitted)===JSON.stringify(right),'Source UI emits expected adjusted answer '+id);
 sourceCheck(model.isChapterFourInsertedPuzzleAnswerCorrect(submitted),'Source adjusted answer accepted '+id);
 const previewCorrect=sourceProjection(id,all(tree).find(n=>n.type==='source-preview').props.state);
 tree=render(id,{...props,completed:true});
 sourceCheck(!all(tree).some(n=>n.type==='source-preview')&&text(tree).includes('记录完成'),'Source completed readonly '+id);
 actButton(tree,n=>text(n)==='返回现场');sourceCheck(closed,'Source explicit close callback '+id);
 hooks=[];tree=render(id,props);sourceCheck(JSON.stringify(all(tree).find(n=>n.type==='source-preview').props.state)===JSON.stringify(defaults),'Source unmount/reopen resets '+id);
 const dark=all(render(id,{mode:'dark'}));sourceCheck(!dark.some(n=>n.type==='source-preview'),'Source dark readonly '+id);
 fixtures.cases.push({id,wrong:bad,correct:right,previewWrong,previewCorrect,factId:model.CHAPTER_FOUR_INSERTED_PUZZLES[id].factId});
}
hooks=[];const locked=text(render('media_alignment',{mode:'dark',prerequisiteReady:false}));if(!locked.includes('缺少可校准底片')||locked.includes(traces.media_alignment[0]))throw Error('Missing-film precedence drift');
for (const [relative,value] of [['data/native/chapter4-device-source.json',runtime],['tests/fixtures/chapter4-device-oracle.json',fixtures]]) {
 const file=path.join(destination,relative), serialized=JSON.stringify(value,null,2)+'\n';
 if(checkOnly){if(fs.readFileSync(file,'utf8')!==serialized)throw Error('Source catalog stale: '+relative);}
 else{fs.mkdirSync(path.dirname(file),{recursive:true});fs.writeFileSync(file,serialized);}
}
console.log(`Executed original TS model + TSX panel: ${fixtures.sourceControlChecks} source control checks, six wrong → adjust → right flows, close/reopen, defaults, locked/dark/completed contracts, exact labels/traces/ranges exported.`);
