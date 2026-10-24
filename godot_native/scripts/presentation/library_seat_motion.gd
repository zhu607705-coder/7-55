extends RefCounted
## Disposable poses derived from successful controller facts. No progress writes.
const NOTE_AT := Vector2(1282, 422)
const NOTE_START := Vector2(1261, 408)
const GAP_AT := Vector2(1368, 445)
const INSPECT_MS := 1000.0
const PICKUP_MS := 720.0
const RECEIPT_MS := 1320.0
const REDUCED_MS := 180.0
var bound_state: Dictionary = {}
var active := false
var inspected := false
var note_collected := false
var receipt_collected := false
var reduced := false
var inspect_ms := -1.0
var note_ms := -1.0
var receipt_ms := -1.0
var pickup_from := NOTE_AT
var pickup_angle := 0.0
var pickup_size := Vector2(42, 30)
var pickup_bend := 0.0
var view_ref: WeakRef
var visibility_listener: Callable
var exit_listener: Callable

func sync(state: Dictionary, replaced: bool = false) -> void:
	var here: bool = state.get("native", {}).get("scene", "") == "library_interior"
	var puzzle: Dictionary = state.get("ui", {}).get("libraryFinalsPuzzle", {})
	reduced = bool(state.get("native", {}).get("settings", {}).get("reduced_motion", false))
	if not here or not active or replaced or not is_same(bound_state, state):
		settle()
	else:
		if not inspected and puzzle.get("backpackInspected", false): inspect_ms = 0.0
		if not note_collected and puzzle.get("occupancyNoteCollected", false):
			# A quick second tap starts at the paper's current rendered position.
			var prior: Dictionary = note_pose()
			pickup_from = prior.position; pickup_angle = prior.angle
			pickup_size = Vector2(prior.width,prior.height); pickup_bend = prior.bend
			note_ms = 0.0
		if not receipt_collected and puzzle.get("seatReceiptCollected", false): receipt_ms = 0.0
	bound_state = state
	active = here
	inspected = bool(puzzle.get("backpackInspected", false))
	note_collected = bool(puzzle.get("occupancyNoteCollected", false))
	receipt_collected = bool(puzzle.get("seatReceiptCollected", false))
	if not _visible(): settle()

func advance(delta: float) -> void:
	if not active or not _visible(): settle(); return
	if not is_finite(delta) or delta <= 0: return
	var elapsed: float = delta * 1000.0
	if inspect_ms >= 0:
		inspect_ms += elapsed
		if inspect_ms >= (REDUCED_MS if reduced else INSPECT_MS): inspect_ms = -1.0
	if note_ms >= 0:
		note_ms += elapsed
		if note_ms >= (REDUCED_MS if reduced else PICKUP_MS): note_ms = -1.0
	if receipt_ms >= 0:
		receipt_ms += elapsed
		if receipt_ms >= (REDUCED_MS if reduced else RECEIPT_MS): receipt_ms = -1.0

func settle() -> void:
	inspect_ms = -1.0; note_ms = -1.0; receipt_ms = -1.0

func bag_pose() -> Dictionary:
	var lean := 0.0
	if active and inspect_ms >= 0 and not reduced:
		lean = smoothstep(0.0, 230.0, inspect_ms) * (1.0 - smoothstep(520.0, INSPECT_MS, inspect_ms))
	return {"offset": Vector2(-5, -3) * lean, "angle": -10.0 * lean}

func note_pose() -> Dictionary:
	var at := NOTE_AT
	var angle := 0.0
	var bend := 0.0
	var alpha := 1.0
	var dimensions := Vector2(42, 30)
	if inspect_ms >= 0 and not reduced:
		var reveal: float = smoothstep(140.0, 820.0, inspect_ms)
		at = NOTE_START.lerp(NOTE_AT, reveal)
		angle = lerpf(-18.0, 0.0, reveal)
		bend = sin(reveal * PI) * 5.0
		dimensions = Vector2(8,18).lerp(Vector2(42,30),reveal)
		alpha = smoothstep(80.0,180.0,inspect_ms)
	elif inspect_ms >= 0:
		alpha = smoothstep(0.0, REDUCED_MS, inspect_ms)
	if note_ms >= 0:
		var lift: float = smoothstep(0.0, PICKUP_MS, note_ms)
		at = pickup_from + Vector2(9, -40) * (0.0 if reduced else lift)
		angle = pickup_angle + (0.0 if reduced else -12.0 * lift)
		bend = 0.0 if reduced else lerpf(pickup_bend,0.0,lift) + sin(lift * PI) * 7.0
		dimensions = pickup_size.lerp(Vector2(42,30),lift)
		alpha = 1.0 - smoothstep(0.0 if reduced else 370.0, REDUCED_MS if reduced else PICKUP_MS, note_ms)
	return {"visible": active and ((inspected and not note_collected) or note_ms >= 0), "position": at, "angle": angle, "bend": bend, "alpha": alpha, "width": dimensions.x, "height": dimensions.y}

func receipt_pose() -> Dictionary:
	var at := GAP_AT
	var width := 8.0
	var height := 12.0
	var angle := 0.0
	var bend := 2.0
	var alpha := 1.0
	var arrow := 0.0
	var arrow_at := GAP_AT + Vector2(-34, 0)
	if receipt_ms >= 0:
		if reduced:
			width = 42.0; height = 24.0; at += Vector2(20, -6); bend = 0.0
			alpha = 1.0 - smoothstep(0.0, REDUCED_MS, receipt_ms)
		else:
			var insert: float = smoothstep(0.0, 240.0, receipt_ms)
			var extract: float = smoothstep(220.0, 740.0, receipt_ms)
			var lift: float = smoothstep(760.0, RECEIPT_MS, receipt_ms)
			arrow_at += Vector2(22.0 * insert + 18.0 * extract, 0)
			arrow = smoothstep(0.0, 80.0, receipt_ms) * (1.0 - smoothstep(740.0, 900.0, receipt_ms))
			width = lerpf(8.0, 42.0, extract)
			height = lerpf(12.0, 24.0, extract)
			at += Vector2(30.0 * extract + 8.0 * lift, -6.0 * extract - 26.0 * lift)
			angle = -8.0 * extract - 5.0 * lift
			bend = lerpf(2.0, 0.0, extract) + 5.0 * sin(lift * PI)
			alpha = 1.0 - smoothstep(950.0, RECEIPT_MS, receipt_ms)
	return {"visible": active and (not receipt_collected or receipt_ms >= 0), "position": at, "angle": angle, "bend": bend, "alpha": alpha, "width": width, "height": height, "arrowAlpha": arrow, "arrowPosition": arrow_at}

static func paper_outline(pose: Dictionary) -> PackedVector2Array:
	var half := Vector2(float(pose.width), float(pose.height)) / 2.0
	var bend: float = pose.bend
	return PackedVector2Array([Vector2(-half.x,-half.y), Vector2(0,-half.y-bend), Vector2(half.x,-half.y), Vector2(half.x,half.y), Vector2(0,half.y-bend), Vector2(-half.x,half.y)])

static func paper_geometry(pose: Dictionary) -> Dictionary:
	return {"polygon": paper_outline(pose), "transform": Transform2D(deg_to_rad(float(pose.angle)), Vector2(pose.position))}

func bind_view(view: CanvasItem) -> void:
	if view_ref != null and view_ref.get_ref() == view: return
	_disconnect_view()
	view_ref = weakref(view)
	var receiver: WeakRef = weakref(self)
	visibility_listener = func():
		var motion: RefCounted = receiver.get_ref()
		if motion != null and not motion._visible(): motion.settle()
	exit_listener = func():
		var motion: RefCounted = receiver.get_ref()
		if motion != null: motion.settle(); motion.active = false; motion._disconnect_view()
	view.visibility_changed.connect(visibility_listener)
	view.tree_exiting.connect(exit_listener)
	if not _visible(): settle()

func _visible() -> bool:
	var view: CanvasItem = view_ref.get_ref() if view_ref != null else null
	return view_ref == null or (is_instance_valid(view) and view.is_inside_tree() and view.is_visible_in_tree())

func _disconnect_view() -> void:
	var view: CanvasItem = view_ref.get_ref() if view_ref != null else null
	if is_instance_valid(view):
		if visibility_listener.is_valid() and view.visibility_changed.is_connected(visibility_listener): view.visibility_changed.disconnect(visibility_listener)
		if exit_listener.is_valid() and view.tree_exiting.is_connected(exit_listener): view.tree_exiting.disconnect(exit_listener)
	view_ref = null

func _notification(what: int) -> void:
	if what != NOTIFICATION_PREDELETE: return
	var view: CanvasItem = view_ref.get_ref() if view_ref != null else null
	if is_instance_valid(view):
		if visibility_listener.is_valid() and view.visibility_changed.is_connected(visibility_listener): view.visibility_changed.disconnect(visibility_listener)
		if exit_listener.is_valid() and view.tree_exiting.is_connected(exit_listener): view.tree_exiting.disconnect(exit_listener)
