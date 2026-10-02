extends "res://tests/test_virtual_run_controls.gd"
## Drives the real copied/unmodified chapter authority with actual UI proof.
const Controller = preload("res://scripts/chapters/chapter1_2.gd")
var controller = Controller.new()
var state: Dictionary
var authority_calls := 0

func initial_state() -> void:
	controller = Controller.new()
	state = JSON.parse_string(FileAccess.get_file_as_string("res://data/initial_state.json"))
	state.native = {"chapter":2,"page":"tiyi","scene":"dorm_hub","mode":"light","selected_item":""}
	state.networkMode = "cellular"
	state.actOne.phase = "movement_required"
	state.actOne.characterNamed = true
	state.actOne.identityVerified = true
	state.actOne.inventoryRecovered = true
	state.actOne.exerciseStarted = false
	authority_calls = 0

func submit(result: Dictionary) -> void:
	authority_calls += 1
	controller.dispatch(state,"c2_exercise_result",result)
	game.resolve(bool(state.actOne.exerciseStarted))

func run() -> void:
	initial_state()
	var opened: Dictionary = controller.dispatch(state,"c2_exercise")
	check(opened.get("game",{}).get("script","") == "res://scripts/games/virtual_run.gd","existing authority still opens authored run")
	await spawn(Vector2i(390,844))
	game.finished.connect(submit)
	for i in range(9): await mouse_click(game.target)
	check(not state.actOne.exerciseStarted and authority_calls == 0,"nine actual presses never reach authority")
	await mouse_click(game.target)
	check(authority_calls == 1 and state.actOne.exerciseStarted,"tenth press immediately submits unchanged proof to real authority")
	check(game.accepted and game.return_button.visible,"authoritative response alone enables success presentation")
	await mouse_click(game.return_button)
	check(state.actOne.exerciseStarted and authority_calls == 1 and cancels == 1,"return does not resubmit or roll back authoritative progress")
	initial_state()
	await spawn(Vector2i(430,860))
	game.finished.connect(submit)
	for i in range(9): await mouse_click(game.target)
	state.actOne.characterNamed = false
	await mouse_click(game.target)
	check(authority_calls == 1 and not state.actOne.exerciseStarted,"lost identity rejects submitted proof in unchanged controller")
	check(game.completed == 9 and not game.accepted and not game.return_button.visible,"real rejection returns to ninth point without success UI")
	await mouse_click(game.target)
	check(authority_calls == 2 and not state.actOne.exerciseStarted and game.completed == 9,"genuine retry cannot bypass lost identity")
	await mouse_click(game.exit_button)
	check(cancels == 1 and not state.actOne.exerciseStarted,"rejected exit preserves incomplete story")
	for changed: Dictionary in [{"points":9},{"distanceMeters":2999},{"elapsedSeconds":599},{"failed":true}]:
		initial_state()
		var proof := {"failed":false,"points":10,"elapsedSeconds":600,"distanceMeters":3000}
		proof.merge(changed,true)
		controller.dispatch(state,"c2_exercise_result",proof)
		check(not state.actOne.exerciseStarted,"controller still rejects incorrect result: "+str(changed))
	game.queue_free()
	await frames()
	print("VIRTUAL_RUN_AUTHORITY: %d checks; %d failures" % [checks,failures])
	quit(1 if failures else 0)
