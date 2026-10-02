extends SceneTree
## Headless actual-input fixtures, not a manual campaign or screenshot claim.
const VirtualRun = preload("res://scripts/games/virtual_run.gd")
const Ui = preload("res://scripts/ui/native_ui_theme.gd")
var checks := 0
var failures := 0
var game: Control
var results: Array = []
var cancels := 0
var dimensions := Vector2i(390,844)

func _initialize() -> void: run.call_deferred()

func check(ok: bool,message: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		push_error("VIRTUAL_RUN: "+message)

func frames(count: int = 3) -> void:
	for i in range(count): await process_frame

func screen_rect(node: Control) -> Rect2:
	var transform := node.get_global_transform_with_canvas()
	return Rect2(transform.origin,node.size*transform.get_scale())

func resize(view: Vector2i) -> void:
	dimensions = view
	root.size = view
	var scale_factor := minf((view.x-20)/430.0,(view.y-20)/820.0)
	game.scale = Vector2.ONE*scale_factor
	game.position = (Vector2(view)-game.size*scale_factor)/2
	await frames()

func spawn(view: Vector2i) -> void:
	if is_instance_valid(game):
		game.queue_free()
		await frames()
	results.clear()
	cancels = 0
	game = VirtualRun.new()
	game.size = Vector2(430,820)
	game.theme = Ui.font_theme(load("res://assets/rpg/fonts/fusion_pixel_12px_proportional_zh_hans.ttf"))
	root.add_child(game)
	game.finished.connect(func(result: Dictionary): results.append(result))
	game.cancelled.connect(func(): cancels += 1)
	game.start({})
	await resize(view)

func mouse_point(point: Vector2,down: bool) -> void:
	var event := InputEventMouseButton.new()
	event.position = point
	event.global_position = point
	event.button_index = MOUSE_BUTTON_LEFT
	event.pressed = down
	root.push_input(event,true)
	await frames(1)

func mouse_click(node: Control) -> void:
	var point := screen_rect(node).get_center()
	var motion := InputEventMouseMotion.new()
	motion.position = point
	root.push_input(motion,true)
	await mouse_point(point,true)
	await mouse_point(point,false)

func touch(node: Control,down: bool,canceled: bool = false) -> void:
	var event := InputEventScreenTouch.new()
	event.index = 0
	event.position = screen_rect(node).get_center()
	event.pressed = down
	event.canceled = canceled
	Input.parse_input_event(event)
	await frames(1)

func key(code: int,down: bool,echo_event: bool = false) -> void:
	var event := InputEventKey.new()
	event.keycode = code
	event.physical_keycode = code
	event.pressed = down
	event.echo = echo_event
	root.push_input(event,true)
	await frames(1)

func press_key(code: int) -> void:
	await key(code,true)
	await key(code,false)

func verify_layout() -> void:
	var bounds := Rect2(Vector2.ZERO,Vector2(dimensions))
	for button: Button in game.point_buttons:
		var rect := screen_rect(button)
		check(bounds.encloses(rect),"point stays in window at "+str(dimensions))
		check(rect.size.x >= 43.99 and rect.size.y >= 43.99,"point has a physical44px target at "+str(dimensions))
		check(screen_rect(game.track).encloses(rect),"point stays inside track")
		for other: Button in game.point_buttons:
			if button != other: check(not rect.intersects(screen_rect(other)),"point hit regions remain disjoint")
	for i in range(game.point_buttons.size()):
		var button: Button = game.point_buttons[i]
		var mark: Line2D = game.recorded_marks[i]
		check(mark.get_parent() == button and mark.points.size() == 3,"recorded symbol uses an actual native three-point line, not font text")
		check(mark.visible == (i < game.completed),"only genuinely recorded points show the vector check")
		check(button.text == ("" if i < game.completed else str(i+1)),"visited point has no unsupported glyph; future point retains its number")
		check(button.accessibility_name == button.tooltip_text and ("第 %d 分钟" % (i+1)) in button.accessibility_name,"every point preserves its numbered accessible name and tooltip")
		check(("已记录" in button.accessibility_name) == (i < game.completed),"accessible recorded state matches genuine point count")
		for point: Vector2 in mark.points:
			check(Rect2(Vector2.ZERO,button.size).has_point(point*mark.scale),"native check geometry stays inside the unchanged hitbox")
	for label: Label in [game.eyebrow,game.stat_titles[0],game.next_title,game.next_detail,game.status,game.footer,game.progress_label,game.gps]:
		check(bounds.encloses(screen_rect(label)),"text is inside window: "+label.text)
		check(label.get_theme_font_size("font_size")*game.scale.x >= 11.99,"caption retains12px physical floor")
		check(label.get_minimum_size().x <= label.size.x+.1,"label does not grow beyond layout width: "+label.text)
		check(label.get_minimum_size().y <= label.size.y+.1,"label does not grow beyond layout height: "+label.text)
	check(screen_rect(game.exit_button).size.x>=43.99,"exit has44px target")
	check(screen_rect(game.footer).end.y<=screen_rect(game).end.y-5,"footer stays above bottom edge")

func run() -> void:
	Input.emulate_mouse_from_touch = true
	for view: Vector2i in [Vector2i(390,844),Vector2i(430,860)]:
		await spawn(view)
		verify_layout()
		check(game.completed == 0 and results.is_empty(),"mount/start do not create a fix")
		game._process(3600)
		check(game.completed == 0,"elapsed wall time never generates a recorded fix")
		var point_start := screen_rect(game.target).get_center()
		await mouse_point(point_start,true)
		var away := InputEventMouseMotion.new()
		away.position = screen_rect(game.header).get_center()
		away.button_mask = MOUSE_BUTTON_MASK_LEFT
		root.push_input(away,true)
		await mouse_point(away.position,false)
		check(game.completed == 0,"dragging a press off its target does not record")
		await mouse_click(game.point_buttons[4])
		check(game.completed == 0 and results.is_empty() and "定位漂移" in game.status.text,"future real control gives feedback without progress")
		await mouse_click(game.point_buttons[0])
		check(game.completed == 1 and game.stat_values[0].text == "01:00" and game.stat_values[1].text == "0.30","first real press records exactly one minute and300m")
		await mouse_click(game.point_buttons[0])
		check(game.completed == 1 and "已记录" in game.status.text,"repeat point cannot duplicate progress")
		await mouse_click(game.target)
		check(game.completed == 2 and game.target == game.point_buttons[2],"second press advances next target")
		await press_key(KEY_SPACE)
		check(game.completed == 3,"Space activates the focused next target")
		await press_key(KEY_ENTER)
		check(game.completed == 4,"Enter activates the focused next target")
		await key(KEY_SPACE,true)
		for i in range(4): await key(KEY_SPACE,true,true)
		await key(KEY_SPACE,false)
		check(game.completed == 5,"held keyboard accept cannot consume future targets")
		var before_touch: int = game.completed
		await touch(game.target,true)
		await touch(game.target,false)
		check(game.completed == before_touch+1,"actual screen touch records one fix")
		var before_resize: int = game.completed
		await resize(Vector2i(430,860) if view.x == 390 else Vector2i(390,844))
		verify_layout()
		check(game.completed == before_resize and results.is_empty(),"resize preserves attempt without completion")
		while game.completed < 9: await mouse_click(game.target)
		check(results.is_empty() and game.stat_values[0].text == "09:00" and game.stat_values[1].text == "2.70","nine real controls cannot finish")
		check("终点" in game.next_title.text and "3.00" in game.next_detail.text,"final target explains payoff")
		await mouse_click(game.target)
		check(results.size() == 1 and game.pending_result and not game.accepted,"tenth press submits once and awaits authority")
		check(results[0] == {"failed":false,"points":10,"elapsedSeconds":600,"distanceMeters":3000},"unchanged exact result payload")
		await mouse_click(game.point_buttons[9])
		await press_key(KEY_ENTER)
		check(results.size() == 1,"extra point/keyboard input cannot resubmit pending result")
		game.resolve(true)
		await frames()
		check(game.accepted and game.completed == 10 and game.return_button.visible,"accepted result retains completed track and explicit return")
		check(game.title.text == "课外锻炼已同步" and "3.00" in game.next_detail.text,"authoritative success has visible distance/time payoff")
		verify_layout()
		check(screen_rect(game.return_button).size.y >=43.99 and Rect2(Vector2.ZERO,Vector2(dimensions)).encloses(screen_rect(game.return_button)),"result return is visible and44px")
		await mouse_click(game.return_button)
		check(cancels == 1 and results.size() == 1,"Return closes without a second submission")
		await press_key(KEY_ESCAPE)
		check(cancels == 1,"repeat Back after close is idempotent")
	await spawn(Vector2i(390,844))
	for i in range(10): await mouse_click(game.target)
	game.resolve(false)
	await frames()
	check(game.completed == 9 and not game.accepted and not game.pending_result,"controller rejection restores source ninth-fix state")
	check(game.target == game.point_buttons[9] and "身份失效" in game.status.text,"rejection leaves final retry control and exit guidance")
	await mouse_click(game.target)
	check(results.size() == 2 and game.pending_result,"retry submits only after another genuine final press")
	game.resolve(false)
	await press_key(KEY_ESCAPE)
	check(cancels == 1 and game.closed,"Esc exits rejected attempt")
	await spawn(Vector2i(390,844))
	check(game.completed == 0 and not game.accepted,"reopening cancelled run restarts at first fix")
	await mouse_click(game.target)
	await mouse_click(game.exit_button)
	check(cancels == 1 and results.is_empty(),"partial run exit never submits proof")
	await spawn(Vector2i(430,860))
	await press_key(KEY_TAB)
	check(root.gui_get_focus_owner() != null,"Tab keeps keyboard navigation in game controls")
	await press_key(KEY_ESCAPE)
	check(cancels == 1 and results.is_empty(),"keyboard back exits without a point")
	game.queue_free()
	await frames()
	print("VIRTUAL_RUN_CONTROLS: %d checks; %d failures" % [checks,failures])
	quit(1 if failures else 0)
