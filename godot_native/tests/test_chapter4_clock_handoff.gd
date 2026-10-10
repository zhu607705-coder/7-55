extends SceneTree
const Chapter=preload("res://scripts/chapters/chapter4.gd")
const Effect=preload("res://scripts/ui/chapter4_world_handoff.gd")
const Layers=preload("res://scripts/ui/chapter4_world_layers.gd")
var checks: int=0
var failures: int=0
var state: Dictionary={}
var controller: RefCounted
var events: Array=[]
func check(ok: bool,label: String) -> void:
	checks+=1
	if not ok: failures+=1; push_error(label)
func _initialize() -> void: call_deferred("run")
func fresh() -> Dictionary:
	var s: Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://data/initial_state.json"))
	s.native={"chapter":4,"scene":"duan_yongping_temporal_maze","player":{"x":1001,"y":214},"settings":{}}
	s.chapter4.prologueSeen=true; s.chapter4.phase="maintenance_repair"; s.chapter4.timeState="2245_maintenance"; s.chapter4.floor="A1"; s.chapter4.mode="light"; s.chapter4.factIds=["clock_gear_repaired"]; s.items.attendanceRecordPaper=true
	return s
func begin(holder: Control) -> Control:
	var request: Dictionary=controller.dispatch(state,"c4_final_drag")
	check(request.has("world_effect") and request.world_effect.kind=="clock_drag","Clock interaction stays on original world and source endpoint")
	var effect: Control=Effect.new(); holder.add_child(effect); effect.set_process(false)
	var config: Dictionary=request.world_effect.duplicate(true)
	config.read_state=func(): return state
	config.project_position=func(p): return Vector2(480,160)+(p-Vector2(996,63))*0.85
	effect.event.connect(func(action,value): events.append({"action":action,"value":value}); controller.dispatch(state,action,value))
	effect.setup(config); return effect
func run() -> void:
	controller=Chapter.new(); state=fresh(); var holder: Control=Control.new(); holder.size=Vector2(960,540); root.add_child(holder)
	var effect: Control=begin(holder)
	for i in 30: effect._process(0.05)
	check(effect.elapsed_ms==0 and not effect.clock_started and state.items.attendanceRecordPaper,"Waiting on clock never advances or steals paper without actual input")
	var center: Vector2=effect.project_position.call(effect._clock_endpoint(effect.clock_angle))
	var down: InputEventMouseButton=InputEventMouseButton.new(); down.button_index=MOUSE_BUTTON_LEFT; down.position=center; down.pressed=true; effect._gui_input(down)
	check(effect.clock_dragging and not effect.clock_started,"Pointer grabs actual rendered endpoint before transaction")
	var cancelled: InputEventMouseButton=InputEventMouseButton.new(); cancelled.button_index=MOUSE_BUTTON_LEFT; cancelled.position=center; cancelled.pressed=false; cancelled.canceled=true; effect._gui_input(cancelled)
	await process_frame
	check(state.items.attendanceRecordPaper and controller.pending.is_empty() and Layers.presentation.is_empty(),"Cancelled pointer restores clock/paper and releases nonce")
	effect=begin(holder); down.position=effect.project_position.call(effect._clock_endpoint(effect.clock_angle)); effect._gui_input(down)
	var motion: InputEventMouseMotion=InputEventMouseMotion.new(); motion.position=effect.project_position.call(effect._clock_endpoint(240)); effect._gui_input(motion)
	check(effect.clock_started and effect.elapsed_ms==0,"Real endpoint motion within original tolerance starts source sequence")
	for i in 13: effect._process(0.05)
	check(state.items.attendanceRecordPaper and effect.elapsed_ms==650,"Paper remains owned before authored680ms flight")
	for i in 7: effect._process(0.05); effect.queue_redraw(); await process_frame
	check(state.items.attendanceRecordPaper and state.chapter4.phase=="maintenance_repair","1040ms commit boundary is not advanced early")
	effect._process(0.04); await process_frame
	check(not state.items.attendanceRecordPaper and state.chapter4.phase=="blackout_light_grid","Original minute theft commits after actual input and1040ms world sequence")
	check(events.back().action=="c4_minute_stolen" and events.back().value.dragged and events.back().value.elapsedMs>=1040,"In-world terminal supplies input and time proof to controller")
	state=fresh(); effect=begin(holder)
	var key: InputEventKey=InputEventKey.new(); key.keycode=KEY_SPACE; key.pressed=true; effect._unhandled_key_input(key)
	check(effect.clock_started,"Keyboard activates source clock gesture without a synthetic minigame result")
	effect.cancel(); await process_frame
	check(state.items.attendanceRecordPaper and state.chapter4.phase=="maintenance_repair","Cancellation during theft presentation cannot consume story evidence")
	holder.queue_free(); await process_frame
	print("CHAPTER4_CLOCK_HANDOFF_TESTS ",checks," checks; ",failures," failures")
	quit(1 if failures else 0)
