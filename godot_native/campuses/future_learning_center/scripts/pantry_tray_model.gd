extends RefCounted
## Session-only experiment. Water quantity, flow and earned trials live here.
const ARMS := [-2.0, -1.0, 1.0, 2.0]
const TARGETS := [60.0, 90.0, 120.0, 150.0]
const BAND := 8.0
const CAPACITY := 180.0
const FLOW_ML_PER_SECOND := 4.0 # A full empty glass takes 45 seconds.
const DRAIN_ML_PER_SECOND := 48.0
const GLASS_TARE := 40.0
const TRAY_TARE := 120.0
const SUPPORT_STOPS := [-.25, 0.0, .25]
const TOLERANCE := 8.0
const LIFT_SECONDS := .65
const DELIVERY_SECONDS := 1.4
var cups: Array[int] = [0, 1, 2, 3]
var water: Array[float] = [0.0, 0.0, 0.0, 0.0]
var dock_slot := -1
var tap_open := false
var draining := false
var dispensed_ml := 0.0
var support := 0.0
var phase := "table"
var elapsed := 0.0
var revision := 0
var trial_revision := -1
var earned := false
var advanced_earned := false
var deliveries := 0
var attempts := 0
var last_moment := 0.0

func moment() -> float:
	var total := -TRAY_TARE * support
	for i: int in 4: total += (GLASS_TARE + water[cups[i]]) * (ARMS[i] - support)
	return total

func stable() -> bool: return absf(moment()) <= TOLERANCE
func editable() -> bool: return phase in ["table", "tilted"]
func portion_ready(cup: int) -> bool: return cup >= 0 and cup < 4 and absf(water[cup] - TARGETS[cup]) <= BAND + .001
func portions_ready() -> bool:
	for cup: int in 4:
		if not portion_ready(cup): return false
	return true
func ready() -> bool: return dock_slot == -1 and portions_ready() and stable()
func flowing() -> bool: return tap_open and dock_slot >= 0 and not draining and editable()

func swap(a: int, b: int) -> bool:
	if not editable() or dock_slot >= 0 or a < 0 or b < 0 or a >= 4 or b >= 4 or a == b: return false
	lower()
	var cup := cups[a]; cups[a] = cups[b]; cups[b] = cup
	revision += 1
	return true

func dock(slot: int) -> bool:
	if not editable() or dock_slot >= 0 or slot < 0 or slot > 3: return false
	lower(); dock_slot = slot; revision += 1
	return true

func undock(target: int) -> bool:
	if not editable() or dock_slot < 0 or target < 0 or target > 3: return false
	var source := dock_slot
	stop_water(); dock_slot = -1
	if target != source:
		var cup := cups[source]; cups[source] = cups[target]; cups[target] = cup
	revision += 1
	return true

func set_tap(value: bool) -> bool:
	if value and (not editable() or dock_slot < 0 or draining): return false
	tap_open = value
	return true

func set_draining(value: bool) -> void:
	draining = value and editable() and dock_slot >= 0
	if draining: tap_open = false

func stop_water() -> void:
	tap_open = false; draining = false

func move_support(value: float) -> bool:
	if not earned or not editable() or dock_slot >= 0 or not value in SUPPORT_STOPS or value == support: return false
	lower(); support = value; revision += 1
	return true

func lift() -> bool:
	if not editable() or dock_slot >= 0: return false
	stop_water(); phase = "lifting"; elapsed = 0; trial_revision = revision
	attempts += 1; last_moment = moment()
	return true

func send() -> bool:
	if phase != "held" or revision != trial_revision or not ready(): return false
	phase = "delivering"; elapsed = 0
	return true

func lower() -> void:
	stop_water(); phase = "table"; elapsed = 0; trial_revision = -1

func cancel() -> void:
	stop_water()
	if phase != "delivered": lower()

func step(dt: float) -> void:
	if not is_finite(dt) or dt <= 0: return
	# No background catch-up or a frame hitch can jump over a water band.
	var seconds := minf(dt, .1)
	if dock_slot >= 0 and editable():
		var cup := cups[dock_slot]
		var before := water[cup]
		if draining: water[cup] = maxf(0, before - seconds * DRAIN_ML_PER_SECOND)
		elif flowing():
			water[cup] = minf(CAPACITY, before + seconds * FLOW_ML_PER_SECOND)
			dispensed_ml += water[cup] - before
			if water[cup] >= CAPACITY: tap_open = false
		if water[cup] != before: revision += 1
	if not phase in ["lifting", "delivering"]: return
	if trial_revision != revision: lower(); return
	elapsed += seconds
	if phase == "lifting" and elapsed >= LIFT_SECONDS:
		phase = "held" if stable() else "tilted"; elapsed = 0
	elif phase == "delivering":
		if not ready(): lower(); return
		if elapsed >= DELIVERY_SECONDS:
			phase = "delivered"; deliveries += 1; earned = true
			advanced_earned = advanced_earned or support != 0
			elapsed = 0
