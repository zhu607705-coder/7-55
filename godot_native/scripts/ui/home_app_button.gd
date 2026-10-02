extends Button
## Native mouse/touch long press. Editing cancels ordinary activation.
signal editing_started
signal dragged(point: Vector2)
signal drag_finished
signal move_requested(offset: int)
signal removal_requested
signal editing_finished
var editing = false
var held = false
var elapsed = 0.0
var origin = Vector2.ZERO
var suppress_activation = false
var editable = true

func _ready() -> void:
	focus_mode=Control.FOCUS_ALL
	set_process(true)

func _process(delta: float) -> void:
	if not held or editing: return
	elapsed += delta
	if elapsed >= .460:
		editing=true; suppress_activation=true; editing_started.emit()

func _gui_input(event: InputEvent) -> void:
	if not editable: return
	if event is InputEventKey and event.pressed:
		if event.keycode==KEY_F2:
			editing=true; suppress_activation=true; editing_started.emit(); accept_event()
		elif editing:
			var offsets={KEY_LEFT:-1,KEY_RIGHT:1,KEY_UP:-4,KEY_DOWN:4}
			if offsets.has(event.keycode): move_requested.emit(offsets[event.keycode]); accept_event()
			elif event.keycode in [KEY_DELETE,KEY_BACKSPACE]: removal_requested.emit(); accept_event()
			elif event.keycode==KEY_ESCAPE: editing=false; held=false; editing_finished.emit(); accept_event()
	if event is InputEventMouseButton and event.button_index==MOUSE_BUTTON_LEFT:
		if event.pressed: held=true; elapsed=0; origin=event.position; suppress_activation=editing
		else:
			if held and editing: suppress_activation=true; drag_finished.emit()
			held=false
	elif event is InputEventScreenTouch:
		if event.pressed: held=true; elapsed=0; origin=event.position; suppress_activation=editing
		else:
			if held and editing: suppress_activation=true; drag_finished.emit()
			held=false
	elif event is InputEventMouseMotion or event is InputEventScreenDrag:
		if not held: return
		if not editing and origin.distance_to(event.position)>10: held=false
		elif editing: dragged.emit(get_global_transform()*event.position); accept_event()

func can_activate() -> bool:
	if suppress_activation: suppress_activation=false; return false
	return not editing

func _notification(what: int) -> void:
	if what==NOTIFICATION_WM_WINDOW_FOCUS_OUT:
		if held and editing: drag_finished.emit()
		held=false; elapsed=0; suppress_activation=true
