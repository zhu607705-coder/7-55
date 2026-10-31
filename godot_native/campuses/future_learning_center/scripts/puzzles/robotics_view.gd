extends Control
const ApparatusStyle=preload("res://campuses/future_learning_center/scripts/apparatus_style.gd")
signal closed
const Model=preload("res://campuses/future_learning_center/scripts/puzzles/robotics_model.gd")
const INK=ApparatusStyle.INK
const PAPER=ApparatusStyle.PAPER
const TURN:=Vector2(350,235)
const SWITCH:=Vector2(620,310)
const POWER:=Vector2(130,427)
var model=Model.new()
var font:Font
var drag:=-1
var touch_id:=-1
var pending_touch_action:=""
var touch_press:=Vector2.ZERO
var pointer:=Vector2.ZERO
var origin:=Vector2.ZERO
var grip_offset:=Vector2.ZERO
var turn_offset:=0.0
var preview_turn:=-PI/2
var preview_switch:=-16.0
var resume_after_drag:=false
var paper_open:=false
var hint_level:=0
var focus_index:=0
const HINTS:=["同一个岔口，从两边进入会碰到哪一面？","送达以后，空托盘走到了哪一处？","保持轨道不变，比较去程实线与返程点线。"]
func _ready()->void:
 ApparatusStyle.configure_exit(self,close)
 mouse_filter=Control.MOUSE_FILTER_STOP;focus_mode=Control.FOCUS_ALL
 font=ApparatusStyle.font();size=Vector2(960,540);hide()
func open()->void:cancel_pointer();show();grab_focus();queue_redraw()
func close()->void:model.cancel();cancel_pointer();hide();closed.emit()
func cancel_pointer()->void:
 pending_touch_action="";_cancel_pointer_state()
func _cancel_pointer_state()->void:
 drag=-1;touch_id=-1
 if resume_after_drag and model.running:model.resume()
 resume_after_drag=false;queue_redraw()
func turn_pose()->float:return preview_turn if drag==0 else (PI/2 if model.return_direction==1 else -PI/2)
func switch_pose()->float:return preview_switch if drag==1 else (16.0 if model.selector==1 else -16.0)
func move_at(at:Vector2)->void:
 pointer=at
 if drag==0 and at.distance_to(TURN)>=8:preview_turn=(at-TURN).angle()+turn_offset
 elif drag==1:preview_switch=clampf(at.x-grip_offset.x-SWITCH.x,-16,16)
 queue_redraw()
func _notification(what:int)->void:
 if what in [NOTIFICATION_APPLICATION_FOCUS_OUT,NOTIFICATION_APPLICATION_PAUSED]:resume_after_drag=false;model.pause();cancel_pointer()
func _process(dt:float)->void:
 if visible:model.step(dt);queue_redraw()
func _touch_action(at:Vector2)->String:
 if at.distance_to(POWER)<30:return "power"
 if at.distance_to(Vector2(225,427))<26:return "step"
 if Rect2(42,474,140,38).has_point(at):return "paper"
 if at.distance_to(Vector2(855,490))<25:return "undo"
 return ""
func _gui_input(e:InputEvent)->void:
 if not visible:return
 if e is InputEventScreenTouch:
  if e.index==touch_id and e.canceled:
   cancel_pointer()
  elif e.pressed and not e.canceled and touch_id<0:
   touch_id=e.index;touch_press=e.position;pending_touch_action=_touch_action(e.position)
   if pending_touch_action.is_empty():press_at(e.position)
  elif not e.pressed and e.index==touch_id:
   if not pending_touch_action.is_empty():
    var activate:bool=not e.canceled and touch_press.distance_to(e.position)<18 and _touch_action(e.position)==pending_touch_action
    pending_touch_action=""
    if activate:press_at(e.position)
   else:release_at(e.position)
   touch_id=-1
  accept_event()
 elif e is InputEventScreenDrag and e.index==touch_id:move_at(e.position);accept_event()
 elif e is InputEventMouse and e.device==InputEvent.DEVICE_ID_EMULATION:return
 elif e is InputEventMouseButton and touch_id<0 and e.button_index==MOUSE_BUTTON_LEFT:
  if e.pressed:press_at(e.position)
  else:release_at(e.position)
  accept_event()
 elif e is InputEventMouseMotion and touch_id<0:move_at(e.position)
 elif e is InputEventKey and e.pressed and not e.echo:
  if drag>=0 and e.keycode!=KEY_ESCAPE:return
  if e.keycode==KEY_ESCAPE:close()
  elif e.keycode==KEY_TAB:focus_index=posmod(focus_index+1,5)
  elif e.keycode in [KEY_ENTER,KEY_SPACE]:
   if focus_index==0:_power()
   elif focus_index==1:model.edit("selector",1-model.selector)
   elif focus_index==2:model.edit("return_direction",1-model.return_direction)
   elif focus_index==3:model.edit("target",5 if model.target==2 else 2)
   else:_paper()
  queue_redraw();accept_event()
func _power()->void:
 if drag>=0:return
 if model.running:
  if model.paused:model.resume()
  else:model.pause()
 else:model.start()
func press_at(at:Vector2)->void:
 origin=at;pointer=at
 if at.distance_to(POWER)<30:_power();return
 if at.distance_to(Vector2(225,427))<26:model.single_step();queue_redraw();return
 if Rect2(42,474,140,38).has_point(at):_paper();return
 if at.distance_to(Vector2(855,490))<25:model.undo();return
 if at.distance_to(TURN)<32:
  preview_turn=turn_pose();turn_offset=preview_turn-(at-TURN).angle() if at.distance_to(TURN)>=8 else 0.0;drag=0
 elif at.distance_to(SWITCH+Vector2(switch_pose(),34))<26:
  preview_switch=switch_pose();grip_offset=at-(SWITCH+Vector2(preview_switch,34));drag=1
 elif at.distance_to(Model.NODES[model.target]+Vector2(80,0))<30:
  grip_offset=at-(Model.NODES[model.target]+Vector2(80,0));drag=2
 if drag>=0:
  resume_after_drag=model.running and not model.paused
  if model.running:model.pause()
 queue_redraw()
func release_at(at:Vector2)->void:
 # Release commits the last visible pose, not a hidden toggle or a remote endpoint.
 if drag==0 and origin.distance_to(pointer)>=6 and at.distance_to(pointer)<=12:
  var candidate:=1 if sin(preview_turn)>0 else 0
  var detent:=PI/2 if candidate==1 else -PI/2
  if absf(angle_difference(preview_turn,detent))<=PI/6:model.edit("return_direction",candidate)
 elif drag==1 and origin.distance_to(pointer)>=6 and at.distance_to(pointer)<=12:
  if absf(preview_switch)>=12:model.edit("selector",1 if preview_switch>0 else 0)
 elif drag==2 and at.distance_to(pointer)<=12:
  for target:int in [2,5]:
   if (pointer-grip_offset).distance_to(Model.NODES[target]+Vector2(80,0))<22:model.edit("target",target)
 cancel_pointer()
func _paper()->void:
 if not paper_open:paper_open=true;hint_level=0
 elif hint_level<2:hint_level+=1
 else:paper_open=false
 queue_redraw()
func _text(s:String,at:Vector2,pixels:=16,color:=INK)->void:draw_string(font,at,s,HORIZONTAL_ALIGNMENT_LEFT,-1,pixels,color)
func _arrow(at:Vector2,heading:float,color:Color)->void:
 var d:=Vector2.RIGHT.rotated(heading);var side:=d.orthogonal()
 draw_line(at-d*12,at+d*12,color,3);draw_line(at+d*12,at+d*4+side*7,color,3);draw_line(at+d*12,at+d*4-side*7,color,3)
func _draw()->void:
 if font==null:return
 draw_rect(Rect2(0,0,960,540),INK);_text("机器人团队",Vector2(32,38),22,PAPER)
 if paper_open:_text("完成装载、卸载与空载返回",Vector2(33,66),16,PAPER)
 draw_rect(Rect2(35,88,890,375),Color("a58e6e"))
 for y:int in range(95,460,26):draw_line(Vector2(40,y),Vector2(920,y),Color("978060"),1)
 for edge:Array in Model.EDGES:
  var a:Vector2=Model.NODES[edge[0]];var b:Vector2=Model.NODES[edge[1]];var normal:Vector2=(b-a).normalized().orthogonal()*13
  draw_line(a,b,Color("685f50"),33)
  draw_line(a+normal,b+normal,PAPER,3);draw_line(a-normal,b-normal,PAPER,3)
 _arrow(Vector2(480,310),0,Color("d4b77d"))
 # The central rail has an actual reverse-facing stop, drawn at the same edge used by the graph.
 draw_line(Vector2(585,295),Vector2(585,325),INK,7)
 draw_line(Vector2(574,295),Vector2(585,310),Color("d4b77d"),4)
 var turn_angle:=turn_pose()
 draw_circle(TURN,28,Color("b9ae93"));draw_arc(TURN,24,0,TAU,32,INK,3);_arrow(TURN,turn_angle,INK)
 draw_circle(TURN+Vector2.RIGHT.rotated(turn_angle)*26,5,PAPER)
 var stop:=TURN+Vector2.RIGHT.rotated(turn_angle)*40
 var tangent:=Vector2.RIGHT.rotated(turn_angle).orthogonal()*15
 draw_line(stop-tangent,stop+tangent,INK,6)
 draw_line(stop-tangent+Vector2.RIGHT.rotated(turn_angle)*10,stop,Color("d4b77d"),4)
 var blend:=(switch_pose()+16)/32
 draw_line(SWITCH,SWITCH+Vector2(-35,0).lerp(Vector2(0,-35),blend),Color("c8b480"),7)
 draw_line(SWITCH+Vector2(0,10),SWITCH+Vector2(switch_pose(),34),INK,5)
 draw_circle(SWITCH+Vector2(switch_pose(),34),10,Color("c8b480"))
 ApparatusStyle.grip(self,SWITCH+Vector2(switch_pose(),34),"drag",drag==1)
 ApparatusStyle.grip(self,TURN,"rotate",drag==0)
 for n:int in [0,2,5]:
  var at:Vector2=Model.NODES[n]
  draw_rect(Rect2(at+Vector2(-52 if n==0 else 26,-25),Vector2(32,50)),Color("696f60"))
  for off:int in [-18,18]:draw_line(at+Vector2(-48 if n==0 else 30,off),at+Vector2(-24 if n==0 else 54,off),PAPER,3)
 var flag:Vector2=pointer-grip_offset if drag==2 else Model.NODES[model.target]+Vector2(80,0)
 draw_line(flag+Vector2(0,23),flag-Vector2(0,23),INK,3);draw_rect(Rect2(flag-Vector2(0,23),Vector2(30,20)),Color("c8b480"))
 ApparatusStyle.grip(self,flag,"drag",drag==2)
 if drag==2:
  for target:int in [2,5]:
   var destination:Vector2=Model.NODES[target]+Vector2(80,0)
   ApparatusStyle.target(self,Rect2(destination-Vector2(22,24),Vector2(44,48)),flag.distance_to(destination)<22)
 if paper_open:
  if model.outward.size()>1:draw_polyline(PackedVector2Array(model.outward),Color("e4d6a3"),2)
  for i:int in range(1,model.inward.size()):
   var a:Vector2=model.inward[i-1];var b:Vector2=model.inward[i]
   for t:int in range(0,int(a.distance_to(b)),15):draw_circle(a.move_toward(b,t),2,INK)
 var at:Vector2=model.position
 var heading:=0.0
 if model.next_node>=0:heading=(Model.NODES[model.next_node]-Model.NODES[model.node]).angle()
 draw_set_transform(at,heading)
 for y:int in [-17,17]:
  draw_rect(Rect2(-16,y-4,32,8),INK);draw_line(Vector2(-13+fmod(at.x+at.y,12),y-3),Vector2(-13+fmod(at.x+at.y,12),y+3),PAPER,2)
 draw_rect(Rect2(-24,-14,48,28),Color("769492"));draw_rect(Rect2(-12,-10,25,20),Color("b9ae93"),false,2)
 draw_circle(Vector2(18,-6),3,PAPER);draw_circle(Vector2(18,6),3,PAPER)
 var jaw:=7.0 if model.loaded else 15.0
 if model.phase=="loading":jaw=lerpf(15,7,model.progress)
 elif model.phase=="unloading":jaw=lerpf(7,15,model.progress)
 for sign_value:int in [-1,1]:draw_line(Vector2(-8,jaw*sign_value),Vector2(8,jaw*sign_value),PAPER,3)
 draw_set_transform(Vector2.ZERO)
 draw_rect(Rect2(model.cargo_position-Vector2(9,9),Vector2(18,18)),Color("c09161"))
 if not model.blocked_edge.is_empty():draw_arc(at,28,-.9,.9,20,Color("ac6559"),4)
 draw_circle(POWER,25,INK);draw_line(POWER,POWER+Vector2(0,-18 if model.running and not model.paused else 18),PAPER,8)
 draw_arc(Vector2(225,427),20,0,TAU,24,PAPER,4)
 for turn:float in [0.0,TAU/3,TAU*2/3]:draw_line(Vector2(225,427),Vector2(225,427)+Vector2.RIGHT.rotated(turn+model.progress)*18,INK,3)
 draw_circle(Vector2(225,427),5,INK)
 draw_rect(Rect2(42,474,140,38),PAPER);_text("试车记录",Vector2(67,499),16)
 draw_arc(Vector2(855,490),14,.4,5.5,24,PAPER,3)
 if paper_open:_text(HINTS[hint_level],Vector2(205,499),16,PAPER)
 elif not model.outcome.is_empty():_text(model.outcome,Vector2(205,499),16,PAPER)
