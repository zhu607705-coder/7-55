extends Control
## Only the chosen source-pixel position leaves this view.
signal pose_changed(pose: Dictionary)
const Investigation = preload("res://scripts/chapters/c35_investigation.gd")
const Palette = preload("res://scripts/ui/chapter35_palette.gd")
const MAX_ZOOM := 7.0
const NO_POINTER := -2
var layers: RefCounted
var painting: Control
var center := Investigation.CAMPUS_SIZE/2
var lake_gate := Vector2.INF
var zoom := 1.0
var pin := Vector2.INF
var pointer := NO_POINTER
var start := Vector2.ZERO
var last := Vector2.ZERO
var dragged := false
var touches: Dictionary={}

func _init() -> void:
	name="C35CampusPinMap"
	custom_minimum_size=Vector2(0,478)
	size_flags_horizontal=Control.SIZE_EXPAND_FILL
	focus_mode=Control.FOCUS_ALL
	accessibility_name="紫金港校园地图。拖动浏览，双指或滚轮缩放，点击落针。"
	mouse_filter=Control.MOUSE_FILTER_STOP
	texture_filter=CanvasItem.TEXTURE_FILTER_NEAREST
	clip_contents=true
	painting=Control.new()
	painting.mouse_filter=Control.MOUSE_FILTER_IGNORE
	add_child(painting)
	painting.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	painting.draw.connect(_paint)

func _ready() -> void:
	resized.connect(_clamp_and_redraw)
	_clamp_and_redraw()

func restore(pose: Dictionary) -> void:
	center=pose.get("center",center)
	zoom=float(pose.get("zoom",1.0))
	pin=pose.get("pin",Vector2.INF)

func zoom_by(direction: int) -> void:
	_zoom_at(1.5 if direction>0 else 1.0/1.5,size/2,size/2)

func overview() -> void:
	center=Investigation.CAMPUS_SIZE/2
	zoom=1.0
	pin=Vector2.INF
	_changed()

func show_area(area: Vector2) -> void:
	if not area.is_finite(): return
	center=area
	zoom=2.6
	pin=Vector2.INF
	_changed()

func clear_pin() -> void:
	pin=Vector2.INF
	_changed()

func _map_scale() -> float:
	var fitted := minf(size.x/Investigation.CAMPUS_SIZE.x,size.y/Investigation.CAMPUS_SIZE.y)
	return maxf(.001,fitted)*zoom

func _map_origin() -> Vector2:
	return size/2-center*_map_scale()

func _map_point(local: Vector2) -> Vector2:
	return (local-_map_origin())/_map_scale()

func _clamp_and_redraw() -> void:
	var half := (size/(2*_map_scale())).min(Investigation.CAMPUS_SIZE/2)
	center=center.clamp(half,Investigation.CAMPUS_SIZE-half)
	painting.queue_redraw()

func _changed() -> void:
	_clamp_and_redraw()
	pose_changed.emit({"center":center,"zoom":zoom,"pin":pin})

func _zoom_at(multiplier: float, previous_anchor: Vector2, anchor: Vector2) -> void:
	var focal := _map_point(previous_anchor)
	zoom=clampf(zoom*multiplier,1.0,MAX_ZOOM)
	center=focal-(anchor-size/2)/_map_scale()
	_changed()

func _paint() -> void:
	painting.draw_rect(Rect2(Vector2.ZERO,size),Palette.NIGHT)
	if layers!=null and layers.ready:
		var scale_factor := _map_scale()
		var origin := _map_origin()
		layers.draw_background(painting,origin,scale_factor,size,0)
		if lake_gate.is_finite(): _paint_lake_gate(origin+lake_gate*scale_factor)
		if pin.is_finite():
			var tip := origin+pin*scale_factor
			if Rect2(Vector2(13,17),size-Vector2(26,30)).has_point(tip):
				painting.draw_line(tip-Vector2(0,12),tip,Palette.NIGHT,4)
				painting.draw_circle(tip-Vector2(0,12),9,Palette.NIGHT)
				painting.draw_circle(tip-Vector2(0,12),6,Palette.PENDING)
	if has_focus(): painting.draw_rect(Rect2(Vector2.ONE,size-Vector2(2,2)),Palette.PALE,false,2)

func _paint_lake_gate(at: Vector2) -> void:
	if not Rect2(Vector2(8,10),size-Vector2(16,20)).has_point(at): return
	painting.draw_circle(at,6,Palette.NIGHT)
	painting.draw_circle(at,3,Palette.PALE)
	var font := get_theme_font("font","Label")
	var caption := "启真湖入口"
	var width := font.get_string_size(caption,HORIZONTAL_ALIGNMENT_LEFT,-1,15).x
	var x := at.x+10 if at.x+width+18<size.x else at.x-width-16
	var bounds := Rect2(x,at.y-13,width+10,23)
	painting.draw_rect(bounds,Palette.NIGHT)
	painting.draw_string(font,bounds.position+Vector2(5,16),caption,HORIZONTAL_ALIGNMENT_LEFT,-1,15,Palette.PAPER)

func _begin(id: int, position: Vector2) -> void:
	if pointer!=NO_POINTER: return
	pointer=id
	start=position
	last=position
	dragged=false
	grab_focus()

func _move(id: int, position: Vector2) -> void:
	if pointer!=id: return
	if not dragged and start.distance_to(position)<6: return
	dragged=true
	center-=(position-last)/_map_scale()
	last=position
	_changed()

func _end(id: int, position: Vector2, cancelled: bool=false) -> void:
	if pointer!=id: return
	pointer=NO_POINTER
	if not dragged and not cancelled and Rect2(Vector2.ZERO,size).has_point(position):
		_place(position)

func _place(local: Vector2) -> void:
	if layers==null or not layers.ready: return
	var candidate := _map_point(local)
	if not Rect2(Vector2.ZERO,Investigation.CAMPUS_SIZE).has_point(candidate): return
	pin=candidate
	_changed()

func _screen_touch(event: InputEventScreenTouch) -> void:
	var id := event.index
	if event.pressed:
		if touches.size()>=2: return
		touches[id]=event.position
		if touches.size()==1: _begin(id,event.position)
		else: dragged=true
		return
	if not touches.has(id): return
	touches.erase(id)
	if touches.is_empty():
		_end(id,event.position,event.canceled)
	else:
		pointer=int(touches.keys()[0])
		last=touches[pointer]

func _screen_drag(event: InputEventScreenDrag) -> void:
	if not touches.has(event.index): return
	var before: Vector2=touches[event.index]
	touches[event.index]=event.position
	if touches.size()==1:
		_move(event.index,event.position)
		return
	for id: int in touches:
		if id==event.index: continue
		var other: Vector2=touches[id]
		var distance := before.distance_to(other)
		if distance>=8:
			_zoom_at(maxf(8,event.position.distance_to(other))/distance,(before+other)/2,(event.position+other)/2)

func _gui_input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		_screen_touch(event)
	elif event is InputEventScreenDrag:
		_screen_drag(event)
	elif event is InputEventMouse and event.device==InputEvent.DEVICE_ID_EMULATION:
		accept_event()
		return
	elif event is InputEventMouseButton:
		if event.button_index==MOUSE_BUTTON_LEFT:
			if event.pressed: _begin(-1,event.position)
			else: _end(-1,event.position)
		elif event.pressed and event.button_index in [MOUSE_BUTTON_WHEEL_UP,MOUSE_BUTTON_WHEEL_DOWN]:
			_zoom_at(1.5 if event.button_index==MOUSE_BUTTON_WHEEL_UP else 1.0/1.5,event.position,event.position)
		else: return
	elif event is InputEventMouseMotion:
		_move(-1,event.position)
	elif event is InputEventKey and event.pressed:
		var axes := {KEY_LEFT:Vector2.LEFT,KEY_RIGHT:Vector2.RIGHT,KEY_UP:Vector2.UP,KEY_DOWN:Vector2.DOWN}
		if axes.has(event.keycode):
			center+=Vector2(axes[event.keycode])*36/_map_scale()
			_changed()
		elif event.keycode in [KEY_EQUAL,KEY_PLUS,KEY_KP_ADD]: zoom_by(1)
		elif event.keycode in [KEY_MINUS,KEY_KP_SUBTRACT]: zoom_by(-1)
		elif event.keycode in [KEY_ENTER,KEY_SPACE]: _place(size/2)
		else: return
	else: return
	accept_event()

func _notification(what: int) -> void:
	if what==NOTIFICATION_WM_WINDOW_FOCUS_OUT:
		pointer=NO_POINTER
		touches.clear()
	if what in [NOTIFICATION_FOCUS_ENTER,NOTIFICATION_FOCUS_EXIT] and is_instance_valid(painting): painting.queue_redraw()
