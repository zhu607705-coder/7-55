extends Control
## Source InvestigationRing.tsx and investigation-ring.css, rebuilt as native UI.
signal page_requested(page: String)
var branches: Array=[]
var buttons: Array=[]
var completed: int=0
func configure(nodes: Array) -> void:
	branches=nodes
	completed=nodes.filter(func(node: Dictionary) -> bool: return bool(node.ready)).size()
	custom_minimum_size=Vector2(360,286)
	for node: Dictionary in nodes:
		var button: Button=Button.new()
		button.text=str(node.label)+"\n"+("已恢复" if node.ready else "点击进入来源")
		button.size=Vector2(120,58)
		button.add_theme_font_size_override("font_size",11)
		for role: String in ["font_color","font_hover_color","font_pressed_color","font_hover_pressed_color","font_focus_color","font_disabled_color"]: button.add_theme_color_override(role,Color("1b2328"))
		var box: StyleBoxFlat=StyleBoxFlat.new()
		box.bg_color=Color("d3dfcf") if node.ready else Color("efe9d8")
		box.border_color=Color("3d8168") if node.ready else Color("1f6d7f")
		box.set_border_width_all(2)
		for mode: String in ["normal","hover","pressed","hover_pressed","disabled"]: button.add_theme_stylebox_override(mode,box)
		button.pressed.connect(func() -> void: page_requested.emit(node.page))
		# Source InvestigationRing uses cyclic investigation order. Godot's
		# spatial nearest-control navigation stalls at the rightmost node.
		button.gui_input.connect(_node_input.bind(button))
		add_child(button)
		buttons.append(button)
	resized.connect(layout)
	layout()
func _node_input(event: InputEvent,button: Button) -> void:
	if not event is InputEventKey or not event.pressed or event.echo or buttons.is_empty(): return
	var index: int=buttons.find(button)
	var next: int=index
	match event.keycode:
		KEY_RIGHT,KEY_DOWN: next=(index+1)%buttons.size()
		KEY_LEFT,KEY_UP: next=posmod(index-1,buttons.size())
		KEY_HOME: next=0
		KEY_END: next=buttons.size()-1
		_: return
	button.accept_event()
	buttons[next].grab_focus()
func layout() -> void:
	var width: float=maxf(size.x,custom_minimum_size.x)
	for index: int in range(buttons.size()):
		var angle: float=-PI/2+TAU*index/buttons.size()
		buttons[index].position=Vector2(width*(0.5+cos(angle)*0.325),286*(0.5+sin(angle)*0.325))-Vector2(60,29)
	queue_redraw()
func _draw() -> void:
	var width: float=maxf(size.x,custom_minimum_size.x)
	draw_rect(Rect2(0,0,width,286),Color("e2dccb"))
	for x: int in range(0,int(width),8): draw_line(Vector2(x,0),Vector2(x,286),Color(0.39,0.45,0.48,0.08))
	for y: int in range(0,287,8): draw_line(Vector2(0,y),Vector2(width,y),Color(0.39,0.45,0.48,0.08))
	var points: PackedVector2Array=[]
	for index: int in range(branches.size()+1):
		var angle: float=-PI/2+TAU*(index%branches.size())/branches.size()
		points.append(Vector2(width*(0.5+cos(angle)*0.325),286*(0.5+sin(angle)*0.325)))
	for index: int in range(maxi(0,points.size()-1)): draw_dashed_line(points[index],points[index+1],Color("65747a"),1,5)
	var center: Rect2=Rect2(width/2-52,102,104,82)
	draw_rect(center,Color("e2dccb"))
	draw_rect(center,Color("65747a"),false,2)
	var font: Font=get_theme_default_font()
	draw_string(font,Vector2(width/2-45,120),"已查记录",HORIZONTAL_ALIGNMENT_CENTER,90,10,Color("677278"))
	draw_string(font,Vector2(width/2-45,151),str(completed)+" / 4",HORIZONTAL_ALIGNMENT_CENTER,90,22,Color("1f6d7f"))
	draw_string(font,Vector2(width/2-45,172),"已查齐" if completed==4 else "尚有未查",HORIZONTAL_ALIGNMENT_CENTER,90,10,Color("677278"))
