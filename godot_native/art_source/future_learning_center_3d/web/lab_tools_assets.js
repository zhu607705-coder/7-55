/** Independent static equipment sample library. No gameplay/controller changes.
 * Load once; create() clones Object3D transforms but shares geometry/materials.
 * The host supplies projected height, so camera distance/FOV does not imply scale.
 */
import * as THREE from 'three';
import {GLTFLoader} from 'three/addons/loaders/GLTFLoader.js';
import {DRACOLoader} from 'three/addons/loaders/DRACOLoader.js';
export const LAB_TOOL_IDS=Object.freeze(['printer_enclosure_study','laser_enclosure_study','bench_power_supply']);
export function labToolLevel(projectedPixels){return projectedPixels>=150?0:projectedPixels>=55?1:2;}
export async function loadLabToolSamples(){
 const decoder=new DRACOLoader().setDecoderPath('./vendor/three/draco/');
 const loader=new GLTFLoader().setDRACOLoader(decoder),prototypes=new Map();
 try{
  await Promise.all(LAB_TOOL_IDS.map(async id=>{
   const levels=await Promise.all([0,1,2].map(async level=>(await loader.loadAsync(`./assets/models/lab_tools/${id}/lod${level}.draco.glb`)).scene));
   prototypes.set(id,levels);
  }));
 }finally{decoder.dispose();}
 return {
  create(id){
   if(!prototypes.has(id))throw new Error('Unknown static prop: '+id);
   const group=new THREE.Group();group.name=id+' static material sample';group.userData.assetId=id;
   const levels=prototypes.get(id).map(p=>p.clone(true));levels.forEach(x=>group.add(x));
   group.setProjectedSize=pixels=>{const selected=labToolLevel(pixels);levels.forEach((o,i)=>o.visible=i===selected);group.userData.level=selected;};
   group.setProjectedSize(Infinity);return group;
  },
  dispose(){
   const geometries=new Set(),materials=new Set();
   for(const levels of prototypes.values())for(const root of levels)root.traverse(o=>{if(o.geometry)geometries.add(o.geometry);for(const m of Array.isArray(o.material)?o.material:o.material?[o.material]:[])materials.add(m);});
   geometries.forEach(g=>g.dispose());materials.forEach(m=>m.dispose());prototypes.clear();
  }
 };
}
