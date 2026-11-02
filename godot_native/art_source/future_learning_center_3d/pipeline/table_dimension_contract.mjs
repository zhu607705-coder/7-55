// Tabletop design dimensions and full wheeled-frame collision envelopes are
// different contracts. Keep them separate; never hide an oversized model behind
// a tabletop-depth allowance. Read-only validation: no asset regeneration.
import fs from 'node:fs/promises';
import assert from 'node:assert/strict';
import {NodeIO,getBounds} from '@gltf-transform/core';
import {ALL_EXTENSIONS} from '@gltf-transform/extensions';
import draco3d from 'draco3dgltf';

export function insideRect(bounds, origin, scale, rect, tolerance=.001) {
  return bounds.min[0]*scale+origin[0]>=rect[0]-tolerance &&
    bounds.min[2]*scale+origin[2]>=rect[1]-tolerance &&
    bounds.max[0]*scale+origin[0]<=rect[2]+tolerance &&
    bounds.max[2]*scale+origin[2]<=rect[3]+tolerance;
}

export async function validateTableDimensions(root='.') {
  const read=async p=>JSON.parse(await fs.readFile(`${root}/${p}`,'utf8'));
  const catalog=await read('web/assets/generated_furniture_catalog.json');
  const split=await read('review/building_split_validation.json');
  const layout=await read('web/assets/layout.json');
  const edits=await read('sources/models/hi3d/mobile_exhibition_table/local_edits/edit_receipt.json');
  const io=new NodeIO().registerExtensions(ALL_EXTENSIONS).registerDependencies({'draco3d.decoder':await draco3d.createDecoderModule()});
  const rows=[],check=(pass,label,details)=>{rows.push({pass:!!pass,label,details});assert.ok(pass,label);};
  const slots=split.staticSlots.filter(s=>s.id.startsWith('display_table_'));
  check(slots.length===4,'four existing table placements have dimension contracts');
  for(const slot of slots){
    const code=slot.id.slice('display_table_'.length),edit=edits.variants.find(v=>v.widthCode===code);
    check(!!edit,`${slot.id}: preserved local source identifies the tabletop design`);
    check(edit.widthM===slot.target[0]&&edit.tabletopDepthM===slot.target[1],`${slot.id}: target refers to tabletop width/depth, not caster footprint`);
    const source=await io.read(`${root}/${edit.file}`);
    const board=source.getRoot().listNodes().find(n=>n.getName()==='Rounded flat tabletop');
    check(!!board,`${slot.id}: editable source retains a separately measurable tabletop`);
    const bb=getBounds(board),size=bb.max.map((v,i)=>v-bb.min[i]);
    check(Math.abs(size[0]-edit.widthM)<.001&&Math.abs(size[2]-edit.tabletopDepthM)<.001&&Math.abs(bb.max[1]-1)<.001,`${slot.id}: actual source tabletop matches declared width/depth and 1m top within 1mm`,size);
    const candidates=layout.floors['3'].colliders.filter(c=>c.id==='Mobile exhibition tabletop'&&c.rect&&Math.abs((c.rect[0]+c.rect[2])/2-slot.origin[0])<.001&&Math.abs((c.rect[1]+c.rect[3])/2-slot.origin[2])<.001);
    check(candidates.length===1,`${slot.id}: exactly one actual layout collision proxy matches its placement`);
    const rect=candidates[0].rect;
    // build_scene.mobile_display explicitly includes caster overhang in this proxy.
    check(Math.abs(rect[2]-rect[0]-edit.widthM)<.001&&Math.abs(rect[3]-rect[1]-(edit.tabletopDepthM*.96+.13))<.001,`${slot.id}: collision proxy preserves authored wheel-clearance geometry`,rect);
    const cfg=catalog.slots[slot.id],folder=`${root}/web/assets/${catalog.assets[cfg.asset].folder}`,manifest=JSON.parse(await fs.readFile(`${folder}/manifest.json`));
    for(const level of manifest.levels){
      const doc=await io.read(`${folder}/${level.file}`),bounds=getBounds(doc.getRoot().listScenes()[0]);
      check(insideRect(bounds,slot.origin,cfg.uniformScale,rect),`${slot.id} LOD${level.level}: decoded full model lies inside actual collision proxy (1mm encoding tolerance)`,{bounds,rect});
      // Compare both signed edges, not only width/depth: shifted meshes must fail.
      const drift=Math.max(...bounds.min.map((v,i)=>Math.abs(v-manifest.levels[0].bounds.min[i])),...bounds.max.map((v,i)=>Math.abs(v-manifest.levels[0].bounds.max[i])));
      check(drift<=.007,`${slot.id} LOD${level.level}: full geometry preserves near-LOD envelope within 7mm`,{maxEdgeDriftM:drift});
    }
  }
  const base={min:[-.5,0,-.3],max:[.5,1,.3]},rect=[-.5,-.353,.5,.353];
  check(insideRect(base,[0,0,0],1,rect),'fixture: correct geometry fits collision proxy');
  check(!insideRect({min:[-.48,0,-.3],max:[.52,1,.3]},[0,0,0],1,rect),'fixture: same-size mesh shifted 20mm must fail');
  check(!insideRect({min:[-.5,0,-.36],max:[.5,1,.36]},[0,0,0],1,rect),'fixture: geometry outside caster proxy must fail without 108mm exemption');
  return {checks:rows.length,failures:0,rows};
}
