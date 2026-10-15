extends "res://tests/test_canteen_victory_camera.gd"
## QA snapshots of production renderers. Fixtures are not claimed earned play.
func save(name:String)->void:
	shell.world.queue_redraw();await frames(3);await RenderingServer.frame_post_draw
	var directory:String=OS.get_environment("HUD_OVERLAY_CAPTURE_DIR")
	if directory.is_empty():directory="/tmp/hud-layout-results"
	DirAccess.make_dir_recursive_absolute(directory)
	var error:int=root.get_texture().get_image().save_jpg(directory+"/"+name+".jpg",.92)
	if error!=OK:push_error("HUD screenshot write failed: "+str(error));quit(2)
func run()->void:
	if not ProjectSettings.globalize_path("user://").begins_with("/tmp/"):quit(2);return
	if DisplayServer.get_name()=="headless":quit(2);return
	Engine.max_fps=30
	state=root.get_node("State")
	oracle=JSON.parse_string(FileAccess.get_file_as_string("res://tests/fixtures/canteen_victory_source.json"))
	for dimensions:Vector2i in [Vector2i(1440,900),Vector2i(960,720),Vector2i(390,844),Vector2i(844,390)]:
		await open_victory(dimensions,false)
		var host:Control=shell.c3_narrative_host
		advance_to(float(host.current.lines[0].atMs));host.tick(0,true)
		await save("victory_%dx%d"%[dimensions.x,dimensions.y])
		host.reset();state.d.canteenHunt.phase="tray_search";state.d.canteenHunt.entryPaperEscaped=true
		shell.mobile_world=true;shell._refresh();await frames(3)
		shell.world.set_process(false);host.set_process(false);shell.world.transition_alpha=0
		shell.world.player=Vector2(1380,852);shell.world._sync_player()
		if OS.get_environment("HUD_OVERLAY_CAPTURE_SHORT")!="1":
			for zoom:float in [.45,.85,1.6]:
				shell.world.zoom=zoom;shell.world._update_camera();await save("door_%dx%d_z%.2f"%[dimensions.x,dimensions.y,zoom])
		# Explicit presentation fixture uses the original stamped-proof lines.
		# It is not represented as an earned stamp replay.
		await close_main();state.d=state.initial();state.developer_mode=true
		state.d.native.chapter=2;state.d.native.scene="library_interior";state.d.native.page="phone_home"
		state.d.runtimeMode="rpg";state.d.rpgScene="library_interior";state.d.actOne.phase="complete"
		state.d.ui.libraryFinalsPhase="evidence_gathering";state.d.ui.libraryFinalsPuzzle.nonPersonProofStamped=true
		await new_main(dimensions);shell.mobile_world=true;shell._refresh();await frames(3)
		shell.library_story_host.set_process(false);shell.world.set_process(false)
		shell.world.player=Vector2(334,736);shell.world._sync_player();shell.world.transition_alpha=0
		var source:Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://tests/fixtures/library_story_source.json"))
		var session:RefCounted=load("res://scripts/presentation/library_story_session.gd").new(state.d,"library_bag_nonperson_proof_issued",source.sequences.library_bag_nonperson_proof_issued)
		check(session.attach(state.d,shell.library_story_host),"capture source Library line attaches")
		shell.library_story_host.current=session;shell.library_story_host.view.session=session
		shell.PhoneNotice.set_message(shell.toast,"获得书包非本人证明。","系统");shell.toast_time=3.25
		shell.library_story_host.view.tick();shell._layout();await frames(2);shell.library_story_host.view.tick()
		shell.world._update_camera();await save("library_feedback_%dx%d"%[dimensions.x,dimensions.y])
	await close_main();print("WORLD_OVERLAY_CAPTURE_DONE: ",failures," failures");quit(1 if failures else 0)
