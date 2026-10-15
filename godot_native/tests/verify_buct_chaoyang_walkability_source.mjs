// Dependency-free source/geometry guard on the accepted #126 + genuine-L scene. Native AStar and physical movement are tested separately.
import assert from 'node:assert/strict';
import fs from 'node:fs';
import path from 'node:path';
import {createHash} from 'node:crypto';
const project=path.resolve(import.meta.dirname,'..');
const campus=path.join(project,'campuses/buct');
const read=p=>fs.readFileSync(path.join(campus,p));
const data=JSON.parse(read('data/playable_route.json'));
const layers=JSON.parse(read('data/layers.json'));
const sha=v=>createHash('sha256').update(v).digest('hex');
const jsonSha=v=>sha(JSON.stringify(v));
let checks=0;
function check(value,message){assert.ok(value,message);checks++;}
for(const [key,value,expected] of [
 ['original guide',data.route_waypoints,'91e7042258804ab85181e3471c8e287c41215c6026e4c7437ee4d6a636e8c35c'],
 ['three landmarks',data.landmarks,'5f8c61b9e19050c26565152c54883bb3ab9b0f0238d0e6eed6ba4eeac6530225'],
 ['original paving',data.walkable_polygons.slice(0,22),'7fd9b07a232cd1012f0d7b9e56ac76eeece020558617daafc4da157a14baa75d'],
 ['original crowns',data.occluders.slice(0,8),'97fcd7a6b20a2c36b99a1d1e39d78e4e1878baf6bb6beae0efe489e7ea959c84']
])check(jsonSha(value)===expected,`Unchanged ${key}`);
for(const [file,expected] of Object.entries({
 'assets/approved-chaoyang.png':'b9d3c5ce191003bd30f959a51c16737c84dceb3f59985f703fe668ad274fc6e9',
 'data/layers.json':'2f978d0e43d1bfb6b172dbb485461c300fd1c736bc3424fbda606bb3c692d5c5',
 'scenes/registered_layers.tscn':'b708a21669d952bd465e4cfc39f70ad26ab1812645498b3fd34d9162045b151c',
 'scripts/campus_visitor.gd':'ab0b08ad8eb71f2dff5a75381f744140aa77b1256b66d6c9a93115bbd656c144'
}))check(sha(read(file))===expected,`Unchanged ${file}`);
check(data.walkable_polygons.length===57,'22 original and 35 additional paving polygons');
check(data.exploration_sectors.length===2,'Two bounded connected branches');
check(data.occluders.length===10,'Eight original and two small source-pixel roadside crown groups');
function distanceSegment(p,a,b){const dx=b[0]-a[0],dy=b[1]-a[1],n=dx*dx+dy*dy;const t=n?Math.max(0,Math.min(1,((p[0]-a[0])*dx+(p[1]-a[1])*dy)/n)):0;return Math.hypot(p[0]-a[0]-t*dx,p[1]-a[1]-t*dy);}
function inside(p,poly){let hit=false;for(let i=0,j=poly.length-1;i<poly.length;j=i++){const a=poly[i],b=poly[j];if(distanceSegment(p,a,b)<1e-8)return true;if((a[1]>p[1])!==(b[1]>p[1])&&p[0]<(b[0]-a[0])*(p[1]-a[1])/(b[1]-a[1])+a[0])hit=!hit;}return hit;}
const polygons=data.walkable_polygons.map(poly=>({poly,minX:Math.min(...poly.map(p=>p[0])),maxX:Math.max(...poly.map(p=>p[0])),minY:Math.min(...poly.map(p=>p[1])),maxY:Math.max(...poly.map(p=>p[1]))}));
const inPaving=p=>polygons.some(b=>p[0]>=b.minX&&p[0]<=b.maxX&&p[1]>=b.minY&&p[1]<=b.maxY&&inside(p,b.poly));
const lProfile=JSON.parse(read('data/west-inner-l-profile.json'));
check(sha(read('data/west-inner-l-profile.json'))==='005498b0edde4b5eb6fcee0d2b282befce9ab9879d2a02d074bbd3cca42bc09a','Accepted L depth, foliage and footprint profile remains immutable');
check(lProfile.collision_polygons_source_xy.length===3,'Accepted L building retains three ground contacts');
const footprints=layers.objects.flatMap(o=>o.id==='west_inner_l_block'?lProfile.collision_polygons_source_xy:o.footprints);
function walkable(p){
 if(![[0,0],[3,0],[-3,0],[0,3],[0,-3]].every(o=>inPaving([p[0]+o[0],p[1]+o[1]])))return false;
 if(footprints.some(poly=>inside(p,poly)||poly.some((a,i)=>distanceSegment(p,a,poly[(i+1)%poly.length])<3.2)))return false;
 return !data.occluders.some(o=>Math.hypot(p[0]-o.anchor[0],p[1]-o.anchor[1])<o.trunk_radius+3.2);
}
const allowed=new Set();
for(let x=0;x<362;x++)for(let y=0;y<272;y++)if(walkable([x*4+2,y*4+2]))allowed.add(`${x},${y}`);
function nearest(p){let best=null,d=Infinity;for(const key of allowed){const [x,y]=key.split(',').map(Number),q=[x*4+2,y*4+2],dist=Math.hypot(p[0]-q[0],p[1]-q[1]);if(dist<d){d=dist;best=key;}}return {key:best,distance:d};}
const start=nearest(data.spawn).key,queue=[start],parent=new Map([[start,null]]);
for(let index=0;index<queue.length;index++){
 const key=queue[index],[x,y]=key.split(',').map(Number);
 for(const [dx,dy] of [[0,-1],[1,0],[0,1],[-1,0],[1,1],[-1,1],[1,-1],[-1,-1]]){
  const next=`${x+dx},${y+dy}`;
  if(!allowed.has(next)||parent.has(next))continue;
  if(dx&&dy&&(!allowed.has(`${x+dx},${y}`)||!allowed.has(`${x},${y+dy}`)))continue;
  // Sample edges as well as nodes: no diagonal through a clipped paving corner.
  let clear=true;for(let j=0;j<=16;j++)if(!walkable([x*4+2+dx*4*j/16,y*4+2+dy*4*j/16]))clear=false;
  if(clear){parent.set(next,key);queue.push(next);}
 }
}
const newCells=[...allowed].filter(key=>{const [x,y]=key.split(',').map(Number);return data.walkable_polygons.slice(22).some(poly=>inside([x*4+2,y*4+2],poly));});
check(newCells.every(key=>parent.has(key)),'Every allowed added-sector grid cell belongs to the original spawn component');
const endpoints=[];
for(const item of data.exploration_endpoints){
 check(walkable(item.position),`Authored endpoint has foot clearance: ${item.id}`);
 const end=nearest(item.position);check(end.distance<=4,`Endpoint is not snapped across a boundary: ${item.id}`);
 check(parent.has(end.key),`Spawn connects to endpoint without diagonal cutting: ${item.id}`);
 let length=0,cursor=end.key,count=0;while(parent.get(cursor)){const p=parent.get(cursor),a=cursor.split(',').map(Number),b=p.split(',').map(Number);length+=4*Math.hypot(a[0]-b[0],a[1]-b[1]);cursor=p;count++;}
 endpoints.push({id:item.id,path_nodes:count+1,path_length_px:Number(length.toFixed(2)),endpoint:item.position});
}
for(const sector of data.exploration_sectors){
 check(sector.polygon_indices.length===sector.waypoints.length-1,`One attributed polygon per road segment: ${sector.id}`);
 check(sector.inferred_segments.every(i=>i>=0&&i<sector.polygon_indices.length),`Foliage-inferred connections explicitly indexed: ${sector.id}`);
 for(let i=1;i<sector.waypoints.length;i++){
  const a=sector.waypoints[i-1],b=sector.waypoints[i],steps=Math.ceil(Math.hypot(b[0]-a[0],b[1]-a[1])*2);
  for(let j=0;j<=steps;j++)check(walkable([a[0]+(b[0]-a[0])*j/steps,a[1]+(b[1]-a[1])*j/steps]),`Clear authored ${sector.id} segment ${i-1} sample ${j}`);
 }
}
for(const item of data.excluded_probe_points)check(!walkable(item.position),`Excluded surface remains blocked: ${item.id}`);
for(const item of data.occluders.slice(8)){
 check(item.trunk_radius===1.5,`Only small inferred tree foot: ${item.id}`);
 check(!walkable(item.anchor),`Inferred trunk remains blocked: ${item.id}`);
}
const report={schema:'buct-chaoyang-west-sector-source-check-v1',checks,source_size:data.canvas_size,original_guide_waypoints:data.route_waypoints.length,original_landmarks:data.landmarks.length,paving_polygons:data.walkable_polygons.length,additional_segments:35,additional_crown_groups:2,walkable_grid_cells:allowed.size,spawn_component_cells:parent.size,added_sector_cells:newCells.length,all_added_cells_connected:true,endpoints,blocked_probes:data.excluded_probe_points.map(p=>p.id),native_engine_tested:false,limit:'Conservative source-only geometry check. Not Godot AStar, physics, rendering, campus-wide coverage or surveyed navigation.'};
if(process.env.BUCT_WALKABILITY_REPORT)fs.writeFileSync(process.env.BUCT_WALKABILITY_REPORT,JSON.stringify(report,null,2)+'\n');
console.log(JSON.stringify(report,null,2));
