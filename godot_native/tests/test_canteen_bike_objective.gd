extends "res://tests/test_canteen_menu_objective.gd"
## Read-only guidance and actual Main Tasks/device transitions in isolated
## source-phase fixtures. Does not claim earned traversal or visual GUI QA.
var chapter: RefCounted=load("res://scripts/chapters/chapter3.gd").new()

func select_expected() -> void:
	expected=Goal.current(state.d).duplicate(true)
	expected.hunt=state.d.canteenHunt.duplicate(true)

func projection_cases() -> void:
	var content: Dictionary=chapter.content("chapter3-canteen.content")
	for mode in ["light","dark"]:
		for cleaned in [false,true]:
			for paid in [false,true]:
				for code_read in [false,true]:
					var value:=earned.duplicate(true)
					value.native.mode=mode;value.canteenHunt.mode=mode
					value.canteenHunt.bikeLockCleaned=cleaned;value.canteenHunt.bikePaid=paid;value.canteenHunt.bikeCodeRead=code_read
					var before:=JSON.stringify(value)
					var goal: Dictionary=Goal.current(value)
					check(goal.id==("bike_ride" if paid else "bike_pay" if cleaned else "bike_clean"),"existing cleaned/paid facts choose next action; optional observation never gates it")
					check(goal.title==chapter.objective(value),"chapter objective uses same read-only projection as journal")
					if paid:
						check(goal.title==str(content.bike.task).trim_prefix("任务："),"paid title retains exact original source task")
						check(goal.detail.contains("开始骑行") and not goal.detail.contains("付款") and not goal.detail.contains("浅色"),"paid guidance names Ride without a new mode or payment gate")
					elif cleaned:check(goal.detail.ends_with(content.bike.unlock) and not goal.title.contains("清洁"),"cleaned guidance uses source payment copy without repeating cleaning")
					else:check(goal.detail.ends_with(content.bike.hints[0]),"unclean guidance preserves source cleaning/payment hint")
					check(goal.detail.begins_with("切回浅色操作。")==(mode=="dark" and not paid),"mode hint only covers existing light cleaning/payment operations")
					for answer in ["纸包鸡","0755","剧院","755 米"]:
						check(not goal.detail.contains(answer),"guidance reveals no later answer or destination: "+answer)
					check(JSON.stringify(value)==before,"projection preserves every save field")
	for phase in ["exit_blocking","chasing","theater_reached"]:
		var value:=earned.duplicate(true);value.canteenHunt.phase=phase
		check(Goal.current(value).is_empty(),"bike guidance excluded from other phases: "+phase)
	for later in ["theaterHunt","qizhenLake"]:
		var value:=earned.duplicate(true);value[later].active=true
		check(Goal.current(value).is_empty(),"later active route suppresses stale bike guidance")
	var value:=earned.duplicate(true);value.canteenHunt.active=false
	check(Goal.current(value).is_empty(),"inactive canteen has no bike instruction")

func open_bike() -> bool:
	var point: Dictionary=chapter.get_definition("campus_bootstrap","bike",state.d)
	shell.world.player=Vector2(point.x-70,point.y+60)
	shell.world._sync_player();shell.world._update_camera();shell.world._process(0);shell.world.grab_focus();await frames()
	shell.world._process(0)
	check(shell.world.nearby.get("id","")=="bike","fixture stand resolves visible source bike")
	await press(KEY_SPACE)
	check(is_instance_valid(shell.c3_device_panel),"world Space opens existing bike device")
	return is_instance_valid(shell.c3_device_panel)

func device_flow(dimensions: Vector2i) -> void:
	await restore(earned,dimensions)
	select_expected();await journal_round_trip("pointer")
	if not await open_bike():return
	await click(shell.c3_device_panel.controls.clean)
	check(state.d.canteenHunt.bikeLockCleaned and state.d.items.greaseTissue and state.d.wallet.cashCents==200,"clean changes original fact and retains tissue/wage balance")
	await press(KEY_ESCAPE)
	select_expected();await journal_round_trip("keyboard")
	if not await open_bike():return
	await click(shell.c3_device_panel.controls.pay)
	check(state.d.canteenHunt.bikePaid and state.d.wallet.cashCents==0 and not state.d.items.cafeteriaWages and state.d.items.greaseTissue,"source payment consumes exactly 2 yuan and retains tissue")
	await press(KEY_ESCAPE)
	select_expected();await journal_round_trip("touch")
	if not await open_bike():return
	check(shell.c3_device_panel.controls.ride.is_visible_in_tree() and not shell.c3_device_panel.controls.pay.visible,"paid reopen offers the action named by Tasks")
	check(state.d.wallet.cashCents==0 and state.d.canteenHunt.phase=="chase_ready","paid reopen cannot charge or start riding")
	await click(shell.c3_device_panel.controls.ride);await frames(6)
	check(state.d.canteenHunt.phase=="chase_ready" and shell.active_game.stage=="start","named Ride action presents departure before source chase phase")
	await click(shell.active_game.skip_button);await frames(6)
	check(state.d.canteenHunt.phase=="chasing" and is_instance_valid(shell.active_game),"named Ride action starts existing chase controller")
	check(Goal.current(state.d).is_empty() and state.objective()=="骑车追上纸条","active chase retires bike details and preserves original task")

func run() -> void:
	check(ProjectSettings.globalize_path("user://").begins_with("/tmp/"),"isolated test profile")
	if failures:quit(1);return
	state=root.get_node("State");state.developer_mode=true;state.d=state.initial()
	check(state.begin_checkpoint("c3-canteen-entry"),"source checkpoint initializes fixture")
	earned=state.d.duplicate(true)
	earned.canteenHunt.phase="chase_ready";earned.canteenHunt.entryPaperEscaped=true
	earned.canteenHunt.trayTaskStarted=true;earned.canteenHunt.returnedTrayIds=["tray_blue_01","tray_blue_02","tray_blue_03"]
	earned.canteenHunt.promoDrinkPlaced=true;earned.canteenHunt.queueGapOpened=true
	earned.native.scene="campus_bootstrap";earned.rpgScene="campus_bootstrap"
	earned.native.mode="light";earned.canteenHunt.mode="light"
	earned.items.greaseTissue=true;earned.items.cafeteriaWages=true;earned.wallet.cashCents=200
	var point: Dictionary=chapter.get_definition("campus_bootstrap","bike",earned)
	# Source bike has a proximity anchor, not a dedicated authored stand.
	# Use the same nearby walkable fixture as the existing world-drop test.
	earned.native.player={"x":point.x-70,"y":point.y+60,"scene":"campus_bootstrap"}
	projection_cases()
	shell=load("res://scenes/main.tscn").instantiate();root.add_child(shell);await frames();shell.set_process(false)
	state.action_completed.connect(func(id,_a,_b,_result):actions.append(id))
	for dimensions in [Vector2i(390,844),Vector2i(430,860),Vector2i(1440,900)]:
		for mode in ["light","dark"]:
			for stage in ["clean","pay","ride"]:
				var value:=earned.duplicate(true);value.native.mode=mode;value.canteenHunt.mode=mode
				value.canteenHunt.bikeLockCleaned=stage!="clean";value.canteenHunt.bikePaid=stage=="ride"
				if stage=="ride":value.items.cafeteriaWages=false;value.wallet.cashCents=0
				await restore(value,dimensions);select_expected()
				for method in ["pointer","touch","keyboard"]:await journal_round_trip(method)
		await device_flow(dimensions)
	await shell.shutdown();shell.queue_free();await frames()
	var report:=OS.get_environment("UI_QA_REPORT")
	if not report.is_empty():
		var file:=FileAccess.open(report,FileAccess.WRITE)
		file.store_string(JSON.stringify({"checks":checks,"failures":failures,"gui_used":false,"manual_campaign":false,"measurements":observations},"\t"));file.close()
	print("CANTEEN BIKE OBJECTIVE: %d checks; %d failures"%[checks,failures]);quit(1 if failures else 0)
