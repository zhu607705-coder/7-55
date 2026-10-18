extends SceneTree
## Native 60 Hz rendering with ordinary input dispatch. No model coordinates,
## art, physics, story state or time scale are changed by this replay.
const View = preload("res://scripts/presentation/chapter4_endless_stair_view.gd")
var game
var started := false
var completing := false
var frames := 0
var limit_ticks := 1920
var portrait := false
var old_jump := false
var held_key: Key = KEY_D
var capture_dir := ""
var event_log: Array = []
var pause_x := 0.0
func _initialize() -> void: start.call_deferred()
func dispatch(event: InputEvent) -> void:
	Input.parse_input_event(event)
	Input.flush_buffered_events()
func key(code: Key, pressed: bool) -> void:
	var e := InputEventKey.new(); e.keycode=code; e.physical_keycode=code; e.pressed=pressed
	dispatch(e)
func touch(index: int, point: Vector2, pressed: bool) -> void:
	var e := InputEventScreenTouch.new(); e.index=index; e.position=point; e.pressed=pressed
	dispatch(e)
func forward_touch_point() -> Vector2:
	var actor_point: Vector2 = game.camera.unproject_position(game.actor.position)
	actor_point *= game.size / Vector2(game.viewport.size)
	var side: float = signf(game.model.route_heading(game.model.player.x).dot(game.camera.global_basis.x))
	return Vector2(clampf(actor_point.x+side*90,10,game.size.x-10),game.size.y*.7)
func start() -> void:
	portrait = "--portrait" in OS.get_cmdline_user_args()
	root.size = Vector2i(390,844) if portrait else Vector2i(1280,720)
	root.position = Vector2i(0,0)
	capture_dir = "user://camera_input_portrait" if portrait else "user://camera_input_landscape"
	DirAccess.make_dir_recursive_absolute(capture_dir)
	game = View.new(); root.add_child(game)
	await process_frame
	game.set_process(false); game.set_physics_process(false)
	game.capture_frames.clear(); game.demo_mode=false; game._start(); game._present(0)
	root.gui_release_focus()
	key(held_key,true)
	event_log.append({"frame":0,"action":"hold keyboard forward across landing turns"})
	started=true
func _process(_delta: float) -> bool:
	if not started or completing: return false
	var m=game.model
	if frames == 300:
		key(held_key,false); pause_x=m.player.x
		event_log.append({"frame":frames,"action":"release keyboard movement"})
	if frames == 306:
		event_log.append({"frame":frames,"action":"six neutral ticks","movement_metres":m.player.x-pause_x})
		held_key=KEY_D if m.route_heading(m.player.x).dot(game.camera.global_basis.x)>0 else KEY_A
		key(held_key,true)
	if frames == 720:
		key(held_key,false)
		touch(31,forward_touch_point(),true)
		event_log.append({"frame":frames,"action":"switch to held primary touch; keep route intent through turns"})
	if old_jump:
		key(KEY_SPACE,false); old_jump=false
	if frames < 300 or frames >= 306:
		if m.reference_input() & m.JUMP:
			if frames < 720:
				key(KEY_SPACE,true); old_jump=true
			else:
				touch(32,game.size*.5,true); touch(32,game.size*.5,false)
			event_log.append({"frame":frames,"action":"jump via " + ("Space" if frames<720 else "second touch")})
	game._physics_process(1.0/60)
	game._present(1.0/60)
	frames+=1
	if frames in [1,330,465,780,960,1260,1740,1918]: save_frame.call_deferred(frames)
	if frames>=limit_ticks or m.status!="running":
		completing=true
		var result={"viewport":[root.size.x,root.size.y],"ticks":m.tick,"status":m.status,"frames":frames,"duration_seconds":float(frames)/60,"events":event_log,"input":"synthetic keyboard and multi-touch events dispatched to the original view; native offline 60 Hz MovieWriter, not human play or a realtime FPS measurement"}
		FileAccess.open(capture_dir+"/capture.json",FileAccess.WRITE).store_string(JSON.stringify(result,"  "))
		print("CAMERA_INPUT_CAPTURE ",JSON.stringify(result))
		finish.call_deferred()
	return false
func save_frame(frame: int) -> void:
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(capture_dir+"/frame_%04d.png"%frame)
func finish() -> void:
	await RenderingServer.frame_post_draw
	var failed: bool=game.model.status=="failed"
	game.rhythm_feedback.pause_audio(); game.queue_free()
	await process_frame
	quit(1 if failed else 0)
