extends Control
## Fixed 960x540 source-pixel mixer surface. Main must mount this inside its
## blocking modal owner and uniformly scale it with the world (see port doc).
## Only callbacks request actions; neither this panel nor its session mutates s.
signal closed(reason: String)
const Session = preload("res://scripts/presentation/c3_mixer_session.gd")
const CENTER := Vector2(480, 245)
var session: RefCounted = Session.new()
var read_state: Callable
var dispatch: Callable
var feedback: Callable
var model: Dictionary = {}
var slots: Array[Button] = []
var labels: Array[Label] = []
var exit_button: Button
var shelf_label: Label
var close_emitted: bool = false
var compact_layout := false
var compact_portrait := false
var compact_board := Rect2()
var title_label: Label
var glass_label: Label
var prompt_label: Label
var exit_label: Label
var feedback_label: Label
var compact_glass_height := 144.0

func setup(state_reader: Callable, action_sink: Callable, feedback_sink: Callable = Callable(), random: RandomNumberGenerator = null) -> bool:
	read_state = state_reader
	dispatch = action_sink
	feedback = feedback_sink
	size = Vector2(960, 540)
	custom_minimum_size = size
	mouse_filter = Control.MOUSE_FILTER_STOP
	if not read_state.is_valid() or not session.open(read_state.call(), random):
		visible = false
		return false
	if slots.is_empty(): _build()
	close_emitted = false
	visible = true
	refresh()
	return true

func _build() -> void:
	feedback_label=_add_label("",Rect2(),14,Color("fff2d8"))
	feedback_label.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	feedback_label.hide()
	title_label = _add_label("食堂新品混合台", Rect2(162, 63, 470, 28), 22, Color("fff3c4"), false)
	exit_button = _button(Rect2(CENTER+Vector2(208, -190), Vector2(132, 40)), "退出混合台")
	exit_button.pressed.connect(dismiss)
	exit_label = _add_label("退出  Esc", Rect2(CENTER+Vector2(211, -183), Vector2(126, 26)), 14, Color("fff3c4"))
	glass_label = _add_label("大玻璃杯", Rect2(CENTER+Vector2(-100, -131), Vector2(200, 26)), 14, Color("c8f3ff"))
	prompt_label = _add_label(str(session.drinks.mixerPrompt), Rect2(CENTER+Vector2(-320, 85), Vector2(640, 26)), 15, Color("fff2c4"))
	shelf_label = _add_label("", Rect2(CENTER+Vector2(-320, 109), Vector2(640, 26)), 13, Color.WHITE)
	for index in range(3):
		var x: float = Session.BUTTON_X[index]
		var button: Button = _button(Rect2(CENTER+Vector2(x-88, 133), Vector2(176, 54)), "")
		button.pressed.connect(_pour.bind(index))
		slots.append(button)
		labels.append(_add_label("", Rect2(CENTER+Vector2(x-65, 147), Vector2(150, 26)), 13, Color.WHITE))

func set_feedback(message: String) -> void:
	if not is_instance_valid(feedback_label): return
	feedback_label.text=message
	feedback_label.visible=compact_layout and not message.is_empty()

func configure_layout(viewport: Vector2, compact: bool) -> void:
	compact_layout=compact
	for child in get_children():
		if child is Control and not child.has_meta("desktop_rect"):
			child.set_meta("desktop_rect",Rect2(child.position,child.size))
			child.set_meta("desktop_font",child.get_theme_font_size("font_size"))
	if not compact:
		custom_minimum_size=Vector2(960,540); size=custom_minimum_size
		for child in get_children():
			if child is Control:
				var rect: Rect2=child.get_meta("desktop_rect"); child.position=rect.position; child.size=rect.size
				child.add_theme_font_size_override("font_size",child.get_meta("desktop_font"))
		exit_label.text="退出  Esc"
		feedback_label.hide()
		queue_redraw(); return
	custom_minimum_size=Vector2.ZERO; size=viewport
	compact_portrait=viewport.y>viewport.x
	var extent:=Vector2(minf(viewport.x-24,560 if compact_portrait else 720),minf(viewport.y-24,620 if compact_portrait else 460))
	compact_board=Rect2((viewport-extent)/2,extent)
	var start: Vector2=compact_board.position; var w: float=extent.x
	_place(title_label,Rect2(start+Vector2(16,14),Vector2(w-98,32)),20)
	_place(exit_button,Rect2(start+Vector2(w-78,10),Vector2(64,44)))
	_place(exit_label,Rect2(exit_button.position,exit_button.size),16); exit_label.text="退出"
	_place(glass_label,Rect2(start+Vector2(16,64),Vector2(w-32,24)),14)
	compact_glass_height=144 if compact_portrait else clampf(extent.y-326,56,134)
	var prompt_y: float=284 if compact_portrait else 102+compact_glass_height+26
	_place(prompt_label,Rect2(start+Vector2(16,prompt_y),Vector2(w-32,44 if compact_portrait else 28)),16)
	prompt_label.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	_place(shelf_label,Rect2(start+Vector2(16,prompt_y+48 if compact_portrait else prompt_y+32),Vector2(w-32,40 if compact_portrait else 28)),14)
	shelf_label.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	for index in range(3):
		var rect: Rect2
		if compact_portrait: rect=Rect2(start+Vector2(16,392+index*58),Vector2(w-32,48))
		else:
			var width: float=(w-48)/3
			rect=Rect2(start+Vector2(16+index*(width+8),prompt_y+70),Vector2(width,48))
		_place(slots[index],rect)
		_place(labels[index],Rect2(rect.position+Vector2(32,0),rect.size-Vector2(38,0)),16)
	_place(feedback_label,Rect2(start+Vector2(16,560 if compact_portrait else prompt_y+128),Vector2(w-32,52 if compact_portrait else 44)),14)
	feedback_label.visible=not feedback_label.text.is_empty()
	queue_redraw()

func _place(control: Control, rect: Rect2, font_size: int=0) -> void:
	control.position=rect.position;control.size=rect.size
	if font_size>0: control.add_theme_font_size_override("font_size",font_size)

func _draw_compact() -> void:
	# A mobile-sized device keeps every action visible; the shuffled model and
	# actual pour layers are the same ones used by the original desktop surface.
	draw_rect(Rect2(Vector2.ZERO,size),Color(0.02,0.04,0.06,.82))
	_frame(compact_board,Color("08151c"),Color("e0b858"),3)
	var start: Vector2=compact_board.position; var w: float=compact_board.size.x
	draw_rect(Rect2(start+Vector2(3,3),Vector2(w-6,52)),Color("183847"))
	_frame(Rect2(exit_button.position,exit_button.size),Color("2a4651"),Color("e0b858"),2)
	var top: float=start.y+102
	var height: float=compact_glass_height
	var center: float=start.x+w/2
	_frame(Rect2(center-48,top,96,height),Color("b9e6ee",.13),Color("b9e6ee"),3)
	var layer_height: float=(height-14)/3
	for index in range(model.layers.size()):
		var layer: Dictionary=model.layers[index]
		draw_rect(Rect2(center-43,top+height-5-(index+1)*layer_height,86,layer_height-2),_source_color(int(layer.color),float(layer.alpha)))
	_frame(Rect2(start.x+24,top+height+3,w-48,15),Color("8a6135"),Color("3f2b20"),2)
	if feedback_label.visible:
		draw_rect(Rect2(feedback_label.position-Vector2(4,2),feedback_label.size+Vector2(8,4)),Color("172a34"))
	for index in range(model.slots.size()):
		var slot: Dictionary=model.slots[index];var rect:=Rect2(slots[index].position,slots[index].size)
		_frame(rect,Color("164b59") if slot.owned else Color("263038"),Color("6cdcf3") if slot.owned else Color("56636a"),2)
		_frame(Rect2(rect.position+Vector2(10,12),Vector2(16,24)),_source_color(int(slot.color)),Color("c7d9dc"),2)

func _button(rect: Rect2, accessibility: String) -> Button:
	var button := Button.new()
	button.position = rect.position
	button.size = rect.size
	button.tooltip_text = accessibility
	button.add_theme_stylebox_override("normal", StyleBoxEmpty.new())
	button.add_theme_stylebox_override("hover", StyleBoxEmpty.new())
	button.add_theme_stylebox_override("pressed", StyleBoxEmpty.new())
	var focus := StyleBoxFlat.new()
	focus.bg_color = Color.TRANSPARENT
	focus.border_color = Color("fff3c4")
	focus.set_border_width_all(1)
	button.add_theme_stylebox_override("focus", focus)
	add_child(button)
	return button

func _add_label(text: String, rect: Rect2, font_size: int, color: Color, centered: bool = true) -> Label:
	var label := Label.new()
	label.text = text
	label.position = rect.position
	label.size = rect.size
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER if centered else HORIZONTAL_ALIGNMENT_LEFT
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(label)
	return label

func refresh() -> void:
	if close_emitted or not read_state.is_valid(): return
	model = session.snapshot(read_state.call())
	if model.is_empty():
		_finish_close()
		return
	for index in range(slots.size()):
		var slot: Dictionary = model.slots[index]
		# Missing ingredients remain visible and clickable for source feedback.
		slots[index].disabled = false
		slots[index].tooltip_text = slot.label
		labels[index].text = slot.label
		labels[index].add_theme_color_override("font_color", Color("f4fbff") if slot.owned else Color("7f8d92"))
	shelf_label.text = model.shelfStatus
	shelf_label.add_theme_color_override("font_color", Color("91e4ba") if model.shelfRead else Color("e3b878"))
	queue_redraw()

func _pour(index: int) -> void:
	if not blocks_world_input(): return
	refresh()
	if model.is_empty() or index < 0 or index >= model.slots.size(): return
	var slot: Dictionary = model.slots[index]
	if not slot.owned:
		if feedback.is_valid(): feedback.call(session.missing_feedback())
		return
	if dispatch.is_valid(): dispatch.call(str(slot.action), null)
	# State.act is synchronous; source refreshes after each accepted ingredient,
	# then closes on either terminal event. Never judge a recipe in this layer.
	refresh()

func dismiss() -> void:
	if not session.active: return
	session.close()
	model = {}
	_finish_close()

func _finish_close() -> void:
	visible = false
	if close_emitted: return
	close_emitted = true
	closed.emit(session.close_reason)

func blocks_world_input() -> bool:
	return visible and session.active

func _process(_delta: float) -> void:
	if session.active: refresh()

func _input(event: InputEvent) -> void:
	if not blocks_world_input(): return
	if event is InputEventKey and event.keycode == KEY_ESCAPE:
		get_viewport().set_input_as_handled()
		if event.pressed and not event.echo: dismiss()

func _gui_input(event: InputEvent) -> void:
	# Clicking outside the panel has no action and must not move the player.
	if event is InputEventMouse or event is InputEventScreenTouch or event is InputEventScreenDrag:
		accept_event()

func _draw() -> void:
	if model.is_empty(): return
	if compact_layout: _draw_compact(); return
	_frame(Rect2(CENTER-Vector2(345, 195), Vector2(690, 390)), Color(0x08/255.0, 0x15/255.0, 0x1c/255.0, 0.985), Color("e0b858"), 5)
	draw_rect(Rect2(CENTER+Vector2(-338, -191), Vector2(676, 42)), Color("183847"))
	_frame(Rect2(CENTER+Vector2(211, -185), Vector2(126, 30)), Color("2a4651"), Color("e0b858"), 2)
	_frame(Rect2(CENTER+Vector2(-310, 33), Vector2(620, 58)), Color("8a6135"), Color("3f2b20"), 4)
	draw_rect(Rect2(CENTER+Vector2(-56, -94), Vector2(112, 158)), Color(0xdf/255.0, 0xf8/255.0, 1, 0.13))
	for layer: Dictionary in model.layers:
		var rect: Rect2 = layer.rect
		rect.position += CENTER
		draw_rect(rect, _source_color(int(layer.color), float(layer.alpha)))
	var glass := PackedVector2Array([CENTER+Vector2(-58,-98), CENTER+Vector2(-50,64), CENTER+Vector2(50,64), CENTER+Vector2(58,-98), CENTER+Vector2(-58,-98)])
	draw_polyline(glass, Color("b9e6ee"), 5)
	for slot: Dictionary in model.slots:
		var center := CENTER+Vector2(slot.x, 160)
		_frame(Rect2(center-Vector2(87,24), Vector2(174,48)), Color("164b59") if slot.owned else Color("263038"), Color("6cdcf3") if slot.owned else Color("56636a"), 3)
		_frame(Rect2(center-Vector2(66,12), Vector2(18,24)), _source_color(int(slot.color)), Color(0xc7/255.0,0xd9/255.0,0xdc/255.0,0.85), 2)

func _frame(rect: Rect2, fill: Color, stroke: Color, width: float) -> void:
	draw_rect(rect, fill)
	draw_rect(rect, stroke, false, width)

func _source_color(hex: int, alpha: float = 1.0) -> Color:
	return Color(float((hex>>16)&255)/255, float((hex>>8)&255)/255, float(hex&255)/255, alpha)

func _exit_tree() -> void:
	if session.active: session.close("teardown")
