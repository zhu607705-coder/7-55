import fs from 'node:fs';
import path from 'node:path';
import {fileURLToPath} from 'node:url';
import {execFileSync} from 'node:child_process';
import {buildOtherFloors,core,point} from './build_other_floors.mjs';
const root=path.resolve(path.dirname(fileURLToPath(import.meta.url)),'..');
const read=n=>JSON.parse(fs.readFileSync(path.join(root,'data',n),'utf8'));
const write=(n,v)=>fs.writeFileSync(path.join(root,'data',n),JSON.stringify(v,null,2)+'\n');
const assets=read('room_assets.json'),props=read('object_assets.json'),atriumArt=read('atrium_asset.json');
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

const names={desk:'工作桌',chair_back:'网布工作椅',chair_front:'网布工作椅',monitor:'27 英寸显示器',monitor_front:'支架显示器',monitor_back:'支架显示器',desk_divider:'桌面低隔板',workbench:'机电实验台',cabinet:'个人储物柜',discussion_table:'拼接研讨桌',whiteboard:'移动白板',printer_3d:'封闭式 3D 打印机',camera_tripod:'录制相机',sofa:'双人沙发',pantry_counter:'茶水台',tool_cart:'移动工具车',parts_rack:'元件收纳架',coffee_machine:'咖啡机',potted_plant:'室内绿植',soldering_station:'焊接工作站'};
Object.assign(names,{pantry_island:'深灰色共享长桌',pantry_tree:'木盆绿植',pantry_chair_front:'木扶手座椅',pantry_chair_back:'木扶手座椅',pantry_microwave:'微波炉',pantry_wall_unit:'茶水柜与水槽'});
for(const color of ['orange','mint','slate','blue'])names['hall_stool_'+color]='彩色圆凳';
function furnish(p){
 p.objects=[];p.windows=[];p.lighting={orientation:'north-up',sunArc:'east-south-west',clock:'presentation-only',hours:[8,12,16,21],floorMaterial:'continuous gray microcement',source:'window apertures on generated room masters'};
 if(p.floor===3){
  // This isolated review starts beside the desk bank, away from the added seats.
  const [x,y,w,h]=bounds(p.ground.find(g=>g.id==='studio_1_floor_0').polygon);
  p.spawn=[x+w*.66,y+h*.5];
 }
 const reserved=[p.spawn,...p.doors.flatMap(d=>[d.inside,d.outside])];
 function put(room,asset,at,width,options={}){
  const a=props[asset],b=a.opaqueBounds,crop=[b[0],b[1],b[2]-b[0],b[3]-b[1]];
  const maxHeight=({cabinet:102,whiteboard:96,parts_rack:110,tool_cart:65,potted_plant:78,pantry_tree:150,pantry_wall_unit:190})[asset];
  if(maxHeight)width=Math.min(width,maxHeight*crop[2]/crop[3]);
  const scale=width/crop[2],h=crop[3]*scale;
  const footprint=[at[0]-width*.44,at[1]-(options.depth??width*.35),width*.88,options.depth??width*.35];
  const floor=p.ground.find(g=>g.id===(room.groundId??room.id+'_floor_0'))?.polygon;
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
  // Each existing four-seat bank gets its facing counterpart. Reuse upright
  // desk art; opposite chairs and monitor backs express the other orientation.
  // Two desk footprints meet at the shared divider, with chairs outside them.
  // Leave a continuous middle aisle and both ends open at the fixed prop scale.
  const [x,y,w,h]=bounds(p.ground.find(g=>g.id===r.id+'_floor_0').polygon);
  for(const [row,cy] of [y+140,y+h-60].entries()){
   const cluster=r.id+'_bank_'+row;
   for(let col=0;col<4;col++){
    const cx=x+150+col*118;
    const rear=put(r,'desk',[cx,cy-42],118,{depth:42,cluster});
    const front=put(r,'desk',[cx,cy],118,{depth:42,cluster});
    const chairs=[put(r,'chair_front',[cx,cy-100],42,{depth:28,cluster}),put(r,'chair_back',[cx,cy+44],42,{depth:28,cluster})];
    if(!rear||!front||chairs.some(c=>!c))throw new Error(`Facing workstation does not fit ${r.id} bank ${row} seat ${col}: rear=${!!rear} front=${!!front} chairs=${chairs.map(Boolean)}`);
    put(r,'monitor_back',[cx,cy-91],40,{mounted:true,parent:rear.id,baseline:rear.baseline+.1,height:28});
    put(r,'desk_divider',[cx,cy-74],106,{mounted:true,parent:front.id,baseline:cy+.05,height:28});
    put(r,'monitor_front',[cx,cy-37],40,{mounted:true,parent:front.id,baseline:cy+.1,height:28});
   }
  }
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
 function pantry(r){
  // User's on-site photo: fitted oak sink wall, a dark communal island with
  // a planter, mixed loose chairs, and a separate side worktop. No sofa pair.
  const [x,floorY,w,h]=bounds(p.ground.find(g=>g.id===r.id+'_floor_0').polygon);
  const y=floorY-60; // Put the fitted cabinet's rear edge against the north wall.
  const counter=put(r,'pantry_wall_unit',[x+w*.67,y+145],560,{depth:68,height:150});
  if(counter)for(const u of [.22,.78])
   put(r,'pantry_microwave',[counter.bounds[0]+counter.bounds[2]*u,counter.baseline-counter.bounds[3]*.31],44,{mounted:true,parent:counter.id,baseline:counter.baseline+.1});
  const cx=x+w*.57,cy=y+h*.70;
  const table=put(r,'pantry_island',[cx,cy],500,{depth:150,cluster:r.id+'_island'});
  if(!table)throw new Error('Photo-referenced pantry island does not fit');
  for(const dx of [-168,-56,56,168]){
   put(r,'pantry_chair_front',[cx+dx,cy-160],40,{depth:28,cluster:r.id+'_island'});
   put(r,dx<0?'chair_back':'pantry_chair_back',[cx+dx,cy+45],40,{depth:28,cluster:r.id+'_island'});
  }
  put(r,'pantry_tree',[cx-60,cy-table.bounds[3]*.67],112,{mounted:true,parent:table.id,baseline:table.baseline+.1,height:130});
  for(const dx of [105,223]){
   const desk=put(r,'desk',[x+dx,y+h*.48],118,{depth:42,cluster:r.id+'_side_table'});
   if(desk)put(r,'chair_back',[x+dx,y+h*.48+60],40,{depth:28,cluster:r.id+'_side_table'});
  }
 }
 function hall(){
  // The user confirmed 4F. This reversible placement uses an existing solid
  // landing; it does not turn any of the source plan's three voids into floor.
  const floor=p.ground.find(g=>g.id==='northeast_landing').polygon;
  const [x,y,w,h]=bounds(floor);
  const r={id:'hall',name:'四楼大厅',bounds:[x,y,w,h],groundId:'northeast_landing'};
  p.rooms.push(r);
  const a=props.hall_blue_frame,b=a.opaqueBounds,scale=420/(b[2]-b[0]);
  const front=[x+w*.50,y+h*.53],at=[front[0]-420/2,front[1]-(b[3]-b[1])*scale];
  const map=q=>[at[0]+(q[0]-b[0])*scale,at[1]+(q[1]-b[1])*scale];
  const worldRect=q=>[...map(q),q[2]*scale,q[3]*scale];
  const frontY=map([0,968])[1];
  // These seven non-overlapping regions partition the original alpha. The
  // four visible foot plates are the only colliders; the canopy is overhead.
  const parts=[
   ['rear_left',[334,528,390,187],[333,657,96,48],705],
   ['rear_right',[724,528,394,187],[1018,655,98,52],707],
   ['front_left',[152,528,182,187],[211,904,123,64],968],
   ['front_right',[1118,528,178,187],[1114,904,123,64],968],
   ['front_left_base',[152,715,572,253],null,968.01,'hall_frame_front_left'],
   ['front_right_base',[724,715,572,253],null,968.01,'hall_frame_front_right'],
   ['canopy',[152,98,1144,430],null,968.02],
  ];
  for(const [id,crop,foot,baseline,parent] of parts){
   const footprint=foot?worldRect(foot):[front[0]-1,frontY-1,2,2];
   if(foot&&!rect(footprint).every(q=>inside(q,floor)))throw new Error('Hall post outside existing floor: '+id);
   p.objects.push({id:'hall_frame_'+id,room:r.id,asset:'hall_blue_frame',name:foot?'蓝色构架立柱':'蓝色构架',path:a.path,crop,scale,bounds:worldRect(crop),footprint,baseline:map([0,baseline])[1],height:150,floor,mounted:!foot,...(parent?{parent}:{}),...(id==='canopy'?{actorOcclusionAlpha:.78}:{}),cluster:'hall_blue_frame'});
  }
  const colors=['orange','orange','slate','orange','mint','slate','blue','mint','slate','orange','mint','blue'];
  for(const [i,color] of colors.entries()){
   const at=[front[0]-105+(i%4)*37+(Math.floor(i/4)%2)*8,frontY+160+Math.floor(i/4)*31];
   if(!put(r,'hall_stool_'+color,at,32,{depth:19,height:36,cluster:'hall_stools'}))throw new Error('Hall stool does not fit: '+i);
  }
  for(const [color,dx,dy] of [['mint',150,190],['slate',-40,95]])
   if(!put(r,'hall_stool_'+color,[front[0]+dx,frontY+dy],32,{depth:19,height:36}))throw new Error('Loose hall stool does not fit');
  p.hallReference={floor:4,floorEvidence:'User explicitly confirmed 四楼 on 2026-10-28',photo:'593fd97a8125724eecc3966485abf05f.jpg',placement:'review placement within the existing northeast landing; exact site anchor remains unverified',frameCenter:[front[0],frontY-48],walkThrough:[[front[0],frontY-160],[front[0],frontY+55]],capture:[front[0]+240,frontY-8]};
  p.scopeNotes.push('用户确认蓝色构架和彩色圆凳大厅位于四楼。当前在既有东北大厅地面试摆，精确方位仍需实景对齐；三处挑空、门洞及交通核不变。');
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
  }else if(r.id==='pantry'){pantry(r);}else if(r.id==='storage'){
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
 if(p.floor===4)hall();
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
 p.objectScope='Independent furniture and mounted equipment. Four 3F studios use the user-requested facing-row duplication; the pantry uses six masters derived from user-supplied site photography. Laboratory objects follow the supplied equipment requirements. 2F platform activity islands are gameplay staging proposals. Exact site placement, room capacity, unique team vehicles and specialist machines remain under review.';
}
for(const f of [2,3,4]){
 const p=read(`floor_${f}.json`);if(f===3)upgradeThree(p);
 for(const atrium of [...(p.atriums??[]),...(p.atrium?[p.atrium]:[])]){
  atrium.source=atriumArt.path;atrium.crops=atriumArt.crops;
 }
 furnish(p);write(`floor_${f}.json`,p);
 console.log(`${f}F: ${p.objects.length} separate objects, ${p.windows.length} window panes, ${p.transits.length} paired landings`);
}
