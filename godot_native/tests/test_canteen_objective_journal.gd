extends "res://tests/test_portrait_exploration.gd"
## Actual Main input and controller-owned dialogue; explicitly isolated fixtures.
## An earned-save snapshot is read only. This is not a full manual campaign pass.
const Goal=preload("res://scripts/presentation/canteen_objective.gd")
var earned: Dictionary
var observations: Array=[]
func node(id: String) -> Control: return shell.find_child(id,true,false)
func key(code: int,down: bool,shift:=false) -> void:
	var e:=InputEventKey.new();e.keycode=code;e.physical_keycode=code;e.pressed=down;e.shift_pressed=shift;event(e);await process_frame
func press(code: int,shift:=false) -> void:
	await key(code,true,shift);await key(code,false,shift);await frames()
func restore(value: Dictionary, dimensions: Vector2i) -> void:
	shell._close_modal();state.story_reset.emit();state.d=value.duplicate(true)
	root.size=dimensions;shell.size=Vector2(dimensions);shell.mobile_world=true;shell._refresh();await frames(6)
	shell.world.set_process(false);shell.c3_scene_host.set_process(false);shell.c3_narrative_host.set_process(false);shell.world.grab_focus()
func check_layout() -> void:
	check(Rect2(Vector2.ZERO,Vector2(root.size)).encloses(shell.modal_panel.get_global_rect()),"journal panel fits physical viewport")
	for id in ["JournalObjective","JournalNextStep","JournalResume","JournalHistoryToggle"]:
		var item:=node(id)
		if item==null:continue
		check(Rect2(Vector2.ZERO,Vector2(root.size)).encloses(item.get_global_rect()),"default journal content stays onscreen: "+id)
		if item is Label: check(item.get_line_count()==item.get_visible_line_count(),"journal text wraps without clipping: "+id)
		if item is Button:check(item.get_global_rect().size.y>=44,"journal button keeps44px target: "+id)
	observations.append({"viewport":str(root.size),"panel":str(shell.modal_panel.get_global_rect()),"goal":state.objective(),"nextStep":node("JournalNextStep").text if node("JournalNextStep") else ""})
func journal_cases(dimensions: Vector2i) -> void:
	await restore(earned,dimensions)
	var before:=JSON.stringify(state.d)
	shell._show_journal();await frames()
	check(node("JournalObjective").text=="与收餐口阿姨交谈","earned snapshot names reachable staff step")
	check(node("JournalNextStep").text=="到右侧收餐口，与阿姨交谈。","earned shelf does not replace auntie step")
	check(not node("JournalHistory").visible and node("JournalHistory").get_child_count()==0,"history begins collapsed and unbuilt")
	check(node("JournalObservationCompare")==null,"chapter3 respects existing comparison eligibility")
	check(root.gui_get_focus_owner()==node("JournalResume"),"journal focuses return control")
	check_layout()
	await click(node("JournalHistoryToggle"))
	check(node("JournalHistory").visible and node("JournalHistory").get_child_count()==earned.native.log.size(),"pointer expands every retained log row")
	check(node("JournalHistoryRow0").text==earned.native.log[0].text,"oldest retained row remains readable")
	check(node("JournalHistoryRow"+str(earned.native.log.size()-1)).text==earned.native.log[-1].text,"newest retained row remains readable")
	await press(KEY_SPACE)
	check(not node("JournalHistory").visible and root.gui_get_focus_owner()==node("JournalHistoryToggle"),"Space folds history and preserves toggle focus")
	await press(KEY_TAB)
	check(shell.modal.is_ancestor_of(root.gui_get_focus_owner()),"Tab remains within actual modal")
	var rotated:=Vector2i(1440,900) if dimensions.x<1100 else Vector2i(390,844)
	root.size=rotated;shell.size=Vector2(rotated);shell._layout();await frames()
	check_layout()
	shell.world._notification(Node.NOTIFICATION_WM_WINDOW_FOCUS_OUT);shell.c3_scene_host.tick(100,false)
	check(JSON.stringify(state.d)==before,"journal pointer, keyboard, resize and focus loss preserve complete save")
	await click(node("JournalResume"))
	check(not is_instance_valid(shell.modal) and shell.world.has_focus() and root.gui_get_focus_owner()==null,"return control restores actual world keyboard focus")
	shell._show_journal();await frames();await press(KEY_ESCAPE)
	check(not is_instance_valid(shell.modal) and shell.world.has_focus(),"Escape also returns to world without reopening journal")
	check(JSON.stringify(state.d)==before,"repeated journal returns never progress story")
func early_main_cases(dimensions: Vector2i) -> void:
	var fixture:=earned.duplicate(true)
	fixture.canteenHunt.phase="tracking";fixture.canteenHunt.entryPaperEscaped=false
	fixture.native.scene="campus_bootstrap";fixture.rpgScene="campus_bootstrap"
	await restore(fixture,dimensions)
	var before:=JSON.stringify(state.d)
	shell._show_journal();await frames();check_layout()
	check(node("JournalObjective").text=="追上逃跑的记录纸条" and not node("JournalNextStep").text.contains("餐盘"),"actual tracking Main preserves paper objective without future task")
	await click(node("JournalResume"));check(JSON.stringify(state.d)==before,"tracking journal preserves exact fixture")
	check(state.begin_checkpoint("c3-canteen-entry"),"original entry checkpoint loads")
	shell.mobile_world=true;shell._refresh();await frames();shell.world.set_process(false);shell.c3_scene_host.set_process(false)
	shell.c3_scene_host.tick(0,true);await frames()
	var session:RefCounted=shell.c3_scene_host.current
	check(session!=null and session.status=="waiting","actual waiting Main retains source paper session")
	before=JSON.stringify(state.d)
	shell._show_journal();await frames();check_layout()
	check(node("JournalObjective").text=="靠近食堂里的异常纸条","actual waiting Main directs approach, not interception")
	shell.c3_scene_host.tick(100,true)
	check(session.status=="waiting" and JSON.stringify(state.d)==before,"journal leaves entry receipt unearned")
	await press(KEY_ESCAPE)
	check(shell.c3_scene_host.current==session and session.status=="waiting","journal return retains exact waiting session")

func goal_cases() -> void:
	var fixture:=earned.duplicate(true)
	fixture.canteenHunt.phase="tracking";fixture.canteenHunt.entryPaperEscaped=false
	check(Goal.current(fixture).id=="tracking","tracking points to canteen without tray spoilers")
	fixture.canteenHunt.phase="tray_search"
	check(Goal.current(fixture).id=="paper_entry" and not Goal.current(fixture).detail.contains("阿姨"),"waiting keeps paper approach before escape")
	fixture.canteenHunt.entryPaperEscaped=true;fixture.native.mode="dark"
	check(Goal.current(fixture).detail.begins_with("切回浅色操作"),"unstarted task in dark directs reachable light-mode auntie")
	fixture.canteenHunt.trayTaskStarted=true
	for count in range(4):
		fixture.canteenHunt.returnedTrayIds=["tray_blue_01","tray_blue_02","tray_blue_03"].slice(0,count)
		fixture.canteenHunt.returnedTrayIds.append("tray_clean_01")
		var goal:Dictionary=Goal.current(fixture)
		check(goal.id=="queue" if count==3 else goal.title.ends_with("（%d/3）"%count),"only original target IDs count; third return hands off to source queue goal")
	fixture.canteenHunt.returnedTrayIds=[];fixture.canteenHunt.carriedTrayIds=["tray_clean_01"]
	check(Goal.current(fixture).id=="tray_carry" and not Goal.current(fixture).title.contains("干净"),"carrying any tray directs return without revealing its validity")
	for phase in ["exit_blocking","chase_ready","chasing","theater_reached"]:
		fixture.canteenHunt.phase=phase;check(Goal.current(fixture).is_empty(),"later phase retains original objective: "+phase)
	fixture.canteenHunt.phase="tray_search";fixture.theaterHunt.active=true
	check(Goal.current(fixture).is_empty(),"later chapter suppresses stale canteen journal hints")
func controller_case(dimensions: Vector2i) -> void:
	await restore(earned,dimensions)
	# Unit fixture stands at the authored auntie interaction point. Movement to
	# that point is outside this bounded automated test and remains manual QA.
	shell.world.player=Vector2(1466,608);shell.world._sync_player();shell.world._process(0)
	check(shell.world.nearby.get("id","")=="auntie","source position resolves actual nearby auntie")
	await press(KEY_SPACE)
	var story:RefCounted=state.get_c3_narrative_session()
	check(story!=null and story.sequence_id=="canteen_tray_intro","actual world Space requests source auntie dialogue")
	if story==null:return
	check(not state.d.canteenHunt.trayTaskStarted and state.objective()=="与收餐口阿姨交谈","objective remains before dialogue completion")
	shell.c3_narrative_host.tick(0,true)
	var elapsed:float=story.elapsed_ms;shell.c3_narrative_host.tick(100,false)
	check(story.elapsed_ms==elapsed and not state.d.canteenHunt.trayTaskStarted,"blur cannot complete dialogue or update goal")
	while shell.c3_narrative_host.current!=null: shell.c3_narrative_host.tick(100,true)
	await frames()
	check(state.d.canteenHunt.trayTaskStarted and state.objective()=="找出并交回带污渍的餐盘（0/3）","original terminal acknowledgement updates goal")
	shell._show_journal();await frames();check_layout()
	check(node("JournalNextStep").text.contains("阿姨托你送回三只脏盘"),"only earned dialogue surfaces tray assignment")
	await click(node("JournalResume"))
	# Repeated inspect/collect/return uses controller at source tray stands.
	for id in ["tray_blue_01","tray_blue_02"]:
		var target:Dictionary={}
		for entry:Dictionary in state.get_targets("canteen_interior"):
			if entry.id==id:target=entry
		check(not target.is_empty(),"active task exposes original tray target")
		if target.is_empty():return
		shell.world.player=Vector2(target.stand.x,target.stand.y);shell.world._sync_player()
		state.toggle_mode();state.act("c3_target:"+id);state.toggle_mode();state.act("c3_target:"+id);await frames()
		check(state.objective().begins_with("交回手中的餐盘"),"validated pickup replaces search with return step")
		shell._show_journal();await frames();check_layout();await click(node("JournalResume"))
		shell.world.player=Vector2(1466,608);shell.world._sync_player();state.act("c3_target:auntie")
		shell.c3_narrative_host.tick(0,true)
		while shell.c3_narrative_host.current!=null:shell.c3_narrative_host.tick(100,true)
		await frames()
	check(state.objective()=="找出并交回带污渍的餐盘（2/3）","accepted returns update n/3 without awarding early reward")
	check(not state.d.items.cafeteriaWages and state.d.wallet.cashCents==earned.wallet.cashCents,"two trays do not alter source reward gate")
func comparison_case(dimensions: Vector2i) -> void:
	var fixture:=earned.duplicate(true);fixture.native.chapter=2;fixture.canteenHunt.active=false
	await restore(fixture,dimensions)
	var before:=JSON.stringify(state.d)
	shell._show_journal();await frames()
	check(node("JournalObservationCompare")!=null,"existing earned chapter2 comparison is discoverable")
	await click(node("JournalObservationCompare"))
	check(node("ObservationJournalReturn")!=null,"comparison exposes explicit journal return")
	await click(node("ObservationJournalReturn"))
	check(node("JournalResume")!=null and not node("JournalHistory").visible,"comparison returns to current task hierarchy")
	check(JSON.stringify(state.d)==before,"comparison round-trip preserves complete save")
	await press(KEY_ESCAPE)
func run() -> void:
	check(ProjectSettings.globalize_path("user://").begins_with("/tmp/"),"isolated test profile")
	if failures:quit(1);return
	state=root.get_node("State");state.developer_mode=true;state.d=state.initial()
	var path:=OS.get_environment("CANTEEN_EARNED_SAVE")
	if path.is_empty():
		# Reproducible source-phase fixture for the aggregate suite. The optional
		# external snapshot path exercises the actual manually earned save.
		check(state.begin_checkpoint("c3-canteen-entry"),"default fixture uses original source checkpoint")
		earned=state.d.duplicate(true);earned.canteenHunt.entryPaperEscaped=true;earned.canteenHunt.drinkShelfRead=true
		earned.native.log=[]
		for i in range(129):earned.native.log.append({"text":"历史记录 %d"%i,"time":"fixture"})
	else:earned=JSON.parse_string(FileAccess.get_file_as_string(path)).state
	shell=load("res://scenes/main.tscn").instantiate();root.add_child(shell);await frames();shell.set_process(false)
	goal_cases()
	for dimensions in [Vector2i(390,844),Vector2i(430,860),Vector2i(1440,900)]:
		await early_main_cases(dimensions)
		await journal_cases(dimensions)
		await controller_case(dimensions)
		await comparison_case(dimensions)
	await shell.shutdown();shell.queue_free();await frames()
	var report:=OS.get_environment("UI_QA_REPORT")
	if not report.is_empty():
		var file:=FileAccess.open(report,FileAccess.WRITE);file.store_string(JSON.stringify({"checks":checks,"failures":failures,"gui_used":false,"manual_campaign":false,"measurements":observations},"\t"));file.close()
	print("CANTEEN_OBJECTIVE_JOURNAL: %d checks; %d failures"%[checks,failures]);quit(1 if failures else 0)
