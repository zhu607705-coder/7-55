extends "res://tests/test_virtual_run_controls.gd"
## Requires the actual Main scene and State autoload. The isolated integration
## snapshot includes them; no story controller or phone-page edits are used.
var shell: Control
var state_node: Node

func prepare(view: Vector2i) -> void:
	# Each direct State.d replacement is a separate fixture. Tear down its
	# presentation owner too: the previous success has a real180ms text cue,
	# which otherwise leaks into the next fixture's zero-point game.
	if is_instance_valid(shell):
		if is_instance_valid(shell.active_game):
			await mouse_click(shell.active_game.exit_button)
		await shell.shutdown()
		shell.queue_free()
		await frames(3)
	state_node.d = state_node.initial()
	state_node.d.native.chapter = 2
	state_node.d.native.page = "tiyi"
	state_node.d.native.scene = "dorm_hub"
	state_node.d.networkMode = "cellular"
	state_node.d.actOne.phase = "movement_required"
	state_node.d.actOne.characterNamed = true
	state_node.d.actOne.identityVerified = true
	state_node.d.actOne.inventoryRecovered = true
	state_node.d.actOne.exerciseStarted = false
	root.size = view
	shell = load("res://scenes/main.tscn").instantiate()
	root.add_child(shell)
	shell.size = Vector2(view)
	shell._refresh()
	await frames(4)
	state_node.act("c2_exercise")
	await frames(3)
	game = shell.active_game
	check(is_instance_valid(game),"ordinary exercise authority mounts the native run")

func run() -> void:
	state_node = root.get_node("State")
	state_node.developer_mode = true
	for view: Vector2i in [Vector2i(390,844),Vector2i(430,860)]:
		await prepare(view)
		var attempt := game
		for i in range(9): await mouse_click(game.target)
		check(not state_node.d.actOne.exerciseStarted and shell.active_game == attempt,"nine real controls retain an incomplete mounted attempt")
		await mouse_click(game.target)
		check(state_node.d.actOne.exerciseStarted,"Main submits tenth control proof immediately")
		check(is_instance_valid(attempt) and shell.active_game == attempt and attempt.accepted,"Main retains the exact accepted game instance")
		check(attempt.return_button.visible and attempt.completed == 10,"retained result exposes explicit return with all ten fixes")
		check(shell.toast.text.is_empty() and not shell.toast.visible,"generic result toast cannot cover retained result controls")
		# Also observe the source's real delayed cue while its result is still
		# mounted. This waits only in the test; gameplay adds no delay.
		var cue_deadline := Time.get_ticks_msec()+2000
		while shell.audio_director.scheduled.any(func(cue: Dictionary): return cue.id == "act2_exercise_started") and Time.get_ticks_msec() < cue_deadline:
			await process_frame
		check(shell.audio_director.last_subtitle.get("text","") == "锻炼记录已同步。" and shell.toast.text.is_empty(),"authored180ms result cue is delivered and remains scene-owned")
		shell.audio_director.subtitle_timed.emit("锻炼记录已同步。","toast",3600.0,"task")
		check(shell.toast.text.is_empty(),"late AudioDirector result subtitle remains scene-owned")
		shell._feedback("电量仅剩 1%，请寻找现场充电服务站。")
		var notice: String = shell.toast.text
		var notice_duration: float = shell.toast_time
		shell.audio_director.subtitle_timed.emit("锻炼记录已同步。","toast",2400.0,"task")
		check(shell.toast.text == notice and shell.toast.visible and shell.toast_time == notice_duration,"late result cue neither erases nor retimes an unrelated notice")
		# Clear this test-only injected notice before testing the return control.
		shell.toast.text = ""; shell.toast.hide(); shell.toast_time = 0
		root.size = Vector2i(430,860) if view.x == 390 else Vector2i(390,844)
		shell.size = Vector2(root.size)
		shell._layout()
		await frames(3)
		check(shell.active_game == attempt and attempt.accepted,"resizing accepted Main keeps same result")
		await mouse_click(attempt.return_button)
		check(shell.active_game == null and state_node.d.actOne.exerciseStarted,"actual Return closes once and retains authoritative success")
		await frames(3)
		check(not is_instance_valid(attempt),"completed instance is freed only after explicit return")
		var repeated_open: Dictionary = state_node.act("c2_exercise")
		check(not repeated_open.has("game") and shell.active_game == null,"ordinary completed story cannot open the fresh run used by the next fixture")
	await prepare(Vector2i(390,844))
	for i in range(9): await mouse_click(game.target)
	state_node.d.actOne.characterNamed = false
	var rejected := game
	await mouse_click(game.target)
	check(not state_node.d.actOne.exerciseStarted and shell.active_game == rejected,"rejected proof leaves story incomplete and retains the attempt")
	check(rejected.completed == 9 and not rejected.accepted and "身份失效" in rejected.status.text,"Main passes actual rejection back to ninth point")
	check(shell.toast.text.is_empty(),"rejected game feedback also owns its clear retry/exit message")
	await press_key(KEY_ESCAPE)
	check(shell.active_game == null and not state_node.d.actOne.exerciseStarted,"actual Esc exits rejected run without success")
	await prepare(Vector2i(390,844))
	await mouse_click(game.target)
	await mouse_click(game.exit_button)
	check(shell.active_game == null and not state_node.d.actOne.exerciseStarted,"partial close submits no result")
	state_node.act("c2_exercise")
	await frames(3)
	check(shell.active_game.completed == 0,"ordinary reopening after cancel starts from first point")
	await mouse_click(shell.active_game.exit_button)
	await shell.shutdown()
	shell.queue_free()
	await frames()
	print("VIRTUAL_RUN_MAIN: %d checks; %d failures" % [checks,failures])
	quit(1 if failures else 0)
