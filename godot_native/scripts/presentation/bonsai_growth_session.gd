extends RefCounted
## Read-only, mounted-page presentation. No save keys, rewards or timer intents.
const DURATION_MS := 4800.0
const STAGGER_MS := 160.0
var bound_state: Dictionary = {}
var observed_bloom := false
var mounted := false
var started_ms := -1

func route(page: String) -> void:
	if page not in ["bonsai", "control_center"]:
		reset()

func reset() -> void:
	bound_state = {}; mounted = false; observed_bloom = false; started_ms = -1

func observe(state: Dictionary) -> void:
	var bloom := bool(state.flags.flowerBloomed)
	if not mounted or not is_same(bound_state, state):
		bound_state = state; observed_bloom = bloom; mounted = true; started_ms = -1
	elif bloom and not observed_bloom:
		started_ms = Time.get_ticks_msec()
	elif not bloom:
		started_ms = -1
	observed_bloom = bloom
	if bool(state.native.get("flower_eight_visible", false)) or bool(state.flags.flowerEightTaken):
		finish()

func finish() -> void:
	started_ms = -1

func age_ms() -> float:
	return DURATION_MS if started_ms < 0 else minf(DURATION_MS, Time.get_ticks_msec() - started_ms)

func active() -> bool:
	return started_ms >= 0 and age_ms() < DURATION_MS

static func pose(age: float, blossom: int, reduced: bool = false) -> Dictionary:
	var local := maxf(0.0, age - STAGGER_MS * blossom)
	# Real atlas poses: anticipation/closed, swelling, outside petals, inner cup,
	# open corolla. Twenty-four distinct drawings, not 24 fps or rescaled stills.
	var frame := 0
	if local >= 1450.0:
		frame = clampi(int(floor((local - 1450.0) / 2800.0 * 23.0)), 0, 23)
	var lift := 0.0 if reduced else 8.0 * (1.0 - smoothstep(0.0, 850.0, local))
	var settle := 0.0
	if not reduced and local >= 3550.0 and local < 4250.0:
		var t := (local - 3550.0) / 700.0
		settle = sin(t * TAU) * (1.0 - t) * 2.0
	return {"frame": frame, "lift": lift + settle, "angle": 0.0 if reduced else settle * 0.004,
		"atlas_mix": smoothstep(1290.0, 1450.0, local),
		"source_mix": smoothstep(4050.0, 4250.0, local), "finished": age >= DURATION_MS}
