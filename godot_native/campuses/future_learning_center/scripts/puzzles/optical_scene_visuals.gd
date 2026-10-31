extends Node2D
## Presentation-only independent PNG objects. No model mutations, timers or save writes.
const ObjectSprite=preload("res://campuses/future_learning_center/scripts/puzzles/schedule_object_sprite.gd")
const LightPaths=preload("res://campuses/future_learning_center/scripts/puzzles/optical_light_paths.gd")
var light_paths:Node2D
var art:Dictionary={}
var objects:Dictionary={}
var variants:Dictionary={}
var reduced_motion:=false
var _ordered_count:=-1
func object_at(id:String,fallback:Vector2)->Vector2:
 return objects[id].position if objects.has(id) and objects[id].visible else fallback
func hit(id:String,at:Vector2)->bool:
 if not objects.has(id) or not objects[id].visible:return false
 var object:Sprite2D=objects[id]
 return object.get_rect().has_point(object.to_local(to_global(at)))
func put(id:String,key:String,at:Vector2,box:=Vector2.ZERO,direct:=true,lift:=0.0,base_pivot:=false)->void:
 if not art.has(key):return
 var spec:Dictionary=art[key]
 if not objects.has(id):
  var body=ObjectSprite.new();body.name=id;body.manual_advance=true;add_child(body);objects[id]=body
 var object=objects[id]
 var logical:Vector2=spec.box if box==Vector2.ZERO else box
 var variant:=key+str(logical)+str(base_pivot)
 if variants.get(id,"")!=variant:
  object.configure(spec.texture,spec.region,logical)
  if spec.has("pivot"):object.offset=spec.region.position+spec.region.size*.5-spec.pivot
  elif base_pivot:object.offset=Vector2(0,-spec.region.size.y*.5)
  variants[id]=variant
 object.set_presented(true);object.set_reduced_motion(reduced_motion)
 object.present(at,direct,lift)
func sync(view,dt:float,snap:=false)->void:
 if light_paths==null:
  light_paths=LightPaths.new();light_paths.name="LightPaths";add_child(light_paths)
 light_paths.view=view;light_paths.queue_redraw()
 for object in objects.values():object.advance_visual(dt)
 put("Tabletop","tabletop",Vector2(480,315),Vector2(960,440))
 put("Fixture","fixture",view.CENTER,Vector2(312,185))
 for slot:int in 4:
  var id:="Socket%d"%slot
  var horizontal:bool=slot%2==1
  put(id,"socket",view.projected(view.Model.SLOT_POINTS[slot]),Vector2(116 if horizontal else 76.56,8))
  if objects.has(id):objects[id].rotation=0.0 if horizontal else PI/2
 for i:int in 2:put("BaffleTray%d"%i,"cradle",view.TRAY[i]+Vector2(0,12),Vector2(124,58))
 put("NotebookCover","cover",Vector2(104,455),Vector2(145,72))
 put("RecordsPage","page",Vector2(864,245),Vector2(180,255))
 for row:int in 3:put("Receipt%d"%row,"card",Vector2(864,207+row*48),Vector2(111,40))
 var rotated:bool=view.model.quarter_turn%2==1
 var feed_start:Vector2=view.projected(view.model.rotate_point(Vector2(0,210)))
 for lane:int in 2:
  var rail_at:Vector2=view.projected(view.model.rotate_point(Vector2(-20 if lane==0 else 20,105)))
  put("FeedRail%d"%lane,"rail_horizontal" if rotated else "rail_vertical",rail_at,Vector2(210,8) if rotated else Vector2(8,138.6))
 put("Target","target",view.CENTER,Vector2(36,34))
 if objects.has("Target"):objects.Target.modulate=Color.WHITE if view.model.light_blocked(view.model.condition) else Color(1.12,1.06,.86)
 put("Carriage","carriage",feed_start.lerp(view.CENTER,view.model.travel),Vector2(38,37),true,0,true)
 for side:int in 2:
  var id:="Lamp%d"%side
  put(id,"lamp",view.lamp_at(side),Vector2(36,38))
  if objects.has(id):objects[id].modulate=Color.WHITE if side==view.model.condition else Color(.68,.72,.73)
 put("Camera","camera",view.camera_at(),Vector2(57,43))
 put("FeedBase","starter_base",view.lever_at()+Vector2(0,6),Vector2(52,58))
 put("FeedCap","starter_cap",view.lever_at()+Vector2(0,1 if view.action=="feed" else -4),Vector2(29,19))
 put("QuarterControl","quarter_control",Vector2(650,454 if view.action=="rotate" else 452),Vector2(60,60))
 for i:int in 2:
  var held:bool=view.drag==i
  var slot:int=view.model.slots[i]
  var at:Vector2=view.pointer+view.grab_offset if held else view.logical_position_of(i)
  var front:bool=held or slot<0 or slot%2==1
  var baffle_box:Vector2=Vector2(116,41) if front else art.get("baffle_edge",{}).get("box",Vector2(17,68))
  put("Baffle%d"%i,"baffle_front" if front else "baffle_edge",at,baffle_box,held or snap,1.0 if held else 0.0,true)
 if view.has_method("bracket_position"):
  for i:int in 2:
   var id:="Baffle%d"%i
   if objects.has(id):objects[id].modulate=Color.WHITE if view.model.bracket_attached or view.model.slots[i]<0 else Color(.70,.72,.72)
  put("BracketTray","cradle",view.BRACKET_TRAY+Vector2(0,9),Vector2(97,45))
  put("SupportRail","rail_vertical" if rotated else "rail_horizontal",view.projected(view.model.rotate_point(Vector2(0,65))),Vector2(12,182.16) if rotated else Vector2(276,12))
  var held:bool=view.bracket_drag
  put("Bracket","bracket",view.pointer+view.grab_offset if held else view.logical_bracket_position(),Vector2(28,52),held or snap,1.0 if held else 0.0,true)
 for id:String in ["NotebookPage","HistoryCard"]:
  if objects.has(id):objects[id].set_presented(false)
 if view.show_records:put("HistoryCard","card",Vector2(690,123),Vector2(450,160))

 # Layer order changes only when a new sprite appears, not on every motion frame.
 if objects.size()==_ordered_count:return
 _ordered_count=objects.size()
 # Stable physical layering, including objects first created after the first frame.
 var order:Array[String]=["Tabletop","Fixture","Socket0","Socket1","Socket2","Socket3","FeedRail0","FeedRail1","SupportRail","BaffleTray0","BaffleTray1","BracketTray","LightPaths","Target","Carriage","Lamp0","Lamp1","Camera","FeedBase","FeedCap","QuarterControl","Baffle0","Baffle1","Bracket","NotebookCover","RecordsPage","Receipt0","Receipt1","Receipt2","NotebookPage","HistoryCard"]
 for id:String in order:
  if id=="LightPaths":move_child(light_paths,get_child_count()-1)
  elif objects.has(id):move_child(objects[id],get_child_count()-1)
