extends SceneTree
## Actual OpenGL proof, run on a graphics display with isolated XDG directories.
## Output is a caller-selected private review directory, not a shipped runtime control.
var output := ""
var report := {"checks":[],"failures":[]}
var app
func _initialize() -> void: run.call_deferred()
func check(value: bool, message: String) -> void:
	report.checks.append({"check":message,"passed":value})
	if not value:report.failures.append(message);push_error(message)
func settle() -> void:
	await process_frame;await process_frame;await RenderingServer.frame_post_draw
func save_image(image: Image,name: String) -> void: image.save_png(output.path_join(name))
func diff_images(a: Image,b: Image,excluded:=Rect2i()) -> Dictionary:
	var changed := 0;var maximum := 0;var total := 0
	for y in range(a.get_height()):
		for x in range(a.get_width()):
			if excluded.has_point(Vector2i(x,y)):continue
			var ca:=a.get_pixel(x,y);var cb:=b.get_pixel(x,y)
			var d:=maxi(maxi(roundi(absf(ca.r-cb.r)*255),roundi(absf(ca.g-cb.g)*255)),roundi(absf(ca.b-cb.b)*255))
			if d>0:changed+=1
			maximum=maxi(maximum,d);total+=d
	return {"changed_pixels":changed,"max_channel_error":maximum,"sum_max_error":total}
func node_count(node: Node) -> int:
	var count:=1
	for child in node.get_children():count+=node_count(child)
	return count
func run() -> void:
	output=OS.get_environment("BUCT_CAPTURE_DIR")
	if output.is_empty():output=ProjectSettings.globalize_path("user://buct-library-review")
	DirAccess.make_dir_recursive_absolute(output)
	root.size=Vector2i(1440,900)
	report.adapter=RenderingServer.get_video_adapter_name();report.engine=Engine.get_version_info().string
	app=load("res://campuses/buct/scenes/playable.tscn").instantiate();root.add_child(app)
	await settle()
	app.toggle_overview();await settle();save_image(root.get_texture().get_image(),"full-campus-overview.png")
	# Whole-campus viewport frame cost after warm-up. llvmpipe is software OpenGL.
	var elapsed: Array[float]=[]
	var previous:=Time.get_ticks_usec()
	for i in range(90):
		await RenderingServer.frame_post_draw
		var now:=Time.get_ticks_usec();elapsed.append(float(now-previous)/1000.0);previous=now
	elapsed.sort()
	report.performance={"frame_ms_median":elapsed[45],"frame_ms_p95":elapsed[85],"process_ms":Performance.get_monitor(Performance.TIME_PROCESS)*1000,"draw_calls":Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME),"live_nodes":Performance.get_monitor(Performance.OBJECT_NODE_COUNT),"library_nodes":node_count(app.library),"old_library_nodes":12,"library_node_growth":node_count(app.library)-12,"native_strips":app.library.depth_columns.size(),"note":"Actual full-campus overview on reported adapter; not a hardware-performance guarantee."}
	app.toggle_overview();app.visitor.position=Vector2(755,590);app._process(0);app.camera.position=app._walking_camera_position();app.camera.reset_smoothing();await settle()
	save_image(root.get_texture().get_image(),"full-campus-library-closeup.png")
	app.show_landmark("library");await settle();save_image(root.get_texture().get_image(),"full-campus-library-info.png")
	app.toggle_library();await settle();save_image(root.get_texture().get_image(),"full-campus-library-hidden.png")
	app.reset_library();app.close_info();app.set_process(false);app.visitor.set_physics_process(false);app.visitor.hide()
	var renderer:=SubViewport.new();renderer.size=Vector2i(1448,1086);renderer.render_target_update_mode=SubViewport.UPDATE_ALWAYS;renderer.world_2d=World2D.new();root.add_child(renderer)
	app.world.reparent(renderer,true);await settle()
	var columns_image:=renderer.get_texture().get_image();save_image(columns_image,"full-world-native-strips.png")
	var source: Image=load("res://campuses/buct/assets/approved-chaoyang.png").get_image()
	if source.is_compressed():source.decompress()
	var outside:=diff_images(columns_image,source,Rect2i(620,410,251,169))
	report.outside_library_repair_vs_original=outside
	check(outside.changed_pixels==0,"All source pixels outside registered library repair remain unchanged")
	for strip in app.library.depth_columns:strip.hide()
	app.library.set_actor_foot(Vector2(750,100000));app.library.back_sprite.z_index=0;app.library.back_sprite.show();await settle()
	var full_image:=renderer.get_texture().get_image();save_image(full_image,"full-world-single-rgba-reference.png")
	var strip_diff:=diff_images(columns_image,full_image)
	report.strips_vs_same_rgba_full_reference=strip_diff
	check(strip_diff.max_channel_error<=1,"Shared-UV native strips match full RGBA within one 8-bit rounding level, no alpha gaps")
	app.library.back_sprite.hide()
	for strip in app.library.depth_columns:strip.show()
	await settle()
	var actor=app.visitor;actor.show()
	var depth_results:=[]
	for x in [638.0,665.0,730.0,790.0,849.0]:
		var y: float=app.library.depth_y_at_world_x(x)
		for front in [false,true]:
			actor.position=Vector2(x,y+(5.0 if front else -5.0));await settle()
			var actual:=renderer.get_texture().get_image()
			var head:=Vector2i(roundi(x),roundi(actor.position.y-13))
			var visible:=actual.get_pixelv(head)!=columns_image.get_pixelv(head)
			depth_results.append({"x":x,"foot_y":actor.position.y,"front":front,"head_visible":visible})
			check(visible==front,"Library native local facade depth x=%s front=%s"%[x,front])
			save_image(actual,"library-depth-x%d-%s.png"%[int(x),"front" if front else "behind"])
	report.library_depth_probes=depth_results
	var tree_results:=[]
	for pair in [[Vector2(720,686),Vector2(720,692),"promenade"],[Vector2(655,646),Vector2(655,652),"nearest_library_tree"]]:
		for i in range(2):
			actor.position=pair[i];await settle();var actual:=renderer.get_texture().get_image()
			var head:=Vector2i(roundi(actor.position.x),roundi(actor.position.y-13))
			var visible:=actual.get_pixelv(head)!=columns_image.get_pixelv(head)
			tree_results.append({"tree":pair[2],"front":i==1,"head_visible":visible})
			check(visible==(i==1),"Old native tree ordering preserved %s front=%s"%[pair[2],i==1])
			save_image(actual,"tree-%s-%s.png"%[pair[2],"front" if i==1 else "behind"])
	report.tree_depth_probes=tree_results
	actor.hide();app.library.set_body_visible(false);await settle();var hidden:=renderer.get_texture().get_image();save_image(hidden,"full-world-library-hidden.png")
	app.library.hide();await settle();var absent:=renderer.get_texture().get_image()
	var hide_diff:=diff_images(hidden,absent);report.hidden_vs_node_absent=hide_diff
	check(hide_diff.changed_pixels==0,"Full-campus hiding removes all new body and independent shadow pixels")
	var file:=FileAccess.open(output.path_join("fullmap-render-report.json"),FileAccess.WRITE);file.store_string(JSON.stringify(report,"\t"));file.close()
	app.queue_free();renderer.queue_free();await process_frame
	print("BUCT_LIBRARY_NATIVE_RENDER ","PASS" if report.failures.is_empty() else "FAIL"," ",JSON.stringify(report.performance)," failures=",report.failures)
	quit(0 if report.failures.is_empty() else 1)
