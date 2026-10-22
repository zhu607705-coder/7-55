extends SceneTree
## Read-only journey views, original officer surface and bounded reflection guidance.
## These fixtures grant no manual progress, fishing proof or reward.
const Lake=preload("res://scripts/chapters/c3_lake.gd")
const Layers=preload("res://scripts/ui/chapter3_world_layers.gd")
var checks:=0
var failures:=0
func _initialize() -> void: run.call_deferred()
func check(ok: bool,label: String) -> void:
	checks+=1
	if not ok: failures+=1; push_error(label)
func officer(layer: RefCounted,s: Dictionary) -> Dictionary:
	for entry: Dictionary in layer.entries(s):
		if entry.id=="qizhen_dock_safety_officer": return entry
	return {}
func simulate_confirmation_for_hud_unit(world: Control,target: Dictionary) -> void:
	# This World-only fixture has no Main/input routing. Seed post-confirmation
	# presentation state explicitly; real pointer dispatch is tested separately
	# by test_mobile_direct_touch.gd. This helper performs no interaction/action.
	world.mobile_confirmed_target_id=str(target.get("id",""))
	world.mobile_confirmed_world_key=world.world_key
func run() -> void:
	var state: Node=root.get_node("State"); state.developer_mode=true
	var lake:=Lake.new(); var s: Dictionary=state.initial()
	s.native.chapter=3; s.native.scene="qizhen_lake"; s.native.page="c3_lake"; s.native.mode="light"
	s.qizhenLake.merge({"active":true,"phase":"tool_chain","zone":"dock","vehicle":"on_foot","boardingTutorialCompleted":true,"kayakEquipped":true,"leftPaddleEquipped":true,"rightPaddleEquipped":true,"rainSafetyCleared":true,"lockerOpened":true},true)
	s.items.fishingRod=true; s.items.nylonCord=true
	var before: String=JSON.stringify(s)
	var body: String=lake.view("c3_lake",s).body
	check(body.contains(lake.objective(s)) and body.contains("现在可以下水") and body.contains("从小码头上船"),"completed dock visit presents current goal and existing boarding action")
	check(not body.contains("交替前划四次"),"completed tutorial is not presented as unfinished")
	check(not body.contains("浮排下方"),"unobserved net-frame route is not disclosed by the phone")
	check(JSON.stringify(s)==before,"phone guidance does not change facts")
	s.qizhenLake.phase="boarding_tutorial"; s.qizhenLake.boardingTutorialCompleted=false
	check(lake.view("c3_lake",s).body.contains("交替前划四次"),"initial tutorial retains exact original requirement")
	s.native.player={"x":710,"y":650}
	check(lake.physical(s,"qizhen_dock_board").message.contains("交替前划四次"),"initial actual boarding keeps tutorial")
	s.qizhenLake.vehicle="on_foot"; s.qizhenLake.phase="tool_chain"; s.qizhenLake.boardingTutorialCompleted=true
	before=JSON.stringify(s)
	s.native.mode="dark"
	var board: Dictionary={}
	for target: Dictionary in lake.targets("qizhen_lake",s):
		if target.id=="qizhen_dock_board": board=target
	check(board.hud_prompt==lake.prose("chapter3-qizhen-lake.content","prompts.needLight"),"boarding HUD names required source mode")
	var dark_before: String=JSON.stringify(s)
	check(lake.physical(s,"qizhen_dock_board").message==board.hud_prompt,"dark refusal and visible boarding prompt agree")
	check(JSON.stringify(s)==dark_before,"dark board refusal changes no state")
	s.native.mode="light"
	var result: Dictionary=lake.physical(s,"qizhen_dock_board")
	check(result.message==lake.prose("chapter3-qizhen-lake.content","boarding.controls"),"returning boat uses original controls without restarting tutorial")
	check(s.qizhenLake.vehicle=="kayak" and s.qizhenLake.boardingTutorialCompleted and s.items.nylonCord,"boarding retains tutorial and earned cord")
	check(result.presentation.size()==1 and result.presentation[0].cueId=="qizhen_kayak_boarded","original boarding cue remains once")
	# Inherited source mismatch: only an observed reflection discloses its real location.
	s.qizhenLake.zone="open_water"; s.qizhenLake.observedFishingSpotIds=[]
	s.native.player={"x":910,"y":360}; before=JSON.stringify(s)
	result=lake.physical(s,"qizhen_reflection_item_3")
	check(result.message.contains("倒影") and not result.message.contains("朝那里抛竿"),"unobserved light reflection no longer pretends to be a cast target")
	check(JSON.stringify(s)==before,"light inspection grants no observation")
	s.native.mode="dark"; result=lake.physical(s,"qizhen_reflection_item_3")
	check(s.qizhenLake.observedFishingSpotIds==["net_frame"],"dark inspection records only the existing observed fact")
	check(result.message.contains("大湖北侧") and result.message.contains("浮排河道") and result.message.contains("浮排下方"),"observed reflection names actual channel cast location")
	lake.physical(s,"qizhen_reflection_item_3")
	check(s.qizhenLake.observedFishingSpotIds==["net_frame"],"repeated observation remains idempotent")
	s.native.mode="light"; before=JSON.stringify(s)
	check(lake.physical(s,"qizhen_reflection_item_3").message==lake.net_frame_location(),"light review retains observed route")
	check(lake.view("c3_lake",s).body.contains(lake.net_frame_location()),"phone retains previously observed location")
	check(JSON.stringify(s)==before,"recalled hint cannot grant a catch or consume an item")
	var loaded: Dictionary=JSON.parse_string(JSON.stringify(s))
	check(lake.view("c3_lake",loaded).body.contains(lake.net_frame_location()),"ordinary serialization retains clue review")
	s.native.player={"x":10,"y":10}; before=JSON.stringify(s)
	lake.physical(s,"qizhen_reflection_item_3")
	check(JSON.stringify(s)==before,"far interaction retains original range guard")
	s.native.player={"x":1040,"y":620}
	check(lake.physical(s,"qizhen_reflection_item_1").message==lake.prose("chapter3-qizhen-lake.content","reflection.lightWater"),"co-located key reflection keeps original behavior")
	var target: Dictionary={}
	for entry: Dictionary in lake.definitions():
		if entry.id=="qizhen_fishing_item_3": target=entry
	check(target.zone=="channel" and Vector2(target.x,target.y)==Vector2(640,575),"physical cast anchor stays at source channel location")
	check(lake.CATCH_ZONE.net_frame==target.zone and Vector2(lake.CATCH_POINTS.net_frame[0],lake.CATCH_POINTS.net_frame[1])==Vector2(target.x,target.y),"guidance agrees with unchanged controller cast authority")
	s.items.brokenNetFrame=true
	check(not lake.view("c3_lake",s).body.contains(lake.net_frame_location()),"caught item retires its location reminder")
	# Reuse the original sheet, dimensions, foot anchor, source ordering and pick surface.
	s.qizhenLake.zone="dock"; s.qizhenLake.vehicle="on_foot"; s.native.selected_item=""
	var layer:=Layers.new(); layer.sync(s,true); before=JSON.stringify(s)
	var entry: Dictionary=officer(layer,s)
	check(not entry.is_empty(),"original teacher is visible at the active dock")
	check(entry.asset=="res://assets/rpg/npcs/finale/guard_check_watch_2frame.png" and layer.texture(entry.asset)!=null,"original teacher asset loads")
	check(entry.frameSize==Vector2(96,128) and entry.scale==.52 and entry.point==Vector2(650,746) and entry.anchor==Vector2(.5,1) and entry.depth==748,"original teacher source metrics retained")
	check(entry.frame==0,"first idle frame")
	for i in range(5): layer.tick(.1,s)
	check(officer(layer,s).frame==1,"original second idle frame after half second")
	for i in range(5): layer.tick(.1,s)
	check(officer(layer,s).frame==0,"original two-frame loop")
	check(JSON.stringify(s)==before,"original sprite animation never writes story facts")
	s.native.settings.reduced_motion=true
	check(officer(layer,s).frame==0,"reduced motion fixes a readable original pose")
	s.native.mode="dark"
	check(not officer(layer,s).is_empty(),"source teacher stays visible in dark mode")
	s.native.selected_item="nylonCord"
	check(officer(layer,s).alpha==.3,"source unmatched held item dims the teacher")
	check(layer.owns_pick_target({"id":"qizhen_dock_safety_officer"},s) and layer._pick_ids(entry,[])==["qizhen_dock_safety_officer"],"visible sprite owns existing teacher interaction")
	check(layer.adjusted_collisions([],s).is_empty(),"restored visual introduces no invisible solid")
	s.qizhenLake.vehicle="kayak"
	check(officer(layer,s).is_empty(),"source teacher target hides after boarding")
	s.qizhenLake.vehicle="on_foot";s.qizhenLake.zone="channel"
	check(officer(layer,s).is_empty(),"teacher does not leak into another zone")
	var hud_state:Dictionary=s.duplicate(true)
	hud_state.native.mode="light";hud_state.native.selected_item="";hud_state.qizhenLake.zone="dock"
	var hud_before:String=JSON.stringify(hud_state)
	var world: Control=load("res://scripts/world.gd").new()
	world.scene_id="qizhen_lake";world.world_key="qizhen_lake:dock"
	world.targets=lake.targets("qizhen_lake",hud_state)
	var hud_board:Dictionary={}
	for candidate:Dictionary in world.targets:
		if candidate.id=="qizhen_dock_board":hud_board=candidate;break
	check(not hud_board.is_empty() and hud_board.get("hud_prompt","")=="从小码头上船","HUD fixture uses real light-mode dock target and source context")
	world.nearby=hud_board;world.player=world._target_point(hud_board)
	check(world._hud_line()=="空格 · 从小码头上船","desktop HUD uses contextual action")
	world.mobile_exploration=true
	check(world._mobile_confirmed_target().is_empty() and not world._hud_line().contains("从小码头上船"),"nearby mobile board has no automatic contextual plaque")
	simulate_confirmation_for_hud_unit(world,hud_board)
	check(world._hud_line()=="点按物品 · 从小码头上船","confirmed touch HUD uses same contextual action before label")
	var fallback:Dictionary={"id":"hud_label_fallback","position":[710,650],"radius":64,"label":"未改动目标"}
	world.targets=[fallback];world.nearby=fallback;world.player=world._target_point(fallback)
	check(world._mobile_confirmed_target().is_empty() and not world._hud_line().contains("未改动目标"),"changing to another nearby target does not transfer confirmation")
	simulate_confirmation_for_hud_unit(world,fallback)
	check(world._hud_line()=="点按物品 · 未改动目标","confirmed other targets retain label fallback")
	world.player+=Vector2(float(fallback.radius)+1,0)
	check(not world._hud_line().contains("未改动目标") and world.mobile_confirmed_target_id.is_empty() and world.mobile_confirmed_world_key.is_empty(),"leaving original interaction radius clears confirmed mobile plaque")
	world.player=world._target_point(fallback)
	check(not world._hud_line().contains("未改动目标"),"returning nearby does not automatically restore cleared plaque")
	world.mobile_exploration=false
	check(world._hud_line()=="空格 · 未改动目标","desktop label fallback remains available without mobile confirmation")
	check(JSON.stringify(hud_state)==hud_before,"HUD confirmation presentation fixture changes no game facts")
	world.free()
	print("LAKE_DOCK_HANDOFF: ",checks," checks; ",failures," failures")
	quit(1 if failures else 0)
