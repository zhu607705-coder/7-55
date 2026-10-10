extends RefCounted
## One tap history per visible inventory, retained while slot nodes rebuild.
const DOUBLE_TAP_MS := 380
const DOUBLE_TAP_DISTANCE := 24.0
var last_item := ""
var last_ms := -1000
var last_position := Vector2.INF
func tap(item: String, point: Vector2, now_ms: int, native_double_click: bool=false) -> bool:
	# The native mouse recognizer already measured the click interval before
	# possible main-thread delivery delay. It does not override item/position.
	var inspect := last_item == item and (native_double_click or now_ms-last_ms <= DOUBLE_TAP_MS) and now_ms >= last_ms and last_position.distance_to(point) <= DOUBLE_TAP_DISTANCE
	if inspect:
		reset()
	else:
		last_item=item; last_ms=now_ms; last_position=point
	return inspect
func reset() -> void:
	last_item=""; last_ms=-1000; last_position=Vector2.INF

# Godot exposes one native drag and one global touch-to-mouse setting. Inventory
# views therefore share one transient pointer owner, even across separate docks.
static var _touch_owner: WeakRef
static var _touch_baseline := false
static var _touch_restore_pending := false
static var _touch_epoch := 0

static func touch_owner() -> Object:
	return _touch_owner.get_ref() if _touch_owner!=null else null

static func acquire_touch(owner: Object) -> bool:
	var active:=touch_owner()
	if is_instance_valid(active): return active==owner
	# A same-turn replacement inherits the ORIGINAL baseline. Its epoch invalidates
	# the outgoing owner's deferred restore, so emulation stays off during capture.
	if not _touch_restore_pending: _touch_baseline=Input.emulate_mouse_from_touch
	_touch_epoch+=1; _touch_restore_pending=false; _touch_owner=weakref(owner)
	Input.emulate_mouse_from_touch=false
	return true

static func release_touch(owner: Object) -> void:
	if touch_owner()!=owner: return
	_touch_owner=null; _touch_epoch+=1; _touch_restore_pending=true
	_finish_touch_restore.call_deferred(_touch_epoch)

static func _finish_touch_restore(epoch: int) -> void:
	if epoch!=_touch_epoch or not _touch_restore_pending or is_instance_valid(touch_owner()): return
	Input.emulate_mouse_from_touch=_touch_baseline
	_touch_restore_pending=false

static var _drag_epoch := 0
static func begin_drag() -> int:
	_drag_epoch+=1
	return _drag_epoch

static func cancel_drag_later(viewport: Viewport, epoch: int) -> void:
	_finish_drag_cancel.call_deferred(viewport,epoch)

static func _finish_drag_cancel(viewport: Viewport, epoch: int) -> void:
	# Visibility/exit notifications cannot safely remove the preview immediately.
	# A replacement drag started before idle must not be canceled by this cleanup.
	if epoch==_drag_epoch and is_instance_valid(viewport) and viewport.gui_is_dragging(): viewport.gui_cancel_drag()
