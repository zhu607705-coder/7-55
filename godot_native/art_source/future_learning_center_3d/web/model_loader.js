import {GLTFLoader} from 'three/addons/loaders/GLTFLoader.js';
import {DRACOLoader} from 'three/addons/loaders/DRACOLoader.js';

// Share one local Draco worker pool across chair and generated furniture assets.
export function createModelLoader(){
 const decoder=new DRACOLoader().setDecoderPath('./vendor/three/draco/').setWorkerLimit(2);
 return {loader:new GLTFLoader().setDRACOLoader(decoder),dispose:()=>decoder.dispose()};
}
