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
  const qKeys=['active','phase','mode','zone','vehicle','rodFound','decoyBaitAttached','lockerOpened','netCombined','feedTinRetrieved','feedTinOpened','fishCaught','swanFed','magneticRodCombined','paperCaptured','swanReleased'];
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
  await writeFile('godot_native/tests/fixtures/qizhen_branch_source.json',JSON.stringify({source:'src/modules/ChapterThreeQizhenLakeController.ts + src/core/SaveStore.ts',parts,itemIds,qKeys,orders,combinations,swan,legacy:{initial:legacyInitial,steps:legacy}},null,2)+'\n');
  console.log(`Qizhen original source fixtures: ${orders.length} branch orders, ${combinations.length} assembly cases, ${swan.length} swan cases, legacy fish path`);
} finally {await server.close();}
