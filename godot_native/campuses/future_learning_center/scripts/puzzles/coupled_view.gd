extends Control
const ApparatusStyle=preload("res://campuses/future_learning_center/scripts/apparatus_style.gd")
signal closed
const Model=preload("res://campuses/future_learning_center/scripts/puzzles/coupled_model.gd")
const INK=ApparatusStyle.INK
const PAPER=ApparatusStyle.PAPER
const PIN_TRAY:=Vector2(100,310)
var model=Model.new()
var font:Font
var drag:=-1
var touch_id:=-1
var pointer:=Vector2.ZERO
var offset:=Vector2.ZERO
var before:Dictionary={}
var paper_open:=false
var hint_level:=0
var focus_index:=0
var selected:=-1
const HINTS:=["单块与连体，分别在哪里停住或不导通？","观察边角扫过的范围，以及托盘能托住的位置。","终台两端与滑块之间的插孔，都接触了吗？"]
func _ready()->void:
 ApparatusStyle.configure_exit(self,close)
 mouse_filter=Control.MOUSE_FILTER_STOP;focus_mode=Control.FOCUS_ALL
 font=ApparatusStyle.font();size=Vector2(960,540);hide()
func open()->void:model.resume();show();grab_focus();queue_redraw()
func close()->void:cancel_pointer();hide();closed.emit()
func cancel_pointer()->void:
 if not before.is_empty():model.restore(before)
 before={};drag=-1;touch_id=-1;queue_redraw()
func _notification(what:int)->void:
 if what in [NOTIFICATION_APPLICATION_FOCUS_OUT,NOTIFICATION_APPLICATION_PAUSED]:cancel_pointer();model.pause()
func _gui_input(event:InputEvent)->void:
 if not visible:return
 if event is InputEventScreenTouch:
  if event.index==touch_id and event.canceled:cancel_pointer()
  elif event.pressed and touch_id<0:touch_id=event.index;press_at(event.position)
  elif not event.pressed and event.index==touch_id:release_at(event.position);touch_id=-1
  accept_event()
 elif event is InputEventScreenDrag and event.index==touch_id:move_at(event.position);accept_event()
 elif event is InputEventMouse and event.device==InputEvent.DEVICE_ID_EMULATION:return
 elif event is InputEventMouseButton and touch_id<0 and event.button_index==MOUSE_BUTTON_LEFT:
  if event.pressed:press_at(event.position)
  else:release_at(event.position)
  accept_event()
 elif event is InputEventMouseMotion and touch_id<0:move_at(event.position)
 elif event is InputEventKey and event.pressed and not event.echo:
  if event.keycode==KEY_ESCAPE:close()
  elif event.keycode==KEY_TAB:focus_index=posmod(focus_index+1,5)
  elif event.keycode in [KEY_ENTER,KEY_SPACE]:
   if focus_index<2:selected=focus_index
   elif focus_index==2:
    model.remember()
    if model.connected:model.remove_pin()
    else:model.insert_pin()
    model.finish_gesture()
   elif focus_index==3:model.remember();model.rotate_to(model.angle+PI/2);model.finish_gesture()
   else:_paper()
  elif selected>=0 and event.keycode in [KEY_LEFT,KEY_RIGHT,KEY_UP,KEY_DOWN]:
   var d:=Vector2(float(event.keycode==KEY_RIGHT)-float(event.keycode==KEY_LEFT),float(event.keycode==KEY_DOWN)-float(event.keycode==KEY_UP))*5
   model.remember();model.move_piece(selected,model.positions[selected]+d);model.finish_gesture()
  queue_redraw();accept_event()
func handle()->Vector2:return model.midpoint()+Vector2(0,-57).rotated(model.angle)
func press_at(at:Vector2)->void:
 pointer=at
 if Rect2(42,472,140,42).has_point(at):_paper();return
 if at.distance_to(Vector2(855,490))<28:model.undo();queue_redraw();return
 before=model.snapshot()
 if at.distance_to(model.midpoint() if model.connected else PIN_TRAY)<24:
  drag=2
  if model.connected:model.remove_pin()
 elif model.connected and at.distance_to(handle())<22:drag=3
 else:
  for i:int in 2:
   if Rect2(-30,-30,60,60).has_point((at-model.positions[i]).rotated(-model.angle)):
    drag=i;offset=at-model.positions[i];selected=i;break
 if drag<0:before={}
 queue_redraw()
func move_at(at:Vector2)->void:
 pointer=at
 if drag in [0,1]:model.move_piece(drag,at-offset)
 elif drag==3:model.rotate_to((at-model.midpoint()).angle()+PI/2)
 queue_redraw()
func release_at(at:Vector2)->void:
 if drag<0:return
 move_at(at)
 if drag==2:
  if at.distance_to(model.midpoint())<28:model.insert_pin()
  elif at.distance_to(PIN_TRAY)>45:model.restore(before)
 if not before.is_empty():model.history.append(before)
 before={};drag=-1;model.finish_gesture();queue_redraw()
func _paper()->void:
 if not paper_open:paper_open=true;hint_level=0
 elif hint_level<2:hint_level+=1
 else:paper_open=false
 queue_redraw()
func _text(value:String,at:Vector2,pixels:=16,color:=INK)->void:draw_string(font,at,value,HORIZONTAL_ALIGNMENT_LEFT,-1,pixels,color)
func _pin(at:Vector2)->void:
 draw_line(at+Vector2(0,-11),at+Vector2(0,12),INK,9)
 draw_line(at+Vector2(0,-11),at+Vector2(0,10),Color("c5b78e"),5)
 draw_circle(at-Vector2(0,11),10,Color("9f8765"));draw_arc(at-Vector2(0,11),7,PI,TAU,16,PAPER,2)
func _draw()->void:
 if font==null:return
 draw_rect(Rect2(0,0,960,540),INK);_text("团队工作室 · 连起来以后",Vector2(32,38),22,PAPER)
 _text("把两块送入终台区域并连成一个导通整体",Vector2(33,66),16,Color("bdc5bd"))
 draw_rect(Rect2(35,86,890,380),Color("a58e6e"))
 for y:int in range(95,470,26):draw_line(Vector2(40,y),Vector2(920,y),Color("978060"),1)
 # All three support surfaces use the exact model boundaries.
 for r:Rect2 in [Rect2(180,90,600,160),Rect2(438,250,84,80),Rect2(180,330,600,140)]:
  draw_rect(Rect2(r.position+Vector2(0,5),r.size),INK);draw_rect(r,Color("d2c5a9"))
 draw_line(Vector2(438,250),Vector2(438,330),INK,3);draw_line(Vector2(522,250),Vector2(522,330),INK,3)
 for t:Vector2 in Model.TARGETS:
  draw_rect(Rect2(t-Vector2(32,32),Vector2(64,64)),Color("8e947e"),false,2)
  draw_circle(t,11,Color("bd9c65"));draw_circle(t,5,PAPER)
 draw_line(Model.TARGETS[0],Vector2(450,114),Color("bd9c65"),3)
 draw_line(Model.TARGETS[1],Vector2(510,114),Color("bd9c65"),3)
 draw_line(Vector2(450,114),Vector2(510,114),Color("bd9c65"),3)
 draw_circle(Vector2(480,114),9,Color("e4d6a3") if model.circuit_closed() else INK)
 draw_rect(Rect2(PIN_TRAY-Vector2(23,30),Vector2(46,60)),Color("756c59"))
 for i:int in 2:
  var at:Vector2=model.positions[i]
  draw_colored_polygon(model.corners(at+Vector2(0,5),model.angle),INK)
  draw_colored_polygon(model.corners(at,model.angle),Color("769492") if i==0 else Color("b89269"))
  var top:=model.corners(at,model.angle);draw_line(top[0],top[1],PAPER,2)
  var socket:Vector2=at+(model.positions[1-i]-at).normalized()*28
  draw_circle(socket,5,INK);draw_circle(socket,2,Color("c5b78e"))
  draw_arc(at,12,0,TAU,24,INK,3);draw_line(at-Vector2(8,0).rotated(model.angle),at+Vector2(8,0).rotated(model.angle),PAPER,2)
  if selected==i:draw_arc(at,18,0,TAU,24,PAPER,1)
 if model.connected:
  draw_line(model.positions[0],model.positions[1],Color("c5b78e"),5)
  _pin(model.midpoint());draw_line(model.midpoint(),handle(),INK,3);draw_arc(handle(),12,0,TAU,24,PAPER,4)
 elif drag!=2:_pin(PIN_TRAY)
 if drag==2:_pin(pointer)
 if model.blocked_at!=Vector2.ZERO:draw_arc(model.blocked_at,34,0,TAU,32,Color("ac6559"),3)
 draw_rect(Rect2(42,474,140,38),PAPER);_text("制作者便笺",Vector2(59,499),16)
 draw_arc(Vector2(855,490),14,.4,5.5,24,PAPER,3);draw_line(Vector2(841,482),Vector2(841,494),PAPER,3)
 if paper_open:_text(HINTS[hint_level],Vector2(205,499),16,PAPER)
 elif not model.outcome.is_empty():_text(model.outcome,Vector2(205,499),16,PAPER)
