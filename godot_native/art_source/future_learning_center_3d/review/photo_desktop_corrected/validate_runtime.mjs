/** Independent decode/geometry check. Run from art root after runtime build. */
import fs from 'node:fs/promises';
import {createRequire} from 'node:module';
const require=createRequire(new URL('../../pipeline/package.json',import.meta.url));
const {NodeIO,getBounds}=require('@gltf-transform/core');
const {ALL_EXTENSIONS}=require('@gltf-transform/extensions');
const draco3d=require('draco3dgltf');
const io=new NodeIO().registerExtensions(ALL_EXTENSIONS).registerDependencies({'draco3d.decoder':await draco3d.createDecoderModule()});
const ids=['photo_mouse'];
const assert=(v,msg)=>{if(!v)throw Error(msg)};
function inspect(doc){
 const points=[];let triangles=0,normalCount=0,degenerate=0,minArea=Infinity,invalidNormals=0;
 for(const node of doc.getRoot().listNodes()){
  if(!node.getMesh())continue;const m=node.getWorldMatrix();
  for(const prim of node.getMesh().listPrimitives()){
   const pos=prim.getAttribute('POSITION'),normal=prim.getAttribute('NORMAL');assert(normal,'Missing normals');assert(normal.getCount()===pos.getCount(),'Attribute count mismatch');const pp=[];
   for(let i=0;i<pos.getCount();i++){
    const v=pos.getElement(i,[]),n=normal.getElement(i,[]);assert([...v,...n].every(Number.isFinite),'Non-finite decoded attribute');
    const p=[m[0]*v[0]+m[4]*v[1]+m[8]*v[2]+m[12],m[1]*v[0]+m[5]*v[1]+m[9]*v[2]+m[13],m[2]*v[0]+m[6]*v[1]+m[10]*v[2]+m[14]];
    const nn=[m[0]*n[0]+m[4]*n[1]+m[8]*n[2],m[1]*n[0]+m[5]*n[1]+m[9]*n[2],m[2]*n[0]+m[6]*n[1]+m[10]*n[2]];const len=Math.hypot(...nn);if(Math.abs(len-1)>.005)invalidNormals++;
    points.push({p,n:nn.map(x=>x/len)});pp.push(p);normalCount++;
   }
   const inds=prim.getIndices()?.getArray()??Array.from({length:pp.length},(_,i)=>i);assert(inds.length%3===0,'Nontriangular primitive');triangles+=inds.length/3;
   for(let i=0;i<inds.length;i+=3){const a=pp[inds[i]],b=pp[inds[i+1]],c=pp[inds[i+2]],u=b.map((x,j)=>x-a[j]),v=c.map((x,j)=>x-a[j]);const area=Math.hypot(u[1]*v[2]-u[2]*v[1],u[2]*v[0]-u[0]*v[2],u[0]*v[1]-u[1]*v[0])/2;minArea=Math.min(minArea,area);if(area<1e-13)degenerate++;}
  }
 }
 return {points,triangles,normalCount,degenerate,minArea,invalidNormals,bounds:getBounds(doc.getRoot().listScenes()[0])};
}
function compare(a,b,normalCheck){
 const cell=.0001,grid=new Map(),key=p=>p.map(x=>Math.floor(x/cell));
 for(const item of b){const k=key(item.p).join(',');if(!grid.has(k))grid.set(k,[]);grid.get(k).push(item)}
 let maxPositionError=0,maxNormalAngle=0;
 for(const item of a){const k=key(item.p);let nearest=Infinity,bestDot=-1;
  for(let dx=-1;dx<=1;dx++)for(let dy=-1;dy<=1;dy++)for(let dz=-1;dz<=1;dz++)for(const q of grid.get([k[0]+dx,k[1]+dy,k[2]+dz].join(','))??[]){const d=Math.hypot(...q.p.map((x,i)=>x-item.p[i]));nearest=Math.min(nearest,d);if(d<.00001)bestDot=Math.max(bestDot,q.n.reduce((s,x,i)=>s+x*item.n[i],0));}
  maxPositionError=Math.max(maxPositionError,nearest);if(normalCheck)maxNormalAngle=Math.max(maxNormalAngle,Math.acos(Math.max(-1,Math.min(1,bestDot))));
 }
 assert(maxPositionError<.00001,'Position mismatch '+maxPositionError);if(normalCheck)assert(maxNormalAngle<.015,'Normal mismatch '+maxNormalAngle);return {maxPositionErrorM:maxPositionError,maxNormalAngleRadians:normalCheck?maxNormalAngle:null};
}
const results=[];
for(const id of ids){
 const out=`web/assets/models/photo_desktop_corrected/${id}`;const manifest=JSON.parse(await fs.readFile(`${out}/manifest.json`));assert(Math.abs(manifest.calibration.uniformScale-1)<1e-6,'Unexpected scale');
 for(const level of [0,1,2]){
  const source=inspect(await io.read(`sources/models/photo_desktop_corrected/${id}/lod${level}_source.glb`));const plain=inspect(await io.read(`${out}/lod${level}.glb`));const decoded=inspect(await io.read(`${out}/lod${level}.draco.glb`));
  for(const q of [source,plain,decoded]){assert(q.degenerate===0,'Degenerate triangles');assert(q.invalidNormals===0,'Invalid normals');}
  assert(plain.triangles===decoded.triangles,'Decode triangle mismatch');// Draco may merge vertices whose quantized attributes become identical. Compare both directions below.
  const b=manifest.source.bounds,cx=(b.min[0]+b.max[0])/2,cz=(b.min[2]+b.max[2])/2;
  const calibrated=source.points.map(({p,n})=>({p:[p[0]-cx,p[1]-b.min[1],p[2]-cz],n:[n[0],n[1],n[2]]}));
  const s=compare(plain.points,calibrated,false),d=compare(decoded.points,plain.points,true),reverse=compare(plain.points,decoded.points,true);
  const boundsError=Math.max(...decoded.bounds.min.map((x,i)=>Math.abs(x-plain.bounds.min[i])),...decoded.bounds.max.map((x,i)=>Math.abs(x-plain.bounds.max[i])));assert(boundsError<.00001,'Bounds mismatch');
  results.push({id,level,sourceTriangles:source.triangles,runtimeTriangles:plain.triangles,decodedTriangles:decoded.triangles,sourceNormals:source.normalCount,plainNormals:plain.normalCount,decodedNormals:decoded.normalCount,degenerateTriangles:decoded.degenerate,invalidNormals:decoded.invalidNormals,minDecodedTriangleArea:decoded.minArea,boundsErrorM:boundsError,sourceToRuntime:s,dracoToPlain:d,plainToDraco:reverse});
 }
}
await fs.writeFile('review/photo_desktop_corrected/source_vs_draco.json',JSON.stringify({independentDecoder:'draco3dgltf 1.5.9, separate NodeIO reader',allPassed:true,checks:'Actual decoded triangles, attributes, unit normal lengths, nearest positions and normals, world bounds. Source-to-runtime includes documented yaw=0 and grounded center shift.',results},null,2));console.log(JSON.stringify(results,null,2));
