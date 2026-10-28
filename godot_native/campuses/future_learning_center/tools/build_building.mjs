import fs from 'node:fs';
import path from 'node:path';
import {fileURLToPath} from 'node:url';
import {execFileSync} from 'node:child_process';
import {buildOtherFloors,core,point} from './build_other_floors.mjs';
const root=path.resolve(path.dirname(fileURLToPath(import.meta.url)),'..');
const read=n=>JSON.parse(fs.readFileSync(path.join(root,'data',n),'utf8'));
const write=(n,v)=>fs.writeFileSync(path.join(root,'data',n),JSON.stringify(v,null,2)+'\n');
const assets=read('room_assets.json'),props=read('object_assets.json');
const rect=([x,y,w,h])=>[[x,y],[x+w,y],[x+w,y+h],[x,y+h]];
const bounds=poly=>{const xs=poly.map(p=>p[0]),ys=poly.map(p=>p[1]);return [Math.min(...xs),Math.min(...ys),Math.max(...xs)-Math.min(...xs),Math.max(...ys)-Math.min(...ys)];};
const inside=(q,vertices)=>{let yes=false;for(let i=0,j=vertices.length-1;i<vertices.length;j=i++){const a=vertices[i],b=vertices[j];if((a[1]>q[1])!==(b[1]>q[1])&&q[0]<(b[0]-a[0])*(q[1]-a[1])/(b[1]-a[1])+a[0])yes=!yes;}return yes;};
const intersects=(a,b)=>a[0]<b[0]+b[2]&&a[0]+a[2]>b[0]&&a[1]<b[1]+b[3]&&a[1]+a[3]>b[1];
execFileSync(process.execPath,[path.join(root,'tools/build_floor.mjs')],{stdio:'inherit'});
buildOtherFloors();

function upgradeThree(p){
 p.schema=2;p.transits=[];p.windows=[];p.objects=[];
 const oldService=p.modules.find(r=>r.id==='west_services');
 p.modules=p.modules.filter(r=>!['northeast_core','west_services'].includes(r.id));
 p.ground=p.ground.filter(r=>r.id!=='northeast_landing');
 const c=core(p,{westX:180,westW:1344,eastX:3801,eastW:1344,serviceY:oldService.at[1],stairY:oldService.at[1]+900});
 const y=c.lift.at[1]+c.lift.bounds[3];
 p.ground.push({id:'northeast_landing',polygon:rect([3801,y,1344,1880-y])});
 p.northeastLanding={bounds:[3801,y,1344,1880-y]};
 const bottom=Math.max(p.world[1]-180,c.sw.at[1]+c.sw.bounds[3]);
 p.ground.push({id:'west_corridor_extension',polygon:rect([1524,oldService.at[1],420,bottom-oldService.at[1]])});
 p.world[1]=bottom+180;
 for(const t of p.transits){
  const x=t.id==='southwest_stair'?1734:3591;
  p.waypoints.push({id:t.id,point:t.arrival},{id:t.id+'_hall',point:[x,t.arrival[1]]});
  p.links.push([t.id,t.id+'_hall']);
  const nearest=p.waypoints.filter(q=>q.id.startsWith(t.id==='southwest_stair'?'hall_0_':'hall_1_')).sort((a,b)=>Math.abs(a.point[1]-t.arrival[1])-Math.abs(b.point[1]-t.arrival[1]))[0];
  p.links.push([t.id+'_hall',nearest.id]);
 }
 for(const r of p.modules)if(r.asset)r.sourceSize=assets[r.asset].size;
}

const names={desk:'工作桌',chair_back:'网布工作椅',chair_front:'网布工作椅',monitor:'27 英寸显示器',monitor_front:'支架显示器',desk_divider:'桌面低隔板',workbench:'机电实验台',cabinet:'个人储物柜',discussion_table:'拼接研讨桌',whiteboard:'移动白板',printer_3d:'封闭式 3D 打印机',camera_tripod:'录制相机',sofa:'双人沙发',pantry_counter:'茶水台',tool_cart:'移动工具车',parts_rack:'元件收纳架',coffee_machine:'咖啡机',potted_plant:'室内绿植',soldering_station:'焊接工作站'};
function furnish(p){
 p.objects=[];p.windows=[];p.lighting={orientation:'north-up',sunArc:'east-south-west',clock:'presentation-only',hours:[8,12,16,21],floorMaterial:'continuous gray microcement',source:'window apertures on generated room masters'};
 const reserved=[p.spawn,...p.doors.flatMap(d=>[d.inside,d.outside])];
 function put(room,asset,at,width,options={}){
  const a=props[asset],b=a.opaqueBounds,crop=[b[0],b[1],b[2]-b[0],b[3]-b[1]];
  const maxHeight=({cabinet:102,whiteboard:96,parts_rack:110,tool_cart:65,potted_plant:78})[asset];
  if(maxHeight)width=Math.min(width,maxHeight*crop[2]/crop[3]);
  const scale=width/crop[2],h=crop[3]*scale;
  const footprint=[at[0]-width*.44,at[1]-(options.depth??width*.35),width*.88,options.depth??width*.35];
  const floor=p.ground.find(g=>g.id===room.id+'_floor_0')?.polygon;
  if(!floor)return null;
  if(!options.mounted){
   if(!rect(footprint).every(q=>inside(q,floor)))return null;
   if(reserved.some(q=>intersects(footprint,[q[0]-60,q[1]-45,120,90])))return null;
   if(p.objects.some(o=>{
    const gap=options.cluster&&o.cluster===options.cluster?0:18;
    return !o.mounted&&intersects(footprint,[o.footprint[0]-gap,o.footprint[1]-gap,o.footprint[2]+2*gap,o.footprint[3]+2*gap]);
   }))return null;
  }
  const object={id:room.id+'_'+asset+'_'+p.objects.length,room:room.id,asset,name:names[asset],path:a.path,crop,scale,bounds:[at[0]-width/2,at[1]-h,width,h],footprint,baseline:options.baseline??at[1],height:options.height??(asset==='cabinet'?120:65),floor,mounted:options.mounted??false,...(options.parent?{parent:options.parent}:{}),...(options.cluster?{cluster:options.cluster}:{})};
  p.objects.push(object);return object;
 }
 function station(r,x,y,monitor=true,cluster=null){
  const d=put(r,'desk',[x,y],118,{depth:42,cluster});if(!d)return;
  put(r,'chair_back',[x,y+68],42,{depth:28});
  if(monitor){
   put(r,'desk_divider',[x,y-52],106,{mounted:true,parent:d.id,baseline:y+.05,height:28});
   put(r,'monitor_front',[x,y-37],40,{mounted:true,parent:d.id,baseline:y+.1,height:28});
  }
 }
 function studio(r){
  // The supplied team-room reference has continuous desk banks and storage at
  // the edge. Keep player/prop scale fixed; arrange eight seats around a clear
  // central aisle instead of scattering individual desks across the room.
  const [x,y,w,h]=bounds(p.ground.find(g=>g.id===r.id+'_floor_0').polygon);
  for(const [row,cy] of [y+125,y+h-79].entries())
   for(let col=0;col<4;col++)station(r,x+150+col*118,cy,true,r.id+'_bank_'+row);
  put(r,'cabinet',[x+w*.83,y+105],150,{depth:48,height:120});
  put(r,'whiteboard',[x+w*.83,y+h-55],150,{depth:35,height:125});
 }
 function platform(r){
  // Review-only activity islands around the edge. The user's open platform
  // has no invented door or central obstacle; its middle remains traversable.
  const [x,y,w,h]=bounds(p.ground.find(g=>g.id===r.id+'_floor_0').polygon);
  for(const [u,v] of [[.18,.19],[.80,.73]]){
   const cx=x+w*u,cy=y+h*v;
   put(r,'discussion_table',[cx,cy],240,{depth:132});
   for(const dx of [-65,65])put(r,'chair_back',[cx+dx,cy+55],42,{depth:28});
   put(r,'whiteboard',[cx+185,cy-12],110,{depth:30});
  }
  const d=put(r,'desk',[x+w*.79,y+h*.20],118,{depth:42});
  if(d)put(r,'printer_3d',[d.bounds[0]+d.bounds[2]/2,d.baseline-43],44,{mounted:true,parent:d.id,baseline:d.baseline+.1});
  put(r,'camera_tripod',[x+w*.79,y+h*.20+175],65,{depth:38});
 }
 function grid(r,cols,rows,{monitor=true,compact=false}={}){
  const f=p.ground.find(g=>g.id===r.id+'_floor_0');if(!f)return;
  const [x,y,w,h]=bounds(f.polygon);
  for(let row=0;row<rows;row++)for(let col=0;col<cols;col++)station(r,compact?x+w*.25+col*118:x+w*(.20+.60*(cols===1?.5:col/(cols-1))),y+130+(h-280)*(rows===1?.5:row/(rows-1)),monitor,compact?r.id+'_row_'+row:null);
 }
 function discussion(r){
  const [x,y,w,h]=bounds(p.ground.find(g=>g.id===r.id+'_floor_0').polygon);
  const cx=x+w*.43,cy=y+h*.59;
  const table=put(r,'discussion_table',[cx,cy],340,{depth:190});
  if(table)for(const [dx,dy,kind] of [[-90,-205,'chair_front'],[90,-205,'chair_front'],[-90,70,'chair_back'],[90,70,'chair_back'],[-185,-55,'chair_front'],[185,-55,'chair_front']])put(r,kind,[cx+dx,cy+dy],42,{depth:28});
  put(r,'whiteboard',[x+w*.80,y+h*.48],150,{depth:35,height:125});
  put(r,'cabinet',[x+w*.77,y+h*.83],158,{depth:50,height:120});
 }
 function equipment(r){
  const [x,y,w,h]=bounds(p.ground.find(g=>g.id===r.id+'_floor_0').polygon);
  for(const t of [.25,.68])for(const v of [.30,.72])put(r,'workbench',[x+w*t,y+h*v],144,{depth:55,height:100});
  for(const t of [.31,.60])put(r,'cabinet',[x+w*t,y+h*.93],114,{depth:42});
  const d=put(r,'desk',[x+w*.48,y+h*.46],118,{depth:42});
  if(d)put(r,'printer_3d',[d.bounds[0]+59,d.baseline-43],44,{mounted:true,parent:d.id,baseline:d.baseline+.1});
 }
 for(const r of p.modules.filter(r=>r.asset&&!r.core)){
  if(!p.ground.some(g=>g.id===r.id+'_floor_0'))continue;
  if(r.id==='platform'){platform(r);continue;}
  if(r.id.startsWith('studio_')){studio(r);}
  else if(r.id==='focus_a')grid(r,2,8,{compact:true});
  else if(r.id==='collab_b')grid(r,2,6,{compact:true});
  else if(r.id==='flex_c')grid(r,5,2);
  else if(r.id==='xlab_north')grid(r,2,7);
  else if(r.id==='xlab_south'){grid(r,2,6);}
  else if(['formula','robotics','electrical','machinery'].includes(r.id))equipment(r);
  else if(['team','koala'].includes(r.id))grid(r,r.id==='koala'?6:3,2);
  else if(r.id.startsWith('seminar'))discussion(r);
  else if(r.id==='recording'){
   const [x,y,w,h]=bounds(p.ground.find(g=>g.id===r.id+'_floor_0').polygon);
   put(r,'sofa',[x+w*.38,y+h*.30],260,{depth:85});put(r,'camera_tripod',[x+w*.34,y+h*.75],72,{depth:50,height:125});station(r,x+w*.75,y+h*.60);
  }else if(r.id==='pantry'){
   const [x,y,w,h]=bounds(p.ground.find(g=>g.id===r.id+'_floor_0').polygon);
   put(r,'pantry_counter',[x+w*.62,y+h*.25],560,{depth:76});
   put(r,'sofa',[x+w*.30,y+h*.73],245,{depth:85});put(r,'sofa',[x+w*.69,y+h*.73],245,{depth:85});
  }else if(r.id==='storage'){
   const [x,y,w,h]=bounds(p.ground.find(g=>g.id===r.id+'_floor_0').polygon);
   for(const t of [.24,.60])for(const v of [.35,.70])put(r,'cabinet',[x+w*t,y+h*v],170,{depth:55});
  }
  const [fx,fy,fw,fh]=bounds(p.ground.find(g=>g.id===r.id+'_floor_0').polygon);
  if(['electrical','machinery'].includes(r.id)){
   for(const v of [.18,.47,.80])put(r,'parts_rack',[fx+fw*.85,fy+fh*v],125,{depth:45});
   for(const v of [.39,.76])put(r,'tool_cart',[fx+fw*.49,fy+fh*v],62,{depth:32});
   for(const bench of p.objects.filter(o=>o.room===r.id&&o.asset==='workbench'))
    put(r,'soldering_station',[bench.bounds[0]+bench.bounds[2]*.5,bench.baseline-65],45,{mounted:true,parent:bench.id,baseline:bench.baseline+.1});
  }
  if(['focus_a','collab_b','flex_c'].includes(r.id)){
   const count=r.id==='flex_c'?2:4;
   for(let i=0;i<count;i++)put(r,'cabinet',[fx+fw*.84,fy+fh*(.16+.67*i/(count-1))],100,{depth:36});
   put(r,'whiteboard',[fx+fw*.69,fy+fh*.52],110,{depth:30});
  }
  if(r.id==='pantry'){
   const counter=p.objects.find(o=>o.room===r.id&&o.asset==='pantry_counter');
   if(counter)put(r,'coffee_machine',[counter.bounds[0]+counter.bounds[2]*.70,counter.baseline-60],42,{mounted:true,parent:counter.id,baseline:counter.baseline+.1});
   for(const u of [.10,.88])put(r,'potted_plant',[fx+fw*u,fy+fh*.80],60,{depth:28});
  }
  // Aperture strips are measured in normalized source pixels, never inferred
  // from a room's generic screen position. No beam can spill outside its floor.
  const floor=p.ground.find(g=>g.id===r.id+'_floor_0').polygon;
  const [x,y,w,h]=bounds(floor);
  const sides=[];
  if(r.at[0]===180&&!['recording'].includes(r.id))sides.push('west');
  if(['electrical','machinery','focus_a','collab_b','flex_c','xlab_north','xlab_south'].includes(r.id))sides.push('east');
  if(['pantry','koala','flex_c'].includes(r.id))sides.push('south');
  if(r.id==='seminar')sides.push('north');
  for(const side of sides){
   const horizontal=['north','south'].includes(side),normal=({east:[1,0],west:[-1,0],south:[0,1],north:[0,-1]})[side];
   const count=horizontal?5:Math.max(2,Math.round(h/260));
   for(let i=0;i<count;i++){
    const t0=.14+.72*i/count,t1=t0+.55/count;
    const a=horizontal?[x+w*t0,side==='north'?y:y+h]:[side==='west'?x:x+w,y+h*t0];
    const b=horizontal?[x+w*t1,a[1]]:[a[0],y+h*t1];
    p.windows.push({id:r.id+'_'+side+'_'+i,room:r.id,a,b,normal,height:680,floor});
   }
  }
 }
 p.objectCounts=Object.fromEntries([...new Set(p.objects.map(o=>o.asset))].map(k=>[k,p.objects.filter(o=>o.asset===k).length]));
 // Keep reachability samples in the same room when a newly placed table occupies
 // the former empty-room centre. These are QA anchors, never story checkpoints.
 p.openSamples=p.openSamples.map(q=>{
  const floor=p.ground.find(g=>g.id.includes('_floor_')&&inside(q,g.polygon));
  if(!floor)return q;
  for(const d of [[0,0],[0,120],[0,-140],[180,0],[-180,0],[0,240],[240,120],[-240,120]]){
   const candidate=[q[0]+d[0],q[1]+d[1]],box=[candidate[0]-12,candidate[1]-10,24,20];
   if(rect(box).every(v=>inside(v,floor.polygon))&&!p.objects.some(o=>!o.mounted&&intersects(box,o.footprint)))return candidate;
  }
  throw new Error('No clear sample beside '+q);
 });
 p.status='three-floor furnished architecture and lighting review; not story integration';
 p.objectScope='Independent furniture, desk partitions, front-facing screens, tool carts, parts racks, soldering stations, coffee machine and plants. 3F studio grouping follows supplied design reference; lab/pantry object types follow supplied equipment requirements. 2F platform activity islands are game staging proposals. Exact site placement, unique team vehicles and specialist machines remain under review.';
}
for(const f of [2,3,4]){
 const p=read(`floor_${f}.json`);if(f===3)upgradeThree(p);
 furnish(p);write(`floor_${f}.json`,p);
 console.log(`${f}F: ${p.objects.length} separate objects, ${p.windows.length} window panes, ${p.transits.length} paired landings`);
}
