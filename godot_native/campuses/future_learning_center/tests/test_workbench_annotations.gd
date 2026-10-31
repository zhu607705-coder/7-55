extends SceneTree
## Delivered raster rooms are annotation-free until the player requests notes.
const BASE="res://campuses/future_learning_center/scripts/puzzles/"
const DELIVERED=["collab","assembly","recording","sync","signal_sync","flex","schedule"]
var checks:=0
var failures:=0
func _initialize()->void:run.call_deferred()
func check(ok:bool,label:String)->void:
 checks+=1
 if not ok:failures+=1;push_error(label)
func run()->void:
 for name:String in DELIVERED:
  var view=load(BASE+name+"_view.gd").new();root.add_child(view);view.open();view.set_process(false)
  check(not view.annotations_visible(),name+" default has no written annotations")
  view.model.completed=true
  check(not view.annotations_visible(),name+" completion cannot add persistent captions")
  if name=="flex":
   view.press(Vector2(100,470));check(view.notebook and view.annotations_visible(),"flex physical notebook opens help")
   view.press(Vector2(220,433));check(not view.annotations_visible(),"flex close restores clean view")
  elif name=="schedule":
   view.press_at(Vector2(100,470));check(view.paper_open and view.annotations_visible(),"schedule physical notebook opens help")
   view.press_at(Vector2(100,470));check(not view.annotations_visible(),"schedule close restores clean view")
  else:
   view._press(Vector2(100,470));view._release(Vector2(100,470))
   check(view.hint_level>=0 and view.annotations_visible(),name+" physical paper opens help")
   view.hint_level=-1;view.show_records=true
   check(view.annotations_visible(),name+" requested records remain readable")
   view.show_records=false;check(not view.annotations_visible(),name+" closing notes restores clean view")
  if name=="sync":
   view._sync_visuals(0)
   for marks in view.visuals.print_marks:check(not marks.annotations_visible,"normal tape hides numeric captions but retains event glyphs")
   view.hint_level=0;view._sync_visuals(0)
   for marks in view.visuals.print_marks:check(marks.annotations_visible,"on-demand tape timestamps remain available")
  view.queue_free()
 var print_source:=FileAccess.get_file_as_string(BASE+"recording_print_feedback.gd")
 check(print_source.contains("if annotations_visible:draw_string("),"paper ink renderer guards timestamp text")
 # Platform shares the helper but is not one of the seven delivered raster rooms.
 var prototype=load(BASE+"platform_view.gd").new();root.add_child(prototype)
 check(prototype.annotations_visible(),"unrelated platform subclass retains authored labels");prototype.queue_free()
 # Every text emission in these views routes through guarded helpers.
 for name:String in DELIVERED:
  var source:=FileAccess.get_file_as_string(BASE+name+"_view.gd")
  var direct:=source.count("draw_string(")
  check(direct==(1 if name in ["collab","flex","schedule"] else 0),name+" no unguarded text drawing bypass")
  if direct>0:check(source.contains("if not annotations_visible():return"),name+" draw helper checks on-demand visibility")
 print("FLC_WORKBENCH_ANNOTATIONS %d checks; %d failures"%[checks,failures]);quit(1 if failures else 0)
