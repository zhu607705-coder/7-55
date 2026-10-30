extends Control
signal closed
const Model=preload("res://campuses/future_learning_center/scripts/puzzles/formula_model.gd")
const INK:=Color("283c43")
const PAPER:=Color("e8e1cf")
const BENCH_CAR:=Vector2(480,365)
const TILT_KNOB:=Vector2(593,386)
const GATE:=Vector2(850,342)
const LAMP:=Vector2(835,93)
const PANEL_TRAYS:=[Vector2(112,382),Vector2(245,382)]
const GEAR_TRAYS:=[Vector2(390,460),Vector2(462,460),Vector2(534,460)]
const HINTS:=["在哪段光照里，两辆车开始拉开距离？","固定板和传动，先只改变板的朝向。","把本场与上次轨迹叠看，找出变暗前后距离的变化。"]
var model=Model.new()
var font:Font
var touch_id:=-1
var action:=""
var part:=-1
var pointer:=Vector2.ZERO
var origin:=Vector2.ZERO
var notebook:=false
var hint_level:=0
func _ready()->void:
	font=load("res://scripts/ui/native_typography.gd").body_font();size=Vector2(960,540);mouse_filter=Control.MOUSE_FILTER_STOP;hide()
func open()->void:show();queue_redraw()
func close()->void:model.cancel();cancel_pointer();hide();closed.emit()
func cancel_pointer()->void:touch_id=-1;action="";part=-1;queue_redraw()
func _notification(what:int)->void:
	if what in [NOTIFICATION_APPLICATION_FOCUS_OUT,NOTIFICATION_APPLICATION_PAUSED]:model.cancel();cancel_pointer()
func _process(dt:float)->void:
	if visible:model.step(minf(dt,.1));queue_redraw()
func _local(at:Vector2)->Vector2:return get_global_transform_with_canvas().affine_inverse()*at
func _input(event:InputEvent)->void:
	if not visible:return
	if event is InputEventScreenTouch:
		if event.canceled and event.index==touch_id:cancel_pointer()
		elif event.pressed and touch_id<0:touch_id=event.index;press(_local(event.position))
		elif not event.pressed and event.index==touch_id:release(_local(event.position));touch_id=-1
	elif event is InputEventScreenDrag:
		if event.index==touch_id:motion(_local(event.position))
	elif event is InputEventMouseButton and event.button_index==MOUSE_BUTTON_LEFT:
		if touch_id>=0 or event.device==InputEvent.DEVICE_ID_EMULATION:return
		if event.pressed:press(_local(event.position))
		else:release(_local(event.position))
	elif event is InputEventMouseMotion:
		if touch_id>=0 or event.device==InputEvent.DEVICE_ID_EMULATION:return
		motion(_local(event.position))
	elif event is InputEventKey and event.pressed and not event.echo and event.keycode==KEY_ESCAPE:close()
	else:return
	get_viewport().set_input_as_handled();queue_redraw()
func race_point(distance:float,lane:int)->Vector2:
	var a:=distance/20*TAU-PI/2
	return Vector2(480,184)+Vector2(cos(a)*(345-lane*22),sin(a)*(65-lane*18))
func press(at:Vector2)->void:
	pointer=at;origin=at;action=""
	if Rect2(865,9,80,48).has_point(at):action="close";return
	if notebook:action="page" if Rect2(640,416,220,40).has_point(at) else "paper";return
	if Rect2(45,446,145,64).has_point(at):action="paper";return
	if at.distance_to(LAMP)<31:action="lamp";return
	if at.distance_to(GATE)<36:action="gate";return
	var car:Vector2=race_point(model.cars[0].distance,0) if model.on_track else BENCH_CAR
	if at.distance_to(car)<45:action="car";model.cancel();return
	if model.running:return
	if at.distance_to(TILT_KNOB)<30:action="tilt";return
	for i:int in 2:
		if at.distance_to(PANEL_TRAYS[i])<50 and i!=model.panel:action="panel";part=i;return
	for i:int in 3:
		if at.distance_to(GEAR_TRAYS[i])<29 and i!=model.gear:action="gear";part=i;return
func motion(at:Vector2)->void:
	pointer=at
	if action=="tilt":model.edit("tilt",clampi(roundi((TILT_KNOB.y-at.y)/24)+1,0,2))
	queue_redraw()
func release(at:Vector2)->void:
	if action in ["panel","gear"] and Rect2(410,308,145,105).has_point(at):model.edit(action,part)
	elif action=="car":
		if Rect2(108,103,737,165).has_point(at):model.place_on_track(true)
		elif Rect2(390,300,240,123).has_point(at):model.place_on_track(false)
	elif action=="lamp":model.set_scenario(1-model.scenario)
	elif action=="gate":
		if model.running:model.cancel()
		else:model.start()
	elif origin.distance_to(at)<18:
		match action:
			"close":close()
			"paper":notebook=not notebook
			"page":hint_level=mini(3,hint_level+1)
	action="";part=-1;queue_redraw()
func text(value:String,at:Vector2,sz:=17,color:=INK)->void:draw_string(font,at,value,HORIZONTAL_ALIGNMENT_LEFT,-1,sz,color)
func slab(rect:Rect2,color:Color,depth:=7.0)->void:
	draw_rect(Rect2(rect.position+Vector2(0,depth),rect.size),color.darkened(.3));draw_rect(rect,color);draw_rect(rect,INK,false,1.5)
	draw_line(rect.position+Vector2(2,2),Vector2(rect.end.x-2,rect.position.y+2),color.lightened(.2),2)
func panel_at(at:Vector2,id:int,angle:float,scale_value:=1.0)->void:
	if id<0:return
	var width:float=(62 if id==0 else 94)*scale_value
	var height:=maxf(9,32*cos(deg_to_rad(angle)))*scale_value
	slab(Rect2(at-Vector2(width/2,height/2),Vector2(width,height)),Color("547d84"),4*scale_value)
	for i:int in 4:draw_line(at+Vector2(-width/2+width*(i+1)/5,-height/2+2),at+Vector2(-width/2+width*(i+1)/5,height/2-2),Color("a5bcb3"),scale_value)
func car_at(at:Vector2,config:Array,scale_value:=1.0,distance:=0.0)->void:
	for x:float in [-32,32]:
		for y:float in [-15,15]:
			var hub:=at+Vector2(x,y)*scale_value
			draw_circle(hub,9*scale_value,INK);draw_line(hub,hub+Vector2(cos(distance*10),sin(distance*10))*6*scale_value,PAPER,2*scale_value)
	slab(Rect2(at-Vector2(36,20)*scale_value,Vector2(72,40)*scale_value),Color("bba276"),5*scale_value)
	panel_at(at-Vector2(0,7)*scale_value,config[0],Model.TILTS[config[1]],scale_value)
	if config[2]>=0:
		var gear_at:=at+Vector2(31,9)*scale_value
		draw_circle(gear_at,(8+config[2]*2)*scale_value,INK)
		draw_circle(gear_at,(5+config[2]*2)*scale_value,Color("b8ba9d"))
		draw_line(gear_at,gear_at+Vector2(cos(distance*12),sin(distance*12))*6*scale_value,INK,2*scale_value)
func _draw()->void:
	if font==null:return
	draw_rect(Rect2(0,0,960,540),Color("c3c9bc"))
	for y:int in range(80,540,34):draw_line(Vector2(0,y),Vector2(960,y+8),Color("b4bdad"),1)
	text("方程式车队 · 同一束阳光",Vector2(32,36),23);text("装好小车，放上跑道，与基准车跑同一个光照片段。",Vector2(33,65),16);text("返回",Vector2(878,40),17)
	for lane:int in 2:
		var loop:=PackedVector2Array()
		for n:int in 97:loop.append(race_point(float(n)/96*20,lane))
		draw_polyline(loop,Color("536760"),17);draw_polyline(loop,Color("b8c3ad"),2)
		for n:int in 20:
			var at:=race_point(n,lane);draw_line(at-Vector2(0,4),at+Vector2(0,4),PAPER,1)
	if model.on_track:car_at(pointer if action=="car" else race_point(model.cars[0].distance,0),model.configuration(),.4,model.cars[0].distance)
	car_at(race_point(model.cars[1].distance,1),model.baseline(),.35,model.cars[1].distance)
	# Faint marks are measured positions from the previous completed run, never a canned opponent path.
	for previous:Dictionary in model.records.slice(maxi(0,model.records.size()-1)):
		if previous.scenario==model.scenario:
			for row:Dictionary in previous.segments:
				var mark:=race_point(row.player,0)
				draw_arc(mark,8,0,TAU,16,Color(.77,.63,.37,.65),2)
			text("上次分段刻痕",Vector2(655,282),13)
	text("你的车  %.2f"%model.cars[0].distance,Vector2(392,165),18)
	text("基准车  %.2f"%model.cars[1].distance,Vector2(392,193),18)
	text("%.1f / 30 模拟秒"%model.time(),Vector2(402,220),14)
	var light:float=model.irradiance(model.time())
	draw_line(LAMP+Vector2(0,18),Vector2(480,110),Color(.94,.87,.59,light*.5),8)
	draw_line(LAMP, LAMP+Vector2(-25 if model.scenario==0 else -44,25),INK,8)
	slab(Rect2(LAMP-Vector2(22,15),Vector2(44,30)),Color("b8a784"),5)
	if light<.3:
		draw_rect(Rect2(103,104,748,167),Color(.22,.29,.27,.16))
		slab(Rect2(LAMP+Vector2(-40,20),Vector2(55,16)),Color("727a70"),3)
	text("30°" if model.scenario==0 else "60°",LAMP+Vector2(26,7),14)
	slab(Rect2(55,316,760,111),Color("937e5e"),15)
	for i:int in 2:
		draw_rect(Rect2(PANEL_TRAYS[i]-Vector2(53,28),Vector2(106,56)),Color("c1b99f"),false,2)
		if model.panel!=i:panel_at(pointer if action=="panel" and part==i else PANEL_TRAYS[i],i,0)
		text("小板 · 0.4" if i==0 else "大板 · 1.1",PANEL_TRAYS[i]+Vector2(-40,49),14)
	if not model.on_track:car_at(pointer if action=="car" else BENCH_CAR,model.configuration())
	else:draw_rect(Rect2(BENCH_CAR-Vector2(42,28),Vector2(84,56)),Color("c6baa0"),false,2)
	for i:int in 3:
		var at:Vector2=pointer if action=="gear" and part==i else GEAR_TRAYS[i]
		draw_arc(GEAR_TRAYS[i],25,0,TAU,20,Color("818a78"),1)
		if model.gear!=i:
			draw_circle(at,15+i*4,INK);draw_circle(at,11+i*4,Color("aaa98c"));draw_circle(at,4,INK)
		text(str(Model.RATIOS[i]),GEAR_TRAYS[i]+Vector2(-10,39),14)
	draw_circle(TILT_KNOB,22,INK);draw_circle(TILT_KNOB,17,Color("b5b593"));draw_line(TILT_KNOB,TILT_KNOB+Vector2(0,-15).rotated(deg_to_rad(Model.TILTS[model.tilt]-30)),PAPER,3)
	text("%d°"%Model.TILTS[model.tilt],TILT_KNOB+Vector2(-12,41),15)
	draw_circle(GATE+Vector2(0,13),24,INK);draw_line(GATE+Vector2(0,13),GATE+Vector2(0,-22 if model.running else -7),Color("d2c4a6"),8);draw_circle(GATE+Vector2(0,-22 if model.running else -7),11,Color("9c7850"))
	text("发车闸",GATE+Vector2(-24,53),15)
	slab(Rect2(45,450,145,60),PAPER,5);text("试车记录",Vector2(77,477),18);text("按需翻阅",Vector2(78,500),14)
	text("教学模型 · 距离为模型单位",Vector2(655,522),13)
	if not model.outcome.is_empty():text(model.outcome,Vector2(635,477),18)
	if notebook:
		slab(Rect2(105,95,750,361),PAPER,8)
		text("本场与历史轨迹",Vector2(132,134),23)
		text("阴影区间：10–%d 秒；两车共用同一灯光。"%int(model.shadow_end()),Vector2(132,172),17)
		if not model.records.is_empty():
			var record:Dictionary=model.records[-1]
			for i:int in record.segments.size():
				var row:Dictionary=record.segments[i]
				text("%.0fs  %.1f / %.1f"%[row.time,row.player,row.baseline],Vector2(132+i*165,213),15)
		text("个人纪录 %.2f · %.2f"%[model.personal_best[0],model.personal_best[1]],Vector2(132,246),16)
		for i:int in hint_level:text(HINTS[i],Vector2(132,291+i*36),17)
		text("翻下一页提示",Vector2(670,443),17)
