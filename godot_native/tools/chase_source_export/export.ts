import path from 'node:path';
import {repositoryRoot,outputDirectory} from './paths';
import './node_adapter';
import {fakeCanvas} from './node_adapter';
import {readFile,writeFile,mkdir} from 'node:fs/promises';
import * as THREE from 'three';
import {GLTFLoader} from 'three/examples/jsm/loaders/GLTFLoader.js';
import {GLTFExporter} from 'three/examples/jsm/exporters/GLTFExporter.js';
import {installChaseHumanTemplate} from '../../../src/scenes/rpg/canteen-chase/ChaseHumanAsset';
import {ChaseThreeRenderer,mergeStaticWorldMeshes} from '../../../src/scenes/rpg/canteen-chase/ChaseThreeRenderer';
import {applyChaseRiderPose,measureChaseRiderContactError,CHASE_RIDER_DISPLAY_SCALE,CHASE_RIDER_GEAR_RATIO,CHASE_RIDER_WHEEL_RADIUS} from '../../../src/scenes/rpg/canteen-chase/ChaseRiderRig';
import {visibleStuntObstacles,STUNT_RAMPS,STUNT_PICKUPS} from '../../../src/scenes/rpg/canteen-chase/ChaseStuntModel';
import {pedestrianAt} from '../../../src/scenes/rpg/canteen-chase/ChaseGeometry';
import {CHASE_WORLD_PER_METER,CHASE_ROUTE_STAGES} from '../../../src/scenes/rpg/canteen-chase/ChaseRoute';
const OUT=outputDirectory+path.sep; await mkdir(OUT,{recursive:true});
const save=async(name:string,value:any)=>writeFile(OUT+name,typeof value==='string'?value:Buffer.from(value));
(globalThis as any).ResizeObserver=class{observe(){}disconnect(){}};
let clock=1000;Object.defineProperty(globalThis,'performance',{value:{now:()=>clock},configurable:true});
const bytes=await readFile(path.join(repositoryRoot,'src/assets/rpg/canteen-characters/quaternius_casual.glb'));
const human=await new GLTFLoader().parseAsync(bytes.buffer.slice(bytes.byteOffset,bytes.byteOffset+bytes.byteLength),'');installChaseHumanTemplate(human);
const renderer:any=new ChaseThreeRenderer(fakeCanvas() as any);
const metadata:any={kind:'offline original Three geometry/pose extraction; no source WebGL pixels',world_per_meter:CHASE_WORLD_PER_METER,stages:CHASE_ROUTE_STAGES,rider_display_scale:CHASE_RIDER_DISPLAY_SCALE,wheel_radius:CHASE_RIDER_WHEEL_RADIUS,gear_ratio:CHASE_RIDER_GEAR_RATIO,rear_contact_m:.72*CHASE_RIDER_DISPLAY_SCALE/CHASE_WORLD_PER_METER,front_contact_m:-.72*CHASE_RIDER_DISPLAY_SCALE/CHASE_WORLD_PER_METER,assets:{},camera_samples:[],ramps:STUNT_RAMPS,pickups:STUNT_PICKUPS,pedestrians:[]};
const exporter=new GLTFExporter();
function nodeList(root:THREE.Object3D){const nodes:THREE.Object3D[]=[];root.traverse(n=>nodes.push(n));return nodes;}
async function asset(name:string,root:THREE.Object3D){
 const nodes=nodeList(root);const names=nodes.map(n=>n.name);const oldPos=root.position.clone();const oldQuat=root.quaternion.clone();
 nodes.forEach((n,i)=>n.name=`${name}_${String(i).padStart(4,'0')}`);
 const info=nodes.map((n,i)=>({name:n.name,original:names[i],type:n.type,parent:n.parent?nodes.indexOf(n.parent):-1,visible:n.visible,worldMinZ:n.userData.worldMinZ,worldMaxZ:n.userData.worldMaxZ,castShadow:(n as any).castShadow,receiveShadow:(n as any).receiveShadow}));
 const glb=await exporter.parseAsync(root,{binary:true,onlyVisible:false,trs:true});await save(name+'.glb',glb);
 metadata.assets[name]={bytes:glb.byteLength,nodes:info};nodes.forEach((n,i)=>n.name=names[i]);root.position.copy(oldPos);root.quaternion.copy(oldQuat);
 console.log('EXPORTED',name,glb.byteLength,nodes.length);
}
const state:any={runState:'running',distance:0,lane:1,invulnerableMs:0,collisions:0,paused:false,airHeight:0,charge:0,bellPulse:0,boostSeconds:0,shield:false,paperLane:1,paperGap:27,clearedObstacleIds:new Set(),collectedPickupIds:new Set()};
for(const distance of [0,188,377,566,755]){
 state.distance=distance;for(let i=0;i<90;i++){clock+=1000/60;renderer.render(state);} const c=renderer.camera;
 metadata.camera_samples.push({distance,position:c.position.toArray(),quaternion:c.quaternion.toArray(),fov:c.fov,near:c.near,far:c.far,riderPosition:renderer.rider.root.position.toArray(),riderScale:renderer.rider.root.scale.toArray()});
}
// Same source batching, bounded one24-unit world chunk at a time instead of its peak all-world copy.
const world=renderer.staticWorld as THREE.Group;world.updateMatrixWorld(true);
const groups=new Map<number,THREE.Group>();const children=[...world.children];
for(const child of children){const box=new THREE.Box3().setFromObject(child),center=box.getCenter(new THREE.Vector3()),span=box.getSize(new THREE.Vector3());const chunk=span.z>80?9999:Math.floor(center.z/24);let group=groups.get(chunk);if(!group){group=new THREE.Group();group.name='source-world-chunk-'+chunk;groups.set(chunk,group);}group.add(child);}
children.length=0;metadata.world_chunks=[];
for(const [index,group]of groups){
 if((globalThis as any).gc)(globalThis as any).gc();
 console.log('WORLD_CHUNK_START',index,process.memoryUsage().rss);mergeStaticWorldMeshes(group);group.updateMatrixWorld(true);
 const box=new THREE.Box3().setFromObject(group);const name=index===9999?'world_shared':'world_'+(index<0?'n'+(-index):'p'+index);
 await asset(name,group);metadata.world_chunks.push({asset:name,min_z:box.min.z,max_z:box.max.z,shared:index===9999});
 groups.delete(index);group.clear();if((globalThis as any).gc)(globalThis as any).gc();
}
console.log('WORLD_CHUNKS_COMPLETE',metadata.world_chunks.length,process.memoryUsage());
const seen=new Set<string>();
for(const distance of [0,188,377,566]){
 state.distance=distance;clock+=1000/60;renderer.render(state);
 for(const obstacle of visibleStuntObstacles(distance))if(!seen.has(obstacle.kind)){
  seen.add(obstacle.kind);const model=renderer.obstacleModels.get(obstacle.id);const p=model.position.clone(),q=model.quaternion.clone();model.position.set(0,0,0);model.rotation.set(0,obstacle.kind==='bicycle'?Math.PI:0,0);
  await asset('hazard_'+obstacle.kind,model);model.position.copy(p);model.quaternion.copy(q);
 }
 for(const [id,model]of renderer.stuntObjects){const kind=id.startsWith('ramp')?'ramp':STUNT_PICKUPS.find(x=>x.id===id)?.kind;if(!kind||seen.has(kind))continue;seen.add(kind);const p=model.position.clone(),q=model.quaternion.clone();model.position.set(0,0,0);model.rotation.set(0,0,0);await asset('stunt_'+kind,model);model.position.copy(p);model.quaternion.copy(q);}
}
const pp=renderer.paper.position.clone();renderer.paper.position.set(0,0,0);renderer.paper.rotation.set(0,0,0);await asset('paper',renderer.paper);renderer.paper.position.copy(pp);
// Rider geometry/pose tables are exported separately by export_rider.ts.
for(let index=0;index<18;index++){const p=pedestrianAt(index);if(p)metadata.pedestrians.push(p);}
await save('source_manifest.json',JSON.stringify(metadata));
console.log('COMPLETE OFFLINE SOURCE WORLD EXTRACTION',metadata.world_chunks.length);
