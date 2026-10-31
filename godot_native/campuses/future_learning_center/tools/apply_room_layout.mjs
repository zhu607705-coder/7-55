// Final stable-ID room pass. Run only after all legacy put() calls have finished.
// Keeps the surveyed architecture/navigation untouched; furniture positions are gameplay staging.
import fs from 'node:fs';
const assets=JSON.parse(fs.readFileSync(new URL('../data/object_assets.json',import.meta.url)));
const calibration=JSON.parse(fs.readFileSync(new URL('../assets/room_props/manifest.json',import.meta.url)));
function translateObject(object,dx,dy){for(const key of ['bounds','footprint']){object[key][0]+=dx;object[key][1]+=dy;}object.baseline+=dy;}
function descendants(plan,id){const result=[],seen=new Set([id]),queue=[id];while(queue.length){const parent=queue.shift();for(const object of plan.objects.filter(o=>o.parent===parent)){if(seen.has(object.id))throw Error('Cyclic parent: '+object.id);seen.add(object.id);result.push(object);queue.push(object.id);}}return result;}
const find=(plan,id)=>{const a=plan.objects.filter(o=>o.id===id);if(a.length!==1)throw Error(`Expected one ${id}`);return a[0];};
function transform(object,from,to,factor){
 for(const key of ['bounds','footprint'])object[key]=[to[0]+(object[key][0]-from[0])*factor,to[1]+(object[key][1]-from[1])*factor,object[key][2]*factor,object[key][3]*factor];
 object.baseline=to[1]+(object.baseline-from[1])*factor;object.scale*=factor;if(object.height!==undefined)object.height*=factor;
}
function group(plan,id,to,width,chairId=null,chairOffset=null){
 const root=find(plan,id),from=[root.bounds[0]+root.bounds[2]/2,root.baseline],factor=width/root.bounds[2];
 const members=[root,...descendants(plan,id)];if(chairId)members.push(find(plan,chairId));
 for(const object of members)transform(object,from,to,factor);
 if(chairId&&chairOffset!==null){const chair=find(plan,chairId);translateObject(chair,0,to[1]+chairOffset-chair.baseline);}
}
function wall(plan,room,sourceY){const m=plan.modules.find(x=>x.id===room);return m.at[1]+(sourceY-m.crop[1])*m.scale;}
function floor(plan,room){return plan.ground.find(g=>g.id===room+'_floor_0').polygon;}
function rasterProp(plan,id,room,name,file,point,height=null){
 const art=calibration.find(a=>a.filename===file),s=height?height/art.source_region[3]:art.uniform_scale;
 const [x,y,w,h]=art.source_region,[px,py]=art.source_baseline_pivot,[fx,fy,fw,fh]=art.source_foot_aabb;
 return {id,room,asset:file.replace('.png',''),name,path:`res://campuses/future_learning_center/assets/room_props/${file}`,crop:[x,y,w,h],scale:s,bounds:[point[0]+(x-px)*s,point[1]+(y-py)*s,w*s,h*s],footprint:[point[0]+(fx-px)*s,point[1]+(fy-py)*s,fw*s,fh*s],baseline:point[1],height:height||83.3,floor:floor(plan,room),mounted:false};
}
function locker(plan,id,x,wallY){
 const room='team',a=assets.locker_photo_v2,b=a.opaqueBounds,crop=[b[0],b[1],b[2]-b[0],b[3]-b[1]],height=102*1.15,scale=height/crop[3],width=crop[2]*scale,depth=102*120/974*1.15;
 const footprint=[x-87.56501026694045*1.15/2,wallY+.5,87.56501026694045*1.15,depth],baseline=wallY+.5+depth;
 const navY=Math.min(...floor(plan,room).map(q=>q[1]));
 return {id,room,asset:'cabinet',photoAsset:'locker_photo_v2',name:'个人储物柜',path:a.path,crop,scale,bounds:[x-width/2,baseline-height,width,height],footprint,baseline,height:120*1.15,floor:floor(plan,room),mounted:false,cluster:'team_wall_storage',wallStorage:{side:'north',wallY,rearY:wallY+.5,gap:.5,projectedDepth:depth,access:[footprint[0],Math.max(baseline,navY+1),footprint[2],48],navigationY:navY,sourceWall:{path:plan.modules.find(o=>o.id===room).path,sourceY:275,sourceSpans:[[210,1000]],sha256:'43a1423ef0b385c74c20f54c4fd778bfe96a3e61d8172f17d3c21e637651ec9c'}}};
}
function remount(plan,id,parentId,sourceContact){
 const object=find(plan,id),parent=find(plan,parentId),art=calibration.find(a=>a.filename==='media_cart.png');
 const target=[parent.bounds[0]+(sourceContact[0]-art.source_region[0])*parent.scale,parent.bounds[1]+(sourceContact[1]-art.source_region[1])*parent.scale];
 const dx=target[0]-object.bounds[0]-object.bounds[2]/2,dy=target[1]-object.bounds[1]-object.bounds[3];
 for(const key of ['bounds','footprint']){object[key][0]+=dx;object[key][1]+=dy;}
 object.baseline=parent.baseline+.1;object.parent=parent.id;object.mounted=true;
}
export function applyRoomLayout(p){
 if(![2,3].includes(p.floor)||p.roomLayout?.version===1)return;
 const oldIds=p.objects.map(o=>o.id);
 if(new Set(oldIds).size!==oldIds.length)throw Error('Duplicate legacy object ID');
 if(p.floor===2){
  const y=wall(p,'team',275)+42*1.15;
  for(const [id,x,chair] of [[6,470,7],[10,625,11],[14,780,15],[18,935,19]])group(p,`team_desk_${id}`,[x,y],118*1.15,`team_chair_back_${chair}`,45);
  for(const [id,x,chair] of [[22,650,23],[26,805,27]])group(p,`team_desk_${id}`,[x,4100],118*1.15,`team_chair_back_${chair}`);
  p.objects.push(rasterProp(p,'team_media_cart','team','移动媒体车','media_cart.png',[1200,3790]));
  p.objects.push(locker(p,'team_wall_cabinet_a',1110,wall(p,'team',275)),locker(p,'team_wall_cabinet_b',1230,wall(p,'team',275)));
  remount(p,'team_monitor_front_21','team_media_cart',[430,530]);
  p.npcs=[...(p.npcs||[]),{id:'flc_2_team_student_a',room:'team',name:'同学',path:'res://campuses/future_learning_center/assets/npcs/student_phone_glance_2frame.png',frameSize:[96,128],frameCount:2,foot:[1055,3755],line:'我在等这边的实验记录。'},{id:'flc_2_team_student_b',room:'team',name:'同学',path:'res://campuses/future_learning_center/assets/npcs/canteen_queue_student_01_front.png',frameSize:[96,128],frameCount:2,foot:[970,4070],line:'我在整理项目记录。'}];
 }else if(p.floor===3){
  const y=wall(p,'recording',321);
  group(p,'recording_desk_234',[1110,y+42*1.15],118*1.15,'recording_chair_back_235',45);
  // The old sofa was already oversized relative to the actor. Keep its natural aspect, not the desk multiplier.
  group(p,'recording_sofa_232',[700,y+85*(180/260)],180);
  const camera=find(p,'recording_camera_tripod_233');group(p,camera.id,[camera.bounds[0]+camera.bounds[2]/2,camera.baseline],camera.bounds[2]*95/camera.bounds[3]);
  const cartDepth=(1074-762)*calibration.find(a=>a.filename==='media_cart.png').uniform_scale;
  p.objects.push(rasterProp(p,'recording_media_cart','recording','移动媒体车','media_cart.png',[930,y+cartDepth]));
  p.objects.push(rasterProp(p,'recording_softbox','recording','录播柔光灯','softbox.png',[515,5500],110));
  remount(p,'recording_monitor_front_237','recording_media_cart',[430,530]);
  p.npcs=[...(p.npcs||[]),{id:'flc_3_recording_student_a',room:'recording',name:'同学',path:'res://campuses/future_learning_center/assets/npcs/canteen_queue_student_01_front.png',frameSize:[96,128],frameCount:2,foot:[1260,5370],line:'设备先放在车上。'}];
 }
 for(const room of p.floor===2?['team']:['recording']){
  const parent=find(p,room+'_media_cart');
  mountRaster(p,room+'_cart_cable_reel',room,'收好的线轴',parent,'cable_scene/cable_reel.png',[75,98,1264,973],28,[800,530]);
 }
 // Visible apparatus reuses the approved independent raster masters.
 if(p.floor===2){
  const desk=find(p,'team_desk_18'),cx=desk.bounds[0]+desk.bounds[2]/2,cy=desk.bounds[1]+desk.bounds[3]*.58;
  for(const [suffix,dx] of [['left',-31],['right',22]])appendMounted(p,'team_puzzle_monitor_'+suffix,'team','同步显示器',desk,'cable_scene/monitor.png',[125,287,1003,724],36,[cx+dx,cy]);
 }else{
  const desk=find(p,'recording_desk_234'),cx=desk.bounds[0]+desk.bounds[2]/2,cy=desk.bounds[1]+desk.bounds[3]*.6;
  appendMounted(p,'recording_puzzle_rail','recording','联动导轨',desk,'optical_scene/rail_horizontal.png',[82,272,2008,170],91,[cx,cy]);
  appendMounted(p,'recording_puzzle_baffle','recording','联动挡片',desk,'recording_scene/sliding_baffle.png',[375,96,221,1427],5.5,[cx,cy]);
 }
 // A closed notebook on a non-puzzle project desk; no invented surface graphics.
 if(p.floor===2){const desk=find(p,'team_desk_22');mountedOnDesk(p,desk,'team_project_notebook','项目记录本','schedule_scene/cover.png',[153,113,1519,642],30);}
 if(p.floor===2){
  const units=p.objects.filter(o=>o.id.startsWith('team_wall_cabinet_'));
  p.wallStorage.after+=units.length;
  p.wallStorage.rooms.push({room:'team',before:0,after:units.length,cabinets:units.length,racks:0,fitted:0,refrigerators:0,wallY:wall(p,'team',275),navigationY:Math.min(...floor(p,'team').map(q=>q[1])),maxRearGap:.5,unitIds:units.map(o=>o.id)});
 }
 p.roomLayout={version:1,rooms:p.floor===2?['team']:['recording'],deskGroupScale:1.15,stableLegacyIds:true,placement:'Wall work zones and open central activity space; source wall seams, full-foot navigation and separate mounted raster objects.'};
 if(oldIds.some((id,i)=>p.objects[i]?.id!==id))throw Error('Legacy IDs/order changed');
 if(new Set(p.objects.map(o=>o.id)).size!==p.objects.length)throw Error('Duplicate room-pass object ID');
}
function mountRaster(p,id,room,name,parent,file,crop,width,sourceContact){
 const art=calibration.find(a=>a.filename==='media_cart.png');
 const contact=[parent.bounds[0]+(sourceContact[0]-art.source_region[0])*parent.scale,parent.bounds[1]+(sourceContact[1]-art.source_region[1])*parent.scale];
 appendMounted(p,id,room,name,parent,file,crop,width,contact);
}
function mountedOnDesk(p,parent,id,name,file,crop,width){
 appendMounted(p,id,parent.room,name,parent,file,crop,width,[parent.bounds[0]+parent.bounds[2]*.23,parent.bounds[1]+parent.bounds[3]*.53]);
}
function appendMounted(p,id,room,name,parent,file,crop,width,contact){
 const scale=width/crop[2],height=crop[3]*scale;
 p.objects.push({id,room,asset:file.includes('reel')?'cable_reel':file.includes('cover')?'notebook':'tabletop_apparatus',name,path:'res://campuses/future_learning_center/assets/puzzles/'+file,crop,scale,bounds:[contact[0]-width/2,contact[1]-height,width,height],footprint:[contact[0]-width/2,contact[1]-2,width,2],baseline:parent.baseline+.2,height:14,floor:floor(p,room),mounted:true,parent:parent.id});
}
