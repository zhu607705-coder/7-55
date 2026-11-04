/** Replace only furniture wholly owned by the existing room, never its walls.
 * Called only for fully loaded atomic photo bindings. No source GLB is mutated. */
import * as THREE from './vendor/three/three.module.js';
export function roomFurnitureNodes(original,layout,binding){
 const room=layout.floors[binding.floor]?.rooms.find(r=>r.id===binding.replaceRoomFurniture);
 if(!room)throw Error('Unknown photo replacement room '+binding.replaceRoomFurniture);
 const [x0,z0,x1,z1]=room.bounds,inverse=original.matrixWorld.clone().invert(),removed=new Set();
 original.traverse(mesh=>{
  if(!mesh.isMesh)return;
  let owner=mesh;while(owner&&owner!==original){if((binding.preserveSourcePrefixes||[]).some(prefix=>(owner.userData.name||owner.name||'').startsWith(prefix)))return;owner=owner.parent;}
  let p=mesh,kind;
  while(p&&p!==original){kind??=p.userData.kind;p=p.parent;}
  if(kind!=='furniture')return;
  mesh.geometry.computeBoundingBox();
  const box=mesh.geometry.boundingBox.clone().applyMatrix4(inverse.clone().multiply(mesh.matrixWorld));
  if(box.min.x>=x0&&box.max.x<=x1&&box.min.z>=z0&&box.max.z<=z1)removed.add(mesh);
 });
 // Also suppress the old inspectable/chair/static parents so replacement assets
 // cannot be instantiated a second time by the normal optimization pass.
 original.traverse(node=>{
  if(node.isMesh||node===original)return;
  let count=0,all=true;node.traverse(child=>{if(child.isMesh){count++;if(!removed.has(child))all=false;}});
  if(count&&all)removed.add(node);
  if(!count&&(node.userData.assetId||node.userData.staticAssetSlot)){const p=new THREE.Vector3().setFromMatrixPosition(inverse.clone().multiply(node.matrixWorld));if(p.x>x0&&p.x<x1&&p.z>z0&&p.z<z1)removed.add(node);}
 });
 return removed;
}
export function removeRoomFurnitureCollision(layout,binding){
 const floor=layout.floors[binding.floor],room=floor.rooms.find(r=>r.id===binding.collision.replaceRoom);
 if(!room)throw Error('Unknown photo collision room');
 const [x0,z0,x1,z1]=room.bounds;
 floor.colliders=floor.colliders.filter(c=>!(c.kind==='furniture'&&!(binding.collision.preserveIds||[]).includes(c.id)&&c.rect&&c.rect[0]>=x0&&c.rect[1]>=z0&&c.rect[2]<=x1&&c.rect[3]<=z1));
}
