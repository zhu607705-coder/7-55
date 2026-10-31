extends Control
## A close view of two cabinet compartments; all puzzle actions are physical gestures.
signal closed
const Model = preload("res://campuses/future_learning_center/scripts/locker_cipher_model.gd")
const FeedbackSubtitle = preload("res://campuses/future_learning_center/scripts/feedback_subtitle.gd")
const ApparatusStyle = preload("res://campuses/future_learning_center/scripts/apparatus_style.gd")
const BOARD := Vector2(105, 151)
const CARD_HOME := Vector2(105, 250)
const CARD_SIZE := Vector2(280, 168)
const CELL := Vector2(70, 42)
const CLUE_DOOR := Rect2(83, 81, 328, 345)
const CLUE_EDGE := Rect2(53, 80, 48, 350)
const LOCK_HANDLE := Rect2(759, 324, 76, 55)
const HINT_NOTE := Rect2(826, 91, 52, 49)
const WHEEL_CENTERS := [Vector2(740, 251), Vector2(780, 251), Vector2(820, 251)]
const HINTS := [
	"让纸片和数字纸的橙色折角对齐，留意窗口旁的图形。",
	"找锁轮上出现的图形；其余图形不是锁轮的线索。",
	"同一种图形旁的两个数字相加，按锁轮的图形顺序输入。"
]

var model = Model.new()
var font: Font
var pointer_owner := -2
var gesture := ""
var press_at := Vector2.ZERO
var pointer := Vector2.ZERO
var card_start := Vector2.ZERO
var card_preview := CARD_HOME
var active_wheel := -1
var clue_progress := 0.0
var lock_progress := 0.0
var warning_time := 0.0
var feedback := ""
var feedback_seconds := 0.0
var reduced_motion := false

func _ready() -> void:
	font = ApparatusStyle.font()
	mouse_filter = Control.MOUSE_FILTER_STOP
	reduced_motion = OS.get_environment("FLC_REDUCED_MOTION") == "1"
	if OS.has_feature("web"):
		reduced_motion = reduced_motion or bool(JavaScriptBridge.eval("window.matchMedia('(prefers-reduced-motion: reduce)').matches"))
	var exit := ApparatusStyle.configure_exit(self, close)
	exit.text = "离开储物柜"
	exit.accessibility_name = "离开储物柜，返回当前房间"
	hide()

func open() -> void:
	_cancel_gesture()
	clue_progress = 1.0 if model.clue_open else 0.0
	lock_progress = 1.0 if model.unlocked else 0.0
	show()
	notice("打开一侧柜门，看看里面留下了什么。" if not model.clue_open else "拨动数字轮，再拉动柜门把手。")

func close() -> void:
	_cancel_gesture(); hide(); closed.emit()

func notice(message: String) -> void:
	feedback = message; feedback_seconds = FeedbackSubtitle.duration(message)

func _notification(what: int) -> void:
	if what in [NOTIFICATION_APPLICATION_FOCUS_OUT, NOTIFICATION_APPLICATION_PAUSED]:
		_cancel_gesture()

func _cancel_gesture() -> void:
	pointer_owner = -2; gesture = ""; active_wheel = -1
	card_preview = BOARD if model.stencil_placed else CARD_HOME
	queue_redraw()

func _input(event: InputEvent) -> void:
	if ApparatusStyle.navigation_event(self, event): return
	if not visible: return
	if event is InputEventMouse and event.device == InputEvent.DEVICE_ID_EMULATION: return
	if event is InputEventScreenTouch and event.canceled:
		if event.index == pointer_owner:
			_release(event.position, true)
			get_viewport().set_input_as_handled()
		return
	var handled := false
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_ESCAPE:
		if gesture.is_empty(): close()
		else: _cancel_gesture()
		handled = true
	elif event is InputEventScreenTouch:
		if event.pressed and pointer_owner == -2 and not Rect2(808, 7, 144, 40).has_point(event.position):
			pointer_owner = event.index; _press(event.position); handled = true
		elif not event.pressed and pointer_owner == event.index:
			_release(event.position, event.canceled); handled = true
	elif event is InputEventScreenDrag and pointer_owner == event.index:
		_move(event.position); handled = true
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed and pointer_owner == -2 and not Rect2(808, 7, 144, 40).has_point(event.position):
			pointer_owner = -1; _press(event.position); handled = true
		elif not event.pressed and pointer_owner == -1:
			_release(event.position, false); handled = true
	elif event is InputEventMouseMotion and pointer_owner == -1:
		_move(event.position); handled = true
	if handled: get_viewport().set_input_as_handled()

func _press(at: Vector2) -> void:
	press_at = at; pointer = at
	if not model.unlocked and HINT_NOTE.has_point(at):
		gesture = "hint"
	elif model.clue_open and Rect2(BOARD if model.stencil_placed else CARD_HOME, CARD_SIZE).has_point(at):
		gesture = "card"; card_start = BOARD if model.stencil_placed else CARD_HOME; card_preview = card_start
	elif not model.unlocked and LOCK_HANDLE.has_point(at):
		gesture = "handle"
	elif not model.unlocked:
		for i: int in WHEEL_CENTERS.size():
			if Rect2(WHEEL_CENTERS[i] - Vector2(20, 50), Vector2(40, 100)).has_point(at):
				active_wheel = i; gesture = "wheel"; break
	if gesture.is_empty() and ((not model.clue_open and CLUE_DOOR.has_point(at)) or (model.clue_open and CLUE_EDGE.has_point(at))):
		gesture = "door"
	queue_redraw()

func _move(at: Vector2) -> void:
	pointer = at
	if gesture == "card": card_preview = card_start + at - press_at
	queue_redraw()

func wheel_preview(index: int) -> int:
	if gesture == "wheel" and active_wheel == index:
		return posmod(model.digits[index] + roundi((press_at.y - pointer.y) / 24.0), 10)
	return model.digits[index]

func _release(at: Vector2, cancelled: bool) -> void:
	var valid := not cancelled and Rect2(0, 0, 960, 540).has_point(at)
	if valid:
		match gesture:
			"door":
				if at.distance_to(press_at) < 30:
					model.clue_open = not model.clue_open
					if model.clue_open: notice("柜里有一张数字纸和带缺口的纸片。")
			"card":
				var destination := card_start + at - press_at
				if destination.distance_to(BOARD) <= 46:
					model.stencil_placed = true; notice("纸片贴合了。留意窗口和锁轮上的图形。")
				elif destination.distance_to(CARD_HOME) <= 46:
					model.stencil_placed = false
				elif at.distance_to(press_at) < 12:
					notice("拿住纸片，把折角与数字纸上的折角对齐。")
			"wheel":
				var change := roundi((press_at.y - at.y) / 24.0)
				if absi(change) == 0 and at.distance_to(press_at) < 12:
					change = 1 if at.y <= WHEEL_CENTERS[active_wheel].y else -1
				model.turn(active_wheel, change)
			"handle":
				if at.y - press_at.y > 20:
					if model.try_handle(): notice("锁开了，柜门正在打开。")
					else: warning_time = 0.7; notice("锁还没有打开，再对照纸片上的窗口。")
				else: notice("上下拨动数字轮，向下拉把手试一试。")
			"hint":
				if HINT_NOTE.has_point(at) and at.distance_to(press_at) < 12:
					notice(HINTS[model.next_hint() - 1])
	_cancel_gesture()

func _process(dt: float) -> void:
	if not visible: return
	feedback_seconds = maxf(0.0, feedback_seconds - dt)
	warning_time = maxf(0.0, warning_time - dt)
	var speed := 100.0 if reduced_motion else 3.0
	clue_progress = move_toward(clue_progress, 1.0 if model.clue_open else 0.0, dt * speed)
	lock_progress = move_toward(lock_progress, 1.0 if model.unlocked else 0.0, dt * speed)
	queue_redraw()

func _text(value: String, center: Vector2, size_value: int, color: Color) -> void:
	var width: float = font.get_string_size(value, HORIZONTAL_ALIGNMENT_LEFT, -1, size_value).x
	draw_string(font, center - Vector2(width / 2, -size_value * 0.35), value, HORIZONTAL_ALIGNMENT_LEFT, -1, size_value, color)

func _draw() -> void:
	draw_rect(Rect2(0, 0, 960, 540), Color("c7ccc8"))
	draw_rect(Rect2(0, 450, 960, 90), Color("adb8b5"))
	# Steel frame and two compartments follow the photographed white-and-charcoal lockers.
	draw_colored_polygon(PackedVector2Array([Vector2(55, 60), Vector2(68, 49), Vector2(915, 49), Vector2(905, 60)]), Color("768987"))
	draw_colored_polygon(PackedVector2Array([Vector2(905, 60), Vector2(915, 49), Vector2(915, 457), Vector2(905, 468)]), Color("42565b"))
	draw_rect(Rect2(55, 60, 850, 408), Color("23343b"))
	draw_rect(Rect2(63, 66, 834, 394), Color("879492"))
	draw_line(Vector2(66, 69), Vector2(893, 69), Color("c6cfca"), 2)
	for p: Vector2 in [Vector2(68, 73), Vector2(892, 73), Vector2(68, 451), Vector2(892, 451)]:
		draw_circle(p, 2.5, Color("354a4e")); draw_circle(p + Vector2(-.5, -.5), .8, Color("d2d9d1"))
	draw_rect(Rect2(74, 76, 345, 366), Color("263f47"))
	draw_rect(Rect2(421, 76, 458, 366), Color("344952"))
	draw_rect(Rect2(79, 82, 335, 353), Color("a9b9b2"))
	draw_colored_polygon(PackedVector2Array([Vector2(79, 82), Vector2(105, 104), Vector2(105, 410), Vector2(79, 435)]), Color("7b908b"))
	draw_colored_polygon(PackedVector2Array([Vector2(79, 82), Vector2(414, 82), Vector2(390, 104), Vector2(105, 104)]), Color("d3dbd1"))
	draw_colored_polygon(PackedVector2Array([Vector2(79, 435), Vector2(105, 410), Vector2(390, 410), Vector2(414, 435)]), Color("d3dbd1"))
	_draw_sheet()
	_draw_right_compartment()
	if model.clue_open and clue_progress > 0.8:
		_draw_stencil(card_preview if gesture == "card" else (BOARD if model.stencil_placed else CARD_HOME))
	_draw_left_door()
	draw_rect(Rect2(63, 447, 834, 13), Color("26363e"))
	draw_line(Vector2(76, 454), Vector2(880, 454), Color("a8b7b4"), 2)
	if feedback_seconds > 0: FeedbackSubtitle.paint(self, font, feedback)

func _draw_sheet() -> void:
	draw_rect(Rect2(BOARD - Vector2(3, 3), CARD_SIZE + Vector2(12, 12)), Color("80948d"))
	draw_rect(Rect2(BOARD - Vector2(6, 6), CARD_SIZE + Vector2(12, 12)), Color("d3cabb"))
	draw_rect(Rect2(BOARD, CARD_SIZE), Color("f6f2e5"))
	for row: int in 4:
		for col: int in 4:
			var cell := Rect2(BOARD + Vector2(col * CELL.x, row * CELL.y), CELL)
			draw_rect(cell, Color("c8c9be"), false, 1)
			_text(str(Model.GRID[row][col]), cell.get_center() + Vector2(10, 0), 27, Color("263f47"))
	draw_colored_polygon(PackedVector2Array([BOARD, BOARD + Vector2(17, 0), BOARD + Vector2(0, 17)]), Color("db8248"))
	draw_rect(Rect2(BOARD + Vector2(119, -9), Vector2(42, 12)), Color("718482"))
	draw_rect(Rect2(BOARD + Vector2(123, -7), Vector2(34, 5)), Color("d1d6ca"))

func _draw_stencil(at: Vector2) -> void:
	# The holes are real gaps in the card drawing, so they reveal the sheet beneath.
	draw_line(at + Vector2(4, CARD_SIZE.y + 4), at + Vector2(CARD_SIZE.x + 4, CARD_SIZE.y + 4), Color("83948a"), 3)
	for row: int in 4:
		for col: int in 4:
			var cell := Rect2(at + Vector2(col * CELL.x, row * CELL.y), CELL)
			var shape: String = Model.window_shape(Vector2i(col, row))
			if shape.is_empty():
				draw_rect(cell, Color("d7c49e"))
				draw_rect(cell, Color("b9a782"), false, 1)
			else:
				# Four strips leave a real aperture; its adjacent stamp identifies the pair.
				var hole := Rect2(cell.position + Vector2(25, 4), Vector2(39, 34))
				draw_rect(Rect2(cell.position, Vector2(25, CELL.y)), Color("d7c49e"))
				draw_rect(Rect2(cell.position + Vector2(25, 0), Vector2(45, 4)), Color("d7c49e"))
				draw_rect(Rect2(cell.position + Vector2(25, 38), Vector2(45, 4)), Color("d7c49e"))
				draw_rect(Rect2(cell.position + Vector2(64, 4), Vector2(6, 34)), Color("d7c49e"))
				draw_rect(hole, Color("8a7454"), false, 2)
				_draw_shape(shape, cell.position + Vector2(13, 21), 7.0, Color("4d4638"))
	draw_rect(Rect2(at, CARD_SIZE), Color("8e7c60"), false, 3)
	draw_colored_polygon(PackedVector2Array([at, at + Vector2(17, 0), at + Vector2(0, 17)]), Color("db8248"))

func _draw_shape(shape: String, center: Vector2, radius: float, ink: Color) -> void:
	match shape:
		"circle": draw_circle(center, radius, ink)
		"square": draw_rect(Rect2(center - Vector2.ONE * radius, Vector2.ONE * radius * 2), ink)
		"triangle":
			draw_colored_polygon(PackedVector2Array([center + Vector2(0, -radius), center + Vector2(radius, radius), center + Vector2(-radius, radius)]), ink)
		"diamond":
			draw_colored_polygon(PackedVector2Array([center + Vector2(0, -radius), center + Vector2(radius, 0), center + Vector2(0, radius), center + Vector2(-radius, 0)]), ink)
		"star":
			var points := PackedVector2Array()
			for i: int in 10:
				var angle := -PI / 2.0 + TAU * i / 10.0
				var length := radius if i % 2 == 0 else radius * 0.43
				points.append(center + Vector2(cos(angle), sin(angle)) * length)
			draw_colored_polygon(points, ink)

func _draw_left_door() -> void:
	var width := 328.0 * (1.0 - clue_progress)
	if width > 1:
		var door := Rect2(83, 81, width, 345)
		draw_rect(door, Color("ecebe3")); draw_rect(door, Color("3e5055"), false, 3)
		draw_line(door.position + Vector2(4, 4), Vector2(door.end.x - 4, door.position.y + 4), Color("ffffff", .6), 2)
		draw_line(Vector2(door.position.x + 4, door.end.y - 5), door.end - Vector2(4, 5), Color("aebdb5"), 3)
		if width > 65:
			draw_rect(Rect2(door.end.x - 34, 229, 22, 62), Color("3b5056"))
			draw_rect(Rect2(door.end.x - 31, 232, 16, 56), Color("8c9e9b"))
			draw_rect(Rect2(door.end.x - 27, 238, 8, 43), Color("465960"))
			draw_line(Vector2(door.end.x - 27, 239), Vector2(door.end.x - 27, 280), Color("c5d1c9"), 1)
	if clue_progress > 0.05:
		var opened := 28.0 * clue_progress
		draw_colored_polygon(PackedVector2Array([Vector2(83, 81), Vector2(83 - opened, 91), Vector2(83 - opened, 416), Vector2(83, 426)]), Color("d8ddd4"))
		draw_line(Vector2(83 - opened, 91), Vector2(83 - opened, 416), Color("52656b"), 3)

func _draw_right_compartment() -> void:
	var panel := Rect2(427, 82, 446, 344)
	if lock_progress > 0:
		draw_rect(panel, Color("536b6a"))
		draw_rect(Rect2(443, 101, 415, 303), Color("a9b9b2"))
		draw_colored_polygon(PackedVector2Array([Vector2(427, 82), Vector2(443, 101), Vector2(443, 404), Vector2(427, 426)]), Color("718983"))
		draw_colored_polygon(PackedVector2Array([Vector2(427, 82), Vector2(873, 82), Vector2(858, 101), Vector2(443, 101)]), Color("d4dcd1"))
		draw_rect(Rect2(443, 292, 415, 10), Color("4c6261"))
		# A folder and a small parts box remain in the opened compartment.
		draw_rect(Rect2(562, 193, 102, 91), Color("315b75"))
		draw_rect(Rect2(574, 181, 77, 96), Color("e6e8d9"))
		draw_line(Vector2(581, 193), Vector2(644, 193), Color("a8b4a8"), 2)
		draw_line(Vector2(581, 202), Vector2(633, 202), Color("a8b4a8"), 2)
		draw_rect(Rect2(686, 248, 100, 42), Color("d7c49e"))
		draw_rect(Rect2(686, 248, 100, 42), Color("8e7c60"), false, 2)
		draw_line(Vector2(694, 257), Vector2(778, 257), Color("eee2c9"), 2)
	var door_scale := 1.0 - lock_progress
	if door_scale > .01:
		# Project the actual door toward its hinge while the compartment is revealed.
		draw_set_transform(Vector2(panel.end.x * (1.0 - door_scale), 0), 0, Vector2(door_scale, 1))
		_draw_right_door(panel)
		draw_set_transform(Vector2.ZERO, 0, Vector2.ONE)
	if lock_progress > 0:
		var opened := 35.0 * lock_progress
		draw_colored_polygon(PackedVector2Array([Vector2(873, 82), Vector2(873 + opened, 98), Vector2(873 + opened, 413), Vector2(873, 426)]), Color("dedfd7"))
		draw_line(Vector2(873 + opened, 98), Vector2(873 + opened, 413), Color("72847d"), 3)

func _draw_right_door(panel: Rect2) -> void:
	draw_rect(panel, Color("e9e8df")); draw_rect(panel, Color("52636a"), false, 3)
	draw_line(panel.position + Vector2(4, 4), Vector2(panel.end.x - 4, panel.position.y + 4), Color("ffffff", .6), 2)
	draw_line(Vector2(panel.position.x + 4, panel.end.y - 5), panel.end - Vector2(4, 5), Color("adbcb4"), 3)
	# The lock belongs to the cabinet door, with three independent number rollers.
	var lock_color := Color("b5594b") if warning_time > 0 else Color("315b61")
	# A small engraved diagram teaches that the two matching windows are added.
	draw_rect(Rect2(714, 144, 151, 40), Color("334a51"))
	draw_rect(Rect2(720, 149, 139, 31), Color("82b9b7"))
	var engraving := Color("253f44")
	_draw_shape("circle", Vector2(737, 164), 6, engraving)
	_text("+", Vector2(755, 164), 20, engraving)
	_draw_shape("circle", Vector2(773, 164), 6, engraving)
	draw_line(Vector2(788, 164), Vector2(808, 164), engraving, 2)
	draw_line(Vector2(802, 158), Vector2(808, 164), engraving, 2)
	draw_line(Vector2(802, 170), Vector2(808, 164), engraving, 2)
	_draw_shape("circle", Vector2(826, 164), 6, engraving)
	draw_rect(Rect2(718, 189, 151, 194), Color("8d9e96"))
	draw_rect(Rect2(714, 184, 151, 194), Color("334a51"))
	draw_rect(Rect2(720, 190, 139, 182), Color("82b9b7"))
	draw_line(Vector2(723, 193), Vector2(856, 193), Color("d3e5dc"), 2)
	draw_rect(Rect2(725, 204, 131, 94), Color("d9e8df"))
	for i: int in WHEEL_CENTERS.size():
		var center: Vector2 = WHEEL_CENTERS[i]
		var value := wheel_preview(i)
		_draw_shape(Model.LOCK_SHAPES[i], Vector2(center.x, 198), 7, Color("253f44"))
		draw_rect(Rect2(center - Vector2(17, 44), Vector2(34, 88)), Color("f7f5e9"))
		draw_rect(Rect2(center - Vector2(17, 44), Vector2(34, 88)), Color("8aa29c"), false, 1)
		_text(str(posmod(value + 1, 10)), center - Vector2(0, 31), 16, Color("526763"))
		_text(str(value), center, 30, Color("253e46"))
		_text(str(posmod(value - 1, 10)), center + Vector2(0, 31), 16, Color("526763"))
	draw_rect(Rect2(766, 319, 65, 48), lock_color)
	draw_rect(Rect2(783, 346, 30, 13), Color("334a51"))
	var handle_offset := clampf(pointer.y - press_at.y, 0, 22) if gesture == "handle" else 0.0
	draw_rect(Rect2(774, 327 + handle_offset, 49, 19), Color("db8248"))
	# A folded note is a physical, optional hint; it has no permanent caption.
	draw_rect(HINT_NOTE, Color("f5f0dd")); draw_rect(HINT_NOTE, Color("b7a786"), false, 1)
	draw_line(HINT_NOTE.position + Vector2(8, 12), HINT_NOTE.position + Vector2(36, 12), Color("b5bcb0"), 2)
	draw_line(HINT_NOTE.position + Vector2(8, 19), HINT_NOTE.position + Vector2(33, 19), Color("b5bcb0"), 2)
	draw_colored_polygon(PackedVector2Array([HINT_NOTE.end - Vector2(14, 0), HINT_NOTE.end, HINT_NOTE.end - Vector2(0, 14)]), Color("c49559"))

func draw_room_prop(canvas: CanvasItem, box: Rect2) -> void:
	# The existing cabinet owns the hit target; only the status of its small lock changes.
	canvas.draw_rect(Rect2(box.position + Vector2(46, 31), Vector2(5, 8)), Color("93dcbd") if model.unlocked else Color("50cbd2"))
