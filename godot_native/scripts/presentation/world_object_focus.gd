extends Node
## Temporary camera ownership for inspecting a physical object. No player,
## collision, inventory, checkpoint or progression writes occur here.
signal finished
var world: Control
var panel: Control
var read_state: Callable
var bound_state: Dictionary = {}
var scene_id := ""
var phase := "idle"
var amount := 0.0
var original_camera := Vector2.ZERO
var original_pan := Vector2.ZERO
var original_zoom := 1.0
var focus_camera := Vector2.ZERO
var focus_zoom := 1.0
var original_size := Vector2.ZERO
var reduced := false
var motion: Tween
var focus_paused := false

func setup(world_ref: Control, panel_ref: Control, reader: Callable, bounds: Rect2) -> void:
	world=world_ref;panel=panel_ref;read_state=reader;bound_state=reader.call()
	scene_id=world.scene_id;original_camera=world.camera;original_zoom=world.zoom
	original_pan=world.pan_offset;original_size=world.size
	reduced=bool(bound_state.native.get("settings",{}).get("reduced_motion",false))
	focus_zoom=original_zoom*1.65
	var half: Vector2=world.size/(2.0*focus_zoom)
	focus_camera=bounds.get_center().clamp(half,world.world_size-half)
	world.cancel_exploration_gestures();world.move_target=Vector2.INF;world.touch_axis=Vector2.ZERO
	phase="entering";_set_amount(0)
	if reduced:_set_amount(1);phase="inside";return
	motion=create_tween()
	motion.tween_method(_set_amount,0.0,1.0,.72).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
	motion.tween_callback(func(): phase="inside";motion=null)

func apply_owned_camera() -> bool:
	if phase=="idle" or not is_instance_valid(world):return false
	world.camera=original_camera.lerp(focus_camera,amount)
	world.zoom=lerpf(original_zoom,focus_zoom,amount)
	return true

func _set_amount(value: float) -> void:
	amount=value
	apply_owned_camera()
	if is_instance_valid(world):world.queue_redraw()
	if is_instance_valid(panel):
		var opacity: float=smoothstep(.38,.96,value)
		panel.modulate.a=opacity
		if panel.has_method("set_transition_ready"):panel.set_transition_ready(value>=.999 and phase!="leaving")

func request_close(immediate := false) -> void:
	if phase in ["idle","leaving"] and not immediate:return
	if motion!=null:motion.kill();motion=null
	if immediate or reduced or not _same_context():_finish();return
	phase="leaving"
	if is_instance_valid(panel) and panel.has_method("set_transition_ready"):panel.set_transition_ready(false)
	motion=create_tween()
	motion.tween_method(_set_amount,amount,0.0,.45).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
	motion.tween_callback(_finish)

func _same_context() -> bool:
	if not is_instance_valid(world) or not read_state.is_valid():return false
	var s: Dictionary=read_state.call()
	return is_same(s,bound_state) and world.scene_id==scene_id and str(s.native.scene)==scene_id

func _process(_delta: float) -> void:
	if phase=="idle":return
	if not _same_context() or not is_instance_valid(panel):request_close(true);return
	if not reduced and bool(bound_state.native.get("settings",{}).get("reduced_motion",false)):
		reduced=true
		if phase=="leaving":request_close(true);return
		if motion!=null:motion.kill();motion=null
		_set_amount(1);phase="inside"
	if str(bound_state.get("runtimeMode",""))!="rpg" or str(bound_state.native.mode)!="light" or world.size!=original_size:
		request_close(true);return
	if not world.is_visible_in_tree() or (is_instance_valid(world.host_node) and not world.host_node.world_frame.is_visible_in_tree()):request_close(true);return
	if DisplayServer.get_name()!="headless" and phase in ["entering","leaving"] and motion!=null and motion.is_valid():
		if not get_window().has_focus():motion.pause();focus_paused=true
		elif focus_paused:focus_paused=false;motion.play()

func _restore() -> void:
	if not _same_context():return
	world.zoom=original_zoom;world.pan_offset=original_pan
	world.camera=original_camera
	if world.size!=original_size:world._update_camera()
	world.queue_redraw()

func _finish() -> void:
	if motion!=null:motion.kill();motion=null
	phase="idle";_restore();finished.emit();queue_free()

func _exit_tree() -> void:
	if motion!=null:motion.kill();motion=null
	phase="idle";_restore()
