extends SceneTree
const View = preload("res://scripts/games/progressive_transport.gd")
const Model = preload("res://scripts/games/progressive_transport_model.gd")
const POWER = ["right","right","right","up","right","right","right","continue","down","right","right","up","left","up","right","right","up","right","right","right","continue","down","right","right","right","up","left","up","left","up","right","right","up","right","right","right","right"]
var checks := 0
var failures := 0
var game: Control
var delivered: Array = []
var cancellations := 0

func _initialize() -> void:
	_run.call_deferred()

func check(ok: bool, message: String) -> void:
	checks += 1
	print("PASS " if ok else "FAIL ",message)
	if not ok: failures += 1

func frames(n: int = 2) -> void:
	for i: int in n: await process_frame

func key(code: int, pressed: bool, echo: bool = false) -> void:
	var e := InputEventKey.new()
	e.physical_keycode = code
	e.pressed = pressed
	e.echo = echo
	Input.parse_input_event(e)
	await frames()

func tap(code: int) -> void:
	await key(code,true)
	await key(code,false)

func click(button: Button) -> void:
	var point := button.get_global_rect().get_center()
	var motion := InputEventMouseMotion.new()
	motion.position = point
	motion.global_position = point
	Input.parse_input_event(motion)
	for pressed: bool in [true,false]:
		var e := InputEventMouseButton.new()
		e.button_index = MOUSE_BUTTON_LEFT
		e.position = point
		e.global_position = point
		e.pressed = pressed
		Input.parse_input_event(e)
		await frames()

func touch(point: Vector2, pressed: bool, canceled: bool = false) -> void:
	var e := InputEventScreenTouch.new()
	e.index = 0
	e.position = point
	e.pressed = pressed
	e.canceled = canceled
	Input.parse_input_event(e)
	await frames()

func fresh(id: String = "power_topology") -> void:
	if is_instance_valid(game):
		game.queue_free()
		await frames()
	game = View.new()
	root.add_child(game)
	game.setup({"puzzleId":id,"session":{"id":7,"nonce":"ui-owned-session","puzzleId":id}})
	game.configure_activity_layout(Vector2(root.size),false)
	game.completed.connect(func(value): delivered.append(value.duplicate(true)))
	game.cancelled.connect(func(): cancellations += 1)
	await frames()

func _run() -> void:
	root.size = Vector2i(1280,720)
	await fresh()
	check(game.state.valid and not game.state.complete,"ordinary configured model starts without a completion")
	check(not game.controls.TransportContinue.visible,"Continue is absent before an actual exit")
	var initial: Dictionary = game.state.actor.duplicate(true)
	await tap(KEY_ENTER)
	check(game.model.proof().actions.is_empty() and delivered.is_empty(),"Enter and an idle presentation cannot grant an action or proof")
	await key(KEY_RIGHT,true)
	var first_count: int = game.state.actionsCount
	await key(KEY_RIGHT,true,true)
	check(first_count==1 and game.state.actionsCount==1,"one physical press moves once and key repeat cannot auto-play a route")
	await key(KEY_RIGHT,false)
	await tap(KEY_Z)
	check(game.state.actor==initial and not game.state.complete,"real undo returns the actor without granting completion")
	await click(game.controls.TransportHelp)
	check(game.help_open and game.reading_panel.visible and game.help_tier==1,"actual Help opens only the first optional observation")
	var frozen: Dictionary = game.model.proof()
	await tap(KEY_RIGHT)
	check(game.model.proof()==frozen,"movement is stopped while reading Help")
	if game.reading_next.visible:
		await click(game.reading_next)
		check(game.help_tier==2 and game.model.proof()==frozen,"requesting another hint changes no model action or progress")
	game.notification(NOTIFICATION_APPLICATION_FOCUS_OUT)
	game.notification(NOTIFICATION_APPLICATION_FOCUS_OUT)
	check(game.paused and game.help_open,"repeated focus loss during Help cannot silently resume gameplay")
	await click(game.reading_close)
	check(not game.paused and not game.help_open,"an explicit visible return restores input")
	await click(game.controls.TransportPause)
	await tap(KEY_RIGHT)
	check(game.paused and game.model.proof()==frozen,"Pause blocks actual directional input without changing proof")
	await click(game.reading_close)
	game.hide()
	await frames()
	game.show()
	await tap(KEY_RIGHT)
	check(game.paused and game.model.proof()==frozen,"hidden activities remain paused after showing until explicit resume")
	await click(game.reading_close)
	await fresh()
	for action: String in POWER:
		if action=="continue":
			check(game.state.stageComplete and not game.state.complete,"intermediate board requires its real exit before Continue")
			await click(game.controls.TransportContinue)
			check(not game.state.stageComplete and delivered.is_empty(),"Continue opens the next board and never submits a partial exercise")
			if game.state.stageIndex==2:
				for extent: Vector2i in [Vector2i(390,844),Vector2i(430,860)]:
					root.size = extent
					game.configure_activity_layout(Vector2(extent),true)
					await frames()
					var card: Rect2 = game.circuit_card.get_rect()
					check(game.circuit_card.visible and card.size.x>=300 and card.size.y==130 and game.CIRCUIT_FONT_SIZE>=13,"portrait circuit card uses readable native pixels: "+str(extent))
					check(Rect2(Vector2.ZERO,Vector2(extent)).encloses(card) and card.position.y>=game.controls.TransportPause.get_rect().end.y+8,"portrait graph stays in bounds below feedback and handoff controls: "+str(extent))
					var separate := not card.intersects(game.field)
					for id: String in ["TransportUp","TransportDown","TransportLeft","TransportRight","TransportUndo","TransportRestart","TransportHelp"]:
						separate = separate and not card.intersects(game.controls[id].get_rect())
					check(separate,"portrait graph never covers the world or action hit areas: "+str(extent))
					check(game.objective_label.visible and game.objective_label.text==game.state.objective and game.status_label.text=="第 3 / 3 拍 · 当前连接 0 / 7" and not game.help_open,"default portrait HUD keeps one task objective and actual connections without duplicate prose or expected answers: "+str(extent))
				root.size = Vector2i(390,844)
				game.configure_activity_layout(Vector2(root.size),true)
		else:
			await tap({"right":KEY_RIGHT,"left":KEY_LEFT,"up":KEY_UP,"down":KEY_DOWN}[action])
	check(game.state.complete and game.state.stageComplete,"real directional input reaches all three actual exits")
	check(game.status_label.text=="第 3 / 3 拍 · 当前连接 5 / 7","portrait readout follows the five actually connected edges after ordinary moves")
	check(delivered.is_empty(),"the final exit waits for explicit handoff rather than an animation timer")
	await click(game.controls.TransportContinue)
	check(delivered.size()==1 and delivered[0].session.nonce=="ui-owned-session","final visible submit emits one proof with the issued session unchanged")
	if delivered.size()==1:
		var result: Dictionary = Model.replay(delivered[0].puzzleId,delivered[0].actions)
		check(result.valid and result.completed and delivered[0].keys().size()==4,"delivered proof independently replays and carries no caller answer or completion flag")
	await click(game.controls.TransportContinue)
	await tap(KEY_RIGHT)
	check(delivered.size()==1,"repeat submit and later inputs cannot emit a second result")
	root.size = Vector2i(390,844)
	await fresh("lake_logistics")
	await touch(Vector2(2,2),true)
	await touch(Vector2(2,2),false)
	check(game.controls.TransportRight.visible,"real coarse input exposes the anchored directional controls")
	check(is_equal_approx(game.field.size.x/game.field.size.y,16.0/9.0),"portrait presentation preserves the complete 960 by 540 world ratio")
	for id: String in ["TransportRight","TransportLeft","TransportUp","TransportDown","TransportUndo","TransportRestart","TransportHelp","TransportExit"]:
		var button: Button = game.controls[id]
		check(Rect2(Vector2.ZERO,Vector2(root.size)).encloses(button.get_rect()) and button.size.x>=44 and button.size.y>=44,"touch target stays anchored, in bounds and at least44px: "+id)
	var point: Vector2 = game.controls.TransportRight.get_global_rect().get_center()
	await touch(point,true)
	print("TOUCH_DIAGNOSTIC_PRESS ",JSON.stringify({"point":point,"owner":game.pointer_id,"button":str(game.touch_button.name) if is_instance_valid(game.touch_button) else "none","paused":game.paused,"count":game.state.actionsCount,"viewport":root.get_visible_rect(),"game_rect":game.get_global_rect()}))
	await touch(point,false)
	print("TOUCH_DIAGNOSTIC_RELEASE ",JSON.stringify({"owner":game.pointer_id,"paused":game.paused,"count":game.state.actionsCount,"actor":game.state.actor}))
	check(game.state.actionsCount==1,"one actual touch click applies exactly one grid move")
	await touch(point,true)
	await touch(point,false,true)
	check(game.state.actionsCount==1,"canceled touch cannot apply a move")
	await touch(game.controls.TransportHelp.get_global_rect().get_center(),true)
	await touch(game.controls.TransportHelp.get_global_rect().get_center(),false)
	check(game.help_open,"touch can open Help using the rendered button")
	await touch(game.reading_close.get_global_rect().get_center(),true)
	await touch(game.reading_close.get_global_rect().get_center(),false)
	check(not game.help_open,"touch can close the reading panel without moving the boat")
	root.size = Vector2i(844,390)
	game.configure_activity_layout(Vector2(root.size),true)
	check(game.field.size.y>=380 and is_equal_approx(game.field.size.x/game.field.size.y,16.0/9.0),"short landscape keeps the world full height rather than a narrow phone strip")
	for id: String in game.controls:
		var button: Button = game.controls[id]
		if button.visible: check(Rect2(Vector2.ZERO,Vector2(root.size)).encloses(button.get_rect()),"landscape visible control remains inside the activity: "+id)
	game.dispose_presentation()
	await tap(KEY_RIGHT)
	check(game.state.actionsCount==1,"disposing the activity retires input without a submitted proof")
	await fresh("evacuation_route")
	await click(game.controls.TransportExit)
	await click(game.controls.TransportExit)
	check(cancellations==1 and delivered.size()==1,"explicit Exit cancels exactly once and never submits a route")
	game.queue_free()
	await frames()
	print("PROGRESSIVE_UI_RESULT ",JSON.stringify({"checks":checks,"failures":failures,"passed":failures==0}))
	quit(0 if failures==0 else 1)
