extends "res://tests/test_canteen_menu_objective.gd"
## Executed source task plus actual Main journal input/layout, with read-only
## snapshots and isolated fixtures. This does not prove blind route discovery.
func oracle_cases() -> void:
	for record: Dictionary in source.pickupCases:
		var value:=earned.duplicate(true)
		for field in record.hunt:value.canteenHunt[field]=record.hunt[field]
		for item in record.items:value.items[item]=record.items[item]
		value.native.mode=record.mode
		var before:=JSON.stringify(value)
		var goal: Dictionary=Goal.current(value)
		check(goal.id==record.id and goal.title==record.title,"pickup and earlier facts follow executed original QuestModel precedence")
		if record.id=="pickup":
			expected=record
			check(goal.detail==record.detail,"both pickup hints match original wording exactly")
			for answer in ["纸包鸡","纸包过","0755","取纸","3号","第三","黑咖啡","蓝色","白色"]:
				check(not goal.title.contains(answer) and not goal.detail.contains(answer),"pickup guidance never reveals answer or recipe: "+answer)
		check(JSON.stringify(value)==before,"pickup guidance preserves the complete save")
	for phase in ["exit_blocking","chase_ready","chasing","theater_reached"]:
		var value:=earned.duplicate(true);value.canteenHunt.phase=phase
		check(Goal.current(value).is_empty(),"completed pickup suppresses old guidance: "+phase)
	for later in ["theaterHunt","qizhenLake"]:
		var value:=earned.duplicate(true);value[later].active=true
		check(Goal.current(value).is_empty(),"later active chapter suppresses stale pickup guidance")
	var value:=earned.duplicate(true);value.canteenHunt.active=false
	check(Goal.current(value).is_empty(),"inactive canteen suppresses pickup guidance")
	# A wrong-window refusal leaves this objective active; actual non-paper
	# collection returns to the existing menu task. These are controller calls
	# at explicit fixture targets, not a manual navigation claim.
	var chapter: RefCounted=load("res://scripts/chapters/chapter3.gd").new()
	value=earned.duplicate(true);value.native.mode="light";value.canteenHunt.mode="light"
	value.canteenHunt.orderedMenuOption="A";value.items.pickupTicket0755=true
	var wrong: Dictionary=chapter.get_definition("canteen_interior","pickup_window_3",value)
	var correct: Dictionary=chapter.get_definition("canteen_interior","pickup_window_1",value)
	var before:=JSON.stringify(value)
	chapter.canteen_target(value,wrong)
	check(JSON.stringify(value)==before and Goal.current(value).id=="pickup","source refusal preserves ticket and pickup task")
	chapter.canteen_target(value,correct)
	check(value.canteenHunt.phase=="menu_order" and not value.items.pickupTicket0755 and value.items.canteenRealBun,"source accepted food collection retains original transaction")
	check(Goal.current(value).id=="menu_order","food collection returns to existing menu guidance")

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
		earned.canteenHunt.promoDrinkPlaced=true;earned.canteenHunt.queueGapOpened=true
		earned.canteenHunt.phase="pickup_search";earned.canteenHunt.orderedMenuOption="D"
		earned.items.pickupTicket0755=true
	else:earned=JSON.parse_string(FileAccess.get_file_as_string(path)).state
	check(earned.canteenHunt.phase=="pickup_search" and earned.canteenHunt.queueGapOpened and earned.items.pickupTicket0755,"input has earned pending ticket and open queue")
	source=JSON.parse_string(FileAccess.get_file_as_string("res://tests/fixtures/canteen_handoff_source.json"));oracle_cases()
	shell=load("res://scenes/main.tscn").instantiate();root.add_child(shell);await frames();shell.set_process(false)
	state.action_completed.connect(func(id,_a,_b,_result):actions.append(id))
	for dimensions in [Vector2i(390,844),Vector2i(430,860),Vector2i(1440,900)]:
		for mode in ["light","dark"]:
			for clue_read in [false,true]:
				var value:=earned.duplicate(true);value.native.mode=mode;value.canteenHunt.mode=mode
				value.canteenHunt.pickupDarkClueRead=clue_read
				await restore(value,dimensions)
				for method in ["pointer","touch","keyboard"]:await journal_round_trip(method)
	await shell.shutdown();shell.queue_free();await frames()
	var report:=OS.get_environment("UI_QA_REPORT")
	if not report.is_empty():
		var file:=FileAccess.open(report,FileAccess.WRITE)
		file.store_string(JSON.stringify({"checks":checks,"failures":failures,"sourceCases":source.pickupCases.size(),"gui_used":false,"manual_campaign":false,"earned_snapshot":not path.is_empty(),"measurements":observations},"\t"));file.close()
	print("CANTEEN PICKUP OBJECTIVE: %d checks; %d failures; %d source cases"%[checks,failures,source.pickupCases.size()]);quit(1 if failures else 0)
