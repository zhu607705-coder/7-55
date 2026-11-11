extends Control
## Tracks one pull from the visible droplet. Inventory items use Godot's native drop path.

signal pulled
signal inspected
signal item_dropped(item_id: String)

const Gesture = preload("res://scripts/ui/inventory_gesture.gd")
const PULL_DISTANCE := 18.0

var _mouse_active := false
var _touch_index := -1
var _origin := Vector2.ZERO

@onready var _glyph: Control = $HomeCollectibleDropGlyph
@onready var _glyph_origin := _glyph.position


func _ready() -> void:
	focus_mode = Control.FOCUS_ALL
	mouse_default_cursor_shape = Control.CURSOR_DRAG
	focus_entered.connect(queue_redraw)
	focus_exited.connect(queue_redraw)


func _gui_input(event: InputEvent) -> void:
	if event is InputEventKey and not event.echo:
		if event.is_action_pressed("ui_down"):
			accept_event()
			pulled.emit()
		elif event.is_action_pressed("ui_accept"):
			accept_event()
			inspected.emit()
		return
	if get_viewport().gui_is_dragging() or _mouse_active or _touch_index >= 0:
		return
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		if event.device == InputEvent.DEVICE_ID_EMULATION or Gesture.touch_owner() != null:
			return
		_mouse_active = true
		_origin = event.position
		accept_event()
	elif event is InputEventScreenTouch and event.pressed and Gesture.acquire_touch(self):
		_touch_index = event.index
		_origin = event.position
		accept_event()


func _input(event: InputEvent) -> void:
	if not _mouse_active and _touch_index < 0:
		return
	if event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		_reset_pull()
		return
	if _mouse_active and event.device != InputEvent.DEVICE_ID_EMULATION:
		if event is InputEventMouseMotion:
			_track(event.position)
		elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and not event.pressed:
			_finish(event.position, event.canceled)
	elif _touch_index >= 0:
		if event is InputEventScreenDrag and event.index == _touch_index:
			_track(event.position)
		elif event is InputEventScreenTouch and event.index == _touch_index and not event.pressed:
			_finish(event.position, event.canceled)


func _track(viewport_point: Vector2) -> void:
	get_viewport().set_input_as_handled()
	var movement := _local_point(viewport_point) - _origin
	_glyph.position.y = _glyph_origin.y + clampf(movement.y, 0.0, PULL_DISTANCE)


func _finish(viewport_point: Vector2, cancelled: bool) -> void:
	get_viewport().set_input_as_handled()
	var point := _local_point(viewport_point)
	var movement := point - _origin
	_reset_pull()
	if cancelled or not get_viewport().get_visible_rect().has_point(viewport_point):
		return
	if movement.y >= PULL_DISTANCE and absf(movement.x) <= movement.y * 1.25:
		pulled.emit()
	else:
		inspected.emit()


func _reset_pull() -> void:
	_mouse_active = false
	_touch_index = -1
	Gesture.release_touch(self)
	if is_instance_valid(_glyph):
		_glyph.position = _glyph_origin


func _notification(what: int) -> void:
	if what in [NOTIFICATION_WM_WINDOW_FOCUS_OUT, NOTIFICATION_APPLICATION_FOCUS_OUT, NOTIFICATION_EXIT_TREE]:
		_reset_pull()
	elif what == NOTIFICATION_VISIBILITY_CHANGED and not is_visible_in_tree():
		_reset_pull()


func _local_point(viewport_point: Vector2) -> Vector2:
	return get_global_transform_with_canvas().affine_inverse() * viewport_point


func _can_drop_data(at_position: Vector2, data: Variant) -> bool:
	if not data is Dictionary or data.get("kind") != "inventory_item" or not data.get("item") is String:
		return false
	var release: Variant = Gesture.release_position(data, get_viewport())
	var point := at_position if release == null else _local_point(release)
	return Rect2(Vector2.ZERO, size).has_point(point)


func _drop_data(at_position: Vector2, data: Variant) -> void:
	if _can_drop_data(at_position, data):
		item_dropped.emit(str(data.item))


func _draw() -> void:
	if has_focus():
		draw_rect(Rect2(Vector2.ZERO, size).grow(-1.0), Color("174d9d"), false, 1.0)
