extends SceneTree
## Real rendered-window benchmark; scripted input workload, not a manual play proof.
var view: Control
var start: int
var last: int
var times: Array[float]=[]
var process_ms: Array[float]=[]
var draw_calls: Array[float]=[]
var events: Array=[]
var input_index: int=0
var phases: Dictionary={}
var measured: bool=false
func _initialize() -> void:call_deferred("run")
func run() -> void:
	root.size=Vector2i(1180,812)
	view=load("res://scenes/qizhen_playable_chase.tscn").instantiate();root.add_child(view)
	events=JSON.parse_string(FileAccess.get_file_as_string("res://tests/fixtures/playable_upper_manual_input.json")).inputs
	start=Time.get_ticks_usec();last=start
func _process(_dt: float) -> bool:
	if view==null:return false
	var now: int=Time.get_ticks_usec()
	var wall: float=(now-start)/1000000.0
	if wall>=3 and not measured:
		view.restart(true);measured=true
	if measured:
		while input_index<events.size() and float(events[input_index].time)<=view.game.elapsed:
			view.stroke(events[input_index].side,bool(events[input_index].reverse));input_index+=1
		times.append((now-last)/1000.0)
		process_ms.append(Performance.get_monitor(Performance.TIME_PROCESS)*1000.0)
		draw_calls.append(Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME))
		phases[view.game.swan_phase]=true
	last=now
	if wall>=25:
		var result: Dictionary={"mode":"native_window_no_recording","workload":"scripted real-time stroke injection; not manual play evidence","resolution":[root.size.x,root.size.y],"seconds":wall-3,"frames":times.size(),"frame_ms":summary(times),"process_ms":summary(process_ms),"draw_calls":summary(draw_calls),"renderer":RenderingServer.get_video_adapter_name(),"vendor":RenderingServer.get_video_adapter_vendor(),"fps_cap":Engine.max_fps,"vsync_mode":DisplayServer.window_get_vsync_mode(),"movie_writer":false,"fixed_fps":false,"swan_phases_observed":phases.keys(),"outcome":view.game.outcome,"elapsed":view.game.elapsed,"inputs":view.game.accepted_inputs.size(),"guarantees_device_60fps":false}
		result.draw_calls.erase("over_16_667ms")
		var filename: String=OS.get_environment("CHASE_BENCH_OUTPUT")
		if not filename.is_empty():
			var f=FileAccess.open(filename,FileAccess.WRITE);f.store_string(JSON.stringify(result,"  "))
		print("CHASE_BENCHMARK ",JSON.stringify(result));quit()
	return false
func summary(values: Array[float]) -> Dictionary:
	values.sort();var total: float=0;var over: int=0
	for v: float in values:
		total+=v
		if v>16.667:over+=1
	return {"mean":total/values.size(),"p50":values[int(values.size()*.50)],"p95":values[int(values.size()*.95)],"p99":values[int(values.size()*.99)],"max":values[-1],"over_16_667ms":over}
