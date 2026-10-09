extends SceneTree
## Fixed-start native input replay for before/after review. Not full progression.
const Fixture=preload("res://tests/canteen_native_fixture.gd")
const Metrics=preload("res://scripts/player_metrics.gd")
var world:Control
var samples:Array=[]
var failures:=0
func _initialize()->void:call_deferred("run")
func key(code:int,pressed:bool)->void:
	var event:=InputEventKey.new();event.keycode=code;event.physical_keycode=code;event.pressed=pressed;Input.parse_input_event(event)
func run()->void:
	var state:Node=root.get_node("State");Fixture.install(state)
	var portrait:bool=OS.get_environment("CANTEEN_OCCLUSION_PORTRAIT")=="1"
	root.size=Vector2i(390,844) if portrait else Vector2i(960,600)
	world=load("res://scripts/world.gd").new();world.size=root.size;root.add_child(world);await process_frame;world.set_process(false)
	world.player=Vector2(616,325);world._sync_player();world.transition_alpha=0
	var folder:=OS.get_environment("CANTEEN_OCCLUSION_REPLAY_DIR")
	if folder.is_empty():push_error("CANTEEN_OCCLUSION_REPLAY_DIR is required");quit(1);return
	if DirAccess.make_dir_recursive_absolute(folder)!=OK:
		push_error("Cannot create replay directory: "+folder);await finish(1);return
	for frame in range(36):
		if frame==4:key(KEY_S,true)
		if frame==12:key(KEY_S,false)
		if frame==20:key(KEY_W,true)
		if frame==28:key(KEY_W,false)
		var process_start:int=Time.get_ticks_usec()
		world._process(1.0/20.0)
		var process_us:int=Time.get_ticks_usec()-process_start
		world.camera=Vector2(647,333);world.zoom=2.0 if portrait else 2.0
		var configure_start:int=Time.get_ticks_usec()
		world.native_canteen.configure_view(world.size/2-world.camera*world.zoom,world.zoom,world.player)
		var configure_us:int=Time.get_ticks_usec()-configure_start
		world.queue_redraw();await process_frame;await RenderingServer.frame_post_draw
		var legal:bool=world.can_stand(world.player)
		if not legal:failures+=1
		samples.append({"frame":frame,"simulation_ms":frame*1000.0/20.0,"player":[world.player.x,world.player.y],"foot_bottom":Metrics.foot_rect(world.player).end.y,"legal":legal,"process_us":process_us,"configure_us":configure_us,"draw_calls":Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME),"nodes":get_node_count()})
		if root.get_texture().get_image().save_png(folder.path_join("frame_%03d.png"%frame))!=OK:
			push_error("Cannot save replay frame; stopping capture");await finish(1);return
	key(KEY_S,false);key(KEY_W,false)
	var file:=FileAccess.open(folder.path_join("frames.json"),FileAccess.WRITE)
	if file==null:
		push_error("Cannot save replay report; stopping capture");await finish(1);return
	file.store_string(JSON.stringify({"fixture":true,"source":"Godot viewport after real InputEventKey + World._process","portrait":portrait,"simulation_fps":20,"failures":failures,"samples":samples},"\t"));file.close()
	print("CANTEEN_OCCLUSION_REPLAY ",samples.size()," frames; ",failures," failures")
	await finish(1 if failures else 0)
func finish(code:int)->void:
	key(KEY_S,false);key(KEY_W,false)
	world.queue_free();await process_frame;quit(code)
