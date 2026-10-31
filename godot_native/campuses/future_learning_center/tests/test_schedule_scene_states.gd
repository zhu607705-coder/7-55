extends SceneTree
## Deterministic presentation contracts. Run only with the integrated, generated
## scene-part assets. No stand-in textures or screenshot-pixel snapshots.
const View=preload("res://campuses/future_learning_center/scripts/puzzles/schedule_view.gd")
var checks:=0
var failures:=0
class SaveSentinel extends Node:
 var d:Dictionary={"native":{"settings":{"reduced_motion":false},"presentation_test_marker":731}}
func check(ok:bool,message:String)->void:
 checks+=1
 if not ok:failures+=1;push_error(message)
func _initialize()->void:run.call_deferred()
func model_snapshot(model)->Dictionary:
 var result:Dictionary={}
 for property:String in ["slots","tools","cameras","revision","running","paused","beat","progress","artifacts","errors","current_tasks","records","completed","extension_completed","_trial_revision","_invalid","_undo"]:
  result[property]=model.get(property)
 return result.duplicate(true)
func object(view,id:String):return view.visuals.objects[id]
func check_group(view,task:int,center:Vector2)->void:
 check(object(view,"TaskCard%d"%task).position.is_equal_approx(center),"Task body follows the exact visible hand anchor")
 check(object(view,"TaskArtifact%d"%task).position.is_equal_approx(center+Vector2(-35,10)),"Artifact shares card pose with no frame lag")
 check(object(view,"AssignedTool%d"%task).position.is_equal_approx(center+Vector2(33,10)),"Assigned tool shares card pose with no frame lag")
func run()->void:
 var sentinel:Node=null
 var state=root.get_node_or_null("State")
 if state==null:
  sentinel=SaveSentinel.new();sentinel.name="State";root.add_child(sentinel);state=sentinel
 var saved_before:Dictionary=state.d.duplicate(true)
 var view=View.new();root.add_child(view);view.set_process(false);view.open();view._sync_visuals(0)
 var ids:Array[String]=["Tabletop","ScheduleBoard","ToolTray","StarterBase","StarterCap","UndoWrench","NotebookCover","NotebookPage","ReserveDock","ReserveCamera"]
 for task:int in 4:
  for prefix:String in ["TaskCard","TaskArtifact","AssignedTool","OutputDock","Output"]:ids.append(prefix+str(task))
 var instances:Dictionary={}
 for id:String in ids:
  check(view.visuals.objects.has(id),"Independent object exists: "+id)
  if not view.visuals.objects.has(id):continue
  var node=object(view,id)
  check(node is Sprite2D and node.get_parent()==view.visuals,"Object is an independent Sprite2D: "+id)
  check(not instances.has(node.get_instance_id()),"Object identity is not shared: "+id);instances[node.get_instance_id()]=true
  check(node.region_enabled and node.texture!=null,"Object retains a generated texture region: "+id)
  var extent:Vector2=node.rendered_size()
  check(extent.x<=node.logical_box_size.x*1.04001 and extent.y<=node.logical_box_size.y*1.04001,"Uniform contained extent stays within lift bound: "+id)
 if failures:
  view.queue_free()
  if sentinel:sentinel.queue_free()
  await process_frame;print("FLC_SCHEDULE_SCENE_STATES: %d checks, %d failures"%[checks,failures]);quit(1);return
 # Edge pickup keeps the visible anchor, rather than snapping a card to its center.
 var start:Vector2=view.card_visual_point(0)
 var edge:=Vector2(75,20)
 var slots_before:Array=view.model.slots.duplicate()
 view._pointer_press(start+edge)
 check(view.held_task==0 and view.task_grab_offset.is_equal_approx(-edge),"Edge pickup records card-to-pointer offset")
 for pointer_at:Vector2 in [Vector2(450,170),Vector2(500,190),Vector2(575,162)]:
  view.pointer=pointer_at;view._sync_visuals(.016)
  check_group(view,0,pointer_at-edge)
  check(view.model.slots==slots_before,"Held preview does not edit authoritative slots")
 var released_from:Vector2=view.card_visual_point(0)
 view._pointer_release(view.pointer)
 check(view.model.slots[0]==1 and view.held_task==-1,"Owned release commits destination slot once")
 var destination:Vector2=view.card_point(0)
 view._sync_visuals(0)
 var previous:Vector2=released_from
 for i:int in 12:
  view._sync_visuals(.01)
  var current:Vector2=view.card_visual_point(0)
  check(current.x>=minf(released_from.x,destination.x)-.001 and current.x<=maxf(released_from.x,destination.x)+.001,"Release x stays between hand and slot")
  check(current.y>=minf(released_from.y,destination.y)-.001 and current.y<=maxf(released_from.y,destination.y)+.001,"Release y stays between hand and slot")
  check(current.distance_to(destination)<=previous.distance_to(destination)+.001,"Release settles monotonically")
  check_group(view,0,current);previous=current
 check(view.card_visual_point(0).is_equal_approx(destination),"Release settles at authoritative slot within120ms")
 # Start another settle, then pick the drawn card before it reaches its new slot.
 view._pointer_press(destination+edge);view.pointer=Vector2(650,142)+edge;view._sync_visuals(0)
 view._pointer_release(view.pointer);view._sync_visuals(.02)
 var drawn:Vector2=view.card_visual_point(0)
 view._pointer_press(drawn-edge)
 check(view.held_task==0 and view.task_grab_offset.is_equal_approx(edge),"Regrab uses drawn card hot rectangle during settling")
 view.pointer=Vector2(400,250);view._sync_visuals(.01);check_group(view,0,view.pointer+edge)
 var committed_slots:Array=view.model.slots.duplicate()
 view._cancel_drag();view._sync_visuals(0)
 check(view.model.slots==committed_slots,"Cancel does not rewrite committed layout")
 check_group(view,0,view.card_point(0))
 # Tools have an exact hand offset, a short return, and a visible regrab target.
 var glove_home:=Vector2(145,300)
 var tool_edge:=Vector2(12,7)
 var tools_before:Array=view.model.tools.duplicate()
 view._pointer_press(glove_home+tool_edge)
 check(view.held_tool==-1 and view.tool_grab_offset.is_equal_approx(-tool_edge),"Tool edge pickup preserves its hand anchor")
 view.pointer=Vector2(260,360)+tool_edge;view._sync_visuals(.016)
 check(object(view,"HeldTool").position.is_equal_approx(Vector2(260,360)),"Held tool follows pointer exactly without easing")
 check(view.model.tools==tools_before,"Tool preview does not mutate assigned tools")
 view._pointer_release(view.pointer);view._sync_visuals(.02)
 check(view.model.tools==tools_before and object(view,"SettlingTool").visible,"Invalid tool drop returns without changing assignments")
 var returning:Vector2=object(view,"SettlingTool").position
 check(returning.distance_to(glove_home)<Vector2(260,360).distance_to(glove_home),"Tool return makes continuous progress toward home")
 view._pointer_press(returning)
 check(view.held_tool==-1,"Returning tool is picked at its visible position")
 view.pointer=Vector2(280,380);view._sync_visuals(.016)
 check(object(view,"HeldTool").position.is_equal_approx(Vector2(280,380)),"Regrab interrupts old tool return with no frame lag")
 check(not object(view,"SettlingTool").visible,"Old settling copy disappears upon regrab")
 view._cancel_drag();view._sync_visuals(0)
 check(view.model.tools==tools_before and not object(view,"HeldTool").visible and not object(view,"SettlingTool").visible,"Canceled tool regrab preserves assignments and retires hand copies")
 # Successful tool delivery moves from the visible drop to the assigned seat.
 var camera_home:=Vector2(70,220)
 view._pointer_press(camera_home+tool_edge)
 var task_target:Vector2=view.card_visual_point(1)
 view.pointer=task_target+tool_edge;view._sync_visuals(0)
 view._pointer_release(view.pointer);view._sync_visuals(0)
 check(view.model.tools[1]==0,"Qualified tool release assigns the actual camera")
 var tool_destination:Vector2=task_target+Vector2(33,10)
 var prior_distance:float=object(view,"SettlingTool").position.distance_to(tool_destination)
 for i:int in 12:
  view._sync_visuals(.01)
  var current_distance:float=object(view,"SettlingTool").position.distance_to(tool_destination)
  check(current_distance<=prior_distance+.001,"Tool seat settle has no backward motion or overshoot")
  prior_distance=current_distance
 # The authored settle is .12s; allow the next frame under the .15s contract.
 view._sync_visuals(.03)
 check(not object(view,"SettlingTool").visible and object(view,"AssignedTool1").visible,"Assigned tool replaces settling copy within150ms")
 check(object(view,"AssignedTool1").position.is_equal_approx(tool_destination),"Assigned tool ends exactly at its card seat")
 # Physical starter motion is feedback only. Press/cancel never starts a model.
 var crank:=Vector2(870,340)
 var cap_up:Vector2=object(view,"StarterCap").position
 view._pointer_press(crank);view._sync_visuals(.04)
 check(not view.model.running and view.pending_tap=="crank","Starter down is a pending owned action")
 check(object(view,"StarterCap").position.y>cap_up.y,"Starter cap visibly depresses while pending")
 view._cancel_drag();view._sync_visuals(0)
 check(not view.model.running and object(view,"StarterCap").position.is_equal_approx(cap_up),"Canceled starter returns without starting")
 view._pointer_press(crank);view._pointer_release(crank);view._sync_visuals(.12)
 check(view.model.running,"Starter starts only on qualified release")
 var cap_down:Vector2=object(view,"StarterCap").position
 check(cap_down.y>cap_up.y,"Running state retains depressed cap")
 view.model.pause();view._sync_visuals(.12)
 check(object(view,"StarterCap").position.is_equal_approx(cap_up),"Paused state releases cap")
 view.model.resume();view._sync_visuals(.12)
 check(object(view,"StarterCap").position.is_equal_approx(cap_down),"Resumed state depresses cap again")
 view.model.cancel()
 # Generated paper moves continuously; reduced motion eliminates interpolation.
 view.paper_open=true;view._sync_visuals(.04)
 var opened:float=view.visuals.page_amount
 check(opened>0 and opened<1 and object(view,"NotebookPage").visible,"Notebook begins continuous opening")
 view._sync_visuals(.04);check(view.visuals.page_amount>opened and view.visuals.page_amount<1,"Notebook opening has intermediate states")
 var half_open:float=view.visuals.page_amount
 view.paper_open=false;view._sync_visuals(.04)
 check(view.visuals.page_amount>0 and view.visuals.page_amount<half_open,"Closing reverses from current page state")
 view._sync_visuals(.2);check(view.visuals.page_amount==0 and not object(view,"NotebookPage").visible,"Closed generated page is hidden")
 view.reduced_motion=true;view.paper_open=true;view._sync_visuals(0)
 check(view.visuals.page_amount==1,"Reduced motion opens notebook immediately")
 view.paper_open=false;view._sync_visuals(0);check(view.visuals.page_amount==0,"Reduced motion closes notebook immediately")
 view.reduced_motion=false
 # Test fixtures supply artifact facts; the renderer may only display them.
 view.model.artifacts.assign([false,false,false,false]);view._sync_visuals(0)
 for task:int in 4:check(not object(view,"Output%d"%task).visible,"Output absent before model artifact exists")
 view.model.artifacts[0]=true
 var authority_before:Dictionary=model_snapshot(view.model)
 for i:int in 20:view._sync_visuals(.02)
 check(object(view,"Output0").visible and not object(view,"Output1").visible,"Only authorized artifact is displayed")
 check(model_snapshot(view.model)==authority_before and not view.model.completed,"Animation never advances model or fabricates completion")
 check(state.d==saved_before,"Presentation never writes save authority")
 # Close/reentry retires both pointer ownership and stale returning poses.
 view._pointer_press(view.card_visual_point(0)+edge);view.pointer=Vector2(350,350);view._sync_visuals(.016)
 var reentry_slots:Array=view.model.slots.duplicate()
 view.close();view.open();view._sync_visuals(0)
 check(view.held_task==-1 and view.touch_id==-1 and not view.mouse_owned,"Reentry has no old hand ownership")
 check(view.model.slots==reentry_slots,"Reentry preserves committed slots")
 check_group(view,0,view.card_point(0));view._sync_visuals(.15);check_group(view,0,view.card_point(0))
 check(state.d==saved_before,"Reentry presentation leaves saved state unchanged")
 view.queue_free()
 if sentinel:sentinel.queue_free()
 await process_frame
 print("FLC_SCHEDULE_SCENE_STATES: %d checks, %d failures"%[checks,failures]);quit(1 if failures else 0)
