extends Control
signal closed
const Model=preload("res://campuses/future_learning_center/scripts/puzzles/koala_model.gd")
const INK:=Color("29373b")
const PAPER:=Color("e7e1cf")
const INPUT_CLAMP:=Rect2(60,105,260,100)
const NOTEBOOK:=Rect2(535,120,120,76)
const NOTE_PAGE:=Rect2(785,388,88,48)
const CRANK:=Vector2(870,270)
const UNDO:=Vector2(870,480)
const CHAIN_ZONE:=Rect2(80,233,755,76)
const RACK_ZONE:=Rect2(80,436,755,78)
const GOAL_ORIGIN:=Vector2(302,390)
const OUTPUT_ORIGIN:=Vector2(577,390)
var model=Model.new()
var font:Font
var held:=-1
var held_card:=-1
var touch_id:=-1
var pointer:=Vector2.ZERO
var origin:=Vector2.ZERO
var grab_offset:=Vector2.ZERO
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
func socket(index:int)->Vector2:return Vector2(130+index*90,270)
func module_position(id:int)->Vector2:
 var index:int=model.chain.find(id)
 return socket(index) if index>=0 else Vector2(130+id*90,480)
func card_position(id:int)->Vector2:return Vector2(735+id*110,155)
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
 elif e is InputEventScreenDrag and e.index==touch_id:move_at(e.position);accept_event()
 elif e is InputEventMouse and e.device==InputEvent.DEVICE_ID_EMULATION:return
 elif e is InputEventMouseButton and touch_id<0 and e.button_index==MOUSE_BUTTON_LEFT:
  if e.pressed:press_at(e.position)
  else:release_at(e.position)
  accept_event()
 elif e is InputEventMouseMotion and touch_id<0:move_at(e.position)
 elif e is InputEventKey and e.pressed and e.keycode==KEY_ESCAPE:close();accept_event()
func press_at(at:Vector2)->void:
 pointer=at;origin=at
 if Rect2(880,15,60,50).has_point(at):close();return
 if paper_open:
  if NOTE_PAGE.has_point(at):frame_cursor+=4;hint_level=(hint_level+1)%3
  else:paper_open=false
  queue_redraw();return
 if NOTEBOOK.has_point(at):paper_open=true;cancel_pointer();queue_redraw();return
 if at.distance_to(UNDO)<26:model.undo();return
 if at.distance_to(CRANK)<35:
  if model.paused:model.resume()
  else:model.start()
  return
 for i:int in 2:
  if Rect2(card_position(i)-Vector2(43,36),Vector2(86,72)).has_point(at):held_card=i;grab_offset=at-card_position(i);return
 for i:int in 8:
  if at.distance_to(module_position(i))<31:held=i;grab_offset=at-module_position(i);return
 # Editing belongs to the original target card, never the transformed input.
 for i:int in 4:
  if Rect2(GOAL_ORIGIN+Vector2(i*48-23,-27),Vector2(46,54)).has_point(at):model.edit_token(i,at.y>GOAL_ORIGIN.y);return
func move_at(at:Vector2)->void:
 pointer=at;queue_redraw()
func held_center()->Vector2:return pointer-grab_offset
func release_at(at:Vector2)->void:
 # Release never moves the object; only the last visible pose may be committed.
 if at.distance_to(pointer)>12:cancel_pointer();return
 var center:=held_center()
 if held_card>=0:
  if center.distance_to(INPUT_CLAMP.get_center())<=24:model.insert_card(held_card)
  held_card=-1;queue_redraw();return
 if held<0:return
 var id:=held;held=-1
 if CHAIN_ZONE.has_point(center):
  var index:=clampi(roundi((center.x-130)/90),0,model.chain.size())
  if center.distance_to(socket(index))<=20:model.attach(id,index)
 elif center.distance_to(Vector2(130+id*90,480))<=20:model.attach(id,-1)
 queue_redraw()
func output_is_current()->bool:
 return not model.frames.is_empty() and model.trial_revision==model.revision and model.trial_card==model.card and model.frames[0]==Model.forward(model.original())
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
func _card(id:int,at:Vector2)->void:
 draw_rect(Rect2(at-Vector2(43,36)+Vector2(3,4),Vector2(86,72)),INK)
 draw_rect(Rect2(at-Vector2(43,36),Vector2(86,72)),PAPER)
 _text("试样 "+("A" if id==0 else "B"),at+Vector2(-27,-13),15)
 _pattern(Model.VECTORS[id],at+Vector2(-27,12),.375)
 var receipt:Dictionary=model.receipts.get(id,{})
 if not receipt.is_empty():_text("○" if receipt.passed else "×",at+Vector2(23,33),13)
func _draw()->void:
 if font==null:return
 draw_rect(Rect2(0,0,960,540),INK)
 _text("考拉工作室 · 把变化倒过来",Vector2(32,37),22,PAPER)
 _text("接好模块，让输出与原图一致。",Vector2(33,66),16,Color("bdc8c2"))
 _text("×",Vector2(898,47),28,PAPER)
 draw_rect(Rect2(35,87,890,430),Color("a48d6c"))
 for y:int in range(105,515,30):draw_line(Vector2(43,y),Vector2(917,y),Color("987e5d"),1)
 # The encoded card is the only input image; its paper is physically clamped.
 draw_rect(INPUT_CLAMP,PAPER)
 _text("待还原图案",Vector2(76,128),16)
 _pattern(Model.forward(model.original()),Vector2(91,165),1.16)
 draw_rect(Rect2(174,99,31,12),Color("738782"));draw_line(Vector2(179,102),Vector2(200,102),PAPER,2)
 _text("试样 A" if model.card==0 else ("试样 B" if model.card==1 else "自设图案"),Vector2(233,196),13)
 # Spare originals read as labelled cards, not two competing result panels.
 for id:int in 2:
  if held_card==id:continue
  _card(id,card_position(id))
 _text("换卡试验",Vector2(747,214),13)
 # Closed notebook keeps examples and every intermediate result off the main task.
 draw_rect(NOTEBOOK,Color("687d75"));draw_line(Vector2(545,124),Vector2(545,192),PAPER,2)
 _text("试验笔记",Vector2(557,153),16,PAPER);_text("翻看过程",Vector2(560,177),13,PAPER)
 # A bent paper guide links input to the left end of the physical pipeline.
 draw_polyline(PackedVector2Array([Vector2(190,205),Vector2(190,220),Vector2(95,220),Vector2(95,270)]),INK,3)
 draw_line(Vector2(95,270),Vector2(817,270),INK,8)
 for i:int in 8:
  draw_rect(Rect2(socket(i)-Vector2(32,28),Vector2(64,56)),Color("786950"))
  if i<7:
   var p:=socket(i)+Vector2(44,0);draw_line(p-Vector2(5,5),p,Color("d8ccb1"),2);draw_line(p-Vector2(5,-5),p,Color("d8ccb1"),2)
 for i:int in 8:
  if held!=i:_module(i,module_position(i))
 if model.running and model.step_index<model.chain.size():draw_arc(socket(model.step_index),36,0,TAU,32,PAPER,2)
 draw_circle(CRANK,28,INK);draw_line(CRANK,CRANK+Vector2(16,-20),PAPER,6);draw_circle(CRANK+Vector2(16,-20),9,Color("b79b73"))
 _text("摇柄",CRANK+Vector2(-15,48),13)
 draw_polyline(PackedVector2Array([Vector2(817,270),Vector2(817,334),Vector2(652,334),Vector2(652,345)]),INK,3)
 # Comparison is adjacent, uses identical token scale and one shared baseline.
 draw_rect(Rect2(268,344,223,73),PAPER);draw_rect(Rect2(543,344,223,73),PAPER)
 _text("原图",Vector2(283,365),15);_text("本次输出",Vector2(558,365),15)
 _pattern(model.original(),GOAL_ORIGIN,1)
 if output_is_current():_pattern(model.work,OUTPUT_ORIGIN,1)
 else:
  for i:int in 4:draw_line(OUTPUT_ORIGIN+Vector2(i*48-9,0),OUTPUT_ORIGIN+Vector2(i*48+9,0),Color("b5b19f"),2)
 if model.running:_text("模块 %d / %d"%[mini(model.step_index+1,model.chain.size()),model.chain.size()],Vector2(565,434),14)
 elif output_is_current() and not model.outcome.is_empty():_text(model.outcome,Vector2(530,434),14)
 _text("备用模块",Vector2(81,432),14)
 draw_arc(UNDO,17,.4,5.7,24,PAPER,5)
 if held>=0:_module(held,held_center())
 if held_card>=0:_card(held_card,held_center())
 if paper_open:_draw_notebook()
func _draw_notebook()->void:
 draw_rect(Rect2(69,104,817,342),INK);draw_rect(Rect2(65,100,817,342),PAPER)
 draw_line(Vector2(472,114),Vector2(472,426),Color("b5ac95"),2)
 _text("原机留下的变化",Vector2(94,135),20)
 var sample:Array=[0,2,4,6]
 _pattern(sample,Vector2(224,173),.9)
 for i:int in 3:
  draw_set_transform(Vector2(146,221+i*51),0,Vector2(.58,.58));_module([0,4,5][i],Vector2.ZERO);draw_set_transform(Vector2.ZERO)
  sample=Model.transform(sample,[0,2,3][i]);_pattern(sample,Vector2(224,221+i*51),.9)
 _text("实际试验纸带" if output_is_current() else "上次试验纸带",Vector2(499,135),20)
 if model.frames.is_empty():_text("摇动把手后，过程留在这里。",Vector2(503,184),16)
 else:
  var page:int=frame_cursor%model.frames.size()
  for row:int in mini(4,model.frames.size()-page):
   var index:=page+row
   _text("输入" if index==0 else str(index),Vector2(503,180+row*50),14)
   _pattern(model.frames[index],Vector2(568,176+row*50),.9)
 _text(HINTS[hint_level],Vector2(93,405),15)
 draw_line(Vector2(818,432),Vector2(878,389),INK,2);_text("翻页",Vector2(817,412),14)
