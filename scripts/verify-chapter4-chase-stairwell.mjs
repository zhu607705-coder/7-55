import assert from 'node:assert/strict';
import { readFile } from 'node:fs/promises';
import { build } from 'esbuild';
const result=await build({stdin:{contents:`export * from './src/modules/ChapterFourChaseStairwellModel.ts';export * from './src/modules/ChapterFourTemporalMazeController.ts';export * from './src/modules/DeveloperChannel.ts';export * from './src/core/GameState.ts';export * from './src/core/EventBus.ts';export * from './src/core/SaveStore.ts';export * from './src/modules/ChapterFourFinalChaseModel.ts';`,resolveDir:process.cwd()},bundle:true,platform:'node',format:'esm',write:false});
const api=await import(`data:text/javascript;base64,${Buffer.from(result.outputFiles[0].text).toString('base64')}`);
const png=await readFile('src/assets/rpg/interiors/finale/finale_stairwell.png');assert.equal(png.readUInt32BE(16),1672);assert.equal(png.readUInt32BE(20),941);
const clear=[{x:833,y:826},{x:989,y:650},{x:989,y:426},{x:784,y:300},{x:715,y:57},{x:610,y:390},{x:800,y:512}];
const blocked=[{x:300,y:500},{x:721,y:388},{x:884,y:600},{x:950,y:322},{x:1100,y:800},{x:519,y:620},{x:820,y:81}];
const boxes=api.chaseStairBlockedRects();
for(const p of clear){assert(api.chaseStairFootOpen(p),`clear floor blocked: ${JSON.stringify(p)}`);assert(!boxes.some(r=>api.chaseStairInside(p,r)));}
for(const p of blocked){assert(!api.chaseStairWalkable(p),`solid source region open: ${JSON.stringify(p)}`);assert(boxes.some(r=>api.chaseStairInside(p,r)));}
for(const landing of api.CHASE_STAIR_LANDINGS){assert(api.chaseStairFootOpen(landing.spawn));assert(api.chaseStairFootOpen(landing.guard));assert(api.chaseStairPath(landing.guard,landing.spawn).length);}
for(let i=0;i<8;i++)assert(api.chaseStairLineOpen(api.CHASE_STAIR_ROUTE[i],api.CHASE_STAIR_ROUTE[i+1]),`route edge ${i} blocked`);
assert(api.chaseStairDistance(api.CHASE_STAIR_LANDINGS[0].spawn,{x:715,y:57})>1000,'stairwell must add a real traversal');
assert(api.chaseStairPath({x:610,y:390},{x:989,y:650}).length>=3,'guard must route around the railing');
assert(api.chaseStairPath({x:989,y:610},{x:917.75,y:610}).length,'wall-hugging player stays connected to guard navigation');
const seed=api.createDeveloperCheckpointState('c4-755-chase');const store=api.createGameStore(seed),bus=new api.EventBus();const controller=new api.ChapterFourTemporalMazeController(store,bus);const attempt=seed.chapter4.chaseAttempt;
const enter={type:'traverse_main_stair',fromFloor:'A1',toFloor:'A2',expectedAttempt:attempt};
assert(controller.resolve755Intent(enter).accepted);assert.equal(store.getState().chapter4.floor,'A1');assert.equal(store.getState().chapter4.chaseStairwellStage,'inside');
const exit={type:'leave_chase_stairwell',position:{x:715,y:57},expectedAttempt:attempt};
assert(!controller.resolve755Intent(exit).accepted,'entry cannot immediately complete');
assert(!controller.resolve755Intent({type:'reach_chase_stairwell_landing',landing:2,position:{x:784,y:207},expectedAttempt:attempt}).accepted,'cannot skip first landing');
assert(!controller.resolve755Intent({type:'reach_chase_stairwell_landing',landing:1,position:{x:500,y:500},expectedAttempt:attempt}).accepted,'wrong location rejected');
assert(controller.resolve755Intent({type:'reach_chase_stairwell_landing',landing:1,position:{x:989,y:426},expectedAttempt:attempt}).accepted);
class Storage {values=new Map();getItem(k){return this.values.get(k)??null;}setItem(k,v){this.values.set(k,String(v));}removeItem(k){this.values.delete(k);}}
const storage=new Storage(),saves=new api.SaveStore(storage);assert(saves.save(store.getState()));const restored=saves.load(api.createInitialGameState());assert.equal(restored.chapter4.chaseStairwellStage,'inside');assert.equal(restored.chapter4.chaseStairwellLanding,1);
assert(controller.resolve755Intent({type:'reach_chase_stairwell_landing',landing:2,position:{x:784,y:207},expectedAttempt:attempt}).accepted);assert(controller.resolve755Intent(exit).accepted);assert.equal(store.getState().chapter4.floor,'A2');assert.equal(store.getState().chapter4.chaseStairwellStage,'complete');
assert(saves.save(store.getState()));const a2=saves.load(api.createInitialGameState());assert.equal(a2.chapter4.floor,'A2');assert.equal(a2.rpgCheckpoint,'c4_a2_corridor');
const facts=[...store.getState().chapter4.factIds];assert(controller.resolve755Intent({type:'fail_chase',expectedAttempt:attempt}).accepted);assert.equal(store.getState().chapter4.floor,'A2');assert.equal(store.getState().chapter4.chaseStairwellStage,'complete');assert.equal(store.getState().chapter4.chaseRestartCheckpoint,'c4_a2_corridor');assert.equal(store.getState().chapter4.chaseStairwellLanding,0);assert.deepEqual(store.getState().chapter4.factIds,facts);assert(!controller.resolve755Intent(exit).accepted,'old attempt cannot finish after retry');
const downstairs=api.createGameStore(seed);const downstairsController=new api.ChapterFourTemporalMazeController(downstairs,new api.EventBus());assert(downstairsController.resolve755Intent({type:'fail_chase',expectedAttempt:attempt}).accepted);assert.equal(downstairs.getState().chapter4.floor,'A1');assert.equal(downstairs.getState().chapter4.chaseStairwellStage,'pending');assert.equal(downstairs.getState().chapter4.chaseRestartCheckpoint,'c4_a1_lobby');
const waitingGuard={...api.createChapterFourFinalChaseState(0),phase:'portal_transfer',portalApplied:true,floor:'A2',portalRemainingDistance:1000};
const finishWhileGuardTransfers=api.stepChapterFourFinalChase(waitingGuard,{deltaMs:16,committedAndApplied:true,floor:'A2',playerPosition:{x:1353,y:356},guardPosition:{x:966,y:214},playerInsideFinish:true,playerEnteredMainStair:false,guardContact:false});
assert.equal(finishWhileGuardTransfers.finishRequested,true,'202 must accept arrival even while the guard is still in the stairwell');
console.log(`Chase stairwell passed: source bounds, ${clear.length} clear/${blocked.length} solid samples, ${boxes.length} exact collision rectangles, guard routing, ordered gates, save/reload and chase-only retry.`);
