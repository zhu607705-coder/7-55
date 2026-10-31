extends SceneTree
var checks:=0
var failures:=0
func check(ok:bool,message:String)->void:
 checks+=1
 if not ok:failures+=1;push_error(message)
func _initialize()->void:run.call_deferred()
func touch(view,at:Vector2,index:int,pressed:bool,canceled:=false)->void:
 var e:=InputEventScreenTouch.new();e.position=view.get_global_transform_with_canvas()*at;e.index=index;e.pressed=pressed;e.canceled=canceled
 view._input(e)
func run()->void:
 for factor:float in [1.0,.626]:
  for round_index:int in 3:
   var collab=load("res://campuses/future_learning_center/scripts/puzzles/collab_view.gd").new()
   root.add_child(collab);collab.position=Vector2(21,44);collab.scale=Vector2.ONE*factor;collab.open()
   var before:Array=collab.model.slots.duplicate()
   touch(collab,collab.position_of(0),5,true)
   check(collab.drag==0,"Scaled collab touch grabs visible part")
   touch(collab,collab.position_of(1),7,true)
   check(collab.drag==0 and collab.touch_id==5,"Second finger cannot steal collab grip")
   touch(collab,collab.projected(collab.Model.SLOT_POINTS[0]),5,false,true)
   check(collab.drag==-1 and collab.model.slots==before,"Canceled scaled collab drop preserves slots")
   touch(collab,Vector2(100,450),5,true);touch(collab,Vector2(100,450),5,false)
   check(collab.hint_level==0,"Visible notebook opens at transformed position")
   collab.close();collab.open();check(collab.drag==-1 and collab.touch_id==-1,"Collab reentry clears pointer")
   collab.queue_free();await process_frame
   var logic=load("res://campuses/future_learning_center/scripts/puzzles/logic_view.gd").new()
   root.add_child(logic);logic.position=Vector2(21,44);logic.scale=Vector2.ONE*factor;logic.open()
   touch(logic,Vector2(80,150),5,true)
   check(logic.drag=="card0","Scaled logic touch grabs visible circuit card")
   touch(logic,Vector2(80,245),7,true)
   check(logic.drag=="card0" and logic.touch_id==5,"Second finger cannot steal logic card")
   touch(logic,logic.SLOT.get_center(),5,false,true)
   check(logic.model.card==-1 and logic.drag=="","Canceled scaled logic drop cannot install card")
   touch(logic,Vector2(80,150),5,true);touch(logic,logic.SLOT.get_center(),5,false)
   check(logic.model.card==0,"Scaled circuit card drops into visible socket")
   touch(logic,Vector2(100,450),5,true);touch(logic,Vector2(100,450),5,false)
   check(logic.hints==0,"Logic help remains reachable")
   logic.close();logic.open();check(logic.model.card==0 and logic.drag=="","Logic reentry preserves assembly without pointer")
   logic.queue_free();await process_frame
 print("FLC_UPPER_OBJECT_MAPPING: %d checks, %d failures"%[checks,failures]);quit(1 if failures else 0)
