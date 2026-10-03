extends "res://tests/test_canteen_defense_resume.gd"
## Automated source-phase fixture and real Main/root input; not an earned run.
var accepted:=false
func run() -> void:
	state=root.get_node("State");state.developer_mode=true
	imported=state.initial();imported.native.chapter=3;imported.native.page="phone_home";imported.native.scene="canteen_interior"
	imported.canteenHunt.active=true;imported.canteenHunt.phase="exit_blocking"
	state.action_completed.connect(func(id,_before,after,_result):
		if id=="c3_defense_result": accepted=after.canteenHunt.phase=="chase_ready"
	)
	defense_fixture();await new_main(Vector2i(1440,900))
	check(is_instance_valid(shell.active_game) and shell.mobile_world,"desktop admission retains world return intent")
	var game: Control=shell.active_game
	check(str(game.config.seed)=="1","first ordinary controller session matches source fixture seed")
	shell.c3_narrative_host.set_process(false)
	root.size=Vector2i(430,860);shell.size=Vector2(430,860);shell._layout();await frames()
	check(shell.active_game==game and not shell.phone.visible,"portrait resize preserves admitted activity")
	await tap(game.start_button);finger_event(game.stick_center,0,true)
	var proof: Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://tests/fixtures/canteen_defense.json"))
	for input: Dictionary in proof.inputs:
		finger_drag(game.stick_center+Vector2(input.x,input.y)*55,0)
		if input.dash:
			var point: Vector2=game.dash_button.get_global_rect().get_center()
			finger_event(point,1,true);finger_event(point,1,false)
		game._process(1.0/60)
	check(game.model.status=="won" and game.model.tick==3600,"real root trace wins the unchanged sixty-second simulation")
	game._process(1);await frames()
	check(accepted and state.d.canteenHunt.phase=="chase_ready","ordinary completion callback accepts full controller proof")
	check(not is_instance_valid(shell.active_game) and shell.world_frame.is_visible_in_tree() and not shell.phone.visible,"completion returns to visible world after desktop-to-portrait entry")
	var host: Control=shell.c3_narrative_host
	host.tick(0,true)
	check(host.current!=null and host.current.sequence_id=="canteen_escape","authored victory narrative owns the next beat")
	var expected: Array=host.current.lines.map(func(line):return line.text)
	var seen: Array=[]
	var hidden_lines:=0
	for i in range(500):
		if host.current==null:break
		host.tick(50,true)
		if host.current!=null:
			var text: String=host.current.snapshot().rawText
			if not text.is_empty():
				if not text in seen:seen.append(text)
				if not host.view.is_visible_in_tree() or not shell.world_frame.is_visible_in_tree() or shell.phone.visible:hidden_lines+=1
	check(hidden_lines==0 and seen==expected,"every authored victory line is visibly owned by the world in source order")
	check(host.current==null and shell.world_frame.is_visible_in_tree() and not shell.phone.visible,"ordinary narrative completion retains world destination")
	# Exit uses the same admitted return context, but does not auto-admit again.
	defense_fixture();await new_main(Vector2i(1440,900));game=shell.active_game
	root.size=Vector2i(430,860);shell.size=Vector2(430,860);shell._layout();await frames()
	await tap(game.exit_button)
	check(not is_instance_valid(shell.active_game) and shell.mobile_world and shell.world_frame.visible and not shell.phone.visible,"Exit returns to world after desktop admission and portrait resize")
	for i in range(5):shell._process(.1);shell._layout();await frames(1)
	check(not is_instance_valid(shell.active_game),"world-return intent cannot restart an exited activity")
	await close_main()
	print("CANTEEN_DEFENSE_WORLD_RETURN: ",checks," checks; ",failures," failures")
	quit(1 if failures else 0)
