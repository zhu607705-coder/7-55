/** A temporary view of one instanced desk. All resources remain source-owned. */
export function createDeskInspectionProxy(THREE,desk){
 const parent=desk.parent,root=new THREE.Group();root.name='Selected desk inspection';root.userData={kind:'tool',reviewInspectionProxy:true,floor:desk.userData.floor};
 const entries=desk.userData.parts.map(part=>{const mesh=new THREE.Mesh(part.batch.geometry,part.batch.material);mesh.matrixAutoUpdate=false;mesh.castShadow=part.batch.castShadow;mesh.receiveShadow=part.batch.receiveShadow;root.add(mesh);return {part,mesh};});
 parent.add(root);const inverse=new THREE.Matrix4(),matrix=new THREE.Matrix4();let disposed=false;
 function update(){if(disposed)return;parent.updateWorldMatrix(true,false);inverse.copy(parent.matrixWorld).invert();for(const {part,mesh} of entries){part.batch.updateWorldMatrix(true,false);part.batch.getMatrixAt(part.index,matrix);mesh.matrix.copy(inverse).multiply(part.batch.matrixWorld).multiply(matrix);mesh.matrixWorldNeedsUpdate=true;}root.updateMatrixWorld(true);}
 function dispose(){if(disposed)return;disposed=true;root.removeFromParent();root.clear();/* Never dispose borrowed geometry/material/texture. */}
 update();return {root,update,dispose};
}
