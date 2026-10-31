extends SceneTree
## Full generated-art acceptance: intentionally fails until all originals are present.
const Art=preload("res://campuses/future_learning_center/scripts/puzzles/optical_scene_art.gd")
const Collab=preload("res://campuses/future_learning_center/scripts/puzzles/collab_view.gd")
const Assembly=preload("res://campuses/future_learning_center/scripts/puzzles/assembly_view.gd")
var checks:=0
var failures:=0
func check(ok:bool,label:String)->void:
 checks+=1
 if not ok:failures+=1;push_error("OPTICAL_ART "+label)
func _initialize()->void:run.call_deferred()
func run()->void:
 check(Art.complete(),"all eleven inspected web-generated optical originals are present")
 if not Art.complete():quit(1);return
 for key:String in Art.REQUIRED:
  var spec:Dictionary=Art.OPTICAL_PARTS[key]
  var image:Image=spec.texture.get_image()
  check(image!=null and image.get_pixel(0,0).a<.01,"transparent source exterior: "+key)
  check(Rect2(Vector2.ZERO,spec.texture.get_size()).encloses(spec.region),"source crop within original: "+key)
  if spec.has("pivot"):check(spec.region.has_point(spec.pivot),"registered pivot within crop: "+key)
 for Type in [Collab,Assembly]:
  var view=Type.new();root.add_child(view);view.open();view.set_process(false)
  check(view.visuals!=null,"complete artwork activates independent sprite scene")
  if view.visuals==null:continue
  check(view.visuals.light_paths.get_index()>view.visuals.objects.Fixture.get_index() and view.visuals.light_paths.get_index()<view.visuals.objects.Baffle0.get_index(),"light paths lie above deck and below solid components")
  var ids:Array[String]=["Fixture","Socket0","Socket1","Socket2","Socket3","Baffle0","Baffle1","Lamp0","Lamp1","Carriage","FeedRail0","FeedRail1","Target","QuarterControl"]
  if view.has_method("bracket_position"):ids.append_array(["Bracket","SupportRail"])
  var seen:Dictionary={}
  for id:String in ids:
   check(view.visuals.objects.has(id),"independent generated object: "+id)
   if not view.visuals.objects.has(id):continue
   var body=view.visuals.objects[id]
   check(body.texture!=null and not seen.has(body.get_instance_id()),"separate sprite and raster: "+id);seen[body.get_instance_id()]=true
  for turn:int in 4:
   view._sync_visuals(.2)
   check(view.visuals.objects.Fixture.rotation==0,"fixture deck does not rotate with rig")
   for slot:int in 4:check(view.visuals.object_at("Socket%d"%slot,Vector2.INF).is_equal_approx(view.projected(view.Model.SLOT_POINTS[slot])),"fixed socket matches authoritative slot")
   check(view.visuals.object_at("Lamp0",Vector2.INF).is_equal_approx(view.lamp_at(0)),"lamp follows authoritative quarter index")
   view.model.rotate_fixture()
  view.model.place(0,1)
  var camera_source:Vector2=view.model.rotate_point(Vector2(0,-210))
  check(view.visuals.light_paths.clipped_end(camera_source).is_equal_approx(Vector2(0,-110)),"camera sight line stops at its actual obstruction")
  view.model.place(0,0);view._sync_visuals(.2);view._sync_visuals(.2)
  var anchor:Vector2=view.position_of(0)
  var body:Sprite2D=view.visuals.objects.Baffle0
  var local_rect:Rect2=body.get_rect()
  var top:Vector2=view.get_global_transform().affine_inverse()*body.to_global(local_rect.position+local_rect.size*Vector2(.5,.15))
  check(view.visuals.hit("Baffle0",top),"upper visible edge baffle is part of picking footprint")
  view._press(top)
  check(view.drag==0,"upper visible edge baffle can be grabbed")
  var revision:int=view.model.configuration_revision
  for point:Vector2 in [Vector2(380,230),Vector2(410,300),Vector2(420,350)]:
   view.pointer=point;view._sync_visuals(.016)
   check(view.visuals.object_at("Baffle0",Vector2.INF).is_equal_approx(point+view.grab_offset),"held baffle follows pointer exactly without tween lag")
   check(view.model.configuration_revision==revision,"drag motion does not commit model")
  view._cancel_pointer()
  check(view.visuals.object_at("Baffle0",Vector2.INF).is_equal_approx(view.logical_position_of(0)),"cancel snaps to authoritative insertion point")
  view.model.start("feed")
  for step:int in 8:
   view.model.step(.1);view._sync_visuals(.016)
   var start:Vector2=view.projected(view.model.rotate_point(Vector2(0,210)))
   check(view.visuals.object_at("Carriage",Vector2.INF).is_equal_approx(start.lerp(view.CENTER,view.model.travel)),"carriage uses exact model travel every frame")
  view.model.pause();var travel:float=view.model.travel
  for step:int in 10:view._sync_visuals(.016)
  check(view.model.travel==travel,"presentation cannot move paused carriage")
  if view.has_method("bracket_position"):
   view.model.cancel();view.model.place(0,0);view.model.place(1,2);view.model.set_bracket(0,false);view._sync_visuals(0)
   check(view.visuals.light_paths.lamp_end(0)==Vector2.ZERO and view.visuals.light_paths.lamp_end(1)==Vector2.ZERO,"removed support permits actual side light despite retained slot state")
   view.model.set_bracket(0,true);view.model.place(1,3);view._sync_visuals(.2);view._sync_visuals(.2)
   view._press(view.position_of(1))
   check(view.drag==1 and not view.bracket_drag,"bracket touch padding cannot steal visible neighbouring baffle")
   view._cancel_pointer()
  view.close();view.queue_free()
 await process_frame
 print("FLC_OPTICAL_GENERATED_ART: %d checks, %d failures"%[checks,failures]);quit(1 if failures else 0)
