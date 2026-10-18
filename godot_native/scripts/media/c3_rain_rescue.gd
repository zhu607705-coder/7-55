extends Control
## Source-authored route, native rescue (legacy Theora fallback), and dock hold.
## Scene coordinates are transient presentation only; the controller owns completion.
signal event(action: String,value: Variant)
const Session=preload("res://scripts/media/c3_rain_rescue_session.gd")
const Model=preload("res://scripts/media/c3_rain_rescue_model.gd")
const KayakVisual=preload("res://scripts/ui/kayak_visual.gd")
const NativeRenderer=preload("res://scripts/media/c3_rain_rescue_native/renderer.gd")
const Metrics=preload("res://scripts/player_metrics.gd")
var session: RefCounted
var read_state: Callable
var world: Control
var callback: String="c3_rain_rescue_result"
var reported:=false
var video: VideoStreamPlayer
var native_renderer: Control
var cinematic_mode: String="native"
var caption: Label
var skip: Button
var skip_display_scale: float=-1.0
var compact_caption: bool=false
var visual: RefCounted=KayakVisual.new()
var pose: Dictionary={}
var old_camera:=Vector2.ZERO
var old_zoom:=1.0
var last_stage:=""
var font: Font
var cinematic_started:=false
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
	cinematic_mode=str(config.get("cinematic_mode","native"))
	if cinematic_mode not in ["native","video"]: cinematic_mode="native"
	if cinematic_mode=="native" and not NativeRenderer.available(): cinematic_mode="video"
	if not session.begin(self,cinematic_mode): cancel(); return
	caption=Label.new(); caption.position=Vector2(24,440); caption.size=Vector2(912,78); caption.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	caption.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER; caption.vertical_alignment=VERTICAL_ALIGNMENT_CENTER
	caption.add_theme_font_override("font",font); caption.add_theme_font_size_override("font_size",20); caption.add_theme_color_override("font_color",Color("e9f9ff")); caption.mouse_filter=Control.MOUSE_FILTER_IGNORE; add_child(caption)
	caption.text=State.content("chapter3-qizhen-lake.content").dock.forcedLaunch
	_layout_caption(read_state.call())
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
	if is_instance_valid(skip):
		skip.disabled=not focused
		_layout_skip(s)
	if snap.phase=="cinematic":
		if not cinematic_started: _begin_cinematic()
		if is_instance_valid(native_renderer): native_renderer.present(Model.native_source_ms(float(snap.cinematicMs)),session.reduced_motion())
	if snap.phase=="rescued":
		if is_instance_valid(video): video.hide(); video.stop()
		if is_instance_valid(native_renderer): native_renderer.hide()
		if is_instance_valid(skip): skip.hide()
		caption.show()
		caption.text=State.content("chapter3-qizhen-lake.content").dock.forcedRescue
	elif pose.get("stage")=="gust": caption.text=State.content("chapter3-qizhen-lake.content").dock.forcedCapsize
	_layout_caption(s)
	if pose.has("x") and pose.has("y"):
		var point:=Vector2(pose.x,pose.y)
		var half: Vector2=Vector2(480,270)/world.zoom
		world.camera=point.clamp(half,Model.MAP_SIZE-half)
	world.queue_redraw(); queue_redraw()
	if snap.phase=="complete":
		reported=true; _restore()
		event.emit(callback,session); queue_free()
func _begin_cinematic() -> void:
	cinematic_started=true
	if session.reduced_motion(): session.finish_cinematic(self,"fallback","reduced_motion"); return
	if cinematic_mode=="native":
		native_renderer=NativeRenderer.new()
		native_renderer.size=Vector2(960,540)
		add_child(native_renderer); move_child(native_renderer,0)
		caption.hide()
	else:
		if not ResourceLoader.exists(Model.VIDEO_PATH):
			degraded_reason="视频资源未就绪，正在恢复到码头。"
			caption.text=degraded_reason; session.finish_cinematic(self,"fallback","missing_video"); return
		video=VideoStreamPlayer.new(); video.stream=load(Model.VIDEO_PATH); video.expand=true; video.size=Vector2(960,540); video.mouse_filter=Control.MOUSE_FILTER_IGNORE
		video.volume_db=-80 # Source rescue <video> is muted.
		add_child(video); move_child(video,0)
		caption.text="启真湖 · 雨天救援\n正在将落水者拉回码头"
		video.finished.connect(func(): _request_finish("video"))
		video.play()
	skip=Button.new(); skip.text="跳过回放"; skip.focus_mode=Control.FOCUS_NONE; skip.add_theme_font_override("font",font); add_child(skip)
	_layout_skip(read_state.call())
	skip.pressed.connect(func(): _request_finish("skipped"))

func _layout_skip(s: Dictionary) -> void:
	if not is_instance_valid(skip): return
	var display_scale: float=float(s.get("native",{}).get("host",{}).get("world_display_scale",1.0))
	if not is_finite(display_scale) or display_scale<=0: display_scale=1.0
	# The supported narrow viewports remain above .1. Bound corrupt host metadata
	# so a font's own minimum size can never force this control out of 960x540.
	display_scale=clampf(display_scale,.1,4.0)
	if is_equal_approx(skip_display_scale,display_scale): return
	skip_display_scale=display_scale
	var font_size: int=int(ceil(16.0/minf(1.0,display_scale)))
	skip.add_theme_font_size_override("font_size",font_size)
	var text_size: Vector2=font.get_string_size(skip.text,HORIZONTAL_ALIGNMENT_LEFT,-1,font_size)
	var width: float=minf(944,maxf(140,text_size.x+24.0/display_scale))
	var height: float=minf(528,maxf(44.0/display_scale,maxf(44,text_size.y+12.0/display_scale)))
	skip.size=Vector2(ceil(width),ceil(height))
	skip.position=Vector2(952-skip.size.x,6)

func _layout_caption(s: Dictionary) -> void:
	if not is_instance_valid(caption): return
	var display_scale: float=float(s.get("native",{}).get("host",{}).get("world_display_scale",1.0))
	if not is_finite(display_scale) or display_scale<=0: display_scale=1.0
	display_scale=clampf(display_scale,.1,4.0)
	compact_caption=display_scale<.7
	var native_visible: bool=is_instance_valid(native_renderer) and native_renderer.visible
	if native_visible:
		native_renderer.external_caption=compact_caption
		if compact_caption: caption.text=native_renderer.caption_text()
		caption.visible=compact_caption
	else: caption.show()
	if not compact_caption:
		caption.position=Vector2(24,440); caption.size=Vector2(912,78)
		caption.max_lines_visible=-1; caption.clip_text=false
		caption.add_theme_font_size_override("font_size",20)
		return
	# Keep all original words. Only the compact embedding owns larger wrapping
	# text in the existing footer; the renderer and scene geometry do not move.
	caption.position=Vector2(24,428); caption.size=Vector2(912,108)
	caption.max_lines_visible=2; caption.clip_text=true
	for physical_size: float in [16.0,15.0,14.0]:
		var font_size: int=int(ceil(physical_size/display_scale))
		caption.add_theme_font_size_override("font_size",font_size)
		var lines: int=caption.get_line_count()
		var text_height: float=font.get_height(font_size)*lines+caption.get_theme_constant("line_spacing")*maxi(0,lines-1)
		if lines<=2 and text_height<=108: break
	# A temporary larger font can increase Label minimum size. Restore the
	# authored footer after choosing the final fitting font.
	caption.size=Vector2(912,108)

func _request_finish(result: String) -> void:
	if reported or session==null or not read_state.is_valid() or not is_instance_valid(world): return
	var s: Dictionary=read_state.call()
	# A queued input or decoder signal during focus loss cannot bypass the pause.
	if not Session.eligible(s) or world.scene_id!="qizhen_lake" or not s.native.get("host",{}).get("world_visible",true): return
	if not s.native.get("host",{}).get("focused",true): return
	session.finish_cinematic(self,result)

func cancel() -> void:
	if reported: return
	reported=true
	if session!=null: session.cancel()
	_restore()
	if session!=null: event.emit(callback,session)
	queue_free()
func _restore() -> void:
	if is_instance_valid(video): video.stop()
	if is_instance_valid(native_renderer): native_renderer.hide()
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
	if not is_instance_valid(native_renderer) or not native_renderer.visible:
		draw_rect(Rect2(12,424,936,116) if compact_caption else Rect2(12,434,936,94),Color(.02,.07,.11,.9))
