extends Control
## Isolated presentation study. Uses the unmodified original kayak dynamics.
const Kayak = preload("res://scripts/games/kayak_model.gd")
const Rig = preload("res://scripts/presentation/kayak_rig.gd")
var kayak: RefCounted = Kayak.new()
var rig: Node2D
var foreground: Node2D
var lake: Texture2D
var font: Font
var elapsed: float = 0.0
var paused: bool = false
var capture_demo: bool = false
var close_view: bool = true
var zoom: float = 3.5
var controls: Dictionary = {}
var touch_starts: Dictionary = {}
var accepted_inputs: int = 0
var mode_label: String = "可操作 · A / D 交替划桨"
var visual_clock: float = 0.0

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter=Control.MOUSE_FILTER_STOP
	lake=load("res://assets/rpg/interiors/qizhen_lake_open_water.png")
	font=load("res://assets/rpg/fonts/fusion_pixel_12px_proportional_zh_hans.ttf")
	rig=Rig.new();rig.name="LayeredKayakRig";add_child(rig)
	foreground=Node2D.new();foreground.name="StudyHUD";foreground.z_index=10;add_child(foreground);foreground.draw.connect(_draw_overlay)
	restart()

func restart() -> void:
	kayak=Kayak.new();kayak.configure({"phase":"world","bounded":false})
	kayak.position=Vector2(820,600);kayak.heading=-PI/2
	paused=false;elapsed=0;visual_clock=0;accepted_inputs=0;touch_starts.clear()
	zoom=target_zoom()
	if rig!=null:rig.reset();_sync_rig(0,true)
	queue_redraw()

func set_paused(value: bool) -> void:
	paused=value;touch_starts.clear();rig.set_paused(value);queue_redraw()

func stroke(side: String, reverse: bool=false) -> void:
	if paused or kayak.status!="running":return
	kayak.stroke(side,reverse)
	accepted_inputs+=1
	rig.request_stroke(side,reverse)
	if kayak.status!="running":rig.motion.pending.clear()
	queue_redraw()

func _process(delta: float) -> void:
	if paused:return
	var dt: float=minf(maxf(delta,0),.05)
	elapsed+=dt;visual_clock+=dt
	kayak.update(dt)
	zoom=lerpf(zoom,target_zoom(),1-exp(-6.0*dt))
	_sync_rig(dt)
	rig.advance(dt)
	queue_redraw()

func _sync_rig(dt: float, snap: bool=false) -> void:
	if rig==null:return
	rig.sync_pose(world_anchor(),kayak.heading,kayak.speed,kayak.roll,zoom*display_scale(),dt,snap,kayak.position)

func display_scale() -> float:
	return minf(size.x/1280.0,size.y/720.0)

func world_anchor() -> Vector2:
	var top: float=70.0 if size.x<750 else 88.0
	var bottom: float=size.y-(136.0 if capture_demo else 178.0)
	return Vector2(size.x*.53,(top+bottom)*.5)

func target_zoom() -> float:
	var top: float=70.0 if size.x<750 else 88.0
	var bottom: float=size.y-(136.0 if capture_demo else 178.0)
	var fit: float=maxf(.5,(bottom-top)*.84/(160*.52*maxf(display_scale(),.1)))
	return minf(3.5 if close_view else 1.0,fit)

func _notification(what: int) -> void:
	if what==NOTIFICATION_APPLICATION_FOCUS_OUT and rig!=null and not capture_demo:set_paused(true)

func _unhandled_key_input(event: InputEvent) -> void:
	if not event is InputEventKey or not event.pressed or event.echo:return
	if event.keycode==KEY_R:restart()
	elif event.keycode in [KEY_P,KEY_ESCAPE]:set_paused(not paused)
	elif event.keycode==KEY_C:close_view=not close_view
	elif event.keycode in [KEY_A,KEY_LEFT]:stroke("left",Input.is_key_pressed(KEY_S) or Input.is_key_pressed(KEY_DOWN))
	elif event.keycode in [KEY_D,KEY_RIGHT]:stroke("right",Input.is_key_pressed(KEY_S) or Input.is_key_pressed(KEY_DOWN))
	get_viewport().set_input_as_handled()

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index==MOUSE_BUTTON_LEFT:
		if event.device==-1:return
		_pointer(event.position,event.pressed,-1)
	elif event is InputEventScreenTouch:_pointer(event.position,event.pressed,event.index)

func _pointer(at: Vector2, pressed: bool, id: int) -> void:
	if pressed:
		for action: String in controls:
			if controls[action].has_point(at):
				if action=="pause":set_paused(not paused)
				elif action=="restart":restart()
				elif action=="camera":close_view=not close_view
				else:touch_starts[id]={"side":action,"start":at}
				accept_event();queue_redraw();return
	elif touch_starts.has(id):
		var intent: Dictionary=touch_starts[id];touch_starts.erase(id)
		stroke(intent.side,at.y-float(intent.start.y)>22)
		accept_event()

func _draw() -> void:
	if lake==null:return
	var s: float=display_scale()
	var z: float=zoom*s
	# The camera follows the unmodified model at 1:1 world speed.
	# No artificial drift/extra force is added for the motion demonstration.
	var center: Vector2=world_anchor()
	var cam: Vector2=kayak.position
	draw_rect(Rect2(Vector2.ZERO,size),Color("154551"))
	draw_texture_rect(lake,Rect2(center-cam*z,Vector2(1672,941)*z),false)
	foreground.queue_redraw()

func _draw_overlay() -> void:
	var compact: bool=size.x<750
	foreground.draw_rect(Rect2(0,0,size.x,70 if compact else 88),Color(.025,.08,.11,.88))
	foreground.draw_string(font,Vector2(20,32),"启真湖 · 划桨动作",HORIZONTAL_ALIGNMENT_LEFT,-1,20 if compact else 24,Color("edf5ee"))
	var subtitle: String="入水 → 拉水 → 出水 → 回桨" if compact else "原船与角色拆层 · 双臂跟随同一根双叶桨 · 动作不增加推进力"
	foreground.draw_string(font,Vector2(20,58),subtitle,HORIZONTAL_ALIGNMENT_LEFT,-1,14 if compact else 18,Color("a9c7c6"))
	var phase: String=rig.motion.phase()
	var phase_names: Dictionary={"rest":"收桨滑行","catch":"入水 CATCH","power":"水下拉桨 POWER","exit":"出水 EXIT","recovery":"空中回桨 RECOVERY"}
	var side_text: String="左侧" if rig.motion.side=="left" else "右侧"
	if rig.motion.reverse:side_text+=" · 反划"
	var title: String=phase_names[phase] if phase=="rest" else side_text+" · "+phase_names[phase]
	if paused:title="暂停 · 动作和推进同时冻结"
	var panel_y: float=size.y-136 if capture_demo else size.y-178
	foreground.draw_rect(Rect2(16,panel_y,size.x-32,68),Color(.025,.08,.11,.88))
	foreground.draw_string(font,Vector2(30,panel_y+26),title,HORIZONTAL_ALIGNMENT_LEFT,-1,18 if compact else 22,Color("edf4e4"))
	var progress: float=clampf(rig.motion.age/rig.motion.duration,0,1) if rig.motion.active else 0
	var bar: Rect2=Rect2(30,panel_y+43,size.x-60,7)
	foreground.draw_rect(bar,Color("2d4c55"));foreground.draw_rect(Rect2(bar.position,Vector2(bar.size.x*progress,bar.size.y)),Color("e7b875"))
	for boundary: float in [.15,.58,.72]:foreground.draw_line(bar.position+Vector2(bar.size.x*boundary,-2),bar.position+Vector2(bar.size.x*boundary,9),Color("9cb6ba"),1)
	var footer: String="原生 60 帧离线动作采样 · 不代表实时帧率" if capture_demo else "A/D 划桨 · S+划桨反划 · C 镜头 · P 暂停 · R 重试"
	if compact and not capture_demo:footer="上划前进 · 下划反划 · 左右交替"
	foreground.draw_string(font,Vector2(20,size.y-22),footer,HORIZONTAL_ALIGNMENT_LEFT,-1,14 if compact else 18,Color("e0eeea"))
	controls.clear()
	if not capture_demo:
		_button("左桨 A",Rect2(18,size.y-100,120,56),"left")
		_button("右桨 D",Rect2(size.x-138,size.y-100,120,56),"right")
		_button("继续" if paused else "暂停",Rect2(size.x-164,12,70,34),"pause")
		_button("重试",Rect2(size.x-86,12,70,34),"restart")
		_button("正常镜头" if close_view else "动作近景",Rect2(size.x-164,50,148,30),"camera")
	if kayak.status!="running":foreground.draw_string(font,Vector2(24,120),"连续同侧失衡 · R 重试",HORIZONTAL_ALIGNMENT_LEFT,-1,20,Color("f3c7a5"))

func _button(label: String, rect: Rect2, action: String) -> void:
	controls[action]=rect
	foreground.draw_rect(rect,Color(.08,.20,.24,.95))
	foreground.draw_rect(rect,Color("789b9b"),false,1)
	foreground.draw_string(font,rect.position+Vector2(8,rect.size.y/2+6),label,HORIZONTAL_ALIGNMENT_CENTER,rect.size.x-16,16,Color("eef4e7"))
