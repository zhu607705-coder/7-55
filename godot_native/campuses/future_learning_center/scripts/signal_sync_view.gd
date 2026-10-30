extends "res://campuses/future_learning_center/scripts/physical_bench.gd"
const Model=preload("res://campuses/future_learning_center/scripts/signal_sync_model.gd")
const PORTS:={"live":Vector2(263,180),"cached":Vector2(263,320),"split":Vector2(343,278),"split_a":Vector2(512,239),"split_b":Vector2(512,316),"left":Vector2(550,180),"right":Vector2(550,320)}
const PORT_ORDER:=["live","cached","split","split_a","split_b","left","right"]
const HINTS:=["比较源端改动之后，两台屏幕哪一处没有跟着变。","只改一个角标，沿着接线观察这次变化到哪里停住。","对照修改便条与回放盒的接收记录，看看它们记录的是哪一次稿件。"]
var model=Model.new()
var monitor:Texture2D
var selected:=""
var drag_output:=""
var drag_input:=""
var card:=-1
var swapped:=false
var drag_screen:=""
var previous_state:=""
var receive_age:={"left":10.0,"right":10.0}
var previous_display:={"left":-2,"right":-2}

func _ready()->void:
 super._ready()
 monitor=_load_texture("res://campuses/future_learning_center/assets/objects/monitor_front.png")
func open()->void:
 bench_mode="signal";selected="";book_open=false;book_page=0;previous_state="";cancel_gesture();clear_motion();show()
 notice("让两台屏幕跟随同一份修改稿。")
 queue_redraw()
func close()->void:model.cancel();drag_output="";super.close()
func _lost_focus()->void:model.cancel();drag_output="";drag_input=""
func _port_position(id:String)->Vector2:
 var at:Vector2=PORTS["right" if id=="left" else "left"] if swapped and id in ["left","right"] else PORTS[id]
 return at+receiver_drag_offset() if gesture=="screen" and id==drag_screen else at
func receiver_drag_offset()->Vector2:
 return (pointer-press_at).clamp(Vector2(-160,-170),Vector2(160,170)) if gesture=="screen" else Vector2.ZERO
func receiver_at(id:String,preview:=true)->Vector2:
 var y:float=PORTS["right" if id=="left" else "left"].y if swapped else PORTS[id].y
 var at:=Vector2(577,112 if y<250 else 252)
 return at+receiver_drag_offset() if preview and gesture=="screen" and id==drag_screen else at
func _lever_live()->bool:return model.running
func _assembly_stamp()->String:return str([model.wires,model.source_pattern,swapped])
func _lever_action(offset:float)->void:
 if offset< -20:model.transmit()
 elif offset>20:model.reset();notice("接线回到原始摆位。")
 else:model.cancel();notice("本次传送已停下，接线保留。")
func _undo()->void:
 model.undo();selected="";drag_output="";notice("已撤回上一处接线。")
func _book_lines()->Array[String]:
 return ["修改便条",HINTS[book_page-1]] if book_page>0 else ["试用记录","回放盒保留旧角标。源端改稿后，两边都应跟着变。翻页看线索。"]
func _process(dt:float)->void:
 if not visible:return
 _tick_shell(dt);model.step(minf(dt,.1))
 for id:String in ["left","right"]:
  if previous_display[id]!=model.displayed[id]:receive_age[id]=0.0;previous_display[id]=model.displayed[id]
  else:receive_age[id]+=dt
 if model.outcome!=previous_state:
  previous_state=model.outcome
  if model.outcome in ["one_change","passed","mismatch"]:notice(model.message())
 queue_redraw()
func _keyboard(event:InputEventKey)->bool:
 match event.keycode:
  KEY_SPACE:model.change_pattern()
  KEY_Z:_undo()
  KEY_X:if selected in Model.INPUTS:model.disconnect_port(selected)
  KEY_H:book_open=true;book_page=mini(3,maxi(1,book_page+1))
  KEY_1,KEY_2,KEY_3,KEY_4,KEY_5,KEY_6,KEY_7:_port(PORT_ORDER[int(event.keycode)-int(KEY_1)])
  _:return false
 return true
func _port(id:String)->void:
 if selected in Model.OUTPUTS and id in Model.INPUTS:model.connect_ports(selected,id);selected=""
 elif selected in Model.INPUTS and id in Model.OUTPUTS:model.connect_ports(id,selected);selected=""
 else:selected=id
func _object_press(at:Vector2)->void:
 for id:String in PORT_ORDER:
  if at.distance_to(_port_position(id))<25:
   gesture="wire";drag_input=id if id in Model.INPUTS else ""
   drag_output=id if id in Model.OUTPUTS else str(model.wires.get(id,""));return
 for i:int in 3:
  var id:="card%d"%i
  if Rect2(part_at(id,Vector2(91+i*93,374))-Vector2(4,4),Vector2(77,57)).has_point(at):gesture="card";card=i;returns.erase(id);return
 for id:String in ["left","right"]:
  var top:=receiver_at(id,false)
  if Rect2(top+Vector2(0,1),Vector2(184,82)).grow(5).has_point(at) or Rect2(top+Vector2(58,86),Vector2(68,21)).grow(8).has_point(at):drag_screen=id;gesture="screen";return
func _object_release(at:Vector2,cancelled:bool)->void:
 if cancelled:
  if gesture=="card":return_part("card%d"%card,pointer-Vector2(25,50),Vector2(91+93*card,374))
  drag_output="";drag_input="";return
 if gesture=="wire":
  var target:=""
  for id:String in PORT_ORDER:
   if at.distance_to(_port_position(id))<27:target=id;break
  if at.distance_to(press_at)<10:
   if not target.is_empty():_port(target)
  elif target in Model.INPUTS and not drag_output.is_empty():model.connect_ports(drag_output,target);selected=""
  elif target in Model.OUTPUTS and not drag_input.is_empty():model.connect_ports(target,drag_input);selected=""
  elif target.is_empty() and not drag_input.is_empty():model.disconnect_port(drag_input);selected=""
  else:notice("把插头放进另一端插座；放回原位会保留接线。")
 elif gesture=="card":
  if Rect2(42,108,194,124).has_point(at):
   if not model.apply_pattern(card):notice("选择一张不同的角标稿，等本次传送结束再改。")
  else:notice("把角标稿放到左上方正在编辑的屏幕里。");return_part("card%d"%card,pointer-Vector2(25,50),Vector2(91+93*card,374))
 elif gesture=="screen" and at.distance_to(press_at)>35:
  var other:String="right" if drag_screen=="left" else "left"
  if Rect2(receiver_at(other,false),Vector2(184,134)).grow(12).has_point(at):swapped=not swapped
 drag_output="";drag_input="";drag_screen=""
func _draw()->void:
 if font==null:return
 draw_table("两台屏幕，两个版本")
 ink("当前编辑稿",Vector2(46,102),18);ink("片段回放",Vector2(46,242),18)
 for id:String in ["left","right"]:
  var label_at:Vector2=receiver_at(id)+Vector2(4,-10)
  var covered:=gesture=="screen" and id!=drag_screen and Rect2(receiver_at(drag_screen),Vector2(184,105)).grow(5).intersects(Rect2(label_at-Vector2(0,20),Vector2(100,24)))
  if not covered:ink("接收屏甲" if id=="left" else "接收屏乙",label_at,18)
 ink("分配盒",Vector2(401,301),18,Color("f4eddb"))
 draw_tools();draw_book()

static func mini(canvas:CanvasItem,bounds:Rect2,value:int)->void:
 var factor:float=bounds.size.x/864.0
 var screen:=Rect2(bounds.position+Vector2(30,34)*factor,Vector2(803,332)*factor)
 canvas.draw_rect(screen,Color("202b35"))
 if value<0:return
 var patterns:Array=[[0,1,4,7],[0,3,4,5],[1,2,4,7]]
 var color:Color=[Color("c79b62"),Color("83a7b6"),Color("bfd0b7")][value]
 var cell:float=screen.size.y/4.0
 for i:int in patterns[value]:canvas.draw_rect(Rect2(screen.position+Vector2(3+(i%3)*cell,2+floorf(i/3.0)*cell),Vector2.ONE*(cell-1)),color)
