extends RefCounted
## Disposable source-pixel parts; the original controller owns the inspection.
const Picker = preload("res://scripts/world_object_picker.gd")
const DRAWER := Rect2(5, 76, 50, 10)
const LATCH := Rect2(22, 77, 17, 4)
const PAPER := Rect2(17, 59, 27, 6)
const TRAVEL := Vector2(-2, 10)
const DURATION_MS := 1320.0
const REDUCED_MS := 180.0
const OBSERVATION := "打印机显示缺纸；旁边的纸盒显示库存充足。"
var bound_state: Dictionary = {}
var active := false
var playing := false
var elapsed_ms := 0.0
var reduced := false
var inspections := 0
var state_ref: WeakRef
var view_ref: WeakRef
var action_listener: Callable
var visibility_listener: Callable
var exit_listener: Callable

func sync(state: Dictionary, available: bool, replaced: bool = false) -> void:
	if replaced or not is_same(bound_state, state) or not available: cancel()
	bound_state = state
	active = available and str(state.get("native", {}).get("scene", "")) == "library_interior"
	reduced = bool(state.get("native", {}).get("settings", {}).get("reduced_motion", false))
	if not active:
		_disconnect_state()
		return
	var loop: MainLoop = Engine.get_main_loop()
	var owner: Node = (loop as SceneTree).root.get_node_or_null("State") if loop is SceneTree else null
	if owner != null and is_same(owner.get("d"), bound_state): _bind_state(owner)
	else: _disconnect_state()
	if not _visible(): cancel()

func _bind_state(owner: Node) -> void:
	if state_ref != null and state_ref.get_ref() == owner: return
	_disconnect_state()
	state_ref = weakref(owner)
	# The singleton must not retain a RefCounted presentation or its world.
	var receiver: WeakRef = weakref(self)
	action_listener = func(action: String, before: Dictionary, next: Dictionary, result: Dictionary):
		var observer: RefCounted = receiver.get_ref()
		if observer != null: observer.observe(action, before, next, result)
	owner.connect("action_completed", action_listener)

func _disconnect_state() -> void:
	var owner: Node = state_ref.get_ref() if state_ref != null else null
	if is_instance_valid(owner) and action_listener.is_valid() and owner.is_connected("action_completed", action_listener):
		owner.disconnect("action_completed", action_listener)
	state_ref = null
	action_listener = Callable()

func bind_view(view: CanvasItem) -> void:
	if view_ref != null and view_ref.get_ref() == view: return
	_disconnect_view()
	view_ref = weakref(view)
	var receiver: WeakRef = weakref(self)
	visibility_listener = func():
		var observer: RefCounted = receiver.get_ref()
		if observer != null: observer.visibility_changed()
	exit_listener = func():
		var observer: RefCounted = receiver.get_ref()
		if observer != null: observer.dispose()
	view.visibility_changed.connect(visibility_listener)
	view.tree_exiting.connect(exit_listener)
	visibility_changed()

func _disconnect_view() -> void:
	var view: CanvasItem = view_ref.get_ref() if view_ref != null else null
	if is_instance_valid(view):
		if visibility_listener.is_valid() and view.visibility_changed.is_connected(visibility_listener): view.visibility_changed.disconnect(visibility_listener)
		if exit_listener.is_valid() and view.tree_exiting.is_connected(exit_listener): view.tree_exiting.disconnect(exit_listener)
	view_ref = null
	visibility_listener = Callable()
	exit_listener = Callable()

func _visible() -> bool:
	var view: CanvasItem = view_ref.get_ref() if view_ref != null else null
	return view_ref == null or (is_instance_valid(view) and view.is_inside_tree() and view.is_visible_in_tree())

func visibility_changed() -> void:
	if not _visible(): cancel()

static func accepted(action: String, before: Dictionary, next: Dictionary, result: Dictionary) -> bool:
	if action != "lib_printer" or not result.get("handled", false) or str(result.get("message", "")) != OBSERVATION: return false
	for snapshot: Dictionary in [before, next]:
		var native: Dictionary = snapshot.get("native", {})
		if native.get("scene") != "library_interior" or int(native.get("chapter", 1)) != 2: return false
		if str(snapshot.get("ui", {}).get("libraryFinalsPhase", "idle")) == "idle": return false
	return true

func observe(action: String, before: Dictionary, next: Dictionary, result: Dictionary) -> void:
	var owner: Node = state_ref.get_ref() if state_ref != null else null
	if not active or not _visible() or not is_instance_valid(owner) or not is_same(owner.get("d"), bound_state):
		cancel()
		return
	if playing or not accepted(action, before, next, result): return
	playing = true
	elapsed_ms = 0.0
	inspections += 1

func advance(delta: float) -> void:
	if not playing or not is_finite(delta) or delta <= 0: return
	if not active or not _visible(): cancel(); return
	elapsed_ms = minf(elapsed_ms + delta * 1000.0, REDUCED_MS if reduced else DURATION_MS)
	if elapsed_ms >= (REDUCED_MS if reduced else DURATION_MS): cancel()

func cancel() -> void:
	playing = false
	elapsed_ms = 0.0

func dispose() -> void:
	cancel()
	active = false
	bound_state = {}
	_disconnect_state()
	_disconnect_view()

func _notification(what: int) -> void:
	if what != NOTIFICATION_PREDELETE: return
	# RefCounted has already reached zero here; do not invoke an instance method.
	var owner: Node = state_ref.get_ref() if state_ref != null else null
	if is_instance_valid(owner) and action_listener.is_valid() and owner.is_connected("action_completed", action_listener): owner.disconnect("action_completed", action_listener)
	var view: CanvasItem = view_ref.get_ref() if view_ref != null else null
	if is_instance_valid(view):
		if visibility_listener.is_valid() and view.visibility_changed.is_connected(visibility_listener): view.visibility_changed.disconnect(visibility_listener)
		if exit_listener.is_valid() and view.tree_exiting.is_connected(exit_listener): view.tree_exiting.disconnect(exit_listener)

static func sample(age_ms: float, reduced_motion: bool = false) -> Dictionary:
	var age: float = maxf(0.0, age_ms)
	if reduced_motion:
		return {"offset": TRAVEL if age < REDUCED_MS else Vector2.ZERO, "latch": 0.0, "phase": "open" if age < REDUCED_MS else "idle"}
	var open: float = smoothstep(120.0, 480.0, age) * (1.0 - smoothstep(840.0, 1220.0, age))
	var latch: float = smoothstep(0.0, 100.0, age) * (1.0 - smoothstep(1200.0, DURATION_MS, age))
	var offset := Vector2(roundf(TRAVEL.x * open), roundf(TRAVEL.y * open))
	return {"offset": offset, "latch": roundf(latch), "phase": "latch" if age < 120 else "pull" if age < 480 else "open" if age < 840 else "close" if age < 1220 else "settle" if age < DURATION_MS else "idle"}

func pose() -> Dictionary:
	return sample(elapsed_ms, reduced) if playing else {"offset": Vector2.ZERO, "latch": 0.0, "phase": "idle"}

static func without(region: Rect2, cut: Rect2) -> Array:
	var middle: Rect2 = region.intersection(cut)
	if not middle.has_area(): return [region]
	var result: Array = []
	for part: Rect2 in [Rect2(region.position, Vector2(region.size.x, middle.position.y-region.position.y)), Rect2(Vector2(region.position.x, middle.end.y), Vector2(region.size.x, region.end.y-middle.end.y)), Rect2(Vector2(region.position.x, middle.position.y), Vector2(middle.position.x-region.position.x, middle.size.y)), Rect2(Vector2(middle.end.x, middle.position.y), Vector2(region.end.x-middle.end.x, middle.size.y))]:
		if part.has_area(): result.append(part)
	return result

static func part(whole: Dictionary, source: Rect2, offset: Vector2 = Vector2.ZERO) -> Dictionary:
	var factor: float = whole.rect.size.x / whole.source.size.x
	return {"texture": whole.texture, "source": source, "rect": Rect2(whole.rect.position + (source.position-whole.source.position+offset)*factor, source.size*factor)}

func parts(whole: Dictionary) -> Array:
	var result: Array = []
	for region: Rect2 in without(whole.source, DRAWER): result.append(part(whole, region))
	var current: Dictionary = pose()
	var offset: Vector2 = current.offset
	if offset.y > 0:
		var recess: Dictionary = part(whole, DRAWER)
		recess.erase("texture"); recess["color"] = Color("202b35")
		result.append(recess)
		# The paper uses the original output-stack pixels at the same density.
		var exposed := Rect2(PAPER.position, Vector2(PAPER.size.x, minf(PAPER.size.y, offset.y-1)))
		if exposed.has_area(): result.append(part(whole, exposed, Vector2(14, 76)-PAPER.position+Vector2(offset.x*.5, 1)))
	for region: Rect2 in without(DRAWER, LATCH): result.append(part(whole, region, offset))
	if float(current.latch) > 0:
		var gap: Dictionary = part(whole, LATCH, offset)
		gap.erase("texture"); gap["color"] = Color("202b35")
		result.append(gap)
	result.append(part(whole, LATCH, offset+Vector2(0, -float(current.latch))))
	return result

func draw(canvas: CanvasItem, whole: Dictionary, targets: Array) -> void:
	bind_view(canvas)
	for geometry: Dictionary in parts(whole):
		Picker.record(canvas, targets, geometry)
		if geometry.has("color"): canvas.draw_rect(geometry.rect, geometry.color)
		else: canvas.draw_texture_rect_region(geometry.texture, geometry.rect, geometry.source)

func snapshot() -> Dictionary:
	return {"playing": playing, "elapsedMs": elapsed_ms, "pose": pose(), "inspections": inspections, "parts": ["body", "paper_drawer", "small_latch", "paper_stack"], "stateConnected": state_ref != null and state_ref.get_ref() != null}
