extends RefCounted
## Only this local paper clock can rewind. The folder is NOT in its history.
## No controller, autoload, inventory, save, award or story-proof dependency.

const DURATION := 9.0
const ENTRY_TIME := 6.5
const REWIND_RATE := 1.8
const TICK := 1.0 / 120.0
const SETTLE_DURATION := 1.05
const FOLDER_RECT := Rect2(485, 234, 230, 138)
const CATCH_RECT := Rect2(503, 218, 184, 92)
const REST_POINT := Vector2(593, 303)
const PAPER_HALF := Vector2(22, 27)

var time := ENTRY_TIME
var mode := "intro"
var folder_open := false
var catch_time := -1.0
var catch_position := Vector2.ZERO
var ever_rewound := false
var failed_once := false
var completion_count := 0
var paper_collected := false
var _accumulator := 0.0

func reset() -> void:
	time = ENTRY_TIME
	mode = "intro"
	folder_open = false
	catch_time = -1.0
	catch_position = Vector2.ZERO
	ever_rewound = false
	failed_once = false
	completion_count = 0
	paper_collected = false
	_accumulator = 0.0

func start() -> bool:
	if mode != "intro":
		return false
	mode = "forward"
	return true

func play() -> bool:
	if mode not in ["paused", "rewind"] or time >= DURATION:
		return false
	mode = "forward"
	_accumulator = 0.0
	return true

func pause() -> bool:
	if mode not in ["forward", "rewind"]:
		return false
	mode = "paused"
	_accumulator = 0.0
	return true

func rewind() -> bool:
	if mode in ["intro", "solved", "cancelled"] or time <= 0.0:
		return false
	mode = "rewind"
	_accumulator = 0.0
	return true

func seek(value: float) -> bool:
	if mode in ["intro", "solved", "cancelled"] or not is_finite(value):
		return false
	var target := clampf(value, 0.0, DURATION)
	if target < time:
		ever_rewound = true
	time = target
	# Preview is never a collision and never earns a catch/completion.
	catch_time = -1.0
	catch_position = Vector2.ZERO
	mode = "paused"
	_accumulator = 0.0
	return true

func open_folder() -> bool:
	if folder_open or mode in ["intro", "solved", "cancelled"]:
		return false
	folder_open = true
	return true

func retry_paper() -> bool:
	if mode in ["intro", "cancelled"]:
		return false
	# An explicit paper-only reset retains the player's environmental change.
	time = 0.0
	catch_time = -1.0
	catch_position = Vector2.ZERO
	paper_collected = false
	mode = "paused"
	_accumulator = 0.0
	return true

func collect() -> bool:
	if mode != "landed" or catch_time < 0.0 or not folder_open:
		return false
	mode = "solved"
	paper_collected = true
	completion_count += 1
	return true

func cancel() -> bool:
	if mode == "cancelled":
		return false
	mode = "cancelled"
	_accumulator = 0.0
	return true

func advance(delta: float) -> void:
	if not is_finite(delta) or delta <= 0.0 or mode not in ["forward", "rewind"]:
		return
	# Fixed steps plus swept contact make large frames and low FPS deterministic.
	_accumulator += delta
	while _accumulator + 0.0000001 >= TICK and mode in ["forward", "rewind"]:
		_accumulator = maxf(0.0, _accumulator - TICK)
		_step()

func _step() -> void:
	if mode == "rewind":
		time = maxf(0.0, time - TICK * REWIND_RATE)
		ever_rewound = true
		if time < catch_time:
			catch_time = -1.0
		if time <= 0.000001:
			time = 0.0
			mode = "paused"
		return
	var previous := time
	time = minf(DURATION, time + TICK)
	if catch_time < 0.0 and folder_open:
		var a := free_position(previous)
		var b := free_position(time)
		# The wide physical opening, not a timeline threshold, accepts the paper.
		if segment_hits_rect(a, b, CATCH_RECT.grow(8.0)):
			catch_time = previous
			catch_position = a
	if catch_time >= 0.0 and time - catch_time >= SETTLE_DURATION:
		time = catch_time + SETTLE_DURATION
		mode = "landed"
	elif time >= DURATION:
		mode = "failed"
		failed_once = true

static func free_position(at_time: float) -> Vector2:
	return Vector2(110.0 + 98.0 * at_time, 170.0 + 17.0 * at_time + 18.0 * sin(at_time * 1.1))

func paper_position() -> Vector2:
	if catch_time < 0.0:
		return free_position(time)
	var amount := clampf((time - catch_time) / SETTLE_DURATION, 0.0, 1.0)
	return catch_position.lerp(REST_POINT, amount * amount * (3.0 - 2.0 * amount))

static func segment_hits_rect(a: Vector2, b: Vector2, rect: Rect2) -> bool:
	var near := 0.0
	var far := 1.0
	var movement := b - a
	for axis: int in range(2):
		if absf(movement[axis]) < 0.0000001:
			if a[axis] < rect.position[axis] or a[axis] > rect.end[axis]:
				return false
		else:
			var one: float = (rect.position[axis] - a[axis]) / movement[axis]
			var two: float = (rect.end[axis] - a[axis]) / movement[axis]
			near = maxf(near, minf(one, two))
			far = minf(far, maxf(one, two))
			if near > far:
				return false
	return true

func snapshot() -> Dictionary:
	return {"time": time, "mode": mode, "folder_open": folder_open,
		"paper_position": paper_position(), "catch_time": catch_time,
		"ever_rewound": ever_rewound, "failed_once": failed_once,
		"completion_count": completion_count, "paper_collected": paper_collected}
