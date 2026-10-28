extends SceneTree
## Actual viewport captures only. Refuses headless/dummy rendering and missing art.
## DEV/source-time fixtures; no claim of earned campaign progression.
const Metrics=preload("res://scripts/player_metrics.gd")
func _initialize()->void:run.call_deferred()
func frames(n:=3)->void:
	for i in n:await process_frame
func run()->void:
	if DisplayServer.get_name()=="headless":
		printerr("NORTH_PROP_CAPTURE_BLOCKED: a real graphics display is required; headless cannot be called a screenshot.");quit(2);return
	if not preload("res://tests/native_test_isolation.gd").is_isolated_save():quit(2);return
	var output:=OS.get_environment("NORTH_PROP_CAPTURE_DIR")
	if output.is_empty():printerr("Set NORTH_PROP_CAPTURE_DIR");quit(2);return
	DirAccess.make_dir_recursive_absolute(output)
	var state:Node=root.get_node("State");state.developer_mode=true
	state.begin_checkpoint("c4-755-classrooms-1850")
	state.d.chapter4.mode="light";state.d.native.mode="light"
	root.size=Vector2i(1280,720);DisplayServer.window_set_size(root.size)
	var world:Control=load("res://scripts/world.gd").new();world.size=Vector2(1280,720);root.add_child(world);world.set_process(false)
	await frames()
	if not world.north_objects.active:
		printerr("NORTH_PROP_CAPTURE_BLOCKED: real generated assets required: "+str(world.north_objects.issues));quit(2);return
	world.camera=Vector2(1415,590);world.zoom=2.5;world.transition_alpha=0;world.subtitle="";world.nearby={}
	var cleanup_only:=OS.get_environment("NORTH_PROP_CAPTURE_CLEANUP_ONLY")=="1"
	if cleanup_only:
		world.presentation_actor_hidden=true
		for object:Node2D in world.north_props.objects.values():object.hide()
		for reveal:Sprite2D in world.north_props.reveal_objects.values():reveal.hide()
	var depths:Array=["cleanup_only"] if cleanup_only else ["behind_wall_contact","in_front"]
	var report:Array=[]
	for time_id:String in ["2245_opening","2245_maintenance","0754_blackout","1225_bakery","0755_morning"]:
		# Swap only the authored plate for a presentation fixture. Controller phase
		# is untouched; no interactions are dispatched during these captures.
		world.background=load("res://assets/rpg/interiors/finale/chapter4-755/states/a1_"+time_id+".png")
		world.north_objects.configure(world.scene_id,"A1",world.background)
		for depth:String in depths:
			var bottom_y:=584.0 if depth=="behind_wall_contact" else 626.0
			world.player=Vector2(1406,bottom_y)-Metrics.FOOT_CENTER_OFFSET-Vector2(0,Metrics.FOOT_SIZE.y/2)
			if not world.can_stand(world.player):printerr("Illegal screenshot fixture stand "+depth);quit(1);return
			world.queue_redraw();await frames(6);await RenderingServer.frame_post_draw
			var pixels:=root.get_texture().get_image()
			if pixels==null or pixels.is_empty():printerr("No real viewport pixels");quit(2);return
			var file_name:=time_id+"-"+depth+".png"
			if pixels.save_png(output.path_join(file_name))!=OK:quit(2);return
			report.append({"image":file_name,"timePlate":time_id,"playerFootBottom":bottom_y,"legalStand":true,"source":"actual Godot viewport","fixture":"cleanup diagnostic (new sprites and player deliberately hidden)" if cleanup_only else "isolated DEV presentation; not campaign proof"})
	var file:=FileAccess.open(output.path_join("cleanup_captures.json" if cleanup_only else "captures.json"),FileAccess.WRITE);file.store_string(JSON.stringify(report,"  "));file.close()
	world.queue_free();await frames();print("NORTH_PROP_ACTUAL_CAPTURES: ",report.size());quit()
