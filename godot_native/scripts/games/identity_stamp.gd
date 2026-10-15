extends Control
signal finished(result: Dictionary)
signal cancelled
var elapsed = 0.0
var label: Label
var stamp: Button
var issued = false
func _ready() -> void:
	var bg = ColorRect.new()
	bg.color = Color("17253c")
	bg.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	add_child(bg)
	label = Label.new()
	label.position = Vector2(30,60)
	label.size = Vector2(370,180)
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_color_override("font_color",Color.WHITE)
	label.text = "物品身份盖章机\n正在扫描报告……"
	add_child(label)
	stamp = Button.new()
	stamp.position = Vector2(40,260)
	stamp.size = Vector2(260,64)
	stamp.text = "盖章：非本人"
	stamp.disabled = true
	stamp.pressed.connect(_stamp)
	add_child(stamp)
func start(_config: Dictionary) -> void: pass
func _process(delta: float) -> void:
	elapsed += minf(delta,.1)
	if label != null and elapsed >= .72:
		label.text = "物品身份盖章机\n姓名：未通过\n学号：未通过\n人格：未通过\n对象类型：书包"
		stamp.disabled = false
func _stamp() -> void:
	if elapsed < .72 or issued: return
	issued = true
	finished.emit({"scanMs":elapsed*1000,"identityChecks":[false,false,false],"stamped":true})
