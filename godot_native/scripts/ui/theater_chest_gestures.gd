extends RefCounted
## Pointer poses are temporary. Only release submits the existing controller
## intent; cancelling never clears a piece, turns the cam or opens the drawer.
const Mechanism=preload("res://scripts/games/theater_chest_mechanism.gd")
const Contents=preload("res://scripts/objects/theater_chest_contents.gd")
const TURN:=TAU/3.0
var panel: Control
var capture: Dictionary={}

func bind(owner_panel: Control) -> void:panel=owner_panel
func dragging() -> bool:return not capture.is_empty() and bool(capture.get("moved",false))

func input(event: InputEvent) -> void:
	if not is_instance_valid(panel) or not panel.active or not panel.is_visible_in_tree():return
	if event is InputEventKey and event.pressed and event.keycode==KEY_ESCAPE and not capture.is_empty():
		cancel();panel.get_viewport().set_input_as_handled();return
	var pointer: int=-1
	var point:=Vector2.ZERO
	var press:=false;var release:=false;var motion:=false
	if event is InputEventScreenTouch:
		if event.canceled and not capture.is_empty() and int(capture.pointer)==event.index:
			cancel();panel.get_viewport().set_input_as_handled();return
		pointer=event.index;point=event.position;press=event.pressed;release=not press
	elif event is InputEventScreenDrag:
		pointer=event.index;point=event.position;motion=true
	elif event is InputEventMouseButton and event.button_index==MOUSE_BUTTON_LEFT:
		if event.device==InputEvent.DEVICE_ID_EMULATION:
			# Godot dispatches the emulated mouse event before the raw touch.
			# Reserve just these physical parts so a tap is never executed twice.
			var local: Vector2=panel.get_global_transform_with_canvas().affine_inverse()*event.position
			if not capture.is_empty() or panel.pick_part(local) in ["fan","butterfly","lamp","crank","axle","drawer"]:
				panel.get_viewport().set_input_as_handled()
			return
		point=event.position;press=event.pressed;release=not press
	elif event is InputEventMouseMotion:
		if event.device==InputEvent.DEVICE_ID_EMULATION:return
		point=event.position;motion=true
	else:return
	point=panel.get_global_transform_with_canvas().affine_inverse()*point
	if not capture.is_empty():
		if pointer!=int(capture.pointer):return
		panel.get_viewport().set_input_as_handled()
		if not panel._refresh_context():cancel();return
		if motion:_move(point)
		elif release:_release(point)
		return
	if not press or panel.busy or not panel.transition_ready or panel.phase!="inside" or panel.mechanism.is_empty():return
	if panel.focus_motion!=null and panel.focus_motion.is_valid():return
	if bool(panel.mechanism.get("clue_open",false)):return
	var id: String=panel.pick_part(point)
	if id not in ["fan","butterfly","lamp","crank","axle","drawer"]:return
	if not panel._refresh_context():return
	panel.controls[id].grab_focus()
	var center: Vector2=panel.art_origin+Contents.ROTOR_CENTER*panel.art_scale
	capture={"id":id,"pointer":pointer,"start":point,"current":point,"moved":false,"angle":(point-center).angle(),"angle_ready":point.distance_to(center)>8,"turn":0.0,"session":panel.mechanism.session.duplicate(true)}
	panel.get_viewport().set_input_as_handled()

func _can_lift(piece: String) -> bool:
	if piece=="crank" or piece in panel.mechanism.get("cleared",[]):return true
	var cleared: Array=panel.mechanism.get("cleared",[])
	return cleared.size()<3 and piece==Mechanism.CLEAR_ORDER[cleared.size()]

func _can_turn() -> bool:
	return bool(panel.mechanism.get("crank_installed",false)) and panel.mechanism.get("slots",[])==Mechanism.ASSEMBLY and not bool(panel.mechanism.get("latch_released",false))

func _move(point: Vector2) -> void:
	if capture.is_empty():return
	capture.current=point
	if not capture.moved and point.distance_to(capture.start)<7:return
	if not capture.moved:
		capture.moved=true;panel.selected="";panel.contents.set_state(panel.mechanism,"");panel._say("")
	var id: String=capture.id
	var delta: Vector2=(point-capture.start)/panel.art_scale
	if id in ["fan","butterfly","lamp","crank"]:
		var free:=_can_lift(id)
		panel.contents.preview_held(id,delta if free else delta.limit_length(8),48.0 if free else 0.0)
	elif id=="axle":
		var center: Vector2=panel.art_origin+Contents.ROTOR_CENTER*panel.art_scale
		if point.distance_to(center)>8:
			var angle: float=(point-center).angle()
			if capture.angle_ready:capture.turn+=angle_difference(float(capture.angle),angle)
			capture.angle=angle;capture.angle_ready=true
		panel.contents.turn_angle=clampf(float(capture.turn),-0.045,TURN) if _can_turn() else clampf(float(capture.turn),-0.035,0.035)
	elif id=="drawer":
		var limit:=1.0 if bool(panel.mechanism.get("latch_released",false)) else 0.035
		panel.contents.drawer_amount=clampf(delta.y/Contents.DRAWER_RECT.size.y,0,limit)
	panel._layout_controls()

func _drop_target(point: Vector2, piece: String) -> Variant:
	var ids: Array=["axle"] if piece=="crank" else ["slot0","slot1","slot2"]
	var best:="";var distance:=INF
	for id: String in ids:
		var bounds: Rect2=panel._part_bounds(id)
		var target:=Rect2(bounds.get_center()-bounds.size.max(Vector2(45,45))*.5,bounds.size.max(Vector2(45,45)))
		if not target.has_point(point):continue
		var next: float=point.distance_squared_to(bounds.get_center())
		if next<distance:distance=next;best=id
	if best.is_empty():return null
	return "axle" if best=="axle" else best.trim_prefix("slot").to_int()

func _release(point: Vector2) -> void:
	if capture.is_empty():return
	var previous: Dictionary=capture.duplicate(true)
	if not Rect2(Vector2.ZERO,panel.size).has_point(point) or previous.session!=panel.mechanism.get("session",{}):cancel();return
	if not previous.moved:
		capture={};panel._layout_controls()
		if panel.pick_part(point)==previous.id:panel.controls[previous.id].pressed.emit()
		return
	_move(point)
	var id: String=previous.id
	var turn: float=capture.turn
	capture={}
	if id in ["fan","butterfly","lamp","crank"]:
		var anchor: Vector2=panel.contents.part_anchor(id)
		var lift: float=panel.contents.held_lift
		var allowed:=true
		if id!="crank" and id not in panel.mechanism.get("cleared",[]):
			allowed=bool(panel._intent("clear",{"piece":id}).get("accepted",false))
		var destination: Variant=_drop_target(point,id)
		if allowed and destination!=null:panel._intent("place",{"piece":id,"slot":destination})
		_settle_piece(id,anchor,lift)
	elif id=="axle":
		var visual: float=panel.contents.turn_angle
		if turn>=TURN-0.025 or not _can_turn() or turn<-.1:
			var result: Dictionary=panel._intent("turn",{"direction":1 if turn>=0 else -1})
			if result.get("accepted",false):visual-=TURN
		panel.contents.set_state(panel.mechanism,"");panel.contents.turn_angle=visual
		panel._animate_prop("turn_angle",visual,0.0,.2,func():panel.contents.set_state(panel.mechanism,"") )
	elif id=="drawer":
		var amount: float=panel.contents.drawer_amount
		var accepted:=false
		if amount>=.7 or not bool(panel.mechanism.get("latch_released",false)):
			accepted=bool(panel._intent("open").get("accepted",false))
		panel.contents.set_state(panel.mechanism,"")
		panel._animate_prop("drawer_amount",amount,1.0 if accepted else 0.0,.24,func():
			panel.contents.set_state(panel.mechanism,"")
			if accepted:panel._animate_frame(Contents.DRAWER_RECT.grow(40),1.0))
	panel._layout_controls()

func _settle_piece(id: String, anchor: Vector2, lift: float) -> void:
	panel.contents.preview_held("",Vector2.ZERO,0);panel.contents.set_state(panel.mechanism,"")
	var base: Vector2=panel.contents.part_anchor(id)
	if panel._reduced:panel._layout_controls();return
	panel.contents.preview_held(id,anchor-base,lift);panel.busy=true
	panel.prop_motion=panel.create_tween();panel.prop_motion.set_parallel(true)
	panel.prop_motion.tween_property(panel.contents,"held_offset",Vector2.ZERO,.22).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	panel.prop_motion.tween_property(panel.contents,"held_lift",0.0,.22).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	panel.prop_motion.chain().tween_callback(func():
		panel.contents.preview_held("",Vector2.ZERO,0);panel.busy=false;panel.prop_motion=null;panel._layout_controls())

func cancel() -> void:
	if capture.is_empty():return
	capture={}
	if not is_instance_valid(panel) or not is_instance_valid(panel.contents):return
	panel.contents.preview_held("",Vector2.ZERO,0)
	panel.contents.turn_angle=0;panel.contents.drawer_amount=1.0 if panel.mechanism.get("drawer_open",false) else 0.0
	panel.contents.set_state(panel.mechanism,panel.selected);panel._layout_controls()
