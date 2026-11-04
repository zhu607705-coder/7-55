/** Versioned review identities and pure presentation state. Never edits layout/colliders. */
const ROOM_KEYS = Object.freeze({
 '2': ['seminar','formula','team','robotics','mechatronics','koala'],
 '3': ['seminar','studio_1','studio_2','studio_3','studio_4','recording','pantry','xlab'],
 '4': ['storage','seminar_1','seminar_2','seminar_3','focus','collab','flex']
});
const ROOM_NAMES = Object.freeze({
 '2': ['研讨空间','工作空间 A','工作空间 B','工作空间 C','机电开放实验室','共享空间'],
 '3': ['北侧开放研讨与展示区','工作空间 1','工作空间 2','工作空间 3','工作空间 4','录播空间','茶水与休息区','实验空间'],
 '4': ['储物与辅助空间','办公室 1','办公室 2','办公室 3','办公区 A','办公区 B','办公区 C（边界待核准）']
});
const freeze = value => {if(value&&typeof value==='object'&&!Object.isFrozen(value)){Object.values(value).forEach(freeze);Object.freeze(value);}return value;};
export function buildSpatialCatalog(layout){
 if(!layout?.floors||![2,3,4].every(f=>layout.floors[f]))throw new Error('Expected verified source floors 2–4');
 const floors={'1':{id:'flc/f1',floor:'1',name:'1F · 待核准改造',status:'pending-reference',walkable:false,rooms:[],sourceElevation:null,reviewMode:'placeholder',note:'仅为版本化预留层；无已核准平面或改造几何。'}};
 for(const floor of ['2','3','4']){
  const source=layout.floors[floor];
  const rooms=source.rooms.map(room=>{
   const i=ROOM_KEYS[floor].indexOf(room.id);
   if(i<0)throw new Error(`Unmapped source room ${floor}/${room.id}; assign an explicit stable identity`);
   return {id:`flc/f${floor}/r${String(i+1).padStart(2,'0')}`,floor,sourceRoomId:room.id,name:ROOM_NAMES[floor][i],sourceName:room.name,bounds:[...room.bounds],area:room.area,walkable:floor!=='4',reviewMode:floor==='4'?'outline-only':'source-space'};
  });
  if(new Set(rooms.map(r=>r.id)).size!==rooms.length)throw new Error('Duplicate source room');
  floors[floor]={id:`flc/f${floor}`,floor,name:floor==='4'?'4F · 办公轮廓与走廊':`${floor}F`,status:'existing-source',walkable:true,sourceElevation:source.elevation,reviewMode:floor==='4'?'corridor-and-outlines':'source-space',rooms};
 }
 return freeze({schemaVersion:1,building:{id:'flc',name:'未来学习中心'},floors,objects:{},source:{units:layout.units,width:layout.width,length:layout.length,rise:layout.rise}});
}
export function spatialObjectId(floor,sourceNodeName){
 if(!['2','3','4'].includes(String(floor))||typeof sourceNodeName!=='string'||!sourceNodeName.trim())throw new Error('Object requires source floor and nonempty stable node name');
 return `flc/f${floor}/object/${encodeURIComponent(sourceNodeName)}`;
}
export function withSpatialObjects(catalog,descriptors){
 const objects={...catalog.objects};
 for(const descriptor of descriptors){
  const floor=String(descriptor.floor),room=descriptor.room||'';
  if(!Object.hasOwn(catalog.floors,floor)||floor==='1'||!descriptor.id?.startsWith(`flc/f${floor}/object/`)||descriptor.id===`flc/f${floor}/object/`)throw new Error('Invalid spatial object identity');
  if(room&&!catalog.floors[floor].rooms.some(r=>r.sourceRoomId===room))throw new Error('Invalid spatial object room');
  if(objects[descriptor.id])throw new Error('Duplicate spatial object identity: '+descriptor.id);
  objects[descriptor.id]={...descriptor,floor,room};
 }
 return freeze({...catalog,objects});
}
function floorFor(catalog,floor){const entry=Object.hasOwn(catalog.floors,String(floor))?catalog.floors[String(floor)]:null;if(!entry)throw new Error('Unknown floor: '+floor);return entry;}
function roomFor(catalog,floor,room){const entry=floorFor(catalog,floor).rooms.find(r=>r.sourceRoomId===room||r.id===room);if(!entry)throw new Error('Unknown room: '+room);return entry;}
export function createSpatialState(catalog,initial={}){
 const floor=String(initial.floor??'3');floorFor(catalog,floor);
 const room=initial.room?roomFor(catalog,floor,initial.room).sourceRoomId:'';
 return freeze({schemaVersion:1,building:catalog.building.id,scope:initial.expanded?'building':room?'room':'floor',floor,room:initial.expanded?'':room,object:'',expanded:!!initial.expanded});
}
export function reduceSpatialState(state,event,catalog){
 let next={...state};
 switch(event.type){
 case 'EXPAND': next={...next,scope:'building',expanded:true,room:'',object:''};break;
 case 'COLLAPSE': next={...next,scope:'floor',expanded:false,room:'',object:''};break;
 case 'SELECT_FLOOR': floorFor(catalog,event.floor);next={...next,scope:'floor',floor:String(event.floor),room:'',object:'',expanded:false};break;
 case 'SELECT_ROOM': {
  const floor=String(event.floor??state.floor);
  if(!event.room){floorFor(catalog,floor);next={...next,scope:'floor',floor,room:'',object:'',expanded:false};break;}
  const room=roomFor(catalog,floor,event.room);next={...next,scope:'room',floor,room:room.sourceRoomId,object:'',expanded:false};break;
 }
 case 'SELECT_OBJECT': {
  const object=Object.hasOwn(catalog.objects,event.object)?catalog.objects[event.object]:null;if(!object)throw new Error('Unknown object: '+event.object);
  next={...next,scope:'object',floor:object.floor,room:object.room,object:object.id,expanded:false};break;
 }
 case 'BACK':
  if(state.scope==='object')next={...next,scope:state.room?'room':'floor',object:''};
  else if(state.scope==='room')next={...next,scope:'floor',room:'',object:''};
  else next={...next,scope:'building',expanded:true,room:'',object:''};
  break;
 case 'RESET': return createSpatialState(catalog,{floor:'3',expanded:true});
 default: throw new Error('Unknown spatial event: '+event.type);
 }
 return freeze(next);
}
/** Render-only vertical delta. 1F is a labeled placeholder; this is not its surveyed elevation. */
export function displayFloorOffset(floor,expanded,rise=4.05){
 if(!['1','2','3','4'].includes(String(floor)))throw new Error('Unknown display floor');
 if(!Number.isFinite(rise)||rise<=0)throw new Error('Invalid source floor rise');
 return expanded?rise+(Number(floor)-1)*5:0;
}
export function validateExhibitionConfig(config,catalog){
 if(config?.schemaVersion!==1||!Array.isArray(config.teams)||!Array.isArray(config.exhibits)||!Array.isArray(config.roomAssignments))throw new Error('Unsupported exhibition config');
 const ids=new Set(),targets=new Set(Object.values(catalog.floors).flatMap(f=>[f.id,...f.rooms.map(r=>r.id)]));
 for(const item of [...config.teams,...config.exhibits]){if(typeof item.id!=='string'||!item.id||ids.has(item.id))throw new Error('Duplicate/invalid content identity');ids.add(item.id);}
 const teams=new Set(config.teams.map(t=>t.id)),exhibits=new Set(config.exhibits.map(e=>e.id));
 for(const assignment of config.roomAssignments){if(!targets.has(assignment.spaceId))throw new Error('Unknown assignment space');if(!(assignment.teamIds||[]).every(id=>teams.has(id))||!(assignment.exhibitIds||[]).every(id=>exhibits.has(id)))throw new Error('Unknown assignment content');}
 return true;
}
