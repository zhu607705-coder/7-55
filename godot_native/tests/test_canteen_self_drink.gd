extends "res://tests/test_portrait_exploration.gd"
## Main/root-viewport integration. Fixtures are labelled; EARNED_SELF_DRINK=1
## loads a byte-identical ordinary pre-mix save through State's normal loader.
const Chapter=preload("res://scripts/chapters/chapter3.gd")
var oracle: Dictionary
var baseline: Dictionary
var mixed: Dictionary
var ordinary_save:=false
var already_mixed:=false
var routed: Array=[]
func source_screen(point: Vector2) -> Vector2:
	return world_screen((point-shell.world.camera)*shell.world.zoom+shell.world.size/2)
func assert_unchanged(before: Dictionary,label: String) -> void:
	check(state.d.items==before.items and state.d.canteenHunt==before.canteenHunt and state.d.wallet==before.wallet,label+" preserves items, canteen facts and wallet")
func reset_case(dimensions: Vector2i,mode: String="light",source_state: Dictionary={}) -> void:
	shell._close_modal();state.story_reset.emit()
	state.d=(mixed if source_state.is_empty() else source_state).duplicate(true)
	state.d.native.mode=mode;state.d.canteenHunt.mode=mode
	root.size=dimensions;shell.size=Vector2(dimensions);shell.mobile_world=false;shell.compact_inventory_open=false
	shell.world.world_key="";shell.world.scene_id="";shell._refresh();shell._show_world_mobile();await frames(8)
	shell.world.set_process(false)
	if dimensions.x<1100 and not shell.inventory_dock.visible: await click(shell.inventory_handle)
	await frames(4)
	check(shell.world_frame.visible and shell.inventory_dock.visible,"real Main presents world and inventory")
func mix_in_main() -> void:
	var before: int=int(state.d.canteenHunt.drinkMixAttemptCount)
	state.act("c3_target:canteen-mixer");await frames()
	check(is_instance_valid(shell.c3_device_panel),"physical mixer controller opens Main's native panel")
	if not is_instance_valid(shell.c3_device_panel):return
	for id: String in ["sparklingWater","blackCoffee","lemonTea"]:
		var panel: Control=shell.c3_device_panel
		var index:int=panel.session.button_order.find(id)
		check(index>=0,"actual visible mixer slot exists: "+id)
		await click(panel.slots[index])
	check(state.d.items.badDrink and not state.d.items.dailySpecialSparklingWater,"actual wrong-order pours create badDrink only")
	check(state.d.canteenHunt.drinkMixAttemptCount==before+1 and state.d.canteenHunt.drinkMixSequence.is_empty(),"one completed failed mixture resets only its sequence")
	check(not is_instance_valid(shell.modal),"completed wrong mixture closes native mixer")
	mixed=state.d.duplicate(true)
func check_dialogue() -> void:
	var story=state.get_c3_narrative_session()
	check(story!=null and story.sequence_id=="canteen_bad_drink","existing controller issues authored bad-drink story")
	if story==null:return
	check(story.lines.size()==oracle.dialogue.lines.size() and story.duration_ms==oracle.dialogue.completeAtMs,"source dialogue count and total timing retained")
	for i in story.lines.size():
		check(story.lines[i].text==oracle.dialogue.lines[i] and story.lines[i].atMs==oracle.dialogue.atMs[i] and story.lines[i].durationMs==oracle.dialogue.durationMs[i],"exact source text, start and display time retained")
func test_controller_oracle() -> void:
	for row: Dictionary in oracle.eligibility:
		var c=Chapter.new();var s:Dictionary=baseline.duplicate(true)
		s.canteenHunt.phase=row.phase;s.canteenHunt.active=row.active;s.canteenHunt.mode=row.mode;s.native.mode=row.mode;s.items.badDrink=row.owned
		var before: Dictionary=s.duplicate(true)
		c.dispatch(s,"c3_bad_drink")
		check(s.items.badDrink==row.remaining and (c.story!=null)==row.accepted,"source eligibility: "+str([row.phase,row.active,row.mode,row.owned]))
		check(s.canteenHunt==before.canteenHunt and s.wallet==before.wallet,"self-use grants no progression or payment")
		var once: Dictionary=s.duplicate(true);c.dispatch(s,"c3_bad_drink")
		check(s==once,"repeated controller request has no second effect")
func run() -> void:
	state=root.get_node("State");state.developer_mode=true
	already_mixed=OS.get_environment("EARNED_SELF_DRINK_MIXED")=="1"
	ordinary_save=already_mixed or OS.get_environment("EARNED_SELF_DRINK")=="1"
	oracle=JSON.parse_string(FileAccess.get_file_as_string("res://tests/fixtures/canteen_self_drink_source.json"))
	if not ordinary_save:
		state.d=state.initial();state.d.native.chapter=3;state.d.native.page="phone_home";state.d.native.scene="canteen_interior"
		state.d.runtimeMode="rpg";state.d.rpgScene="canteen_interior"
		state.d.actOne.phase="complete";state.d.actOne.inventoryRecovered=true;state.d.actOne.controlsInstalled=true
		state.d.canteenHunt.active=true;state.d.canteenHunt.phase="tray_search";state.d.canteenHunt.entryPaperEscaped=true
		state.d.canteenHunt.queueChallengeSeen=true;state.d.canteenHunt.drinkShelfRead=true
		for id in ["sparklingWater","blackCoffee","lemonTea","campusCard"]:state.d.items[id]=true
		var def: Dictionary=Chapter.new().get_definition("canteen_interior","canteen-mixer",state.d)
		var stand: Dictionary=def.get("stand",{"x":def.x,"y":def.y})
		state.d.native.positions={"canteen_interior:":stand}
	baseline=state.d.duplicate(true)
	if already_mixed:
		check(baseline.items.badDrink and not baseline.items.sparklingWater and not baseline.items.blackCoffee and not baseline.items.lemonTea and baseline.canteenHunt.drinkMixAttemptCount>=1,"unchanged normal-load failed-mixture save owns exactly its earned badDrink")
	else:
		check(not baseline.items.badDrink and baseline.items.sparklingWater and baseline.items.blackCoffee and baseline.items.lemonTea,"unmodified pre-mix input has three real ingredients")
	root.size=Vector2i(430,860);shell=load("res://scenes/main.tscn").instantiate();root.add_child(shell);await frames(8)
	state.action_completed.connect(func(id,_a,_b,_c):actions.append(id))
	state.feedback.connect(func(line):feedback.append(line))
	await reset_case(Vector2i(430,860),"light",baseline)
	if already_mixed: mixed=state.d.duplicate(true)
	else: await mix_in_main()
	if mixed.is_empty():await shell.shutdown();quit(1);return
	test_controller_oracle()
	# Exact source geometry is exercised through the live world adapter. No
	# picker tolerance, sprite-alpha requirement, expanded radius or teleport.
	for row:Dictionary in oracle.geometry:
		await reset_case(Vector2i(1440,900))
		var before:Dictionary=state.d.duplicate(true)
		var source:Vector2=shell.world.player+Vector2(row.offset[0],row.offset[1])
		var local:Vector2=(source-shell.world.camera)*shell.world.zoom+shell.world.size/2
		shell.world._drop_data(local,{"kind":"inventory_item","item":"badDrink"})
		check(state.d.items.badDrink!=row.accepted,"exact original source circle: "+str(row.offset))
		if not row.accepted:assert_unchanged(before,"source-circle miss")
	# Real root drag dispatch crosses the actual inventory/Main/SubViewport
	# transforms at desktop, portrait and landscape sizes in both source modes.
	for dims:Vector2i in [Vector2i(1440,900),Vector2i(430,860),Vector2i(390,844),Vector2i(844,390),Vector2i(960,540)]:
		for mode:String in ["light","dark"]:
			await reset_case(dims,mode)
			var before:Dictionary=state.d.duplicate(true);var count:int=actions.count("c3_bad_drink")
			var point:Vector2=source_screen(shell.world.player-Vector2(0,24))
			await drag_item("badDrink",point,dims.x<1100)
			check(not state.d.items.badDrink and actions.count("c3_bad_drink")==count+1,"Main root drag consumes exactly once: "+str(dims)+" "+mode)
			check(state.d.canteenHunt==before.canteenHunt and state.d.wallet==before.wallet,"root self-use leaves recipe/promo/queue/phase/wallet untouched")
			check(slot("badDrink")==null,"consumed drink disappears from actual inventory")
			check_dialogue()
			routed.append({"size":str(dims),"mode":mode,"touch":dims.x<1100,"rootDrop":str(point)})
	await reset_case(Vector2i(430,860))
	var center:Vector2=source_screen(shell.world.player-Vector2(0,24))
	var before:Dictionary=state.d.duplicate(true);var count:int=actions.count("c3_bad_drink")
	await drag_item("campusCard",center,true)
	assert_unchanged(before,"wrong item at actor");check(actions.count("c3_bad_drink")==count,"wrong item cannot dispatch self-drink")
	await drag_item("badDrink",source_screen(shell.world.player+Vector2(90,-24)),true)
	assert_unchanged(before,"root miss");check(feedback.has("把难喝饮料拖到人物自己身上才能喝掉。"),"miss preserves original source instruction")
	await drag_item("badDrink",center,true,true);assert_unchanged(before,"cancelled touch")
	await reset_case(Vector2i(1440,900));before=state.d.duplicate(true)
	await drag_item("badDrink",source_screen(shell.world.player-Vector2(0,24)),false,true);assert_unchanged(before,"Escape-cancelled mouse")
	# A modal opened mid-drag cancels the actual gesture and blocks the adapter.
	await reset_case(Vector2i(430,860));before=state.d.duplicate(true)
	var item:Control=await reveal("badDrink");await begin_drag(item,true)
	shell._modal_base("回归测试");await frames()
	check(not root.gui_is_dragging() and slot("badDrink").disabled,"modal cancels in-flight drag and disables its source")
	var local:Vector2=(shell.world.player-Vector2(0,24)-shell.world.camera)*shell.world.zoom+shell.world.size/2
	shell.world._drop_data(local,{"kind":"inventory_item","item":"badDrink"});assert_unchanged(before,"modal-blocked drop")
	shell._close_modal();await frames()
	check(not slot("badDrink").disabled,"closing modal restores inventory input")
	# Reserved mobile HUD remains non-world input, even inside source circle.
	var original_player:Vector2=shell.world.player
	var control:Vector2=shell.world.mobile_control_metrics().interact.get_center()
	shell.world.player=(control-shell.world.size/2)/shell.world.zoom+shell.world.camera+Vector2(0,24)
	shell.world._drop_data(control,{"kind":"inventory_item","item":"badDrink"});assert_unchanged(before,"mobile control ownership")
	shell.world.player=original_player
	# Other scenes cannot route the canteen-specific adapter.
	var original_scene:String=shell.world.scene_id;shell.world.scene_id="library_interior"
	shell.world._drop_data(local,{"kind":"inventory_item","item":"badDrink"});assert_unchanged(before,"outside canteen")
	shell.world.scene_id=original_scene
	# Finish one real five-second narrative and prove stale/repeated drops
	# cannot recreate it. Timing runs through the live Main presentation host.
	await reset_case(Vector2i(430,860));before=state.d.duplicate(true)
	await drag_item("badDrink",source_screen(shell.world.player-Vector2(0,24)),true);check_dialogue()
	var story=state.get_c3_narrative_session();var started:=Time.get_ticks_msec()
	check(shell.c3_narrative_host.blocks_input(),"authored trial-drink dialogue holds its ordinary input lock")
	while state.get_c3_narrative_session()!=null and Time.get_ticks_msec()-started<7000:await process_frame
	check(state.get_c3_narrative_session()==null and Time.get_ticks_msec()-started>=4700,"live Main completes original five-second dialogue naturally")
	var remaining:Dictionary=state.d.duplicate(true)
	local=(shell.world.player-Vector2(0,24)-shell.world.camera)*shell.world.zoom+shell.world.size/2
	shell.world._drop_data(local,{"kind":"inventory_item","item":"badDrink"});await frames()
	assert_unchanged(remaining,"repeated stale drop after completion")
	check(state.get_c3_narrative_session()==null,"repeated stale drop creates no new dialogue")
	var report:=OS.get_environment("SELF_DRINK_REPORT")
	if not report.is_empty():
		var f:=FileAccess.open(report,FileAccess.WRITE);f.store_string(JSON.stringify({"checks":checks,"failures":failures,"ordinarySave":ordinary_save,"alreadyMixedSave":already_mixed,"graphicalAcceptance":false,"routes":routed},"\t"));f.close()
	await shell.shutdown();shell.queue_free();await frames()
	print("CANTEEN_SELF_DRINK: ",checks," checks; ",failures," failures; ordinarySave=",ordinary_save);quit(1 if failures else 0)
