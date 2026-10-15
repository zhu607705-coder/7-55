extends Control
## Native 960x540 rendering of ChapterThreeOpeningOverlay and its CSS parts.
signal advance
signal skip
var session: RefCounted
var font: Font
var backdrop: Texture2D
var subtitle: Label
var advance_button: Button
var skip_button: Button
var scale_factor: float=1
var origin:=Vector2.ZERO
var last_beat: int=-1
var subtitle_panel:=Rect2()
var narrow: bool=false
func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter=Control.MOUSE_FILTER_STOP
	clip_contents=true
	font=load("res://assets/rpg/fonts/fusion_pixel_12px_proportional_zh_hans.ttf")
	backdrop=load("res://assets/rpg/interiors/library_interior.png")
	subtitle=Label.new(); subtitle.mouse_filter=Control.MOUSE_FILTER_IGNORE
	subtitle.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	subtitle.vertical_alignment=VERTICAL_ALIGNMENT_CENTER
	subtitle.add_theme_color_override("font_color",Color("f4edd6"))
	add_child(subtitle)
	advance_button=Button.new(); advance_button.pressed.connect(func():advance.emit()); advance_button.draw.connect(_draw_advance_icon); add_child(advance_button)
	skip_button=Button.new(); skip_button.text="跳过演出"; skip_button.pressed.connect(func():skip.emit()); add_child(skip_button)
	for button: Button in [advance_button,skip_button]:
		var box:=StyleBoxFlat.new(); box.bg_color=Color("101e28",0.94); box.border_color=Color("cfbd74"); box.set_border_width_all(2)
		for mode: String in ["normal","hover","pressed","hover_pressed","disabled"]: button.add_theme_stylebox_override(mode,box)
		var focused: StyleBoxFlat=box.duplicate(); focused.border_color=Color("9ee7f1"); focused.set_border_width_all(3)
		button.add_theme_stylebox_override("focus",focused)
		for role: String in ["font_color","font_hover_color","font_pressed_color","font_hover_pressed_color","font_focus_color","font_disabled_color"]: button.add_theme_color_override(role,Color("f4edd6"))
	visible=false
func tick() -> void:
	if session==null: visible=false; return
	var was_visible: bool=visible
	visible=true
	scale_factor=minf(size.x/960,size.y/540); origin=(size-Vector2(960,540)*scale_factor)/2
	var view: Dictionary=session.snapshot()
	subtitle.text=str(view.speaker)+"："+str(view.text)
	narrow=size.x<620
	subtitle.position=origin+Vector2(42,430)*scale_factor
	subtitle.size=Vector2(720,76)*scale_factor
	subtitle.add_theme_font_size_override("font_size",maxi(10,int(18*scale_factor)))
	advance_button.position=origin+Vector2(778,451)*scale_factor; advance_button.size=Vector2(140,46)*scale_factor
	advance_button.text="回到校园" if view.phase=="arrival" else ""
	advance_button.queue_redraw()
	skip_button.position=origin+Vector2(812,24)*scale_factor; skip_button.size=Vector2(120,36)*scale_factor
	skip_button.disabled=view.phase=="arrival"
	for button: Button in [advance_button,skip_button]: button.add_theme_font_size_override("font_size",maxi(10,int(14*scale_factor)))
	subtitle_panel=Rect2(origin+Vector2(26,420)*scale_factor,Vector2(908,88)*scale_factor)
	if narrow:
		# This view is already in Main's screen space, so 14 means 14 actual
		# pixels rather than 14 logical pixels inside the scaled world.
		var display_size:=Vector2(960,540)*scale_factor
		var panel_width: float=display_size.x-20
		var text_width: float=panel_width-84
		var text_font: Font=subtitle.get_theme_font("font")
		var text_height: float=text_font.get_multiline_string_size(subtitle.text,HORIZONTAL_ALIGNMENT_LEFT,text_width,14).y
		var panel_height: float=maxf(54,text_height+16)
		subtitle_panel=Rect2(origin+Vector2(10,display_size.y-panel_height-10),Vector2(panel_width,panel_height))
		subtitle.add_theme_font_size_override("font_size",14)
		subtitle.position=subtitle_panel.position+Vector2(8,8); subtitle.size=Vector2(text_width,panel_height-16)
		advance_button.position=subtitle_panel.end-Vector2(72,38); advance_button.size=Vector2(64,30)
		skip_button.position=origin+Vector2(display_size.x-94,10); skip_button.size=Vector2(84,30)
		for button: Button in [advance_button,skip_button]: button.add_theme_font_size_override("font_size",12)
	if not was_visible or (last_beat!=view.beatIndex and view.phase=="arrival"): advance_button.grab_focus()
	last_beat=view.beatIndex
	queue_redraw()
func advance_triangle() -> PackedVector2Array:
	if not is_instance_valid(advance_button) or session==null or not advance_button.text.is_empty(): return PackedVector2Array()
	# The source down-triangle must not depend on the pixel font containing ▾.
	var center: Vector2=advance_button.size/2
	var radius: float=clampf(advance_button.size.y*.16,4,8)
	return PackedVector2Array([center+Vector2(-radius,-radius*.55),center+Vector2(radius,-radius*.55),center+Vector2(0,radius*.75)])
func _draw_advance_icon() -> void:
	var triangle: PackedVector2Array=advance_triangle()
	if triangle.size()==3: advance_button.draw_colored_polygon(triangle,Color("f4edd6"))
func _input(event: InputEvent) -> void:
	if not visible or session==null: return
	# A shell modal above this presentation owns its focus and keyboard. The
	# opening claims its own advance button when shown, so normal continuation
	# remains local without consuming a settings/form key behind the modal.
	var focused: Control=get_viewport().gui_get_focus_owner()
	if focused!=null and focused!=self and not is_ancestor_of(focused): return
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode==KEY_TAB:
			if skip_button.disabled or skip_button.has_focus(): advance_button.grab_focus()
			else: skip_button.grab_focus()
			get_viewport().set_input_as_handled()
		elif event.keycode in [KEY_SPACE,KEY_ENTER,KEY_KP_ENTER]:
			if skip_button.has_focus() and not skip_button.disabled: skip.emit()
			else: advance.emit()
			get_viewport().set_input_as_handled()
func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index==MOUSE_BUTTON_LEFT and event.pressed:
		advance.emit(); accept_event()
func _text(at: Vector2,text: String,font_size: int,color: Color,width: float=-1) -> void:
	draw_string(font,at,text,HORIZONTAL_ALIGNMENT_LEFT,width,font_size,color)
func _panel(rect: Rect2,color: Color=Color("101e28"),border: Color=Color("cfbd74")) -> void:
	draw_rect(Rect2(rect.position+Vector2(5,6),rect.size),Color(0,0,0,0.45)); draw_rect(rect,color); draw_rect(rect,border,false,2)
func _draw() -> void:
	if session==null: return
	draw_rect(Rect2(Vector2.ZERO,size),Color("020508"))
	draw_set_transform(origin,0,Vector2.ONE*scale_factor)
	var v: Dictionary=session.snapshot(); var phase: String=v.phase; var p: float=v.beatProgress
	var dark: bool=phase in ["mode_unlock","mode_explanation","exit_observation","route_confirm"]
	if phase!="arrival":
		var factor: float=1.11 if dark else 1.14 if phase in ["paper_burst","paper_dialogue"] else 1.095 if phase in ["record_scan","record_escape"] else 1.035
		var extent:=Vector2(960,540)*factor
		draw_texture_rect(backdrop,Rect2((Vector2(960,540)-extent)/2,extent),false,Color(0.42,0.59,0.64) if dark else Color(0.72,0.74,0.70))
		draw_rect(Rect2(0,0,960,540),Color(0.015,0.04,0.07,0.5 if dark else 0.28))
	for y in range(0,540,4): draw_line(Vector2(0,y),Vector2(960,y),Color(0.72,0.89,0.9,0.022))
	if phase!="arrival":
		_panel(Rect2(26,24,220,62)); _text(Vector2(42,44),"CHAPTER 03",10,Color("d2bb58")); _text(Vector2(42,70),"07:55 的残影",18,Color("f4f1dd"))
	if phase in ["conversation","record_scan","record_escape"]:
		var center:=Vector2(480,248)
		if phase=="record_scan" and not session.reduced_motion: center.x+=sin(p*TAU*9)*3
		_panel(Rect2(center-Vector2(119,74),Vector2(238,148)),Color("071117",0.93),Color("d85f5c") if phase=="record_escape" else Color("cfbd74"))
		_text(center+Vector2(-44,-13),"022",44,Color("ff7772") if phase=="record_escape" else Color("efe2a7"))
		draw_rect(Rect2(center+Vector2(-83,5),Vector2(166,6)),Color("253b43"))
		if phase=="record_scan": draw_rect(Rect2(center+Vector2(-83,5),Vector2(166*minf(p*1350/1150,1),6)),Color("6fd3e7"))
		_text(center+Vector2(-44,34),"RECORD QUERY",10,Color("98a9ad")); _text(center+Vector2(-18,55),"07:55",10,Color("ff7772") if phase=="record_escape" else Color("6fd3e7"))
	if phase in ["mode_unlock","mode_explanation"]:
		_panel(Rect2(288,160,384,160),Color("051018",0.96),Color("61cbe4"))
		_text(Vector2(424,189),"外观模式切换",12,Color("dfcf77"))
		_panel(Rect2(314,210,105,45),Color("d8e3e7"),Color("d8e3e7")); _text(Vector2(326,239),"浅色模式",16,Color("16242b"))
		_panel(Rect2(541,210,105,45),Color("102b3b"),Color("61cbe4")); _text(Vector2(553,239),"深色模式",16,Color("98ecff"))
		draw_line(Vector2(438,232),Vector2(522,232),Color("61cbe4"),3); draw_rect(Rect2(474,225,13,13),Color("f3df79"))
		_text(Vector2(360,293),"当前校园 / 07:55 的校园残影",14,Color("a9c0c9"))
	if phase in ["paper_burst","paper_dialogue"]:
		var lift: float=0 if session.reduced_motion else sin(session.elapsed_ms/950*TAU)*4
		var paper_scale: float=1 if phase=="paper_dialogue" else lerpf(0.2,1,minf(1,p*2))
		var center:=origin+(Vector2(480,227+lift))*scale_factor
		draw_set_transform(center,deg_to_rad(-3),Vector2.ONE*scale_factor*paper_scale)
		_panel(Rect2(-60,-41,120,82),Color("eee6cc"),Color("463a2b")); draw_line(Vector2(-42,-18),Vector2(42,-18),Color("79654a"),3); draw_line(Vector2(-42,-7),Vector2(16,-7),Color("79654a"),3)
		_text(Vector2(-47,28),"本人马上回来",10,Color("5d2630"))
		draw_set_transform(origin,0,Vector2.ONE*scale_factor)
		for i in range(6):
			var drift: float=0 if session.reduced_motion else fposmod(session.elapsed_ms/1400+i*0.17,1)
			draw_rect(Rect2(384+i*50+drift*25,250-i*12-drift*35,8,4),Color("c3eef3",1-drift*0.65))
	if phase in ["exit_observation","route_confirm"]:
		for i in range(6):
			var alpha: float=clampf((session.beat_elapsed_ms-i*70)/450,0,1)
			draw_rect(Rect2(451+(i%2)*29+i*4,259+i*27,11,6),Color("8fe8f2",alpha))
		for word: Array in [["食堂",374,248,120],["热气",528,302,240],["退款",374,362,360]]:
			var alpha: float=clampf((session.beat_elapsed_ms-word[3])/360,0,1)
			draw_rect(Rect2(word[1],word[2],52,27),Color("06141c",alpha)); _text(Vector2(word[1]+9,word[2]+18),word[0],12,Color("a8eff9",alpha))
	if phase in ["cart_clear","route_confirm"]:
		var x: float=672 if phase=="route_confirm" else lerpf(461,672,p)
		_panel(Rect2(x,367,88,44),Color("5f6970"),Color("222c32"))
		for i in range(3): draw_rect(Rect2(x+12+i*22,375,17,24),[Color("bfa65d"),Color("738ea0"),Color("a26763")][i])
		for wheel: int in [15,73]: draw_circle(Vector2(x+wheel,415),6,Color("192126"))
	if phase=="arrival":
		_panel(Rect2(300,205,360,90),Color("050b10",0.9),Color("e2cf70")); _text(Vector2(444,232),"MISSION",12,Color("75d7e7")); _text(Vector2(350,270),"追到东区大食堂",28,Color("f4edd2"))
	if not narrow: _panel(Rect2(26,420,908,88),Color("071017",0.95),Color("8ab3b7") if v.tone=="system" else Color("cfbd74"))
	draw_rect(Rect2(0,535,960,5),Color("19323d")); draw_rect(Rect2(0,535,960*float(v.overallProgress),5),Color("7ce1ed"))
	draw_set_transform(Vector2.ZERO)
	if narrow: _panel(subtitle_panel,Color("071017",0.95),Color("8ab3b7") if v.tone=="system" else Color("cfbd74"))
