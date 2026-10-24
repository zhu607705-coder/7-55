extends SceneTree
## Seeded renderer lifecycle fixtures, not a replacement for chapter handoffs.
const CanteenFixture=preload("res://tests/canteen_native_fixture.gd")
const ROOM_ATLAS="res://assets/rpg/interiors/finale/chapter4-755/sprites/chapter4_a2_room204_furniture_v02.png"
var state: Node
var world: Control
var checks:=0
var failures:=0

func _initialize()->void: run.call_deferred()
func frames(count:=3)->void:
	for index in range(count): await process_frame
func check(ok: bool,label: String)->void:
	checks+=1
	if not ok: failures+=1;push_error("LAZY_SCENE_RESOURCES: "+label)
func facts()->Dictionary:
	return {"items":state.d.items.duplicate(true),"actOne":state.d.actOne.duplicate(true),"canteen":state.d.canteenHunt.duplicate(true),"library":state.d.ui.libraryFinalsPuzzle.duplicate(true),"chapter4":state.d.chapter4.duplicate(true)}
func switch_scene(scene: String)->void:
	state.d.native.scene=scene;world.world_key="";world.refresh_world();world.queue_redraw();await frames()
func run()->void:
	check(load("res://tests/native_test_isolation.gd").is_isolated_save(),"disposable save profile")
	if failures: quit(1);return
	state=root.get_node("State");state.d=state.initial();state.developer_mode=false
	world=load("res://scripts/world.gd").new();world.size=Vector2(960,540);root.add_child(world);world.set_process(false)
	await frames()
	check(not is_instance_valid(world.native_dorm) and world.player_frames.is_empty() and world.guard_model==null,"first phone chapter creates no dormant room, actor frames or future guard")
	state.d.native.chapter=2;state.d.actOne.dormHubUnlocked=true
	await switch_scene("dorm_hub")
	check(is_instance_valid(world.native_dorm) and world.native_dorm.plate!=null and world.player_frames.size()==4,"first earned dorm entry loads its independent objects and shared actor frames")
	check(world.guard_model==null and world.guard_sheet==null,"dorm entry does not decode the fourth-chapter guard")
	var dorm_id:int=world.native_dorm.get_instance_id()
	await switch_scene("campus_bootstrap");await switch_scene("dorm_hub")
	check(world.native_dorm.get_instance_id()==dorm_id,"dorm re-entry reuses one object owner and its animations")
	check(not is_instance_valid(world.native_canteen),"fresh dorm has no inactive canteen scene or props")
	check(world.library_layers.art==null and world.library_layers.staff_art==null and world.library_layers.stamp_art==null,"fresh dorm does not decode three library-only textures")
	check(world.room204_object.tables.is_empty() and not ResourceLoader.has_cached(ROOM_ATLAS),"lightweight Room204 adapter does not preload the Chapter 4 furniture atlas")
	var opening:Control=load("res://scripts/presentation/c3_opening_view.gd").new();root.add_child(opening)
	opening.tick();check(opening.backdrop==null and not opening.visible,"hidden opening view does not preload the library plate")
	opening.free()
	state.d.native.chapter=2;state.d.ui.libraryFinalsPhase="evidence_gathering"
	var prior:=facts()
	await switch_scene("library_interior")
	var library:RefCounted=world.library_layers
	check(library.art!=null and library.staff_art!=null and library.stamp_art!=null and library.rebuild.ready,"first library entry loads its original and independently rebuilt art")
	check(not is_instance_valid(world.native_canteen) and facts()==prior,"library loading creates no canteen, item, or story facts")
	var plate_id:int=library.art.get_instance_id()
	await switch_scene("campus_bootstrap");await switch_scene("library_interior")
	check(library.art.get_instance_id()==plate_id,"returning to the library reuses the loaded texture")
	CanteenFixture.install(state);prior=facts();world.world_key="";world.refresh_world();await frames()
	var canteen:Node2D=world.native_canteen
	check(is_instance_valid(canteen) and canteen.is_active() and canteen.objects.size()>0,"first canteen entry owns a complete independent object scene")
	check(facts()==prior,"loading props leaves controller and inventory facts untouched")
	var node_id:=canteen.get_instance_id();var node_count:=canteen.get_child_count()
	var signal_count:int=state.action_completed.get_connections().size()
	for visit in range(4):
		await switch_scene("campus_bootstrap")
		check(not canteen.is_active() and not canteen.visible,"leaving retires visible canteen surfaces")
		var retired:=true
		for prop:Node2D in canteen.objects.values():
			if prop.body!=null: retired=retired and prop.body.collision_layer==0
		for row:Dictionary in canteen.structures: retired=retired and row.body.collision_layer==0
		check(retired,"inactive canteen colliders do not block the campus")
		await switch_scene("canteen_interior")
		check(world.native_canteen.get_instance_id()==node_id and canteen.get_child_count()==node_count,"reentry reuses one existing scene without rebuilding props")
		check(state.action_completed.get_connections().size()==signal_count and facts()==prior,"reentry adds no duplicate action observers or story facts")
	world.free();await frames()
	check(not is_instance_valid(canteen),"disposing World releases the owned canteen")
	print("LAZY_SCENE_RESOURCES: %d checks; %d failures"%[checks,failures]);quit(1 if failures else 0)
