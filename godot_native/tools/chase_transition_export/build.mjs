import {build} from 'esbuild';
import {readFile} from 'node:fs/promises';
import path from 'node:path';
import {fileURLToPath} from 'node:url';
const root=path.dirname(fileURLToPath(import.meta.url));
await build({entryPoints:[path.join(root,'export_source.ts')],outfile:path.join(root,'export_source.mjs'),platform:'node',bundle:true,format:'esm',plugins:[{name:'offline-source-adapters',setup(b){
 b.onResolve({filter:/\.glb\?url$/},args=>({path:args.path,namespace:'asset'}));
 b.onLoad({filter:/.*/,namespace:'asset'},()=>({contents:'export default "offline-preinstalled-template.glb"',loader:'js'}));
 b.onLoad({filter:/CanteenBikeTransitionRenderer\.ts$/},async args=>({contents:`class RecordingRenderer {shadowMap={};canvas;constructor(options){this.canvas=options.canvas;}setPixelRatio(){}setSize(w,h){this.canvas.width=w;this.canvas.height=h;}render(){}resetState(){}dispose(){}}\n`+(await readFile(args.path,'utf8')).replace('new THREE.WebGLRenderer({','new RecordingRenderer({'),loader:'ts'}));
}}]});
