extends SceneTree
## Fresh reconstruction tests. Historical run counts are not test evidence.
const Base = preload("res://scripts/games/chapter4_side_chase_model.gd")
const Folded = preload("res://scripts/games/chapter4_folded_chase_model.gd")
var checks := 0
var failures := 0

func _initialize() -> void:
	run.call_deferred()

func check(ok: bool, detail: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		push_error("FOLDED CHASE: " + detail)

func near(a: float, b: float) -> bool:
	return absf(a - b) < 0.0001

func flat_geometry() -> Dictionary:
	return {"spawn": {"player": [1.0, 0.0], "guard": [-100.0, 0.0]}, "bounds": [-1000.0, 1000.0],
		"killY": -5.0, "fallDepth": 2.4, "floors": [{"x": -1000.0, "y": -0.3, "width": 2000.0, "height": 0.3}],
		"obstacles": [], "gates": [], "exit": {"x": 999.0, "minY": -0.05, "maxY": 0.05},
		"routes": [{"kind": "entry", "start": -1000.0, "length": 2000.0, "fromXZ": [-1000, 0], "toXZ": [1000, 0], "fromY": 0, "toY": 0}],
		"lighting": {"torchHeight": 1.1}}

func test_geometry() -> void:
	var d: Dictionary = Folded.data()
	check(d.id == "chapter4-folded-stair-chase-v1" and d.version == 1 and d.prototypeOnly, "prototype manifest identity")
	check(d.floors.size() == 83 and d.routes.size() == 9 and d.gates.size() == 4, "83 floors, nine segments, four ordered gates")
	check(d.obstacles.size() == 2 and near(d.obstacles[0].rect[0], 17.45) and near(d.obstacles[1].rect[0], 58.3), "authored barriers retained")
	check(d.spawn.player == [1.0, 0.0] and d.spawn.guard == [-3.4, 0.0], "canonical spawn retained")
	check(near(d.routes.back().start, 61.9) and near(d.exit.x, 65.5), "four-flight finish lies on final landing")
	check(near(d.lighting.ambient, 0.105) and near(d.lighting.torchRange,3.2) and d.lighting.torchAngle == 7, "lighting manifest constants")
	var m = Folded.new()
	for i: int in range(d.routes.size() - 1):
		var a: Dictionary = d.routes[i]
		var b: Dictionary = d.routes[i + 1]
		check(near(a.start + a.length, b.start) and a.toXZ == b.fromXZ and near(a.toY, b.fromY), "corner continuity " + str(i))
		var corner: Vector3 = m.route_position(b.start, b.fromY)
		check(corner.distance_to(Vector3(b.fromXZ[0], b.fromY, b.fromXZ[1])) < 0.0001, "route position at corner " + str(i))
	check(m.route_position(-7.0, 0).distance_to(Vector3(-17, 0, 0)) < 0.0001, "entry route extends before first segment")
	check(near(m.route_surface_height(10), 1.65) and near(m.route_surface_height(100), 13.2), "surface height is clamped segment interpolation")
	check(m.route_heading(5).is_equal_approx(Vector3.RIGHT) and m.route_heading(20).is_equal_approx(Vector3.LEFT), "alternating flight headings")
	check(m.screen_direction(5, 1, Vector3.RIGHT) == 1 and m.screen_direction(20, 1, Vector3.RIGHT) == -1, "screen input reverses with route heading")
	d.floors.clear()
	check(Folded.data().floors.size() == 83, "callers cannot mutate canonical geometry cache")
	check(Folded.geometry_hash().length() == 64 and Folded.geometry_hash() == Folded.geometry_hash(), "canonical hash is stable SHA-256")
	check(not m.actor_open(Vector2(17.6, 3.3)) and m.actor_open(Vector2(17.6, 3.9)), "feet use box end.y as the top")

func test_physics() -> void:
	var m = Base.new(flat_geometry())
	m.step(0)
	check(near(m.player.x, 1) and m.player_grounded, "idle input does not auto-run player")
	m.step(Base.RIGHT)
	check(near(m.player.x, 1 + Base.PLAYER_SPEED / 60), "player speed is exactly 3.25 metres/second")
	check(near(m.guard.x, -100 + 2 * Base.GUARD_SPEED / 60), "guard speed is exactly 2.71875 metres/second")
	var x: float = m.player.x
	m.step(Base.LEFT | Base.RIGHT)
	check(near(m.player.x, x), "opposing direction inputs cancel")
	m.step(Base.LEFT)
	check(near(m.player.x, x - Base.PLAYER_SPEED / 60), "left input moves left")
	m.step(Base.JUMP)
	check(not m.player_grounded and m.player_velocity.y > 0, "grounded rising-edge jump")
	var vy: float = m.player_velocity.y
	m.step(0)
	m.step(Base.JUMP)
	check(near(m.player_velocity.y, vy - 2 * Base.GRAVITY / 60), "released-and-pressed airborne jump cannot reset velocity")
	for _i: int in range(90):
		m.step(Base.JUMP)
	check(m.player_grounded and near(m.player.y, 0), "held jump does not bounce on landing")
	m.step(0)
	m.step(Base.JUMP)
	check(not m.player_grounded and m.player_velocity.y > 0, "release enables next grounded jump")

	var d := flat_geometry()
	d.obstacles = [{"x": 2.0, "y": 0.0, "width": 0.1, "height": 10.0}]
	m = Base.new(d)
	var result: Dictionary = m._move_actor(Vector2(0, 0), Vector2(100, 0), true, 0.1)
	check(near(result.position.x, 1.75), "high-speed sweep stops at first right wall")
	result = m._move_actor(Vector2(5, 0), Vector2(-100, 0), true, 0.1)
	check(near(result.position.x, 2.35), "high-speed sweep stops at first left wall")
	d.obstacles.append({"x": 4.0, "y": 0.0, "width": 0.1, "height": 10.0})
	d.obstacles.reverse()
	m = Base.new(d)
	result = m._move_actor(Vector2(0, 0), Vector2(100, 0), true, 0.1)
	check(near(result.position.x, 1.75), "horizontal sweep is independent of box order")
	d = flat_geometry()
	d.obstacles = [{"x": -5, "y": 3.7, "width": 10, "height": 0.3}, {"x": -5, "y": 1.7, "width": 10, "height": 0.3}]
	for _i: int in range(2):
		m = Base.new(d)
		result = m._move_actor(Vector2(0, 10), Vector2(0, -20), false, 1.0)
		check(near(result.position.y, 4) and result.grounded, "fall lands on highest crossed top, order " + str(_i))
		d.obstacles.reverse()
	d.obstacles = [{"x": -5, "y": 3.0, "width": 10, "height": 0.3}, {"x": -5, "y": 5.0, "width": 10, "height": 0.3}]
	for _i: int in range(2):
		m = Base.new(d)
		result = m._move_actor(Vector2(0, 0), Vector2(0, 20), false, 0.5)
		check(near(result.position.y, 3 - Base.BODY_HEIGHT) and not result.grounded and near(result.velocity.y, 0), "jump hits lowest crossed ceiling, order " + str(_i))
		d.obstacles.reverse()

	d = flat_geometry()
	d.obstacles = [{"x": 2, "y": 0, "width": 2, "height": 0.165}]
	m = Base.new(d)
	result = m._move_actor(Vector2(1.74, 0), Vector2(Base.PLAYER_SPEED, 0), true)
	check(near(result.position.x, 1.75) and near(result.position.y, 0), "base model never auto-steps")
	m = Folded.new(d)
	result = m._move_actor(Vector2(1.74, 0), Vector2(Base.PLAYER_SPEED, 0), true)
	check(near(result.position.x, 1.74 + Base.PLAYER_SPEED / 60) and near(result.position.y, 0.165) and result.grounded, "folded model walks 0.165 metre riser without losing speed")
	d.obstacles[0].height = 0.19
	m = Folded.new(d)
	result = m._move_actor(Vector2(1.74, 0), Vector2(Base.PLAYER_SPEED, 0), true)
	check(near(result.position.x, 1.75) and near(result.position.y, 0), "solid above 0.18 metres blocks walking")
	d.obstacles[0].height = 0.165
	m = Folded.new(d)
	result = m._move_actor(Vector2(1.74, 0), Vector2(Base.PLAYER_SPEED, 0), false)
	check(near(result.position.x, 1.75), "airborne actor cannot use ground-step assist")
	d.obstacles.append({"x": 1.6, "y": 1.55, "width": 1, "height": 0.3})
	m = Folded.new(d)
	result = m._move_actor(Vector2(1.74, 0), Vector2(Base.PLAYER_SPEED, 0), true)
	check(near(result.position.x, 1.75), "small step cannot force actor through a low ceiling")

func test_failures_and_reset() -> void:
	var m = Folded.new()
	for _i: int in range(300):
		m.step(0)
		if m.status != "running":
			break
	check(m.status == "failed" and m.failure_reason == "caught", "idle player is caught")
	var terminal_tick: int = m.tick
	m.step(Base.RIGHT)
	check(m.tick == terminal_tick, "terminal model consumes no more inputs")
	m.guard_fell = true
	m.gates_passed = 3
	m.reset()
	check(m.player == Vector2(1, 0) and m.guard == Vector2(-3.4, 0), "retry restores spawn positions")
	check(m.status == "running" and m.failure_reason.is_empty() and not m.guard_fell and m.gates_passed == 0, "retry clears failure and all gates")
	check(m.tick == 0 and m.input_log.is_empty() and m.last_input == 0 and m.player_velocity == Vector2.ZERO and m.guard_velocity == Vector2.ZERO, "retry clears velocities, input edge state and proof log")
	check(m.player_grounded and m.guard_grounded, "retry recalculates grounded state")
	m.player = Vector2(24.35, 4.785)
	m.player_grounded = true
	for _i: int in range(180):
		m.step(Base.RIGHT)
		if m.status != "running":
			break
	check(m.status == "failed" and m.failure_reason == "player_fell", "walking into missing treads fails rather than teleporting")
	m.reset()
	m.guard = Vector2(-3.4, -6)
	m.guard_grounded = false
	m.step(Base.RIGHT)
	check(m.status == "failed" and m.guard_fell and m.failure_reason == "guard_fell", "fallen guard invalidates the chase")
	m.reset()
	m.player = Vector2(65.49, 13.2)
	m.player_grounded = true
	m.step(Base.RIGHT)
	check(m.status != "finished" and m.gates_passed == 0, "exit shortcut without ordered gates cannot win")
	m.reset()
	m.player = Vector2(65.49, 13.3)
	m.player_grounded = false
	m.gates_passed = 4
	m.step(Base.RIGHT)
	check(m.status != "finished", "airborne exit crossing cannot win")
	m.reset()
	m.player = Vector2(15.7, 3.3)
	m.guard = Vector2(16.3, 3.3)
	check(m._contact(), "capture measures physical XZ around folded corner")
	m.guard.y = 5.0
	check(not m._contact(), "different vertical floors do not capture")
	m.reset()
	m.step(8)
	check(m.status == "failed" and m.failure_reason == "invalid_input", "runtime invalid bit masks fail closed")

func test_facing_and_torch() -> void:
	var basis := Basis.IDENTITY
	check(Folded.visible_facing(Vector3.RIGHT, basis) == {"facing": "side", "left": false}, "camera-right facing")
	check(Folded.visible_facing(Vector3.LEFT, basis) == {"facing": "side", "left": true}, "camera-left facing")
	check(Folded.visible_facing(Vector3.FORWARD, basis).facing == "up", "camera-away facing")
	check(Folded.visible_facing(Vector3.BACK, basis).facing == "down", "camera-toward facing")
	var rotated := Basis(Vector3.UP, PI / 2)
	check(Folded.visible_facing(rotated.x, rotated).facing == "side", "facing is camera-relative after camera rotation")
	var m = Folded.new()
	m.guard = Vector2(10, 1.65)
	m.player = Vector2(11, 1.98)
	var pose: Dictionary = m.torch_pose()
	var actor: Vector3 = m.route_position(m.guard.x, m.guard.y)
	check(pose.position.distance_to(actor + Vector3(0.24, 0.65, 0)) < 0.0001, "torch is in front at authored hand height")
	check(pose.target.distance_to(pose.position + Vector3(3.2, 0.23, 0)) < 0.0001, "torch follows stair rise")
	check(pose.case_position.distance_to(pose.position - Vector3(0.09, 0, 0)) < 0.0001, "torch case stays behind light source")
	m.player.x = 9
	pose = m.torch_pose()
	check(pose.target.x < pose.position.x and pose.target.y < pose.position.y, "torch points downhill when guard chases backwards")

func test_guard_and_completion() -> Dictionary:
	var m = Folded.new()
	m.player = Vector2(65.4, 13.2)
	m.player_grounded = true
	var furthest: float = m.guard.x
	for _i: int in range(2500):
		m.step(0)
		furthest = maxf(furthest, m.guard.x)
		if m.status != "running":
			break
	check(furthest >= 61.9 and not m.guard_fell, "separate fixture proves guard clears all four flights and gap")
	check(m.status == "failed" and m.failure_reason == "caught", "guard ultimately reaches stationary final-landing player")
	m.reset()
	var jumps := 0
	var previous := 0
	var max_speed_excess := 0.0
	for _i: int in range(Base.MAX_TICKS):
		var mask: int = m.reference_input()
		if mask & Base.JUMP and not (previous & Base.JUMP):
			jumps += 1
		var old_x: float = m.player.x
		m.step(mask)
		max_speed_excess = maxf(max_speed_excess, m.player.x - old_x - Base.PLAYER_SPEED / 60)
		previous = mask
		if m.status != "running":
			break
	check(m.status == "finished", "reference input reaches the grounded final exit: " + m.failure_reason)
	check(m.gates_passed == 4 and m.player_grounded and not m.guard_fell, "fresh completion satisfies all four gates and guard legality")
	check(m.player.x >= 65.5 - Base.EPS and m.player.y >= 13.15 and m.player.y <= 13.25, "finish position is on actual final landing")
	check(max_speed_excess < 0.0001, "reference run has no disguised speed boost or blocker teleport")
	check(jumps == 3, "reference run jumps for two barriers and the missing treads")
	print("FOLDED_CHASE_FRESH_RUN: ticks=", m.tick, " seconds=", float(m.tick) / 60, " jumps=", jumps, " player=", m.player, " guard=", m.guard)
	return m.proof(false)

func test_proofs(raw_proof: Dictionary) -> void:
	check(Folded.validate_proof(raw_proof), "full raw input proof replays successfully")
	check(Folded.validate_proof(JSON.parse_string(JSON.stringify(raw_proof))), "raw proof survives JSON numeric roundtrip")
	var m = Folded.new()
	for mask: int in raw_proof.input:
		m.step(mask)
	var compressed: Dictionary = m.proof(true)
	check(compressed.input.size() < raw_proof.input.size(), "RLE compacts raw input without replacing replay")
	check(Folded.validate_proof(compressed), "full RLE proof replays successfully")
	check(Folded.validate_proof(JSON.parse_string(JSON.stringify(compressed))), "RLE proof survives JSON roundtrip")
	var modified := raw_proof.duplicate(true)
	modified.input.append(Base.RIGHT)
	modified.elapsedTicks += 1
	check(not Folded.validate_proof(modified), "extra input after terminal success is rejected")
	for key: String in ["kind", "version", "physicsVersion", "geometryId", "geometryHash"]:
		modified = raw_proof.duplicate(true)
		modified[key] = 99 if key in ["version", "physicsVersion"] else "wrong"
		check(not Folded.validate_proof(modified), "mismatched proof " + key + " is rejected")
	for bad: Variant in [-1, 8, 2.5, INF, NAN, true, "2", null]:
		modified = raw_proof.duplicate(true)
		modified.input[0] = bad
		check(not Folded.validate_proof(modified), "invalid raw mask rejected: " + str(bad))
	for bad: Variant in [0, -1, 7201, 2.5, INF, NAN, true, "12", null]:
		modified = raw_proof.duplicate(true)
		modified.elapsedTicks = bad
		check(not Folded.validate_proof(modified), "invalid elapsedTicks rejected: " + str(bad))
	modified = compressed.duplicate(true)
	modified.input = [{"mask": Base.RIGHT, "ticks": 1}, {"mask": Base.RIGHT, "ticks": 9223372036854775807}]
	var start := Time.get_ticks_msec()
	check(not Folded.validate_proof(modified), "signed-int64-max RLE after valid first entry rejected before addition")
	check(Time.get_ticks_msec() - start < 1000, "malicious RLE fails promptly without expansion")
	for bad: Variant in [0, -1, 7201, 1.5, INF, NAN, true, "1", null]:
		modified = compressed.duplicate(true)
		modified.input = [{"mask": Base.RIGHT, "ticks": bad}]
		check(not Folded.validate_proof(modified), "invalid RLE count rejected: " + str(bad))
	modified = compressed.duplicate(true)
	modified.input = [{"mask": Base.RIGHT, "ticks": 1}, {"mask": Base.RIGHT, "ticks": int(raw_proof.elapsedTicks)}]
	check(not Folded.validate_proof(modified), "bounded RLE segments cannot exceed declared elapsed total")
	modified = compressed.duplicate(true)
	modified.input = [{"mask": Base.RIGHT, "ticks": 1}, Base.RIGHT]
	check(not Folded.validate_proof(modified), "mixed raw/RLE encoding rejected")
	modified = raw_proof.duplicate(true)
	modified.input = []
	check(not Folded.validate_proof(modified), "empty proof rejected")
	modified.input.resize(7201)
	modified.input.fill(0)
	check(not Folded.validate_proof(modified), "too many proof entries rejected")
	modified = raw_proof.duplicate(true)
	modified.input.fill(0)
	check(not Folded.validate_proof(modified), "idle/caught replay cannot claim success")
	check(not Folded.validate_proof({}) and not Folded.validate_proof(null) and not Folded.validate_proof([]), "non-proof values rejected")
	# An altered fixture cannot be made authoritative by copying a canonical hash.
	var d := flat_geometry()
	d.exit.x = 1.01
	m = Folded.new(d)
	m.step(Base.RIGHT)
	check(m.status == "finished" and not Folded.validate_proof(m.proof()), "replay uses canonical geometry instead of model fixture claims")

func run() -> void:
	test_geometry()
	test_physics()
	test_failures_and_reset()
	test_facing_and_torch()
	var raw_proof := test_guard_and_completion()
	test_proofs(raw_proof)
	print("FOLDED_CHASE_MODEL: ", checks, " checks, ", failures, " failures")
	quit(1 if failures else 0)
