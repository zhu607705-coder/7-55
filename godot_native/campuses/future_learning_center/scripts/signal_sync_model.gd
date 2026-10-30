extends RefCounted
## Isolated room experiment. No production quest, inventory or save writes.
const OUTPUTS := ["live", "cached", "split_a", "split_b"]
const INPUTS := ["split", "left", "right"]
const INITIAL := {"split":"live", "left":"split_a", "right":"cached"}
const HOP_SECONDS := 0.45
var wires: Dictionary = INITIAL.duplicate()
var history: Array[Dictionary] = []
var revision := 0
var source_pattern := 1
var cached_pattern := 0
var displayed := {"left":1, "right":0}
var received := {"left":false, "right":false}
var verified_patterns: Array[int] = []
var running := false
var elapsed := 0.0
var run_revision := -1
var complete := false
var earned := false
var outcome := "ready"

func connect_ports(output: String, input: String) -> bool:
	if not output in OUTPUTS or not input in INPUTS: return false
	if input == "split" and output.begins_with("split_"): return false
	if wires.get(input, "") == output: return false
	history.append(wires.duplicate())
	# Each physical output socket holds one cable; the splitter has two outputs.
	for target: String in INPUTS:
		if wires.get(target, "") == output: wires.erase(target)
	wires[input] = output
	_invalidate()
	return true

func disconnect_port(input: String) -> bool:
	if not input in INPUTS or not wires.has(input): return false
	history.append(wires.duplicate()); wires.erase(input); _invalidate()
	return true

func undo() -> bool:
	if history.is_empty(): return false
	wires = history.pop_back(); _invalidate(); return true

func reset() -> void:
	history.append(wires.duplicate()); wires = INITIAL.duplicate(); _invalidate()
	source_pattern = 1; displayed = {"left":1, "right":0}; outcome = "ready"

func _invalidate() -> void:
	revision += 1; running = false; elapsed = 0
	complete = false; verified_patterns.clear(); received = {"left":false, "right":false}
	outcome = "edited"
	if history.size() > 32: history.pop_front()

func source_for(input: String) -> Dictionary:
	var output: String = wires.get(input, "")
	if output in ["live", "cached"]: return {"kind":output, "hops":1}
	if output in ["split_a", "split_b"] and input != "split":
		var upstream := source_for("split")
		return {"kind":upstream.kind, "hops":int(upstream.hops) + 1}
	return {"kind":"none", "hops":0}

func change_pattern() -> bool:
	if running: return false
	return apply_pattern((source_pattern + 1) % 3)

func apply_pattern(value: int) -> bool:
	if running or value<0 or value>2 or value==source_pattern: return false
	source_pattern=value
	return transmit()

func transmit() -> bool:
	if running: return false
	run_revision = revision; elapsed = 0; running = true; complete = false
	received = {"left":false, "right":false}; outcome = "running"
	return true

func step(dt: float) -> void:
	if not running or dt <= 0 or not is_finite(dt): return
	if run_revision != revision: cancel(); return
	elapsed += minf(dt, 1.5)
	for target: String in ["left", "right"]:
		var source := source_for(target)
		if source.kind == "live" and elapsed >= float(source.hops) * HOP_SECONDS:
			displayed[target] = source_pattern; received[target] = true
		elif source.kind == "cached": displayed[target] = cached_pattern
		elif source.kind == "none": displayed[target] = -1
	if elapsed < HOP_SECONDS * 2 + 0.15: return
	running = false
	if received.left and received.right:
		if not source_pattern in verified_patterns: verified_patterns.append(source_pattern)
		complete = verified_patterns.size() >= 2
		earned = earned or complete
		outcome = "passed" if complete else "one_change"
	else: outcome = "mismatch"

func cancel() -> void:
	if running: outcome = "cancelled"
	running = false

func message() -> String:
	return {
		"ready":"源端和两台屏幕的角标不一样，改一次稿件看看。",
		"edited":"连接已改变。可以再改稿件，看看两边收到什么。",
		"running":"稿件正在传送，观察它沿哪条线走到屏幕。",
		"one_change":"这次两边都收到新稿，再修改一处看看是否仍跟随。",
		"passed":"两次不同的修改都同步到了，两台屏幕会继续跟随稿件。",
		"mismatch":"有屏幕没有收到这次修改，保留现场再比较一次。",
		"cancelled":"本次传送已中止，回到台面后可重新改稿试验。"
	}.get(outcome, "")
