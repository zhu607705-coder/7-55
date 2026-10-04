extends Control
signal completed(result: Dictionary)
signal cancelled
signal presentation_requested(id: String,payload: Dictionary)
const StairChase = preload("res://scripts/games/chapter4_chase_stair_model.gd")
const GuardModel = preload("res://scripts/games/chapter4_guard_model.gd")
const Source = preload("res://scripts/games/chapter4_stair_model.gd")
var config: Dictionary={}
var source: Dictionary={}
var kind: String=""
var elapsed: float=0
var running: bool=true
var done: bool=false
var title: Label
var body: Label
var controls: VBoxContainer
var stage: String=""
var selection: int=81807
var boarded: bool=false
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

func uses_activity_layout() -> bool:
	return kind == "prologue"

func configure_activity_layout(available: Vector2, _compact: bool) -> void:
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
	controls=VBoxContainer.new(); controls.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_RIGHT); controls.position=Vector2(-310,-220); controls.size=Vector2(286,200); add_child(controls)
	match kind:
		"elevator_alignment":
			running=false; stage="select"; _elevator_controls()
		"chase_stairwell":
			var file: String="res://assets/rpg/interiors/finale/finale_stairwell.png"
			if ResourceLoader.exists(file): plate=load(file)
			body.text="WASD / 方向键移动；按住地面可指向移动。不要让保安追上。"
			if ResourceLoader.exists("res://assets/rpg/player/player_up_0.png"): player_art=load("res://assets/rpg/player/player_up_0.png")
			if ResourceLoader.exists("res://assets/rpg/npcs/finale/guard_walk_up_8frame.png"): guard_art=load("res://assets/rpg/npcs/finale/guard_walk_up_8frame.png")
			_reset_chase()
		"star_lamp_closure":
			running=false; stage="questions"; _build_starfield()
			for key in ["dark","outline","leds","core","glow"]:
				var file: String="res://assets/rpg/cinematics/chapter4-755/canruo-star-lamp/lamp_"+key+".png"
				if ResourceLoader.exists(file): lamp[key]=load(file)
			if config.get("answersSaved",false):
				answers=config.get("selectedAnswers",{}).duplicate()
				body.text="第一问：到浙大来做什么？\n第二问：将来毕业后要做什么样的人？"
				_button("确认并点亮",_begin_lamp_playback)
			else: _question()
		"prologue": _prologue()
		"dialogue":
			running=false; _button("继续",func(): _finish({"acknowledged":true}))
		_:
			running=false; body.text="该活动未接入。剧情未前进。"
	if kind!="prologue": _button("返回",func(): cancelled.emit())
	queue_redraw()
func _button(text: String,callback: Callable) -> Button:
	var button: Button=Button.new(); button.text=text; button.custom_minimum_size.y=42; button.pressed.connect(callback); controls.add_child(button); return button
func _clear_controls() -> void:
	for child in controls.get_children():
		if kind=="prologue": controls.remove_child(child)
		child.queue_free()
func _finish(proof: Dictionary={}) -> void:
	if done: return
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
	_clear_controls()
	var slider: HSlider=HSlider.new(); slider.min_value=config.timeline.selectableStartMinSeconds; slider.max_value=config.timeline.selectableStartMaxSeconds; slider.step=1; slider.value=selection; slider.value_changed.connect(func(v): selection=int(v); queue_redraw()); controls.add_child(slider)
	_button("开始轨迹回放",func(): stage="replay"; running=true; elapsed=0; boarded=false; _clear_controls(); _button("走入电梯",_board); _button("返回",func(): cancelled.emit()))
	body.text="调节回放起点，让六秒进入窗口覆盖门体轨迹。"
func _board() -> void:
	if stage=="replay" and elapsed<=6000: boarded=true; body.text="乘客轨迹正在回放。"
func _question() -> void:
	_clear_controls()
	var question: Dictionary=config.questions[question_index]; body.text=question.prompt
	for option in question.options:
		_button(option.label,_answer.bind(question.id,option.id))
func _answer(id: String,value: String) -> void:
	if stage!="questions": return
	answers[id]=value
	if question_index==0: question_index=1; _question()
	else:
		var owner: Node=get_node_or_null("/root/State")
		if not owner: body.text="回答未能保存，请重试。"; return
		var result: Dictionary=owner.act("c4_lamp_answers",{"session":config.get("session",""),"answers":answers})
		if not result.get("accepted",false): body.text=result.get("message","回答未能保存，请重试。"); return
		_begin_lamp_playback()
func _begin_lamp_playback() -> void:
	stage="playback"; elapsed=0; running=true; body.text=""; _clear_controls()
func _reset_chase() -> void:
	elapsed=0; player=Vector2(833,826); guard=Vector2(833,922); trail=[]; guard_trail=[Vector2(833,826)]; landing=0; stage="chase"; snapshot_clock=0; guard_target=null; guard_repath=0; running=true; pointer_moving=false
	_clear_controls(); _button("返回",func(): cancelled.emit())
func _rect(r: Dictionary) -> Rect2: return Rect2(float(r.x),float(r.y),float(r.width),float(r.height))
func _walkable(p: Vector2) -> bool:
	for rect in source.stair.walkable:
		if _rect(rect).has_point(p): return true
	return false
func _foot(p: Vector2) -> bool:
	for x in [-8,0,8]:
		for y in [-5,0,5]:
			if not _walkable(p+Vector2(x,y)): return false
	return true
func _chase(delta: float) -> void:
	var direction: Vector2=Vector2(float(Input.is_physical_key_pressed(KEY_D) or Input.is_physical_key_pressed(KEY_RIGHT))-float(Input.is_physical_key_pressed(KEY_A) or Input.is_physical_key_pressed(KEY_LEFT)),float(Input.is_physical_key_pressed(KEY_S) or Input.is_physical_key_pressed(KEY_DOWN))-float(Input.is_physical_key_pressed(KEY_W) or Input.is_physical_key_pressed(KEY_UP)))
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
		snapshot_clock=0; trail.append({"x":player.x,"y":player.y,"t":elapsed})
		if guard_trail.is_empty() or Vector2(guard_trail.back()).distance_to(player)>4: guard_trail.append(player)
	if landing<2 and _rect(source.stair.gates[landing]).has_point(player): landing+=1
	if landing==2 and _rect(source.stair.exit).has_point(player):
		if trail.is_empty() or float(trail.back().t)!=elapsed: trail.append({"x":player.x,"y":player.y,"t":elapsed})
		_finish({"path":trail,"escaped":true,"expectedAttempt":config.get("expectedAttempt",0),"failures":failures}); return
	if elapsed>2000:
		guard_repath-=delta*1000
		if guard_repath<=0 or guard_target==null or guard.distance_to(guard_target)<12:
			var route: Array=StairChase.path(guard,player); guard_target=route[0] if not route.is_empty() else null; guard_repath=260
		if guard_target!=null:
			var candidate_guard: Vector2=guard.move_toward(guard_target,174*delta)
			if StairChase.foot_open(candidate_guard): guard=candidate_guard
		if GuardModel.chase_contact(guard,Rect2(player-Vector2(8,5),Vector2(16,10))):
			stage="caught"; running=false; failures+=1; body.text="保安追上了你。重新从楼梯入口开始。"; _clear_controls(); _button("重试楼梯间",_reset_chase); _button("返回",func(): cancelled.emit())

func _process(delta: float) -> void:
	if not built or done: return
	var focused := get_window().has_focus()
	if kind=="prologue" and focused!=prologue_focused:
		prologue_focused=focused
		if is_instance_valid(video):
			video.paused=not focused or stage=="card"
			if focused: _sync_prologue_video(true)
		presentation_requested.emit("native_activity_resumed" if focused else "native_activity_paused",{"prefixes":["chapter4_prologue_"]})
	if not focused: return
	if running:
		var step: float=minf(delta,0.048 if kind=="prologue" else 0.05); elapsed+=step*1000
		match kind:
			"chase_stairwell": _chase(step)
			"elevator_alignment":
				if elapsed>=6000:
					running=false
					if selection==int(config.timeline.correctReplayStartSeconds) and boarded: _finish({"startSeconds":selection,"boarded":true})
					else: body.text="乘客轨迹与门体窗口错开了。"; stage="select"; _elevator_controls()
			"star_lamp_closure":
				if stage=="playback" and elapsed>=5800:
					stage="final"; running=false; body.text="从此，你将与历史上众多灿若星辰的名字一起，共享'浙大人'这个无上荣光的称号！"; _button("我记住了",func(): _finish({"consumer":"ChapterFourStarLampClosure","answers":answers,"playbackMs":elapsed,"acknowledged":true}))
			"prologue":
				for beat in source.prologue.beats:
					if elapsed>=float(beat.at) and not cues_fired.has(beat.cueEvent): cues_fired[beat.cueEvent]=true; _cue(beat.cueEvent)
				body.text=""
				for subtitle in source.prologue.subtitles:
					if elapsed>=float(subtitle.at) and elapsed<float(subtitle.at)+float(subtitle.durationMs): body.text=subtitle.text
				_sync_prologue_video()
				if elapsed>=43834: _show_prologue_card()
			_: pass
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
		"chase_stairwell": _draw_chase()
		"star_lamp_closure": _draw_lamp()
		"elevator_alignment":
			var origin: Vector2=Vector2(size.x*0.15,size.y*0.4); var width: float=size.x*0.56
			draw_rect(Rect2(origin,Vector2(width,100)),Color("334151"))
			var start: float=float(selection-int(config.timeline.selectableStartMinSeconds)); var true_start: float=float(int(config.timeline.correctReplayStartSeconds)-int(config.timeline.selectableStartMinSeconds))
			draw_rect(Rect2(origin+Vector2(true_start/16*width,15),Vector2(8.0/16*width,20)),Color("719bac"))
			draw_rect(Rect2(origin+Vector2(start/16*width,65),Vector2(6.0/16*width,20)),Color("d0ad60"))
			if stage=="replay": draw_line(origin+Vector2((start+elapsed/1000)/16*width,0),origin+Vector2((start+elapsed/1000)/16*width,100),Color.WHITE,3)
			title.text="电梯乘客残影 · %02d:%02d:%02d"%[selection/3600,(selection%3600)/60,selection%60]
func _map_rect() -> Rect2:
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
func _smooth(value: float) -> float:
	var t: float=clampf(value,0,1); return t*t*t*(t*(t*6-15)+10)
func _build_starfield() -> void:
	stars=[]
	for layer in [{"count":4200,"min":38.0,"max":54.0,"size":0.12,"color":Color("97acd2"),"opacity":0.5,"seed":1.1},{"count":1600,"min":28.0,"max":38.0,"size":0.19,"color":Color("d4dded"),"opacity":0.66,"seed":2.4},{"count":520,"min":20.0,"max":28.0,"size":0.28,"color":Color("ffe7ae"),"opacity":0.82,"seed":4.7}]:
		var rng: int=int(floor(float(layer.seed)*1000003))&0xffffffff
		for i in range(int(layer.count)):
			rng=(rng*1664525+1013904223)&0xffffffff; var radius: float=float(layer.min)+float(rng)/4294967296.0*(float(layer.max)-float(layer.min))
			rng=(rng*1664525+1013904223)&0xffffffff; var ct: float=float(rng)/4294967296.0*2-1
			rng=(rng*1664525+1013904223)&0xffffffff; var phi: float=float(rng)/4294967296.0*TAU
			var st: float=sqrt(1-ct*ct)
			stars.append({"p":Vector3(radius*st*cos(phi),radius*ct,radius*st*sin(phi)),"size":layer.size,"color":layer.color,"opacity":layer.opacity,"seed":layer.seed})
func _draw_lamp() -> void:
	var playback: bool=stage in ["playback","final"]
	var t: float=elapsed if playback else 0.0
	var rise: float=_smooth((t-120)/2080) if playback else 1.0
	var scale_factor: float=lerpf(1.16,0.92,rise)
	var artwork_bounds: Vector2=size*1.14
	var art_size: Vector2=artwork_bounds
	if lamp.has("dark"):
		var texture: Texture2D=lamp.dark; art_size=Vector2(texture.get_width(),texture.get_height()); art_size*=minf(artwork_bounds.x/art_size.x,artwork_bounds.y/art_size.y)
	art_size*=scale_factor
	var rect: Rect2=Rect2((size-art_size)*0.5+Vector2(0,lerpf(-0.22,0,rise)*artwork_bounds.y),art_size)
	var camera: Vector3=Vector3(0,lerpf(-5.8,0.35,rise),-lerpf(12.4,15.8,rise))
	var forward: Vector3=(Vector3(0,lerpf(-4.1,0.25,rise),0)-camera).normalized()
	var right: Vector3=forward.cross(Vector3.UP).normalized(); var up: Vector3=right.cross(forward).normalized()
	var focal: float=size.y/(2*tan(deg_to_rad(44.0)/2))
	var glow: float=_smooth((t-2930)/960)*0.26
	for star in stars:
		var relative: Vector3=Vector3(star.p)-camera; var depth: float=relative.dot(forward)
		if depth<=0.1 or depth>=120: continue
		var pos: Vector2=Vector2(size.x/2+relative.dot(right)/depth*focal,size.y/2-relative.dot(up)/depth*focal)
		if not Rect2(Vector2.ZERO,size).has_point(pos): continue
		var color: Color=star.color; color.a=float(star.opacity)*(0.68+glow*0.12)*(0.88+sin(t*0.0012+float(star.seed))*0.12)
		draw_circle(pos,maxf(0.35,float(star.size)*focal/depth/2),color)
	for key in ["dark","outline","glow","core","leds"]:
		if not lamp.has(key): continue
		var alpha: float=1; var brightness: float=1
		match key:
			"dark": brightness=0.56
			"outline": alpha=0.44; brightness=0.72
			"leds": alpha=_smooth((t-2350)/780)*0.7; brightness=0.94
			"core": alpha=_smooth((t-2750)/800)*0.62; brightness=0.96
			"glow": alpha=glow; brightness=0.9
		# The source renderer is viewport-clipped. Crop rather than letting the
		# camera-rise artwork paint over the surrounding phone/task shell.
		var region: Dictionary=_lamp_visible_region(rect,lamp[key].get_size())
		if not region.is_empty(): draw_texture_rect_region(lamp[key],region.destination,region.source,Color(brightness,brightness,brightness,alpha))
	if playback and t<260: draw_rect(Rect2(Vector2.ZERO,size),Color(0,0,0,1-_smooth(t/260)))
func _lamp_visible_region(destination: Rect2,dimensions: Vector2) -> Dictionary:
	var visible: Rect2=destination.intersection(Rect2(Vector2.ZERO,size))
	if not visible.has_area(): return {}
	var source_rect:=Rect2((visible.position-destination.position)/destination.size*dimensions,visible.size/destination.size*dimensions)
	return {"destination":visible,"source":source_rect}
func _gui_input(event: InputEvent) -> void:
	if kind=="chase_stairwell":
		if event is InputEventMouseButton and event.button_index==MOUSE_BUTTON_LEFT:
			pointer_moving=event.pressed; pointer_target=(event.position-_map_rect().position)/(_map_rect().size.x/1672)
		elif event is InputEventMouseMotion and pointer_moving: pointer_target=(event.position-_map_rect().position)/(_map_rect().size.x/1672)
func _unhandled_key_input(event: InputEvent) -> void:
	if not event.is_pressed() or event.is_echo(): return
	if kind=="prologue" and event.keycode==KEY_ESCAPE and stage!="card":
		_skip_prologue(); get_viewport().set_input_as_handled(); return
	if kind=="elevator_alignment" and event.keycode==KEY_SPACE: _board()
	if kind=="star_lamp_closure" and stage=="final" and event.keycode in [KEY_SPACE,KEY_ENTER]: _finish({"consumer":"ChapterFourStarLampClosure","answers":answers,"playbackMs":elapsed,"acknowledged":true})

func _exit_tree() -> void:
	if kind=="prologue": presentation_requested.emit("chapter4_prologue_closed",{})
	if is_instance_valid(video): video.stop(); video.stream=null
	for child in get_children():
		if child is AudioStreamPlayer: child.stop(); child.stream=null
