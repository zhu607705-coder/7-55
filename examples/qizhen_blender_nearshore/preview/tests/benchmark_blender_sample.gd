extends SceneTree
var view: Node2D
var frames: int=0
var started: int=0
var timings: Array[float]=[]
func _initialize() -> void:call_deferred("start")
func start() -> void:
 view=load("res://scenes/blender_lake_sample.tscn").instantiate();root.add_child(view);view.title_open=false;view.auto_control=true;view.test_thrust=true;view.test_turn=.16
func _process(dt: float) -> bool:
 if view==null:return false
 frames+=1
 if frames==30:started=Time.get_ticks_usec()
 if frames>30:timings.append(dt)
 if frames==330:
  var seconds: float=(Time.get_ticks_usec()-started)/1000000.0;timings.sort()
  var result: Dictionary={"renderer":"Godot 4.6.3 compatibility / Mesa llvmpipe software rasterizer","size":[1280,720],"measured_frames":300,"wall_seconds":seconds,"mean_fps":300/seconds,"p95_frame_ms":timings[int(timings.size()*.95)]*1000,"fixed_fps_capture":false,"mobile_hardware_tested":false,"environment_glb_draw_groups":view.environment_glb.get_child_count(),"two_live_subviewports":true}
  var f:=FileAccess.open("res://../verification/runtime-benchmark.json",FileAccess.WRITE);f.store_string(JSON.stringify(result,"  "));print("BENCHMARK ",JSON.stringify(result));quit()
 return false
