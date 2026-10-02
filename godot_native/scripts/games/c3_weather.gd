extends Control
signal finished(result: Dictionary)
signal cancelled
const TARGET: Array = [34.0,52.0,70.0]
const WIND: Array = [5.5,6.5,7.5]
var positions: Array = [78.0,22.0,38.0]
var directions: Array = [0,0,0]
var touch_directions: Array = [0,0,0]
var controlled: Array = [false,false,false]
var moves: int = 0
var elapsed: float = 0
var stable: float = 0
var started: bool = false
var paused: bool = false
var label: Label
var start_button: Button
var exit_button: Button
var row_buttons: Array[Button]=[]
var row_centers: Array=[175.0,265.0,355.0]
var presentation_scale: float=-1
var compact_presentation: bool=false
var layout_label_size:=Vector2.ZERO
const FONT=preload("res://assets/rpg/fonts/fusion_pixel_12px_proportional_zh_hans.ttf")
func setup(_config: Dictionary) -> void: pass
func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_TOP_LEFT)
	size=Vector2(960,540)
	label=Label.new()
	label.position=Vector2(60,25)
	label.size=Vector2(840,100)
	label.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_font_override("font",FONT)
	label.add_theme_color_override("font_color",Color("eaf1f7"))
	add_child(label)
	for row: int in range(3):
		var band: int = 2-row
		for dir: int in [-1,1]:
			var button: Button = Button.new()
			button.text=("向左" if dir==-1 else "向右")
			button.set_meta("weather_band",band)
			button.set_meta("weather_direction",dir)
			button.tooltip_text=["高层","中层","低层"][row]+("后退" if dir==-1 else "前进")+"，键盘 "+[["Q","E"],["A","D"],["Z","C"]][row][0 if dir==-1 else 1]
			button.position=Vector2(42 if dir==-1 else 825,150+row*90)
			button.size=Vector2(90,50)
			row_buttons.append(button)
			_style_button(button)
			button.button_down.connect(func() -> void: touch_directions[band]=dir)
			button.button_up.connect(func() -> void: touch_directions[band]=0)
			add_child(button)
	start_button=Button.new()
	_style_button(start_button)
	start_button.text="开始调整"
	start_button.position=Vector2(390,445)
	start_button.size=Vector2(180,48)
	start_button.pressed.connect(func() -> void: started=true; paused=false; start_button.hide())
	add_child(start_button)
	exit_button=Button.new()
	_style_button(exit_button)
	exit_button.text="返回天气"
	exit_button.position=Vector2(40,445)
	exit_button.size=Vector2(150,45)
	exit_button.pressed.connect(func() -> void: cancelled.emit())
	add_child(exit_button)
	_apply_presentation_layout(true)
	refresh()
func _notification(what: int) -> void:
	if what==NOTIFICATION_APPLICATION_FOCUS_OUT and started:
		directions=[0,0,0]
		touch_directions=[0,0,0]
		paused=true
		if is_instance_valid(start_button): start_button.text="继续调整"; start_button.show()
func set_direction(band: int, direction: int) -> void:
	if directions[band]!=direction and direction!=0:
		moves+=1
		controlled[band]=true
	directions[band]=direction
func _process(delta: float) -> void:
	_apply_presentation_layout()
	if not started or paused: return
	var keys: Array = [[KEY_Z,KEY_C],[KEY_A,KEY_D],[KEY_Q,KEY_E]]
	for band: int in range(3):
		var dir: int = int(Input.is_physical_key_pressed(keys[band][1]))-int(Input.is_physical_key_pressed(keys[band][0]))
		set_direction(band,dir if dir!=0 else int(touch_directions[band]))
	var dt: float=minf(delta,0.05)
	elapsed+=dt*1000
	var aligned: bool=true
	for band: int in range(3):
		positions[band]=clampf(positions[band]+(-WIND[band]+directions[band]*30.0)*dt,2,98)
		aligned=aligned and absf(positions[band]-TARGET[band])<=8
	stable=minf(1000,stable+dt*1000) if aligned else 0.0
	refresh()
	if stable>=1000 and controlled.all(func(v: Variant) -> bool: return bool(v)):
		started=false
		finished.emit({"moves":moves,"cloudOffsets":positions.duplicate(),"controlledBands":controlled.duplicate(),"stableMs":stable,"elapsedMs":elapsed})
func _style_button(button: Button) -> void:
	button.add_theme_font_override("font",FONT)
	button.add_theme_color_override("font_color",Color("14212a"))
	button.add_theme_color_override("font_hover_color",Color("14212a"))
	button.add_theme_color_override("font_pressed_color",Color("14212a"))
	for state: String in ["normal","hover","pressed"]:
		var style:=StyleBoxFlat.new()
		style.bg_color=Color("c9e96e") if state=="pressed" else Color("e8e6db")
		style.border_color=Color("9aafae"); style.set_border_width_all(2); style.set_corner_radius_all(4)
		button.add_theme_stylebox_override(state,style)
func _apply_presentation_layout(force: bool=false) -> void:
	if not is_instance_valid(exit_button): return
	var factor: float=maxf(.15,absf(get_global_transform_with_canvas().get_scale().x))
	if not force and is_equal_approx(factor,presentation_scale) and label.size==layout_label_size: return
	presentation_scale=factor; compact_presentation=960*factor<620
	var body_font: int=maxi(20,int(ceil(15.0/factor)))
	var button_font: int=maxi(18,int(ceil(14.0/factor)))
	label.add_theme_font_size_override("font_size",body_font)
	label.position=Vector2(60,10 if compact_presentation else 25)
	refresh()
	var caption_height: float=ceil(FONT.get_multiline_string_size(label.text,HORIZONTAL_ALIGNMENT_LEFT,840,body_font).y)
	label.size=Vector2(840,caption_height if compact_presentation else 100)
	var button_h: float=maxf(50,ceil(30.0/factor)) if compact_presentation else 50
	var footer_h: float=maxf(48,ceil(30.0/factor)) if compact_presentation else 48
	var footer_y: float=540-10-footer_h if compact_presentation else 445
	if compact_presentation:
		var first: float=label.position.y+label.size.y+4+button_h/2
		var last: float=footer_y-4-button_h/2
		row_centers=[first,(first+last)/2,last]
	else: row_centers=[175.0,265.0,355.0]
	for i in range(row_buttons.size()):
		var button: Button=row_buttons[i]
		button.add_theme_font_size_override("font_size",button_font)
		button.position=Vector2(28 if i%2==0 else 824,float(row_centers[i/2])-button_h/2) if compact_presentation else Vector2(42 if i%2==0 else 825,150+(i/2)*90)
		button.size=Vector2(108 if compact_presentation else 90,button_h)
	for button: Button in [start_button,exit_button]: button.add_theme_font_size_override("font_size",button_font)
	start_button.size=Vector2(maxf(180,FONT.get_string_size(start_button.text,HORIZONTAL_ALIGNMENT_LEFT,-1,button_font).x+24),footer_h)
	start_button.position=Vector2(480-start_button.size.x/2,footer_y)
	exit_button.size=Vector2(maxf(150,FONT.get_string_size(exit_button.text,HORIZONTAL_ALIGNMENT_LEFT,-1,button_font).x+24),footer_h)
	exit_button.position=Vector2(40,footer_y)
	refresh()
	layout_label_size=label.size
func refresh() -> void:
	if is_instance_valid(label):
		label.text=("风向校准 · 逆风修正三层云带\n高层 Q/E · 中层 A/D · 低层 Z/C\n%s · 稳定 %.1f / 1.0 秒" % ["同步稳定" if controlled.all(func(v: Variant) -> bool: return bool(v)) else "三层均需操作",stable/1000.0]) if compact_presentation else "天气 · 三层云带\n高层 Q/E，中层 A/D，低层 Z/C；触屏按住左右控制。让三层云带进入目标区域并保持稳定。\n稳定 %.1f / 1.0 秒" % (stable/1000.0)
	queue_redraw()
func _draw() -> void:
	draw_rect(Rect2(0,0,960,540),Color("15243a"))
	for row: int in range(3):
		var band: int=2-row
		var y: float=float(row_centers[row])
		draw_rect(Rect2(145,y-22,660,44),Color("233b54"))
		draw_rect(Rect2(145+(TARGET[band]-8)*6.6,y-24,16*6.6,48),Color("427b68"))
		draw_circle(Vector2(145+positions[band]*6.6,y),19,Color("eaf1f7"))
		draw_circle(Vector2(135+positions[band]*6.6,y+8),14,Color("eaf1f7"))
		draw_circle(Vector2(160+positions[band]*6.6,y+6),15,Color("eaf1f7"))
