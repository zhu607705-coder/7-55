// Execute the active, unmodified TypeScript controller and SaveStore as the oracle.
// No expected item transitions are reimplemented here.
import {createServer} from 'vite';
import {writeFile} from 'node:fs/promises';
const server=await createServer({configFile:false,appType:'custom',logLevel:'error',optimizeDeps:{noDiscovery:true,include:[]},server:{middlewareMode:true,ws:false}});
try {
  const [{createGameStore,createInitialGameState},{EventBus},{ChapterThreeQizhenLakeController},{SaveStore}]=await Promise.all([
    server.ssrLoadModule('/src/core/GameState.ts'),server.ssrLoadModule('/src/core/EventBus.ts'),
    server.ssrLoadModule('/src/modules/ChapterThreeQizhenLakeController.ts'),server.ssrLoadModule('/src/core/SaveStore.ts')
  ]);
  const parts=['nylonCord','brokenNetFrame','swanMagnet','fishingRod'];
  const itemIds=[...parts,'magneticFishingRod','rustedLockerKey','improvisedDipNet','sealedFeedTin','fishFeedPellets','smallCarp','decoyPaper'];
  const qKeys=['active','phase','mode','zone','vehicle','rodFound','decoyBaitAttached','lockerOpened','netCombined','legacyNetMaterialsConsumed','feedTinRetrieved','feedTinOpened','fishCaught','swanFed','magneticRodCombined','paperCaptured','swanReleased'];
  const project=s=>({items:Object.fromEntries(itemIds.map(k=>[k,s.items[k]])),qizhenLake:Object.fromEntries(qKeys.map(k=>[k,s.qizhenLake[k]])),selectedItem:s.ui.selectedItem});
  function fixture(itemPatch={},qPatch={},selectedItem=null) {
    const fresh=createInitialGameState();
    const state={...fresh,items:{...fresh.items,fishingRod:true,decoyPaper:false,...itemPatch},ui:{...fresh.ui,selectedItem},qizhenLake:{...fresh.qizhenLake,active:true,phase:'tool_chain',mode:'light',zone:'open_water',vehicle:'kayak',rodFound:true,decoyBaitAttached:true,boardingTutorialCompleted:true,...qPatch}};
    const store=createGameStore(state),controller=new ChapterThreeQizhenLakeController(store,new EventBus());
    return {store,controller};
  }
  function move(f,zone,vehicle='kayak') {f.store.setState(s=>({...s,qizhenLake:{...s.qizhenLake,zone,vehicle}}));}
  function reload(f) {
    const data=new Map(); const save=new SaveStore({getItem:k=>data.get(k)??null,setItem:(k,v)=>data.set(k,v),removeItem:k=>data.delete(k)});
    save.save(f.store.getState());f.store.setState(()=>save.load(createInitialGameState()));
  }
  function record(f,steps,op,args,result) {steps.push({op,args,result,expected:project(f.store.getState())});}
  function act(f,steps,op,args=[]) {const result=f.controller[op](...args);record(f,steps,op,args,result);}
  const permutations=a=>a.length<2?[a]:a.flatMap((v,i)=>permutations(a.filter((_,j)=>i!==j)).map(t=>[v,...t]));
  const orders=[];
  for(const order of permutations(['locker','raft','swan'])) {
    const f=fixture(),steps=[],initial=project(f.store.getState());
    for(const branch of order) {
      if(branch==='locker') {
        move(f,'open_water');record(f,steps,'move',['open_water','kayak'],'accepted');
        act(f,steps,'castAt',['locker_key']);
        move(f,'dock','on_foot');record(f,steps,'move',['dock','on_foot'],'accepted');
        act(f,steps,'useItemAt',['qizhen_use_item_1','rustedLockerKey']);
      } else if(branch==='raft') {
        move(f,'channel');record(f,steps,'move',['channel','kayak'],'accepted');act(f,steps,'castAt',['net_frame']);
      } else {
        move(f,'swan_cove');record(f,steps,'move',['swan_cove','kayak'],'accepted');act(f,steps,'completeSwanBranch');
      }
      reload(f);record(f,steps,'reload',[],'accepted');
    }
    act(f,steps,'combineItems',[parts.filter(p=>p!=='swanMagnet')]);
    act(f,steps,'combineItems',[[...parts].reverse()]);
    reload(f);record(f,steps,'reload',[],'accepted');
    act(f,steps,'combineItems',[parts]);
    orders.push({order,initial,steps});
  }
  const combinations=[];
  function combo(label,owned,requested,qPatch={},selected='nylonCord') {
    const f=fixture(Object.fromEntries(parts.map(k=>[k,owned.includes(k)])),qPatch,selected);
    const initial=project(f.store.getState());const result=f.controller.combineItems(requested);
    combinations.push({label,initial,requested,result,expected:project(f.store.getState())});
  }
  for(let mask=0;mask<16;mask++) {
    const subset=parts.filter((_,i)=>(mask&(1<<i))!==0);
    combo(`owned_subset_${mask}`,subset,parts);combo(`requested_subset_${mask}`,parts,subset);
  }
  for(const phase of ['inactive','lake_exploration','tool_chain','swan_exchange','paper_capture','swan_chase','complete'])combo(`phase_${phase}`,parts,parts,{phase});
  combo('inactive_flag',parts,parts,{active:false});combo('dark_mode',parts,parts,{mode:'dark'});
  combo('already_combined',parts,parts,{magneticRodCombined:true});
  combo('permuted',parts,[...parts].reverse());combo('duplicate_missing',parts,['nylonCord','nylonCord','swanMagnet','fishingRod']);
  combo('superset',parts,[...parts,'decoyPaper']);combo('selection_unrelated',parts,parts,{},'campusCard');
  combo('legacy_stale_spent_selection',['fishingRod','swanMagnet'],parts,{legacyNetMaterialsConsumed:true,netCombined:true,lockerOpened:true,feedTinRetrieved:true},'nylonCord');
  for(const [label,patch] of [
    ['legacy_missing_net',{netCombined:false}],['legacy_missing_locker',{lockerOpened:false}],
    ['legacy_missing_consumption',{feedTinRetrieved:false}],['legacy_non_boolean_credit',{legacyNetMaterialsConsumed:1}]
  ])combo(label,['fishingRod','swanMagnet'],parts,{legacyNetMaterialsConsumed:true,netCombined:true,lockerOpened:true,feedTinRetrieved:true,...patch});
  const swan=[];
  for(const [label,qPatch,itemPatch] of [
    ['independent',{},{}],['dark',{mode:'dark'},{}],['wrong_zone',{zone:'open_water'},{}],['wrong_phase',{phase:'swan_exchange'},{}],
    ['duplicate_flag',{swanFed:true},{}],['duplicate_item',{}, {swanMagnet:true}]
  ]) {
    const f=fixture(itemPatch,{zone:'swan_cove',...qPatch}),initial=project(f.store.getState());
    const result=f.controller.completeSwanBranch();swan.push({label,initial,result,expected:project(f.store.getState())});
  }
  const legacyFixture=fixture({improvisedDipNet:true},{netCombined:true,lockerOpened:true,zone:'swan_cove'}),legacy=[];
  const legacyInitial=project(legacyFixture.store.getState());
  act(legacyFixture,legacy,'useItemAt',['qizhen_use_item_4','improvisedDipNet']);
  act(legacyFixture,legacy,'useItemAt',['qizhen_use_item_5','sealedFeedTin']);
  move(legacyFixture,'open_water');record(legacyFixture,legacy,'move',['open_water','kayak'],'accepted');
  act(legacyFixture,legacy,'castAt',['fish']);
  move(legacyFixture,'swan_cove');record(legacyFixture,legacy,'move',['swan_cove','kayak'],'accepted');
  act(legacyFixture,legacy,'feedSwan',['smallCarp']);
  reload(legacyFixture);record(legacyFixture,legacy,'reload',[],'accepted');
  act(legacyFixture,legacy,'combineItems',[parts]);reload(legacyFixture);record(legacyFixture,legacy,'reload',[],'accepted');act(legacyFixture,legacy,'combineItems',[parts]);
  const legacySaves=[];
  for(const [label,version,kind] of [['legacy_v18',18,'earned'],['legacy_v26',26,'earned'],['legacy_v35',35,'earned'],['phase_only',35,'phase_only'],['explicit_false',35,'explicit_false']]) {
    const f=fixture({smallCarp:true},{phase:'swan_exchange',zone:'swan_cove',lockerOpened:true,netCombined:true,feedTinRetrieved:true,feedTinOpened:true,fishCaught:true});
    f.store.setState(s=>({...s,runtimeMode:'rpg',rpgScene:'qizhen_lake'}));
    const raw={version,state:structuredClone(f.store.getState())};
    delete raw.state.qizhenLake.legacyNetMaterialsConsumed;
    if(kind==='phase_only')for(const key of ['lockerOpened','netCombined','feedTinRetrieved','feedTinOpened','fishCaught'])delete raw.state.qizhenLake[key];
    if(kind==='explicit_false')raw.state.qizhenLake.legacyNetMaterialsConsumed=false;
    const memory=new Map([['seven_fifty_five_state',JSON.stringify(raw)]]);
    const save=new SaveStore({getItem:k=>memory.get(k)??null,setItem:(k,v)=>memory.set(k,v),removeItem:k=>memory.delete(k)});
    f.store.setState(()=>save.load(createInitialGameState()));
    const initial=project(f.store.getState()),steps=[];
    act(f,steps,'feedSwan',['smallCarp']);reload(f);record(f,steps,'reload',[],'accepted');
    reload(f);record(f,steps,'reload',[],'accepted');act(f,steps,'combineItems',[parts]);
    reload(f);record(f,steps,'reload',[],'accepted');act(f,steps,'combineItems',[parts]);
    legacySaves.push({label,kind,raw,initial,steps});
  }
  await writeFile('godot_native/tests/fixtures/qizhen_branch_source.json',JSON.stringify({source:'src/modules/ChapterThreeQizhenLakeController.ts + src/core/SaveStore.ts',parts,itemIds,qKeys,orders,combinations,swan,legacy:{initial:legacyInitial,steps:legacy},legacySaves},null,2)+'\n');
  console.log(`Qizhen original source fixtures: ${orders.length} branch orders, ${combinations.length} assembly cases, ${swan.length} swan cases, legacy fish path and ${legacySaves.length} saved continuations`);
} finally {await server.close();}
