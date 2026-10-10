extends SceneTree
var failures:=0
func check(value: bool,label: String) -> void:
	if not value: failures+=1; push_error("TEST FAILED: "+label)
func _initialize() -> void: _run.call_deferred()
func _run() -> void:
	if not OS.get_user_data_dir().begins_with("/tmp/"): quit(1); return
	var state=root.get_node("State"); state.developer_mode=true
	var shell=load("res://scenes/main.tscn").instantiate(); root.add_child(shell); await process_frame
	state.begin_checkpoint("c3-qizhen-swan-chase"); shell._refresh(); shell.mobile_world=true; shell._layout()
	# Identify source chase checkpoint without relying on a guessed historical id.
	if state.d.qizhenLake.phase!="swan_chase":
		for checkpoint: Dictionary in state.developer_checkpoints():
			if checkpoint.state.qizhenLake.phase=="swan_chase": state.begin_checkpoint(checkpoint.id); break
		shell._refresh(); shell.mobile_world=true; shell._layout()
	check(state.d.qizhenLake.phase=="swan_chase","source chase checkpoint available for isolated reload regression")
	shell.world.player=Vector2(620,680); shell.world.kayak.position=shell.world.player; shell.world._sync_player()
	var path:="user://reload-boundary.json"
	check(state.export_save(path)==OK,"source-valid chase snapshot exports")
	var result: Dictionary=state.import_save(path); await process_frame; await process_frame
	check(result.ok,"native chase reload succeeds")
	check(shell.world.player==Vector2(1280,680),"import starts original safe channel checkpoint, not prior in-memory midpoint")
	check(shell.world.kayak.position==shell.world.player,"renderer/model share rehydrated safe position")
	await shell.shutdown(); shell.queue_free(); await process_frame
	print("Lake reload boundary failures: ",failures)
	quit(1 if failures else 0)
