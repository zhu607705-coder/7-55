extends RefCounted
## Low-voltage teaching model. Owns experiment facts, never chapter/save state.
const IDLE := [2, 1, 1, 2, 2]
const ACTIVE := [3, 3, 2, 2, 0]
const TRIAL_SECONDS := 1.2
var assignments: Array[int] = [0, 0, 1, 1, -1]
var extension := false
var revision := 0
var mode := 0
var running := false
var paused := false
var elapsed := 0.0
var tested_revision := -1
var tested_device := -1
var receipts: Dictionary = {}
var completed := false
var extension_completed := false
var outcome := ""
var history: Array[Dictionary] = []
var undo_stack: Array[Dictionary] = []

func device_count() -> int: return 5 if extension else 4
func limit(for_mode: int) -> int: return 4 if extension and for_mode == 0 else 5
func loads(for_mode: int) -> Array[int]:
	var result: Array[int] = [0, 0]
	var values: Array = IDLE if for_mode == 0 else ACTIVE
	for i: int in device_count():
		if assignments[i] in [0, 1]: result[assignments[i]] += int(values[i])
	return result
func all_connected() -> bool:
	for i: int in device_count():
		if assignments[i] not in [0, 1]: return false
	return true
func valid_mode(for_mode: int) -> bool:
	if for_mode not in [0, 1] or not all_connected(): return false
	var values := loads(for_mode)
	return values[0] <= limit(for_mode) and values[1] <= limit(for_mode)
func _snapshot() -> Dictionary: return {"assignments": assignments.duplicate(), "extension": extension}
func _invalidate() -> void:
	if not receipts.is_empty(): history.append({"revision": revision, "receipts": receipts.duplicate(true)})
	revision += 1
	receipts.clear()
	cancel()
	outcome = ""
func connect_device(device: int, branch: int) -> bool:
	if device < 0 or device >= device_count() or branch not in [-1, 0, 1]: return false
	if assignments[device] == branch: return true
	undo_stack.append(_snapshot())
	_invalidate()
	assignments[device] = branch
	return true
func set_extension(value: bool) -> bool:
	if extension == value: return true
	undo_stack.append(_snapshot())
	_invalidate()
	extension = value
	assignments[4] = -1
	return true
func undo() -> bool:
	if undo_stack.is_empty(): return false
	var saved: Dictionary = undo_stack.pop_back()
	_invalidate()
	assignments.assign(saved.assignments)
	extension = bool(saved.extension)
	return true
func start(for_mode: int, single_device := -1) -> bool:
	if for_mode not in [0, 1] or running or single_device < -1 or single_device >= device_count(): return false
	tested_device = single_device
	mode = for_mode
	running = true
	paused = false
	elapsed = 0.0
	tested_revision = revision
	outcome = ""
	return true
func pause() -> void:
	if running: paused = true
func resume() -> bool:
	if not running or not paused: return false
	paused = false
	return true
func cancel() -> void:
	running = false
	paused = false
	elapsed = 0.0
	tested_revision = -1
	tested_device = -1
func step(dt: float) -> void:
	if not running or paused or dt <= 0.0 or not is_finite(dt): return
	elapsed = minf(elapsed + dt, TRIAL_SECONDS)
	if elapsed < TRIAL_SECONDS: return
	running = false
	if tested_revision != revision: return
	if tested_device >= 0:
		outcome = "single_passed" if assignments[tested_device] >= 0 else "unplugged"
		return
	var passed := valid_mode(mode)
	receipts[mode] = {"revision": revision, "passed": passed, "loads": loads(mode)}
	outcome = "passed" if passed else ("unplugged" if not all_connected() else "overload")
	if _current_passed(0) and _current_passed(1):
		completed = true
		if extension: extension_completed = true
func _current_passed(for_mode: int) -> bool:
	var receipt: Dictionary = receipts.get(for_mode, {})
	return int(receipt.get("revision", -1)) == revision and bool(receipt.get("passed", false))
func displayed_loads() -> Array[int]:
	if tested_device < 0: return loads(mode)
	var result: Array[int] = [0, 0]
	var branch: int = assignments[tested_device]
	if branch >= 0: result[branch] = int((IDLE if mode == 0 else ACTIVE)[tested_device])
	return result
func branch_powered(branch: int) -> bool:
	return branch in [0, 1] and (running or not outcome.is_empty()) and displayed_loads()[branch] <= limit(mode)
func device_powered(device: int) -> bool:
	return (tested_device < 0 or tested_device == device) and branch_powered(assignments[device])
