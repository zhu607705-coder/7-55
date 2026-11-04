import fs from 'node:fs';
import assert from 'node:assert/strict';
import * as THREE from '../web/vendor/three/three.module.js';
import {parse} from './parse_glb_geometry.mjs';
import {loadPhotoSceneAssets} from '../web/photo_scene_assets.js';
import {photoComposition,installPhotoCollision} from '../web/photo_static_placement.js';
import {roomFurnitureNodes} from '../web/photo_room_replacement.js';
import {canStand,moveBody} from '../web/collision.js';
const web=new URL('../web/',import.meta.url),json=async u=>JSON.parse(fs.readFileSync(new URL(u,web)));
const codec={loader:{async loadAsync(u){if(u.endsWith('.draco.glb'))throw Error('fallback');return parse(new URL(u,web));}}};
const library=await loadPhotoSceneAssets(codec,{fetchJSON:json});assert.deepEqual(library.errors,[]);
const binding=[...library.bindings.values()].find(b=>b.replaceRoomFurniture);assert.ok(binding);
assert.equal(binding.parts.length,23,'21 earlier parts plus third equal chair and cushion');
assert.equal(binding.parts.filter(p=>p.asset==='lounge_single_corrected').length,3);
assert.equal(binding.parts.filter(p=>p.asset==='lounge_double_corrected').length,0);
assert.equal(binding.parts.filter(p=>p.asset==='lounge_loose_cushion').length,1);
// Actual decoded seat triangle contact, not just a proxy/manifest height.
for(let lod=0;lod<3;lod++){
 const seat=parse(new URL('assets/models/photo_lounge_corrected/lounge_single_corrected/lod'+lod+'.glb',web)).scene;
 const hit=new THREE.Raycaster(new THREE.Vector3(0,.55,.125),new THREE.Vector3(0,-1,0)).intersectObject(seat,true)[0];
 const pillow=binding.parts.find(p=>p.asset==='lounge_loose_cushion');
 assert.ok(hit&&Math.abs(hit.point.y-pillow.position[1])<.0005,'cushion supported within 0.5 mm at LOD '+lod);
 const single=binding.parts.find(p=>p.asset==='lounge_single_corrected');
 const support=new THREE.Vector3(0,pillow.position[1],.125).applyMatrix4(new THREE.Matrix4().makeTranslation(...single.position).multiply(new THREE.Matrix4().makeRotationY(single.yaw)));
 assert.ok(support.distanceTo(new THREE.Vector3(...pillow.position))<1e-6,'pillow position follows the actual retained single seat');
}
const reports=[];
for(const building of ['building.glb','building.web.glb']){
 const source=parse(new URL('assets/'+building,web)).scene,layout=await json('assets/layout.json');
 let floor;source.traverse(n=>{if(String(n.userData.floorRoot)==='3')floor=n;});assert.ok(floor);
 const removed=roomFurnitureNodes(floor,layout,binding);assert.ok(removed.size>100,'non-vacuous furniture removal');
 const anchor=source.getObjectByName(binding.sourceNodeName);assert.ok(removed.has(anchor),'anchor chair removed');
 const vendingNodes=[];floor.traverse(n=>{if(n.isMesh&&(n.userData.name||n.name).startsWith('Vending '))vendingNodes.push(n);});
 assert.ok(vendingNodes.length>=29,'actual original vending machine and all existing details found');
 for(const n of vendingNodes)assert.ok(!removed.has(n),'vending geometry retained '+n.name);
 const originalVending=structuredClone(layout.floors['3'].colliders.find(c=>c.id==='Vending machine'));assert.ok(originalVending);
 const vendingBounds=new THREE.Box3(),inverse=floor.matrixWorld.clone().invert();
 for(const n of vendingNodes){n.geometry.computeBoundingBox();vendingBounds.union(n.geometry.boundingBox.clone().applyMatrix4(inverse.clone().multiply(n.matrixWorld)));}
 const composition=photoComposition(library,binding),matrix=new THREE.Matrix4().makeTranslation(...binding.floorAnchor);
 const room=layout.floors['3'].rooms.find(r=>r.id==='pantry'),[x0,z0,x1,z1]=room.bounds;
 const equalSeats=binding.parts.map((p,i)=>({p,i})).filter(({p})=>p.asset==='lounge_single_corrected');
 for(const {p,i} of equalSeats){assert.equal(p.scale,undefined,'chair has no non-rigid scale');assert.ok(composition.partBounds[i].getSize(new THREE.Vector3()).distanceTo(composition.partBounds[equalSeats[0].i].getSize(new THREE.Vector3()))<1e-6,'three chairs have identical physical bounds');}
 for(const level of composition.levels)for(const part of level.filter(p=>p.asset==='lounge_single_corrected')){const position=new THREE.Vector3(),rotation=new THREE.Quaternion(),scale=new THREE.Vector3();part.transform.decompose(position,rotation,scale);assert.ok(scale.distanceTo(new THREE.Vector3(1,1,1))<1e-8,'every chair part and LOD uses only a rigid instance transform');}
 const boxes=composition.partBounds.map(b=>b.clone().applyMatrix4(matrix));
 for(let i=0;i<boxes.length;i++){const b=boxes[i];assert.ok(b.min.x>x0+.05&&b.max.x<x1-.05&&b.min.z>z0+.05&&b.max.z<z1-.05,'inside room '+binding.parts[i].asset);}
 for(let a=0;a<binding.collision.partIndices.length;a++)for(let b=a+1;b<binding.collision.partIndices.length;b++){
  const i=binding.collision.partIndices[a],j=binding.collision.partIndices[b];
  if([i,j].every(k=>['photo_side_by_side_fridge','photo_fridge_wood_surround'].includes(binding.parts[k].asset)))continue;
  const overlap=boxes[i].clone().intersect(boxes[j]);assert.ok(overlap.isEmpty()||Math.min(...overlap.getSize(new THREE.Vector3()).toArray())<.0001,'separate furniture bodies '+i+'/'+j);
 }
 for(const i of binding.collision.partIndices){
  assert.ok(!boxes[i].intersectsBox(vendingBounds),'new body does not intersect actual vending geometry '+i);
  const r=originalVending.rect,b=boxes[i];assert.ok(b.max.x<=r[0]||b.min.x>=r[2]||b.max.z<=r[1]||b.min.z>=r[3],'new body does not overlap original vending collider '+i);
 }
 const microwaveIndex=binding.parts.findIndex(p=>p.asset==='photo_pantry_grey_roundfront_appliance'),fridgeIndex=binding.parts.findIndex(p=>p.asset==='photo_side_by_side_fridge');
 const microwave=binding.parts[microwaveIndex],fridge=binding.parts[fridgeIndex];
 assert.equal(microwave.yaw,Math.PI,'microwave faces service aisle');assert.equal(fridge.yaw,microwave.yaw,'fridge and microwave face the same aisle');
 assert.ok(fridge.position[0]>microwave.position[0],'fridge immediately on microwave side of counter');
 for(const p of binding.parts.filter(p=>['photo_pantry_sink_faucets','photo_pantry_white_cleartop_appliance'].includes(p.asset)))assert.ok(p.position[0]<microwave.position[0],'no other counter appliance between microwave and fridge');
 const applianceGap=boxes[fridgeIndex].min.x-boxes[microwaveIndex].max.x;
 assert.ok(applianceGap>.0&&applianceGap<.85,'adjacent assemblies with only verified wood-side/recess transition');
 const walls=JSON.stringify(layout.floors['3'].colliders.filter(c=>c.kind!=='furniture'));
 installPhotoCollision(layout,binding,composition,matrix);
 assert.deepEqual(layout.floors['3'].colliders.find(c=>c.id==='Vending machine'),originalVending,'original vending collider unchanged');
 assert.equal(JSON.stringify(layout.floors['3'].colliders.filter(c=>c.kind!=='furniture')),walls,'walls and door stay unchanged');
 let pos=room.spawn;const route=[[11.35,37.15],[11.35,41],[14.67,41],[16.134,41],[15.2,41],[15.2,36.9],[11.35,36.9],[11.35,37.15],[11.35,37.55],[10.85,37.55],[11.35,37.55],[11.35,39.45],[10.85,39.45],[11.35,39.45],[11.35,40.57626],[10.85,40.57626],[11.35,40.57626],[11.35,41.65],[10.85,41.65]];
 for(const goal of route){pos=moveBody(layout,'3',pos,goal[0]-pos[0],goal[1]-pos[1]);assert.ok(Math.hypot(pos[0]-goal[0],pos[1]-goal[1])<.001,'continuous clear loop '+JSON.stringify({goal,pos}));}
 for(const i of binding.collision.partIndices){const c=boxes[i].getCenter(new THREE.Vector3());assert.equal(canStand(layout,'3',c.x,c.z),false,'solid body '+i);}
 reports.push({building,removedNodes:removed.size,retainedVendingMeshes:vendingNodes.length,vendingBounds:{min:vendingBounds.min.toArray(),max:vendingBounds.max.toArray()},parts:boxes.length,route,fridgeMicrowaveGapM:applianceGap,boxes:boxes.map(b=>({min:b.min.toArray(),max:b.max.toArray()}))});
}
const broken=await loadPhotoSceneAssets({loader:{async loadAsync(u){if(u.includes('photo_pantry_counter'))throw Error('missing pantry');return codec.loader.loadAsync(u);}}},{fetchJSON:json});assert.ok(![...broken.bindings.values()].some(b=>b.replaceRoomFurniture));assert.ok([...broken.bindings.values()].some(b=>b.id==='xlab/workshop-candidate'));
fs.writeFileSync(new URL('../review/lounge-room-node.json',import.meta.url),JSON.stringify({passed:true,reports},null,2));console.log('PASS: two building files, atomic room replacement, preserved walls, ground footprints and continuous circulation.');
