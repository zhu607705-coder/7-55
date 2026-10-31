extends SceneTree
const Art=preload("res://campuses/future_learning_center/scripts/puzzles/cable_scene_art.gd")
const SignalView=preload("res://campuses/future_learning_center/scripts/puzzles/signal_sync_view.gd")
const FlexView=preload("res://campuses/future_learning_center/scripts/puzzles/flex_view.gd")
var checks:=0
var failures:=0
func check(ok:bool,label:String)->void:
 checks+=1
 if not ok:failures+=1;push_error("CABLE_ART "+label)
func _initialize()->void:run.call_deferred()
func run()->void:
 check(Art.complete(),"all13 inspected webpage originals present")
 if not Art.complete():quit(1);return
 for key:String in Art.REQUIRED:
  var spec:Dictionary=Art.PARTS[key];var image:Image=spec.texture.get_image()
  check(image!=null and image.has_mipmaps()==false,"original texture available "+key)
  check(Rect2(Vector2.ZERO,spec.texture.get_size()).encloses(spec.region),"crop inside retained source "+key)
  if spec.has("pivot"):check(spec.region.has_point(spec.pivot),"calibrated source pivot inside crop "+key)
 for Type in [SignalView,FlexView]:
  var view=Type.new();root.add_child(view);view.open();view.set_process(false)
  check(view.visuals!=null,"new generated object helper exists")
  if view.visuals==null:continue
  check(view.visuals.light_paths==null,"no inherited optical ray renderer attached")
  var ids:Array[String]=["Tabletop"]
  if Type==SignalView:
   ids.append_array(["SourceCard","Distribution","CacheCard","Monitor0","Monitor1","Notes","Records"])
   for port:String in view.SignalSync.INPUTS+view.SignalSync.OUTPUTS:ids.append("Socket_"+port)
   for input:String in view.SignalSync.INPUTS:ids.append("Plug_"+input)
  else:
   ids.append_array(["Fixture","Handle","Pillar","Adapter","Dock0","Dock1","StarterBase","StarterCap","Notebook","Reel"])
   for i:int in 3:
    ids.append("Plug%d"%i);ids.append("RouteClip%d"%i)
    for side:int in 2:ids.append("Socket%d_%d"%[side,i])
  var seen:Dictionary={}
  for id:String in ids:
   check(view.visuals.objects.has(id),"independent object "+id)
   if not view.visuals.objects.has(id):continue
   var body:Sprite2D=view.visuals.objects[id]
   check(body.texture!=null and not seen.has(body.get_instance_id()),"unique raster object node "+id);seen[body.get_instance_id()]=true
   check(is_equal_approx(body.scale.x,body.scale.y),"uniform source scale "+id)
  for id:String in view.visuals.cables:
   var line:Line2D=view.visuals.cables[id]
   check(line.texture is ImageTexture and line.get("source_texture")==Art.PARTS.cable_strip.texture and line.texture.get_size()==Art.PARTS.cable_strip.region.size,"real original strip texture "+id)
   check(line.texture_mode==Line2D.LINE_TEXTURE_TILE and line.width==8,"tile actual raster at model diameter "+id)
   check(line.joint_mode==Line2D.LINE_JOINT_BEVEL,"no smooth path rounding across obstacle "+id)
  if Type==SignalView:
   for at:Vector2 in [Vector2(610,145),Vector2(800,400),Vector2(700,250)]:
    view.model.move_screen(0,at);view._sync_visuals(0)
    check(view.visuals.objects.Monitor0.position==at,"screen model pose is raster pose")
    check(view.visuals.objects.Socket_screen_a.position==view.port_at("screen_a"),"socket exact center matches model")
    check(view.visuals.cables.Cable_screen_a.points[0]==view.port_at("screen_a"),"cable anchored to actual moving socket")
   var monitor:Sprite2D=view.visuals.objects.Monitor0
   var spec:Dictionary=Art.PARTS.monitor
   var aperture:=Rect2(Vector2(213,374)-spec.pivot,Vector2(826,404))
   aperture=Rect2(aperture.position*monitor.scale,aperture.size*monitor.scale)
   check(aperture.grow(.6).encloses(Rect2(-43,-33,86,58)),"functional screen ink inside actual transparent aperture")
  else:
   var board_id:int=view.visuals.board.get_instance_id()
   for station:int in 2:
    view.model.move_to(station);view.board_display_offset=view.station_offset();view._sync_visuals(0)
    check(view.visuals.board.get_instance_id()==board_id,"station does not duplicate board")
    check(view.visuals.board.position==view.station_offset(),"station visual transform matches hit transform")
    for i:int in 3:
     check(view.visuals.cables["Cable%d"%i].points==view._visible_cable(view.model.cable_path(i)),"raster follows exact model path")
     check(view.visuals.objects["Socket0_%d"%i].position==Vector2(350,view.PORT_Y[i]),"input socket center exact")
     check(view.visuals.objects["Socket1_%d"%i].position==Vector2(610,view.PORT_Y[i]),"output socket center exact")
   view.model.route_cable(1,false);view._sync_visuals(0)
   check(view.model.failure_distance(1)==121,"first contact uses radius-inflated pillar")
   check(view.visuals.objects.Pillar.position==view.Model.PILLAR.get_center(),"pillar raster registered to collision center")
   for i:int in 3:view.model.edit(i,-1)
   view.model.edit(0,1);view.model.set_short(true);view._sync_visuals(0)
   var line:Line2D=view.visuals.cables.Cable0
   check(is_equal_approx(view.model.path_length(line.points),430),"generated short cable has actual430 path pixels")
   check(line.points[-1]==Vector2(606,302),"four-pixel missing reach remains visible")
   check(view.visuals.objects.Plug0.position==line.points[-1],"plug follows physical truncated end, not destination")
   var records:int=view.model.records.size()
   for i:int in 10:view._sync_visuals(.1)
   check(view.model.records.size()==records and not view.model.completed,"visual changes cannot grant completion")
  view.close();view.queue_free()
 await process_frame
 print("FLC_CABLE_GENERATED_ART %d checks; %d failures"%[checks,failures]);quit(1 if failures else 0)
