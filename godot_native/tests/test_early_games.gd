extends SceneTree
const Interception = preload("res://scripts/games/prologue_interception.gd")
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
	tick(game,3.3)
	check(game.phase == "blackout","error and red flash lead to blackout")
	tick(game,6.7)
	check(game.phase == "blackout","seven-second blackout cannot be skipped")
	tick(game,.5)
	check(game.phase == "deploy","blackout leads to same error-window board")
	game._switch("intercept")
	for i in range(3):
		game.paddle = 79 if i == 0 else 21
		if game.blocks == 0: game.paddle = 79
		tick(game,2.3)
		tick(game,.7)
	check(game.phase == "failed" and game.misses == 3,"three misses enter retry")
	game._retry()
	check(game.phase == "deploy" and game.misses == 0,"retry skips blackout and resets misses")
	tick(game,1.6)
	for end_x in [24,78,50]:
		game.paddle = end_x
		while game.phase == "intercept": game._process(.02)
		tick(game,.4)
	check(game.phase == "lock" and game.blocks == 3,"three actual path interceptions unlock hold")
	game.holding = true
	tick(game,1.0)
	game._pointer(Vector2.ZERO,false)
	check(game.hold_ms == 0 and game.phase == "lock","early pointer release resets hold")
	game.holding = true
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
	for i in range(9): run._point()
	check(runs.is_empty(),"partial virtual run cannot complete")
	run._point()
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
	check(stamps.size()==1 and stamps[0].identityChecks==[false,false,false],"stamp supplies evidence result")
	stamp.queue_free()
	print("EARLY_GAMES_TESTS: %d passed; %d failed" % [passed,failed])
	quit(1 if failed else 0)
