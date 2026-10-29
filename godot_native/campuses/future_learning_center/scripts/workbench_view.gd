extends Control
## Direct manipulation of the bench, shared by native and standalone Web.
signal closed
const Model=preload("res://campuses/future_learning_center/scripts/workbench_model.gd")
const MOTOR:=Vector2(262,205)
const AXLE:=Vector2(350,205)
const OUTPUT:=Vector2(650,205)
const POWER:=Vector2(480,386)
const TENSION:=Vector2(610,386)
const BELT:=Rect2(690,350,160,84)
var model=Model.new()
var font:Font
var bench:Texture2D
var crop:Rect2
var drag:=-1
var drag_origin:=Vector2.ZERO
var pointer:=Vector2.ZERO
var touch_id:=-1
var feedback:=""

func _ready()->void:
	mouse_filter=Control.MOUSE_FILTER_STOP
	font=load("res://scripts/ui/native_typography.gd").body_font()
	var manifest:Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://campuses/future_learning_center/data/object_assets.json"))
	var a:Dictionary=manifest.lab_assembly_bench;var b:Array=a.opaqueBounds
	crop=Rect2(b[0],b[1],b[2]-b[0],b[3]-b[1])
	bench=load(a.path) if OS.has_feature("web") else ImageTexture.create_from_image(Image.load_from_file(ProjectSettings.globalize_path(a.path)))
	hide()
func open()->void:feedback="";show();queue_redraw()
func close()->void:
	model.cancel();drag=-1;touch_id=-1;hide();closed.emit()
func _notification(what:int)->void:
	if what==NOTIFICATION_APPLICATION_FOCUS_OUT or what==NOTIFICATION_APPLICATION_PAUSED:
		if model.running:feedback="试转已暂停，按台上的开关重新开始。"
		model.cancel();drag=-1;touch_id=-1
func _process(dt:float)->void:
	if not visible:return
	model.step(minf(dt,.1));queue_redraw()
func _input(event:InputEvent)->void:
	if not visible:return
	if event is InputEventKey and event.pressed and not event.echo:
		match event.keycode:
			KEY_ESCAPE:close()
			KEY_1,KEY_2,KEY_3:_edit("gear",int(event.keycode)-int(KEY_1))
			KEY_B:_edit("belt",2 if model.belt==1 else 1)
			KEY_T:_edit("tension",(model.tension+1)%3)
			KEY_SPACE:feedback="";model.start()
			KEY_R:model.reset();feedback=""
		get_viewport().set_input_as_handled()
	elif event is InputEventMouseButton and event.button_index==MOUSE_BUTTON_LEFT:
		if event.pressed:_press(event.position)
		else:_release(event.position)
		get_viewport().set_input_as_handled()
	elif event is InputEventMouseMotion:
		pointer=event.position
		get_viewport().set_input_as_handled()
	elif event is InputEventScreenTouch:
		if event.pressed and touch_id<0:touch_id=event.index;_press(event.position)
		elif not event.pressed and touch_id==event.index:_release(event.position);touch_id=-1
		get_viewport().set_input_as_handled()
	elif event is InputEventScreenDrag:
		if event.index==touch_id:pointer=event.position
		get_viewport().set_input_as_handled()
func _edit(part:String,value:int)->void:
	model.edit(part,value);feedback="";queue_redraw()
func _press(at:Vector2)->void:
	pointer=at;drag_origin=at
	if Rect2(818,0,132,70).has_point(at):close();return
	if Rect2(822,450,126,50).has_point(at):model.reset();feedback="";return
	for i:int in 3:
		if Rect2(98+i*96,344,88,94).has_point(at):drag=i;return
	if at.distance_to(POWER)<48:feedback="";model.start()
	elif at.distance_to(TENSION)<50:_edit("tension",(model.tension+1)%3)
	elif BELT.has_point(at) or Rect2(405,160,206,75).has_point(at):_edit("belt",2 if model.belt==1 else 1)
func _release(at:Vector2)->void:
	if drag<0:return
	if at.distance_to(AXLE)<68 or at.distance_to(drag_origin)<12:_edit("gear",drag)
	else:feedback="把齿轮放到中间的空轴位；也可以点按零件装入。"
	drag=-1
func text_at(value:String,at:Vector2,size_value:=16,color:=Color("e8e0c8"))->void:
	draw_string(font,at,value,HORIZONTAL_ALIGNMENT_LEFT,-1,size_value,color)
static func gear_at(canvas:CanvasItem,center:Vector2,radius:float,phase:float,color:Color)->void:
	var poly:=PackedVector2Array()
	for i:int in 80:
		var angle:=phase+TAU*i/80.0;var r:=radius*(1.0 if i%4 in [0,1] else .84)
		poly.append(center+Vector2(cos(angle)*r,sin(angle)*r*.58))
	canvas.draw_colored_polygon(poly,Color("202b35"))
	var inner:=PackedVector2Array()
	for i:int in 80:inner.append(center+(poly[i]-center)*.9)
	canvas.draw_colored_polygon(inner,color)
	canvas.draw_line(center,center+Vector2(cos(phase)*radius*.65,sin(phase)*radius*.38),Color("e8e0c8"),3)
	canvas.draw_circle(center,5,Color("202b35"));canvas.draw_circle(center,2,Color("c5c1a9"))
static func mini(canvas:CanvasItem,at:Vector2,scale_value:float,model_state:RefCounted)->void:
	canvas.draw_set_transform(at,0,Vector2.ONE*scale_value)
	canvas.draw_colored_polygon(PackedVector2Array([Vector2(6,0),Vector2(204,0),Vector2(210,44),Vector2(0,44)]),Color("344452"))
	gear_at(canvas,Vector2(32,22),22,model_state.motor_phase,Color("c79b62"))
	if model_state.gear>=0:gear_at(canvas,Vector2(76,22),Model.RADII[model_state.gear]*.5,model_state.gear_phase,Color("83a7b6"))
	else:canvas.draw_circle(Vector2(76,22),4,Color("e8e0c8"))
	if model_state.belt>0:
		canvas.draw_line(Vector2(76,13),Vector2(171,31 if model_state.belt==2 else 13),Color("c5c1a9"),3)
		canvas.draw_line(Vector2(76,31),Vector2(171,13 if model_state.belt==2 else 31),Color("c5c1a9"),3)
	gear_at(canvas,Vector2(171,22),22,model_state.output_phase,Color("7993a1"))
	canvas.draw_set_transform(Vector2.ZERO)
func _draw()->void:
	if font==null:return
	draw_rect(Rect2(0,0,960,540),Color("18242d"))
	draw_rect(Rect2(0,0,960,78),Color("202b35"))
	text_at("机电实验区 / 传动装配台",Vector2(24,31),21)
	text_at("让试件沿箭头向右移动，送到白色刻线。",Vector2(24,62),17,Color("b7c8cc"))
	draw_style_box(_box(Color("344452")),Rect2(818,8,132,36));text_at("返回实验区 Esc",Vector2(830,32),14)
	draw_texture_rect_region(bench,Rect2(42,116,876,876*crop.size.y/crop.size.x),crop)
	# Separate machinery lives on the generated empty table surface.
	draw_rect(Rect2(202,174,54,57),Color("344452"));text_at("电机",Vector2(208,163),14)
	gear_at(self,MOTOR,44,model.motor_phase,Color("c79b62"))
	if model.gear>=0:gear_at(self,AXLE,Model.RADII[model.gear],model.gear_phase,Color("83a7b6"))
	else:
		draw_arc(AXLE,24,0,TAU,32,Color("e8e0c8"),2);draw_line(AXLE-Vector2(0,12),AXLE+Vector2(0,12),Color("e8e0c8"),2)
	text_at("装配轴",Vector2(328,153),14)
	if model.belt>0:
		var left:=AXLE+Vector2(8,0);var right:=OUTPUT
		var sag:=12.0 if model.tension==0 else 0.0
		var line_a:=PackedVector2Array([left+Vector2(0,-15),Vector2(505,190+sag),right+Vector2(0,15 if model.belt==2 else -15)])
		var line_b:=PackedVector2Array([left+Vector2(0,15),Vector2(505,220+sag),right+Vector2(0,-15 if model.belt==2 else 15)])
		if model.belt==2:
			line_a[1]=Vector2(505,205+sag);line_b[1]=Vector2(505,205+sag)
		draw_polyline(line_a,Color("202b35"),7);draw_polyline(line_b,Color("202b35"),7)
		draw_polyline(line_a,Color("a39b87"),2);draw_polyline(line_b,Color("a39b87"),2)
	gear_at(self,OUTPUT,36,model.output_phase,Color("7993a1"));text_at("送料轴",Vector2(625,153),14)
	draw_line(OUTPUT+Vector2(0,24),Vector2(650,263),Color("202b35"),8)
	draw_rect(Rect2(606,253,216,30),Color("344452"));draw_line(Vector2(612,268),Vector2(816,268),Color("7993a1"),3)
	draw_line(Vector2(796,248),Vector2(796,289),Color("e8e0c8"),3)
	var block:=Vector2(614+model.travel*190,254)
	draw_rect(Rect2(block,Vector2(20,24)),Color("c79b62"));draw_rect(Rect2(block+Vector2(3,3),Vector2(14,5)),Color("e8e0c8"))
	draw_line(Vector2(710,240),Vector2(777,240),Color("e8e0c8"),2);draw_line(Vector2(777,240),Vector2(769,235),Color("e8e0c8"),2)
	draw_style_box(_box(Color("263742")),Rect2(90,330,314,112));text_at("零件盘 · 点按或拖到轴位",Vector2(102,350),14)
	for i:int in 3:
		var center:=Vector2(142+i*96,387)
		if model.gear==i:draw_rect(Rect2(center-Vector2(38,27),Vector2(76,65)),Color("42616c"))
		gear_at(self,center,Model.RADII[i]*.6,0,Color("83a7b6"))
		text_at(["小轮 1","中轮 2","大轮 3"][i],center+Vector2(-24,40),14)
	draw_circle(POWER,29,Color("202b35"));draw_circle(POWER,23,Color("c79b62") if model.running else Color("83a7b6"));text_at("试转",POWER+Vector2(-17,6),16,Color("202b35"));text_at("开关 Space",POWER+Vector2(-39,49),14)
	draw_circle(TENSION,29,Color("202b35"));draw_circle(TENSION,22,Color("7993a1"));var angle:float=[-2.4,-1.57,-.7][model.tension]
	draw_line(TENSION,TENSION+Vector2(cos(angle),sin(angle))*21,Color("e8e0c8"),4);text_at(["松","适中","紧"][model.tension],TENSION+Vector2(-9,5),14);text_at("皮带松紧 T",TENSION+Vector2(-40,49),14)
	draw_style_box(_box(Color("344452")),BELT);text_at("皮带 · 点按翻带 B",BELT.position+Vector2(10,22),14);text_at(["从工具盘装入","平行绕带","交叉绕带"][model.belt],BELT.position+Vector2(29,61),16)
	text_at("重新装配 R",Vector2(833,488),14)
	draw_rect(Rect2(0,500,960,40),Color("202b35"));text_at(model.message() if feedback.is_empty() else feedback,Vector2(24,526),16)
	if model.outcome=="passed":text_at("送料完成",Vector2(711,316),17,Color("bfd0b7"))
	if drag>=0:gear_at(self,pointer,Model.RADII[drag],0,Color("c5c1a9"))
func _box(color:Color)->StyleBoxFlat:
	var result:=StyleBoxFlat.new();result.bg_color=color;result.border_color=Color("526b7a");result.set_border_width_all(1);return result
