extends SceneTree
## Exact #127 Haidian + bounded outdoor roads. Actor is never repositioned in the primary journey.
var checks := 0
var failures: Array[String] = []
var ticks := 0
var illegal := 0
var jumps := 0
var max_step := 0.0
var trace: Array = []
var arrivals: Array = []
var preview := ""
var start_usec := 0
var bad_edges: Array = []
func _init() -> void:call_deferred("run")
func check(value: bool,label: String) -> void:
	checks+=1;print("PASS " if value else "FAIL ",label)
	if not value:failures.append(label)
func frames(count: int) -> void:
	for i in range(count):await physics_frame
func sample(app: Node2D,before: Vector2) -> void:
	ticks+=1
	var p: Vector2=app.visitor.position
	var step: float=before.distance_to(p);max_step=maxf(max_step,step)
	if not app.is_walkable(p):illegal+=1
	if step>88.0/Engine.physics_ticks_per_second+0.06:jumps+=1
	trace.append([ticks,(Time.get_ticks_usec()-start_usec)/1000000.0,p.x,p.y])
func snapshot(app: Node2D,name: String,caption: String) -> void:
	if preview.is_empty():return
	app.current_path.clear();app.status.text=caption
	await frames(2);await RenderingServer.frame_post_draw
	check(root.get_texture().get_image().save_png(preview.path_join(name+".png"))==OK,"Actual scene preview saved: "+name)
func walk_to(app: Node2D,target: Vector2,label: String) -> void:
	var path: PackedVector2Array=app.grid.get_point_path(app.nearest_cell(app.visitor.position),app.nearest_cell(target))
	var clear:=not path.is_empty()
	for i in range(1,path.size()):
		var n:=maxi(1,ceili(path[i-1].distance_to(path[i])*4.0))
		for j in range(n+1):
			var q: Vector2=path[i-1].lerp(path[i],float(j)/n)
			if not app.is_walkable(q):
				clear=false;bad_edges.append({"journey":label,"a":[path[i-1].x,path[i-1].y],"b":[path[i].x,path[i].y],"probe":[q.x,q.y]})
	check(clear,"Native AStar sub-edges remain on paving: "+label)
	app.path_to(target)
	var count:=0;var stalled:=0
	while app.visitor.position.distance_to(target)>4.1 and count<1200:
		var before: Vector2=app.visitor.position
		await physics_frame;count+=1;sample(app,before)
		stalled=stalled+1 if before.distance_to(app.visitor.position)<0.001 else 0
		if stalled>90:break
	var arrived: bool=app.visitor.position.distance_to(target)<=4.1
	check(arrived,"Continuous 88px/s student arrives: "+label)
	arrivals.append({"label":label,"target":[target.x,target.y],"feet":[app.visitor.position.x,app.visitor.position.y],"tick":ticks,"arrived":arrived})
	app.current_path.clear()
func occupied(app: Node2D,p: Vector2) -> bool:
	var query:=PhysicsPointQueryParameters2D.new();query.position=p;query.collision_mask=1
	return not app.get_world_2d().direct_space_state.intersect_point(query).is_empty()
func collect_refs(node: Node,refs: Array[WeakRef]) -> void:
	refs.append(weakref(node))
	for child in node.get_children():collect_refs(child,refs)
func run() -> void:
	preview=OS.get_environment("BUCT_HAIDIAN_ROADS_PREVIEW")
	var app=load("res://campuses/buct_haidian/scenes/playable.tscn").instantiate();root.add_child(app);await frames(3)
	check(app.initialized,"Accepted Haidian scene initializes")
	if not app.initialized:app.queue_free();await frames(2);quit(1);return
	check(app.visitor.position==Vector2(963,297),"Primary journey starts at the real original north-entry spawn")
	check(app.visitor.speed==88.0 and app.visitor.get_node("FeetCollision").shape.radius==3.0 and app.visitor.character_visual.target_height==18.0,"Accepted shared student height, foot radius and speed retained")
	check(app.data.walkable_polygons.size()==30,"26 old and four clear-street polygons only")
	check(app.data.route_waypoints.size()==25 and app.data.landmarks.size()==3,"Original 25-point guide and three POIs retained")
	check(app.real_buildings.size()==1 and is_instance_valid(app.library_component) and app.library_component.body_passes.size()==3,"Accepted teaching and compact genuine Rongmao coexist")
	check(app.landmark_at(Vector2(650,310))=="main_building" and app.landmark_at(Vector2(520,400))=="library","Accepted teaching and Rongmao alpha identities retained")
	var join_clear:=true
	for i in range(33):join_clear=join_clear and app.is_walkable(Vector2(954,314+4.0*i/32.0))
	check(join_clear,"Previously failing native edge (954,314) to (954,318) is fully paved at radius 3")
	start_usec=Time.get_ticks_usec()
	await walk_to(app,Vector2(944,348),"street middle")
	await snapshot(app,"01-street-middle","北入口东侧街道 · 原图铺装中段")
	Input.action_press("buct_haidian_walk_right")
	for i in range(35):
		var before: Vector2=app.visitor.position;await physics_frame;sample(app,before)
	Input.action_release("buct_haidian_walk_right");await frames(2)
	check(app.visitor.position.x<956 and app.visitor.last_motion.length()<0.01,"Actual rightward input stops before the planted hall divider")
	await walk_to(app,Vector2(935,368),"clear south stop")
	await snapshot(app,"02-street-south-stop","北入口东侧街道 · 当前止于清晰铺装段")
	var before_stop: Vector2=app.visitor.position
	Input.action_press("buct_haidian_walk_down")
	for i in range(35):
		var before: Vector2=app.visitor.position;await physics_frame;sample(app,before)
	Input.action_release("buct_haidian_walk_down");await frames(2)
	check(app.visitor.position.y-before_stop.y<8.0,"Actual manual south input stops at the deferred foliage boundary")
	await walk_to(app,Vector2(963,297),"return along new street to original spawn")
	check(illegal==0,"All primary-journey feet remain on paving")
	check(jumps==0,"Primary journey has no relocation, teleport or overspeed")
	check(app.visited.is_empty(),"New free-walk stops do not create visits or extra POIs")
	for item in app.data.excluded_probe_points:check(not app.is_walkable(Vector2(item.position[0],item.position[1])),"Forbidden surface stays blocked: "+str(item.id))
	for item in app.data.occluders:
		if not str(item.id).begins_with("east_road_"):continue
		check(app.objects.get_node(str(item.id)).get_node_or_null("TrunkFeetCollision")==null,"Visual source foliage has no invented trunk collider: "+str(item.id))
	# A distinct original-guide journey uses the public guide reset after the continuous proof.
	app.start_guide();var guide_ticks:=0;var guide_illegal:=0
	while app.guide_active and guide_ticks<2500:
		await physics_frame;guide_ticks+=1
		if not app.is_walkable(app.visitor.position):guide_illegal+=1
	check(not app.guide_active and app.visited.size()==3 and app.info_id=="library" and app.visitor.position.distance_to(Vector2(551,481))<9,"Original guide still arrives at teaching and Rongmao with exactly three visits")
	check(guide_illegal==0,"Original guide has no invalid feet")
	check(app.library_component.selected,"Original library arrival still selects accepted Rongmao")
	var lib=app.library_component;var building=app.real_buildings.main_building
	check(lib.source_anchor==Vector2(517,473) and lib.image_scale==196.0/1115.0,"Rongmao accepted uniform raw-pixel transform remains exact")
	check(lib.hit_test_alpha(Vector2(520,400)) and not lib.hit_test_alpha(Vector2(410,480)),"Rongmao opaque selection and transparent-frame miss retained")
	check(occupied(app,Vector2(519,460)),"Rongmao solid foundation retains actual physics collider")
	app.close_info();check(not lib.selected and app.info_id.is_empty(),"Rongmao close clears selection")
	var library_pose: Transform2D=lib.transform;var ground_pose: Transform2D=app.generated_repair.transform
	app.active_building="main_building";app.toggle_real_visible();await frames(2)
	check(not building.body_enabled and building.physics_body.collision_layer==0 and not building.shadow_sprite.visible and not occupied(app,Vector2(650,320)),"Teaching hide removes its own body, shadow and actual collider")
	app.reset_real_buildings();app.toggle_real_moved();await frames(2)
	check(building.position==building.source_anchor+Vector2(35,-20) and lib.transform==library_pose and app.generated_repair.transform==ground_pose,"Teaching move preserves Rongmao and ground transforms")
	check(not occupied(app,Vector2(650,320)) and app.landmark_at(Vector2(685,290))=="main_building","Teaching move removes old collision and moves true-alpha picking")
	app.reset_real_buildings();await frames(2)
	check(building.transform==building.rest_transform and building.body_enabled and occupied(app,Vector2(650,320)),"Teaching reset restores accepted pose and actual collider")
	var refs: Array[WeakRef]=[];collect_refs(app,refs);app.queue_free();app=null;building=null;lib=null;await frames(3)
	var freed:=true
	for ref in refs:freed=freed and ref.get_ref()==null
	check(freed,"Full campus exit releases every descendant")
	for action in ["buct_haidian_walk_left","buct_haidian_walk_right","buct_haidian_walk_up","buct_haidian_walk_down","buct_haidian_walk_fast"]:check(not InputMap.has_action(action),"Owned movement input removed on exit: "+action)
	var report={"schema":"buct-haidian-east-roads-native-v1","checks":checks,"failures":failures,"continuous_ticks":ticks,"simulation_seconds":float(ticks)/Engine.physics_ticks_per_second,"trace_columns":["physics_tick","wall_seconds_since_start","foot_x","foot_y"],"trace":trace,"arrivals":arrivals,"bad_planned_edges":bad_edges,"illegal_feet":illegal,"teleports_or_overspeed":jumps,"max_step_px":max_step,"guide_ticks":guide_ticks,"guide_illegal":guide_illegal,"preview_directory":preview,"limits":"Only the clear north-entry street; removed hall crossing, deferred south continuation, court, roof, grass, enclosed apron, water and interiors stay blocked. Source is stylized game art, not surveyed public navigation."}
	var output:=OS.get_environment("BUCT_HAIDIAN_ROADS_REPORT")
	if not output.is_empty():
		var file:=FileAccess.open(output,FileAccess.WRITE)
		if file:file.store_string(JSON.stringify(report,"\t")+"\n")
	print("BUCT_HAIDIAN_EAST_ROADS ","PASS" if failures.is_empty() else "FAIL"," checks=",checks," ticks=",ticks," guide_ticks=",guide_ticks," illegal=",illegal," jumps=",jumps)
	quit(0 if failures.is_empty() else 1)
