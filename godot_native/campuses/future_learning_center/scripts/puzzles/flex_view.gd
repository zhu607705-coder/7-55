extends Control
const ApparatusStyle=preload("res://campuses/future_learning_center/scripts/apparatus_style.gd")
const CableArt=preload("res://campuses/future_learning_center/scripts/puzzles/cable_scene_art.gd")
const CableVisuals=preload("res://campuses/future_learning_center/scripts/puzzles/cable_scene_visuals.gd")
signal closed
const Model=preload("res://campuses/future_learning_center/scripts/puzzles/flex_model.gd")
const INK=ApparatusStyle.INK
const PAPER=ApparatusStyle.PAPER
const COPPER=Color("b88a58")
const PORT_Y=[232.0,302.0,372.0]
const ROLE_LABEL=["源","分","收"]
const HINTS=["底座换位后，哪些标记跟着它一起转了？","固定一个输入，在两个工位分别追踪它到达的端点。","对照功能草图和端点测试，检查端口角色与线长。"]
var model=Model.new()
var font:Font
var visuals:Node2D
var reduced_motion:=false
var pending_touch:=""
var pending_unplug:=-1
var pending_origin:=Vector2.ZERO
var route_drag:=-1
var route_origin:=Vector2.ZERO
var route_selected:=-1
var route_grab_offset:=Vector2.ZERO
var cable_grab_offset:=Vector2.ZERO
var dragging:=-1
var pointer:=Vector2.ZERO
var touch_id:=-1
var mouse_owned:=false
var held_board:=false
var board_grab_offset:=Vector2.ZERO
var board_display_offset:=Vector2.ZERO
var selected:=-1
var hint_level:=0
var notebook:=false
var feedback:=""
var fade:=0.0
var keyboard_active:=false
var keyboard_index:=0
var keyboard_destination:=0
func _ready()->void:
 ApparatusStyle.configure_exit(self,close);font=ApparatusStyle.font();mouse_filter=Control.MOUSE_FILTER_STOP
 if CableArt.complete():
  visuals=CableVisuals.new();visuals.art=CableArt.parts();visuals.z_index=-20;add_child(visuals)
  var backdrop:=ColorRect.new();backdrop.color=Color("c7ccc8");backdrop.size=Vector2(960,540);backdrop.z_index=-30;backdrop.mouse_filter=Control.MOUSE_FILTER_IGNORE;add_child(backdrop)
 var state=get_node_or_null("/root/State")
 if state!=null:reduced_motion=bool(state.d.get("native",{}).get("settings",{}).get("reduced_motion",false))
 hide()
func station_offset()->Vector2:return Vector2(30,14) if model.station==1 else Vector2.ZERO
func board_offset()->Vector2:return pointer+board_grab_offset-Vector2(480,122) if held_board else board_display_offset
func to_board(at:Vector2)->Vector2:return at-board_offset()
func from_board(at:Vector2)->Vector2:return at+board_offset()
func open()->void:show();fade=0;board_display_offset=station_offset();_sync_visuals(0);queue_redraw()
func close()->void:model.cancel();_clear_drag();hide();closed.emit()
func _sync_visuals(dt:float)->void:
 if visuals!=null:visuals.reduced_motion=reduced_motion;visuals.sync(self,dt)
func _clear_drag()->void:
 pending_touch="";pending_unplug=-1;route_drag=-1;route_selected=-1;dragging=-1;held_board=false;touch_id=-1;mouse_owned=false;selected=-1
 cable_grab_offset=Vector2.ZERO;route_grab_offset=Vector2.ZERO;board_display_offset=station_offset();_sync_visuals(0)
func _notification(what:int)->void:
 if what in [NOTIFICATION_APPLICATION_FOCUS_OUT,NOTIFICATION_APPLICATION_PAUSED]:model.pause();_clear_drag();queue_redraw()
func _process(dt:float)->void:
 if not visible:return
 fade=minf(1,fade+dt*5);model.step(minf(dt,.1))
 if not held_board:board_display_offset=station_offset() if reduced_motion else board_display_offset.move_toward(station_offset(),maxf(dt,0)*1800)
 _sync_visuals(dt);queue_redraw()
func _input(event:InputEvent)->void:
 if ApparatusStyle.navigation_event(self,event):return
 if not is_visible_in_tree():return
 if event is InputEventKey and event.pressed and not event.echo:
  if event.keycode==KEY_ESCAPE:close()
  else:_keyboard(event)
 elif event is InputEventMouseButton and event.button_index==MOUSE_BUTTON_LEFT:
  if touch_id>=0 or event.device==InputEvent.DEVICE_ID_EMULATION:return
  if event.pressed and not mouse_owned:mouse_owned=true;_touch_begin(get_global_transform_with_canvas().affine_inverse()*event.position)
  elif not event.pressed and mouse_owned:mouse_owned=false;_touch_finish(get_global_transform_with_canvas().affine_inverse()*event.position)
 elif event is InputEventMouseMotion:
  if touch_id>=0 or event.device==InputEvent.DEVICE_ID_EMULATION:return
  pointer=get_global_transform_with_canvas().affine_inverse()*event.position
 elif event is InputEventScreenTouch:
  if event.canceled and event.index==touch_id:_clear_drag()
  elif event.pressed and not event.canceled and touch_id<0 and not mouse_owned:touch_id=event.index;_touch_begin(get_global_transform_with_canvas().affine_inverse()*event.position)
  elif not event.pressed and event.index==touch_id:_touch_finish(get_global_transform_with_canvas().affine_inverse()*event.position);touch_id=-1
 elif event is InputEventScreenDrag:
  if event.index==touch_id:pointer=get_global_transform_with_canvas().affine_inverse()*event.position
 else:return
 _sync_visuals(0);queue_redraw();get_viewport().set_input_as_handled()
func _keyboard(event:InputEventKey)->void:
 if event.keycode not in [KEY_TAB,KEY_ENTER,KEY_SPACE,KEY_LEFT,KEY_RIGHT,KEY_UP,KEY_DOWN,KEY_DELETE,KEY_BACKSPACE]:return
 if mouse_owned or touch_id>=0 or held_board or route_drag>=0 or dragging>=0:return
 keyboard_active=true
 if event.keycode==KEY_TAB:keyboard_index=(keyboard_index+1)%8;return
 if model.running:
  if model.paused and event.keycode in [KEY_ENTER,KEY_SPACE]:model.resume()
  return
 if keyboard_index<3:
  if event.keycode in [KEY_LEFT,KEY_RIGHT]:keyboard_destination=posmod(keyboard_destination+(-1 if event.keycode==KEY_LEFT else 1),3)
  elif event.keycode in [KEY_ENTER,KEY_SPACE]:_connect(keyboard_index,keyboard_destination)
  elif event.keycode in [KEY_DELETE,KEY_BACKSPACE]:model.edit(keyboard_index,-1)
  elif event.keycode in [KEY_UP,KEY_DOWN]:model.route_cable(keyboard_index,event.keycode==KEY_UP)
 elif event.keycode in [KEY_ENTER,KEY_SPACE]:
  match keyboard_index:
   3:model.rotate_adapter()
   4:model.move_to(1-model.station)
   5:model.set_short(not model.short_cable)
   6:model.start()
   7:notebook=not notebook
func _touch_action(at:Vector2)->String:
 if notebook:return "notes"
 if Rect2(48,438,130,65).has_point(at):return "paper"
 if Rect2(190,435,110,65).has_point(at):return "reel"
 if model.paused:return "resume"
 if not model.running and to_board(at).distance_to(Vector2(275,164))<34:return "adapter"
 if not model.running and at.distance_to(Vector2(730,300))<40:return "trial"
 return ""
func _touch_begin(at:Vector2)->void:
 pointer=at;pending_origin=at;pending_touch=_touch_action(at);pending_unplug=-1
 if pending_touch.is_empty():press(at)
func _touch_finish(at:Vector2)->void:
 if not Rect2(0,0,960,540).has_point(at):_clear_drag();return
 if not pending_touch.is_empty():
  var activate:=pending_touch==_touch_action(at) and pending_origin.distance_to(at)<18
  pending_touch=""
  if activate:press(pending_origin)
 else:release(at)
func press(at:Vector2)->void:
 keyboard_active=false;pointer=at;pending_origin=at
 if notebook:
  if Rect2(590,400,220,54).has_point(at):hint_level=mini(3,hint_level+1)
  else:notebook=false
  return
 if Rect2(48,438,130,65).has_point(at):notebook=true;return
 if Rect2(190,435,110,65).has_point(at):model.set_short(not model.short_cable);return
 if model.paused:model.resume();return
 if model.running:return
 var local:=to_board(at)
 if Rect2(385,94,190,56).has_point(local):board_grab_offset=from_board(Vector2(480,122))-at;held_board=true;return
 if route_selected>=0 and _seat_route(route_selected,at):route_selected=-1;return
 for i:int in 3:
  if local.distance_to(Vector2(350,PORT_Y[i]))<29:
   dragging=i;selected=i;cable_grab_offset=Vector2(350,PORT_Y[i])-local;return
  if local.distance_to(Vector2(610,PORT_Y[i]))<29:
   if selected>=0:_connect(selected,i);selected=-1
   else:
    var channel:int=model.connections.find(i)
    if channel>=0:dragging=channel;selected=channel;pending_unplug=channel;cable_grab_offset=Vector2(610,PORT_Y[i])-local
   return
  if at.distance_to(route_grip(i))<19:route_drag=i;route_selected=i;route_origin=at;route_grab_offset=to_board(route_grip(i))-local;return
 if local.distance_to(Vector2(275,164))<34:model.rotate_adapter();return
 if at.distance_to(Vector2(730,300))<40:model.start();feedback="";return
func _connect(channel:int,port:int)->void:feedback="" if model.edit(channel,port) else "这个插孔已有插头，先拔下。"
func route_grip(channel:int)->Vector2:return from_board(model.point_at_distance(model.cable_path(channel),75))
func route_seat(channel:int,outside:bool)->Vector2:
 if not outside:return from_board(Vector2(450,PORT_Y[channel]))
 var port:int=model.connections[channel]
 if port<0:return from_board(Vector2(430,PORT_Y[channel]))
 var direct:=PackedVector2Array([Vector2(350,PORT_Y[channel]),Vector2(450,PORT_Y[channel]),Vector2(530,PORT_Y[port]),Vector2(610,PORT_Y[port])])
 var y:float=PORT_Y[channel]
 if channel!=port or model.obstruction_distance(direct)>=0:y=Model.PILLAR.position.y-20 if channel==port else 180.0-channel*12.0
 return from_board(Vector2(430,y))
func _seat_route(channel:int,at:Vector2)->bool:
 var outer_distance:=at.distance_to(route_seat(channel,true));var inner_distance:=at.distance_to(route_seat(channel,false))
 if minf(outer_distance,inner_distance)>=30:return false
 model.route_cable(channel,outer_distance<inner_distance);return true
func release(at:Vector2)->void:
 pointer=at
 if not Rect2(0,0,960,540).has_point(at):_clear_drag();return
 if route_drag>=0:
  var channel:=route_drag;route_drag=-1
  if at.distance_to(route_origin)>8:_seat_route(channel,at+route_grab_offset);route_selected=-1
  route_grab_offset=Vector2.ZERO;_sync_visuals(0);queue_redraw();return
 if held_board:
  board_display_offset=board_offset()
  var seated:=false
  for station:int in 2:
   if Rect2(710,104+station*66,160,60).has_point(at):model.move_to(station);seated=true
  held_board=false
  if not seated:board_display_offset=station_offset()
 if dragging>=0:
  var connected:=false
  for i:int in 3:
   if (to_board(at)+cable_grab_offset).distance_to(Vector2(610,PORT_Y[i]))<35:_connect(dragging,i);selected=-1;connected=true;break
  if not connected and pending_unplug>=0:model.edit(pending_unplug,-1);selected=-1
  dragging=-1;pending_unplug=-1;cable_grab_offset=Vector2.ZERO
 _sync_visuals(0);queue_redraw()
# Object captions and test records are available only on request.
func annotations_visible()->bool:return notebook
func _txt(value:String,at:Vector2,size_px:=18,color:=INK)->void:
 if not annotations_visible():return
 draw_string(font,at,value,HORIZONTAL_ALIGNMENT_LEFT,-1,size_px,color)
func _symbol(at: Vector2, role: int, color := INK) -> void:
 match role:
  0: draw_colored_polygon(PackedVector2Array([at+Vector2(0,-8),at+Vector2(9,7),at+Vector2(-9,7)]),color)
  1: draw_rect(Rect2(at-Vector2(7,7),Vector2(14,14)),color)
  2: draw_circle(at,8,color)
func route_preview(channel:int,path:PackedVector2Array)->PackedVector2Array:
 # A held segment is a non-running proposal only. Endpoints stay fixed and no
 # route/length/collision result is written before an existing seat accepts it.
 if route_drag!=channel or model.running:return path
 var result:=PackedVector2Array([path[0]])
 var distance:=0.0
 var inserted:=false
 for i:int in range(1,path.size()):
  var segment:=path[i-1].distance_to(path[i])
  if not inserted and distance+segment>=75:
   result.append(to_board(pointer)+route_grab_offset);inserted=true
  result.append(path[i]);distance+=segment
 return result
func _point_on(line: PackedVector2Array, fraction: float) -> Vector2:
 return model.point_at_distance(line,model.path_length(line)*fraction)
func _visible_cable(line: PackedVector2Array) -> PackedVector2Array:
 var result := PackedVector2Array([line[0]])
 var remaining: float = model.cable_length()
 for i: int in range(1,line.size()):
  var length := line[i-1].distance_to(line[i])
  if remaining < length:
   result.append(line[i-1].lerp(line[i],remaining/maxf(length,.001))); break
  result.append(line[i]); remaining -= length
 return result
func _draw()->void:
 if font==null or visuals==null:return
 _txt("流动工位",Vector2(36,38),24)
 if notebook:
  _txt("连接记录",Vector2(220,140),23)
  _txt("三角 → 源端    方形 → 分配    圆形 → 接收",Vector2(220,179),18)
  _txt("搬动底座不会复制作品；旧连接无需重插。",Vector2(220,214),17)
  _txt("线长：%d · 已验证工位：%d / 2"%[model.cable_length(),int(model.station_proofs[0])+int(model.station_proofs[1])],Vector2(220,238),16)
  for i:int in hint_level:_txt(HINTS[i],Vector2(220,260+i*41),17)
  _txt("翻下一页提示",Vector2(610,433),18);_txt("点空白合上",Vector2(220,433),16)
  return
 _txt("便携底座 · 01",from_board(Vector2(402,90)),16)
 for s:int in 2:
  for port:int in 3:_symbol(Vector2(767+port*29,139+s*66),Model.ROLES[s][port],INK)
  _txt("甲" if s==0 else "乙",Vector2(706,144+s*66),16)
  if held_board:ApparatusStyle.target(self,Rect2(730,115+s*66,128,48),true)
  if s==model.station:_txt("已接入",Vector2(868,146+s*66),12)
  if model.station_proofs[s]:draw_circle(Vector2(841,130+s*66),5,INK)
 for i:int in 3:
  var line:=model.cable_path(i)
  if model.running:
   var pulse:=from_board(model.point_at_distance(line,minf(model.path_length(line)*model.progress,model.failure_distance(i))))
   draw_circle(pulse,6,PAPER);_symbol(pulse,model.source_role(i),INK)
  if model.outcomes[i] in ["blocked","short"]:
   var collision:=from_board(model.point_at_distance(line,model.failure_distance(i)))
   draw_line(collision-Vector2(9,9),collision+Vector2(9,9),Color("915443"),3);draw_line(collision+Vector2(-9,9),collision+Vector2(9,-9),Color("915443"),3)
   if model.outcomes[i]=="short":_txt("未接上",collision+Vector2(12,-12),13,Color("743a2b"))
  if route_selected==i:
   for outside:bool in [true,false]:
    var seat:=route_seat(i,outside);ApparatusStyle.target(self,Rect2(seat-Vector2(14,14),Vector2(28,28)),pointer.distance_to(seat)<30)
  for side:int in 2:
   var at:=from_board(Vector2(350 if side==0 else 610,PORT_Y[i]))
   var role:int=model.source_role(i) if side==0 else Model.ROLES[model.station][i]
   _symbol(at,role);_txt(ROLE_LABEL[role],at+Vector2(-48 if side==0 else 31,6),17)
  if model.received[i]>=0:_txt(str(model.received[i]),Vector2(832,329+i*25),20)
 if route_selected>=0 or model.outcomes.has("blocked"):
  draw_rect(Rect2(from_board(Model.PILLAR.position),Model.PILLAR.size),Color("915443"),false,1)
  _txt("接触边界",from_board(Model.PILLAR.position)+Vector2(-12,-8),12,Color("743a2b"))
 _symbol(from_board(Vector2(275,164)),model.orientation)
 _txt("适配定位环",from_board(Vector2(222,106)),15)
 if route_drag>=0:_txt("未落座",pointer+Vector2(14,-12),13)
 _txt("源信号",Vector2(720,355),17);_txt("接收",Vector2(813,304),16)
 _txt("试验手册",Vector2(64,470),18)
 _txt("430" if model.short_cable else "800",Vector2(280,476),16)
 if model.completed:_txt("已留存两工位记录",Vector2(637,505),20)
 elif model.paused:_txt("已暂停 · 触碰装置继续",Vector2(530,474),18)
 elif not feedback.is_empty():_txt(feedback,Vector2(323,474),17)
 if keyboard_active:
  var focus:=Rect2()
  if keyboard_index<3:
   focus=Rect2(from_board(Vector2(350,PORT_Y[keyboard_index]))-Vector2(20,20),Vector2(40,40))
   ApparatusStyle.target(self,Rect2(from_board(Vector2(610,PORT_Y[keyboard_destination]))-Vector2(20,20),Vector2(40,40)),true)
  else:
   match keyboard_index:
    3:focus=Rect2(from_board(Vector2(243,132)),Vector2(64,64))
    4:focus=Rect2(from_board(Vector2(385,94)),Vector2(190,56))
    5:focus=Rect2(190,435,110,65)
    6:focus=Rect2(695,260,70,80)
    7:focus=Rect2(48,438,130,65)
  ApparatusStyle.target(self,focus,true)
