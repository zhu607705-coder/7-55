extends Control
const Model = preload("res://scripts/raking_model.gd")
const World = preload("res://scripts/raking_world.gd")
const FONT = preload("res://assets/MorningNote-Regular.ttf")
var model := Model.new()
var current_world: Node3D
var recorded_world: Node3D
var current_viewport: SubViewport
var history_viewport: SubViewport
var current_rect := Rect2()
var history_rect := Rect2()
var history_offset := Vector2.ZERO
var pointer_positions: Dictionary={}
var title: Label
var instruction: Label
var status: Label
var history_caption: Label
var retry: Button
var cancel: Button
var resume: Button
var current_image: TextureRect
var history_image: TextureRect
var last_size := Vector2.ZERO
var metrics: Dictionary={}

func _ready() -> void:
	mouse_filter=Control.MOUSE_FILTER_IGNORE
	var theme_resource := Theme.new(); theme_resource.default_font=FONT; theme_resource.default_font_size=17; theme=theme_resource
	current_viewport=_viewport(); current_world=World.new(); current_viewport.add_child(current_world); current_world.setup(false)
	history_viewport=_viewport(); recorded_world=World.new(); history_viewport.add_child(recorded_world); recorded_world.setup(true)
	current_image=_image(current_viewport); history_image=_image(history_viewport)
	title=_label("斜光找压痕",24,Color("e8ddbe"))
	instruction=_label("抬一抬纸边，再把灯压低。",17,Color("c8cdbf"))
	history_caption=_label("旧时光 · 只读光向",15,Color("d4d2bd"))
	status=_label("拖纸边调整倾斜 · 拖灯罩移动光源",16,Color("d6d6c1"))
	retry=_button("重新摆放",func(): model.reset(); pointer_positions.clear(); resume.hide())
	cancel=_button("暂停",func(): _suspend())
	resume=_button("继续观察",func(): model.resume(); resume.hide())
	resized.connect(_layout)
	_layout()

func _viewport() -> SubViewport:
	var viewport := SubViewport.new(); viewport.own_world_3d=true
	viewport.render_target_update_mode=SubViewport.UPDATE_ALWAYS
	viewport.msaa_3d=Viewport.MSAA_2X; add_child(viewport); return viewport

func _image(viewport: SubViewport) -> TextureRect:
	var image := TextureRect.new(); image.texture=viewport.get_texture(); image.mouse_filter=Control.MOUSE_FILTER_IGNORE
	image.show_behind_parent=true; image.expand_mode=TextureRect.EXPAND_IGNORE_SIZE; add_child(image); return image

func _label(text_value: String, font_size: int, color: Color) -> Label:
	var label := Label.new(); label.text=text_value; label.add_theme_font_size_override("font_size",font_size); label.add_theme_color_override("font_color",color)
	label.mouse_filter=Control.MOUSE_FILTER_IGNORE; add_child(label); return label

func _button(text_value: String, callback: Callable) -> Button:
	var button := Button.new(); button.text=text_value; button.add_theme_font_size_override("font_size",15)
	button.pressed.connect(callback); add_child(button); return button

func _layout() -> void:
	if not current_world: return
	if last_size!=Vector2.ZERO and last_size!=size: _suspend()
	last_size=size
	var wide := size.x>700
	current_rect=Rect2(0,222,size.x,maxf(250,size.y-292))
	if wide: current_rect=Rect2(size.x*0.29,86,size.x*0.71,size.y-156)
	current_viewport.size=Vector2i(current_rect.size); current_image.position=current_rect.position; current_image.size=current_rect.size
	current_world.configure_camera(current_rect.size)
	var history_size := Vector2(minf(358,size.x-32),150)
	if wide: history_size=Vector2(size.x*0.27,190)
	history_rect=Rect2(Vector2(16,92)+history_offset,history_size)
	_clamp_history()
	history_viewport.size=Vector2i(history_rect.size); history_image.position=history_rect.position; history_image.size=history_rect.size
	recorded_world.configure_camera(history_rect.size,true)
	title.position=Vector2(18,15); instruction.position=Vector2(18,49)
	history_caption.position=history_rect.position+Vector2(10,8)
	status.position=Vector2(16,size.y-67)
	retry.position=Vector2(16,size.y-36); retry.size=Vector2(110,30)
	cancel.position=Vector2(size.x-102,size.y-36); cancel.size=Vector2(86,30)
	resume.position=Vector2(size.x*0.5-72,size.y*0.57); resume.size=Vector2(144,44); resume.visible=model.suspended
	queue_redraw()

func _clamp_history() -> void:
	history_rect.position.x=clampf(history_rect.position.x,6,maxf(6,size.x-history_rect.size.x-6))
	history_rect.position.y=clampf(history_rect.position.y,80,maxf(80,size.y-history_rect.size.y-90))

func _process(delta: float) -> void:
	if not current_world: return
	current_world.update_scene(model.paper_tilt,model.lamp_azimuth,model.lamp_elevation,model.stable_time/Model.HOLD_SECONDS,model.completed,delta)
	# Recorded lighting is immutable. It is not a control for the current lamp.
	recorded_world.update_scene(Vector2(9,-6),-28,18,0,false)
	metrics=current_world.visibility_metrics()
	model.update(delta,metrics)
	if model.completed: status.text="压痕已看清，后方预览门打开。"
	elif model.suspended: status.text="已松开双手。继续后重新稳定观察。"
	elif model.stable_time>0.05: status.text="就是这束斜光。稳住，看清整条压痕。"
	elif metrics.get("incidence",90)>24: status.text="光还太正。把灯罩向下拖，轻抬纸边。"
	else: status.text="慢慢侧移灯罩，让光扫过整张纸。"
	queue_redraw()

func paper_polygon() -> PackedVector2Array:
	var points := PackedVector2Array()
	for p: Vector3 in [Vector3(-1.68,0,-1.2),Vector3(1.68,0,-1.2),Vector3(1.68,0,1.2),Vector3(-1.68,0,1.2)]:
		points.append(current_rect.position+current_world.screen_point(current_world.paper_pivot.to_global(p)))
	return points

func paper_hit_point() -> Vector2:
	return current_rect.position+current_world.screen_point(current_world.paper_pivot.to_global(Vector3(-1.50,0.02,0.83)))

func lamp_hit_point() -> Vector2:
	return current_rect.position+current_world.screen_point(current_world.lamp_head.global_position)

func _target(point: Vector2) -> String:
	if history_rect.has_point(point): return "history"
	if not current_rect.has_point(point): return ""
	if point.distance_to(lamp_hit_point())<=35: return "lamp"
	if Geometry2D.is_point_in_polygon(point,paper_polygon()) or point.distance_to(paper_hit_point())<27: return "paper"
	return ""

func _input(event: InputEvent) -> void:
	# Browsers/OS input bridges may still deliver emulated mouse events even when
	# Godot's own touch-to-mouse option is disabled. Never give them an owner.
	if (event is InputEventMouseButton or event is InputEventMouseMotion) and event.device==InputEvent.DEVICE_ID_EMULATION: return
	if event is InputEventScreenTouch:
		if event.canceled: _suspend(); return
		if event.pressed: _down(event.index,event.position)
		else: _up(event.index)
	elif event is InputEventScreenDrag: _move(event.index,event.position)
	elif event is InputEventMouseButton and event.button_index==MOUSE_BUTTON_LEFT:
		if event.pressed: _down(-1,event.position)
		else: _up(-1)
	elif event is InputEventMouseMotion and pointer_positions.has(-1): _move(-1,event.position)
	elif event.is_action_pressed("ui_cancel"): _suspend()

func _down(id: int, point: Vector2) -> void:
	var object := _target(point)
	if model.start(id,object):
		pointer_positions[id]=point
		get_viewport().set_input_as_handled()

func _move(id: int, point: Vector2) -> void:
	if not pointer_positions.has(id) or not model.owners.has(id): return
	if not Rect2(Vector2.ZERO,size).has_point(point): _suspend(); return
	var delta: Vector2=point-pointer_positions[id]; pointer_positions[id]=point
	if model.owners[id]=="history":
		history_rect.position+=delta; _clamp_history()
		history_offset=history_rect.position-Vector2(16,92)
		history_image.position=history_rect.position; history_caption.position=history_rect.position+Vector2(10,8)
	else: model.drag(id,delta*390.0/maxf(320,current_rect.size.x))
	get_viewport().set_input_as_handled()

func _up(id: int) -> void:
	pointer_positions.erase(id); model.release(id)

func _suspend() -> void:
	model.suspend(); pointer_positions.clear()
	if resume: resume.show()

func _notification(what: int) -> void:
	if what==NOTIFICATION_APPLICATION_FOCUS_OUT or what==NOTIFICATION_WM_WINDOW_FOCUS_OUT or what==NOTIFICATION_APPLICATION_PAUSED: _suspend()

func _draw() -> void:
	if not current_world: return
	# Only handle affordances and history frame are 2D; the paper marks are lit geometry.
	draw_style_box(_frame_style(),history_rect.grow(3))
	var hand := Color(0.88,0.79,0.54,0.70)
	if not model.completed:
		draw_arc(paper_hit_point(),23,0,TAU,48,hand,1.5,true)
		draw_arc(lamp_hit_point(),27,0,TAU,48,hand,1.5,true)
	for id: int in pointer_positions:
		var p: Vector2=pointer_positions[id]
		draw_arc(p,15,0,TAU,40,Color("eee6cc"),2,true)

func _frame_style() -> StyleBoxFlat:
	var box := StyleBoxFlat.new(); box.bg_color=Color.TRANSPARENT
	box.border_color=Color("87998c"); box.set_border_width_all(2); box.set_corner_radius_all(4); return box
