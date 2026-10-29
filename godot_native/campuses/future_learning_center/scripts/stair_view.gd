extends Control
## Source-pixel stair illustration and foreground rail; no projective warping.
signal finished(receipt:Dictionary)
signal cancelled
const Model=preload("res://campuses/future_learning_center/scripts/stair_traversal.gd")
const Body=preload("res://scripts/player_metrics.gd")
const PLATE="res://campuses/future_learning_center/assets/rooms/stairs_orthographic_photo.png"
var model=Model.new()
var plate:Texture2D
var sprites:Dictionary={}
var font:Font
var elapsed:=0.0
var fixed_camera:=false

func texture(path:String)->Texture2D:
	return load(path) if OS.has_feature("web") else ImageTexture.create_from_image(Image.load_from_file(ProjectSettings.globalize_path(path)))
func _ready()->void:
	mouse_filter=Control.MOUSE_FILTER_STOP;texture_filter=CanvasItem.TEXTURE_FILTER_NEAREST
	font=load("res://scripts/ui/native_typography.gd").body_font();plate=texture(PLATE)
	for facing:String in ["up","down","side"]:
		for frame:int in 8:sprites[facing+str(frame)]=texture("res://assets/rpg/player/player_%s_%d.png"%[facing,frame])
	hide()
func open(from:int,to:int,landing:String)->bool:
	if not model.start(from,to,landing):return false
	elapsed=0;show();queue_redraw();return true
func close()->void:model.cancel();hide();cancelled.emit()
func _notification(what:int)->void:
	if what in [NOTIFICATION_APPLICATION_FOCUS_OUT,NOTIFICATION_APPLICATION_PAUSED]:model.pause();queue_redraw()
func _process(dt:float)->void:
	if not visible:return
	if not model.paused:elapsed+=minf(dt,.1)
	if model.step(minf(dt,.1)):
		var receipt:Dictionary=model.take_arrival();hide();finished.emit(receipt)
	queue_redraw()
func _input(event:InputEvent)->void:
	if not visible:return
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode==KEY_ESCAPE:close()
		elif event.keycode in [KEY_SPACE,KEY_ENTER]:model.resume() if model.paused else model.pause()
	elif event is InputEventMouseButton and event.pressed and event.button_index==MOUSE_BUTTON_LEFT:_tap(event.position)
	elif event is InputEventScreenTouch and event.pressed:_tap(event.position)
	get_viewport().set_input_as_handled()
func _tap(at:Vector2)->void:
	if Rect2(788,12,154,40).has_point(at):close()
	elif Rect2(390,478,180,44).has_point(at):model.resume() if model.paused else model.pause()
	queue_redraw()

func _rail_polygon(points:Array)->void:
	var vertices:=PackedVector2Array();var uvs:=PackedVector2Array()
	for q:Array in points:
		var at:=Vector2(q[0],q[1]);vertices.append(at);uvs.append(at/plate.get_size())
	draw_polygon(vertices,PackedColorArray([Color.WHITE]),uvs,plate)

func _draw()->void:
	if plate==null or not visible:return
	draw_rect(Rect2(0,0,960,540),Color("202e38"))
	var zoom:float=model.zoom;var center:Vector2=model.center
	if fixed_camera:zoom=.57;center=Vector2(836,470.5)
	draw_set_transform(Vector2(480,270)-center*zoom,0,Vector2.ONE*zoom)
	draw_texture(plate,Vector2.ZERO)
	var foot:Vector2=model.foot();var anchor:Vector2=foot-Body.FOOT_CENTER_OFFSET
	draw_set_transform(Vector2(480,270)-center*zoom+foot*zoom,0,Vector2(1,.32)*zoom)
	draw_circle(Vector2(0,20),13,Color(0,0,0,.20))
	draw_set_transform(Vector2(480,270)-center*zoom,0,Vector2.ONE*zoom)
	var direction:Vector2=model.tangent();var facing:="side" if absf(direction.x)>absf(direction.y) else ("up" if direction.y<0 else "down")
	var frame:int=Body.frame_at(elapsed*1000) if model.active and not model.paused else 0
	var box:Rect2=Body.visual_rect(anchor)
	if facing=="side" and direction.x<0:box.position.x+=box.size.x;box.size.x=-box.size.x
	draw_texture_rect(sprites[facing+str(frame)],box,false)
	# Repaint only the exact same-source foreground metal. The image already
	# contains its pixels; no stretched duplicate wall or full-flight overlay.
	if model.on_upper_flight():
		_rail_polygon(model.spec.upperRail)
		for r:Array in model.spec.upperPosts:draw_texture_rect_region(plate,Rect2(r[0],r[1],r[2],r[3]),Rect2(r[0],r[1],r[2],r[3]))
	draw_set_transform(Vector2.ZERO)
	draw_rect(Rect2(0,0,960,65),Color(.035,.055,.075,.94))
	draw_string(font,Vector2(22,28),"%s  ·  %dF → %dF"%["上楼" if model.direction==1 else "下楼",model.source_floor,model.target_floor],HORIZONTAL_ALIGNMENT_LEFT,-1,20,Color("f1f3ee"))
	draw_string(font,Vector2(22,51),"东北楼梯" if model.via=="northeast_stair" else "西南楼梯",HORIZONTAL_ALIGNMENT_LEFT,-1,13,Color("b9c9cf"))
	draw_style_box(_button_style(),Rect2(788,12,154,40));draw_string(font,Vector2(804,39),"返回原层  Esc",HORIZONTAL_ALIGNMENT_LEFT,-1,16,Color.WHITE)
	draw_rect(Rect2(0,468,960,72),Color(.035,.055,.075,.92))
	draw_string(font,Vector2(24,499),"转向平台" if model.distance>model.lengths[12] and model.distance<model.lengths[15] else ("前往上层平台" if model.direction==1 else "前往下层平台"),HORIZONTAL_ALIGNMENT_LEFT,-1,16,Color("d2dedb"))
	draw_style_box(_button_style(),Rect2(390,478,180,44));draw_string(font,Vector2(406,507),"继续行走 · Space" if model.paused else "暂停脚步 · Space",HORIZONTAL_ALIGNMENT_LEFT,-1,16,Color.WHITE)
	draw_rect(Rect2(664,493,260,4),Color("4d5b63"));draw_rect(Rect2(664,493,260*model.progress(),4),Color("c2d3bc"))
func _button_style()->StyleBoxFlat:
	var style:=StyleBoxFlat.new();style.bg_color=Color("33434c");style.set_corner_radius_all(4);return style
