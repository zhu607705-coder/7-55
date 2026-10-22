extends SceneTree
const Driver=preload("res://tests/sample_route_driver.gd")
var view: Node2D
var driver: RefCounted
var frame: int=0
var held: Dictionary={}
var trace: FileAccess
var evidence: String
var started_at: int
var previous_position:=Vector2.ZERO
var previous_heading: float=0
var maximum_frame_distance: float=0
var maximum_frame_turn: float=0
var state_jumps: int=0
var previous_progress: int=0
func _initialize() -> void:
 evidence=ProjectSettings.globalize_path("res://../outputs/")
 for a in OS.get_cmdline_user_args():
  if a.begins_with("--evidence-dir="):evidence=a.trim_prefix("--evidence-dir=").trim_suffix("/")+"/"
 DirAccess.make_dir_recursive_absolute(evidence);call_deferred("start")
func key(code: int,value: bool) -> void:
 if held.get(code,false)==value:return
 held[code]=value;var e:=InputEventKey.new();e.keycode=code;e.pressed=value;Input.parse_input_event(e)
func touch(id: int,p: Vector2,down: bool) -> void:
 var e:=InputEventScreenTouch.new();e.index=id;e.position=p;e.pressed=down;Input.parse_input_event(e)
func start() -> void:
 view=load("res://scenes/blender_lake_sample.tscn").instantiate();root.add_child(view);view.set_process(false);view.capture_mode=true
 driver=Driver.new();previous_position=view.game.position;previous_heading=view.game.heading;trace=FileAccess.open(evidence+"input-trace.jsonl",FileAccess.WRITE);started_at=Time.get_ticks_msec()
func _process(_dt: float) -> bool:
 if view==null:return false
 frame+=1
 if frame==1:key(KEY_ENTER,true);key(KEY_ENTER,false)
 if frame>=31 and view.game.status=="running":
  driver.control(view.game)
  # Keyboard propulsion/brake/use plus continuous touch direction.
  if view.touch_left==-1:touch(1,Vector2(145,530),true)
  var e:=InputEventScreenDrag.new();e.index=1;e.position=Vector2(145,530)+Vector2.from_angle(view.game.heading+driver.turn*.65)*70;Input.parse_input_event(e)
  key(KEY_W,driver.throttle);key(KEY_S,driver.brake);key(KEY_E,driver.use)
 else:
  key(KEY_W,false);key(KEY_S,false);key(KEY_E,false)
  if view.touch_left!=-1:touch(1,Vector2(145,530),false)
 view._process(1.0/30)
 maximum_frame_distance=maxf(maximum_frame_distance,view.game.position.distance_to(previous_position))
 maximum_frame_turn=maxf(maximum_frame_turn,absf(angle_difference(previous_heading,view.game.heading)))
 if view.game.progress-previous_progress not in [0,1]:state_jumps+=1
 previous_position=view.game.position;previous_heading=view.game.heading;previous_progress=view.game.progress
 if frame%15==0:trace.store_line(JSON.stringify({"frame":frame,"keys":held,"touch_turn":view.touch_vector,"state":view.game.result()}))
 if frame in [25,180,230,430,580,610]:call_deferred("snapshot",frame)
 if frame>=720:
  trace.flush()
  var result: Dictionary={"frames":frame,"fps":30,"video_seconds":24,"render_seconds":(Time.get_ticks_msec()-started_at)/1000.0,"input_only":true,"no_teleports":maximum_frame_distance<=9.6 and maximum_frame_turn<=.051 and state_jumps==0,"maximum_frame_distance":maximum_frame_distance,"maximum_frame_turn_radians":maximum_frame_turn,"invalid_progress_jumps":state_jumps,"native_godot_renderer":true,"result":view.game.result(),"rig_accepted":view.rig.motion.accepted_intents,"rig_started":view.rig.motion.started_strokes,"actual_glb_environment":view.environment_glb!=null,"actual_glb_boat":view.boat_3d!=null}
  var file:=FileAccess.open(evidence+"capture-result.json",FileAccess.WRITE);file.store_string(JSON.stringify(result,"  "));print("NATIVE_SAMPLE_CAPTURE ",JSON.stringify(result));quit(0 if view.game.status=="won" else 1)
 return false
func snapshot(n: int) -> void:
 await RenderingServer.frame_post_draw
 root.get_texture().get_image().save_png(evidence+"sample-%04d.png"%n)
