extends SceneTree
const Collab=preload("res://campuses/future_learning_center/scripts/puzzles/collab_view.gd")
const Assembly=preload("res://campuses/future_learning_center/scripts/puzzles/assembly_view.gd")
const Art=preload("res://campuses/future_learning_center/scripts/puzzles/optical_scene_art.gd")
const Visuals=preload("res://campuses/future_learning_center/scripts/puzzles/optical_scene_visuals.gd")
var checks:=0
var failures:=0
func check(ok:bool,label:String)->void:
 checks+=1
 if not ok:failures+=1;push_error("OPTICAL_SCENE "+label)
func _initialize()->void:run.call_deferred()
func mouse(view,at:Vector2,down:bool)->void:
 var e:=InputEventMouseButton.new();e.position=view.get_global_transform_with_canvas()*at;e.button_index=MOUSE_BUTTON_LEFT;e.pressed=down;view._input(e)
func touch(view,id:int,at:Vector2,down:bool,canceled:=false)->void:
 var e:=InputEventScreenTouch.new();e.position=view.get_global_transform_with_canvas()*at;e.index=id;e.pressed=down;e.canceled=canceled;view._input(e)
func run()->void:
 for Type in [Collab,Assembly]:
  var view=Type.new();root.add_child(view);view.open();view.set_process(false)
  var start:Vector2=view.position_of(0);var edge:=Vector2(20,0)
  mouse(view,start+edge,true)
  check(view.drag==0 and view.grab_offset.is_equal_approx(-edge),"edge pickup keeps object registration")
  touch(view,2,view.camera_at(),true)
  check(view.touch_id==-1 and view.mouse_owned and not view.model.running,"touch cannot steal a mouse gesture")
  var target:Vector2=view.projected(view.Model.SLOT_POINTS[0])
  mouse(view,target+edge,false)
  check(view.model.slots[0]==0 and not view.mouse_owned,"release uses object anchor rather than finger offset")
  var revision:int=view.model.configuration_revision
  mouse(view,view.camera_at(),false)
  check(not view.model.running,"late unowned mouse release cannot activate")
  touch(view,3,target,true)
  touch(view,4,view.camera_at(),true);touch(view,4,view.camera_at(),false)
  check(view.drag==0 and view.touch_id==3 and not view.model.running,"second touch cannot steal or release")
  touch(view,3,Vector2(900,500),false,true);touch(view,3,view.camera_at(),false)
  check(view.drag==-1 and view.touch_id==-1 and view.model.configuration_revision==revision,"cancel and late release preserve model")
  view._press(target+edge);view._notification(Control.NOTIFICATION_APPLICATION_FOCUS_OUT)
  check(view.drag==-1 and view.grab_offset==Vector2.ZERO and view.model.configuration_revision==revision,"focus loss restores pointer preview")
  if view.has_method("bracket_position"):
   var bracket:Vector2=view.bracket_position();var x:float=view.model.bracket_x
   view._press(bracket+Vector2(10,0))
   check(view.bracket_drag and view.grab_offset==Vector2(-10,0),"bracket pickup retains grab offset")
   view._cancel_pointer()
   check(not view.bracket_drag and view.model.bracket_x==x,"bracket cancellation does not commit")
   view._press(bracket+Vector2(10,0));view._release(view.projected(Vector2(65,65))+Vector2(10,0))
   check(is_equal_approx(view.model.bracket_x,65),"bracket committed at actual object anchor")
  # Reused generated objects are tested without synthetic stand-in art for missing parts.
  var visuals=Visuals.new();visuals.art=Art.parts();view.add_child(visuals)
  var before:Dictionary={"slots":view.model.slots.duplicate(),"revision":view.model.configuration_revision,"history":view.model.history.duplicate(true),"completed":view.model.completed,"travel":view.model.travel}
  visuals.sync(view,0,true)
  var identities:Dictionary={}
  for id:String in ["Tabletop","BaffleTray0","BaffleTray1","NotebookCover","RecordsPage","Receipt0","Receipt1","Receipt2","Camera","FeedBase","FeedCap"]:
   check(visuals.objects.has(id),"reused generated independent object exists: "+id)
   if visuals.objects.has(id):
    var body=visuals.objects[id]
    check(body.texture!=null and not identities.has(body.get_instance_id()),"independent raster identity: "+id);identities[body.get_instance_id()]=true
    check(body.rendered_size().x<=body.logical_box_size.x*1.041 and body.rendered_size().y<=body.logical_box_size.y*1.041,"uniform containment: "+id)
  for step:int in 20:visuals.sync(view,.016)
  check(view.model.slots==before.slots and view.model.configuration_revision==before.revision and view.model.history==before.history and view.model.completed==before.completed and view.model.travel==before.travel,"presentation never changes model or completion")
  for factor:float in [.375,.6,1.0]:
   view.scale=Vector2.ONE*factor
   var camera:Vector2=view.camera_at()
   mouse(view,camera,true);mouse(view,camera,false)
   check(view.model.running,"scaled pointer uses actual canvas transform %s"%factor)
   view.model.cancel()
  view.close();view.queue_free()
 for sibling:String in ["recording","sync","platform","signal_sync"]:
  var view=load("res://campuses/future_learning_center/scripts/puzzles/%s_view.gd"%sibling).new()
  root.add_child(view);view.open()
  check(view.visuals==null,"unrelated inherited room does not receive optical sprite scene: "+sibling)
  view._cancel_pointer();view.close();view.queue_free()
 await process_frame
 print("FLC_OPTICAL_SCENE_STATES: %d checks, %d failures"%[checks,failures]);quit(1 if failures else 0)
