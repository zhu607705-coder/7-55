import test from 'node:test';
import assert from 'node:assert/strict';
import fs from 'node:fs';
import os from 'node:os';
import path from 'node:path';
import crypto from 'node:crypto';
import {restoreResourceCache,captureResourceCache} from '../tools/resource_import_cache.mjs';
const hash=(s,kind='sha256')=>crypto.createHash(kind).update(s).digest('hex');
const engine={version:'4.7.1.test',binarySha256:'a'.repeat(64)};
function fixture(){
 const root=fs.mkdtempSync(path.join(os.tmpdir(),'755-import-cache-test-')),project=path.join(root,'project'),cache=path.join(root,'cache');fs.mkdirSync(project);fs.writeFileSync(path.join(project,'project.godot'),'config_version=5\n');fs.writeFileSync(path.join(project,'a.png'),'SOURCE');return {root,project,cache,engine};
}
function imported(f,{extra='',wrongMd5=false}={}){
 const stem='.godot/imported/a.png-'+hash('res://a.png','md5'),dest=stem+'.ctex';
 fs.mkdirSync(path.join(f.project,'.godot/imported'),{recursive:true});fs.writeFileSync(path.join(f.project,dest),'DERIVED');fs.writeFileSync(path.join(f.project,stem+'.md5'),`source_md5="${hash(wrongMd5?'wrong':fs.readFileSync(path.join(f.project,'a.png')),'md5')}"\ndest_md5="${hash('DERIVED','md5')}"\n`);
 fs.writeFileSync(path.join(f.project,'a.png.import'),`[remap]\nimporter="texture"\npath="res://${dest}"\n[deps]\nsource_file="res://a.png"\ndest_files=["res://${dest}"]\n[params]\ncompress/mode=0\n${extra}`);return dest;
}
function cold(f){fs.rmSync(path.join(f.project,'.godot'),{recursive:true,force:true});fs.rmSync(path.join(f.project,'a.png.import'),{force:true});}
test('exact resource warm cache restores only sidecar, payload and md5',()=>{
 const f=fixture();try{
  const first=restoreResourceCache(f);assert.equal(first.miss,1);const dest=imported(f);assert.equal(captureResourceCache(first).stored,1);cold(f);
  const warm=restoreResourceCache(f);assert.equal(warm.restored,1);assert.equal(fs.readFileSync(path.join(f.project,dest),'utf8'),'DERIVED');assert.deepEqual(fs.readdirSync(path.join(f.project,'.godot')),['imported']);
 }finally{fs.rmSync(f.root,{recursive:true,force:true});}
});
for(const change of ['source','project','engine','sidecar'])test(`changed ${change} cannot restore old derived bytes`,()=>{
 const f=fixture();try{
  const first=restoreResourceCache(f);imported(f);captureResourceCache(first);cold(f);
  if(change==='source')fs.writeFileSync(path.join(f.project,'a.png'),'NEW');
  if(change==='project')fs.appendFileSync(path.join(f.project,'project.godot'),'\n[rendering]\ntextures/default_filters/use_nearest_mipmap_filter=true\n');
  if(change==='engine')f.engine={...engine,binarySha256:'b'.repeat(64)};
  if(change==='sidecar')fs.writeFileSync(path.join(f.project,'a.png.import'),'custom current settings');
  assert.equal(restoreResourceCache(f).restored,0);assert.equal(fs.existsSync(path.join(f.project,'.godot')),false);
  if(change==='sidecar')assert.equal(fs.readFileSync(path.join(f.project,'a.png.import'),'utf8'),'custom current settings');
 }finally{fs.rmSync(f.root,{recursive:true,force:true});}
});
for(const corruption of ['payload','manifest','seal','sidecar'])test(`corrupt ${corruption} rejected before restore`,()=>{
 const f=fixture();try{
  const first=restoreResourceCache(f);const dest=imported(f);captureResourceCache(first);cold(f);const dir=path.join(f.cache,fs.readdirSync(f.cache)[0]);
  const target={payload:'files/'+dest,manifest:'receipt.json',seal:'receipt.sha256',sidecar:'sidecar.import'}[corruption];fs.appendFileSync(path.join(dir,target),'corruption');
  const result=restoreResourceCache(f);assert.equal(result.restored,0);assert.equal(result.rejected,1);assert.equal(fs.existsSync(path.join(f.project,'.godot')),false);
 }finally{fs.rmSync(f.root,{recursive:true,force:true});}
});
test('custom dependencies and stale checksum are never cached',()=>{
 const f=fixture();try{
  let first=restoreResourceCache(f);imported(f,{extra:'other="res://foreign.png"'});assert.equal(captureResourceCache(first).stored,0);cold(f);
  first=restoreResourceCache(f);imported(f,{wrongMd5:true});assert.equal(captureResourceCache(first).stored,0);
  fs.mkdirSync(path.join(f.project,'addons'));assert.equal(restoreResourceCache(f).disabled,true);
 }finally{fs.rmSync(f.root,{recursive:true,force:true});}
});
test('restore failure rolls back published files and never replaces a different output',()=>{
 const f=fixture(),rename=fs.renameSync;try{
  const first=restoreResourceCache(f),dest=imported(f);captureResourceCache(first);cold(f);
  fs.renameSync=(from,to)=>{if(to.endsWith('.md5'))throw Error('injected second-publish failure');return rename(from,to);};
  assert.equal(restoreResourceCache(f).restored,0);assert.equal(fs.existsSync(path.join(f.project,dest)),false);assert.equal(fs.existsSync(path.join(f.project,'a.png.import')),false);
  fs.renameSync=rename;fs.mkdirSync(path.dirname(path.join(f.project,dest)),{recursive:true});fs.writeFileSync(path.join(f.project,dest),'keep current differing output');
  assert.equal(restoreResourceCache(f).restored,0);assert.equal(fs.readFileSync(path.join(f.project,dest),'utf8'),'keep current differing output');assert.equal(fs.existsSync(path.join(f.project,'a.png.import')),false);
 }finally{fs.renameSync=rename;fs.rmSync(f.root,{recursive:true,force:true});}
});
for(const extra of ['fallbacks=["uid://foreignfont"]','fallbacks=[Resource("uid://foreignfont")]','fallbacks=[ExtResource("font")]','fallbacks=[SubResource("font")]','fallback="/usr/share/fonts/foreign.ttf"','fallback="C:\\\\Fonts\\\\foreign.ttf"','fallback="file:///fonts/foreign.ttf"','fallback="https://example.invalid/foreign.ttf"'])test(`dependency-bearing parameters are not cached: ${extra}`,()=>{
 const f=fixture();try{
  const first=restoreResourceCache(f);imported(f,{extra});assert.equal(captureResourceCache(first).stored,0);
 }finally{fs.rmSync(f.root,{recursive:true,force:true});}
});
test('resource own remap UID is identity metadata, not an external dependency',()=>{
 const f=fixture();try{
  const first=restoreResourceCache(f);imported(f);const file=path.join(f.project,'a.png.import');fs.writeFileSync(file,fs.readFileSync(file,'utf8').replace('[remap]','[remap]\nuid="uid://ownresource"'));
  assert.equal(captureResourceCache(first).stored,1);cold(f);assert.equal(restoreResourceCache(f).restored,1);
 }finally{fs.rmSync(f.root,{recursive:true,force:true});}
});

for(const extra of ['roughness/src_normal="normal.png"','roughness/src_normal="../normal.png"','roughness/src_normal="extensionless"','fallbacks=["font.ttf"]','fallbacks=["extensionless"]','dependency="../extensionless"','dependency="nested/extensionless"','dependency="normal.png"','dependency="font.tres"'])test(`relative dependency is not cached: ${extra}`,()=>{
 const f=fixture();try{
  const first=restoreResourceCache(f);imported(f,{extra});assert.equal(captureResourceCache(first).stored,0);
 }finally{fs.rmSync(f.root,{recursive:true,force:true});}
});
test('empty built-in dependency parameters retain warm cache support',()=>{
 const f=fixture();try{
  const first=restoreResourceCache(f);imported(f,{extra:'roughness/src_normal=""\nfallbacks=[]'});assert.equal(captureResourceCache(first).stored,1);cold(f);assert.equal(restoreResourceCache(f).restored,1);
 }finally{fs.rmSync(f.root,{recursive:true,force:true});}
});
