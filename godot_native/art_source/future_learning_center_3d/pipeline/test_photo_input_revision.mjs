/** Specific geometric contract for the GPX-inspired candidate, not manufacturer CAD. */
import fs from 'node:fs/promises';
import assert from 'node:assert/strict';
import {NodeIO,getBounds} from '@gltf-transform/core';
const io=new NodeIO(),rows=[];
const check=(ok,label,actual)=>{rows.push({pass:!!ok,label,actual});assert.ok(ok,label)};
const bounds=n=>getBounds(n),size=n=>{const b=bounds(n);return b.max.map((x,i)=>x-b.min[i])};
for(let lod=0;lod<3;lod++){
 const mouse=await io.read(`sources/models/photo_desktop/photo_mouse/lod${lod}_source.glb`),nodes=mouse.getRoot().listNodes(),body=nodes.find(n=>n.getName().includes('GPX continuous'));
 const s=size(body);check(Math.abs(s[0]-.0635)<.0003&&Math.abs(s[2]-.125)<.00001,`LOD${lod} shell follows official 125 x 63.5 mm envelope`,s);
 const bb=bounds(body);check(Math.abs(bb.max[1]-.040)<.0002,`LOD${lod} round shell height follows official 40 mm datum`,bb.max[1]);
 const base=nodes.find(n=>n.getName()==='Thin inset black base');check(size(base)[1]<=.00251,`LOD${lod} thin separate underside, not old tall pedestal`,size(base));
 const side=nodes.filter(n=>n.getName().startsWith('Side button left only'));check(side.length===2&&side.every(n=>bounds(n).min[0]>.025),`LOD${lod} two anatomical left-only keys (+X for nose -Y)`,side.map(bounds));
 check(nodes.some(n=>n.getName()==='Left click panel')&&nodes.some(n=>n.getName()==='Right click panel'),`LOD${lod} separate left/right click surfaces`);
 const points=[];for(const p of body.getMesh().listPrimitives()){const pos=p.getAttribute('POSITION');for(let k=0;k<pos.getCount();k++){const v=[];pos.getElement(k,v);points.push(v)}}
 const middle=points.filter(v=>Math.abs(v[0])<.001&&Math.abs(v[2])<.025),nose=points.filter(v=>Math.abs(v[0])<.001&&v[2]>.05),tail=points.filter(v=>Math.abs(v[0])<.001&&v[2]<-.05);
 const max=a=>Math.max(...a.map(v=>v[1]));check(max(middle)>max(nose)+.012&&max(middle)>max(tail)+.012,`LOD${lod} continuous raised palm region and descending nose/tail`,{middle:max(middle),nose:max(nose),tail:max(tail)});
 const key=await io.read(`sources/models/photo_desktop/photo_keyboard/lod${lod}_source.glb`),kn=key.getRoot().listNodes();
 check(kn.some(n=>n.getName()==='Separated right navigation deck')&&kn.some(n=>n.getName()==='Six mm navigation separator'),`LOD${lod} separately modeled right navigation island`);
 const caps=kn.filter(n=>n.getName().startsWith('Keycap ')&&!n.getName().startsWith('Keycap top'));
 const right=caps.filter(n=>bounds(n).min[0]>.15),main=caps.filter(n=>bounds(n).max[0]<.155);
 const gap=Math.min(...right.map(n=>bounds(n).min[0]))-Math.max(...main.map(n=>bounds(n).max[0]));
 check(right.length>=5&&gap>=.005&&gap<=.008,`LOD${lod} real cap clearance between right island and main keys is 5–8 mm`,{rightKeys:right.length,gap});
 check(mouse.getRoot().listTextures().length===0&&key.getRoot().listTextures().length===0,`LOD${lod} no private photo or invented brand pixels`);
}
await fs.writeFile('review/photo_desktop/input_revision_validation.json',JSON.stringify({checks:rows.length,failures:0,scope:'GPX public envelope and visual-reference estimates; no exact manufacturer CAD or measured photo scale claim.',rows},null,2)+'\n');console.log(`${rows.length} input revision checks passed`);
