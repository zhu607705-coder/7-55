extends "res://tests/test_maintenance_cover_main.gd"
## Controlled source poses are labeled separately from a fresh real-input stop.
var output:=""
func capture(label:String)->void:
	await frames(3);await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(output+"/"+label+".png")
func run()->void:
	if DisplayServer.get_name()=="headless":print("MAINTENANCE_COVER_CAPTURE needs a graphical display");quit(0);return
	if not OS.get_user_data_dir().begins_with("/tmp/"):
		push_error("Refusing maintenance capture import outside isolated /tmp profile");quit(2);return
	state=root.get_node("State");output=OS.get_environment("COVER_CAPTURE_DIR")
	if output.is_empty():output=ProjectSettings.globalize_path("res://.screenshots/maintenance-cover")
	DirAccess.make_dir_recursive_absolute(output)
	for dim in [Vector2i(1280,720),Vector2i(390,844)]:
		DisplayServer.window_set_size(dim);await cover_fixture(dim);await diagnose();await reveal("shortPryBar")
		await capture("cover-%dx%d-closed"%[dim.x,dim.y])
		state.act("c4_cart_cover");await frames(2);shell.world.set_process(false)
		var motion:RefCounted=shell.world.chapter4_layers.phases.cover_motion
		for stamp in [0.0,100.0,200.0]:
			# Freeze only the already-authorized local hinge, never a story fact.
			motion.sample(state.d);motion.started_ms=-1;motion.elapsed_ms=stamp;shell.world.queue_redraw()
			await capture("cover-%dx%d-frozen-%dms"%[dim.x,dim.y,int(stamp)])
		state.act("c4_cart_oil");shell.world.set_process(true);await frames(3)
		check(not state.d.items.shortPryBar and not state.d.items.universalLubricatingOil,"Original controller remains tool authority")
	if OS.get_environment("COVER_MANUAL")=="1":
		DisplayServer.window_set_size(Vector2i(1280,720));await cover_fixture(Vector2i(1280,720));await diagnose();await reveal("shortPryBar")
		var path:=output+"/manual-events.jsonl";var f:=FileAccess.open(path,FileAccess.WRITE);f.close()
		state.action_completed.connect(func(action:String,before:Dictionary,after:Dictionary,result:Dictionary):
			var file:=FileAccess.open(path,FileAccess.READ_WRITE);file.seek_end();file.store_line(JSON.stringify({"at_ms":Time.get_ticks_msec(),"action":action,"before_facts":before.chapter4.factIds,"after_facts":after.chapter4.factIds,"result":result}));file.close()
		)
		print("MAINTENANCE_COVER_MANUAL_READY prybar=",slot("shortPryBar").get_global_rect()," target=",wheel_screen("a1_cleaning_cart_wheel_cover"))
		return
	if is_instance_valid(shell):await shell.shutdown();shell.queue_free();await frames()
	print("MAINTENANCE_COVER_CAPTURE: %d checks; %d failures"%[checks,failures]);quit(1 if failures else 0)
