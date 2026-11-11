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
func assert_direct_water_layout(dimensions: Vector2i) -> void:
	for button: Button in host.control_buttons.values():check(not button.visible,"neither input scheme exposes simulated action pads")
	check(not is_instance_valid(host.fishing_controls_button) or not host.fishing_controls_button.visible,"removed touch toggle remains absent")
	var can_pause: bool = host.running and host.model.phase == "running" and not host.sent
	check(host.pause_button.visible == can_pause and not host.retry_button.visible and not host.exit_button.visible,"Pause is the only live navigation action once the fishing clock has started")
	if host.pause_button.visible:
		var pause_rect: Rect2 = host.pause_button.get_rect()
		check(Rect2(dimensions.x * .5, 0, dimensions.x * .5, 64).encloses(pause_rect),"Pause stays in the top right: "+str(pause_rect)+" in "+str(dimensions))
		check(pause_rect.size.x >= 44 and pause_rect.size.y >= 44, "Pause keeps its physical touch target")
	check_uncovered_bottom(dimensions)
func run() -> void:
	root.get_node("State").developer_mode=true
	for dimensions: Vector2i in [Vector2i(390,844),Vector2i(430,860),Vector2i(1180,812),Vector2i(844,390)]:
		root.size=dimensions
		host=load("res://scripts/ui/minigame_host.gd").new();root.add_child(host);await frames()
		host.setup({"type":"rhythm","chartId":"locker_key","title":"锈蚀钥匙","control_scheme":"auto"})
		# Explicit capability fixture keeps scheme policy width-independent.
		host.fishing_touch_available=false;host.fishing_controls_enabled=false
		host.configure_activity_layout(Vector2(dimensions),dimensions.x<1100)
		host.set_process(false);host.begin();await frames()
		check(not host.fishing_controls_enabled,"mouse/keyboard desktop retains its scheme at every width")
		assert_direct_water_layout(dimensions)
		var keyboard_hint: String = host.fishing_view.control_instructions()
		check("A / D" in keyboard_hint and "空格" in keyboard_hint and "拖动" in keyboard_hint,"ready hint teaches keyboard and direct dragging")
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
		check(not host.fishing_controls_enabled and not host.paused and host.model.controls.is_empty(),"retired T toggle cannot change scheme or playback")
		check(host.model.elapsed==elapsed and host.fishing_view.size==desktop_field,"retired toggle has no clock or layout side effect")
		await key(KEY_ESCAPE);await key(KEY_ESCAPE,false)
		check(host.paused and host.model.controls.is_empty(),"Pause still clears held controls")
		var pause_overlay = host.shared_pause_overlay
		check(pause_overlay.is_open() and pause_overlay.resume_button.is_visible_in_tree(),"shared pause presents Continue")
		var pause_actions: Array[String] = []
		for button: Button in pause_overlay.action_buttons:
			if button.is_visible_in_tree(): pause_actions.append(button.text)
		check(host.retry_button.text in pause_actions and host.exit_button.text in pause_actions,"shared pause presents Retry and Exit")
		check(not host.start_button.visible and not host.retry_button.visible and not host.exit_button.visible,"pause actions are not duplicated below the shared surface")
		check_uncovered_bottom(dimensions)
		await key(KEY_ENTER);await key(KEY_ENTER,false)
		check(not host.paused,"Enter continues the same attempt")
		host.restart();host.begin();await frames()
		await mouse(host.fishing_view.size*Vector2(.7,.5),true)
		check(host.model.controls.has("hook"),"direct field owns held reel input")
		await key(KEY_ESCAPE);await key(KEY_ESCAPE,false)
		await mouse(Vector2(-20,-20),false)
		check(host.paused and host.model.cast_attempts==0 and host.model.controls.is_empty() and host.fishing_pointer.is_empty(),"pause cancels held input without a scored release")
		host.fishing_control_scheme="keyboard";host._apply_fishing_control_layout()
		await key(KEY_ENTER);await key(KEY_ENTER,false)
		await touch(host.fishing_view.size*.5,true);await touch(host.fishing_view.size*.5,false,true)
		host._process(0)
		check(not host.fishing_controls_enabled,"actual touch respects an explicit keyboard scheme")
		host.fishing_control_scheme="auto";host.fishing_touch_seen=false;host.fishing_touch_available=false
		host.restart();host.begin();await frames()
		var before_touch: Vector2=host.fishing_view.size
		var point: Vector2=before_touch*Vector2(.7,.5)
		await touch(point,true)
		for i in range(4):host._process(.1)
		check(host.fishing_view.size==before_touch,"automatic touch detection never moves the field during a held gesture")
		await touch(point,false);host._process(0);await frames()
		check(host.fishing_controls_enabled and host.model.cast_attempts==1,"touch selects its scheme after one completed gesture, independent of width")
		assert_direct_water_layout(dimensions)
		host.restart();await frames()
		host.fishing_view.advance_view(0)
		var ready_hint: Label = host.fishing_view.labels.modal_body
		check(ready_hint.visible and "水面" in ready_hint.text and "拖动" in ready_hint.text,"touch ready hint teaches direct water dragging")
		check(ready_hint.get_minimum_size().y <= ready_hint.size.y, "touch ready hint fits its allocated text height")
		host.fishing_control_scheme="keyboard";host._apply_fishing_control_layout();host.restart();host.begin();await frames()
		host.fishing_control_scheme="auto";host.fishing_touch_seen=false;host.fishing_touch_available=true;host._apply_fishing_control_layout()
		check(host.fishing_controls_enabled,"touch-capable hardware retains its scheme even on a large viewport")
		assert_direct_water_layout(dimensions)
		host.fishing_control_scheme="touch";host._apply_fishing_control_layout();await frames()
		check(host.fishing_controls_enabled,"explicit touch scheme remains available without action pads")
		assert_direct_water_layout(dimensions)
		await key(KEY_R);await key(KEY_R,false)
		check(not host.running and not host.paused and host.model.cast_attempts==0,"keyboard Retry remains available")
		host.fishing_control_scheme="keyboard";host._apply_fishing_control_layout();host.begin();await frames()
		await key(KEY_A);await key(KEY_A,false);host._process(0);await frames()
		var pause_point: Vector2=host.pause_button.get_global_rect().get_center()
		await touch(pause_point,true)
		check(host.pause_button.get_meta("fishing_held"),"touch Pause press has visible held feedback before activation")
		var drag:=InputEventScreenDrag.new();drag.index=4;drag.position=Vector2(-20,-20)
		root.push_input(drag,true);await frames()
		check(not host.pause_button.get_meta("fishing_held"),"drag outside removes the Pause pressed face")
		drag=drag.duplicate();drag.position=pause_point;root.push_input(drag,true);await frames()
		await touch(pause_point,false)
		check(not host.pause_button.get_meta("fishing_held"),"Pause release clears its held visual state")
		check(host.paused,"real touch release activates Pause once")
		await emulated_mouse(pause_point,true);await emulated_mouse(pause_point,false)
		check(host.paused,"paired emulated mouse cannot activate Pause a second time")
		var exits: Array=[];host.cancelled.connect(func():exits.append(true))
		var exit: Button
		for button: Button in host.shared_pause_overlay.action_buttons:
			if button.text==host.exit_button.text: exit=button
		check(exit!=null and exit.is_visible_in_tree(),"shared Exit is visible while paused")
		if exit!=null:
			exit.grab_focus();await key(KEY_ENTER);await key(KEY_ENTER,false)
		check(exits.size()==1,"focused shared Exit emits once through keyboard")
		host.queue_free();await frames()
	print("LAKE_FISHING_CONTROL_SCHEME: ",checks," checks; ",failures," failures")
	quit(1 if failures else 0)
