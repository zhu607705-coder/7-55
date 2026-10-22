extends SceneTree
const Fixture=preload("res://tests/canteen_native_fixture.gd")
const TrayFrames=preload("res://scripts/presentation/c3_tray_frames.gd")
var checks:=0
var failures:=0
var records:Array=[]
func check(ok:bool,label:String)->void:
	checks+=1
	if not ok:failures+=1;push_error(label)
func _initialize()->void:call_deferred("run")
func sample(world:Control,ms:float)->Dictionary:
	world.chapter3_layers.pickup_ms=ms
	world.native_canteen.configure_view(world.size/2-world.camera*world.zoom,world.zoom,world.player)
	for id:String in ["tray_pickup","carried_tray"]:
		var sprite:Sprite2D=world.native_canteen.entities.get(id)
		if is_instance_valid(sprite) and sprite.visible:return {"id":id,"position":sprite.position,"rotation":sprite.rotation,"scale":sprite.scale,"source":sprite.region_rect,"texture":sprite.texture.resource_path}
	return {}
func verify_depth_handover(world:Control,state:Node,reduced:bool,point:Vector2,tray_at:Vector2)->void:
	Fixture.install(state);state.d.native.settings.reduced_motion=reduced
	world.world_key="";world.refresh_world();world.player=point;world._sync_player()
	var scene:Node2D=world.native_canteen
	scene.configure_view(Vector2.ZERO,1,point)
	check(world.can_stand(point),"pickup depth regression starts in a legal aisle "+str(point))
	var tray:Dictionary={}
	for target:Dictionary in world.targets:
		if str(target.id).begins_with("tray_") and Vector2(target.position[0],target.position[1])==tray_at:tray=target;break
	check(not tray.is_empty(),"authored pickup slot exists "+str(tray_at))
	if tray.is_empty():return
	var resting_depth:float=scene.entities[str(tray.id)].get_meta("source_depth")
	state.act(str(tray.action));scene.sync(state.d,"canteen_interior")
	check(state.d.canteenHunt.carriedTrayIds.has(tray.id),"controller accepts side/rear pickup without changing reachability")
	var duration:float=TrayFrames.pickup_duration_ms(reduced)
	for progress:float in [0.0,.08,.18,.30,.50,.82,1.0]:
		var pose:Dictionary=sample(world,duration*progress)
		check(not pose.is_empty(),"pickup/held pose exists throughout side/rear flight")
		if pose.is_empty():continue
		var node:Sprite2D=scene.entities[pose.id]
		if progress==0:check(is_equal_approx(float(node.get_meta("source_depth")),resting_depth),"flight begins at the resting support depth")
		var overlaps:=0;var hidden:=0
		for prop:Node2D in scene.objects.values():
			for surface:Dictionary in prop.surfaces():
				if not world.object_picker.contains(surface.geometry,pose.position):continue
				overlaps+=1
				if surface.canvas_z>node.z_index or (surface.canvas_z==node.z_index and surface.root_order>node.get_index()):hidden+=1
		check(hidden==0,"opaque furniture cannot hide the tray center during reachable flight p="+str(progress)+" from "+str(point))
		if progress==0:check(overlaps>0,"first-frame visibility assertion actually overlaps the supporting tabletop")
func run()->void:
	var state:Node=root.get_node("State");Fixture.install(state)
	var world:Control=load("res://scripts/world.gd").new();world.size=Vector2(390,628);root.add_child(world);await process_frame;world.set_process(false)
	for reduced:bool in [false,true]:
		Fixture.install(state);state.d.native.settings.reduced_motion=reduced
		world.world_key="";world.refresh_world()
		var tray:Dictionary={}
		for target:Dictionary in world.targets:
			if str(target.id).begins_with("tray_"):tray=target;break
		check(not tray.is_empty(),"original source tray target exists")
		world.player=Vector2(tray.position[0],tray.position[1])+Vector2(0,30);world._sync_player()
		state.act(str(tray.action));world.native_canteen.sync(state.d,"canteen_interior")
		check(state.d.canteenHunt.carriedTrayIds.has(tray.id),"original action accepts fixture-near tray")
		var duration:float=100 if reduced else 360
		var first:=sample(world,0);var middle:=sample(world,duration/2);var near_end:=sample(world,duration-.1);var held:=sample(world,duration)
		check(first.get("id")=="tray_pickup" and held.get("id")=="carried_tray","original duration owns animation-to-held switch")
		if first.is_empty() or held.is_empty():continue
		check(first.position.distance_to(world.chapter3_layers.pickup_start)<.001,"first visible pose stays at original tray position")
		check(near_end.position.distance_to(held.position)<.1,"last pickup frame meets held pose within a tenth source pixel")
		check(held.position.distance_to(world.player+Vector2(0,-3))<.001 and absf(held.rotation)<.001,"held tray is level at original adapter hand anchor")
		check(is_equal_approx(middle.rotation,0) and middle.texture==TrayFrames.ATLAS_ASSET,"genuine keypose owns tilt without rotating or squashing the runtime canvas")
		check(middle.source==TrayFrames.atlas_region(1 if reduced else 4),"midpoint selects restrained reduced pose or the normal lifted pose")
		check((middle.scale*middle.source.size).is_equal_approx(Vector2(24,24)),"atlas changes retain the original source-size pickup canvas")
		check(first.texture==TrayFrames.SOURCE_ASSET and held.texture==TrayFrames.SOURCE_ASSET and first.source==held.source,"first and carried endpoints retain the exact original SVG")
		records.append({"reduced":reduced,"duration_ms":duration,"first":str(first),"middle":str(middle),"near_end":str(near_end),"held":str(held),"handover_jump":near_end.position.distance_to(held.position)})
		state.d=state.d.duplicate(true);world.chapter3_layers.sync(state.d,true);world.native_canteen.sync(state.d,"canteen_interior")
		var reload_pose:=sample(world,INF)
		check(reload_pose.get("id")=="carried_tray" and reload_pose.position.is_equal_approx(held.position),"ordinary layer reset restores held pose without replay")
		world.native_canteen.sync(state.d,"campus_bootstrap")
		check(not world.native_canteen.visible,"leaving region hides held and pickup visuals")
	for reduced:bool in [false,true]:
		for approach:Array in [[Vector2(616,285),Vector2(662,328)],[Vector2(743,285),Vector2(688,328)],[Vector2(616,375),Vector2(662,372)],[Vector2(743,375),Vector2(688,372)]]:
			verify_depth_handover(world,state,reduced,approach[0],approach[1])
	var path:=OS.get_environment("CANTEEN_MOTION_REPORT")
	if not path.is_empty():
		var f:=FileAccess.open(path,FileAccess.WRITE);f.store_string(JSON.stringify({"checks":checks,"failures":failures,"controlled_pose_sampling":true,"records":records},"\t"));f.close()
	print("CANTEEN_PICKUP_CONTINUITY ",checks," checks; ",failures," failures")
	world.queue_free();await process_frame;quit(1 if failures else 0)
