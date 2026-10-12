extends SceneTree
var output := ""
var rows: Array[Dictionary]=[]
var pose_results: Array[Dictionary]=[]
var failures: Array[String]=[]
func _initialize() -> void:run.call_deferred()
func frames(count:=3) -> void:
	for i in range(count):await RenderingServer.frame_post_draw
func expect(ok: bool,label: String) -> void:
	print("PASS " if ok else "FAIL ",label)
	if not ok:failures.append(label)
func capture(view: SubViewport,name: String) -> void:
	await frames()
	var picture:=view.get_texture().get_image();picture.save_png(output.path_join(name+".png"))
func cost(view: SubViewport) -> Dictionary:
	await frames(30)
	var times: Array[float]=[];var draws: Array[float]=[];var previous:=Time.get_ticks_usec()
	for i in range(120):
		await RenderingServer.frame_post_draw
		var now:=Time.get_ticks_usec();times.append(float(now-previous)/1000.0);previous=now
		draws.append(Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME))
	times.sort();draws.sort()
	return {"median_ms":times[60],"p95_ms":times[114],"median_draw_calls":draws[60],"p95_draw_calls":draws[114],"nodes":int(Performance.get_monitor(Performance.OBJECT_NODE_COUNT)),"texture_memory_bytes":int(Performance.get_monitor(Performance.RENDER_TEXTURE_MEM_USED)),"static_memory_bytes":int(Performance.get_monitor(Performance.MEMORY_STATIC)),"render_target":[view.size.x,view.size.y],"root_actual_size":[root.size.x,root.size.y],"samples":120}
func run() -> void:
	output=OS.get_environment("BUCT_RONGMAO_GPU")
	if output.is_empty():printerr("Workspace proof directory required");quit(2);return
	DirAccess.make_dir_recursive_absolute(output)
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED);Engine.max_fps=0
	var state: Node=root.get_node("State");var before: Dictionary=state.d.duplicate(true)
	var base_script: GDScript=load("res://tests/fixtures/rongmao-base-playable.gd")
	for mode in ["baseline_before","rongmao","baseline_after"]:
		var app: Node2D=base_script.new() if mode!="rongmao" else load("res://campuses/buct_haidian/scenes/playable.tscn").instantiate()
		root.add_child(app);await process_frame;await frames()
		expect(app.initialized,"Full #126 source campus initialized "+mode)
		if not app.initialized:app.queue_free();await process_frame;quit(1);return
		app.set_process(false);app.ui.hide();app.pin_layer.hide();app.camera.enabled=false;app.canopy_locator.hide();app.visitor.set_physics_process(false);app.visitor.hide();app.route_visual.hide()
		var view:=SubViewport.new();view.size=Vector2i(1280,800);view.render_target_update_mode=SubViewport.UPDATE_ALWAYS;root.add_child(view)
		var campus: Node2D=app.world;app.remove_child(campus);view.add_child(campus)
		var camera:=Camera2D.new();camera.position=Vector2(724,543);camera.zoom=Vector2(.69,.69);view.add_child(camera);camera.make_current()
		campus.get_node("GroundRepairTiles").render_target_update_mode=SubViewport.UPDATE_ONCE
		if mode=="rongmao":app.library_component.update_actor_foot(297.0,true)
		var row:=await cost(view);row.mode=mode
		if mode=="rongmao":
			row.library_component=app.library_component.get_diagnostics()
			row.ground_texture_imported_size=app.generated_repair.get_node("Rongmao141PixelGroundRepair").texture.get_size()
		rows.append(row)
		await capture(view,mode+"-overview")
		# Exact native source coordinates, independent of desktop window clamping.
		view.size=Vector2i(1448,1086);camera.enabled=false;await capture(view,mode+"-source")
		if mode=="rongmao":
			view.size=Vector2i(640,640);camera.enabled=true;camera.position=Vector2(520,375);camera.zoom=Vector2(2.1,2.1)
			await capture(view,"rongmao-close-normal")
			var lib: Node2D=app.library_component
			for item in [["east_front",Vector2(550,428)],["east_behind_probe",Vector2(550,408)],["tree_behind",Vector2(540,456)],["tree_front",Vector2(540,472)],["route_arrival",Vector2(551,481)]]:
				app.visitor.position=item[1];app.visitor.show();lib.update_actor_foot(item[1].y,true)
				app.visitor.character_visual.reset_pose()
				var walkable: bool=app.is_walkable(item[1])
				pose_results.append({"id":item[0],"feet":[item[1].x,item[1].y],"actually_walkable":walkable,"qualification":"Geometric occlusion probe only when not walkable"})
				await capture(view,"rongmao-"+item[0])
			app.visitor.hide()
			var opaque:=Vector2(520,400);var blank:=Vector2(410,480)
			expect(lib.hit_test_alpha(opaque) and not lib.hit_test_alpha(blank),"Actual loaded full-map texture alpha picking")
			app.show_landmark("library");expect(lib.selected and app.info_id=="library","Library information owner and selection")
			app.close_info();expect(not lib.selected,"Library info return clears selection")
			var diagnostic: Dictionary=lib.get_diagnostics()
			expect(int(diagnostic.body_passes_allocated)==3,"Only three exact foot passes; no campus-wide threshold list")
		campus.queue_free();app.queue_free();view.queue_free();await process_frame;await process_frame;await frames(5)
	expect(state.d==before,"Original story state unchanged by all map proof phases")
	var result: Dictionary={"status":"CAPTURED_FOR_PIXEL_REVIEW","failures":failures,"adapter":RenderingServer.get_video_adapter_name(),"engine":Engine.get_version_info().string,"camera_position":[724,543],"camera_zoom":[.69,.69],"cost_rows":rows,"poses":pose_results,"qualification":"Same fixed1280x800 viewport, hiddenUI/player, cached source ground, #126 baseline→Rongmao→baseline. Core pixels/protected regions reviewed independently. No whole-building hide/move demonstrated."}
	var file:=FileAccess.open(output.path_join("capture-and-cost.json"),FileAccess.WRITE);file.store_string(JSON.stringify(result,"  "));file.close()
	print("RONGMAO_FULLMAP_CAPTURE_COMPLETE ",JSON.stringify(result))
	quit(0 if failures.is_empty() else 1)
