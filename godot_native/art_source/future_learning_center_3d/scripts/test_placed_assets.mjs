import './test_lounge_room.mjs';
import fs from 'node:fs';
import assert from 'node:assert/strict';
import * as THREE from '../web/vendor/three/three.module.js';
import {parse} from './parse_glb_geometry.mjs';
import {loadPhotoSceneAssets} from '../web/photo_scene_assets.js';
import {photoComposition,installPhotoCollision} from '../web/photo_static_placement.js';
import {canStand,moveBody} from '../web/collision.js';
const web=new URL('../web/',import.meta.url),config=JSON.parse(fs.readFileSync(new URL('assets/photo_scene_config.json',web)));
const json=async u=>JSON.parse(fs.readFileSync(new URL(u,web)));
const codec={loader:{async loadAsync(u){if(u.endsWith('.draco.glb'))throw Error('forced fallback');return parse(new URL(u,web));}}};
const library=await loadPhotoSceneAssets(codec,{fetchJSON:json});assert.deepEqual(library.errors,[]);
const added=config.bindings.filter(b=>b.id==='xlab/workshop-candidate'),reports=[];
assert.equal(added.length,1);assert.deepEqual(added.map(b=>b.parts.length),[8]);
for(const building of ['building.glb','building.web.glb']){
 const source=parse(new URL('assets/'+building,web)).scene,layout=await json('assets/layout.json');
 let floor;source.traverse(n=>{if(n.userData.floorRoot===3||n.userData.floorRoot==='3')floor=n;});assert.ok(floor);
 const inverse=floor.matrixWorld.clone().invert(),boxes=[];
 for(const binding of added){
  const node=source.getObjectByName(binding.sourceNodeName);assert.ok(node,'actual source anchor '+binding.sourceNodeName);
  const matrix=binding.floorSpace?new THREE.Matrix4().makeTranslation(...binding.floorAnchor):inverse.clone().multiply(node.matrixWorld);
  const composition=photoComposition(library,binding);installPhotoCollision(layout,binding,composition,matrix);
  const room=layout.floors['3'].rooms.find(r=>r.id===(binding.floorSpace?'xlab':'pantry'));
  binding.parts.forEach((p,index)=>{
   const local=composition.partBounds[index],world=local.clone().applyMatrix4(matrix);
   assert.ok(world.min.x>room.bounds[0]+.05&&world.max.x<room.bounds[2]-.05&&world.min.z>room.bounds[1]+.05&&world.max.z<room.bounds[3]-.05,'inside room and clear of wall '+p.asset);
   if(index===0||binding.floorSpace&&index===1)assert.ok(Math.abs(world.min.y)<.00001,'footpoint on floor '+p.asset);
   boxes.push({binding:binding.id,index,asset:p.asset,box:world});
   for(let level=0;level<3;level++){
    const a=library.assets.get(p.asset),transform=matrix.clone().multiply(new THREE.Matrix4().makeTranslation(...p.position.map((v,k)=>v-(binding.floorSpace?binding.floorAnchor[k]:0)))).multiply(new THREE.Matrix4().makeRotationY(p.yaw||0));
    const bounds=new THREE.Box3();for(const part of a.levels[level])bounds.union(part.geometry.boundingBox.clone().applyMatrix4(transform));
    assert.ok(bounds.min.y>=-.00001,'all LODs nonnegative height');
   }
  });
 }
 // Test exact decoded mat surfaces rather than the cart's highest handles/rims.
 const cart=library.assets.get('photo_workshop_green_tool_cart');
 const workshop=added[0],cartBoxes=boxes.filter(b=>b.binding===workshop.id&&b.index<2);
 for(let level=0;level<3;level++){
  const mat=cart.levels[level].find(p=>p.sourcePart==='Rubber top work mat');assert.ok(mat,'real support mesh');
  for(let cartIndex=0;cartIndex<2;cartIndex++){
   const p=workshop.parts[cartIndex],matrix=new THREE.Matrix4().makeTranslation(...p.position).multiply(new THREE.Matrix4().makeRotationY(p.yaw));
   const top=mat.geometry.boundingBox.clone().applyMatrix4(matrix);
   const tools=boxes.filter(b=>b.binding===workshop.id&&(cartIndex===0?[2,3,4]:[5,6,7]).includes(b.index));
   for(const tool of tools){const b=tool.box;assert.ok(Math.abs(b.min.y-top.max.y)<.00001,'tool actually rests on mat '+tool.asset);assert.ok(b.min.x>=top.min.x-.00001&&b.max.x<=top.max.x+.00001&&b.min.z>=top.min.z-.00001&&b.max.z<=top.max.z+.00001,'full footprint supported '+tool.asset);}
   for(let i=0;i<tools.length;i++)for(let j=i+1;j<tools.length;j++)assert.ok(!tools[i].box.intersectsBox(tools[j].box),'tool bodies do not intersect '+tools[i].asset+'/'+tools[j].asset);
  }
 }
 // Retained scene furniture must not intersect any added cart or replacement seat.
 const bodies=boxes.filter(b=>b.asset==='lounge_single_corrected'||b.asset==='photo_workshop_green_tool_cart');
 let furnitureComparisons=0;
 for(const body of bodies){source.traverse(mesh=>{
  if(!mesh.isMesh||mesh.userData.floor!==3||mesh.userData.kind!=='furniture')return;
  let p=mesh,skip=false;while(p){if(added.some(b=>!b.retainOriginal&&b.sourceNodeName===p.name))skip=true;p=p.parent;}if(skip)return;
  furnitureComparisons++;mesh.geometry.computeBoundingBox();const b=mesh.geometry.boundingBox.clone().applyMatrix4(inverse.clone().multiply(mesh.matrixWorld));
  const overlap=body.box.clone().intersect(b);if(!overlap.isEmpty()){const size=overlap.getSize(new THREE.Vector3());assert.ok(Math.min(size.x,size.y,size.z)<.0001,'no original furniture overlap '+body.asset+'/'+mesh.name);}
 });}
 assert.ok(furnitureComparisons>100,'non-vacuous comparisons against actual original furniture');
 // Continuous ordinary collision stepping: entry then full west-side length of X-Lab.
 let pos=[19.508381502890174,20.31513043478261];assert.ok(canStand(layout,'3',...pos));
 for(const goal of [[19.508381502890174,14],[19.508381502890174,41],[24.1,41],[24.1,14]]){
  pos=moveBody(layout,'3',pos,goal[0]-pos[0],goal[1]-pos[1]);assert.ok(Math.hypot(pos[0]-goal[0],pos[1]-goal[1])<.0001,'continuous aisle route reaches '+goal);
 }
 for(const body of bodies){const c=body.box.getCenter(new THREE.Vector3());assert.equal(canStand(layout,'3',c.x,c.z),false,'solid body blocks walking');}
 const originals=JSON.parse(fs.readFileSync(new URL('assets/layout.json',web)));assert.deepEqual(layout.floors['2'],originals.floors['2']);assert.deepEqual(layout.floors['4'],originals.floors['4']);
 reports.push({building,parts:boxes.map(({box,...b})=>({...b,min:box.min.toArray(),max:box.max.toArray()})),furnitureComparisons,route:'west entrance to north/south; east aisle x=24.1 across full room'});
}
// Asset loss makes the entire composition unavailable, so runtime never replaces collision or source.
const broken=await loadPhotoSceneAssets({loader:{async loadAsync(u){if(u.includes('photo_workshop_small_vise'))throw Error('missing vise');return codec.loader.loadAsync(u);}}},{fetchJSON:json});assert.ok(![...broken.bindings.values()].some(b=>b.id==='xlab/workshop-candidate'));assert.ok([...broken.bindings.values()].some(b=>b.id==='rest/photo-room-composition'));
fs.writeFileSync(new URL('../review/placed-assets-node.json',import.meta.url),JSON.stringify({passed:true,reports,scope:'Actual uncompressed GLB geometry, support, full-aisle collision stepping and atomic fallback. Not browser visual acceptance.'},null,2));
console.log('Passed: both building sources, 8 workshop parts, all LODs, ground/mat contact, room/wall/furniture clearance, continuous navigation and partial failure.');
