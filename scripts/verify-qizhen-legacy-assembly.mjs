import assert from 'node:assert/strict';
import {createServer} from 'vite';
import {createElement} from 'react';
import {renderToStaticMarkup} from 'react-dom/server';

const server=await createServer({configFile:false,appType:'custom',logLevel:'error',optimizeDeps:{noDiscovery:true,include:[]},server:{middlewareMode:true,ws:false}});
try {
  const [{createGameStore,createInitialGameState},{EventBus},{ChapterThreeQizhenLakeController},{SaveStore},assembly,{RpgInventoryDock}]=await Promise.all([
    server.ssrLoadModule('/src/core/GameState.ts'),server.ssrLoadModule('/src/core/EventBus.ts'),
    server.ssrLoadModule('/src/modules/ChapterThreeQizhenLakeController.ts'),server.ssrLoadModule('/src/core/SaveStore.ts'),
    server.ssrLoadModule('/src/modules/QizhenFinalAssembly.ts'),server.ssrLoadModule('/src/scenes/rpg/RpgInventoryDock.tsx')
  ]);
  const parts=assembly.QIZHEN_FINAL_RIG_PARTS;
  const ids=[...parts,'smallCarp','magneticFishingRod','improvisedDipNet'];
  const items=s=>Object.fromEntries(ids.map(id=>[id,s.items[id]]));
  function fixture(qPatch={},itemPatch={}) {
    const initial=createInitialGameState();
    const store=createGameStore({...initial,checkinDone:true,actOne:{...initial.actOne,phase:'complete',inventoryRecovered:true},runtimeMode:'rpg',rpgScene:'qizhen_lake',items:{...initial.items,fishingRod:true,smallCarp:true,...itemPatch},qizhenLake:{...initial.qizhenLake,active:true,phase:'swan_exchange',zone:'swan_cove',mode:'light',vehicle:'kayak',rodFound:true,lockerOpened:true,netCombined:true,feedTinRetrieved:true,feedTinOpened:true,fishCaught:true,...qPatch}});
    const events=new EventBus(),emitted=[];events.subscribe(e=>emitted.push(e));
    return {store,events,emitted,controller:new ChapterThreeQizhenLakeController(store,events)};
  }
  function reload(f,{old=false,version=35,phaseOnly=false}={}) {
    const data=new Map();const save=new SaveStore({getItem:k=>data.get(k)??null,setItem:(k,v)=>data.set(k,v),removeItem:k=>data.delete(k)});
    assert.equal(save.save(f.store.getState()),true);
    if(old) {
      const envelope=JSON.parse(data.get('seven_fifty_five_state'));envelope.version=version;
      delete envelope.state.qizhenLake.legacyNetMaterialsConsumed;
      if(phaseOnly)for(const key of ['netCombined','lockerOpened','feedTinRetrieved','feedTinOpened','fishCaught'])delete envelope.state.qizhenLake[key];
      data.set('seven_fifty_five_state',JSON.stringify(envelope));
    }
    const loaded=save.load(createInitialGameState());assert.ok(loaded);f.store.setState(()=>loaded);
  }
  for(const version of [18,26,35]) {
    const f=fixture(),before=items(f.store.getState());reload(f,{old:true,version});
    assert.equal(f.store.getState().qizhenLake.legacyNetMaterialsConsumed,true,'explicit old net consumption survives migration');
    assert.deepEqual(items(f.store.getState()),before,'migration grants no material or final rod');
    assert.equal(f.controller.feedSwan('smallCarp'),'accepted');
    assert.equal(f.store.getState().items.fishingRod,true);
    assert.equal(f.store.getState().items.magneticFishingRod,false,'feeding cannot assemble the rod');
    reload(f);assert.equal(assembly.hasQizhenFinalAssemblyMaterials(f.store.getState()),true);
    const html=renderToStaticMarkup(createElement(RpgInventoryDock,{state:f.store.getState(),events:f.events,shellRef:{current:null},canvasHostRef:{current:null},runtimeScene:'qizhen_lake',onInspect:()=>{},onDragSelectionChange:()=>{}}));
    assert.match(html,/组合四件材料/,'legacy continuation still exposes its real assembly control');
    assert.match(html,/绳和网框已用于旧抄网/,'legacy UI explains why spent parts are absent');
    assert.equal(f.controller.combineItems(parts),'accepted');
    assert.deepEqual(items(f.store.getState()),{nylonCord:false,brokenNetFrame:false,swanMagnet:false,fishingRod:false,smallCarp:false,magneticFishingRod:true,improvisedDipNet:false});
    assert.deepEqual(f.emitted.findLast(e=>e.name==='combine_item').payload.items,['swanMagnet','fishingRod'],'already spent cord/frame are not consumed again');
    assert.equal(f.store.getState().qizhenLake.legacyNetMaterialsConsumed,false,'assembly closes its credit');
    const settled=JSON.stringify(f.store.getState());assert.equal(f.controller.combineItems(parts),'already_complete');assert.equal(JSON.stringify(f.store.getState()),settled);
    reload(f);assert.equal(f.store.getState().items.magneticFishingRod,true);assert.equal(f.store.getState().qizhenLake.legacyNetMaterialsConsumed,false);
  }
  const phaseOnly=fixture();reload(phaseOnly,{old:true,phaseOnly:true});
  assert.equal(phaseOnly.store.getState().qizhenLake.legacyNetMaterialsConsumed,false,'phase alone cannot prove spent materials');
  assert.equal(phaseOnly.controller.feedSwan('smallCarp'),'accepted');
  for(let i=0;i<2;i++)reload(phaseOnly);
  assert.equal(phaseOnly.store.getState().qizhenLake.legacyNetMaterialsConsumed,false,'repeat normalization cannot launder inferred net flags into credit');
  const unchanged=JSON.stringify(phaseOnly.store.getState());assert.equal(phaseOnly.controller.combineItems(parts),'wrong_item');assert.equal(JSON.stringify(phaseOnly.store.getState()),unchanged);
  for(const patch of [{legacyNetMaterialsConsumed:true,netCombined:false},{legacyNetMaterialsConsumed:true,lockerOpened:false},{legacyNetMaterialsConsumed:true,feedTinRetrieved:false},{legacyNetMaterialsConsumed:1}]) {
    const f=fixture(patch,{smallCarp:false,swanMagnet:true});
    assert.equal(f.controller.combineItems(parts),'wrong_item','an unsupported receipt cannot substitute for materials');
  }
  for(const missing of ['fishingRod','swanMagnet']) {
    const f=fixture({legacyNetMaterialsConsumed:true},{smallCarp:false,swanMagnet:true,[missing]:false});
    assert.equal(f.controller.combineItems(parts),'wrong_item','credit never substitutes for rod or magnet');
  }
  const net=fixture({phase:'tool_chain',feedTinRetrieved:false,feedTinOpened:false,fishCaught:false},{improvisedDipNet:true,smallCarp:false});
  assert.equal(net.controller.useItemAt('qizhen_use_item_4','improvisedDipNet'),'accepted');
  assert.equal(net.store.getState().qizhenLake.legacyNetMaterialsConsumed,true,'actual net consumption issues the same bounded receipt');
  const fresh=fixture({phase:'tool_chain',netCombined:false,lockerOpened:true,legacyNetMaterialsConsumed:false},{smallCarp:false,nylonCord:true,brokenNetFrame:true,swanMagnet:true});
  assert.equal(fresh.controller.combineItems(parts),'accepted');
  assert.deepEqual(fresh.emitted.findLast(e=>e.name==='combine_item').payload.items,[...parts],'fresh play still consumes exactly four owned parts');
  console.log('Qizhen legacy assembly PASS: old saves v18/v26/v35, feeding, actual inventory control, no duplicate consumption, reload and negative proof cases');
} finally {await server.close();}
