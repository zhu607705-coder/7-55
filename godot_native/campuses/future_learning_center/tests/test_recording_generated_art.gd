extends SceneTree
## Accepted original rasters, independent nodes and model-authoritative presentation.
const Art=preload("res://campuses/future_learning_center/scripts/puzzles/recording_scene_art.gd")
const Recording=preload("res://campuses/future_learning_center/scripts/puzzles/recording_view.gd")
const Sync=preload("res://campuses/future_learning_center/scripts/puzzles/sync_view.gd")
var checks:=0
var failures:=0
func check(ok:bool,label:String)->void:
 checks+=1
 if not ok:failures+=1;push_error("RECORDING_ART "+label)
func _initialize()->void:run.call_deferred()
func run()->void:
 check(Art.complete(),"nine inspected web originals present")
 if not Art.complete():quit(1);return
 for key:String in Art.REQUIRED:
  var spec:Dictionary=Art.PARTS[key]
  var image:Image=spec.texture.get_image()
  check(image!=null and image.get_pixel(0,0).a<.01,"transparent source exterior "+key)
  check(Rect2(Vector2.ZERO,spec.texture.get_size()).encloses(spec.region),"crop within original "+key)
  if spec.has("pivot"):check(spec.region.has_point(spec.pivot),"registered pivot inside crop "+key)
 for Type in [Recording,Sync]:
  var view=Type.new();root.add_child(view);view.open();view.set_process(false)
  check(view.visuals!=null,"independent generated scene enabled")
  if view.visuals==null:continue
  var ids:Array[String]=["Tabletop","NotebookCover","Carriage","Lamp","Endstop"]
  if Type==Recording:ids.append_array(["Rail0","Rail1","BaffleRail","Baffle","Camera","DriveBase","DriveHandle","Handwheel","RecordsPage","PhotoPaper"])
  else:ids.append_array(["PaperGuide0","PaperGuide1","Paper0Tile0","Paper0Tile1","Paper0Tile2","Paper1Tile0","Paper1Tile1","Paper1Tile2","Dropgate","StarterBase","StarterCap","PaperRoll"])
  var seen:Dictionary={}
  for id:String in ids:
   check(view.visuals.objects.has(id),"independent object "+id)
   if not view.visuals.objects.has(id):continue
   var body=view.visuals.objects[id]
   check(body.texture!=null and not seen.has(body.get_instance_id()),"separate raster node "+id);seen[body.get_instance_id()]=true
   check(is_equal_approx(body.scale.x,body.scale.y),"uniform original pixel scale "+id)
  if Type==Recording:
   for y:float in [150,200,250,300]:
    view.model.move_baffle(y);view._sync_visuals(.016)
    check(view.visuals.objects.Baffle.position==Vector2(441,view.model.baffle_y),"baffle center matches model sweep")
   view.model.move_baffle(150);view.model.drive(1)
   for i:int in 12:
    view.model.step(.1);view._sync_visuals(.016)
    check(view.visuals.objects.Carriage.position==Vector2(view.model.x,300),"carriage follows exact model x")
   view.model.pause();var x:float=view.model.x
   for i:int in 10:view._sync_visuals(.1)
   check(view.model.x==x and not view.model.completed,"visual settling cannot move stopped model")
  else:
   for offset:float in [-230,-138,0,92,230]:
    view.model.shift(1,offset);view._sync_visuals(0)
    for tile:int in 3:check(is_equal_approx(view.visuals.objects["Paper1Tile%d"%tile].position.x,view.visuals.PAPER_APERTURE_SIZE.x*.5+(tile-1)*view.visuals.paper_period()+offset),"paper perforations follow offset")
    check(view.visuals.paper_windows[1].size.is_equal_approx(view.visuals.PAPER_APERTURE_SIZE) and view.visuals.paper_windows[1].clip_contents,"paper clip remains fixed")
   view.model.start()
   for i:int in 33:
    view.model.step(.1);view._sync_visuals(.016)
    check(view.visuals.objects.Carriage.position==Vector2(210+view.model.travel*405,388.5),"recorded feed follows model travel")
    check(view.visuals.objects.Dropgate.position==Vector2(527,350+view.model.gate*36),"gate follows exact authoritative phase")
  view.close();view.queue_free()
 await process_frame
 print("FLC_RECORDING_GENERATED_ART %d checks; %d failures"%[checks,failures]);quit(1 if failures else 0)
