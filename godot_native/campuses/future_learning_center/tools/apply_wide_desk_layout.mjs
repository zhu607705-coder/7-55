// Geometry-only revision over the stable room pass. Original raster bytes and actor metrics stay unchanged.
import fs from 'node:fs';
const art=JSON.parse(fs.readFileSync(new URL('../assets/room_props/manifest.json',import.meta.url))).find(row=>row.filename==='wide_desk.png');
const marks=art.source_marks;
const find=(p,id)=>{const o=p.objects.find(o=>o.id===id);if(!o)throw Error('Missing stable room object '+id);return o;};
const wall=(p,room,y)=>{const m=p.modules.find(m=>m.id===room);return m.at[1]+(y-m.crop[1])*m.scale;};
const lerp=(a,b,t)=>a+(b-a)*t;
function translated(object,dx,dy){for(const key of ['bounds','footprint']){object[key][0]+=dx;object[key][1]+=dy;}object.baseline+=dy;}
export function tabletopContact(desk,u,v){
 const q=desk.tabletop.polygon,left=[lerp(q[0][0],q[3][0],v),lerp(q[0][1],q[3][1],v)],right=[lerp(q[1][0],q[2][0],v),lerp(q[1][1],q[2][1],v)];
 return [lerp(left[0],right[0],u),lerp(left[1],right[1],u)];
}
function placeDesk(p,id,x,baseline,chairId,chairOffset){
 const desk=find(p,id),s=art.uniform_scale,[cx,cy,w,h]=art.source_region,[px,py]=art.source_baseline_pivot,[fx,fy,fw,fh]=art.source_foot_aabb;
 desk.path='res://campuses/future_learning_center/assets/room_props/wide_desk.png';desk.crop=[cx,cy,w,h];desk.scale=s;
 desk.bounds=[x+(cx-px)*s,baseline+(cy-py)*s,w*s,h*s];desk.footprint=[x+(fx-px)*s,baseline+(fy-py)*s,fw*s,fh*s];desk.baseline=baseline;
 desk.height=(py-marks.tabletop_front_y)*s;
 const point=([sx,sy])=>[x+(sx-px)*s,baseline+(sy-py)*s];
 desk.tabletop={polygon:marks.tabletop_quad.map(point),backEdgeFloorY:baseline+(marks.back_edge_ground_y-py)*s,verticalHeight:desk.height,projectedDepth:(marks.tabletop_front_y-marks.tabletop_back_y)*s,source:'wide_desk.png manual source-pixel registration'};
 const chair=find(p,chairId);translated(chair,x-chair.bounds[0]-chair.bounds[2]/2,baseline+chairOffset-chair.baseline);
 for(const child of p.objects.filter(o=>o.parent===id)){
  let u=.5,v=.82,order=.1;
  if(child.asset==='desk_divider'){v=.4;order=.05;}
  if(child.id.endsWith('monitor_left'))u=.31;
  if(child.id.endsWith('monitor_right'))u=.69;
  if(child.id==='team_project_notebook'){u=.23;v=.8;order=.2;}
  if(child.id.startsWith('recording_puzzle_')){v=.84;order=.2;}
  const contact=tabletopContact(desk,u,v),[,,width,height]=child.bounds;
  child.bounds=[contact[0]-width/2,contact[1]-height,width,height];child.footprint=[contact[0]-width/2,contact[1]-2,width,2];child.baseline=baseline+order;
  child.tableContact={point:contact,uv:[u,v],parent:desk.id};
 }
}
export function applyWideDeskLayout(p){
 if(![2,3].includes(p.floor)||!p.roomLayout||p.roomLayout.version>=2)return;
 const ids=p.objects.map(o=>o.id),depth=(art.source_baseline_pivot[1]-marks.back_edge_ground_y)*art.uniform_scale;
 if(p.floor===2){
  const north=wall(p,'team',275)+depth;
  for(const [desk,x,chair] of [[6,490,7],[10,685,11],[18,880,19]])placeDesk(p,`team_desk_${desk}`,x,north,`team_chair_back_${chair}`,45);
  for(const [desk,x,chair] of [[14,520,15],[22,720,23],[26,920,27]])placeDesk(p,`team_desk_${desk}`,x,4100,`team_chair_back_${chair}`,78.2);
  const student=p.npcs.find(n=>n.id==='flc_2_team_student_b');if(!student)throw Error('Missing project student');student.foot=[1110,4170];
 }else placeDesk(p,'recording_desk_234',1110,wall(p,'recording',321)+depth,'recording_chair_back_235',45);
 p.roomLayout={...p.roomLayout,version:2,deskRevision:'wide-low-web-v2',deskWidth:170,actorScaleUnchanged:true,tabletopProjectedDepth:(marks.tabletop_front_y-marks.tabletop_back_y)*art.uniform_scale,placement:'Three north-wall team workstations plus a three-desk project group; recording workbench remains at the surveyed north wall. Other prop and actor scales unchanged.'};
 if(ids.some((id,i)=>p.objects[i]?.id!==id))throw Error('Wide desk pass changed stable IDs/order');
}
