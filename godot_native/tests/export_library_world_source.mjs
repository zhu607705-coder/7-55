import fs from 'node:fs';
import vm from 'node:vm';
import ts from 'typescript';
import crypto from 'node:crypto';
import { fileURLToPath } from 'node:url';
import { createRequire } from 'node:module';
const require=createRequire(import.meta.url);
const stepped=require('phaser/src/math/easing/stepped/Stepped.js');
const root=fileURLToPath(new URL('../../',import.meta.url));
const read=p=>fs.readFileSync(root+p,'utf8');
const scene=read('src/scenes/rpg/LibraryInteriorScene.ts');
const model=read('src/scenes/rpg/LibraryInteriorModel.ts');
const motion=read('src/scenes/rpg/LibraryShelfRevealMotion.ts');
const evaluate=(code,expression,extra={})=>{
 const js=ts.transpileModule(code.replace(/export /g,''),{compilerOptions:{target:ts.ScriptTarget.ES2022}}).outputText;
 const ctx=vm.createContext({Math,...extra});vm.runInContext(js+`;result=${expression}`,ctx);return ctx.result;
};
const shelf=evaluate(model.slice(model.indexOf('export const LIBRARY_SHELF_SOURCE_BOUNDS'),model.indexOf('// Bounds are authored'))+motion,'({bounds:LIBRARY_SHELF_SOURCE_BOUNDS,outline:LIBRARY_SHELF_OUTLINE,frames:LIBRARY_SHELF_REVEAL_FRAMES,shiftPx:LIBRARY_SHELF_REVEAL_SHIFT_PX,totalMs:LIBRARY_SHELF_REVEAL_TOTAL_MS,collisionSamples:[-2,-1,0,1,2,4,6,8,10,12,14,16].map(offset=>({offset,...getLibraryShelfCollision(offset)}))})');
const shape=(type,x,y,width,height,color,alpha=1)=>({type,x,y,width,height,color,alpha,angle:0,setAngle(a){this.angle=a;return this},setStrokeStyle(width,color,alpha=1){this.stroke={width,color,alpha};return this}});
const add={rectangle:(...args)=>shape('rectangle',...args),ellipse:(...args)=>shape('ellipse',...args),container:(x,y,parts)=>({x,y,parts,setDepth(depth){this.depth=depth;return this},setScale(scale){this.scale=scale;return this},setAngle(angle){this.angle=angle;return this}})};
const backpack=evaluate('const BACKPACK_BASE_SCALE=0.6; class Source { add=add;'+scene.slice(scene.indexOf('  private createBackpack('),scene.indexOf('  private createPaperObject('))+'}', 'new Source().createBackpack(1255,407)',{add});
const clean=JSON.parse(JSON.stringify(backpack));
const patch=JSON.parse(scene.match(/const BACKPACK_TABLE_PATCH_SOURCE = (\{.*?\}) as const;/)[1].replace(/(\w+):/g,'"$1":'));
const desk=evaluate(scene.slice(scene.indexOf('const LIBRARY_FRONT_DESK_COUNTER_FOREGROUND_BOUNDS'),scene.indexOf('const ITEM_LABELS')), '({counterBounds:LIBRARY_FRONT_DESK_COUNTER_FOREGROUND_BOUNDS,position:LIBRARY_FRONT_DESK_STAFF_POSITION,scale:LIBRARY_FRONT_DESK_STAFF_SCALE,stampPosition:LIBRARY_FRONT_DESK_STAMP_POSITION,stampHeadX:LIBRARY_FRONT_DESK_STAMP_HEAD_X,stampRestY:LIBRARY_FRONT_DESK_STAMP_REST_Y,stampPressY:LIBRARY_FRONT_DESK_STAMP_PRESS_Y})');
desk.idleFrames=[0,0,0,1,1,0];desk.frameRate=1.8;desk.repeatDelayMs=900;desk.staffDepth=706;desk.counterDepth=728;desk.serviceDepth=742;
const files=['src/scenes/rpg/LibraryInteriorScene.ts','src/scenes/rpg/LibraryInteriorModel.ts','src/scenes/rpg/LibraryShelfRevealMotion.ts'];
const result={frontDesk:desk,steppedSamples:[0,0.001,0.25,0.5,0.999,1].map(value=>({value,result:stepped(value)})),sources:files.map(path=>({path,sha256:crypto.createHash('sha256').update(read(path)).digest('hex')})),shelf,backpack:clean,backpackClearPatchSource:patch,playerDepthOffset:120,shelfFloorSourceTop:shelf.bounds.top+160,shelfDepth:234+96,mechanismDepth:418,paperDepth:425,backpackTimeline:{shakeDurationMs:70,shakeRepeat:8,shakeYoyo:true,waitMs:1900,transferMs:1200,transferTo:{x:334,y:634}},shelfPaperTimeline:{waitMs:110,revealMs:240,holdMs:220,transferMs:220,reduced:{slideMs:140,revealMs:120,holdMs:20,transferMs:100}}};
// These source snippets guard timing extraction against an unnoticed source change.
for(const pattern of ['duration: 70,','repeat: 8,','duration: 1200,','delay: 1900,','x: this.backpack.x + 7,','y: getLibraryTarget("front_desk").y + 40,','this.time.delayedCall(elapsedMs + 110','duration: this.reducedMotion ? 120 : 240,','duration: this.reducedMotion ? 100 : 220,']) if(!scene.includes(pattern))throw Error('Changed source animation contract: '+pattern);
const path=root+'godot_native/data/native/library-world-source.json';const serialized=JSON.stringify(result,null,2)+'\n';
if(process.argv.includes('--check')){if(fs.readFileSync(path,'utf8')!==serialized)throw Error('Native Library world source data is stale');console.log('Library world source geometry/timelines match');}else{fs.writeFileSync(path,serialized);console.log(path)}
