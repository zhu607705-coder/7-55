// Remove repeated chair geometry from the web assembly, retaining every anchor.
// Full building.glb stays intact as the offline source and failure fallback.
import fs from 'node:fs/promises';
import crypto from 'node:crypto';
import {NodeIO,getBounds} from '@gltf-transform/core';
import {ALL_EXTENSIONS} from '@gltf-transform/extensions';
import {prune} from '@gltf-transform/functions';
const io=new NodeIO().registerExtensions(ALL_EXTENSIONS),input='web/assets/building.glb',output='web/assets/building.web.glb';
const data=await fs.readFile(input),doc=await io.readBinary(data);
const layout=JSON.parse(await fs.readFile('web/assets/layout.json','utf8'));
const floor3=doc.getRoot().listNodes().find(n=>n.getExtras().floorRoot===3);
const north=layout.floors['3'].rooms.find(r=>r.id==='seminar'),pantry=layout.floors['3'].rooms.find(r=>r.id==='pantry');
const [x0,z0,x1,z1]=north.bounds,cx=(x0+x1)/2;
const tableNames=/^(Mobile exhibition tabletop|Display steel upright|Display wheeled foot|Large display caster|Display lower stretcher|Exhibition caster)/;
const slotDefinitions=[
 {id:'display_table_125',asset:'mobile_exhibition_table',origin:[x0+1.8,0,z0+2.7],target:[1.25,.60,1],test:n=>tableNames.test(n)},
 {id:'display_table_135',asset:'mobile_exhibition_table',origin:[cx-.40,0,z0+1.65],target:[1.35,.60,1],test:n=>tableNames.test(n)},
 {id:'display_table_120',asset:'mobile_exhibition_table',origin:[cx+1.05,0,z0+1.75],target:[1.20,.60,1],test:n=>tableNames.test(n)},
 {id:'display_table_150',asset:'mobile_exhibition_table',origin:[x1-1.45,0,z0+2.35],target:[1.50,.65,1],test:n=>tableNames.test(n)},
 {id:'silver_exhibit',asset:'silver_covered_exhibit',origin:[cx-.40,1.03,z0+1.65],target:[.88,.54,.54],test:n=>n.startsWith('Photographed silver covered form')},
 {id:'pantry_sofa',asset:'rest_sofa',origin:[(pantry.bounds[0]+pantry.bounds[2])/2-.40,0,pantry.bounds[3]-1.9],target:[1.8,.85,.95],test:n=>/^Sofa (lower|back|arm|cushion)/.test(n)}
];
const staticSlots=[];
for(const slot of slotDefinitions){
 const selected=floor3.listChildren().filter(n=>{
  if(!n.getMesh()||!slot.test(n.getName()))return false;
  const b=getBounds(n),x=(b.min[0]+b.max[0])/2,z=(b.min[2]+b.max[2])/2;
  return Math.abs(x-slot.origin[0])<=slot.target[0]/2+.02&&Math.abs(z-slot.origin[2])<=slot.target[1]/2+.08;
 });
 if(!selected.length)throw Error('No authored fallback geometry for '+slot.id);
 const before=selected.map(n=>getBounds(n));
 const anchor=doc.createNode('Static asset '+slot.id).setTranslation(slot.origin).setExtras({
  staticAssetSlot:slot.id,generatedAsset:slot.asset,targetWidthDepthHeightM:slot.target,kind:'furniture',floor:3
 });floor3.addChild(anchor);
 selected.forEach(n=>{const m=[...n.getMatrix()];m[12]-=slot.origin[0];m[13]-=slot.origin[1];m[14]-=slot.origin[2];floor3.removeChild(n);anchor.addChild(n);n.setMatrix(m);});
 const error=Math.max(...selected.flatMap((n,i)=>{const b=getBounds(n);return [...b.min.map((v,j)=>Math.abs(v-before[i].min[j])),...b.max.map((v,j)=>Math.abs(v-before[i].max[j]))];}));
 if(error>.00001)throw Error('Fallback geometry moved for '+slot.id);
 staticSlots.push({id:slot.id,asset:slot.asset,origin:slot.origin,target:slot.target,fallbackParts:selected.length,worldBoundsErrorM:error});
}
const chairs=doc.getRoot().listNodes().filter(n=>n.getExtras().assetId==='office_chair');
const anchors=chairs.map(n=>({name:n.getName(),extras:n.getExtras(),matrix:n.getWorldMatrix()}));
function remove(node){for(const child of node.listChildren())remove(child);node.dispose();}
for(const chair of chairs){for(const child of chair.listChildren())remove(child);chair.setMesh(null);}
await doc.transform(prune({keepExtras:true,keepLeaves:true,keepAttributes:true}));
const result=await io.writeBinary(doc);await fs.writeFile(output,result);
const read=await io.readBinary(result),retained=read.getRoot().listNodes().filter(n=>n.getExtras().assetId==='office_chair').map(n=>({name:n.getName(),extras:n.getExtras(),matrix:n.getWorldMatrix()}));
if(JSON.stringify(anchors)!==JSON.stringify(retained))throw Error('Chair placements or metadata changed');
const sha=b=>crypto.createHash('sha256').update(b).digest('hex');
const report={source:{file:input,bytes:data.length,sha256:sha(data)},output:{file:output,bytes:result.length,sha256:sha(result)},chairAnchors:chairs.length,staticSlots,anchorContract:'Chair matrices/names/extras and static fallback world bounds retained. Layout and collision proxies remain separate.'};
await fs.writeFile('review/building_split_validation.json',JSON.stringify(report,null,2)+'\n');console.log(JSON.stringify(report));
