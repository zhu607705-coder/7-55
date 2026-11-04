import fs from 'node:fs/promises';
import crypto from 'node:crypto';
import assert from 'node:assert/strict';
import {NodeIO,getBounds} from '@gltf-transform/core';
import {ALL_EXTENSIONS} from '@gltf-transform/extensions';
import draco3d from 'draco3dgltf';
const io=new NodeIO().registerExtensions(ALL_EXTENSIONS).registerDependencies({'draco3d.decoder':await draco3d.createDecoderModule()});
const rows=[],check=(v,label,details)=>{rows.push({pass:!!v,label,details});assert.ok(v,label);};
const expected={printer_enclosure_study:[.492,.626,.514],laser_enclosure_study:[1,.268,.639],bench_power_supply:[.3,.28,.25]};
const parts={printer_enclosure_study:['Closed front glazing','Build bed plate','Blank recessed touchscreen','Door handle'],laser_enclosure_study:['Closed tinted lid glass','Internal bed','Blank control display','Lid front pull'],bench_power_supply:['Folded instrument enclosure','Blank LCD no voltage/current readout','Adjustment dial','Terminal dark recess']};
for(const [id,sizeGoal] of Object.entries(expected)){
 const folder=`web/assets/models/lab_tools/${id}/`,m=JSON.parse(await fs.readFile(folder+'manifest.json'));
 const source=await io.read(`sources/models/lab_tools/${id}/lod0_source.glb`),names=source.getRoot().listNodes().map(n=>n.getName());
 for(const part of parts[id])check(names.some(n=>n===part||n.startsWith(part+'.')),id+' has separate '+part);
 check(source.getRoot().listAnimations().length===0&&source.getRoot().listSkins().length===0,id+' remains static non-operational sample');
 check(source.getRoot().listTextures().length===0,id+' factor-only PBR declared honestly');
 check(source.getRoot().listMaterials().every(m=>m.getEmissiveFactor().every(x=>x===0)),id+' no fabricated active display or light output');
 check(m.levels.length===3,id+' has three levels');
 for(const l of m.levels){
  const bytes=await fs.readFile(folder+l.file),doc=await io.readBinary(bytes),bounds=getBounds(doc.getRoot().listScenes()[0]),size=bounds.max.map((v,i)=>v-bounds.min[i]);
  check(crypto.createHash('sha256').update(bytes).digest('hex')===l.sha256,`${id} LOD${l.level} exact file hash`);
  check(size.every((v,i)=>Math.abs(v-sizeGoal[i])<.001),`${id} LOD${l.level} decoded metric envelope within1mm`,size);
  check(Math.abs(bounds.min[1])<.0001&&Math.abs(bounds.min[0]+bounds.max[0])<.0001&&Math.abs(bounds.min[2]+bounds.max[2])<.0001,`${id} LOD${l.level} grounded center pivot`,bounds);
  let count=0,finite=true,indexValid=true,degenerate=0;
  for(const mesh of doc.getRoot().listMeshes())for(const p of mesh.listPrimitives()){
   const pos=p.getAttribute('POSITION'),idx=p.getIndices();count+=(idx?.getCount()??pos.getCount())/3;finite&&=[...pos.getArray()].every(Number.isFinite);indexValid&&=!idx||[...idx.getArray()].every(i=>i>=0&&i<pos.getCount());
   const a=pos.getArray(),ii=idx?.getArray()??Array.from({length:pos.getCount()},(_,i)=>i);
   for(let k=0;k<ii.length;k+=3){const p=ii[k]*3,q=ii[k+1]*3,r=ii[k+2]*3,u=[0,1,2].map(j=>a[q+j]-a[p+j]),v=[0,1,2].map(j=>a[r+j]-a[p+j]);if(Math.hypot(u[1]*v[2]-u[2]*v[1],u[2]*v[0]-u[0]*v[2],u[0]*v[1]-u[1]*v[0])<1e-12)degenerate++;}
  }
  check(finite&&indexValid,`${id} LOD${l.level} real finite vertices and valid indices`);
  check(degenerate===0,`${id} LOD${l.level} has no zero-area decoded triangles`,degenerate);
  check(count===l.triangles,`${id} LOD${l.level} actual triangle count`,count);
  const plain=await io.read(folder+l.uncompressedFile),pb=getBounds(plain.getRoot().listScenes()[0]);
  const err=Math.max(...bounds.min.map((v,i)=>Math.abs(v-pb.min[i])),...bounds.max.map((v,i)=>Math.abs(v-pb.max[i])));
  check(err<.0001,`${id} LOD${l.level} Draco edge error below0.1mm`,err);
  check(doc.getRoot().listMaterials().every(mat=>mat.getMetallicFactor()>=0&&mat.getMetallicFactor()<=1&&mat.getRoughnessFactor()>=0&&mat.getRoughnessFactor()<=1),`${id} LOD${l.level} bounded PBR factors`);
  if(id!=='bench_power_supply')check(doc.getRoot().listMaterials().some(mat=>mat.getExtension('KHR_materials_transmission')?.getTransmissionFactor()>.7),`${id} LOD${l.level} real glTF transmission material preserved`);
 }
 check(m.levels[0].triangles>m.levels[1].triangles&&m.levels[1].triangles>m.levels[2].triangles,id+' genuinely reduces polygon count at both distances');
}
await fs.writeFile('review/lab_tools/validation.json',JSON.stringify({checks:rows.length,failures:0,scope:'Actual decoded equipment geometry/material data, not operational simulation or browser acceptance',rows},null,2)+'\n');console.log(`Lab tool samples: ${rows.length} checks passed`);
