extends Control
signal completed(result: Dictionary)
signal cancelled
signal presentation_requested(id: String,payload: Dictionary)
signal progress_requested(proof:Dictionary)
signal attempt_failed(proof:Dictionary)
const LampClosure=preload("res://scripts/presentation/chapter4_lamp_closure.gd")
var lamp_view:Control
const ElevatorPanel = preload("res://scripts/ui/chapter4_elevator_panel.gd")
const StairChase = preload("res://scripts/games/chapter4_chase_stair_model.gd")
const GuardModel = preload("res://scripts/games/chapter4_guard_model.gd")
const Source = preload("res://scripts/games/chapter4_stair_model.gd")
const ChaseView = preload("res://scripts/presentation/chapter4_chase_stair_view.gd")
const NativeUi = preload("res://scripts/ui/native_ui_theme.gd")
const Capture=preload("res://scripts/presentation/chapter4_guard_capture.gd")
const PlayerMetrics=preload("res://scripts/player_metrics.gd")
var config: Dictionary={}
var source: Dictionary={}
var kind: String=""
var elapsed: float=0
var running: bool=true
var done: bool=false
var title: Label
var body: Label
var controls: BoxContainer
var stage: String=""
var selection: int=81807
var boarded: bool=false
var elevator_panel: Control
var elevator_feedback: String=""
var answers: Dictionary={}
var question_index: int=0
var lamp: Dictionary={}
var stars: Array=[]
var music: AudioStreamPlayer
var audio_manifest: Dictionary={}
var audio_events: Dictionary={}
var cues_fired: Dictionary={}
var video: VideoStreamPlayer
var pointer_target: Vector2=Vector2.ZERO
var pointer_moving: bool=false
var player: Vector2=Vector2(833,826)
var guard: Vector2=Vector2(833,922)
var trail: Array=[]
var guard_trail: Array=[]
var guard_target: Variant=null
var guard_repath: float=0
var player_art: Texture2D
var guard_art: Texture2D
var landing: int=0
var failures: int=0
var snapshot_clock: float=0
var built: bool=false
var plate: Texture2D
var prologue_focused := true
var prologue_fallback := false
var prologue_reduced := false
var prologue_notice: Label
var prologue_card: ColorRect
var prologue_portraits: Array=[]
var prologue_available := Vector2(960,540)
var prologue_adaptive := false
var prologue_field := Rect2(0,0,960,540)
var chase_view:Control
var chase_overview:Control
var chase_status:Label
var chase_touch_enabled:=false
var chase_touch_seen:=false
var chase_touch_axis:=Vector2.ZERO
var chase_pointer_owner:=""
var chase_finger:=-1
var chase_pad:=Rect2()
var chase_adaptive:=false
var guard_delay_ms:=0.0
var chase_animation_ms:=0.0
var chase_progress_pending:=false
var chase_request_remaining_ms:=0.0
var chase_capture:RefCounted=Capture.new()

func uses_activity_layout() -> bool:
	return kind in ["prologue","elevator_alignment","chase_stairwell","star_lamp_closure"]

func configure_activity_layout(available: Vector2, _compact: bool) -> void:
	if kind=="star_lamp_closure":
		custom_minimum_size=Vector2.ZERO;scale=Vector2.ONE;position=Vector2.ZERO;size=available.max(Vector2(240,240))
		if is_instance_valid(lamp_view):lamp_view.size=size
		return
	if kind=="chase_stairwell":
		if size!=available:_clear_chase_pointer()
		chase_adaptive=true;custom_minimum_size=Vector2.ZERO;scale=Vector2.ONE;position=Vector2.ZERO;size=available.max(Vector2(240,240));_layout_chase();return
	if kind == "elevator_alignment":
		custom_minimum_size=Vector2.ZERO;scale=Vector2.ONE;position=Vector2.ZERO;size=available.max(Vector2(240,240))
		if is_instance_valid(elevator_panel):elevator_panel.size=size
		return
	if kind != "prologue": return
	prologue_adaptive = true
	prologue_available = available.max(Vector2(240,240))
	custom_minimum_size = Vector2.ZERO
	scale = Vector2.ONE
	position = Vector2.ZERO
	size = prologue_available
	_layout_prologue()

func _layout_prologue() -> void:
	if not prologue_adaptive or not built or kind != "prologue": return
	var portrait := size.y > size.x
	var inset := 16.0
	var film_area := Rect2(Vector2.ZERO,size)
	if portrait: film_area = Rect2(16,78,size.x-32,(size.x-32)*9.0/16.0)
	var factor := minf(film_area.size.x/960.0,film_area.size.y/540.0)
	prologue_field = Rect2(film_area.get_center()-Vector2(960,540)*factor/2,Vector2(960,540)*factor)
	if is_instance_valid(video): video.position=prologue_field.position; video.size=prologue_field.size
	controls.set_anchors_preset(Control.PRESET_TOP_LEFT)
	controls.add_theme_constant_override("separation",8)
	for button in controls.get_children():
		if button is Button:
			button.custom_minimum_size.y=44
			button.add_theme_font_size_override("font_size",18)
	title.add_theme_font_size_override("font_size",22)
	title.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	body.add_theme_font_size_override("font_size",18)
	body.add_theme_constant_override("line_spacing",5)
	if stage == "card":
		body.text="CHAPTER 03.5 · COMPLETE\n"+("" if size.y<500 else "\n")+"现场定位：段永平教学楼玻璃门\n当前目标：追踪进入教学楼的异常签到纸"
		var card_width := minf(410 if portrait else 470,size.x-32)
		var card_top := prologue_field.end.y+16 if portrait else 16.0
		var card_rect := Rect2((size.x-card_width)/2 if portrait else size.x-card_width-16,card_top,card_width,size.y-card_top-16)
		prologue_card.position=card_rect.position; prologue_card.size=card_rect.size
		title.position=card_rect.position+Vector2(inset,16); title.size=Vector2(card_width-32,34)
		body.position=title.position+Vector2(0,46); body.size=Vector2(card_width-32,maxf(100,card_rect.size.y-228))
		controls.position=Vector2(title.position.x,card_rect.end.y-160); controls.size=Vector2(card_width-32,144)
	else:
		title.position=Vector2(16,16); title.size=Vector2(size.x-32 if portrait else maxf(300,size.x-296),54)
		body.position=Vector2(20,prologue_field.end.y+16) if portrait else Vector2(32,size.y-106)
		body.size=Vector2(size.x-40, maxf(100,size.y-body.position.y-132)) if portrait else Vector2(size.x-64,86)
		controls.position=Vector2(16,size.y-112) if portrait else Vector2(size.x-256,16)
		controls.size=Vector2(size.x-32 if portrait else 240,96)
	prologue_notice.position=Vector2(20,prologue_field.position.y+8)
	prologue_notice.size=Vector2(size.x-40,42)
	prologue_notice.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	queue_redraw()

func setup(value: Dictionary) -> void:
	config=value
	if is_inside_tree(): _build()
func _ready() -> void:
	if not config.is_empty(): _build()
func _build() -> void:
	if built: return
	built=true; source=Source.data(); kind=config.get("kind","")
	set_anchors_preset(Control.PRESET_TOP_LEFT)
	size=Vector2(960,540)
	title=Label.new(); title.position=Vector2(24,12); title.size=Vector2(880,40); title.text=config.get("title",""); title.add_theme_color_override("font_color",Color("edf4dc")); add_child(title)
	body=Label.new(); body.position=Vector2(24,64); body.size=Vector2(880,120); body.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART; body.text=config.get("body",""); body.add_theme_color_override("font_color",Color("edf4dc")); add_child(body)
	controls=HBoxContainer.new() if kind=="chase_stairwell" else VBoxContainer.new(); controls.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_RIGHT); controls.position=Vector2(-310,-220); controls.size=Vector2(286,200); add_child(controls)
	match kind:
		"elevator_alignment":
			running=false; stage="select"; selection=int(config.timeline.selectableStartMinSeconds)
			title.hide();body.hide();controls.hide()
			elevator_panel=ElevatorPanel.new();elevator_panel.configure(config.timeline);elevator_panel.size=size
			elevator_panel.shifted.connect(_shift_elevator);elevator_panel.replay_requested.connect(_start_elevator_replay);elevator_panel.board_requested.connect(_board);elevator_panel.close_requested.connect(func():cancelled.emit())
			add_child(elevator_panel);_elevator_controls()
		"chase_stairwell":
			var file: String="res://assets/rpg/interiors/finale/finale_stairwell.png"
			if ResourceLoader.exists(file): plate=load(file)
			body.text="WASD / 方向键移动；按住地面可指向移动。不要让保安追上。"
			if ResourceLoader.exists("res://assets/rpg/player/player_up_0.png"): player_art=load("res://assets/rpg/player/player_up_0.png")
			if ResourceLoader.exists("res://assets/rpg/npcs/finale/guard_walk_up_8frame.png"): guard_art=load("res://assets/rpg/npcs/finale/guard_walk_up_8frame.png")
			chase_touch_enabled=DisplayServer.is_touchscreen_available()
			chase_view=ChaseView.new();add_child(chase_view)
			chase_overview=ChaseView.new();chase_overview.overview=true;add_child(chase_overview)
			chase_status=Label.new();chase_status.add_theme_color_override("font_color",Color("edf4dc"));add_child(chase_status)
			_reset_chase()
		"star_lamp_closure":
			running=false;stage="questions";title.hide();body.hide();controls.hide()
			lamp_view=LampClosure.new();lamp_view.configure(config);lamp_view.size=size
			lamp_view.save_requested.connect(_save_lamp_answers)
			lamp_view.acknowledged.connect(func(proof):elapsed=float(proof.playbackMs);_finish(proof))
			add_child(lamp_view)
		"prologue": _prologue()
		"dialogue":
			running=false; _button("继续",func(): _finish({"acknowledged":true}))
		_:
			running=false; body.text="该活动未接入。剧情未前进。"
	if kind not in ["prologue","elevator_alignment","chase_stairwell","star_lamp_closure"]: _button("返回",func(): cancelled.emit())
	queue_redraw()
func _button(text: String,callback: Callable) -> Button:
	var button: Button=Button.new(); button.text=text; button.custom_minimum_size.y=42; button.pressed.connect(callback); controls.add_child(button); return button
func _clear_controls() -> void:
	for child in controls.get_children():
		if kind in ["prologue","chase_stairwell"]: controls.remove_child(child)
		child.queue_free()
func _finish(proof: Dictionary={}) -> void:
	if done: return
	if kind=="chase_stairwell":_clear_chase_pointer();chase_capture.cancel();chase_progress_pending=false
	done=true; running=false
	if kind=="prologue": _cue("chapter4_prologue_finished")
	var result: Dictionary={"kind":kind,"session":config.get("session",""),"elapsedMs":elapsed}
	result.merge(proof,true); completed.emit(result)
func _prologue() -> void:
	prologue_reduced=bool(config.get("settings",{}).get("reduced_motion",false))
	var path: String=config.get("video","")
	prologue_fallback=prologue_reduced or not ResourceLoader.exists(path)
	if not prologue_fallback:
		var stream: Resource=load(path)
		if stream is VideoStream:
			video=VideoStreamPlayer.new(); video.stream=stream; video.expand=true; video.position=Vector2.ZERO; video.size=size; video.volume=0; video.mouse_filter=Control.MOUSE_FILTER_IGNORE; add_child(video); move_child(video,0)
			video.finished.connect(_prologue_video_finished); video.play()
		else: prologue_fallback=true
	for manifest in ["chapter4-prologue-voice.audio.generated.json","chapter4-prologue-sfx.audio.generated.json","chapter4-prologue-music.audio.generated.json"]:
		var d: Variant=JSON.parse_string(FileAccess.get_file_as_string("res://data/source/"+manifest))
		if d is Dictionary: audio_manifest.merge(d.get("assets",{}))
	audio_manifest["music_ch4_prologue_h3_44s"]={"path":"chapter4/prologue/music_ch4_prologue_h3_44s.mp3"}
	var d: Variant=JSON.parse_string(FileAccess.get_file_as_string("res://data/source/chapter4-prologue.audio.json")); audio_events=d.get("events",{}) if d is Dictionary else {}
	prologue_notice=Label.new(); prologue_notice.position=Vector2(24,70); prologue_notice.size=Vector2(560,40); prologue_notice.add_theme_font_size_override("font_size",14); prologue_notice.add_theme_color_override("font_color",Color("edf4dc")); add_child(prologue_notice)
	for suffix in ["a","b"]:
		var portrait_path: String="res://assets/rpg/portraits/finale/runtime/departing_student_"+suffix+".png"
		if ResourceLoader.exists(portrait_path): prologue_portraits.append(load(portrait_path))
	_prologue_playback_controls()
func _prologue_playback_controls() -> void:
	stage="playback"; running=true
	title.text="RECOVERED TIMELINE  ·  SOURCE 4 / 4"; title.position=Vector2(24,18); title.size=Vector2(560,46); title.add_theme_color_override("font_color",Color("edf4dc"))
	body.text=""; body.position=Vector2(40,420); body.size=Vector2(880,92); body.add_theme_color_override("font_color",Color("edf4dc"))
	controls.position=Vector2(692,16); controls.size=Vector2(240,100); _clear_controls()
	_button("跳过恢复回放",_skip_prologue); _button("返回",func(): cancelled.emit())
	_update_prologue_notice()
	_layout_prologue()
func _update_prologue_notice() -> void:
	if not is_instance_valid(prologue_notice): return
	prologue_notice.visible=prologue_fallback and stage!="card"
	prologue_notice.text="减少动态效果：静态回放" if prologue_reduced else "视频不可用，已切换静态回放"
func _prologue_video_finished() -> void:
	if elapsed<43584 and stage=="playback":
		prologue_fallback=true; video.hide(); _update_prologue_notice(); queue_redraw()
func _sync_prologue_video(force: bool=false) -> void:
	if not is_instance_valid(video) or prologue_fallback or stage!="playback": return
	var target: float=elapsed/1000.0; var length: float=video.get_stream_length()
	if length>0: target=minf(target,maxf(0,length-1.0/24.0))
	if force or absf(video.stream_position-target)>0.25: video.stream_position=target
func _skip_prologue() -> void:
	if kind!="prologue" or stage=="card" or done: return
	# Source skip silences pending beats, opens the task card, and still requires acknowledgement.
	for beat in source.prologue.beats: cues_fired[beat.cueEvent]=true
	_cue("chapter4_prologue_skip"); elapsed=43834; _cue("chapter4_prologue_task_card"); _show_prologue_card()
func _show_prologue_card() -> void:
	if stage=="card": return
	stage="card"; running=false; elapsed=43834
	if is_instance_valid(video): video.paused=true
	_clear_controls(); _update_prologue_notice()
	prologue_card=ColorRect.new(); prologue_card.color=Color("edf4dc"); prologue_card.position=Vector2(574,112); prologue_card.size=Vector2(352,350); prologue_card.mouse_filter=Control.MOUSE_FILTER_IGNORE; add_child(prologue_card); move_child(prologue_card,1 if is_instance_valid(video) else 0)
	title.text="第四章：时间迷宫"; title.position=Vector2(594,136); title.size=Vector2(312,40); title.add_theme_color_override("font_color",Color("18374d"))
	body.text="CHAPTER 03.5 · COMPLETE\n\n现场定位：段永平教学楼玻璃门\n当前目标：追踪进入教学楼的异常签到纸"; body.position=Vector2(594,184); body.size=Vector2(312,120); body.add_theme_color_override("font_color",Color("18374d"))
	controls.position=Vector2(594,316); controls.size=Vector2(312,130)
	_button("收下任务，进入第四章",func(): _finish({"acknowledged":true})); _button("重播过场",_restart_prologue); _button("返回",func(): cancelled.emit()); _layout_prologue(); queue_redraw()
func _restart_prologue() -> void:
	if kind!="prologue" or done: return
	_cue("chapter4_prologue_closed"); elapsed=0; cues_fired.clear()
	if is_instance_valid(prologue_card): prologue_card.queue_free(); prologue_card=null
	if is_instance_valid(video) and not prologue_reduced:
		prologue_fallback=false; video.show(); video.stop(); video.stream_position=0; video.paused=false; video.play()
	_prologue_playback_controls(); queue_redraw()
func _draw_prologue_fallback() -> void:
	# Exact source static fallback shapes; source video remains the primary presentation.
	var upper: Color=Color("102d50"); var middle: Color=Color("245f7d"); var lower: Color=Color("152130")
	for y in range(540):
		var t: float=float(y)/540; var color: Color=upper.lerp(middle,t/0.58) if t<0.58 else middle.lerp(lower,(t-0.58)/0.42)
		draw_rect(Rect2(0,y,960,1),color)
	draw_rect(Rect2(0,352,960,188),Color("0b111a")); draw_rect(Rect2(0,352,960,6),Color("263b50")); draw_rect(Rect2(640,92,250,260),Color("111a26"))
	for row in range(3):
		for column in range(4): draw_rect(Rect2(670+column*48,126+row*58,22,18),Color("e7c56b"))
	draw_set_transform(Vector2(480,306),-0.08); draw_rect(Rect2(-39,-27,78,54),Color("554d39")); draw_rect(Rect2(-36,-24,72,48),Color("e8dfc4"))
	for row in [[-24,-8,38,3],[-24,1,48,3],[-24,10,31,3]]: draw_rect(Rect2(row[0],row[1],row[2],row[3]),Color("7b8799"))
	draw_set_transform(Vector2.ZERO)
	if elapsed>=24600 and elapsed<28300 and prologue_portraits.size()==2:
		var art: Texture2D=prologue_portraits[int(elapsed/680)%2]; var dimensions: Vector2=art.get_size(); dimensions*=minf(270/dimensions.x,310/dimensions.y)
		draw_texture_rect(art,Rect2(Vector2(942-dimensions.x,532-dimensions.y),dimensions),false)
func _cue(event: String) -> void:
	if not get_signal_connection_list("presentation_requested").is_empty():
		presentation_requested.emit(event,{})
		return
	for cue in audio_events.get(event,{}).get("cues",[]):
		var settings: Dictionary=config.get("settings",{})
		if cue.get("channel","")=="music" and not settings.get("music",true): continue
		if cue.get("channel","") in ["sfx","ambient"] and not settings.get("effects",true): continue
		if not audio_manifest.has(cue.get("asset","")): continue
		var path: String="res://assets/audio/"+audio_manifest[cue.asset].path
		if not ResourceLoader.exists(path): continue
		var player_audio: AudioStreamPlayer=AudioStreamPlayer.new(); player_audio.stream=load(path); player_audio.volume_db=linear_to_db(maxf(0.001,float(cue.get("volume",0.5))*float(settings.get("volume",1.0)))); add_child(player_audio)
		if cue.get("channel","")=="music": music=player_audio
		else: player_audio.finished.connect(player_audio.queue_free)
		var delay: float=float(cue.get("offsetMs",0))/1000.0
		if delay>0: get_tree().create_timer(delay).timeout.connect(func(): if is_instance_valid(player_audio): player_audio.play())
		else: player_audio.play()
func _elevator_controls() -> void:
	if is_instance_valid(elevator_panel):elevator_panel.refresh(selection,stage,elapsed,boarded,elevator_feedback)
func _shift_elevator(seconds:int) -> void:
	if stage!="select" or done:return
	selection=clampi(selection+seconds,int(config.timeline.selectableStartMinSeconds),int(config.timeline.selectableStartMaxSeconds))
	elevator_feedback="";_elevator_controls()
func _start_elevator_replay() -> void:
	if stage!="select" or done:return
	stage="replay";running=true;elapsed=0;boarded=false;elevator_feedback="";_elevator_controls()
func _board() -> void:
	if stage=="replay" and elapsed<=6000:
		boarded=true;_elevator_controls()
func _save_lamp_answers(value:Dictionary)->void:
	if done or not is_instance_valid(lamp_view):return
	var owner:=get_node_or_null("/root/State")
	var result:Dictionary=owner.act("c4_lamp_answers",{"session":config.get("session",""),"answers":value}) if owner else {"message":"回答未能保存，请重试。"}
	if is_instance_valid(lamp_view) and not done:lamp_view.accept_save(result)
func _reset_chase() -> void:
	landing=clampi(int(config.get("startLanding",0)),0,2)
	var entry:Dictionary=StairChase.guard_entry(landing,float(config.get("guardLeadDistance",650)))
	elapsed=0;player=entry.player;guard=entry.guard;guard_delay_ms=entry.delayMs;chase_animation_ms=0
	trail=[];guard_trail=[player];stage="chase";snapshot_clock=0;guard_target=null;guard_repath=0;running=true;pointer_moving=false
	chase_progress_pending=false;chase_request_remaining_ms=0;chase_capture.cancel()
	_clear_chase_pointer()
	body.text="WASD / 方向键移动；按住地面可指向移动。不要让保安追上。"
	if is_instance_valid(chase_view):chase_view.reset_view(player,guard);chase_overview.reset_view(player,guard)
	_chase_buttons();_present_chase();_layout_chase()

func _clear_chase_pointer():
	pointer_moving=false;chase_touch_axis=Vector2.ZERO;chase_pointer_owner="";chase_finger=-1

func _leave_chase():
	if done:return
	done=true;running=false;_clear_chase_pointer();chase_capture.cancel();chase_progress_pending=false;cancelled.emit()

func _toggle_chase_touch():
	_clear_chase_pointer();chase_touch_enabled=not chase_touch_enabled;_chase_buttons();_layout_chase()

func _chase_buttons():
	_clear_controls()
	_button("隐藏摇杆" if chase_touch_enabled else "显示摇杆",_toggle_chase_touch)
	_button("返回",_leave_chase)
	_layout_chase()

func _layout_chase():
	if kind!="chase_stairwell" or not built or not is_instance_valid(chase_view):return
	var portrait:=size.y>size.x
	title.position=Vector2(16,12);title.size=Vector2(size.x-32,30);title.add_theme_font_size_override("font_size",22)
	controls.set_anchors_preset(Control.PRESET_TOP_LEFT);controls.position=Vector2(12,50);controls.size=Vector2(size.x-24,44);controls.add_theme_constant_override("separation",8)
	for button:Button in controls.get_children():
		button.size_flags_horizontal=Control.SIZE_EXPAND_FILL;button.custom_minimum_size=Vector2(0,44)
		NativeUi.apply_button(button,Color("163c3e"),Color("fff0c2"),Color("b4a77b"),0,2,16,Vector2(8,5),Color("76dfc9"))
	body.position=Vector2(16,102);body.size=Vector2(size.x-32,66 if portrait else 44);body.add_theme_font_size_override("font_size",16);body.add_theme_constant_override("line_spacing",4)
	chase_status.add_theme_font_size_override("font_size",16)
	chase_overview.visible=portrait and size.y>=650
	chase_pad=Rect2()
	if portrait:
		chase_view.position=Vector2(12,178);chase_view.size=Vector2(size.x-24,(size.x-24)*9/16.0)
		chase_status.position=Vector2(16,chase_view.position.y+chase_view.size.y+12);chase_status.size=Vector2(size.x-32,26)
		chase_overview.position=chase_status.position+Vector2(0,36);chase_overview.size=Vector2(size.x-32,minf((size.x-32)*941/1672.0,maxf(80,size.y-chase_overview.position.y-192)))
		if chase_touch_enabled:chase_pad=Rect2(Vector2((size.x-156)/2,size.y-178),Vector2(156,156))
	else:
		var reserved:=176.0 if chase_touch_enabled else 0.0
		chase_view.position=Vector2(12+reserved,152);chase_view.size=Vector2(size.x-24-reserved,maxf(64,size.y-168))
		chase_status.position=Vector2(16,126);chase_status.size=Vector2(size.x-32,26)
		if chase_touch_enabled:chase_pad=Rect2(12,maxf(154,size.y-172),156,156)
	queue_redraw()

func _present_chase():
	if not is_instance_valid(chase_view):return
	var visible_guard:bool=elapsed>=guard_delay_ms
	chase_view.present(player,guard,chase_animation_ms,running,landing,visible_guard)
	chase_overview.present(player,guard,chase_animation_ms,running,landing,visible_guard)
	chase_overview.camera=chase_view.camera
	chase_status.text="已到平台 %d / 2"%landing+(" · 下方为楼梯全貌" if chase_overview.visible else "")

func _chase_pointer_begin(point:Vector2,owner:int)->bool:
	if not running or done or not chase_pointer_owner.is_empty():return false
	if chase_touch_enabled and chase_pad.has_point(point):
		chase_pointer_owner="pad";chase_finger=owner;_chase_pointer_move(point);return true
	var target:Vector2=chase_view.to_world(point-chase_view.position)
	if not target.is_finite():return false
	chase_pointer_owner="field";chase_finger=owner;pointer_moving=true;pointer_target=target;return true

func _chase_pointer_move(point:Vector2):
	if chase_pointer_owner=="pad":
		var offset:Vector2=(point-chase_pad.get_center())/(chase_pad.size.x*.4)
		chase_touch_axis=offset.limit_length(1) if offset.length()>.12 else Vector2.ZERO
	elif chase_pointer_owner=="field":
		var target:Vector2=chase_view.to_world(point-chase_view.position)
		if not target.is_finite():_clear_chase_pointer()
		else:pointer_target=target

func _chase_input(event:InputEvent)->bool:
	if (event is InputEventMouseButton or event is InputEventMouseMotion) and event.device==-1:return false
	if event is InputEventScreenTouch:
		if not event.pressed or event.canceled:
			if event.index==chase_finger:_clear_chase_pointer();return true
			return false
		# The first real finger must not rebuild a Return/Retry button beneath
		# its own press. Capability detection already enables hardware touch.
		if not chase_touch_seen and not Rect2(controls.position,controls.size).has_point(event.position):
			chase_touch_seen=true
			if not chase_touch_enabled:chase_touch_enabled=true;_chase_buttons();_layout_chase()
		return _chase_pointer_begin(event.position,event.index)
	if event is InputEventScreenDrag and event.index==chase_finger:_chase_pointer_move(event.position);return true
	if event is InputEventMouseButton and event.button_index==MOUSE_BUTTON_LEFT:
		if event.pressed:return _chase_pointer_begin(event.position,-2)
		if chase_finger==-2:_clear_chase_pointer();return true
	if event is InputEventMouseMotion and chase_finger==-2:_chase_pointer_move(event.position);return true
	return false
func _rect(r: Dictionary) -> Rect2: return Rect2(float(r.x),float(r.y),float(r.width),float(r.height))
func _walkable(p: Vector2) -> bool:
	for rect in source.stair.walkable:
		if _rect(rect).has_point(p): return true
	return false
func _foot(p: Vector2) -> bool:
	return StairChase.player_open(p)

func _record_chase_sample():
	if elapsed<=0:return
	if trail.is_empty() or float(trail.back().t)<elapsed:trail.append({"x":player.x,"y":player.y,"t":elapsed})

func _chase_proof_payload()->Dictionary:
	return {"kind":kind,"session":config.get("session",""),"expectedAttempt":config.get("expectedAttempt",-1),"path":trail.duplicate(true),"elapsedMs":elapsed}

func resolve_progress(result:Dictionary):
	if not chase_progress_pending or done:return
	chase_progress_pending=false;chase_request_remaining_ms=0
	if result.get("accepted",false):landing=int(result.landing)
	else:body.text="沿平台继续上行，再进入上方楼梯口。"

func _chase_capture_context()->Dictionary:
	var state:Node=get_node_or_null("/root/State");var c:Dictionary=state.d.chapter4 if state else {}
	return {"scene":state.d.native.scene if state else "","floor":c.get("floor",""),"phase":c.get("phase",""),"time":c.get("timeState",""),"mode":c.get("mode",""),"guardMode":c.get("guardMode",""),"attempt":int(c.get("chaseAttempt",-1)),"session":config.get("session","")}

func _chase_context_current()->bool:
	var context:=_chase_capture_context()
	return context.scene=="duan_yongping_temporal_maze" and context.floor=="A1" and context.phase=="final_chase" and context.guardMode=="chase" and context.attempt==int(config.get("expectedAttempt",-1)) and get_node("/root/State").d.chapter4.chaseStairwellStage=="inside"

func _capture_chase():
	_record_chase_sample()
	var proof:=_chase_proof_payload();proof.captured=true;proof.guard={"x":guard.x,"y":guard.y}
	if not chase_capture.begin(_chase_capture_context(),"c4_fail_chase",proof):return
	stage="capture";running=false;_clear_chase_pointer();body.text="保安："+Capture.LINE

func _tick_chase_capture(delta_ms:float):
	if done or not chase_capture.active:return
	if not chase_capture.matches(_chase_capture_context()):_leave_chase();return
	var result:Dictionary=chase_capture.advance(delta_ms,_chase_capture_context(),get_window().has_focus() and is_visible_in_tree())
	if result.is_empty():return
	var proof:Dictionary=result.value;proof.captureMs=chase_capture.elapsed_ms
	done=true;running=false;_clear_chase_pointer();attempt_failed.emit(proof)

func source_stair_handoff()->Dictionary:
	return {"attempt":int(config.get("expectedAttempt",-1)),"destination":"A2","leadDistance":StairChase.exit_lead(guard,player,maxf(0,guard_delay_ms-elapsed))}
func _chase(delta: float) -> void:
	var direction: Vector2=Vector2(float(Input.is_physical_key_pressed(KEY_D) or Input.is_physical_key_pressed(KEY_RIGHT))-float(Input.is_physical_key_pressed(KEY_A) or Input.is_physical_key_pressed(KEY_LEFT)),float(Input.is_physical_key_pressed(KEY_S) or Input.is_physical_key_pressed(KEY_DOWN))-float(Input.is_physical_key_pressed(KEY_W) or Input.is_physical_key_pressed(KEY_UP)))
	direction+=chase_touch_axis
	if direction==Vector2.ZERO and pointer_moving:
		direction=pointer_target-player
		if direction.length()<8: direction=Vector2.ZERO
	direction=direction.normalized()
	var movement: Vector2=direction*208.0*delta
	var candidate: Vector2=player+Vector2(movement.x,0)
	if _foot(candidate): player=candidate
	candidate=player+Vector2(0,movement.y)
	if _foot(candidate): player=candidate
	snapshot_clock+=delta*1000
	if snapshot_clock>=80:
		snapshot_clock=0;_record_chase_sample()
		if guard_trail.is_empty() or Vector2(guard_trail.back()).distance_to(player)>4: guard_trail.append(player)
	if chase_progress_pending:
		chase_request_remaining_ms-=delta*1000
		if chase_request_remaining_ms<=0:chase_progress_pending=false
	if landing<2 and not chase_progress_pending and _rect(source.stair.gates[landing]).has_point(player):
		_record_chase_sample();chase_progress_pending=true;chase_request_remaining_ms=2000
		var proof:=_chase_proof_payload();proof.landing=landing+1;progress_requested.emit(proof)
	if landing==2 and _rect(source.stair.exit).has_point(player):
		_record_chase_sample()
		_finish({"path":trail,"escaped":true,"expectedAttempt":config.get("expectedAttempt",0),"failures":0}); return
	if elapsed>=guard_delay_ms:
		guard_repath-=delta*1000
		if guard_repath<=0 or guard_target==null or guard.distance_to(guard_target)<12:
			var route: Array=StairChase.path(guard,player); guard_target=route[0] if not route.is_empty() else null; guard_repath=260
		if guard_target!=null:
			var candidate_guard: Vector2=guard.move_toward(guard_target,174*delta)
			if StairChase.body_open(candidate_guard,Vector2(20,14)):guard=candidate_guard
		if GuardModel.chase_contact(guard,Rect2(player-PlayerMetrics.FOOT_SIZE/2,PlayerMetrics.FOOT_SIZE)):_capture_chase()

func _process(delta: float) -> void:
	if not built or done: return
	var focused := get_window().has_focus()
	if kind=="star_lamp_closure":
		if is_instance_valid(lamp_view):
			lamp_view.advance(maxf(0,delta)*1000,focused);stage=lamp_view.stage;elapsed=lamp_view.playback_ms
		return
	if kind=="prologue" and focused!=prologue_focused:
		prologue_focused=focused
		if is_instance_valid(video):
			video.paused=not focused or stage=="card"
			if focused: _sync_prologue_video(true)
		presentation_requested.emit("native_activity_resumed" if focused else "native_activity_paused",{"prefixes":["chapter4_prologue_"]})
	if not focused:
		if kind=="chase_stairwell":_clear_chase_pointer()
		return
	if kind=="chase_stairwell":
		if not _chase_context_current():_leave_chase();return
		chase_animation_ms+=maxf(0,delta)*1000
		if chase_capture.active:
			_tick_chase_capture(maxf(0,delta)*1000);_present_chase();queue_redraw();return
	if running:
		var step: float=minf(delta,0.048 if kind=="prologue" else 0.05); elapsed+=step*1000
		match kind:
			"chase_stairwell": _chase(step)
			"elevator_alignment":
				if elapsed>=6000:
					running=false
					if selection==int(config.timeline.correctReplayStartSeconds) and boarded: _finish({"startSeconds":selection,"boarded":true})
					else:
						elevator_feedback="校验结果：两条区间边缘仍未对齐，请调整重放起点。" if selection!=int(config.timeline.correctReplayStartSeconds) else "未在六秒进入窗口内走入电梯，请重新回放。"
						stage="select";_elevator_controls()
				elif is_instance_valid(elevator_panel):elevator_panel.refresh(selection,stage,elapsed,boarded,elevator_feedback)
			"prologue":
				for beat in source.prologue.beats:
					if elapsed>=float(beat.at) and not cues_fired.has(beat.cueEvent): cues_fired[beat.cueEvent]=true; _cue(beat.cueEvent)
				body.text=""
				for subtitle in source.prologue.subtitles:
					if elapsed>=float(subtitle.at) and elapsed<float(subtitle.at)+float(subtitle.durationMs): body.text=subtitle.text
				_sync_prologue_video()
				if elapsed>=43834: _show_prologue_card()
			_: pass
	if kind=="chase_stairwell":_present_chase()
	queue_redraw()
func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO,size),Color("101722"))
	if not built: return
	match kind:
		"prologue":
			if prologue_fallback:
				draw_set_transform(prologue_field.position,0,Vector2.ONE*(prologue_field.size.x/960.0))
				_draw_prologue_fallback()
				draw_set_transform(Vector2.ZERO)
		"chase_stairwell":
			if chase_touch_enabled and chase_pad.has_area():
				draw_circle(chase_pad.get_center(),chase_pad.size.x/2,Color("163c3e"))
				draw_arc(chase_pad.get_center(),chase_pad.size.x/2-2,0,TAU,64,Color("b4a77b"),2)
				draw_circle(chase_pad.get_center()+chase_touch_axis*chase_pad.size.x*.3,24,Color("e8dbac"))
		"star_lamp_closure": pass
		"elevator_alignment": pass
func _map_rect() -> Rect2:
	if kind=="chase_stairwell" and is_instance_valid(chase_view):return Rect2(chase_view.position+chase_view.field.position,chase_view.field.size)
	var available: Vector2=Vector2(size.x,size.y-120); var factor: float=minf(available.x/1672,available.y/941)
	var dimensions: Vector2=Vector2(1672,941)*factor
	return Rect2(Vector2((size.x-dimensions.x)/2,110),dimensions)
func _draw_chase() -> void:
	var rect: Rect2=_map_rect(); var factor: float=rect.size.x/1672
	if plate: draw_texture_rect(plate,rect,false)
	else:
		draw_rect(rect,Color("141b25"))
		for r in source.stair.walkable: draw_rect(Rect2(rect.position+Vector2(r.x,r.y)*factor,Vector2(r.width,r.height)*factor),Color("7c8587"))
	if player_art: draw_texture_rect(player_art,Rect2(rect.position+(player-Vector2(96*0.65/2,128*0.65))*factor,Vector2(96,128)*0.65*factor),false)
	else: draw_circle(rect.position+player*factor,9,Color("f5d481"))
	if elapsed>2000:
		if guard_art:
			var frame: int=int(fmod(elapsed,880)/110); var width: float=float(guard_art.get_width())/8; var height: float=guard_art.get_height()
			draw_texture_rect_region(guard_art,Rect2(rect.position+(guard-Vector2(width*0.68/2,height*0.68))*factor,Vector2(width,height)*0.68*factor),Rect2(frame*width,0,width,height))
		else: draw_circle(rect.position+guard*factor,11,Color("cf5555"))
func _gui_input(event: InputEvent) -> void:
	pass # Chase owns pointer press, move and release together in _input.
func _input(event:InputEvent) -> void:
	if kind=="chase_stairwell":
		if not is_visible_in_tree():_clear_chase_pointer();return
		if event is InputEventKey and event.pressed and not event.echo and event.keycode==KEY_ESCAPE:_leave_chase();get_viewport().set_input_as_handled();return
		if _chase_input(event):get_viewport().set_input_as_handled()
		return
	if kind!="elevator_alignment" or done or not event is InputEventKey or not event.pressed or event.echo:return
	match event.keycode:
		KEY_ESCAPE:cancelled.emit()
		KEY_LEFT,KEY_UP:_shift_elevator(-1)
		KEY_RIGHT,KEY_DOWN:_shift_elevator(1)
		KEY_ENTER,KEY_KP_ENTER:
			if stage=="select":_start_elevator_replay()
			else:_board()
		KEY_SPACE:_board()
		_:return
	get_viewport().set_input_as_handled()
func _unhandled_key_input(event: InputEvent) -> void:
	if not event.is_pressed() or event.is_echo(): return
	if kind=="prologue" and event.keycode==KEY_ESCAPE and stage!="card":
		_skip_prologue(); get_viewport().set_input_as_handled(); return
	if kind=="star_lamp_closure" and is_instance_valid(lamp_view):lamp_view._gui_input(event)

func _exit_tree() -> void:
	if is_instance_valid(lamp_view):lamp_view.dispose()
	_clear_chase_pointer()
	chase_capture.cancel();chase_progress_pending=false
	if kind=="prologue": presentation_requested.emit("chapter4_prologue_closed",{})
	if is_instance_valid(video): video.stop(); video.stream=null
	for child in get_children():
		if child is AudioStreamPlayer: child.stop(); child.stream=null
