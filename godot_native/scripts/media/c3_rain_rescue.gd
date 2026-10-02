extends Control
## Source-authored forced launch, capsize, real Ogg/Theora rescue and dock hold.
## Scene coordinates are transient presentation only; the controller owns completion.
signal event(action: String,value: Variant)
const Session=preload("res://scripts/media/c3_rain_rescue_session.gd")
const Model=preload("res://scripts/media/c3_rain_rescue_model.gd")
const KayakVisual=preload("res://scripts/ui/kayak_visual.gd")
const Metrics=preload("res://scripts/player_metrics.gd")
var session: RefCounted
var read_state: Callable
var world: Control
var callback: String="c3_rain_rescue_result"
var reported:=false
var video: VideoStreamPlayer
var caption: Label
var skip: Button
var visual: RefCounted=KayakVisual.new()
var pose: Dictionary={}
var old_camera:=Vector2.ZERO
var old_zoom:=1.0
var last_stage:=""
var font: Font
var video_started:=false
var degraded_reason:=""
func setup(config: Dictionary) -> void:
	mouse_filter=Control.MOUSE_FILTER_STOP
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	set_meta("blocks_input",true)
	session=config.get("session"); read_state=config.get("read_state",Callable()); world=config.get("world")
	callback=str(config.get("on_event",callback))
	if not session is Session or not read_state.is_valid() or not is_instance_valid(world) or not Session.eligible(read_state.call()): cancel(); return
	font=world.font
	old_camera=world.camera; old_zoom=world.zoom
	world.presentation_actor_hidden=true
	world.move_target=Vector2.INF; world.touch_axis=Vector2.ZERO
	if not session.begin(self): cancel(); return
	caption=Label.new(); caption.position=Vector2(24,440); caption.size=Vector2(912,78); caption.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	caption.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER; caption.vertical_alignment=VERTICAL_ALIGNMENT_CENTER
	caption.add_theme_font_override("font",font); caption.add_theme_font_size_override("font_size",20); caption.add_theme_color_override("font_color",Color("e9f9ff")); caption.mouse_filter=Control.MOUSE_FILTER_IGNORE; add_child(caption)
	caption.text=State.content("chapter3-qizhen-lake.content").dock.forcedLaunch
	queue_redraw()
func _process(_delta: float) -> void:
	if session==null or reported: return
	var s: Dictionary=read_state.call()
	if not Session.eligible(s) or not is_instance_valid(world) or world.scene_id!="qizhen_lake" or not s.native.get("host",{}).get("world_visible",true): cancel(); return
	var focused: bool=s.native.get("host",{}).get("focused",true)
	if is_instance_valid(video): video.paused=not focused
	var snap: Dictionary=session.sample(self,focused)
	if snap.is_empty(): cancel(); return
	pose=snap.pose
	if snap.phase=="cinematic" and not video_started: _begin_video()
	if snap.phase=="rescued":
		if is_instance_valid(video): video.hide(); video.stop()
		if is_instance_valid(skip): skip.hide()
		caption.text=State.content("chapter3-qizhen-lake.content").dock.forcedRescue
	elif pose.get("stage")=="gust": caption.text=State.content("chapter3-qizhen-lake.content").dock.forcedCapsize
	if pose.has("x") and pose.has("y"):
		var point:=Vector2(pose.x,pose.y)
		var half: Vector2=Vector2(480,270)/world.zoom
		world.camera=point.clamp(half,Model.MAP_SIZE-half)
	world.queue_redraw(); queue_redraw()
	if snap.phase=="complete":
		reported=true; _restore()
		event.emit(callback,session); queue_free()
func _begin_video() -> void:
	video_started=true
	if session.reduced_motion(): session.finish_cinematic(self,"fallback","reduced_motion"); return
	if not ResourceLoader.exists(Model.VIDEO_PATH):
		degraded_reason="视频资源未就绪，正在恢复到码头。"
		caption.text=degraded_reason; session.finish_cinematic(self,"fallback","missing_video"); return
	video=VideoStreamPlayer.new(); video.stream=load(Model.VIDEO_PATH); video.expand=true; video.size=Vector2(960,540); video.mouse_filter=Control.MOUSE_FILTER_IGNORE
	video.volume_db=-80 # Source rescue <video> is muted.
	add_child(video); move_child(video,0)
	caption.text="启真湖 · 雨天救援\n正在将落水者拉回码头"
	skip=Button.new(); skip.text="跳过回放"; skip.position=Vector2(800,20); skip.size=Vector2(140,44); add_child(skip)
	skip.pressed.connect(func(): session.finish_cinematic(self,"skipped"))
	video.finished.connect(func(): session.finish_cinematic(self,"video"))
	video.play()
func cancel() -> void:
	if reported: return
	reported=true
	if session!=null: session.cancel()
	_restore()
	if session!=null: event.emit(callback,session)
	queue_free()
func _restore() -> void:
	if is_instance_valid(video): video.stop()
	if is_instance_valid(world):
		world.presentation_actor_hidden=false; world.camera=old_camera; world.zoom=old_zoom; world.queue_redraw()
func _exit_tree() -> void:
	if not reported:
		if session!=null: session.cancel()
		_restore()
		if session!=null: event.emit(callback,session)
func _draw() -> void:
	if pose.is_empty() or not is_instance_valid(world): return
	var stage: String=pose.get("stage","")
	var origin: Vector2=size/2-world.camera*world.zoom
	if stage in ["approach","rescued"]:
		var frame: Texture2D=world.player_frames["down" if stage=="rescued" else "up"][0]
		var rect: Rect2=Metrics.visual_rect(Vector2(pose.x,pose.y))
		draw_texture_rect(frame,Rect2(origin+rect.position*world.zoom,rect.size*world.zoom),false,Color(1,1,1,float(pose.get("alpha",1))))
	elif stage not in ["cinematic",""]:
		var body: Dictionary=pose.duplicate(); body.strokeAgeMs=body.get("localMs",1000)
		visual.draw(self,origin+Vector2(pose.x,pose.y)*world.zoom,world.zoom,body,float(session.snapshot().elapsedMs))
		if stage=="capsize":
			var progress: float=clampf(float(pose.localMs)/float(Model.timing(session.reduced_motion()).capsizeMs),0,1)
			for i in range(4 if session.reduced_motion() else 8):
				var center: Vector2=origin+(Vector2(pose.x,pose.y)+Vector2.from_angle(i*TAU/8)*(10+i*2))*world.zoom
				draw_arc(center,(15+i*5)*(1+progress*.55)*world.zoom,0,TAU,24,Color(.88,.97,1,(1-progress)*.7),2)
	draw_rect(Rect2(12,434,936,94),Color(.02,.07,.11,.9))
