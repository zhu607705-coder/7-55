import * as THREE from 'three';

export async function loadStaticAssets(codec){
 const library=new Map();
 try{
  const response=await fetch('./assets/generated_furniture_catalog.json');if(!response.ok)return library;
  const catalog=await response.json();
  await Promise.all(Object.entries(catalog.assets).filter(([,a])=>a.acceptedForPreview).map(async([id,asset])=>{
   try{
    const response=await fetch('./assets/'+asset.folder+'/manifest.json');if(!response.ok)return;
    const manifest=await response.json();
    const levels=await Promise.all(manifest.levels.map(async level=>{
     const gltf=await codec.loader.loadAsync('./assets/'+asset.folder+'/'+level.file);gltf.scene.updateMatrixWorld(true);
     const parts=[];gltf.scene.traverse(m=>{if(!m.isMesh)return;const geometry=m.geometry.clone();geometry.applyMatrix4(m.matrixWorld);parts.push({geometry,material:m.material});});return parts;
    }));
    library.set(id,{...asset,manifest,levels});
   }catch(error){/* Keep the corresponding authored fallback when optional assets fail. */}
  }));
  library.slots=catalog.slots;
 }catch(error){/* The complete authored furniture remains available. */}
 return library;
}

export class StaticAssetInstance{
 constructor(asset,slot,anchor,parent){
  this.asset=asset;this.slot=slot;this.level=-1;
  this.root=new THREE.Group();this.root.userData={...anchor.userData,
   assetId:anchor.userData.staticAssetSlot,assetLabel:asset.name,generatedAsset:true,
   inspectable:true,floor:parent.userData.floor,kind:'furniture'};
  this.root.position.copy(anchor.position);this.root.quaternion.copy(anchor.quaternion);
  this.root.scale.copy(anchor.scale).multiplyScalar(slot.uniformScale??1);
  this.levels=asset.levels.map(parts=>{const g=new THREE.Group();for(const {geometry,material,transform,asset:photoAsset} of parts){
   const m=new THREE.Mesh(geometry,material.clone());m.castShadow=true;m.receiveShadow=true;
   if(transform){m.matrix.copy(transform);m.matrixAutoUpdate=false;}
   m.userData={kind:'furniture',floor:parent.userData.floor,photoAsset};g.add(m);
  }this.root.add(g);return g;});
  this.center=new THREE.Vector3();parent.add(this.root);
 }
 update(camera,height,inspecting){
  this.root.updateWorldMatrix(true,false);this.center.set(0,this.asset.manifest.levels[0].size[1]/2,0).applyMatrix4(this.root.matrixWorld);
  const size=Math.max(...this.asset.manifest.levels[0].size)*this.root.scale.x;
  const pixels=size*height/(2*Math.tan(THREE.MathUtils.degToRad(camera.fov/2))*Math.max(.1,camera.position.distanceTo(this.center)));
  const level=inspecting?0:pixels>=200?0:pixels>=80?1:2;
  if(level!==this.level){this.level=level;this.levels.forEach((g,i)=>g.visible=i===level);}
 }
 snapshot(){return {slot:this.root.userData.assetId,asset:this.slot.asset,level:this.level,
  size:this.asset.manifest.levels[0].size.map(v=>v*this.root.scale.x),modelPage:this.asset.modelPage,
  trianglesByLod:this.asset.manifest.levels.map(l=>l.triangles),materials:this.asset.manifest.levels[0].materials};}
}
