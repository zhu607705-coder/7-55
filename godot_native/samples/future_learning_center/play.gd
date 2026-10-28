extends SceneTree
var host:SubViewportContainer
var viewport:SubViewport
var world:Node2D
func _initialize()->void:run.call_deferred()
func run()->void:
	if not preload("res://tests/native_test_isolation.gd").is_isolated_save():printerr("Use samples/future_learning_center/run.mjs");quit(2);return
	root.title="7:55 · 未来学习中心 · 单间拼接 / 房间镜头"
	RenderingServer.set_default_clear_color(Color("101820"))
	host=SubViewportContainer.new();host.size=Vector2(960,540);host.stretch=false;root.add_child(host)
	viewport=SubViewport.new();viewport.size=Vector2i(960,540);viewport.render_target_update_mode=SubViewport.UPDATE_ALWAYS;host.add_child(viewport)
	world=load("res://campuses/future_learning_center/scripts/floor_view.gd").new();viewport.add_child(world)
	root.size_changed.connect(fit);fit()
	if not OS.get_environment("FLC_CAPTURE_DIR").is_empty():
		if OS.get_environment("FLC_INPUT_CHECK")=="1":await check_input()
		await capture_review()
		if OS.get_environment("FLC_EXPORT_MAP")=="1":await export_map()
		if OS.get_environment("FLC_CAPTURE_MOTION")=="1":await capture_motion()
		quit()
func fit()->void:
	var ratio:float=minf(root.size.x/960.0,root.size.y/540.0)
	host.scale=Vector2.ONE*ratio;host.position=(Vector2(root.size)-Vector2(960,540)*ratio)/2
func capture(label:String)->void:
	var folder:=OS.get_environment("FLC_CAPTURE_DIR");DirAccess.make_dir_recursive_absolute(folder)
	await process_frame;await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(folder.path_join(label+".png"))
func capture_review()->void:
	await process_frame;await process_frame
	world.user_control=false
	await capture("studio_room")
	for target:Array in [["seminar",Vector2(700,560)],["recording",Vector2(700,650)],["pantry",Vector2(650,650)],["xlab_south",Vector2(450,1000)]]:
		for row:Dictionary in world.data.modules:
			if row.id!=target[0]:continue
			var foot:Vector2=Vector2(row.at[0],row.at[1])+(target[1]-Vector2(row.crop[0],row.crop[1]))*float(row.scale)
			if not world.set_foot(foot):push_error("Invalid screenshot position: "+str(target[0]));continue
			await create_timer(.15).timeout;await capture(str(target[0])+"_room")
	world.overview=true;world.framing.update(0,world.player,world.space,true,true);world._apply_camera();world.queue_redraw()
	await capture("floor_overview")
	var report:={"floor":3,"world":world.data.world,"viewport":str(root.size),"illegalFrames":world.invalid_frames,"graphRejectedEdges":world.space.invalid_links,"modules":world.data.modules.size()}
	var file:=FileAccess.open(OS.get_environment("FLC_CAPTURE_DIR").path_join("capture.json"),FileAccess.WRITE);file.store_string(JSON.stringify(report,"  "));file.close()
func export_map()->void:
	world.capture_only=true;world.ui.hide();viewport.transparent_bg=true
	viewport.size=Vector2i(ceili(world.data.world[0]),ceili(world.data.world[1]))
	world.camera.position=Vector2(viewport.size)/2;world.camera.zoom=Vector2.ONE;world.camera.force_update_scroll();world.queue_redraw()
	await process_frame;await RenderingServer.frame_post_draw
	var plate:Image=viewport.get_texture().get_image()
	var output:=OS.get_environment("FLC_CAPTURE_DIR")
	plate.save_png(output.path_join("floor_3_assembled.png"))
	plate.resize(1316,2000,Image.INTERPOLATE_LANCZOS);plate.save_png(output.path_join("floor_3_assembled_preview.png"))
	viewport.size=Vector2i(960,540);viewport.transparent_bg=false;world.capture_only=false;world.ui.show()
	world.framing.update(0,world.player,world.space,true,world.overview);world._apply_camera()
func capture_motion()->void:
	var output:=OS.get_environment("FLC_CAPTURE_DIR").path_join("motion")
	DirAccess.make_dir_recursive_absolute(output)
	world.overview=false;world.user_control=true;world.set_process(false)
	var door:Dictionary=world.data.doors[0]
	var inside:=Vector2(door.inside[0],door.inside[1]);var outside:=Vector2(door.outside[0],door.outside[1])
	world.set_foot(inside-Vector2(480,0))
	world.request_walk(outside+Vector2(140,0))
	for frame:int in 420:
		if frame==220:world.request_walk(inside-Vector2(480,0))
		world._process(1.0/30.0)
		await process_frame;await RenderingServer.frame_post_draw
		viewport.get_texture().get_image().save_png(output.path_join("frame_%04d.png"%frame))
	world.set_process(true)
func key(code:Key,pressed:bool)->void:
	var event:=InputEventKey.new();event.keycode=code;event.physical_keycode=code;event.pressed=pressed
	Input.parse_input_event(event);await process_frame
func check_input()->void:
	var checks:=0;var failures:=0
	root.grab_focus();await process_frame;await process_frame
	var spawn:=Vector2(world.data.spawn[0],world.data.spawn[1])
	world.set_foot(spawn);world.user_control=true
	var before:Vector2=world.player
	await key(KEY_D,true);await create_timer(.35).timeout;await key(KEY_D,false)
	checks+=1
	if world.player.distance_to(before)<30 or not world.space.can_stand(world.player):failures+=1;push_error("FLC_INPUT keyboard did not move legally: %s -> %s"%[str(before),str(world.player)])
	await key(KEY_W,true);await create_timer(1.2).timeout;await key(KEY_W,false)
	checks+=1
	if not world.space.can_stand(world.player):failures+=1;push_error("FLC_INPUT crossed north wall")
	before=world.player
	await key(KEY_S,true);await create_timer(.3).timeout;await key(KEY_S,false)
	checks+=1
	if world.player.distance_to(before)<30:failures+=1;push_error("FLC_INPUT cannot retreat from wall")
	world.set_foot(spawn)
	var target:Vector2=spawn+Vector2(160,30)
	var screen:Vector2=host.position+world.world_to_screen(target)*host.scale
	var touch:=InputEventScreenTouch.new();touch.index=0;touch.position=screen;touch.pressed=true
	root.push_input(touch,true);await process_frame
	touch=touch.duplicate();touch.pressed=false;root.push_input(touch,true)
	await create_timer(1.1).timeout
	checks+=1
	if (world.player+world.Body.FOOT_CENTER_OFFSET).distance_to(target)>8:failures+=1;push_error("FLC_INPUT scaled touch did not reach target")
	checks+=1
	if world.invalid_frames!=0:failures+=1;push_error("FLC_INPUT illegal frame")
	var output:=OS.get_environment("FLC_CAPTURE_DIR");DirAccess.make_dir_recursive_absolute(output)
	var file:=FileAccess.open(output.path_join("input.json"),FileAccess.WRITE)
	file.store_string(JSON.stringify({"checks":checks,"failures":failures,"invalidFrames":world.invalid_frames,"viewport":[root.size.x,root.size.y],"scale":host.scale.x,"touchTarget":[target.x,target.y],"touchFinal":[world.player.x+world.Body.FOOT_CENTER_OFFSET.x,world.player.y+world.Body.FOOT_CENTER_OFFSET.y]},"  "));file.close()
	print("FLC_INPUT: %d checks, %d failures at %s"%[checks,failures,str(root.size)])
	world.set_foot(spawn)
