extends Control
signal closed
const Model=preload("res://campuses/future_learning_center/scripts/puzzles/solid_projection_model.gd")
const INK:=Color("29373b")
const PAPER:=Color("e7e1cf")
const RACK:=[Vector2(125,180),Vector2(125,290),Vector2(125,400)]
var model=Model.new()
var font:Font
var held:=-1
var held_sheet:=false
var touch_id:=-1
var pointer:=Vector2.ZERO
var paper_open:=false
var hint_level:=0
var angle:=0.0
const HINTS:=["哪张图能区分前后相叠的块？","底座缺口不变，只换一块的前后位置。","把三张图对照；上层也需要下方的实体支撑。"]
func _ready()->void:
 mouse_filter=Control.MOUSE_FILTER_STOP;focus_mode=Control.FOCUS_ALL;font=load("res://scripts/ui/native_typography.gd").body_font();size=Vector2(960,540);hide()
func open()->void:show();model.resume();queue_redraw()
func close()->void:model.cancel();cancel_pointer();hide();closed.emit()
func cancel_pointer()->void:held=-1;held_sheet=false;touch_id=-1;queue_redraw()
func _notification(what:int)->void:
 if what in [NOTIFICATION_APPLICATION_FOCUS_OUT,NOTIFICATION_APPLICATION_PAUSED]:model.pause();cancel_pointer()
func _process(dt:float)->void:
 if visible:
  if not model.paused:angle=move_toward(angle,model.observation*PI/2,minf(dt,.1)*PI)
  model.step(dt);queue_redraw()
func project_point(p:Vector3)->Vector2:
 var x:=p.x-1;var y:=p.y-1;var a:=angle+PI/4
 return Vector2(445+(x*cos(a)-y*sin(a))*72,323+(x*sin(a)+y*cos(a))*32-p.z*57)
func slot_point(x:int,y:int)->Vector2:return project_point(Vector3(x+.5,y+.5,0))
func piece_position(piece:int)->Vector2:
 if model.poses[piece]==Model.TRAY:return RACK[piece]
 var p:=Vector3(model.poses[piece])+Vector3(.5,.5,.5)
 if piece==0:p+=Vector3(.5,0,0) if model.bar_turn==0 else Vector3(0,.5,0)
 return project_point(p)
func rotation_handle()->Vector2:return piece_position(0)+Vector2(0,-44)
func sheet_position()->Vector2:return Vector2(766,374) if model.extension else Vector2(620,475)
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
 pointer=at
 if Rect2(880,15,60,50).has_point(at):close();return
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
  if at.distance_to(piece_position(i))<(55 if i==0 else 35):held=i;return
func release_at(at:Vector2)->void:
 if held_sheet:
  held_sheet=false
  if Rect2(690,330,205,95).has_point(at):model.set_extension(true)
  elif Rect2(570,448,115,62).has_point(at):model.set_extension(false)
  return
 if held<0:return
 var piece:=held;held=-1
 if Rect2(45,110,170,330).has_point(at):model.place(piece,Model.TRAY);return
 var best:=Vector2i(-1,-1);var distance:=INF
 for x:int in 2:
  for y:int in 2:
   var d:float=at.distance_to(slot_point(x,y))
   if d<distance:distance=d;best=Vector2i(x,y)
 if distance<58:model.drop(piece,best.x,best.y)
 queue_redraw()
func _text(s:String,p:Vector2,sz:=16,c:=INK)->void:draw_string(font,p,s,HORIZONTAL_ALIGNMENT_LEFT,-1,sz,c)
func _cube(cell:Vector3i,color:Color)->void:
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
 draw_rect(Rect2(0,0,960,540),INK);_text("跨学科研讨 · 三个视图，同一件东西",Vector2(32,38),22,PAPER);_text("×",Vector2(898,47),28,PAPER)
 draw_rect(Rect2(35,87,890,430),Color("a38e70"))
 for y:int in range(105,515,30):draw_line(Vector2(43,y),Vector2(917,y),Color("987e5f"),1)
 draw_rect(Rect2(54,111,150,330),Color("756b56"))
 for i:int in 3:
  if model.poses[i]==Model.TRAY and held!=i:
   var at:Vector2=RACK[i];var width:=92 if i==0 and model.bar_turn==0 else 49
   var height:=92 if i==0 and model.bar_turn==1 else 48
   draw_rect(Rect2(at-Vector2(width/2.0,height/2.0)+Vector2(0,6),Vector2(width,height)),INK);draw_rect(Rect2(at-Vector2(width/2.0,height/2.0),Vector2(width,height)),Color("71918e") if i==0 else Color("b8956d"))
 var base:=PackedVector2Array([project_point(Vector3.ZERO),project_point(Vector3(2,0,0)),project_point(Vector3(2,2,0)),project_point(Vector3(0,2,0))])
 draw_colored_polygon(base,Color("cbc0a5"));base.append(base[0]);draw_polyline(base,INK,4)
 for x:int in 2:
  for y:int in 2:draw_circle(slot_point(x,y),5,Color("7b8071"))
 draw_circle(project_point(Vector3.ZERO),8,INK)
 var cells:Array[Dictionary]=[]
 for piece:int in 3:
  for cell:Vector3i in model.cells(piece,model.poses[piece],model.bar_turn):cells.append({"cell":cell,"piece":piece,"depth":project_point(Vector3(cell)+Vector3(.5,.5,0)).y})
 cells.sort_custom(func(a:Dictionary,b:Dictionary)->bool:return a.depth<b.depth if a.depth!=b.depth else a.cell.z<b.cell.z)
 for row:Dictionary in cells:_cube(row.cell,Color("71918e") if row.piece==0 else Color("b8956d"))
 var h:=rotation_handle();draw_arc(h,12,.3,5.7,20,PAPER,3);draw_circle(h+Vector2(10,-8),4,INK)
 draw_circle(Vector2(540,412),24,INK);draw_line(Vector2(540,412),Vector2(558,396),PAPER,6);draw_circle(Vector2(558,396),7,Color("ba9c75"))
 for view:int in 3:
  var y:=112+view*111
  draw_rect(Rect2(695,y,192,96),PAPER);_text(["俯视","正面","侧面"][view],Vector2(707,y+20),14)
  _grid(Vector2(712,y+31),model.target(view),view,true);_grid(Vector2(806,y+31),Model.project(model.voxels(),view),view,false)
  draw_circle(Vector2(700,y+90),4,INK)
 if held>=0:
  draw_rect(Rect2(pointer-Vector2(44 if held==0 else 23,22),Vector2(88 if held==0 else 46,44)),Color("bdc4ad"))
 draw_rect(Rect2(575,453,105,51),Color("77664f"))
 var sheet:=pointer if held_sheet else sheet_position()
 draw_rect(Rect2(sheet-Vector2(38,12),Vector2(76,24)),Color("b1a083"));draw_line(sheet+Vector2(27,-17),sheet+Vector2(27,7),INK,5)
 draw_rect(Rect2(782,457,96,39),INK);draw_circle(Vector2(818,475),18,Color("7d9590"));draw_circle(Vector2(818,475),11,INK);draw_circle(Vector2(861,452 if not model.running else 457),8,Color("b4936c"))
 draw_rect(Rect2(45,472,145,38),PAPER);_text("观察便笺",Vector2(68,498),16)
 draw_arc(Vector2(240,490),15,.3,5.7,20,PAPER,4)
 if paper_open:_text(HINTS[hint_level],Vector2(295,497),15,PAPER)
 elif not model.outcome.is_empty():_text(model.outcome,Vector2(303,497),15,PAPER)
