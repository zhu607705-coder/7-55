extends SceneTree
const Model=preload("res://campuses/future_learning_center/scripts/puzzles/schedule_model.gd")
var checks:=0
var failures:=0
func check(value:bool,message:String)->void:
 checks+=1
 if not value:failures+=1;push_error(message)
func finish(model)->void:
 for i:int in 30:model.step(.1)
func _initialize()->void:call_deferred("run")
func run()->void:
 var model=Model.new();model.start();finish(model)
 check(not model.completed,"Same-beat assembly cannot feed photo")
 check(model.errors[2]!="","Missing predecessor remains visible")
 model.place(2,1);model.place(3,2);model.start();finish(model)
 check(model.completed and model.artifacts[3],"Three-beat parallel plan produces comparison")
 var successes:=0
 for a:int in 3:
  for b:int in 3:
   for c:int in 3:
    for d:int in 3:
     var trial=Model.new();trial.slots.assign([a,b,c,d]);trial.start();finish(trial)
     if trial.completed:successes+=1
 check(successes==1,"All 81 schedules enumerated; single-camera dependency-safe solution")
 model=Model.new();model.set_second_camera(true);model.slots.assign([1,0,1,2]);model.connect_tool(2,1);model.start();finish(model)
 check(model.extension_completed,"Two cameras allow parallel photos after assembly")
 model=Model.new();model.set_second_camera(true);model.slots.assign([0,0,0,1]);model.connect_tool(2,1);model.start();finish(model)
 check(not model.completed,"Extra camera cannot remove causal dependency")
 model=Model.new();model.set_second_camera(true);model.slots.assign([1,0,1,2]);model.start();finish(model)
 check(not model.completed and model.errors[0]=="tool_busy" and model.errors[2]=="tool_busy","Same physical camera cannot serve two tasks")
 model=Model.new();model.place(2,1);model.place(3,2);model.start();model.step(.1);model.pause();var progress:float=model.progress;finish(model)
 check(model.progress==progress and model.records.is_empty(),"Pause freezes trial")
 model.resume();model.step(.1);check(model.progress>progress,"Resume continues")
 model.place(0,1);check(not model.running and model.artifacts==[false,false,false,false],"Edit cancels stale outputs")
 check(model.undo() and model.slots[0]==0,"Wrench undo restores physical scheduling")
 model.start();model.cancel();finish(model);check(model.records.is_empty(),"Close cannot finish trial")
 check(not model.place(-1,0) and not model.place(0,3),"Reject outside-board tasks")
 check(not model.connect_tool(0,1),"Cannot use absent second camera")
 if "--with-view" in OS.get_cmdline_user_args():await view_checks()
 print("FLC_SCHEDULE: %d checks, %d failures"%[checks,failures]);quit(1 if failures else 0)

func view_checks()->void:
 var view=load("res://campuses/future_learning_center/scripts/puzzles/schedule_view.gd").new()
 root.add_child(view);view.open()
 view.press_at(view.card_point(2));view.release_at(Vector2(545,282))
 check(view.model.slots[2]==1,"Dragging task changes its real beat")
 view.press_at(view.card_point(3));view.release_at(Vector2(720,352))
 check(view.model.slots[3]==2,"Comparison task moves independently")
 view.press_at(Vector2(220,220));view.release_at(view.card_point(0))
 check(view.model.tools[0]==2,"Tool magnet physically attaches to selected task")
 view.press_at(Vector2(238,471));check(view.model.tools[0]==0,"Wrench restores previous tool")
 view.press_at(Vector2(870,470));view.release_at(Vector2(145,220))
 check(view.model.cameras==2,"Dragging spare camera adds actual resource")
 view.press_at(Vector2(870,340));check(view.model.running,"Clockwork handle starts trial")
 view.press_at(Vector2(870,340));check(view.model.paused,"Handle pauses without completing")
 view.press_at(Vector2(870,340));check(not view.model.paused,"Handle resumes same trial")
 view._notification(Node.NOTIFICATION_APPLICATION_FOCUS_OUT)
 check(view.model.paused,"Focus loss stops production")
 var event:=InputEventScreenTouch.new();event.index=2;event.position=view.card_point(0);event.pressed=true;view._input(event)
 event=InputEventScreenTouch.new();event.index=3;event.position=view.card_point(1);event.pressed=true;view._input(event)
 check(view.touch_id==2 and view.held_task==0,"Second touch cannot steal task")
 var mouse:=InputEventMouseButton.new();mouse.device=InputEvent.DEVICE_ID_EMULATION;mouse.pressed=true;mouse.button_index=MOUSE_BUTTON_LEFT;mouse.position=Vector2(238,471);view._input(mouse)
 check(view.held_task==0,"Synthetic mouse does not duplicate touch")
 event=InputEventScreenTouch.new();event.index=2;event.canceled=true;event.position=Vector2(720,142);view._input(event)
 check(view.model.slots[0]==0 and view.held_task==-1,"Cancel does not place task at release point")
 view.close();check(not view.visible and not view.model.running,"Close never earns production result")
 view.queue_free();await process_frame
