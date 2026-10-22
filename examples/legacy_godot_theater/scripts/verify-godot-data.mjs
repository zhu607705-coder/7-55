import assert from 'node:assert/strict';
import {readFile} from 'node:fs/promises';
import {readStaticConstants, validateSpatialManifest} from './lib/static-ts-data.mjs';
let count = 0;
function test(name, fn) {fn();count++;console.log(`PASS ${name}`);}
const fixture = () => ({schemaVersion:1,world:{width:1672,height:941},viewport:{width:960,height:540},
  collisions:[{id:'wall',left:0,top:0,right:10,bottom:100}],occlusion:[{id:'crop',left:20,top:20,right:40,bottom:40,sortY:40}],
  spawns:{lobby:{x:836,y:820},auditorium:{x:1080,y:590},stage:{x:420,y:200}},
  player:{width:96,height:128,scale:0.65,frameMs:110,frameCount:8,foot:{width:30,height:22.5,offsetX:33,offsetY:101.5}}});
test('literal objects, as const and freeze convert without module execution', () => {
 const source='throw Error("must not execute"); export const X = Object.freeze({a: [1,-2,+3,"x",true,false,null] as const});';
 assert.equal(JSON.stringify(readStaticConstants(source,['X']).X),'{"a":[1,-2,3,"x",true,false,null]}');
});
test('computed calls, imports, spreads, getters, pollution and duplicate keys fail closed', () => {
 for(const expression of ['run()', 'Imported', '{...Other}', '{get x(){return 1}}', '{__proto__: {}}','{a:1,a:2}', '[...Other]', '1/0'])
  assert.throws(()=>readStaticConstants(`const X=${expression};`,['X']));
});
test('missing, mutable and invalid declarations are rejected', () => {
 for(const source of ['const Y=1;', 'let X=1;', 'const X = {;', 'const X=1;const X=2;'])assert.throws(()=>readStaticConstants(source,['X']));
});
test('nested-expression depth and node budget are bounded', () => {
 assert.throws(()=>readStaticConstants('const X='+ '['.repeat(100)+'0'+']'.repeat(100),['X']));
 assert.throws(()=>readStaticConstants('const X=['+'0,'.repeat(100001)+']', ['X']));
});
test('valid manifest survives JSON serialization', () => assert.deepEqual(validateSpatialManifest(JSON.parse(JSON.stringify(fixture()))),fixture()));
test('NaN, negative/empty/outside rectangles and duplicate ids are rejected', () => {
 for(const patch of [{left:NaN},{right:0},{left:-1},{right:2000},{top:Infinity}]){
  const data=fixture();Object.assign(data.collisions[0],patch);assert.throws(()=>validateSpatialManifest(data));
 }
 const data=fixture();data.collisions.push({...data.collisions[0]});assert.throws(()=>validateSpatialManifest(data));
});
test('invalid schema, spawns, player collision and occlusion sorting are rejected', () => {
 for(const mutate of [d=>d.schemaVersion=2,d=>d.spawns.stage.x=-1,d=>d.player.foot.height=999,
  d=>d.occlusion[0].sortY=99999,d=>d.player.frameCount=1.5,d=>d.player.scale=Infinity]){
  const data=fixture();mutate(data);assert.throws(()=>validateSpatialManifest(data));
 }
});
// Run against real current repository declarations, not copied geometry fixtures.
let checkedSource = false;
try {
 const text=await readFile(new URL('../src/scenes/rpg/TheaterInteriorModel.ts',import.meta.url),'utf8');
 const names=['THEATER_INTERIOR_WORLD','THEATER_STATIC_COLLISION_RECTS','THEATER_OCCLUSION_RECTS','THEATER_GATE_BLOCKER'];
 const constants=readStaticConstants(text,names);
 assert.ok(constants.THEATER_STATIC_COLLISION_RECTS.length>0);
 assert.ok(constants.THEATER_OCCLUSION_RECTS.length>0);
 checkedSource=true;
} catch(error) {
 if(error.code!=='ENOENT' || !process.argv.includes('--fixtures-only'))throw error;
}
console.log(JSON.stringify({passed:count,realRepositorySourceChecked:checkedSource}));
