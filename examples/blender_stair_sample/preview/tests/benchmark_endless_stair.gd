extends SceneTree
const View=preload("res://tests/benchmark_endless_stair_view.gd")
var game
var ready_to_measure:=false
var last_usec:=0
var elapsed_frames: Array[float]=[]
var draw_calls: Array[float]=[]
var rendered_objects: Array[float]=[]
var render_primitives: Array[float]=[]
var process_ms: Array[float]=[]
var physics_ms: Array[float]=[]
var start_usec:=0
var warmup_usec:=0
func _initialize() -> void: start.call_deferred()
func start() -> void:
	DirAccess.make_dir_recursive_absolute("user://endless_stair_b3")
	root.size=Vector2i(1280,720)
	root.position=Vector2i(40,120)
	game=View.new()
	root.add_child(game)
	await process_frame
	game.demo_mode=true
	game.capture_frames.clear()
	game._start()
	last_usec=Time.get_ticks_usec()
	start_usec=last_usec
	ready_to_measure=true
func stats(values: Array[float]) -> Dictionary:
	if values.is_empty():return {}
	var a:=values.duplicate();a.sort()
	var total:=0.0
	for n in a:total+=n
	return {"count":a.size(),"min":a[0],"p50":a[int(a.size()*.5)],"p95":a[mini(a.size()-1,int(a.size()*.95))],"p99":a[mini(a.size()-1,int(a.size()*.99))],"max":a[-1],"mean":total/a.size()}
func _process(_delta: float) -> bool:
	if not ready_to_measure:return false
	var now:=Time.get_ticks_usec()
	if game.model.tick>=120:
		if warmup_usec==0:warmup_usec=now
		else:
			elapsed_frames.append(float(now-last_usec)/1000.0)
			draw_calls.append(Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME))
			rendered_objects.append(Performance.get_monitor(Performance.RENDER_TOTAL_OBJECTS_IN_FRAME))
			render_primitives.append(Performance.get_monitor(Performance.RENDER_TOTAL_PRIMITIVES_IN_FRAME))
			process_ms.append(Performance.get_monitor(Performance.TIME_PROCESS)*1000.0)
			physics_ms.append(Performance.get_monitor(Performance.TIME_PHYSICS_PROCESS)*1000.0)
	last_usec=now
	if game.model.tick>=1500 or game.model.status!="running":
		ready_to_measure=false
		var result={"recording":false,"fixed_fps":false,"resolution":[root.size.x,root.size.y],"renderer":RenderingServer.get_video_adapter_name(),"physics_hz":Engine.physics_ticks_per_second,"physics_ticks":game.model.tick,"status":game.model.status,"wall_seconds":float(now-start_usec)/1000000,"measured_wall_seconds":float(now-warmup_usec)/1000000,"frame_ms":stats(elapsed_frames),"present_usec":stats(game.present_usec),"physics_usec":stats(game.physics_usec),"draw_calls":stats(draw_calls),"rendered_objects":stats(rendered_objects),"primitives":stats(render_primitives),"process_ms":stats(process_ms),"physics_process_ms":stats(physics_ms),"node_count":Performance.get_monitor(Performance.OBJECT_NODE_COUNT),"object_count":Performance.get_monitor(Performance.OBJECT_COUNT),"video_memory_bytes":Performance.get_monitor(Performance.RENDER_VIDEO_MEM_USED)}
		result["reveal_usec"]=stats(game.reveal_usec)
		result["broadphase_usec"]=stats(game.broadphase_usec)
		result["beam_usec"]=stats(game.beam_usec)
		result["measured_fps"]=elapsed_frames.size()/maxf(.001,float(now-warmup_usec)/1000000)
		var file:=FileAccess.open("user://endless_stair_b3/runtime_benchmark.json",FileAccess.WRITE)
		file.store_string(JSON.stringify(result,"  "))
		print("B_RUNTIME_BENCHMARK ",JSON.stringify(result))
		quit()
	return false
