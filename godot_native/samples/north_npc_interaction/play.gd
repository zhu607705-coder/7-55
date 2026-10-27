extends SceneTree
## Actual formal world, actor, keyboard/touch input and original controller reply.
## Only the starting checkpoint is developer supplied; saves are disposable.
var world:Control
var shell:Control
var state:Node
var checks:=0
var failures:=0

func _initialize()->void:run.call_deferred()
func check(ok:bool,label:String)->void:
	checks+=1
	if not ok:failures+=1;push_error("NPC_PREVIEW: "+label)

func key(code:Key,pressed:bool)->void:
	var event:=InputEventKey.new()
	event.keycode=code;event.physical_keycode=code;event.pressed=pressed
	Input.parse_input_event(event)
	await process_frame

func touch_teacher()->void:
	await RenderingServer.frame_post_draw
	var point:=Vector2.INF
	# Use a visible painted pixel selected by the actual world picker.
	for y in range(532,574,3):
		for x in range(1356,1388,3):
			var hit:Dictionary=world._pick_target(Vector2(x,y))
			if str(hit.get("id",""))=="a3_reference_teacher":
				point=Vector2(x,y);break
		if point.is_finite():break
	check(point.is_finite(),"teacher has visible touchable sprite pixels")
	if not point.is_finite():return
	var local:Vector2=(point-world.camera)*world.zoom+world.size/2
	var pixel:Vector2=world.get_global_transform_with_canvas()*local
	var screen:Vector2=shell.world_view.get_global_transform_with_canvas()*(pixel*shell.world_view.size/Vector2(shell.world_viewport.size))
	var down:=InputEventScreenTouch.new();down.index=0;down.position=screen;down.pressed=true
	Input.parse_input_event(down);await process_frame
	var up:=InputEventScreenTouch.new();up.index=0;up.position=screen;up.pressed=false
	Input.parse_input_event(up);await process_frame

func capture(name:String)->void:
	var output:=OS.get_environment("NPC_PREVIEW_CAPTURE_DIR")
	if output.is_empty() or DisplayServer.get_name()=="headless":return
	DirAccess.make_dir_recursive_absolute(output)
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(output.path_join(name+".png"))
	var evidence:={"source":"actual native world/player/NPC/controller","checkpoint":"disposable DEV checkpoint, not earned campaign progression","player":[world.player.x,world.player.y],"nearby":world.nearby.get("id",""),"subtitle":world.subtitle,"npcResponses":world.chapter4_layers.phases.npc_interaction_motion.responses,"floor":state.d.chapter4.floor,"facts":state.d.chapter4.factIds}
	var file:=FileAccess.open(output.path_join(name+".json"),FileAccess.WRITE)
	file.store_string(JSON.stringify(evidence,"  "));file.close()

func run()->void:
	if not preload("res://tests/native_test_isolation.gd").is_isolated_save():
		printerr("Use samples/north_npc_interaction/run.mjs; an isolated save is required.");quit(2);return
	state=root.get_node("State");state.developer_mode=true
	state.begin_checkpoint("c4-755-room204-1850")
	state.d.chapter4.mode="light";state.d.native.mode="light"
	state.d.native.positions={"duan_yongping_temporal_maze:A3":{"x":1190,"y":540}}
	shell=load("res://scenes/main.tscn").instantiate();root.add_child(shell)
	await process_frame;await process_frame
	shell.mobile_world=true;shell._refresh();shell._layout()
	world=shell.world
	world.player=Vector2(1190,540);world._sync_player()
	world.zoom=1.25;world.pan_offset=Vector2.ZERO;world._update_camera();world.queue_redraw()
	root.grab_focus();world.grab_focus()
	check(world.can_stand(world.player),"start uses clear classroom aisle")
	check(world.targets.any(func(target):return str(target.id)=="a3_reference_teacher"),"original teacher target is active")
	print("NPC_PREVIEW: actual A3 teacher; WASD/arrows to approach, Space to talk. Isolated DEV checkpoint.")
	if not OS.get_cmdline_user_args().has("--demo"):return
	await create_timer(.8).timeout
	await capture("npc-before")
	var start:Vector2=world.player
	await key(KEY_D,true);await create_timer(.8).timeout;await key(KEY_D,false)
	await create_timer(.3).timeout
	check(world.player.distance_to(start)>80,"ordinary keyboard input approaches teacher")
	check(str(world.nearby.get("id",""))=="a3_reference_teacher","Space selects actual nearby teacher")
	var facts:Array=state.d.chapter4.factIds.duplicate()
	if OS.get_cmdline_user_args().has("--touch"):
		await touch_teacher()
	else:
		await key(KEY_SPACE,true);await key(KEY_SPACE,false)
	await create_timer(.16).timeout
	check(world.chapter4_layers.phases.npc_interaction_motion.responses.has("a3_reference_teacher"),"original interaction starts NPC response")
	check(not world.subtitle.is_empty(),"original teacher reply is displayed")
	check(state.d.chapter4.factIds==facts,"conversation cannot award puzzle facts")
	await capture("npc-speaking")
	await create_timer(3.2).timeout
	await key(KEY_A,true);await create_timer(.8).timeout;await key(KEY_A,false)
	await create_timer(2.5).timeout
	check(world.chapter4_layers.phases.npc_interaction_motion.responses.is_empty(),"finished reply returns to idle")
	await capture("npc-after")
	print("NPC_PREVIEW: %d checks, %d failures"%[checks,failures])
	quit(1 if failures else 0)
