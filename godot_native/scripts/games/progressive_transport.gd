extends Control
## A world-sized reader/input adapter. Only the model may establish an exit;
## only the chapter controller may accept its replay and commit progression.
signal completed(result: Dictionary)
signal cancelled

const Model = preload("res://scripts/games/progressive_transport_model.gd")
const Ui = preload("res://scripts/ui/native_ui_theme.gd")
const LOGICAL := Vector2(960,540)
const PAPER := Color("f4efdf")
const INK := Color("26383c")
const MUTED := Color("64736d")
const ACCENT := Color("b26742")
const WATER := Color("bed1cf")
const CIRCUIT_FONT_SIZE := 13

var config: Dictionary = {}
var model: RefCounted
var state: Dictionary = {}
var controls: Dictionary = {}
var title_label: Label
var objective_label: Label
var status_label: Label
var feedback_label: Label
var feedback_chip: Label
var circuit_card: Control
var reading_panel: PanelContainer
var reading_title: Label
var reading_body: Label
var reading_next: Button
var reading_close: Button
var field := Rect2()
var board := Rect2()
var cell_size := 48.0
var paused := false
var help_open := false
var help_tier := 0
var done := false
var disposed := false
var coarse := false
var touch_seen := false
var held_keys: Dictionary = {}
var pointer_id := -99
var pointer_start := Vector2.ZERO
var touch_button: Button
var last_touch_ms := -1000
var chip_left := 0.0
var chip_cell: Dictionary = {}
var chip_text := ""
var animation_time := 0.0
var _built := false

func setup(value: Dictionary) -> void:
	config = value.duplicate(true)
	model = Model.new(str(config.get("puzzleId","")))
	state = model.snapshot()
	done = false
	disposed = false
	paused = false
	help_open = false
	help_tier = 0
	if is_inside_tree():
		_build()
		_refresh()

func uses_activity_layout() -> bool:
	return true

func configure_activity_layout(available: Vector2, _compact: bool) -> void:
	if size != available: _clear_input()
	custom_minimum_size = Vector2.ZERO
	scale = Vector2.ONE
	position = Vector2.ZERO
	size = available.max(Vector2(240,240))
	_layout()

func _ready() -> void:
	name = "ProgressiveTransport"
	mouse_filter = Control.MOUSE_FILTER_STOP
	focus_mode = Control.FOCUS_ALL
	coarse = DisplayServer.is_touchscreen_available()
	_build()
	resized.connect(_layout)
	visibility_changed.connect(_visibility_changed)
	get_window().focus_exited.connect(_focus_out)
	if model != null: _refresh()
	grab_focus.call_deferred()

func _label(id: String, pixels: int, color: Color = INK) -> Label:
	var label := Label.new()
	label.name = id
	label.add_theme_font_size_override("font_size",pixels)
	label.add_theme_color_override("font_color",color)
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(label)
	return label

func _button(id: String, text: String, action: Callable) -> Button:
	var button := Button.new()
	button.name = id
	button.text = text
	button.focus_mode = Control.FOCUS_NONE
	Ui.apply_button(button,Color("e6e1cf"),INK,Color("80908b"),4,1,16,Vector2(8,6),Color("cf9870"))
	button.pressed.connect(action)
	controls[id] = button
	add_child(button)
	return button

func _build() -> void:
	if _built: return
	_built = true
	title_label = _label("TransportTitle",24)
	objective_label = _label("TransportObjective",17)
	status_label = _label("TransportStatus",14,MUTED)
	feedback_label = _label("TransportFeedback",16)
	feedback_chip = _label("TransportObjectFeedback",14)
	feedback_chip.add_theme_stylebox_override("normal",Ui.box(Color("fff8e7"),Color("bc8b69"),1,4,Vector2(8,6)))
	feedback_chip.hide()
	circuit_card = Control.new()
	circuit_card.name = "TransportCircuitCard"
	circuit_card.mouse_filter = Control.MOUSE_FILTER_IGNORE
	circuit_card.clip_contents = true
	circuit_card.draw.connect(_draw_portrait_circuit)
	add_child(circuit_card)
	circuit_card.hide()
	_button("TransportExit","返回现场",_cancel)
	_button("TransportHelp","观察提示",_help)
	_button("TransportPause","暂停",_pause)
	_button("TransportUndo","撤回 · Z",func(): _apply("undo"))
	_button("TransportRestart","重来 · R",func(): _apply("restart"))
	_button("TransportContinue","下一拍",_continue)
	for spec: Array in [["TransportUp","↑","up"],["TransportDown","↓","down"],["TransportLeft","←","left"],["TransportRight","→","right"]]:
		var action: String = spec[2]
		var direction_button:=_button(spec[0],spec[1],func(): _apply(action))
		direction_button.set_meta("tactile_keep_layout",true)
		direction_button.set_meta("tactile_variant","ghost")
	reading_panel = PanelContainer.new()
	reading_panel.name = "TransportReadingPanel"
	reading_panel.add_theme_stylebox_override("panel",Ui.box(Color("fff9e9"),INK,2,6,Vector2(18,16)))
	add_child(reading_panel)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation",14)
	reading_panel.add_child(column)
	reading_title = Label.new()
	reading_title.add_theme_font_size_override("font_size",22)
	reading_title.add_theme_color_override("font_color",INK)
	column.add_child(reading_title)
	reading_body = Label.new()
	reading_body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	reading_body.add_theme_font_size_override("font_size",18)
	reading_body.add_theme_color_override("font_color",INK)
	reading_body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	column.add_child(reading_body)
	reading_next = Button.new()
	reading_next.name = "TransportNextHint"
	reading_next.text = "再观察一层"
	reading_next.custom_minimum_size.y = 44
	Ui.apply_button(reading_next,Color("e6e1cf"),INK,MUTED,4,1,16,Vector2(8,6),ACCENT)
	reading_next.pressed.connect(_next_hint)
	column.add_child(reading_next)
	reading_close = Button.new()
	reading_close.name = "TransportCloseReading"
	reading_close.text = "回到棋盘"
	reading_close.custom_minimum_size.y = 44
	Ui.apply_button(reading_close,INK,PAPER,INK,4,1,16,Vector2(8,6),ACCENT)
	reading_close.pressed.connect(_close_reading)
	column.add_child(reading_close)
	reading_panel.hide()
	_layout()

func _place(id: String, rect: Rect2) -> void:
	var button: Button = controls[id]
	button.position = rect.position
	button.size = rect.size

func _layout() -> void:
	if not _built: return
	var portrait: bool = size.y > size.x
	var short_landscape: bool = not portrait and size.y < 560
	var touch: bool = coarse or touch_seen
	title_label.position = Vector2(18,14)
	title_label.size = Vector2(maxf(100,size.x-152),35)
	title_label.add_theme_font_size_override("font_size",20 if portrait else 24)
	_place("TransportExit",Rect2(size.x-128,12,110,44))
	objective_label.visible = true
	objective_label.position = Vector2(18,57)
	objective_label.size = Vector2(size.x-36,24 if portrait else 44)
	objective_label.autowrap_mode = TextServer.AUTOWRAP_OFF if portrait else TextServer.AUTOWRAP_WORD_SMART
	status_label.position = Vector2(18,88 if portrait else 98)
	status_label.size = Vector2(size.x-36,24)
	status_label.autowrap_mode = TextServer.AUTOWRAP_OFF if portrait else TextServer.AUTOWRAP_WORD_SMART
	var top := 120.0 if portrait else 126.0
	var bottom := 252.0 if portrait and touch else 150.0 if touch else 128.0
	var area := Rect2(12,top,size.x-24,maxf(100,size.y-top-bottom))
	var factor := minf(area.size.x/LOGICAL.x,area.size.y/LOGICAL.y)
	if portrait and size.y<760:
		factor = minf(factor,maxf(70,size.y-top-376)/LOGICAL.y)
	field = Rect2(Vector2((size.x-LOGICAL.x*factor)/2,top if portrait else area.get_center().y-LOGICAL.y*factor/2),LOGICAL*factor)
	feedback_label.position = Vector2(18,field.end.y+10)
	feedback_label.size = Vector2(size.x-36,42)
	var tools_y := size.y-58
	if portrait:
		var w := (size.x-48)/3
		_place("TransportUndo",Rect2(12,tools_y,w,44))
		_place("TransportRestart",Rect2(24+w,tools_y,w,44))
		_place("TransportHelp",Rect2(36+w*2,tools_y,w,44))
		_place("TransportPause",Rect2(size.x-108,field.end.y+60,96,44))
		_place("TransportContinue",Rect2(12,field.end.y+60,size.x-132,44))
	else:
		_place("TransportUndo",Rect2(18,tools_y,124,44))
		_place("TransportRestart",Rect2(152,tools_y,124,44))
		_place("TransportHelp",Rect2(286,tools_y,124,44))
		_place("TransportPause",Rect2(420,tools_y,96,44))
		_place("TransportContinue",Rect2(size.x-202,tools_y,184,44))
	var pad := Vector2(83,size.y-145) if portrait else Vector2(size.x-304,size.y-83)
	for spec: Array in [["TransportUp",Vector2(0,-48)],["TransportDown",Vector2(0,0)],["TransportLeft",Vector2(-48,0)],["TransportRight",Vector2(48,0)]]:
		_place(spec[0],Rect2(pad+spec[1],Vector2(44,44)))
		controls[spec[0]].visible = touch
	if portrait and size.y<760:
		var row_ids := ["TransportLeft","TransportUp","TransportDown","TransportRight"]
		for i: int in row_ids.size():
			_place(row_ids[i],Rect2((size.x-204)/2+i*54,size.y-118,44,44))
	if short_landscape:
		# A short landscape screen keeps its full world; readable controls occupy
		# the drawing's side margin rather than shrinking the board to a strip.
		factor = minf(size.x/LOGICAL.x,size.y/LOGICAL.y)
		field = Rect2((size-LOGICAL*factor)/2,LOGICAL*factor)
		var side_x := field.position.x+710*factor
		title_label.position = Vector2(side_x,12)
		title_label.size = Vector2(size.x-side_x-12,28)
		title_label.add_theme_font_size_override("font_size",18)
		status_label.position = Vector2(side_x,44)
		status_label.size = Vector2(size.x-side_x-12,42)
		objective_label.position = Vector2(side_x,88)
		objective_label.size = Vector2(size.x-side_x-12,64)
		objective_label.add_theme_font_size_override("font_size",14)
		feedback_label.position = Vector2(side_x,156)
		feedback_label.size = Vector2(size.x-side_x-12,62)
		feedback_label.add_theme_font_size_override("font_size",14)
		var toolbar_width := (size.x-84)/6
		var toolbar_ids := ["TransportUndo","TransportRestart","TransportHelp","TransportPause","TransportContinue","TransportExit"]
		for i: int in toolbar_ids.size():
			_place(toolbar_ids[i],Rect2(12+i*(toolbar_width+12),tools_y,toolbar_width,44))
			controls[toolbar_ids[i]].add_theme_font_size_override("font_size",14)
		pad = Vector2(size.x-98,size.y-116)
		for spec: Array in [["TransportUp",Vector2(0,-48)],["TransportDown",Vector2(0,0)],["TransportLeft",Vector2(-48,0)],["TransportRight",Vector2(48,0)]]:
			_place(spec[0],Rect2(pad+spec[1],Vector2(44,44)))
	else:
		objective_label.add_theme_font_size_override("font_size",16 if portrait else 17)
		feedback_label.add_theme_font_size_override("font_size",16)
	reading_panel.size = Vector2(minf(490,size.x-32),minf(330,size.y-32))
	reading_panel.position = (size-reading_panel.size)/2
	_update_board()
	_layout_circuit_card()
	_update_status()
	_place_chip()
	queue_redraw()

func _update_board() -> void:
	var width: int = maxi(1,int(state.get("width",1)))
	var height: int = maxi(1,int(state.get("height",1)))
	var portrait: bool = size.y>size.x
	var board_width := 936.0 if portrait else 640.0
	var board_height := 516.0 if portrait else 400.0 if size.y<560 else 454.0
	var origin := Vector2(12,12) if portrait else Vector2(30,42)
	cell_size = minf(board_width/width,board_height/height)
	board = Rect2(origin+Vector2((board_width-width*cell_size)/2,(board_height-height*cell_size)/2),Vector2(width,height)*cell_size)

func _update_status() -> void:
	var portrait: bool = size.y>size.x
	status_label.text = "第 %d / %d 拍" % [int(state.get("stageIndex",0))+1,int(state.get("stageCount",3))]
	if not portrait: status_label.text += " · "+str(state.get("stageTitle",""))
	if not state.get("connections",{}).is_empty() and (portrait or size.y<560):
		var connected := 0
		for value: String in state.connections.values():
			if value == "on": connected += 1
		status_label.text += " · 当前连接 %d / %d" % [connected,state.connections.size()]

func _layout_circuit_card() -> void:
	if not _built: return
	circuit_card.visible = size.y>size.x and not state.get("connections",{}).is_empty()
	circuit_card.size = Vector2(minf(330,size.x-32),130)
	circuit_card.position = Vector2((size.x-circuit_card.size.x)/2,field.end.y+116)
	circuit_card.queue_redraw()

func _refresh() -> void:
	if not _built or model == null: return
	state = model.snapshot()
	title_label.text = str(state.get("title","现场演练"))
	# Teaching rationale belongs to the authoring data, not the default HUD.
	objective_label.text = str(state.get("objective",""))
	_update_status()
	var feedback: Dictionary = state.get("feedback",{})
	feedback_label.text = str(feedback.get("text","先观察物件与通路，再尝试移动。"))
	var complete: bool = bool(state.get("complete",false))
	var stage_complete: bool = bool(state.get("stageComplete",false))
	controls.TransportContinue.visible = complete or stage_complete
	controls.TransportContinue.text = ("结束复盘" if bool(config.get("replay",false)) else "提交记录") if complete else "下一拍"
	controls.TransportContinue.disabled = done or paused or help_open
	controls.TransportUndo.disabled = not bool(state.get("canUndo",false)) or done or paused or help_open
	controls.TransportRestart.disabled = done or paused or help_open
	for key: String in ["TransportUp","TransportDown","TransportLeft","TransportRight"]:
		controls[key].disabled = done or paused or help_open or stage_complete or complete
	controls.TransportPause.text = "继续" if paused else "暂停"
	_update_board()
	_layout_circuit_card()
	_place_chip()
	queue_redraw()

func _apply(action: String) -> void:
	if done or disposed or paused or help_open or model == null: return
	var previous: Dictionary = state.duplicate(true)
	model.apply(action)
	_refresh()
	_observe_action(previous)
	_place_chip()

func _observe_action(previous: Dictionary) -> void:
	var feedback: Dictionary = state.get("feedback",{})
	chip_cell = feedback.get("cell",{}).duplicate(true)
	chip_text = str(feedback.get("text",""))
	if feedback.get("kind","") == "move":
		chip_cell = {}
		for category: String in ["objects","plates","gates"]:
			var old: Array = previous.get(category,[])
			for item: Dictionary in state.get(category,[]):
				for before: Dictionary in old:
					if before.get("id") != item.get("id") or before == item: continue
					chip_cell = {"x":item.x,"y":item.y}
					chip_text = ("通道打开" if item.get("open",false) else "通道关闭") if category=="gates" else ("触点亮起" if item.get("active",false) else "触点熄灭") if category=="plates" else "物件移动"
	chip_left = 2.0 if not chip_cell.is_empty() else 0.0

func _continue() -> void:
	if done or disposed or paused or help_open or model == null: return
	if bool(state.get("complete",false)):
		done = true
		_clear_input()
		var proof: Dictionary = model.proof()
		proof["session"] = config.get("session",{}).duplicate(true)
		_refresh()
		completed.emit(proof)
	elif bool(state.get("stageComplete",false)):
		help_tier = 0
		_apply("continue")

func _help() -> void:
	if done or disposed or model == null: return
	_clear_input()
	help_open = true
	help_tier = maxi(1,help_tier)
	_update_reading()
	_refresh()

func _next_hint() -> void:
	if not help_open or disposed: return
	help_tier = mini(help_tier+1,state.get("hints",[]).size())
	_update_reading()

func _update_reading() -> void:
	reading_panel.show()
	reading_title.text = "停下来观察" if help_open else "演练已暂停"
	var hints: Array = state.get("hints",[])
	reading_body.text = str(hints[clampi(help_tier-1,0,hints.size()-1)]) if help_open and not hints.is_empty() else "棋盘保留在原处。准备好后再继续。"
	reading_next.visible = help_open and help_tier < hints.size()
	reading_close.text = "回到棋盘"
	reading_panel.move_to_front()
	reading_close.grab_focus.call_deferred()

func _close_reading() -> void:
	if disposed: return
	_clear_input()
	help_open = false
	paused = false
	reading_panel.hide()
	_refresh()
	grab_focus()

func _pause() -> void:
	if done or disposed or not _built: return
	if paused or help_open:
		_close_reading()
		return
	_clear_input()
	paused = true
	_update_reading()
	_refresh()

func _visibility_changed() -> void:
	if not is_visible_in_tree(): _focus_out()

func _focus_out() -> void:
	if paused or done or disposed or not _built: return
	_clear_input()
	paused = true
	_update_reading()
	_refresh()

func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT: _focus_out()

func _cancel() -> void:
	if done or disposed: return
	done = true
	_clear_input()
	cancelled.emit()

func _clear_input() -> void:
	held_keys.clear()
	pointer_id = -99
	touch_button = null

func dispose_presentation() -> void:
	disposed = true
	_clear_input()
	set_process_input(false)
	set_process(false)

func _exit_tree() -> void:
	dispose_presentation()
	if get_window() != null and get_window().focus_exited.is_connected(_focus_out):
		get_window().focus_exited.disconnect(_focus_out)

func _input(event: InputEvent) -> void:
	if done or disposed or not is_visible_in_tree(): return
	if event is InputEventKey:
		var key: int = event.physical_keycode if event.physical_keycode else event.keycode
		if not event.pressed:
			held_keys.erase(key)
			return
		if event.echo or held_keys.has(key): return
		held_keys[key] = true
		if key == KEY_ESCAPE:
			_pause()
			get_viewport().set_input_as_handled()
			return
		if paused or help_open: return
		var action: String = {KEY_W:"up",KEY_UP:"up",KEY_S:"down",KEY_DOWN:"down",KEY_A:"left",KEY_LEFT:"left",KEY_D:"right",KEY_RIGHT:"right",KEY_Z:"undo",KEY_R:"restart"}.get(key,"")
		if not action.is_empty():
			_apply(action)
			get_viewport().set_input_as_handled()
	elif event is InputEventScreenTouch:
		last_touch_ms = Time.get_ticks_msec()
		if not touch_seen:
			touch_seen = true
			_layout()
		var point: Vector2 = get_global_transform_with_canvas().affine_inverse()*event.position
		# Some platform GUI emulation arrives before the source touch. A real
		# finger supersedes that synthetic mouse owner, never another finger.
		if event.pressed and not event.canceled and pointer_id in [-99,-1]:
			pointer_id = event.index
			pointer_start = point
			touch_button = _button_at(point)
		elif not event.pressed and event.index == pointer_id:
			var button: Button = touch_button
			var origin := pointer_start
			_clear_input()
			if not event.canceled:
				if is_instance_valid(button) and button.is_visible_in_tree() and not button.disabled and Rect2(Vector2.ZERO,button.size).has_point(button.get_global_transform_with_canvas().affine_inverse()*event.position): button.pressed.emit()
				elif button == null and not paused and not help_open: _point_action(origin,point)
		get_viewport().set_input_as_handled()
	elif event is InputEventMouse and Time.get_ticks_msec()-last_touch_ms < 400:
		get_viewport().set_input_as_handled()

func _button_at(point: Vector2) -> Button:
	if paused or help_open:
		for button: Button in [reading_close,reading_next]:
			if button.is_visible_in_tree() and not button.disabled and button.get_global_rect().has_point(global_position+point): return button
		return null
	for key: String in controls:
		var button: Button = controls[key]
		if button.is_visible_in_tree() and not button.disabled and button.get_rect().has_point(point): return button
	return null

func _gui_input(event: InputEvent) -> void:
	if paused or help_open or done or disposed: return
	# GUI-generated touch emulation may bypass the raw input callback.
	if event is InputEventMouse and Time.get_ticks_msec()-last_touch_ms < 400: return
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			pointer_start = event.position
			pointer_id = -1
			grab_focus()
		elif pointer_id == -1:
			pointer_id = -99
			_point_action(pointer_start,event.position)
		accept_event()

func _point_action(origin: Vector2, target: Vector2) -> void:
	if not field.has_point(origin) or not field.has_point(target): return
	var local := (target-field.position)/maxf(.001,field.size.x/LOGICAL.x)
	if not board.has_point(local): return
	var actor: Dictionary = state.get("actor",state.get("player",{}))
	var from := Vector2(float(actor.get("x",0))+.5,float(actor.get("y",0))+.5)
	var to := (local-board.position)/cell_size
	var direction := to-from
	var swipe := target-origin
	if swipe.length() > 18: direction = swipe
	if direction.length() < .25: return
	_apply(("right" if direction.x>0 else "left") if absf(direction.x)>absf(direction.y) else ("down" if direction.y>0 else "up"))

func _process(delta: float) -> void:
	if disposed or done or paused or help_open: return
	animation_time += minf(delta,.1)
	chip_left = maxf(0,chip_left-delta)
	_place_chip()
	queue_redraw()

func _cell_center(value: Dictionary) -> Vector2:
	return board.position+Vector2(float(value.get("x",0))+.5,float(value.get("y",0))+.5)*cell_size

func _place_chip() -> void:
	if not _built: return
	feedback_chip.visible = chip_left>0 and not chip_cell.is_empty() and not paused and not help_open
	if not feedback_chip.visible: return
	feedback_chip.text = chip_text
	feedback_chip.size = Vector2(minf(252,size.x-32),58)
	var center := field.position+_cell_center(chip_cell)*(field.size.x/LOGICAL.x)
	feedback_chip.position = Vector2(clampf(center.x-feedback_chip.size.x/2,12,size.x-feedback_chip.size.x-12),clampf(center.y-70,field.position.y,field.end.y-58))

func _text(text: String, point: Vector2, pixels: int = 18, color: Color = INK) -> void:
	draw_string(get_theme_default_font(),point,text,HORIZONTAL_ALIGNMENT_LEFT,-1,pixels,color)

func _bounded_text(text: String, rect: Rect2, pixels: int, color: Color = INK) -> void:
	var font := get_theme_default_font()
	while pixels>11 and font.get_string_size(text,HORIZONTAL_ALIGNMENT_LEFT,-1,pixels).x>rect.size.x-6: pixels-=1
	var shown := text
	while shown.length()>1 and font.get_string_size(shown,HORIZONTAL_ALIGNMENT_LEFT,-1,pixels).x>rect.size.x-6:
		shown = shown.substr(0,shown.length()-2)+"…"
	_text(shown,rect.position+Vector2(3,rect.size.y*.6),pixels,color)

func _draw_connections() -> void:
	var connections: Dictionary = state.get("connections",{})
	if connections.is_empty(): return
	_text("当前线路",Vector2(710,72),22)
	var nodes := {"hall":Vector2(818,126),"west_corridor":Vector2(748,219),"east_corridor":Vector2(888,219),"bakery_back_area":Vector2(748,340),"classroom_zone":Vector2(888,340)}
	for edge: String in connections:
		var ends := edge.split("__")
		if ends.size()!=2 or not nodes.has(ends[0]) or not nodes.has(ends[1]): continue
		var active: bool = connections[edge]=="on"
		draw_line(nodes[ends[0]],nodes[ends[1]],Color("3e7780") if active else Color("b7bdb0"),4 if active else 1)
	var labels := {"hall":"门厅","west_corridor":"西廊","east_corridor":"东廊","bakery_back_area":"烘焙后区","classroom_zone":"教室区"}
	for id: String in nodes:
		var rect := Rect2(nodes[id]-Vector2(43,20),Vector2(86,40))
		draw_style_box(Ui.box(PAPER,MUTED,1,4,Vector2.ZERO),rect)
		_bounded_text(labels[id],rect,17)
	_text("实线：已连接",Vector2(714,424),16,MUTED)
	_text("细线：未连接",Vector2(714,454),16,MUTED)

func _draw_portrait_circuit() -> void:
	# Native UI pixels keep this graph readable independently of the uniformly
	# scaled world. Every edge is drawn only from the current observed state.
	if not circuit_card.visible: return
	var extent := circuit_card.size
	circuit_card.draw_style_box(Ui.box(Color("fcf8eb"),Color("b4c0b3"),1,5,Vector2.ZERO),Rect2(Vector2.ZERO,extent))
	var nodes := {"hall":Vector2(.5,25),"west_corridor":Vector2(.19,66),"east_corridor":Vector2(.81,66),"bakery_back_area":Vector2(.19,108),"classroom_zone":Vector2(.81,108)}
	for id: String in nodes: nodes[id] = Vector2(nodes[id].x*extent.x,nodes[id].y)
	var connections: Dictionary = state.get("connections",{})
	for edge: String in connections:
		var ends := edge.split("__")
		if ends.size()!=2 or not nodes.has(ends[0]) or not nodes.has(ends[1]): continue
		var active: bool = connections[edge]=="on"
		circuit_card.draw_line(nodes[ends[0]],nodes[ends[1]],Color("3e7780") if active else Color("b7bdb0"),2.5 if active else 1)
	var labels := {"hall":"门厅","west_corridor":"西廊","east_corridor":"东廊","bakery_back_area":"烘焙后区","classroom_zone":"教室区"}
	var font := get_theme_default_font()
	for id: String in nodes:
		var rect := Rect2(nodes[id]-Vector2(36,12),Vector2(72,24))
		circuit_card.draw_style_box(Ui.box(PAPER,MUTED,1,3,Vector2.ZERO),rect)
		var text: String = labels[id]
		var width: float = font.get_string_size(text,HORIZONTAL_ALIGNMENT_LEFT,-1,CIRCUIT_FONT_SIZE).x
		circuit_card.draw_string(font,Vector2(rect.get_center().x-width/2,rect.position.y+17),text,HORIZONTAL_ALIGNMENT_LEFT,-1,CIRCUIT_FONT_SIZE,INK)

func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO,size),PAPER)
	draw_line(Vector2(18,50),Vector2(size.x-18,50),Color("d1d4c6"),1)
	if state.is_empty() or field.size.x <= 0: return
	var factor := field.size.x/LOGICAL.x
	draw_set_transform(field.position,0,Vector2.ONE*factor)
	draw_style_box(Ui.box(Color("e5e3d4"),Color("b4c0b3"),2,8,Vector2.ZERO),Rect2(Vector2.ZERO,LOGICAL))
	var tiles: Array = state.get("tiles",[])
	for y: int in tiles.size():
		var row: String = str(tiles[y])
		for x: int in row.length():
			var rect := Rect2(board.position+Vector2(x,y)*cell_size,Vector2.ONE*cell_size)
			var tile := row.substr(x,1)
			var color: Color = Color("788783") if tile=="#" else WATER if tile=="~" else Color("f7f3e4")
			draw_rect(rect.grow(-1),color)
			if tile=="#":
				draw_line(rect.position+Vector2(3,4),rect.position+Vector2(cell_size-4,4),Color("a0ada1"),3)
			elif tile=="~":
				draw_arc(rect.get_center()+Vector2(0,4),cell_size*.24,.2,2.7,12,Color("8eafad"),1.3)
	for plate: Dictionary in state.get("plates",[]):
		var center := _cell_center(plate)
		draw_rect(Rect2(center-Vector2.ONE*cell_size*.32,Vector2.ONE*cell_size*.64),Color("c58b55") if plate.get("active",false) else Color("ddd1a7"))
		draw_rect(Rect2(center-Vector2.ONE*cell_size*.24,Vector2.ONE*cell_size*.48),INK,false,2)
	for target: Dictionary in state.get("targets",[]):
		var rect := Rect2(board.position+Vector2(target.x,target.y)*cell_size,Vector2(target.get("width",1),target.get("height",1))*cell_size).grow(-4)
		var color := Color("628b80") if target.get("active",false) else Color("ad9367")
		draw_rect(rect,Color(color,.15))
		draw_rect(rect,color,false,2 if target.get("active",false) else 1)
		_bounded_text(str(target.get("label","停放位")),rect,14,color)
	for checkpoint: Dictionary in state.get("checkpoints",[]):
		var center := _cell_center(checkpoint)
		draw_circle(center,cell_size*.27,Color("819b8d") if checkpoint.get("visited",false) else Color("d7dbca"))
		_bounded_text(str(checkpoint.get("label","站")),Rect2(center-Vector2.ONE*cell_size*.35,Vector2.ONE*cell_size*.7),16)
	for gate: Dictionary in state.get("gates",[]):
		var rect := Rect2(board.position+Vector2(gate.x,gate.y)*cell_size,Vector2(gate.get("width",1),gate.get("height",1))*cell_size).grow(-3)
		if gate.get("open",false): draw_rect(rect,Color("90a798"),false,3)
		else:
			draw_rect(rect,Color("9f7162"))
			for i: int in 3: draw_line(rect.position+Vector2((i+1)*rect.size.x/4,3),rect.position+Vector2((i+1)*rect.size.x/4,rect.size.y-3),PAPER,2)
	var exit: Dictionary = state.get("exit",{})
	if not exit.is_empty():
		var center := _cell_center(exit)
		draw_rect(Rect2(center-Vector2.ONE*cell_size*.4,Vector2.ONE*cell_size*.8),Color("e0b580") if exit.get("open",false) else Color("c9cbb9"),false,3)
		_text("出口",center+Vector2(-18,6),18)
	for tool: Dictionary in state.get("objects",state.get("tools",[])):
		var rect := Rect2(board.position+Vector2(tool.x,tool.y)*cell_size,Vector2(tool.get("width",1),tool.get("height",1))*cell_size).grow(-5)
		draw_rect(rect,Color("b7aa86"))
		draw_rect(rect,INK,false,2)
		draw_line(rect.position+Vector2(5,6),rect.end-Vector2(5,6),Color("e8ddbb"),2)
		_bounded_text(str(tool.get("label","模块")),rect,16)
	var actor: Dictionary = state.get("actor",state.get("player",{}))
	if not actor.is_empty():
		var center := _cell_center(actor)
		if actor.get("kind","")=="boat" or str(state.get("puzzleId",""))=="lake_logistics":
			draw_colored_polygon(PackedVector2Array([center+Vector2(0,-cell_size*.4),center+Vector2(cell_size*.29,cell_size*.27),center+Vector2(-cell_size*.29,cell_size*.27)]),Color("886e50"))
			draw_line(center+Vector2(-cell_size*.39,0),center+Vector2(cell_size*.39,0),INK,3)
		else:
			draw_circle(center+Vector2(0,cell_size*.1),cell_size*.24,INK)
			draw_line(center+Vector2(-cell_size*.2,cell_size*.35),center+Vector2(cell_size*.2,cell_size*.35),INK,4)
		draw_circle(center+Vector2(0,-cell_size*.19),cell_size*.16,Color("dbad7e"))
	if size.y>size.x:
		pass # Portrait uses the readable native circuit card, never tiny legends.
	elif not state.get("connections",{}).is_empty() and not (size.x>size.y and size.y<560):
		_draw_connections()
	elif not (size.x>size.y and size.y<560):
		_text("现场演练",Vector2(710,72),24)
		_text("人 / 船",Vector2(710,128),18)
		_text("每次输入移动一格",Vector2(710,163),15,MUTED)
		if not state.get("plates",[]).is_empty():
			_text("压力垫与门",Vector2(710,225),18)
			_text("留意动作前后的变化",Vector2(710,260),15,MUTED)
		elif not state.get("targets",[]).is_empty():
			_text("停放位置",Vector2(710,225),18)
			_text("轮廓标出当前交接区域",Vector2(710,260),15,MUTED)
		_text("抵达出口",Vector2(710,322),18)
		_text("局部成立后，仍要亲自离场",Vector2(710,357),15,MUTED)
		_text("点相邻方向 / 滑动一步",Vector2(710,431),15,MUTED)
		_text("WASD · 方向键",Vector2(710,459),15,MUTED)
	draw_set_transform(Vector2.ZERO)
	if paused or help_open: draw_rect(Rect2(Vector2.ZERO,size),Color(0.08,.12,.12,.38))
