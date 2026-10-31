extends Control
const ApparatusStyle=preload("res://campuses/future_learning_center/scripts/apparatus_style.gd")
signal closed
const Model=preload("res://campuses/future_learning_center/scripts/puzzles/solid_projection_model.gd")
const INK=ApparatusStyle.INK
const PAPER=ApparatusStyle.PAPER
const RACK:=[Vector2(125,180),Vector2(125,290),Vector2(125,400)]
var model=Model.new()
var font:Font
var held:=-1
var held_sheet:=false
var touch_id:=-1
var pending_touch_action:=""
var touch_press:=Vector2.ZERO
var pointer:=Vector2.ZERO
var paper_open:=false
var hint_level:=0
var angle:=0.0
var grab_offset:=Vector2.ZERO
var last_motion:=Vector2.ZERO
var pointer_valid:=true
const HINTS:=["哪张图能区分前后相叠的块？","底座缺口不变，只换一块的前后位置。","把三张图对照；上层也需要下方的实体支撑。"]
func _ready()->void:
 ApparatusStyle.configure_exit(self,close)
 mouse_filter=Control.MOUSE_FILTER_STOP;focus_mode=Control.FOCUS_ALL;font=ApparatusStyle.font();size=Vector2(960,540);hide()
func open()->void:show();model.resume();queue_redraw()
func close()->void:model.cancel();cancel_pointer();hide();closed.emit()
func cancel_pointer()->void:
 pending_touch_action="";_cancel_pointer_state()
func _cancel_pointer_state()->void:model.cancel_drag();held=-1;held_sheet=false;touch_id=-1;queue_redraw()
func _notification(what:int)->void:
 if what in [NOTIFICATION_APPLICATION_FOCUS_OUT,NOTIFICATION_APPLICATION_PAUSED]:model.pause();cancel_pointer()
func _process(dt:float)->void:
 if visible:
  if not model.paused and model.drag_piece<0:angle=move_toward(angle,model.observation*PI/2,minf(dt,.1)*PI)
  model.step(dt)
  if held>=0 and model.drag_stage in ["lift","carry"]:move_at(pointer)
  queue_redraw()
func project_point(p:Vector3)->Vector2:
 var x:=p.x-1;var y:=p.y-1;var a:=angle+PI/4
 return Vector2(445+(x*cos(a)-y*sin(a))*72,323+(x*sin(a)+y*cos(a))*32-p.z*57)
func slot_point(x:int,y:int)->Vector2:return project_point(Vector3(x+.5,y+.5,0))
func piece_position(piece:int)->Vector2:
 if piece==model.drag_piece:return project_point(model.preview_origin+piece_center_offset(piece))
 if model.poses[piece]==Model.TRAY:return RACK[piece]
 var p:=Vector3(model.poses[piece])+Vector3(.5,.5,.5)
 if piece==0:p+=Vector3(.5,0,0) if model.bar_turn==0 else Vector3(0,.5,0)
 return project_point(p)
func piece_center_offset(piece:int)->Vector3:
 return Vector3(.5,.5,.5)+(Vector3(.5,0,0) if model.bar_turn==0 else Vector3(0,.5,0)) if piece==0 else Vector3(.5,.5,.5)
func inverse_point(at:Vector2,z:float)->Vector3:
 var a:=angle+PI/4;var right:float=(at.x-445)/72;var depth:float=(at.y-323+z*57)/32
 return Vector3(1+right*cos(a)+depth*sin(a),1-right*sin(a)+depth*cos(a),z)
func move_at(at:Vector2)->void:
 pointer=at
 if held>=0:
  pointer_valid=Rect2(50,95,850,355).has_point(at)
  if pointer_valid and model.drag_stage in ["lift","carry"]:
   var offset:=piece_center_offset(held)
   var center:=inverse_point(at-grab_offset,model.preview_origin.z+offset.z)
   if model.move_drag(center-offset):last_motion=at
 queue_redraw()
func rotation_handle()->Vector2:return piece_position(0)+Vector2(0,-44)
func sheet_position()->Vector2:return Vector2(766,374) if model.extension else Vector2(620,475)
func _touch_action(at:Vector2)->String:
 if Rect2(45,470,145,42).has_point(at):return "paper"
 if at.distance_to(Vector2(240,490))<27:return "undo"
 if at.distance_to(Vector2(540,412))<28:return "holder"
 if at.distance_to(Vector2(830,470))<40:return "shutter"
 if Rect2(sheet_position()-Vector2(42,17),Vector2(84,34)).has_point(at):return ""
 if at.distance_to(rotation_handle())<19:return "bar"
 return ""
func _gui_input(e:InputEvent)->void:
 if not visible:return
 if e is InputEventScreenTouch:
  if e.index==touch_id and e.canceled:
   if pending_touch_action.is_empty():model.cancel()
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
 elif e is InputEventKey and e.pressed and e.keycode==KEY_ESCAPE:close();accept_event()
func press_at(at:Vector2)->void:
 pointer=at
 if Rect2(45,470,145,42).has_point(at):paper_open=not paper_open;hint_level=(hint_level+1)%3;return
 if at.distance_to(Vector2(240,490))<27:model.undo();return
 if at.distance_to(Vector2(540,412))<28:model.rotate_holder();return
 if at.distance_to(Vector2(830,470))<40:
  if model.paused:model.resume()
  else:model.start()
  return
 if Rect2(sheet_position()-Vector2(42,17),Vector2(84,34)).has_point(at):held_sheet=true;return
 if at.distance_to(rotation_handle())<19:model.rotate_bar();return
 for i:int in range(2,-1,-1):
  if at.distance_to(piece_position(i))<(55 if i==0 else 35):
   var center:=piece_position(i);var rack:=inverse_point(center,.5)-piece_center_offset(i)
   var lift:=inverse_point(center,2+piece_center_offset(i).z)-piece_center_offset(i)
   if model.begin_drag(i,rack,lift):held=i;grab_offset=at-center;last_motion=at;pointer_valid=true
   return
func release_at(at:Vector2)->void:
 if held_sheet:
  held_sheet=false
  if Rect2(690,330,205,95).has_point(at):model.set_extension(true)
  elif Rect2(570,448,115,62).has_point(at):model.set_extension(false)
  return
 if held<0:return
 var piece:=held;held=-1
 if not pointer_valid or at.distance_to(last_motion)>12 or model.drag_stage!="carry":model.cancel_drag();return
 if Rect2(45,110,170,330).has_point(at):
  if piece_position(piece).distance_to(RACK[piece])<=14:model.return_to_rack()
  else:model.cancel_drag()
  return
 var candidate:=Model.TRAY;var distance:=INF
 for x:int in 2:
  for y:int in 2:
   for z:int in 2:
    var pose:=Vector3i(x,y,z);var test:Array[Vector3i]=model.poses.duplicate();test[piece]=pose
    if not model.valid(test,model.bar_turn):continue
    var d:float=piece_position(piece).distance_to(project_point(Vector3(pose)+piece_center_offset(piece)))
    if d<distance:distance=d;candidate=pose
 if distance>14 or not model.request_drop(candidate):model.cancel_drag()
 queue_redraw()
func _text(s:String,p:Vector2,sz:=16,c:=INK)->void:draw_string(font,p,s,HORIZONTAL_ALIGNMENT_LEFT,-1,sz,c)
func _cube(cell:Vector3,color:Color)->void:
 var p:=Vector3(cell)
 var faces:=[ [Vector3(0,0,0),Vector3(1,0,0),Vector3(1,0,1),Vector3(0,0,1)], [Vector3(1,0,0),Vector3(1,1,0),Vector3(1,1,1),Vector3(1,0,1)], [Vector3(1,1,0),Vector3(0,1,0),Vector3(0,1,1),Vector3(1,1,1)], [Vector3(0,1,0),Vector3(0,0,0),Vector3(0,0,1),Vector3(0,1,1)], [Vector3(0,0,1),Vector3(1,0,1),Vector3(1,1,1),Vector3(0,1,1)] ]
 var order:Array=[]
 for index:int in 4:
  var middle:Vector3=(faces[index][0]+faces[index][1])*.5
  order.append({"index":index,"depth":project_point(p+middle).y})
 order.sort_custom(func(a:Dictionary,b:Dictionary)->bool:return a.depth<b.depth)
 order.append({"index":4})
 for row:Dictionary in order:
  var points:=PackedVector2Array()
  for v:Vector3 in faces[row.index]:points.append(project_point(p+v))
  draw_colored_polygon(points,color.lightened(.18) if row.index==4 else color.darkened(.08*row.index));points.append(points[0]);draw_polyline(points,INK,1)
func _grid(at:Vector2,cells:Dictionary,view:int,mask:bool)->void:
 for x:int in 2:
  for y:int in 2:
   var cell:=Vector2i(x,y);var r:=Rect2(at+Vector2(x*27,(1-y)*27),Vector2(25,25))
   draw_rect(r,INK if cells.has(cell) else Color("c9c1ad"))
   if mask and not model.visible_cell(view,cell):draw_rect(r,Color("b1a083"));draw_line(r.position,r.end,PAPER,2)
func _draw()->void:
 if font==null:return
 draw_rect(Rect2(0,0,960,540),INK);_text("跨学科研讨",Vector2(32,38),22,PAPER)
 draw_rect(Rect2(35,87,890,430),Color("a38e70"))
 for y:int in range(105,515,30):draw_line(Vector2(43,y),Vector2(917,y),Color("987e5f"),1)
 draw_rect(Rect2(54,111,150,330),Color("756b56"))
 for i:int in 3:
  if model.poses[i]==Model.TRAY and model.drag_piece!=i:
   var rack_origin:=inverse_point(RACK[i],piece_center_offset(i).z)-piece_center_offset(i)
   for local:Vector3i in model.cells(i,Vector3i.ZERO,model.bar_turn):_cube(rack_origin+Vector3(local),Color("71918e") if i==0 else Color("b8956d"))
 var base:=PackedVector2Array([project_point(Vector3.ZERO),project_point(Vector3(2,0,0)),project_point(Vector3(2,2,0)),project_point(Vector3(0,2,0))])
 draw_colored_polygon(base,Color("cbc0a5"));base.append(base[0]);draw_polyline(base,INK,4)
 for x:int in 2:
  for y:int in 2:draw_circle(slot_point(x,y),5,Color("7b8071"))
 draw_circle(project_point(Vector3.ZERO),8,INK)
 var cells:Array[Dictionary]=[]
 for piece:int in 3:
  if piece==model.drag_piece:continue
  for cell:Vector3i in model.cells(piece,model.poses[piece],model.bar_turn):cells.append({"cell":cell,"piece":piece,"depth":project_point(Vector3(cell)+Vector3(.5,.5,0)).y})
 cells.sort_custom(func(a:Dictionary,b:Dictionary)->bool:return a.depth<b.depth if a.depth!=b.depth else a.cell.z<b.cell.z)
 for row:Dictionary in cells:_cube(Vector3(row.cell),Color("71918e") if row.piece==0 else Color("b8956d"))
 var h:=rotation_handle();draw_arc(h,12,.3,5.7,20,PAPER,3);draw_circle(h+Vector2(10,-8),4,INK)
 ApparatusStyle.grip(self,h,"press",false)
 for i:int in 3:
  if model.drag_piece!=i:ApparatusStyle.grip(self,piece_position(i),"drag",false)
 draw_circle(Vector2(540,412),24,INK);draw_line(Vector2(540,412),Vector2(558,396),PAPER,6);draw_circle(Vector2(558,396),7,Color("ba9c75"))
 for view:int in 3:
  var y:=112+view*111
  draw_rect(Rect2(695,y,192,96),PAPER);_text(["俯视","正面","侧面"][view],Vector2(707,y+20),14)
  _grid(Vector2(712,y+31),model.target(view),view,true)
  if model.drag_piece<0:_grid(Vector2(806,y+31),Model.project(model.voxels(),view),view,false)
  else:draw_arc(Vector2(833,y+57),13,.3,5.7,16,INK,2)
  draw_circle(Vector2(700,y+90),4,INK)
 if model.drag_piece>=0:
  for local:Vector3i in model.cells(model.drag_piece,Vector3i.ZERO,model.bar_turn):_cube(model.preview_origin+Vector3(local),Color("71918e") if model.drag_piece==0 else Color("b8956d"))
 draw_rect(Rect2(575,453,105,51),Color("77664f"))
 var sheet:=pointer if held_sheet else sheet_position()
 draw_rect(Rect2(sheet-Vector2(38,12),Vector2(76,24)),Color("b1a083"));draw_line(sheet+Vector2(27,-17),sheet+Vector2(27,7),INK,5)
 draw_rect(Rect2(782,457,96,39),INK);draw_circle(Vector2(818,475),18,Color("7d9590"));draw_circle(Vector2(818,475),11,INK);draw_circle(Vector2(861,452 if not model.running else 457),8,Color("b4936c"))
 draw_rect(Rect2(45,472,145,38),PAPER);_text("观察便笺",Vector2(68,498),16)
 draw_arc(Vector2(240,490),15,.3,5.7,20,PAPER,4)
 if paper_open:
  _text("让同一件组合体符合三个视图。",Vector2(33,66),16,PAPER)
  _text(HINTS[hint_level],Vector2(295,497),15,PAPER)
 elif not model.outcome.is_empty():_text(model.outcome,Vector2(303,497),15,PAPER)
