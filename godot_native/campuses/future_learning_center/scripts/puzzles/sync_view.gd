extends "res://campuses/future_learning_center/scripts/puzzles/collab_view.gd"
const Sync=preload("res://campuses/future_learning_center/scripts/puzzles/sync_model.gd")
var tape_drag:=-1
var start_offset:=0.0
func _init()->void:
 model=Sync.new();hints=["同一动作，在两条纸带上是否出现在同一位置？","对齐一次闪光后，再看看远处的碰停事件。","比较相机图帧与碰停纸带中两处共同事件的间隔。"]
func _cancel_pointer()->void:
 if tape_drag>=0:model.shift(tape_drag,start_offset)
 tape_drag=-1;super._cancel_pointer()
func _press(at:Vector2)->void:
 pointer=at;pressed_at=at;action=""
 if Rect2(35,440,150,70).has_point(at):action="hint";return
 if at.distance_to(Vector2(850,440))<44:action="roll";return
 if model.paused:action="resume";return
 for i:int in 2:
  if Rect2(85,118+i*108,790,83).has_point(at):tape_drag=i;start_offset=model.offsets[i];return
 if at.distance_to(Vector2(740,383))<38:action="run";return
func _input(event:InputEvent)->void:
 if ApparatusStyle.navigation_event(self,event):return
 super._input(event)
 if visible and tape_drag>=0 and (event is InputEventMouseMotion or event is InputEventScreenDrag):
  if event is InputEventMouseMotion and (touch_id>=0 or event.device==InputEvent.DEVICE_ID_EMULATION):return
  if event is InputEventScreenDrag and event.index!=touch_id:return
  model.shift(tape_drag,clampf(start_offset+pointer.x-pressed_at.x,-230,230));queue_redraw()
func _release(at:Vector2)->void:
 if tape_drag>=0:model.shift(tape_drag,clampf(start_offset+at.x-pressed_at.x,-230,230));tape_drag=-1;return
 if at.distance_to(pressed_at)>18:action="";return
 match action:
  "close":close()
  "hint":hint_level=(hint_level+1)%4;if_hint()
  "roll":model.replace_roll()
  "run":model.start()
  "resume":model.resume()
 action="";queue_redraw()
func _event_icon(at:Vector2,kind:String,color:Color)->void:
 if kind=="flash":
  for angle:float in [0,PI/2,PI/4,-PI/4]:draw_line(at-Vector2(cos(angle),sin(angle))*12,at+Vector2(cos(angle),sin(angle))*12,color,2)
 elif kind=="feed":
  draw_rect(Rect2(at-Vector2(14,10),Vector2(24,20)),color);draw_line(at+Vector2(15,-15),at+Vector2(15,15),color,3)
 else:
  draw_rect(Rect2(at-Vector2(16,10),Vector2(22,20)),color);draw_line(at+Vector2(8,-19),at+Vector2(8,19),color,5)
func _draw()->void:
 if font==null:return
 draw_rect(Rect2(0,0,960,540),Color("26323a"));text("两份记录差了一个节拍",Vector2(35,38),22)
 box(Rect2(30,90,900,337),Color("95866d"),14)
 for i:int in 2:
  var y:=118+i*108
  box(Rect2(80,y-4,800,91),Color("536467"),4);draw_rect(Rect2(87,y+3,786,77),Color("d2cbb3"))
  for hole:int in range(0,32):
   draw_circle(Vector2(98+hole*24,y+10),2,Color("63706c"));draw_circle(Vector2(98+hole*24,y+70),2,Color("63706c"))
  text("相机" if i==0 else "传感",Vector2(36,y+48),13)
  for j:int in 4:
   var x:float=model.event_x(i,j)
   if x<110 or x>852:continue
   _event_icon(Vector2(x,y+40),Sync.CAMERA[j].kind,Color("35474d"))
   text(str(int(Sync.CAMERA[j].time+(model.bias() if i==1 else 0))),Vector2(x-6,y+65),12,Color("35474d"))
 # Thin guide lines expose both separated anchor discrepancies, not an auto-snap solution.
 for j:int in [0,3]:
  var a:=Vector2(model.event_x(0,j),202);var b:=Vector2(model.event_x(1,j),226)
  if a.x>85 and a.x<875 and b.x>85 and b.x<875:draw_line(a,b,Color("b8bdac"),2)
 draw_line(Vector2(200,380),Vector2(640,380),Color("394b52"),8)
 var x:float=210+model.travel*405
 box(Rect2(x-17,350,34,27),Color("b29c7a"),8)
 var gate_y:float=330+model.gate*36
 box(Rect2(520,gate_y-30,14,50),Color("6f8180"),8)
 box(Rect2(632,343,12,49),Color("627674"),4)
 draw_circle(Vector2(160,356),13,Color("dacc9d") if model.running and (model.elapsed<.18 or (model.elapsed>.7 and model.elapsed<.9)) else Color("667b7b"))
 draw_circle(Vector2(740,383),28,Color("354951"));draw_line(Vector2(740,383),Vector2(740,360 if model.running else 372),Color("cad0be"),7);draw_circle(Vector2(740,360 if model.running else 372),10,Color("ac9274"))
 ApparatusStyle.grip(self,Vector2(740,360 if model.running else 372),"press",model.running)
 draw_circle(Vector2(850,464),35,Color("b1b6a3"));draw_circle(Vector2(850,464),15,Color("40555c"));draw_line(Vector2(820,441),Vector2(852,435),Color("d3cdb4"),9)
 box(Rect2(35,450,150,60),Color("d2cbb3"),4);text("对照笔记",Vector2(65,484),17,Color("35474d"))
 for i:int in 2:ApparatusStyle.grip(self,Vector2(110,158+i*108),"horizontal",tape_drag==i)
 ApparatusStyle.grip(self,Vector2(850,440),"rotate",action=="roll")
 if hint_level>=0:text(hints[hint_level],Vector2(35,75),15)
 if not model.outcome.is_empty():text(model.outcome,Vector2(205,475),14)
 if model.paused:text("已暂停 · 触碰装置继续",Vector2(260,507),15)
