import fs from 'node:fs';
import {createHash} from 'node:crypto';
// Align storage to the measured room-floor/wall seam, using the projected
// depth visible in each existing front-facing master. No sprite stretching.
const seams=JSON.parse(fs.readFileSync(new URL('../data/wall_storage_seams.json',import.meta.url),'utf8'));
const kinds = new Set(['cabinet', 'parts_rack', 'pantry_wall_unit', 'pantry_fridge']);
const profiles = {
  cabinet: {height: 102, depthRatio: 120 / 974, label: '个人储物柜'},
  parts_rack: {height: 110, depthRatio: 150 / 1082, label: '元件收纳架'},
  pantry_wall_unit: {height: 190, depthRatio: 78 / 716, label: '茶水柜与水槽'},
  pantry_fridge: {height: 148, depthRatio: 90 / 1280, label: '冰箱'},
};
const rectPoints = ([x,y,w,h]) => [[x,y],[x+w,y],[x+w,y+h],[x,y+h]];
const intersects = (a,b) => a[0]<b[0]+b[2] && a[0]+a[2]>b[0] && a[1]<b[1]+b[3] && a[1]+a[3]>b[1];
const grow = ([x,y,w,h],n) => [x-n,y-n,w+2*n,h+2*n];
function inside([x,y],polygon) {
  let yes=false;
  for(let i=0,j=polygon.length-1;i<polygon.length;j=i++) {
    const a=polygon[i],b=polygon[j];
    if((a[1]>y)!==(b[1]>y) && x<(b[0]-a[0])*(y-a[1])/(b[1]-a[1])+a[0])yes=!yes;
  }
  return yes;
}
function cut(spans,[lo,hi]) {
  return spans.flatMap(([a,b])=>hi<=a||lo>=b?[[a,b]]:[[a,Math.min(lo,b)],[Math.max(hi,a),b]].filter(([x,y])=>y-x>1));
}
function northWall(module,polygon) {
  const calibration=seams.assets[module.asset];
  if(!calibration || calibration.path!==module.path)throw Error('Missing source-wall measurement: '+module.asset);
  const source=new URL('../../../'+module.path.replace('res://',''),import.meta.url);
  const hash=createHash('sha256').update(fs.readFileSync(source)).digest('hex');
  if(hash!==calibration.sha256)throw Error('Room master changed; remeasure wall seam: '+module.asset);
  return {y:module.at[1]+(calibration.sourceY-module.crop[1])*module.scale,
    navigationY:Math.min(...polygon.map(p=>p[1])),calibration,
    spans:calibration.sourceSpans.map(([a,b])=>[module.at[0]+(a-module.crop[0])*module.scale+8,module.at[0]+(b-module.crop[0])*module.scale-8])};
}
function dimensions(props,asset) {
  const a=props[asset],profile=profiles[asset],b=a.opaqueBounds;
  const crop=[b[0],b[1],b[2]-b[0],b[3]-b[1]];
  const scale=profile.height/crop[3];
  return {crop,scale,width:crop[2]*scale,height:profile.height,depth:profile.height*profile.depthRatio};
}

export function placeWallStorage(p,props) {
  const old=p.objects.filter(o=>kinds.has(o.asset));
  const originalByRoom=new Map();
  for(const o of old) {
    if(!originalByRoom.has(o.room))originalByRoom.set(o.room,[]);
    originalByRoom.get(o.room).push(o);
  }
  p.objects=p.objects.filter(o=>!kinds.has(o.asset));
  const assignments=new Map();
  const set=(room,cabinets,racks=0)=>assignments.set(room,[...Array(cabinets).fill('cabinet'),...Array(racks).fill('parts_rack')]);
  if(p.floor===2) {
    set('formula',4);set('robotics',4);set('seminar',2);
    set('electrical',4,4);set('machinery',4,4);
  } else if(p.floor===3) {
    for(let i=1;i<=4;i++)set('studio_'+i,4);
    set('seminar',2);set('pantry',2);
  } else if(p.floor===4) {
    for(let i=1;i<=3;i++)set('seminar_'+i,4);
    set('storage',5);set('focus_a',6);set('collab_b',6);set('flex_c',4);
  }
  // Future storage families cannot silently retain a floating placement.
  for(const [room,items] of originalByRoom)if(!assignments.has(room))assignments.set(room,items.filter(o=>o.asset!=='pantry_wall_unit').map(o=>o.asset));
  const reports=[];
  for(const [roomId,wanted] of assignments) {
    const room=p.rooms.find(r=>r.id===roomId);
    const floor=p.ground.find(g=>g.id===(room?.groundId??roomId+'_floor_0'))?.polygon;
    if(!room || !floor)throw Error('Missing storage room '+roomId);
    const wall=northWall(p.modules.find(m=>m.id===roomId),floor);
    let spans=wall.spans;
    // Source-measured spans already exclude painted windows, columns and doors.
    // Lighting apertures are approximate and cannot calibrate furniture overlap.
    const original=originalByRoom.get(roomId)||[];
    const used=new Set();
    const placed=[];
    const reserved=[p.spawn,...p.doors.flatMap(d=>[d.inside,d.outside]),...p.transits.map(t=>t.arrival)];
    function make(asset,x,template) {
      const d=dimensions(props,asset),backY=wall.y+.5,frontY=backY+d.depth;
      const footprint=[x-d.width*.48,backY,d.width*.96,d.depth];
      // The existing walkable polygon is inset from some painted walls. Fit the
      // unit to the visible wall and keep its approach on the original ground.
      const access=[footprint[0],Math.max(frontY,wall.navigationY+1),footprint[2],48];
      if(!rectPoints(access).every(v=>inside(v,floor)) || access[1]+24-frontY>96)return null;
      if(reserved.some(q=>intersects(grow(footprint,24),[q[0]-60,q[1]-45,120,90])))return null;
      if(p.objects.some(o=>!o.mounted && (intersects(grow(footprint,2),o.footprint)||intersects(access,o.footprint))))return null;
      // Do not place a new unit across the approach to another storage unit.
      if(placed.some(o=>intersects(footprint,o.wallStorage.access)))return null;
      const id=template?.id??`${roomId}_wall_${asset}_${placed.length+1}`;
      return {id,room:roomId,asset,name:profiles[asset].label,path:props[asset].path,crop:d.crop,scale:d.scale,
        bounds:[x-d.width/2,frontY-d.height,d.width,d.height],footprint,baseline:frontY,
        height:template?.height??(asset==='cabinet'?120:asset==='parts_rack'?125:150),floor,mounted:false,
        cluster:roomId+'_wall_storage',wallStorage:{side:'north',wallY:wall.y,rearY:backY,gap:.5,projectedDepth:d.depth,access,
          sourceWall:wall.calibration,navigationY:wall.navigationY,
          basis:'Existing front-facing master; rear ground edge follows measured source-image wall seam. Quantity is a review layout, not a surveyed inventory.'}};
    }
    function attach(object,template) {
      if(template) {
        used.add(template.id);
        const dx=object.bounds[0]-template.bounds[0],dy=object.baseline-template.baseline;
        for(const child of p.objects.filter(o=>o.parent===template.id)) {
          child.bounds=[child.bounds[0]+dx,child.bounds[1]+dy,...child.bounds.slice(2)];
          child.footprint=[child.footprint[0]+dx,child.footprint[1]+dy,...child.footprint.slice(2)];
          child.baseline+=dy;
        }
      }
      p.objects.push(object);placed.push(object);
      spans=cut(spans,[object.bounds[0]-2,object.bounds[0]+object.bounds[2]+2]);
    }
    // Keep the photo-derived sink unit as one complete fitted unit. Move its
    // mounted microwaves with it; extra storage uses separate existing cabinets.
    for(const fixed of original.filter(o=>o.asset==='pantry_wall_unit')) {
      const d=dimensions(props,fixed.asset),preferred=fixed.bounds[0]+fixed.bounds[2]/2;
      const xs=[preferred,...spans.flatMap(([a,b])=>[a+d.width/2,b-d.width/2])];
      const candidate=xs.map(x=>make(fixed.asset,x,fixed)).find(o=>o&&spans.some(([a,b])=>o.bounds[0]>=a && o.bounds[0]+o.bounds[2]<=b));
      if(!candidate)throw Error('No unobstructed wall position for '+fixed.id);
      attach(candidate,fixed);
    }
    for(const asset of wanted) {
      const d=dimensions(props,asset),template=original.find(o=>o.asset===asset&&!used.has(o.id));
      let candidate=null;
      for(const [a,b] of spans) {
        // Search from the right so small studios use the free wall beside their
        // desk bank. Window strips and door clearances are excluded above.
        for(let x=b-d.width/2;x>=a+d.width/2-.001;x-=2) {
          candidate=make(asset,x,template);
          if(candidate)break;
        }
        if(candidate)break;
      }
      if(!candidate)throw Error(`Not enough safe wall capacity: ${p.floor}F ${roomId}, ${placed.length}/${wanted.length} units, asset ${asset}`);
      attach(candidate,template);
    }
    if(p.floor===3 && roomId==='pantry') {
      const d=dimensions(props,'pantry_fridge'),span=spans.at(-1);
      const template=original.find(o=>o.asset==='pantry_fridge')??{id:'pantry_fridge_northeast',bounds:[0,0,0,0],baseline:0,height:148};
      const fridge=make('pantry_fridge',span[1]-d.width/2,template);
      if(!fridge || fridge.bounds[0]<span[0])throw Error('No clear right-hand pantry wall position for refrigerator');
      fridge.evidence='User confirmed refrigerator at far right of 3F pantry; dimensions and silver finish are review choices.';
      attach(fridge,template);
    }
    reports.push({room:roomId,before:original.length,after:placed.length,cabinets:placed.filter(o=>o.asset==='cabinet').length,
      racks:placed.filter(o=>o.asset==='parts_rack').length,fitted:placed.filter(o=>o.asset==='pantry_wall_unit').length,
      refrigerators:placed.filter(o=>o.asset==='pantry_fridge').length,
      wallY:wall.y,navigationY:wall.navigationY,maxRearGap:Math.max(...placed.map(o=>o.wallStorage.gap)),unitIds:placed.map(o=>o.id)});
  }
  if(old.some(o=>!p.objects.some(n=>n.id===o.id)))throw Error('Existing storage ID was lost during placement');
  p.wallStorage={version:2,before:old.length,after:reports.reduce((n,r)=>n+r.after,0),rooms:reports,
    placement:'All storage is aligned to verified floor-wall seams; facing and source art scale retained.',
    capacityBasis:'User requested more cabinets throughout. Counts are review choices constrained by walls, windows, doors, furniture and access.'};
  (p.scopeNotes??=[]).push('所有储物柜、零件架及茶水柜统一按柜背落地点贴墙，避开窗洞、门口与其他家具，保留柜前通行。新增数量为评审布局，非现场清点结果。');
}
