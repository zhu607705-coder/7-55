// Optional, per-resource derived byte cache. Never restores editor state,
// script/global caches, test results or a preflight success receipt.
import fs from 'node:fs';
import path from 'node:path';
import crypto from 'node:crypto';
import {spawnSync} from 'node:child_process';
import {fileURLToPath} from 'node:url';
const hash=b=>crypto.createHash('sha256').update(b).digest('hex');
const md5=b=>crypto.createHash('md5').update(b).digest('hex');
const digest=f=>hash(fs.readFileSync(f));
const extensions=new Set(['.png','.jpg','.jpeg','.webp','.ttf','.otf','.wav','.ogg','.mp3']);
const importers=new Set(['texture','font_data_dynamic','wav','oggvorbisstr','mp3']);
const plain=f=>{try{return fs.lstatSync(f).isFile()&&!fs.lstatSync(f).isSymbolicLink();}catch{return false;}};
function safe(project,relative) {
 if(typeof relative!=='string'||relative.startsWith('/')||relative.includes('\\')||relative.split('/').some(s=>!s||s==='.'||s==='..'))throw Error('Unsafe resource cache path');
 let file=project;for(const part of relative.split('/')){file=path.join(file,part);if(fs.existsSync(file)&&fs.lstatSync(file).isSymbolicLink())throw Error('Symlink resource cache path');}return file;
}
function sourceFiles(project) {
 const files=[];function walk(dir,prefix=''){for(const entry of fs.readdirSync(dir,{withFileTypes:true})){
  if(entry.name.startsWith('.')||['exports','node_modules'].includes(entry.name)||entry.isSymbolicLink())continue;
  const name=prefix+entry.name;if(entry.isDirectory())walk(path.join(dir,entry.name),name+'/');else if(entry.isFile()&&extensions.has(path.extname(name).toLowerCase()))files.push(name);
 }}walk(project);return files.sort();
}
export function engineIdentity(command) {
 const candidates=command.includes(path.sep)?[path.resolve(command)]:(process.env.PATH||'').split(path.delimiter).map(d=>path.join(d,command));
 const executable=candidates.find(f=>{try{fs.accessSync(f,fs.constants.X_OK);return fs.statSync(f).isFile();}catch{return false;}});
 if(!executable)throw Error('Missing Godot executable for import cache');
 const r=spawnSync(executable,['--version'],{encoding:'utf8',timeout:30000});if(r.status!==0||r.error)throw Error('Cannot identify Godot for import cache');
 return {version:r.stdout.trim(),binarySha256:digest(executable)};
}
function descriptor(relative,sourceBytes,project,context) {
 const sidecar=safe(project,relative+'.import');
 return {relative,sourceSha256:hash(sourceBytes),sourceMd5:md5(sourceBytes),initialSidecarSha256:plain(sidecar)?digest(sidecar):null,context};
}
function payloadPaths(relative,sidecar) {
 const source='res://'+relative,stem='.godot/imported/'+path.basename(relative)+'-'+md5(source);
 const importer=sidecar.match(/^importer="([^"]+)"$/m)?.[1];
 const actual=sidecar.match(/^source_file="([^"]+)"$/m)?.[1];
 const encoded=sidecar.match(/^dest_files=(\[[^\n]+\])$/m)?.[1];
 if(!importers.has(importer)||actual!==source||!encoded)throw Error('Unsupported importer/source/dependencies');
 let dest;try{dest=JSON.parse(encoded);}catch{throw Error('Unsupported importer destination syntax');}
 if(!Array.isArray(dest)||!dest.length||new Set(dest).size!==dest.length||dest.some(n=>typeof n!=='string'||!n.startsWith('res://'+stem+'.')||n.slice(('res://'+stem).length).includes('/')))throw Error('Foreign imported destination');
 // No dependency-bearing custom params; restoring them would need another graph.
 let section='';const parameterLines=[];
 for(const line of sidecar.split(/\r?\n/)){const header=line.match(/^\[([^\]]+)\]\s*$/);if(header)section=header[1];else if(section==='params')parameterLines.push(line);}
 const params=parameterLines.join('\n');
 // Built-in resource-valued settings must be empty. Relative references can
 // otherwise escape the source closure even without a URI or absolute path.
 for(const line of parameterLines){const setting=line.match(/^\s*(roughness\/src_normal|fallbacks)\s*=\s*(.*?)\s*$/);if(setting&&setting[2]!== (setting[1]==='fallbacks'?'[]':'""'))throw Error('Nonempty resource-valued importer setting');}
 if(/\b(?:Resource|ExtResource|SubResource)\s*\(|uid:\/\//i.test(params))throw Error('Resource-valued importer parameter');
 for(const match of params.matchAll(/"(?:\\.|[^"\\])*"/g)) {
  let value;try{value=JSON.parse(match[0]);}catch{throw Error('Unsupported importer parameter string');}
  if(/^[a-z][a-z0-9+.-]*:/i.test(value)||/^(?:[a-z]:[\\/]|[\\/]|~[\\/])/i.test(value))throw Error('External importer parameter path');
  if(/[\\/]/.test(value)||/\.(?:png|jpe?g|webp|svg|bmp|tga|exr|hdr|ktx|dds|ttf|otf|woff2?|tres|res|tscn|scn|wav|ogg|mp3|mp4|ogv|glb|gltf|obj|fbx)(?:$|[?#])/i.test(value))throw Error('Relative importer dependency');
 }
 const refs=[...sidecar.matchAll(/res:\/\/[^"\s]+/g)].map(m=>m[0]);
 if(refs.some(r=>r!==source&&!dest.includes(r)))throw Error('External importer dependency');
 return [...dest.map(n=>n.slice(6)),stem+'.md5'];
}
function entry(cache,key){return path.join(cache,key);}
function checkedPayload(cache,key,expected) {
 const dir=entry(cache,key);if(fs.lstatSync(dir).isSymbolicLink())throw Error('Symlink cache entry');
 const receiptFile=safe(dir,'receipt.json');if(!plain(receiptFile))throw Error('Missing import receipt');
 const sealFile=safe(dir,'receipt.sha256');if(!plain(sealFile))throw Error('Missing import manifest seal');
 const bytes=fs.readFileSync(receiptFile),seal=fs.readFileSync(sealFile,'utf8').trim();if(hash(bytes)!==seal)throw Error('Import manifest hash mismatch');
 const row=JSON.parse(bytes);if(JSON.stringify(row.identity)!==JSON.stringify(expected))throw Error('Import identity mismatch');
 const sidecarFile=safe(dir,'sidecar.import');if(!plain(sidecarFile)||digest(sidecarFile)!==row.sidecarSha256)throw Error('Import sidecar hash mismatch');
 if(expected.initialSidecarSha256!==null&&row.sidecarSha256!==expected.initialSidecarSha256)throw Error('Authored import settings changed');
 const sidecar=fs.readFileSync(sidecarFile,'utf8'),paths=payloadPaths(expected.relative,sidecar);
 if(JSON.stringify(row.files?.map(f=>f.path))!==JSON.stringify(paths))throw Error('Import inventory mismatch');
 for(const f of row.files){const source=safe(dir,'files/'+f.path);if(!plain(source)||fs.statSync(source).size!==f.bytes||digest(source)!==f.sha256)throw Error('Import payload hash mismatch');}
 const checksum=fs.readFileSync(safe(dir,'files/'+paths.at(-1)),'utf8');if(checksum.match(/^source_md5="([a-f0-9]{32})"$/m)?.[1]!==expected.sourceMd5)throw Error('Godot source checksum mismatch');
 return {dir,sidecarFile,row};
}
/** Return this capture context to captureResourceCache after strict import. */
export function restoreResourceCache({project,cache,engine}) {
 const started=Date.now();project=path.resolve(project);if(!cache)return {disabled:true,restored:0,elapsedMs:0};
 if(!path.isAbsolute(cache)||cache===project||cache.startsWith(project+path.sep))throw Error('Import cache must be absolute and outside project');
 if(fs.existsSync(cache)&&(!fs.lstatSync(cache).isDirectory()||fs.lstatSync(cache).isSymbolicLink()))throw Error('Non-directory/symlink import cache');
 const settings=fs.readFileSync(path.join(project,'project.godot'),'utf8');
 if(fs.existsSync(path.join(project,'addons'))||/\[editor_plugins\][\s\S]*?enabled=PackedStringArray\(\s*"/.test(settings))return {disabled:true,restored:0,reason:'custom importer/plugin project',elapsedMs:Date.now()-started};
 const context={schema:1,engine,projectSha256:digest(path.join(project,'project.godot')),helperSha256:digest(fileURLToPath(import.meta.url)),platform:process.platform,arch:process.arch};
 const sources=[],stats={restored:0,miss:0,rejected:0};
 for(const relative of sourceFiles(project)) {
  const id=descriptor(relative,fs.readFileSync(safe(project,relative)),project,context),key=hash(JSON.stringify(id));sources.push({identity:id,key});
  if(!fs.existsSync(entry(cache,key))){stats.miss++;continue;}
  try {
   const data=checkedPayload(cache,key,id),sidecar=safe(project,relative+'.import');
   const sameInputs=()=>digest(safe(project,relative))===id.sourceSha256 && (id.initialSidecarSha256===null?!fs.existsSync(sidecar):plain(sidecar)&&digest(sidecar)===id.initialSidecarSha256);
   if(!sameInputs())throw Error('Source/sidecar changed before restore');
   // Never overwrite an existing different output. Stage every missing file,
   // recheck inputs, then atomically rename each; rollback our new files on error.
   const wanted=[...data.row.files.map(f=>({...f,from:safe(data.dir,'files/'+f.path)})),{path:relative+'.import',from:data.sidecarFile,sha256:data.row.sidecarSha256}];
   const stage=fs.mkdtempSync(path.join(project,'.resource-import-stage-')),pending=[],published=[];
   try {
    for(const f of wanted){const target=safe(project,f.path);if(fs.existsSync(target)){if(!plain(target)||digest(target)!==f.sha256)throw Error('Different existing derived file/settings');continue;}
     const from=path.join(stage,String(pending.length));fs.copyFileSync(f.from,from);if(digest(from)!==f.sha256)throw Error('Cached payload changed during staging');pending.push({from,target});}
    if(!sameInputs())throw Error('Source/sidecar changed during staging');
    for(const f of pending){fs.mkdirSync(path.dirname(f.target),{recursive:true});if(fs.existsSync(f.target))throw Error('Concurrent derived output writer');fs.renameSync(f.from,f.target);published.push(f.target);}
    stats.restored++;
   }catch(error){for(const f of published.reverse())fs.rmSync(f,{force:true});throw error;}
   finally{fs.rmSync(stage,{recursive:true,force:true});}
  }catch{stats.rejected++;}
 }
 return {project,cache,context,sources,...stats,elapsedMs:Date.now()-started};
}
/** Store only outputs of a successful fresh strict import, never its result. */
export function captureResourceCache(snapshot) {
 const started=Date.now();if(snapshot.disabled)return {stored:0,elapsedMs:0};const {project,cache,context}=snapshot;
 if(digest(path.join(project,'project.godot'))!==context.projectSha256)throw Error('Project settings changed during cached import');
 fs.mkdirSync(cache,{recursive:true});if(fs.lstatSync(cache).isSymbolicLink())throw Error('Symlink import cache root');
 let stored=0,unsupported=0;
 for(const {identity:id,key} of snapshot.sources){
  let stage;try {
   const source=safe(project,id.relative),sidecar=safe(project,id.relative+'.import');if(digest(source)!==id.sourceSha256||!plain(sidecar))throw Error('Source drift/missing sidecar');
   if(id.initialSidecarSha256!==null&&digest(sidecar)!==id.initialSidecarSha256)throw Error('Authored sidecar changed during import');
   const text=fs.readFileSync(sidecar,'utf8'),paths=payloadPaths(id.relative,text),files=paths.map(p=>{const f=safe(project,p);if(!plain(f))throw Error('Missing derived resource');return {path:p,bytes:fs.statSync(f).size,sha256:digest(f)};});
   if(fs.readFileSync(safe(project,paths.at(-1)),'utf8').match(/^source_md5="([a-f0-9]{32})"$/m)?.[1]!==id.sourceMd5)throw Error('Stale imported checksum');
   // Immutable valid entries need no replacement; invalid entries are replaced
   // only after fresh importer output has independently passed the above checks.
   try{checkedPayload(cache,key,id);continue;}catch{}
   stage=fs.mkdtempSync(path.join(cache,'.staged-'));fs.copyFileSync(sidecar,path.join(stage,'sidecar.import'));
   for(const f of files){const out=safe(stage,'files/'+f.path);fs.mkdirSync(path.dirname(out),{recursive:true});fs.copyFileSync(safe(project,f.path),out);if(digest(out)!==f.sha256)throw Error('Derived bytes changed while copying');}
   const row={identity:id,sidecarSha256:hash(text),files},bytes=JSON.stringify(row)+'\n';fs.writeFileSync(path.join(stage,'receipt.json'),bytes);fs.writeFileSync(path.join(stage,'receipt.sha256'),hash(bytes)+'\n');
   const dest=entry(cache,key);if(fs.existsSync(dest)){if(fs.lstatSync(dest).isSymbolicLink())throw Error('Symlink import entry');fs.rmSync(dest,{recursive:true});}fs.renameSync(stage,dest);stage=null;stored++;
  }catch{unsupported++;}finally{if(stage)fs.rmSync(stage,{recursive:true,force:true});}
 }
 return {stored,unsupported,elapsedMs:Date.now()-started};
}
