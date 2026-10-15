import path from 'node:path';
import {repositoryRoot,outputDirectory} from './paths';
import './node_adapter';
import {readFile,writeFile} from 'node:fs/promises';
import * as THREE from 'three';
import {GLTFLoader} from 'three/examples/jsm/loaders/GLTFLoader.js';
import {GLTFExporter} from 'three/examples/jsm/exporters/GLTFExporter.js';
import {installChaseHumanTemplate} from '../../../src/scenes/rpg/canteen-chase/ChaseHumanAsset';
import {createChaseRiderRig,applyChaseRiderPose,measureChaseRiderContactError} from '../../../src/scenes/rpg/canteen-chase/ChaseRiderRig';
import {ThreePrimitiveCache} from '../../../src/scenes/rpg/ThreePrimitiveCache';
const out=outputDirectory+path.sep;
const bytes=await readFile(path.join(repositoryRoot,'src/assets/rpg/canteen-characters/quaternius_casual.glb'));
const human=await new GLTFLoader().parseAsync(bytes.buffer.slice(bytes.byteOffset,bytes.byteOffset+bytes.byteLength),'');installChaseHumanTemplate(human);
const rig=createChaseRiderRig(new ThreePrimitiveCache());rig.root.position.set(0,0,0);rig.root.rotation.set(0,0,0);
const nodes:THREE.Object3D[]=[];rig.root.traverse(n=>nodes.push(n));const bones=nodes.filter(n=>n instanceof THREE.Bone);const names=nodes.map(n=>n.name);
const steers=Array.from({length:21},(_,i)=>(i-10)*.035),phaseFrames=96;
const localSamples:any[]=[];const boneFloats:number[]=[];let maxControlError=0,maxSkinnedError=0;
for(const steer of steers)for(let frame=0;frame<=phaseFrames;frame++){
 applyChaseRiderPose(rig,'ride',{pedalPhaseRadians:-frame/phaseFrames*Math.PI*2,steeringRadians:steer});rig.root.updateMatrixWorld(true);
 const error=measureChaseRiderContactError(rig);maxControlError=Math.max(maxControlError,error.leftHandToGripWorldUnits,error.rightHandToGripWorldUnits,error.leftFootToPedalWorldUnits,error.rightFootToPedalWorldUnits);
 maxSkinnedError=Math.max(maxSkinnedError,...Object.values(rig.human.group.userData.contactErrors) as number[]);
 localSamples.push(nodes.map(n=>[...n.position.toArray(),...n.quaternion.toArray(),...n.scale.toArray()]));
 for(const bone of bones)boneFloats.push(...bone.matrixWorld.elements);
}
const dynamic:number[]=[];
for(let n=1;n<nodes.length;n++){if(nodes[n] instanceof THREE.Bone)continue;let changes=false;for(let i=1;i<localSamples.length&&!changes;i++)for(let k=0;k<10;k++)if(Math.abs(localSamples[i][n][k]-localSamples[0][n][k])>1e-9)changes=true;if(changes)dynamic.push(n);}
const localFloats:number[]=[];for(const frame of localSamples)for(const index of dynamic)localFloats.push(...frame[index]);
const centerIndex=10*(phaseFrames+1);const first=localSamples[centerIndex];
const refs:any={};for(const [name,node]of Object.entries({rearWheel:rig.rearWheel,frontWheel:rig.frontWheel,frontAssembly:rig.frontAssembly,leftGrip:rig.leftGripContact,rightGrip:rig.rightGripContact,leftFoot:rig.leftFootContact,rightFoot:rig.rightFootContact,leftPedal:rig.leftPedalContact,rightPedal:rig.rightPedalContact,crank:rig.crank}))refs[name]=nodes.indexOf(node as THREE.Object3D);
const offgrid:any[]=[];
for(const [steer,phase]of [[-.183,.237],[-.071,1.923],[.093,3.179],[.219,4.823],[0,5.119]]){
 applyChaseRiderPose(rig,'ride',{pedalPhaseRadians:-phase,steeringRadians:steer});rig.root.updateMatrixWorld(true);
 offgrid.push({steer,phase,boneWorld:bones.map(b=>b.matrixWorld.elements.slice()),references:Object.fromEntries(Object.entries(refs).map(([k,i])=>[k,nodes[i as number].matrixWorld.elements.slice()]))});
}
nodes.forEach((n,i)=>{n.name=`rider_${String(i).padStart(4,'0')}`;n.position.fromArray(first[i]);n.quaternion.fromArray(first[i],3);n.scale.fromArray(first[i],7);});rig.root.updateMatrixWorld(true);
const geometry=await new GLTFExporter().parseAsync(rig.root,{binary:true,trs:true,onlyVisible:false});await writeFile(out+'rider_geometry.glb',Buffer.from(geometry as ArrayBuffer));
await writeFile(out+'rider_bone_poses.bin',Buffer.from(new Float32Array(boneFloats).buffer));await writeFile(out+'rider_local_poses.bin',Buffer.from(new Float32Array(localFloats).buffer));
const manifest={kind:'Exact source IK sample grid; no source pixel capture',phaseFrames,steers,bones:bones.map(n=>({name:n.name,index:nodes.indexOf(n),original:names[nodes.indexOf(n)]})),dynamic:dynamic.map(i=>nodes[i].name),nodes:nodes.map((n,i)=>({name:n.name,original:names[i],visible:n.visible,type:n.type})),references:Object.fromEntries(Object.entries(refs).map(([name,i])=>[name,nodes[i as number].name])),sourceMaxControlError:maxControlError,sourceMaxSkinnedError:maxSkinnedError,offgrid};
await writeFile(out+'rider_pose_manifest.json',JSON.stringify(manifest));console.log('SOURCE_RIDER_GRID',geometry.byteLength,boneFloats.length,localFloats.length,maxControlError,maxSkinnedError);
