extends RefCounted
## Presentation only. One controller intent requests one stroke; no movement,
## forces, progression, controller callbacks, or save writes live here.
const NOMINAL_DURATION: float = 0.72
var active: bool = false
var paused: bool = false
var age: float = 0.0
var clock: float = 0.0
var side: String = "left"
var reverse: bool = false
var duration: float = NOMINAL_DURATION
var pending: Dictionary = {}
var previous_intent_time: float = -100.0
var blend_age: float = 1.0
var blend_duration: float = 0.0864
var blend_from: Dictionary = {}
var accepted_intents: int = 0
var started_strokes: int = 0

func reset() -> void:
	active = false
	paused = false
	age = 0.0
	clock = 0.0
	side = "left"
	reverse = false
	duration = NOMINAL_DURATION
	pending.clear()
	previous_intent_time = -100.0
	blend_age = 1.0
	blend_duration = NOMINAL_DURATION * 0.12
	blend_from.clear()
	accepted_intents = 0
	started_strokes = 0

func set_paused(value: bool) -> void:
	paused = value
	# Never replay buffered touch/key intent after focus/pause changes.
	pending.clear()

func request_stroke(request_side: String, request_reverse: bool = false) -> void:
	if paused or request_side not in ["left", "right"]: return
	accepted_intents += 1
	var interval: float = clock - previous_intent_time
	previous_intent_time = clock
	var request: Dictionary = {"side": request_side, "reverse": request_reverse, "duration": clampf(interval * 1.04, 0.20, NOMINAL_DURATION)}
	if active and float(request.duration) < duration - 0.0001 and age / duration < 0.86:
		var compressed: float = minf(duration, maxf(float(request.duration), age / 0.52))
		if compressed < duration - 0.0001:
			blend_from = pose()
			blend_age = 0.0
			duration = compressed
			blend_duration = _transition_duration()
	if not active or age / duration >= 0.86:
		_begin(request)
	else:
		# Bounded latest-intent buffer. Rapid input must not build seconds of
		# autonomous paddling after the player stops. Physics receives EVERY
		# intent separately; this coalesces presentation only.
		pending = request

func _begin(request: Dictionary) -> void:
	blend_from = pose()
	blend_age = 0.0
	active = true
	age = 0.0
	side = request.side
	reverse = request.reverse
	duration = request.duration
	blend_duration = _transition_duration()
	started_strokes += 1
	pending.clear()

func advance(delta: float) -> void:
	if paused: return
	var dt: float = maxf(0.0, delta)
	clock += dt
	blend_age += dt
	if not active: return
	age += dt
	if not pending.is_empty() and age / duration >= 0.88:
		var carry: float = maxf(0.0, age - duration * 0.88)
		_begin(pending.duplicate())
		age = carry
		blend_age = carry
	if age >= duration:
		blend_from = _sample(1.0)
		blend_age = age - duration
		blend_duration = _transition_duration()
		active = false
		age = duration

func phase() -> String:
	if not active: return "rest"
	var t: float = age / duration
	if t < 0.15: return "catch"
	if t < 0.58: return "power"
	if t < 0.72: return "exit"
	return "recovery"

func _transition_duration() -> float:
	# A catch owns 15% of the stroke. Finish easing before that boundary,
	# including a 200ms stroke, so power never starts with a dry blade.
	return minf(0.09, duration * 0.12)

func pose() -> Dictionary:
	var target: Dictionary = _sample(clampf(age / duration, 0.0, 1.0)) if active else _rest()
	if not blend_from.is_empty() and blend_age < blend_duration:
		var t: float = smoothstep(0.0, blend_duration, blend_age)
		for key: String in ["sweep", "pitch", "twist", "hip_twist", "shoulder_drive", "lean", "immersion", "lift"]:
			target[key] = lerpf(float(blend_from[key]), float(target[key]), t)
	return target

func _rest() -> Dictionary:
	return {"sweep": 0.0, "pitch": 0.0, "twist": 0.0, "hip_twist": 0.0, "shoulder_drive": 0.0, "lean": 0.0, "immersion": 0.0, "lift": 0.0, "side": side, "phase": "rest", "active": false, "reverse": reverse, "progress": 1.0}

func _sample(t: float) -> Dictionary:
	var sign_side: float = -1.0 if side == "left" else 1.0
	var direction: float = -1.0 if reverse else 1.0
	var sweep: float
	var pitch: float
	var immersion: float
	var lean: float
	var lift: float
	if t < 0.15:
		var u: float = smoothstep(0.0, 0.15, t)
		sweep = lerpf(-0.48, -0.57, u)
		pitch = lerpf(0.08, -0.24, u)
		lift = 14.0 * (1.0-u)
		immersion = smoothstep(0.42, 1.0, u)
		lean = -3.0 * u
	elif t < 0.58:
		var u: float = smoothstep(0.15, 0.58, t)
		sweep = lerpf(-0.57, 0.53, u)
		pitch = -0.24
		lift = 0.0
		immersion = 1.0
		lean = lerpf(-3.0, 2.0, u)
	elif t < 0.72:
		var u: float = smoothstep(0.58, 0.72, t)
		sweep = lerpf(0.53, 0.60, u)
		pitch = lerpf(-0.24, 0.08, u)
		lift = 14.0 * u
		immersion = 1.0 - smoothstep(0.0, 0.7, u)
		lean = lerpf(2.0, 0.0, u)
	else:
		var u: float = smoothstep(0.72, 1.0, t)
		sweep = lerpf(0.60, 0.0, u)
		pitch = lerpf(0.08, 0.0, u)
		lift = 14.0 * (1.0-u)
		immersion = 0.0
		lean = 0.0
	var drive: float = sin(PI * clampf((t-0.15)/0.43, 0.0, 1.0))
	# This is the paddle's rigid 3D axis, projected by the rig. The torso and
	# both hand targets use this same phase; they cannot drift independently.
	return {"sweep": sweep * sign_side * direction, "pitch": pitch * sign_side, "twist": (sweep * 0.36 + drive * 0.035) * sign_side * direction, "hip_twist": sweep * sign_side * direction * 0.11, "shoulder_drive": drive, "lean": lean * direction, "immersion": immersion, "lift": lift, "side": side, "phase": phase(), "active": true, "reverse": reverse, "progress": t}
