import fs from 'node:fs';
import path from 'node:path';
import assert from 'node:assert/strict';
import {createRequire} from 'node:module';
const project=path.resolve(import.meta.dirname,'..');
const repo=path.resolve(project,'..');
const require=createRequire(path.join(repo,'package.json'));
const {transform}=require('esbuild');
const source=fs.readFileSync(path.join(repo,'src/scenes/phone/P18_Photos/index.tsx'),'utf8');
const body=source.slice(source.indexOf('export function PhotosScene(')).replace('export function','function');
const {code}=await transform(body,{loader:'tsx',format:'cjs',jsx:'transform'});
const app=fs.readFileSync(path.join(repo,'src/App.tsx'),'utf8');
assert.match(app,/<Scene key=\{`\$\{state.currentScene\}:\$\{developerCheckpointEpoch\}`\}/);
let refs=[],deps=[],effects=[],cursor=0,calls=0,current;
function useRef(value){const i=cursor++;return refs[i]??=( {current:value} );}
function useEffect(effect,next){const i=cursor++;if(!deps[i]||next.some((v,j)=>!Object.is(v,deps[i][j]))){deps[i]=next;effects.push(effect);}}
const kit={libraryFinals:{dimPhoto(b){if(Number.isFinite(b)&&b<=20)calls++;},capturePhoto(){return true;},generateItemReport(){}}};
const React={createElement:(type,props)=>({type,props})};
const PhotosScene=Function('useRef','useEffect','kit','React','PhotoEvidenceOverlay','InterludeRecoveredAlbum',code+'\nreturn PhotosScene;')(useRef,useEffect,kit,React,'overlay','album');
const traces=[];
function run(name,steps){refs=[];deps=[];let mounted=false;const recorded=[];for(const step of steps){if(step.reset){refs=[];deps=[];mounted=false;}const page=step.page||'photos';if(page!=='photos'){mounted=false;refs=[];deps=[];recorded.push({...step,page,expected:false});continue;}if(!mounted){refs=[];deps=[];mounted=true;}cursor=0;effects=[];calls=0;current={ui:{brightness:step.brightness,libraryFinalsPuzzle:{photoCaptured:step.captured,photoDimmed:step.dimmed,backpackInspected:true}},qizhenLake:{phase:'idle'},chapterThreeInterlude:{completed:false}};PhotosScene({state:current,router:{}});for(const effect of effects)effect();recorded.push({...step,page,expected:calls>0});}traces.push({name,steps:recorded});}
const s=(label,b,c=true,d=false,page='photos',reset=false)=>({label,brightness:b,captured:c,dimmed:d,page,reset});
run('pre-capture and baseline return',[s('initial',75,false),s('dim before capture',20,false),s('capture',20),s('unchanged',20),s('up',30),s('capture baseline',20),s('new low value',19),s('source flag',19,true,true),s('raise after unlock',75,true,true),s('lower after unlock',20,true,true)]);
run('captured mount high',[s('mount',75),s('unrelated refresh',75),s('threshold above',20.001),s('exact threshold',20),s('repeated before commit',20),s('source flag committed',20,true,true)]);
run('mount and reentry low',[s('mount at20',20),s('up',30),s('back to baseline',20),s('away',75,true,false,'phone_home'),s('change away',20,true,false,'phone_home'),s('reentry at20',20),s('up again',30),s('back to new baseline',20),s('different low',19)]);
run('session reset',[s('mount at75',75),s('up',80),s('developer reset at20',20,true,false,'photos',true),s('still20',20),s('different low',0)]);
run('captured later while mounted',[s('mount empty',75,false),s('unrelated refresh',50,false),s('capture',50),s('exact20',20)]);
run('already dimmed',[s('mount',20,true,true),s('up',100,true,true),s('down',0,true,true)]);
assert.equal(traces[0].steps[5].expected,false);assert.equal(traces[0].steps[6].expected,true);
const out=path.join(project,'tests/photo_consumer_cases.json');
assert.deepEqual(JSON.parse(fs.readFileSync(out,'utf8')),traces,'native lifecycle fixtures match the executed source hooks');
console.log(`PHOTO_CONSUMER_SOURCE: executed active PhotosScene useRef/useEffect across ${traces.length} traces / ${traces.reduce((n,t)=>n+t.steps.length,0)} observations; exact mount/key/previous/capture behavior verified`);
