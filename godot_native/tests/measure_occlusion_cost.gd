extends SceneTree
const Fixture=preload("res://tests/canteen_native_fixture.gd")
func _initialize()->void:call_deferred("run")
func run()->void:
	Fixture.install(root.get_node("State"))
	var world:Control=load("res://scripts/world.gd").new();world.size=Vector2(1280,800);root.add_child(world);await process_frame;world.set_process(false)
	var scene:Node2D=world.native_canteen
	var started:=Time.get_ticks_usec()
	for i in range(120):
		world.player=Vector2(616,300+float(i%80));world._sync_player()
		scene.configure_view(Vector2.ZERO,1,world.player)
	print("OCCLUSION_COST ",Time.get_ticks_usec()-started," us; ",get_node_count()," nodes")
	world.queue_free();await process_frame;quit()
