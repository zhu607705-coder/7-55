extends Control
const ApparatusStyle=preload("res://campuses/future_learning_center/scripts/apparatus_style.gd")
signal closed
const Model=preload("res://campuses/future_learning_center/scripts/puzzles/schedule_model.gd")
const INK=ApparatusStyle.INK
const PAPER=ApparatusStyle.PAPER
const NAMES=["拍 A","装 B","拍 B","比较"]
const XS=[370.0,545.0,720.0]
var model=Model.new()
var font:Font
var held_task:=-1
var held_tool:=-2
var selected_task:=-1
var pointer:=Vector2.ZERO
var touch_id:=-1
var paper_open:=false
func _ready()->void:
 ApparatusStyle.configure_exit(self,close)
 font=ApparatusStyle.font()
 mouse_filter=Control.MOUSE_FILTER_STOP;hide()
func open()->void:show();queue_redraw()
func close()->void:
 _cancel_drag();model.cancel();hide();closed.emit()
func _notification(what:int)->void:
 if what in [NOTIFICATION_APPLICATION_FOCUS_OUT,NOTIFICATION_APPLICATION_PAUSED]:_cancel_drag();model.pause()
func _process(dt:float)->void:
 if visible:model.step(dt);queue_redraw()
func card_point(task:int)->Vector2:return Vector2(XS[model.slots[task]],142+task*70)
func _cancel_drag()->void:held_task=-1;held_tool=-2;selected_task=-1;touch_id=-1;queue_redraw()
func _input(event:InputEvent)->void:
 if ApparatusStyle.navigation_event(self,event):return
 if not is_visible_in_tree():return
 if (event is InputEventMouseButton or event is InputEventMouseMotion) and event.device==InputEvent.DEVICE_ID_EMULATION:return
 if event is InputEventScreenTouch:
  if event.pressed and not event.canceled and touch_id<0:touch_id=event.index;press_at(get_global_transform_with_canvas().affine_inverse()*event.position)
  elif event.index==touch_id:
   if event.canceled:_cancel_drag()
   elif not event.pressed:release_at(get_global_transform_with_canvas().affine_inverse()*event.position);touch_id=-1
  get_viewport().set_input_as_handled()
 elif event is InputEventScreenDrag and event.index==touch_id:pointer=get_global_transform_with_canvas().affine_inverse()*event.position;queue_redraw();get_viewport().set_input_as_handled()
 elif event is InputEventMouseButton and event.button_index==MOUSE_BUTTON_LEFT and touch_id<0:
  var at:Vector2=get_global_transform_with_canvas().affine_inverse()*event.position
  if event.pressed:press_at(at)
  else:release_at(at)
  get_viewport().set_input_as_handled()
 elif event is InputEventMouseMotion and touch_id<0:pointer=get_global_transform_with_canvas().affine_inverse()*event.position;queue_redraw()
 elif event is InputEventKey and event.pressed and event.keycode==KEY_ESCAPE:close();get_viewport().set_input_as_handled()
func press_at(at:Vector2)->void:
 pointer=at
 if Rect2(42,427,150,74).has_point(at):paper_open=not paper_open;queue_redraw();return
 if at.distance_to(Vector2(238,471))<30:model.undo();return
 if at.distance_to(Vector2(870,340))<39:
  if model.running:
   if model.paused:model.resume()
   else:model.pause()
  else:model.start()
  return
 if Rect2(816,440,110,60).has_point(at):held_tool=3;return
 for task:int in 4:
  if Rect2(card_point(task)-Vector2(68,26),Vector2(136,52)).has_point(at):
   if held_tool>=-1 and held_tool<3:model.connect_tool(task,held_tool);held_tool=-2
   else:held_task=task;selected_task=task
   return
 for tool:int in 3:
  if tool==1 and model.cameras<2:continue
  if at.distance_to(Vector2(70+tool*75,220))<30:held_tool=tool;return
 # Hands are a physical glove pair beside the tool rack.
 if at.distance_to(Vector2(145,300))<30:held_tool=-1;return
func release_at(at:Vector2)->void:
 if held_task>=0:
  if Rect2(284,95,523,300).has_point(at):
   var slot:=0
   for index:int in 3:
    if absf(at.x-XS[index])<absf(at.x-XS[slot]):slot=index
   model.place(held_task,slot)
  held_task=-1
 elif held_tool==3:
  if Rect2(32,150,225,110).has_point(at):model.set_second_camera(true)
  held_tool=-2
 elif held_tool>=-1:
  for task:int in 4:
   if Rect2(card_point(task)-Vector2(68,26),Vector2(136,52)).has_point(at):model.connect_tool(task,held_tool);break
  held_tool=-2
 queue_redraw()
func _text(value:String,at:Vector2,sz:=16,color:=INK)->void:draw_string(font,at,value,HORIZONTAL_ALIGNMENT_LEFT,-1,sz,color)
func _camera(at:Vector2,color:=PAPER)->void:
 draw_rect(Rect2(at-Vector2(24,15)+Vector2(0,5),Vector2(48,30)),INK)
 draw_rect(Rect2(at-Vector2(24,15),Vector2(48,30)),color)
 draw_circle(at,11,INK);draw_circle(at,5,Color("7c9695"))
 draw_rect(Rect2(at+Vector2(-18,-20),Vector2(13,8)),color)
func _tool(tool:int,at:Vector2)->void:
 if tool in [0,1]:_camera(at);_text(str(tool+1),at+Vector2(27,5),12)
 elif tool==2:
  draw_rect(Rect2(at-Vector2(23,9),Vector2(46,14)),PAPER)
  for x:int in [-18,18]:draw_line(at+Vector2(x,5),at+Vector2(x,23),INK,5)
 else:
  draw_circle(at+Vector2(-9,0),9,PAPER);draw_circle(at+Vector2(9,0),9,PAPER)
func _card(task:int,at:Vector2)->void:
 draw_rect(Rect2(at-Vector2(68,26)+Vector2(0,5),Vector2(136,52)),INK)
 var face:=Color("d2cbb6")
 if model.artifacts[task]:face=Color("a3b6a1")
 elif model.errors[task]!="":face=Color("bd9582")
 draw_rect(Rect2(at-Vector2(68,26),Vector2(136,52)),face)
 _text(NAMES[task],at+Vector2(-54,6),18)
 _tool(model.tools[task],at+Vector2(33,0))
 if model.current_tasks.has(task):draw_line(at+Vector2(-62,21),at+Vector2(-62+124*model.progress,21),INK,3)
func _draw()->void:
 if font==null:return
 draw_rect(Rect2(0,0,960,540),Color("253236"))
 _text("开放研讨 · 同一拍能做什么",Vector2(32,39),23,PAPER)
 draw_rect(Rect2(25,85,910,420),Color("4d5652"));draw_rect(Rect2(25,77,910,420),Color("a89b80"))
 draw_rect(Rect2(283,95,525,303),Color("cbc6b3"))
 for slot:int in 3:
  draw_line(Vector2(XS[slot]-87,95),Vector2(XS[slot]-87,398),Color("969988"),1)
  _text(str(slot+1),Vector2(XS[slot]-5,91),15,PAPER)
 draw_rect(Rect2(35,154,220,112),Color("717c71"));_text("工具托盘",Vector2(85,180),16,PAPER)
 _tool(0,Vector2(70,220));_tool(2,Vector2(220,220))
 if model.cameras==2:_tool(1,Vector2(145,220))
 else:draw_arc(Vector2(145,220),26,0,TAU,32,Color("9b9f8d"),1)
 _tool(-1,Vector2(145,300))
 for task:int in 4:
  _card(task,pointer if held_task==task else card_point(task))
 # A clockwork handle advances the physical production board, not a Run button.
 draw_circle(Vector2(870,340),35,INK)
 var angle:float=model.progress*TAU if model.running else -.8
 draw_line(Vector2(870,340),Vector2(870,340)+Vector2.from_angle(angle)*27,PAPER,7)
 draw_circle(Vector2(870,340)+Vector2.from_angle(angle)*27,9,Color("7b6253"))
 for i:int in 3:draw_circle(Vector2(847+i*23,395),5,Color("c3cbb0") if model.beat>i else INK)
 # Actual output rack: photos, assembled B and the comparison sheet appear only
 # after their beat finishes; same-beat consumers cannot see them prematurely.
 for task:int in 4:
  var at:=Vector2(350+task*105,451)
  draw_rect(Rect2(at-Vector2(35,21),Vector2(70,42)),Color("667468"))
  if model.artifacts[task]:
   draw_rect(Rect2(at-Vector2(25,17),Vector2(50,34)),PAPER)
   _text(NAMES[task],at+Vector2(-22,5),14)
 draw_rect(Rect2(42,429,150,70),PAPER);draw_line(Vector2(53,429),Vector2(53,499),Color("9b9c89"),2);_text("排期笔记",Vector2(65,466),16)
 draw_arc(Vector2(238,471),18,.4,5.8,20,PAPER,6);draw_line(Vector2(223,484),Vector2(209,498),PAPER,7)
 if model.cameras<2:_camera(Vector2(870,470),Color("aebbaa"))
 else:_text("备用相机已入架",Vector2(815,476),13)
 if held_tool>=-1 and held_tool<3:_tool(held_tool,pointer)
 elif held_tool==3:_camera(pointer)
 if model.completed:_text("照片与装配件已齐备",Vector2(332,525),16,PAPER)
 if paper_open:
  draw_rect(Rect2(42,92,235,315),PAPER)
  var lines=["拍 A：相机", "装 B：操作台", "拍 B：先有装好的 B", "比较：先有两张照片", "", "同一件工具一拍只用一次。", "本拍产物从下一拍才能用。", "", "拖任务磁片到拍位。", "从托盘把工具接到任务上。"]
  for i:int in lines.size():_text(lines[i],Vector2(54,121+i*25),14)
