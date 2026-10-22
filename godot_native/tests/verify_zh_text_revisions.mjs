import fs from 'node:fs';
import path from 'node:path';
import assert from 'node:assert/strict';
import {fileURLToPath} from 'node:url';
import {applyTextRevisions, readTextRevisions, synchronizeSourceTextRevisions} from '../tools/apply-zh-text-revisions.mjs';
const root=fileURLToPath(new URL('../../',import.meta.url));
const spec=readTextRevisions(root);
const report=synchronizeSourceTextRevisions(root,{check:true});
const read=(base,file)=>JSON.parse(fs.readFileSync(path.join(root,base,file),'utf8'));
const ptr=keys=>JSON.stringify(keys);
let leaves=0;
function compare(before,after,changes,keys=[]){
  if(typeof before==='string' && changes.has(ptr(keys))){
    const entry=changes.get(ptr(keys));assert.equal(before,entry.oldText);assert.equal(after,entry.newText);leaves++;return;
  }
  if(Array.isArray(before)){assert(Array.isArray(after));assert.equal(after.length,before.length);before.forEach((v,i)=>compare(v,after[i],changes,[...keys,i]));return;}
  if(before!==null&&typeof before==='object'){assert.deepEqual(Object.keys(after),Object.keys(before));for(const key of Object.keys(before))compare(before[key],after[key],changes,[...keys,key]);return;}
  assert.deepEqual(after,before,`Unapproved/non-display change at ${ptr(keys)}`);
}
for(const file of new Set(spec.revisions.map(x=>x.sourceFile))){
 const revisions=spec.revisions.filter(x=>x.sourceFile===file);
 compare(read('src/data',file),read('godot_native/data/source',file),new Map(revisions.map(x=>[ptr(x.path),x])));
}
assert.equal(leaves,spec.revisions.length);
for(const file of fs.readdirSync(path.join(root,'src/data')).filter(x=>x.endsWith('.json'))){
 if(spec.revisions.some(x=>x.sourceFile===file))continue;
 const target=path.join(root,'godot_native/data/source',file);
 assert.deepEqual(fs.readFileSync(target),fs.readFileSync(path.join(root,'src/data',file)),`Unrelated native source ${file}`);
}
assert.throws(()=>applyTextRevisions({text:'old'},[{path:['text'],oldText:'stale',newText:'新'}]),/Original Chinese text changed/);
assert.throws(()=>applyTextRevisions({speaker:'system'},[{path:['speaker'],oldText:'system',newText:'player'}]),/Non-display/);
assert.throws(()=>applyTextRevisions({text:'old'},[{path:['missing','text'],oldText:'old',newText:'新'}]),/Missing/);
assert.throws(()=>applyTextRevisions({text:'old'},[{path:['text'],oldText:'old',newText:'新'},{path:['text'],oldText:'新',newText:'新二'}]),/Duplicate/);
const pure={dialogue:[{speaker:'system',text:'old',durationMs:1234,event:'e'}]};
assert.deepEqual(applyTextRevisions(structuredClone(pure),[{path:['dialogue',0,'text'],oldText:'old',newText:'新'}]),{dialogue:[{speaker:'system',text:'新',durationMs:1234,event:'e'}]});
console.log(JSON.stringify({result:'PASS',...report,exactFields:leaves,arrayShapeSpeakerAndUnlistedFields:'unchanged',staleAndProtectedFieldRejection:'passed'}));
