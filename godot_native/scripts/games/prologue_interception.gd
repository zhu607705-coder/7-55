extends Control
## Source-authored paths/timing, using one coordinate-error window as the paddle.
signal finished(result: Dictionary)
signal cancelled
signal presentation_requested(id: String, payload: Dictionary)
const DURATIONS = [2.2,1.9,1.65]
const DIALOGUE = ["旁白：嘿！你到底在干什么？放开我！", "玩家：不，除非你帮助我", "玩家：不然你就和我的绩点同归于尽吧", "旁白：哦，好吧，好吧！但你先把手放开！"]
var phase = "success"
var elapsed = 0.0
var blocks = 0
var misses = 0
var paddle = 50.0
var orb = Vector2(82,12)
var hold_ms = 0.0
var holding = false
var dragging = false
var paused = false
var done = false
var dialogue_index = 0
var intro_elapsed_ms: float = 0.0
var intro_segments: Array = []
var config: Dictionary = {}
var retry: Button
var resume_button: Button
var field = Rect2()

func _ready() -> void:
	var content: Variant = JSON.parse_string(FileAccess.get_file_as_string("res://data/source/act-one-bootstrap.content.json"))
	if content is Dictionary: intro_segments = content.get("audioNarration",{}).get("prologue_narrator_intro",{}).get("subtitleSegmentsZh",[])
	mouse_filter = Control.MOUSE_FILTER_STOP
	focus_mode = Control.FOCUS_ALL
	grab_focus()
	retry = Button.new()
	retry.text = "重试拦截"
	retry.pressed.connect(_retry)
	add_child(retry)
	resume_button = Button.new()
	resume_button.text = "继续"
	resume_button.pressed.connect(_resume)
	add_child(resume_button)
	get_tree().root.focus_exited.connect(_pause)

func start(request: Dictionary) -> void:
	config = request
	done = false; paused = false; dialogue_index = 0
	_switch("blackout" if request.get("resume",false) else "success")

func _pause() -> void:
	if paused or done: return
	paused = true
	presentation_requested.emit("prologue_playback_paused", {})
	holding = false
	dragging = false
	if phase == "lock": hold_ms = 0

func _resume() -> void:
	if not paused or done: return
	paused = false
	grab_focus()
	presentation_requested.emit("prologue_playback_resumed", {})

func _exit_tree() -> void:
	presentation_requested.emit("prologue_scene_closed", {})
	if get_tree().root.focus_exited.is_connected(_pause): get_tree().root.focus_exited.disconnect(_pause)

func _retry() -> void:
	blocks = 0
	misses = 0
	paddle = 50
	hold_ms = 0
	holding = false
	_switch("deploy")
	grab_focus()

func _switch(next: String) -> void:
	phase = next
	elapsed = 0
	match phase:
		"blackout": presentation_requested.emit("prologue_blackout_started", {"durationMs":7000})
		"deploy":
			intro_elapsed_ms = 0
			presentation_requested.emit("prologue_narrator_intro", {})
		"impact": presentation_requested.emit("prologue_error_intercepted", {"blockedCount":blocks,"requiredBlocks":3})
		"miss": presentation_requested.emit("prologue_error_intercept_missed", {"misses":misses,"maxMisses":3})
		"failed": presentation_requested.emit("prologue_error_round_failed", {"misses":misses})
		"lock": presentation_requested.emit("prologue_error_lock_ready", {"requiredHoldMs":1400})
		"caught":
			dialogue_index = 0
			presentation_requested.emit("prologue_narrator_caught", {"blockedCount":blocks,"lockHeldMs":hold_ms})
		"burst": presentation_requested.emit("prologue_white_burst", {})

func _process(delta: float) -> void:
	field = Rect2(Vector2(maxf(0,(size.x - size.y * 430.0 / 820.0) / 2),0),Vector2(minf(size.x,size.y * 430.0 / 820.0),size.y))
	if retry != null:
		retry.visible = phase == "failed" and not paused
		retry.position = Vector2(size.x / 2 - 110,size.y * 0.64)
		retry.size = Vector2(220,56)
		resume_button.visible = paused
		resume_button.position = Vector2(size.x / 2 - 110,size.y / 2)
		resume_button.size = Vector2(220,56)
	if paused or done:
		queue_redraw()
		return
	var dt = minf(delta,0.05)
	elapsed += dt
	if phase in ["deploy","intercept","impact","miss","lock"]: intro_elapsed_ms += dt * 1000
	if phase in ["deploy","intercept","impact","miss"]:
		var direction = float(Input.is_physical_key_pressed(KEY_D) or Input.is_physical_key_pressed(KEY_RIGHT)) - float(Input.is_physical_key_pressed(KEY_A) or Input.is_physical_key_pressed(KEY_LEFT))
		paddle = clampf(paddle + direction * 54 * dt,21,79)
	match phase:
		"success":
			if elapsed >= 0.9: _switch("error")
		"error":
			if elapsed >= 1.9: _switch("red")
		"red":
			if elapsed >= 0.35: _switch("blackout")
		"blackout":
			if elapsed >= 7.0: _switch("deploy")
		"deploy":
			if elapsed >= 1.5: _switch("intercept")
		"intercept":
			var p = clampf(elapsed / DURATIONS[mini(blocks,2)],0,1)
			orb = _path(blocks,p)
			if p >= 1:
				if absf(paddle - orb.x) <= 19:
					blocks += 1
					_switch("impact")
				else:
					misses += 1
					orb.y = 92
					_switch("miss")
		"impact":
			if elapsed >= 0.35:
				if blocks >= 3:
					orb = Vector2(50,42)
					_switch("lock")
				else: _switch("intercept")
		"miss":
			if elapsed >= 0.65: _switch("failed" if misses >= 3 else "intercept")
		"lock":
			if holding:
				hold_ms = minf(1400,hold_ms + dt * 1000)
				if hold_ms >= 1400:
					holding = false
					_switch("caught")
		"caught":
			var previous_dialogue: int = dialogue_index
			dialogue_index = 3 if elapsed >= 5.2 else 2 if elapsed >= 4.1 else 1 if elapsed >= 3 else 0
			if dialogue_index == 3 and previous_dialogue != 3: presentation_requested.emit("prologue_narrator_bargain", {})
			if elapsed >= 8.9: _switch("burst")
		"burst":
			if elapsed >= 0.95: _switch("whiteout")
		"whiteout":
			if elapsed >= 0.7:
				done = true
				finished.emit({"interceptedCount":blocks,"lockHeldMs":hold_ms,"failed":false,"dialogueCount":4,"whiteoutCompleted":true})
	queue_redraw()

func _path(round_index: int, p: float) -> Vector2:
	if round_index == 0: return Vector2(clampf(84 - 60*p + sin(p*PI*2)*9 + sin(p*PI*5)*3,8,92),12 + 69*p + sin(p*PI*3)*2.5)
	if round_index == 1: return Vector2(clampf(14 + 64*p + sin(p*PI*3)*10 - sin(p*PI*7)*3,8,92),12 + 69*p + sin(p*PI*4)*3)
	return Vector2(clampf(50 + 32*sin(p*PI*3) + 7*sin(p*PI*8),8,92),12 + 69*p + sin(p*PI*5)*3)

func _position(percent: Vector2) -> Vector2:
	return field.position + field.size * percent / 100.0

func _gui_input(event: InputEvent) -> void:
	if paused: return
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		_pointer(event.position,event.pressed)
		accept_event()
	elif event is InputEventScreenTouch:
		_pointer(event.position,event.pressed)
		accept_event()
	elif (event is InputEventMouseMotion or event is InputEventScreenDrag) and dragging:
		paddle = clampf((event.position.x-field.position.x) / maxf(1,field.size.x) * 100,21,79)
		accept_event()
	elif event is InputEventKey and not event.echo:
		if event.physical_keycode in [KEY_SPACE,KEY_ENTER] and phase == "lock":
			holding = event.pressed
			if not holding: hold_ms = 0
			accept_event()
		elif event.physical_keycode == KEY_ESCAPE and event.pressed: _pause()

func _pointer(point: Vector2, down: bool) -> void:
	if phase == "lock":
		if down and point.distance_to(_position(Vector2(50,42))) <= maxf(55,field.size.x * 0.16): holding = true
		elif not down:
			holding = false
			hold_ms = 0
	elif phase in ["deploy","intercept","impact","miss"]:
		dragging = down
		if down: paddle = clampf((point.x-field.position.x)/maxf(1,field.size.x)*100,21,79)

func _text(text: String, y: float, color = Color.WHITE, font_size: int = 22) -> void:
	var font = get_theme_default_font()
	var lines: Array = []
	for paragraph in text.split("\n"):
		var line = ""
		for i in range(paragraph.length()):
			var next = line + paragraph.substr(i,1)
			if font.get_string_size(next,HORIZONTAL_ALIGNMENT_LEFT,-1,font_size).x > size.x - 36 and not line.is_empty():
				lines.append(line)
				line = paragraph.substr(i,1)
			else: line = next
		lines.append(line)
	for i in range(lines.size()):
		var width = font.get_string_size(lines[i],HORIZONTAL_ALIGNMENT_LEFT,-1,font_size).x
		draw_string(font,Vector2((size.x-width)/2,y+i*(font_size+9)),lines[i],HORIZONTAL_ALIGNMENT_LEFT,-1,font_size,color)

func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO,size),Color("0c111a"))
	if phase == "blackout": return
	if phase == "red":
		draw_rect(Rect2(Vector2.ZERO,size),Color("ef223d"))
		return
	if phase in ["burst","whiteout"]:
		if phase == "whiteout" or int(elapsed*18) % 2 == 0: draw_rect(Rect2(Vector2.ZERO,size),Color.WHITE)
		return
	if phase == "success":
		_text("签　到",size.y * 0.45,Color("75ead8"),44)
		return
	if phase == "error":
		draw_rect(Rect2(Vector2(size.x/2-185,size.y/2-70),Vector2(370,140)),Color("ececf3"))
		_text("经度与纬度不存在",size.y/2,Color("283348"),25)
		return
	_text("经度与纬度不存在",45,Color("f2787d"),25)
	_text("拦截 %s / 3　漏过 %s / 3" % [blocks,misses],80,Color("dadfe9"),20)
	if phase in ["deploy","intercept","impact","miss","failed","lock"] and intro_segments.size() >= 3:
		var segment: int = 2 if intro_elapsed_ms >= 6800 else 1 if intro_elapsed_ms >= 3400 else 0
		_text(str(intro_segments[segment]),size.y * 0.16,Color("d3dce9"),18)
	if phase == "failed":
		_text("旁白溜走了。\n调整错误窗口的位置，再试一次。",size.y * 0.43,Color("f3989d"),21)
	elif phase == "caught":
		_text(DIALOGUE[dialogue_index],size.y * 0.5,Color.WHITE,20)
	elif phase == "lock":
		var center = _position(Vector2(50,42))
		draw_circle(center,55,Color("ad414a"))
		draw_arc(center,62,-PI/2,-PI/2 + TAU*hold_ms/1400,60,Color("fff0b0"),5)
		_text("按住旁白圆圈\n或持续按住空格 / Enter 1.4 秒\n松开会重新计时",size.y * 0.62,Color.WHITE,20)
	else:
		var box = Rect2(_position(Vector2(paddle-19,79)),Vector2(field.size.x*0.38,field.size.y*0.09))
		draw_rect(box,Color("f1e4e6"))
		draw_rect(box,Color("e76272"),false,3)
		var font = get_theme_default_font()
		draw_string(font,box.position+Vector2(7,box.size.y/2+6),"经纬度错误",HORIZONTAL_ALIGNMENT_LEFT,-1,18,Color("3f2432"))
		draw_circle(_position(orb),19,Color("f36d76"))
		_text("拖动错误窗口，或 A/D、←/→\n挡住旁白的离场路径",size.y * 0.94,Color("d3dce9"),18)
	if paused:
		draw_rect(Rect2(Vector2.ZERO,size),Color(0,0,0,0.8))
		_text("已暂停",size.y*0.4,Color.WHITE,28)
