import {readFile,writeFile} from 'node:fs/promises';
import {createHash} from 'node:crypto';
import * as THREE from 'three';
import {GLTFLoader} from 'three/examples/jsm/loaders/GLTFLoader.js';
const source='src/assets/rpg/canteen-characters/quaternius_casual.glb';
const bytes=await readFile(source);const gltf=await new GLTFLoader().parseAsync(bytes.buffer.slice(bytes.byteOffset,bytes.byteOffset+bytes.byteLength),'');
const bones=new Map();gltf.scene.traverse(n=>{if(n.isBone)bones.set(n.name,n)});
const mapping={Hips:'Hips',Torso:'Torso',Head:'Head',Neck:'Neck'};
for(const s of ['L','R'])for(const [to,from] of [['Shoulder','UpperArm.'],['Elbow','LowerArm.'],['Wrist','Wrist.'],['Hip','UpperLeg.'],['Knee','LowerLeg.'],['Foot','Foot.']])mapping[to+s]=from+s;
gltf.scene.updateMatrixWorld(true);const convert=new THREE.Quaternion().setFromAxisAngle(new THREE.Vector3(0,1,0),Math.PI);
const snapshot=()=>Object.fromEntries(Object.entries(mapping).map(([to,from])=>{const p=bones.get(from.replaceAll('.','')).getWorldPosition(new THREE.Vector3()).applyQuaternion(convert);const q=bones.get(from.replaceAll('.','')).getWorldQuaternion(new THREE.Quaternion()).premultiply(convert);return[to,{p:p.toArray(),q:q.toArray()}]}));
const rest=snapshot();const mixer=new THREE.AnimationMixer(gltf.scene);const clip=gltf.animations.find(a=>a.name.endsWith('|Walk'));mixer.clipAction(clip).play();const frames=120,samples=[];
for(let i=0;i<=frames;i++){mixer.setTime(i/frames*clip.duration);gltf.scene.updateMatrixWorld(true);samples.push(snapshot())}
const result={schema:'755-cc0-student-walk-v1',source,sourceSha256:createHash('sha256').update(bytes).digest('hex'),license:'CC0-1.0',author:'Quaternius',url:'https://quaternius.com/packs/ultimatemodularcharacters.html',clip:clip.name,duration:clip.duration,frames,hipMeanY:samples.reduce((n,s)=>n+s.Hips.p[1],0)/samples.length,orientation:'source rotated pi about Y; forward is -Z',mapping,rest,samples};
const target='godot_native/assets/native_755/ride/student_walk_cc0.json';
const encoded=JSON.stringify(result);
if(process.argv.includes('--check')) {if(await readFile(target,'utf8')!==encoded)throw new Error('Baked student walk differs from the licensed source animation');}
else await writeFile(target,encoded);
console.log(JSON.stringify({clip:clip.name,duration:clip.duration,frames,sourceSha256:result.sourceSha256,hipMeanY:result.hipMeanY,checked:process.argv.includes('--check')}));
