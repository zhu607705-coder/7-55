/** Pure state/data checks. These do not establish browser, GPU or pointer acceptance. */
import assert from 'node:assert/strict';
import fs from 'node:fs';
import {buildSpatialCatalog,spatialObjectId,withSpatialObjects,createSpatialState,reduceSpatialState,displayFloorOffset,validateExhibitionConfig} from '../web/spatial_catalog.js';
const layout=JSON.parse(fs.readFileSync(new URL('../web/assets/layout.json',import.meta.url))),before=JSON.stringify(layout);
const config=JSON.parse(fs.readFileSync(new URL('../web/assets/exhibition_config.json',import.meta.url)));
let passed=0;const check=(condition,message)=>{assert.ok(condition,message);passed++;};const throws=(f,re)=>{assert.throws(f,re);passed++;};
let catalog=buildSpatialCatalog(layout);
check(catalog.building.id==='flc','stable building');check(Object.keys(catalog.floors).join(',')==='1,2,3,4','four explicit floor records');
check(catalog.floors['1'].status==='pending-reference'&&!catalog.floors['1'].walkable&&catalog.floors['1'].rooms.length===0&&catalog.floors['1'].sourceElevation===null,'1F contains no invented geometry');
for(const floor of ['2','3','4']){
 const source=layout.floors[floor],entry=catalog.floors[floor];check(source.rooms.length===entry.rooms.length,'all source rooms retained');check(source.elevation===entry.sourceElevation,'physical elevation retained');
 for(const r of entry.rooms){const original=source.rooms.find(x=>x.id===r.sourceRoomId);check(JSON.stringify(r.bounds)===JSON.stringify(original.bounds),'bounds retained '+r.id);check(!/团队|ASABE|考拉|方程式|X-Lab/.test(r.name),'display is not team-bound '+r.id);check(r.id.startsWith(`flc/f${floor}/r`),'stable spatial identity '+r.id);}
}
check(catalog.floors['4'].rooms.every(r=>r.reviewMode==='outline-only'&&!r.walkable),'office interiors not presented as public walkthrough');
const reordered=structuredClone(layout);for(const floor of Object.values(reordered.floors)){floor.rooms.reverse();for(const room of floor.rooms)room.name='Renamed by source';}
const reorderedCatalog=buildSpatialCatalog(reordered);
for(const floor of ['2','3','4'])for(const room of catalog.floors[floor].rooms)check(reorderedCatalog.floors[floor].rooms.find(r=>r.sourceRoomId===room.sourceRoomId).id===room.id,'identity survives source order/name change');
const id=spatialObjectId('3','Lab sample / 01'),other=spatialObjectId('2','Lab sample / 01');check(id!==other&&id.includes('Lab%20sample%20%2F%2001'),'source object namespace escaped and floor-specific');
catalog=withSpatialObjects(catalog,[{id,floor:'3',room:'xlab',name:'Existing sample'},{id:other,floor:'2',room:'',name:'Hall sample'}]);
let state=createSpatialState(catalog,{floor:'3',room:'xlab'});check(state.scope==='room'&&state.room==='xlab','deep room link');
state=reduceSpatialState(state,{type:'SELECT_OBJECT',object:id},catalog);check(state.scope==='object'&&state.object===id&&state.room==='xlab','object contextual selection');
state=reduceSpatialState(state,{type:'BACK'},catalog);check(state.scope==='room'&&state.object==='','object cancel restores room');
state=reduceSpatialState(state,{type:'BACK'},catalog);check(state.scope==='floor'&&state.room==='','room cancel restores floor');
state=reduceSpatialState(state,{type:'BACK'},catalog);check(state.scope==='building'&&state.expanded,'floor cancel restores exploded building');
const expanded=state;state=reduceSpatialState(state,{type:'SELECT_FLOOR',floor:'4'},catalog);check(state.scope==='floor'&&!state.expanded&&state.floor==='4','choose exploded floor focuses it');check(expanded.expanded,'event does not mutate prior state');
state=reduceSpatialState(state,{type:'SELECT_ROOM',room:'seminar_1'},catalog);check(state.room==='seminar_1','4F outline remains selectable');
state=reduceSpatialState(state,{type:'SELECT_FLOOR',floor:'1'},catalog);check(state.floor==='1'&&state.room===''&&state.object==='','switch clears selected descendants');
throws(()=>reduceSpatialState(state,{type:'SELECT_ROOM',room:'imagined-office'},catalog),/Unknown room/);
state=reduceSpatialState(state,{type:'EXPAND'},catalog);state=reduceSpatialState(state,{type:'COLLAPSE'},catalog);check(state.floor==='1'&&state.scope==='floor'&&!state.expanded,'collapse can restore 1F placeholder');
state=reduceSpatialState(state,{type:'SELECT_OBJECT',object:other},catalog);check(state.floor==='2'&&state.room===''&&state.scope==='object','hall object context');state=reduceSpatialState(state,{type:'BACK'},catalog);check(state.scope==='floor','hall object cancel restores floor');
state=reduceSpatialState(state,{type:'SELECT_ROOM',floor:'3',room:'flc/f3/r08'},catalog);check(state.room==='xlab'&&state.floor==='3','stable room identity accepted');
state=reduceSpatialState(state,{type:'SELECT_ROOM',room:''},catalog);check(state.scope==='floor'&&state.room==='','whole-floor selector clears room');
for(let n=0;n<20;n++){state=reduceSpatialState(state,{type:'EXPAND'},catalog);state=reduceSpatialState(state,{type:'SELECT_ROOM',floor:'3',room:'xlab'},catalog);state=reduceSpatialState(state,{type:'SELECT_OBJECT',object:id},catalog);state=reduceSpatialState(state,{type:'BACK'},catalog);check(state.room==='xlab'&&!state.expanded&&state.object==='','repeat selection/back remains clean');}
state=reduceSpatialState(state,{type:'RESET'},catalog);check(state.scope==='building'&&state.floor==='3'&&state.expanded,'reset deterministic');
for(const floor of ['1','2','3','4']){check(displayFloorOffset(floor,false,layout.rise)===0,'collapse zero display delta');check(displayFloorOffset(floor,true,layout.rise)===layout.rise+(Number(floor)-1)*5,'expanded display delta');}
check(-layout.rise+displayFloorOffset('1',true,layout.rise)===0,'1F provisional visual anchor remains above ground');
throws(()=>displayFloorOffset('5',true),/Unknown display floor/);throws(()=>displayFloorOffset('2',true,-1),/Invalid source/);
throws(()=>createSpatialState(catalog,{floor:'99'}),/Unknown floor/);throws(()=>createSpatialState(catalog,{floor:'1',room:'fake'}),/Unknown room/);throws(()=>reduceSpatialState(state,{type:'SELECT_OBJECT',object:'unknown'},catalog),/Unknown object/);throws(()=>reduceSpatialState(state,{type:'SELECT_FLOOR',floor:'99'},catalog),/Unknown floor/);throws(()=>reduceSpatialState(state,{type:'BAD'},catalog),/Unknown spatial/);
throws(()=>withSpatialObjects(catalog,[{id,floor:'3',room:'xlab'}]),/Duplicate/);throws(()=>withSpatialObjects(catalog,[{id:'bad',floor:'3',room:''}]),/Invalid spatial/);throws(()=>withSpatialObjects(catalog,[{id:spatialObjectId('3','new'),floor:'3',room:'bad'}]),/Invalid spatial object room/);throws(()=>spatialObjectId('1','new'),/requires/);throws(()=>spatialObjectId('2',''),/requires/);
check(validateExhibitionConfig(config,catalog),'versioned exhibition config valid');check(config.floorVersions['1'].geometry===null&&config.floorVersions['1'].status==='pending-reference','1F versioned config is only a reservation');check(config.teams.length===0&&config.exhibits.every(e=>e.status==='placeholder'&&e.image===null),'no invented teams or artwork');
const replaced=structuredClone(config);replaced.teams=[{id:'team/test',name:'Config test only'}];replaced.roomAssignments[0].teamIds=['team/test'];replaced.exhibits[0].title='Replacement title';check(validateExhibitionConfig(replaced,catalog),'replace independent content without geometry');check(catalog.floors['3'].rooms.find(r=>r.sourceRoomId==='xlab').id==='flc/f3/r08','content replacement does not change space identity');
for(const mutation of [c=>c.schemaVersion=2,c=>c.roomAssignments[0].spaceId='fake',c=>c.roomAssignments[0].exhibitIds=['fake'],c=>c.teams.push({id:c.exhibits[0].id})]){const invalid=structuredClone(config);mutation(invalid);throws(()=>validateExhibitionConfig(invalid,catalog),/Unsupported|Unknown|Duplicate/);}
throws(()=>createSpatialState(catalog,{floor:'toString'}),/Unknown floor/);throws(()=>reduceSpatialState(state,{type:'SELECT_OBJECT',object:'toString'},catalog),/Unknown object/);
check(JSON.stringify(layout)===before,'physical source layout byte-equivalent after transitions');check(Object.isFrozen(catalog.floors['3'].rooms[0].bounds)&&Object.isFrozen(state),'derived structures immutable');
console.log(JSON.stringify({passed,scope:'Pure spatial identity, reversible selection, independent content config and immutable source geometry. Not browser/GPU acceptance.'},null,2));
