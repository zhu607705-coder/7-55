extends SceneTree
## Standalone: no assets, autoloads, saves, controller state or imported scene.
const Swan = preload("res://scripts/games/qizhen_swan_motion.gd")
const WATER: Rect2 = Rect2(0.0, 0.0, 1800.0, 1000.0)
var checks: int = 0
var failures: int = 0

func check(value: bool, label: String) -> void:
	checks += 1
	if not value:
		failures += 1
		push_error(label)

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	test_spawn()
	test_disabled_protection()
	test_opening_physical_buffer()
	test_turning_and_speeds()
	test_charge_lock_and_recovery()
	test_collision_and_catching()
	print("Qizhen swan motion: %d checks, %d failures" % [checks, failures])
	quit(1 if failures else 0)

func test_spawn() -> void:
	var swan: RefCounted = Swan.new()
	var solid: Array = [{"left": 300, "top": 250, "right": 460, "bottom": 450}]
	swan.reset(Vector2(380, 350), 0.0, solid, WATER)
	check(swan.spawn_valid and swan._clear(swan.position), "solid spawn relocates into water")
	check(swan.position.distance_to(Vector2(380, 350)) < 140.0, "spawn correction remains nearby")
	swan.reset(Vector2(-400, -200), 0.0, solid, WATER)
	check(swan.spawn_valid and swan.position.x >= 22 and swan.position.y >= 22, "map-edge spawn includes body radius")
	swan.reset(Vector2.ZERO, 0.0, [], Rect2(0, 0, 30, 30))
	var result: Dictionary = swan.step(0.2, Vector2.ZERO, Vector2.ZERO)
	check(not swan.spawn_valid and not result.caught and swan.speed == 0.0, "too-small water fails safely")

func test_disabled_protection() -> void:
	var swan: RefCounted = Swan.new()
	swan.reset(Vector2(500, 500), 0.0, [], WATER)
	swan.speed = 300.0
	for index: int in range(480):
		swan.step(1.0 / 60.0, swan.position, Vector2.ZERO, false)
	check(swan.elapsed == 0.0 and not swan.caught, "eight-second cinematic consumes no contact protection")
	check(swan.speed == 0.0 and swan.phase == "coasting", "disabled swan coasts to rest")
	for index: int in range(209):
		swan.step(1.0 / 60.0, swan.position, Vector2.ZERO, true)
	check(not swan.caught and swan.elapsed < 3.5, "contact stays protected for 3.5 active seconds")
	for index: int in range(3):
		swan.step(1.0 / 60.0, swan.position, Vector2.ZERO, true)
	check(swan.caught, "near contact becomes live after protection")
	swan.reset(Vector2(500, 500), 0.0, [], WATER)
	swan.elapsed = 8.0
	swan.step(0.1, swan.position, Vector2.ZERO, false)
	check(not swan.caught and swan.elapsed == 8.0, "disabled mode suppresses contact even after grace expires")

func test_opening_physical_buffer() -> void:
	for start_gap: float in [140.0, 310.0, 700.0]:
		var swan: RefCounted = Swan.new()
		var player: Vector2 = Vector2(1000, 500)
		swan.reset(player - Vector2(start_gap, 0), 0.0, [], WATER)
		var minimum_gap: float = start_gap
		var warning_before_contact: bool = false
		var previous: Vector2 = swan.position
		for index: int in range(419):
			swan.step(1.0 / 120.0, player, Vector2.ZERO)
			minimum_gap = minf(minimum_gap, swan.position.distance_to(player))
			if swan.phase == "charge_warning" and swan.elapsed < Swan.CONTACT_GRACE:
				warning_before_contact = true
			check(swan.position.distance_to(previous) <= Swan.CHARGE_SPEED / 120.0 + 0.001, "protection never teleports the swan")
			previous = swan.position
		check(minimum_gap >= Swan.GRACE_BUFFER - 0.001, "stationary kayak retains full 120 px opening buffer")
		check(warning_before_contact, "stationary kayak sees warning before opening protection ends")
		check(not swan.caught, "opening buffer cannot cause an early catch")
		swan.step(1.0 / 120.0, player, Vector2.ZERO)
		check(not swan.caught, "grace expiry does not produce an instant overlap catch")
		for index: int in range(180):
			swan.step(1.0 / 120.0, player, Vector2.ZERO)
			if swan.caught:
				break
		check(swan.caught, "normal chase contact resumes after opening protection")
	# Deliberately overspeed the body next to the guard to test the last
	# substep boundary independently of the normal braking envelope.
	var swan: RefCounted = Swan.new()
	swan.reset(Vector2(879, 500), 0.0, [], WATER)
	swan.speed = Swan.CHARGE_SPEED
	swan.step(0.2, Vector2(1000, 500), Vector2.ZERO)
	check(swan.position.distance_to(Vector2(1000, 500)) >= Swan.GRACE_BUFFER, "fast initial speed cannot cross grace buffer")

func test_turning_and_speeds() -> void:
	var swan: RefCounted = Swan.new()
	swan.reset(Vector2(600, 500), 0.0, [], WATER)
	swan.step(1.0 / 60.0, Vector2(200, 500), Vector2.ZERO)
	check(absf(swan.heading) > 0.0 and absf(swan.heading) < 0.03, "opposite target accelerates turn without facing snap")
	var previous: float = swan.heading
	for index: int in range(90):
		swan.step(1.0 / 60.0, Vector2(200, 500), Vector2.ZERO)
		check(absf(angle_difference(previous, swan.heading)) <= Swan.MAX_TURN_RATE / 60.0 + 0.0001, "bounded physical turn rate")
		previous = swan.heading
	swan.reset(Vector2(100, 500), 0.0, [], WATER)
	for index: int in range(100):
		swan.step(1.0 / 60.0, swan.position + Vector2(700, 0), Vector2.ZERO)
	check(swan.speed > 340.0, "distant chase can close on a 340 px/s kayak")
	swan.reset(Vector2(100, 500), 0.0, [], WATER)
	for index: int in range(100):
		swan.step(1.0 / 60.0, swan.position + Vector2(110, 0), Vector2.ZERO)
	check(swan.speed < 340.0, "near tracking leaves the kayak room to maneuver")

func test_charge_lock_and_recovery() -> void:
	var swan: RefCounted = Swan.new()
	swan.reset(Vector2(200, 500), 0.0, [], Rect2(0, 0, 5000, 2000))
	var warning_time: float = -1.0
	var charge_time: float = -1.0
	var recovery_time: float = -1.0
	var charge_heading: float = 0.0
	var warning_aim: Vector2 = Vector2.ZERO
	var dodges: int = 0
	for index: int in range(700):
		var before: String = swan.phase
		var target: Vector2 = swan.position + Vector2(310, 0)
		if before in ["charge_warning", "charge"]:
			target = swan.position + Vector2(310, 380)
		var result: Dictionary = swan.step(1.0 / 120.0, target, Vector2.ZERO)
		if before != "charge_warning" and swan.phase == "charge_warning":
			warning_time = swan.elapsed
			warning_aim = swan.aim
		if before == "charge_warning" and swan.phase == "charge_warning":
			check(swan.aim == warning_aim, "warning target remains readable and fixed")
		if before != "charge" and swan.phase == "charge":
			charge_time = swan.elapsed
			charge_heading = swan.heading
		if swan.phase == "charge":
			check(is_equal_approx(swan.heading, charge_heading), "charge cannot home toward a moving target")
		if result.dodged:
			dodges += 1
			recovery_time = swan.elapsed
		if recovery_time > 0.0 and swan.phase == "tracking":
			check(swan.elapsed - recovery_time >= Swan.RECOVERY_SECONDS - 0.01, "miss leaves full recovery window")
			break
	check(warning_time >= 0.0 and charge_time - warning_time >= 0.7, "charge has at least 0.7 seconds of warning")
	check(recovery_time - charge_time >= 0.64 and recovery_time - charge_time <= 0.67, "straight charge lasts about 0.65 seconds")
	check(dodges == 1 and swan.charge_count == 1, "miss emits exactly one dodge pulse")
	check(swan.phase == "tracking", "recovery returns to tracking")

func test_collision_and_catching() -> void:
	var swan: RefCounted = Swan.new()
	var net: Array = [{"left": 600, "top": 0, "right": 602, "bottom": 1000}]
	swan.reset(Vector2(565, 500), 0.0, net, WATER)
	swan.elapsed = 4.0
	for index: int in range(30):
		swan.step(1.0 / 60.0, Vector2(625, 500), Vector2.ZERO)
		check(not swan.caught, "short-distance contact does not reach through net")
		check(swan._clear(swan.position), "local steering never enters net")
	swan.reset(Vector2(450, 500), 0.0, net, WATER)
	swan.phase = "charge"
	swan.speed = Swan.CHARGE_SPEED
	swan.elapsed = 4.0
	var result: Dictionary = swan.step(0.5, Vector2(800, 500), Vector2.ZERO)
	check(swan.position.x <= 578.0 and swan._clear(swan.position), "coarse frame cannot tunnel through two-pixel net")
	check(result.blocked and swan.phase == "recovery", "blocked charge recovers without heading snap")
	swan.reset(Vector2(250, 500), 0.0, [], WATER)
	swan.elapsed = 4.0
	result = swan.step(1.0 / 60.0, Vector2(305, 500), Vector2.ZERO)
	check(result.caught_now and result.caught, "clear nearby contact catches once")
	result = swan.step(1.0 / 60.0, Vector2(305, 500), Vector2.ZERO)
	check(not result.caught_now and result.caught, "caught event is not repeated")
