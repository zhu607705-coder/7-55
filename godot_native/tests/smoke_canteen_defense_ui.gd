extends SceneTree
const Game=preload("res://scripts/games/canteen_defense.gd")
const Model=preload("res://scripts/games/canteen_defense_model.gd")
var failures: int=0
var received: Dictionary={}
func check(ok: bool,message: String) -> void:
	if ok: print("PASS ",message)
	else:
		failures+=1
		push_error(message)
func _initialize() -> void: call_deferred("run")
func run() -> void:
	var game: Control=Game.new()
	game.size=Vector2(960,540)
	root.add_child(game)
	game.setup({"seed":"1","session_id":"smoke-defense"})
	await process_frame
	game.set_process(false)
	game.finished.connect(func(result: Dictionary): received=result)
	check(not game.running and game.start_button.visible,"Defense waits for actual start")
	game.begin()
	var fixture: Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://tests/fixtures/canteen_defense.json"))
	for tick: int in range(fixture.inputs.size()):
		var input: Dictionary=fixture.inputs[tick]
		game.touch_direction=Vector2(input.x,input.y)
		game.dash_requested=input.dash
		if tick==90:
			var before: Vector2=game.model.player
			var velocity: Vector2=game.model.velocity
			game.toggle_pause()
			game._process(2)
			check(game.model.player==before and game.model.velocity==velocity,"Pause freezes position without unrecorded velocity mutation")
			game.begin()
			game.touch_direction=Vector2(input.x,input.y)
			game.dash_requested=input.dash
		game._process(1.0/60.0)
	check(game.model.status=="won","Real host input path survives60seconds")
	game._process(1)
	check(received.get("session_id")=="smoke-defense","Terminal callback preserves authorized session")
	check(Model.validate_result(received,"1"),"Paused/resumed host result still replays exactly")
	game.queue_free()
	await process_frame
	print("DEFENSE UI FAILURES ",failures)
	quit(1 if failures else 0)
