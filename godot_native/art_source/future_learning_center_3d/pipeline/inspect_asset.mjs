import fs from 'node:fs/promises';
import {NodeIO,getBounds} from '@gltf-transform/core';
import {ALL_EXTENSIONS} from '@gltf-transform/extensions';
import draco3d from 'draco3dgltf';
import {MeshoptDecoder} from 'meshoptimizer';
await MeshoptDecoder.ready;
const io=new NodeIO().registerExtensions(ALL_EXTENSIONS).registerDependencies({'draco3d.decoder':await draco3d.createDecoderModule(),'meshopt.decoder':MeshoptDecoder});
for(const file of process.argv.slice(2)){
 const doc=await io.read(file),root=doc.getRoot(),bounds=getBounds(root.listScenes()[0]);
 const row={file,bytes:(await fs.stat(file)).size,bounds,size:bounds.max.map((v,i)=>v-bounds.min[i]),
  triangles:root.listMeshes().flatMap(m=>m.listPrimitives()).reduce((n,p)=>n+(p.getIndices()?.getCount()??p.getAttribute('POSITION').getCount())/3,0),
  materials:root.listMaterials().map(m=>({name:m.getName(),baseColor:!!m.getBaseColorTexture(),normal:!!m.getNormalTexture(),metalRough:!!m.getMetallicRoughnessTexture(),occlusion:!!m.getOcclusionTexture()})),
  textures:root.listTextures().map(t=>({name:t.getName(),size:t.getSize(),mime:t.getMimeType(),bytes:t.getImage()?.length??0}))};
 console.log(JSON.stringify(row));
}
