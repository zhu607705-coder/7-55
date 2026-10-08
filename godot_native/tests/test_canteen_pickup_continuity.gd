extends SceneTree
const Fixture=preload("res://tests/canteen_native_fixture.gd")
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
		if is_instance_valid(sprite) and sprite.visible:return {"id":id,"position":sprite.position,"rotation":sprite.rotation,"scale":sprite.scale}
	return {}
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
		check(is_equal_approx(middle.rotation,0) if reduced else middle.rotation<-.2,"reduced motion removes tilt; normal midpoint retains readable tilt")
		records.append({"reduced":reduced,"duration_ms":duration,"first":str(first),"middle":str(middle),"near_end":str(near_end),"held":str(held),"handover_jump":near_end.position.distance_to(held.position)})
		state.d=state.d.duplicate(true);world.chapter3_layers.sync(state.d,true);world.native_canteen.sync(state.d,"canteen_interior")
		var reload_pose:=sample(world,INF)
		check(reload_pose.get("id")=="carried_tray" and reload_pose.position.is_equal_approx(held.position),"ordinary layer reset restores held pose without replay")
		world.native_canteen.sync(state.d,"campus_bootstrap")
		check(not world.native_canteen.visible,"leaving region hides held and pickup visuals")
	var path:=OS.get_environment("CANTEEN_MOTION_REPORT")
	if not path.is_empty():
		var f:=FileAccess.open(path,FileAccess.WRITE);f.store_string(JSON.stringify({"checks":checks,"failures":failures,"controlled_pose_sampling":true,"records":records},"\t"));f.close()
	print("CANTEEN_PICKUP_CONTINUITY ",checks," checks; ",failures," failures")
	world.queue_free();await process_frame;quit(1 if failures else 0)
