import assert from "node:assert/strict";
import { createServer } from "vite";
import { readFileSync } from "node:fs";
const server=await createServer({configFile:false,appType:"custom",logLevel:"error",optimizeDeps:{noDiscovery:true,include:[]},server:{middlewareMode:true,ws:false}});
try {
  const [game,dev,events,controller,saves,rooms,puzzles]=await Promise.all([
    server.ssrLoadModule("/src/core/GameState.ts"),server.ssrLoadModule("/src/modules/DeveloperChannel.ts"),
    server.ssrLoadModule("/src/core/EventBus.ts"),server.ssrLoadModule("/src/modules/ChapterFourTemporalMazeController.ts"),
    server.ssrLoadModule("/src/core/SaveStore.ts"),server.ssrLoadModule("/src/scenes/rpg/ChapterFourRoom204Model.ts"),
    server.ssrLoadModule("/src/modules/ChapterFourInsertedPuzzleModel.ts")
  ]);
  const spatial={distance:"within_range"};
  const roundtrip=state=>{const data=new Map();const memory={getItem:k=>data.get(k)??null,setItem:(k,v)=>data.set(k,v),removeItem:k=>data.delete(k)};const save=new saves.SaveStore(memory);assert(save.save(state));return save.load(game.createInitialGameState());};
  const harness=id=>{const store=game.createGameStore(dev.createDeveloperCheckpointState(id));return {store,ctrl:new controller.ChapterFourTemporalMazeController(store,new events.EventBus())};};
  {
    const layout=JSON.parse(readFileSync('src/data/chapter4-three-floor-maze.layout.json','utf8'));
    const {store,ctrl}=harness('c4-755-bakery-1225');
    const invokeTarget=(type,targetId,extra={})=>{
      const target=layout.bakeryRuntime.targetEntities.find(t=>t.targetId===targetId);
      return ctrl.resolve755Intent({type,targetId,spatial,...extra},{targetId,entityId:target.entityId,bounds:target.installationBounds});
    };
    assert(invokeTarget('inspect_bakery_conveyor_lamp','a1_bakery_inspection_lamp').accepted);
    assert(ctrl.resolve755Intent({type:'complete_bakery_conveyor_stop'}).accepted);
    assert(invokeTarget('collect_hour_hand','a1_bakery_hour_hand_pickup').accepted);
    assert.equal(store.getState().chapter4.roomId,'a1_bakery');
    const install={type:'install_hour_hand',itemId:'oldClockHourHand',targetId:'a1_hall_clock_hour_hand_socket'};
    const before=store.getState();
    assert.equal(ctrl.resolve755Intent({...install,spatial:{distance:'too_far'}}).reason,'too_far','clock reachability uses physical distance, not stale bakery room metadata');
    assert.equal(store.getState(),before,'a distant drop must keep the item and state');
    assert(ctrl.resolve755Intent({...install,spatial}).accepted,'walking back to the hall must enable the clock socket without a room-id rewrite');
    assert.equal(store.getState().chapter4.timeState,'1225_bakery');
    assert.equal(store.getState().items.oldClockHourHand,false);
    assert.equal(roundtrip(store.getState()).chapter4.timeState,'1225_bakery');
  }
  for(const [id,before,after] of [["c4-755-clock-1850-ready","1225_bakery","1850_evening"],["c4-755-clock-2245-ready","1850_evening","2245_maintenance"]]){
    const {store,ctrl}=harness(id);assert.equal(store.getState().chapter4.timeState,before);
    const restored=roundtrip(store.getState());assert.equal(restored.chapter4.timeState,before,"reload must not skip the player's pending clock operation");assert.equal(restored.chapter4.guardMode,"absent");
    assert(ctrl.resolve755Intent({type:"adjust_hall_clock_time",targetId:"a1_hall_clock",targetTimeState:after,spatial}).accepted);
    assert.equal(roundtrip(store.getState()).chapter4.timeState,after);
  }
  const answers=[
    {puzzleId:"duty_board",order:["classroom_104","classroom_105","main_elevator"]},
    {puzzleId:"archive_index",yearBand:"1991_1998",floor:"A3",purpose:"wayfinding"},
    {puzzleId:"media_alignment",xOffset:2,yOffset:-1,rotationQuarterTurns:1},
    {puzzleId:"positioning_calibration",horizontal:-2,vertical:1,pressure:3},
    {puzzleId:"power_topology",edgeIds:["hall__west_corridor","hall__east_corridor","west_corridor__bakery_back_area","east_corridor__classroom_zone","bakery_back_area__classroom_zone"]},
    {puzzleId:"evacuation_route",order:["lecture_202_door","east_corridor","transport_core","main_stair_down"]}
  ];
  for(const answer of answers){
    const {store,ctrl}=harness("c4-755-a2-field-records");const floor=answer.puzzleId==="duty_board"?"A1":["archive_index","media_alignment"].includes(answer.puzzleId)?"A3":"A2";
    const fact=puzzles.CHAPTER_FOUR_INSERTED_PUZZLES[answer.puzzleId].factId;
    store.setState(s=>({...s,chapter4:{...s.chapter4,floor,mode:"light",factIds:[...s.chapter4.factIds.filter(f=>f!==fact),...(answer.puzzleId==="media_alignment"?["a3_archive_film_retrieved"]:[])]}}));
    assert(ctrl.resolve755Intent({type:"complete_inserted_puzzle",answer}).accepted,answer.puzzleId);
    assert(roundtrip(store.getState()).chapter4.factIds.includes(fact),`${answer.puzzleId} must survive save/reload`);
    assert(!ctrl.resolve755Intent({type:"complete_inserted_puzzle",answer}).accepted,"replay must not grant completion twice");
  }
  const {store,ctrl}=harness("c4-755-maintenance-2245");
  assert(ctrl.resolve755Intent({type:"complete_maintenance_diagnosis",answers:{wheel_sound:"latch",clock_jam:"gear_offset",oil_trace:"oil_shortage"}}).accepted);
  assert(store.getState().items.shortPryBar);
  assert(!store.getState().items.universalLubricatingOil,"oil is found when the wheel cover is opened, not fabricated by diagnosis");
  const layout=JSON.parse(readFileSync("src/data/chapter4-three-floor-maze.layout.json","utf8"));
  const cover=layout.maintenanceRuntime.targetEntities.find(t=>t.targetId==="a1_cleaning_cart_wheel_cover");
  assert(ctrl.resolve755Intent({type:"open_cart_wheel_cover",itemId:"shortPryBar",targetId:cover.targetId,spatial},
    {targetId:cover.targetId,entityId:cover.entityId,bounds:cover.installationBounds}).accepted);
  assert(store.getState().items.universalLubricatingOil);
  assert.equal(rooms.selectRoom204RuntimePresentation("maintenance_repair",true,rooms.createCanonicalCompleteRoom204Placements()),"restored");
  console.log("History restoration PASS: manual clock/save, six investigation rewards/save, diagnosis/cover and restored Room204 display.");
} finally { await server.close(); }
