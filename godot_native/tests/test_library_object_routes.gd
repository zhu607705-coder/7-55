extends SceneTree
## Full-room navigation through measured furniture; uses the real shared feet.
const Planner=preload("res://scripts/mobile_floor_route.gd")
const Isolation=preload("res://tests/native_test_isolation.gd")
const Notebook=preload("res://scripts/objects/library_geometry_notebook.gd")
var checks:=0
var failures:=0
var records:Array=[]

func _initialize()->void:run.call_deferred()
func check(ok:bool,label:String)->void:
	checks+=1
	if not ok:failures+=1;push_error("LIBRARY_OBJECT_ROUTES "+label)

func verify_route(world:Control,label:String,start:Vector2,goal:Vector2)->void:
	var obstacles:Array=world._floor_obstacles()
	var began:=Time.get_ticks_usec()
	var route:Array[Vector2]=world._floor_planner.plan(start,goal,obstacles,Rect2(0,0,1500,900),world.can_stand,func(a:Vector2,b:Vector2):return world._floor_segment_clear(a,b,obstacles,true))
	var elapsed:=Time.get_ticks_usec()-began
	check(world.can_stand(start) and world.can_stand(goal),label+" endpoints keep legal source feet")
	check(not route.is_empty() and route[-1].is_equal_approx(goal),label+" connects without dropping collision objects")
	var legal:=true
	var previous:=start
	for next:Vector2 in route:
		# Verify every short movement interval using live furniture and door feet,
		# independently of the visibility graph's expanded obstacle rectangles.
		var steps:=maxi(1,ceili(previous.distance_to(next)/4.0))
		for index:int in range(steps+1):
			if not world.can_stand(previous.lerp(next,float(index)/steps)):legal=false
		previous=next
	check(legal,label+" every movement sample respects actual furniture and doors")
	check(world._floor_planner.corner_count<=320 and world._floor_planner.edge_checks<=8192,label+" stays within the library graph budget")
	records.append({"route":label,"viewport":str(root.size),"shelfOffset":world.library_layers.shelf_offset,"waypoints":route.size(),"corners":world._floor_planner.corner_count,"edges":world._floor_planner.edge_checks,"planningUs":elapsed})

func run()->void:
	check(Isolation.is_isolated_save(),"disposable native save")
	if failures:quit(1);return
	var defaults:RefCounted=Planner.new()
	check(defaults.corner_limit==192 and defaults.edge_limit==4096,"all existing planner consumers retain their default limits")
	var state:Node=root.get_node("State")
	for dimensions:Vector2i in [Vector2i(1280,720),Vector2i(390,844)]:
		root.size=dimensions
		state.story_reset.emit();state.d=state.initial();state.developer_mode=true
		state.d.native.chapter=2;state.d.native.scene="library_interior";state.d.rpgScene="library_interior";state.d.runtimeMode="rpg"
		state.d.actOne.phase="complete";state.d.ui.libraryFinalsPhase="evidence_gathering";state.d.ui.libraryFinalsPuzzle.entranceRecordRead=true
		var world:Control=load("res://scripts/world.gd").new();world.size=Vector2(dimensions);root.add_child(world);world.set_process(false)
		await process_frame
		check(world.library_layers.objects.ready,"separate object scene activates")
		# Model the fully opened, already-authorized entrance; no story action is
		# granted by this geometric navigation fixture.
		world.library_door.progress=1.0
		var before:Dictionary=state.d.duplicate(true)
		for offset:int in [0,16]:
			world.library_layers.shelf_offset=offset
			verify_route(world,"front to rear through moving shelf aisle",Vector2(609,320),Vector2(609,96))
			verify_route(world,"cross aisle behind north-south stacks",Vector2(145,110),Vector2(807,110))
			verify_route(world,"reading gate to notebook",Vector2(1062,520),Notebook.APPROACH)
			verify_route(world,"entrance to ordinary row shelf",Vector2(715,850),Vector2(564,316))
			verify_route(world,"entrance to seat 022",Vector2(715,850),Vector2(1302,500))
			verify_route(world,"front desk to seat 022",Vector2(334,680),Vector2(1302,500))
			verify_route(world,"row shelf to seat 022",Vector2(564,316),Vector2(1302,500))
			verify_route(world,"notebook to catalog",Notebook.APPROACH,Vector2(690,650))
			verify_route(world,"seat 022 to entrance",Vector2(1302,500),Vector2(715,850))
		check(state.d.items==before.items and state.d.ui.libraryFinalsPuzzle==before.ui.libraryFinalsPuzzle,"route queries cannot acquire inventory or write story facts")
		world.scene_id="campus_bootstrap";world._floor_obstacles()
		check(world._floor_planner.corner_limit==192 and world._floor_planner.edge_limit==4096,"leaving the library restores the original planner budget")
		world.queue_free();await process_frame
	print("LIBRARY_OBJECT_ROUTES ",checks," checks, ",failures," failures; routes=",JSON.stringify(records))
	quit(0 if failures==0 else 1)
