extends SceneTree
## Use this identical fixture on #119's unchanged campus module and the new library.
## Same window, overview camera, uncapped llvmpipe, warmed static scene per mode.
var app
var output := ""
func _initialize() -> void: run.call_deferred()
func settle() -> void:
	for i in range(20):await RenderingServer.frame_post_draw
func cost() -> Dictionary:
	var times: Array[float]=[]
	var draws: Array[float]=[]
	var previous:=Time.get_ticks_usec()
	for i in range(120):
		await RenderingServer.frame_post_draw
		var now:=Time.get_ticks_usec();times.append(float(now-previous)/1000.0);previous=now
		draws.append(Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME))
	times.sort();draws.sort()
	return {"median_ms":times[60],"p95_ms":times[114],"median_draw_calls":draws[60],"nodes":Performance.get_monitor(Performance.OBJECT_NODE_COUNT)}
func changed(a: Image,b: Image) -> int:
	var count:=0
	for y in range(a.get_height()):
		for x in range(a.get_width()):
			if a.get_pixel(x,y)!=b.get_pixel(x,y):count+=1
	return count
func run() -> void:
	output=OS.get_environment("BUCT_CAPTURE_DIR")
	if output.is_empty():output=ProjectSettings.globalize_path("user://buct-repair-performance")
	DirAccess.make_dir_recursive_absolute(output)
	root.size=Vector2i(1440,900);DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	app=load("res://campuses/buct/scenes/playable.tscn").instantiate();root.add_child(app)
	await process_frame;await process_frame
	app.toggle_overview();app.set_process(false);app.visitor.set_physics_process(false)
	var repair: SubViewport=app.world.get_node("GroundRepairTiles")
	var result={"adapter":RenderingServer.get_video_adapter_name(),"engine":Engine.get_version_info().string,"viewport":[1440,900],"camera_position":[app.camera.position.x,app.camera.position.y],"camera_zoom":[app.camera.zoom.x,app.camera.zoom.y],"cells":repair.get_node("SourcePaving16px").get_used_cells().size(),"vsync":"disabled","failures":[]}
	repair.render_target_update_mode=SubViewport.UPDATE_ALWAYS;await settle()
	result.always=await cost();var always:=root.get_texture().get_image();always.save_png(output.path_join("overview-always.png"))
	repair.render_target_update_mode=SubViewport.UPDATE_ONCE;await settle()
	result.once=await cost();var once:=root.get_texture().get_image();once.save_png(output.path_join("overview-cached.png"))
	result.always_vs_cached_changed_pixels=changed(always,once)
	result.cached_texture_not_empty=repair.get_texture().get_image().get_data().size()>0
	result.update_mode_property_after_once=repair.render_target_update_mode
	# Godot can retain UPDATE_ONCE in the scene property after the server consumes it.
	# Prove caching by hiding its source, then prove explicit refresh works.
	# Do not use modulate: the inherited paving shader explicitly overrides COLOR.
	var tiles: TileMapLayer=repair.get_node("SourcePaving16px")
	var cached_texture:=repair.get_texture().get_image()
	tiles.hide();await settle()
	result.source_change_without_refresh_pixels=changed(cached_texture,repair.get_texture().get_image())
	repair.render_target_update_mode=SubViewport.UPDATE_ONCE;await settle()
	result.explicit_refresh_changed_pixels=changed(cached_texture,repair.get_texture().get_image())
	tiles.show();repair.render_target_update_mode=SubViewport.UPDATE_ONCE;await settle()
	if result.always_vs_cached_changed_pixels!=0:result.failures.append("cache changes overview pixels")
	if result.source_change_without_refresh_pixels!=0:result.failures.append("cache unexpectedly rerendered changed source")
	if result.explicit_refresh_changed_pixels==0:result.failures.append("explicit refresh did not render changed source")
	var library: Node2D=app.objects.get_node("library");library.hide()
	repair.render_target_update_mode=SubViewport.UPDATE_ALWAYS;await settle();var hidden_always:=root.get_texture().get_image()
	repair.render_target_update_mode=SubViewport.UPDATE_ONCE;await settle();var hidden_cached:=root.get_texture().get_image()
	result.hidden_always_vs_cached_changed_pixels=changed(hidden_always,hidden_cached)
	if result.hidden_always_vs_cached_changed_pixels!=0:result.failures.append("cache changes hidden-library pixels")
	FileAccess.open(output.path_join("repair-performance.json"),FileAccess.WRITE).store_string(JSON.stringify(result,"\t"))
	print("BUCT_REPAIR_PERFORMANCE ",JSON.stringify(result))
	app.queue_free();await process_frame;quit(0 if result.failures.is_empty() else 1)
