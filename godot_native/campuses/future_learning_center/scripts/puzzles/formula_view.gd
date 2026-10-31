extends Control
signal closed
const Model=preload("res://campuses/future_learning_center/scripts/puzzles/formula_model.gd")
const ApparatusStyle=preload("res://campuses/future_learning_center/scripts/apparatus_style.gd")
const Miniature=preload("res://campuses/future_learning_center/scripts/formula_miniature.gd")
const INK:=ApparatusStyle.INK
const PAPER:=ApparatusStyle.PAPER
const BENCH_CAR:=Vector2(480,365)
const TILT_KNOB:=Vector2(593,386)
const GATE:=Vector2(595,273)
const LAMP:=Vector2(835,93)
const PANEL_TRAYS:=[Vector2(112,382),Vector2(245,382)]
const GEAR_TRAYS:=[Vector2(390,460),Vector2(462,460),Vector2(534,460)]
const HINTS:=["在哪段光照里，两辆车开始拉开距离？","固定板和传动，先只改变板的朝向。","把本场与上次轨迹叠看，找出变暗前后距离的变化。"]
var model=Model.new()
var font:Font
var miniature:Node
var exit_navigation:Button
var touch_id:=-1
var action:=""
var part:=-1
var pointer:=Vector2.ZERO
var origin:=Vector2.ZERO
var grip_offset:=Vector2.ZERO
var original_tilt:=0
var preview_tilt:=0.0
var notebook:=false
var hint_level:=0
func _ready()->void:
	font=ApparatusStyle.font();size=Vector2(960,540);mouse_filter=Control.MOUSE_FILTER_STOP
	texture_filter=CanvasItem.TEXTURE_FILTER_LINEAR
	miniature=Miniature.new();add_child(miniature)
	exit_navigation=ApparatusStyle.configure_exit(self,close)
	visibility_changed.connect(_sync_renderer_visibility)
	hide()
func _sync_renderer_visibility()->void:
	if is_instance_valid(miniature):miniature.set_active(is_visible_in_tree())
func open()->void:show();miniature.present(self);queue_redraw()
func close()->void:model.cancel();cancel_pointer();hide();closed.emit()
func cancel_pointer()->void:touch_id=-1;action="";part=-1;queue_redraw()
func held_position()->Vector2:return pointer-grip_offset
func panel_tilt()->float:return preview_tilt if action=="tilt" else Model.TILTS[model.tilt]
func _notification(what:int)->void:
	if what in [NOTIFICATION_APPLICATION_FOCUS_OUT,NOTIFICATION_APPLICATION_PAUSED]:model.cancel();cancel_pointer()
func _process(dt:float)->void:
	if is_visible_in_tree():model.step(minf(dt,.1));miniature.present(self);queue_redraw()
func _local(at:Vector2)->Vector2:return get_global_transform_with_canvas().affine_inverse()*at
func _input(event:InputEvent)->void:
	if not visible:return
	if ApparatusStyle.navigation_event(self,event):return
	if event is InputEventScreenTouch:
		if event.canceled and event.index==touch_id:cancel_pointer()
		elif event.pressed and not event.canceled and touch_id<0:touch_id=event.index;press(_local(event.position))
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
	var a:=distance/20*TAU+PI/2
	return Vector2(480,184)+Vector2(cos(a)*(345-lane*22),sin(a)*(65-lane*18))
func press(at:Vector2)->void:
	pointer=at;origin=at;action="";grip_offset=Vector2.ZERO
	if notebook:action="page" if Rect2(640,416,220,40).has_point(at) else "paper";return
	if Rect2(45,446,145,64).has_point(at):action="paper";return
	if at.distance_to(LAMP)<31:action="lamp";return
	if at.distance_to(GATE)<36:action="gate";return
	var car:Vector2=race_point(model.cars[0].distance,0) if model.on_track else BENCH_CAR
	if at.distance_to(car)<45:action="car";grip_offset=at-car;model.cancel();return
	if model.running or model.on_track:return
	if at.distance_to(TILT_KNOB)<30:action="tilt";original_tilt=model.tilt;preview_tilt=Model.TILTS[original_tilt];return
	for i:int in 2:
		if at.distance_to(PANEL_TRAYS[i])<50 and i!=model.panel:action="panel";part=i;grip_offset=at-PANEL_TRAYS[i];return
	for i:int in 3:
		if at.distance_to(GEAR_TRAYS[i])<29 and i!=model.gear:action="gear";part=i;grip_offset=at-GEAR_TRAYS[i];return
func motion(at:Vector2)->void:
	pointer=at
	if action=="tilt":preview_tilt=clampf(Model.TILTS[original_tilt]+(origin.y-at.y)*30.0/24.0,0,60)
	queue_redraw()
func release(at:Vector2)->void:
	if action in ["panel","gear","car"] and at.distance_to(pointer)>12:
		cancel_pointer();return
	if action=="tilt":
		var detent:=clampi(roundi(preview_tilt/30),0,2)
		if at.distance_to(pointer)<=12 and absf(preview_tilt-Model.TILTS[detent])<=8:model.edit("tilt",detent)
	elif action in ["panel","gear"] and Rect2(410,308,145,105).has_point(held_position()):model.edit(action,part)
	elif action=="car":
		if held_position().distance_to(race_point(0,0))<=32:model.place_on_track(true)
		elif held_position().distance_to(BENCH_CAR)<=45:model.place_on_track(false)
	elif action=="lamp" and origin.distance_to(at)<18:model.set_scenario(1-model.scenario)
	elif action=="gate" and origin.distance_to(at)<18:
		if model.running:model.cancel()
		else:model.start()
	elif origin.distance_to(at)<18:
		match action:
			"paper":notebook=not notebook
			"page":hint_level=mini(3,hint_level+1)
	action="";part=-1;queue_redraw()
func text(value:String,at:Vector2,sz:=17,color:=INK)->void:draw_string(font,at,value,HORIZONTAL_ALIGNMENT_LEFT,-1,sz,color)
func slab(rect:Rect2,color:Color,depth:=7.0)->void:
	draw_rect(Rect2(rect.position+Vector2(0,depth),rect.size),color.darkened(.3));draw_rect(rect,color);draw_rect(rect,INK,false,1.5)
	draw_line(rect.position+Vector2(2,2),Vector2(rect.end.x-2,rect.position.y+2),color.lightened(.2),2)
func identity_mark(at:Vector2,id:int,scale_value:=1.0)->void:
	if id==0:draw_circle(at,12*scale_value,INK)
	else:draw_rect(Rect2(at-Vector2(12,12)*scale_value,Vector2(24,24)*scale_value),INK)
	text("1" if id==0 else "2",at+Vector2(-4,5)*scale_value,maxi(12,roundi(14*scale_value)),PAPER)
func config_caption(config:Array)->String:
	return "%s · %d° · %s"%["未装板" if config[0]<0 else ("小板" if config[0]==0 else "大板"),Model.TILTS[config[1]],"未装齿" if config[2]<0 else "%.1f"%Model.RATIOS[config[2]]]
func comparison_distance(id:int)->float:return model.cars[id].distance
func current_outcome()->String:return model.outcome if model.time()>=30 else ""
func history_caption()->String:
	if model.records.is_empty():return "还没有完成的试跑。"
	var record:Dictionary=model.records[-1]
	return "上次来光 %d° · 阴影 10–%d 秒"%[30 if record.scenario==0 else 60,16 if record.scenario==0 else 18]
func _draw()->void:
	if font==null or not is_instance_valid(miniature):return
	draw_texture_rect(miniature.texture(),Rect2(0,0,960,540),false)
	text("太阳能试车台",Vector2(32,36),23)
	for id:int in 2:
		var y:=163+id*34
		identity_mark(Vector2(335,y-5),id,.8)
		text("你的车 · 外道" if id==0 else "基准车 · 内道",Vector2(355,y),16)
		text("%.2f"%comparison_distance(id),Vector2(514,y),20)
		draw_line(Vector2(590,y-5),Vector2(710,y-5),Color("a4af9e"),5)
		draw_line(Vector2(590,y-5),Vector2(590+minf(comparison_distance(id)/80,1)*120,y-5),INK,5)
		if id==1 or model.on_track:
			var at:Vector2=held_position() if id==0 and action=="car" else race_point(model.cars[id].distance,id)
			identity_mark(at+Vector2(-25,-3),id,.65)
	text("%.1f / 30 秒 · 累计距离"%model.time(),Vector2(365,86),16)
	if action=="car":
		ApparatusStyle.target(self,Rect2(race_point(0,0)-Vector2(32,23),Vector2(64,46)),held_position().distance_to(race_point(0,0))<=32)
		ApparatusStyle.target(self,Rect2(BENCH_CAR-Vector2(45,30),Vector2(90,60)),held_position().distance_to(BENCH_CAR)<=45)
	text("来光 %s"%("30°" if model.scenario==0 else "60°"),LAMP+Vector2(-27,-28),16)
	for i:int in 2:
		text("小板 · 0.4" if i==0 else "大板 · 1.1",PANEL_TRAYS[i]+Vector2(-40,49),16)
		if not model.on_track and i!=model.panel:ApparatusStyle.grip(self,held_position() if action=="panel" and part==i else PANEL_TRAYS[i],"drag",action=="panel" and part==i)
	var at:Vector2=held_position() if action=="car" and not model.on_track else BENCH_CAR
	identity_mark(at+Vector2(-48,-3),0,.8)
	identity_mark(Vector2(700,367),1,.7)
	if not model.on_track:
		ApparatusStyle.grip(self,at,"drag",action=="car")
		ApparatusStyle.grip(self,TILT_KNOB,"rotate",action=="tilt")
		if action in ["panel","gear"]:ApparatusStyle.target(self,Rect2(410,308,145,105),Rect2(410,308,145,105).has_point(held_position()))
	else:ApparatusStyle.grip(self,held_position() if action=="car" else race_point(model.cars[0].distance,0),"drag",action=="car")
	for i:int in 3:
		text(str(Model.RATIOS[i]),GEAR_TRAYS[i]+Vector2(-10,39),16)
		if not model.on_track and i!=model.gear:ApparatusStyle.grip(self,held_position() if action=="gear" and part==i else GEAR_TRAYS[i],"drag",action=="gear" and part==i)
	text("板倾角 %.0f°"%panel_tilt(),TILT_KNOB+Vector2(-36,41),16)
	ApparatusStyle.grip(self,GATE,"press",action=="gate")
	text("试车记录",Vector2(77,477),18)
	if not current_outcome().is_empty():text(current_outcome(),Vector2(635,477),20)
	if notebook:
		slab(Rect2(105,95,750,361),PAPER,8)
		text("同一段阳光下，让 1 号车比 2 号车跑得远",Vector2(132,134),21)
		text("将车拖到起跑线，拨发车闸；取回实车后再调整。",Vector2(132,160),16)
		text("1 号 "+config_caption(model.configuration())+"    2 号 "+config_caption(model.baseline()),Vector2(132,188),16)
		text(history_caption(),Vector2(132,216),16)
		if not model.records.is_empty():
			var record:Dictionary=model.records[-1]
			text("上次 1 号："+config_caption(record.configuration),Vector2(132,242),16)
			for i:int in record.segments.size():
				var row:Dictionary=record.segments[i]
				text("%.0fs  %.1f / %.1f"%[row.time,row.player,row.baseline],Vector2(132+i*165,270),15)
		text("个人纪录 %.2f · %.2f（模型单位）"%[model.personal_best[0],model.personal_best[1]],Vector2(132,298),16)
		for i:int in hint_level:text(HINTS[i],Vector2(132,324+i*27),17)
		text("翻下一页提示",Vector2(670,443),17)
