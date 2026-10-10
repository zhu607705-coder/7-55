extends Control
signal finished(result: Dictionary)
signal cancelled
# Original React item-document palette, not a new fantasy/scroll asset.
const PAPER:=Color("eee7d5")
const INK:=Color("29251e")
const MUTED:=Color("766b58")
const RED:=Color("8b3f35")
const SHEET:=Rect2(14,80,402,616)
var elapsed: float=0
var label: Label
var stamp: Button
var issued: bool=false
var result_labels: Array[Label]=[]
var status: Label
var scan_hint: Label
var ready_shown: bool=false
var font: Font=preload("res://assets/rpg/fonts/fusion_pixel_12px_proportional_zh_hans.ttf")
var stamp_art: Texture2D=preload("res://assets/rpg/props/library_front_desk_stamp_v01.png")
var backpack: Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://data/native/library-world-source.json")).backpack
func _label(text: String,rect: Rect2,font_size: int,color: Color=INK) -> Label:
	var value:=Label.new();value.text=text;value.position=rect.position;value.size=rect.size
	value.add_theme_font_override("font",font);value.add_theme_font_size_override("font_size",font_size)
	value.add_theme_color_override("font_color",color);value.mouse_filter=Control.MOUSE_FILTER_IGNORE
	add_child(value);return value
func _button_style(fill: Color,border: Color) -> StyleBoxFlat:
	var style:=StyleBoxFlat.new();style.bg_color=fill;style.border_color=border;style.set_border_width_all(2)
	style.content_margin_left=12;style.content_margin_right=12;return style
func _ready() -> void:
	_label("基础馆 · 身份核验",Rect2(40,105,330,22),14,MUTED)
	label=_label("物品身份盖章机",Rect2(40,138,345,32),24)
	_label("核验对象",Rect2(181,212,178,24),16,MUTED)
	_label("书包",Rect2(181,240,178,30),24)
	status=_label("核验中",Rect2(240,290,112,34),18,MUTED)
	status.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	for i: int in range(3):
		_label(["姓名","学号","人格"][i],Rect2(42,355+i*49,108,34),18,MUTED)
		result_labels.append(_label("核验中…",Rect2(218,355+i*49,155,34),20,MUTED))
	scan_hint=_label("正在扫描报告……",Rect2(42,516,348,28),16,MUTED)
	stamp=Button.new();stamp.name="StampNonPerson";stamp.position=Vector2(42,563);stamp.size=Vector2(346,64)
	stamp.text="盖章：非本人";stamp.disabled=true
	stamp.add_theme_font_override("font",font);stamp.add_theme_font_size_override("font_size",22)
	stamp.add_theme_color_override("font_color",Color("fffaf0"));stamp.add_theme_color_override("font_hover_color",Color("fffaf0"));stamp.add_theme_color_override("font_pressed_color",Color("fffaf0"));stamp.add_theme_color_override("font_disabled_color",MUTED);stamp.add_theme_color_override("font_hover_pressed_color",Color("fffaf0"));stamp.add_theme_color_override("font_focus_color",Color("fffaf0"))
	stamp.add_theme_stylebox_override("normal",_button_style(RED,Color("71382e")))
	stamp.add_theme_stylebox_override("hover",_button_style(Color("a64b3d"),Color("71382e")))
	stamp.add_theme_stylebox_override("pressed",_button_style(Color("74372e"),Color("71382e")))
	stamp.add_theme_stylebox_override("hover_pressed",_button_style(Color("74372e"),Color("71382e")))
	stamp.add_theme_stylebox_override("disabled",_button_style(Color("d8ceb9"),Color("b7aa92")))
	var focus:=_button_style(Color.TRANSPARENT,INK);focus.set_border_width_all(3);stamp.add_theme_stylebox_override("focus",focus)
	stamp.pressed.connect(_stamp);add_child(stamp)
	_label("基础馆失物身份登记",Rect2(42,650,348,24),14,MUTED)
func start(_config: Dictionary) -> void: pass
func _process(delta: float) -> void:
	elapsed+=minf(delta,.1)
	if not ready_shown and elapsed>=.72:
		ready_shown=true
		for row: Label in result_labels:row.text="未通过";row.add_theme_color_override("font_color",RED)
		status.text="待盖章";status.add_theme_color_override("font_color",RED)
		scan_hint.text="核验完成 · 等待盖章";stamp.disabled=false;queue_redraw()
func _stamp() -> void:
	if elapsed<.72 or issued:return
	issued=true
	finished.emit({"scanMs":elapsed*1000,"identityChecks":[false,false,false],"stamped":true})
func _draw() -> void:
	draw_rect(Rect2(SHEET.position+Vector2(5,6),SHEET.size),Color(.17,.13,.08,.23))
	draw_rect(SHEET,PAPER);draw_rect(SHEET,Color("b7aa92"),false,2)
	draw_rect(SHEET.grow(-6),Color(.45,.38,.28,.13),false,1)
	# Quiet deterministic paper fibres. No generated texture or moving noise.
	for i: int in range(90):
		var point:=Vector2(24+(i*83)%378,92+(i*137)%591)
		draw_line(point,point+Vector2(2+i%4,0),Color(.46,.40,.29,.055),1)
	draw_line(Vector2(40,186),Vector2(389,186),Color("736a5a"),2)
	for y: int in [343,397,446,495]:
		for x: int in range(42,388,8):draw_line(Vector2(x,y),Vector2(x+4,y),Color("b7aa92"),1)
	draw_rect(Rect2(235,287,122,40),RED if ready_shown else MUTED,false,2)
	draw_rect(Rect2(239,291,114,32),Color(RED,.35) if ready_shown else Color(MUTED,.35),false,1)
	draw_texture_rect(stamp_art,Rect2(179,279,36,49.5),false)
	if ready_shown:
		for i: int in range(3):
			var at:=Vector2(194,374+i*49)
			draw_line(at-Vector2(5,5),at+Vector2(5,5),RED,2)
			draw_line(at+Vector2(-5,5),at+Vector2(5,-5),RED,2)
	_draw_source_backpack(Vector2(107,261),1.32)
func _draw_source_backpack(center: Vector2,factor: float) -> void:
	# Same authored components as the physical Library-seat backpack.
	for part: Dictionary in backpack.parts:
		draw_set_transform(center+Vector2(part.x,part.y)*factor,deg_to_rad(float(part.angle)),Vector2.ONE*factor)
		var rect:=Rect2(-Vector2(part.width,part.height)/2,Vector2(part.width,part.height))
		var color:=Color.hex(int(part.color)*256+255);color.a=float(part.alpha)
		if part.type=="ellipse":
			var points:=PackedVector2Array()
			for i: int in range(32):points.append(Vector2(cos(i*TAU/32),sin(i*TAU/32))*rect.size/2)
			draw_colored_polygon(points,color)
		else:draw_rect(rect,color)
		if part.has("stroke"):
			var edge:=Color.hex(int(part.stroke.color)*256+255);edge.a=float(part.stroke.alpha)
			draw_rect(rect,edge,false,float(part.stroke.width))
	draw_set_transform(Vector2.ZERO)
