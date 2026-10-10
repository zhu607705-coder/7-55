extends Control
signal inspect_requested(id: String)
signal cinematic_started
## Timed source dialogue + approach owner. Only the controller acknowledges facts.
const View=preload("res://scripts/presentation/c3_narrative_view.gd")
const PromoTimeline=preload("res://scripts/presentation/c3_promo_timeline.gd")
const WorldView=preload("res://scripts/presentation/c3_narrative_world_view.gd")
var world: Control
var read_state: Callable
var provider: Callable
var dispatch: Callable
var cue: Callable
var runtime_reader: Callable
var current: RefCounted
var view: Control
var effects: Control
var completion_sent: bool=false
var was_focused: bool=true
var original_zoom: float=1
var entry_camera:=Vector2.ZERO
var _escape_camera_owned: bool=false
func setup(world_view: Control,state_reader: Callable,session_provider: Callable,action_sink: Callable,cue_sink: Callable=Callable(),runtime_state_reader: Callable=Callable()) -> void:
	world=world_view; read_state=state_reader; provider=session_provider; dispatch=action_sink; cue=cue_sink; runtime_reader=runtime_state_reader
	process_priority=61; mouse_filter=Control.MOUSE_FILTER_IGNORE
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	view=View.new(); world.add_child(view)
	effects=WorldView.new(); effects.world=world; world.add_child(effects)
func owns_world_contract() -> bool: return current!=null and current.owns_world_contract()
func blocks_input() -> bool: return current!=null and current.status in ["issued","playing","inspecting","complete"]
func blocks_movement() -> bool: return blocks_input() and current.blocks_movement()
func _focused() -> bool:
	if not runtime_reader.is_valid(): return true
	var host: Dictionary=runtime_reader.call().get("native",{}).get("host",{})
	return bool(host.get("focused",true)) and bool(host.get("world_visible",true)) and not bool(host.get("minigame_open",false))
func _process(delta: float) -> void:
	if is_visible_in_tree(): tick(delta*1000,_focused())
func tick(delta_ms: float,focused: bool=true) -> void:
	if not read_state.is_valid() or not provider.is_valid() or not is_instance_valid(world): return
	var s: Dictionary=read_state.call()
	if current!=null and (not current.valid(s) or current.status=="cancelled"): reset()
	if current==null and focused and s.native.get("scene","")=="theater_interior" and s.theaterHunt.phase=="reversal" and s.theaterHunt.spotlightRound>=3 and s.native.get("c3_reversal_pending",false)!=true:
		dispatch.call("c3_reversal",null)
	var issued: RefCounted=provider.call(0)
	if current==null and issued!=null and world.scene_id==issued.scene and issued.attach(s,self):
		current=issued; completion_sent=false; was_focused=true
		# Restore canonical bounds before taking a camera sample for a source shot.
		if owns_world_contract(): cinematic_started.emit()
		original_zoom=world.zoom; entry_camera=world.camera
		_escape_camera_owned=current.sequence_id=="canteen_escape"
		if _escape_camera_owned:
			# Defense hides the world, so an old entry fade may still be pending.
			# Source victory is the same room, with no new fade over its 160ms flight.
			world.transition_alpha=0.0
		view.session=current; effects.session=current; view.move_to_front(); move_to_front()
		if current.blocks_movement() or current.sequence_id=="canteen_promo": world.move_target=Vector2.INF; world.touch_axis=Vector2.ZERO
		if current.sequence_id=="canteen_escape" and current.spec.get("playerStart") is Array:
			world.player=Vector2(current.spec.playerStart[0],current.spec.playerStart[1])
			if world.has_method("_sync_player"): world._sync_player()
			world._update_camera()
	_sync_view_layout()
	if current==null: view.session=null; view.tick(); return
	if focused!=was_focused:
		_voice("native_activity_resumed" if focused else "native_activity_paused"); was_focused=focused
	current.frame(s,delta_ms,self,focused)
	if current.sequence_id=="canteen_promo" and not current.visual_acknowledged and current.elapsed_ms>=float(current.spec.delayMs):
		dispatch.call("c3_promo_visual_complete",current)
	if current.sequence_id=="theater_reversal" and not current.visual_acknowledged and current.elapsed_ms>=float(current.spec.delayMs):
		dispatch.call("c3_reversal_visual_complete",current)
	if current.status=="inspecting" and not current.inspector_opened and current.mark_inspector_opened(s,self):
		inspect_requested.emit("decoyPaper")
	_apply_motion(delta_ms if focused else 0)
	view.tick(); effects.queue_redraw()
	for event: Dictionary in current.take_cues():
		if cue.is_valid(): cue.call(event.id,event.payload)
	if current.status=="complete" and not completion_sent:
		completion_sent=true
		var finished: RefCounted=current
		_voice("native_activity_closed")
		dispatch.call("c3_story_complete",finished)
		if finished.status!="consumed": reset(); return
		_restore_camera(finished.sequence_id)
		current=null; view.session=null; view.tick(); effects.session=null; effects.queue_redraw()
func _sync_view_layout() -> void:
	var runtime:Dictionary=runtime_reader.call().get("native",{}).get("host",{}) if runtime_reader.is_valid() else {}
	view.display_scale=float(runtime.get("world_display_scale",1.0))
	view.text_scale=float(read_state.call().native.settings.get("text_scale",1.0)) if read_state.is_valid() else 1.0
	# CanvasItem visibility stops at the SubViewport boundary. The shell is
	# the authority when this subtitle is reparented into the root viewport.
	view.surface_visible=bool(runtime.get("world_visible",world.is_visible_in_tree()))
	view.exploration_rect=Rect2(); view.screen_rect=Rect2();view.align_left=false
	var parent:Node=world
	var shell:Variant=world.get("host_node")
	# Portrait films keep their authored 16:9 camera. Put readable dialogue
	# in the unused screen space instead of inflating it over the small film.
	if is_instance_valid(shell) and owns_world_contract() and shell.size.y>shell.size.x:
		var film:Rect2=shell.world_view.get_global_rect()
		var bottom:float=shell.size.y-12
		if shell.inventory_handle.visible:bottom=minf(bottom,shell.inventory_handle.position.y-8)
		if shell.inventory_dock.visible:bottom=minf(bottom,shell.inventory_dock.position.y-8)
		if bottom-film.end.y>=100:
			parent=self
			view.screen_rect=Rect2(12,film.end.y+8,shell.size.x-24,bottom-film.end.y-8)
	if is_instance_valid(shell) and owns_world_contract() and parent==world:
		var film:Rect2=shell.world_view.get_global_rect()
		var right:float=shell.size.x-film.end.x-20
		var left:float=film.position.x-20
		# Short landscape windows have useful side letterboxes. Preserve the
		# full source room and its exit instead of covering the lower doorway.
		if maxf(left,right)>=120:
			parent=self
			view.screen_rect=Rect2(film.end.x+8 if right>=left else 12,maxf(64,film.position.y),right if right>=left else left,film.size.y)
		else:
			# Wide desktop films have no letterbox. A bounded left-hand caption
			# leaves the source southeast exit and its arrival point unobscured.
			view.align_left=true
	if view.get_parent()!=parent:
		view.reparent(parent,false); view.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	if world.get("mobile_exploration")==true:
		var controls: Dictionary=world.mobile_control_metrics()
		var top: float=float(world.hud_metrics("").header_height)+8
		var bottom: float=minf(controls.stick_rect.position.y,controls.interact.position.y)-8
		view.exploration_rect=Rect2(8,top,world.size.x-16,maxf(0,bottom-top))
	elif parent==world and not owns_world_contract() and world.has_method("exploration_safe_rect"):
		var safe:Rect2=world.exploration_safe_rect()
		view.exploration_rect=Rect2(safe.position+Vector2(8,8),safe.size-Vector2(16,16))

func inspector_closed(id: String) -> bool:
	if current==null or id!="decoyPaper" or not current.mark_inspector_closed(read_state.call(),self): return false
	dispatch.call("c3_reversal_inspect_closed",current)
	tick(0,_focused()); return true
func _apply_motion(delta_ms: float) -> void:
	if current==null: return
	if current.sequence_id=="canteen_escape" and current.blocks_movement() and current.elapsed_ms>=float(current.spec.delayMs) and current.motion_origin==Vector2.INF:
		current.motion_origin=world.player
	var point: Vector2=current.player_pose()
	if point!=Vector2.INF:
		var prior: Vector2=world.player
		world.player=point; world.move_target=Vector2.INF; world.touch_axis=Vector2.ZERO
		if point.distance_to(prior)>0.01: world.walk_clock+=maxf(0,delta_ms)/1000; world.facing="side"; world.player_flip=point.x<prior.x
		else: world.walk_clock=0
		if world.has_method("_sync_player"): world._sync_player()
	if current.sequence_id=="canteen_promo" and current.elapsed_ms<=float(current.spec.delayMs):
		var pose: Dictionary=PromoTimeline.camera(maxf(0,current.elapsed_ms-float(current.spec.get("timelineStartMs",0))),current.reduced,entry_camera,original_zoom,world.player)
		world.zoom=pose.zoom; world.camera=pose.point
	if current.sequence_id=="qizhen_approach":
		world.zoom=.7
		var target: Vector2=world.player+Vector2(270,0)
		var half: Vector2=Vector2(480,270)/world.zoom
		world.camera=Vector2(clampf(target.x,half.x,world.world_size.x-half.x),clampf(target.y,half.y,maxf(half.y,world.world_size.y-half.y)))
	apply_owned_camera()
	world.queue_redraw()

func apply_owned_camera() -> bool:
	# startDefense stops following the player and fits the complete source room.
	# animateDefenseVictory, finishDefense and beginCanteenExit keep that shot.
	# Main retains the canonical 960x540 surface, including on portrait screens.
	if not _escape_camera_owned or current==null or not is_instance_valid(world): return false
	if current.status not in ["playing","complete"] or world.scene_id!=current.scene or not current.valid(read_state.call()): return false
	var room: Vector2=world.world_size
	world.zoom=minf(960.0/room.x,540.0/room.y)*.985
	world.camera=room/2
	return true

func _voice(id: String) -> void:
	if cue.is_valid(): cue.call(id,{"prefixes":["chapter3_story_line"]})
func _restore_camera(id: String) -> void:
	# Release before the normal camera update so it cannot reacquire this shot.
	_escape_camera_owned=false
	if id=="canteen_escape" and is_instance_valid(world) and world.scene_id=="canteen_interior" and current!=null and is_same(read_state.call(),current.bound_state):
		world.zoom=original_zoom; world._update_camera(); world.queue_redraw()
	if id in ["qizhen_approach","canteen_promo"] and is_instance_valid(world) and world.scene_id in ["campus_qizhen_loop","canteen_interior"]:
		world.zoom=1.0 if id=="canteen_promo" else original_zoom; world._update_camera(); world.queue_redraw()
func reset() -> void:
	if current!=null:
		_restore_camera(current.sequence_id); current.cancel(); _voice("native_activity_closed")
	current=null; completion_sent=false
	if is_instance_valid(view): view.session=null; view.tick()
	if is_instance_valid(effects): effects.session=null; effects.queue_redraw()
func _exit_tree() -> void:
	reset()
	if is_instance_valid(effects): effects.queue_free()
	if is_instance_valid(view): view.queue_free()
