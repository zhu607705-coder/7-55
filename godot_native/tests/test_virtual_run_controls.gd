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
	game._layout()
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
	game.set_process(false)
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

func route_event(point: Vector2,down: bool,touch_input: bool=false) -> void:
	if touch_input:
		var event=InputEventScreenTouch.new();event.index=3;event.position=point;event.pressed=down;root.push_input(event,true)
	else:
		var event=InputEventMouseButton.new();event.button_index=MOUSE_BUTTON_LEFT;event.position=point;event.pressed=down;root.push_input(event,true)

func route_motion(point: Vector2,touch_input: bool=false) -> void:
	if touch_input:
		var event=InputEventScreenDrag.new();event.index=3;event.position=point;root.push_input(event,true)
	else:
		var event=InputEventMouseMotion.new();event.position=point;event.button_mask=MOUSE_BUTTON_MASK_LEFT;root.push_input(event,true)

func steer_segment(touch_input: bool=false) -> void:
	var before: int=game.completed
	route_event(game.track.to_screen(game.motion.position),true,touch_input)
	for i in range(1600):
		var offset: Vector2=game.motion.goal()-game.motion.position
		route_motion(game.track.to_screen(game.motion.position+offset.limit_length(16)),touch_input)
		game._step(1.0/60)
		if game.completed!=before or game.pending_result:break
	route_event(game.track.to_screen(game.motion.position),false,touch_input)
	await frames(2)
	check(game.completed==before+1 or game.result_rejected,"continuous pointer path reaches one genuine gate")

func verify_layout() -> void:
	var bounds=Rect2(Vector2.ZERO,Vector2(dimensions))
	for node in [game.track,game.header,game.next_card,game.exit_button,game.status,game.footer]:
		check(bounds.encloses(screen_rect(node)),"layout stays in window at "+str(dimensions))
	for label in [game.eyebrow,game.next_title,game.next_detail,game.status,game.footer,game.progress_label,game.gps]:
		check(label.get_minimum_size().y<=label.size.y+.1,"text fits its own control: "+label.text)
	check(screen_rect(game.exit_button).size.x>=43.99,"exit keeps touch target")
	check(game.track.to_route(game.track.to_screen(game.motion.position)).distance_to(game.motion.position)<.01,"resize preserves exact pointer transform")

func run() -> void:
	var geometry=preload("res://scripts/games/virtual_run_motion.gd")
	var quarter=PI*geometry.RADIUS/2
	check(is_equal_approx(geometry.at_distance(quarter+25).x,geometry.at_distance(quarter+105).x),"left straight has no polygon kink")
	var right=quarter+geometry.STRAIGHT+PI*geometry.RADIUS
	check(is_equal_approx(geometry.at_distance(right+25).x,geometry.at_distance(right+105).x),"right straight has no polygon kink")
	check(geometry.at_distance(0).distance_to(geometry.at_distance(geometry.LENGTH))<.01,"oval start and finish share one closed line")
	for view: Vector2i in [Vector2i(390,844),Vector2i(430,860)]:
		await spawn(view);verify_layout()
		game._step(1000)
		check(game.completed==0 and results.is_empty(),"idle time cannot earn progress")
		for i in range(10):
			var goal=game.track.to_screen(game.POINTS[i]*360)
			route_event(goal,true);route_event(goal,false);game._step(.016)
		check(game.completed==0,"clicking all ten points never completes a segment")
		await press_key(KEY_ENTER);await press_key(KEY_SPACE)
		check(game.completed==0,"accept keys cannot replace traversal")
		await steer_segment();check(game.stat_values[0].text=="01:00" and game.stat_values[1].text=="0.30","one traversed segment records original time and distance")
		await steer_segment(true)
		var position: Vector2=game.motion.position
		for i in range(100):game._step(.016)
		check(position==game.motion.position,"release stops without drifting")
		route_event(game.track.to_screen(position),true)
		route_motion(game.track.to_screen(Vector2(180,180)))
		for i in range(120):game._step(.016)
		check(game.completed==2 and game.motion.retries==1 and game.pointer_id==-2,"cutting across grass resets only current segment and clears held input")
		check(game.motion.position==game.motion.checkpoint(),"recovery uses last earned checkpoint")
		route_event(game.track.to_screen(game.motion.position),true)
		route_motion(game.track.to_screen(game.motion.goal()))
		game._notification(Node.NOTIFICATION_APPLICATION_FOCUS_OUT)
		position=game.motion.position;game._step(.05)
		check(position==game.motion.position and game.held.is_empty(),"focus loss clears pointer and keyboard movement")
		await resize(Vector2i(430,860) if view.x==390 else Vector2i(390,844));verify_layout()
		check(game.completed==2,"resize preserves only genuine progress")
		for i in range(7):await steer_segment(view.x==390)
		check(results.is_empty() and game.stat_values[1].text=="2.70","nine traversed segments cannot finish")
		await steer_segment(view.x==390)
		check(results.size()==1 and game.pending_result and not game.accepted,"last gate submits once and waits for authority")
		check(results[0]=={"failed":false,"points":10,"elapsedSeconds":600,"distanceMeters":3000},"original proof payload retained")
		game._step(.05);check(results.size()==1,"pending cannot resubmit")
		game.resolve(true);await frames();verify_layout()
		check(game.return_button.visible and game.accepted,"only authority unlocks success")
		await mouse_click(game.return_button);check(cancels==1,"return closes once")
	await spawn(Vector2i(390,844))
	for i in range(3):await steer_segment(true)
	check(not game.motion.interference().is_empty(),"signal challenge starts after safe practice segments")
	route_event(game.track.to_screen(game.motion.position),true,true)
	var fast_target: Vector2=game.motion.goal()+(game.motion.goal()-game.motion.position).normalized()*180
	route_motion(game.track.to_screen(fast_target),true)
	for i in range(120):game._step(.016)
	check(game.completed==3 and game.motion.retries==1,"rushing the visible signal zone rejects only current segment")
	await steer_segment(true)
	check(game.completed==4 and game.motion.retries==1,"slower real touch path crosses the same interference safely")
	await spawn(Vector2i(430,860))
	await key(KEY_LEFT,true)
	for i in range(20):game._step(.016)
	await key(KEY_LEFT,false)
	check(game.motion.position.x<game.motion.START.x,"keyboard steers the same cursor")
	await key(KEY_LEFT,true);await key(KEY_SPACE,true)
	for i in range(20):game._step(.016)
	check(game.motion.velocity.length()<=game.motion.SLOW_SPEED+.1,"Space brakes actual movement")
	game._release_input();await press_key(KEY_ESCAPE)
	check(cancels==1 and results.is_empty(),"partial keyboard exit emits no proof")
	game.queue_free();await frames()
	print("VIRTUAL_RUN_CONTROLS: %d checks; %d failures"%[checks,failures]);quit(1 if failures else 0)
