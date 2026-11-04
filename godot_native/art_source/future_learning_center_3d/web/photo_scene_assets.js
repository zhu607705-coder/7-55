/** Optional, metric photo assets. A binding is atomic: keep the authored object
 * until all its parts/LODs load. Pending placements never load or instantiate. */
import * as THREE from './vendor/three/three.module.js';
export const PHOTO_DESKTOP_NAMES=/^(Monitor clamp|Monitor arm upright|Monitor articulated arm|Monitor frame|Screen|Keyboard case|Keyboard key caps|Mouse)(?:\.\d+)?$/;
export function photoLevel(pixels){return pixels>=180?0:pixels>=65?1:2;}
export function validatePhotoConfig(config){
 if(config.schemaVersion!==1||config.units!=='metres')throw Error('Unsupported photo scene config');
 const ids=new Set(),anchors=new Set();
 for(const binding of config.bindings){
  if(ids.has(binding.id))throw Error('Duplicate photo binding ID');ids.add(binding.id);
  if(binding.status!=='active')continue;
  const key=binding.floor+'/'+binding.sourceNodeName;
  if(anchors.has(key))throw Error('Duplicate photo anchor');anchors.add(key);
  if(!['deskDesktop','static'].includes(binding.kind)||!binding.sourceNodeName||!binding.parts?.length)throw Error('Missing photo anchor/parts');
  if(binding.floorSpace&&(!Array.isArray(binding.floorAnchor)||binding.floorAnchor.length!==3||!binding.floorAnchor.every(Number.isFinite)||binding.kind!=='static'||!binding.retainOriginal))throw Error('Floor placement needs an explicit metric anchor and retained source');
  if(binding.collision?.partIndices?.some(i=>!Number.isInteger(i)||i<0||i>=binding.parts.length))throw Error('Invalid collision part');
  if(binding.collision?.replaceCenter&&(!Array.isArray(binding.collision.replaceCenter)||binding.collision.replaceCenter.length!==2||!binding.collision.replaceCenter.every(Number.isFinite)))throw Error('Invalid collision source center');
  for(const part of binding.parts){
   if(!config.assets[part.asset]||!Array.isArray(part.position)||part.position.length!==3||!part.position.every(Number.isFinite)||part.scale!==undefined||(part.yaw!==undefined&&!Number.isFinite(part.yaw)))throw Error('Photo asset requires metric translation, not scaling');
  }
 }
 return config;
}
export async function loadPhotoSceneAssets(codec,{fetchJSON=async url=>{const r=await fetch(url);if(!r.ok)throw Error(url+' '+r.status);return r.json();}}={}){
 const owned=new Set(),retained=new Set();
 const rememberMaterial=(material,set)=>{for(const m of Array.isArray(material)?material:[material]){if(!m)continue;set.add(m);for(const value of Object.values(m))if(value?.isTexture)set.add(value);}};
 const library={assets:new Map(),bindings:new Map(),errors:[],pending:[]};
 try{
  const config=validatePhotoConfig(await fetchJSON('./assets/photo_scene_config.json'));
  library.pending=config.pending||[];
  const active=config.bindings.filter(b=>b.status==='active');
  const ids=new Set(active.flatMap(b=>b.parts.map(p=>p.asset)));
  await Promise.all([...ids].map(async id=>{
   try{
    const folder='./assets/'+config.assets[id].folder+'/',manifest=await fetchJSON(folder+'manifest.json');
    if(manifest.levels.length!==3)throw Error('Expected three photo LODs');
    const settled=await Promise.allSettled(manifest.levels.map(async level=>{
     let gltf;try{gltf=await codec.loader.loadAsync(folder+level.file);}catch(error){
      if(!level.uncompressedFile)throw error;gltf=await codec.loader.loadAsync(folder+level.uncompressedFile);
     }
     gltf.scene.traverse(mesh=>{if(mesh.geometry)owned.add(mesh.geometry);if(mesh.material)rememberMaterial(mesh.material,owned);});
     gltf.scene.updateMatrixWorld(true);const parts=[];
     gltf.scene.traverse(mesh=>{if(!mesh.isMesh)return;const geometry=mesh.geometry.clone();owned.add(geometry);geometry.applyMatrix4(mesh.matrixWorld);parts.push({geometry,material:mesh.material,sourcePart:mesh.userData.part||mesh.name});});
     if(!parts.length)throw Error('Empty photo asset');return parts;
    }));
    const failure=settled.find(result=>result.status==='rejected');if(failure)throw failure.reason;
    const levels=settled.map(result=>result.value);
    for(const parts of levels)for(const part of parts){retained.add(part.geometry);rememberMaterial(part.material,retained);}
    library.assets.set(id,{id,manifest,levels});
   }catch(error){library.errors.push({asset:id,error:String(error)});}
  }));
  for(const binding of active)if(binding.parts.every(p=>library.assets.has(p.asset)))library.bindings.set(binding.floor+'/'+binding.sourceNodeName,binding);
 }catch(error){library.errors.push({config:true,error:String(error)});}
 // Wait for every level/asset before releasing failed resources. A material
 // shared by another successful asset is never disposed by a failed neighbor.
 for(const resource of owned)if(!retained.has(resource))resource.dispose();
 let disposed=false;library.dispose=()=>{if(disposed)return;disposed=true;for(const resource of retained)resource.dispose();library.assets.clear();library.bindings.clear();};
 return library;
}
/** Baked glTF Y-up geometry + original rigid desk transform, applied once. */
export function photoDeskParts(library,binding,deskMatrix){
 const result=[];
 for(const placement of binding.parts){
  const asset=library.assets.get(placement.asset),offset=new THREE.Matrix4().makeTranslation(...placement.position).multiply(new THREE.Matrix4().makeRotationY(placement.yaw||0));
  asset.levels.forEach((parts,level)=>parts.forEach(({geometry,material,sourcePart})=>result.push({geometry,material,sourcePart,level,asset:placement.asset,base:deskMatrix.clone().multiply(offset),factor:1,role:'photoDesktop'})));
 }
 return result;
}
export function rigidPhotoAnchor(matrix){
 const p=new THREE.Vector3(),q=new THREE.Quaternion(),s=new THREE.Vector3();matrix.decompose(p,q,s);
 return [s.x,s.y,s.z].every(v=>Math.abs(v-1)<1e-5);
}
