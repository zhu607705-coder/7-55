// Dependency-free geometry guard; native AStar/physics is tested separately.
import assert from 'node:assert/strict';
import fs from 'node:fs';
import path from 'node:path';
import {createHash} from 'node:crypto';
const root=path.resolve(import.meta.dirname,'..');
const campus=path.join(root,'campuses/buct_haidian');
const read=p=>fs.readFileSync(path.join(campus,p));
const json=p=>JSON.parse(read(p));
const data=json('data/playable_route.json'),layers=json('data/layers.json');
const sha=v=>createHash('sha256').update(v).digest('hex');
let checks=0;
const check=(ok,message)=>{assert.ok(ok,message);checks++;};
const originalHashes={"route_waypoints":"04a810f0f03a8fc4e032ae77f6855a8b806bd0fd248f1895e67a774473a078f3","landmarks":"2e94b52e8f69760ce88719edf8fb80750e7b46cd6cca786041b6a806ca0a8abc","walkable_polygons":"16da02592c3d3b72ba4ebe9920db20cd52099387f7ae7e226536de227b363a22","occluders":"03f1b7c8546c97edd19ece520bb23547742837d7cae2fd5b6badce2421eba677"};
for(const [key,expected] of Object.entries(originalHashes)){
 const value=key==='walkable_polygons'?data[key].slice(0,26):key==='occluders'?data[key].slice(0,7):data[key];
 check(sha(JSON.stringify(value))===expected,`Original ${key} unchanged`);
}
for(const [file,hash] of Object.entries({"assets/approved-haidian.png": "b5a95f81d89819cc54a346c5ec8e22abd7cd2bc7814b7daf5b65d0145bf72c63", "data/layers.json": "ea71503c3fc27ce2928aa1ce92239d2358f8f7a9ee8530a07e43015bde4d581c", "scenes/registered_layers.tscn": "41d6a2cc735c7c49528a60d50e9edbfe33327c61ce8616e669a45e502446e8d1", "scripts/campus_visitor.gd": "a9d2c216e81427cf7cbc3c9672bfd6b6a129b4e5a2b8a4910b4cdc3d365c1c33", "data/buildings/teaching-profile.json": "07964525d564e421d4ece0db5221dd5a78c9352633eaf3e8c4c57e2bc254adfb", "rongmao/data/library-profile.json": "cd798ec9375bd2b5a851008fc08520ddaf27307de9494db599946dcbbc02c06a"}))check(sha(read(file))===hash,`Accepted source unchanged: ${file}`);
check(data.walkable_polygons.length===30,'Exactly four added clear street segments');
check(data.exploration_sectors[0].centreline.at(-1).join(',')==='935,368','Clear street stops before deferred foliage segment');
check(data.exploration_sectors.length===1,'Uncertain hall crossing excluded entirely');
check(data.route_waypoints.length===25&&data.landmarks.length===3,'Original guide and three POIs');
check(data.spawn.join(',')==='963,297','Original spawn unchanged');
function distanceSegment(p,a,b){const dx=b[0]-a[0],dy=b[1]-a[1],n=dx*dx+dy*dy;const t=n?Math.max(0,Math.min(1,((p[0]-a[0])*dx+(p[1]-a[1])*dy)/n)):0;return Math.hypot(p[0]-a[0]-t*dx,p[1]-a[1]-t*dy);}
function inside(p,poly){let hit=false;for(let i=0,j=poly.length-1;i<poly.length;j=i++){const a=poly[i],b=poly[j];if(distanceSegment(p,a,b)<1e-8)return true;if((a[1]>p[1])!==(b[1]>p[1])&&p[0]<(b[0]-a[0])*(p[1]-a[1])/(b[1]-a[1])+a[0])hit=!hit;}return hit;}
const cache=polys=>polys.map(poly=>({poly,x0:Math.min(...poly.map(p=>p[0])),x1:Math.max(...poly.map(p=>p[0])),y0:Math.min(...poly.map(p=>p[1])),y1:Math.max(...poly.map(p=>p[1]))}));
const polys=cache(data.walkable_polygons),old=cache(data.walkable_polygons.slice(0,26));
const teaching=json('data/buildings/teaching-profile.json'),library=json('rongmao/data/library-profile.json');
const blocks=cache(layers.objects.flatMap(o=>o.id==='main_building'?teaching.collision_polygons_source_xy:o.id==='library'?library.collision_polygons_source_xy:o.footprints));
const paved=(p,polys)=>polys.some(b=>p[0]>=b.x0&&p[0]<=b.x1&&p[1]>=b.y0&&p[1]<=b.y1&&inside(p,b.poly));
function walkable(p,ground=polys){
 if(![[0,0],[3,0],[-3,0],[0,3],[0,-3]].every(o=>paved([p[0]+o[0],p[1]+o[1]],ground)))return false;
 if(blocks.some(b=>p[0]>=b.x0-3.2&&p[0]<=b.x1+3.2&&p[1]>=b.y0-3.2&&p[1]<=b.y1+3.2&&(inside(p,b.poly)||b.poly.some((a,i)=>distanceSegment(p,a,b.poly[(i+1)%b.poly.length])<3.2))))return false;
 return !data.occluders.some(o=>!o.visual_only&&Math.hypot(p[0]-o.anchor[0],p[1]-o.anchor[1])<o.trunk_radius+3.2);
}
// Regression for the reviewed subpixel paving join. Do not reduce the foot radius.
for(let j=0;j<=32;j++)check(walkable([954,314+4*j/32]),'Original failing native join edge is clear at radius 3: '+j);
check(data.occluders.length===8&&data.occluders[7].id==='east_road_south_east_crown','Only the necessary kept-street leaf group is added');
check(!data.occluders.some(o=>o.id==='east_road_hall_north_crown'),'Dropped hall branch leaves do not return');
const allowed=new Set();
for(let x=125;x<258;x++)for(let y=68;y<130;y++)if(walkable([x*4+2,y*4+2]))allowed.add(`${x},${y}`);
const nearest=p=>{let best=null,d=Infinity;for(const c of allowed){const [x,y]=c.split(',').map(Number),n=Math.hypot(p[0]-x*4-2,p[1]-y*4-2);if(n<d){best=c;d=n;}}return {cell:best,distance:d};};
const queue=[nearest(data.spawn).cell],reached=new Set(queue);
for(let i=0;i<queue.length;i++){
 const [x,y]=queue[i].split(',').map(Number);
 for(const [dx,dy] of [[1,0],[-1,0],[0,1],[0,-1],[1,1],[1,-1],[-1,1],[-1,-1]]){
  const next=`${x+dx},${y+dy}`;if(!allowed.has(next)||reached.has(next))continue;
  if(dx&&dy&&(!allowed.has(`${x+dx},${y}`)||!allowed.has(`${x},${y+dy}`)))continue;
  if(!Array.from({length:17},(_,j)=>walkable([x*4+2+dx*4*j/16,y*4+2+dy*4*j/16])).every(Boolean))continue;
  reached.add(next);queue.push(next);
 }
}
const newCells=[...allowed].filter(c=>{const [x,y]=c.split(',').map(Number);return !walkable([x*4+2,y*4+2],old);});
check(newCells.length>0&&newCells.every(c=>reached.has(c)),'Every added source-grid cell connects to original spawn: '+JSON.stringify(newCells.filter(c=>!reached.has(c))));
for(const p of data.exploration_destinations){check(!walkable(p.position,old),`Previously blocked: ${p.id}`);check(walkable(p.position)&&reached.has(nearest(p.position).cell),`New reachable endpoint: ${p.id}`);}
for(const p of data.excluded_probe_points)check(!walkable(p.position),`Forbidden surface remains blocked: ${p.id}`);
for(const b of data.exploration_sectors)for(let i=1;i<b.centreline.length;i++){
 const a=b.centreline[i-1],z=b.centreline[i],n=Math.ceil(Math.hypot(z[0]-a[0],z[1]-a[1])*2);
 for(let j=0;j<=n;j++)check(walkable([a[0]+(z[0]-a[0])*j/n,a[1]+(z[1]-a[1])*j/n]),`Radius-3 centreline clearance ${b.id}/${i}/${j}`);
}
for(const o of data.occluders.slice(7)){
 check(o.id.startsWith('east_road_')&&o.source==='assets/approved-haidian.png'&&!o.alpha_mask,'Bounded source-UV foliage, no new texture');
 check(o.visual_only&&o.trunk_radius===0,'Unverified stem has no speculative physical collider');
 check(o.polygon.length>=4,'Explicit source crown contour');
}
console.log(JSON.stringify({suite:'BUCT_HAIDIAN_EAST_ROADS_SOURCE',result:'PASS',checks,new_cells:newCells.length,all_new_cells_connected:true,old_polygons:26,new_polygons:4,old_guide_points:25,old_pois:3,engine_run:false}));
