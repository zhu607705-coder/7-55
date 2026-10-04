extends "res://tests/test_lake_fishing_view.gd"
## Input-mode fixtures, not physical-device or actual-render acceptance.
func key(code: Key,pressed: bool=true) -> void:
	var event:=InputEventKey.new()
	event.keycode=code;event.physical_keycode=code;event.pressed=pressed
	root.push_input(event,true);await frames()
func emulated_mouse(point: Vector2,pressed: bool) -> void:
	var event:=InputEventMouseButton.new()
	event.device=-1;event.position=point;event.global_position=point;event.button_index=MOUSE_BUTTON_LEFT;event.pressed=pressed
	root.push_input(event,true);await frames()
func run() -> void:
	root.get_node("State").developer_mode=true
	for dimensions: Vector2i in [Vector2i(390,844),Vector2i(430,860),Vector2i(1180,812),Vector2i(844,390)]:
		root.size=dimensions
		host=load("res://scripts/ui/minigame_host.gd").new();root.add_child(host);await frames()
		host.setup({"type":"rhythm","chartId":"locker_key","title":"锈蚀钥匙","control_scheme":"auto"})
		# An explicitly simulated desktop capability makes width-independent
		# policy deterministic under both headless and touchscreen CI hosts.
		host.fishing_touch_available=false;host.fishing_controls_enabled=false
		host.configure_activity_layout(Vector2(dimensions),dimensions.x<1100)
		host.set_process(false);host.begin();await frames()
		check(not host.fishing_controls_enabled,"mouse/keyboard desktop has no action row at any width")
		for button: Button in host.control_buttons.values():check(not button.visible,"desktop action pad remains hidden")
		check(host.fishing_controls_button.visible and host.fishing_controls_button.size.x>=44,"touch fallback is always discoverable and reachable")
		check(host.pause_button.visible and host.retry_button.visible and host.exit_button.visible,"essential actions remain visible")
		for button: Button in host._activity_toolbar():
			check(Rect2(Vector2.ZERO,Vector2(dimensions)).encloses(button.get_rect()) and button.size.x>=44 and button.size.y>=44,"essential and fallback targets fit the viewport")
		var desktop_field: Vector2=host.fishing_view.size
		await mouse(desktop_field*Vector2(.7,.5),true)
		check(host.model.controls.has("hook") and host.model.controls.has("right"),"desktop water casting works without visible action pads")
		for i in range(4):host._process(.1)
		await mouse(Vector2(-20,-20),false)
		check(host.model.cast_attempts==1 and host.model.controls.is_empty(),"desktop outside release produces one cast")
		check(not host.fishing_controls_enabled,"mouse input does not masquerade as touch")
		await key(KEY_A);check(host.model.controls.has("left"),"hidden pad does not disable keyboard steering");await key(KEY_A,false)
		var elapsed: float=host.model.elapsed
		await key(KEY_T);await key(KEY_T,false)
		check(host.fishing_controls_enabled and host.paused and host.model.controls.is_empty(),"explicit fallback pauses safely before relayout")
		check(host.model.elapsed==elapsed and host.fishing_view.size.y<desktop_field.y,"fallback uses real space without advancing game time")
		await key(KEY_ENTER);await key(KEY_ENTER,false)
		check(not host.paused,"Enter continues the same attempt")
		for button: Button in host.control_buttons.values():
			check(button.visible and button.size.y>=44,"touch action has a usable physical target")
			check(button.position==button.position.round() and button.size==button.size.floor(),"paint and hit bounds align to physical pixels")
			check(not button.get_rect().intersects(host.fishing_view.get_rect()),"touch action cannot cover the playable field")
			check(button.get_theme_stylebox("normal").border_width_left==2,"source-language button edge is crisp")
		host.restart();host.begin();await frames()
		await mouse(host.control_buttons.hook.get_global_rect().get_center(),true)
		check(host.control_buttons.hook.get_meta("fishing_held") and host.control_buttons.hook.get_theme_stylebox("normal").bg_color==Color("dcc783"),"held control has clear visual feedback")
		await key(KEY_T);await key(KEY_T,false)
		await mouse(Vector2(-20,-20),false)
		check(not host.fishing_controls_enabled and host.paused and host.model.cast_attempts==0,"mode change cancels held input without a scored release")
		check(not host.control_buttons.hook.get_meta("fishing_held"),"mode change restores the released button face")
		await touch(host.fishing_view.size*.5,true);await touch(host.fishing_view.size*.5,false)
		host._process(0)
		check(not host.fishing_controls_enabled,"actual touch respects an explicit hidden-controls choice")
		host.fishing_control_scheme="auto";host.fishing_touch_seen=false;host.fishing_touch_available=false
		host.restart();host.begin();await frames()
		var before_touch: Vector2=host.fishing_view.size
		var point: Vector2=before_touch*Vector2(.7,.5)
		await touch(point,true)
		for i in range(4):host._process(.1)
		check(host.fishing_view.size==before_touch,"automatic touch detection never moves the field during a held gesture")
		await touch(point,false);host._process(0);await frames()
		check(host.fishing_controls_enabled and host.model.cast_attempts==1,"touch enables controls after its one completed gesture, independent of width")
		check(host.fishing_view.labels.guide.get_minimum_size().y<=host.fishing_view.labels.guide.size.y,"contextual control hint fits its allocated text height")
		host.fishing_control_scheme="keyboard";host._apply_fishing_control_layout();host.restart();host.begin();await frames()
		host.fishing_control_scheme="auto";host.fishing_touch_seen=false;host.fishing_touch_available=true;host._apply_fishing_control_layout()
		check(host.fishing_controls_enabled,"touch-capable hardware can retain controls even on a large viewport")
		await key(KEY_R);await key(KEY_R,false)
		check(not host.running and not host.paused and host.model.cast_attempts==0,"keyboard Retry remains available")
		host.fishing_control_scheme="keyboard";host._apply_fishing_control_layout();await frames()
		var toggle_point: Vector2=host.fishing_controls_button.get_global_rect().get_center()
		await touch(toggle_point,true)
		check(host.fishing_controls_button.get_meta("fishing_held"),"touch toolbar press has visible held feedback before activation")
		var drag:=InputEventScreenDrag.new();drag.index=4;drag.position=Vector2(-20,-20)
		root.push_input(drag,true);await frames()
		check(not host.fishing_controls_button.get_meta("fishing_held"),"drag outside removes the toolbar pressed face")
		drag=drag.duplicate();drag.position=toggle_point;root.push_input(drag,true);await frames()
		await touch(toggle_point,false)
		check(not host.fishing_controls_button.get_meta("fishing_held"),"toolbar release clears its held visual state")
		check(host.fishing_controls_enabled,"real touch toolbar release enables the fallback once")
		await emulated_mouse(toggle_point,true);await emulated_mouse(toggle_point,false)
		check(host.fishing_controls_enabled,"paired emulated mouse cannot toggle the touch action a second time")
		var exits: Array=[];host.cancelled.connect(func():exits.append(true))
		await key(KEY_X);await key(KEY_X,false)
		check(exits.size()==1,"keyboard Exit emits once")
		host.queue_free();await frames()
	print("LAKE_FISHING_CONTROL_SCHEME: ",checks," checks; ",failures," failures")
	quit(1 if failures else 0)
