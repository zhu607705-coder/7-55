extends SceneTree
## Reproducible actual presentation fixtures; no earned play or campaign writes.
const StairView = preload("res://scripts/presentation/chapter4_endless_stair_view.gd")
const StairModel = preload("res://scripts/games/chapter4_endless_stair_model.gd")
const RideView = preload("res://scripts/presentation/chase3d/source_chase_3d.gd")
const RideModel = preload("res://scripts/games/chase_stunt_model.gd")
var output := ""
var report: Array = []

func _initialize() -> void:
	run.call_deferred()

func capture(name: String, details: Dictionary) -> void:
	await process_frame
	await RenderingServer.frame_post_draw
	var image := root.get_texture().get_image()
	var path := output.path_join(name + ".png")
	assert(image.save_png(path) == OK, "Cannot save " + path)
	details["file"] = name + ".png"
	details["sha256"] = FileAccess.get_sha256(path)
	report.append(details)

func run() -> void:
	if DisplayServer.get_name() == "headless" or not load("res://tests/native_test_isolation.gd").is_isolated_save():
		push_error("Motion capture requires actual renderer and isolated profile")
		quit(2)
		return
	output = OS.get_environment("MOTION_CAPTURE_DIR")
	assert(not output.is_empty())
	DirAccess.make_dir_recursive_absolute(output)
	root.size = Vector2i(1280, 720)
	root.get_node("State").developer_mode = true
	var probe = StairModel.new()
	var takeoff := -1
	var landing := -1
	for tick in range(7200):
		var grounded: bool = probe.player_grounded
		probe.step(probe.reference_input())
		if grounded and not probe.player_grounded and takeoff < 0:
			takeoff = probe.tick
		if not grounded and probe.player_grounded and takeoff >= 0:
			landing = probe.tick
			break
	assert(takeoff > 3 and landing > takeoff, "Reference replay must contain a complete jump")
	var selected: Array[int] = [takeoff-3, takeoff-1, takeoff, takeoff+3, takeoff+7, (takeoff+landing)/2, landing-3, landing-1, landing, landing+3, landing+7]
	var stair = StairView.new()
	root.add_child(stair)
	await process_frame
	stair.set_process(false)
	stair.set_physics_process(false)
	stair._start()
	for tick in range(landing+8):
		var grounded: bool = stair.model.player_grounded
		stair.model.step(stair.model.reference_input())
		if not stair.model.player_grounded: stair.jump_ticks += 1
		elif not grounded: stair.land_ticks = 7; stair.jump_ticks = 0
		elif stair.land_ticks > 0: stair.land_ticks -= 1
		stair._present(1.0/60)
		if stair.model.tick in selected:
			await capture("b3-%04d" % stair.model.tick, {"kind":"B3 original reference-input replay", "tick":stair.model.tick, "takeoff":takeoff, "landing":landing, "grounded":stair.model.player_grounded, "position":str(stair.actor.position), "camera":str(stair.camera.transform), "texture":stair.actor.texture.resource_path})
	stair.rhythm_feedback.pause_audio()
	stair.queue_free()
	await process_frame
	var ride = RideView.new()
	ride.configure({"asset_directory":"res://assets/native_755/ride/", "live_shadows":true})
	ride.size = Vector2(1280, 720)
	root.add_child(ride)
	await process_frame
	assert(ride.ready3d and ride.failure_reason.is_empty(), "Original rider resources must load")
	var model = RideModel.new()
	# Deliberately controlled presentation samples, never story completion proof.
	for frame in range(241):
		model.tick = frame*2
		model.distance = 110 + frame*.15
		model.lane = 1.0 if frame < 60 else 1.0 - sin(clampf((frame-60)/120.0, 0, 1)*TAU)*.65
		ride.render_model(model, 1.0/60)
		if frame in [59, 75, 90, 105, 120, 135, 150, 180, 240]:
			await capture("ride-%03d" % frame, {"kind":"Original rider controlled rear-view fixture", "frame":frame, "lane":model.lane, "phase":ride.pedal_phase, "steer":ride.handlebar_steer, "roll":ride.body_roll, "leftFootPedalError":ride.hero.reference_world("leftFoot").origin.distance_to(ride.hero.reference_world("leftPedal").origin), "rightFootPedalError":ride.hero.reference_world("rightFoot").origin.distance_to(ride.hero.reference_world("rightPedal").origin)})
	ride.dispose()
	await process_frame
	var file := FileAccess.open(output.path_join("captures.json"), FileAccess.WRITE)
	file.store_string(JSON.stringify(report, "\t"))
	file.close()
	print("MOTION_REFERENCE_CAPTURES ", report.size(), " actual renderer frames")
	quit(0)
