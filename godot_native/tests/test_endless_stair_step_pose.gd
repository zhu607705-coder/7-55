extends SceneTree
## Pure presentation sampling plus a full canonical 60 Hz model differential.
const Model = preload("res://scripts/games/chapter4_endless_stair_model.gd")
const Pose = preload("res://scripts/presentation/endless_stair_step_pose.gd")
var checks := 0
var failures := 0

func _initialize() -> void:
	run.call_deferred()

func check(ok: bool, note: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		push_error("B3_STEP_POSE: " + note)

func finite_pose(pose: Dictionary) -> bool:
	return is_finite(float(pose.body_y)) and pose.feet.size() == 2 \
		and pose.feet[0].is_finite() and pose.feet[1].is_finite() \
		and is_finite(float(pose.phase)) and is_finite(float(pose.lift))

func floor_top(floors: Array, x: float, radius: float = 0.0) -> float:
	var top := -INF
	for raw: Dictionary in floors:
		var r: Array = raw.rect
		if x + radius > float(r[0]) + .000001 and x - radius < float(r[0]) + float(r[2]) - .000001:
			top = maxf(top, float(r[1]) + float(r[3]))
	return top

func expected_feet(model, pose: Dictionary, progress: float) -> bool:
	var section: Dictionary = _contact_flight(model, progress)
	var start := float(section.start)
	var index := int(pose.step_index)
	var support := int(pose.support_foot)
	var phase := float(pose.phase)
	var x := start + float(index) * .6 + .105
	var travel := phase * phase * (3.0 - 2.0 * phase)
	var previous_x := x - .6 if is_finite(floor_top(model.geometry.floors, x - .6)) else x
	var next_x := x + .6 if is_finite(floor_top(model.geometry.floors, x + .6)) else x
	var swing_x := lerpf(previous_x, next_x, travel)
	var side: Vector3 = _heading(section).cross(Vector3.UP) * .115
	var contact: Vector3 = model.route_position(x, floor_top(model.geometry.floors, x)) \
		+ side * (-1.0 if support == 0 else 1.0)
	var support_ok: bool = pose.feet[support].distance_to(contact) < .0001
	var feet_clear := true
	for foot: int in 2:
		var foot_x := x if foot == support else swing_x
		feet_clear = feet_clear and pose.feet[foot].y >= floor_top(model.geometry.floors, foot_x, .1) - .0001
	return support_ok and feet_clear

func run() -> void:
	var model = Model.new()
	var baseline = Model.new()
	var geometry_before := JSON.stringify(model.geometry)
	var physical_trace_equal := true
	var geometry_unchanged := true
	var finite_all := true
	var supported_all := true
	var bounds_all := true
	var freeze_all := true
	var phase_all := true
	var planted_all := true
	var max_body_grounded_delta := 0.0
	var max_body_all_delta := 0.0
	var max_rendered_grounded_delta := 0.0
	var last_rendered_y: float = model.player.y
	var max_foot_delta := 0.0
	var active_samples := 0
	var inactive_flight_samples := 0
	var flights := {}
	var pose_frames := {}
	var cache: Dictionary = Pose.cache_floors(model.geometry.floors)
	var cached_equal := true
	var max_local_floors := 0
	var last_pose: Dictionary = Pose.sample(model, model.player.x, model.player.y, model.player_grounded)
	var last_grounded: bool = model.player_grounded
	var last_progress: float = model.player.x
	var last_route: String = str(model.route_section(last_progress).id)
	while model.status == "running":
		var mask: int = model.reference_input()
		model.step(mask)
		baseline.step(mask)
		var before := _state(model)
		var pose: Dictionary = Pose.sample(model, model.player.x, model.player.y, model.player_grounded)
		physical_trace_equal = physical_trace_equal and before == _state(model) and before == _state(baseline)
		for actor in [model.player, model.guard]:
			var grounded: bool = model.player_grounded if actor == model.player else model.guard_grounded
			var candidates: Array = cache.get(floori(actor.x / 1.2), [])
			max_local_floors = maxi(max_local_floors, candidates.size())
			cached_equal = cached_equal and Pose.sample(model, actor.x, actor.y, grounded) == Pose.sample(model, actor.x, actor.y, grounded, candidates)
		var repeated: Dictionary = Pose.sample(model, model.player.x, model.player.y, model.player_grounded)
		freeze_all = freeze_all and pose == repeated
		finite_all = finite_all and finite_pose(pose)
		bounds_all = bounds_all and absf(float(pose.body_y) - model.player.y) <= .180001
		var route: Dictionary = model.route_section(model.player.x)
		var body_delta := absf(float(pose.body_y) - float(last_pose.body_y))
		max_body_all_delta = maxf(max_body_all_delta, body_delta)
		if last_grounded and model.player_grounded:
			max_body_grounded_delta = maxf(max_body_grounded_delta, body_delta)
			max_rendered_grounded_delta = maxf(max_rendered_grounded_delta, absf((float(pose.body_y) if pose.active else model.player.y) - last_rendered_y))
		last_rendered_y = float(pose.body_y) if pose.active else model.player.y
		if pose.active:
			route = _contact_flight(model, model.player.x)
			active_samples += 1
			flights[route.id] = true
			pose_frames[pose.pose_frame] = true
			supported_all = supported_all and str(route.kind) == "flight" and model.player_grounded \
				and expected_feet(model, pose, model.player.x)
			var distance: float = (model.player.x - float(route.start) + .25) / .6
			var expected_index := clampi(floori(distance + .00001), 0, 19)
			phase_all = phase_all and int(pose.step_index) == expected_index \
				and absf(float(pose.phase) - clampf(distance - expected_index, 0, 1)) < .00001 \
				and int(pose.pose_frame) == int(pose.support_foot) * 8 + mini(7, floori(float(pose.phase) * 8))
			if last_pose.active and last_route == str(route.id):
				for foot: int in 2:
					max_foot_delta = maxf(max_foot_delta, pose.feet[foot].distance_to(last_pose.feet[foot]))
				if pose.contact_token == last_pose.contact_token:
					var foot := int(pose.support_foot)
					planted_all = planted_all and pose.feet[foot].distance_to(last_pose.feet[foot]) < .00001
		elif str(route.kind) == "flight":
			inactive_flight_samples += 1
		last_pose = pose
		last_grounded = model.player_grounded
		last_progress = model.player.x
		last_route = str(route.id)
	geometry_unchanged = JSON.stringify(model.geometry) == geometry_before
	check(model.status == "finished" and model.tick == 3485 and model.gates_passed == 12, "canonical 3485-tick input still finishes all 12 flights")
	check(physical_trace_equal and model.proof() == baseline.proof(), "sampling does not alter any paired player/guard/pursuit/input/proof trace")
	check(cached_equal and max_local_floors < 16, "local floor cache exactly matches full queries for both actors over all 3485 ticks")
	check(geometry_unchanged, "manifest geometry is read-only")
	check(finite_all and bounds_all, "both world soles and body stay finite; body correction is at most 0.18 m")
	check(flights.size() == 12 and active_samples > 2000, "contact gait runs on all 12 flights")
	check(supported_all, "every active support is on a real tread; both full shoe spans clear real floor tops")
	check(planted_all, "the support foot is world-locked for each contact token")
	check(phase_all and pose_frames.size() == 16, "distance phase and all 16 alternating contact poses are sampled")
	check(freeze_all, "identical progress freezes phase, body, contact, and both feet")
	check(max_body_grounded_delta < .04, "grounded 60 Hz body rise is continuous, including flight approach/exit and gap fallback")
	check(max_rendered_grounded_delta < .04, "active-only body rendering stays continuous at all grounded gap edges")
	check(max_foot_delta < .20, "consecutive active 60 Hz world feet do not snap between treads")
	_dense_sampling()
	_edge_cases()
	var result := {"checks": checks, "failures": failures, "fixedTicks": model.tick,
		"floorCandidatesMax": max_local_floors, "flightCount": flights.size(), "activeSamples": active_samples,
		"inactiveFlightSamples": inactive_flight_samples, "poseFrames": pose_frames.size(),
		"maxGroundedBodyDeltaMetres": max_body_grounded_delta,
		"maxAllBodyDeltaMetres": max_body_all_delta, "maxRenderedGroundedBodyDeltaMetres": max_rendered_grounded_delta, "maxActiveFootDeltaMetres": max_foot_delta,
		"physicsAndPursuitTraceIdentical": physical_trace_equal, "manifestUnchanged": geometry_unchanged,
		"inputSource": "canonical deterministic 60 Hz simulation; not human play"}
	DirAccess.make_dir_recursive_absolute("user://endless_stair_b3")
	FileAccess.open("user://endless_stair_b3/B3_step_pose_checks.json", FileAccess.WRITE).store_string(JSON.stringify(result, "  "))
	print("B3_STEP_POSE: ", JSON.stringify(result))
	quit(1 if failures else 0)

func _state(model) -> Array:
	return [model.player, model.guard, model.player_velocity, model.guard_velocity,
		model.player_grounded, model.guard_grounded, model.guard_fell, model.tick,
		model.status, model.failure_reason, model.gates_passed, model.last_input,
		model.input_log.duplicate(), model.pursuit_state(), model.torch_pose()]

func _dense_sampling() -> void:
	var model = Model.new()
	var all_ok := true
	var mirror_ok := true
	var reverse_ok := true
	var seam_ok := true
	var feet_clear := true
	var count := 0
	var cached := {}
	for route: Dictionary in model.geometry.routes:
		if str(route.kind) != "flight":
			continue
		for sample_index: int in range(0, 1201):
			var progress := float(route.start) + float(sample_index) * .01
			var physical_y := floor_top(model.geometry.floors, progress, .25)
			var pose: Dictionary = Pose.sample(model, progress, physical_y, true)
			all_ok = all_ok and finite_pose(pose)
			if not pose.active:
				continue
			count += 1
			feet_clear = feet_clear and expected_feet(model, pose, progress)
			var key := "%s:%d" % [str(route.id), sample_index]
			cached[key] = pose
			if str(route.id) == "flight_1":
				var other := Pose.sample(model, 4.0 + float(sample_index) * .01, physical_y - 3.3, true)
				if other.active:
					mirror_ok = mirror_ok and is_equal_approx(float(other.phase), float(pose.phase)) \
						and absf(float(pose.body_y) - float(other.body_y) - 3.3) < .00001
					var phase := float(pose.phase)
					var swing_local := float(pose.step_index) * .6 + .105 - .6 \
						+ 1.2 * phase * phase * (3.0 - 2.0 * phase)
					for foot: int in 2:
						# The first flight comes from a straight entry; the next
						# comes from a 90-degree turn. Their preceding platforms
						# are not mirror images. Test feet only inside the common
						# flight, while the separate entry checks cover both seams.
						if foot != int(pose.support_foot) and (swing_local < 0.0 or swing_local > 12.0):
							continue
						mirror_ok = mirror_ok and absf(pose.feet[foot].x + other.feet[foot].x) < .0001 \
							and absf(pose.feet[foot].z + other.feet[foot].z + 3.3) < .0001
		for sample_index: int in range(1200, -1, -1):
			var key := "%s:%d" % [str(route.id), sample_index]
			if not cached.has(key):
				continue
			var progress := float(route.start) + float(sample_index) * .01
			var pose := Pose.sample(model, progress, floor_top(model.geometry.floors, progress, .25), true)
			reverse_ok = reverse_ok and pose == cached[key]
		# Check both soles at infinitesimal support swaps. A new contact must
		# begin exactly where the preceding swing finished.
		for index: int in range(1, 20):
			var boundary := float(route.start) + float(index) * .6 - .25
			var a := Pose.sample(model, boundary - .0001, floor_top(model.geometry.floors, boundary - .0001, .25), true)
			var b := Pose.sample(model, boundary + .0001, floor_top(model.geometry.floors, boundary + .0001, .25), true)
			if a.active and b.active:
				seam_ok = seam_ok and absf(float(a.body_y) - float(b.body_y)) < .001
				for foot: int in 2:
					seam_ok = seam_ok and a.feet[foot].distance_to(b.feet[foot]) < .001
	check(all_ok and count > 10000, "dense 1 cm samples remain finite over all authored flights")
	check(feet_clear, "dense toe/heel and planted-contact clearance checks")
	check(mirror_ok, "opposite flight headings mirror the same contact gait in world space")
	check(reverse_ok, "sampling in reverse order gives exactly the same world pose")
	check(seam_ok, "both foot identities and body are continuous at every valid support swap")

func _edge_cases() -> void:
	var model = Model.new()
	var platform := Pose.sample(model, 17.0, 3.3, true)
	var air := Pose.sample(model, 8.0, 3.0, false)
	var elevated := Pose.sample(model, 8.0, 4.0, true)
	var missing := Pose.sample(model, 55.5, 11.55, true)
	check(not platform.active and not air.active and not elevated.active and not missing.active,
		"platform, airborne, unsupported high step, and removed tread all fall back")
	check(finite_pose(Pose.sample(model, NAN, INF, true)), "invalid diagnostic input cannot create nonfinite transforms")
	var preflight_ok := true
	for route: Dictionary in model.geometry.routes:
		if str(route.kind) != "flight":
			continue
		var p := float(route.start) - .20
		var pose := Pose.sample(model, p, float(route.fromY) + .165, true)
		preflight_ok = preflight_ok and pose.active and int(pose.step_index) == 0 \
			and pose.heading.distance_to(_heading(route)) < .00001 \
			and absf(float(pose.body_y) - float(route.fromY) - .01375) < .00001 \
			and expected_feet(model, pose, p)
	check(preflight_ok, "all 12 first-riser contacts start before the centre seam, with the new flight heading")
	var reverse_model = Model.new()
	reverse_model.player = Vector2(104.0, floor_top(reverse_model.geometry.floors, 104.0, .25))
	reverse_model.player_grounded = true
	var reverse_ok := true
	var reverse_contacts := 0
	for i: int in 120:
		reverse_model.step(Model.LEFT)
		var pose := Pose.sample(reverse_model, reverse_model.player.x, reverse_model.player.y, reverse_model.player_grounded)
		reverse_ok = reverse_ok and finite_pose(pose) and absf(float(pose.body_y) - reverse_model.player.y) <= .180001
		if pose.active:
			reverse_contacts += 1
			reverse_ok = reverse_ok and expected_feet(reverse_model, pose, reverse_model.player.x)
	check(reverse_ok and reverse_contacts > 30, "actual reversed 60 Hz movement keeps real planted contacts and sole clearance")
	var frozen := Pose.sample(model, 8.12, floor_top(model.geometry.floors, 8.12, .25), true)
	model.tick = 5000
	model.player_velocity = Vector2(-3.25, 0)
	model.pursuit_phase_ticks = 37
	check(Pose.sample(model, 8.12, floor_top(model.geometry.floors, 8.12, .25), true) == frozen,
		"tick, pursuit time, and movement direction cannot advance a stopped contact pose")

func _contact_flight(model, progress: float) -> Dictionary:
	for section: Dictionary in model.geometry.routes:
		if str(section.kind) == "flight" and progress >= float(section.start) - .25 and progress < float(section.start) + float(section.length):
			return section
	return model.route_section(progress)

func _heading(section: Dictionary) -> Vector3:
	return (Vector3(float(section.toXZ[0]), 0, float(section.toXZ[1])) - Vector3(float(section.fromXZ[0]), 0, float(section.fromXZ[1]))).normalized()
