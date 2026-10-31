extends SceneTree
var checks:=0
var failures:=0
func check(ok:bool,message:String)->void:
 checks+=1
 if not ok:failures+=1;push_error(message)
func _initialize()->void:run.call_deferred()
func touch(view,at:Vector2,index:int,pressed:bool,canceled:=false)->void:
 var e:=InputEventScreenTouch.new();e.position=view.get_global_transform_with_canvas()*at;e.index=index;e.pressed=pressed;e.canceled=canceled
 root.push_input(e)
func run()->void:
 for factor:float in [1.0,.626]:
  for attempt:int in 3:
   var view=load("res://campuses/future_learning_center/scripts/puzzles/schedule_view.gd").new()
   root.add_child(view);view.position=Vector2(21,44);view.scale=Vector2.ONE*factor;view.open()
   var crank:=Vector2(870,340)
   touch(view,crank,1,true);check(not view.model.running,"Crank waits for owned release")
   touch(view,crank,2,true);touch(view,crank,2,false)
   check(not view.model.running and view.touch_id==1,"Other finger cannot release crank")
   touch(view,crank,1,false,true);touch(view,crank,1,false)
   check(not view.model.running,"Canceled and late crank releases do nothing")
   touch(view,crank,1,true);view._notification(Node.NOTIFICATION_APPLICATION_FOCUS_OUT);touch(view,crank,1,false)
   check(not view.model.running,"Focus-loss release cannot start trial")
   touch(view,crank,1,true);touch(view,crank,1,false)
   check(view.model.running,"Ordinary owned crank release starts trial")
   view.model.cancel();view.model.place(0,1)
   touch(view,Vector2(238,471),1,true);touch(view,Vector2(238,471),1,false,true)
   check(view.model.slots[0]==1,"Canceled wrench keeps edit")
   touch(view,Vector2(238,471),1,true);touch(view,Vector2(238,471),1,false)
   check(view.model.slots[0]==0,"Owned wrench release restores edit")
   touch(view,Vector2(100,460),1,true);touch(view,Vector2(100,460),1,false,true)
   check(not view.paper_open,"Canceled notebook stays closed")
   view.close();view.queue_free();await process_frame
   view=load("res://campuses/future_learning_center/scripts/puzzles/collab_view.gd").new()
   root.add_child(view);view.position=Vector2(21,44);view.scale=Vector2.ONE*factor;view.open()
   var lamp:Vector2=view.lamp_at(1);var old:int=view.model.condition
   touch(view,lamp,1,true);check(view.model.condition==old,"Lamp waits for release")
   touch(view,lamp,2,true);touch(view,lamp,2,false);touch(view,lamp,1,false,true);touch(view,lamp,1,false)
   check(view.model.condition==old,"Canceled lamp and second finger preserve condition")
   touch(view,lamp,1,true);view._notification(Node.NOTIFICATION_APPLICATION_FOCUS_OUT);touch(view,lamp,1,false)
   check(view.model.condition==old,"Focus-loss lamp release does nothing")
   view.model.resume();touch(view,lamp,1,true);touch(view,lamp,1,false)
   check(view.model.condition==1,"Owned lamp release changes condition")
   view.close();view.queue_free();await process_frame
   view=load("res://campuses/future_learning_center/scripts/puzzles/logic_view.gd").new()
   root.add_child(view);view.position=Vector2(21,44);view.scale=Vector2.ONE*factor;view.open()
   var swap:=Vector2(800,200)
   touch(view,swap,1,true);check(not view.model.swapped,"Input plugs wait for release")
   touch(view,swap,2,true);touch(view,swap,2,false);touch(view,swap,1,false,true);touch(view,swap,1,false)
   check(not view.model.swapped,"Canceled plug swap and second finger do nothing")
   touch(view,swap,1,true);view._notification(Node.NOTIFICATION_APPLICATION_FOCUS_OUT);touch(view,swap,1,false)
   check(not view.model.swapped,"Focus-loss swap release does nothing")
   view.model.resume();touch(view,swap,1,true);touch(view,swap,1,false)
   check(view.model.swapped,"Owned release swaps plugs")
   view.close();view.queue_free();await process_frame
 for factor:float in [1.0,.626]:
  for spec:Array in [["balance",Vector2(315,402),"pivot"],["rules",Vector2(100,475),"paper_open"],["storage",Vector2(100,450),"notebook"],["flex",Vector2(220,470),"short_cable"]]:
   var view=load("res://campuses/future_learning_center/scripts/puzzles/%s_view.gd"%spec[0]).new()
   root.add_child(view);view.position=Vector2(21,44);view.scale=Vector2.ONE*factor;view.open()
   var source=view.model if spec[2] in ["pivot","short_cable"] else view
   var before=source.get(spec[2]);var at:Vector2=spec[1]
   touch(view,at,1,true);check(source.get(spec[2])==before,"%s action waits for release"%spec[0])
   touch(view,at,2,true);touch(view,at,2,false);touch(view,at,1,false,true);touch(view,at,1,false)
   check(source.get(spec[2])==before,"%s cancel/late release/second finger preserves state"%spec[0])
   touch(view,at,1,true);view._notification(Node.NOTIFICATION_APPLICATION_FOCUS_OUT);touch(view,at,1,false)
   check(source.get(spec[2])==before,"%s focus loss retires action"%spec[0])
   touch(view,at,1,true);touch(view,at,1,false)
   check(source.get(spec[2])!=before,"%s valid owned release commits"%spec[0])
   if spec[0]=="flex":
    var connections:Array=view.model.connections.duplicate();var port:=Vector2(610,view.PORT_Y[1])
    touch(view,port,1,true)
    check(view.model.connections==connections,"Receiver grab previews without unplugging")
    touch(view,Vector2(500,400),1,false,true);touch(view,Vector2(500,400),1,false)
    check(view.model.connections==connections,"Canceled receiver drag preserves cable and late release")
   view.close();view.queue_free();await process_frame
 print("FLC_UPPER_TOUCH_ACTIONS: %d checks, %d failures"%[checks,failures]);quit(1 if failures else 0)
