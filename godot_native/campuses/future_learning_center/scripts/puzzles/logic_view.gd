extends Control
const ApparatusStyle=preload("res://campuses/future_learning_center/scripts/apparatus_style.gd")
signal closed
const Model=preload("res://campuses/future_learning_center/scripts/puzzles/logic_model.gd")
const TRAYS:=[Vector2(300,455),Vector2(440,455),Vector2(580,455)]
const SLOT:=Rect2(195,180,160,185)
var model=Model.new()
var font:Font
var drag:=""
var selected:=""
var touch_id:=-1
var pointer:=Vector2.ZERO
var down:=Vector2.ZERO
var hints:=-1
var records:=false
const HELP:=["夹爪合拢时，试件哪里真正接触了实验座？","保持走线不动，比较空台、单处和双处接触。","对照接触痕迹与抓空记录，看看缺少哪一处。"]
func _ready()->void:
 ApparatusStyle.configure_exit(self,close)
 font=ApparatusStyle.font();mouse_filter=MOUSE_FILTER_STOP;hide()
func open()->void:show();queue_redraw()
func close()->void:model.cancel();cancel_pointer();hide();closed.emit()
func cancel_pointer()->void:drag="";selected="";touch_id=-1
func _notification(what:int)->void:
 if what in [NOTIFICATION_APPLICATION_FOCUS_OUT,NOTIFICATION_APPLICATION_PAUSED]:model.pause();cancel_pointer()
func _process(dt:float)->void:
 if visible:model.step(dt);queue_redraw()
func _input(e:InputEvent)->void:
 if ApparatusStyle.navigation_event(self,e):return
 if not visible:return
 if e is InputEventKey and e.pressed and e.keycode==KEY_ESCAPE:close();get_viewport().set_input_as_handled()
 elif e is InputEventMouseButton and e.button_index==MOUSE_BUTTON_LEFT:
  if touch_id>=0 or e.device==InputEvent.DEVICE_ID_EMULATION:return
  if e.pressed:press(get_global_transform_with_canvas().affine_inverse()*e.position)
  else:release(get_global_transform_with_canvas().affine_inverse()*e.position)
  get_viewport().set_input_as_handled()
 elif e is InputEventMouseMotion and touch_id<0:pointer=get_global_transform_with_canvas().affine_inverse()*e.position
 elif e is InputEventScreenTouch:
  if e.index==touch_id and e.canceled:cancel_pointer()
  elif e.pressed and not e.canceled and touch_id<0:touch_id=e.index;press(get_global_transform_with_canvas().affine_inverse()*e.position)
  elif not e.pressed and touch_id==e.index:
   if e.canceled:cancel_pointer()
   else:release(get_global_transform_with_canvas().affine_inverse()*e.position);touch_id=-1
  get_viewport().set_input_as_handled()
 elif e is InputEventScreenDrag and e.index==touch_id:pointer=get_global_transform_with_canvas().affine_inverse()*e.position;get_viewport().set_input_as_handled()
func block_at(i:int)->Vector2:return model.position if model.block==i else TRAYS[i]
func press(at:Vector2)->void:
 down=at;pointer=at;drag=""
 if Rect2(35,423,150,80).has_point(at):drag="help";return
 if Rect2(755,305,170,190).has_point(at):drag="records";return
 if model.paused:drag="resume";return
 if model.running:return
 for i:int in 3:
  if Rect2(block_at(i)+Model.SHAPES[i].position,Model.SHAPES[i].size).grow(12).has_point(at):drag="block%d"%i;return
  if Rect2(35,120+i*95,120,78).has_point(at):drag="card%d"%i;return
 if SLOT.has_point(at) and model.card>=0:drag="card%d"%model.card;return
 if at.distance_to(Vector2(680,335))<35:drag="trial";return
 if Rect2(720,155,180,95).has_point(at):drag="swap";return
 if not selected.is_empty():drag=selected
func release(at:Vector2)->void:
 pointer=at
 if drag.begins_with("card"):
  if SLOT.has_point(at):model.install(int(drag.right(1)));selected=""
  elif at.distance_to(down)<8:selected=drag
  elif at.x<170:model.install(-1);selected=""
 elif drag.begins_with("block"):
  if Rect2(390,210,230,190).has_point(at):model.place(int(drag.right(1)),at);selected=""
  elif at.y>400 and model.block==int(drag.right(1)):model.place(-1,Vector2(500,300));selected=""
  elif at.distance_to(down)<8:selected=drag
 elif at.distance_to(down)<18:
  match drag:
   "close":close()
   "help":hints=(hints+1)%4;if hints==3:hints=-1
   "records":records=not records
   "trial":model.start()
   "swap":model.exchange_inputs()
   "resume":model.resume()
 drag="";queue_redraw()
func txt(s:String,p:Vector2,n:=16,c:=Color("e2dfd2"))->void:draw_string(font,p,s,HORIZONTAL_ALIGNMENT_LEFT,-1,n,c)
func slab(r:Rect2,c:Color)->void:
 draw_rect(Rect2(r.position+Vector2(0,7),r.size),Color("28343a"));draw_rect(r,c);draw_rect(r,Color("384349"),false,2)
 draw_line(r.position+Vector2(2,2),r.position+Vector2(r.size.x-2,2),c.lightened(.15),2)
func circuit(at:Vector2,which:int,scale_value:float)->void:
 var nodes:=[Vector2(8,33),Vector2(55,13),Vector2(100,33),Vector2(55,53)]
 for edge_index:int in Model.NETWORKS[which].size():
  var edge:Array=Model.NETWORKS[which][edge_index]
  var a:Vector2=at+nodes[edge[0]]*scale_value;var b:Vector2=at+nodes[edge[1]]*scale_value
  var offset:=Vector2(0,(-16 if edge_index==0 else 16)*scale_value) if which==1 else Vector2.ZERO
  var branch_a:=a+offset;var branch_b:=b+offset
  draw_line(a,branch_a,Color("c7b485"),3);draw_line(branch_b,b,Color("c7b485"),3)
  a=branch_a;b=branch_b
  var mid:Vector2=(a+b)/2
  draw_line(a,mid,Color("c7b485"),3);draw_line(mid+Vector2(8,-6),b,Color("c7b485"),3)
  draw_circle(mid,4,Color("34454b"));txt("A" if edge[2]==0 else "B",mid+Vector2(-4,-8),12)
 for p:Vector2 in nodes:draw_circle(at+p*scale_value,4,Color("d5d6cb"))
func _draw()->void:
 if font==null:return
 draw_rect(Rect2(0,0,960,540),Color("26323a"))
 txt("它为什么抓了个空",Vector2(34,38),22)
 if hints>=0:txt("试件靠近并被托住时，才允许夹持。",Vector2(34,64),15)
 slab(Rect2(25,90,910,320),Color("93836b"))
 for i:int in 3:
  slab(Rect2(35,120+i*95,120,78),Color("667773"));circuit(Vector2(40,125+i*95),i,1.0)
 txt("透明走线片",Vector2(40,113),13)
 slab(SLOT,Color("65736e"));txt("走线插座",Vector2(228,205),16)
 if model.card>=0:circuit(Vector2(202,245),model.card,1.35)
 else:txt("＋",Vector2(255,285),28)
 if drag.begins_with("card"):ApparatusStyle.target(self,SLOT,true)
 var inputs:=model.contacts()
 draw_line(Vector2(355,238),Vector2(430,268),Color("414f54"),5)
 draw_line(Vector2(355,325),Vector2(480,355),Color("414f54"),5)
 slab(Rect2(400,210,220,185),Color("b8b8a3"))
 draw_rect(Model.NEAR,Color("b8a26f") if inputs[0] else Color("677d7c"));draw_rect(Model.SUPPORT,Color("b8a26f") if inputs[1] else Color("677d7c"))
 txt("靠近",Vector2(396,202),14);txt("承托",Vector2(500,382),14)
 # Mechanical gripper fingers move inward; sensors and specimen remain visible.
 var inset:float=model.jaw*29
 slab(Rect2(415+model.jaw*13,220,12,62),Color("596a70"));slab(Rect2(580-inset,220,12,62),Color("596a70"))
 draw_line(Vector2(415,214),Vector2(594,214),Color("3d4c53"),10)
 for i:int in 3:
  var at:=pointer if drag=="block%d"%i else block_at(i)
  var shape:Rect2=Model.SHAPES[i]
  slab(Rect2(at+shape.position,shape.size),[Color("a49478"),Color("929e97"),Color("afa68b")][i])
  ApparatusStyle.grip(self,at,"drag",drag=="block%d"%i)
  txt(str(i+1),at+shape.position+Vector2(8,20),15,Color("26323a"))
 txt("试块托盘",Vector2(300,515),14)
 draw_circle(Vector2(680,335),29,Color("33444a"));draw_line(Vector2(680,340),Vector2(680,309 if model.running else 321),Color("d5d4c6"),7);draw_circle(Vector2(680,309 if model.running else 321),10,Color("a88c69"));txt("试夹",Vector2(663,382),14)
 ApparatusStyle.grip(self,Vector2(680,335),"press",model.running)
 slab(Rect2(720,155,180,95),Color("65736e"))
 draw_line(Vector2(755,180),Vector2(862,222 if model.swapped else 180),Color("b3c5c2"),4)
 draw_line(Vector2(755,222),Vector2(862,180 if model.swapped else 222),Color("b4a17b"),4)
 for pole:Vector2 in [Vector2(755,180),Vector2(755,222),Vector2(862,180),Vector2(862,222)]:
  slab(Rect2(pole-Vector2(9,9),Vector2(18,18)),Color("455a60"));draw_circle(pole,4,Color("c0c6b8"))
 txt("B  ↔  A" if model.swapped else "A  ↔  B",Vector2(757,145),16);txt("输入插头",Vector2(758,270),14)
 slab(Rect2(755,310,170,180),Color("d4cfb9"));txt("试夹记录",Vector2(772,337),18,Color("314249"))
 if records:
  var y:=364
  for key:String in model.receipts:
   var r:Dictionary=model.receipts[key]
   txt(key+"   "+("合拢" if r.output else "张开"),Vector2(772,y),15,Color("314249"));y+=26

 slab(Rect2(35,433,150,65),Color("d4cfb9"));txt("观察手册",Vector2(59,462),18,Color("314249"))
 if hints>=0:txt(HELP[hints],Vector2(195,105),16)
 if model.paused:txt("已暂停 · 触碰装置继续",Vector2(380,530),16)
 elif not model.outcome.is_empty():txt(model.outcome,Vector2(35,530),15)
 if model.completed:txt("四态已验证"+(" · 换线也成立" if model.transfer_completed else ""),Vector2(670,522),15)
 if drag.begins_with("card"):slab(Rect2(pointer-Vector2(60,35),Vector2(120,78)),Color("667773"));circuit(pointer-Vector2(55,30),int(drag.right(1)),1.0)
