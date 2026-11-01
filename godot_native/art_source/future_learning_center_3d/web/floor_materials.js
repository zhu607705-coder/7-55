import * as THREE from 'three';
export async function loadFloorMaterialLibrary(renderer){
 const response=await fetch('./assets/floor_material_catalog.json');if(!response.ok)throw Error('Floor material catalog '+response.status);const catalog=await response.json();
 const profile=catalog.profiles.light_gray_tile,loader=new THREE.TextureLoader();
 const textures=await Promise.all(['color','orm','normal'].map(async role=>{
  const texture=await loader.loadAsync('./assets/'+profile.maps[role].file);texture.colorSpace=role==='color'?THREE.SRGBColorSpace:THREE.NoColorSpace;texture.wrapS=texture.wrapT=THREE.RepeatWrapping;texture.repeat.setScalar(catalog.uv_period_m/profile.repeat_m);texture.anisotropy=Math.min(4,renderer.capabilities.getMaxAnisotropy());texture.flipY=false;texture.needsUpdate=true;return texture;
 }));
 const tile=new THREE.MeshStandardMaterial({name:'Floor comparison light_gray_tile',map:textures[0],roughnessMap:textures[1],metalnessMap:textures[1],normalMap:textures[2],normalScale:new THREE.Vector2(profile.normal_strength,profile.normal_strength),roughness:1,metalness:1});tile.userData.floorProfile='light_gray_tile';
 return {catalog,tile};
}
