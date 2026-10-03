extends Control
signal cinematic_started
## One runtime-only presentation owner. World moves/collides first (priority 0),
## then this host samples its authoritative position (priority 50).
const OpeningView=preload("res://scripts/presentation/c3_opening_view.gd")
const PaperView=preload("res://scripts/presentation/c3_canteen_paper_view.gd")
var world: Control
var read_state: Callable
var request_session: Callable
var dispatch: Callable
var cue: Callable
var runtime_reader: Callable
var current: RefCounted
var opening: Control
var paper: Control
var completion_sent: bool=false
var return_camera:=Vector2.INF
var entry_camera:=Vector2.INF
var last_scene: String=""
func setup(world_view: Control,state_reader: Callable,provider: Callable,action_sink: Callable,cue_sink: Callable=Callable(),runtime_state_reader: Callable=Callable()) -> void:
	world=world_view; read_state=state_reader; request_session=provider; dispatch=action_sink; cue=cue_sink; runtime_reader=runtime_state_reader
	process_priority=50; mouse_filter=Control.MOUSE_FILTER_IGNORE
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	opening=OpeningView.new(); add_child(opening)
	opening.advance.connect(_advance); opening.skip.connect(_skip)
	paper=PaperView.new(); paper.world=world; world.add_child(paper)
func owns_world_contract() -> bool:
	return current!=null and (current.kind=="opening" or current.status in ["playing","complete"])
func blocks_world_input() -> bool:
	return current!=null and (current.kind=="opening" or current.status=="playing")
func _host_context() -> Dictionary:
	var data: Dictionary=runtime_reader.call() if runtime_reader.is_valid() else read_state.call()
	return data.get("native",{}).get("host",{})
func _process(delta: float) -> void:
	if not is_visible_in_tree(): return
	if not read_state.is_valid() or not request_session.is_valid(): return
	var host: Dictionary=_host_context()
	var focused: bool=bool(host.get("focused",true))
	tick(delta*1000,focused)
func tick(delta_ms: float,focused: bool=true) -> void:
	if not read_state.is_valid() or not is_instance_valid(world): return
	paper.display_scale=float(_host_context().get("world_display_scale",1.0))
	var s: Dictionary=read_state.call()
	var scene: String=str(s.get("native",{}).get("scene",""))
	if scene!=last_scene:
		if is_instance_valid(paper): paper.reset()
		last_scene=scene
	if current!=null and not current.valid(s): reset()
	if current==null and request_session.is_valid() and world.scene_id==scene:
		var issued: Variant=request_session.call()
		if issued!=null and issued.attach(s,self):
			current=issued; completion_sent=false; return_camera=Vector2.INF; entry_camera=Vector2.INF
			if current.kind=="opening": opening.session=current; opening.tick(); opening.move_to_front(); move_to_front()
			else: paper.session=current
	if current==null:
		if focused and is_instance_valid(paper): paper.tick(minf(delta_ms,100))
		return
	current.frame(s,delta_ms,self,focused)
	if current.kind=="canteen":
		var host: Dictionary=_host_context()
		var available: bool=focused and not host.get("phone_modal_open",false) and not host.get("minigame_open",false) and host.get("world_visible",true) and not s.get("ui",{}).get("controlCenterOpen",false)
		if current.post_collision(s,world.player,self,available):
			world.move_target=Vector2.INF; world.touch_axis=Vector2.ZERO; world.walk_clock=0
			# Main restores the canonical viewport synchronously before sampling
			# the discovery camera; portrait bounds must not enter the source shot.
			world.zoom=1.18
			cinematic_started.emit()
			# The synchronous layout also changes the paper HUD's physical scale.
			paper.display_scale=float(_host_context().get("world_display_scale",1.0))
			world._update_camera()
			entry_camera=world.camera
		_apply_camera()
		if focused: paper.tick(minf(delta_ms,100))
	else: opening.tick()
	_flush_cues()
	if current.status=="complete" and not completion_sent:
		completion_sent=true
		var completed: RefCounted=current
		var kind: String=completed.kind
		dispatch.call("lib_opening_complete" if kind=="opening" else "c3_entry_paper_complete",completed)
		if completed.status!="consumed":
			reset(); return
		if kind=="canteen":
			paper.tail_lines=completed.prompt_lines.duplicate(); paper.tail_ms=0; paper.tail_reduced=completed.reduced_motion
			paper.session=null; world.zoom=1.0; world._update_camera(); world.queue_redraw()
			if cue.is_valid(): cue.call("canteen_entry_paper_escape_completed",{})
		else:
			opening.session=null; opening.visible=false
			if cue.is_valid():
				cue.call("chapter_three_opening_completed",{"destination":"campus_library_gate"})
				cue.call("chapter_three_canteen_hunt_unlocked",{"objective":"追到东区大食堂"})
		current=null
func _apply_camera() -> void:
	if current==null or current.kind!="canteen": return
	var pose: Dictionary=current.camera_pose()
	if current.status=="waiting":
		world.zoom=1.18; world._update_camera(); world.queue_redraw(); return
	var target: Vector2=pose.target
	if current.elapsed_ms<current.route_start_ms and entry_camera!=Vector2.INF:
		var focus:=Vector2(lerpf(current.trigger_paper.x,current.trigger_player.x,0.24),lerpf(current.trigger_paper.y,current.trigger_player.y,0.38))
		var ratio: float=clampf(current.elapsed_ms/(120 if current.reduced_motion else 520),0,1)
		target=entry_camera.lerp(focus,(1-cos(ratio*PI))/2)
	elif pose.get("followPaper",false):
		# Source camera follow has a 100x68 deadzone and 0.075 smoothing.
		var offset: Vector2=target-world.camera
		var follow: Vector2=world.camera
		for axis in range(2):
			var half: float=(50.0 if axis==0 else 34.0)/world.zoom
			if absf(offset[axis])>half: follow[axis]+=signf(offset[axis])*(absf(offset[axis])-half)*0.075
		target=follow
	elif pose.get("returning",false):
		if return_camera==Vector2.INF: return_camera=world.camera
		var p: float=clampf((current.elapsed_ms-current.escape_end_ms-(100 if current.reduced_motion else 500))/(160 if current.reduced_motion else 720),0,1)
		target=return_camera.lerp(current.trigger_player,(1-cos(p*PI))/2)
	world.zoom=float(pose.zoom)
	var half: Vector2=Vector2(480,270)/world.zoom
	world.camera=Vector2(clampf(target.x,half.x,maxf(half.x,world.world_size.x-half.x)),clampf(target.y,half.y,maxf(half.y,world.world_size.y-half.y)))
	world.queue_redraw()
func _flush_cues() -> void:
	if current==null: return
	for event: Dictionary in current.take_cues():
		if cue.is_valid(): cue.call(event.id,event.payload)
func _advance() -> void:
	if current!=null:
		current.advance_current(read_state.call(),self)
		tick(0,bool(_host_context().get("focused",true)))
func _skip() -> void:
	if current!=null:
		current.skip_to_arrival(read_state.call(),self); opening.tick(); _flush_cues()
func reset() -> void:
	if current!=null:
		if current.kind=="canteen" and is_instance_valid(world) and world.scene_id=="canteen_interior":
			world.zoom=1.0; world._update_camera(); world.queue_redraw()
		current.cancel()
	current=null; completion_sent=false; return_camera=Vector2.INF; entry_camera=Vector2.INF
	if is_instance_valid(opening): opening.session=null; opening.visible=false
	if is_instance_valid(paper): paper.reset()
func _exit_tree() -> void:
	reset()
	if is_instance_valid(paper): paper.queue_free()
