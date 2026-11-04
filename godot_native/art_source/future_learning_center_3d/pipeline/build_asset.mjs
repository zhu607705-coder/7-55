/** Local static-prop pipeline. Never changes source files or scene colliders.
 * node pipeline/build_asset.mjs INPUT.glb OUTPUT_DIR [TARGET_HEIGHT_METERS] [YAW_DEGREES] [MAX_TEXTURE_PX] [MID_INPUT] [FAR_INPUT] [POSITION_BITS=16]
 * Requires npm ci --prefix pipeline. All versions pinned in package-lock.json.
 */
import fs from 'node:fs/promises';
import path from 'node:path';
import crypto from 'node:crypto';
import {NodeIO, getBounds} from '@gltf-transform/core';
import {ALL_EXTENSIONS} from '@gltf-transform/extensions';
import {dedup, flatten, join, prune, weld, simplify, draco, textureCompress} from '@gltf-transform/functions';
import draco3d from 'draco3dgltf';
import {MeshoptSimplifier} from 'meshoptimizer';

const [input, output, heightArg, yawArg, textureArg, midInput, farInput, positionBitsArg] = process.argv.slice(2);
if (!input || !output) throw Error('Usage: node pipeline/build_asset.mjs INPUT OUTPUT_DIR [HEIGHT_M]');
await MeshoptSimplifier.ready;
const io = new NodeIO().registerExtensions(ALL_EXTENSIONS).registerDependencies({
  'draco3d.decoder': await draco3d.createDecoderModule(),
  'draco3d.encoder': await draco3d.createEncoderModule()
});
const source = await fs.readFile(input);
const sha = data => crypto.createHash('sha256').update(data).digest('hex');
const levelSources=await Promise.all([input,midInput||input,farInput||input].map(file=>fs.readFile(file)));
const sourceDoc = await io.readBinary(source);
if (sourceDoc.getRoot().listSkins().length || sourceDoc.getRoot().listAnimations().length)
  throw Error('This static-prop route cannot simplify rigs or animated mechanisms.');
function stats(doc) {
  const root = doc.getRoot(), scenes = root.listScenes();
  const bounds = getBounds(scenes[0]);
  const prims = root.listMeshes().flatMap(m => m.listPrimitives());
  return {
    triangles: prims.reduce((n, p) => n + (p.getMode() === 4 ? (p.getIndices()?.getCount() ?? p.getAttribute('POSITION').getCount()) / 3 : 0), 0),
    primitives: prims.length, bounds,
    size: bounds.max.map((v, i) => v - bounds.min[i]),
    materials: root.listMaterials().map(m => ({name:m.getName(),baseColorTexture:!!m.getBaseColorTexture(),normalTexture:!!m.getNormalTexture(),metalRoughTexture:!!m.getMetallicRoughnessTexture(),occlusionTexture:!!m.getOcclusionTexture(),emissiveTexture:!!m.getEmissiveTexture(),baseColorFactor:m.getBaseColorFactor(),metallicFactor:m.getMetallicFactor(),roughnessFactor:m.getRoughnessFactor()})),
    textures: root.listTextures().map(t => ({name:t.getName(),mime:t.getMimeType(),bytes:t.getImage()?.byteLength??0,size:t.getSize()}))
  };
}
const original = stats(sourceDoc), targetHeight = heightArg ? Number(heightArg) : original.size[1];
const yaw = Number(yawArg || 0) * Math.PI / 180;
const textureLimit = Number(textureArg || 1024);
const positionBits = Number(positionBitsArg || 16);
if(!Number.isInteger(positionBits)||positionBits<16||positionBits>20)throw Error('Position precision must be16–20 bits');
if (!(targetHeight > 0 && targetHeight < 5)) throw Error('Invalid metric prop height');
if (![512,1024,2048].includes(textureLimit)) throw Error('Texture limit must be512,1024 or2048');
await fs.mkdir(output, {recursive:true});
const report = {schema:1,source:{file:path.basename(input),bytes:source.length,sha256:sha(source),...original},
  calibration:{targetHeight,yawDegrees:Number(yawArg||0),uniformScale:targetHeight/original.size[1],groundPivot:'center X/Z; minimum Y = 0',assumedInputAxes:'glTF Y-up; visually verify facing'},textureBudget:{nearMaxPx:textureLimit,midMaxPx:textureLimit/2,farMaxPx:Math.max(256,textureLimit/4)},
  simplification:{lockBorder:false,reason:'Static props with UV seams; verify silhouette and all material boundaries after reduction'},
  encoding:{positionBits},
  tools:{gltfTransform:'4.5.1',meshoptimizer:'1.3.0',draco3dgltf:'1.5.9'},levels:[],
  policy:'Draco changes transfer encoding, not triangle count. LODs are static visual assets; acceptance requires silhouette/material/runtime checks.'};
// Far levels are small enough to instance many times; error may limit reduction.
for (const [level, target, error] of [[0,20000,.0005],[1,8000,.003],[2,2000,.015]]) {
  const doc = await io.readBinary(levelSources[level]);
  const scene = doc.getRoot().listScenes()[0], children = scene.listChildren();
  const pivot = doc.createNode('Metric grounded asset');
  for (const child of children) pivot.addChild(child);
  const scale = targetHeight / original.size[1];
  const cx=(original.bounds.min[0]+original.bounds.max[0])/2, cz=(original.bounds.min[2]+original.bounds.max[2])/2;
  pivot.setScale([scale,scale,scale]).setRotation([0,Math.sin(yaw/2),0,Math.cos(yaw/2)]).setTranslation([
    -(cx*Math.cos(yaw)+cz*Math.sin(yaw))*scale,
    -original.bounds.min[1]*scale,
    -(-cx*Math.sin(yaw)+cz*Math.cos(yaw))*scale
  ]);scene.addChild(pivot);
  await doc.transform(dedup(), flatten(), join(), weld(), prune(), join(), prune());
  const before = stats(doc).triangles;
  if (before > target) await doc.transform(simplify({simplifier:MeshoptSimplifier,ratio:target/before,error,lockBorder:false}),prune());
  const maxTexturePx=Math.max(256,textureLimit/2**level);
  if(doc.getRoot().listTextures().some(t=>t.getSize()?.some(v=>v>maxTexturePx)))
    await doc.transform(textureCompress({resize:[maxTexturePx,maxTexturePx],resizeFilter:'lanczos2'}));
  const plain = await io.writeBinary(doc);
  await fs.writeFile(path.join(output,`lod${level}.glb`),plain);
  const beforeEncoding = stats(doc);
  await doc.transform(draco({method:'edgebreaker',quantizePosition:positionBits,quantizeNormal:10,quantizeTexcoord:12,encodeSpeed:5,decodeSpeed:5}));
  const compressed = await io.writeBinary(doc), filename=`lod${level}.draco.glb`;
  await fs.writeFile(path.join(output,filename),compressed);
  // Decode each emitted GLB with an independent decoder read before reporting it.
  const decoded = stats(await io.readBinary(compressed));
  const boundsError = Math.max(...decoded.bounds.min.map((v,i)=>Math.abs(v-beforeEncoding.bounds.min[i])),...decoded.bounds.max.map((v,i)=>Math.abs(v-beforeEncoding.bounds.max[i])));
  if (decoded.triangles !== beforeEncoding.triangles || boundsError > .001)
    throw Error(`LOD${level} Draco integrity failed: triangles ${beforeEncoding.triangles} -> ${decoded.triangles}; bounds error ${boundsError}`);
  report.levels.push({level,inputFile:path.basename([input,midInput||input,farInput||input][level]),inputSha256:sha(levelSources[level]),file:filename,uncompressedFile:`lod${level}.glb`,requestedTarget:target,error,boundsEncodingErrorM:boundsError,bytes:compressed.length,uncompressedBytes:plain.length,sha256:sha(compressed),...decoded});
}
await fs.writeFile(path.join(output,'manifest.json'),JSON.stringify(report,null,2)+'\n');
console.log(JSON.stringify(report.levels.map(({level,triangles,bytes,uncompressedBytes,size,boundsEncodingErrorM})=>({level,triangles,bytes,uncompressedBytes,size,boundsEncodingErrorM})),null,2));
