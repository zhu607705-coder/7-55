extends "res://tests/test_theater_clue_main.gd"
## Deterministic native-render replay of real fixture inventory gestures.
## This is an animation inspection reel, not an earned campaign playthrough.
func save_frame(part:String,index:int)->void:
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(capture_path(part+"/%04d.png"%index))
func run()->void:
	if DisplayServer.get_name()=="headless":quit(2);return
	state=root.get_node("State")
	var args:=OS.get_cmdline_user_args()
	var parts:Array=["vent"] if args.has("--vent") else ["poster"] if args.has("--poster") else ["poster","vent"]
	var viewport:=Vector2i(390,844) if args.has("--portrait") else Vector2i(1280,820)
	for part in parts:
		await clue_fixture(viewport,part)
		shell.world.set_process(false)
		DirAccess.make_dir_recursive_absolute(capture_path(part))
		var index:=0
		for i in 8:await save_frame(part,index);index+=1
		if part=="poster":await drag_item("greaseTissue",clue_screen(part),args.has("--touch"))
		else:
			# Keep the existing keyboard-equivalent operation in the second shot:
			# actual inventory selection, world focus and Space at the source stand.
			await click(slot("fluorescentBrush"));shell.world.grab_focus()
			for down in [true,false]:
				var key:=InputEventKey.new();key.keycode=KEY_SPACE;key.physical_keycode=KEY_SPACE;key.pressed=down
				event(key);await frames(2)
		var visual:RefCounted=shell.world.chapter3_layers.theater_clues
		check(is_instance_valid(visual.object_scene) and visual.object_scene.get_parent()==shell.world,"native fixture mounts independent clue object scene")
		check(visual.poster_ms==0 if part=="poster" else visual.dust_ms==0,"reel begins from an accepted original inventory/Space input")
		for i in 54:
			shell.world.chapter3_layers.tick(1.0/30.0,state.d)
			shell.world.queue_redraw()
			await save_frame(part,index);index+=1
		for i in 8:await save_frame(part,index);index+=1
		print("THEATER_CLUE_REEL ",part," frames=",index," rate=30; source=original fixture inventory/Space input + deterministic presentation samples")
	await shell.shutdown();shell.queue_free();await frames()
	print("THEATER_CLUE_REEL_COMPLETE failures=",failures);quit(1 if failures else 0)
