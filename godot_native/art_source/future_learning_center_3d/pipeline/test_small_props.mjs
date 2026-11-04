import fs from 'node:fs/promises';
import crypto from 'node:crypto';
import assert from 'node:assert/strict';
import {NodeIO,getBounds} from '@gltf-transform/core';
import {ALL_EXTENSIONS} from '@gltf-transform/extensions';
import draco3d from 'draco3dgltf';
const io=new NodeIO().registerExtensions(ALL_EXTENSIONS).registerDependencies({'draco3d.decoder':await draco3d.createDecoderModule()});
const rows=[],check=(v,label,details)=>{rows.push({pass:!!v,label,details});assert.ok(v,label);};
for(const [id,length] of [['caliper_150',.233],['screwdriver_3x100',.204],['display_tray',.42]]){
 const folder=`web/assets/models/small_props/${id}/`,m=JSON.parse(await fs.readFile(folder+'manifest.json'));
 check(m.levels.length===3,id+' has three real levels');
 const source=await io.read(`sources/models/small_props/${id}/lod0_source.glb`);
 check(source.getRoot().listAnimations().length===0&&source.getRoot().listSkins().length===0,id+' static sample has no hidden animation or rig');
 check(source.getRoot().listTextures().length===0,id+' factor-based PBR accurately declared');
 for(const l of m.levels){
  const bytes=await fs.readFile(folder+l.file),doc=await io.readBinary(bytes),bounds=getBounds(doc.getRoot().listScenes()[0]),size=bounds.max.map((v,i)=>v-bounds.min[i]);
  check(crypto.createHash('sha256').update(bytes).digest('hex')===l.sha256,`${id} LOD${l.level} hash`);
  check(Math.abs(size[0]-length)<.0005,`${id} LOD${l.level} length within0.5mm`,size);
  check(Math.abs(bounds.min[1])<.0005,`${id} LOD${l.level} grounded pivot`);
  check(Math.abs(bounds.max[0]+bounds.min[0])<.0005&&Math.abs(bounds.max[2]+bounds.min[2])<.0005,`${id} LOD${l.level} centered X/Z`);
  if(id==='display_tray')check(Math.abs(size[2]-.32)<.0005&&Math.abs(size[1]-.04)<.0005,`tray LOD${l.level} 420x320x40mm`,size);
  if(id==='screwdriver_3x100')check(size[1]<=.0235&&size[2]<=.0235,`driver LOD${l.level} 23mm handle envelope`,size);
  let triangles=0,finite=true,indices=true;
  for(const mesh of doc.getRoot().listMeshes())for(const p of mesh.listPrimitives()){
   const pos=p.getAttribute('POSITION'),ix=p.getIndices();triangles+=(ix?.getCount()??pos.getCount())/3;finite&&=[...pos.getArray()].every(Number.isFinite);indices&&=!ix||[...ix.getArray()].every(v=>v>=0&&v<pos.getCount());
  }
  check(finite&&indices,`${id} LOD${l.level} real finite indexed geometry`);
  check(triangles===l.triangles,`${id} LOD${l.level} exact decoded triangles`,triangles);
  const plain=await io.read(folder+l.uncompressedFile),pb=getBounds(plain.getRoot().listScenes()[0]);
  const err=Math.max(...bounds.min.map((v,i)=>Math.abs(v-pb.min[i])),...bounds.max.map((v,i)=>Math.abs(v-pb.max[i])));
  check(err<.0001,`${id} LOD${l.level} encoding edge error below0.1mm`,err);
  check(doc.getRoot().listMaterials().every(mat=>mat.getMetallicFactor()>=0&&mat.getMetallicFactor()<=1&&mat.getRoughnessFactor()>=0&&mat.getRoughnessFactor()<=1),`${id} LOD${l.level} bounded PBR factors`);
 }
 check(m.levels[0].triangles>m.levels[1].triangles&&m.levels[1].triangles>m.levels[2].triangles,id+' actual polygon reductions');
}
await fs.writeFile('review/small_props/validation.json',JSON.stringify({checks:rows.length,failures:0,scope:'Decoded geometry/scale/material data; not browser interaction acceptance',rows},null,2));console.log(`Small props: ${rows.length} checks passed`);
