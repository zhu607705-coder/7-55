/** Metric, default-on photo compositions. Source meshes remain shared across LOD instances. */
import * as THREE from './vendor/three/three.module.js';
export function photoComposition(library,binding){
 const bounds=new THREE.Box3(),partBounds=[];
 const levels=[0,1,2].map(()=>[]);
 binding.parts.forEach((placement,index)=>{
  const asset=library.assets.get(placement.asset);
  const transform=new THREE.Matrix4().makeTranslation(...placement.position.map((v,i)=>v-(binding.floorSpace?binding.floorAnchor[i]:0))).multiply(new THREE.Matrix4().makeRotationY(placement.yaw||0));
  const box=new THREE.Box3();
  asset.levels.forEach((parts,level)=>parts.forEach(part=>{
   part.geometry.computeBoundingBox();box.union(part.geometry.boundingBox.clone().applyMatrix4(transform));
   levels[level].push({...part,transform,asset:placement.asset});
  }));
  partBounds[index]=box;bounds.union(box);
 });
 return {id:binding.id,name:binding.label,levels,partBounds,bounds,manifest:{levels:levels.map((parts,i)=>({size:bounds.getSize(new THREE.Vector3()).toArray(),triangles:parts.reduce((n,p)=>n+(p.geometry.index?.count||p.geometry.attributes.position.count)/3,0),materials:[],level:i}))}};
}
/** Apply only after the complete binding loads. Failed assets retain original collision. */
export function installPhotoCollision(layout,binding,composition,anchorMatrix){
 if(!binding.collision)return;
 const floor=layout.floors[binding.floor],c=binding.collision;
 if(c.replaceCenter){
  const [x,z]=c.replaceCenter;
  const index=floor.colliders.findIndex(v=>v.rect&&Math.abs((v.rect[0]+v.rect[2])/2-x)<.001&&Math.abs((v.rect[1]+v.rect[3])/2-z)<.001);
  if(index<0)throw Error('Missing original chair collider '+binding.id);
  floor.colliders.splice(index,1);
 }
 for(const index of c.partIndices||[0]){
  const b=composition.partBounds[index].clone().applyMatrix4(anchorMatrix);
  floor.colliders.push({id:binding.id+'/'+index,kind:'furniture',photoBinding:binding.id,rect:[b.min.x,b.min.z,b.max.x,b.max.z]});
 }
}
