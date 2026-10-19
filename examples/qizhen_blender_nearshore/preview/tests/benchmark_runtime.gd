extends SceneTree
var view: Node2D
var frames: int=0
var start: int=0
var timings: Array[float]=[]
func _initialize() -> void:call_deferred("begin")
func begin() -> void:
	view=load("res://scenes/qizhen_large_world.tscn").instantiate();root.add_child(view);view.auto_control=true;view.title_open=false;view.test_thrust=true
func _process(dt: float) -> bool:
	if view==null:return false
	frames+=1
	if frames==30:start=Time.get_ticks_usec()
	if frames>30:timings.append(dt)
	if frames==330:
		var duration: float=(Time.get_ticks_usec()-start)/1000000.0
		timings.sort();var result: Dictionary={"renderer":"Godot OpenGL compatibility / cloud llvmpipe","measured_frames":300,"wall_seconds":duration,"mean_fps":300/duration,"p95_frame_ms":timings[int(timings.size()*.95)]*1000,"terrain_cache":"2250x4000 render once, 4x nearest scale"}
		var f:=FileAccess.open("../runtime/performance.json",FileAccess.WRITE);f.store_string(JSON.stringify(result,"  "));print(JSON.stringify(result));quit()
	return false
