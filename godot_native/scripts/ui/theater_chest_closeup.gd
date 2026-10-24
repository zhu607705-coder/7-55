extends Control
## Controller transactions remain authoritative. The mounted mechanism
## submits controller intents; only its camera and object motion live here.
signal closed(reason: String)
const Typography=preload("res://scripts/ui/native_typography.gd")
const Chest=preload("res://scripts/objects/theater_chest_object.gd")
const Contents=preload("res://scripts/objects/theater_chest_contents.gd")
const Gestures=preload("res://scripts/ui/theater_chest_gestures.gd")
const PAPER=Color("e8e0c8")
class PartHotspot:
	extends Button
	var owner_panel: Control
	var part_id: String
	func _has_point(point: Vector2) -> bool:
		return is_instance_valid(owner_panel) and owner_panel.pick_part(position+point)==part_id

const NAMES={"fan":"折扇符号片","butterfly":"蝴蝶符号片","lamp":"灯光符号片","crank":"转柄"}
var read_state: Callable
var dispatch: Callable
var report_feedback: Callable
var bound_state: Dictionary={}
var controls: Dictionary={}
var chest: Node2D
var contents: Node2D
var title_label: Label
var feedback_label: Label
var active:=false
var transition_ready:=false
var compact_layout:=false
var observed_open:=false
var phase:="closed"
var lid_open:=0.0
var art_scale:=1.0
var art_origin:=Vector2.ZERO
var interior_focus:=0.0
var frame_rect:=Rect2()
var before_note_frame:=Rect2()
var before_note_focus:=0.0
var mechanism: Dictionary={}
var selected:=""
var motion: Tween
var focus_motion: Tween
var prop_motion: Tween
var busy:=false
var _reduced:=false
var _fresh_open:=false
var _begin_attempted:=false
var gestures=Gestures.new()

func setup(kind: String, reader: Callable, sink: Callable, _feedback_sink: Callable=Callable()) -> bool:
	if kind!="chest" or not reader.is_valid():return false
	read_state=reader;dispatch=sink;report_feedback=_feedback_sink;bound_state=reader.call()
	if not _context_valid(bound_state):return false
	active=true;visible=true
	_reduced=bool(bound_state.native.get("settings",{}).get("reduced_motion",false))
	observed_open=bool(bound_state.theaterHunt.get("propBoxOpened",false))
	_fresh_open=observed_open and bool(get_meta("scan_just_accepted",false))
	phase="opening" if _fresh_open else "inside" if observed_open else "closed"
	lid_open=1.0 if phase=="inside" else 0.0
	frame_rect=Chest.CLOSED_RECT if phase=="closed" else Chest.ART_BOUNDS
	mouse_filter=Control.MOUSE_FILTER_STOP;clip_contents=true
	chest=Chest.new();chest.name="TheaterChestObject";add_child(chest)
	contents=Contents.new();contents.name="ChestContents";chest.add_child(contents)
	chest.move_child(contents,maxi(0,chest.get_child_count()-2));contents.hide()
	title_label=_label("道具箱",20);title_label.hide()
	feedback_label=_label("",16)
	var feedback_back:=StyleBoxFlat.new();feedback_back.bg_color=Color(.09,.075,.06,.94)
	feedback_back.set_content_margin_all(8);feedback_label.add_theme_stylebox_override("normal",feedback_back)
	_hotspot("lid","查看箱盖",func():_say("箱盖还锁着。"))
	_hotspot("bottom","靠近查看箱底",_inspect_bottom)
	for piece: String in ["fan","butterfly","lamp","crank"]:
		_hotspot(piece,NAMES[piece],_select_piece.bind(piece))
	for index: int in range(3):
		_hotspot("slot%d"%index,"放入或取起符号片",_slot_pressed.bind(index))
	_hotspot("axle","安装转柄 · 转动轮盘",_axle_pressed)
	_hotspot("drawer","拉开夹层",_open_drawer)
	_hotspot("note","展开纸条",_inspect_note)
	_hotspot("brush","取出荧光粉刷",_take_brush)
	_hotspot("vent_clue","查看通风口示意图",_inspect_vent_clue)
	var back:=_hotspot("close","返回剧场",dismiss)
	back.text="‹  返回剧场"
	for key in ["normal","hover","pressed","hover_pressed"]:
		var style:=StyleBoxFlat.new();style.bg_color=Color("292523") if key=="normal" else Color("44332d")
		style.border_color=Color("70503b");style.set_border_width_all(1)
		back.add_theme_stylebox_override(key,style)
	gestures.bind(self);configure_layout(Vector2(960,540),false);_sync_art()
	return true

func _context_valid(s: Dictionary) -> bool:
	var n: Dictionary=s.get("native",{});var t: Dictionary=s.get("theaterHunt",{})
	return str(n.get("scene",""))=="theater_interior" and str(n.get("mode","light"))=="light" and str(s.get("runtimeMode",""))=="rpg" and (str(t.get("phase",""))=="prop_setup" or bool(t.get("propBoxOpened",false)))

func _mechanism_available() -> bool:
	var theater: Dictionary=bound_state.get("theaterHunt",{})
	return observed_open and bool(theater.get("active",false)) and bool(theater.get("admitted",false))

func _label(value: String, font_size: int) -> Label:
	var label:=Label.new();Typography.apply_body(label);label.text=value
	label.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;label.vertical_alignment=VERTICAL_ALIGNMENT_CENTER
	label.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;label.mouse_filter=Control.MOUSE_FILTER_IGNORE
	label.add_theme_font_size_override("font_size",font_size);label.add_theme_color_override("font_color",PAPER)
	add_child(label);return label

func _hotspot(id: String, hint: String, action: Callable) -> Button:
	var button: Button=Button.new() if id in ["lid","bottom","close"] else PartHotspot.new()
	if button is PartHotspot:button.owner_panel=self;button.part_id=id
	button.name="Chest_"+id;button.tooltip_text=hint
	Typography.apply_body(button);button.add_theme_font_size_override("font_size",16)
	button.add_theme_color_override("font_color",PAPER)
	button.mouse_default_cursor_shape=Control.CURSOR_POINTING_HAND;button.focus_mode=Control.FOCUS_ALL
	for key in ["normal","pressed","hover_pressed","disabled","hover"]:button.add_theme_stylebox_override(key,StyleBoxEmpty.new())
	var focus:=StyleBoxFlat.new();focus.bg_color=Color.TRANSPARENT;focus.border_color=Color("c79b62");focus.set_border_width_all(2)
	button.add_theme_stylebox_override("focus",focus)
	button.pressed.connect(func():
		if active and (id=="close" or transition_ready):action.call())
	button.mouse_entered.connect(func():
		if is_instance_valid(contents):contents.hovered=id)
	button.mouse_exited.connect(func():
		if is_instance_valid(contents) and contents.hovered==id:contents.hovered="")
	add_child(button);controls[id]=button;return button

func configure_layout(viewport: Vector2, compact: bool) -> void:
	gestures.cancel()
	compact_layout=compact;custom_minimum_size=Vector2.ZERO if compact else Vector2(960,540)
	size=viewport if compact else Vector2(960,540)
	if not is_instance_valid(chest):return
	title_label.position=Vector2(16,12);title_label.size=Vector2(size.x-32,32)
	feedback_label.position=Vector2(20,size.y-136);feedback_label.size=Vector2(size.x-40,68)
	_sync_art();queue_redraw()

func _project(rect: Rect2) -> Rect2:
	return Rect2(art_origin+rect.position*art_scale,rect.size*art_scale)

func get_bottom_rect() -> Rect2:return _project(Chest.BOTTOM_RECT)
func get_art_rect() -> Rect2:return _project(Chest.CLOSED_RECT if phase=="closed" else Chest.ART_BOUNDS)
func get_part_rect(id: String) -> Rect2:return _project(Contents.part_rect(id))

func _sync_art() -> void:
	if not is_instance_valid(chest):return
	var available:=Vector2(maxf(1,size.x-36),maxf(1,size.y-150))
	art_scale=minf(available.x/frame_rect.size.x,available.y/frame_rect.size.y)
	art_origin=Vector2(size.x*.5,54+available.y*.5)-frame_rect.get_center()*art_scale
	chest.position=art_origin;chest.scale=Vector2.ONE*art_scale
	chest.set_closed_inspection(not observed_open);chest.set_open_amount(lid_open)
	_layout_controls()

func _place(control: Control, rect: Rect2) -> void:
	control.position=rect.position;control.size=rect.size

func _part_polygon(id: String) -> PackedVector2Array:
	var projected:=PackedVector2Array()
	for point: Vector2 in contents.get_part_polygon(id):projected.append(art_origin+point*art_scale)
	return projected

func _part_bounds(id: String) -> Rect2:
	var points:=_part_polygon(id)
	if points.is_empty():return get_part_rect(id)
	var result:=Rect2(points[0],Vector2.ZERO)
	for point: Vector2 in points:result=result.expand(point)
	return result

func pick_part(point: Vector2) -> String:
	# Visible silhouettes win before expanded touch targets. Overlapping targets
	# can therefore stay generous without stealing the exposed face below them.
	var order: Array[String]=["brush","vent_clue","note","butterfly","fan","lamp","crank","axle","slot0","slot1","slot2","drawer"]
	if selected in order:order.erase(selected);order.push_front(selected)
	var nearest:="";var distance:=INF
	for id: String in order:
		var button: Control=controls[id]
		if not button.visible or button.disabled:continue
		if Geometry2D.is_point_in_polygon(point,_part_polygon(id)):return id
		var bounds:=Rect2(button.position,button.size)
		if bounds.has_point(point):
			var delta:=point.distance_squared_to(_part_bounds(id).get_center())
			if delta<distance:nearest=id;distance=delta
	return nearest

func _layout_controls() -> void:
	if controls.is_empty():return
	_place(controls.lid,get_art_rect());_place(controls.bottom,get_bottom_rect())
	_place(controls.close,Rect2(size.x*.5-82,size.y-56,164,44))
	var ready: bool=phase=="inside" and not mechanism.is_empty()
	var reading: bool=bool(mechanism.get("clue_open",false))
	controls.lid.visible=phase=="closed";controls.bottom.visible=phase=="inside" and not reading
	for id: String in controls:
		var control: Button=controls[id]
		if id not in ["lid","bottom","close"]:
			var rect:=_part_bounds(id)
			var target_size:=rect.size.max(Vector2.ONE*45)
			_place(control,Rect2(rect.get_center()-target_size*.5,target_size))
			control.visible=ready and (not reading or id=="note")
			if id in ["fan","butterfly","lamp","crank"]:control.visible=control.visible and id in mechanism.get("remaining",[])
			if id=="axle":control.visible=control.visible and (selected.is_empty() or selected=="crank")
			if id.begins_with("slot"):control.visible=control.visible and selected!="crank"
			if id=="note":control.visible=control.visible and mechanism.get("cleared",[]).size()==3
			if id in ["brush","vent_clue"]:control.visible=control.visible and bool(mechanism.get("drawer_open",false)) and (id!="brush" or not bool(mechanism.get("brush_taken",false)))
			if bool(mechanism.get("drawer_open",false)) and id not in ["note","brush","vent_clue"]:control.visible=false
			# Zoomed notes/compartments expose only controls actually in the view.
			control.visible=control.visible and Rect2(Vector2(0,48),Vector2(size.x,size.y-166)).encloses(Rect2(control.position,control.size))
		control.disabled=not active or (id!="close" and (not transition_ready or busy or gestures.dragging() or (focus_motion!=null and focus_motion.is_valid())))
	controls.note.tooltip_text="收起纸条" if reading else "展开纸条"
	contents.visible=observed_open and not mechanism.is_empty()

func set_transition_ready(value: bool) -> void:
	transition_ready=value
	if active and value:
		_begin_mechanism()
		if _fresh_open:_fresh_open=false;_animate_open()
	_layout_controls()

func _begin_mechanism() -> void:
	if _begin_attempted or not _mechanism_available() or not dispatch.is_valid():return
	_begin_attempted=true
	var result: Dictionary=dispatch.call("c3_chest_begin",{})
	if not result.get("accepted",false):return
	mechanism=result.get("mechanism",{});contents.drawer_amount=1.0 if mechanism.get("drawer_open",false) else 0.0;contents.set_state(mechanism,selected)
	_say("")

func _animate_open() -> void:
	if _reduced:_set_lid(1);_opened();return
	_stop_motion();phase="opening";_layout_controls()
	motion=create_tween()
	motion.tween_method(_set_lid,0.0,1.0,.85).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	motion.tween_callback(_opened)

func _set_lid(value: float) -> void:
	lid_open=value;chest.set_open_amount(value)

func _opened() -> void:
	if not active:return
	motion=null;lid_open=1.0;phase="inside";_sync_art()

func _animate_frame(destination: Rect2, focus_value: float) -> void:
	if focus_motion!=null and focus_motion.is_valid():focus_motion.kill()
	var original:=frame_rect;var old_focus:=interior_focus
	if _reduced:frame_rect=destination;interior_focus=focus_value;_sync_art();return
	focus_motion=create_tween()
	focus_motion.tween_method(func(value: float):
		frame_rect=Rect2(original.position.lerp(destination.position,value),original.size.lerp(destination.size,value))
		interior_focus=lerpf(old_focus,focus_value,value);_sync_art(),0.0,1.0,.38).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
	focus_motion.tween_callback(func():focus_motion=null;_layout_controls())

func _inspect_bottom() -> void:
	if phase!="inside" or busy or not _refresh_context():return
	selected="";contents.set_state(mechanism,selected);_say("")
	_animate_frame(Chest.ART_BOUNDS if interior_focus>.5 else Chest.BOTTOM_RECT.grow(34),0.0 if interior_focus>.5 else 1.0)

func _intent(action: String, payload: Dictionary={}) -> Dictionary:
	if busy or not _refresh_context() or mechanism.is_empty() or not dispatch.is_valid():return {}
	payload=payload.duplicate(true);payload.session=mechanism.session
	var result: Dictionary=dispatch.call("c3_chest_"+action,payload)
	if result.get("mechanism") is Dictionary:mechanism=result.mechanism
	if not str(result.get("message","")).is_empty():_say(str(result.message))
	return result

func _select_piece(piece: String) -> void:
	if busy or not _refresh_context():return
	if piece!="crank" and piece not in mechanism.get("cleared",[]):
		var previous:=mechanism.duplicate(true)
		var result:=_intent("clear",{"piece":piece})
		if not result.get("accepted",false):return
		selected="";contents.placement_piece=piece
		contents.placement_to=preload("res://scripts/objects/theater_chest_contents_3d.gd").STAGING[piece]
		contents.set_state(previous,"")
		_animate_prop("placement_amount",0.0,1.0,.38,func():
			contents.placement_piece="";contents.set_state(mechanism,selected))
		return
	selected="" if selected==piece else piece
	contents.set_state(mechanism,selected);_layout_controls()
	_say("" if selected.is_empty() else "把转柄装入中轴。" if piece=="crank" else "对照边缘缺口，放进合适的凹槽。")

func _slot_pressed(index: int) -> void:
	if selected.is_empty():
		var piece: String=str(mechanism.get("slots",["","",""])[index])
		if not piece.is_empty():_select_piece(piece)
		else:_say("这里能嵌入一枚符号片。")
		return
	if selected=="crank":return
	_place_piece(index)

func _place_piece(destination: Variant) -> void:
	var piece:=selected;var previous: Dictionary=mechanism.duplicate(true)
	var source_id:=piece
	var previous_index: int=previous.get("slots",[]).find(piece)
	if previous_index>=0:source_id="slot%d"%previous_index
	var result:=_intent("place",{"piece":piece,"slot":destination})
	if not result.get("accepted",false):return
	selected="";_say("")
	contents.placement_piece=piece
	contents.placement_from=Contents.part_rect(source_id).get_center()
	contents.placement_to=Contents.part_rect("axle" if piece=="crank" else "slot%d"%int(destination)).get_center()
	contents.set_state(previous,piece)
	_animate_prop("placement_amount",0.0,1.0,.3,func():
		contents.placement_piece="";contents.set_state(mechanism,selected))

func _axle_pressed() -> void:
	if selected=="crank":_place_piece("axle");return
	var previous: Dictionary=mechanism.duplicate(true)
	var result:=_intent("turn",{"direction":1})
	if not result.get("accepted",false):return
	_say("");contents.set_state(previous,"")
	_animate_prop("turn_angle",0.0,TAU/3.0,.48,func():
		contents.turn_angle=0.0;contents.set_state(mechanism,selected))

func _inspect_note() -> void:
	var result:=_intent("inspect")
	if not result.get("accepted",false):return
	selected="";contents.set_state(mechanism,selected)
	var reading: bool=mechanism.get("clue_open",false)
	if reading:
		before_note_frame=frame_rect;before_note_focus=interior_focus
		_animate_frame(Contents.part_rect("note").grow(34),1.0)
		_say("缺口吻合后嵌入，顺时针转动，让连杆收回锁舌。点击纸条收起。")
	else:
		_animate_frame(before_note_frame if before_note_frame.has_area() else Chest.ART_BOUNDS,before_note_focus)
		_say("")
	_animate_prop("clue_flip",0.0 if reading else 1.0,1.0 if reading else 0.0,.32,func():contents.set_state(mechanism,selected))

func _open_drawer() -> void:
	var result:=_intent("open")
	if not result.get("accepted",false):return
	selected="";contents.set_state(mechanism,selected)
	_animate_prop("drawer_amount",contents.drawer_amount,1.0,.55,func():
		contents.set_state(mechanism,selected)
		_animate_frame(Contents.DRAWER_RECT.grow(40),1.0))

func _take_brush() -> void:
	var previous:=mechanism.duplicate(true)
	var result:=_intent("take")
	if not result.get("accepted",false):return
	contents.set_state(previous,"")
	_animate_prop("pickup_amount",0.0,1.0,.4,func():
		contents.pickup_amount=0.0;contents.set_state(mechanism,"")
		_animate_frame(Contents.DRAWER_RECT.grow(40),1.0))

func _inspect_vent_clue() -> void:
	_intent("clue")

func _animate_prop(property: String, from: float, to: float, duration: float, finished: Callable) -> void:
	if prop_motion!=null and prop_motion.is_valid():prop_motion.kill()
	contents.set(property,from)
	if _reduced:contents.set(property,to);finished.call();_layout_controls();return
	busy=true;_layout_controls();prop_motion=create_tween()
	prop_motion.tween_property(contents,property,to,duration).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
	prop_motion.tween_callback(func():prop_motion=null;busy=false;finished.call();_layout_controls())

func set_feedback(message: String) -> void:
	if not is_instance_valid(feedback_label):return
	feedback_label.text=message;feedback_label.visible=not message.is_empty()

func _say(message: String) -> void:
	if report_feedback.is_valid():report_feedback.call(message)
	else:set_feedback(message)

func owns_feedback_surface() -> bool:
	return active and is_visible_in_tree() and is_instance_valid(feedback_label) and feedback_label.visible and not feedback_label.text.is_empty()

func _refresh_context() -> bool:
	if not active or not read_state.is_valid():return false
	var current: Dictionary=read_state.call()
	if not is_same(current,bound_state) or not _context_valid(current):dismiss("context_changed");return false
	return true

func refresh() -> void:
	if not _refresh_context():return
	var opened: bool=bool(bound_state.theaterHunt.get("propBoxOpened",false))
	if opened!=observed_open:dismiss("context_changed");return
	if not mechanism.is_empty() and not _mechanism_available():
		_cancel_mechanism();_stop_motion();selected="";_sync_art()
	var reduced: bool=bool(bound_state.native.get("settings",{}).get("reduced_motion",false))
	if reduced and not _reduced:
		if motion!=null and motion.is_valid():motion.custom_step(10)
		if focus_motion!=null and focus_motion.is_valid():focus_motion.custom_step(10)
		if prop_motion!=null and prop_motion.is_valid():prop_motion.custom_step(10)
	_reduced=reduced

func _process(_delta: float) -> void:
	if active:refresh()
func blocks_world_input() -> bool:return active and visible

func _cancel_mechanism() -> void:
	if mechanism.is_empty():return
	var state:=get_node_or_null("/root/State")
	if state!=null and state.has_method("cancel_progressive_activity"):
		state.cancel_progressive_activity("c3_chest_cancel",{"session":mechanism.session})
	elif dispatch.is_valid():dispatch.call("c3_chest_cancel",{"session":mechanism.session})
	mechanism={}

func _stop_motion() -> void:
	gestures.cancel()
	for animation: Tween in [motion,focus_motion,prop_motion]:
		if animation!=null and animation.is_valid():animation.kill()
	motion=null;focus_motion=null;prop_motion=null;busy=false

func dismiss(reason: String="dismissed") -> void:
	if not active:return
	_cancel_mechanism();_stop_motion();active=false;transition_ready=false;_layout_controls();closed.emit(reason)

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouse or event is InputEventScreenTouch or event is InputEventScreenDrag:accept_event()

func _input(event: InputEvent) -> void:gestures.input(event)

func _notification(what: int) -> void:
	if what in [NOTIFICATION_WM_WINDOW_FOCUS_OUT,NOTIFICATION_APPLICATION_FOCUS_OUT]:gestures.cancel()
	for animation: Tween in [motion,focus_motion,prop_motion]:
		if animation==null or not animation.is_valid():continue
		if what==NOTIFICATION_WM_WINDOW_FOCUS_OUT:animation.pause()
		elif what==NOTIFICATION_WM_WINDOW_FOCUS_IN:animation.play()

func _draw() -> void:draw_rect(Rect2(Vector2.ZERO,size),Color(.075,.065,.06,.97))
func _exit_tree() -> void:
	_cancel_mechanism();_stop_motion();active=false;bound_state={}
