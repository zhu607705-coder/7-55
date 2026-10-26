import {acquireNativeWorkspaceLock} from './native_validation_lock.mjs';
import {synchronizeSourceTextRevisions} from './apply-zh-text-revisions.mjs';
import { stripTypeScriptTypes } from 'node:module';import fs from 'node:fs';import path from 'node:path';import vm from 'node:vm';import crypto from 'node:crypto';
const root=path.resolve(import.meta.dirname,'../..');const dest=path.join(root,'godot_native');
const releaseWorkspaceLock=acquireNativeWorkspaceLock(dest,'source synchronization');
// The Web JSON is the sole authored clue text. Native reads a build-time copy.
const wordSource=path.join(root,'src/data/prologue-interception.content.json');
const wordTarget=path.join(dest,'data/native/prologue-interception.content.json');
const wordBytes=fs.readFileSync(wordSource);
if(process.argv.includes('--check-prologue-words')){
 if(!fs.existsSync(wordTarget)||!wordBytes.equals(fs.readFileSync(wordTarget)))throw Error('Native prologue words differ from the authored Web JSON');
 console.log('Prologue word source copy matches exactly.');process.exit(0);
}
fs.mkdirSync(path.dirname(wordTarget),{recursive:true});fs.writeFileSync(wordTarget,wordBytes);
if(process.argv.includes('--prologue-words-only')){
 console.log('Synchronized prologue word JSON only; no media or other source fixtures changed.');process.exit(0);
}
const src=fs.readFileSync(path.join(root,'src/core/GameState.ts'),'utf8');
const body=src.split('export function createInitialGameState(): GameState {')[1].split('\nexport function createGameStore')[0];
const initial=vm.runInNewContext('(function(){'+body+')()', {DEFAULT_PHONE_HOME_APP_ORDER:['wechat','tiyi','zjuding','settings','photos','timeline_recovery','voice_memos','cc98','control_center','clock']});
fs.mkdirSync(path.join(dest,'data/source'),{recursive:true});fs.writeFileSync(path.join(dest,'data/initial_state.json'),JSON.stringify(initial,null,2)+'\n');
fs.cpSync(path.join(root,'src/data'),path.join(dest,'data/source'),{recursive:true,filter:(s)=>fs.statSync(s).isDirectory()||s.endsWith('.json')});
console.log('Applied native Chinese display revisions:', synchronizeSourceTextRevisions(root));
fs.cpSync(path.join(root,'src/assets'),path.join(dest,'assets'),{recursive:true});
// Keep the reviewed mother image intact in source, but import this small desk
// object at 256px on every clean CI/export. Ignored local .import is not authority.
const dockSource = 'res://assets/ui/home_charging_dock.png';
const dockImported = `res://.godot/imported/home_charging_dock.png-${crypto.createHash('md5').update(dockSource).digest('hex')}.ctex`;
fs.writeFileSync(path.join(dest, 'assets/ui/home_charging_dock.png.import'),
  `[remap]\nimporter="texture"\ntype="CompressedTexture2D"\npath="${dockImported}"\nmetadata={"vram_texture": false}\n\n[deps]\nsource_file="${dockSource}"\ndest_files=["${dockImported}"]\n\n[params]\ncompress/mode=0\nmipmaps/generate=false\nprocess/size_limit=256\n`);

let assets=[];function walk(p){for(const n of fs.readdirSync(p)){const f=path.join(p,n);if(fs.statSync(f).isDirectory())walk(f);else assets.push({path:'assets/'+path.relative(path.join(root,'src/assets'),f),bytes:fs.statSync(f).size,sha256:crypto.createHash('sha256').update(fs.readFileSync(f)).digest('hex')});}}walk(path.join(root,'src/assets'));
fs.writeFileSync(path.join(dest,'data/asset_manifest.json'),JSON.stringify({sourceCommit:'39ccde029b0cd25a6011739a4e4f98f8c898b2c3',assetCount:assets.length,totalBytes:assets.reduce((a,b)=>a+b.bytes,0),assets},null,2)+'\n');console.log('Synchronized initial state, JSON and '+assets.length+' source assets.');

const itemModule=await import('data:text/javascript;base64,'+Buffer.from(stripTypeScriptTypes(fs.readFileSync(path.join(root,'src/data/itemCatalog.ts'),'utf8'),{mode:'transform'})).toString('base64'));
fs.mkdirSync(path.join(dest,'data/native'),{recursive:true});fs.writeFileSync(path.join(dest,'data/native/item_catalog.json'),JSON.stringify(itemModule.ITEM_CATALOG,null,2)+'\n');
// The full source sync deterministically creates portable GPU-sized tiles.
// Prologue-only early exits above intentionally never generate other assets.
await import('./build_panorama_tiles.mjs');

releaseWorkspaceLock();
