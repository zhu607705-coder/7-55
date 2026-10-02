extends Button
## Shared pointer contract: tap selects; double tap / Enter inspects; drag uses
## Godot's single native drop dispatch. This class never mutates owned items.
signal selection_requested(item: String)
signal inspection_requested(item: String)
signal drag_finished(landed: bool)
var item_id := ""
var allow_drag := true
const Gesture=preload("res://scripts/ui/inventory_gesture.gd")
var gestures := Gesture.new()
var _touch_index := -1
var _touch_start := Vector2.ZERO
var _touch_time := 0
var _touch_dragging := false
var _scrolling := false
var _scroll: ScrollContainer
var _scroll_start := 0
var _suppress_mouse_until := 0
var _pointer_position := Vector2.ZERO
var _native_double_click := false
var _drag_was_started := false
var _drag_ticket := 0
const DRAG_DISTANCE := 10.0 # root viewport pixels, unaffected by phone scaling
const TOUCH_HOLD_MS := 220

func _ready() -> void:
	focus_mode=Control.FOCUS_ALL
	pressed.connect(_on_pressed)

func _on_pressed() -> void:
	var native_double:=_native_double_click
	_native_double_click=false
	if disabled or Time.get_ticks_msec() < _suppress_mouse_until or _drag_was_started: return
	_activate(_pointer_position,native_double)

func _activate(point: Vector2,native_double_click:=false) -> void:
	if item_id.is_empty() or disabled: return
	if gestures.tap(item_id,point,Time.get_ticks_msec(),native_double_click): inspection_requested.emit(item_id)
	else: selection_requested.emit(item_id)

func _make_drag_preview() -> Control:
	var label := Label.new()
	label.text=text; label.modulate=Color("e9deac"); label.mouse_filter=Control.MOUSE_FILTER_IGNORE
	return label

func _get_drag_data(_at_position: Vector2) -> Variant:
	if item_id.is_empty() or disabled or _scrolling or not allow_drag: return null
	_native_double_click=false
	gestures.reset(); _drag_was_started=true; _drag_ticket=Gesture.begin_drag()
	set_drag_preview(_make_drag_preview())
	return {"kind":"inventory_item","item":item_id}

func _gui_input(event: InputEvent) -> void:
	if disabled: return
	if event is InputEventMouseButton and event.button_index==MOUSE_BUTTON_LEFT:
		_pointer_position=get_global_transform_with_canvas()*event.position
		if event.pressed:
			_native_double_click=event.double_click and Time.get_ticks_msec() >= _suppress_mouse_until
			if Time.get_ticks_msec() >= _suppress_mouse_until:
				_drag_was_started=false; _scrolling=false
	if event is InputEventKey and event.pressed and not event.echo:
		_native_double_click=false
		if event.keycode in [KEY_ENTER,KEY_KP_ENTER]:
			gestures.reset(); _suppress_mouse_until=Time.get_ticks_msec()+100
			accept_event(); inspection_requested.emit(item_id)
		elif event.keycode==KEY_SPACE:
			gestures.reset(); _suppress_mouse_until=Time.get_ticks_msec()+100
			accept_event(); selection_requested.emit(item_id)
	if event is InputEventScreenTouch and event.pressed and _touch_index<0:
		_native_double_click=false
		if not Gesture.acquire_touch(self):
			accept_event(); return
		_touch_index=event.index; _touch_start=get_global_transform_with_canvas()*event.position
		_touch_time=Time.get_ticks_msec(); _touch_dragging=false; _scrolling=false; _drag_was_started=false
		_suppress_mouse_until=Time.get_ticks_msec()+1000
		_scroll=_find_scroll(); _scroll_start=_scroll.scroll_vertical if _scroll else 0
		accept_event()

func _find_scroll() -> ScrollContainer:
	var parent=get_parent()
	while parent:
		if parent is ScrollContainer: return parent
		parent=parent.get_parent()
	return null

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and event.keycode==KEY_ESCAPE and (_touch_index>=0 or _drag_was_started):
		cancel_gesture(); get_viewport().set_input_as_handled(); return
	if _touch_index<0: return
	# Additional fingers never gain a second source/drag or release this owner.
	if (event is InputEventScreenTouch or event is InputEventScreenDrag) and event.index!=_touch_index:
		get_viewport().set_input_as_handled(); return
	if not is_visible_in_tree() or disabled:
		cancel_gesture(); return
	if event is InputEventScreenDrag and event.index==_touch_index:
		_suppress_mouse_until=Time.get_ticks_msec()+1000
		var delta: Vector2=event.position-_touch_start
		if not _touch_dragging and not _scrolling and delta.length()>=DRAG_DISTANCE:
			var scroll_available:=is_instance_valid(_scroll) and _scroll.get_v_scroll_bar().max_value>_scroll.get_v_scroll_bar().page
			if not allow_drag or (scroll_available and absf(delta.y)>absf(delta.x)*1.25 and Time.get_ticks_msec()-_touch_time<TOUCH_HOLD_MS):
				_scrolling=true; gestures.reset()
			else:
				_touch_dragging=true; gestures.reset(); _drag_ticket=Gesture.begin_drag()
				force_drag({"kind":"inventory_item","item":item_id},_make_drag_preview())
				_drag_was_started=true
		if _scrolling and is_instance_valid(_scroll):
			_scroll.scroll_vertical=_scroll_start-roundi(delta.y/maxf(.001,_scroll.get_global_transform_with_canvas().get_scale().y))
		elif _touch_dragging:
			var motion:=InputEventMouseMotion.new(); motion.position=event.position; motion.global_position=event.position; motion.button_mask=MOUSE_BUTTON_MASK_LEFT
			Input.parse_input_event(motion)
		get_viewport().set_input_as_handled()
	elif event is InputEventScreenTouch and not event.pressed and event.index==_touch_index:
		get_viewport().set_input_as_handled()
		_restore_emulation()
		_suppress_mouse_until=Time.get_ticks_msec()+250
		if event.canceled: cancel_gesture()
		elif _touch_dragging:
			_touch_index=-1; _touch_dragging=false
			var release:=InputEventMouseButton.new(); release.button_index=MOUSE_BUTTON_LEFT; release.position=event.position; release.global_position=event.position
			Input.parse_input_event(release)
		else:
			_touch_index=-1
			var local: Vector2=get_global_transform_with_canvas().affine_inverse()*event.position
			if not _scrolling and Rect2(Vector2.ZERO,size).has_point(local): _activate(event.position)
			else: gestures.reset()

func _restore_emulation() -> void:
	Gesture.release_touch(self)

func cancel_gesture(defer_native_cancel:=false) -> void:
	_native_double_click=false
	var had_pointer:=_touch_index>=0 or _drag_was_started
	_restore_emulation()
	_touch_index=-1; _touch_dragging=false; _scrolling=false; gestures.reset()
	_suppress_mouse_until=Time.get_ticks_msec()+250 if had_pointer else 0
	var dragging:=_drag_was_started
	_drag_was_started=false
	if dragging and is_inside_tree() and get_viewport().gui_is_dragging():
		if defer_native_cancel: Gesture.cancel_drag_later(get_viewport(),_drag_ticket)
		else: get_viewport().gui_cancel_drag()

func _notification(what: int) -> void:
	if what==NOTIFICATION_DRAG_END and _drag_was_started:
		_drag_was_started=false
		_suppress_mouse_until=Time.get_ticks_msec()+100
		drag_finished.emit(get_viewport().gui_is_drag_successful())
	elif what==NOTIFICATION_WM_WINDOW_FOCUS_OUT:
		cancel_gesture()
	elif what==NOTIFICATION_EXIT_TREE and (_touch_index>=0 or _drag_was_started):
		cancel_gesture(true)
	elif what==NOTIFICATION_VISIBILITY_CHANGED and is_inside_tree() and not is_visible_in_tree():
		cancel_gesture(true)
