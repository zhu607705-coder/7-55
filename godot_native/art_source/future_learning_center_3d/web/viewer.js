import * as THREE from 'three';
import {OrbitControls} from 'three/addons/controls/OrbitControls.js';
import {RoomEnvironment} from 'three/addons/environments/RoomEnvironment.js';
import {GLTFLoader} from 'three/addons/loaders/GLTFLoader.js';
import {mergeGeometries} from 'three/addons/utils/BufferGeometryUtils.js';
import {buildSpatialCatalog,withSpatialObjects,spatialObjectId,createSpatialState,reduceSpatialState,validateExhibitionConfig} from './spatial_catalog.js';
import {createSpatialPresentation} from './spatial_presentation.js';
import {createDeskInspectionProxy} from './desk_inspection.js';
import {createSpatialOverlay} from './spatial_overlay.js';
import {loadFloorMaterialLibrary} from './floor_materials.js';
import {canStand,moveBody,nearestSafe} from './collision.js';
import {loadChairAssets,ChairInstances} from './chair_assets.js';
import {createModelLoader} from './model_loader.js';
import {loadStaticAssets,StaticAssetInstance} from './static_assets.js';
const $=id=>document.getElementById(id),canvas=$('scene');
const params=new URLSearchParams(location.search),reduced=matchMedia('(prefers-reduced-motion: reduce)').matches;
const state={floor:['1','2','3','4'].includes(params.get('floor'))?params.get('floor'):'4',room:params.get('room')||'',mode:'overview',exploded:false,pos:[0,0],yaw:0,pitch:0,inspect:null,finishes:{'2':'warm_gray_fine','3':'warm_gray_fine','4':'warm_gray_fine'}};
if(params.get('finish')==='light_gray_tile')state.finishes[state.floor]='light_gray_tile';
let layout,catalog,floorLibrary,renderer,scene,camera,orbit,loaded=false,roots=new Map(),selection,look=null,lastTime=0;
let renderedFrames=0,lastFrameGapMs=0,lastRenderMs=0;
let spatialCatalog,spatial,exhibitions,presentation,overlay,placeholder,inspectedRoot=null;
const spatialRoots=new Map();
const keys=new Set(),joy={x:0,y:0,pointer:null};let savedWalk=null,toolRoots=[],deskRoots=[];
let chairLibrary=null;const chairSystems=[];
let staticLibrary=new Map();const staticInstances=[];
const raycaster=new THREE.Raycaster(),pointer=new THREE.Vector2();
function failure(text) {$('loading').hidden=false;$('loading-text').textContent=text;$('retry').hidden=false;stopInput();}
$('retry').onclick=()=>location.reload();
async function start(){
 try{
  [layout,catalog]=await Promise.all(['layout.json','asset_catalog.json'].map(async path=>{const r=await fetch('./assets/'+path);if(!r.ok)throw Error(path+' '+r.status);return r.json();}));
  spatialCatalog=buildSpatialCatalog(layout);
  if(!spatialCatalog.floors[state.floor].rooms.some(r=>r.sourceRoomId===state.room))state.room='';
  spatial=createSpatialState(spatialCatalog,{floor:state.floor,room:state.room,expanded:params.get('view')==='building'||!params.has('floor')});state.exploded=spatial.expanded;
  try{const response=await fetch('./assets/exhibition_config.json');if(!response.ok)throw Error('exhibition config unavailable');exhibitions=await response.json();validateExhibitionConfig(exhibitions,spatialCatalog);}catch(error){console.warn(error);exhibitions={schemaVersion:1,teams:[],exhibits:[],roomAssignments:[],unavailable:true};}
  renderer=new THREE.WebGLRenderer({canvas,antialias:true,alpha:false});renderer.setPixelRatio(Math.min(devicePixelRatio,2));renderer.setClearColor('#e2e7e3');renderer.outputColorSpace=THREE.SRGBColorSpace;renderer.toneMapping=THREE.ACESFilmicToneMapping;renderer.toneMappingExposure=1.15;renderer.localClippingEnabled=true;
  renderer.shadowMap.enabled=true;renderer.shadowMap.type=THREE.PCFSoftShadowMap;
  scene=new THREE.Scene();camera=new THREE.PerspectiveCamera(46,innerWidth/innerHeight,.04,350);orbit=new OrbitControls(camera,canvas);orbit.enableDamping=!reduced;orbit.maxPolarAngle=Math.PI*.48;orbit.minDistance=.1;orbit.maxDistance=110;
  // Neutral interior reflections keep foil and satin metal readable. The PMREM
  // is local, shared and generated once; no remote HDR or baked highlight map.
  const roomEnvironment=new RoomEnvironment(),pmrem=new THREE.PMREMGenerator(renderer);
  scene.environment=pmrem.fromScene(roomEnvironment,.04).texture;scene.environmentIntensity=.20;
  roomEnvironment.dispose();pmrem.dispose();
  scene.add(new THREE.HemisphereLight(0xeef6ff,0xb8bbb3,2.2));
  const sun=new THREE.DirectionalLight(0xfff1dc,3.4);sun.position.set(-18,42,12);sun.castShadow=true;sun.shadow.mapSize.set(2048,2048);sun.shadow.camera.left=-42;sun.shadow.camera.right=42;sun.shadow.camera.top=45;sun.shadow.camera.bottom=-45;sun.shadow.camera.far=100;sun.shadow.normalBias=.035;sun.shadow.bias=-.00015;sun.target.position.set(13,4,20);scene.add(sun,sun.target);
  floorLibrary=await loadFloorMaterialLibrary(renderer);
  const codec=createModelLoader();try{[chairLibrary,staticLibrary]=await Promise.all([
   loadChairAssets(params.get('chair')==='authored'?'authored':'hyper3d',codec),loadStaticAssets(codec)
  ]);}finally{codec.dispose();}
  let gltf;try{gltf=await new GLTFLoader().loadAsync(chairLibrary?'./assets/building.web.glb':'./assets/building.glb');}catch(error){chairLibrary=null;gltf=await new GLTFLoader().loadAsync('./assets/building.glb');}gltf.scene.updateMatrixWorld(true);
  gltf.scene.traverse(obj=>{if(obj.userData.floorRoot){const root=new THREE.Group();root.name='Floor '+obj.userData.floorRoot;root.position.copy(obj.position);root.userData.sourcePosition=Object.freeze(root.position.toArray());root.userData.floor=String(obj.userData.floorRoot);roots.set(String(obj.userData.floorRoot),root);scene.add(root);optimizeFloor(obj,root);}});
  if(roots.size!==3)throw Error('Missing floor roots');
  for(const [floor,root] of roots)for(const mesh of root.children)if(mesh.isMesh&&mesh.userData.kind==='floor'){mesh.userData.originalFloorMaterial=mesh.material;mesh.material=state.finishes[floor]==='light_gray_tile'?floorLibrary.tile:mesh.userData.originalFloorMaterial;}
  registerSpatialObjects();
  placeholder=createPendingFloor();scene.add(placeholder);
  addCorridorPosters();
  presentation=createSpatialPresentation(THREE,roots,layout);
  overlay=createSpatialOverlay({catalog:spatialCatalog,config:exhibitions,onAction:spatialAction,onObject:id=>openSpatialObject(id)});
  const ground=new THREE.Mesh(new THREE.PlaneGeometry(180,180),new THREE.MeshStandardMaterial({color:0xd8dfd8,roughness:1}));ground.rotation.x=-Math.PI/2;ground.position.set(13,-.3,21);ground.receiveShadow=true;scene.add(ground);
  loaded=true;$('walk').disabled=false;$('loading').hidden=true;$('floor').value=state.floor;populateRooms();setOverview();
  for(const [id,a] of Object.entries(catalog.assets)){const li=document.createElement('li'),link=document.createElement('a');link.href=a.source;link.target='_blank';link.rel='noopener';link.textContent=a.name+'：公开尺寸依据';li.append(link);$('source-list').append(li);}
  if(params.get('mode')==='walk'&&state.floor!=='1')enterWalk();
  resize();requestAnimationFrame(frame);window.dispatchEvent(new Event('viewer-ready'));
 }catch(error){console.error(error);failure('空间加载失败，请重新载入。');}
}
function preparedGeometry(mesh,matrix){
 const g=mesh.geometry.clone();
 for(const key of Object.keys(g.attributes)){
  if(!['position','normal','uv'].includes(key)){g.deleteAttribute(key);continue;}
  // Imported GLBs may use normalized integers; merge in one float layout.
  const a=g.getAttribute(key),values=new Float32Array(a.count*a.itemSize);
  for(let i=0;i<a.count;i++)for(let j=0;j<a.itemSize;j++)values[i*a.itemSize+j]=a.getComponent(i,j);
  g.setAttribute(key,new THREE.Float32BufferAttribute(values,a.itemSize));
 }
 if(!g.getAttribute('uv'))g.setAttribute('uv',new THREE.Float32BufferAttribute(new Float32Array(g.getAttribute('position').count*2),2));
 g.applyMatrix4(matrix);return g;
}
function mergeSet(items,parent,kind){
 const buckets=new Map();for(const {mesh,matrix} of items){const mat=Array.isArray(mesh.material)?mesh.material[0]:mesh.material;const key=mat.uuid;if(!buckets.has(key))buckets.set(key,{mat,geometries:[]});buckets.get(key).geometries.push(preparedGeometry(mesh,matrix));}
 for(const {mat,geometries} of buckets.values()){
  const geometry=mergeGeometries(geometries,false);if(!geometry)throw Error('Unable to merge scene geometry');const m=new THREE.Mesh(geometry,mat.clone());m.userData.kind=kind;m.userData.floor=parent.userData.floor;m.castShadow=kind!=='ceiling'&&mat.opacity>.5;m.receiveShadow=true;parent.add(m);for(const g of geometries)g.dispose();
 }
}
function inheritedKind(mesh,root){let owner=mesh;while(owner&&owner!==root){if(owner.userData.kind)return owner.userData.kind;owner=owner.parent;}return 'furniture';}
function optimizeDesk(obj,target,inverse,handled){
 const desk=new THREE.Group();desk.userData={...obj.userData,sourceNodeName:obj.name,assetId:'adjustable_desk',floor:target.userData.floor,currentHeight:.73,targetHeight:.73,parts:[]};
 inverse.clone().multiply(obj.matrixWorld).decompose(desk.position,desk.quaternion,desk.scale);target.add(desk);deskRoots.push(desk);
 const buckets=target.userData.deskBatches??=new Map();
 obj.traverse(mesh=>{if(!mesh.isMesh)return;handled.add(mesh);const mat=Array.isArray(mesh.material)?mesh.material[0]:mesh.material,key=mesh.geometry.uuid+'_'+mat.uuid;
  if(!buckets.has(key))buckets.set(key,{geometry:mesh.geometry,material:mat,entries:[]});
  const entry={desk,factor:Number(mesh.userData.liftFactor||0),control:mesh.userData.deskRole==='control',base:inverse.clone().multiply(mesh.matrixWorld)};
  buckets.get(key).entries.push(entry);desk.userData.parts.push(entry);
 });
}
function finalizeDesks(target){
 for(const {geometry,material,entries} of target.userData.deskBatches?.values()||[]){
  const batch=new THREE.InstancedMesh(geometry,material.clone(),entries.length);batch.userData={kind:'furniture',floor:target.userData.floor,deskEntries:entries};batch.castShadow=true;batch.receiveShadow=true;
  entries.forEach((entry,i)=>{entry.batch=batch;entry.index=i;batch.setMatrixAt(i,entry.base);});batch.instanceMatrix.setUsage(THREE.DynamicDrawUsage);batch.computeBoundingSphere();batch.boundingSphere.radius+=.55;target.add(batch);
 }
 delete target.userData.deskBatches;
}
const liftMatrix=new THREE.Matrix4();
function animateDesks(dt){
 for(const desk of deskRoots){const d=desk.userData,delta=d.targetHeight-d.currentHeight;if(Math.abs(delta)<.0001)continue;d.currentHeight+=Math.sign(delta)*Math.min(Math.abs(delta),.12*dt);
  for(const part of d.parts){liftMatrix.copy(part.base);liftMatrix.elements[13]+=(d.currentHeight-.73)*part.factor;part.batch.setMatrixAt(part.index,liftMatrix);part.batch.instanceMatrix.needsUpdate=true;}
 }
}
function deskControls(){
 camera.updateMatrixWorld();
 return deskRoots.filter(d=>d.userData.floor===state.floor).map(desk=>{
  desk.updateWorldMatrix(true,true);const center=desk.localToWorld(new THREE.Vector3(.48,.683+desk.userData.currentHeight-.73,-.329)),p=center.clone().project(camera);
  return {desk,x:(p.x+1)*innerWidth/2,y:(1-p.y)*innerHeight/2,inFront:p.z>=-1&&p.z<=1&&Math.abs(p.x)<1&&Math.abs(p.y)<1,distance:camera.position.distanceTo(center),height:desk.userData.currentHeight,target:desk.userData.targetHeight};
 });
}
function toggleDesk(desk){stopInput();desk.userData.targetHeight=desk.userData.targetHeight>.9?.73:1.10;canvas.focus({preventScroll:true});}

function optimizeFloor(original,target){
 const inverse=original.matrixWorld.clone().invert(),groups=new Map(),handled=new Set(),chairPlacements=[];let chairReview=false;
 original.traverse(obj=>{
  const slot=staticLibrary.slots?.[obj.userData.staticAssetSlot],asset=slot&&staticLibrary.get(slot.asset);
  if(asset){obj.traverse(child=>{if(child.isMesh)handled.add(child);});
   const anchor=new THREE.Object3D();inverse.clone().multiply(obj.matrixWorld).decompose(anchor.position,anchor.quaternion,anchor.scale);anchor.userData=obj.userData;
   const instance=new StaticAssetInstance(asset,slot,anchor,target);staticInstances.push(instance);instance.root.userData.sourceNodeName=obj.name;toolRoots.push(instance.root);return;
  }
  if(obj.userData.adjustableDesk)optimizeDesk(obj,target,inverse,handled);
  if(!chairReview&&target.userData.floor==='3'&&obj.userData.assetId==='office_chair'){const room=layout.floors['3'].rooms.find(r=>r.id==='studio_1'),p=obj.position;if(p.x>room.bounds[0]&&p.x<room.bounds[2]&&p.z>room.bounds[1]&&p.z<room.bounds[3]){obj.userData.inspectable=true;chairReview=true;}}
  if(chairLibrary&&obj.userData.assetId==='office_chair'){
   obj.traverse(child=>{if(child.isMesh)handled.add(child);});const matrix=inverse.clone().multiply(obj.matrixWorld);
   if(obj.userData.inspectable){const group=chairLibrary.hero();group.userData={...obj.userData,sourceNodeName:obj.name,floor:target.userData.floor};matrix.decompose(group.position,group.quaternion,group.scale);target.add(group);toolRoots.push(group);}else chairPlacements.push(matrix);
   return;
  }
  if(obj.userData.inspectable){const group=new THREE.Group();group.userData={...obj.userData,sourceNodeName:obj.name,floor:target.userData.floor};inverse.clone().multiply(obj.matrixWorld).decompose(group.position,group.quaternion,group.scale);target.add(group);const list=[];const inv=obj.matrixWorld.clone().invert();obj.traverse(child=>{if(child.isMesh){handled.add(child);list.push({mesh:child,matrix:inv.clone().multiply(child.matrixWorld)});}});mergeSet(list,group,'tool');toolRoots.push(group);}
 });
 original.traverse(mesh=>{if(!mesh.isMesh||handled.has(mesh))return;const kind=inheritedKind(mesh,original);if(!groups.has(kind))groups.set(kind,[]);groups.get(kind).push({mesh,matrix:inverse.clone().multiply(mesh.matrixWorld)});});
 for(const [kind,items] of groups)mergeSet(items,target,kind);finalizeDesks(target);
 if(chairPlacements.length)chairSystems.push(new ChairInstances(chairLibrary,target,chairPlacements));
}
function registerSpatialObjects(){
 const descriptors=[];
 for(const node of [...toolRoots,...deskRoots]){
  const floor=String(node.userData.floor),source=node.userData.sourceNodeName;
  if(!source)throw Error('Missing stable source node name');
  const id=spatialObjectId(floor,source),p=node.position;
  const room=layout.floors[floor].rooms.find(r=>p.x>=r.bounds[0]&&p.x<=r.bounds[2]&&p.z>=r.bounds[1]&&p.z<=r.bounds[3]);
  node.userData.spatialId=id;spatialRoots.set(id,node);
  descriptors.push({id,floor,room:room?.id||'',sourceNodeName:source,name:node.userData.adjustableDesk?'可升降工位（原场景）':catalog.assets[node.userData.assetId]?.name||node.userData.assetLabel||source,kind:node.userData.adjustableDesk?'desk':'tool',source:'assets/building.web.glb',note:'沿用已提交模型，不代表现场测绘或团队归属。'});
 }
 spatialCatalog=withSpatialObjects(spatialCatalog,descriptors);
}
function objectBounds(node){
 if(!node?.userData.adjustableDesk)return new THREE.Box3().setFromObject(node);
 const bounds=new THREE.Box3();node.parent.updateMatrixWorld(true);
 for(const part of node.userData.parts){const matrix=new THREE.Matrix4();part.batch.getMatrixAt(part.index,matrix);matrix.premultiply(part.batch.matrixWorld);part.batch.geometry.computeBoundingBox();bounds.union(part.batch.geometry.boundingBox.clone().applyMatrix4(matrix));}
 return bounds;
}
function spatialAction(event){
 if(!loaded)return;
 if(state.inspect){exitInspect();if(event.type==='BACK')return;}stopInput();
 spatial=reduceSpatialState(spatial,event,spatialCatalog);
 state.floor=spatial.floor;state.room=spatial.room;state.exploded=spatial.expanded;
 $('floor').value=state.floor;populateRooms();setOverview();
}
function openSpatialObject(id){
 const node=spatialRoots.get(id);if(!node)return;
 if(state.inspect)exitInspect();
 if(String(node.userData.floor)!==state.floor)spatialAction({type:'SELECT_FLOOR',floor:String(node.userData.floor)});
 if(state.mode==='overview'&&state.room!==spatialCatalog.objects[id].room)spatialAction({type:'SELECT_ROOM',room:spatialCatalog.objects[id].room});
 inspectTool(node);
}
function textTexture(lines){
 const c=document.createElement('canvas');c.width=1024;c.height=384;const context=c.getContext('2d');context.fillStyle='#f3f5f2';context.fillRect(0,0,c.width,c.height);context.strokeStyle='#155d85';context.lineWidth=8;context.strokeRect(4,4,c.width-8,c.height-8);context.fillStyle='#1e343c';context.textAlign='center';context.font='48px sans-serif';lines.forEach((line,i)=>context.fillText(line,512,95+i*90));const texture=new THREE.CanvasTexture(c);texture.colorSpace=THREE.SRGBColorSpace;return texture;
}
function createPendingFloor(){
 const group=new THREE.Group();group.name='1F pending reference (display only)';group.userData={floor:'1',pendingReference:true};
 const points=[[0,0],[layout.width,0],[layout.width,layout.length],[0,layout.length]].map(([x,z])=>new THREE.Vector3(x,.08,z));
 group.add(new THREE.LineLoop(new THREE.BufferGeometry().setFromPoints(points),new THREE.LineDashedMaterial({color:0x155d85,dashSize:.8,gapSize:.5})));
 group.children[0].computeLineDistances();
 const label=new THREE.Mesh(new THREE.PlaneGeometry(15,5.625),new THREE.MeshBasicMaterial({map:textTexture(['1F · 待核准','仅为改造预留层','无已核准平面 / 不可漫游']),side:THREE.DoubleSide}));label.rotation.x=-Math.PI/2;label.position.set(layout.width/2,.09,layout.length/2);group.add(label);return group;
}
function addCorridorPosters(){
 // Explicit proposed slots outside existing west-office boundaries, not surveyed placement.
 for(const room of layout.floors['4'].rooms.filter(r=>/^seminar_/.test(r.id))){
  const poster=new THREE.Mesh(new THREE.PlaneGeometry(1.2,.45),new THREE.MeshBasicMaterial({map:textTexture(['海报图片待提供','走廊示意位置','非已核准展品']),side:THREE.DoubleSide}));
  poster.rotation.y=Math.PI/2;poster.position.set(room.bounds[2]+.08,1.6,(room.bounds[1]+room.bounds[3])/2);poster.userData={floor:'4',kind:'poster',reviewPoster:true,sourceRoomId:room.id};roots.get('4').add(poster);
 }
}

function roomData(){return layout?.floors[state.floor]?.rooms.find(r=>r.id===state.room);}
function populateRooms(){
 const select=$('room');select.replaceChildren();const option=document.createElement('option');option.value='';option.textContent='整层';select.append(option);
 for(const room of spatialCatalog.floors[state.floor].rooms){const option=document.createElement('option');option.value=room.sourceRoomId;option.textContent=room.name;select.append(option);}
 if(!roomData())state.room='';select.value=state.room;
}
function updateUrl(){const q=new URLSearchParams();q.set('floor',state.floor);if(state.exploded)q.set('view','building');if(state.room)q.set('room',state.room);if(state.mode==='walk')q.set('mode','walk');if(params.get('chair')==='authored')q.set('chair','authored');if(state.floor!=='1'&&state.finishes[state.floor]!=='warm_gray_fine')q.set('finish',state.finishes[state.floor]);history.replaceState(null,'','?'+q);}
function previewFloorFinish(id){if(state.floor==='1')return;if(!['warm_gray_fine','light_gray_tile'].includes(id))return;state.finishes[state.floor]=id;for(const mesh of roots.get(state.floor).children)if(mesh.isMesh&&mesh.userData.kind==='floor')mesh.material=id==='light_gray_tile'?floorLibrary.tile:mesh.userData.originalFloorMaterial;presentation.apply({...spatial,mode:state.mode},spatialCatalog);updateUrl();}
$('preview-floor-finish').onclick=()=>{previewFloorFinish($('floor-finish').value);$('sources-dialog').close();};
function updateScene(){
 presentation.apply({...spatial,mode:state.mode},spatialCatalog);
 placeholder.visible=state.exploded||state.floor==='1';
 placeholder.position.y=0;
 overlay.update(spatial,{mode:state.mode,objects:spatialCatalog.objects});
 $('walk').disabled=state.floor==='1'||state.floor==='4';
 document.body.classList.toggle('walking',state.mode==='walk');$('walk-controls').hidden=state.mode!=='walk'||!matchMedia('(any-pointer: coarse)').matches;$('walk').hidden=state.mode==='walk';$('explode').setAttribute('aria-pressed',String(state.exploded));
 const room=roomData(),displayRoom=spatialCatalog.floors[state.floor].rooms.find(r=>r.sourceRoomId===state.room);$('location').textContent=`${state.floor}F${displayRoom?' · '+displayRoom.name:''}${state.mode==='walk'?' · 漫游':''}`;
 $('scale-note').textContent=room?`约 ${(room.bounds[2]-room.bounds[0]).toFixed(2)} × ${(room.bounds[3]-room.bounds[1]).toFixed(2)} m · ${room.area} ㎡`:'约 26.1 × 42.4 m · 按原图面积近似标定';
 if(state.exploded)$('location').textContent='四层展开 · 1F 为待核准占位';
 if(state.floor==='1')$('scale-note').textContent='1F 仅为版本化预留层：平面与改造方案待核准，无可漫游实景。';
 updateUrl();
}
function fitDistance(radius,fov){const vertical=THREE.MathUtils.degToRad(fov/2),horizontal=Math.atan(Math.tan(vertical)*innerWidth/innerHeight);return radius/Math.sin(Math.min(vertical,horizontal))*1.08;}
function setOverview(){if(!loaded)return;if(state.inspect)exitInspect();stopInput();state.mode='overview';orbit.enabled=true;orbit.enableRotate=true;orbit.enablePan=true;orbit.minDistance=1;orbit.maxDistance=220;orbit.maxPolarAngle=Math.PI*.48;camera.fov=46;camera.updateProjectionMatrix();updateScene();const room=roomData(),y=layout.floors[state.floor]?.elevation||0;
 if(room&&!state.exploded){const [a,b,c,d]=room.bounds,w=c-a,h=d-b,size=Math.max(w,h);orbit.target.set((a+c)/2,y+.3,(b+d)/2);camera.position.copy(orbit.target).add(new THREE.Vector3(.75,1.05,.85).normalize().multiplyScalar(fitDistance(Math.hypot(w,h,2)/2,46)));}
 else {orbit.target.set(layout.width/2,state.exploded?15:y,layout.length/2);camera.position.copy(orbit.target).add(new THREE.Vector3(31,43,45).normalize().multiplyScalar(fitDistance(Math.hypot(layout.width,layout.length,state.exploded?36:3)/2,46)));}
 orbit.update();drawSelection();
}
function drawSelection(){if(selection){scene.remove(selection);selection.geometry.dispose();selection.material.dispose();selection=null;}const room=roomData();if(!room||state.mode==='walk'||state.exploded)return;const [a,b,c,d]=room.bounds,y=layout.floors[state.floor].elevation+.018;const g=new THREE.BufferGeometry().setFromPoints([new THREE.Vector3(a,y,b),new THREE.Vector3(c,y,b),new THREE.Vector3(c,y,d),new THREE.Vector3(a,y,d)]);selection=new THREE.LineLoop(g,new THREE.LineBasicMaterial({color:0x27799a}));scene.add(selection);}
function walkFov(){return Math.min(60,THREE.MathUtils.radToDeg(2*Math.atan(Math.tan(THREE.MathUtils.degToRad(82/2))/(innerWidth/innerHeight))));}
function enterWalk(){if(!loaded||state.floor==='1'||state.floor==='4')return;if(state.inspect)exitInspect();stopInput();state.exploded=false;state.mode='walk';if(!state.room&&state.floor==='3'){state.room='seminar';$('room').value=state.room;}spatial=reduceSpatialState(spatial,{type:'SELECT_ROOM',floor:state.floor,room:state.room},spatialCatalog);const room=roomData(),f=layout.floors[state.floor];state.pos=nearestSafe(layout,state.floor,room?room.spawn:f.spawn);state.yaw=room?room.heading:Math.PI;state.pitch=-.14;orbit.enabled=false;camera.fov=walkFov();camera.updateProjectionMatrix();updateScene();drawSelection();syncEye();canvas.focus({preventScroll:true});}
function syncEye(){camera.position.set(state.pos[0],layout.floors[state.floor].elevation+layout.eyeHeight,state.pos[1]);camera.rotation.set(state.pitch,state.yaw,0,'YXZ');}
function stopInput(){keys.clear();joy.x=joy.y=0;joy.pointer=null;$('stick').style.transform='';look=null;}
function resize(){if(!renderer)return;const w=innerWidth,h=innerHeight;renderer.setSize(w,h,false);camera.aspect=w/h;if(loaded&&state.mode==='walk'&&!state.inspect)camera.fov=walkFov();camera.updateProjectionMatrix();if(loaded&&state.inspect){const tool=inspectedRoot,radius=objectBounds(tool).getSize(new THREE.Vector3()).length()/2,dir=camera.position.clone().sub(orbit.target).normalize(),distance=fitDistance(radius,40);camera.position.copy(orbit.target).add(dir.multiplyScalar(distance));orbit.maxDistance=Math.max(.85,distance*2);orbit.update();}else if(loaded&&state.mode==='overview')setOverview();}
function frame(now){requestAnimationFrame(frame);lastFrameGapMs=lastTime?now-lastTime:0;const dt=Math.min(.05,lastTime?(now-lastTime)/1000:0);lastTime=now;if(document.hidden)return;animateDesks(dt);savedWalk?.inspectionProxy?.update();
 if(state.mode==='walk'&&!state.inspect){let f=(keys.has('KeyW')||keys.has('ArrowUp')?1:0)-(keys.has('KeyS')||keys.has('ArrowDown')?1:0)-joy.y;let side=(keys.has('KeyD')||keys.has('ArrowRight')?1:0)-(keys.has('KeyA')||keys.has('ArrowLeft')?1:0)+joy.x;const len=Math.hypot(f,side);if(len>1){f/=len;side/=len;}const speed=layout.speed*dt;const dx=(-Math.sin(state.yaw)*f+Math.cos(state.yaw)*side)*speed,dz=(-Math.cos(state.yaw)*f-Math.sin(state.yaw)*side)*speed;state.pos=moveBody(layout,state.floor,state.pos,dx,dz);
 const current=layout.floors[state.floor].rooms.find(r=>state.pos[0]>r.bounds[0]&&state.pos[0]<r.bounds[2]&&state.pos[1]>r.bounds[1]&&state.pos[1]<r.bounds[3]);
 const roomId=current?.id||'';if(roomId!==state.room){state.room=roomId;spatial=reduceSpatialState(spatial,{type:'SELECT_ROOM',floor:state.floor,room:roomId},spatialCatalog);$('room').value=roomId;updateScene();}
 syncEye();}
 else orbit.update();for(const system of chairSystems)system.update(camera,innerHeight);for(const item of staticInstances)item.update(camera,innerHeight,state.inspect===item.root.userData.assetId);const renderStart=Date.now();renderer.render(scene,camera);lastRenderMs=Date.now()-renderStart;renderedFrames++;
}
$('floor').onchange=()=>spatialAction({type:'SELECT_FLOOR',floor:$('floor').value});$('room').onchange=()=>spatialAction({type:'SELECT_ROOM',room:$('room').value});$('overview').onclick=()=>{if(state.inspect){exitInspect();return;}if(state.mode==='walk')setOverview();else spatialAction({type:'BACK'});};$('walk').onclick=enterWalk;$('explode').onclick=()=>spatialAction({type:state.exploded?'COLLAPSE':'EXPAND'});
for(const name of ['help','sources']){$(name).onclick=()=>{stopInput();if(name==='sources')$('floor-finish').value=state.finishes[state.floor];$(name+'-dialog').showModal();};$(name+'-dialog').addEventListener('close',()=>{stopInput();canvas.focus({preventScroll:true});});}
window.addEventListener('keydown',e=>{if(e.key==='Escape'){if(state.inspect)exitInspect();else if(state.mode==='walk')setOverview();else if(loaded)spatialAction({type:'BACK'});return;}if(document.querySelector('dialog[open]')||/^(INPUT|SELECT|BUTTON)$/.test(document.activeElement?.tagName))return;if(state.mode==='walk'&&['KeyW','KeyA','KeyS','KeyD','ArrowUp','ArrowDown','ArrowLeft','ArrowRight'].includes(e.code)){e.preventDefault();keys.add(e.code);}});
window.addEventListener('keyup',e=>keys.delete(e.code));window.addEventListener('blur',stopInput);document.addEventListener('visibilitychange',()=>{stopInput();lastTime=0;});window.addEventListener('resize',resize);
canvas.addEventListener('contextmenu',e=>e.preventDefault());canvas.addEventListener('pointerdown',e=>{if(e.button!==0)return;canvas.focus({preventScroll:true});if(look)return;look={id:e.pointerId,x:e.clientX,y:e.clientY,startX:e.clientX,startY:e.clientY,moved:false};if(state.mode==='walk'&&!state.inspect)canvas.setPointerCapture(e.pointerId);});
canvas.addEventListener('pointermove',e=>{if(!look||look.id!==e.pointerId)return;const dx=e.clientX-look.x,dy=e.clientY-look.y;look.x=e.clientX;look.y=e.clientY;if(Math.hypot(e.clientX-look.startX,e.clientY-look.startY)>5)look.moved=true;if(state.mode==='walk'&&!state.inspect){state.yaw-=dx*.004;state.pitch=THREE.MathUtils.clamp(state.pitch-dy*.004,-1.25,1.25);}});
canvas.addEventListener('pointerup',e=>{if(!look||look.id!==e.pointerId)return;const clicked=!look.moved;look=null;if(canvas.hasPointerCapture(e.pointerId))canvas.releasePointerCapture(e.pointerId);if(clicked&&!state.inspect)pick(e);});canvas.addEventListener('pointercancel',()=>{look=null;});
canvas.addEventListener('lostpointercapture',()=>{look=null;});
function visibleTools(){
 camera.updateMatrixWorld();
 return toolRoots.filter(tool=>tool.userData.floor===state.floor).map(tool=>{
  const box=new THREE.Box3().setFromObject(tool),center=box.getCenter(new THREE.Vector3()),point=center.clone().project(camera);
  return {tool,assetId:tool.userData.assetId,x:(point.x+1)*innerWidth/2,y:(1-point.y)*innerHeight/2,inFront:point.z>=-1&&point.z<=1&&Math.abs(point.x)<1.2&&Math.abs(point.y)<1.2,distance:camera.position.distanceTo(center)};
 });
}
function hitIsVisible(hit){
 for(let owner=hit.object;owner;owner=owner.parent)if(!owner.visible)return false;
 const material=Array.isArray(hit.object.material)?hit.object.material[hit.face?.materialIndex||0]:hit.object.material;
 return !material.clippingPlanes?.some(plane=>plane.distanceToPoint(hit.point)<0);
}
function pick(e){
 pointer.set(e.clientX/innerWidth*2-1,-e.clientY/innerHeight*2+1);raycaster.setFromCamera(pointer,camera);
 const hits=raycaster.intersectObjects([...roots.values(),placeholder].filter(r=>r.visible),true).filter(hitIsVisible);if(!hits.length)return;
 const hit=hits[0];
 if(state.exploded){let root=hit.object;while(root&&!root.userData.floor)root=root.parent;if(root)spatialAction({type:'SELECT_FLOOR',floor:String(root.userData.floor)});return;}
 const reviewPoster=hit.object.userData.reviewPoster;if(reviewPoster){overlay.showExhibit('exhibit/office-corridor-poster');return;}
 if(state.mode==='overview'&&hit.object.userData.deskEntries?.[hit.instanceId]){openSpatialObject(hit.object.userData.deskEntries[hit.instanceId].desk.userData.spatialId);return;}
 if(state.mode==='walk'){const entry=hit.object.userData.deskEntries?.[hit.instanceId];if(entry?.control){toggleDesk(entry.desk);return;}let owner=hit.object,control=false;while(owner){control ||=!!owner.userData.deskControl;if(owner.userData.adjustableDesk&&control){toggleDesk(owner);return;}owner=owner.parent;}
 const nearby=deskControls().filter(d=>d.inFront&&d.distance<3&&Math.hypot(e.clientX-d.x,e.clientY-d.y)<22&&hit.distance>d.distance-.12).sort((a,b)=>Math.hypot(e.clientX-a.x,e.clientY-a.y)-Math.hypot(e.clientX-b.x,e.clientY-b.y));if(nearby.length){toggleDesk(nearby[0].desk);return;}}
 let tool=hit.object;while(tool&&!tool.userData.inspectable)tool=tool.parent;
 if(tool){openSpatialObject(tool.userData.spatialId);return;}
 // Expand tiny tools' visible anchors to a minimum target, while keeping walls
 // authoritative for occlusion and limiting this assistance to arm's reach.
 if(state.mode==='walk'){
  const nearby=visibleTools().filter(t=>t.inFront&&t.distance<3&&Math.hypot(e.clientX-t.x,e.clientY-t.y)<22&&hit.distance>t.distance-.20).sort((a,b)=>Math.hypot(e.clientX-a.x,e.clientY-a.y)-Math.hypot(e.clientX-b.x,e.clientY-b.y));
  if(nearby.length){openSpatialObject(nearby[0].tool.userData.spatialId);return;}
 }
 if(state.mode==='overview'&&!state.exploded){const f=layout.floors[state.floor],p=hit.point;if(!f)return;const room=f.rooms.find(r=>p.x>r.bounds[0]&&p.x<r.bounds[2]&&p.z>r.bounds[1]&&p.z<r.bounds[3]);if(room){spatialAction({type:'SELECT_ROOM',room:room.id});}}
}
function inspectTool(tool){stopInput();inspectedRoot=tool;savedWalk={spatial,viewport:[innerWidth,innerHeight],mode:state.mode,pos:[...state.pos],yaw:state.yaw,pitch:state.pitch,camera:camera.position.clone(),target:orbit.target.clone()};spatial=reduceSpatialState(spatial,{type:'SELECT_OBJECT',object:tool.userData.spatialId},spatialCatalog);overlay.update(spatial,{mode:state.mode,objects:spatialCatalog.objects});state.inspect=tool.userData.assetId||tool.userData.spatialId;if(state.inspect==='office_chair'||tool.userData.generatedAsset||tool.userData.adjustableDesk){savedWalk.hiddenNodes=[];for(const [floor,root] of roots){if(floor!==tool.userData.floor){savedWalk.hiddenNodes.push([root,root.visible]);root.visible=false;continue;}for(const child of root.children){if(child===tool||child.userData.kind==='floor')continue;savedWalk.hiddenNodes.push([child,child.visible]);child.visible=false;}}}
 if(tool.userData.adjustableDesk)savedWalk.inspectionProxy=createDeskInspectionProxy(THREE,tool);
 const measured=objectBounds(tool).getSize(new THREE.Vector3());const a=catalog.assets[state.inspect]||{name:tool.userData.assetLabel||spatialCatalog.objects[tool.userData.spatialId]?.name||'对象',dimensions:{width:measured.x,depth:measured.z,height:measured.y}},bounds=objectBounds(tool),center=bounds.getCenter(new THREE.Vector3()),size=bounds.getSize(new THREE.Vector3()).length();$('inspect').hidden=false;$('tool-name').textContent=a.name+(state.inspect==='office_chair'&&chairLibrary?.variant==='hyper3d'?' · Hyper3D 试作':'');$('tool-dimensions').textContent=a.dimensions.length?`总长 ${Math.round(a.dimensions.length*1000)} mm · 厂商尺寸参照`:`外形 ${[a.dimensions.width,a.dimensions.depth,a.dimensions.height].map(v=>Math.round(v*1000)).join(' × ')} mm`;if(state.inspect==='office_chair'&&chairLibrary?.variant==='hyper3d')$('tool-dimensions').textContent='模型约 '+[0,2,1].map(i=>Math.round(chairLibrary.manifest.levels[0].size[i]*1000)).join(' × ')+' mm · 比例参照';if(tool.userData.generatedAsset)$('tool-dimensions').textContent='模型约 '+[measured.x,measured.z,measured.y].map(v=>Math.round(v*1000)).join(' × ')+' mm · 比例参照';$('walk-controls').hidden=true;orbit.enabled=true;orbit.minDistance=.10;orbit.maxDistance=.85;orbit.maxPolarAngle=Math.PI*.90;orbit.target.copy(center);const distance=fitDistance(size/2,40);orbit.maxDistance=Math.max(.85,distance*2);camera.position.copy(center).add((a.dimensions.height?new THREE.Vector3(.75,.65,-1.4):new THREE.Vector3(.45,1.15,.95)).applyQuaternion(tool.quaternion).normalize().multiplyScalar(distance));camera.fov=40;camera.updateProjectionMatrix();orbit.update();}
function exitInspect(){if(!state.inspect||!savedWalk)return;stopInput();savedWalk.inspectionProxy?.dispose();for(const [node,visible] of savedWalk.hiddenNodes||[])node.visible=visible;state.inspect=null;inspectedRoot=null;spatial=savedWalk.spatial;$('inspect').hidden=true;state.pos=savedWalk.pos;state.yaw=savedWalk.yaw;state.pitch=savedWalk.pitch;camera.position.copy(savedWalk.camera);orbit.target.copy(savedWalk.target);orbit.minDistance=1;orbit.maxDistance=110;orbit.maxPolarAngle=Math.PI*.48;orbit.enabled=savedWalk.mode!=='walk';camera.fov=savedWalk.mode==='walk'?walkFov():46;camera.updateProjectionMatrix();updateScene();if(state.mode==='walk')syncEye();const refit=state.mode==='overview'&&(savedWalk.viewport[0]!==innerWidth||savedWalk.viewport[1]!==innerHeight);savedWalk=null;if(refit)setOverview();canvas.focus({preventScroll:true});}
$('inspect-exit').onclick=exitInspect;
const joystick=$('joystick');joystick.addEventListener('pointerdown',e=>{e.preventDefault();e.stopPropagation();if(joy.pointer!==null)return;joy.pointer=e.pointerId;joystick.setPointerCapture(e.pointerId);updateStick(e);});joystick.addEventListener('pointermove',e=>{if(joy.pointer===e.pointerId)updateStick(e);});
function updateStick(e){const r=joystick.getBoundingClientRect(),max=r.width*.30;let x=e.clientX-r.left-r.width/2,y=e.clientY-r.top-r.height/2;const len=Math.hypot(x,y);if(len>max){x=x/len*max;y=y/len*max;}joy.x=x/max;joy.y=y/max;$('stick').style.transform=`translate(${x}px,${y}px)`;}
for(const event of ['pointerup','pointercancel','lostpointercapture'])joystick.addEventListener(event,e=>{if(joy.pointer!==e.pointerId)return;joy.pointer=null;joy.x=joy.y=0;$('stick').style.transform='';});
canvas.addEventListener('webglcontextlost',e=>{e.preventDefault();failure('画面连接已中断，请重新载入当前空间。');});
// Read-only diagnostics for acceptance; tests exercise ordinary pointer/key/touch input.
window.flcReview={spatial:()=>({state:spatial,catalog:spatialCatalog,configRevision:exhibitions?.revision,placeholderVisible:placeholder?.visible,displayFloors:[...roots].map(([floor,root])=>({floor,visible:root.visible,y:root.position.y,sourceY:root.userData.sourcePosition[1]})),posterCount:roots.get('4')?.children.filter(n=>n.userData.reviewPoster).length}),generatedAssets:()=>staticInstances.map(item=>item.snapshot()),chairs:()=>({loaded:!!chairLibrary,variant:chairLibrary?.variant,systems:chairSystems.map(s=>s.snapshot())}),floorMaterials:()=>[...roots.entries()].map(([floor,root])=>({floor,profile:state.finishes[floor],specialFinishes:root.children.filter(m=>m.isMesh&&m.userData.kind==='finish').map(m=>m.material.name),surfaces:root.children.filter(m=>m.isMesh&&m.userData.kind==='floor').map(m=>({material:m.material.name,hasColor:!!m.material.map,hasNormal:!!m.material.normalMap,hasRoughness:!!m.material.roughnessMap,uvCount:m.geometry.getAttribute('uv')?.count,uvSpan:m.geometry.getAttribute('uv')?Array.from(m.geometry.getAttribute('uv').array).reduce((r,v)=>[Math.min(r[0],v),Math.max(r[1],v)],[Infinity,-Infinity]):null}))})),desks:()=>deskControls().map(({desk,...info})=>({...info,partOffsets:desk.userData.parts.map(p=>{const m=new THREE.Matrix4();p.batch.getMatrixAt(p.index,m);return {factor:p.factor,offset:m.elements[13]-p.base.elements[13]};})})),layers:()=>[...roots.entries()].map(([floor,root])=>({floor,visible:root.visible,parts:root.children.filter(m=>m.isMesh).map(m=>({kind:m.userData.kind,visible:m.visible,minY:new THREE.Box3().setFromObject(m).min.y,maxY:new THREE.Box3().setFromObject(m).max.y}))})),snapshot:()=>({ready:loaded,renderedFrames,lastFrameGapMs,lastRenderMs,spatialScope:spatial?.scope,expanded:state.exploded,floor:state.floor,room:state.room,mode:state.mode,position:[...state.pos],yaw:state.yaw,pitch:state.pitch,eyeHeight:layout?.eyeHeight,verticalFov:camera?.fov,horizontalFov:camera?THREE.MathUtils.radToDeg(2*Math.atan(Math.tan(THREE.MathUtils.degToRad(camera.fov/2))*camera.aspect)):null,inspect:state.inspect,joystick:[joy.x,joy.y],drawCalls:renderer?.info.render.calls,triangles:renderer?.info.render.triangles,renderedMeshes:[...roots.values()].reduce((n,r)=>n+r.children.length,0)}),canStand:(x,z)=>state.floor!=='1'&&canStand(layout,state.floor,x,z),tools:()=>visibleTools().map(({tool,...info})=>info)};
start();
