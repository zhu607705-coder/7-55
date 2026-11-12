extends Control
## Native 960x540 rendering of ChapterThreeOpeningOverlay and its CSS parts.
const Notice = preload("res://scripts/ui/native_phone_notice.gd")
const Typography = preload("res://scripts/ui/native_typography.gd")
const Overlay = preload("res://scripts/ui/world_overlay_layout.gd")
signal advance
signal skip
var session: RefCounted
var world: Control
var font: Font
var subtitle: Label
var advance_button: Button
var skip_button: Button
var scale_factor: float=1
var origin:=Vector2.ZERO
var last_beat: int=-1
var subtitle_panel:=Rect2()
var subtitle_paper := Notice.card_style()
var narrow: bool=false
func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter=Control.MOUSE_FILTER_STOP
	clip_contents=true
	texture_filter=CanvasItem.TEXTURE_FILTER_NEAREST
	font=Typography.body_font()
	subtitle=Label.new(); subtitle.mouse_filter=Control.MOUSE_FILTER_IGNORE
	subtitle.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	subtitle.vertical_alignment=VERTICAL_ALIGNMENT_CENTER
	Typography.apply_body(subtitle)
	subtitle.add_theme_color_override("font_color",Notice.INK)
	add_child(subtitle)
	advance_button=Button.new(); advance_button.pressed.connect(func():advance.emit()); advance_button.draw.connect(_draw_advance_icon); add_child(advance_button)
	skip_button=Button.new(); skip_button.text="跳过演出"; skip_button.pressed.connect(func():skip.emit()); add_child(skip_button)
	for button: Button in [advance_button,skip_button]:
		button.set_meta("tactile_keep_layout",true)
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
	var text:=str(view.text)
	subtitle.text="" if text.is_empty() else str(view.speaker)+"："+text
	var display_size:=Vector2(960,540)*scale_factor
	var ui_scale:=Overlay.ui_scale(display_size)
	var subtitle_font:=roundi(18*ui_scale)
	narrow=scale_factor<.85
	var panel_size:=Vector2(908,88)*ui_scale
	var panel_origin:=origin+Vector2((display_size.x-panel_size.x)/2,display_size.y-32*ui_scale-panel_size.y)
	subtitle_panel=Rect2(panel_origin,panel_size)
	subtitle.position=panel_origin+Vector2(16,10)*ui_scale
	subtitle.size=Vector2(720,76)*ui_scale
	subtitle.add_theme_font_size_override("font_size",subtitle_font)
	advance_button.position=panel_origin+Vector2(752,31)*ui_scale
	advance_button.size=Vector2(140,46)*ui_scale
	advance_button.text="回到校园" if view.phase=="arrival" else ""
	advance_button.queue_redraw()
	skip_button.position=origin+Vector2(display_size.x-148*ui_scale,24*ui_scale)
	skip_button.size=Vector2(120,36)*ui_scale
	skip_button.disabled=view.phase=="arrival"
	for button: Button in [advance_button,skip_button]: button.add_theme_font_size_override("font_size",roundi(14*ui_scale))
	if narrow:
		# This view is in window space. Wrap at the readable size even
		# when a short window scales the film into a small letterbox.
		var edge:=10*ui_scale
		var padding:=8*ui_scale
		var control_size:=Vector2(64*ui_scale,maxf(28,30*ui_scale))
		var panel_width:=display_size.x-edge*2
		var text_width:=maxf(1,panel_width-control_size.x-20*ui_scale)
		subtitle.size.x=text_width
		# Measure the actual wrapped rows, including the label's line spacing.
		var panel_height:=maxf(control_size.y,subtitle.get_minimum_size().y)+padding*2
		var panel_top:=display_size.y-panel_height-edge
		if size.y>size.x:
			# Tall windows can use the space beneath the film for long lines.
			var bottom_limit:=size.y-origin.y-edge
			panel_top=maxf(panel_top,minf(display_size.y+edge,bottom_limit-panel_height))
		subtitle_panel=Rect2(origin+Vector2(edge,panel_top),Vector2(panel_width,panel_height))
		subtitle.position=subtitle_panel.position+Vector2.ONE*padding
		subtitle.size=Vector2(text_width,panel_height-padding*2)
		advance_button.position=subtitle_panel.end-control_size-Vector2.ONE*padding
		advance_button.size=control_size
		skip_button.size=Vector2(84*ui_scale,control_size.y)
		skip_button.position=origin+Vector2(display_size.x-skip_button.size.x-edge,edge)
	if not was_visible or (last_beat!=view.beatIndex and view.phase=="arrival"): advance_button.grab_focus()
	last_beat=view.beatIndex
	queue_redraw()
func advance_triangle() -> PackedVector2Array:
	if not is_instance_valid(advance_button) or session==null or not advance_button.text.is_empty(): return PackedVector2Array()
	# The source down-triangle must not depend on the pixel font containing ▾.
	var center: Vector2=advance_button.size/2
	var radius:=minf(advance_button.size.x,advance_button.size.y)*.16
	return PackedVector2Array([center+Vector2(-radius,-radius*.55),center+Vector2(radius,-radius*.55),center+Vector2(0,radius*.75)])
func _draw_advance_icon() -> void:
	var triangle: PackedVector2Array=advance_triangle()
	if triangle.size()==3: advance_button.draw_colored_polygon(triangle,advance_button.get_theme_color("font_color"))
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

func _library_projection() -> Dictionary:
	if not is_instance_valid(world) or world.scene_id != "library_interior": return {}
	var layers: RefCounted = world.get("library_layers")
	if layers == null or not layers.objects.ready: return {}
	var room: Vector2 = world.world_size
	var frame := Vector2(960,540) * scale_factor
	# Keep the south doorway and the cart above the narration card.
	var available_height := subtitle_panel.position.y - origin.y - 6.0 * scale_factor
	frame.y = minf(frame.y, maxf(1.0, available_height))
	var zoom := minf(frame.x / room.x, frame.y / room.y)
	return {
		"scene_id": world.scene_id,
		"origin": origin + (frame - room * zoom) / 2.0,
		"zoom": zoom,
		"player": world.player,
		"player_ground_y": world._ground_y(world.player)
	}

func _draw_library(projection: Dictionary, dark: bool) -> void:
	var layers: RefCounted = world.library_layers
	layers.draw_back(self, projection, session.bound_state)
	world.library_gate.draw(self, projection, false)
	layers.draw_front(self, projection, session.bound_state)
	world.library_gate.draw(self, projection, true)
	draw_set_transform(Vector2.ZERO)
	if dark:
		draw_rect(Rect2(projection.origin, world.world_size * projection.zoom), Color(.03,.15,.26,.3))

func _draw_cart(projection: Dictionary, progress: float) -> void:
	var gate: RefCounted = world.library_gate
	var middle: Rect2 = gate.cabinets[1]
	var west: Rect2 = gate.cabinets[0]
	var east: Rect2 = gate.cabinets[2]
	var lane := (west.end.x + middle.position.x) / 2.0
	var parking := lerpf(east.end.x, gate.aperture_x.y, .5)
	var at := Vector2(lerpf(lane, parking, progress) - 44, middle.position.y - 60)
	draw_set_transform(projection.origin, 0, Vector2.ONE * projection.zoom)
	_panel(Rect2(at,Vector2(88,44)),Color("5f6970"),Color("222c32"))
	for i in 3:
		draw_rect(Rect2(at+Vector2(12+i*22,8),Vector2(17,24)),[Color("bfa65d"),Color("738ea0"),Color("a26763")][i])
	for wheel: int in [15,73]:
		draw_circle(at+Vector2(wheel,48),6,Color("192126"))
	draw_set_transform(origin,0,Vector2.ONE*scale_factor)

func _draw_exit_trace(projection: Dictionary, progress: float) -> void:
	var gate: RefCounted = world.library_gate
	var lane: float = (gate.cabinets[0].end.x + gate.cabinets[1].position.x) / 2.0
	var start_y: float = gate.former_door_y - 125.0
	var end_y: float = world.world_size.y - 20.0
	for index in 10:
		var portion := float(index) / 9.0
		var side := -1.0 if index % 2 == 0 else 1.0
		var drift := lerpf(70.0, 0.0, smoothstep(0.0, 0.67, portion))
		var point := Vector2(lane + drift + side * 7.0, lerpf(start_y, end_y, portion))
		var alpha := 0.9 * clampf(progress * 11.0 - index, 0.0, 1.0)
		draw_set_transform(projection.origin + point * projection.zoom, -side * 0.16, Vector2.ONE * projection.zoom)
		draw_rect(Rect2(-4, -6, 8, 8), Color("8fe8f2", alpha))
		draw_rect(Rect2(-3, 4, 6, 4), Color("8fe8f2", alpha))
	draw_set_transform(origin, 0, Vector2.ONE * scale_factor)

func _draw() -> void:
	if session==null: return
	draw_rect(Rect2(Vector2.ZERO,size),Color("020508"))
	var v: Dictionary=session.snapshot(); var phase: String=v.phase; var p: float=v.beatProgress
	var dark: bool=phase in ["mode_unlock","mode_explanation","exit_observation","route_confirm"]
	var projection := _library_projection()
	if not projection.is_empty(): _draw_library(projection, dark)
	draw_set_transform(origin,0,Vector2.ONE*scale_factor)
	if dark or phase == "arrival":
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
		_panel(Rect2(314,210,105,45),Color("d8e3e7"),Color("d8e3e7")); _text(Vector2(326,239),"浅色模式",16,Color("16242b"))
		_panel(Rect2(541,210,105,45),Color("102b3b"),Color("61cbe4")); _text(Vector2(553,239),"深色模式",16,Color("98ecff"))
		draw_line(Vector2(438,232),Vector2(522,232),Color("61cbe4"),3); draw_rect(Rect2(474,225,13,13),Color("f3df79"))
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
		if not projection.is_empty(): _draw_exit_trace(projection, 1.0 if phase == "route_confirm" else p)
		for word: Array in [["食堂",374,248,120],["热气",528,302,240],["退款",374,362,360]]:
			var alpha: float=clampf((session.beat_elapsed_ms-word[3])/360,0,1)
			draw_rect(Rect2(word[1],word[2],52,27),Color("06141c",alpha)); _text(Vector2(word[1]+9,word[2]+18),word[0],12,Color("a8eff9",alpha))
	if phase in ["cart_clear","route_confirm"] and not projection.is_empty():
		_draw_cart(projection, 1.0 if phase == "route_confirm" else p)
	if phase=="arrival":
		draw_set_transform(Vector2.ZERO)
		draw_rect(Rect2(Vector2.ZERO,size),Color("020508",smoothstep(0.0,0.48,p)))
		preload("res://scripts/presentation/library_object_motion.gd").draw_handoff(self,size,v,session.reduced_motion)
		draw_set_transform(origin,0,Vector2.ONE*scale_factor)
		_panel(Rect2(300,205,360,90),Color("050b10",0.9),Color("e2cf70")); _text(Vector2(444,232),"MISSION",12,Color("75d7e7")); _text(Vector2(350,270),"追到东区大食堂",28,Color("f4edd2"))
	draw_rect(Rect2(0,535,960,5),Color("19323d")); draw_rect(Rect2(0,535,960*float(v.overallProgress),5),Color("7ce1ed"))
	draw_set_transform(Vector2.ZERO)
	draw_style_box(subtitle_paper,subtitle_panel)
