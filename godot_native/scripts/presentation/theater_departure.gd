extends Control
## A runtime-only traversal of the original exterior door. The outer host owns
## the existing controller exit request after this presentation completes.
signal completed
signal cancelled(reason:String)
const DESTINATION=Vector2(836,895)
const ACTIVE_TIMEOUT_MS=8000.0
const BLOCKED_TIMEOUT_MS=1200.0
var world:Control
var doors:RefCounted
var read_state:Callable
var owner_state:Dictionary={}
var checkpoint:String=""
var finished:bool=false
var was_cancelled:bool=false
var phase:String="idle"
var elapsed_ms:float=0
var blocked_ms:float=0
var last_player:Vector2
var reduced:bool=false

func setup(world_ref:Control,state_reader:Callable)->bool:
	world=world_ref;read_state=state_reader
	mouse_filter=Control.MOUSE_FILTER_IGNORE
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	if not read_state.is_valid() or not is_instance_valid(world):cancel("missing_world");return false
	owner_state=read_state.call();checkpoint=str(owner_state.get("rpgCheckpoint",""))
	if world.chapter3_layers==null:cancel("missing_door");return false
	doors=world.chapter3_layers.doors
	if not valid_context() or not world.can_stand(world.player) or world.player.distance_to(Vector2(836,842))>90.001:
		cancel("invalid_context");return false
	last_player=world.player
	reduced=bool(owner_state.get("native",{}).get("settings",{}).get("reduced_motion",false))
	world._cancel_floor_route();world.move_target=Vector2.INF;world.cancel_exploration_gestures()
	if not doors.begin_departure(true):cancel("missing_door");return false
	phase="opening";set_meta("blocks_input",true)
	return true

func valid_context()->bool:
	if not read_state.is_valid() or not is_instance_valid(world) or doors==null:return false
	if is_instance_valid(world.host_node):
		var frame:Control=world.host_node.get("world_frame")
		if is_instance_valid(frame) and not frame.is_visible_in_tree():return false
	var state:Dictionary=read_state.call()
	return is_same(owner_state,state) and str(state.get("runtimeMode",""))=="rpg" and str(state.get("rpgScene",""))=="theater_interior" and str(state.get("native",{}).get("scene",""))=="theater_interior" and str(state.get("theaterHunt",{}).get("phase",""))=="complete" and str(state.get("rpgCheckpoint",""))==checkpoint and world.scene_id=="theater_interior" and world.chapter3_layers!=null and world.chapter3_layers.doors==doors and world.is_visible_in_tree()

func _process(delta:float)->void:
	tick(delta,get_window().has_focus())

func tick(delta:float,focused:bool=true,panel_open:bool=false)->void:
	if finished or was_cancelled or phase=="idle":return
	if not valid_context():cancel("context_changed");return
	if not world.player.is_equal_approx(last_player):cancel("actor_moved");return
	var state:Dictionary=read_state.call()
	if not focused or panel_open or bool(state.get("ui",{}).get("controlCenterOpen",false)) or world._shell_input_blocked():return
	var seconds:float=clampf(delta,0,.05)
	if not is_finite(seconds):return
	elapsed_ms+=seconds*1000
	if elapsed_ms>ACTIVE_TIMEOUT_MS:cancel("timeout");return
	doors.advance(seconds*1000)
	if phase=="opening":
		if not doors.passable():return
		phase="align_x"
	var before:Vector2=world.player
	var target:Vector2=Vector2(DESTINATION.x,world.player.y) if phase=="align_x" else DESTINATION
	var remaining:Vector2=target-before
	var motion:Vector2=remaining.limit_length((280.0 if reduced else 196.0)*seconds)
	if not motion.is_zero_approx():
		world.player=world._c4_axis_destination(before,motion)
		world._apply_player_motion(world.player-before,remaining,seconds)
		world._sync_player();world._update_camera();world.queue_redraw()
		if world.player.distance_to(before)<.001:blocked_ms+=seconds*1000
		else:blocked_ms=0
		if blocked_ms>=BLOCKED_TIMEOUT_MS:cancel("blocked_passage");return
	last_player=world.player
	if world.player.distance_to(target)<.001:
		if phase=="align_x":phase="walk_out"
		else:
			finished=true;phase="complete";_release_door()
			world._apply_player_motion(Vector2.ZERO,Vector2.ZERO,0)
			completed.emit()
			if not is_queued_for_deletion():queue_free()

func is_finished()->bool:return finished or was_cancelled

func _release_door()->void:
	if doors!=null:doors.cancel_departure()
	set_meta("blocks_input",false)
	if is_instance_valid(world):world.queue_redraw()

func cancel(reason:String="cancelled")->void:
	if finished or was_cancelled:_release_door();return
	was_cancelled=true;phase="cancelled";_release_door()
	if is_instance_valid(world):world._apply_player_motion(Vector2.ZERO,Vector2.ZERO,0)
	cancelled.emit(reason)
	if is_inside_tree() and not is_queued_for_deletion():queue_free()

func _exit_tree()->void:
	if not finished:was_cancelled=true;phase="cancelled"
	_release_door()
