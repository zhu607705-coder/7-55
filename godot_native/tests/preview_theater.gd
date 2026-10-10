extends Control
## Standalone real playable scene. Three acts validate through the source model;
## no save writes or controller progress is fabricated by this visual fixture.
var game:Control
var round_id:=0
var attempt:=0
var sampling:=false
var evidence_directory_override:=""
var sample_frames:=0
var sample_seconds:=0.0
var sample_fps:Array[float]=[]
func _ready()->void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);resized.connect(_layout);_new_act()
	if FileAccess.file_exists("res://capture.request"):_capture_replay.call_deferred()
func _new_act()->void:
	if is_instance_valid(game):remove_child(game);game.queue_free()
	game=preload("res://scripts/games/c3_spotlight.gd").new();game.setup({"round":round_id,"attempt":attempt});add_child(game)
	game.attempt_submitted.connect(func(proof:Dictionary):
		var accepted:Dictionary=game.rules.validate(proof,round_id,attempt)
		game.resolve(accepted.get("status","")=="won",round_id==2))
	game.finished.connect(func(_result:Dictionary):
		if game.approved:round_id=(round_id+1)%3;attempt=0
		else:attempt+=1
		_new_act.call_deferred())
	_layout()
func _layout()->void:
	if not is_instance_valid(game):return
	var factor:float=minf(size.x/960,size.y/540);game.scale=Vector2.ONE*factor;game.position=(size-Vector2(960,540)*factor)*.5
func _process(delta:float)->void:
	if sampling or not is_instance_valid(game):return
	sample_frames+=1;sample_seconds+=delta
	if sample_frames>120 and sample_frames<480:sample_fps.append(1.0/maxf(.001,delta))
	if sample_frames==480:
		sample_fps.sort()
		var data:Dictionary={"renderer":RenderingServer.get_video_adapter_name(),"frames":sample_frames,"mean_fps":sample_frames/sample_seconds,"median_fps":sample_fps[sample_fps.size()/2],"p10_fps":sample_fps[sample_fps.size()/10],"draw_calls":Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME),"objects":Performance.get_monitor(Performance.RENDER_TOTAL_OBJECTS_IN_FRAME),"primitives":Performance.get_monitor(Performance.RENDER_TOTAL_PRIMITIVES_IN_FRAME)}
		_write_report("render-performance.json",data)
func _unhandled_key_input(event:InputEvent)->void:
	if event is InputEventKey and event.pressed and event.keycode in [KEY_F10,KEY_R] and not sampling:_capture_replay.call_deferred()
	if event is InputEventKey and event.pressed and event.keycode==KEY_F9:
		var dir:String=_evidence_directory()
		if not dir.is_empty():get_viewport().get_texture().get_image().save_png(dir+"/theater-live-"+str(Time.get_ticks_msec())+".png")

func _evidence_directory()->String:
	var directory:String=evidence_directory_override if not evidence_directory_override.is_empty() else "user://theater_review"
	var ancestor:String=ProjectSettings.globalize_path(directory)
	while ancestor.length()>1:
		if FileAccess.file_exists(ancestor):return ""
		var parent:String=ancestor.get_base_dir()
		if parent==ancestor:break
		ancestor=parent
	if DirAccess.make_dir_recursive_absolute(directory)!=OK:return ""
	return directory
func _write_report(name:String,data:Dictionary)->bool:
	var directory:String=_evidence_directory()
	if directory.is_empty():return false
	var file:=FileAccess.open(directory.path_join(name),FileAccess.WRITE)
	if file==null:return false
	file.store_string(JSON.stringify(data,"\t"));file.flush()
	return file.get_error()==OK
func _capture_replay()->void:
	var evidence:String=_evidence_directory()
	if evidence.is_empty():return
	var directory:String=evidence.path_join("replay")
	if DirAccess.make_dir_recursive_absolute(directory)!=OK:return
	sampling=true
	get_window().size=Vector2i(1152,648)
	await get_tree().process_frame
	_layout()
	round_id=0;attempt=0;_new_act();game.set_process(false)
	var frame:=0
	for act_id in 3:
		if act_id>0:round_id=act_id;attempt=0;_new_act();game.set_process(false)
		for opening in 30:
			game._process(1.0/30.0)
			await RenderingServer.frame_post_draw
			get_viewport().get_texture().get_image().save_png(directory+"/%04d.png"%frame);frame+=1
		game._primary()
		for playback in 650:
			if game.screen!="running":break
			var state:Dictionary=game.state;var aim:Vector2=game.rules.mouth(state);var closest:=INF
			for i in int(game.Model.ACTS[act_id].count):
				if not state.collected.has(i) and state.head.distance_to(game.Model.FOOD[i])<closest:closest=state.head.distance_to(game.Model.FOOD[i]);aim=game.Model.FOOD[i]
			var direction:Vector2=(aim-state.head).normalized()
			for hazard:Dictionary in game.rules.hazards(state):
				if state.head.distance_to(hazard.position)<100 and state.invulnerable==0:
					if state.dashCooldown<=1:game.queued_dash=true
					elif state.dashTicks==0 and state.head.distance_to(hazard.position)<65:direction=(direction+(state.head-hazard.position).normalized()*1.6).normalized()
			if not game.dragging:
				var press:=InputEventMouseButton.new();press.button_index=MOUSE_BUTTON_LEFT;press.pressed=true;press.position=game.model_to_pointer(state.head+direction*11);game._gui_input(press)
			else:
				var motion:=InputEventMouseMotion.new();motion.position=game.model_to_pointer(state.head+direction*11);game._gui_input(motion)
			game._process(1.0/30.0)
			await RenderingServer.frame_post_draw
			get_viewport().get_texture().get_image().save_png(directory+"/%04d.png"%frame);frame+=1
		for hold in 40:
			await RenderingServer.frame_post_draw
			get_viewport().get_texture().get_image().save_png(directory+"/%04d.png"%frame);frame+=1
	_write_report("replay/complete.json",{"frames":frame,"rate":30,"final_status":game.state.status})
	sampling=false;round_id=0;attempt=0;_new_act()
