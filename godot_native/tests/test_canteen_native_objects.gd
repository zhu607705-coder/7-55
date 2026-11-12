extends SceneTree
const Fixture=preload("res://tests/canteen_native_fixture.gd")
const Metrics=preload("res://scripts/player_metrics.gd")
var checks:=0
var failures:=0
var route_records:Array=[]
func check(ok:bool,label:String)->void:
	checks+=1
	if not ok:failures+=1;push_error(label)
func _initialize()->void:call_deferred("run")
func pose(world:Control,point:Vector2)->void:
	world.player=point;world._sync_player();world.camera=Vector2(836,470.5);world.zoom=.7;world.transition_alpha=0
	world.native_canteen.configure_view(world.size/2-world.camera*world.zoom,world.zoom,world.player)
func walk(world:Control,direction:Vector2,frames:int)->bool:
	world.touch_axis=direction
	var legal:=true
	for frame:int in frames:
		world._process(.05)
		legal=legal and world.can_stand(world.player)
	world.touch_axis=Vector2.ZERO
	return legal
func opaque_point(world:Control,id:String)->Vector2:
	var geometry:Dictionary=world.native_canteen.target_geometry(id)
	if geometry.is_empty():return Vector2.INF
	var bounds:Rect2=geometry.get("rect",Rect2())
	var transform:Transform2D=geometry.get("transform",Transform2D.IDENTITY)
	for y in range(1,10):
		for x in range(1,10):
			var p:Vector2=transform*(bounds.position+bounds.size*Vector2(x/10.0,y/10.0))
			if world._pick_target(p).get("id","")==id:return p
	return Vector2.INF
func run()->void:
	var state:Node=root.get_node("State");Fixture.install(state)
	var world:Control=load("res://scripts/world.gd").new();world.size=Vector2(1280,800);root.add_child(world);await process_frame;world.set_process(false)
	pose(world,Vector2(1194,834));var scene:Node2D=world.native_canteen
	var base:Image=scene.textures.empty_floor.get_image()
	var visible_floor:Image=scene.floor_sprite.texture.get_image()
	check(scene.is_active() and visible_floor.get_size()==base.get_size() and visible_floor.get_pixel(1342,450)==base.get_pixel(1342,450),"the composite retains the supplied floor outside the repairs")
	check(base.get_pixel(1265,925).a>.5 and visible_floor.get_pixel(1265,925).a==0.0 and visible_floor.get_pixel(1426,925).a==0.0,"the floor edge erases both retired pillar silhouettes")
	var paper_exit: Dictionary=scene.layout.side_exit.paperExitPoint
	check(visible_floor.get_pixel(paper_exit.x,paper_exit.y)==scene.floor_pixels.get_pixel(paper_exit.x,paper_exit.y) and visible_floor.get_pixel(paper_exit.x,paper_exit.y).a>.5,"the rendered landing shares the physics plate")
	var joined_edge:=true
	for x in range(75,1644):
		joined_edge=joined_edge and visible_floor.get_pixel(x,923).a>.5
	check(joined_edge,"the visible southern edge continues between both side walls and across the sill")
	check(scene.floor_sprite.z_index>=0,"floor stays above the opaque World canvas background")
	check(scene.objects.size()>100 and scene.objects.dining_1_1_table.parts.size()>=2,"table/bench furniture has independent native roots and grounded surface pieces")
	check(scene.dynamic_collisions.size()==13,"original light queue and return-worker thirteen foot solids are preserved")
	check(world.can_stand(Vector2(1194,834)),"original entrance spawn is physically clear")
	for point:Vector2 in [Vector2(1473,208),Vector2(1320,400),Vector2(1470,576),Vector2(260,870),Vector2(755,250),Vector2(1349,835)]:check(world.can_stand(point),"authored task approach has a visible clear foot position "+str(point))
	check(not scene.objects.has("decorative_cart_2") and not scene.objects.has("decorative_cart_3"),"both decorative carts are removed from the lower aisles")
	check(world.can_stand(Metrics.anchor_from_foot_center(Vector2(1176,697))) and world.can_stand(Metrics.anchor_from_foot_center(Vector2(1082,900))),"both former cart footprints are walkable")
	for point: Vector2 in [Vector2(558,700),Vector2(558,850),Vector2(1080,850),Vector2(1268,642),Vector2(1274,738)]:
		check(world.can_stand(Metrics.anchor_from_foot_center(point)),"the former divider's restored floor is walkable at "+str(point))
	check(not world.can_stand(Metrics.anchor_from_foot_center(Vector2(1040,833))),"the hot counter's existing base still blocks feet")
	pose(world,Vector2(1133,864))
	var south_clear:=walk(world,Vector2.DOWN,12)
	var edge:Vector2=world.player
	check(south_clear and absf(Metrics.foot_rect(edge,"canteen_interior").end.y-916.0)<.1,"moving south stops with the whole foot box just inside the continuous rim")
	check(walk(world,Vector2.LEFT,20) and world.player.x<1050 and is_equal_approx(world.player.y,edge.y),"player can move left past the cart's old position after reaching the lower edge")
	check(walk(world,Vector2.RIGHT,20) and world.player.is_equal_approx(edge),"player can walk back along the same lower edge")
	var shelf_west:=Metrics.anchor_from_foot_center(Vector2(1400,251))
	var shelf_east:=Metrics.anchor_from_foot_center(Vector2(1560,251))
	world._floor_bounds=Rect2(Vector2.ZERO,world.world_size)
	check(world._floor_segment_clear(shelf_west,shelf_east),"the removed rear shelf bar leaves a clear walking route for the full foot box")
	pose(world,shelf_west)
	check(walk(world,Vector2.RIGHT,20) and world.player.x>1540,"directional movement passes through the restored rear shelf aisle")
	check(walk(world,Vector2.LEFT,20) and world.player.is_equal_approx(shelf_west),"player can return along the rear shelf aisle")
	pose(world,Vector2(1194,834))
	var prop:Node2D=scene.objects.dining_1_1_table
	check(prop.blocks_feet(Rect2(prop.base_position+Vector2(-4,-22),Vector2(8,8))),"table's real base blocks feet")
	check(not prop.blocks_feet(Rect2(prop.base_position+Vector2(70,-22),Vector2(8,8))),"side aisle is not an invisible furniture rectangle")
	for id:String in ["drink-machine-sparkling","drink-machine-lemon","drink-machine-coffee","drink-bottle-shelf","canteen-mixer","queue-column-three-front"]:
		check(opaque_point(world,id).is_finite(),"visible original target has a reachable alpha pick: "+id)
	var machine:Node2D=scene.objects.drink_machine_sparkling;var geo:Dictionary=machine.geometry();var transparent:=false
	for yy in range(5):
		for xx in range(5):
			var p:Vector2=geo.rect.position+Vector2(xx*.3,yy*.3)
			if not world.object_picker.contains(geo,p):transparent=true
	check(transparent,"transparent padded sprite corners are not rectangular click targets")
	state.d.native.mode="dark";world.refresh_world();pose(world,Vector2(1194,834))
	check(scene.dynamic_collisions.is_empty(),"dark observation uses original non-collidable light NPC rule")
	check(scene.entities.tray_blue_01.texture.resource_path.ends_with("tray_dirty.svg"),"original blue-tray observation artwork/meaning survives replacement")
	Fixture.install(state,"menu_order");world.world_key="";world.refresh_world();pose(world,Vector2(755,250))
	check(opaque_point(world,"ordering_kiosk").is_finite(),"third-window menu target belongs to the separate terminal")
	state.d.canteenHunt.phase="pickup_search";state.d.canteenHunt.orderedMenuOption="D";state.d.items.pickupTicket0755=true;world.refresh_world();pose(world,Vector2(755,250))
	check(world._pick_target(Vector2(835,218),true).get("id","")=="pickup_window_3","0755 slot is a visible target alongside the third terminal")
	check(world._pick_target(Vector2(346,218),true).get("id","")=="pickup_window_1","wrong-window ticket attempt remains physically selectable")
	var stable:Dictionary=state.d.duplicate(true)
	world.scene_id="campus_bootstrap";scene.sync(state.d,"campus_bootstrap")
	var retired:=true
	for object:Node2D in scene.objects.values():
		if object.body!=null:retired=retired and object.body.collision_layer==0
	for row:Dictionary in scene.structures:retired=retired and row.body.collision_layer==0
	check(not scene.visible and retired,"leaving canteen retires every static body")
	state.d=stable.duplicate(true);world.scene_id="canteen_interior";scene.sync(state.d,"canteen_interior");pose(world,Vector2(755,250))
	check(scene.is_active() and scene.return_age>1,"ordinary dictionary reload restores scene without replaying tray return")
	# Actual World planner with its unchanged corner/edge limits. Fixture positions,
	# source-coordinate taps and simulated frames are reported as controlled tests.
	Fixture.install(state);world.world_key="";world.refresh_world();world.mobile_exploration=true;world.size=Vector2(1280,1000)
	for pair:Array in [[Vector2(1194,834),Vector2(1470,576)],[Vector2(1470,576),Vector2(1473,208)],[Vector2(1473,208),Vector2(755,250)],[Vector2(755,250),Vector2(260,870)],[Vector2(260,870),Vector2(1349,730)]]:
		pose(world,pair[0]);world._floor_route.clear();world._floor_status="";world._floor_goal=Vector2.INF;world._update_camera()
		scene.configure_view(world.size/2-world.camera*world.zoom,world.zoom,world.player)
		var pixel:Vector2=(pair[1]+Metrics.FOOT_CENTER_OFFSET-world.camera)*world.zoom+world.size/2
		var start_us:=Time.get_ticks_usec();world._mobile_floor_tap(pixel);var elapsed_us:=Time.get_ticks_usec()-start_us
		var success:bool=not world._floor_route.is_empty()
		check(success,"actual floor tap plans task route "+str(pair[0])+" to "+str(pair[1]))
		var waypoints:String=str(world._floor_route)
		var legal:=true
		for frame in range(1800):
			if world._floor_route.is_empty():break
			world._process(1.0/60.0);legal=legal and world.can_stand(world.player)
		check(not success or (world._floor_status=="arrived" and legal),"planned route reaches task without crossing a visible foot obstacle")
		route_records.append({"start":str(pair[0]),"goal":str(pair[1]),"planned":success,"status":world._floor_status,"waypoints":waypoints,"planning_us":elapsed_us,"edge_checks":world._floor_planner.edge_checks,"corners":world._floor_planner.corner_count,"obstacles":world._floor_obstacles().size(),"bounds":str(world._floor_bounds)})
	var out:=OS.get_environment("CANTEEN_NATIVE_REPORT")
	if not out.is_empty():
		var file:=FileAccess.open(out,FileAccess.WRITE);file.store_string(JSON.stringify({"checks":checks,"failures":failures,"routes":route_records,"fixture":true},"\t"));file.close()
	print("CANTEEN_NATIVE_OBJECTS ",checks," checks; ",failures," failures")
	world.queue_free();await process_frame;quit(1 if failures else 0)
