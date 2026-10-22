extends SceneTree
const Host=preload("res://scripts/ui/minigame_host.gd")
var failures: int=0
func check(ok: bool,message: String) -> void:
	if ok: print("PASS ",message)
	else:
		push_error(message)
		failures+=1
func _initialize() -> void: call_deferred("run")
func run() -> void:
	for mode: String in ["chase","rhythm","kayak"]:
		var host: Control=Host.new()
		host.size=Vector2(960,540)
		root.add_child(host)
		host.setup({"type":mode,"phase":"boarding","goal":4,"spotId":"locker_key","session_id":"ui-test"})
		await process_frame
		await process_frame
		check(not host.running and host.start_button.visible,"UI "+mode+" opens without simulation")
		host.begin()
		host.press_action("left","test")
		await process_frame
		host.release_action("left","test")
		host.toggle_pause()
		var at: float=host.model.elapsed
		host._process(1)
		check(host.paused and host.model.elapsed==at,"UI "+mode+" pause freezes simulation clock")
		host.begin()
		host.restart()
		check(not host.running and host.start_button.visible,"UI "+mode+" retry resets to a real start")
		if mode=="chase":
			host.model.status="lost"
			host.begin()
			check(host.running and host.model.status=="running","Keyboard restart replaces terminal chase model")
		if mode=="rhythm":
			host.model.phase="failed"
			host.begin()
			check(host.running and host.model.phase=="idle","Keyboard restart replaces failed fishing model")
		host.queue_free()
		await process_frame
	print("MINIGAME UI FAILURES: ",failures)
	quit(1 if failures else 0)
