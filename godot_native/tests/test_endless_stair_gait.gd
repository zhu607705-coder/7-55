extends SceneTree
## Renderer lifecycle regression. Headless only; no screenshots or source asset writes.
## --baseline-signature can run this same file against the published B3 project.
var View = load("res://scripts/presentation/chapter4_endless_stair_view.gd") if ResourceLoader.exists("res://scripts/presentation/chapter4_endless_stair_view.gd") else load("res://scripts/presentation/chapter4_folded_chase_view.gd")
var Model = load("res://scripts/games/chapter4_endless_stair_model.gd") if ResourceLoader.exists("res://scripts/games/chapter4_endless_stair_model.gd") else load("res://scripts/games/chapter4_folded_chase_model.gd")
const PLAYER_TRACE_HASH := "3d48528af32e48f2817af4c5154b96d614fdcd10666a81d862720446c9df1e81"
const FULL_TRACE_HASH := "0364bc9122b979fc0202553837d4c745c668a18acf702ffcce0a242b303f7d80"
const ORIGINAL_ASSET_HASH := "cb8ddbf4289407c1348c921843a1c0695c8b6710b012548447dc9d7cb6331fbd"
const SOURCE_HASHES := {
	"res://scripts/games/chapter4_endless_stair_model.gd": "06cf6e03a086b1024a534ae31674541144f82e4413be34ea04469172f9a1a5f1",
	"res://scripts/games/chapter4_endless_stair_physics.gd": "a80a13d9b3383ce7c6909e85de95cc5cdcd25f3cc891ac8f31f841819d09f642",
	"res://data/native/chapter4-endless-stair-b3.json": "e486b1ffe612afe6815ef119fcdd6025031db8f6cc321165392540018eea84e1"
}
var checks := 0
var failures := 0
var details: Array[String] = []
var metrics: Dictionary = {}

func _initialize() -> void:
	run.call_deferred()

func check(ok: bool, note: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		push_error("B3 gait lifecycle: " + note)

func remember(note: String) -> void:
	if details.size() < 12 and not details.has(note): details.append(note)

func player_record(m) -> Array:
	return [m.tick, m.player.x, m.player.y, m.player_velocity.x,
		m.player_velocity.y, m.player_grounded, m.last_input, m.gates_passed]

func full_record(m) -> Array:
	return [player_record(m), m.guard.x, m.guard.y, m.guard_velocity.x,
		m.guard_velocity.y, m.guard_grounded, m.guard_fell, m.status,
		m.failure_reason, m.guard_pursuit_speed, m.pursuit_state()]

func original_asset_hash() -> String:
	var paths: Array[String] = []
	for direction: String in ["up", "down", "side"]:
		for frame: int in 8:
			paths.append("res://assets/rpg/player/player_%s_%d.png" % [direction, frame])
	paths.append("res://assets/rpg/player/player_side_idle.png")
	for suffix: String in ["", "_up", "_down"]:
		paths.append("res://assets/rpg/npcs/finale/guard_walk%s_8frame.png" % suffix)
	var rows := ""
	for path: String in paths: rows += path + "=" + FileAccess.get_sha256(path) + "\n"
	return rows.sha256_text()

func baseline_signature() -> void:
	var m = Model.new()
	var trace: Array = []
	var player_trace: Array = []
	while m.status == "running":
		m.step(m.reference_input())
		trace.append(full_record(m))
		player_trace.append(player_record(m))
	print("B3_GAIT_BASELINE ", JSON.stringify({"ticks": m.tick, "status": m.status,
		"playerTraceHash": JSON.stringify(player_trace, "", true).sha256_text(),
		"fullTraceHash": JSON.stringify(trace, "", true).sha256_text(),
		"originalAssetHash": original_asset_hash()}))
	quit(0 if m.status == "finished" and m.tick == 3485 else 1)

func material_state(v) -> Array:
	var result: Array = []
	for index: int in 2:
		var limb = v.stair_gait.limbs[index]
		result.append([limb.get_instance_id(), limb.mesh.get_instance_id(),
			limb.material_override.get_instance_id(), limb.material_override.albedo_texture.get_instance_id()])
		var upper = v.stair_gait.upper_nodes[index]
		result.append([upper.get_instance_id(), upper.mesh.get_instance_id(),
			upper.material_override.get_instance_id(), upper.material_override.albedo_texture.get_instance_id()])
	return result

func valid_crop(v, guard: bool) -> bool:
	var sprite: Sprite3D = v.pursuer if guard else v.actor
	if not sprite.region_enabled: return true
	if sprite.region_rect != Rect2(0, 0, 96, 98) or sprite.offset != Vector2(0, 77) \
		or not is_equal_approx(sprite.pixel_size, 1.7 / 128.0): return false
	if guard:
		if not sprite.texture is AtlasTexture or sprite.texture.atlas != v.guard_frames.side \
			or sprite.texture.region.size != Vector2(96, 128) or sprite.hframes != 1: return false
	else:
		if sprite.texture.get_size() != Vector2(96, 128): return false
		if sprite.texture != v.player_frames.idle and not v.player_frames.side.has(sprite.texture): return false
	# Crop retains the complete wrist/hand to y=97. +15 pixels cancels the
	# lost half-height; the same deformation maps every visible pixel/socket.
	for pixel: Vector2 in [Vector2(48, 22), Vector2(46, 61), Vector2(36, 91), Vector2(30, 93), Vector2(57, 84), Vector2(46, 93)]:
		var warped: Vector2 = v.stair_gait.warp_pixel(pixel, guard)
		var x := (warped.x - 48.0) * (-1.0 if sprite.flip_h else 1.0)
		var y := 64.0 - warped.y + 62.0
		var expected: Vector3 = (v.camera.global_basis.x * x + v.camera.global_basis.y * y) * (1.7 / 128.0)
		var actual: Vector3 = v._sprite_socket(sprite, pixel) - sprite.position
		if actual.distance_to(expected) > .00001: return false
	return true

func run() -> void:
	if "--baseline-signature" in OS.get_cmdline_user_args():
		baseline_signature()
		return
	for path: String in SOURCE_HASHES:
		check(FileAccess.get_sha256(path) == SOURCE_HASHES[path], "published model/physics/manifest bytes unchanged: " + path)
	check(original_asset_hash() == ORIGINAL_ASSET_HASH, "all 28 original PNG source bytes match the independent published project")
	var v = View.new()
	root.add_child(v)
	await process_frame
	v.set_process(false)
	v.set_physics_process(false)
	v._start()
	v.demo_mode = true
	v.capture_frames.clear()
	# The demo's explicit tick-2100 screenshot is bypassed by driving its exact
	# raw reference inputs below, while retaining actual present/renderer code.
	var initial_materials := material_state(v)
	check(v.stair_gait.limbs[0].material_override.albedo_texture == v.player_frames.side[2] \
		and v.stair_gait.limbs[1].material_override.albedo_texture == v.guard_frames.side,
		"leg materials reuse the original player side2 and guard side atlas textures")
	check(v.stair_gait.upper_nodes[0].material_override.albedo_texture == v.player_frames.side[0] \
		and v.stair_gait.upper_nodes[1].material_override.albedo_texture == v.guard_frames.side,
		"upper materials deform original side0 pixels without repainting or source-frame swapping")
	_replay(v, initial_materials)
	_two_step_semantics(v)
	_stopped_and_reset(v)
	check(original_asset_hash() == ORIGINAL_ASSET_HASH, "full replay and lifecycle checks do not modify any original PNG")
	print("B3_GAIT_LIFECYCLE ", JSON.stringify({"checks": checks, "failures": failures,
		"metrics": metrics, "firstFailureDetails": details,
		"method": "headless actual view/gait lifecycle, independent published 3485-tick model signature; no GUI or human play"}))
	v.queue_free()
	await process_frame
	await create_timer(.12).timeout
	quit(1 if failures else 0)

func _replay(v, initial_materials: Array) -> void:
	var reference = Model.new()
	var trace: Array = []
	var player_trace: Array = []
	var physics_equal := true
	var presentation_read_only := true
	var ordinary_smooth := true
	var offsets_bounded := true
	var repeats_frozen := true
	var crop_exact := true
	var materials_reused := true
	var landing_exact := true
	var reentry_smooth := true
	var stair_sounds_exact := true
	var contacts_audible := true
	var ordinary_steps := 0
	var landings := [0, 0]
	var reentries := [0, 0]
	var cropped_frames := [0, 0]
	var max_ordinary_delta := 0.0
	var min_reentry_delta := INF
	var max_offset := 0.0
	var same_phone_hand := true
	var phone_continuous := true
	var old_phone_local := Vector3.ZERO
	var old_phone_active := false
	var max_phone_local_delta := 0.0
	var post_landing := [false, false]
	var old_bodies := [0.0, 0.0]
	v._present(0)
	old_bodies = [float(v.stair_gait.player_pose.body_y), float(v.stair_gait.guard_pose.body_y)]
	while v.model.status == "running":
		var m = v.model
		var old_grounded := [m.player_grounded, m.guard_grounded]
		var old_y := [m.player.y, m.guard.y]
		var old_x := [m.player.x, m.guard.x]
		var old_contacts: int = v.stair_gait.contact_events.size()
		var old_sounds: int = v.rhythm_feedback.step_events.size()
		var mask: int = reference.reference_input()
		reference.step(mask)
		m.step(mask)
		# Mirror the production jump/landing counter update without capture hooks.
		if not m.player_grounded: v.jump_ticks += 1
		elif not old_grounded[0]: v.land_ticks = 7; v.jump_ticks = 0
		elif v.land_ticks > 0: v.land_ticks -= 1
		var before_present := JSON.stringify(full_record(m), "", true)
		v._present(Model.DT)
		var after_present := JSON.stringify(full_record(m), "", true)
		physics_equal = physics_equal and after_present == JSON.stringify(full_record(reference), "", true)
		presentation_read_only = presentation_read_only and before_present == after_present
		trace.append(full_record(m))
		player_trace.append(player_record(m))
		materials_reused = materials_reused and material_state(v) == initial_materials
		var phone_active: bool = v.stair_gait.player_pose.get("active", false) and v.actor.region_enabled
		if phone_active:
			var expected_hand: Vector3 = v._sprite_socket(v.actor, Vector2(36, 91))
			same_phone_hand = same_phone_hand and v.player_hand_world.distance_to(expected_hand) < .00001 \
				and v.phone.position.distance_to(expected_hand + v.camera.global_basis.z * .07) < .00001
			var local_hand: Vector3 = v.player_hand_world - v.actor.position
			if old_phone_active:
				var hand_delta := local_hand.distance_to(old_phone_local)
				max_phone_local_delta = maxf(max_phone_local_delta, hand_delta)
				if hand_delta > .035:
					phone_continuous = false
					remember("same-hand jump tick=%d local_delta=%.6f" % [m.tick, hand_delta])
			old_phone_local = local_hand
		old_phone_active = phone_active
		for index: int in 2:
			var grounded: bool = m.guard_grounded if index else m.player_grounded
			var point: Vector2 = m.guard if index else m.player
			var pose: Dictionary = v.stair_gait.guard_pose if index else v.stair_gait.player_pose
			var body := float(pose.body_y)
			var offset := float(v.stair_gait.visual_offsets[index])
			max_offset = maxf(max_offset, absf(offset))
			offsets_bounded = offsets_bounded and is_finite(body) and is_finite(offset) \
				and absf(offset) <= .18001 and absf(body - point.y - offset) < .00001
			if grounded and not old_grounded[index]:
				landings[index] += 1
				landing_exact = landing_exact and absf(offset) < .00001
				post_landing[index] = true
			elif post_landing[index] and grounded and absf(point.x - float(old_x[index])) > .00001:
				reentries[index] += 1
				var delta := body - float(old_bodies[index])
				min_reentry_delta = minf(min_reentry_delta, delta)
				if delta < -.06:
					reentry_smooth = false
					remember("landing re-entry actor=%d tick=%d body_delta=%.6f" % [index, m.tick, delta])
				post_landing[index] = false
			var rise := point.y - float(old_y[index])
			if grounded and old_grounded[index] and pose.get("active", false) \
				and absf(rise - .165) < .0001:
				ordinary_steps += 1
				var delta := absf(body - float(old_bodies[index]))
				max_ordinary_delta = maxf(max_ordinary_delta, delta)
				if delta > .055:
					ordinary_smooth = false
					remember("ordinary rise actor=%d tick=%d body_delta=%.6f" % [index, m.tick, delta])
			var sprite: Sprite3D = v.pursuer if index else v.actor
			if sprite.region_enabled:
				cropped_frames[index] += 1
				if not valid_crop(v, bool(index)):
					crop_exact = false
					remember("upper crop/socket actor=%d tick=%d texture=%s scale=%.8f land_ticks=%d" % [index, m.tick, sprite.texture.get_size(), sprite.pixel_size, v.land_ticks])
			old_bodies[index] = body
		for sound_index: int in range(old_sounds, v.rhythm_feedback.step_events.size()):
			var sound: Dictionary = v.rhythm_feedback.step_events[sound_index]
			var token := str(sound.get("stair_contact", ""))
			if token.is_empty(): continue
			var match_found := false
			for contact_index: int in range(old_contacts, v.stair_gait.contact_events.size()):
				var contact: Dictionary = v.stair_gait.contact_events[contact_index]
				if contact.guard and contact.tick == sound.tick and contact.token == token: match_found = true
			stair_sounds_exact = stair_sounds_exact and match_found
		for contact_index: int in range(old_contacts, v.stair_gait.contact_events.size()):
			var contact: Dictionary = v.stair_gait.contact_events[contact_index]
			if not contact.guard or absf(m.guard.x - float(old_x[1])) <= .00001: continue
			var matched := 0
			for sound_index: int in range(old_sounds, v.rhythm_feedback.step_events.size()):
				var sound: Dictionary = v.rhythm_feedback.step_events[sound_index]
				if sound.tick == contact.tick and sound.get("stair_contact", "") == contact.token: matched += 1
			contacts_audible = contacts_audible and matched == 1
		if m.tick % 17 == 0:
			var builds: int = v.stair_gait.poses_built
			var upper_builds: int = v.stair_gait.upper_mesh_builds
			var contacts: int = v.stair_gait.contact_events.size()
			var sounds: int = v.rhythm_feedback.step_events.size()
			var offsets: Array = v.stair_gait.visual_offsets.duplicate()
			for repeat: int in 3: v._present(1.0 / 144.0)
			repeats_frozen = repeats_frozen and v.stair_gait.poses_built == builds \
				and v.stair_gait.upper_mesh_builds == upper_builds \
				and v.stair_gait.contact_events.size() == contacts and v.rhythm_feedback.step_events.size() == sounds \
				and v.stair_gait.visual_offsets == offsets and after_present == JSON.stringify(full_record(m), "", true)
	var full_hash := JSON.stringify(trace, "", true).sha256_text()
	check(v.model.status == "finished" and v.model.tick == 3485 and v.model.gates_passed == 12,
		"canonical 3485 ticks finish all twelve flights")
	check(physics_equal and presentation_read_only, "every model field remains equal to the independently stepped reference before/after present")
	check(JSON.stringify(player_trace, "", true).sha256_text() == PLAYER_TRACE_HASH, "player trace exactly matches published B3")
	check(full_hash == FULL_TRACE_HASH, "full player/guard/pursuit trace exactly matches the independent published B3 project")
	check(ordinary_steps > 300 and ordinary_smooth, "ordinary grounded risers never reproduce the old 0.165 m body teleport")
	check(offsets_bounded, "both presentation offsets remain finite and at most 0.18 m for the entire replay")
	check(landings[0] > 0 and landings[1] > 0 and landing_exact, "both actors reset visual offset to zero on actual jump landing")
	check(reentries[0] > 0 and reentries[1] > 0 and reentry_smooth, "first moving grounded tick after landing cannot pop down by 0.156 m")
	check(repeats_frozen, "repeated present at the same simulation tick does not rebuild mesh or repeat contacts/sounds")
	check(materials_reused, "existing mesh instances and original-source materials are reused throughout the full replay")
	check(cropped_frames[0] > 1000 and cropped_frames[1] > 1000 and crop_exact,
		"98-pixel crop retains source wrists and applies exactly the same warp to upper pixels and sockets")
	check(same_phone_hand and phone_continuous, "phone remains on one original near-hand pixel without a frame-switch jump")
	check(stair_sounds_exact and contacts_audible, "every moving guard stair contact has exactly one same-tick token-matched footstep")
	metrics = {"ticks": v.model.tick, "fullTraceHash": full_hash, "ordinaryRisers": ordinary_steps,
		"maxOrdinaryBodyDelta": max_ordinary_delta, "maxVisualOffset": max_offset,
		"landings": landings, "reentries": reentries, "minimumReentryBodyDelta": min_reentry_delta,
		"croppedFrames": cropped_frames, "meshBuilds": v.stair_gait.poses_built,
		"upperMeshBuilds": v.stair_gait.upper_mesh_builds, "maxPhoneLocalDelta": max_phone_local_delta,
		"contacts": v.stair_gait.contact_events.size(), "footsteps": v.rhythm_feedback.step_events.size()}

func support_height(m, progress: float) -> float:
	var top := -INF
	for raw: Dictionary in m.geometry.floors:
		var r: Array = raw.rect
		if progress + .25 > float(r[0]) + .00001 and progress - .25 < float(r[0]) + float(r[2]) - .00001:
			top = maxf(top, float(r[1]) + float(r[3]))
	return top

func _stopped_and_reset(v) -> void:
	v._start()
	v.model.player = Vector2(8.12, support_height(v.model, 8.12))
	v.model.guard = Vector2(7.52, support_height(v.model, 7.52))
	v.model.player_grounded = true
	v.model.guard_grounded = true
	v.model.player_velocity = Vector2.ZERO
	v.model.guard_velocity = Vector2.ZERO
	v._present(0)
	var gait = v.stair_gait
	check(gait.player_pose.active and gait.guard_pose.active, "stopped lifecycle fixture places both actors on real stair support")
	var poses := [gait.player_pose.duplicate(true), gait.guard_pose.duplicate(true)]
	var builds: int = gait.poses_built
	var upper_builds: int = gait.upper_mesh_builds
	var contacts: int = gait.contact_events.size()
	var sounds: int = v.rhythm_feedback.step_events.size()
	var offsets: Array = gait.visual_offsets.duplicate()
	for tick: int in 90:
		# Clock-only changes with fixed positions exercise pause/stopped render
		# lifecycle, without inventing different movement or pursuit rules.
		v.model.tick += 1
		v._present(Model.DT)
	check(gait.player_pose == poses[0] and gait.guard_pose == poses[1] and gait.visual_offsets == offsets,
		"90 stopped ticks preserve the complete pose, contact phase, and visual offset")
	check(gait.poses_built == builds and gait.upper_mesh_builds == upper_builds and gait.contact_events.size() == contacts \
		and v.rhythm_feedback.step_events.size() == sounds, "stopped actors cause no mesh rebuilds, contacts, or footsteps")
	v._lose_focus()
	var paused_tick: int = v.model.tick
	v._physics_process(Model.DT)
	for repeat: int in 5: v._present(Model.DT)
	check(v.model.tick == paused_tick and gait.poses_built == builds and gait.upper_mesh_builds == upper_builds,
		"focus pause freezes simulation and both upper/leg mesh rebuilding")
	# Dirty every state that can otherwise leak across retry, including states
	# not simultaneously reachable during a single ordinary stair contact.
	gait.landing_anchors = [8.12, 7.52]
	gait.landing_corrections = [.14, .12]
	gait.airborne_offsets = [-.14, -.12]
	gait.airborne_ticks = [5, 7]
	gait.previous_grounded = [false, false]
	v._start()
	check(gait.last_tick == -1 and gait.previous_tokens == ["", ""] and gait.contact_events.is_empty() \
		and gait.visual_offsets == [0.0, 0.0] and gait.airborne_offsets == [0.0, 0.0] \
		and gait.landing_corrections == [0.0, 0.0] \
		and gait.airborne_ticks == [0, 0] and gait.previous_grounded == [true, true],
		"retry clears contact, landing, airborne, and offset lifecycle state")
	check(not is_finite(gait.landing_anchors[0]) and not is_finite(gait.landing_anchors[1]) \
		and not gait.player_pose.active and not gait.guard_pose.active \
		and not gait.limbs[0].visible and not gait.limbs[1].visible \
		and not gait.upper_nodes[0].visible and not gait.upper_nodes[1].visible \
		and v.actor.visible and v.pursuer.visible \
		and not gait.mesh_keys[0].is_finite() and not gait.mesh_keys[1].is_finite(),
		"retry invalidates both mesh keys and hides all previous stair poses")
	check(v.rhythm_feedback.stair_contact_token == "" and v.rhythm_feedback.step_events.is_empty(),
		"retry also clears guard audio's old stair-contact token")

func correlation(a: Array[float], b: Array[float]) -> float:
	var mean_a := 0.0
	var mean_b := 0.0
	for i: int in a.size():
		mean_a += a[i]
		mean_b += b[i]
	mean_a /= a.size()
	mean_b /= b.size()
	var covariance := 0.0
	var variance_a := 0.0
	var variance_b := 0.0
	for i: int in a.size():
		var da := a[i] - mean_a
		var db := b[i] - mean_b
		covariance += da * db
		variance_a += da * da
		variance_b += db * db
	if variance_a < .0000001 or variance_b < .0000001: return 0.0
	return covariance / sqrt(variance_a * variance_b)

func _two_step_semantics(v) -> void:
	var results: Array = []
	# Both flights ascend, but one faces camera-right and one camera-left.
	# Near/far is measured from camera depth, never assumed from foot number.
	for flight_index: int in 2:
		v._start()
		var flight: Dictionary = v.model.geometry.routes[1 + flight_index * 2]
		var first_x := float(flight.start) + 4.0 * .60 - .25 + .0001
		var arm_samples: Array = [[], []]
		var leg_samples: Array = [[], []]
		var near_indices := [-1, -1]
		var sources_stable := true
		var sockets_exact := true
		var visible := true
		var max_hand_delta := [0.0, 0.0]
		var old_hand := [Vector3.ZERO, Vector3.ZERO]
		for sample: int in 121:
			var progress := first_x + 1.20 * float(sample) / 120.0
			var physical_y := support_height(v.model, progress)
			v.model.player = Vector2(progress, physical_y)
			v.model.guard = Vector2(progress, physical_y)
			v.model.player_grounded = true
			v.model.guard_grounded = true
			v.model.player_velocity = Vector2(3.25, 0)
			v.model.guard_velocity = Vector2(3.36, 0)
			v.model.tick += 1
			v._present(0)
			for index: int in 2:
				var pose: Dictionary = v.stair_gait.guard_pose if index else v.stair_gait.player_pose
				var sprite: Sprite3D = v.pursuer if index else v.actor
				var upper: MeshInstance3D = v.stair_gait.upper_nodes[index]
				visible = visible and pose.get("active", false) and upper.visible and not sprite.visible
				if not pose.get("active", false): continue
				var heading: Vector3 = pose.heading
				var lateral := Vector3(-heading.z, 0, heading.x)
				var near_foot := 1 if lateral.dot(v.camera.global_basis.z) > 0 else 0
				near_indices[index] = near_foot
				var hand_pixel := Vector2(30, 93) if index else Vector2(36, 91)
				var hand: Vector3 = v._sprite_socket(sprite, hand_pixel)
				var chest: Vector3 = v._sprite_socket(sprite, Vector2(47, 70))
				var pelvis: Vector3 = v._sprite_socket(sprite, Vector2(46, 93))
				var relative_hand := hand - chest
				arm_samples[index].append(relative_hand.dot(heading))
				leg_samples[index].append((Vector3(pose.feet[near_foot]) - pelvis).dot(heading))
				if sample > 0: max_hand_delta[index] = maxf(max_hand_delta[index], relative_hand.distance_to(old_hand[index]))
				old_hand[index] = relative_hand
				sources_stable = sources_stable and v.stair_gait.source_frame(bool(index), sample % 8) == 0
				sockets_exact = sockets_exact and valid_crop(v, bool(index))
		check(visible and sources_stable and sockets_exact, "both mirrored stair directions use fixed original upper pixels and one shared socket warp: " + str(flight.id))
		for index: int in 2:
			var hands: Array[float] = []
			var feet: Array[float] = []
			hands.assign(arm_samples[index])
			feet.assign(leg_samples[index])
			if hands.size() != 121:
				check(false, "all 121 two-step semantic samples remain on real stair support")
				continue
			var coefficient := correlation(hands, feet)
			var hand_range := float(hands.max()) - float(hands.min())
			var half_difference := absf(hands[60] - hands[0])
			var closure := absf(hands[120] - hands[0])
			var counterphase := coefficient < -.75 and hand_range > .035
			check(counterphase, "near hand/chest and near foot/pelvis are counterphase for actor=%d heading=%s (r=%.5f)" % [index, flight.id, coefficient])
			check(half_difference > .035 and closure < .002,
				"upper arm takes two stairs, not one stair, to complete a cycle: actor=%d heading=%s" % [index, flight.id])
			check(max_hand_delta[index] < .010,
				"same near hand is continuous across both contact swaps: actor=%d heading=%s" % [index, flight.id])
			if not counterphase: remember("semantic actor=%d flight=%s near_foot=%d correlation=%.6f range=%.6f" % [index, flight.id, near_indices[index], coefficient, hand_range])
			results.append({"actor": index, "flight": flight.id, "nearFoot": near_indices[index],
				"correlation": coefficient, "handRange": hand_range, "halfCycleDifference": half_difference,
				"cycleClosure": closure, "maxHandDeltaAt1cm": max_hand_delta[index]})
	metrics.twoStepSemantics = results
