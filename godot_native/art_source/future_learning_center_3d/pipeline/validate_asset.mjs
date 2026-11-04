import fs from 'node:fs/promises';
import crypto from 'node:crypto';
import assert from 'node:assert/strict';
import {NodeIO,getBounds} from '@gltf-transform/core';
import {ALL_EXTENSIONS} from '@gltf-transform/extensions';
import draco3d from 'draco3dgltf';
const io=new NodeIO().registerExtensions(ALL_EXTENSIONS).registerDependencies({'draco3d.decoder':await draco3d.createDecoderModule()});
const rows=[],check=(ok,label,details)=>{rows.push({pass:!!ok,label,details});assert.ok(ok,label);};
const base='web/assets/models/ergonomic_chair/hyper3d/',manifest=JSON.parse(await fs.readFile(base+'manifest.json'));
const original=await io.read('sources/models/hyper3d_ergonomic_chair_original.glb'),names=original.getRoot().listNodes().map(n=>n.getName());
check(names.filter(n=>/^Base spoke \d+_export$/.test(n)).length===5,'source has five independent base spokes');
check(names.filter(n=>/^Caster \d+ wheel -?1_export$/.test(n)).length===10,'source has ten wheels in five twin casters');
for(const name of ['Curved floating lumbar support_export','Headrest woven textile_export','Contoured seat cushion_export','Left arm pad_export','Right arm pad_export'])check(names.includes(name),'source includes '+name);
for(const level of manifest.levels){
 const data=await fs.readFile(base+level.file),doc=await io.readBinary(data),bounds=getBounds(doc.getRoot().listScenes()[0]);
 check(crypto.createHash('sha256').update(data).digest('hex')===level.sha256,`LOD${level.level} binds exact compressed file hash`);
 let triangles=0;
 for(const mesh of doc.getRoot().listMeshes())for(const p of mesh.listPrimitives()){
  const positions=p.getAttribute('POSITION'),indices=p.getIndices();triangles+=(indices?.getCount()??positions.getCount())/3;
  check([...positions.getArray()].every(Number.isFinite),`LOD${level.level} ${mesh.getName()} positions are finite`);
  check(!indices||[...indices.getArray()].every(i=>i>=0&&i<positions.getCount()),`LOD${level.level} ${mesh.getName()} indices address real vertices`);
 }
 check(triangles===level.triangles,`LOD${level.level} decoded triangle count matches receipt`,triangles);
 check(Math.abs(bounds.max[1]-1.29)<.002&&Math.abs(bounds.min[1])<.003,`LOD${level.level} stays at metric head/foot heights`,bounds);
 check(level.size[0]<=.71&&level.size[2]<=.71,`LOD${level.level} fits original chair collision footprint`,level.size);
 check(level.boundsEncodingErrorM<.001,`LOD${level.level} Draco envelope error below 1mm`,level.boundsEncodingErrorM);
}
check(manifest.levels[0].triangles>manifest.levels[1].triangles&&manifest.levels[1].triangles>manifest.levels[2].triangles,'detail levels reduce real geometry');
check(manifest.source.textures.length===0,'receipt accurately records factor-only PBR, without inventing texture maps');
await fs.writeFile('review/asset_geometry_validation.json',JSON.stringify({checks:rows.length,failures:0,rows,scope:'Geometry/decode/source-part checks plus separate screenshot review; no survey or production-asset certification.'},null,2)+'\n');
console.log(`Asset geometry: ${rows.length} checks passed`);
