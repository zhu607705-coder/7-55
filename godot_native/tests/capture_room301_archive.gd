extends "res://tests/test_room301_archive_main.gd"
## Source-seeded real-Main rendering. No complete earned-walkthrough claim.
var output:=""
var prefix:=""
func capture(label:String)->void:
	await frames(4);await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(output+"/"+prefix+label+".png")
	print("ROOM301_CAPTURE ",prefix+label)
func run()->void:
	if DisplayServer.get_name()=="headless":print("ROOM301_CAPTURE requires a graphical display");quit(0);return
	state_node=root.get_node("State")
	output=OS.get_environment("ROOM301_CAPTURE_DIR")
	if output.is_empty():output=ProjectSettings.globalize_path("res://.screenshots/room301")
	DirAccess.make_dir_recursive_absolute(output)
	var dimension:=Vector2i(390,844) if OS.get_environment("ROOM301_CAPTURE_SIZE")=="390x844" else Vector2i(1280,720)
	prefix="room301-%dx%d-"%[dimension.x,dimension.y]
	await prepare_archive(dimension)
	# Explicit test stand-point setup so the normal room object is in frame.
	shell.world.player=Vector2(290,442);shell.world._sync_player();shell._show_world_mobile();await frames(5)
	await capture("world-before")
	var panel:Control=await open_archive()
	await capture("open")
	await select_index(panel,"yearBand","1977_1984");await select_index(panel,"floor","A1");await select_index(panel,"purpose","attendance")
	await click_at(panel.view.handle.get_center());await settle(panel)
	check(not panel.session.completed and not panel.feedback.text.is_empty(),"Rendered wrong answer retains failure feedback")
	await capture("wrong")
	await press_key(KEY_ESCAPE);panel=await open_archive()
	await select_index(panel,"yearBand","1991_1998");await select_index(panel,"floor","A3");await select_index(panel,"purpose","wayfinding")
	await capture("selected")
	await click_at(panel.view.handle.get_center());await settle(panel)
	check(panel.session.completed,"Rendered real handle submission earns original film")
	await capture("accepted")
	await press_key(KEY_ESCAPE);await frames(1)
	# Freeze only presentation time for the documented source poses.
	shell.world.set_process(false)
	for stamp in [0.0,480.0,760.0,1000.0]:
		shell.world.chapter4_layers.archive_motion.stage="handoff"
		shell.world.chapter4_layers.archive_motion.elapsed_ms=stamp
		shell.world.queue_redraw();await capture("handoff-%d"%int(stamp))
	shell.world.set_process(true);await frames(3)
	panel=await open_archive();await capture("completed-reentry")
	await press_key(KEY_ESCAPE)
	# Optional manual stop presents a fresh, valid setup for desktop input QA.
	if OS.get_environment("ROOM301_MANUAL")=="1":
		await prepare_archive(dimension);panel=await open_archive()
		var manual_path:=output+"/manual-events.jsonl"
		var file:=FileAccess.open(manual_path,FileAccess.WRITE);file.close()
		state_node.action_completed.connect(func(action:String,before:Dictionary,after:Dictionary,result:Dictionary):
			var log:=FileAccess.open(manual_path,FileAccess.READ_WRITE);log.seek_end()
			log.store_line(JSON.stringify({"at_ms":Time.get_ticks_msec(),"action":action,"result":result,"before_film":ArchiveMotion.FACT in before.chapter4.factIds,"after_film":ArchiveMotion.FACT in after.chapter4.factIds}));log.close()
		)
		print("ROOM301_MANUAL_READY ",dimension)
		return
	await shell.shutdown();shell.queue_free();await frames(3)
	print("ROOM301_CAPTURE: %d checks; %d failures"%[checks,failures]);quit(1 if failures else 0)
