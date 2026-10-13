extends SceneTree
## Bounded fixed-camera GPU stills only; this is not travel evidence.
var campus: Node2D
var out := ""
var records := {}
var failures: Array[String] = []
func _initialize() -> void:run.call_deferred()
func frame() -> void:await process_frame;await process_frame;await RenderingServer.frame_post_draw
func save(name: String) -> void:
	await frame()
	if root.get_texture().get_image().save_png(out.path_join(name)) != OK:failures.append(name)
func run() -> void:
	out = OS.get_environment("BUCT_SOUTH_BRIDGE_OUTPUT")
	if out.is_empty():quit(2);return
	root.size = Vector2i(960,720)
	campus = load("res://campuses/buct_changping/scenes/playable.tscn").instantiate();root.add_child(campus);await frame()
	var main: Node2D = campus.lake_surface
	var segment: Node2D = campus.south_bridge_surface
	if not is_instance_valid(main) or not is_instance_valid(segment):quit(1);return
	campus.visitor.set_physics_process(false);campus.visitor.hide();campus.set_process(false)
	campus.ui.hide();campus.pin_layer.hide();campus.canopy_locator.hide();campus.route_visual.hide()
	campus.camera.position_smoothing_enabled = false;campus.camera.zoom = Vector2.ONE*4
	campus.camera.position = Vector2(400,822);campus.camera.reset_smoothing();campus.camera.force_update_scroll()
	main.set_process(false);main.set_animation_enabled(false);await frame()
	var transform: Transform2D = campus.get_canvas_transform()
	records = {"viewport":[root.size.x,root.size.y],"source_to_screen":{"x":[transform.x.x,transform.x.y],"y":[transform.y.x,transform.y.y],"origin":[transform.origin.x,transform.origin.y]},"fixture":"Fixed camera diagnostic only; no position-based travel claim"}
	var ground: Sprite2D = segment.static_ground
	var compound: Material = ground.material
	main.hide();segment.hide();ground.material = null;await save("gpu-original.png")
	main.show();segment.show();ground.material = compound;await save("gpu-static.png")
	segment.hide();await save("gpu-segment-hidden.png");segment.show()
	main.set_animation_enabled(true);main.set_wave_time(0);await save("gpu-main-motion-0.png")
	main.set_wave_time(3.7);await save("gpu-main-motion-3.7.png");main.set_animation_enabled(false)
	main.free();campus.lake_surface = null;await save("gpu-main-removed.png")
	segment.free();campus.south_bridge_surface = null;await save("gpu-all-removed.png")
	records.failures = failures
	var f := FileAccess.open(out.path_join("gpu-capture.json"),FileAccess.WRITE)
	if f == null:failures.append("capture metadata")
	else:f.store_string(JSON.stringify(records,"  ")+"\n");f.close()
	print("BUCT_SOUTH_BRIDGE_GPU ",JSON.stringify(records))
	campus.queue_free();await process_frame;await process_frame
	quit(0 if failures.is_empty() else 1)
