extends "res://tests/test_lake_fishing_view.gd"
## Stationary-pointer regression. Synthetic root input, not earned gameplay.
func move_mouse(point: Vector2) -> void:
	var event:=InputEventMouseMotion.new()
	event.position=point;event.global_position=point;event.button_mask=MOUSE_BUTTON_MASK_LEFT
	root.push_input(event,true);await frames()

func step_for(seconds: float,delta: float) -> void:
	for i in range(roundi(seconds/delta)): host._process(delta)

func point_for(target: float) -> Vector2:
	return host.fishing_view.size*Vector2(.5+target*.29,.5)

func run() -> void:
	root.get_node("State").developer_mode=true
	for dimensions: Vector2i in [Vector2i(1180,812),Vector2i(390,844),Vector2i(430,860),Vector2i(844,390)]:
		root.size=dimensions
		host=load("res://scripts/ui/minigame_host.gd").new();root.add_child(host);await frames()
		host.setup({"type":"rhythm","chartId":"paper","title":"纸条本体","control_scheme":"keyboard"})
		host.configure_activity_layout(Vector2(dimensions),dimensions.x<1100)
		host.set_process(false);host.begin();await frames()
		var target:=.03
		await mouse(point_for(target),true)
		var start_time: float=host.model.elapsed
		step_for(1.5,1.0/60.0)
		check(absf(host.model.elapsed-start_time-1.5)<.00001,"target following preserves the ordinary model clock")
		check(absf(host.model.line_x-target)<=.08001,"stationary held pointer stops inside the original target deadband")
		check(host.model.controls.has("hook") and not host.model.controls.has("left") and not host.model.controls.has("right"),"arrival retires only directional owner while reel stays held")
		var held_position: float=host.model.line_x
		step_for(.5,1.0/60.0)
		check(is_equal_approx(host.model.line_x,held_position),"stationary hold cannot continue drifting after arrival")
		await move_mouse(point_for(-.55));step_for(1.0,.1)
		check(absf(host.model.line_x+.55)<=.08001,"drag reversal reaches the new pointer target on bounded long frames")
		await mouse(Vector2(-20,-20),false)
		check(host.fishing_pointer.is_empty() and host.model.controls.is_empty() and host.model.cast_attempts==1,"outside release closes both pointer owners and attempts one cast")
		held_position=host.model.line_x;step_for(.5,.1)
		check(is_equal_approx(host.model.line_x,held_position),"released pointer cannot revive steering on later frames")
		host.restart();host.begin();await frames()
		await touch(point_for(.45),true);step_for(1.2,.1)
		check(absf(host.model.line_x-.45)<=.08001,"stationary touch uses the same target-following rule")
		await touch(point_for(.45),false,true)
		check(host.model.controls.is_empty() and host.model.cast_attempts==0,"touch cancellation remains neutral")
		for interruption: String in ["pause","resize","focus","retry"]:
			host.restart();host.begin();await frames()
			await mouse(point_for(.6),true);step_for(.2,.1)
			match interruption:
				"pause": host.toggle_pause()
				"resize": host.configure_activity_layout(Vector2(dimensions)+Vector2(1,0),dimensions.x<1100)
				"focus": host.notification(Node.NOTIFICATION_WM_WINDOW_FOCUS_OUT)
				"retry": host.restart()
			check(host.fishing_pointer.is_empty() and host.fishing_direction.is_empty() and host.model.controls.is_empty(),interruption+" clears retained pointer and direction owners")
			check(host.model.cast_attempts==0,interruption+" cannot turn cancellation into a scored cast")
		host.restart();host.begin();await frames()
		await mouse(point_for(.7),true)
		host.press_action("right","keyboard:right")
		await mouse(Vector2(-20,-20),false)
		check(host.model.controls.has("right") and host.action_sources.right.has("keyboard:right"),"pointer release preserves independently held keyboard steering")
		host.release_action("right","keyboard:right")
		check(host.model.controls.is_empty(),"final keyboard release retires the remaining owner")
		host.queue_free();await frames()
	print("LAKE_FISHING_POINTER_FOLLOW: ",checks," checks; ",failures," failures")
	quit(1 if failures else 0)
