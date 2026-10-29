import fs from 'node:fs';
import path from 'node:path';
import {fileURLToPath} from 'node:url';
const root=path.resolve(path.dirname(fileURLToPath(import.meta.url)),'..');
const assets=JSON.parse(fs.readFileSync(path.join(root,'data/room_assets.json'),'utf8'));
const poly=([x,y,w,h])=>[[x,y],[x+w,y],[x+w,y+h],[x,y+h]];
const plate='res://campuses/future_learning_center/assets/floors/floor_3_overview_v1.png';
export function makePlan(floor){return {schema:2,floor,title:`未来学习中心 · ${floor}F`,source:'https://zju-xlab.feishu.cn/wiki/NKVGwp4KxikWgSktPoucZzsvnUf',status:'room-scale architectural review',scaleNote:'Game-space enlargement; source adjacency and orientation, not surveyed metric dimensions.',world:[],modules:[],ground:[],rooms:[],waypoints:[],links:[],doors:[],occluders:[],blockedSamples:[],openSamples:[],transits:[],windows:[],objects:[],atriums:[]};}
export const ground=(p,id,polygon)=>p.ground.push({id,polygon});
export function point(r,q){return [r.at[0]+(q[0]*r.sourceSize[0]-r.crop[0])*r.scale,r.at[1]+(q[1]*r.sourceSize[1]-r.crop[1])*r.scale];}
export function room(p,id,asset,name,at,width,floor,doors=[],focus=true){
 const a=assets[asset],b=a.opaqueBounds;
 const r={id,asset,name,path:a.path,at,crop:[b[0],b[1],b[2]-b[0],b[3]-b[1]],scale:width/(b[2]-b[0]),sourceSize:a.size};
 r.bounds=[...at,width,r.crop[3]*r.scale];p.modules.push(r);
 for(let i=0;i<floor.length;i++)ground(p,`${id}_floor_${i}`,floor[i].map(q=>point(r,q)));
 if(focus)p.rooms.push({id,name,group:id,bounds:r.bounds});
 for(const d of doors){
  const polygon=poly(d.rect).map(q=>point(r,q)),inside=point(r,d.inside),outside=point(r,d.outside);
  const key=`${id}_${d.id}`;ground(p,key,polygon);p.doors.push({id:key,room:id,inside,outside,polygon,side:d.id.split('_')[0]});
 }
 if(floor.length){
  const f=floor[0];const center=f.reduce((a,b)=>[a[0]+b[0]/f.length,a[1]+b[1]/f.length],[0,0]);
  p.openSamples.push(point(r,center));
 }
 p.blockedSamples.push(point(r,[.5,.08]));
 return r;
}
const eastDoor=(y)=>({id:'east',rect:[.865,y-.022,.17,.044],inside:[.875,y],outside:[1.025,y]});
const westDoor=(y,id='west')=>({id,rect:[-.025,y-.023,.215,.046],inside:[.18,y],outside:[-.025,y]});
const southDoor=(x)=>({id:'south',rect:[x-.038,.78,.076,.26],inside:[x,.79],outside:[x,1.035]});
const northDoor=(x,id='north')=>({id,rect:[x-.035,-.025,.07,.34],inside:[x,.30],outside:[x,-.025]});
const regular=[[[.17,.23],[.84,.23],[.91,.825],[.125,.825]]];
const eastFloor=[[[.185,.18],[.82,.18],[.88,.87],[.125,.87]]];
function moduleHeight(asset,width){const b=assets[asset].opaqueBounds;return (b[3]-b[1])*width/(b[2]-b[0]);}
function graph(p,xs,northY,southY){
 const ys=[northY,southY,...p.doors.map(d=>d.outside[1]),...p.transits.map(t=>t.arrival[1])].map(v=>Math.round(v));
 const all=[...new Set(ys)].sort((a,b)=>a-b);
 const wp=(id,point)=>p.waypoints.push({id,point});
 const inside=(q,vertices)=>{let yes=false;for(let i=0,j=vertices.length-1;i<vertices.length;j=i++){const a=vertices[i],b=vertices[j];if((a[1]>q[1])!==(b[1]>q[1])&&q[0]<(b[0]-a[0])*(q[1]-a[1])/(b[1]-a[1])+a[0])yes=!yes;}return yes;};
 for(let side=0;side<2;side++){let last=null;for(let i=0;i<all.length;i++){
  const q=[xs[side],all[i]];if(!p.corridors.some(r=>inside(q,r.polygon)))continue;
  const id=`hall_${side}_${i}`;wp(id,q);if(last)p.links.push([last,id]);last=id;
 }}
 for(const y of [northY,southY])p.links.push([`hall_0_${all.indexOf(Math.round(y))}`,`hall_1_${all.indexOf(Math.round(y))}`]);
 for(const d of p.doors){
  wp(d.id+'_in',d.inside);wp(d.id+'_out',d.outside);p.links.push([d.id+'_in',d.id+'_out']);
  const side=d.outside[0]>(xs[0]+xs[1])/2?1:0;
  if(d.side==='north'||d.side==='south'){
   const y=d.room==='seminar'||d.room==='storage'?northY:southY;
   const crossX=d.room==='flex_c'?xs[1]:d.outside[0];
   wp(d.id+'_cross',[crossX,y]);p.links.push([d.id+'_out',d.id+'_cross']);
   for(let s=0;s<2;s++)p.links.push([d.id+'_cross',`hall_${s}_${all.indexOf(Math.round(y))}`]);
  }else p.links.push([d.id+'_out',`hall_${side}_${all.indexOf(Math.round(d.outside[1]))}`]);
 }
 for(const t of p.transits){
  wp(t.id,t.arrival);const side=t.id==='southwest_stair'?0:1;
  p.links.push([t.id,`hall_${side}_${all.indexOf(Math.round(t.arrival[1]))}`]);
 }
}
export function contours(p,westX,westW,centerX,eastHallX,eastX){
 for(const r of p.modules.filter(m=>m.asset&&!m.core)){
  const left=[],right=[];
  for(const s of assets[r.asset].outerWallStrips){
   const y=r.at[1]+(s[0]-r.crop[1])*r.scale,h=(s[1]-s[0])*r.scale;
   const l=r.at[0]+(s[2]-r.crop[0])*r.scale,rr=r.at[0]+(s[3]-r.crop[0])*r.scale;
   left.push([l,y],[l,y+h]);right.push([rr,y],[rr,y+h]);
  }
  const top=r.at[1],bottom=top+r.bounds[3];
  if(r.at[0]===westX)ground(p,r.id+'_outside_e',[...right,[centerX,bottom],[centerX,top]]);
  if(r.at[0]===centerX){
   ground(p,r.id+'_outside_w',[[westX+westW,top],[westX+westW,bottom],...left.toReversed()]);
   if(r.bounds[2]<eastX-centerX)ground(p,r.id+'_outside_e',[...right,[eastX,bottom],[eastX,top]]);
  }
  if(r.at[0]===eastX)ground(p,r.id+'_outside_w',[[eastHallX,top],[eastHallX,bottom],...left.toReversed()]);
 }
}
export function core(p,positions){
 const {westX,westW,eastX,eastW,serviceY,stairY}=positions;
 // Exactly east-west flights. The elevator is a separate shaft BELOW the NE
 // stair; restrooms remain an opaque block ABOVE the SW stair.
 const ne=room(p,'northeast_stair_art','stairs_horizontal','东北楼梯',[eastX,380],eastW,[],[],false);ne.core=true;
 const lift=room(p,'elevator_art','elevator_west','电梯',[eastX+eastW*.40,ne.at[1]+ne.bounds[3]+12],eastW*.60,[],[],false);lift.core=true;
 const services=room(p,'services','service_closed','卫生间',[westX,serviceY],westW,[],[],false);services.core=true;
 const sw=room(p,'southwest_stair_art','stairs_horizontal','西南楼梯',[westX,Math.max(stairY,serviceY+services.bounds[3])],westW,[],[],false);sw.core=true;
 // Access lands on painted flat end-platforms; the flights and roofs stay solid.
 for(const [id,kind,r,side,center] of [
  ['northeast_stair','stairs',ne,'west',[.16,.5]],
  ['southwest_stair','stairs',sw,'east',[.84,.5]],
  ['elevator','elevator',lift,'west',[.075,.55]],
 ]){
  const at=point(r,center),width=side==='west'?at[0]-(eastX-210)+50:(westX+westW+210)-at[0]+50;
  ground(p,id+'_threshold',poly([side==='west'?eastX-210:at[0]-50,at[1]-55,width,110]));
  p.transits.push({id,kind,name:{northeast_stair:'东北楼梯',southwest_stair:'西南楼梯',elevator:'电梯'}[id],arrival:at,zone:[at[0]-48,at[1]-45,96,90],flightsAxis:kind==='stairs'?'east-west':undefined});
 }
 p.blockedSamples.push(point(lift,[.65,.50]),point(ne,[.50,.5]),point(services,[.5,.5]));
 return {ne,lift,services,sw};
}
function mechanical(p,at,width){const s=width/225;const r={id:'mechanical',path:plate,crop:[80,24,225,292],at,scale:s,bounds:[...at,width,292*s],overviewDetail:true};p.modules.push(r);}
function finalize(p,g,northY,southY,bottom){
 const {wx,ww,cx,cw,ex,ew,hw}=g,eh=cx+cw;
 ground(p,'west_corridor',poly([wx+ww,northY-180,hw,bottom-northY+180]));
 ground(p,'east_corridor',poly([eh,180,hw,(g.eastStop??bottom)-180]));
 ground(p,'north_cross',poly([wx+ww,northY-180,ex-wx-ww,360]));
 ground(p,'north_cross_extension',poly([wx+ww,northY,ex-wx-ww,1880-northY]));
 ground(p,'south_cross',poly([wx+ww,southY-180,(p.floor===2?ex+ew:ex)-wx-ww,360]));
 for(const d of p.doors){
  if(d.side==='east')ground(p,d.id+'_threshold',poly([d.inside[0]-10,d.inside[1]-25,wx+ww+hw/2-d.inside[0]+10,50]));
  if(d.side==='west'){
   const target=d.room==='classroom'?wx+ww+hw/2:eh+hw/2;
   ground(p,d.id+'_threshold',poly([target,d.inside[1]-25,d.inside[0]-target+10,50]));
  }
 }
 contours(p,wx,ww,cx,eh,ex);
 p.corridors=p.ground.filter(r=>/corridor|cross/.test(r.id));
 p.world=[ex+ew+180,bottom+180];p.blockedSamples.push([30,30]);
 graph(p,[wx+ww+hw/2,eh+hw/2],northY,southY);
 p.spawn=p.openSamples[0];
 fs.writeFileSync(path.join(root,`data/floor_${p.floor}.json`),JSON.stringify(p,null,2)+'\n');
 console.log(`${p.floor}F ${p.world.map(Math.round).join(' × ')}; ${p.rooms.length} rooms; ${p.doors.length} apertures`);
}
function floor2(){
 const p=makePlan(2);p.sourcePlan='d7e9b5e4023c60de0e5fb570d3a20b09.png; north seminar, three west studios, open central platform (user correction), east laboratory, south Koala';
 const wx=180,ww=1344,hw=420,mainY=1880,cx=wx+ww+hw;
 let y=mainY;
 for(const [id,asset,name,dy] of [['formula','f2_formula','方程式车队',.535],['team','f2_team','团队工作室',.56],['robotics','f2_robotics','ASABE 机器人团队',.55]]){
  const r=room(p,id,asset,name,[wx,y],ww,regular,[eastDoor(dy)]);y+=r.bounds[3]-18;
 }
 // Keep the reviewed game-space span independent of the rejected classroom art.
 const cw=1771,eh=cx+cw,ex=eh+hw,ew=1344;
 const platformAsset=assets.f2_platform,bounds=platformAsset.opaqueBounds;
 const platformScale=(y-mainY)/(bounds[3]-bounds[1]),platformWidth=(bounds[2]-bounds[0])*platformScale;
 const platform={id:'platform',asset:'f2_platform',name:'二楼开放大平台',path:platformAsset.path,sourceSize:platformAsset.size,crop:[bounds[0],bounds[1],bounds[2]-bounds[0],bounds[3]-bounds[1]],at:[cx+(cw-platformWidth)/2,mainY],scale:platformScale,bounds:[cx+(cw-platformWidth)/2,mainY,platformWidth,y-mainY],openPlatform:true};
 p.modules.push(platform);ground(p,'platform_floor_0',poly([cx-5,mainY-5,cw+10,y-mainY+10]));
 p.rooms.push({id:'platform',name:'二楼开放大平台',group:'platform',bounds:[cx,mainY,cw,y-mainY]});p.openSamples.push([cx+cw/2,(mainY+y)/2]);
 p.scopeNotes=['用户于 2026-10-28 明确：二楼中央是开放大平台，无围合房间和门。平台与环廊连续连通；实景设施待核实。'];
 room(p,'seminar','north_seminar','跨学科研讨室',[cx,120],cw,[[[.14,.26],[.875,.26],[.91,.80],[.11,.80]]],[southDoor(.74)]);
 const northY=Math.max(1480,moduleHeight('north_seminar',cw)+130);
 const labY=mainY+650;
 const lab=room(p,'electrical','f2_lab','机电开放实验室 · 电工区',[ex,labY],ew,eastFloor,[westDoor(.28,'west_a'),westDoor(.70,'west_b')]);
 const machine=room(p,'machinery','f2_machinery','机电开放实验室 · 机加工区',[ex,lab.at[1]+lab.bounds[3]-15],ew,eastFloor,[westDoor(.445)]);
 const southY=Math.max(y+250,machine.at[1]+machine.bounds[3]+170);
 const koala=room(p,'koala','f2_koala','考拉工作室',[cx,southY+180],ex+ew-cx,[[[.08,.31],[.92,.31],[.95,.77],[.05,.77]]],[northDoor(.21,'north_a'),northDoor(.79,'north_b')]);
 ground(p,'platform_south_landing',poly([cx,y-12,cw,southY+180-y+12]));
 mechanical(p,[wx,120],ww);
 const cores=core(p,{westX:wx,westW:ww,eastX:ex,eastW:ew,serviceY:y,stairY:y+850});
 const bottom=Math.max(koala.at[1]+koala.bounds[3],cores.sw.at[1]+cores.sw.bounds[3]);
 ground(p,'northeast_landing',poly([ex,Math.max(cores.lift.bounds[1]+cores.lift.bounds[3],northY-180),ew,labY-Math.max(cores.lift.bounds[1]+cores.lift.bounds[3],northY-180)]));
 finalize(p,{wx,ww,cx,cw,ex,ew,hw},northY,southY,bottom);
}
function floor4(){
 const p=makePlan(4);p.sourcePlan='image 7.png; three west rooms, three east partitions, north/main/south voids, NW storage, NE stair above elevator, SW stair below services';
 p.scopeNotes=['原图注明空间对应不正确：保留三间西侧房间及三块东侧空间；大型会议室位置待核实，不凭文字增加隔墙。','东侧 C 为方案可选区；本版保留现状轮廓，摆设可独立撤下。'];
 const wx=180,ww=1344,hw=420,cx=1944,cw=1437,ex=cx+cw+hw,ew=1344,mainY=1880;
 let y=mainY;
 for(const [i,asset,dy] of [[1,'f4_seminar_a',.66],[2,'f4_seminar_b',.66],[3,'f4_seminar_c',.65]]){
  const r=room(p,`seminar_${i}`,asset,`研讨间 ${i}`,[wx,y],ww,regular,[eastDoor(dy)]);y+=r.bounds[3]-18;
 }
 const northY=1510;
 const storage=room(p,'storage','f4_storage','设备储藏室',[wx+760,120],ww+hw-760,[[[.32,.25],[.68,.25],[.70,.75],[.30,.75]]],[{id:'south',rect:[.445,.70,.11,.36],inside:[.50,.73],outside:[.50,1.035]}]);
 ground(p,'storage_landing',poly([wx+760,storage.at[1]+storage.bounds[3]-12,ww+hw-760,northY+180-storage.at[1]-storage.bounds[3]+12]));
 mechanical(p,[wx,120],760);
 const a=room(p,'focus_a','f4_focus_a','A · 专注孵化区',[ex,mainY+750],ew,eastFloor,[westDoor(.66)]);
 const b=room(p,'collab_b','f4_collab_b','B · 协作共创区',[ex,a.at[1]+a.bounds[3]-15],ew,eastFloor,[westDoor(.445)]);
 const southY=Math.max(y+250,b.at[1]+b.bounds[3]-180);
 const c=room(p,'flex_c','f4_flex_c','C · 流动工位区',[cx+cw,southY+180],ew+hw,[[[.13,.25],[.87,.25],[.91,.79],[.085,.79]]],[northDoor(.24)]);
 p.atriums=[{bounds:[cx,120,cw,northY-300],source:plate},{bounds:[cx,mainY,cw,southY-mainY-180],source:plate},{bounds:[cx,southY+180,cw,c.bounds[3]],source:plate}];
 for(const atrium of p.atriums)p.blockedSamples.push([atrium.bounds[0]+cw/2,atrium.bounds[1]+atrium.bounds[3]/2]);
 const cores=core(p,{westX:wx,westW:ww,eastX:ex,eastW:ew,serviceY:y,stairY:southY+180});
 const bottom=Math.max(c.at[1]+c.bounds[3],cores.sw.at[1]+cores.sw.bounds[3]);
 ground(p,'northeast_landing',poly([ex,cores.lift.at[1]+cores.lift.bounds[3],ew,a.at[1]-cores.lift.at[1]-cores.lift.bounds[3]]));
 finalize(p,{wx,ww,cx,cw,ex,ew,hw,eastStop:c.at[1]},northY,southY,bottom);
}
if(process.argv[1]===fileURLToPath(import.meta.url)){floor2();floor4();}
export function buildOtherFloors(){floor2();floor4();}
