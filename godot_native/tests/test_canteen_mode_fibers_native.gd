extends SceneTree
const Fixture=preload("res://tests/canteen_native_fixture.gd")
const Prop=preload("res://scripts/objects/canteen_scene_object.gd")
var checks:=0
var failures:=0
func _initialize() -> void: call_deferred("run")
func check(ok: bool,label: String) -> void:
	checks+=1
	if not ok: failures+=1; push_error(label)
func frames(count: int=3) -> void:
	for i in range(count): await process_frame
func paint(world: Control) -> void:
	world.native_canteen.configure_view(Vector2.ZERO,1,world.player)
	world.queue_redraw()
func run() -> void:
	var state:=root.get_node("State"); Fixture.install(state)
	var world: Control=load("res://scripts/world.gd").new(); world.size=Vector2(960,540); root.add_child(world); world.set_process(false); await frames()
	var scene: Node2D=world.native_canteen
	var view: Node2D=scene.source_space.get_node_or_null("CanteenModeFibers")
	check(is_instance_valid(view),"production independent renderer mounts the fiber view")
	if not is_instance_valid(view): world.queue_free(); await frames(); quit(1); return
	paint(world)
	check(not view.visible and view.samples.is_empty(),"production light mode paints no fibers")
	state.d.native.mode="dark"; state.d.canteenHunt.mode="dark"; world.chapter3_layers.sync(state.d)
	for i in range(20): world.chapter3_layers.tick(.017,state.d)
	paint(world); await frames()
	check(view.is_visible_in_tree() and view.samples.size()==4,"production dark mode actually consumes four circle entries")
	check(view.z_index==Prop.draw_layer(1602) and view.get_meta("source_depth")==1602.0,"fiber view preserves source1602 in native layer ordering")
	check(not view.is_processing() and view.get_parent()==scene.source_space,"native view uses the shared source transform and no second clock")
	check(scene.entity_surfaces.all(func(e:Dictionary)->bool:return not str(e.node.name).begins_with("mode_fiber")),"circles add no pick or collision surfaces")
	var count_before: int=scene.source_space.get_child_count(); var snapshot: Array=view.samples.duplicate(true)
	for i in range(10): paint(world)
	check(scene.source_space.get_child_count()==count_before and view.samples==snapshot,"paused repeated redraws neither allocate duplicates nor advance motion")
	var facts_before:=JSON.stringify(state.d); paint(world)
	check(JSON.stringify(state.d)==facts_before,"production rendering never mutates state")
	state.d.native.settings.reduced_motion=true; world.chapter3_layers.sync(state.d); paint(world)
	snapshot=view.samples.duplicate(true)
	for i in range(40): world.chapter3_layers.tick(.05,state.d)
	paint(world)
	check(view.samples==snapshot and view.samples[0].point==Vector2(790,218),"production reduced mode holds readable source points")
	state.d.canteenHunt.phase="exit_blocking"; world.chapter3_layers.sync(state.d); paint(world)
	check(not view.visible and view.samples.is_empty(),"defense clears the actual renderer")
	state.d.native.scene="campus_bootstrap"; world.world_key=""; world.refresh_world(); await frames()
	check(not view.is_visible_in_tree() and view.samples.is_empty(),"scene exit retires the actual circle view")
	state.d.canteenHunt.phase="tray_search"; state.d.native.scene="canteen_interior"; world.world_key=""; world.refresh_world(); paint(world); await frames()
	check(view.is_visible_in_tree() and view.samples.size()==4,"reentry reuses one clean native view")
	world.queue_free(); await frames()
	await test_shell_pause(state)
	print("CANTEEN_MODE_FIBERS_NATIVE ",checks," checks; ",failures," failures"); quit(1 if failures else 0)

func test_shell_pause(state: Node) -> void:
	Fixture.install(state)
	state.d.native.mode="dark";state.d.canteenHunt.mode="dark"
	root.size=Vector2i(1180,812)
	var shell: Control=load("res://scenes/main.tscn").instantiate();root.add_child(shell)
	await frames(4);shell._show_world_mobile();await frames(4)
	var fibers: RefCounted=shell.world.chapter3_layers.mode_fibers
	var before: float=fibers.clock_ms
	await frames(5)
	check(fibers.clock_ms>before,"visible real shell advances the shared fiber clock")
	shell._show_phone_surface();await frames(2)
	before=fibers.clock_ms
	await frames(8)
	check(shell.phone.is_visible_in_tree() and not shell.world_frame.is_visible_in_tree() and fibers.clock_ms==before,"actual phone surface freezes hidden fiber timing")
	shell._return_from_phone();await frames(4)
	check(shell.world_frame.is_visible_in_tree() and fibers.clock_ms>before,"ordinary phone return resumes the same fiber clock")
	paused=true;before=fibers.clock_ms
	await frames(8)
	check(fibers.clock_ms==before,"actual SceneTree pause freezes presentation")
	paused=false;await frames(4)
	check(fibers.clock_ms>before,"SceneTree resume continues presentation")
	await shell.shutdown();shell.queue_free();await frames()
