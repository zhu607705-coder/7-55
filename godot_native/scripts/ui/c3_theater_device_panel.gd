extends Control
const PixelEdges=preload("res://scripts/ui/pixel_edges.gd")
## Source-sized theater device controls. Draft edits use controller intents;
## local keypad text is presentation-only and clears on a fresh open.
signal closed(reason: String)
const CENTER := Vector2(480,270)
const Typography=preload("res://scripts/ui/native_typography.gd")
var kind := ""
var read_state: Callable
var dispatch: Callable
var feedback: Callable
var bound_state: Dictionary = {}
var code := ""
var active := false
var compact_layout := false
var compact_board := Rect2()
var title_label: Label
var feedback_label: Label
var display: Label
var program_buttons: Dictionary = {}
var controls: Dictionary = {}
var content: Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://data/source/chapter3-theater.content.json"))

func setup(device: String, reader: Callable, sink: Callable, feedback_sink: Callable=Callable()) -> bool:
	kind=device; read_state=reader; dispatch=sink; feedback=feedback_sink
	if not reader.is_valid() or kind not in ["code","program"]: return false
	bound_state=reader.call()
	if str(bound_state.get("native",{}).get("scene",""))!="theater_interior": return false
	size=Vector2(960,540); custom_minimum_size=size
	mouse_filter=Control.MOUSE_FILTER_STOP
	active=true; code=""
	_build(); refresh(); return active

func _build() -> void:
	feedback_label=_label("",Rect2(),14,Color("fff2d8"));feedback_label.hide()
	if kind=="code":
		title_label=_label(str(content.ticket.codePrompt),Rect2(235,105,490,42),17,Color("fff2d8"))
		display=_label("",Rect2(340,168,280,58),30,Color("8fe8ff"))
		Typography.apply_display(display)
		for index in range(10):
			var digit:=str(index)
			_button(digit,digit,Vector2(-180+(index%5)*90,5+floori(float(index)/5)*58),Vector2(70,42),func(): _digit(digit))
		_button("backspace","退格",Vector2(-150,132),Vector2(120,42),backspace)
		_button("submit","提交",Vector2(0,132),Vector2(120,42),submit)
		_button("close","关闭",Vector2(150,132),Vector2(120,42),dismiss)
	else:
		title_label=_label(str(content.program.consolePrompt)+"\n"+str(content.program.consoleState),Rect2(185,85,590,60),17,Color("fff2d8"))
		display=_label("",Rect2(200,164,560,49),22,Color("8fe8ff"))
		for index in range(bound_state.theaterHunt.collectedProgramIds.size()):
			var id: String=str(bound_state.theaterHunt.collectedProgramIds[index])
			program_buttons[id]=_button(id,str(content.program.labels[id]),Vector2(-190+index*190,4),Vector2(150,48),func(): _append_program(id))
		_button("undo","撤回",Vector2(-205,92),Vector2(120,42),func():
			var order: Array=read_state.call().theaterHunt.programOrder.duplicate()
			if not order.is_empty(): order.pop_back()
			_set_program(order))
		_button("clear","清空",Vector2(-68,92),Vector2(120,42),func(): _set_program([]))
		_button("submit","提交",Vector2(68,92),Vector2(120,42),submit)
		_button("close","关闭",Vector2(205,92),Vector2(120,42),dismiss)

func set_feedback(message: String) -> void:
	if not is_instance_valid(feedback_label): return
	feedback_label.text=message; feedback_label.visible=compact_layout and not message.is_empty()

func owns_feedback_surface() -> bool:
	return active and is_visible_in_tree() and compact_layout and is_instance_valid(feedback_label) and feedback_label.visible and not feedback_label.text.is_empty()

func configure_layout(viewport: Vector2, compact: bool) -> void:
	compact_layout=compact
	display.add_theme_font_size_override("font_size",30 if kind=="code" else 22)
	for child in get_children():
		if child is Control and not child.has_meta("desktop_rect"): child.set_meta("desktop_rect",Rect2(child.position,child.size))
	if not compact:
		custom_minimum_size=Vector2(960,540);size=custom_minimum_size
		for child in get_children():
			if child is Control:
				var rect: Rect2=child.get_meta("desktop_rect");child.position=rect.position;child.size=rect.size
		feedback_label.hide()
		queue_redraw();return
	custom_minimum_size=Vector2.ZERO;size=viewport
	var portrait: bool=viewport.y>viewport.x
	var extent:=Vector2(minf(viewport.x-24,560 if portrait else 680),minf(viewport.y-24,460 if portrait else 430))
	compact_board=Rect2((viewport-extent)/2,extent)
	var start: Vector2=compact_board.position;var w: float=extent.x
	# Short landscape spends less space between controls, never scales hit targets.
	# Reserve the authored 48px feedback row plus an 8px gap after actions.
	var short_landscape:bool=not portrait and extent.y<366
	var action_y:float=minf(252 if kind=="code" else 250,extent.y-62-8-48) if short_landscape else (252 if kind=="code" else 250)
	var keypad_y:float=action_y-8-48-52 if short_landscape else 132
	var keypad_pitch:float=52 if short_landscape else 56
	var screen_y:float=(84 if kind=="program" else keypad_y-52) if short_landscape else (84 if kind=="program" else 76)
	_place(title_label,Rect2(start+Vector2(16,14),Vector2(w-32,64 if kind=="program" else 48)))
	_place(display,Rect2(start+Vector2(16,100 if portrait else screen_y),Vector2(w-32,64 if portrait else 48)))
	if kind=="code":
		var button_width: float=(w-64)/5
		for index in range(10):
			_place(controls[str(index)],Rect2(start+Vector2(16+(index%5)*(button_width+8),(192 if portrait else keypad_y)+floori(float(index)/5)*(56 if portrait else keypad_pitch)),Vector2(button_width,48)))
		var width: float=(w-48)/3
		for index in range(3): _place(controls[["backspace","submit","close"][index]],Rect2(start+Vector2(16+index*(width+8),344 if portrait else action_y),Vector2(width,48)))
	else:
		var card_width: float=(w-48)/3
		var index:=0
		for id in program_buttons:
			_place(program_buttons[id],Rect2(start+Vector2(16+index*(card_width+8),212 if portrait else (138 if short_landscape else 154)),Vector2(card_width,56)));index+=1
		var width: float=(w-56)/4
		for i in range(4): _place(controls[["undo","clear","submit","close"][i]],Rect2(start+Vector2(16+i*(width+8),334 if portrait else action_y),Vector2(width,48)))
	_place(feedback_label,Rect2(start+Vector2(16,extent.y-62),Vector2(w-32,48)))
	if not portrait and extent.y<340:
		if kind=="code":display.add_theme_font_size_override("font_size",24)
		# 568×320: explicit measured rows rather than letting the keypad push
		# the readout into the heading. All interactive targets remain 44px high.
		_place(title_label,Rect2(start+Vector2(16,12),Vector2(w-32,32 if kind=="code" else 52)))
		_place(display,Rect2(start+Vector2(16,48 if kind=="code" else 72),Vector2(w-32,36)))
		if kind=="code":
			var key_width:float=(w-64)/5
			for index in range(10):
				_place(controls[str(index)],Rect2(start+Vector2(16+(index%5)*(key_width+8),92+floori(float(index)/5)*48),Vector2(key_width,44)))
			var action_width:float=(w-48)/3
			for index in range(3):_place(controls[["backspace","submit","close"][index]],Rect2(start+Vector2(16+index*(action_width+8),192),Vector2(action_width,44)))
		else:
			var card_width:float=(w-48)/3
			var index:=0
			for id in program_buttons:
				_place(program_buttons[id],Rect2(start+Vector2(16+index*(card_width+8),116),Vector2(card_width,48)));index+=1
			var action_width:float=(w-56)/4
			for i in range(4):_place(controls[["undo","clear","submit","close"][i]],Rect2(start+Vector2(16+i*(action_width+8),176),Vector2(action_width,44)))
		_place(feedback_label,Rect2(start+Vector2(16,244),Vector2(w-32,44)))
	feedback_label.visible=not feedback_label.text.is_empty()
	queue_redraw()

func _place(control: Control, rect: Rect2) -> void:
	control.position=rect.position;control.size=rect.size

func _label(text: String, rect: Rect2, font_size: int, color: Color) -> Label:
	var label:=Label.new(); Typography.apply_body(label); label.text=text; label.position=rect.position; label.size=rect.size
	label.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER; label.vertical_alignment=VERTICAL_ALIGNMENT_CENTER
	label.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART; label.mouse_filter=Control.MOUSE_FILTER_IGNORE
	label.add_theme_font_size_override("font_size",font_size); label.add_theme_color_override("font_color",color)
	add_child(label); return label

func _button(id: String, text: String, point: Vector2, extent: Vector2, action: Callable) -> Button:
	var button:=Button.new(); button.name="Device_"+id; button.text=text; button.position=CENTER+point-extent/2; button.size=extent
	Typography.apply_body(button)
	button.add_theme_font_size_override("font_size",17)
	var primary:bool=id=="submit"
	var ink:=Color("18232b") if primary else Color("fff5df")
	for font_state in ["font_color","font_hover_color","font_focus_color","font_pressed_color","font_hover_pressed_color"]: button.add_theme_color_override(font_state,ink)
	button.add_theme_color_override("font_disabled_color",Color("b7c8d1"))
	for state:String in ["normal","hover","pressed","hover_pressed","disabled"]:
		var style:=StyleBoxFlat.new();PixelEdges.configure(style)
		var pressed:bool=state in ["pressed","hover_pressed"]
		style.bg_color=(Color("d5b77b") if state=="hover" else Color("bea16b")) if primary else (Color("374855") if state=="hover" else Color("263642"))
		if pressed:style.bg_color=Color("aa8d59") if primary else Color("1b2933")
		style.border_color=Color("745f3c") if primary else Color("536974")
		style.set_border_width_all(1)
		style.border_width_bottom=1 if pressed else 3
		# The existing hit rectangles stay exact; depth is painted inward.
		button.add_theme_stylebox_override(state,style)
	var focus:=StyleBoxFlat.new();PixelEdges.configure(focus);focus.bg_color=Color.TRANSPARENT
	focus.border_color=Color("fff2d8");focus.set_border_width_all(2)
	button.add_theme_stylebox_override("focus",focus)
	button.pressed.connect(func():
		if active: action.call())
	add_child(button); controls[id]=button; return button

func _digit(digit: String) -> void:
	if not active or kind!="code" or code.length()>=4: return
	code+=digit; refresh()

func backspace() -> void:
	if not active or kind!="code": return
	code=code.left(maxi(0,code.length()-1)); refresh()

func _append_program(id: String) -> void:
	if not active: return
	var order: Array=read_state.call().theaterHunt.programOrder.duplicate()
	if order.has(id) or order.size()>=3: return
	order.append(id); _set_program(order)

func _set_program(order: Array) -> void:
	if not active: return
	dispatch.call("c3_program_set",order); refresh()

func submit() -> void:
	if not active: return
	if kind=="code":
		if code.length()!=4: return
		var result: Variant=dispatch.call("c3_ticket_code",code)
		if result is Dictionary and result.get("close_theater_device",false): dismiss("release_required"); return
	else:
		dispatch.call("c3_program_submit",null)
	refresh()

func refresh() -> void:
	if not active: return
	var s: Dictionary=read_state.call()
	if not is_same(s,bound_state) or str(s.native.scene)!="theater_interior" or str(s.native.mode)!="light": dismiss("context_changed"); return
	if kind=="code":
		if s.theaterHunt.phase!="entry_ticket" or s.items.theaterTicketHalfB or s.items.temporaryTheaterTicket: dismiss("complete"); return
		var digits: Array=[]
		for index in range(4): digits.append(code[index] if index<code.length() else "·")
		display.text=" ".join(digits)
	else:
		if s.theaterHunt.phase!="program_search": dismiss("complete"); return
		var labels: Array=[]
		for id in s.theaterHunt.programOrder: labels.append(str(content.program.labels.get(id,id)))
		display.text="  →  ".join(labels) if not labels.is_empty() else "_  →  _  →  _"
		for id in program_buttons: program_buttons[id].modulate=Color("91abb5") if s.theaterHunt.programOrder.has(id) else Color.WHITE
	queue_redraw()

func _process(_delta: float) -> void: refresh()
func blocks_world_input() -> bool: return active and visible
func dismiss(reason: String="dismissed") -> void:
	if not active: return
	active=false; visible=false; code=""; bound_state={}; closed.emit(reason)
func _input(event: InputEvent) -> void:
	if not active or not event is InputEventKey or not event.pressed: return
	if event.keycode==KEY_ESCAPE: get_viewport().set_input_as_handled(); dismiss(); return
	if kind!="code": return
	if not (event.keycode>=KEY_0 and event.keycode<=KEY_9) and event.keycode not in [KEY_BACKSPACE,KEY_ENTER,KEY_KP_ENTER]: return
	get_viewport().set_input_as_handled()
	if event.keycode>=KEY_0 and event.keycode<=KEY_9: _digit(str(event.keycode-KEY_0))
	elif event.keycode==KEY_BACKSPACE: backspace()
	else: submit()
func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouse or event is InputEventScreenTouch or event is InputEventScreenDrag: accept_event()
func _draw() -> void:
	if compact_layout:draw_rect(Rect2(Vector2.ZERO,size),Color(0.02,0.04,0.06,.82))
	var extent:=Vector2(560,360) if kind=="code" else Vector2(620,390)
	var board:Rect2=compact_board if compact_layout else Rect2(CENTER-extent/2,extent)
	# Equipment, not stationery: thin folded metal case with an inset screen.
	var shell:=StyleBoxFlat.new();PixelEdges.configure(shell,true)
	shell.bg_color=Color("111b24");shell.border_color=Color("697a80");shell.set_border_width_all(1);shell.border_width_bottom=2
	draw_style_box(shell,board)
	for point:Vector2 in [board.position+Vector2(5,5),Vector2(board.end.x-7,board.position.y+5),Vector2(board.position.x+5,board.end.y-7),board.end-Vector2(7,7)]:
		draw_rect(Rect2(point,Vector2(2,2)),Color("8b8b79"))
	var screen:=Rect2(display.position,display.size)
	var recess:=StyleBoxFlat.new();PixelEdges.configure(recess)
	recess.bg_color=Color("07131d");recess.border_color=Color("03080d");recess.set_border_width_all(1)
	draw_style_box(recess,screen)
	draw_rect(Rect2(screen.position+Vector2(4,0),Vector2(screen.size.x-8,2)),Color("03080d"))
	draw_rect(Rect2(screen.position+Vector2(0,4),Vector2(2,screen.size.y-8)),Color("03080d"))
	draw_rect(Rect2(screen.end-Vector2(screen.size.x-4,1),Vector2(screen.size.x-8,1)),Color("415760"))
	if compact_layout and feedback_label.visible:
		var feedback_rect:=Rect2(feedback_label.position-Vector2(4,2),feedback_label.size+Vector2(8,4))
		draw_rect(feedback_rect,Color("172a34"))
		draw_rect(Rect2(feedback_rect.position,Vector2(2,feedback_rect.size.y)),Color("bea16b"))
func _exit_tree() -> void:
	active=false; bound_state={}; code=""
