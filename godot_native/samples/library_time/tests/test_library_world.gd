extends SceneTree
const Scene = preload("res://scenes/library_time.tscn")
var failures := 0
func _initialize() -> void: call_deferred("run")
func check(value: bool, label: String) -> void:
	if not value: failures+=1; push_error("TEST FAILED: "+label)
	else: print("PASS ",label)
func run() -> void:
	root.size=Vector2i(390,844); var view := Scene.instantiate(); root.add_child(view)
	await process_frame; await physics_frame; await physics_frame
	check(view.current_viewport.find_world_3d()!=view.history_viewports[0].find_world_3d(),"current and past have independent World3D")
	check(view.history_viewports[0].find_world_3d()!=view.history_viewports[1].find_world_3d(),"historical snapshots cannot share collisions")
	for index: int in range(2):
		var world=view.history_worlds[index]
		print("WORLD ",index," top=",world.visible_from_camera(world.glyph_point(true))," bottom=",world.visible_from_camera(world.glyph_point(false))," anchor=",world.visible_from_camera(world.REFERENCE)," topxy=",world.screen_point(world.glyph_point(true))," bottomxy=",world.screen_point(world.glyph_point(false))," anchorxy=",world.screen_point(world.REFERENCE))
		for probe: Vector3 in world.fragment_probes(index==0):
			print("PROBE ",index," ",probe," ",world.visible_from_camera(probe))
			check(world.visible_from_camera(probe),"whole exposed fragment and reference visible along actual orthographic ray")
		check(world.visible_from_camera(world.glyph_point(index==0)),"snapshot exposes its own clue fragment")
		check(not world.visible_from_camera(world.glyph_point(index!=0)),"physical occluder hides other clue fragment")
		check(world.visible_from_camera(world.REFERENCE),"fixed brass shelf corner stays visible")
		var before: Vector3=world.books[4].position; world.update_current(4,1,true,1)
		check(world.books[4].position==before,"history update cannot pull or take books")
	for id: int in range(6): print("BOOK ",id," p=",view.book_point(id)," visible=",view.book_visible(id))
	var top_candidates := 0; var bottom_candidates := 0; var pair_candidates := 0
	var target: Node3D=view.current_world.books[4]
	var target_color: Color=target.get_node("ClothCover").material_override.albedo_color
	for id: int in range(6):
		var candidate: Node3D=view.current_world.books[id]
		var upper: bool=candidate.get_meta("upper_mark")==target.get_meta("upper_mark")
		var lower: bool=candidate.get_meta("lower_bars")==target.get_meta("lower_bars")
		if upper: top_candidates+=1
		if lower: bottom_candidates+=1
		if upper and lower: pair_candidates+=1
		check(candidate.get_node("ClothCover").material_override.albedo_color==target_color,"cover color cannot reveal the hidden upper mark")
	check(top_candidates==3 and bottom_candidates==2 and pair_candidates==1,"each fragment has decoys; only the complete pair identifies one book")
	check(not view.model.completed,"idle presentation cannot complete retrieval")
	print("LIBRARY_WORLD failures=",failures)
	view.queue_free(); await process_frame; quit(1 if failures else 0)
