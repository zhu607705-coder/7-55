import * as THREE from './vendor/three/three.module.js';
import {loadPhotoSceneAssets} from './photo_scene_assets.js';
export const REVIEW_ANCHOR='flc/f3/object/office_desk008';
export const WIDTHS=[.553,.614,.675];
export const CANDIDATES=[
 {asset:'separated_twist_drill',position:[.38,0,.13]},
 {asset:'waisted_double_ended_bit',position:[.43,0,.13]},
 {asset:'short_metal_extension',position:[.48,0,.13]},
];
export async function loadReviewCandidates(codec){
 const config={schemaVersion:1,units:'metres',assets:Object.fromEntries(CANDIDATES.map(p=>[p.asset,{folder:'models/review_candidates/'+p.asset}])),bindings:CANDIDATES.map(p=>({id:p.asset,floor:'3',sourceNodeName:p.asset,status:'active',kind:'static',parts:[{asset:p.asset,position:[0,0,0]}]}))};
 return loadPhotoSceneAssets(codec,{fetchJSON:async url=>{if(url.endsWith('photo_scene_config.json'))return config;const r=await fetch(url);if(!r.ok)throw Error(r.status+' '+url);return r.json();}});
}
/** Temporary proxy in the actual floor. Never modifies source geometry or saved layouts. */
export function createWorkstationReview(desk,library){
 const initialHeight=desk.userData.currentHeight,initialTarget=desk.userData.targetHeight;
 const root=new THREE.Group();root.name='Temporary workstation review';root.userData={reviewCandidate:true,floor:'3',kind:'furniture'};desk.parent.add(root);
 const panel=part=>part.asset==='photo_monitor_stand'&&/Monitor bezel|Neutral screen/.test(part.sourcePart||'');
 const entries=desk.userData.parts.filter(p=>p.level===undefined||p.level===0).map(part=>{const mesh=new THREE.Mesh(part.batch.geometry,part.batch.material);mesh.matrixAutoUpdate=false;mesh.castShadow=true;mesh.receiveShadow=true;root.add(mesh);return {part,mesh};});
 const toolRoot=new THREE.Group();root.add(toolRoot);const tools=[];
 for(const placement of CANDIDATES.every(p=>library.assets.has(p.asset))?CANDIDATES:[]){const asset=library.assets.get(placement.asset);if(!asset)continue;const group=new THREE.Group();group.userData={reviewCandidate:true,asset:placement.asset};toolRoot.add(group);const levels=asset.levels.map(parts=>{const level=new THREE.Group();for(const p of parts){const mesh=new THREE.Mesh(p.geometry,p.material);mesh.castShadow=true;level.add(mesh);}group.add(level);return level;});tools.push({placement,asset,group,levels,level:0});}
 const settings={width:.614,panelCenter:.305,depth:0,tools:false};let disposed=false;
 const m=new THREE.Matrix4(),zero=new THREE.Vector3(0,0,0),deskMatrix=new THREE.Matrix4();
 function update(camera,viewportHeight=800){if(disposed)return;desk.updateMatrix();deskMatrix.copy(desk.matrix);const lift=desk.userData.currentHeight-.73;
  for(const {part,mesh} of entries){m.copy(part.base);m.elements[13]+=lift*part.factor;if(panel(part)){const scale=settings.width/.614;m.multiply(new THREE.Matrix4().makeTranslation(0,settings.panelCenter-.305,settings.depth)).multiply(new THREE.Matrix4().makeTranslation(0,.305,0)).multiply(new THREE.Matrix4().makeScale(scale,scale,1)).multiply(new THREE.Matrix4().makeTranslation(0,-.305,0));}mesh.matrix.copy(m);mesh.matrixWorldNeedsUpdate=true;}
  // Hide only this desk's original instances. Other desks and architecture remain visible.
  for(const part of desk.userData.parts){m.copy(part.base).scale(zero);part.batch.setMatrixAt(part.index,m);part.batch.instanceMatrix.needsUpdate=true;}
  toolRoot.visible=settings.tools;
  for(const t of tools){t.group.position.set(t.placement.position[0],desk.userData.currentHeight,t.placement.position[2]);t.group.position.applyMatrix4(deskMatrix);t.group.quaternion.copy(desk.quaternion);t.group.updateWorldMatrix(true,false);const world=t.group.getWorldPosition(new THREE.Vector3());const pixels=camera?Math.max(...t.asset.manifest.levels[0].size)*viewportHeight/(2*Math.tan(THREE.MathUtils.degToRad(camera.fov/2))*Math.max(.1,camera.position.distanceTo(world))):200;t.level=pixels>=100?0:pixels>=35?1:2;t.levels.forEach((g,i)=>g.visible=i===t.level);}
  root.updateMatrixWorld(true);
 }
 function set(change){if(change.width!==undefined&&!WIDTHS.includes(change.width))throw Error('Unknown width candidate');if(change.panelCenter!==undefined&&(!Number.isFinite(change.panelCenter)||change.panelCenter<.29||change.panelCenter>.40))throw Error('Panel center out of range');if(change.depth!==undefined&&(!Number.isFinite(change.depth)||Math.abs(change.depth)>.04))throw Error('Panel offset out of range');Object.assign(settings,change);if(tools.length!==3)settings.tools=false;update();}
 function dispose(){if(disposed)return;disposed=true;desk.userData.currentHeight=initialHeight;desk.userData.targetHeight=initialTarget;for(const part of desk.userData.parts){m.copy(part.base);m.elements[13]+=(desk.userData.currentHeight-.73)*part.factor;if(part.level!==undefined&&part.level!==desk.userData.photoLevel)m.scale(zero);part.batch.setMatrixAt(part.index,m);part.batch.instanceMatrix.needsUpdate=true;}root.removeFromParent();root.clear();}
 function snapshot(){return {anchor:REVIEW_ANCHOR,status:'reviewCandidate',height:desk.userData.currentHeight,settings:{...settings},tableWidth:1.4,widthRatio:settings.width/1.4,panelParts:entries.filter(e=>panel(e.part)).length,tools:tools.map(t=>({asset:t.placement.asset,level:t.level,position:t.group.position.toArray(),size:t.asset.manifest.levels[t.level].size})),errors:library.errors};}
 update();return {root,update,set,dispose,snapshot};
}
