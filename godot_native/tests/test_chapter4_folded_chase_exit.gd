extends SceneTree
## Separate process: success is the canonical exit button ending this process.
## A missing/ineffective standalone close handler reaches the watchdog and fails.
func _initialize() -> void:
	_run.call_deferred()

func _run() -> void:
	var preview = load("res://scenes/chapter4_folded_chase_preview.tscn").instantiate()
	root.add_child(preview)
	current_scene = preview
	preview.set_process(false)
	preview.set_physics_process(false)
	create_timer(2.0).timeout.connect(_failed_exit)
	await process_frame
	var exit_button: Button = preview.menu.get_child(0).get_child(2)
	print("FOLDED_STANDALONE_EXIT: dispatching canonical exit button; watchdog will fail if process remains open")
	exit_button.pressed.emit()

func _failed_exit() -> void:
	push_error("FOLDED_STANDALONE_EXIT: exit button did not close the standalone scene")
	quit(1)
