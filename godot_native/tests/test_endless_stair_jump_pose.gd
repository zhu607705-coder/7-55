extends SceneTree
## Real view + unchanged reference inputs; no replacement physics or art.
const View = preload("res://scripts/presentation/chapter4_endless_stair_view.gd")
const Model = preload("res://scripts/games/chapter4_endless_stair_model.gd")
var checks := 0
var failures := 0

func check(ok: bool, note: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		push_error(note)

func _initialize() -> void:
	run.call_deferred()

func run() -> void:
	var view = View.new()
	root.add_child(view)
	await process_frame
	view.set_process(false)
	view.set_physics_process(false)
	view._start()
	var airborne := 0
	var gathered := 0
	var absorbed := 0
	var coherent := true
	var anchored := true
	for tick in range(640):
		var grounded: bool = view.model.player_grounded
		view.model.step(view.model.reference_input())
		if not view.model.player_grounded: view.jump_ticks += 1
		elif not grounded: view.land_ticks = 7; view.jump_ticks = 0
		elif view.land_ticks > 0: view.land_ticks -= 1
		var before: String = var_to_str([view.model.player, view.model.player_velocity, view.model.tick, view.model.player_grounded])
		view._present(1.0/60)
		check(before == var_to_str([view.model.player, view.model.player_velocity, view.model.tick, view.model.player_grounded]), "presentation cannot change jump physics")
		var facing: String = Model.visible_facing(view.retained_heading, view.camera.global_basis).facing
		if facing != "side" and not view.stair_gait.player_pose.get("active", false):
			if not view.model.player_grounded:
				airborne += 1
				coherent = coherent and view.actor.texture in [view.player_frames[facing][1], view.player_frames[facing][5]]
				if view.actor.texture == view.player_frames[facing][5]: gathered += 1
			if view.land_ticks > 0 and view.actor.scale.y < .99: absorbed += 1
		if view.actor.scale != Vector3.ONE:
			var pixel := Vector2(28, 89) if facing == "up" else Vector2(67, 91)
			var expected: Vector3 = view.actor.position + (view.camera.global_basis.x * ((pixel.x-48)*view.actor.scale.x) + view.camera.global_basis.y*((126-pixel.y)*view.actor.scale.y))*view.actor.pixel_size
			anchored = anchored and view._sprite_socket(view.actor, pixel).distance_to(expected) < .00001
	check(airborne > 20 and gathered > 0 and coherent, "front/back jump gathers original pixels instead of walking in mid-air")
	check(absorbed >= 4, "actual landing has a short sole-rooted absorption and recovery")
	check(anchored, "scaled wrist sockets follow the same original sprite transform")
	view._start()
	check(view.actor.scale == Vector3.ONE, "retry retires the old jump/landing deformation")
	view.queue_free()
	await process_frame
	print("B3_JUMP_POSE checks=", checks, " failures=", failures)
	quit(1 if failures else 0)
