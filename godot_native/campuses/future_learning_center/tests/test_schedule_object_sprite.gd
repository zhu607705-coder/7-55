extends SceneTree
const ObjectSprite=preload("res://campuses/future_learning_center/scripts/puzzles/schedule_object_sprite.gd")
var checks:=0
var failures:=0
func check(ok:bool,message:String)->void:
 checks+=1
 if not ok:failures+=1;push_error(message)
func _initialize()->void:run.call_deferred()
func run()->void:
 # In-memory test pixels are a geometry fixture only, never shipped artwork.
 var texture:=ImageTexture.create_from_image(Image.create(400,300,false,Image.FORMAT_RGBA8))
 var sprite=ObjectSprite.new();root.add_child(sprite)
 check(sprite.configure(texture,Rect2(20,30,200,100),Vector2(80,70)),"Accept valid original PNG region")
 check(sprite.texture==texture and sprite.region_enabled and sprite.region_rect==Rect2(20,30,200,100),"Keep original texture and exact source region")
 check(sprite.centered and sprite.offset==Vector2.ZERO,"Stable center pivot")
 check(sprite.scale.is_equal_approx(Vector2(.4,.4)),"Uniform containment preserves region aspect")
 check(not sprite.configure(texture,Rect2(350,0,200,100),Vector2(80,70)),"Reject region outside PNG")
 check(not sprite.configure(texture,Rect2(20,30,0,100),Vector2(80,70)),"Reject zero region")
 check(not sprite.configure(texture,Rect2(20,30,200,100),Vector2(-1,70)),"Reject invalid logical box")
 sprite.present(Vector2(100,200))
 check(sprite.position==Vector2(100,200),"First appearance is immediate")
 for i:int in 30:
  var hand:=Vector2(100+i*4.25,200-i*2.1)
  sprite.present(hand,true,1.0)
  check(sprite.position==hand,"Held object follows pointer without lag")
  check(sprite.scale.is_equal_approx(Vector2(.416,.416)),"Held scale bounded to four percent")
  sprite.advance_pose(.08)
  check(sprite.position==hand,"Held pose never drifts after pointer stops")
 sprite.present(Vector2(400,100),false,0)
 var start:Vector2=sprite.position
 for i:int in 12:
  sprite.present(Vector2(400,100),false,0) # render-loop refresh must not restart.
  sprite.advance_pose(.01)
  check(sprite.position.x>=start.x and sprite.position.x<=400 and sprite.position.y>=100 and sprite.position.y<=start.y,"Release settle cannot overshoot either axis")
 check(sprite.position.is_equal_approx(Vector2(400,100)),"Repeated identical target still settles in 120ms")
 check(sprite.scale.is_equal_approx(Vector2(.4,.4)),"Release restores contain scale")
 for i:int in 20:
  var home:=Vector2(i*3,50)
  sprite.present(Vector2(500,300),true,1)
  sprite.present(home,false,0) # Owner's canceled gesture supplies its committed home.
  sprite.advance_pose(.03)
  sprite.present(Vector2(600,200),true,1) # New grab interrupts old settle.
  check(sprite.position==Vector2(600,200),"Rapid regrab interrupts return without stale tween")
  sprite.present(home,false,0);sprite.advance_pose(.12)
  check(sprite.position==home,"Canceled pose returns exactly to supplied home")
 sprite.present(Vector2(200,200),false,0);sprite.set_reduced_motion(true)
 check(sprite.position==Vector2(200,200),"Reduced motion snaps in-flight settle")
 sprite.present(Vector2(300,300),false,1)
 check(sprite.position==Vector2(300,300),"Reduced motion disables future easing")
 sprite.set_reduced_motion(false);sprite.present(Vector2(100,100));sprite.set_presented(false)
 check(not sprite.visible and not sprite.is_processing(),"Hidden object retires animation")
 sprite.set_presented(true);sprite.present(Vector2(700,400))
 check(sprite.position==Vector2(700,400),"Reentry cannot replay old return")
 sprite.present(Vector2(10,10));var before:Vector2=sprite.position
 sprite.advance_pose(-1);check(sprite.position==before,"Invalid negative timestep cannot reverse settling")
 sprite.advance_pose(1);check(sprite.position==Vector2(10,10),"Large timestep lands exactly without overshoot")
 sprite.manual_advance=true
 var detail=ObjectSprite.new();root.add_child(detail);detail.manual_advance=true
 detail.configure(texture,Rect2(0,0,100,100),Vector2(20,20))
 sprite.present(Vector2(200,100),true,0);sprite.present(Vector2(400,300),false,0)
 check(not sprite.is_processing(),"Manual driver cannot double-step through engine process")
 for i:int in 12:
  sprite.advance_visual(.01);detail.present(sprite.position+Vector2(12,-8),true,0)
  check(detail.position==sprite.position+Vector2(12,-8),"Independent grouped object has no frame lag")
 check(sprite.rendered_size().is_equal_approx(Vector2(80,40)),"Exposed rendered size reflects uniform contain")
 check(sprite.logical_box_size==Vector2(80,70),"Retain configured logical box for geometry audit")
 detail.queue_free()
 sprite.queue_free();await process_frame
 print("FLC_SCHEDULE_OBJECT_SPRITE: %d checks, %d failures"%[checks,failures]);quit(1 if failures else 0)
