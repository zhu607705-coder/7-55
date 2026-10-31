extends SceneTree
## Generated art stays attached to the same physical inputs and output identities.
const View=preload("res://campuses/future_learning_center/scripts/puzzles/schedule_view.gd")
var checks:=0
var failures:=0
func check(ok:bool,message:String)->void:
 checks+=1
 if not ok:failures+=1;push_error(message)
func _initialize()->void:run.call_deferred()
func run()->void:
 var view=View.new();root.add_child(view);view.open()
 var textures:Array=[View.CAMERA_TEXTURE,View.WORKTABLE_TEXTURE,View.GLOVES_TEXTURE]
 var regions:Array=[View.CAMERA_REGION,View.WORKTABLE_REGION,View.GLOVES_REGION]
 var boxes:Array=[Vector2(48,40),Vector2(46,32),Vector2(44,36)]
 textures.append_array(View.ARTIFACT_TEXTURES)
 regions.append_array(View.ARTIFACT_REGIONS)
 boxes.append_array(View.ARTIFACT_BOXES)
 for i:int in textures.size():
  var texture:Texture2D=textures[i]
  var region:Rect2=regions[i]
  var box:Vector2=boxes[i]
  check(texture!=null and texture.get_width()>0,"Generated sprite loads %d"%i)
  check(Rect2(Vector2.ZERO,texture.get_size()).encloses(region),"Source crop inside original image %d"%i)
  var image:Image=texture.get_image()
  check(image!=null and image.get_pixel(0,0).a<.01,"Actual transparent exterior %d"%i)
  var at:=Vector2(33,100)
  var rendered:Rect2=view._sprite_rect(region,at,box)
  check(rendered.get_center().is_equal_approx(at),"Visible sprite centered on existing hit target %d"%i)
  check(rendered.size.x<=box.x+.001 and rendered.size.y<=box.y+.001,"Contained footprint %d"%i)
  check(is_equal_approx(rendered.size.aspect(),region.size.aspect()),"No stretched generated art %d"%i)
 for spec:Array in [[0,Vector2(70,220)],[2,Vector2(220,220)],[-1,Vector2(145,300)]]:
  view.press_at(spec[1]);check(view.held_tool==spec[0],"Visible generated tool remains draggable")
  view._cancel_drag();check(view.held_tool==-2,"Generated tool cancellation clears ownership")
 view.press_at(Vector2(870,470));check(view.held_tool==3,"Generated spare camera remains separate resource")
 view.release_at(Vector2(145,220));check(view.model.cameras==2,"Generated spare camera inserts normally")
 view.close();view.free()
 print("FLC_SCHEDULE_GENERATED_ART: %d checks, %d failures"%[checks,failures]);quit(1 if failures else 0)
