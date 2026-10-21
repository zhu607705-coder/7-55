extends "res://tests/capture_ui_redesign.gd"
## Every registered world, actual renderer. DEV fixtures, never campaign proof.
func run()->void:
	if DisplayServer.get_name()=="headless" and not validate_only:quit(2);return
	if not load("res://tests/native_test_isolation.gd").is_isolated_save():quit(2);return
	create_timer(180).timeout.connect(func():push_error("Selected world capture deadline");quit(2))
	output=OS.get_environment("UI_CAPTURE_DIR")
	if output.is_empty():quit(2);return
	DirAccess.make_dir_recursive_absolute(output)
	state=root.get_node("State");state.developer_mode=true
	var fixtures:Dictionary={"dorm_hub":"c2-dorm-exit","campus_bootstrap":"c2-library-gate","library_interior":"c2-occupancy-note","canteen_interior":"c3-canteen-entry","theater_interior":"c3-theater-program","campus_qizhen_loop":"c3-qizhen-location","qizhen_lake":"c3-qizhen-location","duan_yongping_temporal_maze":"c4-755-hall-clock"}
	var registered:Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://data/worlds.json")).worlds
	if not require_fixture(fixtures.size()==registered.size(),"every registered world has a fixture"):quit(1);return
	for dimensions:Vector2i in [Vector2i(1440,900),Vector2i(390,844),Vector2i(667,375)]:
		DisplayServer.window_set_size(dimensions);root.size=dimensions
		for id:String in fixtures:
			print("Selected world fixture ",dimensions," / ",id)
			if not fixture_checkpoint(fixtures[id]):quit(1);return
			state.d.native.scene=id;state.d.rpgScene=id;state.d.native.settings.volume=0
			await fresh_shell(dimensions)
			shell.mobile_world=true;shell._refresh();shell._layout();await frames(20)
			shell.world.transition_alpha=0;shell.world.subtitle=""
			# Keep authored target/prose; expose the real first target only for UI review.
			if not shell.world.targets.is_empty():
				# Freeze only the screenshot presentation, after selecting an authored
				# target. No new action, reward or target is authored by this fixture.
				shell.world.set_process(false)
				shell.world.nearby=shell.world.targets[0]
			shell.world.queue_redraw();await frames()
			if not require_fixture(shell.world.scene_id==id,"actual world mounted "+id):continue
			fixture_note="DEV "+str(fixtures[id])+" + native.scene/rpgScene="+id+" + first authored target nearby / world tick frozen for screenshot; no earned completion"
			await capture("%dx%d-selected-world-%s"%[dimensions.x,dimensions.y,id])
	var file:=FileAccess.open(output.path_join("selected-world-captures.json"),FileAccess.WRITE)
	if file==null:quit(2);return
	file.store_string(JSON.stringify(report,"\t"));file.close()
	await shell.shutdown();shell.queue_free();await frames()
	print("SELECTED_WORLD_FIXTURES " if validate_only else "SELECTED_WORLD_CAPTURES ",report.size())
	quit(1 if capture_failed else 0)
