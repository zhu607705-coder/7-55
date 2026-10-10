extends Control
## Original mixer transaction with an independently layered physical surface.
## Main retains the original blocking modal owner and responsive coordinates.
## Only callbacks request actions; neither this panel nor its session mutates s.
signal closed(reason: String)
const Session = preload("res://scripts/presentation/c3_mixer_session.gd")
const MixerMotion = preload("res://scripts/presentation/c3_mixer_motion.gd")
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
var surface: Control
var art_board := Rect2(120,20,720,480)
var status_strip: Panel
var finishing:=false
var finish_state: Dictionary={}
var finish_attempt:=0
var finish_elapsed_ms:=0.0
var finish_message:=""
var finish_reduced:=false
var submitting:=false
const SETTLE_MS:=100.0
const RESULT_MS:=340.0
const RETURN_MS:=220.0

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
	finishing=false;submitting=false;finish_state={};modulate.a=1.0
	surface.cancel_presentation();_show_feedback("");prompt_label.text="选择饮料，杯子推压杆接取"
	visible = true
	refresh()
	return true

func _build() -> void:
	surface=preload("res://scripts/ui/c3_mixer_surface.gd").new();surface.name="PhysicalMixerSurface";add_child(surface)
	status_strip=Panel.new();status_strip.mouse_filter=Control.MOUSE_FILTER_IGNORE
	var status_style:=StyleBoxFlat.new();status_style.bg_color=Color("14221f")
	status_style.border_color=Color("9b8354");status_style.border_width_top=1
	status_strip.add_theme_stylebox_override("panel",status_style);add_child(status_strip)
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
		labels.append(_add_label("", Rect2(CENTER+Vector2(x-65, 147), Vector2(150, 26)), 14, Color.WHITE))
	configure_layout(Vector2(960,540),false)

func set_feedback(message: String) -> void:
	if finishing or submitting: return
	_show_feedback(message)

func _show_feedback(message: String) -> void:
	if not is_instance_valid(feedback_label): return
	feedback_label.text=message
	feedback_label.visible=not message.is_empty()
	prompt_label.visible=message.is_empty()

func configure_layout(viewport: Vector2, compact: bool) -> void:
	compact_layout=compact
	custom_minimum_size=Vector2.ZERO if compact else Vector2(960,540)
	size=viewport if compact else Vector2(960,540)
	compact_portrait=compact and viewport.y>viewport.x
	var extent:=Vector2(minf(viewport.x-24,560),minf(viewport.y-24,740)) if compact_portrait else Vector2(minf(viewport.x-24,720),minf(viewport.y-56,460)) if compact else Vector2(720,480)
	art_board=Rect2((size-extent)/2,extent);compact_board=art_board
	var start: Vector2=art_board.position;var w: float=extent.x;var h: float=extent.y
	_place(title_label,Rect2(start+Vector2(14,10),Vector2(w-94,32)),20)
	_place(exit_button,Rect2(start+Vector2(w-74,8),Vector2(62,44)),16)
	_place(exit_label,Rect2(exit_button.position,exit_button.size),16);exit_label.text="退出"
	# One physical machine: colored push controls above a fixed central outlet.
	# The whole assembly shrinks uniformly; portrait keeps a comfortably large cup.
	var machine_height: float = minf(h-164,480)
	var cup_height: float = minf(machine_height*(150.0/356.0),(w-24)*(150.0/286.0))
	var k: float = cup_height/150.0
	var cup: Vector2=start+Vector2(w/2,h-72-16*k)
	var ingredient_height: float=66*k
	var button_spacing: float=maxf(86*k,90)
	var contacts: Array[Vector2]=[]
	for index in range(3):
		var foot: Vector2=cup+Vector2((index-1)*button_spacing,-264*k)
		contacts.append(foot)
		var sprite_width: float=ingredient_height*(466.0/470.0)
		var target_width: float=maxf(44,sprite_width+6)
		var target_height: float=maxf(44,ingredient_height+4)
		var rect:=Rect2(foot-Vector2(target_width/2,ingredient_height+2),Vector2(target_width,target_height))
		_place(slots[index],rect,16)
		_place(labels[index],Rect2(Vector2(foot.x-42,foot.y+2),Vector2(84,20)),14)
		labels[index].autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	_place(glass_label,Rect2(cup+Vector2(-90,-165)*k,Vector2(180,24)),14)
	# Keep bottle names on their own row. One quiet footer owns either the
	# operation hint or the latest feedback; the recorded clue stays at the top.
	var status_rect:=Rect2(start+Vector2(16,h-54),Vector2(w-32,46))
	_place(status_strip,Rect2(start+Vector2(1,h-62),Vector2(w-2,61)))
	_place(prompt_label,status_rect,14)
	prompt_label.text="调配中…" if finishing else "选择饮料，杯子推压杆接取"
	prompt_label.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	_place(shelf_label,Rect2(start+Vector2(16,52),Vector2(w-32,40)),14)
	shelf_label.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	_place(feedback_label,status_rect,14)
	feedback_label.visible=not feedback_label.text.is_empty()
	prompt_label.visible=feedback_label.text.is_empty()
	glass_label.hide()
	surface.size=size;surface.configure(art_board,cup,cup_height,contacts,ingredient_height)
	queue_redraw()

func _place(control: Control, rect: Rect2, font_size: int=0) -> void:
	control.position=rect.position;control.size=rect.size
	if font_size>0: control.add_theme_font_size_override("font_size",font_size)

func _button(rect: Rect2, accessibility: String) -> Button:
	var button := Button.new()
	button.position = rect.position
	button.size = rect.size
	button.tooltip_text = accessibility
	button.add_theme_stylebox_override("normal", StyleBoxEmpty.new())
	button.add_theme_stylebox_override("hover", StyleBoxEmpty.new())
	button.add_theme_stylebox_override("pressed", StyleBoxEmpty.new())
	button.add_theme_stylebox_override("disabled", StyleBoxEmpty.new())
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
	label.add_theme_color_override("font_shadow_color",Color("121b19"))
	label.add_theme_constant_override("shadow_offset_x",1)
	label.add_theme_constant_override("shadow_offset_y",2)
	label.add_theme_constant_override("outline_size",2)
	label.add_theme_color_override("font_outline_color",Color("15211f"))
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER if centered else HORIZONTAL_ALIGNMENT_LEFT
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(label)
	return label

func refresh() -> void:
	if close_emitted or not read_state.is_valid(): return
	if submitting: return
	if finishing:
		_validate_finish()
		return
	model = session.snapshot(read_state.call())
	if model.is_empty():
		_finish_close()
		return
	for index in range(slots.size()):
		var slot: Dictionary = model.slots[index]
		# Missing ingredients remain visible and clickable for source feedback.
		slots[index].disabled = false
		slots[index].tooltip_text = "推杯接取"+str(Session.NAMES[slot.id]) if slot.owned else slot.label
		labels[index].text = str(Session.NAMES[slot.id])
		labels[index].add_theme_color_override("font_color", Color("f4fbff") if slot.owned else Color("7f8d92"))
	surface.synchronize(model,read_state.call())
	shelf_label.text = "货架线索：黑色 → 蓝色 → 白色" if model.shelfRead else "货架线索尚未查看"
	shelf_label.add_theme_color_override("font_color", Color("91e4ba") if model.shelfRead else Color("e3b878"))
	queue_redraw()

func _pour(index: int) -> void:
	if not blocks_world_input() or finishing or submitting: return
	refresh()
	if model.is_empty() or index < 0 or index >= model.slots.size(): return
	var slot: Dictionary = model.slots[index]
	if not slot.owned:
		surface.reject(str(slot.id),bool(read_state.call().get("native",{}).get("settings",{}).get("reduced_motion",false)))
		if feedback.is_valid(): feedback.call(session.missing_feedback())
		return
	var before: Dictionary=read_state.call().duplicate(true)
	var result: Dictionary={}
	submitting=true
	if dispatch.is_valid():
		var response: Variant=dispatch.call(str(slot.action), null)
		if response is Dictionary: result=response
	submitting=false
	if close_emitted or not is_instance_valid(surface): return
	var current: Dictionary=read_state.call()
	# Context replacement during dispatch must retire this presentation, not
	# animate an old result over a loaded save or another scene.
	if not is_same(current,session.bound_state) or str(current.get("native",{}).get("scene",""))!="canteen_interior":
		refresh();return
	surface.accept(str(slot.action),before,current,result)
	var completed: bool=int(current.get("canteenHunt",{}).get("drinkMixAttemptCount",0))==int(before.get("canteenHunt",{}).get("drinkMixAttemptCount",0))+1
	if completed:
		_begin_finish(current,result)
	else:
		refresh()

func _begin_finish(current: Dictionary,result: Dictionary) -> void:
	# Source session closes now; the retained surface is an optional visual tail.
	# Reward, consumption, sequence reset and save have already committed.
	finish_state=current;finish_attempt=int(current.canteenHunt.drinkMixAttemptCount)
	finish_reduced=bool(current.get("native",{}).get("settings",{}).get("reduced_motion",false))
	finish_message=str(result.get("message",""))
	finishing=true;finish_elapsed_ms=0
	session.close("attempt_complete")
	for index in range(slots.size()):
		slots[index].disabled=true
		model.slots[index].owned=bool(current.items.get(str(model.slots[index].id),false))
		labels[index].add_theme_color_override("font_color",Color("7f8d92"))
	surface.source_slots=model.slots.duplicate(true)
	_show_feedback("");prompt_label.text="调配中…"

func _validate_finish() -> bool:
	var current: Dictionary=read_state.call()
	if not is_same(current,finish_state) or str(current.get("native",{}).get("scene",""))!="canteen_interior" or int(current.get("canteenHunt",{}).get("drinkMixAttemptCount",0))!=finish_attempt:
		session.close("context_changed");_finish_close();return false
	return true

func dismiss() -> void:
	if not session.active and not finishing: return
	session.close()
	model = {}
	_finish_close()

func _finish_close() -> void:
	visible = false
	if close_emitted: return
	close_emitted = true
	finishing=false;finish_state={}
	if is_instance_valid(surface): surface.cancel_presentation()
	closed.emit(session.close_reason)

func blocks_world_input() -> bool:
	return visible and (session.active or finishing)

func _process(delta: float) -> void:
	if finishing:
		if not _validate_finish() or surface.is_pouring(): return
		finish_elapsed_ms+=maxf(delta,0)*1000.0*MixerMotion.PLAYBACK_RATE
		var settle: float=0.0 if finish_reduced else SETTLE_MS
		var hold: float=160.0 if finish_reduced else RESULT_MS
		var fade: float=100.0 if finish_reduced else RETURN_MS
		if finish_elapsed_ms>=settle:
			_show_feedback(finish_message)
		modulate.a=1.0-smoothstep(settle+hold,settle+hold+fade,finish_elapsed_ms)
		if finish_elapsed_ms>=settle+hold+fade: _finish_close()
	elif session.active:
		refresh()

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
	draw_rect(Rect2(Vector2.ZERO,size),Color(0.02,0.04,0.06,.90))
	# Surface child owns all physical imagery; this owner only draws the border.
	draw_rect(art_board,Color("e0b858"),false,2)

func _frame(rect: Rect2, fill: Color, stroke: Color, width: float) -> void:
	draw_rect(rect, fill)
	draw_rect(rect, stroke, false, width)

func _source_color(hex: int, alpha: float = 1.0) -> Color:
	return Color(float((hex>>16)&255)/255, float((hex>>8)&255)/255, float(hex&255)/255, alpha)

func _exit_tree() -> void:
	if session.active or finishing: session.close("teardown")
	finishing=false;finish_state={}
