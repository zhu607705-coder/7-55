extends SceneTree
const Interception = preload("res://scripts/games/prologue_interception.gd")
const SuccessPresentation = preload("res://scripts/ui/checkin_success_view.gd")
const WordDriver=preload("res://tests/prologue_word_driver.gd")
const VirtualRun = preload("res://scripts/games/virtual_run.gd")
const Stamp = preload("res://scripts/games/identity_stamp.gd")
var passed = 0
var failed = 0
func check(value: bool, msg: String) -> void:
	if value: passed += 1
	else:
		failed += 1
		push_error(msg)
func tick(game, seconds: float) -> void:
	for i in range(int(ceil(seconds/.02))): game._process(.02)
func _initialize() -> void: call_deferred("_run")
func _run() -> void:
	var game = Interception.new()
	game.size = Vector2(430,820)
	root.add_child(game)
	game.set_process(false)
	game.start({"resume":false})
	check(game.phase == "success","check-in starts with success stamp")
	tick(game, game.success_view.interruption_time() - .1)
	check(game.phase == "success", "receipt prints until the stamp starts to appear")
	tick(game, .12)
	check(game.phase == "signal_loss", "partial receipt loses its CRT signal")
	tick(game, SuccessPresentation.GLITCH_DURATION)
	check(game.phase == "error", "signal loss enters the original error phase")
	tick(game,1.7)
	check(game.phase == "error","original error is retained before its 1.9-second boundary")
	tick(game,.25)
	check(game.phase == "red","original error advances to the red flash")
	tick(game,.4)
	check(game.phase == "blackout","error and red flash lead to blackout")
	tick(game,6.7)
	check(game.phase == "blackout","seven-second blackout cannot be skipped")
	tick(game,.5)
	check(game.phase == "deploy","blackout leads to same error-window board")
	for index in 3500:
		game._process(.02)
	check(not game.done and game.phase=="intercept" and game.session.phase=="hint" and game.misses>0 and game.blocks==0 and game.session.captures.is_empty(),"missing words waits for explicit retry without an idle pass")
	var stage = game.session.stage
	var previous_misses=game.misses
	tick(game,.1)
	check(game.session.stage==stage and game.session.phase=="hint" and game.misses==previous_misses and game.session.captures.is_empty(),"waiting cannot restart the failed round or grant contacts")
	for down:bool in [true,false]:
		var event=InputEventKey.new();event.keycode=KEY_ENTER;event.physical_keycode=KEY_ENTER;event.pressed=down;root.push_input(event,true)
	game._process(0)
	check(game.phase=="deploy" and game.session.phase=="clue" and game.session.stage==stage and game.blocks==0 and game.session.captures.is_empty(),"root Enter explicitly retries only the failed round without granting proof")
	check(WordDriver.until(game,"lock"),"all six real word contacts complete the three semantic stages")
	check(game.phase == "lock" and game.blocks == 3,"three semantic stages unlock the unchanged hold")
	game._pointer(game.field.position+game._lock_center()*game.display_scale,true)
	tick(game,1.0)
	game._pointer(game.field.position+game._lock_center()*game.display_scale,false)
	check(game.hold_ms == 0 and game.phase == "lock","early pointer release resets hold")
	game._pointer(game.field.position+game._lock_center()*game.display_scale,true)
	tick(game,1.42)
	check(game.phase == "caught" and game.hold_ms >= 1400,"full hold locks narrator")
	var results: Array = []
	game.finished.connect(func(r): results.append(r))
	tick(game,8)
	check(results.is_empty(),"cannot finish before all dialogue")
	tick(game,3)
	check(results.size()==1 and results[0].dialogueCount==4,"full dialogue and burst yield one verified result")
	game.queue_free()
	var run = VirtualRun.new()
	run.size = Vector2(430,820)
	root.add_child(run)
	run.set_process(false)
	var runs: Array = []
	run.finished.connect(func(r): runs.append(r))
	run.start({})
	for i in range(1800):
		run.pointer_id=-1;run.pointer_target=preload("res://tests/helpers/virtual_run_driver.gd").target(run.motion)
		run._step(.05)
		if run.completed==9:break
	check(runs.is_empty(),"partial virtual run cannot complete")
	for i in range(400):
		run.pointer_id=-1;run.pointer_target=preload("res://tests/helpers/virtual_run_driver.gd").target(run.motion)
		run._step(.05)
		if run.pending_result:break
	check(runs.size()==1 and runs[0].distanceMeters==3000,"tenth point yields authored run")
	run.queue_free()
	var stamp = Stamp.new()
	root.add_child(stamp)
	stamp.set_process(false)
	var stamps: Array = []
	stamp.finished.connect(func(r): stamps.append(r))
	stamp._stamp()
	check(stamps.is_empty(),"stamp waits for scan")
	tick(stamp,.74)
	stamp._stamp()
	tick(stamp,1.1)
	check(stamps.size()==1 and stamps[0].identityChecks==[false,false,false],"stamp supplies evidence result")
	stamp.queue_free()
	print("EARLY_GAMES_TESTS: %d passed; %d failed" % [passed,failed])
	quit(1 if failed else 0)
