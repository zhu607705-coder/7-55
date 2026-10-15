import { stripTypeScriptTypes } from 'node:module';import fs from 'node:fs';import path from 'node:path';import vm from 'node:vm';import crypto from 'node:crypto';
const root=path.resolve(import.meta.dirname,'../..');const dest=path.join(root,'godot_native');
const src=fs.readFileSync(path.join(root,'src/core/GameState.ts'),'utf8');
const body=src.split('export function createInitialGameState(): GameState {')[1].split('\nexport function createGameStore')[0];
const initial=vm.runInNewContext('(function(){'+body+')()', {DEFAULT_PHONE_HOME_APP_ORDER:['wechat','tiyi','zjuding','settings','photos','timeline_recovery','voice_memos','cc98','control_center','clock']});
fs.mkdirSync(path.join(dest,'data/source'),{recursive:true});fs.writeFileSync(path.join(dest,'data/initial_state.json'),JSON.stringify(initial,null,2)+'\n');
fs.cpSync(path.join(root,'src/data'),path.join(dest,'data/source'),{recursive:true,filter:(s)=>fs.statSync(s).isDirectory()||s.endsWith('.json')});
fs.cpSync(path.join(root,'src/assets'),path.join(dest,'assets'),{recursive:true});
let assets=[];function walk(p){for(const n of fs.readdirSync(p)){const f=path.join(p,n);if(fs.statSync(f).isDirectory())walk(f);else assets.push({path:'assets/'+path.relative(path.join(root,'src/assets'),f),bytes:fs.statSync(f).size,sha256:crypto.createHash('sha256').update(fs.readFileSync(f)).digest('hex')});}}walk(path.join(root,'src/assets'));
fs.writeFileSync(path.join(dest,'data/asset_manifest.json'),JSON.stringify({sourceCommit:'39ccde029b0cd25a6011739a4e4f98f8c898b2c3',assetCount:assets.length,totalBytes:assets.reduce((a,b)=>a+b.bytes,0),assets},null,2)+'\n');console.log('Synchronized initial state, JSON and '+assets.length+' source assets.');

const itemModule=await import('data:text/javascript;base64,'+Buffer.from(stripTypeScriptTypes(fs.readFileSync(path.join(root,'src/data/itemCatalog.ts'),'utf8'),{mode:'transform'})).toString('base64'));
fs.mkdirSync(path.join(dest,'data/native'),{recursive:true});fs.writeFileSync(path.join(dest,'data/native/item_catalog.json'),JSON.stringify(itemModule.ITEM_CATALOG,null,2)+'\n');
