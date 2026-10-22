extends SceneTree
const View = preload("res://scripts/presentation/chapter4_endless_stair_view.gd")
const Model = preload("res://scripts/games/chapter4_endless_stair_model.gd")
var checks := 0
var failures := 0
var metrics: Array = []
func _initialize() -> void: run.call_deferred()
func check(ok: bool, note: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		push_error("CAMERA_INPUT: " + note)
func key(code: Key, pressed: bool) -> void:
	var event := InputEventKey.new()
	event.physical_keycode = code
	event.keycode = code
	event.pressed = pressed
	Input.parse_input_event(event)
	Input.flush_buffered_events()
func normalized(v, point: Vector3) -> Vector2:
	# Use the same orthographic projection and fixed basis as Camera3D. This
	# remains testable with the dummy renderer, which has no GPU projection.
	var relative: Vector3 = point - v.follow_center
	var height: float = v.camera.size
	var width: float = height * v.size.x / v.size.y
	return Vector2(.5 + relative.dot(v.camera.global_basis.x) / width, .5 - relative.dot(v.camera.global_basis.y) / height)
func run() -> void:
	root.size = Vector2i(1280,720)
	var v = View.new()
	root.add_child(v)
	await process_frame
	v.set_process(false); v.set_physics_process(false)
	v._start()
	v.model.player_grounded = false
	check(v._buffered_jump_mask(Model.RIGHT, true) == Model.RIGHT, "press in air does not apply mid-air thrust")
	check(v.jump_buffer_ticks == View.JUMP_BUFFER_TICKS - 1, "airborne edge creates a seven-tick buffer")
	for i in 3: v._buffered_jump_mask(Model.RIGHT, false)
	v.model.player_grounded = true
	check(v._buffered_jump_mask(Model.RIGHT, false) == (Model.RIGHT | Model.JUMP), "early released tap is consumed on next grounded tick")
	check(v.jump_buffer_ticks == 0 and v._buffered_jump_mask(Model.RIGHT, false) == Model.RIGHT, "buffer consumes once")
	v._clear_input(); v.model.player_grounded = false
	v._buffered_jump_mask(0, true)
	for i in View.JUMP_BUFFER_TICKS: v._buffered_jump_mask(0, true)
	v.model.player_grounded = true
	check(v._buffered_jump_mask(0, true) == 0, "expired airborne press and held Space do not auto-jump")
	check(v._buffered_jump_mask(0, false) == 0 and v._buffered_jump_mask(0, true) == Model.JUMP, "new press rearms jump")
	# Actual collision landing, followed by buffered launch with unchanged physics.
	v._start(); v.model.guard = Vector2(-3.4,0)
	v.model.player = Vector2(1,.06); v.model.player_velocity = Vector2(0,-2); v.model.player_grounded = false
	v.model.step(v._buffered_jump_mask(0,false,true))
	v.model.step(v._buffered_jump_mask(0,false))
	check(v.model.player_grounded, "actual falling actor reaches support")
	v.model.step(v._buffered_jump_mask(0,false))
	check(not v.model.player_grounded and v.model.player_velocity.y > 7.0, "buffer launches with canonical 7.6 m/s jump impulse")
	# A held screen direction keeps one route intent across every platform turn.
	v._start(); v._update_camera(0)
	for route in v.model.geometry.routes:
		v.model.player.x = float(route.start) + .01
		check(v._adjust_input_mask(Model.RIGHT) == Model.RIGHT, "held input follows forward route through " + str(route.id))
	check(v._adjust_input_mask(0) == 0 and v.held_route_direction == 0, "neutral input releases retained route")
	v._start(); v._present(0)
	var press_point: Vector2 = v.size * Vector2(.9,.65)
	v._pointer_press(4,press_point,true)
	check(v.primary_touch == 4 and v.touch_axis != 0, "touch owns movement")
	v._pointer_press(4,press_point,false)
	check(v.primary_touch == -99 and v.touch_axis == 0 and not v.queued_jump, "quick movement release stops without synthesizing a jump")
	v._pointer_press(4,press_point,true)
	v._pointer_press(5,press_point,true)
	check(v.primary_touch == 4 and v.queued_jump, "second finger requests jump without stealing movement")
	v.queued_jump = false
	v._pointer_move(4,press_point - Vector2(0,45))
	check(v.queued_jump and v.swipe_used, "upward swipe requests jump")
	v.queued_jump = false
	v._pointer_move(4,press_point - Vector2(0,75))
	check(not v.queued_jump, "one swipe emits only one jump")
	v.jump_buffer_ticks = 5
	v._cancel_touch(4)
	check(v.primary_touch == -99 and v.touch_axis == 0 and v.jump_buffer_ticks == 0, "canceled touch clears all pending intent")
	key(KEY_D,true); key(KEY_SPACE,true)
	v._lose_focus()
	check(not v.active and v.jump_buffer_ticks == 0 and v.input_rearm_keys.has(KEY_D), "focus loss pauses and disarms held key")
	v._menu_action()
	v._physics_process(Model.DT)
	check(v.model.player_velocity.x == 0 and v.model.player_grounded, "resume cannot inherit held movement or Space")
	key(KEY_D,false); key(KEY_SPACE,false)
	v._physics_process(Model.DT)
	key(KEY_D,true)
	v._physics_process(Model.DT)
	check(v.model.player_velocity.x > 0, "release and fresh key press restores movement")
	key(KEY_D,false)
	v._physics_process(Model.DT)
	check(v.model.player_velocity.x == 0, "key release has no movement residue")
	# Orientation changes cancel old touch coordinates before gameplay resumes.
	v._start(); v.size=Vector2(390,844); v._fit(); v._present(0)
	v._pointer_press(8,v.size*Vector2(.9,.7),true)
	check(v.primary_touch == 8, "portrait fixture owns active touch")
	v.size=Vector2(844,390); v._fit()
	check(v.primary_touch == -99 and v.touch_axis == 0 and v.held_route_direction == 0, "rotation cancels stale pointer and retained route")
	v._physics_process(Model.DT)
	check(v.model.player_velocity.x == 0, "rotation produces neutral movement until a fresh press")
	v._pointer_press(9,v.size*Vector2(.9,.7),true)
	check(v.primary_touch == 9 and v.touch_axis != 0, "fresh landscape touch rearms movement")
	v._clear_input()
	# Repeated A/D reversals cannot create a camera whip or an instantaneous lead flip.
	v.size=Vector2(1280,720); v._fit(); v._start()
	v.model.player.x=7; v._update_camera(0)
	var max_reverse_step := 0.0; var max_lead_step := 0.0
	for i in 240:
		var direction := 1.0 if (i / 30) % 2 == 0 else -1.0
		v.model.player_velocity.x=direction*Model.PLAYER_SPEED
		v.model.player.x+=direction*Model.PLAYER_SPEED*Model.DT
		var old_center: Vector3=v.follow_center
		var old_lead: float=v.camera_route_direction
		v._update_camera(Model.DT)
		max_reverse_step=maxf(max_reverse_step, old_center.distance_to(v.follow_center))
		max_lead_step=maxf(max_lead_step,absf(old_lead-v.camera_route_direction))
	check(max_reverse_step<=.10001, "repeated reversal camera step is speed-bounded")
	check(max_lead_step<=4.0*Model.DT+.00001, "repeated reversal blends lookahead direction over 0.5 s")
	# Exercise the view adapter, not only raw model replay, through both sample flights.
	v._start(); v.touch_axis=1
	while v.model.status == "running":
		v.queued_jump = bool(v.model.reference_input() & Model.JUMP)
		v._physics_process(Model.DT)
	check(v.model.status == "finished" and v.model.gates_passed == v.model.geometry.gates.size(), "ordinary input adapter reaches all sample gates")
	check(Model.validate_proof(v.model.proof()), "buffered input adapter preserves canonical replay proof")
	# The next foot placement and 4.5 m warning horizon stay in the safe frame.
	for screen in [Vector2(1280,720), Vector2(1024,768), Vector2(844,390), Vector2(390,844)]:
		v.size = screen; v._fit(); v._start()
		check(screen.x >= screen.y or v.size.x / v.surface.stretch_shrink >= 360.0, "render target preserves phone pixel detail at " + str(screen))
		var ground_only := true
		var min_x := 1.0; var max_x := 0.0; var min_y := 1.0; var max_y := 0.0
		var max_camera_step := 0.0; var old_center: Vector3 = v.follow_center
		while v.model.status == "running":
			v.model.step(v.model.reference_input())
			v._update_camera(Model.DT)
			max_camera_step = maxf(max_camera_step, v.follow_center.distance_to(old_center))
			old_center = v.follow_center
			var points: Array[Vector3] = [v.model.route_position(v.model.player.x,v.model.player.y), v.model.route_position(v.model.player.x,v.model.player.y+1.7), v._camera_ground(v.model.player.x+1.0), v._camera_ground(v.model.player.x+4.5)]
			for point in points:
				var uv := normalized(v, point)
				min_x = minf(min_x,uv.x); max_x = maxf(max_x,uv.x)
				min_y = minf(min_y,uv.y); max_y = maxf(max_y,uv.y)
			if v.model.tick % 120 == 0:
				var target: Vector3 = v._camera_target()
				v.model.player.y += 3.0
				ground_only = ground_only and target.is_equal_approx(v._camera_target())
				v.model.player.y -= 3.0
		check(ground_only,"camera target independent of jump and landing height at " + str(screen))
		check(min_x >= .04 and max_x <= .96 and min_y >= .04 and max_y <= .96,"feet, head and 4.5 m warning fit " + str(screen))
		check(max_camera_step < .065,"camera remains continuous through every landing at " + str(screen))
		metrics.append({"viewport":[screen.x,screen.y],"min_x":min_x,"max_x":max_x,"min_y":min_y,"max_y":max_y,"max_camera_metres_per_tick":max_camera_step,"ticks":v.model.tick,"status":v.model.status})
	# Position-sampled lookahead has no target discontinuity at route corners.
	var max_seam := 0.0
	for route in v.model.geometry.routes:
		for direction in [-1.0,1.0]:
			v.camera_route_direction = direction
			v.model.player.x = float(route.start) - direction*1.45 - .0001
			var before: Vector3 = v._camera_target()
			v.model.player.x += .0002
			max_seam = maxf(max_seam,before.distance_to(v._camera_target()))
	check(max_seam < .0003,"lookahead has no instant tangent flip at any platform")
	var result := {"checks":checks,"failures":failures,"jump_buffer_ticks":View.JUMP_BUFFER_TICKS,"physics_unchanged":true,"max_target_seam_metres":max_seam,"max_reversal_camera_step":max_reverse_step,"max_reversal_lead_step":max_lead_step,"framing":metrics,"input":"Godot fixed-tick synthetic events and complete two-flight sample route replays; not human play"}
	print("CAMERA_INPUT: ",JSON.stringify(result))
	v.queue_free(); await process_frame
	quit(1 if failures else 0)
