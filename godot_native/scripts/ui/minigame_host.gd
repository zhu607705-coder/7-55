extends Control
## Shared native real-time host; terminal proof is replayed by chapter controllers.
signal finished(result: Dictionary)
signal cancelled
signal presentation_requested(id: String, payload: Dictionary)
const CompactOverlay = preload("res://scripts/ui/compact_overlay_layout.gd")
const NativeUi = preload("res://scripts/ui/native_ui_theme.gd")
const Chase = preload("res://scripts/games/chase_stunt_model.gd")
const Fishing = preload("res://scripts/games/rhythm_fishing_model.gd")
const Kayak = preload("res://scripts/games/kayak_model.gd")
var config: Dictionary={}
var mode: String=""
var model: RefCounted
var running: bool=false
var paused: bool=false
var sent: bool=false
var pending_result: Dictionary={}
var finish_wait: float=0.0
var headline: Label
var status: Label
var hint: Label
var start_button: Button
var pause_button: Button
var retry_button: Button
var exit_button: Button
var overlay_layout: Dictionary={"compact":false}
var _overlay_signature: String=""
var control_buttons: Dictionary={}
var action_sources: Dictionary={}
var touch_sources: Dictionary={}
var _audio_previous: Dictionary={}
var _audio_seen_notes: Dictionary={}
var _audio_next_beat: int=0
var _audio_attempts: int=0
var _audio_failures: int=0
var _audio_terminal_sent: bool=false
var _audio_first_telegraph: bool=false
var background: Texture2D
var rider: Texture2D
var kayak: Texture2D
var font: Font
const FG = Color("eff4e8")
const AQUA = Color("64d2cd")
const GOLD = Color("f5cd74")

func _ready() -> void:
	mouse_filter=Control.MOUSE_FILTER_STOP
	font=load("res://assets/rpg/fonts/fusion_pixel_12px_proportional_zh_hans.ttf")
	headline=_label(Vector2(26,14),Vector2(645,33),24)
	status=_label(Vector2(26,53),Vector2(900,42),18)
	hint=_label(Vector2(160,394),Vector2(640,53),18)
	hint.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	hint.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	pause_button=_button("暂停",Rect2(698,14,75,35),func(): toggle_pause())
	retry_button=_button("重试",Rect2(782,14,75,35),func(): restart())
	exit_button=_button("退出",Rect2(866,14,75,35),func(): cancel_game())
	start_button=_button("开始",Rect2(367,283,226,57),func(): begin())
	if not config.is_empty(): restart()

func setup(parameters: Dictionary) -> void:
	config=parameters.duplicate(true)
	mode=str(config.get("type",""))
	if is_node_ready(): restart()

func restart() -> void:
	for button: Button in control_buttons.values():
		remove_child(button)
		button.queue_free()
	control_buttons.clear()
	_overlay_signature=""
	action_sources.clear()
	touch_sources.clear()
	running=false
	paused=false
	sent=false
	pending_result.clear()
	finish_wait=0.0
	background=null
	_audio_close(true)
	_audio_previous.clear(); _audio_seen_notes.clear(); _audio_next_beat=0; _audio_terminal_sent=false; _audio_first_telegraph=false
	match mode:
		"chase":
			model=Chase.new()
			background=load("res://assets/rpg/canteen_chase/campus_avenue_distance_atlas_273f.png")
			rider=load("res://assets/rpg/canteen_chase/rider_turn_cycle_12f.png")
			_control("left","← A",Rect2(20,446,108,74))
			_control("right","D →",Rect2(137,446,108,74))
			_control("jump","按住蓄力 / 松开跳",Rect2(365,456,230,63))
			_control("bell","铃铛 J",Rect2(700,446,110,74))
			_control("item","道具 E",Rect2(821,446,119,74))
		"rhythm":
			model=Fishing.new()
			var id: String=str(config.get("chartId",config.get("spotId","locker_key")))
			model.configure(id,Fishing.load_chart(id),bool(config.get("assist",false)))
			background=load("res://assets/rpg/qizhen_fishing/qizhen_fishing_dawn_environment.png")
			_control("left","← A 控线",Rect2(20,446,150,74))
			_control("right","D 控线 →",Rect2(180,446,150,74))
			_control("hook","按住收线 / 松开提竿",Rect2(620,446,320,74))
		"kayak":
			model=Kayak.new()
			model.configure(config)
			kayak=load("res://assets/rpg/qizhen/kayak_overhead_frame_a.png")
			_control("left","左桨 A\n下滑反划",Rect2(30,440,185,80))
			_control("right","右桨 D\n下滑反划",Rect2(745,440,185,80))
		_:
			model=null
			status.text="该小游戏尚未接入。剧情未前进。"
	start_button.text="开始"
	start_button.visible=model!=null
	pause_button.text="暂停"
	_refresh()

func _label(at: Vector2, dimensions: Vector2, font_size: int) -> Label:
	var label: Label=Label.new()
	label.position=at
	label.size=dimensions
	label.add_theme_color_override("font_color",FG)
	label.add_theme_font_size_override("font_size",font_size)
	label.mouse_filter=Control.MOUSE_FILTER_IGNORE
	add_child(label)
	return label

func _button(text: String, rect: Rect2, callback: Callable) -> Button:
	var button: Button=Button.new()
	button.text=text
	button.position=rect.position
	button.size=rect.size
	button.set_meta("desktop_rect",rect)
	button.pressed.connect(callback)
	add_child(button)
	return button

func _control(action: String, text: String, rect: Rect2) -> void:
	var button: Button=Button.new()
	button.text=text
	button.position=rect.position
	button.size=rect.size
	button.set_meta("desktop_rect",rect)
	button.focus_mode=Control.FOCUS_NONE
	button.gui_input.connect(func(event: InputEvent):
		if event is InputEventMouseButton and event.button_index==MOUSE_BUTTON_LEFT and event.device!=-1:
			if event.pressed: press_action(action,"mouse:"+action)
			else: release_action(action,"mouse:"+action)
	)
	add_child(button)
	control_buttons[action]=button

func begin() -> void:
	if model==null: return
	if (mode=="rhythm" and model.phase in ["failed","completed"]) or (mode!="rhythm" and model.status=="lost"):
		restart()
	if paused:
		paused=false
		presentation_requested.emit("native_activity_resumed",{"prefixes":_audio_prefixes()})
	else:
		if not running: _audio_begin()
		running=true
	start_button.hide()
	_refresh()

func toggle_pause() -> void:
	if not running or sent: return
	paused=not paused
	presentation_requested.emit("native_activity_paused" if paused else "native_activity_resumed",{"prefixes":_audio_prefixes()})
	if mode in ["chase","rhythm"]: model.neutral()
	action_sources.clear()
	touch_sources.clear()
	start_button.text="继续"
	start_button.visible=paused
	pause_button.text="继续" if paused else "暂停"
	_refresh()

func cancel_game() -> void:
	if sent: return
	running=false
	if mode=="rhythm": presentation_requested.emit("qizhen_fishing_cancelled",_fishing_payload({"reason":"player_cancel"}))
	_audio_close(false)
	cancelled.emit()

func _notification(what: int) -> void:
	if what==NOTIFICATION_APPLICATION_FOCUS_OUT and running and not paused: toggle_pause()

func press_action(action: String, source: String) -> void:
	if not running or paused or sent or model==null: return
	if mode=="kayak":
		model.stroke(action,Input.is_physical_key_pressed(KEY_S) or Input.is_physical_key_pressed(KEY_DOWN))
		_audio_update()
		_check_terminal()
		return
	var sources: Dictionary=action_sources.get(action,{})
	if sources.has(source): return
	sources[source]=true
	action_sources[action]=sources
	model.press(action)
	_audio_update()

func release_action(action: String, source: String) -> void:
	if model==null or mode=="kayak": return
	var sources: Dictionary=action_sources.get(action,{})
	sources.erase(source)
	action_sources[action]=sources
	if sources.is_empty() and running and not paused:
		var before_velocity: float=float(model.air_velocity) if mode=="chase" else 0
		model.release(action)
		if mode=="chase" and action=="jump" and float(model.air_velocity)>before_velocity: _chase_tone("jump")
		_audio_update()
	_check_terminal()

func _input(event: InputEvent) -> void:
	if not visible or model==null: return
	if event is InputEventKey and not event.echo:
		var code: int=event.physical_keycode
		if code in [KEY_ESCAPE,KEY_P] and event.pressed:
			toggle_pause()
			get_viewport().set_input_as_handled()
			return
		if code==KEY_ENTER and event.pressed and (not running or paused):
			begin()
			get_viewport().set_input_as_handled()
			return
		var action: String=""
		if code in [KEY_A,KEY_LEFT]: action="left"
		if code in [KEY_D,KEY_RIGHT]: action="right"
		if code==KEY_SPACE: action="hook" if mode=="rhythm" else "jump"
		if code in [KEY_J,KEY_B]: action="bell"
		if code==KEY_E: action="item"
		if not control_buttons.has(action): return
		if event.pressed: press_action(action,"key:%d"%code)
		else: release_action(action,"key:%d"%code)
		get_viewport().set_input_as_handled()
	if event is InputEventScreenTouch:
		var point: Vector2=get_global_transform_with_canvas().affine_inverse()*event.position
		var source: String="touch:%d"%event.index
		if event.pressed:
			for action: String in control_buttons:
				var button: Button=control_buttons[action]
				if Rect2(button.position,button.size).has_point(point):
					touch_sources[event.index]={"action":action,"start":point}
					if mode!="kayak": press_action(action,source)
					get_viewport().set_input_as_handled()
					break
		elif touch_sources.has(event.index):
			var touch: Dictionary=touch_sources[event.index]
			if mode=="kayak" and running and not paused:
				model.stroke(touch.action,point.y-touch.start.y>25)
				_check_terminal()
			else: release_action(touch.action,source)
			touch_sources.erase(event.index)
			get_viewport().set_input_as_handled()

func _process(delta: float) -> void:
	if model==null: return
	if sent and not pending_result.is_empty():
		finish_wait-=delta
		if finish_wait<=0:
			var result: Dictionary=pending_result.duplicate(true)
			pending_result.clear()
			finished.emit(result)
			return
	if running and not paused and not sent:
		model.update(minf(delta,0.1))
		_audio_update()
		_check_terminal()
	_refresh()

func _check_terminal() -> void:
	if model==null or sent: return
	var result: Dictionary={}
	var lost: bool=false
	if mode=="rhythm":
		if model.phase=="completed":
			if model.final_result.passed: result=model.final_result.duplicate(true)
			else: lost=true
		elif model.phase=="failed": lost=true
	else:
		if model.status=="won": result=model.result()
		elif model.status=="lost": lost=true
	if not result.is_empty():
		sent=true
		running=false
		result["session_id"]=config.get("session_id","")
		if mode=="kayak": result["target_zone"]=config.get("target_zone","")
		pending_result=result
		finish_wait=0.9
	elif lost:
		running=false
		start_button.text="重试"
		start_button.show()

func _refresh() -> void:
	if not is_instance_valid(headline): return
	_layout_overlay()
	pause_button.text="继续" if paused else "暂停"
	headline.text=str(config.get("title",{"chase":"755 米 · 追上纸条","rhythm":"启真湖 · 控线钓鱼","kayak":"启真湖 · 双桨航行"}.get(mode,"7:55")))
	for button: Button in control_buttons.values(): button.visible=running and not paused
	if model==null:
		queue_redraw()
		return
	if mode=="chase":
		status.text="%d / 755 m    机会 %d    连击 %d    %s"%[int(model.distance),model.lives,model.combo,"餐盘护体" if model.shield else ("道具："+model.powerup if model.powerup!="" else "")]
		hint.text=model.feedback
	elif mode=="rhythm":
		status.text="%s · %s    收竿 %d / %d    鱼线张力 %d%%"%[model.rhythm_name,{"casting":"对准鱼影抛竿","count_in":"预备拍","fighting":"跟鱼 · 避猛拽 · 闪金提竿"}[model.stage],model.judged,model.notes.size(),int(model.tension)]
		hint.text=model.cue
		control_buttons.hook.text="按住蓄力 / 松开抛竿" if model.stage=="casting" else "按住收线 / 松开提竿"
	elif mode=="kayak":
		status.text="交替桨 %d    距离 %d / %d    侧倾 %d%%    %s"%[model.tutorial_streak,int(model.distance),int(model.goal),int(absf(model.roll)*100),"天鹅 %d m"%int(model.gap) if model.phase=="chase" else ""]
		hint.text=model.feedback
	if not running and not sent:
		hint.text=str(config.get("instructions",hint.text)) if (mode=="rhythm" and model.phase=="idle") or (mode!="rhythm" and model.status=="running") else hint.text
	if sent: hint.text="追上了！" if mode=="chase" else ("收竿成功" if mode=="rhythm" else "安全抵达")
	if paused: hint.text="已暂停。继续后从同一时刻恢复"
	queue_redraw()

func _layout_overlay() -> void:
	var transform := get_global_transform_with_canvas()
	var display_scale := absf(transform.get_scale().x)
	var viewport_size := get_viewport_rect().size
	var signature := str([mode,viewport_size,transform.origin,display_scale,control_buttons.size()])
	if signature==_overlay_signature: return
	_overlay_signature=signature
	overlay_layout=CompactOverlay.chase(viewport_size,transform.origin,display_scale) if mode=="chase" else {"compact":false}
	var buttons: Array=[pause_button,retry_button,exit_button,start_button]
	buttons.append_array(control_buttons.values())
	if not overlay_layout.compact:
		for button: Button in buttons:
			if not is_instance_valid(button): continue
			var desktop: Rect2=button.get_meta("desktop_rect",Rect2(button.position,button.size))
			button.autowrap_mode=TextServer.AUTOWRAP_OFF
			button.remove_theme_font_size_override("font_size")
			for state: String in ["normal","hover","pressed","hover_pressed","disabled","focus"]: button.remove_theme_stylebox_override(state)
			for state: String in ["font_color","font_hover_color","font_pressed_color","font_hover_pressed_color","font_focus_color","font_disabled_color"]: button.remove_theme_color_override(state)
			button.position=desktop.position; button.size=desktop.size
		for row: Array in [[headline,Rect2(26,14,645,33),24],[status,Rect2(26,53,900,42),18],[hint,Rect2(160,394,640,53),18]]:
			row[0].add_theme_font_size_override("font_size",row[2]); row[0].position=row[1].position; row[0].size=row[1].size
		return
	for row: Array in [[headline,"headline","title_font"],[status,"status","status_font"],[hint,"hint","body_font"]]:
		var rect: Rect2=overlay_layout[row[1]]
		row[0].position=rect.position; row[0].size=rect.size; row[0].add_theme_font_size_override("font_size",overlay_layout[row[2]])
	for row: Array in [[pause_button,"pause"],[retry_button,"retry"],[exit_button,"exit"],[start_button,"start"]]:
		_style_compact_button(row[0],overlay_layout[row[1]],display_scale)
	for action: String in control_buttons:
		_style_compact_button(control_buttons[action],overlay_layout.controls[action],display_scale)

func _style_compact_button(button: Button, rect: Rect2, display_scale: float) -> void:
	# Resolve the new width before larger type can cache a wrapped minimum.
	button.position=rect.position
	button.size=rect.size
	var content_width: float=rect.size.x-12.0/display_scale
	var needs_wrap: bool=font.get_string_size(button.text,HORIZONTAL_ALIGNMENT_LEFT,-1,overlay_layout.button_font).x>content_width
	button.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART if needs_wrap else TextServer.AUTOWRAP_OFF
	NativeUi.apply_button(button,Color("1a4544"),Color("ffedb9"),Color("e6ce8c"),0,maxi(1,ceili(1.0/display_scale)),overlay_layout.button_font,Vector2(6,4)/display_scale,Color("83d9ef"))
	button.position=rect.position
	button.size=rect.size

func _draw() -> void:
	draw_rect(Rect2(0,0,960,540),Color("102530"))
	if background and mode=="chase":
		_draw_chase_background()
	elif background:
		var dimensions: Vector2=background.get_size()
		var scale_factor: float=maxf(960/dimensions.x,540/dimensions.y)
		var rendered: Vector2=dimensions*scale_factor
		draw_texture_rect(background,Rect2((Vector2(960,540)-rendered)/2,rendered),false,Color(0.65,0.72,0.76) if mode=="rhythm" else Color.WHITE)
	if model:
		match mode:
			"chase": _draw_chase()
			"rhythm": _draw_fishing()
			"kayak": _draw_kayak()
	draw_rect(overlay_layout.header_panel if overlay_layout.compact else Rect2(0,0,960,103),Color(0.03,0.08,0.12,0.88))
	draw_rect(overlay_layout.hint_panel if overlay_layout.compact else Rect2(145,388,670,58),Color(0.03,0.08,0.12,0.84))
	if not running or paused:
		draw_rect(overlay_layout.modal_panel if overlay_layout.compact else Rect2(280,161,400,194),Color(0.03,0.08,0.12,0.93))
		if font:
			var title: String="准备好了吗？" if not paused else "已暂停"
			if sent: title="追上了！" if mode=="chase" else ("收竿成功" if mode=="rhythm" else "安全抵达")
			if model and mode!="rhythm" and model.status=="lost": title="从安全点重试"
			if model and mode=="rhythm" and model.phase in ["failed","completed"]: title="再试一次"
			if overlay_layout.compact:
				var title_rect: Rect2=overlay_layout.modal_title
				var detail_rect: Rect2=overlay_layout.modal_detail
				draw_string(font,title_rect.position+Vector2(0,font.get_ascent(overlay_layout.modal_font)),title,HORIZONTAL_ALIGNMENT_CENTER,title_rect.size.x,overlay_layout.modal_font,FG)
				draw_string(font,detail_rect.position+Vector2(0,font.get_ascent(overlay_layout.detail_font)),"本次操作已完成" if sent else "鼠标 / 触屏 / 键盘均可操作",HORIZONTAL_ALIGNMENT_CENTER,detail_rect.size.x,overlay_layout.detail_font,AQUA)
			else:
				draw_string(font,Vector2(345,206),title,HORIZONTAL_ALIGNMENT_CENTER,270,28,FG)
				draw_string(font,Vector2(306,250),"本次操作已完成" if sent else "鼠标 / 触屏 / 键盘均可操作",HORIZONTAL_ALIGNMENT_CENTER,345,18,AQUA)

func road_point(ahead: float, lane: float) -> Vector3:
	var depth: float=clampf(1-ahead/96,0,1)
	var perspective: float=depth*depth
	return Vector3(480+(lane-1)*(36+perspective*210),138+perspective*362,0.16+perspective*1.12)

func _draw_chase() -> void:
	# Source projection coordinates and collision lanes are identical.
	for lane: float in [0.5,1.5]:
		var far: Vector3=road_point(96,lane)
		var near: Vector3=road_point(0,lane)
		draw_line(Vector2(far.x,far.y),Vector2(near.x,near.y),Color(1,1,0.85,0.23),2)
	for ramp: Array in Chase.RAMPS:
		var ahead: float=float(ramp[0])-model.distance
		if ahead<=0 or ahead>96: continue
		var p: Vector3=road_point(ahead,ramp[1])
		draw_colored_polygon(PackedVector2Array([Vector2(p.x-24*p.z,p.y),Vector2(p.x+24*p.z,p.y),Vector2(p.x+19*p.z,p.y-20*p.z),Vector2(p.x-19*p.z,p.y-20*p.z)]),AQUA)
	for i: int in range(Chase.PICKUPS.size()):
		var pick: Array=Chase.PICKUPS[i]
		var ahead: float=float(pick[0])-model.distance
		if ahead<=0 or ahead>96 or model.collected.has(i): continue
		var p: Vector3=road_point(ahead,pick[1])
		draw_circle(Vector2(p.x,p.y-12*p.z),15*p.z,GOLD if pick[2]=="tray" else AQUA)
	var ordered: Array=model.obstacles.duplicate()
	ordered.reverse()
	for obstacle: Dictionary in ordered:
		var ahead: float=float(obstacle.distance)-model.distance
		if ahead<=0 or ahead>96 or model.cleared.has(obstacle.id): continue
		var lane: float=obstacle.lane
		if obstacle.kind=="runner":
			var depth: float=clampf(1-ahead/96,0,1)
			var progress: float=clampf((depth-0.32)/0.62,0,1)
			progress=progress*progress*(3-2*progress)
			lane=lerpf(-1.25 if obstacle.side<0 else 3.25,lane,progress)
		var p: Vector3=road_point(ahead,lane)
		var width: float=37*p.z
		var height: float=(23+float(Chase.HEIGHTS[obstacle.kind])*22)*p.z
		var c: Color=Color("ed8e62") if obstacle.kind in ["cone","barrier"] else Color("847dae")
		draw_rect(Rect2(p.x-width/2,p.y-height,width,height),c)
		draw_line(Vector2(p.x-width/2,p.y-height*0.7),Vector2(p.x+width/2,p.y-height*0.7),FG,3*p.z)
	var paper: Vector3=road_point(model.paper_gap,model.paper_lane)
	draw_rect(Rect2(paper.x-10*paper.z,paper.y-35*paper.z,20*paper.z,26*paper.z),GOLD)
	var player: Vector3=road_point(5,model.lane)
	draw_circle(Vector2(player.x,player.y),30,Color(0,0,0,0.28))
	if rider:
		var row: int=0 if model.velocity < -0.3 else (2 if model.velocity>0.3 else 1)
		var frame: int=int(model.elapsed*8)%4
		draw_texture_rect_region(rider,Rect2(player.x-43,player.y-135-model.air_height*33,86,129),Rect2(frame*256,row*384,256,384),Color(1,1,1,0.45) if model.invulnerable>0 and int(model.elapsed*12)%2==0 else Color.WHITE)
	if model.shield: draw_arc(Vector2(player.x,player.y-60),55,0,TAU,32,AQUA,3)
	if model.bell_pulse>0: draw_arc(Vector2(player.x,player.y-55),55+(1-model.bell_pulse)*130,PI,TAU,24,Color(1,0.84,0.35,model.bell_pulse),4)
	if model.charge>0: draw_rect(Rect2(player.x-35,player.y-145,70*model.charge,6),GOLD)

func _draw_fishing() -> void:
	var center: Vector2=Vector2(480,252)
	draw_rect(Rect2(160,194,640,113),Color(0.02,0.16,0.21,0.9))
	var fish_x: float=480+model.fish_x()*290
	var line_x: float=480+model.line_x*290
	var fish_color: Color=GOLD if model.lift_ready() else (Color("ed826c") if model.rushing_at(model.elapsed) else AQUA)
	draw_circle(Vector2(fish_x,248),16,fish_color)
	draw_colored_polygon(PackedVector2Array([Vector2(fish_x-12,248),Vector2(fish_x-30,236),Vector2(fish_x-30,260)]),fish_color)
	draw_line(Vector2(line_x,132),Vector2(line_x,271),FG,2)
	draw_circle(Vector2(line_x,270),8,FG)
	if model.stage=="fighting":
		var steady: float=clampf(model.tracking_seconds/(0.25 if model.assist else 0.42),0,1)
		draw_rect(Rect2(line_x-37,288,74,5),Color("18262a"))
		draw_rect(Rect2(line_x-37,288,74*steady,5),GOLD if steady>=1 else AQUA)
	var tolerance: float=(0.34 if model.assist else 0.25)*290
	draw_arc(Vector2(line_x,248),tolerance,PI*1.12,PI*1.88,30,Color(1,1,1,0.2),2)
	draw_rect(Rect2(170,318,620,10),Color("15232d"))
	draw_rect(Rect2(170,318,620*model.tension/100,10),Color("ec836f") if model.tension>=80 else AQUA)
	if model.stage=="casting":
		draw_rect(Rect2(260,354,440,13),Color("1a2630"))
		draw_rect(Rect2(392,354,264,13),Color("458f68"))
		draw_rect(Rect2(260,350,440*model.cast_power(),21),Color(1,0.87,0.5,0.65))
	else:
		var rhythm: Vector2=model.rhythm_position(model.elapsed)
		for beat: int in range(4):
			var c: Color=GOLD if beat==3 else AQUA
			draw_circle(Vector2(350+beat*86,360),20,c if beat==int(rhythm.x) else Color(0.2,0.28,0.3))
			if font: draw_string(font,Vector2(329+beat*86,366),["稳","放","收","提"][beat],HORIZONTAL_ALIGNMENT_CENTER,42,18,FG)
		var note: Dictionary=model.current_note()
		if not note.is_empty():
			var until: float=float(note.timeSec)-model.elapsed
			draw_rect(Rect2(260,378,440*clampf(1-until/(4*model.beat_sec),0,1),4),GOLD)

func _draw_kayak() -> void:
	draw_rect(Rect2(0,103,960,280),Color("26798a"))
	draw_rect(Rect2(0,103,960,40),Color("5b8271"))
	draw_rect(Rect2(0,368,960,23),Color("5b8271"))
	for i: int in range(17):
		var x: float=fposmod(i*73-model.distance,1000)-20
		draw_line(Vector2(x,185+(i%4)*42),Vector2(x+35,185+(i%4)*42),Color(0.55,0.92,0.95,0.25),2)
	var boat_position: Vector2=Vector2(480,model.position.y)
	if model.phase=="chase":
		var swan_position: Vector2=Vector2(480+model.swan.x-model.position.x,model.swan.y)
		draw_circle(swan_position,24,Color("151923"))
		draw_line(swan_position,swan_position+Vector2(35,-20),Color("151923"),12)
		draw_circle(swan_position+Vector2(36,-24),10,Color("151923"))
		if model.pressure=="charge_warning": draw_arc(swan_position,40,0,TAU,30,GOLD,4)
	if kayak:
		draw_set_transform(boat_position,model.heading+PI/2+model.roll*0.15)
		draw_texture_rect(kayak,Rect2(-43,-54,86,108),false)
		draw_set_transform(Vector2.ZERO)
	else: draw_circle(boat_position,25,GOLD)
	if absf(model.speed)>1:
		var rear: Vector2=boat_position-Vector2(cos(model.heading),sin(model.heading))*55*signf(model.speed)
		draw_arc(rear,30,0.2,PI-0.2,15,FG,2)
	draw_rect(Rect2(315,463,330,10),Color("1a2630"))
	draw_rect(Rect2(480+minf(0,model.roll)*165,463,absf(model.roll)*165,10),Color("ed836b"))
	if font: draw_string(font,Vector2(302,501),"S / ↓ + 划桨：后退",HORIZONTAL_ALIGNMENT_CENTER,350,17,FG)

func _draw_chase_background() -> void:
	const KEYS = [0,47,95,143,190,238,285,331,377,424,470,518,566,600,635,668,700,755]
	var distance: float=0 if model==null else model.distance
	var lower: int=0
	for i: int in range(1,KEYS.size()):
		if KEYS[i]>distance: break
		lower=i
	var upper: int=mini(lower+1,KEYS.size()-1)
	var progress: float=1 if lower==upper else clampf((distance-KEYS[lower])/float(KEYS[upper]-KEYS[lower]),0,1)
	var frame: int=mini(272,int(floor(lower*16+progress*16))) if lower<17 else 272
	draw_texture_rect_region(background,Rect2(0,0,960,540),Rect2((frame%16)*320,floor(frame/16.0)*180,320,180))

# Read-only source audio adapters. None of these callbacks advance physics or facts.
func _fishing_payload(extra: Dictionary={}) -> Dictionary:
	var value: Dictionary={"sessionId":str(config.get("session_id","")),"spotId":str(config.get("spotId",config.get("chartId","locker_key")))}
	value.merge(extra,true); return value

func _audio_prefixes() -> Array:
	return ["native_chase_","canteen_chase_"] if mode=="chase" else ["native_fishing_","qizhen_fishing_"] if mode=="rhythm" else ["qizhen_swan_chase_","rpg_qizhen_chase_"]

func _audio_close(terminal: bool) -> void:
	var prefixes: Array=["native_chase_","native_fishing_"]
	if not terminal and mode=="chase": prefixes.append_array(["canteen_chase_started","canteen_chase_collision","canteen_chase_finish"])
	elif not terminal and mode=="kayak": prefixes.append_array(["rpg_qizhen_chase_started","rpg_qizhen_chase_restarted","qizhen_swan_chase_"])
	presentation_requested.emit("native_activity_closed",{"prefixes":prefixes})

func _exit_tree() -> void:
	_audio_close(sent)

func _chase_tone(kind: String) -> void:
	presentation_requested.emit("native_chase_tone",{"kind":kind})

func _audio_begin() -> void:
	if mode=="rhythm":
		presentation_requested.emit("qizhen_fishing_started",_fishing_payload({"chartId":model.chart_id,"targetLabel":config.get("title",""),"totalNotes":model.notes.size(),"assist":model.assist}))
	elif mode=="kayak" and model.phase=="chase":
		presentation_requested.emit("rpg_qizhen_chase_started" if _audio_attempts==0 else "rpg_qizhen_chase_restarted",{"zone":"channel"})
	_audio_attempts+=1
	_audio_previous=_audio_snapshot()

func _audio_snapshot() -> Dictionary:
	if model==null: return {}
	if mode=="chase": return {"collisions":model.collisions,"lives":model.lives,"status":model.status,"collected":model.collected.size(),"powerup":model.powerup,"shield":model.shield,"bell":model.bell_cooldown}
	if mode=="kayak": return {"pressure":model.pressure,"segment":model.segment,"status":model.status}
	return {}

func _audio_update() -> void:
	if model==null: return
	if mode=="chase":
		var previous: Dictionary=_audio_previous
		if int(model.collisions)>int(previous.get("collisions",model.collisions)):
			_chase_tone("collision")
			presentation_requested.emit("canteen_chase_collision",{"collisions":model.collisions,"lives":model.lives})
		if float(model.bell_cooldown)>float(previous.get("bell",model.bell_cooldown))+.001: _chase_tone("bell")
		if int(model.collected.size())>int(previous.get("collected",model.collected.size())) and str(previous.get("powerup",""))=="": _chase_tone("collect")
		if int(model.lives)>int(previous.get("lives",model.lives)) or (bool(previous.get("shield",false)) and not model.shield) or (str(previous.get("powerup",""))!="" and model.powerup==""): _chase_tone("item")
		if model.status in ["won","lost"] and not _audio_terminal_sent:
			_audio_terminal_sent=true; _chase_tone("finish")
			presentation_requested.emit("canteen_chase_finish",{"result":model.status,"mode":"story","distance":int(floor(model.distance)),"lives":model.lives,"collisions":model.collisions})
	elif mode=="rhythm":
		for note in model.notes:
			if str(note.judgment)=="" or _audio_seen_notes.has(note.index): continue
			_audio_seen_notes[note.index]=true
			presentation_requested.emit("native_fishing_judgment",{"judgment":note.judgment})
			if float(model.tension)>=80 and float(model.tension)<100: presentation_requested.emit("qizhen_fishing_warning",_fishing_payload({"kind":"tension_high","tension":int(round(model.tension))}))
		if model.phase=="running" and model.stage!="casting":
			while _metronome_time(_audio_next_beat)<=float(model.elapsed-model.cast_at)+.12:
				var at: float=_metronome_time(_audio_next_beat)
				presentation_requested.emit("native_fishing_beat",{"beat":_audio_next_beat,"offsetMs":maxf(0,(at-float(model.elapsed-model.cast_at))*1000),"beatDurationSec":_metronome_time(_audio_next_beat+1)-at})
				_audio_next_beat+=1
		if (model.phase=="failed" or (model.phase=="completed" and not model.final_result.get("passed",false))) and not _audio_terminal_sent:
			_audio_terminal_sent=true; _audio_failures+=1
			var details: Dictionary={"reason":model.failure if model.phase=="failed" else "grade","failures":_audio_failures,"assistNext":_audio_failures>=2}
			if model.phase=="completed": details.result=model.final_result.duplicate(true)
			presentation_requested.emit("qizhen_fishing_failed",_fishing_payload(details))
			presentation_requested.emit("native_activity_closed",{"prefixes":["native_fishing_"]})
	elif mode=="kayak" and model.phase=="chase":
		var event: String=""
		if model.segment=="final_bank" and _audio_previous.get("segment")!="final_bank": event="final_bank"
		elif model.pressure!=_audio_previous.get("pressure"):
			if model.pressure=="release_warning": event="release"
			elif model.pressure=="charge_warning": event="telegraph"
			elif model.pressure=="charge": event="surge"
		if event!="":
			presentation_requested.emit("qizhen_swan_chase_"+event,{"cycle":model.cycle_index,"segment":model.segment,"gap":maxi(0,int(round(model.gap)))})
			if event=="telegraph" and not _audio_first_telegraph:
				_audio_first_telegraph=true
				presentation_requested.emit("qizhen_swan_chase_telegraph_voice",{"cycle":model.cycle_index})
		if model.status in ["won","lost"] and not _audio_terminal_sent:
			_audio_terminal_sent=true
			if model.status=="won": presentation_requested.emit("rpg_qizhen_escape_completed_requested",{"zone":"dock","distance":int(round(model.distance)),"completion":"far_bank_reached"})
			elif float(model.elapsed)>=4 and float(model.gap)<=104: presentation_requested.emit("rpg_qizhen_chase_failed",{"reason":"swan_caught","zone":"channel","distance":int(round(model.distance)),"attempt":int(config.get("audio_chase_attempt",0))+_audio_attempts,"restartCheckpoint":"qizhen_chase"})
	_audio_previous=_audio_snapshot()

func _metronome_time(beat: int) -> float:
	return beat*float(model.beat_sec) if beat<4 else 4*float(model.beat_sec)+float(model.phrase_time(beat-4))
