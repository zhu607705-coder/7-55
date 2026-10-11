extends Control
## This overlay cannot grant, consume, or persist items. Cancellation simply closes it.
signal event(action: String,value: Variant)
const Motion=preload("res://scripts/presentation/lake_rod_assembly.gd")
const Chrome=preload("res://scripts/ui/phone_chrome.gd")
var elapsed_ms: float=0
var closed: bool=false
var read_state: Callable
var reduced_motion: bool=false
var source_font: Font=load("res://assets/rpg/fonts/fusion_pixel_12px_proportional_zh_hans.ttf")
func setup(config: Dictionary) -> void:
	read_state=config.get("read_state",Callable())
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter=Control.MOUSE_FILTER_STOP
	focus_mode=Control.FOCUS_ALL
	grab_focus()
	z_index=100
	if read_state.is_valid(): reduced_motion=bool(read_state.call().get("native",{}).get("settings",{}).get("reduced_motion",false))
func uses_responsive_exploration() -> bool: return true
func cancel() -> void:
	if closed:return
	closed=true
	queue_free()
func _notification(what: int) -> void:
	if what==NOTIFICATION_WM_WINDOW_FOCUS_OUT: cancel()
func _process(delta: float) -> void:
	if closed:return
	if read_state.is_valid():
		var current: Dictionary=read_state.call()
		if not current.get("qizhenLake",{}).get("magneticRodCombined",false) or not current.get("items",{}).get("magneticFishingRod",false): cancel();return
	elapsed_ms+=minf(delta,.05)*1000
	if elapsed_ms>=(1100.0 if reduced_motion else Motion.DURATION_MS):cancel();return
	queue_redraw()
func _gui_input(input: InputEvent) -> void:
	if input is InputEventKey and input.pressed and input.keycode==KEY_ESCAPE: cancel();accept_event()
func _text(p: Vector2,value: String,font_size: int=19,color: Color=Color("e8e3d5")) -> void:
	var width:=source_font.get_string_size(value,HORIZONTAL_ALIGNMENT_LEFT,-1,font_size).x
	draw_string(source_font,p-Vector2(width/2,0),value,HORIZONTAL_ALIGNMENT_LEFT,-1,font_size,color)
func _icon(id: String,center: Vector2,cell: float,alpha: float=1) -> void:
	var data: Dictionary=Chrome.PIXEL_ICONS[id]
	var rows: Array=data.rows
	for y in rows.size():
		for x in str(rows[y]).length():
			var key: String=str(rows[y])[x]
			if data.palette.has(key):draw_rect(Rect2(center+Vector2(x-4.5,y-5)*cell,Vector2.ONE*cell),Color(str(data.palette[key]),alpha))
func _draw() -> void:
	if closed:return
	draw_rect(Rect2(Vector2.ZERO,size),Color("061920",.86))
	var scale_value:=maxf(.1,minf((size.x-24)/510.0,(size.y-100)/410.0))
	var origin:=size/2
	draw_set_transform(origin,0,Vector2.ONE*scale_value)
	draw_style_box(_panel(),Rect2(-249,-201,498,402))
	var pose:=Motion.sample(3400 if reduced_motion else elapsed_ms)
	var captions: Dictionary={"frame":"网框套上竿端","rope":"绕绳 · 收紧","clasp":"磁性扣固定到框沿","tug":"拉紧检查","stow":"磁吸钓竿已收好"}
	_text(Vector2(0,-164),captions[pose.phase],23)
	# Original inventory identities stay visible during the physical join.
	var ids: Array=["fishingRod","brokenNetFrame","nylonCord","swanMagnet"]
	for i in ids.size():
		_icon(ids[i],Vector2(-132+i*88,155),2.3,.75)
	var stow: float=pose.stow
	var assembly_origin:=origin+Vector2(lerpf(0,157,stow),lerpf(0,150,stow))*scale_value
	var unit:=scale_value*lerpf(1,.16,stow)
	draw_set_transform(assembly_origin,lerpf(0,-.2,stow),Vector2.ONE*unit)
	var tug:=Vector2(float(pose.tug),0)
	var tip: Vector2=Motion.TIP+tug
	var grip:=Vector2(-130,70)
	# Tapered rod keeps the source brown shaft and grey reel, with true tip contact.
	var rod:=PackedVector2Array([grip+Vector2(-3,-5),Vector2(-28,-14)+tug*.3,tip-Vector2(1,2),tip+Vector2(2,1),Vector2(-25,-9)+tug*.3,grip+Vector2(4,5)])
	draw_colored_polygon(rod,Color("755234"))
	draw_line(grip,grip+Vector2(21,-16),Color("463a2a"),10)
	draw_arc(grip+Vector2(24,0),9,0,TAU,18,Color("52636a"),4)
	var frame: Vector2=pose.frame+tug
	_icon("brokenNetFrame",frame,6)
	# The original icon's bottom two cells are the socket; extend it exactly to the tip.
	draw_line(frame+Vector2(0,24),frame+Vector2(0,33),Color("536165"),7)
	var wrap: float=pose.wrap
	if wrap<1:
		_icon("nylonCord",Vector2(-140,-91),4,1-wrap*.4)
		if wrap>0:
			var moving_end:=tip+Vector2(cos(wrap*TAU*3)*13,sin(wrap*TAU*3)*7)
			draw_polyline(PackedVector2Array([Vector2(-120,-74),Vector2(-36,-109+wrap*40),moving_end]),Color("d8d2bd"),3,false)
	for i in 4:
		var at:=clampf(wrap*4-i,0,1)
		if at>0:draw_arc(tip+Vector2(-i*3,i*2),8,PI*.1,PI*.1+TAU*at,16,Color("d8d2bd"),3,false)
	if wrap>=1:
		draw_line(tip+Vector2(-7,4),tip+Vector2(-14,12),Color("d8d2bd"),3)
		draw_line(tip+Vector2(-7,4),tip+Vector2(-4,13),Color("d8d2bd"),3)
	_icon("swanMagnet",Vector2(pose.clasp)+tug,3.3)
	# Hands are attached to the shaft and joining component, not a floating UI cursor.
	if stow<.8:
		var work_hand: Vector2=tip+Vector2(2,4)
		if pose.phase=="frame":work_hand=frame+Vector2(29,12)
		elif pose.phase=="clasp":work_hand=Vector2(pose.clasp)+Vector2(22,10)
		elif pose.phase=="tug":work_hand=tip+Vector2(2,4)
		_hand(grip+Vector2(0,5),Vector2(-180,125))
		_hand(work_hand,Vector2(172,90))
	draw_set_transform(Vector2.ZERO)
func _hand(point: Vector2,wrist: Vector2) -> void:
	draw_line(wrist,point,Color("244f75"),17)
	draw_line(point+(wrist-point).normalized()*18,point,Color("e5b891"),12)
	draw_rect(Rect2(point-Vector2(7,5),Vector2(14,10)),Color("e5b891"))
func _panel() -> StyleBoxFlat:
	var result:=StyleBoxFlat.new();result.bg_color=Color("112c36");result.border_color=Color("71999b");result.set_border_width_all(2)
	return result
