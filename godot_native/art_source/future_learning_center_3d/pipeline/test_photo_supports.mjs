/** Real Draco decoding for two provisional photo support candidates.
 * Occluded geometry and all dimensions are assumptions, not manufacturer CAD.
 * Preserves monitor/divider/arm against the verified restored Library v1 snapshot.
 * Keyboard and mouse are explicitly revised by the 2026-11-03 user request.
 */
import fs from 'node:fs/promises';
import crypto from 'node:crypto';
import assert from 'node:assert/strict';
import {execFileSync} from 'node:child_process';
import {NodeIO,getBounds} from '@gltf-transform/core';
import {ALL_EXTENSIONS} from '@gltf-transform/extensions';
import draco3d from 'draco3dgltf';
const baseline='3f7ca5ed03339538229e2e6dc1e8dbf768f18baf';
const art='godot_native/art_source/future_learning_center_3d/';
const io=new NodeIO().registerExtensions(ALL_EXTENSIONS).registerDependencies({'draco3d.decoder':await draco3d.createDecoderModule()});
const rows=[],preserved=[];const check=(ok,label,details)=>{rows.push({pass:!!ok,label,details});assert.ok(ok,label);};
const sha=b=>crypto.createHash('sha256').update(b).digest('hex');
const report=JSON.parse(await fs.readFile('review/photo_desktop/supports_build_report.json'));
// XYZ below means glTF width/height/depth, not Blender's Z-up axis order.
const contracts={photo_desk_divider:{range:[[1.5,1.8],[.35,.5],[.6,.8]],parts:[/^Rear divider/i,/^Right return/i]},photo_monitor_arm:{range:[[.2,.35],[.45,.65],[.06,.15]],parts:[/^Lower.*segment/i,/^Upper.*segment/i,/^Visible elbow joint/i,/^Inferred desk clamp/i,/^Display tilt joint/i]}};
const primitiveList=doc=>doc.getRoot().listMeshes().flatMap(m=>m.listPrimitives());
function sceneTriangles(doc){let triangles=0;doc.getRoot().listScenes()[0].traverse(n=>{for(const p of n.getMesh()?.listPrimitives()??[])triangles+=(p.getIndices()?.getCount()??p.getAttribute('POSITION').getCount())/3;});return triangles;}
function size(bounds){return bounds.max.map((v,i)=>v-bounds.min[i]);}
for(const [id,contract] of Object.entries(contracts)){
 const sourceBase=`sources/models/photo_desktop/${id}/`,runtimeBase=`web/assets/models/photo_desktop/${id}/`,manifest=JSON.parse(await fs.readFile(runtimeBase+'manifest.json'));
 const receipts=[0,1,2].map(level=>report.records.filter(r=>r.asset===id&&r.level===level));
 check(receipts.every(r=>r.length===1),id+' exactly one independent source receipt per LOD');
 check(manifest.levels.length===3&&manifest.levels.map(l=>l.level).join(',')==='0,1,2',id+' three ordered real LODs');
 check(manifest.encoding.positionBits===20,id+' explicit 20-bit mechanical detail encoding');
 const blend=await fs.readFile(sourceBase+id+'.blend');check(blend.subarray(0,7).toString()==='BLENDER',id+' editable native source exists');
 for(const level of manifest.levels){
  const label=`${id} LOD${level.level}`,receipt=receipts[level.level][0],sourceBytes=await fs.readFile(sourceBase+`lod${level.level}_source.glb`),source=await io.readBinary(sourceBytes),sourceBounds=getBounds(source.getRoot().listScenes()[0]),sourceSize=size(sourceBounds),receiptSize=[receipt.sizeBlenderXYZ[0],receipt.sizeBlenderXYZ[2],receipt.sizeBlenderXYZ[1]];
  if(level.level===0){const names=source.getRoot().listNodes().map(n=>n.getName());for(const part of contract.parts)check(names.some(name=>part.test(name)),id+' separate authored structure '+part);}
  check(sourceSize.every((v,i)=>Math.abs(v-receiptSize[i])<.00001),label+' source bounds independently match Blender receipt',sourceSize);
  check(sourceSize.every((v,i)=>v>=contract.range[i][0]&&v<=contract.range[i][1]),label+' fits provisional candidate range, not measured photo scale',sourceSize);
  check(sceneTriangles(source)===receipt.triangles,label+' source triangles independently match receipt');
  check(sha(sourceBytes)===receipt.sha256&&sha(sourceBytes)===level.inputSha256,label+' input provenance hashes');
  check(source.getRoot().listTextures().length===0&&source.getRoot().listSkins().length===0&&source.getRoot().listAnimations().length===0,label+' static factor material source, no fabricated image or rig');
  const bytes=await fs.readFile(runtimeBase+level.file),json=JSON.parse(bytes.subarray(20,20+bytes.readUInt32LE(12))),doc=await io.readBinary(bytes),bounds=getBounds(doc.getRoot().listScenes()[0]),decodedSize=size(bounds);
  check(json.meshes.every(m=>m.primitives.every(p=>p.extensions?.KHR_draco_mesh_compression)),label+' actual Draco-coded primitive bytes');
  check(![...(json.buffers??[]),...(json.images??[])].some(item=>item.uri&&!item.uri.startsWith('data:')),label+' GLB is self-contained');
  check(sha(bytes)===level.sha256&&bytes.length===level.bytes,label+' exact emitted file hash and size');
  let triangles=0,finite=true,validIndices=true,degenerate=0,normalValid=true;
  for(const p of primitiveList(doc)){
   check(p.getMode()===4,label+' triangle primitive topology');
   const pos=p.getAttribute('POSITION'),normal=p.getAttribute('NORMAL'),idx=p.getIndices(),a=pos.getArray(),ii=idx?.getArray()??Array.from({length:pos.getCount()},(_,i)=>i);triangles+=ii.length/3;
   finite&&=[...a].every(Number.isFinite);validIndices&&=ii.length%3===0&&[...ii].every(i=>Number.isInteger(i)&&i>=0&&i<pos.getCount());
   if(!normal)normalValid=false;else{const n=normal.getArray();for(let i=0;i<n.length;i+=3){const length=Math.hypot(n[i],n[i+1],n[i+2]);normalValid&&=Number.isFinite(length)&&Math.abs(length-1)<.01;}}
   for(let i=0;i<ii.length;i+=3){const x=ii[i]*3,y=ii[i+1]*3,z=ii[i+2]*3,u=[0,1,2].map(k=>a[y+k]-a[x+k]),v=[0,1,2].map(k=>a[z+k]-a[x+k]);if(Math.hypot(u[1]*v[2]-u[2]*v[1],u[2]*v[0]-u[0]*v[2],u[0]*v[1]-u[1]*v[0])<1e-12)degenerate++;}
  }
  check(finite&&validIndices,label+' real finite vertices and valid indices');check(normalValid,label+' real finite unit normals');check(degenerate===0,label+' no zero-area decoded triangles',degenerate);check(triangles===level.triangles,label+' actual decoded triangle count',triangles);
  check(decodedSize.every((v,i)=>Math.abs(v-sourceSize[i])<.001),label+' source envelope preserved within 1mm',{decodedSize,sourceSize});
  check(Math.abs(bounds.min[1])<.0001,label+' grounded pivot');
  check(Math.abs(bounds.min[0]+bounds.max[0])<.001&&Math.abs(bounds.min[2]+bounds.max[2])<.001,label+' near-source center pivot retained');
  const plain=await io.read(runtimeBase+level.uncompressedFile),plainBounds=getBounds(plain.getRoot().listScenes()[0]),edgeError=Math.max(...bounds.min.map((v,i)=>Math.abs(v-plainBounds.min[i])),...bounds.max.map((v,i)=>Math.abs(v-plainBounds.max[i])));
  check(edgeError<.0001,label+' real plain/Draco edge error below 0.1mm',edgeError);check(sceneTriangles(plain)===triangles,label+' encoding leaves triangle count unchanged');
  const materials=doc.getRoot().listMaterials();check(materials.length>=2&&materials.length<=8,label+' distinct bounded material groups',materials.length);
  check(materials.every(m=>[m.getMetallicFactor(),m.getRoughnessFactor(),...m.getBaseColorFactor()].every(v=>Number.isFinite(v)&&v>=0&&v<=1)),label+' bounded factor PBR');
  check(materials.every(m=>m.getEmissiveFactor().every(v=>v===0))&&doc.getRoot().listTextures().length===0,label+' no active light or photo texture');
 }
 check(manifest.levels[0].triangles>manifest.levels[1].triangles&&manifest.levels[1].triangles>manifest.levels[2].triangles,id+' genuinely decreasing decoded LOD triangle counts');
 check(Math.abs(manifest.calibration.uniformScale-1)<.0001,id+' no hidden scale correction');
}
// No implicit network fetch: the immutable baseline must already be present locally.
const paths=execFileSync('git',['ls-tree','-r','--name-only','--full-tree',baseline,'--',art+'sources/models/photo_desktop',art+'web/assets/models/photo_desktop'],{encoding:'utf8'}).trim().split('\n').filter(p=>/\/(photo_monitor_stand|photo_desk_divider|photo_monitor_arm)\//.test(p)&&/\.(blend|glb)$/.test(p));
check(paths.length===30,'baseline contains all 30 unaffected monitor/divider/arm files');
for(const file of paths){const before=execFileSync('git',['show',baseline+':'+file],{maxBuffer:64*1024*1024}),now=await fs.readFile(file.slice(art.length));check(now.equals(before),'unaffected candidate unchanged: '+file);preserved.push({path:file,sha256:sha(now),bytes:now.length});}
await fs.writeFile('review/photo_desktop/supports_validation.json',JSON.stringify({checks:rows.length,failures:0,scope:'Real Draco decode and source/data checks for two additional candidates; hidden structure and scale remain provisional. Not browser/GPU or certified support/load acceptance.',preservedBaseline:baseline,preservedOriginalFiles:preserved,rows},null,2)+'\n');
console.log(`Photo support samples: ${rows.length} checks passed; ${preserved.length} original files byte-identical`);
