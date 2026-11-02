/** Actual GLB geometry + viewer functions in a VM. Renderer, network, DOM and
 * optional generated-asset libraries are mocked. NOT browser/GPU acceptance.
 * Embedded image resources are stripped only in memory to allow Node parsing;
 * positions, indices, node names, extras and hierarchy come from building.glb.
 */
import assert from 'node:assert/strict';
import fs from 'node:fs';
import os from 'node:os';
import path from 'node:path';
import vm from 'node:vm';
import {fileURLToPath,pathToFileURL} from 'node:url';
import * as RealThree from '../web/vendor/three/three.module.js';
import * as spatialModule from '../web/spatial_catalog.js';
import {createSpatialPresentation} from '../web/spatial_presentation.js';
import * as collision from '../web/collision.js';
const root=fileURLToPath(new URL('..',import.meta.url)),web=path.join(root,'web'),temp=fs.mkdtempSync(path.join(os.tmpdir(),'flc-viewer-node-'));
let passed=0;const check=(ok,label)=>{assert.ok(ok,label);passed++;};
try{
 const threeURL=pathToFileURL(path.join(web,'vendor/three/three.module.js')).href;
 for(const [name,relative] of [['BufferGeometryUtils','utils/BufferGeometryUtils'],['SkeletonUtils','utils/SkeletonUtils'],['GLTFLoader','loaders/GLTFLoader']]){
  let source=fs.readFileSync(path.join(web,'vendor/three/addons',relative+'.js'),'utf8').replaceAll("from 'three'",`from '${threeURL}'`);
  source=source.replaceAll("'../utils/BufferGeometryUtils.js'","'./BufferGeometryUtils.mjs'").replaceAll("'../utils/SkeletonUtils.js'","'./SkeletonUtils.mjs'");fs.writeFileSync(path.join(temp,name+'.mjs'),source);
 }
 const {GLTFLoader}=await import(pathToFileURL(path.join(temp,'GLTFLoader.mjs'))),{mergeGeometries}=await import(pathToFileURL(path.join(temp,'BufferGeometryUtils.mjs')));
 const originalGLB=fs.readFileSync(path.join(web,'assets/building.glb')),jsonLength=originalGLB.readUInt32LE(12),sourceJSON=JSON.parse(originalGLB.subarray(20,20+jsonLength));
 const gltfJSON=structuredClone(sourceJSON);delete gltfJSON.images;delete gltfJSON.textures;
 function stripTextures(value){if(!value||typeof value!=='object')return;for(const k of Object.keys(value)){if(/Texture$/.test(k))delete value[k];else stripTextures(value[k]);}}stripTextures(gltfJSON.materials);
 let json=Buffer.from(JSON.stringify(gltfJSON));json=Buffer.concat([json,Buffer.alloc((4-json.length%4)%4,32)]);const bin=originalGLB.subarray(20+jsonLength);const buffer=Buffer.alloc(20+json.length+bin.length);buffer.writeUInt32LE(0x46546c67,0);buffer.writeUInt32LE(2,4);buffer.writeUInt32LE(buffer.length,8);buffer.writeUInt32LE(json.length,12);buffer.writeUInt32LE(0x4e4f534a,16);json.copy(buffer,20);bin.copy(buffer,20+json.length);
 const loaded=await new GLTFLoader().parseAsync(buffer.buffer.slice(buffer.byteOffset,buffer.byteOffset+buffer.byteLength),'');
 let sourceMeshes=0,sourceNodes=0;loaded.scene.traverse(o=>{sourceNodes++;if(o.isMesh)sourceMeshes++;});check(sourceMeshes>1000,'actual source GLB meshes parsed');check(sourceNodes>10000,'actual source GLB hierarchy parsed');
 class Element{
  constructor(tag='div'){this.tagName=tag.toUpperCase();this.style={};this.children=[];this.hidden=false;this.value='';this.listeners={};this.classList={toggle(){},add(){},remove(){}};}
  get options(){return this.children;}append(...items){this.children.push(...items);}add(x){this.append(x);}replaceChildren(...x){this.children=[...x];}setAttribute(k,v){this[k]=v;}addEventListener(k,fn){(this.listeners[k]??=[]).push(fn);}focus(){}setPointerCapture(){}hasPointerCapture(){return false;}releasePointerCapture(){}getBoundingClientRect(){return {x:0,y:0,left:0,top:0,width:120,height:120};}getContext(){return {fillRect(){},strokeRect(){},fillText(){}};}showModal(){this.open=true;}close(){this.open=false;}
 }
 const elements=new Map(),document={body:new Element(),hidden:false,activeElement:null,getElementById:id=>{if(!elements.has(id))elements.set(id,new Element(id==='scene'?'canvas':'div'));return elements.get(id);},createElement:tag=>new Element(tag),createTextNode:text=>({textContent:text}),querySelector:()=>null,addEventListener(){}};
 const errors=[];class Renderer{constructor(){this.shadowMap={};this.info={render:{calls:0,triangles:0}};}setPixelRatio(){}setClearColor(){}setSize(){}render(){}}
 class PMREM{fromScene(){return {texture:new RealThree.Texture()};}dispose(){}}
 class RoomEnvironment extends RealThree.Group{dispose(){}}
 class Orbit{constructor(camera){this.target=new RealThree.Vector3();this.camera=camera;}update(){this.camera.lookAt(this.target);}dispose(){}}
 const context=vm.createContext({THREE:{...RealThree,WebGLRenderer:Renderer,PMREMGenerator:PMREM},...spatialModule,...collision,createSpatialPresentation,mergeGeometries,OrbitControls:Orbit,RoomEnvironment,GLTFLoader:class{async loadAsync(){return {scene:loaded.scene};}},loadFloorMaterialLibrary:async()=>({tile:new RealThree.MeshStandardMaterial()}),loadChairAssets:async()=>null,loadStaticAssets:async()=>new Map(),createModelLoader:()=>({dispose(){}}),ChairInstances:class{},StaticAssetInstance:class{},document,Option:class extends Element{constructor(text,value){super('option');this.textContent=text;this.value=value;}},console:{log(){},warn(){},error:e=>errors.push(String(e.stack||e))},URLSearchParams,location:{search:'?floor=4',reload(){}},history:{replaceState(){}},matchMedia:()=>({matches:false}),innerWidth:1280,innerHeight:800,devicePixelRatio:1,requestAnimationFrame(){},Event:class{},fetch:async url=>({ok:true,json:async()=>JSON.parse(fs.readFileSync(path.resolve(web,url),'utf8'))})});
 context.window=context;context.addEventListener=()=>{};context.dispatchEvent=()=>{};
 vm.runInContext(fs.readFileSync(path.join(web,'spatial_overlay.js'),'utf8').replaceAll('export function','function'),context,{filename:'spatial_overlay.js'});
 const viewer=fs.readFileSync(path.join(web,'viewer.js'),'utf8').replace(/^import .*;\n/gm,'').replace(/\nstart\(\);\s*$/,'');
 vm.runInContext(viewer+'\nglobalThis.integration={start,spatialAction,enterWalk,openSpatialObject,exitInspect,setOverview,resize,frame,toggleDesk,animateDesks,objectBounds,roots,spatialRoots,get state(){return state},get spatial(){return spatial},get catalog(){return spatialCatalog},get layout(){return layout},get camera(){return camera},get savedWalk(){return savedWalk},get toolRoots(){return toolRoots},get deskRoots(){return deskRoots}};',context,{filename:'viewer.js'});
 const api=context.integration;await api.start();check(errors.length===0,'viewer startup errors: '+errors.join('\n'));check(context.flcReview.snapshot().ready,'viewer reaches ready using source GLB');
 const physicalBefore=JSON.stringify(api.layout),ids=Object.keys(api.catalog.objects);
 check(ids.length===api.toolRoots.length+api.deskRoots.length&&ids.length>0,'all real inspectable tools and desks registered');check(new Set(ids).size===ids.length,'no duplicate object IDs');check(ids.every(id=>api.spatialRoots.has(id)),'all registered object IDs map to real roots');check(Object.values(api.catalog.objects).every(o=>o.sourceNodeName),'every registered object has source name');const names=new Set();loaded.scene.traverse(o=>names.add(o.name));check(Object.values(api.catalog.objects).every(o=>names.has(o.sourceNodeName)),'registered IDs derive from actual parsed GLB node names');
 api.spatialAction({type:'EXPAND'});check(api.spatial.scope==='building'&&api.spatial.expanded,'4F to expanded building');check([...api.roots].every(([f,r])=>r.visible&&r.position.y>api.layout.floors[f].elevation),'display-only floor offsets applied');
 api.spatialAction({type:'SELECT_FLOOR',floor:'3'});check(!api.spatial.expanded&&api.state.floor==='3','select 3F collapses display');
 api.spatialAction({type:'SELECT_ROOM',room:'xlab'});check(api.spatial.scope==='room'&&api.state.room==='xlab','focus source lab room');
 const desk=Object.values(api.catalog.objects).find(o=>o.floor==='3'&&o.room==='xlab'&&o.kind==='desk');check(!!desk,'actual lab contains registered desk');
 const deskNode=api.spatialRoots.get(desk.id),originalDeskBounds=api.objectBounds(deskNode).clone();api.toggleDesk(deskNode);api.animateDesks(10);check(Math.abs(deskNode.userData.currentHeight-1.10)<1e-8,'existing desk rises to standing height');check(api.objectBounds(deskNode).max.y>originalDeskBounds.max.y+.3,'instanced desk bounds track physical upper parts');api.toggleDesk(deskNode);api.animateDesks(10);check(Math.abs(deskNode.userData.currentHeight-.73)<1e-8,'existing desk returns to seated height');
 const priorCamera=api.camera.position.clone();api.openSpatialObject(desk.id);check(api.spatial.scope==='object'&&api.spatial.object===desk.id,'lab desk inspection selects stable ID');check(api.camera.position.toArray().every(Number.isFinite),'desk bounds produce finite close camera');api.resize();check(api.camera.position.toArray().every(Number.isFinite),'resize while inspecting actual desk remains finite');
 api.spatialAction({type:'BACK'});check(api.spatial.scope==='room'&&api.state.room==='xlab'&&!api.state.inspect,'single Back exits object, not room');check(api.camera.position.distanceTo(priorCamera)<1e-8,'inspection restores exact pre-inspection camera');
 api.spatialAction({type:'SELECT_FLOOR',floor:'2'});api.enterWalk();check(api.state.mode==='walk'&&api.spatial.floor==='2','existing 2F walkthrough entry remains');
 const walkingPosition=[...api.state.pos],walkingTool=api.toolRoots.find(t=>t.userData.floor==='2');check(!!walkingTool,'actual 2F inspectable source tool');api.openSpatialObject(walkingTool.userData.spatialId);api.exitInspect();check(api.state.mode==='walk'&&api.state.pos.every((n,i)=>n===walkingPosition[i]),'walk inspection restores observer position');
 api.setOverview();api.spatialAction({type:'BACK'});check(api.state.mode==='overview','back does not reenter walking');
 api.spatialAction({type:'SELECT_FLOOR',floor:'1'});api.enterWalk();check(api.state.floor==='1'&&api.state.mode==='overview','1F never enters walkthrough');check(context.flcReview.spatial().placeholderVisible,'1F shows explicit pending placeholder');check([...api.roots].every(([,r])=>!r.visible),'1F does not expose invented floor geometry');
 for(let n=0;n<5;n++){api.spatialAction({type:'EXPAND'});api.spatialAction({type:'SELECT_FLOOR',floor:'3'});api.spatialAction({type:'SELECT_ROOM',room:'xlab'});api.openSpatialObject(desk.id);api.exitInspect();check(api.spatial.scope==='room'&&api.spatial.room==='xlab'&&!api.state.inspect,'repeat inspect/cancel roundtrip');}
 api.openSpatialObject(desk.id);api.spatialAction({type:'SELECT_FLOOR',floor:'4'});check(!api.state.inspect&&api.savedWalk===null&&api.spatial.floor==='4','switch floor while inspecting clears saved object state');api.enterWalk();check(api.state.mode==='overview','office floor does not enter interior walkthrough');check(context.flcReview.spatial().posterCount===3,'three explicit corridor poster placeholders');
 check(fs.readFileSync(path.join(web,'assets/building.glb')).equals(originalGLB),'source GLB bytes untouched');check(JSON.stringify(api.layout)===physicalBefore,'source layout/colliders untouched by viewer actions');check(JSON.stringify(Object.keys(api.catalog.objects))===JSON.stringify(ids),'object identities stable across selection');check(errors.length===0,'no later logged exceptions');
 console.log(JSON.stringify({passed,sourceNodes,sourceMeshes,registeredObjects:ids.length,scope:'Actual building.glb hierarchy/geometry and viewer state integration in Node VM. Renderer, DOM, network and optional generated asset loading mocked; embedded textures stripped in memory. NOT browser/GPU/pointer acceptance.'},null,2));
}finally{fs.rmSync(temp,{recursive:true,force:true});}
