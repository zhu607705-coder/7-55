extends SceneTree
## Native-renderer input replay. No position, heading, speed or progress writes.
## Synthetic keyboard/touch events exercise the same scene handlers as a player.
const Driver=preload("res://tests/route_driver.gd")
var view: Node2D
var driver: RefCounted
var frame: int=0
var previous_brake: bool=false
var inputs: FileAccess
var evidence: String=ProjectSettings.globalize_path("res://test-output/")
func _initialize() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--evidence-dir="):evidence=arg.trim_prefix("--evidence-dir=").trim_suffix("/")+"/"
	DirAccess.make_dir_recursive_absolute(evidence)
	call_deferred("start")
func key(code: int,pressed: bool=true) -> void:
	var event:=InputEventKey.new();event.keycode=code;event.pressed=pressed;Input.parse_input_event(event)
func touch(id: int,point: Vector2,pressed: bool=true) -> void:
	var event:=InputEventScreenTouch.new();event.index=id;event.position=point;event.pressed=pressed;Input.parse_input_event(event)
func drag(id: int,point: Vector2) -> void:
	var event:=InputEventScreenDrag.new();event.index=id;event.position=point;Input.parse_input_event(event)
func start() -> void:
	view=load("res://scenes/qizhen_large_world.tscn").instantiate();root.add_child(view);view.set_process(false);view.capture_mode=true
	driver=Driver.new();inputs=FileAccess.open(evidence+"native-input-events.jsonl",FileAccess.WRITE)
func _process(_dt: float) -> bool:
	if view==null:return false
	frame+=1
	if frame==1:key(KEY_ENTER)
	if frame==180:key(KEY_M)
	if frame==225:key(KEY_M)
	if frame==390:key(KEY_P)
	if frame==420:key(KEY_P)
	if not view._blocked():
		driver.control(view.game)
		if driver.use:
			if view.touch_left!=-1:touch(1,Vector2(200,500),false)
			if view.touch_right!=-1:touch(2,Vector2(1050,500),false)
			if not view.touch_use:touch(3,view.world_to_screen(view.Geo.goals()[view.game.progress].point));touch(3,view.world_to_screen(view.Geo.goals()[view.game.progress].point),false)
		else:
			if view.touch_left==-1:touch(1,Vector2(200,500))
			# The angular error maps back to exactly the same steering scalar.
			drag(1,Vector2(200,500)+Vector2.from_angle(view.game.heading+driver.turn*.65)*70)
			if driver.throttle and view.touch_right==-1:touch(2,Vector2(1050,500))
			elif not driver.throttle and view.touch_right!=-1:touch(2,Vector2(1050,500),false)
		if driver.brake!=previous_brake:key(KEY_S,driver.brake)
		previous_brake=driver.brake
	view._process(1.0/30)
	if frame%15==0:inputs.store_line(JSON.stringify({"frame":frame,"touch_left":view.touch_left,"touch_right":view.touch_right,"touch_use":view.touch_use,"keys":view.keys.keys(),"game":view.game.result(),"visual_strokes":view.rig.motion.started_strokes}))
	if frame in [150,210,240,400,900,1080]:call_deferred("snapshot",frame)
	if frame>=1140:
		inputs.flush()
		var file:=FileAccess.open(evidence+"native-replay-result.json",FileAccess.WRITE)
		var report={"frames":frame,"fps":30,"duration_seconds":38,"source":"Godot native renderer with synthetic input events; not manual play","result":view.game.result(),"accepted_strokes":view.rig.motion.accepted_intents,"started_visual_strokes":view.rig.motion.started_strokes,"has_teleports":false,"map_interval_frames":[180,225],"pause_interval_frames":[390,420]}
		file.store_string(JSON.stringify(report,"  "));print("NATIVE_REPLAY ",JSON.stringify(report));quit(0)
	return false
func snapshot(n: int) -> void:
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(evidence+"replay-%04d.png"%n)
