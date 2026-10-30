extends Control
signal closed
const Model=preload("res://campuses/future_learning_center/scripts/puzzles/koala_model.gd")
const INK:=Color("29373b")
const PAPER:=Color("e7e1cf")
var model=Model.new()
var font:Font
var held:=-1
var held_card:=-1
var touch_id:=-1
var pointer:=Vector2.ZERO
var origin:=Vector2.ZERO
var paper_open:=false
var hint_level:=0
var frame_cursor:=0
const HINTS:=["形状回来了，填纹也回来了吗？","交换两个模块的前后，比较纸带上的中间结果。","最后改变的是哪两个位置？"]
func _ready()->void:
 mouse_filter=Control.MOUSE_FILTER_STOP;focus_mode=Control.FOCUS_ALL;font=load("res://scripts/ui/native_typography.gd").body_font();size=Vector2(960,540);model.insert_card(0);hide()
func open()->void:show();model.resume();queue_redraw()
func close()->void:model.cancel();cancel_pointer();hide();closed.emit()
func cancel_pointer()->void:held=-1;held_card=-1;touch_id=-1;queue_redraw()
func _notification(what:int)->void:
 if what in [NOTIFICATION_APPLICATION_FOCUS_OUT,NOTIFICATION_APPLICATION_PAUSED]:model.pause();cancel_pointer()
func _process(dt:float)->void:
 if visible:model.step(dt);queue_redraw()
func socket(index:int)->Vector2:return Vector2(130+index*90,373)
func module_position(id:int)->Vector2:
 var index:int=model.chain.find(id)
 return socket(index) if index>=0 else Vector2(130+id*90,469)
func card_position(id:int)->Vector2:return Vector2(155,145+id*105)
func _gui_input(e:InputEvent)->void:
 if not visible:return
 if e is InputEventScreenTouch:
  if e.index==touch_id and e.canceled:model.cancel();cancel_pointer()
  elif e.pressed and not e.canceled and touch_id<0:touch_id=e.index;press_at(e.position)
  elif not e.pressed and e.index==touch_id:
   if e.canceled:model.cancel();cancel_pointer()
   else:release_at(e.position)
   touch_id=-1
  accept_event()
 elif e is InputEventScreenDrag and e.index==touch_id:pointer=e.position;queue_redraw();accept_event()
 elif e is InputEventMouse and e.device==InputEvent.DEVICE_ID_EMULATION:return
 elif e is InputEventMouseButton and touch_id<0 and e.button_index==MOUSE_BUTTON_LEFT:
  if e.pressed:press_at(e.position)
  else:release_at(e.position)
  accept_event()
 elif e is InputEventMouseMotion and touch_id<0:pointer=e.position;queue_redraw()
 elif e is InputEventKey and e.pressed and e.keycode==KEY_ESCAPE:close();accept_event()
func press_at(at:Vector2)->void:
 pointer=at;origin=at
 if Rect2(880,15,60,50).has_point(at):close();return
 if Rect2(35,514,150,26).has_point(at):paper_open=not paper_open;hint_level=(hint_level+1)%3;return
 if at.distance_to(Vector2(870,470))<26:model.undo();return
 if at.distance_to(Vector2(870,280))<35:
  if model.paused:model.resume()
  else:model.start()
  return
 if Rect2(660,235,180,96).has_point(at):frame_cursor+=3;return
 for i:int in 2:
  if Rect2(card_position(i)-Vector2(102,35),Vector2(204,70)).has_point(at):held_card=i;return
 for i:int in 8:
  if at.distance_to(module_position(i))<31:held=i;return
 for i:int in 4:
  if Rect2(355+i*60,110,55,70).has_point(at):model.edit_token(i,at.y>150);return
func release_at(at:Vector2)->void:
 if held_card>=0:
  if Rect2(325,95,325,105).has_point(at):model.insert_card(held_card)
  held_card=-1;queue_redraw();return
 if held<0:return
 var id:=held;held=-1
 if Rect2(80,335,755,78).has_point(at):model.attach(id,clampi(roundi((at.x-130)/90),0,model.chain.size()))
 elif Rect2(80,430,760,80).has_point(at):model.attach(id,-1)
 queue_redraw()
func _text(s:String,p:Vector2,sz:=16,c:=INK)->void:draw_string(font,p,s,HORIZONTAL_ALIGNMENT_LEFT,-1,sz,c)
func _token(token:int,p:Vector2,s:=1.0)->void:
 var shape:int=token/2;var poly:=PackedVector2Array();var count:=24 if shape==0 else (4 if shape==1 else (3 if shape==2 else 10))
 for i:int in count:
  var a:float=TAU*i/count-PI/2+(PI/4 if shape==1 else 0);var r:float=17*s*(.48 if shape==3 and i%2==1 else 1.0);poly.append(p+Vector2(cos(a),sin(a))*r)
 draw_colored_polygon(poly,Color("6e8a87"));poly.append(poly[0]);draw_polyline(poly,INK,1.5)
 if token%2==1:
  for x:int in [-6,0,6]:draw_line(p+Vector2(x,-5)*s,p+Vector2(x,5)*s,PAPER,2*s)
func _pattern(tokens:Array,at:Vector2,s:=1.0)->void:
 for i:int in 4:_token(tokens[i],at+Vector2(i*48*s,0),s)
func _module(id:int,at:Vector2)->void:
 draw_rect(Rect2(at-Vector2(30,26)+Vector2(0,5),Vector2(60,52)),INK);draw_rect(Rect2(at-Vector2(30,26),Vector2(60,52)),Color("a8b1a1"))
 var op:int=Model.OPERATORS[id]
 if op in [0,1]:
  var direction:=1 if op==1 else -1
  draw_line(at-Vector2(19*direction,0),at+Vector2(19*direction,0),INK,3);draw_line(at+Vector2(19*direction,0),at+Vector2(9*direction,-9),INK,3);draw_line(at+Vector2(19*direction,0),at+Vector2(9*direction,9),INK,3)
 elif op==2:
  draw_line(at-Vector2(21,10),at+Vector2(21,10),INK,3);draw_line(at-Vector2(21,-10),at+Vector2(21,-10),INK,3)
 else:
  for i:int in 4:
   var p:=at+Vector2(-21+i*14,0);draw_rect(Rect2(p-Vector2(5,7),Vector2(10,14)),INK,i<2)
func _draw()->void:
 if font==null:return
 draw_rect(Rect2(0,0,960,540),INK);_text("考拉工作室 · 把变化倒过来",Vector2(32,38),22,PAPER);_text("×",Vector2(898,47),28,PAPER)
 draw_rect(Rect2(35,87,890,425),Color("a48d6c"))
 for y:int in range(105,510,30):draw_line(Vector2(43,y),Vector2(917,y),Color("987e5d"),1)
 for id:int in 2:
  var p:=pointer if held_card==id else card_position(id)
  draw_rect(Rect2(p-Vector2(102,35),Vector2(204,70)),PAPER);_pattern(Model.VECTORS[id],p-Vector2(73,0))
  var r:Dictionary=model.receipts.get(id,{})
  if not r.is_empty():_text("○" if r.passed else "×",p+Vector2(83,29),17)
 draw_rect(Rect2(330,95,310,105),Color("d5cdb6"));_text("输入原卡",Vector2(344,119),14);_pattern(model.original(),Vector2(382,151),1.2)
 draw_rect(Rect2(330,212,310,93),Color("536c6d"));_text("当前纸带",Vector2(344,233),14,PAPER)
 _pattern(model.work if model.work.size()==4 else Model.forward(model.original()),Vector2(382,268),1.2)
 # A permanent forward machine specimen supplies observable step examples.
 draw_rect(Rect2(665,104,229,124),PAPER)
 var sample:Array=[0,2,4,6]
 _pattern(sample,Vector2(686,125),.65)
 for op:int in 3:
  sample=Model.transform(sample,[0,2,3][op]);_pattern(sample,Vector2(686,151+op*24),.65)
 # The physical history strip can be turned to inspect every intermediate frame.
 draw_rect(Rect2(660,235,180,96),PAPER)
 if not model.frames.is_empty():
  var page:int=frame_cursor%model.frames.size()
  for row:int in mini(3,model.frames.size()-page):
   _text(str(page+row),Vector2(668,258+row*26),12)
   _pattern(model.frames[page+row],Vector2(699,253+row*26),.62)
 draw_line(Vector2(818,313),Vector2(837,329),INK,2)
 draw_line(Vector2(95,373),Vector2(817,373),INK,9)
 for i:int in 8:draw_rect(Rect2(socket(i)-Vector2(32,28),Vector2(64,56)),Color("685e4d"))
 for i:int in 8:
  if held!=i:_module(i,module_position(i))
 if held>=0:_module(held,pointer)
 if model.running and model.step_index<model.chain.size():draw_arc(socket(model.step_index),37,0,TAU,32,PAPER,2)
 draw_circle(Vector2(870,280),28,INK);draw_line(Vector2(870,280),Vector2(886,260),PAPER,6);draw_circle(Vector2(886,260),9,Color("b79b73"))
 draw_arc(Vector2(870,470),17,.4,5.7,24,PAPER,5)
 if model.frames.size()>1:
  var last:Array=model.frames.back();_pattern(last,Vector2(380,325),.55)
 _text("观察便笺",Vector2(46,533),14,PAPER)
 if paper_open:_text(HINTS[hint_level],Vector2(215,532),15,PAPER)
 elif not model.outcome.is_empty():_text(model.outcome,Vector2(315,532),15,PAPER)
