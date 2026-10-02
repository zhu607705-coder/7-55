extends Control
signal finished(result: Dictionary)
signal cancelled
const POINTS = [Vector2(.2,.22),Vector2(.6,.18),Vector2(.79,.32),Vector2(.73,.52),Vector2(.37,.61),Vector2(.16,.48),Vector2(.26,.32),Vector2(.52,.31),Vector2(.63,.48),Vector2(.43,.52)]
var completed = 0
var target: Button
var status: Label
var closed = false
func _ready() -> void:
	var bg = ColorRect.new()
	bg.color = Color("13273a")
	bg.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	add_child(bg)
	status = Label.new()
	status.position = Vector2(24,24)
	status.size = Vector2(382,140)
	status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	status.add_theme_color_override("font_color",Color.WHITE)
	status.text = "虚拟定位跑步\n依次点击十个定位点，每个点记录一分钟、300 米。\n鼠标 / 触屏点击；Tab + Enter / 空格；Esc 退出。"
	add_child(status)
	target = Button.new()
	target.custom_minimum_size = Vector2(74,64)
	target.pressed.connect(_point)
	add_child(target)
	var exit_button = Button.new()
	exit_button.text = "退出本次定位"
	exit_button.position = Vector2(30,175)
	exit_button.pressed.connect(func(): cancelled.emit())
	add_child(exit_button)
	_update_target()
func start(_config: Dictionary) -> void: pass
func _process(_delta: float) -> void:
	if target != null and completed < 10: target.position = Vector2(0,210)+Vector2(size.x-80,size.y-300)*POINTS[completed]
func _point() -> void:
	if closed: return
	completed += 1
	if completed == 10:
		closed = true
		finished.emit({"failed":false,"points":10,"elapsedSeconds":600,"distanceMeters":3000})
		return
	_update_target()
func _update_target() -> void:
	if target == null: return
	target.text = "定位 %s" % (completed+1)
	target.grab_focus()
	status.text = "虚拟定位跑步\n依次点击十个定位点。Tab + Enter / 空格；Esc 退出。\n进度：%s / 10　记录：%s:00　距离：%.2f km" % [completed,completed,completed*0.3]
func _unhandled_key_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and event.physical_keycode == KEY_ESCAPE:
		cancelled.emit()
		get_viewport().set_input_as_handled()
