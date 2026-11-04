/** Decode emitted Draco bytes and compare against independent source geometry.
 * Candidate metric envelopes are design assumptions: the photo has no ruler.
 * Passing this file does not prove photo scale, exact product identity or WebGL.
 */
import fs from 'node:fs/promises';
import crypto from 'node:crypto';
import assert from 'node:assert/strict';
import {NodeIO,getBounds} from '@gltf-transform/core';
import {ALL_EXTENSIONS} from '@gltf-transform/extensions';
import draco3d from 'draco3dgltf';
const io=new NodeIO().registerExtensions(ALL_EXTENSIONS).registerDependencies({'draco3d.decoder':await draco3d.createDecoderModule()});
const sha=bytes=>crypto.createHash('sha256').update(bytes).digest('hex');
const vertexColorComparisons=[];
const rows=[],check=(ok,label,details)=>{rows.push({pass:!!ok,label,details});assert.ok(ok,label);};
const report=JSON.parse(await fs.readFile('review/photo_desktop/build_report.json'));
// glTF X width / Y height / Z depth; broad height bounds avoid fixing an unverified stand height.
const candidates={
 photo_monitor_stand:{range:[[.55,.68],[.38,.60],[.12,.36]],parts:[/panel|screen|display/i,/stand|neck|stem|upright/i,/base|foot/i]},
 photo_keyboard:{range:[[.33,.41],[.012,.06],[.12,.18]],parts:[/shell|body|case|housing/i,/keycap|key cap|key\b/i]},
 photo_mouse:{range:[[.05,.08],[.02,.06],[.10,.15]],parts:[/shell|body|case|housing/i,/button/i,/wheel/i]}
};
function geometry(doc){
 let triangles=0,finite=true,indices=true,degenerate=0;
 for(const mesh of doc.getRoot().listMeshes())for(const primitive of mesh.listPrimitives()){
  check(primitive.getMode()===4,'decoded primitive uses triangle topology');
  const pos=primitive.getAttribute('POSITION'),idx=primitive.getIndices();
  if(!pos){finite=false;continue;}
  const values=pos.getArray(),order=idx?.getArray()??Array.from({length:pos.getCount()},(_,i)=>i);
  triangles+=order.length/3;finite&&=[...values].every(Number.isFinite);indices&&=order.length%3===0&&[...order].every(i=>Number.isInteger(i)&&i>=0&&i<pos.getCount());
  for(let k=0;k<order.length;k+=3){const a=order[k]*3,b=order[k+1]*3,c=order[k+2]*3,u=[0,1,2].map(j=>values[b+j]-values[a+j]),v=[0,1,2].map(j=>values[c+j]-values[a+j]);if(Math.hypot(u[1]*v[2]-u[2]*v[1],u[2]*v[0]-u[0]*v[2],u[0]*v[1]-u[1]*v[0])<1e-12)degenerate++;}
 }
 return {triangles,finite,indices,degenerate};
}
function sceneTriangles(doc){let count=0;doc.getRoot().listScenes()[0].traverse(node=>{for(const p of node.getMesh()?.listPrimitives()??[])count+=(p.getIndices()?.getCount()??p.getAttribute('POSITION').getCount())/3;});return count;}
const sizeOf=bounds=>bounds.max.map((v,i)=>v-bounds.min[i]);
function pbrOK(material){return [material.getMetallicFactor(),material.getRoughnessFactor(),...material.getBaseColorFactor()].every(v=>Number.isFinite(v)&&v>=0&&v<=1);}
for(const [id,contract] of Object.entries(candidates)){
 const folder=`web/assets/models/photo_desktop/${id}/`,base=`sources/models/photo_desktop/${id}/`,manifest=JSON.parse(await fs.readFile(folder+'manifest.json'));
 const records=[0,1,2].map(level=>report.records.filter(r=>r.asset===id&&r.level===level));
 check(records.every(list=>list.length===1),id+' one independent Blender receipt per LOD');
 check(manifest.levels.length===3&&manifest.levels.map(l=>l.level).join(',')==='0,1,2',id+' three ordered real LOD files');
 check(manifest.encoding.positionBits===20,id+' small-detail 20-bit encoding explicitly reported');
 const blend=await fs.readFile(base+id+'.blend');check(blend.subarray(0,7).toString()==='BLENDER',id+' editable native Blender source exists');
 for(const l of manifest.levels){
  const receipt=records[l.level][0],sourceBytes=await fs.readFile(base+`lod${l.level}_source.glb`),source=await io.readBinary(sourceBytes),sourceBounds=getBounds(source.getRoot().listScenes()[0]),sourceSize=sizeOf(sourceBounds),reported=[receipt.sizeBlenderXYZ[0],receipt.sizeBlenderXYZ[2],receipt.sizeBlenderXYZ[1]];
  if(l.level===0){const names=source.getRoot().listNodes().map(node=>node.getName());for(const part of contract.parts)check(names.some(name=>part.test(name)),id+' independently modeled source part '+part);}
  check(sourceSize.every((v,i)=>Math.abs(v-reported[i])<.00001),`${id} LOD${l.level} actual source bounds agree with Blender XYZ receipt`,{sourceSize,reported});
  check(sourceSize.every((v,i)=>v>=contract.range[i][0]&&v<=contract.range[i][1]),`${id} LOD${l.level} candidate envelope within documented design ranges (not measured photo scale)`,sourceSize);
  check(sceneTriangles(source)===receipt.triangles,`${id} LOD${l.level} source triangles match Blender receipt`,{actual:sceneTriangles(source),receipt:receipt.triangles});
  check(sha(sourceBytes)===l.inputSha256&&(!receipt.sha256||sha(sourceBytes)===receipt.sha256),`${id} LOD${l.level} source provenance hashes`);
  check(source.getRoot().listTextures().length===0,`${id} LOD${l.level} no fabricated image/screen texture`);
  check(source.getRoot().listAnimations().length===0&&source.getRoot().listSkins().length===0,`${id} LOD${l.level} static source without hidden rig or operation`);
  const bytes=await fs.readFile(folder+l.file),doc=await io.readBinary(bytes),bounds=getBounds(doc.getRoot().listScenes()[0]),size=sizeOf(bounds),stats=geometry(doc);
  const encodedJSON=JSON.parse(bytes.subarray(20,20+bytes.readUInt32LE(12)).toString());check(encodedJSON.meshes.every(mesh=>mesh.primitives.every(p=>p.extensions?.KHR_draco_mesh_compression)),`${id} LOD${l.level} bytes actually contain Draco-coded primitives`);
  check(sha(bytes)===l.sha256&&bytes.length===l.bytes,`${id} LOD${l.level} emitted Draco bytes match manifest`);
  check(stats.finite&&stats.indices,`${id} LOD${l.level} finite vertices and valid triangle indices`);
  check(stats.degenerate===0,`${id} LOD${l.level} no zero-area decoded triangles`,stats.degenerate);
  check(stats.triangles===l.triangles,`${id} LOD${l.level} exact decoded triangle count`,stats.triangles);
  check(size.every((v,i)=>Math.abs(v-sourceSize[i])<.001),`${id} LOD${l.level} encoded envelope preserves source within 1mm`,{size,sourceSize});
  check(Math.abs(bounds.min[1])<.0001,`${id} LOD${l.level} grounded pivot`,bounds.min[1]);
  check(Math.abs(bounds.min[0]+bounds.max[0])<.001&&Math.abs(bounds.min[2]+bounds.max[2])<.001,`${id} LOD${l.level} center pivot drift below 1mm`,bounds);
  const plain=await io.read(folder+l.uncompressedFile),plainBounds=getBounds(plain.getRoot().listScenes()[0]),edgeError=Math.max(...bounds.min.map((v,i)=>Math.abs(v-plainBounds.min[i])),...bounds.max.map((v,i)=>Math.abs(v-plainBounds.max[i])));
  check(edgeError<.0001,`${id} LOD${l.level} real Draco/plain edge error below 0.1mm`,edgeError);
  check(sceneTriangles(plain)===stats.triangles,`${id} LOD${l.level} encoding retains plain triangle count`);
  if(id==='photo_mouse'){
   const coloredPrimitives=d=>d.getRoot().listMeshes().flatMap(mesh=>mesh.listPrimitives()).filter(p=>p.getAttribute('COLOR_0'));
   const plainParts=coloredPrimitives(plain),decodedParts=coloredPrimitives(doc);
   check(plainParts.length>0&&decodedParts.length===plainParts.length,`${id} LOD${l.level} actual Draco decode retains COLOR_0 primitives`);
   const collect=parts=>{const vertices=[],colors=[],components=new Set();let bounded=true;for(const p of parts){const position=p.getAttribute('POSITION'),color=p.getAttribute('COLOR_0');components.add(color.getElementSize());for(let i=0;i<color.getCount();i++){const point=[],value=[];position.getElement(i,point);color.getElement(i,value);vertices.push(point);colors.push(value);bounded&&=value.every(v=>Number.isFinite(v)&&v>=0&&v<=1);}}return {vertices,colors,bounded,components:[...components].sort()};};
   const a=collect(plainParts),b=collect(decodedParts),uniqueColors=new Set(b.colors.map(c=>c.map(v=>v.toFixed(4)).join(','))).size;
   check(plainParts.concat(decodedParts).every(p=>p.getAttribute('POSITION').getCount()===p.getAttribute('COLOR_0').getCount())&&JSON.stringify(a.components)===JSON.stringify(b.components)&&b.components.every(n=>n===3||n===4),`${id} LOD${l.level} one color per vertex and RGB/RGBA components preserved`);
   check(a.bounded&&b.bounded&&uniqueColors>=8,`${id} LOD${l.level} decoded colors finite, bounded and genuinely varying`,{uniqueColors});
   // Draco may reorder or split shared vertices. Triangle counts remain exact.
   // Compare geometry AND color in BOTH directions, so no source vertex disappears.
   // and constrain that distance independently so missing geometry cannot pass.
   let maxNearestPositionErrorM=0,maxColorError=0;
   for(const [from,to] of [[b,a],[a,b]]) for(let i=0;i<from.vertices.length;i++){
    let nearest=-1,distance=Infinity;
    for(let j=0;j<to.vertices.length;j++){const u=from.vertices[i],v=to.vertices[j];const d=Math.hypot(u[0]-v[0],u[1]-v[1],u[2]-v[2]);if(d<distance){distance=d;nearest=j;}}
    maxNearestPositionErrorM=Math.max(maxNearestPositionErrorM,distance);
    maxColorError=Math.max(maxColorError,...from.colors[i].map((v,k)=>Math.abs(v-to.colors[nearest][k])));
   }
   const comparison={asset:id,level:l.level,plainVertices:a.vertices.length,decodedVertices:b.vertices.length,colorComponents:b.components,uniqueDecodedColors:uniqueColors,maxNearestPositionErrorM,maxColorError,positionToleranceM:1e-5,colorTolerance:2/255};vertexColorComparisons.push(comparison);
   check(maxNearestPositionErrorM<=comparison.positionToleranceM,`${id} LOD${l.level} color correspondence stays within 0.01mm`,comparison);
   check(maxColorError<=comparison.colorTolerance,`${id} LOD${l.level} real decoded vertex color error within 2/255`,comparison);
  }
  const materials=doc.getRoot().listMaterials();check(materials.length>=2&&materials.length<=12,`${id} LOD${l.level} nontrivial bounded material count`,materials.length);
  check(materials.every(pbrOK),`${id} LOD${l.level} finite bounded factor PBR`);
  check(materials.every(m=>m.getEmissiveFactor().every(v=>v===0))&&doc.getRoot().listTextures().length===0,`${id} LOD${l.level} blank non-emissive display/no fabricated artwork`);
 }
 check(manifest.levels[0].triangles>manifest.levels[1].triangles&&manifest.levels[1].triangles>manifest.levels[2].triangles,id+' strict decoded near/mid/far polygon reduction');
 check(Math.abs(manifest.calibration.uniformScale-1)<.0001,id+' receipt calibration does not disguise scale correction',manifest.calibration.uniformScale);
}
await fs.writeFile('review/photo_desktop/validation.json',JSON.stringify({checks:rows.length,failures:0,scope:'Actual Draco decode, independent source geometry/material/provenance checks. Photo has no ruler; dimensions are provisional candidates. Not exact-product or browser/GPU acceptance.',vertexColorComparisons,rows},null,2)+'\n');
console.log(`Photo desktop samples: ${rows.length} checks passed`);
