/** Reversible display-only transforms. Never edits layout, mesh geometry or colliders.
 * Caller owns the scene and textures. This module owns only its cloned materials.
 * Call apply after changing floor finishes or adding review poster nodes.
 */
export function createSpatialPresentation(THREE,roots,layout){
 const originalRoots=new Map(),originalNodes=new Map(),clones=new Set(),cloneSources=new WeakMap(),cache=new WeakMap(),visibilityOverrides=new Map();
 let disposed=false;
 function capture(){
  for(const [floor,root] of roots){
   if(!layout.floors[floor])continue; // 1F is a caller-owned unverified placeholder.
   if(!originalRoots.has(root))originalRoots.set(root,{position:root.position.clone(),visible:root.visible});
   root.traverse(node=>{if(!originalNodes.has(node))originalNodes.set(node,{visible:node.visible,material:node.material});});
  }
 }
 capture();
 function materialFor(material,key){
  const source=cloneSources.get(material)||material;
  let byKey=cache.get(source);if(!byKey){byKey=new Map();cache.set(source,byKey);}
  if(!byKey.has(key)){const clone=source.clone();cloneSources.set(clone,source);clones.add(clone);byKey.set(key,clone);}
  return byKey.get(key);
 }
 function directKind(node){
  if(node.userData.reviewPoster)return 'poster';
  if(node.userData.kind)return node.userData.kind;
  if(node.userData.adjustableDesk||node.userData.inspectable||node.userData.chairInstances||node.userData.deskEntries)return 'furniture';
  return '';
 }
 function inheritedKind(node,root){
  for(let owner=node;owner&&owner!==root;owner=owner.parent)if(owner.userData.reviewPoster)return 'poster';
  for(let owner=node;owner&&owner!==root;owner=owner.parent){const kind=directKind(owner);if(kind)return kind;}
  return '';
 }
 function restoreOverrides(){for(const [node,visible] of visibilityOverrides)node.visible=visible;visibilityOverrides.clear();}
 function overrideVisibility(node,visible){if(!visibilityOverrides.has(node))visibilityOverrides.set(node,node.visible);node.visible=visible;}
 function apply(state,catalog){
  if(disposed)throw new Error('Spatial presentation disposed');
  capture();restoreOverrides();
  const walking=state.mode==='walk',expanded=!!state.expanded&&!walking;
  const selectedFloor=String(state.floor),room=(!walking&&!expanded&&state.room)?layout.floors[selectedFloor]?.rooms.find(r=>r.id===state.room):null;
  for(const [floor,root] of roots){
   if(!layout.floors[floor])continue;
   const base=originalRoots.get(root);root.position.copy(base.position);
   if(expanded)root.position.y+=(Number(floor)-1)*5+layout.rise;
   root.visible=expanded||floor===selectedFloor;
   // Only top-level visibility is ours: preserve dynamic LOD children unchanged.
   for(const child of root.children){
    const kind=directKind(child);
    if(kind==='poster')overrideVisibility(child,true);
    else if(kind==='ceiling')overrideVisibility(child,walking);
    else if(floor==='4'&&!walking&&(kind==='furniture'||kind==='tool'))overrideVisibility(child,false);
   }
   root.traverse(mesh=>{
    if(!mesh.isMesh||!mesh.material)return;
    const kind=inheritedKind(mesh,root),planes=[];
    if(room&&floor===selectedFloor&&kind!=='poster'){
     const [x0,z0,x1,z1]=room.bounds;
     planes.push(new THREE.Plane(new THREE.Vector3(1,0,0),-x0),new THREE.Plane(new THREE.Vector3(-1,0,0),x1),new THREE.Plane(new THREE.Vector3(0,0,1),-z0),new THREE.Plane(new THREE.Vector3(0,0,-1),z1));
    }
    if(kind==='wall'&&!walking)planes.push(new THREE.Plane(new THREE.Vector3(0,-1,0),root.position.y+1.22));
    const configure=material=>{const clone=materialFor(material,`${floor}/${kind}`);clone.clippingPlanes=planes;clone.clipIntersection=false;return clone;};
    mesh.material=Array.isArray(mesh.material)?mesh.material.map(configure):configure(mesh.material);
   });
   root.updateMatrixWorld(true);
  }
 }
 function restore(){
  restoreOverrides();
  for(const [root,base] of originalRoots){root.position.copy(base.position);root.visible=base.visible;root.updateMatrixWorld(true);}
  for(const [node,original] of originalNodes){node.visible=original.visible;if(original.material!==undefined)node.material=original.material;}
 }
 function dispose(){if(disposed)return;restore();clones.forEach(material=>material.dispose());clones.clear();disposed=true;}
 return {apply,restore,dispose,snapshot(){return {disposed,materialClones:clones.size,floors:[...roots].filter(([f])=>layout.floors[f]).map(([floor,root])=>({floor,visible:root.visible,position:root.position.toArray()}))};}};
}
