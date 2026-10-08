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
	check(scene.is_active() and scene.floor_sprite.texture.resource_path.ends_with("canteen_empty_floor.png"),"the visible base is the supplied empty floor")
	check(scene.floor_sprite.z_index>=0,"floor stays above the opaque World canvas background")
	check(scene.objects.size()>100 and scene.objects.dining_1_1_table.parts.size()==2,"table/bench furniture has independent native roots and front strips")
	check(scene.dynamic_collisions.size()==13,"original light queue and return-worker thirteen foot solids are preserved")
	check(world.can_stand(Vector2(1194,834)),"original entrance spawn is physically clear")
	for point:Vector2 in [Vector2(1473,208),Vector2(1320,400),Vector2(1470,576),Vector2(260,870),Vector2(755,250),Vector2(1349,835)]:check(world.can_stand(point),"authored task approach has a visible clear foot position "+str(point))
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
