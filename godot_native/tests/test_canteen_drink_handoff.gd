extends "res://tests/test_canteen_objective_journal.gd"
## Headless Main/layout/input tests at authored stand-point fixtures. The optional
## earned save is copied read-only; this is not manual traversal or GUI evidence.
const Chapter=preload("res://scripts/chapters/chapter3.gd")
var chapter: RefCounted=Chapter.new()
var source_cases:=0

func source_cases_check() -> void:
	var oracle: Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://tests/fixtures/canteen_handoff_source.json"))
	for record: Dictionary in oracle.cases:
		for dark in [false,true]:
			var value:=earned.duplicate(true)
			for field in record.hunt: value.canteenHunt[field]=record.hunt[field]
			value.items.dailySpecialSparklingWater=record.items.dailySpecialSparklingWater
			value.native.mode="dark" if dark else "light"
			var before:=JSON.stringify(value)
			var goal: Dictionary=Goal.current(value)
			check(goal.id==record.id and goal.title==record.title,"id/title match executed original QuestModel")
			check(not goal.detail.contains("黑色") and not goal.detail.contains("蓝色") and not goal.detail.contains("白色") and not goal.detail.contains("黑咖啡"),"guidance never prints the recipe")
			check(JSON.stringify(value)==before,"objective projection preserves every save field")
			check(goal.detail.begins_with("切回浅色操作。") if dark and goal.id!="queue_shift" else not goal.detail.begins_with("切回浅色操作。"),"dark hints name reachable light operation only when an action remains")
			source_cases+=1
	for phase in ["pickup_search","exit_blocking","chase_ready","chasing","theater_reached"]:
		var value:=earned.duplicate(true);value.canteenHunt.phase=phase
		check(Goal.current(value).is_empty(),"later phase remains outside bounded handoff: "+phase)
	var value:=earned.duplicate(true);value.canteenHunt.queueGapOpened=true
	check(Goal.current(value).is_empty(),"opened queue ends this presentation handoff")
	value.canteenHunt.queueGapOpened=false;value.canteenHunt.active=false
	check(Goal.current(value).is_empty(),"inactive canteen has no stale handoff")
	for later in ["theaterHunt","qizhenLake"]:
		value=earned.duplicate(true);value[later].active=true
		check(Goal.current(value).is_empty(),"later active chapter has no stale handoff")

func inspect_journal(id: String) -> void:
	var before:=JSON.stringify(state.d)
	var goal: Dictionary=Goal.current(state.d)
	check(goal.get("id","")==id,"expected source objective "+id)
	shell._show_journal();await frames();check_layout()
	check(node("JournalObjective").text==goal.title and node("JournalNextStep").text==goal.detail,"actual journal displays current projection")
	check(node("JournalObservationCompare")==null,"no new comparison action")
	await press(KEY_ESCAPE)
	check(not is_instance_valid(shell.modal) and shell.world.has_focus(),"journal dismissal returns world focus")
	check(JSON.stringify(state.d)==before,"journal open/close retains exact items, wallet, story and log")

func layout_cases(dimensions: Vector2i) -> void:
	for mode in ["light","dark"]:
		var value:=earned.duplicate(true);value.native.mode=mode;value.canteenHunt.mode=mode
		await restore(value,dimensions);await inspect_journal("queue")
		value.canteenHunt.queueChallengeSeen=true;value.canteenHunt.drinkShelfRead=false
		await restore(value,dimensions);await inspect_journal("drink_shelf")
		value.canteenHunt.drinkShelfRead=true
		for count in range(3):
			value.canteenHunt.drinkMixSequence=["blackCoffee","sparklingWater"].slice(0,count)
			await restore(value,dimensions);await inspect_journal("drink_mix")
		value.canteenHunt.drinkMixSequence=[];value.items.dailySpecialSparklingWater=true
		await restore(value,dimensions);await inspect_journal("promo_drop")
		value.items.dailySpecialSparklingWater=false;value.canteenHunt.promoDrinkPlaced=true
		await restore(value,dimensions);await inspect_journal("queue_shift")

func stand(target: String, expect_nearby:=true) -> void:
	# Position is test setup. Actual keyboard input and controller own the action.
	var entry: Dictionary=chapter.get_definition("canteen_interior",target,state.d)
	check(not entry.is_empty(),"authored stand exists for "+target)
	if entry.is_empty(): return
	var point: Dictionary=entry.get("stand",{"x":entry.x,"y":entry.y})
	var position:=Vector2(point.x,point.y)
	check(shell.world.can_stand(position),"test interaction position is walkable: "+target)
	shell.world.player=position;shell.world._sync_player();shell.world._update_camera();shell.world._process(0)
	shell.world.grab_focus();await frames();shell.world._process(0)
	if expect_nearby:check(shell.world.nearby.get("id","")==target,"actual nearby resolves authored target "+target)

func finish_dialogue() -> void:
	shell.c3_narrative_host.tick(0,true)
	for i in range(1000):
		if shell.c3_narrative_host.current==null:break
		shell.c3_narrative_host.tick(100,true)
	await frames()
	check(shell.c3_narrative_host.current==null,"original dialogue reaches its own terminal acknowledgement")

func collect_drinks() -> void:
	for machine: Dictionary in chapter.world("canteen_interior").constants.CANTEEN_DRINK_MACHINES:
		await stand(machine.id);await press(KEY_SPACE)
		check(is_instance_valid(shell.c3_device_panel),"actual world Space opens drink machine")
		if not is_instance_valid(shell.c3_device_panel):return
		await click(shell.c3_device_panel.controls.take)
		check(state.d.items[machine.value],"source Take grants its own ingredient")

func pour(id: String) -> void:
	var panel: Control=shell.c3_device_panel
	check(is_instance_valid(panel),"existing mixer remains open for a pour")
	if not is_instance_valid(panel):return
	var index: int=panel.session.button_order.find(id)
	check(index>=0,"original shuffled mixer exposes ingredient")
	if index>=0:await click(panel.slots[index])

func live_handoff(dimensions: Vector2i) -> void:
	await restore(earned,dimensions)
	var initial_items: Dictionary=state.d.items.duplicate(true)
	var cash: float=state.d.wallet.cashCents
	await inspect_journal("queue")
	# The randomized source counter NPC can be nearer at the authored queue
	# stand. This one step intentionally tests the controller's targeted intent,
	# not nearest-NPC keyboard selection. Device steps below use actual input.
	await stand("queue-column-three-front",false);state.act("c3_target:queue-column-three-front");await frames()
	check(state.d.canteenHunt.queueChallengeSeen,"source queue interaction earns challenge fact")
	await finish_dialogue()
	check(state.d.items==initial_items and state.d.wallet.cashCents==cash,"queue dialogue neither charges wages nor grants drinks")
	await inspect_journal("drink_mix")
	# A failed mix remains possible and changes only the existing source items.
	await collect_drinks();await stand("canteen-mixer");await press(KEY_SPACE)
	for id in ["lemonTea","sparklingWater","blackCoffee"]:await pour(id)
	check(state.d.items.badDrink and not state.d.items.dailySpecialSparklingWater and state.d.canteenHunt.drinkMixAttemptCount==1,"source wrong recipe remains a failed attempt")
	await inspect_journal("drink_mix")
	await collect_drinks();await stand("canteen-mixer");await press(KEY_SPACE)
	await pour("blackCoffee")
	check(state.d.canteenHunt.drinkMixSequence==["blackCoffee"] and state.objective().ends_with("（1/3）"),"source partial pour updates only earned count")
	await press(KEY_ESCAPE);await inspect_journal("drink_mix")
	await stand("canteen-mixer");await press(KEY_SPACE)
	check(state.d.canteenHunt.drinkMixSequence==["blackCoffee"],"close/reopen preserves partially poured glass")
	await pour("sparklingWater");await pour("lemonTea")
	check(state.d.items.dailySpecialSparklingWater and state.d.canteenHunt.drinkMixAttemptCount==2,"source correct recipe grants product after retry")
	await inspect_journal("promo_drop")
	if shell.inventory_handle.is_visible_in_tree() and not shell.inventory_dock.is_visible_in_tree():await click(shell.inventory_handle)
	await click(await reveal("dailySpecialSparklingWater"))
	await stand("canteen-promo-board");await press(KEY_SPACE)
	check(state.d.canteenHunt.promoDrinkPlaced and not state.d.canteenHunt.queueGapOpened,"source placement waits for original queue presentation")
	check(Goal.current(state.d).id=="queue_shift","pending presentation retains wait objective")
	var before:=JSON.stringify(state.d)
	shell.c3_narrative_host.tick(100,false)
	check(JSON.stringify(state.d)==before,"focus loss cannot earn queue shift")
	await finish_dialogue()
	check(state.d.canteenHunt.queueGapOpened and state.d.canteenHunt.phase=="menu_order" and Goal.current(state.d).id=="menu_order","original terminal acknowledgement hands off to source menu objective")
	check(state.d.wallet.cashCents==cash and state.d.items.cafeteriaWages and state.d.items.greaseTissue,"entire handoff preserves exact wages and tissue")
	check(state.d.items.badDrink,"failed drink retains original inventory behavior after successful retry")

func run() -> void:
	check(ProjectSettings.globalize_path("user://").begins_with("/tmp/"),"isolated test profile")
	if failures:quit(1);return
	state=root.get_node("State");state.developer_mode=true;state.d=state.initial()
	var path:=OS.get_environment("CANTEEN_EARNED_SAVE")
	if path.is_empty():
		check(state.begin_checkpoint("c3-canteen-entry"),"fixture starts from source checkpoint")
		earned=state.d.duplicate(true);earned.canteenHunt.entryPaperEscaped=true;earned.canteenHunt.trayTaskStarted=true
		earned.canteenHunt.returnedTrayIds=["tray_blue_01","tray_blue_02","tray_blue_03"]
		earned.canteenHunt.drinkShelfRead=true;earned.items.cafeteriaWages=true;earned.items.greaseTissue=true;earned.wallet.cashCents=200
	else:earned=JSON.parse_string(FileAccess.get_file_as_string(path)).state
	check(earned.canteenHunt.phase=="tray_search" and earned.canteenHunt.drinkShelfRead and not earned.canteenHunt.queueChallengeSeen,"post-trays fixture retains earned shelf before unseen queue")
	source_cases_check()
	shell=load("res://scenes/main.tscn").instantiate();root.add_child(shell);await frames();shell.set_process(false)
	for dimensions in [Vector2i(390,844),Vector2i(430,860),Vector2i(1440,900)]:
		await layout_cases(dimensions)
		await live_handoff(dimensions)
	await shell.shutdown();shell.queue_free();await frames()
	var report:=OS.get_environment("UI_QA_REPORT")
	if not report.is_empty():
		var file:=FileAccess.open(report,FileAccess.WRITE)
		file.store_string(JSON.stringify({"checks":checks,"failures":failures,"sourceCases":source_cases,"gui_used":false,"manual_campaign":false,"measurements":observations},"\t"));file.close()
	print("CANTEEN DRINK HANDOFF: %d checks; %d failures; %d source cases"%[checks,failures,source_cases]);quit(1 if failures else 0)
