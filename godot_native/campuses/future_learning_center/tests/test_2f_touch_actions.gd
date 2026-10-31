extends SceneTree
## Real viewport routing at desktop and scaled phone apparatus sizes.
var checks:=0
var failures:=0
func check(ok:bool,message:String)->void:
 checks+=1
 if not ok:failures+=1;push_error(message)
func _initialize()->void:run.call_deferred()
func touch(view,at:Vector2,index:int,pressed:bool,canceled:=false)->void:
 var event:=InputEventScreenTouch.new()
 event.position=view.get_global_transform_with_canvas()*at;event.index=index;event.pressed=pressed;event.canceled=canceled
 root.push_input(event)
func run()->void:
 root.size=Vector2i(1280,720)
 var specs:Array=[
  ["koala",Vector2(580,150),"paper_open",false],
  ["koala",Vector2(870,270),"running",true],
  ["koala",Vector2(870,480),"revision",true],
  ["koala",Vector2(302,380),"card",true],
  ["robotics",Vector2(100,490),"paper_open",false],
  ["robotics",Vector2(130,427),"running",true],
  ["robotics",Vector2(225,427),"run_id",true],
  ["robotics",Vector2(855,490),"revision",true],
  ["solid_projection",Vector2(540,412),"observation",true],
  ["solid_projection",Vector2(125,136),"bar_turn",true],
  ["solid_projection",Vector2(100,490),"paper_open",false],
  ["solid_projection",Vector2(240,490),"revision",true],
  ["solid_projection",Vector2(830,470),"running",true],
  ["formula",Vector2(835,93),"scenario",true],
  ["machinery",Vector2(100,470),"notebook",false],
  ["platform",Vector2(90,190),"condition",true],
  ["signal_sync",Vector2(150,225),"source_pattern",true]]
 for factor:float in [1.0,.626]:
  for attempt:int in 3:
   for spec:Array in specs:
    var view=load("res://campuses/future_learning_center/scripts/puzzles/%s_view.gd"%spec[0]).new()
    root.add_child(view);view.position=Vector2(21,44);view.scale=Vector2.ONE*factor;view.open()
    if spec[2]=="revision":
     if spec[0]=="koala":view.model.attach(0,0)
     elif spec[0]=="robotics":view.model.edit("selector",1)
     elif spec[0]=="solid_projection":view.model.rotate_bar()
    var source=view.model if spec[3] else view
    var before=source.get(spec[2]);var at:Vector2=spec[1]
    touch(view,at,1,true)
    check(source.get(spec[2])==before,"%s %s waits for release"%[spec[0],spec[2]])
    touch(view,at,2,true);touch(view,at,2,false)
    check(source.get(spec[2])==before and view.touch_id==1,"%s second finger cannot commit"%spec[0])
    touch(view,at,1,false,true);touch(view,at,1,false)
    check(source.get(spec[2])==before,"%s cancel and late release preserve state"%spec[0])
    touch(view,at,1,true);view._notification(Node.NOTIFICATION_APPLICATION_FOCUS_OUT);touch(view,at,1,false)
    check(source.get(spec[2])==before,"%s focus loss retires pending action"%spec[0])
    touch(view,at,1,true);touch(view,at+Vector2(80,60),1,false)
    check(source.get(spec[2])==before,"%s release away does not commit"%spec[0])
    if view.model.has_method("resume"):view.model.resume()
    touch(view,at,1,true);touch(view,at,1,false)
    check(source.get(spec[2])!=before,"%s owned same-target release commits"%spec[0])
    view.close();view.queue_free();await process_frame
 print("FLC_2F_TOUCH_ACTIONS: %d checks, %d failures"%[checks,failures]);quit(1 if failures else 0)
