import './node_adapter';
import path from 'node:path';
import {fileURLToPath} from 'node:url';
import {readFile,writeFile,mkdir} from 'node:fs/promises';
import {fakeCanvas} from './node_adapter';
import {GLTFLoader} from 'three/examples/jsm/loaders/GLTFLoader.js';
import {installChaseHumanTemplate} from '../../../src/scenes/rpg/canteen-chase/ChaseHumanAsset';
import * as THREE from 'three';
import {GLTFExporter} from 'three/examples/jsm/exporters/GLTFExporter.js';
import {CanteenBikeTransitionRenderer} from '../../../src/scenes/rpg/canteen-chase/CanteenBikeTransitionRenderer';
const repositoryRoot=process.env.CANTEEN_SOURCE_ROOT ?? path.resolve(path.dirname(fileURLToPath(import.meta.url)),'../../..');
const nativeRoot=process.env.CANTEEN_NATIVE_ROOT ?? path.join(repositoryRoot,'godot_native');
const outputDirectory=path.join(nativeRoot,'assets/derived/chase_transition_3d');
const bytes=await readFile(path.join(repositoryRoot,'src/assets/rpg/canteen-characters/quaternius_casual.glb'));
const gltf=await new Promise((resolve,reject)=>new GLTFLoader().parse(bytes.buffer.slice(bytes.byteOffset,bytes.byteOffset+bytes.byteLength),'',resolve,reject));
installChaseHumanTemplate(gltf as any);
const canvas=fakeCanvas(), status={textContent:''};
const renderer:any=new CanteenBikeTransitionRenderer(canvas as any,'start',{preserveDrawingBuffer:true,renderWidth:960,renderHeight:540,pixelRatioCap:1,enableCaptureShadows:false});
const sleep=async(_:number)=>{};
await mkdir(outputDirectory,{recursive:true});
const save=async(name:string,body:any)=>{await writeFile(path.join(outputDirectory,name.replaceAll('-','_')),typeof body==='string'?body:Buffer.from(body));};
async function run(){
 for(let i=0;i<300&&renderer.getAssetState()!=='ready';i++)await sleep(100);
 if(renderer.getAssetState()!=='ready')throw Error('source assets not ready');
 const nodes:THREE.Object3D[]=[];renderer.scene.traverse((n:THREE.Object3D)=>nodes.push(n));
 const originalNames=nodes.map(n=>n.name);
 const refs:any={};
 for(const name of ['leftHandContact','rightHandContact','leftFootContact','rightFootContact','leftGripContact','rightGripContact','leftPedalContact','rightPedalContact'])refs[name]=renderer.rider[name];
 for(const name of ['Hips','Head','WristL','WristR','FootL','FootR'])refs[name]=renderer.rider.human.bones.get(name);
 const referenceNodes=Object.fromEntries(Object.entries(refs).map(([name,node]:any)=>[name,nodes.indexOf(node)]));
 const samples:any={start:[],finish:[]};const transforms:any={start:[],finish:[]};const boneFrames:any={start:[],finish:[]};const boneNodes=[...renderer.rider.human.bones.values()] as THREE.Object3D[];
 const keys:any={start:[0,20,29,37,56,80,90],finish:[0,24,60,75,99,112,122]};
 for(const stage of ['start','finish']){
  renderer.setStage(stage);const last=stage==='start'?90:132;
  for(let frame=0;frame<=last;frame++){
   renderer.renderFrame(frame);renderer.scene.updateMatrixWorld(true);
   const camera=renderer.camera;
   const snap={...renderer.getSnapshot(),cameraPosition:camera.position.toArray(),cameraQuaternion:camera.quaternion.toArray(),cameraFov:camera.fov,background:renderer.scene.background.getHex(),exposure:renderer.renderer.toneMappingExposure,visible:nodes.map(n=>n.visible),humanContact:renderer.rider.human.group.userData.contactErrors,referenceWorld:Object.fromEntries(Object.entries(refs).map(([name,node]:any)=>[name,node.matrixWorld.toArray()]))};
   samples[stage].push(snap);boneFrames[stage].push(boneNodes.map(n=>n.matrixWorld.toArray()));
   transforms[stage].push(nodes.map(n=>[...n.position.toArray(),...n.quaternion.toArray(),...n.scale.toArray()]));
   // Offline transform extraction only. No source pixel capture claim.
   if(frame%20===0){status.textContent=`Source capture ${stage} ${frame}/${last}`;await sleep(0);}
  }
 }
 if(process.env.POSE_ONLY==='1'){
  const dynamic:number[]=[];
  for(let n=0;n<nodes.length;n++){
   if(nodes[n].isBone)continue;
   if(['start','finish'].some(stage=>transforms[stage].some((f:any)=>f[n].some((v:number,k:number)=>Math.abs(v-transforms.start[0][n][k])>1e-8))))dynamic.push(n);
  }
  const data={fps:24,dynamic:dynamic.map(i=>`source_${String(i).padStart(5,'0')}`),bones:boneNodes.map(n=>({name:`source_${String(nodes.indexOf(n)).padStart(5,'0')}`,originalName:n.name})),stages:Object.fromEntries(['start','finish'].map(stage=>[stage,{local:transforms[stage].map((f:any)=>dynamic.map(n=>f[n])),boneWorld:boneFrames[stage]}]))};
  await save('source-pose-frames.json',JSON.stringify(data,(_key,v)=>typeof v==='number'?Math.round(v*1e8)/1e8:v));
  console.log('POSE_ONLY source exact frames',dynamic.length,'nodes',boneNodes.length,'bones');return;
 }
 // Names are assigned only after source rendering/IK capture because the source
 // visibility resolver relies on authored names. Export uses all meshes.
 nodes.forEach((n,i)=>n.name=`source_${String(i).padStart(5,'0')}`);
 const clips:THREE.AnimationClip[]=[];
 for(const stage of ['start','finish']){
  const all=transforms[stage],tracks:THREE.KeyframeTrack[]=[],times=all.map((_:any,i:number)=>i/24);
  for(let n=0;n<nodes.length;n++)for(const [property,offset,length] of [['position',0,3],['quaternion',3,4],['scale',7,3]] as any){
   let changed=false;for(let frame=1;frame<all.length&&!changed;frame++)for(let k=0;k<length;k++)if(Math.abs(all[frame][n][offset+k]-all[0][n][offset+k])>1e-8)changed=true;
   // Include a constant first pose for dynamic stage-specific bones too: each
   // clip must fully restore the rig when switching from a different stage.
   if(!changed && !nodes[n].isBone && !renderer.rider.root.getObjectById(nodes[n].id))continue;
   const values=all.flatMap((f:any)=>f[n].slice(offset,offset+length));
   const Track=property==='quaternion'?THREE.QuaternionKeyframeTrack:THREE.VectorKeyframeTrack;
   tracks.push(new Track(nodes[n].name+'.'+property,times,values,THREE.InterpolateDiscrete));
  }
  clips.push(new THREE.AnimationClip(stage,all.length/24,tracks));
 }
 // Restore frame0 local transforms without calling source name-sensitive code.
 nodes.forEach((n,i)=>{const v=transforms.start[0][i];n.position.fromArray(v);n.quaternion.fromArray(v,3);n.scale.fromArray(v,7);n.visible=true;});
 renderer.scene.updateMatrixWorld(true);
 // Non-rendering controls and exact source scene geometry are exported intact.
 const glb=await new GLTFExporter().parseAsync(renderer.scene,{binary:true,onlyVisible:false,animations:clips,trs:true});
 await save('source-transition.glb',glb);
 const manifest={fps:24,referenceNodes,stages:samples,nodes:nodes.map((n,i)=>({name:n.name,originalName:originalNames[i],type:n.type,parent:n.parent?nodes.indexOf(n.parent):-1})),source:'Source geometry/IK extraction with no-op renderer adapter, no source pixels; preview shadows=false'};
 await save('source-transition.json',JSON.stringify(manifest));
 status.textContent=`DONE: offline source geometry/IK extraction, ${nodes.length} nodes, ${clips.map(c=>c.tracks.length).join('/')} tracks`;
 await save('done.json',JSON.stringify({nodes:nodes.length,tracks:clips.map(c=>c.tracks.length),bytes:glb.byteLength}));
 console.log(status.textContent); // No render after export-renaming.
}
await run().catch(async e=>{console.error(e);await save('error.txt',e.stack);process.exitCode=1;});
