import * as THREE from 'three';
import {OrbitControls} from 'three/addons/controls/OrbitControls.js';
import {GLTFLoader} from 'three/addons/loaders/GLTFLoader.js';
import {DRACOLoader} from 'three/addons/loaders/DRACOLoader.js';
import {RoomEnvironment} from 'three/addons/environments/RoomEnvironment.js';
import {REVIEW_ASSETS,reviewLevel} from './props_review_catalog.js';
import {createReviewStore} from './props_review_store.js';
const $=id=>document.getElementById(id),canvas=$('scene');
const assetSelect=$('asset');
for(const a of REVIEW_ASSETS)assetSelect.add(new Option(a.name,a.id));
let renderer,controls,store,decoder,pmrem,environment,grid,observer,current,instances=[],generation=0,dead=false;
function cleanup(){observer?.disconnect();renderer?.setAnimationLoop(null);group.clear();store?.dispose();decoder?.dispose();controls?.dispose();environment?.dispose();pmrem?.dispose();grid?.geometry.dispose();grid?.material.dispose();renderer?.dispose();}
const scene=new THREE.Scene();scene.background=new THREE.Color('#e2e7e3');
const camera=new THREE.PerspectiveCamera(38,1,.001,100),group=new THREE.Group();scene.add(group);
const info=a=>{for(const key of ['name','dimensions','source','note'])$(key).textContent=a[key];$('source-doc').href=a.doc;};
info(REVIEW_ASSETS[0]);
function showLevel(){
 if(!current||!renderer)return;
 const box=new THREE.Box3().setFromObject(group),center=box.getCenter(new THREE.Vector3());
 // Bounding sphere diameter avoids a flat tool choosing coarse LOD only because it lies down.
 const diameter=new THREE.Vector3(...current.manifest.source.size).length();
 const pixels=diameter*canvas.clientHeight/(2*Math.tan(THREE.MathUtils.degToRad(camera.fov/2))*Math.max(.001,camera.position.distanceTo(center)));
 const level=$('lod').value==='auto'?reviewLevel(pixels):Number($('lod').value);
 for(const roots of instances)roots.forEach((r,i)=>r.visible=i===level);
 const m=current.manifest.levels[level];
 $('stats').textContent=`LOD ${level} · ${m.triangles.toLocaleString()} 三角形 / 件 · ${instances.length} 件共享几何与材质 · ${current.formats[level]}`;
}
function frame(direction='oblique',factor=1){
 if(!current)return;
 const b=new THREE.Box3().setFromObject(group),center=b.getCenter(new THREE.Vector3()),size=b.getSize(new THREE.Vector3());
 const radius=size.length()/2;camera.far=Math.max(100,radius*60);camera.updateProjectionMatrix();
 const fov=Math.min(THREE.MathUtils.degToRad(camera.fov),2*Math.atan(Math.tan(THREE.MathUtils.degToRad(camera.fov/2))*camera.aspect));
 const distance=radius/Math.sin(fov/2)*1.15*factor;
 const v=direction==='front'?new THREE.Vector3(0,.04,1):direction==='side'?new THREE.Vector3(1,.04,0):direction==='top'?new THREE.Vector3(0,1,.001):new THREE.Vector3(1,.65,1);
 camera.position.copy(center).add(v.normalize().multiplyScalar(distance));controls.target.copy(center);controls.minDistance=Math.max(.005,radius*.12);controls.maxDistance=Math.max(10,radius*30);controls.update();showLevel();
}
function populate(){
 group.clear();instances=[];
 if(!current)return;
 const count=Number($('count').value),width=current.manifest.source.size[0];
 for(let n=0;n<count;n++){
  const holder=new THREE.Group(),roots=current.create();holder.add(...roots);holder.position.x=(n-(count-1)/2)*(width*1.35);group.add(holder);instances.push(roots);
 }
 showLevel();frame();
}
async function select(){
 const id=assetSelect.value,a=REVIEW_ASSETS.find(a=>a.id===id),ticket=++generation;info(a);
 $('materials').replaceChildren();$('retry').hidden=true;$('stats').textContent='';
 current=null;group.clear();instances=[];
 if(!store){$('status').textContent='WebGL 初始化失败。尺寸和来源仍可阅读；请换用支持 WebGL 的浏览器后重新打开。';return;}
 $('status').textContent=`正在加载${a.name}；Draco 失败时会尝试未压缩 GLB…`;
 try{
  const loaded=await store.load(id);if(dead||ticket!==generation)return;current=loaded;
  const materials=new Set();for(const root of loaded.create())root.traverse(o=>{for(const m of Array.isArray(o.material)?o.material:o.material?[o.material]:[])materials.add(m);});
  for(const m of materials){const li=document.createElement('li');li.textContent=`${m.name}：金属度 ${Number(m.metalness??0).toFixed(2)}；粗糙度 ${Number(m.roughness??1).toFixed(2)}；透射 ${Number(m.transmission??0).toFixed(2)}`;$('materials').append(li);}
  const bounds=document.createElement('li');bounds.textContent='GLB 包围盒：宽(X) × 深(Z) × 高(Y) = '+[0,2,1].map(i=>(loaded.manifest.source.size[i]*1000).toFixed(2)).join(' × ')+' mm。取自导出清单，不是现场实测；不替代上面的参考尺寸。';$('materials').append(bounds);
  populate();$('status').textContent=loaded.formats.some(x=>x!=='Draco')?'此件已加载；部分档位使用未压缩 GLB 回退。':'已加载。拖动旋转，滚轮或双指缩放。';
 }catch(error){if(dead||ticket!==generation)return;$('status').textContent='此件加载失败（Draco 与未压缩文件均不可用，或清单失败）。可重试此件，或选择其他物件。';$('retry').hidden=false;console.error('Review asset failed',id,error);}
}
assetSelect.addEventListener('change',select);$('retry').addEventListener('click',select);
try{
 renderer=new THREE.WebGLRenderer({canvas,antialias:true});renderer.setPixelRatio(Math.min(devicePixelRatio,2));renderer.toneMapping=THREE.ACESFilmicToneMapping;renderer.toneMappingExposure=1;
 pmrem=new THREE.PMREMGenerator(renderer);const room=new RoomEnvironment();try{environment=pmrem.fromScene(room,.04);}finally{room.dispose();}scene.environment=environment.texture;
 scene.add(new THREE.HemisphereLight(0xffffff,0x64747a,1));const key=new THREE.DirectionalLight(0xffffff,2);key.position.set(2,4,3);scene.add(key);
 grid=new THREE.GridHelper(4,40,0x788f97,0xb4c4c7);grid.position.y=-.0005;scene.add(grid);
 controls=new OrbitControls(camera,canvas);controls.enableDamping=false;controls.addEventListener('change',showLevel);
 decoder=new DRACOLoader().setDecoderPath('./vendor/three/draco/');const loader=new GLTFLoader().setDRACOLoader(decoder);
 store=createReviewStore({assets:REVIEW_ASSETS,loadScene:async url=>(await loader.loadAsync(url)).scene,loadManifest:async url=>{const r=await fetch(url);if(!r.ok)throw new Error(`Manifest HTTP ${r.status}`);return r.json();}});
 const resize=()=>{const w=canvas.clientWidth,h=canvas.clientHeight;renderer.setSize(w,h,false);camera.aspect=w/Math.max(h,1);camera.updateProjectionMatrix();showLevel();};
 observer=new ResizeObserver(resize);observer.observe(canvas);resize();
 $('count').addEventListener('change',populate);$('lod').addEventListener('change',showLevel);$('grid').addEventListener('change',()=>grid.visible=$('grid').checked);
 $('fit').addEventListener('click',()=>frame());$('near').addEventListener('click',()=>frame('oblique',.65));for(const name of ['front','side','top'])$(name).addEventListener('click',()=>frame(name));
 renderer.setAnimationLoop(()=>{if(!document.hidden)renderer.render(scene,camera);});
 canvas.addEventListener('webglcontextlost',event=>{event.preventDefault();$('status').textContent='图形上下文已丢失。请重新加载页面恢复三维查看；尺寸与来源仍可阅读。';renderer.setAnimationLoop(null);});
 addEventListener('pagehide',()=>{dead=true;generation++;cleanup();},{once:true});
}catch(error){cleanup();store=undefined;renderer=undefined;console.error('Review renderer initialization failed',error);for(const id of ['fit','near','front','side','top','lod','count','grid'])$(id).disabled=true;}
select();
addEventListener('pageshow',event=>{if(event.persisted&&dead)location.reload();});
