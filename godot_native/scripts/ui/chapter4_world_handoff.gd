extends Control
## Timed source presentations hosted inside the existing RPG viewport.
signal event(action: String,value: Variant)
const Layers=preload("res://scripts/ui/chapter4_world_layers.gd")
const Metrics=preload("res://scripts/player_metrics.gd")
const Room=preload("res://scripts/games/chapter4_room204_model.gd")
var source_font: Font=load("res://assets/rpg/fonts/fusion_pixel_12px_proportional_zh_hans.ttf")
var layer: RefCounted=Layers.new()
var config: Dictionary={}
var read_state: Callable
var project_position: Callable
var elapsed_ms: float=0
var reported: bool=false
var kind: String=""
var layout: Dictionary={}
var clock_started: bool=false
var clock_dragging: bool=false
var clock_angle: float=234
var clock_release_angle: float=234
func setup(value: Dictionary) -> void:
	config=value; kind=config.get("kind",""); read_state=config.get("read_state",Callable()); project_position=config.get("project_position",Callable())
	mouse_filter=Control.MOUSE_FILTER_IGNORE; set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	layout=JSON.parse_string(FileAccess.get_file_as_string("res://data/source/chapter4-three-floor-maze.layout.json"))
	if not read_state.is_valid() or not project_position.is_valid(): cancel(); return
	Layers.presentation={"kind":kind,"session":config.get("session",""),"elapsedMs":0}
	if kind=="clock_drag":
		mouse_filter=Control.MOUSE_FILTER_STOP; clock_angle=float(layout.finalClockRuntime.initialAngleDegrees); Layers.presentation.angle=clock_angle
func _process(delta: float) -> void:
	if reported: return
	var state: Dictionary=read_state.call(); var c: Dictionary=state.get("chapter4",{})
	if state.get("native",{}).get("scene","")!="duan_yongping_temporal_maze" or c.get("floor","")!=config.get("fromFloor","") or c.get("phase","")!=config.get("phase",""):
		cancel(); return
	if not get_window().has_focus():
		if kind=="clock_drag" and clock_dragging: cancel()
		return
	if kind=="clock_drag" and not clock_started: return
	elapsed_ms+=minf(delta,0.05)*1000
	Layers.presentation.elapsedMs=elapsed_ms
	if kind=="clock_drag":
		clock_angle=lerpf(clock_release_angle,float(layout.finalClockRuntime.targetAngleDegrees),sin(clampf(elapsed_ms/float(layout.finalClockRuntime.presentation.minuteHandAtMs),0,1)*PI/2)); Layers.presentation.angle=clock_angle
	queue_redraw(); if get_parent() is CanvasItem: get_parent().queue_redraw()
	if elapsed_ms>=float(config.get("durationMs",0)):
		reported=true; _clear()
		event.emit(str(config.on_success),{"session":config.session,"kind":kind,"elapsedMs":elapsed_ms,"acknowledged":true,"dragged":kind=="clock_drag" and clock_started,"boarded":true,"arrived":true,"fromFloor":config.fromFloor,"destination":config.get("destination","")})
		queue_free()
func _clear() -> void:
	if Layers.presentation.get("session","")==config.get("session",""): Layers.presentation={}
func cancel() -> void:
	if reported: return
	reported=true; _clear(); event.emit("c4_cancel_presentation",{"session":config.get("session","")}); queue_free()
func _exit_tree() -> void:
	_clear()
	if not reported:
		reported=true; event.emit("c4_cancel_presentation",{"session":config.get("session","")})
func context() -> Dictionary:
	var origin: Vector2=project_position.call(Vector2.ZERO); var unit: Vector2=project_position.call(Vector2.RIGHT)
	return {"origin":origin,"zoom":origin.distance_to(unit),"player":Vector2(0,99999),"scene_id":"duan_yongping_temporal_maze","floor":config.get("fromFloor","")}
func _draw() -> void:
	if reported or not project_position.is_valid(): return
	match kind:
		"paper_flight": _paper_flight()
		"paper_pickup": _paper_pickup()
		"elevator_ride": _elevator()
		"clock_drag": _clock_theft()
		"hall_clock_inspection":
			draw_rect(Rect2(20,size.y-80,size.x-40,62),Color("07111d",0.9))
			draw_multiline_string(source_font,Vector2(36,size.y-57),str(config.get("body","")),HORIZONTAL_ALIGNMENT_LEFT,size.x-72,16,-1,Color("f7f1dc"))
		# Bakery and projection remain depth-composited by Chapter4WorldLayers.
func _paper_flight() -> void:
	var bounds: Rect2
	for a in layout.floors[0].anchors:
		if a.id=="a1_noticeboard_paper": bounds=Room.rect(a.bounds)
	var start: Vector2=Vector2(float(config.get("player",{}).get("x",836)),float(config.get("player",{}).get("y",716)))+Metrics.FOOT_CENTER_OFFSET+Vector2(0,-4.0*48)
	start=start.clamp(Vector2(24,44),Vector2(1648,917))
	var end: Vector2=Vector2(bounds.get_center().x,bounds.end.y); var t: float=clampf(elapsed_ms/1900,0,1); t=(1-cos(t*PI))/2
	layer.draw_frame(self,context(),"chapter4_story_items","sign_in_record_paper",start.lerp(end,t),18*t if t<1 else 0,0.18,Color(1,1,1,0.96))
func _elevator() -> void:
	var from: int=int(str(config.fromFloor).trim_prefix("A")); var dest: int=int(str(config.destination).trim_prefix("A")); var travel: float=abs(dest-from)*620+120; var switch_at: float=1300+travel; var destination: bool=elapsed_ms>=switch_at
	var floor: Dictionary=layout.floors[dest-1 if destination else from-1]; var e: Dictionary=floor.elevator; var aperture: Rect2=Room.rect(e.visibleBounds)
	var ctx: Dictionary=context(); var origin: Vector2=ctx.origin; var zoom: float=ctx.zoom
	var state: Dictionary=read_state.call(); var plate_name: String=str(floor.storyFloor).to_lower()+"_"+str(state.chapter4.timeState)
	if int(floor.displayFloor)==3: plate_name="a3_1850_reference"
	var plate_path: String="res://assets/rpg/interiors/finale/chapter4-755/states/"+plate_name+".png"
	if not ResourceLoader.exists(plate_path): plate_path="res://assets/rpg/interiors/finale/chapter4-755/base/"+str(floor.storyFloor).to_lower()+".png"
	var plate: Texture2D=layer.texture(plate_path)
	if plate: draw_texture_rect(plate,Rect2(origin,Vector2(1672,941)*zoom),false)
	var door: Texture2D=layer.texture("res://assets/rpg/interiors/finale/teaching_building_elevator_doors.png")
	var progress: float=0; var p: Vector2=Room.point(e.doorCenter); var visible: bool=true; var down: bool=false
	if elapsed_ms<440: progress=_sine(elapsed_ms/440); p=Vector2(config.player.x,config.player.y)
	elif elapsed_ms<860: progress=1; p=Vector2(config.player.x,config.player.y).lerp(Room.point(e.doorCenter),_sine((elapsed_ms-440)/420))
	elif elapsed_ms<1300: progress=1-_sine((elapsed_ms-860)/440)
	elif not destination: visible=false
	elif elapsed_ms<switch_at+440: progress=_sine((elapsed_ms-switch_at)/440); visible=false
	elif elapsed_ms<switch_at+860: progress=1; down=true; p=Room.point(e.doorCenter).lerp(Room.point(e.arrivalPosition),_sine((elapsed_ms-switch_at-440)/420))
	else: progress=1-_sine((elapsed_ms-switch_at-860)/440); down=true; p=Room.point(e.arrivalPosition)
	if door:
		var scale_value: float=minf(aperture.size.x/72,aperture.size.y/96); var center: Vector2=Room.point(e.doorCenter)
		draw_texture_rect_region(door,Rect2(origin+(center-Vector2(36,48)*scale_value)*zoom,Vector2(72,96)*scale_value*zoom),Rect2(roundi(progress*5)*72,0,72,96))
	if visible:
		var sprite: Texture2D=layer.texture("res://assets/rpg/player/player_"+("down" if down else "up")+"_"+str(int(elapsed_ms/110)%8)+".png")
		if sprite:
			var visual: Rect2=Metrics.visual_rect(p); draw_texture_rect(sprite,Rect2(origin+visual.position*zoom,visual.size*zoom),false)
	draw_set_transform(origin,0,Vector2.ONE*zoom)
	var shown: int=dest if destination else from
	if elapsed_ms>=1300 and not destination: shown=from+clampi(int((elapsed_ms-1300)/620),0,abs(dest-from))*(1 if dest>from else -1)
	_text(Room.point(e.doorCenter)+Vector2(0,-aperture.size.y/2-13),str(shown)+"F"+(" ↑" if dest>from else " ↓"),13,Color("ffe493"))
	draw_set_transform(Vector2.ZERO)
func _sine(t: float) -> float: return (1-cos(clampf(t,0,1)*PI))/2
func _text(p: Vector2,value: String,size_value: int,color: Color) -> void:
	var font: Font=source_font; var width: float=font.get_string_size(value,HORIZONTAL_ALIGNMENT_LEFT,-1,size_value).x; draw_string(font,p-Vector2(width/2,0),value,HORIZONTAL_ALIGNMENT_LEFT,-1,size_value,color)
func _paper_pickup() -> void:
	# Original seven-second closeup is native vector artwork, including its exact text/timeline.
	var t: float=elapsed_ms; var fade: float=1-clampf((t-5500)/550,0,1); var ink: Color=Color("26332f")
	draw_set_transform(size/2,0,Vector2.ONE*minf(size.x/960,size.y/540))
	draw_rect(Rect2(-480,-270,960,540),Color(0.055,0.09,0.09,0.86*clampf(t/350,0,1)*fade))
	if fade>0:
		draw_line(Vector2(-438,-188),Vector2(438,-188),Color(0.84,0.78,0.65,0.28*fade),1); draw_line(Vector2(-438,206),Vector2(438,206),Color(0.84,0.78,0.65,0.28*fade),1)
		_text(Vector2(-350,-203),"一张迟到的记录",14,Color("c9c2af",fade)); _text(Vector2(370,-203),"第四章 / 7:55",12,Color("9aab9f",fade))
		var room_alpha: float=clampf((t-900)/600,0,1)*fade
		_text(Vector2(-286,-87),"此刻 · 教学楼",16,Color("b0bcae",room_alpha)); _text(Vector2(-286,-20),"22:45",48,Color("ead8a9",room_alpha)); draw_line(Vector2(-336,10),Vector2(-236,10),Color(0.72,0.73,0.58,room_alpha*0.5),1); _text(Vector2(-286,48),"夜还没有结束",14,Color("9aab9f",room_alpha))
		_text(Vector2(0,232),"签到记录已收好",14,Color("ddcfad",clampf((t-3100)/400,0,1)*fade))
	var enter: float=1-pow(1-clampf(t/850,0,1),3); var leave: float=pow(clampf((t-5200)/600,0,1),3); var pos: Vector2=Vector2(70,lerpf(320,-3,enter)).lerp(Vector2(305,242),leave); var rotation: float=lerpf(lerpf(-12,3,enter),-6,leave); var scale_value: float=lerpf(1,0.26,leave); var alpha: float=enter*(1-leave)
	var shake: float=clampf((t-2820)/90,0,2)
	if shake>0 and shake<2: pos+=Vector2(3,4)*(shake if shake<1 else 2-shake); rotation-=shake if shake<1 else 2-shake
	var outer_scale: float=minf(size.x/960,size.y/540)
	draw_set_transform(size/2+pos*outer_scale,deg_to_rad(rotation),Vector2.ONE*scale_value*outer_scale)
	draw_rect(Rect2(-145,-169,326,353),Color(0.008,0.035,0.035,0.48*alpha))
	var polygon: PackedVector2Array=[Vector2(-164,-181),Vector2(135,-181),Vector2(164,-151),Vector2(164,169)]
	for x in range(164,-164,-16): polygon.append(Vector2(x-8,175)); polygon.append(Vector2(maxi(-164,x-16),169))
	polygon.append(Vector2(-164,-181)); draw_colored_polygon(polygon,Color("f0e4c4",alpha)); draw_colored_polygon(PackedVector2Array([Vector2(135,-181),Vector2(135,-151),Vector2(164,-151)]),Color("c4b691",alpha))
	for y in [-71,35,114]: draw_line(Vector2(-137,y),Vector2(137,y),Color(ink,0.22*alpha),1)
	draw_line(Vector2(-155,65),Vector2(156,55),Color(1,1,1,0.34*alpha),1); draw_line(Vector2(-155,67),Vector2(156,57),Color(ink,0.08*alpha),1)
	for y in range(-146,145,22): draw_circle(Vector2(-151,y),2,Color("b8af96",0.6*alpha))
	for n in range(31): draw_rect(Rect2(-106+n*7,133,4 if n%4==0 else 2,15+n%3*3),Color(ink,(0.6 if n%3==0 else 0.28)*alpha))
	for row in [[-133,"签 到 记 录",26,"26332f"],[-98,"已找回的纸条",13,"6a7160"],[-42,"手机停留在",14,"77745e"],[11,"07:55:23",42,"26332f"],[94,"纸条回来了，时间没有。",16,"26332f"]]: _text(Vector2(0,row[0]),row[1],row[2],Color(row[3],alpha))
	var stamp: float=pow(clampf((t-2600)/220,0,1),3); var stamp_scale: float=lerpf(1.65,1,stamp)
	var transform: Transform2D=Transform2D(deg_to_rad(rotation),size/2+pos*outer_scale).scaled_local(Vector2.ONE*scale_value*outer_scale)*Transform2D(deg_to_rad(-9),Vector2(13,63)).scaled_local(Vector2.ONE*stamp_scale)
	draw_set_transform_matrix(transform); draw_rect(Rect2(-102,-25,204,50),Color("a43f32",0.94*stamp*alpha),false,3); draw_rect(Rect2(-96,-19,192,38),Color("a43f32",0.8*stamp*alpha),false,1); _text(Vector2(0,9),"时间不符",26,Color("a43f32",stamp*alpha)); draw_set_transform(Vector2.ZERO)
	if t>=5600: _text(Vector2(size.x/2,size.y-35),"记录回来了，你没有回到记录发生的时候。",18,Color("ddcfad"))

func _clock_endpoint(angle_value: float) -> Vector2:
	return (Room.point(layout.finalClockRuntime.clockCenter)+Vector2.from_angle(deg_to_rad(angle_value))*float(layout.finalClockRuntime.minuteHandRadius)).round()
func _begin_clock_theft() -> void:
	if kind!="clock_drag" or clock_started or reported: return
	clock_started=true; clock_dragging=false; clock_release_angle=clock_angle; elapsed_ms=0; queue_redraw()
func _clock_pointer(position: Vector2,pressed: bool,cancelled_input: bool=false) -> void:
	if clock_started or reported: return
	if cancelled_input: cancel(); return
	if pressed:
		var endpoint: Vector2=project_position.call(_clock_endpoint(clock_angle)); var zoom: float=context().zoom
		clock_dragging=position.distance_to(endpoint)<=maxf(16,12*zoom)
	elif clock_dragging:
		_begin_clock_theft()
func _clock_motion(position: Vector2) -> void:
	if not clock_dragging or clock_started or reported: return
	var center: Vector2=project_position.call(Room.point(layout.finalClockRuntime.clockCenter))
	clock_angle=fposmod(rad_to_deg((position-center).angle()),360); Layers.presentation.angle=clock_angle
	if absf(wrapf(clock_angle-float(layout.finalClockRuntime.targetAngleDegrees),-180,180))<=float(layout.finalClockRuntime.releaseToleranceDegrees): _begin_clock_theft()
	queue_redraw(); if get_parent() is CanvasItem: get_parent().queue_redraw()
func _gui_input(input: InputEvent) -> void:
	if kind!="clock_drag" or reported: return
	if input is InputEventMouseButton and input.button_index==MOUSE_BUTTON_LEFT: _clock_pointer(input.position,input.pressed,input.canceled)
	elif input is InputEventMouseMotion: _clock_motion(input.position)
	elif input is InputEventScreenTouch: _clock_pointer(input.position,input.pressed,input.canceled)
	elif input is InputEventScreenDrag: _clock_motion(input.position)
func _unhandled_key_input(input: InputEvent) -> void:
	if kind!="clock_drag" or reported or not input.is_pressed() or input.is_echo(): return
	if input.keycode==KEY_ESCAPE: cancel(); get_viewport().set_input_as_handled()
	elif input.keycode in [KEY_SPACE,KEY_ENTER]: _begin_clock_theft(); get_viewport().set_input_as_handled()
	elif input.keycode in [KEY_LEFT,KEY_RIGHT] and not clock_started:
		clock_angle+=-2 if input.keycode==KEY_LEFT else 2; Layers.presentation.angle=clock_angle; queue_redraw(); get_viewport().set_input_as_handled()
func _clock_theft() -> void:
	if not clock_started:
		draw_rect(Rect2(20,size.y-69,size.x-40,49),Color("07111d",0.9))
		_text(Vector2(size.x/2,size.y-40),"拖动旧钟分针 · 空格拨钟 · Esc 取消",16,Color("f7f1dc"))
		return
	var start_at: float=layout.finalClockRuntime.presentation.paperFlightAtMs
	if elapsed_ms<start_at: return
	var duration: float=maxf(120,float(layout.finalClockRuntime.presentation.commitAtMs)-start_at-40)
	var t: float=_sine((elapsed_ms-start_at)/duration)
	var start: Vector2=Vector2(float(config.player.x),float(config.player.y))+Metrics.FOOT_CENTER_OFFSET+Vector2(0,-34)
	var destination: Vector2=_clock_endpoint(float(layout.finalClockRuntime.targetAngleDegrees))
	layer.draw_frame(self,context(),"chapter4_story_items","sign_in_record_paper",start.lerp(destination,t),lerpf(-12,28,t),0.15)
