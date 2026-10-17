extends SceneTree
## Input dispatch and layout regression tests, independent of rendering/pixel geometry.
## Run: godot --headless --path . --script res://tests/test_rescue_input.gd
var checks: int=0
var failures: int=0
var shell: Control
var view: Control

func _initialize() -> void:
	run.call_deferred()

func check(ok: bool,label: String) -> void:
	checks+=1
	if not ok:
		failures+=1
		push_error(label)

func click(point: Vector2) -> void:
	for pressed: bool in [true,false]:
		var event:=InputEventMouseButton.new()
		event.button_index=MOUSE_BUTTON_LEFT
		event.position=point
		event.global_position=point
		event.pressed=pressed
		Input.parse_input_event(event)

func touch(point: Vector2) -> void:
	# parse_input_event exercises the real touch-to-mouse emulation path.
	# Viewport.push_input alone does not generate the emulated mouse event.
	for pressed: bool in [true,false]:
		var event:=InputEventScreenTouch.new()
		event.index=0
		event.position=point
		event.pressed=pressed
		Input.parse_input_event(event)

func key(code: Key) -> void:
	for pressed: bool in [true,false]:
		var event:=InputEventKey.new()
		event.keycode=code
		event.physical_keycode=code
		event.pressed=pressed
		Input.parse_input_event(event)

func button_center(index: int) -> Vector2:
	return view.get_global_transform()*view.BUTTONS[index].get_center()

func run() -> void:
	check(ProjectSettings.get_setting("input_devices/pointing/emulate_mouse_from_touch",true),"test project enables normal touch-to-mouse emulation")
	shell=load("res://scenes/rain_rescue_preview.tscn").instantiate()
	root.add_child(shell)
	view=shell.get_node("Presentation")
	view.capture_mode=true
	for dimensions: Vector2i in [Vector2i(280,500),Vector2i(320,568),Vector2i(375,667),Vector2i(390,844),Vector2i(960,540),Vector2i(1280,720)]:
		root.size=dimensions
		await process_frame
		await process_frame
		var viewport_rect:=Rect2(Vector2.ZERO,Vector2(dimensions))
		var portrait: bool=dimensions.x<650 and dimensions.y>dimensions.x
		check(shell.mobile_controls.visible==portrait,"mobile controls visibility at %s" % dimensions)
		if portrait:
			check(viewport_rect.encloses(shell.mobile_controls.get_global_rect()),"mobile controls container fits %s" % dimensions)
			for button: Button in shell.mobile_controls.get_children():
				check(viewport_rect.encloses(button.get_global_rect()),"actual button %s fits %s" % [button.text,dimensions])
				check(button.size.x>=44 and button.size.y>=48,"button %s retains a usable touch target at %s" % [button.text,dimensions])
				check(button.focus_mode==Control.FOCUS_NONE,"mobile buttons do not consume the Space shortcut")
		view.replay()
		click(button_center(0))
		await process_frame
		check(view.timeline.paused,"one real mouse click pauses at %s" % dimensions)
		var saved_elapsed: float=view.timeline.elapsed
		var saved_wet_time: float=view.wet_time
		await process_frame
		await process_frame
		check(view.timeline.elapsed==saved_elapsed and view.wet_time==saved_wet_time,"pause freezes both actor timeline and rain/drip clock")
		click(button_center(0))
		await process_frame
		check(not view.timeline.paused,"second mouse click resumes at %s" % dimensions)
		view.replay()
		touch(button_center(0))
		await process_frame
		check(view.timeline.paused,"one touch pauses exactly once despite emulated mouse at %s" % dimensions)
		var old_run: int=view.timeline.run_id
		touch(button_center(1))
		await process_frame
		check(view.timeline.run_id==old_run+1,"one touch replays exactly once at %s" % dimensions)
		check(not view.timeline.paused and view.timeline.elapsed<.1,"replay unpauses and restarts near time zero")
		var old_callbacks: int=view.callback_count
		touch(button_center(2))
		await process_frame
		check(view.timeline.finished and view.timeline.pose().landed and view.timeline.pose().wet,"touch skip shows safe wet shore state")
		check(view.timeline.outcome=="skipped_preview" and view.callback_count==old_callbacks+1,"touch skip emits one local preview callback")
		touch(button_center(2))
		await process_frame
		check(view.callback_count==old_callbacks+1,"repeated touch skip cannot duplicate completion")
		if portrait:
			view.replay()
			touch(shell.mobile_controls.get_child(0).get_global_rect().get_center())
			await process_frame
			check(view.timeline.paused,"native mobile pause still works through mouse emulation")
			click(shell.mobile_controls.get_child(1).get_global_rect().get_center())
			await process_frame
			check(not view.timeline.paused,"native mobile replay works")
			view.timeline.elapsed=7.0
			key(KEY_SPACE)
			await process_frame
			# Parsed input may dispatch after one frame of timeline advancement.
			check(view.timeline.paused and view.timeline.elapsed>=7.0 and view.timeline.elapsed<=7.051,"Space pauses after native replay click instead of activating replay again")
			key(KEY_R)
			await process_frame
			check(not view.timeline.paused and view.timeline.elapsed<.1,"R replays after mobile control interaction")
		view.footprint_side=-1
		view.replay()
		check(view.footprint_side==1 and view.footprints.is_empty(),"replay restores deterministic footprint state")
	print("QIZHEN_RAIN_RESCUE_INPUT: ",checks," checks; ",failures," failures")
	quit(1 if failures else 0)
