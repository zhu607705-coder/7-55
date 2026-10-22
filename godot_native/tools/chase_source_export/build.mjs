import {build} from 'esbuild';
import {readFile} from 'node:fs/promises';
import path from 'node:path';
import {fileURLToPath} from 'node:url';
const root=path.dirname(fileURLToPath(import.meta.url));
for(const name of ['export','export_rider','export_people','export_effects','export_gust'])await build({entryPoints:[path.join(root,name+'.ts')],outfile:path.join(root,name+'.generated.mjs'),platform:'node',bundle:true,format:'esm',plugins:[{name:'offline-source-only',setup(b){
 b.onResolve({filter:/\.glb\?url$/},args=>({path:args.path,namespace:'asset'}));
 b.onLoad({filter:/.*/,namespace:'asset'},()=>({contents:'export default "offline-preinstalled-template.glb"',loader:'js'}));
 b.onLoad({filter:/ChaseThreeRenderer\.ts$/},async args=>{
  let source=await readFile(args.path,'utf8');
  const bell=source.match(/private readonly bellRing = ([^\n]+);/)?.[1],shield=source.match(/private readonly trayShield = ([^\n]+);/)?.[1];
  if(!bell||!shield)throw Error('Original effect constructor missing');
  source=source.replace('new THREE.WebGLRenderer({','new RecordingRenderer({').replace('mergeStaticWorldMeshes(staticWorld);','/* Export batches the original meshes in bounded source chunks. */');
  return {contents:`class RecordingRenderer {shadowMap={};info={render:{calls:0,triangles:0},memory:{geometries:0,textures:0}};setPixelRatio(){}setSize(){}render(){}resetState(){}dispose(){}}\n`+source+'\nexport {mergeStaticWorldMeshes,buildPerson};\nexport const sourceChaseEffects=()=>({bellRing:'+bell+',trayShield:'+shield+'});',loader:'ts'};
 });
}}]});
