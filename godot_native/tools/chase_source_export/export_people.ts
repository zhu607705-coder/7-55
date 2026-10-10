import path from 'node:path';
import {repositoryRoot,outputDirectory} from './paths';
import './node_adapter';
import {readFile,writeFile} from 'node:fs/promises';
import * as THREE from 'three';
import {GLTFLoader} from 'three/examples/jsm/loaders/GLTFLoader.js';
import {GLTFExporter} from 'three/examples/jsm/exporters/GLTFExporter.js';
import {installChaseHumanTemplate} from '../../../src/scenes/rpg/canteen-chase/ChaseHumanAsset';
import {buildPerson} from '../../../src/scenes/rpg/canteen-chase/ChaseThreeRenderer';
import {animateChasePedestrian} from '../../../src/scenes/rpg/canteen-chase/ChasePeople';
const out=outputDirectory+path.sep;
const bytes=await readFile(path.join(repositoryRoot,'src/assets/rpg/canteen-characters/quaternius_casual.glb'));
const human=await new GLTFLoader().parseAsync(bytes.buffer.slice(bytes.byteOffset,bytes.byteOffset+bytes.byteLength),'');installChaseHumanTemplate(human);
const route=JSON.parse(await readFile(out+'source_manifest.json','utf8'));
const hash=(v:string)=>{let h=2166136261;for(let i=0;i<v.length;i++){h^=v.charCodeAt(i);h=Math.imul(h,16777619)>>>0;}return h;};
for(const entry of route.pedestrians){
 const seed=hash(entry.id),actor:any=buildPerson(entry.kind,seed),nodes:any[]=[];actor.group.traverse((n:any)=>nodes.push(n));const bones=nodes.filter(n=>n.isBone),names=nodes.map(n=>n.name);
 const duration=actor.human.clips.find((c:any)=>c.name.endsWith('|Walk')).duration,phaseFrames=48;
 const samples:any[]=[];const boneFloats:number[]=[];
 for(let frame=0;frame<=phaseFrames;frame++){animateChasePedestrian(actor,frame/phaseFrames*duration*5.7,false);actor.group.updateMatrixWorld(true);samples.push(nodes.map(n=>[...n.position.toArray(),...n.quaternion.toArray(),...n.scale.toArray()]));for(const bone of bones)boneFloats.push(...bone.matrixWorld.elements);}
 const reducedSample=samples.length;animateChasePedestrian(actor,0,true);actor.group.updateMatrixWorld(true);samples.push(nodes.map(n=>[...n.position.toArray(),...n.quaternion.toArray(),...n.scale.toArray()]));for(const bone of bones)boneFloats.push(...bone.matrixWorld.elements);
 const dynamic:number[]=[];for(let n=1;n<nodes.length;n++){if(nodes[n].isBone)continue;let changes=false;for(let f=1;f<samples.length&&!changes;f++)for(let k=0;k<10;k++)if(Math.abs(samples[f][n][k]-samples[0][n][k])>1e-9)changes=true;if(changes)dynamic.push(n);}
 const local:number[]=[];for(const f of samples)for(const i of dynamic)local.push(...f[i]);
 const prefix='ped_'+entry.id.replace(/[^a-z0-9]/g,'_');nodes.forEach((n,i)=>{n.name=prefix+'_'+String(i).padStart(4,'0');n.position.fromArray(samples[0][i]);n.quaternion.fromArray(samples[0][i],3);n.scale.fromArray(samples[0][i],7);});actor.group.updateMatrixWorld(true);
 const glb=await new GLTFExporter().parseAsync(actor.group,{binary:true,onlyVisible:false,trs:true});await writeFile(out+prefix+'_geometry.glb',Buffer.from(glb as ArrayBuffer));await writeFile(out+prefix+'_bone_poses.bin',Buffer.from(new Float32Array(boneFloats).buffer));await writeFile(out+prefix+'_local_poses.bin',Buffer.from(new Float32Array(local).buffer));
 await writeFile(out+prefix+'_pose_manifest.json',JSON.stringify({phaseFrames,reducedSample,steers:[0],duration,restSteerIndex:0,bones:bones.map(n=>({name:n.name,original:names[nodes.indexOf(n)],index:nodes.indexOf(n)})),dynamic:dynamic.map(i=>nodes[i].name),nodes:nodes.map((n,i)=>({name:n.name,original:names[i],visible:n.visible,type:n.type})),references:{}}));
 entry.asset=prefix;entry.seed=seed;entry.walk_duration=duration;console.log('EXPORTED_PEDESTRIAN',entry.id,entry.kind,seed,glb.byteLength,bones.length,duration);
 if((globalThis as any).gc)(globalThis as any).gc();
}
await writeFile(out+'source_manifest.json',JSON.stringify(route));
