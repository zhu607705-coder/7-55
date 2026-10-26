extends Control
const Model = preload("res://scripts/library_model.gd")
const World = preload("res://scripts/library_world.gd")
const Surface = preload("res://kit/history_surface.gd")
const FONT = preload("res://assets/MorningNote-Regular.ttf")
var model := Model.new()
var current_world: Node3D
var current_viewport: SubViewport
var current_image: TextureRect
var history_worlds: Array[Node3D]=[]
var history_viewports: Array[SubViewport]=[]
var history_images: Array[TextureRect]=[]
var history_rects: Array[Rect2]=[]
var current_rect := Rect2()
var pointers: Dictionary={}
var menu_button: Button
var resume_button: Button
var reset_button: Button
var last_size := Vector2.ZERO
var last_visibility := [false,false]

func _ready() -> void:
	mouse_filter=Control.MOUSE_FILTER_IGNORE
	var font_theme := Theme.new(); font_theme.default_font=FONT; font_theme.default_font_size=17; theme=font_theme
	current_viewport=Surface.viewport(self); current_world=World.new(); current_viewport.add_child(current_world); current_world.setup(-1)
	current_image=Surface.image(self,current_viewport)
	for index: int in range(2):
		var viewport := Surface.viewport(self); var world := World.new(); viewport.add_child(world); world.setup(index)
		history_viewports.append(viewport); history_worlds.append(world); history_images.append(Surface.image(self,viewport)); history_rects.append(Rect2())
	menu_button=_button("···",_suspend)
	resume_button=_button("继续",func(): model.resume(); resume_button.hide(); reset_button.hide())
	reset_button=_button("重新摆放",func(): model.reset(); pointers.clear(); _layout(true); resume_button.hide(); reset_button.hide())
	resume_button.hide(); reset_button.hide(); resized.connect(_layout); _layout()

func _button(caption: String, action: Callable) -> Button:
	var button := Button.new(); button.text=caption; button.pressed.connect(action); add_child(button); return button

func _layout(force_reset: bool=false) -> void:
	if not current_world: return
	if last_size!=Vector2.ZERO and last_size!=size: _suspend()
	last_size=size
	var wide := size.x>size.y*1.2
	current_rect=Rect2(Vector2.ZERO,size)
	if wide: current_rect=Rect2(size.x*.28,0,size.x*.72,size.y)
	current_viewport.size=Vector2i(current_rect.size); current_image.position=current_rect.position; current_image.size=current_rect.size; current_world.configure_camera(current_rect.size)
	var window_size := Vector2(minf(174,size.x*.46),210)
	if wide: window_size=Vector2(size.x*.23,minf(245,size.y*.37))
	for index: int in range(2):
		if history_rects[index].size==Vector2.ZERO or force_reset:
			var origin := Vector2(12,58) if index==0 else Vector2(size.x-window_size.x-30,168)
			if wide: origin=Vector2(16+index*40,48+index*180)
			history_rects[index]=Rect2(origin,window_size)
		else: history_rects[index].size=window_size
		_clamp_window(index)
		history_viewports[index].size=Vector2i(window_size); history_images[index].position=history_rects[index].position; history_images[index].size=window_size
		history_worlds[index].configure_camera(window_size)
	menu_button.position=Vector2(size.x-49,10); menu_button.size=Vector2(38,36)
	resume_button.position=Vector2(size.x*.5-72,size.y*.5-44); resume_button.size=Vector2(144,44)
	reset_button.position=Vector2(size.x*.5-72,size.y*.5+12); reset_button.size=Vector2(144,44)
	queue_redraw()

func _clamp_window(index: int) -> void:
	var r := history_rects[index]
	r.position.x=clampf(r.position.x,6,maxf(6,size.x-r.size.x-6)); r.position.y=clampf(r.position.y,50,maxf(50,size.y-r.size.y-6))
	history_rects[index]=r

func _process(delta: float) -> void:
	if not current_world: return
	current_world.update_current(model.selected_book,model.pull,model.completed,delta)
	last_visibility=[history_visible(0),history_visible(1)]
	model.observe(delta,last_visibility)
	queue_redraw()

func history_visible(index: int) -> bool:
	if model.suspended or not history_images[index].is_visible_in_tree(): return false
	var world: Node3D=history_worlds[index]
	var points := [world.glyph_point(index==0),World.REFERENCE]
	for p: Vector3 in points:
		if not world.visible_from_camera(p): return false
		var screen: Vector2=history_rects[index].position+world.screen_point(p)
		if not history_rects[index].has_point(screen) or not Rect2(Vector2.ZERO,size).has_point(screen): return false
		# Higher windows are genuine screen occluders, not transparent input layers.
		for above: int in range(index+1,2):
			if history_images[above].is_visible_in_tree() and history_rects[above].grow(3).has_point(screen): return false
		if _over_button(screen): return false
	return true

func _over_button(p: Vector2) -> bool:
	for button: Button in [menu_button,resume_button,reset_button]:
		if button and button.is_visible_in_tree() and button.get_global_rect().has_point(p): return true
	return false

func book_point(id: int) -> Vector2:
	return current_rect.position+current_world.screen_point(current_world.books[id].to_global(Vector3(0,0,.34)))

func book_visible(id: int) -> bool:
	if id<0 or not current_image.is_visible_in_tree(): return false
	var p := book_point(id)
	if not current_rect.has_point(p) or not Rect2(Vector2.ZERO,size).has_point(p) or _over_button(p): return false
	for index: int in range(2):
		if history_images[index].is_visible_in_tree() and history_rects[index].grow(3).has_point(p): return false
	return current_world.visible_from_camera(current_world.books[id].to_global(Vector3(0,0,.34)))

func _target(p: Vector2) -> String:
	if _over_button(p): return ""
	for index: int in [1,0]:
		if history_images[index].is_visible_in_tree() and history_rects[index].grow(3).has_point(p): return "history%d"%index
	if not current_rect.has_point(p): return ""
	for id: int in range(6):
		if book_visible(id) and Geometry2D.is_point_in_polygon(p-current_rect.position,current_world.book_polygon(id)): return "book:%d"%id
	return ""

func _input(event: InputEvent) -> void:
	if (event is InputEventMouseButton or event is InputEventMouseMotion) and event.device==InputEvent.DEVICE_ID_EMULATION: return
	if event is InputEventScreenTouch:
		if event.canceled: _suspend(); return
		if event.pressed: _down(event.index,event.position)
		else: _up(event.index)
	elif event is InputEventScreenDrag: _move(event.index,event.position)
	elif event is InputEventMouseButton and event.button_index==MOUSE_BUTTON_LEFT:
		if event.pressed: _down(-1,event.position)
		else: _up(-1)
	elif event is InputEventMouseMotion and pointers.has(-1): _move(-1,event.position)
	elif event.is_action_pressed("ui_cancel"): _suspend()

func _down(id: int, p: Vector2) -> void:
	if model.start(id,_target(p)):
		pointers[id]=p; get_viewport().set_input_as_handled()

func _move(id: int, p: Vector2) -> void:
	if not pointers.has(id) or not model.input.owners.has(id): return
	if not Rect2(Vector2.ZERO,size).has_point(p): _suspend(); return
	var delta: Vector2=p-pointers[id]; pointers[id]=p
	var target: String=model.input.owners[id]
	model.drag(id,delta)
	if target.begins_with("history"):
		var index := int(target.right(1)); history_rects[index].position+=delta; _clamp_window(index); history_images[index].position=history_rects[index].position
	get_viewport().set_input_as_handled()

func _up(id: int) -> void:
	var visible := book_visible(model.selected_book) if model.selected_book>=0 else true
	model.release(id,visible); pointers.erase(id)

func _suspend() -> void:
	model.suspend(); pointers.clear()
	if resume_button: resume_button.show(); reset_button.show()

func _notification(what: int) -> void:
	if what==NOTIFICATION_APPLICATION_FOCUS_OUT or what==NOTIFICATION_WM_WINDOW_FOCUS_OUT or what==NOTIFICATION_APPLICATION_PAUSED: _suspend()

func _draw() -> void:
	if not current_world: return
	for index: int in range(2):
		var r := history_rects[index]; var color := Color("ccac72") if index==0 else Color("89b6b2")
		draw_rect(r.grow(3),Color("1f302d"),false,7)
		draw_rect(r.grow(3),color,false,1.5)
		var clock_center := r.position+Vector2(18,18)
		draw_circle(clock_center,12,Color("283d38")); draw_arc(clock_center,8,0,TAU,30,color,1.2,true)
		draw_line(clock_center,clock_center+Vector2(0,-6),color,1.2,true)
		draw_line(clock_center,clock_center+Vector2(-5,2) if index==0 else clock_center+Vector2(5,2),color,1.2,true)
		for offset: int in range(3): draw_line(r.position+Vector2(r.size.x*.5-12,r.size.y-9+offset*3),r.position+Vector2(r.size.x*.5+12,r.size.y-9+offset*3),color,1.1)
		if model.observed[index]: draw_circle(r.position+Vector2(r.size.x-10,10),3,color)
	for id: int in pointers: draw_arc(pointers[id],16,0,TAU,36,Color("efe0bc"),1.8,true)
	if model.suspended: draw_rect(Rect2(Vector2.ZERO,size),Color(0.05,.09,.08,.74))
