import fs from 'node:fs';
import assert from 'node:assert/strict';
import {canStand,moveBody,nearestSafe,inPolygon,segmentDistance} from '../web/collision.js';
const layout=JSON.parse(fs.readFileSync(new URL('../web/assets/layout.json',import.meta.url)));
const rows=[];let checks=0;
const check=(value,label)=>{checks++;rows.push({label,pass:!!value});assert.ok(value,label);};
for(const [floor,data] of Object.entries(layout.floors)) {
 const spawn=nearestSafe(layout,floor,data.spawn);check(canStand(layout,floor,...spawn),`${floor}F corridor spawn`);
 check(!canStand(layout,floor,-1,2)&&!canStand(layout,floor,layout.width+1,2),`${floor}F exterior is blocked`);
 for(const room of data.rooms){const p=nearestSafe(layout,floor,room.spawn);const [a,b,c,d]=room.bounds;check(canStand(layout,floor,...p),`${floor}F ${room.id} safe start`);check(p[0]>a&&p[0]<c&&p[1]>b&&p[1]<d,`${floor}F ${room.id} spawn remains in selected room`);}
 for(const poly of data.voids){const x=poly.reduce((n,p)=>n+p[0],0)/poly.length,z=poly.reduce((n,p)=>n+p[1],0)/poly.length;check(!canStand(layout,floor,x,z),`${floor}F atrium has no walkable floor`);}
 // Actual layout wall: high displacement cannot tunnel through a thin wall.
 const wall=data.colliders.find(c=>c.segment&&Math.abs(c.segment[0][0]-c.segment[1][0])<.01&&c.segment[0][0]>2&&c.segment[0][0]<layout.width-2);
 if(wall){const [a,b]=wall.segment,z=(a[1]+b[1])/2;let p=nearestSafe(layout,floor,[a[0]-.8,z]);const moved=moveBody(layout,floor,p,1.6,0);check(canStand(layout,floor,...moved),`${floor}F swept movement remains valid`);if(p[0]<a[0])check(moved[0]<a[0],`${floor}F high-speed wall crossing blocked`);}
 // Grid traversal proves every room doorway reaches the same circulation network.
 const step=.08,nx=Math.ceil(layout.width/step),nz=Math.ceil(layout.length/step),valid=new Uint8Array(nx*nz);
 for(let iz=0;iz<nz;iz++)for(let ix=0;ix<nx;ix++)valid[iz*nx+ix]=canStand(layout,floor,(ix+.5)*step,(iz+.5)*step)?1:0;
 const indexNear=p=>{let best=-1,dist=Infinity;for(let i=0;i<valid.length;i++)if(valid[i]){const d=Math.hypot((i%nx+.5)*step-p[0],(Math.floor(i/nx)+.5)*step-p[1]);if(d<dist){best=i;dist=d;}}return best;};
 const seen=new Uint8Array(valid.length),queue=[indexNear(spawn)];seen[queue[0]]=1;
 for(let i=0;i<queue.length;i++){const k=queue[i],x=k%nx,z=Math.floor(k/nx);for(const [dx,dz] of [[1,0],[-1,0],[0,1],[0,-1]]){const xx=x+dx,zz=z+dz;if(xx<0||xx>=nx||zz<0||zz>=nz)continue;const n=zz*nx+xx;if(valid[n]&&!seen[n]){seen[n]=1;queue.push(n);}}}
 for(const room of data.rooms)check(seen[indexNear(nearestSafe(layout,floor,room.spawn))]===1,`${floor}F ${room.id} joins common door/corridor network`);
 if(floor==='2'){
  const r=data.rooms.find(r=>r.id==='mechatronics'),x=r.bounds[0]+.90,z=r.partition_z;
  for(const [label,p] of [['electrical side',[x,z-.8]],['machining side',[x,z+.8]]]){
   check(canStand(layout,floor,...p),`lab partition ${label} clear floor`);
   check(seen[indexNear(p)]===1,`lab partition ${label} reaches corridor through an actual doorway`);
  }
  check(canStand(layout,floor,x,z),'1.2m acoustic-partition opening is walkable at eye-body radius');
 }
 if(floor==='4'){
  const zones=['focus','collab','flex'].map(id=>data.rooms.find(r=>r.id===id));
  for(const r of zones)check(r.enclosure==='open',`${r.id} remains a connected open work zone`);
  for(let i=0;i<2;i++){
   const a=zones[i],b=zones[i+1],x=(a.bounds[0]+a.bounds[2])/2,z=(a.bounds[3]+b.bounds[1])/2;
   check(canStand(layout,floor,x,z),`open zones ${a.id}/${b.id} have no inherited dividing wall`);
  }
 }

}
// Recoverability: reverse input can leave a blocked surface, without teleporting.
const p=nearestSafe(layout,'3',[.5,.5]);const blocked=moveBody(layout,'3',p,-100,0),away=moveBody(layout,'3',blocked,.7,0);check(away[0]>blocked[0]+.5,'reverse/away motion is not suppressed by a stale blocked flag');
fs.writeFileSync(new URL('../review/collision_validation.json',import.meta.url),JSON.stringify({checks,failures:0,rows},null,2));console.log(`Collision/navigation: ${checks} checks passed`);
