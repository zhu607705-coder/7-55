extends SceneTree
## Continuous native preview with real route approach; no actor position writes.
var campus:Node2D
var out:=""
var checks:=0
var failures:Array=[]
var trace:Array=[]
var recording:=false
var illegal_ticks:=0
func _initialize()->void:run.call_deferred()
func check(ok:bool,label:String)->void:
	checks+=1
	if not ok:failures.append(label);push_error(label)
func monitor()->void:
	if is_instance_valid(campus) and campus.initialized and not campus.is_walkable(campus.visitor.position):illegal_ticks+=1
func frame()->void:
	await process_frame
	for region in campus.west_hd_regions:region.update_actor_foot(campus.visitor.position.y)
	campus.library_layer.update_actor_foot(campus.visitor.position.y)
	await RenderingServer.frame_post_draw
func aim(p:Vector2,z:float)->void:
	campus.camera.position=p;campus.camera.zoom=Vector2.ONE*z;campus.camera.reset_smoothing();campus.camera.force_update_scroll()
func run()->void:
	out=OS.get_environment("BUCT_WEST_QA_DIR").path_join("preview");DirAccess.make_dir_recursive_absolute(out.path_join("frames-jpeg"));root.size=Vector2i(1280,720)
	campus=load("res://campuses/buct_changping/scenes/playable.tscn").instantiate();root.add_child(campus);current_scene=campus
	await process_frame;await physics_frame;await process_frame
	check(campus.west_hd_regions.size()==2,"Actual production defaults load complete 2x2 group")
	physics_frame.connect(monitor)
	var target:Vector2=campus.grid.get_point_position(campus.nearest_cell(Vector2(731,676)))
	check(campus.path_to(target),"Previously verified original route connects real spawn to north/east legal viewpoint")
	var frames:=0
	while campus.visitor.position.distance_to(target)>3.2 and frames<1600:
		await process_frame;frames+=1
	check(campus.visitor.position.distance_to(target)<=3.2,"Continuous physical approach arrives without teleport")
	if not failures.is_empty():finish();return
	campus.current_path.clear();campus.set_process(false);campus.camera.position_smoothing_enabled=false;campus.ui.hide();campus.pin_layer.hide();campus.canopy_locator.hide()
	var preview_note=CanvasLayer.new();root.add_child(preview_note)
	var label=Label.new();label.text="连片高清区域原生巡视 · 馆西路入口连通待修";label.position=Vector2(18,18)
	label.add_theme_font_override("font",campus.font);label.add_theme_font_size_override("font_size",16)
	label.add_theme_color_override("font_color",Color.WHITE);label.add_theme_color_override("font_shadow_color",Color.BLACK)
	label.add_theme_constant_override("shadow_offset_x",1);label.add_theme_constant_override("shadow_offset_y",1);preview_note.add_child(label)
	var start:=Time.get_ticks_usec();recording=true
	for index in range(180):
		if index<60 or index>=140:aim(Vector2(634,628),1.4)
		elif index<100:aim(Vector2(468,655),3.5)
		else:aim(Vector2(513,786),3.4)
		var delay=maxf(.001,(float(index)*.05)-float(Time.get_ticks_usec()-start)/1000000.)
		await create_timer(delay).timeout;await frame()
		root.get_texture().get_image().save_jpg(out.path_join("frames-jpeg/frame-%04d.jpg"%index),.91)
		trace.append({"frame":index,"timestamp_seconds":float(Time.get_ticks_usec()-start)/1000000.,"feet":[campus.visitor.position.x,campus.visitor.position.y],"legal":campus.is_walkable(campus.visitor.position),"camera":[campus.camera.position.x,campus.camera.position.y],"zoom":campus.camera.zoom.x})
	Input.action_release("buct_changping_walk_up");Input.action_release("buct_changping_walk_down")
	check(illegal_ticks==0,"All real approach and preview movement stays on original paving")
	# Pure 950x1656 map view of the same live scene, every body remains present.
	campus.visitor.hide();campus.route_visual.hide();preview_note.hide()
	var viewport=SubViewport.new();viewport.size=Vector2i(950,1656);viewport.world_2d=campus.get_world_2d();viewport.render_target_update_mode=SubViewport.UPDATE_ALWAYS;root.add_child(viewport)
	var camera=Camera2D.new();camera.position=Vector2(475,828);camera.zoom=Vector2.ONE;viewport.add_child(camera);camera.make_current();await frame()
	var pure=viewport.get_texture().get_image();pure.save_png(out.path_join("changping-950x1656-current-four-regions.png"));check(pure.get_size()==Vector2i(950,1656),"Pure map retains exact source dimensions")
	viewport.queue_free();await process_frame;finish()
func finish()->void:
	var f=FileAccess.open(out.path_join("west-contiguous-preview-result.json"),FileAccess.WRITE);f.store_string(JSON.stringify({"checks":checks,"failures":failures,"frames":trace.size(),"trace":trace,"illegal_physics_ticks":illegal_ticks,"actor_position_writes":0,"caption":"连片高清区域原生巡视；馆西路入口连通待修","scope":"Actor remains at the reachable road viewpoint while camera surveys other regions. Actual renderer continuous native preview; physical unrecorded approach from real spawn to previously verified [731,676], no foot writes or movement during camera-only recording; original library route disconnection retained as separate diagnostic"},"  "));f.close();print("BUCT_WEST_PREVIEW checks=%d failures=%d frames=%d"%[checks,failures.size(),trace.size()]);quit(0 if failures.is_empty() else 1)
