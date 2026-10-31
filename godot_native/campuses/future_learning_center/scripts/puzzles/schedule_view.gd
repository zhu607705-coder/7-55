extends Control
const ApparatusStyle=preload("res://campuses/future_learning_center/scripts/apparatus_style.gd")
signal closed
const Model=preload("res://campuses/future_learning_center/scripts/puzzles/schedule_model.gd")
const INK=ApparatusStyle.INK
const PAPER=ApparatusStyle.PAPER
const CAMERA_TEXTURE=preload("res://campuses/future_learning_center/assets/puzzles/schedule_generated/camera.png")
const CAMERA_REGION=Rect2(105,356,1052,649)
const WORKTABLE_TEXTURE=preload("res://campuses/future_learning_center/assets/puzzles/schedule_generated/worktable.png")
const WORKTABLE_REGION=Rect2(156,405,943,586)
const GLOVES_TEXTURE=preload("res://campuses/future_learning_center/assets/puzzles/schedule_generated/gloves.png")
const GLOVES_REGION=Rect2(284,75,1105,845)
const ARTIFACT_TEXTURES=[
 preload("res://campuses/future_learning_center/assets/puzzles/schedule_generated/photo_a.png"),
 preload("res://campuses/future_learning_center/assets/puzzles/schedule_generated/assembled_b.png"),
 preload("res://campuses/future_learning_center/assets/puzzles/schedule_generated/photo_b.png"),
 preload("res://campuses/future_learning_center/assets/puzzles/schedule_generated/comparison.png")]
const ARTIFACT_REGIONS=[Rect2(121,125,1227,889),Rect2(166,165,1030,958),Rect2(117,108,1237,916),Rect2(46,252,1334,660)]
const ARTIFACT_BOXES=[Vector2(54,40),Vector2(42,38),Vector2(54,40),Vector2(64,36)]
const Visuals=preload("res://campuses/future_learning_center/scripts/puzzles/schedule_scene_visuals.gd")
const SceneArt=preload("res://campuses/future_learning_center/scripts/puzzles/schedule_scene_art.gd")
const CARD_SIZE=Vector2(164,62)
const BOARD_DROP=Rect2(258,88,574,317)
const NAMES=["拍 A","装 B","拍 B","比较"]
const XS=[363.0,545.0,728.0]
var model=Model.new()
var visuals:Node2D
var reduced_motion:=false
var snap_visuals:=true
var font:Font
var held_task:=-1
var held_tool:=-2
var selected_task:=-1
var pointer:=Vector2.ZERO
var task_grab_offset:=Vector2.ZERO
var tool_grab_offset:=Vector2.ZERO
var touch_id:=-1
var paper_open:=false
var pending_tap:=""
var tap_origin:=Vector2.ZERO
var mouse_owned:=false
func _ready()->void:
 ApparatusStyle.configure_exit(self,close)
 font=ApparatusStyle.font()
 visuals=Visuals.new();visuals.art=SceneArt.PARTS;add_child(visuals)
 var state=get_node_or_null("/root/State")
 if state!=null:reduced_motion=bool(state.d.get("native",{}).get("settings",{}).get("reduced_motion",false))
 mouse_filter=Control.MOUSE_FILTER_STOP;hide()
func open()->void:show();snap_visuals=true;_sync_visuals(0);queue_redraw()
func close()->void:
 _cancel_drag();model.cancel();hide();closed.emit()
func _notification(what:int)->void:
 if what in [NOTIFICATION_APPLICATION_FOCUS_OUT,NOTIFICATION_APPLICATION_PAUSED]:_cancel_drag();model.pause()
func _process(dt:float)->void:
 if visible:model.step(dt);_sync_visuals(dt);queue_redraw()
func _sync_visuals(dt:float)->void:
 if visuals==null:return
 visuals.reduced_motion=reduced_motion;visuals.sync(self,dt,snap_visuals);snap_visuals=false
func card_visual_point(task:int)->Vector2:
 return visuals.object_at("TaskCard%d"%task,card_point(task)) if visuals!=null else card_point(task)
func card_point(task:int)->Vector2:return Vector2(XS[model.slots[task]],142+task*70)
func _cancel_drag()->void:held_task=-1;held_tool=-2;selected_task=-1;touch_id=-1;pending_tap="";mouse_owned=false;task_grab_offset=Vector2.ZERO;tool_grab_offset=Vector2.ZERO;snap_visuals=true;queue_redraw()
func _input(event:InputEvent)->void:
 if ApparatusStyle.navigation_event(self,event):return
 if not is_visible_in_tree():return
 if (event is InputEventMouseButton or event is InputEventMouseMotion) and event.device==InputEvent.DEVICE_ID_EMULATION:return
 if event is InputEventScreenTouch:
  if event.pressed and not event.canceled and touch_id<0 and not mouse_owned:touch_id=event.index;_pointer_press(get_global_transform_with_canvas().affine_inverse()*event.position)
  elif event.index==touch_id:
   if event.canceled:_cancel_drag()
   elif not event.pressed:_pointer_release(get_global_transform_with_canvas().affine_inverse()*event.position);touch_id=-1
  get_viewport().set_input_as_handled()
 elif event is InputEventScreenDrag and event.index==touch_id:pointer=get_global_transform_with_canvas().affine_inverse()*event.position;queue_redraw();get_viewport().set_input_as_handled()
 elif event is InputEventMouseButton and event.button_index==MOUSE_BUTTON_LEFT and touch_id<0:
  var at:Vector2=get_global_transform_with_canvas().affine_inverse()*event.position
  if event.pressed and not mouse_owned:mouse_owned=true;_pointer_press(at)
  elif not event.pressed and mouse_owned:mouse_owned=false;_pointer_release(at)
  get_viewport().set_input_as_handled()
 elif event is InputEventMouseMotion and touch_id<0:pointer=get_global_transform_with_canvas().affine_inverse()*event.position;queue_redraw()
 elif event is InputEventKey and event.pressed and event.keycode==KEY_ESCAPE:close();get_viewport().set_input_as_handled()
func _tap_action(at:Vector2)->String:
 if Rect2(42,427,150,74).has_point(at):return "paper"
 if at.distance_to(Vector2(238,471))<30:return "undo"
 if at.distance_to(Vector2(870,340))<39:return "crank"
 return ""
func _pointer_press(at:Vector2)->void:
 pending_tap=_tap_action(at);tap_origin=at;pointer=at
 if pending_tap.is_empty():press_at(at)
func _pointer_release(at:Vector2)->void:
 if not pending_tap.is_empty():
  var activate:=pending_tap==_tap_action(at) and tap_origin.distance_to(at)<16
  pending_tap=""
  if activate:press_at(tap_origin)
 else:release_at(at)
func press_at(at:Vector2)->void:
 pointer=at
 if visuals!=null:
  var settling:int=visuals.settling_pickup(at)
  if settling>=-1:
   held_tool=settling;tool_grab_offset=visuals.object_at("SettlingTool",at)-at;return
 if Rect2(42,427,150,74).has_point(at):paper_open=not paper_open;queue_redraw();return
 if at.distance_to(Vector2(238,471))<30:model.undo();return
 if at.distance_to(Vector2(870,340))<39:
  if model.running:
   if model.paused:model.resume()
   else:model.pause()
  else:model.start()
  return
 if Rect2(816,440,110,60).has_point(at):held_tool=3;tool_grab_offset=Vector2(870,470)-at;return
 for task:int in 4:
  if Rect2(card_visual_point(task)-CARD_SIZE*.5,CARD_SIZE).has_point(at):
   if held_tool>=-1 and held_tool<3:model.connect_tool(task,held_tool);held_tool=-2
   else:held_task=task;selected_task=task;task_grab_offset=card_visual_point(task)-at
   return
 for tool:int in 3:
  if tool==1 and model.cameras<2:continue
  if at.distance_to(Vector2(70+tool*75,220))<30:held_tool=tool;tool_grab_offset=Vector2(70+tool*75,220)-at;return
 # Hands are a physical glove pair beside the tool rack.
 if at.distance_to(Vector2(145,300))<30:held_tool=-1;tool_grab_offset=Vector2(145,300)-at;return
func release_at(at:Vector2)->void:
 var released_tool:=held_tool
 var assigned_task:=-1
 at+=task_grab_offset if held_task>=0 else tool_grab_offset
 if held_task>=0:
  if BOARD_DROP.has_point(at):
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
   if Rect2(card_visual_point(task)-CARD_SIZE*.5,CARD_SIZE).has_point(at):model.connect_tool(task,held_tool);assigned_task=task;break
  held_tool=-2
 if released_tool>=-1 and visuals!=null:
  var destination:=Vector2(145,300) if released_tool==-1 else Vector2(70+released_tool*75,220)
  if released_tool==3:destination=Vector2(145,220) if model.cameras==2 else Vector2(870,470)
  if assigned_task>=0:destination=card_visual_point(assigned_task)+Vector2(33,10)
  visuals.settle_tool(self,released_tool,at,destination,assigned_task)
 queue_redraw()
# Object captions and test records are available only on request.
func annotations_visible()->bool:return paper_open
func _text(value:String,at:Vector2,sz:=16,color:=INK)->void:
 if not annotations_visible():return
 draw_string(font,at,value,HORIZONTAL_ALIGNMENT_LEFT,-1,sz,color)
func _sprite_rect(region:Rect2,at:Vector2,box:Vector2)->Rect2:
 var factor:float=minf(box.x/region.size.x,box.y/region.size.y)
 var extent:Vector2=region.size*factor
 return Rect2(at-extent*.5,extent)
func _feedback()->String:
 if model.running:return ""
 var errors={"tool_busy":"同一拍不能共用工具","missing_input":"前置产物尚未完成","camera_missing":"需要相机","bench_missing":"需要操作台","hands_needed":"请换成手套"}
 var task:int=selected_task
 if task<0 or model.errors[task].is_empty():
  task=-1
  for i:int in 4:
   if not model.errors[i].is_empty():task=i;break
 if task>=0:return NAMES[task]+"："+str(errors.get(model.errors[task],model.errors[task]))
 return "照片与装配件已齐备" if model.completed else ""
func _draw()->void:
 if font==null:return
 _text("开放研讨",Vector2(32,39),23,PAPER)
 for slot:int in 3:_text("第 %d 拍"%(slot+1),Vector2(XS[slot]-26,76),16,PAPER)
 if visuals==null or visuals.page_amount<.01:
  _text("工具托盘",Vector2(85,150),16,INK)
  _text("1",Vector2(97,225),12)
  if model.cameras==2:_text("2",Vector2(172,225),12)
 for task:int in 4:
  var center:=card_visual_point(task)
  _text(NAMES[task],center+Vector2(-70,-11),18)
  if model.tools[task] in [0,1]:_text(str(model.tools[task]+1),center+Vector2(60,17),12)
  if model.current_tasks.has(task):draw_line(center+Vector2(-62,27),center+Vector2(-62+124*model.progress,27),INK,3)
  if held_task==task:
   for slot:int in 3:ApparatusStyle.target(self,Rect2(Vector2(XS[slot],142+task*70)-CARD_SIZE*.5,CARD_SIZE),true)
  if held_tool>=-1 and held_tool<3:ApparatusStyle.target(self,Rect2(center-CARD_SIZE*.5,CARD_SIZE),true)
 _text("试运行",Vector2(845,294),16,INK)
 var status:="暂停" if model.paused else ("第 %d 拍"%(model.beat+1) if model.running else "就绪")
 _text(status,Vector2(848,402),14,INK)
 _text("产物",Vector2(295,424),14,INK)
 for task:int in 3:
  if model.artifacts[task]:_text("A" if task==0 else "B",Vector2(373+task*105,458),16)
 _text("排期笔记",Vector2(65,466),16)
 _text("撤回",Vector2(222,506),14,PAPER)
 _text("备用相机 2",Vector2(827,433),14,INK)
 var feedback:=_feedback()
 if not feedback.is_empty():_text(feedback,Vector2(332,525),16,PAPER)
 if visuals!=null and visuals.page_amount>.98:
  var lines=["拍 A：相机", "装 B：操作台", "拍 B：先有装好的 B", "比较：先有两张照片", "", "同一件工具一拍只用一次。", "本拍产物从下一拍才能用。", "", "拖任务磁片到拍位。", "从托盘把工具接到任务上。"]
  for i:int in lines.size():_text(lines[i],Vector2(54,121+i*25),14)
