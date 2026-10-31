import test from 'node:test';
import assert from 'node:assert/strict';
import fs from 'node:fs';
import {placeProjectionTable} from '../tools/place_projection_table.mjs';
const data=new URL('../data/',import.meta.url);
const assets=JSON.parse(fs.readFileSync(new URL('object_assets.json',data)));
test('portable projection table is deterministic, idempotent and does not redraw the building',()=>{
 const current=JSON.parse(fs.readFileSync(new URL('floor_3.json',data)));
 const plan=structuredClone(current);plan.objects=plan.objects.filter(o=>o.id!=='xlab_box_projection_table');delete plan.projectionReference;plan.objectCounts.desk--;
 const architecture=JSON.stringify({ground:plan.ground,rooms:plan.rooms,doors:plan.doors,links:plan.links,waypoints:plan.waypoints});
 const objects=structuredClone(plan.objects);
 placeProjectionTable(plan,assets);assert.deepEqual({...plan,objects:[...plan.objects].sort((a,b)=>a.id.localeCompare(b.id))},{...current,objects:[...current.objects].sort((a,b)=>a.id.localeCompare(b.id))});
 placeProjectionTable(plan,assets);assert.deepEqual({...plan,objects:[...plan.objects].sort((a,b)=>a.id.localeCompare(b.id))},{...current,objects:[...current.objects].sort((a,b)=>a.id.localeCompare(b.id))});
 assert.deepEqual(plan.objects.filter(o=>o.id!=='xlab_box_projection_table'),objects);
 assert.equal(JSON.stringify({ground:plan.ground,rooms:plan.rooms,doors:plan.doors,links:plan.links,waypoints:plan.waypoints}),architecture);
});
test('other floors are unchanged',()=>{
 for(const floor of [2,4]){
  const plan=JSON.parse(fs.readFileSync(new URL(`floor_${floor}.json`,data))),before=structuredClone(plan);
  placeProjectionTable(plan,assets);assert.deepEqual(plan,before);
 }
});
