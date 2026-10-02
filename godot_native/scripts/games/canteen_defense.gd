extends Control
signal finished(result: Dictionary)
signal cancelled
signal presentation_requested(id: String, payload: Dictionary)
const Model=preload("res://scripts/games/canteen_defense_model.gd")
const MAP_SIZE=Vector2(1672,941)
const MAP_SCALE: float=0.56525
const MAP_OFFSET=Vector2(480,270)-MAP_SIZE*MAP_SCALE/2
var config: Dictionary={}
var model: RefCounted
var running: bool=false
var paused: bool=false
var sent: bool=false
var accumulator: float=0
var retry_wait: float=0
var finish_wait: float=0
var dash_requested: bool=false
var pointer_down: bool=false
var pointer_target: Vector2=Vector2.ZERO
var touch_id: int=-1
var touch_direction: Vector2=Vector2.ZERO
var held: Dictionary={}
var background: Texture2D
var push_sheet: Texture2D
var font: Font
var title: Label
var timer: Label
var hint: Label
var start_button: Button
var pause_button: Button
var dash_button: Button
var occlusions: Array=[]
var _audio_started: bool=false
var _pickup_active: bool=false
var _pickup_elapsed: float=0
var _pickup_beat: int=0
# CanteenInteriorScene.animatePaperBurst: chained authored delays, not guesses.
const PICKUP_CUES: Array=[[0,"canteen_pickup_ticket_handoff"],[850,"canteen_pickup_cutscene_quiet"],[4030,"canteen_paper_package_wait"],[4930,"canteen_paper_package_shake"],[5980,"canteen_paper_burst_started"],[6500,"canteen_paper_camera_impact"]]


func _ready() -> void:
	mouse_filter=Control.MOUSE_FILTER_STOP
	background=load("res://assets/rpg/interiors/canteen_interior.png")
	push_sheet=load("res://assets/rpg/player/player_push_cart_sheet.png")
	font=load("res://assets/rpg/fonts/fusion_pixel_12px_proportional_zh_hans.ttf")
	title=_label(Vector2(25,13),Vector2(500,32),23)
	title.text="食堂 · 守住出口"
	timer=_label(Vector2(25,49),Vector2(750,32),18)
	hint=_label(Vector2(217,488),Vector2(526,46),16)
	hint.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	hint.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	pause_button=_button("暂停",Rect2(702,14,76,38),func(): toggle_pause())
	_button("重试",Rect2(785,14,76,38),func(): restart())
	_button("退出",Rect2(868,14,76,38),func():
		if not sent: cancelled.emit()
	)
	start_button=_button("开始拦截",Rect2(384,299,192,52),func(): begin())
	dash_button=_button("冲刺 · 空格",Rect2(793,445,141,68),func(): dash_requested=true)
	for row: int in range(3):
		for x: int in [227,376,525,675,831,985,1144]:
			var y: int=[361,470,579][row]
			occlusions.append({"rect":Rect2(x-49,y-50,98,100),"sort_y":y+50})
	for r: Rect2 in [Rect2(1344,253,274,154),Rect2(1260,425,368,160),Rect2(1258,620,371,141),Rect2(51,682,418,164),Rect2(542,688,545,188),Rect2(1252,760,53,174),Rect2(1393,760,250,174)]:
		occlusions.append({"rect":r,"sort_y":r.end.y})
	if not config.is_empty(): reset_model()

func setup(parameters: Dictionary) -> void:
	config=parameters.duplicate(true)
	if is_node_ready(): reset_model()

func reset_model() -> void:
	_audio_started=false
	model=Model.new()
	model.configure(str(config.get("seed",config.get("session_id","native-defense"))))
	running=false
	paused=false
	sent=false
	accumulator=0
	retry_wait=0
	finish_wait=0
	clear_input()
	start_button.text="开始拦截"
	start_button.show()
	_pickup_active=bool(config.get("source_pickup_prelude",false)); _pickup_elapsed=0; _pickup_beat=0
	if _pickup_active:
		start_button.hide(); _pickup_tick(0)
	refresh()

func _label(position_value: Vector2, dimensions: Vector2, size_value: int) -> Label:
	var label: Label=Label.new()
	label.position=position_value
	label.size=dimensions
	label.mouse_filter=Control.MOUSE_FILTER_IGNORE
	label.add_theme_color_override("font_color",Color("fff5d7"))
	label.add_theme_font_size_override("font_size",size_value)
	add_child(label)
	return label

func _button(text: String, rect: Rect2, callback: Callable) -> Button:
	var button: Button=Button.new()
	button.text=text
	button.position=rect.position
	button.size=rect.size
	button.pressed.connect(callback)
	add_child(button)
	return button

func clear_input() -> void:
	held.clear()
	dash_requested=false
	pointer_down=false
	touch_id=-1
	touch_direction=Vector2.ZERO

func begin() -> void:
	if not model or _pickup_active: return
	if model.status=="lost": restart()
	paused=false
	running=true
	if not _audio_started:
		_audio_started=true
		presentation_requested.emit("canteen_defense_started",{})
	start_button.hide()
	refresh()

func restart() -> void:
	if not model or sent or _pickup_active: return
	# Source retries keep RNG continuity. Every abandoned/failed input trace is retained.
	if model.status=="running" and model.tick>0:
		# A voluntary restart can be recorded too, but does not count as a failed story attempt.
		reset_model()
	else:
		model.restart_attempt()
		clear_input()
		accumulator=0
		retry_wait=0
		running=true
		paused=false
		start_button.hide()
	refresh()

func toggle_pause() -> void:
	if (not running and not _pickup_active) or sent: return
	paused=not paused
	presentation_requested.emit("native_activity_paused" if paused else "native_activity_resumed",{"prefixes":["canteen_defense_","canteen_pickup_","canteen_paper_package_","canteen_paper_burst_","canteen_paper_camera_"]})
	clear_input()
	start_button.text="继续拦截"
	start_button.visible=paused
	refresh()

func _notification(what: int) -> void:
	if what==NOTIFICATION_APPLICATION_FOCUS_OUT and (running or _pickup_active) and not paused: toggle_pause()

func _input(event: InputEvent) -> void:
	if not visible or not model: return
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
		if code in [KEY_A,KEY_D,KEY_W,KEY_S,KEY_LEFT,KEY_RIGHT,KEY_UP,KEY_DOWN,KEY_SPACE]:
			if event.pressed: held[code]=true
			else: held.erase(code)
			if code==KEY_SPACE and event.pressed and running and not paused: dash_requested=true
			get_viewport().set_input_as_handled()
	if event is InputEventScreenTouch:
		var point: Vector2=get_global_transform_with_canvas().affine_inverse()*event.position
		if event.pressed and point.distance_to(Vector2(98,450))<84 and touch_id<0:
			touch_id=event.index
			touch_direction=(point-Vector2(98,450)).limit_length(55)/55
			get_viewport().set_input_as_handled()
		elif not event.pressed and event.index==touch_id:
			touch_id=-1
			touch_direction=Vector2.ZERO
			get_viewport().set_input_as_handled()
	if event is InputEventScreenDrag and event.index==touch_id:
		var point: Vector2=get_global_transform_with_canvas().affine_inverse()*event.position
		touch_direction=(point-Vector2(98,450)).limit_length(55)/55
		get_viewport().set_input_as_handled()

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index==MOUSE_BUTTON_LEFT and event.device!=-1:
		pointer_down=event.pressed
		pointer_target=(event.position-MAP_OFFSET)/MAP_SCALE
	if event is InputEventMouseMotion and pointer_down: pointer_target=(event.position-MAP_OFFSET)/MAP_SCALE

func _process(delta: float) -> void:
	if _pickup_active:
		if not paused: _pickup_tick(minf(delta,.1)*1000)
		queue_redraw(); return
	if not model: return
	if sent:
		finish_wait-=delta
		if finish_wait<=0:
			var result: Dictionary=model.result()
			result.session_id=config.get("session_id","")
			sent=false
			finished.emit(result)
			set_process(false)
		return
	if running and not paused:
		if model.status=="lost":
			retry_wait-=delta
			if retry_wait<=0: restart()
		else:
			accumulator+=minf(delta,0.1)
			while accumulator>=Model.DT and model.status=="running":
				accumulator-=Model.DT
				var axis: Vector2=Vector2(float(held.has(KEY_D) or held.has(KEY_RIGHT))-float(held.has(KEY_A) or held.has(KEY_LEFT)),float(held.has(KEY_S) or held.has(KEY_DOWN))-float(held.has(KEY_W) or held.has(KEY_UP)))+touch_direction
				if axis.length_squared()==0 and pointer_down:
					var gap: Vector2=pointer_target-(model.player+Model.BODY_CENTER)
					if gap.length()>5: axis=gap.normalized()
				axis=axis.limit_length(1)
				model.step({"x":axis.x,"y":axis.y,"dash":dash_requested})
				dash_requested=false
			if model.status=="lost":
				retry_wait=1.15
				clear_input()
			elif model.status=="won":
				sent=true
				finish_wait=0.85
				clear_input()
	refresh()

func refresh() -> void:
	if not model or not is_instance_valid(timer): return
	timer.text="守住出口  %02d 秒     拦回 %d 次     %s"%[int(ceil(maxf(0,60000-model.elapsed_ms)/1000)),model.turnarounds,"冲刺就绪" if model.dash_cooldown<=0 else "冲刺冷却 %.1fs"%(model.dash_cooldown/1000)]
	pause_button.text="继续" if paused else "暂停"
	dash_button.visible=running and not paused and model.status=="running"
	hint.text="WASD / 方向键移动；空格冲刺\n鼠标按住位置移动；触屏左摇杆 + 冲刺"
	if model.status=="lost": hint.text="纸条从%s溜走了。准备重新拦截"%{"northwest":"左上门","south_gap":"左中下通道","southeast":"右下门"}[model.failure_exit]
	if sent: hint.text="" # Authored victory dialogue belongs to the scene queue after this beat.
	if paused: hint.text="已暂停，计时与纸条位置已冻结"
	queue_redraw()

func _draw() -> void:
	draw_rect(Rect2(0,0,960,540),Color("111d25"))
	if not model or not background: return
	draw_set_transform(MAP_OFFSET,0,Vector2.ONE*MAP_SCALE)
	draw_texture_rect(background,Rect2(Vector2.ZERO,MAP_SIZE),false)
	if model.route_flash>0:
		var points: PackedVector2Array=PackedVector2Array([model.paper])
		for point: Vector2 in model.route: points.append(point)
		if points.size()>1: draw_polyline(points,Color(0.45,0.9,1,model.route_flash/760.0),5)
	var row: int=2
	var origin: Vector2=Vector2(0.5,0.27)
	if absf(model.facing.x)>absf(model.facing.y):
		row=1 if model.facing.x<0 else 3
		origin=Vector2(0.63,0.32) if row==1 else Vector2(0.39,0.32)
	elif model.facing.y>0:
		row=0
		origin.y=0.26
	draw_texture_rect_region(push_sheet,Rect2(model.player-origin*94.2,Vector2(94.2,94.2)),Rect2(model.push_frame*314,row*314,314,314))
	var foot: float=model.body_at(model.player).end.y
	for crop: Dictionary in occlusions:
		if foot<crop.sort_y: draw_texture_rect_region(background,crop.rect,crop.rect)
	_draw_paper()
	draw_set_transform(Vector2.ZERO)
	draw_rect(Rect2(0,0,960,88),Color(0.035,0.06,0.08,0.93))
	draw_rect(Rect2(211,482,538,58),Color(0.035,0.06,0.08,0.85))
	if running and not paused and model.status=="running":
		draw_circle(Vector2(98,450),66,Color(0.025,0.07,0.09,0.7))
		draw_arc(Vector2(98,450),56,0,TAU,40,Color(0.65,0.89,0.9,0.65),2)
		draw_circle(Vector2(98,450)+touch_direction*40,20,Color(0.73,0.9,0.9,0.8))
	if not running or paused or sent:
		draw_rect(Rect2(255,171,450,201),Color(0.03,0.08,0.1,0.96))
		if font:
			draw_string(font,Vector2(279,215),"守住了！" if sent else ("已暂停" if paused else "别让纸条钻出食堂"),HORIZONTAL_ALIGNMENT_CENTER,402,27,Color("fff4c9"))
			draw_string(font,Vector2(270,263),"推车碰到纸条，它就会改换出口",HORIZONTAL_ALIGNMENT_CENTER,420,19,Color("94e0e3"))

func _draw_paper() -> void:
	# Generated from the source 64x50 folded-paper texture geometry.
	var transform: Transform2D=Transform2D(deg_to_rad(model.paper_angle),model.paper)
	var scale_value: Vector2=Vector2(-1.16 if model.paper_flip else 1.16,1.16)
	var lift: float=2 if model.paper_frame%2==0 else 0
	var colors: Array=[Color("60717c"),Color("d7e0e3"),Color("f3f6f3"),Color("e5ebec"),Color("c1ced4")]
	var shapes: Array=[[[7,9],[48,6],[58,34],[17,46],[5,36]],[[5,5],[46,2],[55,30],[15,41],[3,32]],[[5,5],[25,8],[15,41],[3,32]],[[25,8],[46,2],[55,30],[34,27],[15,41]],[[46,2],[55,30],[41,18]]]
	for i: int in range(shapes.size()):
		var points: PackedVector2Array=[]
		for point: Array in shapes[i]: points.append(transform*((Vector2(point[0],point[1]-lift)-Vector2(32,25))*scale_value))
		draw_colored_polygon(points,colors[i])
	for offset: Vector2 in [Vector2(13,13-lift),Vector2(13,20-lift),Vector2(13,25-lift)]:
		var a: Vector2=transform*((offset-Vector2(32,25))*scale_value)
		var b: Vector2=transform*((offset+Vector2(26,0)-Vector2(32,25))*scale_value)
		draw_line(a,b,Color("236f9d"),2.5)

func _exit_tree() -> void:
	presentation_requested.emit("native_activity_closed",{"prefixes":["canteen_defense_","canteen_pickup_","canteen_paper_package_","canteen_paper_burst_","canteen_paper_camera_"]})

func _pickup_tick(milliseconds: float) -> void:
	var before: float=_pickup_elapsed; _pickup_elapsed+=milliseconds
	while _pickup_beat<PICKUP_CUES.size() and float(PICKUP_CUES[_pickup_beat][0])<=_pickup_elapsed:
		presentation_requested.emit(str(PICKUP_CUES[_pickup_beat][1]),{})
		_pickup_beat+=1
	if before<9580 and _pickup_elapsed>=9580:
		hint.text="玩家：那是鸡吗？"
		presentation_requested.emit("native_story_subtitle",{"text":"玩家：那是鸡吗？","durationMs":780,"tone":"player"})
	if before<10480 and _pickup_elapsed>=10480:
		hint.text="系统：现在不是了。"
		presentation_requested.emit("native_story_subtitle",{"text":"系统：现在不是了。","durationMs":780,"tone":"system"})
	if _pickup_elapsed>=11380:
		_pickup_active=false
		config["source_pickup_prelude"]=false
		begin()
