extends Control
const ApparatusStyle=preload("res://campuses/future_learning_center/scripts/apparatus_style.gd")
## Direct manipulation of a physical apparatus; all acceptance lives in Model.
signal closed
const Model=preload("res://campuses/future_learning_center/scripts/puzzles/collab_model.gd")
const OpticalArt=preload("res://campuses/future_learning_center/scripts/puzzles/optical_scene_art.gd")
const OpticalVisuals=preload("res://campuses/future_learning_center/scripts/puzzles/optical_scene_visuals.gd")
var visuals:Node2D
var snap_visuals:=true
var reduced_motion:=false
const CENTER:=Vector2(480,282)
const TRAY:=[Vector2(235,454),Vector2(365,454)]
const HINTS:=["每次改摆法后，哪些记录还对应现在这套装配？","保持装配不动，比较两侧来光与送料结果。","对照交接卡、试拍和装置开口，查看失败记录的具体路径。"]
var model=Model.new()
var hints:Array=HINTS.duplicate()
var apparatus_title:="两侧来光"
var apparatus_goal:="保持同一套装配，核对两侧试拍与送料。"
var font:Font
var drag:=-1
var selected:=-1
var pointer:=Vector2.ZERO
var pressed_at:=Vector2.ZERO
var touch_id:=-1
var mouse_owned:=false
var grab_offset:=Vector2.ZERO
var hint_level:=-1
var show_records:=false
var action:=""
var feedback:=""
var pulse:=0.0
func _ready()->void:
	ApparatusStyle.configure_exit(self,close)
	mouse_filter=Control.MOUSE_FILTER_STOP
	font=ApparatusStyle.font()
	if model is Model and OpticalArt.complete():
		visuals=OpticalVisuals.new();visuals.art=OpticalArt.parts();visuals.z_index=-1;add_child(visuals)
		var backdrop:=ColorRect.new();backdrop.color=Color("c7ccc8");backdrop.size=Vector2(960,540);backdrop.z_index=-2;backdrop.mouse_filter=Control.MOUSE_FILTER_IGNORE;add_child(backdrop)
	var state=get_node_or_null("/root/State")
	if state!=null:reduced_motion=bool(state.d.get("native",{}).get("settings",{}).get("reduced_motion",false))
	hide()
func open()->void:show();snap_visuals=true;_sync_visuals(0);queue_redraw()
func close()->void:
	model.cancel();_cancel_pointer();hide();closed.emit()
func _cancel_pointer()->void:
	drag=-1;selected=-1;touch_id=-1;action="";mouse_owned=false;grab_offset=Vector2.ZERO;snap_visuals=true;_sync_visuals(0);queue_redraw()
func _notification(what:int)->void:
	if what in [NOTIFICATION_APPLICATION_FOCUS_OUT,NOTIFICATION_APPLICATION_PAUSED]:model.pause();_cancel_pointer();queue_redraw()
func _process(dt:float)->void:
	if not visible:return
	model.step(dt);pulse+=minf(dt,.1);_sync_visuals(dt);queue_redraw()
func _sync_visuals(dt:float)->void:
	if visuals==null:return
	visuals.reduced_motion=reduced_motion;visuals.sync(self,dt,snap_visuals);snap_visuals=false
func projected(local:Vector2)->Vector2:return CENTER+Vector2(local.x,local.y*.66)
func position_of(i:int)->Vector2:
	return visuals.object_at("Baffle%d"%i,logical_position_of(i)) if visuals!=null else logical_position_of(i)
func logical_position_of(i:int)->Vector2:
	return TRAY[i] if model.slots[i]<0 else projected(Model.SLOT_POINTS[model.slots[i]])
func object_hit(id:String,at:Vector2,anchor:Vector2,radius:float)->bool:
	return at.distance_to(anchor)<radius or (visuals!=null and visuals.hit(id,at))
func lamp_at(side:int)->Vector2:return projected(model.rotate_point(Vector2(-210 if side==0 else 210,0)))
func camera_at()->Vector2:return projected(model.rotate_point(Vector2(0,-210)))
func lever_at()->Vector2:return Vector2(715,422)
func _input(event:InputEvent)->void:
	if ApparatusStyle.navigation_event(self,event):return
	if not is_visible_in_tree():return
	if event is InputEventKey and event.pressed and not event.echo and event.keycode==KEY_ESCAPE:close();get_viewport().set_input_as_handled()
	elif event is InputEventMouseButton and event.button_index==MOUSE_BUTTON_LEFT:
		if touch_id>=0 or event.device==InputEvent.DEVICE_ID_EMULATION:return
		if event.pressed and not mouse_owned:
			mouse_owned=true;_press(get_global_transform_with_canvas().affine_inverse()*event.position)
		elif not event.pressed and mouse_owned:
			mouse_owned=false;_release(get_global_transform_with_canvas().affine_inverse()*event.position)
		get_viewport().set_input_as_handled()
	elif event is InputEventMouseMotion and touch_id<0 and event.device!=InputEvent.DEVICE_ID_EMULATION:pointer=get_global_transform_with_canvas().affine_inverse()*event.position;_sync_visuals(0);queue_redraw()
	elif event is InputEventScreenTouch:
		if event.index==touch_id and event.canceled:_cancel_pointer()
		elif event.pressed and not event.canceled and touch_id<0 and not mouse_owned:touch_id=event.index;_press(get_global_transform_with_canvas().affine_inverse()*event.position)
		elif not event.pressed and event.index==touch_id:
			if event.canceled:_cancel_pointer()
			else:_release(get_global_transform_with_canvas().affine_inverse()*event.position);touch_id=-1
		get_viewport().set_input_as_handled()
	elif event is InputEventScreenDrag and event.index==touch_id:pointer=get_global_transform_with_canvas().affine_inverse()*event.position;_sync_visuals(0);queue_redraw();get_viewport().set_input_as_handled()
func physical_pick(at:Vector2)->String:
	# Visible pixels win over neighbouring controls' expanded touch targets.
	if visuals==null:return ""
	for i:int in 2:
		if visuals.hit("Baffle%d"%i,at):return "baffle_%d"%i
	for side:int in 2:
		if visuals.hit("Lamp%d"%side,at):return "lamp_%d"%side
	if visuals.hit("Camera",at):return "camera"
	if visuals.hit("FeedCap",at) or visuals.hit("FeedBase",at):return "feed"
	if visuals.hit("QuarterControl",at):return "rotate"
	return ""
func begin_baffle_drag(i:int,at:Vector2)->void:
	drag=i;selected=i;grab_offset=position_of(i)-at
func _press(at:Vector2)->void:
	pressed_at=at;pointer=at;action=""
	if Rect2(38,407,142,88).has_point(at):action="hint";return
	if (Rect2(774,110,182,270) if visuals!=null else Rect2(792,110,145,270)).has_point(at):action="records";return
	if model.paused:action="resume";return
	if model.running:return
	var exact:=physical_pick(at)
	if not exact.is_empty():
		if exact.begins_with("baffle_"):begin_baffle_drag(int(exact.right(1)),at)
		else:action=exact
		return
	for i:int in 2:
		if object_hit("Baffle%d"%i,at,position_of(i),42):
			begin_baffle_drag(i,at);return
	for side:int in 2:
		if at.distance_to(lamp_at(side))<36:action="lamp_%d"%side;return
	if at.distance_to(camera_at())<36:action="camera";return
	if at.distance_to(lever_at())<40:action="feed";return
	if object_hit("QuarterControl",at,Vector2(650,452),34):action="rotate";return
	if selected>=0:
		for slot:int in 4:
			if at.distance_to(projected(Model.SLOT_POINTS[slot]))<40:action="slot_%d"%slot;return
func _release(at:Vector2)->void:
	pointer=at;_sync_visuals(0)
	if drag>=0:
		var part:=drag;drag=-1
		var drop_at:=at+grab_offset;grab_offset=Vector2.ZERO
		if at.distance_to(pressed_at)<8:
			_sync_visuals(0);return # Selected part can next be placed by tapping a slot.
		var placed:=false
		for slot:int in 4:
			if drop_at.distance_to(projected(Model.SLOT_POINTS[slot]))<42:placed=model.place(part,slot);break
		if not placed and Rect2(170,410,260,95).has_point(drop_at):placed=model.place(part,-1)
		feedback="" if placed else "挡片回到原位；插槽被占用或未对齐。"
		selected=-1;_sync_visuals(0);queue_redraw();return
	if at.distance_to(pressed_at)>16:action="";return
	if action=="close":close()
	elif action=="hint":hint_level=(hint_level+1)%4;show_records=false;if_hint()
	elif action=="records":show_records=not show_records;hint_level=-1
	elif action=="resume":model.resume()
	elif action.begins_with("lamp_"):model.set_condition(int(action.right(1)))
	elif action=="camera":model.start("photo");feedback=""
	elif action=="feed":model.start("feed");feedback=""
	elif action=="rotate":model.rotate_fixture();feedback="夹具转过一格，旧记录保留。"
	elif action.begins_with("slot_") and selected>=0:
		model.place(selected,int(action.right(1)));selected=-1;feedback=""
	action="";_sync_visuals(0);queue_redraw()
func if_hint()->void:
	if hint_level==3:hint_level=-1
# Only the seven delivered raster workbenches opt into annotation-free play.
# Other prototype subclasses retain their authored presentation.
func annotations_visible()->bool:
	var scene:String=get_script().resource_path.get_file()
	if scene not in ["collab_view.gd","assembly_view.gd","recording_view.gd","sync_view.gd","signal_sync_view.gd"]:return true
	return hint_level>=0 or show_records
func text(value:String,at:Vector2,size_value:=16,color:=Color("ddd7c8"))->void:
	if not annotations_visible():return
	draw_string(font,at,value,HORIZONTAL_ALIGNMENT_LEFT,-1,size_value,color)
# Compatibility primitive for the existing non-optical subclasses. The two
# optical rooms never call it; their physical artwork is exclusively PNG sprites.
func box(rect:Rect2,color:Color,height:=8.0)->void:
	draw_rect(Rect2(rect.position+Vector2(0,height),rect.size),Color("252d32"))
	draw_rect(rect,color);draw_rect(rect,Color("21292d"),false,2)
	draw_line(rect.position+Vector2(2,2),rect.position+Vector2(rect.size.x-2,2),color.lightened(.12),2)
func _draw()->void:
	if font==null or visuals==null:return
	_draw_generated()
func _draw_generated()->void:
	# Only light paths, interaction feedback and text are drawn in code.
	# Every physical object is an independently generated raster sprite.
	var ink:=Color("253e46")
	text(apparatus_title,Vector2(32,42),24,ink)
	for side:int in 2:text("甲" if side==0 else "乙",lamp_at(side)+Vector2(-8,35),16,ink)
	text("试拍中" if model.running and model.trial=="photo" else "试拍",camera_at()+Vector2(-16,36),16,ink)
	text("送料中" if model.running and model.trial=="feed" else "送料",lever_at()+Vector2(-17,51),16,ink)
	text("转一格",Vector2(625,405),16,ink)
	text("交接卡",Vector2(70,461),16,ink)
	text("试拍记录",Vector2(812,153),17,ink)
	for row:int in 3:
		var key:String=["photo_a","photo_b","feed"][row]
		var record:Dictionary=model.receipts.get(key,{})
		text(["甲侧","乙侧","送料"][row],Vector2(815,214+row*48),16,ink)
		text("—" if record.is_empty() else ("成立" if record.passed else "未成"),Vector2(865,214+row*48),16,ink)
	if drag>=0 or selected>=0:
		for slot:int in 4:ApparatusStyle.target(self,Rect2(projected(Model.SLOT_POINTS[slot])-Vector2(24,24),Vector2(48,48)),true)
	if selected>=0:draw_arc(position_of(selected),43,0,TAU,32,Color("b97d35"),2)
	if hint_level>=0:
		text(apparatus_goal,Vector2(32,68),16,ink)
		text(hints[hint_level],Vector2(32,94),16,ink)
	if show_records:
		var last:Dictionary=model.history.back() if not model.history.is_empty() else {}
		text("没有历史试验" if last.is_empty() else "%s · 装配 %d / 夹具 %d · %s"%[last.kind,last.configuration_revision,last.fixture_revision,"成立" if last.passed else "未成立"],Vector2(482,113),16,ink)
		text("装配 %d · 夹具 %d · 旧记录 %d"%[model.configuration_revision,model.fixture_revision,model.history.size()],Vector2(482,153),14,ink)
	var status:String=feedback if not feedback.is_empty() else model.outcome
	if model.current_passed():status="同一装配下，两侧试拍与送料均成立。"
	if model.paused:status="试验暂停 · 轻触装置继续"
	if not status.is_empty():text(status,Vector2(32,524),16,ink)
	_draw_generated_extra()
func _draw_generated_extra()->void:pass
