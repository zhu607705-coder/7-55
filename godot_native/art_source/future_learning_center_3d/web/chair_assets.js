import * as THREE from 'three';
import {GLTFLoader} from 'three/addons/loaders/GLTFLoader.js';
import {DRACOLoader} from 'three/addons/loaders/DRACOLoader.js';

// Share one decoder; optional failure retains the authored building furniture.
export async function loadChairAssets(variant='authored') {
 const folder=`./assets/models/ergonomic_chair/${variant==='hyper3d'?'hyper3d':'authored'}/`;
 const decoder=new DRACOLoader().setDecoderPath('./vendor/three/draco/').setWorkerLimit(2);
 try {
  const response=await fetch(folder+'manifest.json');if(!response.ok)throw Error('Chair manifest unavailable');
  const manifest=await response.json(),loader=new GLTFLoader().setDRACOLoader(decoder);
  const levels=await Promise.all(manifest.levels.map(async level=>{
   const gltf=await loader.loadAsync(folder+level.file);gltf.scene.updateMatrixWorld(true);
   const parts=[];gltf.scene.traverse(mesh=>{if(!mesh.isMesh)return;const geometry=mesh.geometry.clone();geometry.applyMatrix4(mesh.matrixWorld);parts.push({geometry,material:mesh.material});});
   return {parts,triangles:level.triangles};
  }));
  return {variant,manifest,levels,hero(){const g=new THREE.Group();for(const {geometry,material} of levels[0].parts){const m=new THREE.Mesh(geometry,material.clone());m.castShadow=true;m.receiveShadow=true;m.userData.kind='tool';g.add(m);}return g;}};
 } catch(error) {return null;} finally {decoder.dispose();}
}

// Shared geometry, original placements/colliders, projected-height detail levels.
export class ChairInstances {
 constructor(library,parent,placements) {
  this.library=library;this.parent=parent;this.placements=placements;
  this.group=new THREE.Group();this.group.userData.kind='furniture';parent.add(this.group);
  this.batches=library.levels.map(({parts})=>parts.map(({geometry,material})=>{
   const batch=new THREE.InstancedMesh(geometry,material.clone(),placements.length);
   batch.userData={kind:'furniture',floor:parent.userData.floor,chairInstances:true};
   batch.castShadow=true;batch.receiveShadow=true;batch.frustumCulled=false;
   batch.instanceMatrix.setUsage(THREE.DynamicDrawUsage);batch.count=0;this.group.add(batch);return batch;
  }));
  this.counts=[0,0,0];this.frustum=new THREE.Frustum();this.projection=new THREE.Matrix4();
  this.sphere=new THREE.Sphere();this.center=new THREE.Vector3();this.lastKey='';
 }
 update(camera,height) {
  this.parent.updateWorldMatrix(true,false);camera.updateMatrixWorld();
  const key=[...camera.matrixWorld.elements,camera.fov,height,this.parent.position.y,this.parent.visible,this.group.visible].join(',');
  if(key===this.lastKey)return;this.lastKey=key;this.counts.fill(0);
  this.projection.multiplyMatrices(camera.projectionMatrix,camera.matrixWorldInverse);this.frustum.setFromProjectionMatrix(this.projection);
  if(this.parent.visible&&this.group.visible)for(const matrix of this.placements){
   this.center.set(0,.645,0).applyMatrix4(matrix).applyMatrix4(this.parent.matrixWorld);
   this.sphere.set(this.center,.9*matrix.getMaxScaleOnAxis());if(!this.frustum.intersectsSphere(this.sphere))continue;
   const pixels=1.29*height/(2*Math.tan(THREE.MathUtils.degToRad(camera.fov/2))*Math.max(.1,camera.position.distanceTo(this.center)));
   const level=pixels>=150?0:pixels>=55?1:2,index=this.counts[level]++;
   for(const batch of this.batches[level])batch.setMatrixAt(index,matrix);
  }
  this.batches.forEach((parts,level)=>{for(const batch of parts){batch.count=this.counts[level];batch.instanceMatrix.needsUpdate=true;}});
 }
 snapshot(){return {floor:this.parent.userData.floor,variant:this.library.variant,total:this.placements.length,visibleByLod:[...this.counts],trianglesPerLod:this.library.levels.map(l=>l.triangles)};}
}
