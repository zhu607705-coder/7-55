extends SceneTree
## A disposable checkpoint preview of the actual world and original interactions.
## Launch through run.mjs so this sample cannot read or overwrite a formal save.
var preview_world:Control
var capture_key_was_down:=false
var capture_index:=0
func _initialize()->void:run.call_deferred()
func run()->void:
	if not preload("res://tests/native_test_isolation.gd").is_isolated_save():
		printerr("Launch through samples/north_independent_props/run.mjs; a disposable save profile is required.");quit(2);return
	var state:Node=root.get_node("State");state.developer_mode=true
	state.begin_checkpoint("c4-755-classrooms-1850")
	state.d.chapter4.mode="light";state.d.native.mode="light"
	state.d.native.positions={"duan_yongping_temporal_maze:A1":{"x":1406,"y":590}}
	var shell:Control=load("res://scenes/main.tscn").instantiate();root.add_child(shell)
	await process_frame;await process_frame
	shell.mobile_world=true;shell._refresh();shell._layout()
	var world:Control=shell.world
	if not world.north_objects.active or not world.north_props.active:
		printerr("NORTH_PROP_PREVIEW_BLOCKED: complete real generated art is required: "+str(world.north_objects.issues));quit(2);return
	preview_world=world
	world.player=Vector2(1406,590)
	world._sync_player();world._update_camera();world.queue_redraw()
	print("NORTH_PROP_PREVIEW: actual 105 classroom; WASD/arrows and Space. Disposable DEV checkpoint, not campaign completion.")

func _process(_delta:float)->bool:
	var down:=Input.is_physical_key_pressed(KEY_F8)
	if down and not capture_key_was_down and is_instance_valid(preview_world):capture.call_deferred()
	capture_key_was_down=down
	return false

func capture()->void:
	var output:=OS.get_environment("NORTH_PROP_PLAY_CAPTURE_DIR")
	if output.is_empty() or DisplayServer.get_name()=="headless":return
	DirAccess.make_dir_recursive_absolute(output)
	await RenderingServer.frame_post_draw
	var pixels:=root.get_texture().get_image()
	if pixels==null or pixels.is_empty():return
	capture_index+=1
	var name:="play-%02d"%capture_index
	pixels.save_png(output.path_join(name+".png"))
	var state:Node=root.get_node("State")
	var evidence:={"source":"actual native viewport + actual current controller state","preview":"isolated DEV checkpoint, not earned campaign progression","player":[preview_world.player.x,preview_world.player.y],"scene":preview_world.scene_id,"generatedObjects":preview_world.north_objects.snapshot(),"lecternReplayChecked":state.d.chapter4.factIds.has("classroom_105_terminal_replay_checked")}
	var file:=FileAccess.open(output.path_join(name+".json"),FileAccess.WRITE);file.store_string(JSON.stringify(evidence,"  "));file.close()
	print("NORTH_PROP_PLAY_CAPTURE: "+output.path_join(name+".png"))
