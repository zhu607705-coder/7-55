extends Control
const ApparatusStyle=preload("res://campuses/future_learning_center/scripts/apparatus_style.gd")
## Scene props own manipulation; the only screen-space control is exit navigation.
signal closed
const Plane45=preload("res://campuses/future_learning_center/scripts/bench_projection.gd")
const LEVER_BASE := Vector2(832,365)
const CRANK := Vector2(704,403)
const Miniatures=preload("res://campuses/future_learning_center/scripts/miniature_bench.gd")
var miniature:Node
var bench_mode:="mechanical"
var font: Font
var gesture := ""
var pointer_owner := -2
var pointer := Vector2.ZERO
var press_at := Vector2.ZERO
var lever_offset := 0.0
var book_open := false
var book_page := 0
var book_at := Vector2(710,310)
var book_origin := Vector2.ZERO
var focus_interruptions := 0
var feedback := ""
var feedback_seconds := 0.0
var reduced_motion := false
var motion_time := 0.0
var lever_rest := -42.0
var lever_tween: Tween
var last_lever_live := false
var cues: Array[Dictionary]=[]
var returns: Dictionary={}

func _ready() -> void:
	font=ApparatusStyle.font()
	miniature=Miniatures.new();add_child(miniature)
	visibility_changed.connect(func()->void:miniature.set_active(visible))
	reduced_motion=OS.get_environment("FLC_REDUCED_MOTION")=="1"
	if OS.has_feature("web"):
		reduced_motion=reduced_motion or bool(JavaScriptBridge.eval("window.matchMedia('(prefers-reduced-motion: reduce)').matches"))
	texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	mouse_filter = Control.MOUSE_FILTER_STOP
	ApparatusStyle.configure_exit(self,close)
	hide()

func _load_texture(path: String) -> Texture2D:
	return load(path) if OS.has_feature("web") else ImageTexture.create_from_image(Image.load_from_file(ProjectSettings.globalize_path(path)))

func close() -> void:
	cancel_gesture(); clear_motion(); hide(); closed.emit()

func cancel_gesture() -> void:
	gesture = ""; pointer_owner = -2; lever_offset = 0
	queue_redraw()

func clear_motion() -> void:
	if lever_tween: lever_tween.kill()
	cues.clear();returns.clear();lever_rest=-76.0 if _lever_live() else -42.0

func set_reduced_motion(value: bool) -> void:
	reduced_motion=value
	if value: clear_motion()

func cue(kind: String, at: Vector2) -> void:
	if cues.size()>=12: cues.pop_front()
	cues.append({"kind":kind,"at":at,"age":0.0,"duration":.28 if kind!="brake" else .4})

func lift_at(at: Vector2) -> float:
	if reduced_motion: return 0.0
	var lift:=0.0
	for event: Dictionary in cues:
		if event.kind=="seat" and at.distance_to(event.at)<70:
			var t:float=event.age/event.duration
			lift=maxf(lift,7.0*pow(1.0-t,3))
	return lift

func return_part(id: String, from: Vector2, to: Vector2) -> void:
	if not reduced_motion: returns[id]={"from":from,"to":to,"age":0.0,"duration":.22}

func part_at(id: String, home: Vector2) -> Vector2:
	if not returns.has(id): return home
	var entry: Dictionary=returns[id]
	var t: float=clampf(entry.age/entry.duration,0,1)
	return entry.from.lerp(entry.to,1.0-pow(1.0-t,3))-Vector2(0,sin(t*PI)*5)

func notice(value: String) -> void:
	feedback = value; feedback_seconds = 5.0

func _notification(what: int) -> void:
	if what in [NOTIFICATION_APPLICATION_FOCUS_OUT,NOTIFICATION_APPLICATION_PAUSED]:
		if visible: focus_interruptions+=1
		cancel_gesture(); _lost_focus()
		clear_motion()

func _lost_focus() -> void: pass
func _object_press(_at: Vector2) -> void: pass
func _object_move(_at: Vector2) -> void: pass
func _object_release(_at: Vector2, _cancelled: bool) -> void: pass
func _lever_action(_offset: float) -> void: pass
func _undo() -> void: pass
func _keyboard(_event: InputEventKey) -> bool: return false
func _lever_live() -> bool: return false
func _assembly_stamp() -> String: return ""
func _seat_anchor(at: Vector2) -> Vector2: return at
func _book_lines() -> Array[String]: return ["试验记录","还没有完整试跑。"]

func lever_grip() -> Vector2:
	return LEVER_BASE + Vector2(0,-42+lever_offset if gesture=="lever" else lever_rest)

func _input(event: InputEvent) -> void:
	if ApparatusStyle.navigation_event(self,event):return
	if not visible: return
	# Browsers may synthesize mouse input after the touch owner has released.
	# Ignore it even with no active owner, or one tap can operate the book twice.
	if event is InputEventMouse and event.device==InputEvent.DEVICE_ID_EMULATION:return
	if event is InputEventScreenTouch and event.canceled:
		if event.index==pointer_owner:
			_release(event.position,true)
			get_viewport().set_input_as_handled()
		return
	var handled := false
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode==KEY_ESCAPE:
			if not gesture.is_empty(): cancel_gesture()
			elif book_open: book_open=false
			else: close()
			handled=true
		else: handled=_keyboard(event)
	elif event is InputEventScreenTouch:
		if event.pressed and pointer_owner==-2 and not Rect2(808,7,144,40).has_point(event.position):
			pointer_owner=event.index; _press(event.position); handled=true
		elif not event.pressed and pointer_owner==event.index:
			_release(event.position,event.canceled); handled=true
	elif event is InputEventScreenDrag and pointer_owner==event.index:
		_move(event.position); handled=true
	elif event is InputEventMouseButton and event.button_index==MOUSE_BUTTON_LEFT:
		# Ignore emulated mouse events while a real finger owns the gesture.
		if event.pressed and pointer_owner==-2 and not Rect2(808,7,144,40).has_point(event.position):
			pointer_owner=-1; _press(event.position); handled=true
		elif not event.pressed and pointer_owner==-1:
			_release(event.position,false); handled=true
	elif event is InputEventMouseMotion:
		pointer=event.position
		if pointer_owner==-1: _move(event.position); handled=true
	if handled: get_viewport().set_input_as_handled()

func _press(at: Vector2) -> void:
	pointer=at; press_at=at
	if at.distance_to(lever_grip())<32:
		gesture="lever"; lever_offset=-34 if _lever_live() else 0; book_open=false
	elif at.distance_to(CRANK)<35: gesture="crank"; book_open=false
	elif (Rect2(book_at-Vector2(240,270),Vector2(480,270)).has_point(at) if book_open else Rect2(832,74,104,61).has_point(at)):
		gesture="book"; book_origin=book_at
	else:
		book_open=false; _object_press(at)
	if not gesture.is_empty(): cue("grip",at)

func _move(at: Vector2) -> void:
	pointer=at
	if gesture=="lever": lever_offset=clampf(at.y-(LEVER_BASE.y-42),-44,38)
	elif gesture=="book" and book_open and at.distance_to(press_at)>10:
		book_at=(book_origin+at-press_at).clamp(Vector2(240,280),Vector2(720,480))
	else: _object_move(at)
	queue_redraw()

func _release(at: Vector2, cancelled: bool) -> void:
	var invalid := cancelled or not Rect2(0,0,960,540).has_point(at)
	var before:=_assembly_stamp()
	var released:=gesture
	var grip_before:=lever_grip().y-LEVER_BASE.y
	if not invalid:
		if gesture=="lever":
			if at.distance_to(press_at)>8: _lever_action(lever_offset)
			else: notice("握住杆柄向前推；回到中位暂停，向后拉复位。")
		elif gesture=="crank":
			if absf((press_at-CRANK).angle_to(at-CRANK))>.8: _undo()
			else: notice("转动回卷手轮可撤回上一次装配。")
		elif gesture=="book" and at.distance_to(press_at)<10:
			if not book_open: book_open=true
			elif at.distance_to(book_at+Vector2(164,-25))<38: book_page=mini(3,book_page+1)
			else: book_open=false
		else: _object_release(at,false)
	else: _object_release(at,true)
	if not invalid and _assembly_stamp()!=before: cue("seat",_seat_anchor(at))
	elif invalid and not released.is_empty(): cue("release",press_at)
	cancel_gesture()
	if released=="lever":
		lever_rest=grip_before
		settle_lever()

func settle_lever() -> void:
	if lever_tween: lever_tween.kill()
	var target:=-76.0 if _lever_live() else -42.0
	if reduced_motion: lever_rest=target
	else:
		lever_tween=create_tween()
		lever_tween.tween_property(self,"lever_rest",target,.14).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	last_lever_live=_lever_live()

func _tick_shell(dt: float) -> void:
	feedback_seconds=maxf(0,feedback_seconds-dt)
	motion_time+=dt
	for event: Dictionary in cues: event.age+=dt
	cues=cues.filter(func(event: Dictionary)->bool:return event.age<event.duration)
	for id: String in returns.keys():
		returns[id].age+=dt
		if returns[id].age>=returns[id].duration: returns.erase(id)
	if gesture!="lever" and _lever_live()!=last_lever_live: settle_lever()

func ink(value: String, at: Vector2, size_value:=20, color:=Color("253e46")) -> void:
	draw_string(font,at,value,HORIZONTAL_ALIGNMENT_LEFT,-1,size_value,color)

func draw_table(title: String) -> void:
	miniature.present(self,bench_mode)
	draw_texture_rect(miniature.texture(),Rect2(0,0,960,540),false)
	ink(title,Vector2(32,39),24)

func draw_tools() -> void:
	# Three engraved detents: forward/run, middle/stop, backward/return.
	var x:=LEVER_BASE.x+56
	for y:float in [-76,-42,-8]:draw_line(Vector2(x,y+LEVER_BASE.y),Vector2(x+16,y+LEVER_BASE.y),ApparatusStyle.INK,3,true)
	draw_colored_polygon(PackedVector2Array([Vector2(x+25,LEVER_BASE.y-84),Vector2(x+25,LEVER_BASE.y-68),Vector2(x+37,LEVER_BASE.y-76)]),ApparatusStyle.INK)
	draw_rect(Rect2(x+25,LEVER_BASE.y-48,12,12),ApparatusStyle.INK)
	ApparatusStyle.grip(self,lever_grip(),"vertical",gesture=="lever")
	ApparatusStyle.grip(self,CRANK,"rotate",gesture=="crank")
	if not book_open:ApparatusStyle.grip(self,Vector2(884,103),"book")
	if gesture=="lever":
		ink("运行" if lever_offset< -20 else ("归位" if lever_offset>20 else "暂停"),LEVER_BASE+Vector2(34,35),18)
	draw_cues()
	if feedback_seconds>0:
		draw_rect(Rect2(16,486,928,46),Color("253e46"))
		ink(feedback,Vector2(28,516),21,Color("f5f1e4"))

func draw_book() -> void:
	if not book_open: return
	# Reading is a held, lifted document; keep the text in screen space.
	var cover:=Rect2(book_at-Vector2(238,260),Vector2(476,266))
	draw_rect(cover.grow(5),Color("36777b"));draw_rect(cover,Color("f6edd7"))
	draw_line(book_at+Vector2(0,-258),book_at+Vector2(0,4),Color("bcb8a9"),2,true)
	var lines:=_book_lines()
	ink(lines[0],book_at+Vector2(-172,-190),23,Color("202b35"))
	var value: String=lines[1]
	for n: int in mini(6,int(ceil(value.length()/6.0))):
		ink(value.substr(n*6,6),book_at+Vector2(15,-187+n*27),23,Color("202b35"))
	ink("记录" if book_page==0 else "线索 %d/3"%book_page,book_at+Vector2(-167,-128),20,Color("344452"))
	if bench_mode!="pantry":
		ink("推杆运行 · 中位暂停",book_at+Vector2(-215,-84),16,ApparatusStyle.INK)
		ink("后拉归位 · 转轮撤回",book_at+Vector2(-215,-57),16,ApparatusStyle.INK)
	var fold:=book_at+Vector2(164,-25)
	draw_colored_polygon(PackedVector2Array([fold+Vector2(-17,7),fold+Vector2(17,7),fold+Vector2(17,-20)]),Color("c79b62"))

func draw_cues() -> void:
	for event: Dictionary in cues:
		var t: float=clampf(event.age/event.duration,0,1)
		var at: Vector2=event.at
		var alpha: float=(1-t)*.85
		if event.kind in ["grip","seat","release"]:
			var radius: float=13+(0.0 if reduced_motion else 9*t)
			# Short contact arcs, not a full-screen flash or decorative particles.
			draw_polyline(Plane45.ring(at+Vector2(0,5),radius,.1,PI-.1,16),Color(Color("c79b62"),alpha),2)
		elif event.kind=="brake":
			for side: float in [-1,1]:
				var d: float=0 if reduced_motion else t*10
				draw_line(at+Vector2(side*(22+d),-7),at+Vector2(side*(28+d),-13),Color(Color("c79b62"),alpha),3)
