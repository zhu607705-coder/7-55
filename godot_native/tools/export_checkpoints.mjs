import {gzipSync} from 'node:zlib';import fs from 'node:fs';import path from 'node:path';import {build} from 'esbuild';
const root=path.resolve(import.meta.dirname,'../..');
const bundle=await build({entryPoints:[path.join(root,'src/modules/DeveloperChannel.ts')],platform:'node',format:'esm',bundle:true,write:false,logLevel:'silent'});
const module=await import('data:text/javascript;base64,'+Buffer.from(bundle.outputFiles[0].text).toString('base64'));
const entries=module.DEVELOPER_CHECKPOINTS.map(entry=>({...entry,state:module.createDeveloperCheckpointState(entry.id)}));
fs.writeFileSync(path.join(root,'godot_native/data/native/developer_checkpoints.json.gz'),gzipSync(JSON.stringify({source:'src/modules/DeveloperChannel.ts',sourceCommit:'39ccde029b0cd25a6011739a4e4f98f8c898b2c3',checkpoints:entries}),{level:9}));console.log('Exported '+entries.length+' exact source developer checkpoints');
