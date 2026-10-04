extends "res://tests/test_canteen_objective_journal.gd"
## Exact original menu objective/hints, actual Main Tasks and journal controls.
## Headless isolated fixtures/read-only earned snapshot; no manual campaign claim.
var source: Dictionary
var expected: Dictionary

func oracle_cases() -> void:
	for record: Dictionary in source.menuCases:
		var value:=earned.duplicate(true)
		for field in record.hunt:value.canteenHunt[field]=record.hunt[field]
		value.items.dailySpecialSparklingWater=record.items.dailySpecialSparklingWater
		value.native.mode=record.mode
		var before:=JSON.stringify(value)
		var goal: Dictionary=Goal.current(value)
		check(goal.id==record.id and goal.title==record.title,"menu/queue precedence matches executed original QuestModel")
		if record.id=="menu_order":
			expected=record
			check(goal.detail==record.detail,"both menu hints match original wording exactly")
			for answer in ["纸包鸡","纸包过","0755","取纸"]:
				check(not goal.title.contains(answer) and not goal.detail.contains(answer),"menu guidance does not disclose answer: "+answer)
		else:check(goal.id=="queue_shift","uncompleted queue cannot reveal the menu task early")
		check(JSON.stringify(value)==before,"menu projection preserves complete save")
	for phase in ["exit_blocking","chasing","theater_reached"]:
		var value:=earned.duplicate(true);value.canteenHunt.phase=phase
		check(Goal.current(value).is_empty(),"later branch remains excluded: "+phase)
	for later in ["theaterHunt","qizhenLake"]:
		var value:=earned.duplicate(true);value[later].active=true
		check(Goal.current(value).is_empty(),"later active chapter suppresses stale menu guidance")

func open_tasks(method: String) -> void:
	var button: Button=shell.world_tasks
	check(button.is_visible_in_tree() and not button.disabled,"existing Tasks entry is visible and enabled")
	if method=="keyboard":button.grab_focus();await press(KEY_SPACE)
	elif method=="touch":
		var point: Vector2=button.get_global_rect().get_center();touch(point,true);touch(point,false);await frames()
	else:await click(button)

func journal_round_trip(method: String) -> void:
	var before:=JSON.stringify(state.d)
	var player: Vector2=shell.world.player
	var count:=actions.size()
	await open_tasks(method)
	check(is_instance_valid(shell.modal) and node("NativeJournal")!=null,"existing "+method+" Tasks opens Main journal")
	if not is_instance_valid(shell.modal):return
	check_layout()
	check(state.objective()==expected.title and node("JournalObjective").text==expected.title,"actual Main displays the source objective")
	check(node("JournalNextStep").text==expected.detail,"actual Main displays both source hints")
	check(node("JournalObservationCompare")==null,"menu guidance adds no comparison UI")
	check(root.gui_get_focus_owner()==node("JournalResume"),"journal focuses existing return button")
	await press(KEY_TAB);check(shell.modal.is_ancestor_of(root.gui_get_focus_owner()),"Tab stays within journal")
	shell.world._notification(Node.NOTIFICATION_WM_WINDOW_FOCUS_OUT);shell.c3_scene_host.tick(100,false);shell.c3_narrative_host.tick(100,false)
	check(state.d.canteenHunt.phase==expected.hunt.phase and shell.world.player==player,"journal/focus loss does not order or move the player")
	if method=="keyboard":await click(node("JournalResume"))
	else:await press(KEY_ESCAPE)
	check(not is_instance_valid(shell.modal) and shell.world.has_focus(),"existing dismissal returns world focus")
	check(JSON.stringify(state.d)==before and actions.size()==count,"Tasks/read/return submits no story action and changes no save field")

func run() -> void:
	check(ProjectSettings.globalize_path("user://").begins_with("/tmp/"),"test profile is isolated")
	if failures:quit(1);return
	state=root.get_node("State");state.developer_mode=true;state.d=state.initial()
	var path:=OS.get_environment("CANTEEN_EARNED_SAVE")
	if path.is_empty():
		check(state.begin_checkpoint("c3-canteen-entry"),"default fixture starts from original source checkpoint")
		earned=state.d.duplicate(true)
		earned.canteenHunt.entryPaperEscaped=true;earned.canteenHunt.trayTaskStarted=true
		earned.canteenHunt.returnedTrayIds=["tray_blue_01","tray_blue_02","tray_blue_03"]
		earned.canteenHunt.queueChallengeSeen=true;earned.canteenHunt.drinkShelfRead=true
		earned.canteenHunt.promoDrinkPlaced=true;earned.canteenHunt.queueGapOpened=true;earned.canteenHunt.phase="menu_order"
	else:earned=JSON.parse_string(FileAccess.get_file_as_string(path)).state
	check(earned.canteenHunt.phase=="menu_order" and earned.canteenHunt.queueGapOpened,"input is the actual post-promotion menu state")
	source=JSON.parse_string(FileAccess.get_file_as_string("res://tests/fixtures/canteen_handoff_source.json"));oracle_cases()
	shell=load("res://scenes/main.tscn").instantiate();root.add_child(shell);await frames();shell.set_process(false)
	state.action_completed.connect(func(id,_a,_b,_result):actions.append(id))
	for dimensions in [Vector2i(390,844),Vector2i(430,860),Vector2i(1440,900)]:
		for mode in ["light","dark"]:
			for clue_read in [false,true]:
				var value:=earned.duplicate(true);value.native.mode=mode;value.canteenHunt.mode=mode
				value.canteenHunt.menuDarkClueRead=clue_read
				await restore(value,dimensions)
				for method in ["pointer","touch","keyboard"]:await journal_round_trip(method)
	await shell.shutdown();shell.queue_free();await frames()
	var report:=OS.get_environment("UI_QA_REPORT")
	if not report.is_empty():
		var file:=FileAccess.open(report,FileAccess.WRITE)
		file.store_string(JSON.stringify({"checks":checks,"failures":failures,"sourceCases":source.menuCases.size(),"gui_used":false,"manual_campaign":false,"earned_snapshot":not path.is_empty(),"measurements":observations},"\t"));file.close()
	print("CANTEEN MENU OBJECTIVE: %d checks; %d failures; %d source cases"%[checks,failures,source.menuCases.size()]);quit(1 if failures else 0)
