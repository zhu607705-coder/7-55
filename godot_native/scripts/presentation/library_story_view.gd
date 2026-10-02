extends Control
## One global modal surface across both phone and RPG, matching LibraryStoryOverlay.
signal advance
var session: RefCounted
var panel: Panel
var speaker: Label
var body: Label
var prompt: Label
var last_sequence: String=""
func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter=Control.MOUSE_FILTER_STOP; focus_mode=Control.FOCUS_ALL
	panel=Panel.new(); panel.mouse_filter=Control.MOUSE_FILTER_IGNORE; add_child(panel)
	var box:=StyleBoxFlat.new(); box.bg_color=Color("081419",0.97); box.border_color=Color("b6c9bb"); box.set_border_width_all(2); box.set_corner_radius_all(4)
	panel.add_theme_stylebox_override("panel",box)
	for field: String in ["speaker","body","prompt"]:
		var label:=Label.new(); label.mouse_filter=Control.MOUSE_FILTER_IGNORE
		label.add_theme_font_override("font",load("res://assets/rpg/fonts/fusion_pixel_12px_proportional_zh_hans.ttf"))
		panel.add_child(label); set(field,label)
	body.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	body.add_theme_color_override("font_color",Color("f4edd6"))
	prompt.add_theme_color_override("font_color",Color("9fafac")); prompt.horizontal_alignment=HORIZONTAL_ALIGNMENT_RIGHT
	visible=false
func tick() -> void:
	visible=session!=null
	if not visible: return
	var v: Dictionary=session.snapshot()
	speaker.text=str(v.speaker); body.text=str(v.text)
	var narrow: bool=size.x<620
	var margin: float=16 if narrow else maxf(26,size.x*0.06)
	var width: float=minf(1000,size.x-margin*2)
	var body_size: int=18 if narrow else 23
	var height: float=198 if narrow else 168
	panel.position=Vector2((size.x-width)/2,maxf(8,size.y-height-(30 if narrow else 46)))
	panel.size=Vector2(width,height)
	speaker.position=Vector2(20,16); speaker.size=Vector2(width-40,28)
	speaker.add_theme_font_size_override("font_size",18 if narrow else 20)
	speaker.add_theme_color_override("font_color",Color("edc36c") if v.speaker=="旁白" else Color("c0d59d") if v.speaker=="玩家" else Color("8ed2e4"))
	body.position=Vector2(20,52); body.size=Vector2(width-40,height-85); body.add_theme_font_size_override("font_size",body_size)
	prompt.text="点击 / 空格 / 回车确认" if v.requiresConfirmation else "点击 / 空格 / 回车继续"
	prompt.position=Vector2(20,height-29); prompt.size=Vector2(width-40,22); prompt.add_theme_font_size_override("font_size",12)
	if last_sequence!=str(v.sequenceId): grab_focus(); last_sequence=str(v.sequenceId)
	queue_redraw()
func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO,size),Color(0,0,0,0.22))
func _input(event: InputEvent) -> void:
	if not visible or session==null: return
	if event is InputEventKey:
		get_viewport().set_input_as_handled()
		if event.pressed and not event.echo:
			if event.keycode==KEY_TAB: grab_focus()
			elif event.keycode in [KEY_SPACE,KEY_ENTER,KEY_KP_ENTER]: advance.emit()
	elif event is InputEventMouseButton or event is InputEventScreenTouch:
		# Capture globally so underlying buttons, item drags and world movement
		# cannot act even on the same pointer event that closes the last line.
		get_viewport().set_input_as_handled()
		if event is InputEventMouseButton and event.button_index==MOUSE_BUTTON_LEFT and event.pressed and event.device!=-1: advance.emit()
		elif event is InputEventScreenTouch and event.pressed: advance.emit()
	elif event is InputEventMouseMotion or event is InputEventScreenDrag:
		get_viewport().set_input_as_handled()
