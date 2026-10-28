import fs from 'node:fs';
import path from 'node:path';
import {fileURLToPath} from 'node:url';

// Composition uses uniform transforms of original room masters. No image is
// stretched to a guessed room rectangle. Source polygons own door/ground data.
const root=path.resolve(path.dirname(fileURLToPath(import.meta.url)),'..');
const assets=JSON.parse(fs.readFileSync(path.join(root,'data/room_assets.json'),'utf8'));
const plan={schema:1,floor:3,title:'未来学习中心 · 3F',status:'room-scale architectural review',
  source:'https://zju-xlab.feishu.cn/wiki/NKVGwp4KxikWgSktPoucZzsvnUf',
  sourcePlan:'image 9.png; four west studios, recording south of studios, central void, north seminar, south pantry, east X-Lab',
  scaleNote:'Game-space enlargement requested by user; preserves room count and adjacency, not a surveyed metric reconstruction.',
  world:[5350,8500],modules:[],ground:[],rooms:[],waypoints:[],links:[],doors:[],occluders:[],blockedSamples:[],openSamples:[]};
const pt=(p,t)=>[t.at[0]+(p[0]-t.crop[0])*t.scale,t.at[1]+(p[1]-t.crop[1])*t.scale];
const rectPoly=([x,y,w,h])=>[[x,y],[x+w,y],[x+w,y+h],[x,y+h]];
function ground(id,poly){plan.ground.push({id,polygon:poly});}
function waypoint(id,p){plan.waypoints.push({id,point:p});return id;}
function link(a,b){plan.links.push([a,b]);}
function module(id,asset,at,width,groundPolys,doorDefs,focus=true){
  const a=assets[asset],b=a.opaqueBounds,crop=[b[0],b[1],b[2]-b[0],b[3]-b[1]];
  const t={id,asset,path:a.path,at,crop,scale:width/crop[2]};
  t.bounds=[...at,width,crop[3]*t.scale];plan.modules.push(t);
  for(let i=0;i<groundPolys.length;i++)ground(`${id}_floor_${i}`,groundPolys[i].map(p=>pt(p,t)));
  if(focus)plan.rooms.push({id,name:({team_studio:'团队工作室',north_seminar:'开放研讨区',recording_studio:'录播室',pantry:'茶水休息区',xlab_north:'X-Lab 北区',xlab_south:'X-Lab 南区'})[asset],bounds:t.bounds,group:id.startsWith('xlab')?'xlab':id});
  for(const d of doorDefs){
    const poly=rectPoly(d.rect).map(p=>pt(p,t));ground(`${id}_${d.id}`,poly);
    const inside=pt(d.inside,t),outside=pt(d.outside,t);
    plan.doors.push({id:`${id}_${d.id}`,room:id,inside,outside,polygon:poly});
    waypoint(`${id}_${d.id}_in`,inside);waypoint(`${id}_${d.id}_out`,outside);link(`${id}_${d.id}_in`,`${id}_${d.id}_out`);
  }
  return t;
}
// Four individually replaceable instances, at native detail, matching the plan.
const westX=180,westW=1344,hallW=420,centerX=westX+westW+hallW,centerW=1437,eastHallX=centerX+centerW,eastX=eastHallX+hallW;
const mainY=1880;
let y=mainY;
for(let i=0;i<4;i++){
 const r=module(`studio_${i+1}`,'team_studio',[westX,y],westW,
  [[[250,235],[1425,235],[1490,748],[220,748]]],
  [{id:'east',rect:[1450,435,245,78],inside:[1470,475],outside:[1710,475]}]);
 r.name=`团队工作室 ${i+1}`;plan.rooms.at(-1).name=r.name;
 plan.occluders.push({module:r.id,rect:[1488,345,185,185],baseline:524});
 plan.openSamples.push(pt([820,530],r));plan.blockedSamples.push(pt([700,100],r));
 y+=r.bounds[3]-18;
}
const recording=module('recording','recording_studio',[westX,y],westW,
 [[[190,330],[1150,330],[1190,1010],[170,1010]]],
 [{id:'east',rect:[1150,775,180,105],inside:[1160,830],outside:[1345,830]}]);
plan.occluders.push({module:'recording',rect:[1170,700,135,190],baseline:890});
plan.openSamples.push(pt([700,650],recording));plan.blockedSamples.push(pt([650,170],recording));
const serviceStart=recording.bounds[1]+recording.bounds[3]-24;
const southHallY=serviceStart+260;
const pantryY=southHallY+420;
const seminar=module('seminar','north_seminar',[centerX,160],centerW,
 [[[185,280],[1260,280],[1305,878],[153,878]]],
 [{id:'south',rect:[1000,860,132,260],inside:[1064,860],outside:[1064,1120]}]);
plan.occluders.push({module:'seminar',rect:[954,840,72,140],baseline:980});
plan.occluders.push({module:'seminar',rect:[1130,845,50,140],baseline:984});
plan.openSamples.push(pt([700,560],seminar));plan.blockedSamples.push(pt([650,150],seminar));
const pantry=module('pantry','pantry',[centerX,pantryY],centerW,
 [[[175,235],[1160,235],[1185,930],[155,930]]],
 [{id:'north',rect:[300,-30,120,280],inside:[360,255],outside:[360,-30]}]);
plan.openSamples.push(pt([650,650],pantry));plan.blockedSamples.push(pt([1100,140],pantry));
const floorBottom=pantry.bounds[1]+pantry.bounds[3];
const xn=module('xlab_north','xlab_north',[eastX,mainY],westW,
 [[[170,240],[650,240],[725,1935],[75,1935]]],
 [{id:'west',rect:[-30,405,220,95],inside:[185,450],outside:[-30,450]}]);
const xsHeight=assets.xlab_south.opaqueBounds[3]-assets.xlab_south.opaqueBounds[1];
const xsWidth=assets.xlab_south.opaqueBounds[2]-assets.xlab_south.opaqueBounds[0];
const xsY=floorBottom-xsHeight*westW/xsWidth;
const xs=module('xlab_south','xlab_south',[eastX,xsY],westW,
 [[[116,70],[338,70],[338,500],[778,570],[780,1510],[95,1510]]],
 [{id:'west_a',rect:[-20,740,190,100],inside:[140,790],outside:[-30,790]},
  {id:'west_b',rect:[-20,1260,190,110],inside:[140,1320],outside:[-30,1320]}]);
// Acoustic box is a separate internal room with its own measured west doorway.
ground('xlab_box',[[405,215],[770,215],[780,425],[405,425]].map(p=>pt(p,xs)));
ground('xlab_box_door',rectPoly([320,365,105,65]).map(p=>pt(p,xs)));
plan.rooms.push({id:'xlab_box',name:'X-Lab 多功能小间',group:'xlab',bounds:[...pt([338,70],xs),(805-338)*xs.scale,500*xs.scale]});
plan.occluders.push({module:'xlab_south',rect:[340,425,470,120],baseline:545});
for(const r of [xn,xs]){plan.openSamples.push(pt(r==xn?[400,1100]:[450,1000],r));plan.blockedSamples.push(pt(r==xn?[400,130]:[600,130],r));}
// The two long X-Lab masters share an open joining edge; neither adds a wall.
const joinTop=xn.at[1]+xn.bounds[3]-10,joinBottom=xs.at[1]+120;
if(joinBottom>joinTop)ground('xlab_join',rectPoly([eastX+140,joinTop,westW-280,joinBottom-joinTop]));
const northCrossY=seminar.bounds[1]+seminar.bounds[3]-45;
ground('west_corridor',rectPoly([westX+westW,100,hallW,floorBottom-100]));
ground('east_corridor',rectPoly([eastHallX,100,hallW,floorBottom-100]));
ground('north_cross',rectPoly([westX+westW,northCrossY,centerW+hallW*2,mainY-northCrossY]));
ground('south_cross',rectPoly([westX+westW,southHallY,centerW+hallW*2,420]));
// Corridors meet the actual door aperture, including each module's transparent margin.
for(const d of plan.doors){
 if(d.room.startsWith('studio')||d.room==='recording'){
  ground(`${d.id}_threshold`,rectPoly([d.inside[0]-12,d.inside[1]-28,westX+westW+hallW/2-d.inside[0]+12,56]));
 }else if(d.room.startsWith('xlab')){
  ground(`${d.id}_threshold`,rectPoly([eastHallX+hallW/2,d.inside[1]-28,d.inside[0]-eastHallX-hallW/2+12,56]));
 }
}
// Review-only core art comes from the accepted overview at a uniform scale.
// Its geometry is CLOSED; overview pixels must never be mistaken for walkable roofs.
const plate='res://campuses/future_learning_center/assets/floors/floor_3_overview_v1.png';
function crop(id,src,at,width){const s=width/src[2];const t={id,path:plate,crop:src,at,scale:s,bounds:[...at,width,src[3]*s],overviewDetail:true};plan.modules.push(t);return t;}
crop('northwest_core',[80,24,225,292],[westX,110],westW);
const northeast=crop('northeast_core',[714,30,267,282],[eastX,110],westW);
const landingY=northeast.bounds[1]+northeast.bounds[3];
ground('northeast_landing',rectPoly([eastX,landingY,westW-150,mainY-landingY]));
plan.northeastLanding={bounds:[eastX,landingY,westW,mainY-landingY]};
const service=crop('west_services',[87,978,250,354],[westX,serviceStart],westW);
// Permanent service cores are an art review only in this pass; transit is not
// exposed until 2F/4F are authored and their paired thresholds can be tested.
plan.atrium={bounds:[centerX,mainY,centerW,southHallY-mainY],source:plate};
plan.xlabJoin={bounds:[eastX,joinTop,westW,Math.max(0,joinBottom-joinTop)],source:'xlab_north'};
// A PNG's bounding box includes projecting corner posts. The corridor follows
// the measured opaque exterior of each wall, rather than leaving a black gap
// between that wall and a bounding-box rectangle. Each strip is conservative:
// the entire 16-source-pixel band uses its outermost wall pixel.
for(const r of plan.modules.filter(r=>r.asset)){
 const leftContour=[],rightContour=[];
 for(const strip of assets[r.asset].outerWallStrips){
  const sy=strip[0],ey=strip[1],left=pt([strip[2],sy],r)[0],right=pt([strip[3],sy],r)[0];
  const yy=pt([0,sy],r)[1],hh=(ey-sy)*r.scale;
  leftContour.push([left,yy],[left,yy+hh]);rightContour.push([right,yy],[right,yy+hh]);
 }
 const top=r.at[1],bottom=r.at[1]+r.bounds[3];
 if(r.at[0]===westX)ground(`${r.id}_outside_e`,[...rightContour,[centerX,bottom],[centerX,top]]);
 if(r.at[0]===centerX){
  ground(`${r.id}_outside_w`,[[westX+westW,top],[westX+westW,bottom],...leftContour.toReversed()]);
  ground(`${r.id}_outside_e`,[...rightContour,[eastX,bottom],[eastX,top]]);
 }
 if(r.at[0]===eastX)ground(`${r.id}_outside_w`,[[eastHallX,top],[eastHallX,bottom],...leftContour.toReversed()]);
}
plan.corridors=plan.ground.filter(x=>/corridor|cross|landing/.test(x.id));
plan.world=[eastX+westW+180,Math.max(floorBottom,service.bounds[1]+service.bounds[3])+180];
// Static visibility graph: all edges are checked against the entire foot box.
const hallXs=[westX+westW+hallW/2,eastHallX+hallW/2];
let hallYs=[northCrossY+160,southHallY+210];
for(const d of plan.doors)hallYs.push(d.outside[1]);
hallYs=[...new Set(hallYs.filter(v=>v>100&&v<floorBottom).map(v=>Math.round(v)))].sort((a,b)=>a-b);
for(let side=0;side<2;side++){
 for(let i=0;i<hallYs.length;i++){waypoint(`hall_${side}_${i}`,[hallXs[side],hallYs[i]]);if(i)link(`hall_${side}_${i-1}`,`hall_${side}_${i}`);}
}
for(const d of plan.doors){
 const side=d.room.startsWith('xlab')?1:0;
 if(d.room==='seminar'||d.room==='pantry'){
  const hallY=d.room==='seminar'?northCrossY+160:southHallY+210;
  waypoint(`${d.id}_cross`,[d.outside[0],hallY]);link(`${d.id}_out`,`${d.id}_cross`);
  for(let s=0;s<2;s++)link(`${d.id}_cross`,`hall_${s}_${hallYs.indexOf(Math.round(hallY))}`);
 }else link(`${d.id}_out`,`hall_${side}_${hallYs.indexOf(Math.round(d.outside[1]))}`);
}
for(const hallY of [northCrossY+160,southHallY+210]){const idx=hallYs.indexOf(Math.round(hallY));link(`hall_0_${idx}`,`hall_1_${idx}`);}
// Interior waypoints resolve the longer room and the nested acoustic box.
for(const [id,p,r] of [['xlab_north_center',[400,1100],xn],['xlab_north_end',[400,1850],xn],['xlab_south_passage',[200,270],xs],['xlab_south_center',[450,1000],xs],['xlab_box_inside',[480,390],xs],['xlab_box_outside',[270,390],xs]])waypoint(id,pt(p,r));
link('xlab_north_center','xlab_north_west_in');link('xlab_north_center','xlab_north_end');link('xlab_north_end','xlab_south_passage');link('xlab_south_passage','xlab_box_outside');link('xlab_box_outside','xlab_box_inside');link('xlab_box_outside','xlab_south_center');link('xlab_south_center','xlab_south_west_a_in');link('xlab_south_center','xlab_south_west_b_in');
plan.spawn=pt([860,540],plan.modules.find(x=>x.id==='studio_1'));
plan.blockedSamples.push([centerX+centerW/2,3600],[eastX+westW/2,650],[30,30]);
fs.writeFileSync(path.join(root,'data/floor_3.json'),JSON.stringify(plan,null,2)+'\n');
console.log(`3F ${plan.world.join(' × ')}; ${plan.modules.length} modules; ${plan.rooms.length} room zones; ${plan.doors.length} apertures.`);
