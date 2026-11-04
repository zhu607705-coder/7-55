/** Diagnostic work-budget contracts only; not real geometry/browser acceptance. */
import assert from 'node:assert/strict';
import fs from 'node:fs';
import vm from 'node:vm';
import {displayTargetFromHit} from '../web/project_displays.js';
const source=fs.readFileSync(new URL('../web/viewer.js',import.meta.url),'utf8');
const code=source.slice(source.indexOf('function projectDisplayDiagnostics('),source.indexOf('\nfunction pick(e)'));
let checks=0,rays=0,bounds=0,updates=0,hitMode='wall';
const check=(value,label)=>{assert.ok(value,label);checks++;};
class Vector3{constructor(x=0,y=0,z=0){Object.assign(this,{x,y,z});}clone(){return new Vector3(this.x,this.y,this.z);}add(v){this.x+=v.x;this.y+=v.y;this.z+=v.z;return this;}multiply(v){this.x*=v.x;this.y*=v.y;this.z*=v.z;return this;}applyMatrix4(){return this;}project(){return this;}toArray(){return [this.x,this.y,this.z];}distanceTo(){return 3;}}
class Matrix4{copy(){return this;}premultiply(){return this;}}
const canvas={},wall={userData:{kind:'wall'},name:'wall'},desks=Array.from({length:10},(_,i)=>({userData:{spatialId:'desk/'+i,photoLevel:0,currentHeight:.73,targetHeight:.73}}));
const mesh={isMesh:true,isInstancedMesh:true,visible:true,name:'screens',matrixWorld:{},getMatrixAt(){},userData:{deskEntries:desks.map(desk=>({desk,asset:'photo_monitor_stand',sourcePart:'Neutral screen',level:0}))},geometry:{boundingBox:null,computeBoundingBox(){bounds++;this.boundingBox={getCenter:()=>new Vector3(),getSize:()=>new Vector3(.1,.1,.1)};}}};
const root={visible:true,traverse(fn){fn(mesh);}};
class Raycaster{setFromCamera(){}intersectObjects(){rays++;return hitMode==='visible'?[{object:mesh,instanceId:0,distance:2}]:hitMode==='blocked'?[{object:wall,distance:1},{object:mesh,instanceId:0,distance:2}]:[{object:wall,distance:1}];}}
const context={THREE:{Vector3,Matrix4,Raycaster,Vector2:class{set(){}}},scene:{updateMatrixWorld(){updates++;}},camera:{position:{toArray:()=>[0,0,0]},quaternion:{toArray:()=>[0,0,0,1]},updateMatrixWorld(){}},roots:new Map([['3',root]]),placeholder:null,projectDisplay:{active:'desk/0'},state:{mode:'walk',inspect:null},deskRoots:desks,deskControls:()=>[],innerWidth:100,innerHeight:100,document:{elementFromPoint:()=>canvas},canvas,displayTargetFromHit,hitIsVisible:()=>true};
vm.createContext(context);vm.runInContext(code,context);const query=context.projectDisplayDiagnostics;
const light=query({geometry:false,controls:true,targetId:'desk/0'});
check(light.active==='desk/0'&&light.controls.length===1,'light status returns exact owner and desk');
check(rays===0&&bounds===0&&updates===0,'light status does no traversal, bounds or ray work');
let result=query({kind:'monitor',limit:100});
check(result.nextCursor===3&&result.rayCount===21,'large requested budget is capped at three candidates / 21 rays');
check(bounds===1,'shared geometry bounds computed once');
result=query({kind:'monitor',cursor:3});
check(result.nextCursor===6&&bounds===1,'pagination advances and retains cached bounds');
result=query({kind:'poster'});check(result.candidateCount===0&&result.rayCount===0,'type filter avoids unrelated ray work');
result=query({kind:'monitor',targetId:'desk/8'});check(result.candidateCount===1&&result.nextCursor===null,'known target narrows candidates');
hitMode='visible';result=query({kind:'monitor'});check(result.targets.length===1&&result.rayCount===1,'first nearest-hit verified target returns immediately');
result=query({kind:'monitor',excludeIds:['desk/0']});check(result.candidateCount===9&&result.targets.length===0,'excluded owner cannot be returned from another instance');
hitMode='blocked';result=query({kind:'monitor',occlusion:true});check(result.occluded.length===1&&result.rayCount===1&&result.occluded[0].behindWall,'occlusion requires wall then actual display hit');
hitMode='wall';result=query({kind:'monitor',occlusion:true,targetId:'desk/0'});check(result.occluded.length===0,'wall alone cannot fabricate an occluded display');
console.log(JSON.stringify({passed:checks,scope:'Mock diagnostic budget, filtering and nearest-hit contracts only; not actual building acceptance'},null,2));
