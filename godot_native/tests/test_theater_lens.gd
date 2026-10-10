extends SceneTree
## Lens geometry, presentation boundary and physical-pointer regression coverage.
## Headless synthetic pointer events are not a physical mobile-device test.
const Lens = preload("res://scripts/presentation/theater_lens.gd")
const Model = preload("res://scripts/games/c3_spotlight_model.gd")
const Game = preload("res://scripts/games/c3_spotlight.gd")
const TOLERANCE := 0.25
var checks := 0
var failures := 0
var game: Control
var submissions: Array = []
var continuations: Array = []

func _initialize() -> void:
	_run.call_deferred()

func check(value: bool, message: String) -> void:
	checks += 1
	if not value:
		failures += 1
		push_error("THEATER LENS: " + message)

func near(a: Vector2, b: Vector2) -> bool:
	return a.is_finite() and b.is_finite() and a.distance_to(b) <= TOLERANCE

func frames(count: int = 2) -> void:
	for i in count:
		await process_frame

func mouse(pressed: bool, local_point: Vector2, device: int = 0) -> void:
	var event := InputEventMouseButton.new()
	event.button_index = MOUSE_BUTTON_LEFT
	event.pressed = pressed
	event.position = local_point
	event.device = device
	game._gui_input(event)

func mouse_motion(local_point: Vector2, device: int = 0) -> void:
	var event := InputEventMouseMotion.new()
	event.position = local_point
	event.button_mask = MOUSE_BUTTON_MASK_LEFT
	event.device = device
	game._gui_input(event)

func touch(index: int, pressed: bool, local_point: Vector2, canceled: bool = false, device: int = 0) -> void:
	var event := InputEventScreenTouch.new()
	event.index = index
	event.pressed = pressed
	event.position = local_point
	event.canceled = canceled
	event.device = device
	game._gui_input(event)

func touch_drag(index: int, local_point: Vector2, device: int = 0) -> void:
	var event := InputEventScreenDrag.new()
	event.index = index
	event.position = local_point
	event.device = device
	game._gui_input(event)

func screen_mouse(pressed: bool, source_point: Vector2) -> void:
	var event := InputEventMouseButton.new()
	event.button_index = MOUSE_BUTTON_LEFT
	event.pressed = pressed
	event.position = game.get_global_transform_with_canvas() * game.model_to_pointer(source_point)
	event.global_position = event.position
	root.push_input(event, true)
	await frames()

func screen_touch(index: int, pressed: bool, source_point: Vector2, canceled: bool = false) -> void:
	var event := InputEventScreenTouch.new()
	event.index = index
	event.pressed = pressed
	event.canceled = canceled
	event.position = game.get_global_transform_with_canvas() * game.model_to_pointer(source_point)
	root.push_input(event, true)
	await frames()

func geometry() -> void:
	var shader := FileAccess.get_file_as_string("res://scripts/presentation/theater_lens.gdshader")
	var compact_shader := shader.replace(" ", "").replace("\t", "").replace("\n", "").replace("\r", "")
	check(compact_shader.contains("p.x*(1.0+0.075*p.y*p.y)+0.026*p.y*p.y+0.014*p.x*p.x"), "GPU x sampling polynomial stays synchronized with tested CPU inverse")
	check(compact_shader.contains("p.y+0.16*p.x*p.x*(0.34+p.y)+0.033*p.x*p.x*p.x"), "GPU y sampling polynomial stays synchronized with tested CPU inverse")
	check(not compact_shader.contains("TIME"), "lens remains fixed while presentation animates")
	var largest_displacement := 0.0
	for iy in range(19):
		for ix in range(33):
			var display := Vector2(ix * 30.0, iy * 30.0)
			var sample: Vector2 = Lens.sample_point(display)
			var p: Vector2 = (display-Vector2(480,270))/Vector2(480,270)
			var reference := Vector2(480,270)+Vector2(p.x*(1.0+0.075*p.y*p.y)+0.026*p.y*p.y+0.014*p.x*p.x,p.y+0.16*p.x*p.x*(0.34+p.y)+0.033*p.x*p.x*p.x)*Vector2(480,270)
			check(near(sample,reference), "CPU samples same polynomial as scene shader at " + str(display))
			var recovered: Vector2 = Lens.display_point(sample)
			check(near(recovered, display), "display/source/display grid roundtrip at " + str(display))
			var source := display
			var projected: Vector2 = Lens.display_point(source)
			check(near(Lens.sample_point(projected), source), "source/display/source grid roundtrip at " + str(source))
			largest_displacement = maxf(largest_displacement, source.distance_to(projected))
			if ix > 0 and ix < 32 and iy > 0 and iy < 18:
				var dx: Vector2 = Lens.sample_point(display + Vector2(0.5, 0)) - Lens.sample_point(display - Vector2(0.5, 0))
				var dy: Vector2 = Lens.sample_point(display + Vector2(0, 0.5)) - Lens.sample_point(display - Vector2(0, 0.5))
				check(dx.cross(dy) > 0.05, "local lens does not fold or collapse at " + str(display))
	check(largest_displacement > 2.0, "scene lens is visibly non-identity")
	for source: Vector2 in [Vector2(71,145), Vector2(889,145), Vector2(71,396), Vector2(889,396), Vector2(156,280), Vector2(839,230), Vector2(839,302)]:
		check(near(Lens.sample_point(Lens.display_point(source)), source), "authored stage edge/exit remains reachable at " + str(source))
	for source: Vector2 in Model.FOOD:
		check(near(Lens.sample_point(Lens.display_point(source)), source), "authored punctuation anchor remains reachable at " + str(source))

func presentation_boundary() -> void:
	check(is_instance_valid(game.stage_view), "stage has a dedicated presentation owner")
	for control: Control in [game.label, game.badge, game.start_button, game.dash_button, game.pause_button, game.overlay_title, game.overlay_body]:
		check(not game.stage_view.is_ancestor_of(control), "native HUD/overlay remains outside warped stage: " + control.name)
	check(game.size == Vector2(960,540), "native game retains authored 960 by 540 contract")
	check(game.label.material == null and game.start_button.material == null, "HUD and primary action do not directly inherit a lens shader")

func ownership() -> void:
	game.setup({"round":0,"attempt":0})
	game._primary()
	var saved: Dictionary = game.state.duplicate(true)
	var source := Vector2(300,193)
	var other := Vector2(515,341)
	var point: Vector2 = game.model_to_pointer(source)
	var other_point: Vector2 = game.model_to_pointer(other)
	touch(4,true,point)
	check(game.dragging and near(game.pointer,source), "first touch owns inverse-mapped steering")
	touch(5,true,other_point)
	touch_drag(5,other_point)
	touch(5,false,other_point)
	touch(5,false,other_point,true)
	check(game.dragging and near(game.pointer,source), "second finger cannot move or cancel first touch")
	touch_drag(4,other_point,2)
	touch(4,false,other_point,false,2)
	check(game.dragging and near(game.pointer,source), "another touch device with same index cannot move or release owner")
	mouse(true,other_point)
	mouse_motion(other_point)
	mouse(false,other_point)
	check(game.dragging and near(game.pointer,source), "physical mouse cannot replace or release active touch")
	mouse(true,other_point,-1)
	mouse_motion(other_point,-1)
	mouse(false,other_point,-1)
	check(game.dragging and near(game.pointer,source), "touch-emulated mouse cannot duplicate touch steering")
	touch_drag(4,other_point)
	check(near(game.pointer,other), "owner drag uses the same inverse lens as initial press")
	touch(4,false,other_point,true)
	check(not game.dragging, "owner canceled touch clears steering")
	touch_drag(4,point)
	check(not game.dragging, "late drag cannot restart canceled touch")
	mouse(true,point,-1)
	check(not game.dragging, "standalone emulated mouse press cannot acquire physical owner")
	mouse(true,point)
	check(game.dragging and near(game.pointer,source), "physical mouse owns inverse-mapped steering")
	touch(2,true,other_point)
	touch_drag(2,other_point)
	touch(2,false,other_point,true)
	check(game.dragging and near(game.pointer,source), "touch cannot replace or cancel physical mouse")
	mouse_motion(other_point,2)
	mouse(false,other_point,2)
	check(game.dragging and near(game.pointer,source), "another mouse device cannot move or release mouse owner")
	mouse_motion(other_point)
	check(near(game.pointer,other), "owner mouse motion inverse-maps visible point")
	mouse(false,Vector2(-20,-20))
	check(not game.dragging, "owner mouse release outside stage clears steering")
	mouse_motion(point)
	check(not game.dragging, "late mouse motion cannot restart a released owner")
	mouse(true,Vector2(480,478))
	check(not game.dragging, "HUD-area press cannot acquire stage steering")
	touch(8,true,Vector2(480,478))
	check(not game.dragging, "HUD-area touch cannot acquire stage steering")
	check(game.state==saved and game.trace.is_empty(), "pointer/lens updates never mutate authoritative gameplay outside fixed ticks")

func lifecycle() -> void:
	for boundary: String in ["pause","focus","reset","result"]:
		game.setup({"round":0,"attempt":0})
		game._primary()
		touch(7,true,game.model_to_pointer(Vector2(300,193)))
		game.queued_dash=true
		game.accumulator=0.025
		var saved: Dictionary=game.state.duplicate(true)
		var saved_time: float=game.visual_time
		match boundary:
			"pause": game._pause()
			"focus": game.notification(Node.NOTIFICATION_APPLICATION_FOCUS_OUT)
			"reset": game.setup({"round":1,"attempt":2})
			"result": game.resolve(false)
		check(not game.dragging and not game.queued_dash, boundary + " clears retained pointer and queued dash")
		if boundary in ["pause","focus"]:
			game._process(0.15)
			check(game.state == saved and is_equal_approx(game.visual_time,saved_time), boundary + " freezes rule clock and presentation clock")
			game._primary()
			game._process(0.05)
			check(game.trace.back().x == 0.0 and game.trace.back().y == 0.0 and not game.trace.back().dash, boundary + " resume cannot reuse canceled input")
		elif boundary == "reset":
			check(game.screen=="intro" and game.state.round==1 and game.state.attempt==2 and game.state.tick==0 and game.trace.is_empty() and is_zero_approx(game.accumulator), "setup resets all replay and presentation input state")
			check("2" in game.badge.text, "setup updates source act badge")
		else:
			game._process(0.15)
			check(game.state == saved and game.screen=="result", "result never advances model before acknowledgment")
		touch_drag(7,game.model_to_pointer(Vector2(515,341)))
		check(not game.dragging, boundary + " rejects stale gesture continuation")

func scaled_input() -> void:
	for dimensions: Vector2i in [Vector2i(1280,720),Vector2i(1024,768),Vector2i(390,844),Vector2i(844,390)]:
		root.size=dimensions
		game.setup({"round":0,"attempt":0})
		game._primary()
		var available:=Vector2(dimensions)
		var fit:=minf((available.x-20.0)/960.0,(available.y-20.0)/540.0)
		game.scale=Vector2.ONE*fit
		game.position=(available-Vector2(960,540)*fit)/2.0
		await frames()
		var target:=Vector2(300,193)
		await screen_mouse(true,target)
		check(game.dragging and near(game.pointer,target), "root-routed mouse maps correctly at " + str(dimensions))
		var start: Vector2=game.state.head
		game._process(0.05)
		var expected: Vector2=start+(target-start).normalized()*166.0*0.05
		check(near(game.state.head,expected), "scaled pointer produces unchanged source-model step at " + str(dimensions))
		await screen_mouse(false,target)
		check(not game.dragging, "root-routed release clears mouse at " + str(dimensions))
		await screen_touch(12,true,Vector2(515,341))
		check(game.dragging and near(game.pointer,Vector2(515,341)), "root-routed touch maps correctly at " + str(dimensions))
		await screen_touch(12,false,Vector2(515,341),true)
		check(not game.dragging, "root-routed canceled touch clears steering at " + str(dimensions))
	game.scale=Vector2.ONE
	game.position=Vector2.ZERO

func replay_authority() -> void:
	var rules:=Model.new()
	for round_id in 3:
		var fixture: Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://tests/fixtures/spotlight_%d.json" % round_id))
		var result: Dictionary=rules.validate(fixture,round_id,int(fixture.attempt))
		check(not result.is_empty() and result.status=="won", "unchanged source replay remains accepted for act " + str(round_id))
	game.setup({"round":0,"attempt":0})
	game._primary()
	submissions.clear()
	for i in 1600:
		game._process(0.05)
	check(game.state.status=="lost" and game.state.tick==1600 and game.trace.size()==1600, "idle timeout retains exact 1600 fixed source ticks")
	check(submissions.size()==1 and game.screen=="awaiting", "terminal state submits once and waits for controller result")
	if submissions.size()==1:
		var accepted: Dictionary=rules.validate(submissions[0],0,0)
		check(not accepted.is_empty() and accepted==game.state, "UI terminal replay validates to exactly the authoritative state")
	for i in 4:
		game._process(0.15)
	check(submissions.size()==1 and game.trace.size()==1600, "terminal frames never resubmit or extend proof")
	game.resolve(false)
	check(game.screen=="result" and game.start_button.visible and not game.approved, "rejected/failed attempt keeps its explicit retry acknowledgment")
	game._primary()
	check(continuations.size()==1 and continuations[0].get("continue",false), "result primary only requests controller continuation")

func _run() -> void:
	root.get_node("State").developer_mode=true
	geometry()
	game=Game.new()
	game.setup({"round":0,"attempt":0})
	root.add_child(game)
	game.set_process(false)
	game.attempt_submitted.connect(func(result: Dictionary): submissions.append(result))
	game.finished.connect(func(result: Dictionary): continuations.append(result))
	await frames()
	presentation_boundary()
	ownership()
	lifecycle()
	await scaled_input()
	replay_authority()
	game.queue_free()
	await frames()
	print("THEATER_LENS: %d checks; %d failures" % [checks,failures])
	quit(1 if failures else 0)
