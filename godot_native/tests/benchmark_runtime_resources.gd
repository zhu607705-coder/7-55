extends SceneTree
## Performance fixture, not campaign acceptance. Uses the real Main/World scene
## with declared state prerequisites, then samples engine monitors after warmup.
var state: Node
var shell: Control
var rows: Array = []
var output := OS.get_environment("RUNTIME_PERF_REPORT")
var sample_count := 180

func _initialize() -> void: run.call_deferred()

func frames(count: int) -> void:
	for index in range(count): await process_frame

func stats(values: Array) -> Dictionary:
	var ordered := values.duplicate(); ordered.sort()
	var total := 0.0
	for value in ordered: total += float(value)
	return {"samples":ordered.size(),"p50":ordered[int(ordered.size()/2)],"p95":ordered[mini(ordered.size()-1,int(ordered.size()*.95))],"mean":total/maxi(1,ordered.size()),"max":ordered[-1]}

func monitors() -> Dictionary:
	return {"objects":int(Performance.get_monitor(Performance.OBJECT_COUNT)),"nodes":int(Performance.get_monitor(Performance.OBJECT_NODE_COUNT)),"resources":int(Performance.get_monitor(Performance.OBJECT_RESOURCE_COUNT)),"staticBytes":int(Performance.get_monitor(Performance.MEMORY_STATIC)),"textureBytes":int(Performance.get_monitor(Performance.RENDER_TEXTURE_MEM_USED)),"videoBytes":int(Performance.get_monitor(Performance.RENDER_VIDEO_MEM_USED))}

func sample(label: String, setup_usec: int) -> void:
	# Engine monitors publish on a slower interval than process_frame. Keep
	# setup spikes outside the steady-state sample window even at 120 Hz.
	await create_timer(2.1).timeout
	var processes: Array = []; var physics: Array = []; var calls: Array = []; var elapsed: Array = []
	var before := Time.get_ticks_usec()
	for index in range(sample_count):
		await process_frame
		var now := Time.get_ticks_usec()
		elapsed.append(float(now-before)/1000.0); before=now
		processes.append(Performance.get_monitor(Performance.TIME_PROCESS)*1000.0)
		physics.append(Performance.get_monitor(Performance.TIME_PHYSICS_PROCESS)*1000.0)
		calls.append(Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME))
	var world: Control=shell.world
	var residency := {"canteen":is_instance_valid(world.native_canteen),"libraryPlate":world.library_layers.art!=null,"libraryStaff":world.library_layers.staff_art!=null,"room204Instances":world.room204_object.tables.size()}
	rows.append({"label":label,"setupMs":float(setup_usec)/1000.0,"processMs":stats(processes),"physicsMs":stats(physics),"frameIntervalMs":stats(elapsed),"drawCalls":stats(calls),"monitors":monitors(),"residency":residency,"world":world.scene_id,"viewport":[root.size.x,root.size.y]})
	print("RUNTIME_PERF_SAMPLE ",JSON.stringify(rows[-1]))

func fixture(scene: String, page: String, chapter: int) -> void:
	state.story_reset.emit(); state.d=state.initial(); state.developer_mode=false
	state.d.native.merge({"chapter":chapter,"scene":scene,"page":page,"mode":"light"},true)
	state.d.runtimeMode="phone" if chapter==1 else "rpg";state.d.rpgScene=scene
	if chapter==2:
		state.d.actOne.phase="complete";state.d.ui.libraryFinalsPhase="evidence_gathering"
		state.d.ui.libraryFinalsPuzzle.libraryVisitedPoints=["entrance"]
		state.d.native.positions={"library_interior:":{"x":890.0,"y":625.0}}
	if scene=="canteen_interior":
		state.d.canteenHunt.active=true;state.d.canteenHunt.phase="tray_search";state.d.canteenHunt.entryPaperEscaped=true
		state.d.native.positions={"canteen_interior:":{"x":1466.0,"y":608.0}}
	if scene=="qizhen_lake":
		state.d.qizhenLake.merge({"active":true,"phase":"tool_chain","zone":"dock","vehicle":"on_foot","rainSafetyCleared":true,"kayakEquipped":true,"leftPaddleEquipped":true,"rightPaddleEquipped":true,"boardingTutorialCompleted":true},true)
		state.d.native.positions={"qizhen_lake:dock:on_foot":{"x":590.0,"y":870.0}}

func run() -> void:
	if output.is_empty() or not load("res://tests/native_test_isolation.gd").is_isolated_save(): quit(2);return
	if DisplayServer.get_name()!="headless": DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_NO_FOCUS,true)
	root.size=Vector2i(1280,720)
	state=root.get_node("State")
	for spec: Array in [["phone_home","dorm_hub","phone_home",1],["library","library_interior","library",2],["canteen","canteen_interior","c3_canteen",3],["qizhen_dock","qizhen_lake","c3_lake",3]]:
		fixture(spec[1],spec[2],spec[3])
		var began := Time.get_ticks_usec()
		shell=load("res://scenes/main.tscn").instantiate();root.add_child(shell)
		var setup_usec := Time.get_ticks_usec()-began
		if int(spec[3])>1: shell._show_world_mobile()
		await sample(spec[0],setup_usec)
		shell.free();await frames(10)
	var report={"engine":Engine.get_version_info(),"display":DisplayServer.get_name(),"adapter":RenderingServer.get_video_adapter_name(),"debugBuild":OS.is_debug_build(),"scope":"Native Main/World fixture monitoring, 2.1 seconds warmup/180 sampled rendered frames per case. Engine monitor values are interval-published and repeated reads are not independent per-frame CPU timings. This is not a browser, release build, physical-phone or campaign measurement.","rows":rows,"afterCleanup":monitors()}
	var file:=FileAccess.open(output,FileAccess.WRITE);file.store_string(JSON.stringify(report,"\t"));file.close()
	quit()
