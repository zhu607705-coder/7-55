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
import {createRenderGate} from '../web/render_gate.js';
import {frameTimeSteps} from '../web/frame_timing.js';
import {createDeskInspectionProxy} from '../web/desk_inspection.js';
import {createSpatialPresentation} from '../web/spatial_presentation.js';
import * as collision from '../web/collision.js';
import * as photoPlacement from '../web/photo_static_placement.js';
import * as photoModule from '../web/photo_scene_assets.js';
import {REVIEW_ANCHOR,createWorkstationReview} from '../web/workstation_review.js';
import * as photoMaterials from '../web/photo_desk_materials.js';
const root=fileURLToPath(new URL('..',import.meta.url)),web=path.join(root,'web'),temp=fs.mkdtempSync(path.join(os.tmpdir(),'flc-viewer-node-'));
let passed=0;const check=(ok,label)=>{assert.ok(ok,label);passed++;};
try{
 const threeURL=pathToFileURL(path.join(web,'vendor/three/three.module.js')).href;
 for(const [name,relative] of [['BufferGeometryUtils','utils/BufferGeometryUtils'],['SkeletonUtils','utils/SkeletonUtils'],['GLTFLoader','loaders/GLTFLoader']]){
  let source=fs.readFileSync(path.join(web,'vendor/three/addons',relative+'.js'),'utf8').replaceAll("from 'three'",`from '${threeURL}'`);
  source=source.replaceAll("'../utils/BufferGeometryUtils.js'","'./BufferGeometryUtils.mjs'").replaceAll("'../utils/SkeletonUtils.js'","'./SkeletonUtils.mjs'");fs.writeFileSync(path.join(temp,name+'.mjs'),source);
 }
 const {GLTFLoader}=await import(pathToFileURL(path.join(temp,'GLTFLoader.mjs'))),{mergeGeometries}=await import(pathToFileURL(path.join(temp,'BufferGeometryUtils.mjs')));
 let photoLoads=0;
 const photoLibrary=await photoModule.loadPhotoSceneAssets({loader:{async loadAsync(url){
  if(url.endsWith('.draco.glb'))throw Error('Exercise uncompressed fallback in Node');
  photoLoads++;const b=fs.readFileSync(path.resolve(web,url)),length=b.readUInt32LE(12),j=JSON.parse(b.subarray(20,20+length));delete j.images;delete j.textures;stripTextures(j.materials);
  let json=Buffer.from(JSON.stringify(j));json=Buffer.concat([json,Buffer.alloc((4-json.length%4)%4,32)]);const bin=b.subarray(20+length),clean=Buffer.alloc(20+json.length+bin.length);clean.writeUInt32LE(0x46546c67,0);clean.writeUInt32LE(2,4);clean.writeUInt32LE(clean.length,8);clean.writeUInt32LE(json.length,12);clean.writeUInt32LE(0x4e4f534a,16);json.copy(clean,20);bin.copy(clean,20+json.length);
  return new GLTFLoader().parseAsync(clean.buffer.slice(clean.byteOffset,clean.byteOffset+clean.byteLength),'');
 }}},{fetchJSON:async url=>JSON.parse(fs.readFileSync(path.resolve(web,url),'utf8'))});
 check(photoLibrary.errors.length===0,'all configured photo assets load after Draco fallback');
 check(photoLoads===photoLibrary.assets.size*3,'each photo asset/LOD parsed once for all bindings');
 fs.writeFileSync(path.join(temp,'StaticAssets.mjs'),fs.readFileSync(path.join(web,'static_assets.js'),'utf8').replaceAll("from 'three'",`from '${threeURL}'`));
 const {StaticAssetInstance}=await import(pathToFileURL(path.join(temp,'StaticAssets.mjs')));
 const originalGLB=fs.readFileSync(path.join(web,'assets/'+(process.env.PHOTO_TEST_BUILDING||'building.glb'))),jsonLength=originalGLB.readUInt32LE(12),sourceJSON=JSON.parse(originalGLB.subarray(20,20+jsonLength));
 const gltfJSON=structuredClone(sourceJSON);delete gltfJSON.images;delete gltfJSON.textures;
 function stripTextures(value){if(!value||typeof value!=='object')return;for(const k of Object.keys(value)){if(/Texture$/.test(k))delete value[k];else stripTextures(value[k]);}}stripTextures(gltfJSON.materials);
 let json=Buffer.from(JSON.stringify(gltfJSON));json=Buffer.concat([json,Buffer.alloc((4-json.length%4)%4,32)]);const bin=originalGLB.subarray(20+jsonLength);const buffer=Buffer.alloc(20+json.length+bin.length);buffer.writeUInt32LE(0x46546c67,0);buffer.writeUInt32LE(2,4);buffer.writeUInt32LE(buffer.length,8);buffer.writeUInt32LE(json.length,12);buffer.writeUInt32LE(0x4e4f534a,16);json.copy(buffer,20);bin.copy(buffer,20+json.length);
 const loaded=await new GLTFLoader().parseAsync(buffer.buffer.slice(buffer.byteOffset,buffer.byteOffset+buffer.byteLength),'');
 let sourceMeshes=0,sourceNodes=0;loaded.scene.traverse(o=>{sourceNodes++;if(o.isMesh)sourceMeshes++;});check(sourceMeshes>1000,'actual source GLB meshes parsed');check(sourceNodes>1000,'actual source GLB hierarchy parsed');
 class Element{
  constructor(tag='div'){this.tagName=tag.toUpperCase();this.style={};this.children=[];this.hidden=false;this.value='';this.listeners={};this.classList={toggle(){},add(){},remove(){}};}
  get options(){return this.children;}append(...items){this.children.push(...items);}add(x){this.append(x);}replaceChildren(...x){this.children=[...x];}setAttribute(k,v){this[k]=v;}addEventListener(k,fn){(this.listeners[k]??=[]).push(fn);}focus(){}setPointerCapture(){}hasPointerCapture(){return false;}releasePointerCapture(){}getBoundingClientRect(){return {x:0,y:0,left:0,top:0,width:120,height:120};}getContext(){return {fillRect(){},strokeRect(){},fillText(){}};}showModal(){this.open=true;}close(){this.open=false;}
 }
 const documentListeners={},windowListeners={};
 const emit=(listeners,type)=>{for(const fn of listeners[type]||[])fn({});};
 const elements=new Map(),document={body:new Element(),hidden:false,activeElement:null,getElementById:id=>{if(!elements.has(id))elements.set(id,new Element(id==='scene'?'canvas':'div'));return elements.get(id);},createElement:tag=>new Element(tag),createTextNode:text=>({textContent:text}),querySelector:()=>null,addEventListener(type,fn){(documentListeners[type]??=[]).push(fn);}};
 const errors=[];class Renderer{constructor(){this.shadowMap={};this.info={render:{calls:0,triangles:0}};}setPixelRatio(){}setClearColor(){}setSize(){}render(){}}
 class PMREM{fromScene(){return {texture:new RealThree.Texture()};}dispose(){}}
 class RoomEnvironment extends RealThree.Group{dispose(){}}
 class Orbit{addEventListener(){}constructor(camera){this.target=new RealThree.Vector3();this.camera=camera;}update(){this.camera.lookAt(this.target);const changed=this.changed;this.changed=false;return changed;}dispose(){}}
 let clockNow=0;
 const context=vm.createContext({performance:{now:()=>clockNow},THREE:{...RealThree,WebGLRenderer:Renderer,PMREMGenerator:PMREM},...photoModule,...photoPlacement,...photoMaterials,REVIEW_ANCHOR,createWorkstationReview,loadReviewCandidates:async()=>({assets:new Map(),errors:[]}),...spatialModule,...collision,createSpatialPresentation,createDeskInspectionProxy,createRenderGate,frameTimeSteps,mergeGeometries,OrbitControls:Orbit,RoomEnvironment,GLTFLoader:class{async loadAsync(){return {scene:loaded.scene};}},loadFloorMaterialLibrary:async()=>({tile:new RealThree.MeshStandardMaterial()}),loadChairAssets:async()=>null,loadStaticAssets:async()=>new Map(),loadPhotoSceneAssets:async()=>photoLibrary,createModelLoader:()=>({dispose(){}}),ChairInstances:class{},StaticAssetInstance,document,Option:class extends Element{constructor(text,value){super('option');this.textContent=text;this.value=value;}},console:{log(){},warn(){},error:e=>errors.push(String(e.stack||e))},URLSearchParams,location:{search:'?floor=4',reload(){}},history:{replaceState(){}},matchMedia:()=>({matches:false}),innerWidth:1280,innerHeight:800,devicePixelRatio:1,requestAnimationFrame(){},Event:class{},fetch:async url=>({ok:true,json:async()=>JSON.parse(fs.readFileSync(path.resolve(web,url),'utf8'))})});
 context.window=context;context.addEventListener=(type,fn)=>{(windowListeners[type]??=[]).push(fn);};context.dispatchEvent=()=>{};
 vm.runInContext(fs.readFileSync(path.join(web,'spatial_overlay.js'),'utf8').replaceAll('export function','function'),context,{filename:'spatial_overlay.js'});
 const viewer=fs.readFileSync(path.join(web,'viewer.js'),'utf8').replace(/^import .*;\n/gm,'').replace(/\nstart\(\);\s*$/,'');
 vm.runInContext(viewer+'\nglobalThis.integration={orbit,start,frame,renderGate,spatialAction,enterWalk,openSpatialObject,exitInspect,setOverview,resize,frame,toggleDesk,animateDesks,objectBounds,roots,spatialRoots,get state(){return state},get spatial(){return spatial},get catalog(){return spatialCatalog},get layout(){return layout},get camera(){return camera},get orbit(){return orbit},keys,get savedWalk(){return savedWalk},get toolRoots(){return toolRoots},get deskRoots(){return deskRoots}};',context,{filename:'viewer.js'});
 const api=context.integration;await api.start();check(errors.length===0,'viewer startup errors: '+errors.join('\n'));check(context.flcReview.snapshot().ready,'viewer reaches ready using source GLB');
 api.frame(1000);const initialDraws=context.flcReview.snapshot().renderedFrames;api.frame(1016);api.frame(1032);check(context.flcReview.snapshot().renderedFrames===initialDraws,'idle RAF advances without repeated WebGL submission');api.resize();api.frame(1048);check(context.flcReview.snapshot().renderedFrames===initialDraws+1,'resize invalidates the next draw');api.orbit.changed=true;api.frame(1064);check(context.flcReview.snapshot().renderedFrames===initialDraws+2,'Orbit update change keeps damping/animation frames drawing');api.frame(1080);check(context.flcReview.snapshot().renderedFrames===initialDraws+2,'settled Orbit update stops drawing');
 if(process.env.PHOTO_TEST_BUILDING==='building.web.glb')check(context.flcReview.photoAssets().static.length===7,'real web GLB binds original pantry assets plus two single seats and workshop composition');
 const photos=api.deskRoots.filter(d=>d.userData.photoBinding);check(photos.length===40,'exact forty existing 3F desks receive photo desktop parts');
 check(api.deskRoots.filter(d=>d.userData.floor!=='3').every(d=>!d.userData.photoBinding),'2F and 4F remain unchanged');
 check(photos.every(d=>d.scale.toArray().every(v=>Math.abs(v-1)<1e-6)),'photo desktops have no extra parent scaling');
 check(photos.every(d=>d.userData.parts.filter(p=>p.asset).every(p=>p.factor===1)),'every photo LOD follows full tabletop lift');
 const mouse=photoLibrary.assets.get('photo_mouse'),mb=new RealThree.Box3();for(const p of mouse.levels[0]){p.geometry.computeBoundingBox();mb.union(p.geometry.boundingBox);}
 const ms=mb.getSize(new RealThree.Vector3());check(Math.abs(ms.x-.0635)<.0001&&Math.abs(ms.y-.040)<.0001&&Math.abs(ms.z-.125)<.0001,'actual decoded corrected GPX mesh retains 63.5×40×125 mm');
 const finishes=photos.map(d=>d.userData.parts.find(p=>p.batch.material.name==='Photo pale warm wood tabletop'));
 check(finishes.every(Boolean),'all photo-bound desktops have warm wood finish');check(finishes[0].batch.material===finishes[1].batch.material,'tabletop finish shared across desk instances');
 check(api.deskRoots.filter(d=>d.userData.floor!=='3').every(d=>d.userData.parts.every(p=>p.batch.material.name!=='Photo pale warm wood tabletop')),'unbound floor desktop materials unchanged');
 const fridge=api.toolRoots.find(o=>o.userData.photoBinding==='pantry/fridge');check(!!fridge,'photo fridge binds existing six-part appliance');
 const fridgeBox=new RealThree.Box3().setFromObject(fridge),fridgeCollider=api.layout.floors['3'].colliders.find(c=>c.id==='Refrigerator').rect;
 check(fridgeBox.min.x>=fridgeCollider[0]-.00001&&fridgeBox.max.x<=fridgeCollider[2]+.00001&&fridgeBox.min.z>=fridgeCollider[1]-.00001&&fridgeBox.max.z<=fridgeCollider[3]+.00001,'every fridge LOD stays inside updated exact collision proxy');
 const eastInner=api.layout.floors['3'].rooms.find(r=>r.id==='pantry').bounds[2]-.05;
 check(Math.abs(eastInner-fridgeBox.max.x-.009)<.0001,'fridge has 9 mm model clearance from east wall');
 check(collision.canStand(api.layout,'3',16.6,40.9),'fridge front approach remains navigable');
 check(!collision.canStand(api.layout,'3',16.6,41.7),'new fridge body remains impassable');
 const fridgePosition=fridge.position.clone();api.spatialAction({type:'EXPAND'});api.spatialAction({type:'SELECT_FLOOR',floor:'3'});check(fridge.position.equals(fridgePosition),'expanded-floor round trip does not accumulate fridge placement offset');api.spatialAction({type:'SELECT_FLOOR',floor:'4'});
 const pantry=api.layout.floors['3'].rooms.find(r=>r.id==='pantry');
 for(const appliance of api.toolRoots.filter(o=>['pantry/photo_pantry_grey_roundfront_appliance','pantry/photo_pantry_white_cleartop_appliance'].includes(o.userData.photoBinding))){
  const b=new RealThree.Box3().setFromObject(appliance);check(Math.abs(b.min.y-(4.050000190734863+.92))<.001,'photo appliance bottom sits on actual countertop');
  check(b.min.x>=10.8263&&b.max.x<=15.7264&&b.min.z>=41.5362&&b.max.z<=42.2764,'all appliance LODs fit existing countertop plan');
 }
 check(photos[0].userData.parts.find(p=>p.asset==='photo_mouse').geometry===photos[1].userData.parts.find(p=>p.asset==='photo_mouse').geometry,'photo meshes are shared between workstations');
 const physicalBefore=JSON.stringify(api.layout),ids=Object.keys(api.catalog.objects);
 check(ids.length===api.toolRoots.length+api.deskRoots.length&&ids.length>0,'all real inspectable tools and desks registered');check(new Set(ids).size===ids.length,'no duplicate object IDs');check(ids.every(id=>api.spatialRoots.has(id)),'all registered object IDs map to real roots');check(Object.values(api.catalog.objects).every(o=>o.sourceNodeName),'every registered object has source name');const names=new Set();loaded.scene.traverse(o=>names.add(o.name));check(Object.values(api.catalog.objects).every(o=>names.has(o.sourceNodeName)),'registered IDs derive from actual parsed GLB node names');
 api.spatialAction({type:'EXPAND'});check(api.spatial.scope==='building'&&api.spatial.expanded,'4F to expanded building');check([...api.roots].every(([f,r])=>r.visible&&r.position.y>api.layout.floors[f].elevation),'display-only floor offsets applied');
 const expanded3=context.flcReview.spatial().displayFloors.find(f=>f.floor==='3');check(expanded3.y!==expanded3.sourceY&&expanded3.sourceY===4.050000190734863,'source snapshot stays independent while display is translated');check(Object.isFrozen(api.roots.get('3').userData.sourcePosition),'source transform snapshot immutable');
 api.spatialAction({type:'SELECT_FLOOR',floor:'3'});check(!api.spatial.expanded&&api.state.floor==='3','select 3F collapses display');
 const actual3=context.flcReview.spatial().displayFloors.find(f=>f.floor==='3');check(actual3.sourceY===4.050000190734863,'source GLB Float32 elevation retained separately from decimal design JSON');check(actual3.y===actual3.sourceY,'collapse strictly restores authored source elevation without tolerance');
 api.spatialAction({type:'SELECT_ROOM',room:'xlab'});check(api.spatial.scope==='room'&&api.state.room==='xlab','focus source lab room');
 const desk=Object.values(api.catalog.objects).find(o=>o.floor==='3'&&o.room==='xlab'&&o.kind==='desk');check(!!desk,'actual lab contains registered desk');
 const deskNode=api.spatialRoots.get(desk.id),originalDeskBounds=api.objectBounds(deskNode).clone();api.toggleDesk(deskNode);const activeDraws=context.flcReview.snapshot().renderedFrames;api.frame(1100);check(context.flcReview.snapshot().renderedFrames===activeDraws+1,'active desk animation submits an updated frame');api.animateDesks(10);check(Math.abs(deskNode.userData.currentHeight-1.10)<1e-8,'existing desk rises to standing height');check(api.objectBounds(deskNode).max.y>originalDeskBounds.max.y+.3,'instanced desk bounds track physical upper parts');api.toggleDesk(deskNode);api.animateDesks(10);check(Math.abs(deskNode.userData.currentHeight-.73)<1e-8,'existing desk returns to seated height');
 api.camera.position.set(100,100,100);api.frame(1200);check(deskNode.userData.photoLevel===2,'far desk starts at LOD2 before inspection');
 const priorCamera=api.camera.position.clone();api.openSpatialObject(desk.id);api.frame(1216);check(api.spatial.scope==='object'&&api.spatial.object===desk.id,'lab desk inspection selects stable ID');check(api.camera.position.toArray().every(Number.isFinite),'desk bounds produce finite close camera');
 const proxy=api.savedWalk.inspectionProxy;check(proxy.root.children.every(mesh=>Math.abs(mesh.matrix.determinant())>.99),'first inspection frame has nonzero matrices after LOD2 to LOD0');api.frame(1232);check(proxy.root.children.every(mesh=>Math.abs(mesh.matrix.determinant())>.99),'idle inspection retains visible photo components without further input');check(!!proxy&&proxy.root.children.length===deskNode.userData.parts.filter(p=>p.level===undefined||p.level===0).length,'close view contains only selected desk parts');check(proxy.root.children.every((mesh,i)=>mesh.geometry===deskNode.userData.parts.filter(p=>p.level===undefined||p.level===0)[i].batch.geometry&&mesh.material===deskNode.userData.parts.filter(p=>p.level===undefined||p.level===0)[i].batch.material),'proxy borrows source geometry/material without cloning');check(api.roots.get('3').children.filter(n=>n!==proxy.root&&n!==deskNode&&n.userData.kind!=='floor').every(n=>!n.visible),'surrounding meshes hidden during desk close view');
 let disposedResources=0;const borrowed=new Set(proxy.root.children.flatMap(m=>[m.geometry,m.material]));for(const r of borrowed)r.addEventListener('dispose',()=>disposedResources++);const originalProxyY=new RealThree.Box3().setFromObject(proxy.root).max.y;api.toggleDesk(deskNode);api.animateDesks(10);proxy.update();check(new RealThree.Box3().setFromObject(proxy.root).max.y>originalProxyY+.3,'inspection proxy follows existing desk animation');api.toggleDesk(deskNode);api.animateDesks(10);proxy.update();api.resize();check(api.camera.position.toArray().every(Number.isFinite),'resize while inspecting actual desk remains finite');
 api.spatialAction({type:'BACK'});check(api.spatial.scope==='room'&&api.state.room==='xlab'&&!api.state.inspect,'single Back exits object, not room');check(api.camera.position.distanceTo(priorCamera)<1e-8,'inspection restores exact pre-inspection camera');check(proxy.root.parent===null&&proxy.root.children.length===0,'exit removes temporary proxy');check(disposedResources===0,'exit never destroys borrowed model resources');check(deskNode.userData.parts.every(part=>part.batch.visible),'source instanced desk batches restored');
 api.spatialAction({type:'SELECT_FLOOR',floor:'2'});api.enterWalk();check(api.state.mode==='walk'&&api.spatial.floor==='2','existing 2F walkthrough entry remains');api.frame(2000);const walkDraws=context.flcReview.snapshot().renderedFrames;api.keys.add('KeyS');api.frame(2016);check(context.flcReview.snapshot().renderedFrames===walkDraws+1,'held walking input draws');api.keys.clear();api.frame(2032);check(context.flcReview.snapshot().renderedFrames===walkDraws+1,'stationary walk retains input loop without drawing');
 const walkingPosition=[...api.state.pos],walkingTool=api.toolRoots.find(t=>t.userData.floor==='2');check(!!walkingTool,'actual 2F inspectable source tool');api.openSpatialObject(walkingTool.userData.spatialId);api.exitInspect();check(api.state.mode==='walk'&&api.state.pos.every((n,i)=>n===walkingPosition[i]),'walk inspection restores observer position');
 api.setOverview();api.spatialAction({type:'BACK'});check(api.state.mode==='overview','back does not reenter walking');
 api.spatialAction({type:'SELECT_FLOOR',floor:'1'});api.enterWalk();check(api.state.floor==='1'&&api.state.mode==='overview','1F never enters walkthrough');check(context.flcReview.spatial().placeholderVisible,'1F shows explicit pending placeholder');check([...api.roots].every(([,r])=>!r.visible),'1F does not expose invented floor geometry');
 for(let n=0;n<5;n++){api.spatialAction({type:'EXPAND'});api.spatialAction({type:'SELECT_FLOOR',floor:'3'});api.spatialAction({type:'SELECT_ROOM',room:'xlab'});api.openSpatialObject(desk.id);api.exitInspect();check(api.spatial.scope==='room'&&api.spatial.room==='xlab'&&!api.state.inspect,'repeat inspect/cancel roundtrip');}
 api.openSpatialObject(desk.id);api.spatialAction({type:'SELECT_FLOOR',floor:'4'});check(!api.state.inspect&&api.savedWalk===null&&api.spatial.floor==='4','switch floor while inspecting clears saved object state');api.enterWalk();check(api.state.mode==='overview','office floor does not enter interior walkthrough');check(context.flcReview.spatial().posterCount===3,'three explicit corridor poster placeholders');
 for(let n=0;n<3;n++){
  elements.get('workstation-review').onclick();api.frame(3000+n*100);
  check(context.flcReview.workstation().panelParts===2,'real loader preserves two panel identities');
  check(api.state.room==='studio_1'&&api.state.floor==='3','review uses existing studio 1, never claims 304');
  check(api.roots.get('3').children.some(c=>c.visible&&c.userData.kind==='wall'),'review preserves actual room walls');
  elements.get('review-width').value='.675';elements.get('review-width').oninput();check(context.flcReview.workstation().settings.width===.675,'DOM input handler changes temporary panel');
  elements.get('review-lift').onclick();api.animateDesks(10);api.frame(3050+n*100);check(context.flcReview.workstation().height===1.10,'review lift follows real animation');
  api.exitInspect();check(context.flcReview.workstation()===null,'review session cleared');check(api.spatialRoots.get(REVIEW_ANCHOR).userData.currentHeight===.73,'review restores selected desk initial height');
 }
 for(const origin of [{floor:'4',room:'seminar_1',walk:false},{floor:'3',room:'xlab',walk:false},{floor:'2',room:'',walk:true}]){
  api.spatialAction({type:'SELECT_FLOOR',floor:origin.floor});if(origin.room)api.spatialAction({type:'SELECT_ROOM',room:origin.room});if(origin.walk)api.enterWalk();
  const before={floor:api.state.floor,room:api.state.room,mode:api.state.mode,camera:api.camera.position.clone(),target:api.orbit.target.clone(),position:[...api.state.pos]};
  elements.get('workstation-review').onclick();api.frame(4500);api.exitInspect();
  check(api.state.floor===before.floor&&api.state.room===before.room&&api.state.mode===before.mode,'review exit restores foreign floor room and mode');check(api.camera.position.distanceTo(before.camera)<1e-8&&api.orbit.target.distanceTo(before.target)<1e-8,'review exit restores foreign camera target');check(api.state.pos.every((v,k)=>v===before.position[k]),'review preserves walking observer');
 }
 // Real viewer RAF path: low frame rate must not stretch a 3.083s lift to 124s.
 api.spatialAction({type:'SELECT_FLOOR',floor:'3'});api.spatialAction({type:'SELECT_ROOM',room:'xlab'});
 const timedDesk=deskNode.userData;
 let now=10000;emit(windowListeners,'focus');api.frame(now);
 for(let cycle=0;cycle<3;cycle++){
  api.enterWalk();check(api.state.mode==='walk','timing cycle enters walk');
  clockNow=now;api.toggleDesk(deskNode);now+=1000;api.frame(now);
  check(Math.abs(timedDesk.currentHeight-.85)<1e-8,'one active second moves desk 12cm');
  elements.get('overview').onclick();
  check(api.state.mode==='overview'&&timedDesk.currentHeight<timedDesk.targetHeight,'ordinary overview handler exits immediately during lift');
  now+=2000;api.frame(now);check(Math.abs(timedDesk.currentHeight-1.09)<1e-8,'two-second RAF gap uses wall time');
  now+=100;api.frame(now);check(timedDesk.currentHeight===1.10,'desk reaches exact standing terminal after overview exit');
  clockNow=now;api.toggleDesk(deskNode);now+=1000;api.frame(now);
  check(Math.abs(timedDesk.currentHeight-.98)<1e-8,'reverse starts at current height');
  clockNow=now;api.toggleDesk(deskNode);now+=1000;api.frame(now);check(timedDesk.currentHeight===1.10,'mid-flight target reversal reaches exact terminal');
  clockNow=now;api.toggleDesk(deskNode);now+=2000;api.frame(now);now+=2000;api.frame(now);
  check(timedDesk.currentHeight===.73,'repeated cycle returns to exact seated terminal');
 }
 clockNow=now;api.toggleDesk(deskNode);now+=1000;api.frame(now);const beforePause=timedDesk.currentHeight;
 document.hidden=true;emit(documentListeners,'visibilitychange');now+=30000;api.frame(now);
 check(timedDesk.currentHeight===beforePause,'hidden frame does not animate');
 document.hidden=false;emit(documentListeners,'visibilitychange');now+=30000;api.frame(now);
 check(timedDesk.currentHeight===beforePause,'visibility resume first frame has no catch-up jump');
 now+=1000;api.frame(now);check(Math.abs(timedDesk.currentHeight-beforePause-.12)<1e-8,'visible animation resumes at authored speed');
 emit(windowListeners,'blur');const beforeBlur=timedDesk.currentHeight;now+=30000;api.frame(now);
 check(timedDesk.currentHeight===beforeBlur,'visible but blurred window pauses desk animation through a 30s gap');
 const pausedDraws=context.flcReview.snapshot().renderedFrames;
 const pausedMatrixVersions=timedDesk.parts.map(part=>part.batch.instanceMatrix.version);
 now+=2000;api.frame(now);
 check(context.flcReview.snapshot().renderedFrames===pausedDraws,'paused desk does not invalidate an otherwise idle visible frame');
 check(timedDesk.parts.every((part,i)=>part.batch.instanceMatrix.version===pausedMatrixVersions[i]),'paused desk does not rewrite instance matrices');

 emit(windowListeners,'focus');now+=30000;api.frame(now);check(timedDesk.currentHeight===beforeBlur,'focus resume first frame has no catch-up jump');
 now+=60000;api.frame(now);check(timedDesk.currentHeight===1.10,'foreground 60s gap after resume reaches exact target; duration alone cannot imply suspension');
 clockNow=now;api.toggleDesk(deskNode);now+=4000;api.frame(now);check(timedDesk.currentHeight===.73,'reset seated before 60fps run');
 clockNow=now;api.toggleDesk(deskNode);const sixtyStart=now;let sixtyFrames=0;
 while(timedDesk.currentHeight<1.10-.0001&&sixtyFrames<200){sixtyFrames++;now=sixtyStart+sixtyFrames*1000/60;api.frame(now);}
 check(Math.abs(now-sixtyStart-3083.3333333333335)<17,'real viewer 60fps lift retains approximately 3.083s duration');
 check(Math.abs(timedDesk.currentHeight-1.10)<.0001,'real viewer 60fps lift preserves standing terminal tolerance');
 // A target selected between slow RAF ticks must not inherit pre-click time.
 clockNow=now;api.toggleDesk(deskNode);now+=4000;api.frame(now);
 check(timedDesk.currentHeight===.73,'seated before between-frame click');
 clockNow=now+1900;api.toggleDesk(deskNode);now+=2000;api.frame(now);
 check(Math.abs(timedDesk.currentHeight-.742)<1e-8,'click 1900ms into 2000ms RAF gap receives only 100ms');
 clockNow=now+1900;api.toggleDesk(deskNode);now+=2000;api.frame(now);
 check(Math.abs(timedDesk.currentHeight-.73)<1e-8,'between-frame reversal applies only post-click time to new target');
 const otherDesk=api.deskRoots.find(d=>d!==deskNode);clockNow=now;api.toggleDesk(otherDesk);
 clockNow=now+1900;api.toggleDesk(deskNode);now+=2000;api.frame(now);
 check(Math.abs(otherDesk.userData.currentHeight-.97)<1e-8&&Math.abs(timedDesk.currentHeight-.742)<1e-8,'each desk owns its own target start time');
 // Long foreground frames are real elapsed time, not implicit pause signals.
 // Keep the target-change timestamp independent of the preceding RAF.
 clockNow=now;api.toggleDesk(deskNode);now+=4000;api.frame(now);
 check(timedDesk.currentHeight===.73,'seated before long-frame timing cases');
 for(const gap of [6000,10000,30000]){
  clockNow=now;api.toggleDesk(deskNode);now+=gap;api.frame(now);
  check(timedDesk.currentHeight===1.10,'foreground '+gap+'ms lift reaches exact standing target');
  clockNow=now;api.toggleDesk(deskNode);now+=gap;api.frame(now);
  check(timedDesk.currentHeight===.73,'foreground '+gap+'ms lowering reaches exact seated target');
  clockNow=now+gap-100;api.toggleDesk(deskNode);now+=gap;api.frame(now);
  check(Math.abs(timedDesk.currentHeight-.742)<1e-8,'late click in '+gap+'ms frame receives only post-click 100ms');
  clockNow=now+gap-50;api.toggleDesk(deskNode);now+=gap;api.frame(now);
  check(Math.abs(timedDesk.currentHeight-.736)<1e-8,'late reversal in '+gap+'ms frame receives only post-click 50ms');
  now+=100;api.frame(now);check(timedDesk.currentHeight===.73,'late reversal clamps at exact seated target');
  for(const pause of ['hidden','blur']){
   clockNow=now;api.toggleDesk(deskNode);now+=1000;api.frame(now);
   const height=timedDesk.currentHeight;
   if(pause==='hidden'){document.hidden=true;emit(documentListeners,'visibilitychange');}else emit(windowListeners,'blur');
   now+=gap;api.frame(now);check(timedDesk.currentHeight===height,pause+' '+gap+'ms gap does not animate');
   const draws=context.flcReview.snapshot().renderedFrames,versions=timedDesk.parts.map(part=>part.batch.instanceMatrix.version);
   now+=gap;api.frame(now);
   check(context.flcReview.snapshot().renderedFrames===draws,pause+' repeated long frame does not dirty render');
   check(timedDesk.parts.every((part,i)=>part.batch.instanceMatrix.version===versions[i]),pause+' repeated long frame does not write matrices');
   if(pause==='hidden'){document.hidden=false;emit(documentListeners,'visibilitychange');}else emit(windowListeners,'focus');
   now+=gap;api.frame(now);check(timedDesk.currentHeight===height,pause+' resume first frame discards gap');
   now+=gap;api.frame(now);check(timedDesk.currentHeight===1.10,pause+' next foreground frame reaches exact target');
   clockNow=now;api.toggleDesk(deskNode);now+=gap;api.frame(now);
   check(timedDesk.currentHeight===.73,pause+' case restores exact seated target');
  }
 }
 api.enterWalk();clockNow=now;api.toggleDesk(deskNode);now+=1000;api.frame(now);
 elements.get('overview').onclick();
 check(api.state.mode==='overview'&&timedDesk.currentHeight<timedDesk.targetHeight,'ordinary overview exit remains immediate before long foreground frame');
 now+=10000;api.frame(now);check(timedDesk.currentHeight===1.10,'unfinished lift reaches exact target after overview exit and 10s foreground frame');
 api.enterWalk();let measuredMove=null;const realMove=context.moveBody;context.moveBody=(...args)=>{measuredMove=Math.hypot(args[3],args[4]);return realMove(...args);};
 api.keys.add('KeyW');now+=30000;api.frame(now);api.keys.clear();context.moveBody=realMove;
 check(Math.abs(measuredMove-api.layout.speed*.05)<1e-8,'real moveBody displacement still uses 50ms collision dt at thirty-second foreground RAF');
 api.setOverview();
 check(fs.readFileSync(path.join(web,'assets/'+(process.env.PHOTO_TEST_BUILDING||'building.glb'))).equals(originalGLB),'source GLB bytes untouched');check(JSON.stringify(api.layout)===physicalBefore,'source layout/colliders untouched by viewer actions');check(JSON.stringify(Object.keys(api.catalog.objects))===JSON.stringify(ids),'object identities stable across selection');check(errors.length===0,'no later logged exceptions');
 console.log(JSON.stringify({passed,sourceNodes,sourceMeshes,registeredObjects:ids.length,scope:'Actual '+(process.env.PHOTO_TEST_BUILDING||'building.glb')+' hierarchy/geometry and viewer state integration in Node VM. Renderer, DOM, network and chair/static generated assets mocked; photo assets use actual uncompressed GLBs via forced Draco fallback; embedded textures stripped in memory. NOT browser/GPU/pointer acceptance.'},null,2));
}finally{fs.rmSync(temp,{recursive:true,force:true});}
