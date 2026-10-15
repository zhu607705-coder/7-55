import fs from 'node:fs';
import { stripTypeScriptTypes } from 'node:module';
const root=new URL('../../',import.meta.url);
async function load(file,extra='') {
 let s=stripTypeScriptTypes(fs.readFileSync(new URL(file,root),'utf8'),{mode:'transform'});
 s=s.replace(/import \* as THREE from "three";/,`const THREE={Vector3:class {constructor(x=0,y=0,z=0){this.x=x;this.y=y;this.z=z}clone(){return new this.constructor(this.x,this.y,this.z)}add(v){this.x+=v.x;this.y+=v.y;this.z+=v.z;return this}sub(v){this.x-=v.x;this.y-=v.y;this.z-=v.z;return this}addScaledVector(v,n){this.x+=v.x*n;this.y+=v.y*n;this.z+=v.z*n;return this}negate(){this.x=-this.x;this.y=-this.y;this.z=-this.z;return this}}};`);
 s=s.replace(/import (\w+) from "\.\.\/assets\/([^"\n]+)";/g,(_,v,p)=>`const ${v}="res://assets/${p}";`);
 return import('data:text/javascript;base64,'+Buffer.from(s+extra).toString('base64'));
}
const levels=await load('src/tools/chapter4-stair/levels.ts');
const alumni=await load('src/data/ChapterFourAlumniHonorWall.ts');
const puzzles=await load('src/modules/ChapterFourInsertedPuzzleModel.ts');
const stair=await load('src/modules/ChapterFourChaseStairwellModel.ts','\nexport const NATIVE_EDGES=EDGES;');
const prologue=await load('src/scenes/rpg/chapter4-prologue/PrologueTimeline.ts');
const guard=await load('src/modules/ChapterFourGuardModel.ts');
const chase=await load('src/modules/ChapterFourFinalChaseModel.ts');
const out={guard:{maintenanceRules:guard.CHAPTER_FOUR_MAINTENANCE_GUARD_RULES,patrol:guard.CHAPTER_FOUR_MAINTENANCE_PATROL_WAYPOINTS,chaseRules:chase.CHAPTER_FOUR_FINAL_CHASE_RULES,chasePoints:chase.CHAPTER_FOUR_FINAL_CHASE_POINTS,chaseWaypoints:chase.CHAPTER_FOUR_FINAL_CHASE_WAYPOINTS},prologue:{beats:prologue.PROLOGUE_BEATS,subtitles:prologue.PROLOGUE_SUBTITLES},levels:levels.STAIR_LEVEL_ORDER.map(levels.getStairLevel),cameras:levels.LEVEL_CAMERAS,alumni:alumni.CHAPTER_FOUR_ALUMNI_HONOR_WALL,questions:alumni.CHAPTER_FOUR_ZHU_QUESTIONS,puzzles:puzzles.CHAPTER_FOUR_INSERTED_PUZZLES,registration:puzzles.CHAPTER_FOUR_DEVICE_REGISTRATION,stair:{edges:stair.NATIVE_EDGES,walkable:stair.CHASE_STAIR_WALKABLE,landings:stair.CHASE_STAIR_LANDINGS,gates:stair.CHASE_STAIR_GATES,exit:stair.CHASE_STAIR_EXIT,route:stair.CHASE_STAIR_ROUTE}};
fs.mkdirSync(new URL('godot_native/data/native/',root),{recursive:true});
fs.writeFileSync(new URL('godot_native/data/native/chapter4-native-source.json',root),JSON.stringify(out,null,2)+'\n');
console.log('Exported authored four-level stair campaign, honor wall, questions, puzzle contracts and chase-stair geometry');
