extends "res://campuses/future_learning_center/scripts/physical_bench.gd"
## Physical parts and handles share the same pointer/touch ownership contract.
const Model=preload("res://campuses/future_learning_center/scripts/workbench_model.gd")
const MOTOR:=Vector2(262,205)
const AXLE:=Vector2(350,205)
const OUTPUT:=Vector2(650,205)
const TENSION:=Vector2(610,386)
const TARGET_FLAG:=Vector2(735,293)
var model=Model.new()
var drag:=-1
var preview_tension:=0
var previous_outcome:=""
var last_gear:=-1
var last_belt:=0
func _ready()->void:super._ready()
func _input(event:InputEvent)->void:
 # Keep the external physical bench, with the proven real-touch ownership guards.
 if event is InputEventMouse and (event.device==InputEvent.DEVICE_ID_EMULATION or pointer_owner>=0):return
 var local_event:InputEvent=event
 if event is InputEventMouse or event is InputEventScreenTouch or event is InputEventScreenDrag:
  local_event=event.duplicate();local_event.position=get_global_transform_with_canvas().affine_inverse()*event.position
 if local_event is InputEventScreenTouch and local_event.canceled:
  if local_event.index==pointer_owner:_release(local_event.position,true);get_viewport().set_input_as_handled()
  return
 super._input(local_event)
func open()->void:
 bench_mode="mechanical";book_open=false;book_page=0;cancel_gesture();clear_motion();show();notice("把试件送到白色刻线；翻转目标标牌可试反方向。")
func close()->void:model.cancel();drag=-1;super.close()
func _lost_focus()->void:model.cancel();drag=-1
func _lever_live()->bool:return model.running
func _assembly_stamp()->String:return str([model.gear,model.belt,model.tension,model.reverse_target])
func _seat_anchor(at:Vector2)->Vector2:
 return AXLE if gesture=="gear" else (Vector2(505,205) if gesture in ["belt","twist"] else at)
func _lever_action(offset:float)->void:
 if offset< -20:model.start()
 elif offset>20:model.return_to_start();notice("试件归位，装好的零件保留。")
 else:model.cancel();notice("电机已停下。")
func _undo()->void:
 notice("已撤回上一次装配。" if model.undo() else "还没有可以撤回的装配。")
func _process(dt:float)->void:
 if not visible:return
 _tick_shell(dt);model.step(minf(dt,.1))
 if model.outcome!=previous_outcome:
  previous_outcome=model.outcome
  if not previous_outcome.is_empty():notice(model.message())
  if previous_outcome in ["gear_large","tight"]:cue("brake",AXLE)
 queue_redraw()
func _keyboard(event:InputEventKey)->bool:
 match event.keycode:
  KEY_1,KEY_2,KEY_3:model.edit("gear",int(event.keycode)-int(KEY_1))
  KEY_B:model.edit("belt",2 if model.belt==1 else 1)
  KEY_T:model.edit("tension",(model.tension+1)%3)
  KEY_SPACE:model.start()
  KEY_R:model.reset()
  KEY_H:book_open=true;book_page=mini(3,maxi(1,book_page+1))
  _:return false
 return true
func _object_press(at:Vector2)->void:
 if model.running:notice("先把操纵杆拉回中位，再装配。");return
 if at.distance_to(TARGET_FLAG)<25:gesture="target";return
 for i:int in 3:
  var id:="gear%d"%i
  if at.distance_to(part_at(id,Vector2(142+96*i,387)))<maxf(30,Model.RADII[i]*.6):gesture="gear";drag=i;returns.erase(id);return
 if at.distance_to(TENSION)<33:gesture="tension";preview_tension=model.tension
 elif Rect2(405,160,206,75).has_point(at) and model.belt>0:gesture="twist"
 else:
  for i:int in 2:
   var id:="belt%d"%(i+1)
   if at.distance_to(part_at(id,Vector2(705+i*55,331)))<28:gesture="belt";drag=i+1;returns.erase(id);return
func _object_move(at:Vector2)->void:
 if gesture=="tension":
  var v:=at-TENSION
  preview_tension=0 if v.x< -10 else (2 if v.x>10 else 1)
func _object_release(at:Vector2,cancelled:bool)->void:
 if cancelled:
  if gesture=="gear":return_part("gear%d"%drag,pointer-Vector2(0,20),Vector2(142+96*drag,387))
  elif gesture=="belt":return_part("belt%d"%drag,pointer-Vector2(0,20),Vector2(705+55*(drag-1),331))
  drag=-1;return
 if gesture=="target" and at.distance_to(TARGET_FLAG)<25 and at.distance_to(press_at)<12:
  model.set_reverse(not model.reverse_target);notice("目标已移到左刻线。" if model.reverse_target else "目标已移到右刻线。")
 elif gesture=="gear":
  if at.distance_to(AXLE)<68:model.edit("gear",drag)
  else:notice("把齿轮放到中间的空轴位。");return_part("gear%d"%drag,pointer-Vector2(0,20),Vector2(142+96*drag,387))
 elif gesture=="tension" and at.distance_to(press_at)>8 and at.distance_to(TENSION)<95:model.edit("tension",preview_tension)
 elif gesture=="belt":
  if Rect2(400,155,280,105).has_point(at):model.edit("belt",drag)
  else:notice("把皮带套到中间轴与右侧送料轴上。");return_part("belt%d"%drag,pointer-Vector2(0,20),Vector2(705+55*(drag-1),331))
 elif gesture=="twist" and at.distance_to(press_at)>15:model.edit("belt",2 if model.belt==1 else 1)
 drag=-1
func _book_lines()->Array[String]:
 if book_page==0:return ["装配记录","先看动力停在哪一件零件上，再换一处试转。翻页看现场线索。"]
 return ["现场笔记",["中间齿轮怎样才能同时接住两端？","轮子转了，送料块没动，观察皮带有没有打滑。","对照两根轴的转向，再看皮带两边的绕法。"][book_page-1]]
func text_at(value:String,at:Vector2,size_value:=20,color:=Color("e8e0c8"))->void:ink(value,at,size_value,color)
static func gear_at(canvas:CanvasItem,center:Vector2,radius:float,phase:float,color:Color)->void:
 var poly:=PackedVector2Array()
 for i:int in 80:
  var angle:=phase+TAU*i/80.0;var r:=radius*(1.0 if i%4 in [0,1] else .84)
  poly.append(center+Plane45.offset(cos(angle)*r,sin(angle)*r))
 var side:=PackedVector2Array()
 for point:Vector2 in poly:side.append(point+Vector2(0,4))
 canvas.draw_colored_polygon(side,Color("101820"))
 canvas.draw_colored_polygon(poly,Color("202b35"))
 var inner:=PackedVector2Array()
 for i:int in 80:inner.append(center+(poly[i]-center)*.9)
 canvas.draw_colored_polygon(inner,color)
 canvas.draw_line(center,center+Plane45.offset(cos(phase)*radius*.65,sin(phase)*radius*.65),Color("e8e0c8"),3)
 canvas.draw_circle(center,5,Color("202b35"));canvas.draw_circle(center,2,Color("c5c1a9"))
static func mini(canvas:CanvasItem,at:Vector2,scale_value:float,model_state:RefCounted)->void:
 canvas.draw_set_transform(at,0,Vector2.ONE*scale_value)
 canvas.draw_colored_polygon(PackedVector2Array([Vector2(6,0),Vector2(204,0),Vector2(210,44),Vector2(0,44)]),Color("344452"))
 gear_at(canvas,Vector2(32,22),22,model_state.motor_phase,Color("c79b62"))
 if model_state.gear>=0:gear_at(canvas,Vector2(76,22),Model.RADII[model_state.gear]*.5,model_state.gear_phase,Color("83a7b6"))
 else:canvas.draw_circle(Vector2(76,22),4,Color("e8e0c8"))
 if model_state.belt>0:
  canvas.draw_line(Vector2(76,13),Vector2(171,31 if model_state.belt==2 else 13),Color("c5c1a9"),3)
  canvas.draw_line(Vector2(76,31),Vector2(171,13 if model_state.belt==2 else 31),Color("c5c1a9"),3)
 gear_at(canvas,Vector2(171,22),22,model_state.output_phase,Color("7993a1"))
 canvas.draw_set_transform(Vector2.ZERO)
func draw_table(title:String)->void:
 # Reuse the external 3D tray/materials; only reposition its actual goal stripe.
 miniature.present(self,bench_mode)
 var marker:=647.0 if model.reverse_target else 796.0
 miniature.line("target",Vector2(marker,248),Vector2(marker,289),1.6,miniature.IVORY,10)
 miniature.pad("direction_flag",TARGET_FLAG,Vector2(76,25),miniature.TEAL,5)
 var direction:float=-1.0 if model.reverse_target else 1.0
 var tip:=TARGET_FLAG+Vector2(23*direction,0)
 miniature.line("flag_arrow",TARGET_FLAG-Vector2(23*direction,0),tip,1.6,miniature.IVORY,11)
 miniature.line("flag_tip_a",tip,tip+Vector2(-8*direction,-5),1.6,miniature.IVORY,11)
 miniature.line("flag_tip_b",tip,tip+Vector2(-8*direction,5),1.6,miniature.IVORY,11)
 draw_texture_rect(miniature.texture(),Rect2(0,0,960,540),false)
 ink(title,Vector2(32,39),24)
func _draw()->void:
 if font==null:return
 draw_table("动力停在哪")
 ink("电机",Vector2(208,153),18);ink("装配轴",Vector2(328,153),18)
 ink("送料轴",Vector2(625,153),18);ink("皮带张紧",TENSION+Vector2(-35,44),18)
 for i:int in 3:ink(["小轮","中轮","大轮"][i],Vector2(124+i*96,431),17)
 ApparatusStyle.grip(self,TENSION,"rotate",gesture=="tension")
 for i:int in 3:ApparatusStyle.grip(self,pointer-Vector2(0,20) if gesture=="gear" and drag==i else part_at("gear%d"%i,Vector2(142+96*i,387)),"drag",gesture=="gear" and drag==i)
 if gesture=="gear":ApparatusStyle.target(self,Rect2(AXLE-Vector2(40,40),Vector2(80,80)))
 elif gesture=="belt":ApparatusStyle.target(self,Rect2(400,155,280,105))
 draw_tools();draw_book();draw_feedback()
func _box(color:Color)->StyleBoxFlat:
 var result:=StyleBoxFlat.new();result.bg_color=color;result.border_color=Color("526b7a");result.set_border_width_all(1);return result
