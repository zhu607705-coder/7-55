extends SceneTree
var failures: Array[String]=[]
var checks := 0
func verify(value: bool,message: String) -> void:
	checks+=1
	print("PASS " if value else "FAIL ",message)
	if not value:failures.append(message)
func _init() -> void:
	call_deferred("run_tests")
func frames(count: int) -> void:
	for i in range(count):await physics_frame
func run_tests() -> void:
	var app: Node2D=load("res://campuses/buct/scenes/playable.tscn").instantiate()
	root.add_child(app)
	await frames(3)
	verify(app.world.get_node("GroundRepairTiles").render_target_update_mode in [SubViewport.UPDATE_ONCE,SubViewport.UPDATE_DISABLED],"Playable schedules static repair texture once per scene, retaining cached underlay")
	verify(app.objects.get_node("main_building") is Node2D,"Registered main building remains an individual native object")
	verify(app.visitor is CharacterBody2D,"Visitor movement uses native CharacterBody2D")
	verify(app.visitor.get_node("FeetCollision").shape.radius==3.0,"Collision is a 3px foot circle, not the tall sprite")
	verify(app.camera is Camera2D,"Exploration has a native follow camera")
	verify(app.landmark_at(Vector2(750,750))=="main_building","Clicking the actual main-building silhouette resolves its info")
	verify(app.objects.get_node("main_building/CentralFacadeDepth").global_position.y==807.0,"Main central facade uses its own base depth rather than the long wings")
	verify(app.world.get_node("StaticSourceGroundShadows").get_child_count()==9,"Nine remaining original shadows plus one independent genuine-library shadow")
	verify(app.library.shadow_sprite is Sprite2D and app.library.shadow_sprite.z_index<0,"Library shadow is independent alpha below native actors")
	verify(app.world.has_node("StaticSourceGroundShadows"),"Ground shadows are kept behind the visitor, not treated as solid occluders")
	verify(app.is_walkable(app.visitor.position),"South-gate spawn is inside the walkable paved corridor")
	verify(app.data.occluders.size()==10,"Route has separately depth-sorted original tree canopies")
	var tree_uv_ok:=true
	for item in app.data.occluders:
		var tree=app.objects.get_node(item.id)
		var canopy: Polygon2D=tree.get_node("OriginalCanopyOccluder")
		for i in range(canopy.polygon.size()):tree_uv_ok=tree_uv_ok and canopy.polygon[i]+tree.position==canopy.uv[i]
	verify(tree_uv_ok,"Every tree canopy uses unchanged source-pixel UVs")
	verify(app.objects.y_sort_enabled,"Buildings, canopies and visitor share native feet-depth sorting")
	verify(app.is_walkable(Vector2(720,686)) and app.is_walkable(Vector2(720,692)),"Occlusion regression poses are valid walkable feet locations")
	app.visitor.position=Vector2(720,686);await frames(2);app._process(0)
	verify(app.visitor_head_occluded() and app.visitor.get_node("CanopyFootLocator").visible,"Under-canopy visitor has a small above-canopy feet locator")
	app.visitor.position=Vector2(720,692);await frames(2);app._process(0)
	verify(not app.visitor_head_occluded() and not app.visitor.get_node("CanopyFootLocator").visible,"Locator disappears in front of the same canopy")
	verify(app.is_head_under_canopy(Vector2(548.447265625,706.296447753906)),"Recorded west-garden foliage crossing covers the avatar head")
	verify(app.is_head_under_canopy(Vector2(649.92578125,696.390686035156)),"Recorded rear-promenade crossing covers the avatar head")
	verify(not app.is_head_under_canopy(Vector2(674.0,615.379089355469)),"Library route preserves the visible gap between real crowns")
	verify(Geometry2D.is_point_in_polygon(Vector2(670,601),app.pts(app.data.occluders[7].polygon)),"Library foliage covers only the original left hair/shoulder edge")
	app.return_to_gate()
	for i in range(app.data.route_waypoints.size()):
		var p:=Vector2(app.data.route_waypoints[i][0],app.data.route_waypoints[i][1])
		var from: Vector2=app.visitor.position if i==0 else Vector2(app.data.route_waypoints[i-1][0],app.data.route_waypoints[i-1][1])
		var path: PackedVector2Array=app.grid.get_point_path(app.nearest_cell(from),app.nearest_cell(p))
		verify(not path.is_empty(),"Native navigation connects route stop %d"%i)
		var clear:=true
		for point in path:clear=clear and app.is_walkable(point)
		verify(clear,"Route segment %d stays on paving outside inflated building footprints"%i)
	var start: Vector2=app.visitor.position
	Input.action_press("buct_walk_up")
	await frames(18)
	Input.action_release("buct_walk_up")
	verify(app.visitor.position.distance_to(start)>3.0,"Actual held keyboard action moves visitor through the south gate")
	verify(app.is_walkable(app.visitor.position),"Manual movement remains inside the playable region")
	app.return_to_gate()
	verify(app.visitor.position==Vector2(app.data.spawn[0],app.data.spawn[1]),"Return-to-gate clears movement and restores safe spawn")
	app.show_landmark("main_building")
	verify(app.info_panel.visible and app.movement_paused(),"Landmark panel opens and pauses manual walking")
	Input.action_press("buct_walk_up");await frames(6);Input.action_release("buct_walk_up")
	verify(app.visitor.position==Vector2(app.data.spawn[0],app.data.spawn[1]),"Open information panel does not leak movement input")
	app.close_info()
	verify(not app.info_panel.visible and not app.movement_paused(),"Return from landmark restores the map")
	var click:=InputEventMouseButton.new()
	click.button_index=MOUSE_BUTTON_LEFT;click.pressed=true
	click.position=app.get_canvas_transform()*Vector2(750,750)
	app._unhandled_input(click)
	verify(app.info_id=="main_building","Building clicks use event coordinates, independent of stale desktop pointer state")
	app.close_info()
	app.show_landmark("main_building");app.show_landmark("main_building");app.close_info()
	verify(app.visited.count("main_building")==1,"Repeated landmark interactions do not duplicate progress")
	app.toggle_overview();await frames(5)
	verify(app.overview and app.movement_paused(),"Overview intentionally pauses walking")
	app.camera.force_update_scroll()
	var screen_transform: Transform2D=app.world.get_global_transform_with_canvas()
	var northwest: Vector2=screen_transform*Vector2.ZERO
	var southeast: Vector2=screen_transform*Vector2(1448,1086)
	verify(app.map_area.grow(1).has_point(northwest) and app.map_area.grow(1).has_point(southeast),"Whole source image fits between interface bars in overview")
	app.toggle_overview()
	verify(not app.overview and not app.movement_paused(),"Returning from overview resumes exploration")
	app.visitor.position=Vector2(750,827)
	await frames(3)
	verify(app.visitor.test_move(app.visitor.global_transform,Vector2(0,-35)),"The main facade physically blocks the foot collider")
	app.visitor.position=Vector2(712,697)
	await frames(2)
	verify(app.visitor.test_move(app.visitor.global_transform,Vector2(0,-7)),"A small tree trunk physically blocks feet")
	app.visitor.position=Vector2(720,686)
	await frames(2)
	verify(not app.visitor.test_move(app.visitor.global_transform,Vector2(0,6)),"The canopy is not a wall: feet can pass beneath it beside the trunk")
	app.return_to_gate()
	app.start_guide();await frames(10)
	Input.action_press("buct_walk_left");await frames(3);Input.action_release("buct_walk_left")
	# A guide stop can pause briefly; finish that stop before checking takeover.
	if app.guide_active:
		await frames(60);Input.action_press("buct_walk_left");await frames(3);Input.action_release("buct_walk_left")
	verify(not app.guide_active,"Keyboard input can interrupt guided walking")
	app.start_guide();Input.action_press("buct_walk_left")
	app._notification(Node.NOTIFICATION_APPLICATION_FOCUS_OUT)
	verify(not Input.is_action_pressed("buct_walk_left") and not app.guide_active and app.current_path.is_empty(),"Focus loss releases owned movement and safely stops navigation")
	app.return_to_gate();app.visited.clear();app.start_guide()
	var violations:=0
	var ticks:=0
	while app.guide_active and ticks<2400:
		await physics_frame
		ticks+=1
		if not app.is_walkable(app.visitor.position):violations+=1
	verify(not app.guide_active,"Whole guided walk completes without teleporting or timing out")
	verify(violations==0,"Every guided physics position remains on allowed paving")
	verify(app.visited.size()==3,"South gate, main building and library are visited")
	var last=app.data.route_waypoints[-1]
	verify(app.visitor.position.distance_to(Vector2(last[0],last[1]))<9.0,"Actual visitor feet arrive at the library route endpoint")
	verify(app.info_id=="library","Library arrival displays the final landmark card")
	app.close_info()
	verify(app.landmark_at(Vector2(750,500))=="library","Full campus library uses genuine-alpha hit test")
	verify(app.landmark_at(Vector2(622,420)).is_empty(),"Library transparent corner rejects old silhouette selection")
	verify(not app.landmark_hit_polys.has("library"),"Legacy library click polygon retired")
	var navigation_probe:=Vector2(746,590)
	verify(app.is_walkable(navigation_probe),"Library approach is open at original registration")
	app.library.position+=Vector2(0,30)
	verify(not app.is_walkable(navigation_probe),"New library footprint follows object transform in world-space walkability")
	app.show_landmark("library");app.toggle_library()
	verify(app.is_walkable(navigation_probe),"Hiding replacement retires its navigation blockers, including after movement")
	verify(not app.library.body_enabled and app.library.physics_body.collision_layer==0,"Full-campus hide disables the genuine library physics")
	verify(app.landmark_at(Vector2(750,500)).is_empty(),"Hidden library no longer intercepts map clicks")
	verify(app.world.get_node("LibraryContinuousGround").visible,"Full-campus hide preserves registered continuous ground")
	verify(app.library_blockers.size()==6,"Navigation uses six new inferred native footprint regions, not four stale outlines")
	app.reset_library();app.close_info()
	verify(app.status.text=="图书馆楼体已复位","Reset refreshes status after hidden-body information")
	verify(app.library.body_enabled and app.library.position==Vector2(749,570),"Full-campus library reset restores native body at source coordinate")
	app.return_to_gate();app.return_to_gate()
	verify(app.current_path.is_empty() and not app.guide_active and app.info_id.is_empty(),"Repeated reset leaves no queued path, guide or overlay")
	print("PLAYABLE_TESTS ","PASS" if failures.is_empty() else "FAIL"," checks=",checks," failures=",failures.size()," guide_physics_ticks=",ticks)
	var shadow_refs: Array[WeakRef]=[]
	var names: Array[String]=[]
	for shadow: Node in app.world.get_node("StaticSourceGroundShadows").get_children():
		shadow_refs.append(weakref(shadow));names.append(str(shadow.name))
	verify(names.all(func(value: String):return not value.begins_with("@") and names.count(value)==1),"Reparented shadows have stable unique names")
	app.queue_free();await process_frame
	verify(shadow_refs.all(func(value: WeakRef):return value.get_ref()==null),"Every reparented shadow frees with the campus")
	print("BUCT_PLAYABLE_FINAL ","PASS" if failures.is_empty() else "FAIL"," checks=",checks," failures=",failures.size())
	quit(0 if failures.is_empty() else 1)
