extends "res://tests/test_room204_native_object.gd"
const CanteenFixture=preload("res://tests/canteen_native_fixture.gd")
func repaint()->void:
	world.queue_redraw();await frames(3)
func run()->void:
	state=root.get_node("State");fixture();var saved_room:Dictionary=state.d.duplicate(true)
	world=load("res://scripts/world.gd").new();world.size=Vector2(960,540);root.add_child(world);world.set_process(false);await repaint()
	var adapter:Node2D=world.room204_object
	check(adapter.tables.size()==2 and adapter.visible,"production draw mounts both original Room204 objects")
	CanteenFixture.install(state);world.world_key="";world.refresh_world();await repaint()
	check(adapter.tables.is_empty() and adapter.source_space.get_child_count()==0 and not adapter.visible,"Room204 objects retire before canteen draw returns")
	check(world.native_canteen.is_active() and world.native_canteen.visible,"canteen objects render after Room204 retirement")
	var saved_canteen:Dictionary=state.d.duplicate(true)
	state.d=saved_room.duplicate(true);world.world_key="";world.refresh_world();await repaint()
	check(adapter.tables.size()==2 and adapter.visible,"state replacement recreates only the two source Room204 tables")
	check(not world.native_canteen.is_active() and not world.native_canteen.visible,"leaving canteen retires the native scene")
	var retired:=true
	for prop:Node2D in world.native_canteen.objects.values():
		if prop.body!=null:retired=retired and prop.body.collision_layer==0
	for row:Dictionary in world.native_canteen.structures:retired=retired and row.body.collision_layer==0
	check(retired,"canteen static bodies retire when Room204 resumes")
	state.d=saved_canteen.duplicate(true);world.world_key="";world.refresh_world();await repaint()
	check(adapter.tables.is_empty() and not adapter.visible,"second state replacement also retires both old Room204 objects")
	check(world.native_canteen.return_age>1,"ordinary state replacement does not replay tray feedback")
	state.d.native.scene="campus_bootstrap";world.world_key="";world.refresh_world();await repaint()
	check(adapter.tables.is_empty() and not adapter.visible and not world.native_canteen.visible,"campus contains neither retired interior renderer")
	world.queue_free();await frames();print("CANTEEN_SCENE_LIFECYCLE ",checks," checks; ",failures," failures");quit(1 if failures else 0)
