import test from 'node:test';
import assert from 'node:assert/strict';
import fs from 'node:fs';
import {createHash} from 'node:crypto';
import {isFlcRuntimePath} from '../../../tools/web_story_content_policy.mjs';
import {applyRoomLayout} from '../tools/apply_room_layout.mjs';
const data=new URL('../data/',import.meta.url),baseline=JSON.parse(fs.readFileSync(new URL('room_layout_baseline.json',import.meta.url)));
const playerMetrics=fs.readFileSync(new URL('../../../scripts/player_metrics.gd',import.meta.url),'utf8');
const footSize=playerMetrics.match(/^const FOOT_SIZE := Vector2\(([\d.]+),\s*([\d.]+)\)$/m);
assert.ok(footSize,'shared native foot size is available');
const [,footWidth,footHeight]=footSize.map(Number);
const hash=v=>createHash('sha256').update(JSON.stringify(v)).digest('hex');
const fields=['modules','ground','rooms','doors','links','waypoints','occluders','windows'];
const overlap=(a,b)=>a[0]<b[0]+b[2]&&a[0]+a[2]>b[0]&&a[1]<b[1]+b[3]&&a[1]+a[3]>b[1];
for(const f of [2,3,4])test(`floor ${f} preserves legacy anchors and architecture`,()=>{
 const p=JSON.parse(fs.readFileSync(new URL(`floor_${f}.json`,data))),b=baseline[f];
 assert.equal(hash(p.objects.slice(0,b.oldCount).map(o=>o.id)),b.oldIdsHash);
 assert.equal(hash(Object.fromEntries(fields.map(k=>[k,p[k]??null]))),b.architectureHash);
 assert.equal(hash(p.objects.filter(o=>!['team','recording'].includes(o.room))),b.otherObjectsHash);
 assert.equal(new Set(p.objects.map(o=>o.id)).size,p.objects.length);
 const before=structuredClone(p);applyRoomLayout(p);assert.deepEqual(p,before,'final pass is idempotent');
 for(const o of p.objects.filter(o=>['team','recording'].includes(o.room))){
  assert.ok(Math.abs(o.bounds[2]/o.bounds[3]-o.crop[2]/o.crop[3])<1e-7,`${o.id} uniform raster scale`);
  if(o.mounted){const parent=p.objects.find(q=>q.id===o.parent);assert.ok(parent,`${o.id} keeps an explicit parent`);assert.ok(o.baseline>parent.baseline&&o.baseline<parent.baseline+1,`${o.id} sorts with its parent`);}
  if(!o.mounted)for(const other of p.objects.filter(q=>!q.mounted&&q.room===o.room&&q.id>o.id))assert.ok(!overlap(o.footprint,other.footprint),`${o.id} physical overlap ${other.id}`);
 }
 for(const npc of p.npcs||[]){const foot=[npc.foot[0]-footWidth/2,npc.foot[1]-footHeight/2,footWidth,footHeight];for(const o of p.objects.filter(q=>!q.mounted))assert.ok(!overlap(foot,o.footprint),`${npc.id} foot clear of ${o.id}`);}
});
test('new room rasters preserve downloaded bytes and expose no private URLs',()=>{
 const dir=new URL('../assets/room_props/',import.meta.url),raw=fs.readFileSync(new URL('manifest.json',dir),'utf8');
 assert.ok(!raw.includes('chatgpt.com/c/'));
 for(const row of JSON.parse(raw))assert.equal(createHash('sha256').update(fs.readFileSync(new URL(row.filename,dir))).digest('hex'),row.source.sha256);
});

test('reused NPC sprites belong to the FLC optional pack without loading later chapters',()=>{
 const dir=new URL('../assets/npcs/',import.meta.url),rows=JSON.parse(fs.readFileSync(new URL('manifest.json',dir)));
 for(const row of rows){const bytes=fs.readFileSync(new URL(row.filename,dir));assert.equal(createHash('sha256').update(bytes).digest('hex'),row.sha256);const source=new URL('../../../../'+row.source_path,import.meta.url);assert.deepEqual(bytes,fs.readFileSync(source));}
 for(const f of [2,3]){const p=JSON.parse(fs.readFileSync(new URL(`floor_${f}.json`,data)));for(const npc of p.npcs){assert.ok(isFlcRuntimePath(npc.path),`${npc.id} must load with FLC alone`);assert.ok(npc.path.startsWith('res://campuses/future_learning_center/assets/npcs/'));}}
});

test('wide low desks preserve human metrics, physical height and tabletop contact',()=>{
 assert.match(playerMetrics,/const DISPLAY_SCALE := 0\.65/);
 for(const f of [2,3]){
  const p=JSON.parse(fs.readFileSync(new URL(`floor_${f}.json`,data))),ids=f===2?[6,10,14,18,22,26].map(i=>`team_desk_${i}`):['recording_desk_234'];
  assert.equal(p.roomLayout.version,2);
  for(const id of ids){
   const desk=p.objects.find(o=>o.id===id);assert.equal(desk.bounds[2],170);assert.equal(desk.path,'res://campuses/future_learning_center/assets/room_props/wide_desk.png');
   assert.ok(Math.abs(desk.tabletop.verticalHeight-34.21534130893737)<1e-8);assert.ok(Math.abs(desk.tabletop.projectedDepth-27.994370161857848)<1e-8);
   const polygon=desk.tabletop.polygon,inside=(point)=>{let hit=false;for(let i=0,j=polygon.length-1;i<polygon.length;j=i++){const a=polygon[i],b=polygon[j];if((a[1]>point[1])!==(b[1]>point[1])&&point[0]<(b[0]-a[0])*(point[1]-a[1])/(b[1]-a[1])+a[0])hit=!hit;}return hit;};
   for(const child of p.objects.filter(o=>o.parent===id)){
    assert.equal(child.tableContact.parent,id);const [x,y]=child.tableContact.point;
    assert.ok(inside([x-child.bounds[2]/2,y])&&inside([x+child.bounds[2]/2,y]),`${child.id} full contact line lies on tabletop`);
    assert.ok(Math.abs(child.bounds[1]+child.bounds[3]-y)<1e-8,`${child.id} does not float beyond front lip`);
   }
  }
  const room=f===2?'team':'recording',module=p.modules.find(m=>m.id===room),wallY=module.at[1]+((f===2?275:321)-module.crop[1])*module.scale;
  for(const id of f===2?['team_desk_6','team_desk_10','team_desk_18']:['recording_desk_234'])assert.ok(Math.abs(p.objects.find(o=>o.id===id).tabletop.backEdgeFloorY-wallY)<1e-8,`${id} back tabletop edge meets surveyed wall`);
 }
});
