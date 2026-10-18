extends SceneTree
## 20 s native Godot MovieWriter output. Synthetic ordinary keyboard input.
## Two 60 Hz physics ticks per offline 30 fps video frame. No time-scale changes.
const View=preload("res://scripts/presentation/chapter4_endless_stair_view.gd")
var v
var started=false
var ending=false
var frames=0
var pass_index=1
var finished_frame=-1
var old_jump=false
var events=[]
var max_draw_calls=0.0
var max_render_primitives=0.0
var max_video_mem=0.0
func _initialize():start.call_deferred()
func key(code:Key,pressed:bool):
 var e=InputEventKey.new();e.keycode=code;e.physical_keycode=code;e.pressed=pressed
 Input.parse_input_event(e);Input.flush_buffered_events()
func start():
 root.size=Vector2i(1280,720);root.position=Vector2i(0,0)
 v=View.new();root.add_child(v);await process_frame
 v.set_process(false);v.set_physics_process(false);v.capture_frames.clear();v.demo_mode=false
 v._start();v._present(0);root.gui_release_focus();key(KEY_D,true)
 # Keep the ordinary game corner label; recording metadata is saved separately.
 DirAccess.make_dir_recursive_absolute("user://recording");started=true
func _process(_delta):
 if not started or ending:return false
 if finished_frame>=0 and frames-finished_frame>=24:
  key(KEY_D,false);key(KEY_SPACE,false);old_jump=false;v._start();v._present(0);key(KEY_D,true)
  pass_index+=1;finished_frame=-1
  events.append({"frame":frames,"action":"restart second ordinary-input replay"})
 for substep in 2:
  if v.model.status!="running":break
  if old_jump:key(KEY_SPACE,false);old_jump=false
  if v.model.reference_input() & v.model.JUMP:
   key(KEY_SPACE,true);old_jump=true
   events.append({"frame":frames,"tick":v.model.tick,"pass":pass_index,"action":"Space key jump"})
  v._physics_process(1.0/60);v._present(1.0/60)
  if v.model.status!="running":
   finished_frame=frames;key(KEY_D,false);key(KEY_SPACE,false)
   events.append({"frame":frames,"tick":v.model.tick,"pass":pass_index,"status":v.model.status,"proof_valid":v.model.validate_proof(v.model.proof())})
 frames+=1
 max_draw_calls=maxf(max_draw_calls,Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME))
 max_render_primitives=maxf(max_render_primitives,Performance.get_monitor(Performance.RENDER_TOTAL_PRIMITIVES_IN_FRAME))
 max_video_mem=maxf(max_video_mem,Performance.get_monitor(Performance.RENDER_VIDEO_MEM_USED))
 if frames in [76,166,233,286,301,306,340,599]:save_frame.call_deferred(frames)
 if frames>=600:
  ending=true
  var result={"frames":frames,"requested_duration_s":20,"offline_movie_fps":30,"physics_hz":60,"viewport":[1280,720],"subviewport":[v.viewport.size.x,v.viewport.size.y],"input":"Synthetic D and Space events via Input.parse_input_event; no coordinate overrides, no speed changes, no human input","events":events,"passes":"one full clear, 0.8 s result menu, then second partial replay","renderer":"Godot 4.6.3 Compatibility / Mesa llvmpipe software renderer","max_draw_calls_observed":max_draw_calls,"max_primitives_observed":max_render_primitives,"max_video_mem_bytes_observed":max_video_mem,"fps_claim":"Offline MovieWriter cadence only; not real-time device performance"}
  FileAccess.open("user://recording/capture.json",FileAccess.WRITE).store_string(JSON.stringify(result,"  "))
  print("BLENDER_RECORDING ",JSON.stringify(result));finish.call_deferred()
 return false
func save_frame(frame):
 await RenderingServer.frame_post_draw
 root.get_texture().get_image().save_png("user://recording/frame_%04d.png"%frame)
func finish():
 await RenderingServer.frame_post_draw
 key(KEY_D,false);key(KEY_SPACE,false);v.rhythm_feedback.pause_audio();v.queue_free()
 await process_frame;quit()
