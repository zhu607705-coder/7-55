extends SceneTree
const Metrics=preload("res://scripts/player_metrics.gd")
var world:Control
var checks:=0
var failures:=0
var invalid_frames:=0
var ready_to_audit:=false
func _initialize()->void:run.call_deferred()
func check(ok:bool,label:String)->void:
	checks+=1
	if not ok:failures+=1;push_error("SPACE_REVIEW: "+label)
func _process(_delta:float)->bool:
	if ready_to_audit and is_instance_valid(world) and not world.north_space.allows_foot(Metrics.foot_rect(world.player)):invalid_frames+=1
	return false
func key(code:Key,pressed:bool)->void:
	var event:=InputEventKey.new();event.keycode=code;event.physical_keycode=code;event.pressed=pressed
	Input.parse_input_event(event);await process_frame
func touch_source(point:Vector2)->void:
	var local:Vector2=(point-world.camera)*world.zoom+world.size/2
	var screen:Vector2=world.get_global_transform_with_canvas()*local
	var down:=InputEventScreenTouch.new();down.index=0;down.position=screen;down.pressed=true
	Input.parse_input_event(down);await process_frame
	var up:=InputEventScreenTouch.new();up.index=0;up.position=screen;up.pressed=false
	Input.parse_input_event(up);await process_frame
func capture(label:String)->void:
	var output:=OS.get_environment("NORTH_SPACE_CAPTURE_DIR")
	if output.is_empty() or DisplayServer.get_name()=="headless":return
	DirAccess.make_dir_recursive_absolute(output)
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(output.path_join(label+".png"))
	var state:Node=root.get_node("State")
	var receipt:={"source":"actual native world, collision and depth authorities","save":"isolated developer checkpoint","floor":world._last_floor,"player":[world.player.x,world.player.y],"foot":str(Metrics.foot_rect(world.player)),"groundValid":world.north_space.allows_foot(Metrics.foot_rect(world.player)),"poseValid":world.can_stand(world.player),"invalidFrames":invalid_frames,"space":world.north_space.snapshot(),"chapter":state.d.chapter4}
	var file:=FileAccess.open(output.path_join(label+".json"),FileAccess.WRITE);file.store_string(JSON.stringify(receipt,"  "));file.close()
func run()->void:
	if not preload("res://tests/native_test_isolation.gd").is_isolated_save():
		printerr("Use samples/north_space_review/run.mjs; an isolated save is required.");quit(2);return
	var state:Node=root.get_node("State");state.developer_mode=true;state.begin_checkpoint("c4-755-room204-1850")
	var floor_id:="A3"
	for argument:String in OS.get_cmdline_user_args():
		if argument.begins_with("--floor="):floor_id=argument.trim_prefix("--floor=")
	if floor_id not in ["A1","A2","A3"]:quit(2);return
	state.d.chapter4.floor=floor_id;state.d.chapter4.mode="light";state.d.native.mode="light"
	world=load("res://scripts/world.gd").new();world.size=Vector2(root.size);root.add_child(world)
	var arrival:Dictionary={}
	for floor:Dictionary in world.spec.layout.floors:
		if floor.storyFloor==floor_id:arrival=floor.elevator.arrivalPosition
	world.player=Vector2(arrival.x,arrival.y);world._sync_player();world.transition_alpha=0
	var overview:=OS.get_cmdline_user_args().has("--overview")
	if overview:
		world.capture_mode=true;world.set_process(false)
		world.zoom=minf(world.size.x/world.world_size.x,world.size.y/world.world_size.y);world.camera=world.world_size/2
	else:
		world.zoom=1.25;world._update_camera()
	var overlay:Control=load("res://samples/north_space_review/overlay.gd").new();overlay.world=world;world.add_child(overlay)
	root.grab_focus();world.grab_focus();world.queue_redraw()
	await process_frame;await process_frame;await process_frame
	ready_to_audit=true
	if overview:
		await capture(floor_id.to_lower()+"-space-overview");quit();return
	print("SPACE_REVIEW: actual native world; WASD/arrows and normal touch movement. Complete feet must remain on ground.")
	if not OS.get_cmdline_user_args().has("--demo"):return
	await create_timer(.8).timeout
	var start:Vector2=world.player
	await key(KEY_W,true);await create_timer(1.2).timeout;await key(KEY_W,false)
	var first_contact:Vector2=world.player
	check(first_contact.y<start.y and world.can_stand(first_contact),"walk reaches a valid lift-wall contact")
	await capture("a3-lift-contact")
	await key(KEY_W,true);await create_timer(.8).timeout;await key(KEY_W,false)
	check(world.player.distance_to(first_contact)<.02,"holding up cannot climb onto the lift wall")
	await touch_source(Vector2(850,80));await create_timer(.35).timeout
	check(world.player.distance_to(first_contact)<.02 and world._floor_route.is_empty(),"touching the roof cannot route the player onto it")
	await key(KEY_D,true);await create_timer(.6).timeout;await key(KEY_D,false)
	await key(KEY_W,true);await create_timer(1.0).timeout;await key(KEY_W,false)
	check(world.can_stand(world.player),"side approach remains on legal ground")
	await capture("a3-lift-side-contact")
	await key(KEY_S,true);await create_timer(.7).timeout;await key(KEY_S,false)
	check(world.player.y>first_contact.y+20,"ordinary input can leave the boundary")
	await create_timer(.6).timeout
	check(invalid_frames==0,"every recorded frame keeps full feet on ground")
	await capture("a3-space-final")
	print("SPACE_REVIEW: %d checks, %d failures; %d off-ground frames"%[checks,failures,invalid_frames])
	quit(1 if failures else 0)
