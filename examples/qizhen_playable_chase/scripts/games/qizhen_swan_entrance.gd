extends RefCounted
## A presentation clock only. It grants no story completion or inventory changes.
const DURATION: float = 7.2
const BOAT_START := Vector2(760, 500)
const SWAN_START := Vector2(1100, 322)
const SWAN_EXIT := Vector2(879, 342)
const SWAN_HANDOFF := Vector2(866, 382)
var elapsed: float = 0.0
var completed: bool = false
var paused: bool = false
var completion_count: int = 0

func reset() -> void:
	elapsed = 0.0
	completed = false
	paused = false
	completion_count = 0

func advance(delta: float) -> bool:
	if paused or completed or not is_finite(delta) or delta <= 0: return false
	elapsed = minf(DURATION, elapsed + delta)
	if elapsed < DURATION: return false
	completed = true
	completion_count += 1
	return true

func skip() -> bool:
	if completed: return false
	elapsed = DURATION
	completed = true
	completion_count += 1
	return true

func smooth_segment(a: float, b: float) -> float:
	return smoothstep(a, b, elapsed)

func pose() -> Dictionary:
	var p := SWAN_START
	var frame: int = 0
	var next: int = 0
	var mix: float = 0
	var beat: float = 0
	var heading: float = PI
	var reveal: float = smooth_segment(0.65, 1.45)
	var camera := Vector2(925, 440)
	var zoom: float = 1.0
	var gate: float = smooth_segment(0.45, 1.65)
	var phase: String = "水面有动静"
	if elapsed < 1.4:
		p = SWAN_START.lerp(Vector2(1040, 322), smooth_segment(0.7, 1.4))
		camera = camera.lerp(Vector2(1005, 360), smooth_segment(0, 1.4))
		zoom = lerpf(1.0, 1.65, smooth_segment(0, 1.4))
	elif elapsed < 3.0:
		p = Vector2(1040, 322).lerp(SWAN_EXIT, smooth_segment(1.4, 3.0))
		camera = Vector2(1005, 360).lerp(Vector2(894, 382), smooth_segment(1.4, 3.0))
		zoom = 1.65
		phase = "围栏松开了"
	elif elapsed < 4.15:
		p = SWAN_EXIT
		frame = 0
		next = 1
		mix = smooth_segment(3.05, 3.45)
		camera = Vector2(894, 382)
		zoom = 1.65
		heading = lerpf(PI, 2.8, smooth_segment(3.1, 3.65))
		phase = "它看向了船"
	elif elapsed < 4.75:
		p = SWAN_EXIT
		frame = 1
		next = 2
		mix = smooth_segment(4.15, 4.45)
		camera = Vector2(894, 382)
		zoom = 1.65
		heading = 2.8
		phase = "准备划桨"
	elif elapsed < 5.85:
		var wing_clock: float = (elapsed - 4.75) / 0.18
		var sequence: Array[int] = [2, 3, 4, 5, 6, 3, 4]
		var index: int = mini(5, int(wing_clock))
		frame = sequence[index]
		next = sequence[index + 1]
		mix = fmod(wing_clock, 1.0)
		beat = sin((elapsed - 4.75) / 1.1 * PI * 3.0)
		p = SWAN_EXIT.lerp(Vector2(875, 351), smooth_segment(4.75, 5.85))
		camera = Vector2(894, 382)
		zoom = 1.65
		heading = 2.8
		phase = "扑翅拍水"
	else:
		p = Vector2(875, 351).lerp(SWAN_HANDOFF, smooth_segment(5.85, 6.8))
		frame = 6
		next = 7
		mix = smooth_segment(6.15, 6.8)
		camera = Vector2(894, 382).lerp(Vector2(800, 490), smooth_segment(5.85, DURATION))
		zoom = lerpf(1.65, 1.02, smooth_segment(5.85, DURATION))
		heading = 2.8
		phase = "交替划桨，朝南口离开"
	return {"position": p, "frame": frame, "next_frame": next, "blend": mix,
		"heading": heading, "reveal": reveal, "wing": beat, "gate": gate,
		"camera": camera, "zoom": zoom, "phase": phase,
		"letterbox": 1.0 - smooth_segment(6.05, DURATION)}
