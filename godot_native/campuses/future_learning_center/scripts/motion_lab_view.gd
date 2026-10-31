extends "res://campuses/future_learning_center/scripts/physical_bench.gd"
const Solar=preload("res://campuses/future_learning_center/scripts/solar_race_model.gd")
const Robot=preload("res://campuses/future_learning_center/scripts/robot_delivery_model.gd")
const Props=preload("res://campuses/future_learning_center/scripts/motion_prop_metrics.gd")
const Gears=preload("res://campuses/future_learning_center/scripts/workbench_view.gd")
const ORIGIN:=Vector2(102,145)
const CELL:=Props.CELL
const GUIDE:=Vector2(723,252)
const HINTS:={
 "solar":["先看两辆车在哪一段开始拉开距离。","保留其他零件，只改变板的朝向，再比较同一段赛道。","对照试车轨迹和日照，看看领先发生在起步、阴影还是复光之后。"],
 "robotics":["去程停靠与返程入口有什么不同？","从返程方向观察同一条凹纹。","把送达记录和返程停点叠起来，找出只在返程出现的阻挡。"]}
var solar=Solar.new()
var robot=Robot.new()
var kind:="solar"
var atlases:Dictionary={}
var frames:Dictionary={}
var selected:=Vector2i(2,1)
var drag_value:=0
var original_value:=0
var preview_rotation:=0
var preview_outlet:=2
var previous_state:=""
var source_tile:=Vector2i.ZERO
var panel_angle:=0.0
var rotation_angle:=0.0
var wheel_phase:=0.0
var last_moved:=0.0
var last_solar_distance:=0.0
var last_sky:=0
var lamp_glow:=1.0

func _ready()->void:
 super._ready()
 var measured:Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://campuses/future_learning_center/assets/puzzles/oblique45_frames.json")).vehicles
 frames={"solar_chassis":{"right":measured.solar_right,"left":measured.solar_left},"delivery_robot":{"right":measured.robot_right,"down":measured.robot_down,"left":measured.robot_left,"up":measured.robot_up}}
 var atlas:=_load_texture("res://campuses/future_learning_center/assets/puzzles/vehicles_oblique45_20261030.png")
 atlases.solar_chassis=atlas;atlases.delivery_robot=atlas

func open(mode:String)->void:
 if mode not in ["solar","robotics"]:return
 kind=mode;bench_mode=mode;book_open=false;book_page=0;previous_state="";cancel_gesture();show()
 clear_motion();panel_angle=float(Solar.TILTS[int(solar.setup.tilt)]);rotation_angle=0.0
 notice("让改装车在同一束阳光下跑得更远。" if kind=="solar" else "货物送到右侧，空车还要回到左侧。")
 queue_redraw()
func close()->void:
 solar.cancel()
 if robot.phase!="complete":robot.cancel()
 super.close()
func _lost_focus()->void:
 solar.cancel();robot.pause()
func _lever_live()->bool:return solar.running if kind=="solar" else robot.running
func _assembly_stamp()->String:
 return str([solar.setup,solar.sky]) if kind=="solar" else str([robot.tiles,robot.outlet])
func _seat_anchor(at:Vector2)->Vector2:
 return _car_at(0)-Vector2(0,30) if kind=="solar" and gesture in ["panel","gear","tilt"] else at
func _lever_action(offset:float)->void:
 if offset < -20:
  if kind=="solar":
   if not solar.resume():solar.start()
  elif not robot.resume():robot.start()
 elif offset > 20:
  if kind=="solar":solar.return_to_start()
  else:robot.return_to_start()
  notice("装置归位，零件和上一轮记录都保留。")
 else:
  if kind=="solar":solar.pause()
  else:robot.pause()
  notice("已停在当前位置，可以继续推杆。")
func _undo()->void:
 var changed:bool=solar.undo() if kind=="solar" else robot.undo()
 notice("已撤回上一次装配。" if changed else "还没有可以撤回的装配。")
func _process(dt:float)->void:
 if not visible:return
 _tick_shell(dt)
 if kind=="solar":solar.step(minf(dt,.1))
 else:robot.step(minf(dt,.1))
 var state:String=solar.outcome if kind=="solar" else robot.phase
 if state!=previous_state:
  previous_state=state
  if state in ["passed","compare","blocked","complete","unloading"]:notice(solar.message() if kind=="solar" else robot.message())
  if state=="blocked":cue("brake",_tile_at(robot.position))
 var target_angle:float=Solar.TILTS[drag_value] if gesture=="tilt" else Solar.TILTS[int(solar.setup.tilt)]
 panel_angle=target_angle if reduced_motion else lerpf(panel_angle,target_angle,1-exp(-dt*20))
 lamp_glow=float(solar.intensity_at(solar.elapsed()))
 # Angular phase follows real travelled distance; pausing freezes the wheels.
 wheel_phase=solar.cars[0].distance*2 if kind=="solar" else robot.moved*12
 queue_redraw()
func _keyboard(event:InputEventKey)->bool:
 # Optional equivalence only; the visible scene has no hotkey prompts or action strip.
 match event.keycode:
  KEY_SPACE:_lever_action(-40)
  KEY_Z:_undo()
  KEY_H:book_open=true;book_page=mini(3,maxi(1,book_page+1))
  KEY_R:if kind=="robotics":robot.edit(selected)
  KEY_C:if kind=="robotics":robot.edit(selected,true)
  KEY_N:if kind=="robotics":robot.advance_one()
  KEY_1,KEY_2,KEY_3,KEY_4:
   if kind=="solar":
    var key:String=["tilt","panel","gear","sky"][int(event.keycode)-int(KEY_1)]
    solar.configure(key,((solar.sky if key=="sky" else int(solar.setup[key]))+1)%(2 if key=="panel" else 3))
  KEY_LEFT,KEY_RIGHT,KEY_UP,KEY_DOWN:
   if kind=="robotics":selected=(selected+{KEY_LEFT:Vector2i.LEFT,KEY_RIGHT:Vector2i.RIGHT,KEY_UP:Vector2i.UP,KEY_DOWN:Vector2i.DOWN}[event.keycode]).clamp(Vector2i.ZERO,Vector2i(4,2))
  _:return false
 return true

func _car_at(lane:int)->Vector2:
 # Belt movement carries travel; both cars remain visible beside the one meter.
 return Vector2(192,215+lane*111)
func panel_grip()->Vector2:
 var corners:=Plane45.panel(_car_at(0),76.0 if solar.setup.panel==1 else 56.0,26,deg_to_rad(panel_angle),51)
 return corners[2].lerp(corners[3],.35)
func lamp_grip()->Vector2:return Vector2(787+solar.sky*32 if solar.sky<2 else 803,119 if solar.sky<2 else 142)
func lamp_drag_offset()->Vector2:
 return (pointer-press_at).clamp(Vector2(-40,-16),Vector2(70,35)) if gesture=="light" else Vector2.ZERO
func outlet_grip()->Vector2:
 var v:Vector2=Vector2(Robot.DIRECTIONS[robot.outlet])*23
 return GUIDE+Plane45.offset(v.x,v.y)
func rotation_grip(point:Vector2i,rotation:int)->Vector2:
 return _tile_at(point)+Plane45.offset(cos(rotation*PI/2+PI/4)*44,sin(rotation*PI/2+PI/4)*44)
func _editable()->bool:
 if _lever_live():notice("先把操纵杆拉回中位，再调整零件。");return false
 return true
func _object_press(at:Vector2)->void:
 if not _editable():return
 if kind=="solar":
  if at.distance_to(panel_grip())<32:
   gesture="tilt";original_value=solar.setup.tilt;drag_value=original_value;return
  if at.distance_to(lamp_grip())<36:gesture="light";drag_value=solar.sky;return
  for i:int in 2:
   var id:="panel%d"%i
   if Rect2(part_at(id,Vector2(181+i*113,398))-Vector2(50,42),Vector2(100,70)).has_point(at):gesture="panel";drag_value=i;returns.erase(id);return
  for i:int in 3:
   var id:="gear%d"%i
   if at.distance_to(part_at(id,Vector2(418+i*88,391)))<34:gesture="gear";drag_value=i;returns.erase(id);return
 else:
  if at.distance_to(outlet_grip())<30:gesture="guide";preview_outlet=robot.outlet;return
  for i:int in 3:
   var id:="module%d"%i
   if Rect2(part_at(id,Vector2(138+i*178,398))-Vector2(54,33),Vector2(108,66)).has_point(at):gesture="module";drag_value=i;returns.erase(id);return
  var point:=_point_at(at)
  if point in [Robot.BASE,Robot.DESTINATION] or not robot.tiles.has(point):return
  selected=point;source_tile=point;original_value=robot.tiles[point].rotation;preview_rotation=original_value;rotation_angle=original_value*PI/2
  gesture="rotate" if at.distance_to(rotation_grip(point,original_value))<25 else "tile"
func _object_move(at:Vector2)->void:
 if gesture=="tilt":drag_value=clampi(original_value+roundi((press_at.y-at.y)/23),0,2)
 elif gesture=="light":drag_value=2 if at.y-press_at.y>25 else (1 if at.x>803 else 0)
 elif gesture=="rotate":
  var center:=_tile_at(source_tile)
  var a:=(press_at-center)/Vector2(1,Plane45.DEPTH);var b:=(at-center)/Vector2(1,Plane45.DEPTH)
  rotation_angle=original_value*PI/2+a.angle_to(b)
  preview_rotation=posmod(roundi(rotation_angle/(PI/2)),4)
 elif gesture=="guide":
  var v:=at-GUIDE
  preview_outlet=2 if v.x< -absf(v.y) else (3 if v.y<0 else 1)
func _object_release(at:Vector2,cancelled:bool)->void:
 if cancelled:
  if gesture=="panel":return_part("panel%d"%drag_value,pointer-Vector2(0,18),Vector2(181+113*drag_value,398))
  elif gesture=="gear":return_part("gear%d"%drag_value,pointer-Vector2(0,22),Vector2(418+88*drag_value,391))
  elif gesture=="module":return_part("module%d"%drag_value,pointer-Vector2(0,20),Vector2(138+178*drag_value,398))
  return
 if kind=="solar":
  if gesture=="tilt" and at.distance_to(panel_grip())<115:
   if at.distance_to(press_at)>8:solar.configure("tilt",drag_value)
   else:notice("握住面板边缘，上下拖动支架。")
  elif gesture in ["panel","gear"]:
   if Rect2(_car_at(0)-Vector2(68,83),Vector2(140,110)).has_point(at):solar.configure(gesture,drag_value)
   else:
    notice("把零件拖到改装车上；放在台面会退回零件盘。")
    if gesture=="panel":return_part("panel%d"%drag_value,pointer-Vector2(0,18),Vector2(181+113*drag_value,398))
    else:return_part("gear%d"%drag_value,pointer-Vector2(0,22),Vector2(418+88*drag_value,391))
  elif gesture=="light" and at.distance_to(press_at)>8:solar.configure("sky",drag_value)
 else:
  var target:=_point_at(at)
  if gesture=="guide" and at.distance_to(press_at)>8:robot.set_outlet(preview_outlet)
  elif gesture=="rotate" and at.distance_to(_tile_at(source_tile))<90 and at.distance_to(press_at)>10:robot.place_module(source_tile,robot.tiles[source_tile].kind,preview_rotation)
  elif gesture=="module":
   if not robot.place_module(target,["straight","corner","oneway"][drag_value],0):notice("模块要落在凹槽格内；两端站台是固定的。")
  elif gesture=="tile" and at.distance_to(press_at)>12:
   if not robot.swap_modules(source_tile,target):notice("把轨道放到另一块可拆模块的位置。")
func _point_at(at:Vector2)->Vector2i:
 var p:=Vector2i(roundi((at.x-ORIGIN.x)/CELL.x),roundi((at.y-ORIGIN.y)/CELL.y))
 return p if Rect2(_tile_at(p)-Vector2(52,37),Vector2(104,74)).has_point(at) else Vector2i(-9,-9)
func _book_lines()->Array[String]:
 if book_page>0:return ["现场笔记",HINTS[kind][book_page-1]]
 if kind=="solar":
  if solar.last_trial.is_empty():return ["试车记录","完整跑一轮，再来比较轨迹。翻右下页角看线索。"]
  return ["上轮对照","改装 %.1f 格，基准 %.1f 格。翻页对照日照和面板。"%[solar.last_trial.distance,solar.last_trial.reference]]
 return ["送货记录","货物送到右侧后，空车沿真实轨迹返回。翻页看现场线索。"]
func _text(value:String,at:Vector2,size_value:=20,color:=Color("e8e0c8"))->void:ink(value,at,size_value,color)
func _sprite(id:String,direction:String,at:Vector2,factor:float)->Rect2:
 var a:Array=frames[id][direction];var source:=Rect2(a[0],a[1],a[2],a[3]);var extent:=source.size*factor
 var bounds:=Rect2(at-Vector2(extent.x/2,extent.y),extent)
 draw_texture_rect_region(atlases[id],bounds,source);return bounds
func _draw()->void:
 if font==null or frames.is_empty():return
 draw_table("太阳能耐力赛" if kind=="solar" else "送到了，还要回来")
 if kind=="solar":_solar_readouts()
 else:
  ink("装货站",Vector2(67,355),18);ink("送达站",Vector2(524,355),18)
  ink("返程导向",GUIDE+Vector2(-35,54),18)
 draw_tools();draw_book()
func _solar_readouts()->void:
 var preview:int=drag_value if gesture=="light" else solar.sky
 var light:float=(0 if preview==2 else 1) if gesture=="light" else solar.intensity_at(solar.elapsed())
 ink("太阳光模拟器",Vector2(671,81),19)
 ink(["斜照 30°","斜照 60°","遮光板关闭"][preview],Vector2(675,104),16)
 if book_open:ink("拨动橙色握柄调光",Vector2(419,73),15)
 ink("改装车",Vector2(53,164),18);ink("基准车",Vector2(53,275),18)
 var white:=Color("f4eddb")
 ink("行驶距离 / 格",Vector2(649,187),17,white)
 ink("改装",Vector2(649,221),16,white);ink("%.1f"%solar.cars[0].distance,Vector2(697,228),30,white)
 ink("基准",Vector2(649,268),16,white);ink("%.1f"%solar.cars[1].distance,Vector2(697,275),30,white)
 ink("%.1f / 30 秒"%solar.elapsed(),Vector2(649,307),17,white)
 ink("受光 %d%%"%roundi(light*100),Vector2(509,352),16)
 if gesture=="tilt":ink("%d°"%Solar.TILTS[drag_value],panel_grip()+Vector2(24,-10),20)
func _tile_at(point:Vector2)->Vector2:return ORIGIN+point*CELL
func draw_room_prop(canvas:CanvasItem,mode:String,bounds:Rect2)->void:
 if frames.is_empty():return
 var id:="solar_chassis" if mode=="solar" else "delivery_robot"
 var frame:Array=frames[id].right;var source:=Rect2(frame[0],frame[1],frame[2],frame[3])
 var at:=bounds.position+Vector2(bounds.size.x*.5,bounds.size.y*.59)
 var display:=source.size*.07
 canvas.draw_texture_rect_region(atlases[id],Rect2(at-Vector2(display.x/2,display.y),display),source)
 if mode=="solar":
  var width:=25.0 if solar.setup.panel==1 else 19.0
  var rise:float=Solar.TILTS[solar.setup.tilt]/12.0
  canvas.draw_rect(Rect2(at+Vector2(-width/2,-18-rise),Vector2(width,8+rise)),Color("385b79"))
  canvas.draw_rect(Rect2(at+Vector2(-width/2,-18-rise),Vector2(width,8+rise)),Color("c5c1a9"),false,1)
 elif robot.earned:canvas.draw_rect(Rect2(at+Vector2(23,-8),Vector2(8,8)),Color("c79b62"))
