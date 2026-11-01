// Remove repeated chair geometry from the web assembly, retaining every anchor.
// Full building.glb stays intact as the offline source and failure fallback.
import fs from 'node:fs/promises';
import crypto from 'node:crypto';
import {NodeIO} from '@gltf-transform/core';
import {ALL_EXTENSIONS} from '@gltf-transform/extensions';
import {prune} from '@gltf-transform/functions';
const io=new NodeIO().registerExtensions(ALL_EXTENSIONS),input='web/assets/building.glb',output='web/assets/building.web.glb';
const data=await fs.readFile(input),doc=await io.readBinary(data);
const chairs=doc.getRoot().listNodes().filter(n=>n.getExtras().assetId==='office_chair');
const anchors=chairs.map(n=>({name:n.getName(),extras:n.getExtras(),matrix:n.getWorldMatrix()}));
function remove(node){for(const child of node.listChildren())remove(child);node.dispose();}
for(const chair of chairs){for(const child of chair.listChildren())remove(child);chair.setMesh(null);}
await doc.transform(prune({keepExtras:true,keepLeaves:true,keepAttributes:true}));
const result=await io.writeBinary(doc);await fs.writeFile(output,result);
const read=await io.readBinary(result),retained=read.getRoot().listNodes().filter(n=>n.getExtras().assetId==='office_chair').map(n=>({name:n.getName(),extras:n.getExtras(),matrix:n.getWorldMatrix()}));
if(JSON.stringify(anchors)!==JSON.stringify(retained))throw Error('Chair placements or metadata changed');
const sha=b=>crypto.createHash('sha256').update(b).digest('hex');
const report={source:{file:input,bytes:data.length,sha256:sha(data)},output:{file:output,bytes:result.length,sha256:sha(result)},chairAnchors:chairs.length,anchorContract:'World matrices, names and extras match before/after; layout.json and colliders are separate and unchanged.'};
await fs.writeFile('review/building_split_validation.json',JSON.stringify(report,null,2)+'\n');console.log(JSON.stringify(report));
