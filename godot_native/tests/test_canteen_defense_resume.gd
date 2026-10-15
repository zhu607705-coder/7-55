extends "res://tests/test_canteen_defense_mobile.gd"
var starts:=0
var imported: Dictionary={}
func close_main() -> void:
	if is_instance_valid(shell):
		await shell.shutdown();shell.queue_free();await frames()
func new_main(view: Vector2i) -> void:
	await close_main()
	root.size=view
	shell=load("res://scenes/main.tscn").instantiate();root.add_child(shell);await frames(6)
	shell.set_process(false);shell.world.set_process(false)
	if is_instance_valid(shell.active_game): shell.active_game.set_process(false)
func defense_fixture() -> void:
	state.d=imported.duplicate(true);state.developer_mode=true
func find_text(node: Node,text: String) -> Button:
	if node is Button and node.text==text and node.is_visible_in_tree(): return node
	for child in node.get_children():
		var found:=find_text(child,text)
		if found!=null:return found
	return null
func run() -> void:
	state=root.get_node("State");state.developer_mode=true
	var path:=OS.get_environment("DEFENSE_EARNED_SAVE")
	if not path.is_empty():
		var source: Dictionary=JSON.parse_string(FileAccess.get_file_as_string(path))
		imported=source.state.duplicate(true)
	else:
		imported=state.initial();imported.native.chapter=3;imported.native.page="phone_home";imported.native.scene="canteen_interior"
		imported.runtimeMode="rpg";imported.rpgScene="canteen_interior"
		imported.canteenHunt.active=true;imported.canteenHunt.phase="exit_blocking"
	defense_fixture()
	state.action_completed.connect(func(id,_before,_after,_result):
		if id=="c3_defense":starts+=1
	)
	for _cycle in range(2):
		defense_fixture();var count:=starts;await new_main(Vector2i(1440,900))
		check(is_instance_valid(shell.active_game) and starts==count+1,"fresh desktop entry creates exactly one controller session")
		var game: Control=shell.active_game;var session=game.config.session_id
		check(not game._pickup_active,"saved defense entry never replays pickup")
		await tap(game.start_button); game._process(1.0/60);await tap(game.pause_button)
		root.size=Vector2i(430,860);shell.size=Vector2(430,860);shell._layout();shell._refresh();shell._resume_canteen_defense();await frames()
		check(shell.active_game==game and game.paused and game.config.session_id==session and starts==count+1,"refresh resize and entry cannot replace paused session")
		await tap(game.exit_button);count=starts
		for i in range(6):shell._process(.1);shell._refresh();shell._layout();await frames(1)
		check(not is_instance_valid(shell.active_game) and starts==count,"Exit stays exited across refresh and process frames")
		# Existing phone Tasks/Return path supplies a real, ordinary entry action.
		if shell.mobile_back.visible: await click(shell.mobile_back)
		check(not shell.mobile_world and shell.phone.visible,"ordinary phone return remains available")
		shell._show_journal();await frames()
		var back: Button=shell.find_child("JournalResume",true,false)
		check(back!=null,"existing Tasks has Return to scene")
		if back!=null:await click(back)
		check(is_instance_valid(shell.active_game) and starts==count+1,"Tasks Return deliberately admits another controller session")
		if is_instance_valid(shell.active_game):await tap(shell.active_game.exit_button)
	# Compact fresh startup stays on phone until existing Return explicitly enters.
	defense_fixture();var count:=starts;await new_main(Vector2i(430,860))
	check(not is_instance_valid(shell.active_game) and shell.phone.visible and starts==count,"portrait reload stays on requested phone page")
	shell._show_journal();await frames();var back: Button=shell.find_child("JournalResume",true,false)
	if back!=null:await click(back)
	check(is_instance_valid(shell.active_game) and starts==count+1,"portrait phone to Return starts saved defense")
	if is_instance_valid(shell.active_game):await tap(shell.active_game.exit_button)
	count=starts;state.d.canteenHunt.phase="pickup_search";shell._show_world_mobile();await frames()
	check(starts==count and not is_instance_valid(shell.active_game),"earlier phase cannot enter defense")
	# A desktop journal promises Return to scene even after a portrait resize.
	root.size=Vector2i(1440,900);shell.size=Vector2(1440,900);shell.mobile_world=true;shell._layout();await frames()
	var story_before:=JSON.stringify(state.d)
	shell._show_journal();await frames()
	back=shell.find_child("JournalResume",true,false)
	check(back!=null and back.text=="返回现场","desktop Tasks promises Return to scene")
	root.size=Vector2i(430,860);shell.size=Vector2(430,860);shell._layout();await frames()
	check(is_instance_valid(shell.modal) and shell.world_frame.visible,"portrait resize keeps the same journal over retained world")
	if back!=null:await click(back)
	check(not is_instance_valid(shell.modal) and shell.mobile_world and shell.world_frame.visible and not shell.phone.visible,"actual Return restores original world destination after orientation")
	check(starts==count and not is_instance_valid(shell.active_game) and JSON.stringify(state.d)==story_before,"ordinary pickup Return cannot admit defense or alter story")
	state.d.canteenHunt.phase="exit_blocking";state.d.native.scene="campus_bootstrap";shell._show_world_mobile();await frames()
	check(starts==count and not is_instance_valid(shell.active_game),"another scene cannot enter defense")
	defense_fixture();shell._show_settings();shell._show_world_mobile();await frames()
	check(starts==count and not is_instance_valid(shell.active_game),"modal ownership blocks admission")
	shell._close_modal()
	# Normal export/import uses the same reader, sanitizer, reset and save order.
	var exported: String="user://defense-resume-test.json"
	check(state.export_save(exported)==OK,"fixture exports through ordinary save format")
	for _cycle in range(2):
		count=starts
		var result: Dictionary=state.import_save(exported);await frames(8)
		check(result.ok and is_instance_valid(shell.active_game) and starts==count+1,"import installs candidate before exactly one scene reentry")
		check(state.d.canteenHunt.phase=="exit_blocking","import/resume cannot advance story")
		if is_instance_valid(shell.active_game):
			shell.active_game.set_process(false)
			await tap(shell.active_game.exit_button)
		state.developer_mode=true
	await close_main()
	print("CANTEEN_DEFENSE_RESUME: ",checks," checks; ",failures," failures; controller_starts=",starts)
	quit(1 if failures else 0)
