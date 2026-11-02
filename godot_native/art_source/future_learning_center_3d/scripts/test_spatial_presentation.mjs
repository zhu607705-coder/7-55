import assert from 'node:assert/strict';
import fs from 'node:fs';
import * as THREE from '../web/vendor/three/three.module.js';
import {createSpatialPresentation} from '../web/spatial_presentation.js';
const layout=JSON.parse(fs.readFileSync(new URL('../web/assets/layout.json',import.meta.url))),beforeLayout=JSON.stringify(layout);
let checks=0;function check(value,label){assert.ok(value,label);checks++;}
const source=new THREE.MeshStandardMaterial({color:0x607080}),texture=new THREE.Texture();source.map=texture;
const geometry=new THREE.BoxGeometry(1,1,1),positionsBefore=Array.from(geometry.attributes.position.array),roots=new Map(),nodes={};
for(const f of ['2','3','4']){
 const root=new THREE.Group();root.position.set(0,layout.floors[f].elevation,0);root.userData.floor=f;roots.set(f,root);nodes[f]={};
 for(const kind of ['floor','wall','ceiling','furniture']){const mesh=new THREE.Mesh(geometry,source);mesh.userData.kind=kind;root.add(mesh);nodes[f][kind]=mesh;}
 const lodParent=new THREE.Group();lodParent.userData.kind='furniture';const lod0=new THREE.Group(),lod1=new THREE.Group();lod1.visible=false;
 for(const group of [lod0,lod1])group.add(new THREE.Mesh(geometry,source));lodParent.add(lod0,lod1);root.add(lodParent);Object.assign(nodes[f],{lodParent,lod0,lod1});
 const inspectable=new THREE.Group();inspectable.userData.inspectable=true;inspectable.add(new THREE.Mesh(geometry,source));root.add(inspectable);nodes[f].inspectable=inspectable;
}
const placeholder=new THREE.Group();placeholder.position.y=-4.05;roots.set('1',placeholder);
const view=createSpatialPresentation(THREE,roots,layout),state={floor:'3',room:'xlab',mode:'overview',scope:'room',expanded:false};
view.apply(state);
check(roots.get('3').visible&&!roots.get('2').visible&&!roots.get('4').visible,'isolates selected floor');
check(nodes['3'].wall.material.clippingPlanes.length===5,'room sides plus wall top cap');
check(nodes['3'].floor.material.clippingPlanes.length===4,'floor gets room crop');
check(nodes['3'].wall.material!==nodes['3'].floor.material,'wall cap cannot leak into floor material');
check(nodes['2'].wall.material!==nodes['3'].wall.material,'shared source cloned independently by floor');
check(nodes['3'].floor.material.map===texture,'textures remain shared');
check(source.clippingPlanes===null&&source.map===texture,'source material untouched');
const room=layout.floors['3'].rooms.find(r=>r.id==='xlab'),[x0,z0,x1,z1]=room.bounds,inside=new THREE.Vector3((x0+x1)/2,4.1,(z0+z1)/2);
check(nodes['3'].floor.material.clippingPlanes.every(p=>p.distanceToPoint(inside)>0),'room interior retained');
for(const point of [[x0-.1,z0],[x1+.1,z0],[x0,z0-.1],[x0,z1+.1]])check(nodes['3'].floor.material.clippingPlanes.some(p=>p.distanceToPoint(new THREE.Vector3(point[0],4.1,point[1]))<0),'outside edge clipped');
const cloneCount=view.snapshot().materialClones;
for(let i=0;i<20;i++){
 view.apply({...state,scope:'building',expanded:true});
 check(Math.abs(roots.get('2').position.y-9.05)<1e-8&&Math.abs(roots.get('3').position.y-18.1)<1e-8&&Math.abs(roots.get('4').position.y-27.15)<1e-8,'noncumulative expanded offsets');
 view.apply({...state,mode:'walk',expanded:true});
 check([...roots].filter(([f])=>f!=='1').every(([f,r])=>r.position.y===layout.floors[f].elevation),'walk always physical coordinates');
 check(nodes['3'].floor.material.clippingPlanes.length===0&&nodes['3'].wall.material.clippingPlanes.length===0,'walk restores clipping');
 check(nodes['3'].ceiling.visible&&nodes['4'].furniture.visible&&nodes['4'].lodParent.visible&&nodes['4'].inspectable.visible,'walk restores office geometry and ceilings');
 check(!nodes['3'].lod1.visible&&nodes['3'].lod0.visible,'LOD child states preserved');
 view.apply(state);
}
check(view.snapshot().materialClones===cloneCount,'no repeated material allocation');
view.apply({...state,floor:'4',room:'',scope:'floor'});
check(!nodes['4'].furniture.visible&&!nodes['4'].lodParent.visible&&!nodes['4'].inspectable.visible,'office outline hides furnishing groups without deletion');
check(nodes['4'].floor.visible&&nodes['4'].wall.visible&&!nodes['4'].ceiling.visible,'office architecture retained');
const poster=new THREE.Mesh(geometry,source);poster.userData.reviewPoster=true;roots.get('4').add(poster);view.apply({...state,floor:'4',room:'seminar_1'});
check(poster.visible&&poster.material.clippingPlanes.length===0,'late poster remains visible outside room clipping');
check(placeholder.position.y===-4.05&&placeholder.visible,'unverified 1F remains caller owned');
const alternate=new THREE.MeshStandardMaterial({color:0xe2dfdb});nodes['3'].floor.material=alternate;view.apply(state);
check(nodes['3'].floor.material!==alternate&&nodes['3'].floor.material.color.equals(alternate.color),'later floor finish handled without modifying source');
check(alternate.clippingPlanes===null,'later finish source unchanged');
check(JSON.stringify(layout)===beforeLayout,'layout and collider bytes unchanged');
check(JSON.stringify(Array.from(geometry.attributes.position.array))===JSON.stringify(positionsBefore),'source geometry coordinates unchanged');
view.restore();
check([...roots].filter(([f])=>f!=='1').every(([f,r])=>r.visible&&r.position.y===layout.floors[f].elevation),'restore original root transform and visibility');
check(nodes['3'].floor.material===source&&poster.material===source,'restore original material references');
check(nodes['4'].furniture.visible&&!nodes['3'].lod1.visible,'restore original node visibility');
let textureDisposals=0,sourceDisposals=0;texture.addEventListener('dispose',()=>textureDisposals++);source.addEventListener('dispose',()=>sourceDisposals++);
view.dispose();view.dispose();check(textureDisposals===0&&sourceDisposals===0,'disposal does not own source resources');
assert.throws(()=>view.apply(state),/disposed/);checks++;
console.log(JSON.stringify({passed:checks,scope:'Actual Three.js transforms, clipping planes, material ownership, repeated transitions; not browser/GPU rendering.'},null,2));
