extends SceneTree
## Exercise the Web mobile canvas transform, not merely a narrow native window.
var checks := 0
var failures := 0
func _initialize() -> void: run.call_deferred()
func frames() -> void:
	for i in 4: await process_frame
func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		push_error("ROTATED WORLD: " + label)
func screen_rect(control: Control) -> Rect2:
	return root.get_final_transform() * control.get_global_transform_with_canvas() * Rect2(Vector2.ZERO, control.size)
func click(control: Control) -> void:
	var point := screen_rect(control).get_center()
	for down: bool in [true,false]:
		var event := InputEventScreenTouch.new()
		event.position = point
		event.index = 0
		event.pressed = down
		root.push_input(event, false)
		await frames()
func run() -> void:
	var state := root.get_node("State")
	state.developer_mode = true
	state.d = state.initial()
	var shell = load("res://scenes/main.tscn").instantiate()
	root.add_child(shell)
	await frames()
	# Native headless does not advertise a touchscreen. Enable the exact Web
	# layout owner explicitly and leave all real layout/render transforms intact.
	shell.mobile_surface_managed = true
	shell.set_anchors_preset(Control.PRESET_TOP_LEFT)
	for checkpoint: String in ["c2-dorm-exit", "c2-entrance-record"]:
		check(state.begin_checkpoint(checkpoint), "loads checkpoint " + checkpoint)
		shell._refresh()
		await frames()
		for density: float in [1.0,1.25,2.0,3.0]:
			for dimensions: Vector2i in [Vector2i(390,844),Vector2i(430,932),Vector2i(844,390),Vector2i(390,844)]:
				root.content_scale_factor = density
				root.size = Vector2i(Vector2(dimensions) * density)
				shell.mobile_world = true
				shell._layout()
				await frames()
				var area := Rect2(Vector2.ZERO, Vector2(root.size))
				var painted := screen_rect(shell.world_view)
				var slot := screen_rect(shell.world_view_slot)
				print("ROTATED MEASURE ",checkpoint," ",dimensions," dpr=",density," turn=",shell.mobile_surface_rotation," view=",painted," slot=",slot," phone=",screen_rect(shell.mobile_back))
				check(shell.mobile_surface_rotation == (1 if dimensions.x < dimensions.y else 0), "uses real mobile canvas rotation")
				check(area.grow(1).encloses(painted), "world stays within visible viewport")
				check(painted.get_center().distance_to(slot.get_center()) < 1, "backing remains centered in its rotated slot")
				check(painted.grow(1).encloses(screen_rect(shell.mobile_back)), "phone button stays inside painted world")
				check(painted.grow(1).encloses(screen_rect(shell.inventory_dock)), "inventory stays inside painted world")
				var backing: Vector2 = Vector2(shell.world_viewport.size)
				var expected := Vector2(backing.y,backing.x) if dimensions.x < dimensions.y else backing
				check(painted.size.is_equal_approx(expected), "backing pixels remain 1:1 after rotation")
				for point: Vector2 in [Vector2(120,90),Vector2(480,270),Vector2(840,450)]:
					var pixel: Vector2 = shell.world.get_global_transform_with_canvas() * point
					var physical: Vector2 = root.get_final_transform() * shell.world_view.get_global_transform_with_canvas() * pixel
					var local: Vector2 = (root.get_final_transform() * shell.world_view.get_global_transform_with_canvas()).affine_inverse() * physical
					check(shell.world_view.source_position(local).distance_to(point) < .001, "physical point returns to same world coordinate")
				var scene: String = shell.world.scene_id
				await click(shell.mobile_back)
				check(shell.phone.visible and not shell.world_frame.visible, "actual physical touch opens phone")
				await click(shell.phone_world_return)
				check(shell.world_frame.visible and not shell.phone.visible and shell.world.scene_id == scene and state.d.native.scene == scene, "actual physical touch returns to same world")
	await shell.shutdown()
	shell.queue_free()
	await frames()
	print("ROTATED_WORLD_SURFACE: ",checks," checks; ",failures," failures")
	quit(1 if failures else 0)
