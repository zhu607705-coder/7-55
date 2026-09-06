import assert from 'node:assert/strict';
import { build } from 'esbuild';

const result = await build({ stdin: { contents: `export * from './src/scenes/rpg/TheaterSpotlightModel.ts'; export * from './src/modules/ChapterThreeTheaterController.ts'; export * from './src/core/GameState.ts'; export * from './src/core/EventBus.ts';`, resolveDir: process.cwd() }, bundle: true, platform: 'node', format: 'esm', write: false });
const api = await import(`data:text/javascript;base64,${Buffer.from(result.outputFiles[0].text).toString('base64')}`);
function play(round, attempt = 0) {
  let state = api.createTheaterShow(round, attempt);
  const inputs = [];
  while (state.status === 'running') {
    const foods = api.getTheaterShowFood(state);
    const target = [...foods].sort((a,b)=>Math.hypot(a.x-state.head.x,a.y-state.head.y)-Math.hypot(b.x-state.head.x,b.y-state.head.y))[0] ?? api.getTheaterShowMouth(state);
    const dx = target.x-state.head.x, dy = target.y-state.head.y, length = Math.hypot(dx,dy);
    const danger = api.getTheaterShowHazards(state).some(h=>Math.hypot(h.x-state.head.x,h.y-state.head.y)<85);
    const input = { x: dx/(length||1), y: dy/(length||1), dash: danger && state.dashCooldown===0 };
    inputs.push(input); state = api.stepTheaterShow(state,input);
  }
  return { state, trace: { version: 2, round, attempt, inputs } };
}
const wins = [];
for (let round=0;round<3;round++) {
  const {state,trace} = play(round);
  assert.equal(state.status,'won',`act ${round+1} needs a playable route`);
  assert.deepEqual(api.validateTheaterSpotlightAttempt(trace,round,0),state,'replay must exactly match runtime');
  assert.equal(api.validateTheaterSpotlightAttempt({...trace,version:1},round,0),null,'reject former game protocol');
  assert.equal(api.validateTheaterSpotlightAttempt(trace,round,1),null,'reject stale attempt');
  assert.equal(api.validateTheaterSpotlightAttempt({...trace,inputs:trace.inputs.slice(0,-5)},round,0),null,'reject unfinished trace');
  assert.equal(api.validateTheaterSpotlightAttempt({...trace,inputs:[...trace.inputs,{x:0,y:0,dash:false}]},round,0),null,'reject input after terminal state');
  assert.equal(api.validateTheaterSpotlightAttempt({...trace,inputs:[{x:NaN,y:0,dash:false}]},round,0),null,'reject nonfinite control');
  assert.equal(api.validateTheaterSpotlightAttempt({...trace,inputs:Array(1601).fill({x:0,y:0,dash:false})},round,0),null,'bound replay work');
  wins.push(trace);
  console.log(`act ${round+1}: won, ${state.tick} steps, ${state.lives} lights remaining`);
}
let failure = api.createTheaterShow(0);
const failureInputs=[];
while (failure.status==='running') { const input={x:0,y:0,dash:false};failureInputs.push(input);failure=api.stepTheaterShow(failure,input); }
assert.equal(failure.tick,api.THEATER_SHOW_MAX_TICKS,'stationary first act times out');
assert.equal(api.validateTheaterSpotlightAttempt({version:2,round:0,attempt:0,inputs:failureInputs},0,0).status,'lost');
const held = {x:1,y:0,dash:true};let dash = api.stepTheaterShow(api.createTheaterShow(0),held);
for(let i=0;i<120;i++)dash=api.stepTheaterShow(dash,held);
assert.equal(dash.dashTicks,0,'holding dash does not bypass recharge or auto-repeat');
const bounded = api.stepTheaterShow(api.createTheaterShow(0),{x:-1,y:-1,dash:true});
assert(bounded.head.x>=api.THEATER_SHOW_BOUNDS.left && bounded.head.y>=api.THEATER_SHOW_BOUNDS.top);
const initial=api.createInitialGameState();
initial.theaterHunt={...initial.theaterHunt,active:true,phase:'spotlight_hunt',mode:'light'};
const store=api.createGameStore(initial),events=new api.EventBus(),controller=new api.ChapterThreeTheaterController(store,events);
assert.equal(controller.resolveSpotlightAttempt({version:2,round:0,attempt:0,inputs:[]}),false);
assert.equal(store.getState().theaterHunt.spotlightMistakes,0,'malformed input is not a gameplay mistake');
for(let round=0;round<3;round++) {
  assert.equal(controller.resolveSpotlightAttempt(wins[round]),true);
  assert.equal(store.getState().theaterHunt.spotlightRound,round+1);
  assert.equal(controller.resolveSpotlightAttempt(wins[round]),false,'duplicate cannot advance');
}
assert.equal(store.getState().theaterHunt.phase,'reversal');
assert.equal(controller.completeReversal(),true);
assert.equal(store.getState().theaterHunt.phase,'complete');
assert.equal(store.getState().items.wetProgram,true);
assert.equal(store.getState().qizhenLake.active,true);
const retryStore=api.createGameStore(initial),retryEvents=new api.EventBus(),retry=new api.ChapterThreeTheaterController(retryStore,retryEvents);
const failedTrace={version:2,round:0,attempt:0,inputs:failureInputs};
assert.equal(retry.resolveSpotlightAttempt(failedTrace),false);
assert.equal(retryStore.getState().theaterHunt.spotlightMistakes,1);
assert.equal(retryStore.getState().theaterHunt.spotlightRound,0);
retry.resolveSpotlightAttempt(failedTrace);
assert.equal(retryStore.getState().theaterHunt.spotlightMistakes,1,'stale failure cannot count twice');
assert.equal(retry.resolveSpotlightAttempt(play(0,1).trace),true,'a failed act can be retried');
console.log('Theater surreal show: deterministic routes, trace validation, failure/retry and story handoff passed.');
