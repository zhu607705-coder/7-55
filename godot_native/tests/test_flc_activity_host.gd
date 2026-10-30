extends SceneTree
## The normal entry button owns a real Main activity, not the sample launcher.
var checks:=0
var failures:=0
var state:Node
class SaveBridge extends Node:
 var pending:=false
 var acknowledged:=""
 var error:=""
 var fail:=false
 var ticks:=0
 var digest:=""
 func request_save()->void:pending=true;ticks=0;acknowledged="";error=""
 func _process(_dt:float)->void:
  if not pending:return
  ticks+=1
  if ticks>=3:
   pending=false
   if fail:error="storage_unavailable"
   else:acknowledged=digest
 func read_save_persistence()->Dictionary:return {"pending":pending,"acknowledgedDigest":acknowledged,"error":error}
func _initialize()->void:run.call_deferred()
func check(ok:bool,message:String)->void:
 checks+=1
 if not ok:failures+=1;push_error("FLC HOST: "+message)
func frames(count:=4)->void:
 for i:int in count:await process_frame
func story_snapshot()->Dictionary:
 var result:Dictionary=state.d.duplicate(true)
 # Optional exploration has its own bounded checkpoint, not story progress.
 result.native.erase("flc_rooms")
 return result
func click(button:Button)->void:
 var point:Vector2=button.get_global_transform_with_canvas()*(button.size/2)
 for pressed:bool in [true,false]:
  var event:=InputEventMouseButton.new();event.position=point;event.button_index=MOUSE_BUTTON_LEFT;event.pressed=pressed;root.push_input(event)
 await frames()
func run()->void:
 if not load("res://tests/native_test_isolation.gd").is_isolated_save():push_error("isolated save required");quit(2);return
 state=root.get_node_or_null("State")
 if state==null:push_error("State autoload unavailable");quit(2);return
 var before:=story_snapshot()
 root.size=Vector2i(1280,720)
 change_scene_to_file("res://scenes/entry.tscn");await frames()
 var entry=current_scene
 check(is_instance_valid(entry.flc_button) and entry.flc_button.visible,"ordinary non-preview FLC entry exists")
 var entry_read:Dictionary=entry.entry_snapshot()
 check(entry_read.entry and entry_read.visibleControls.any(func(row:Dictionary):return row.name=="OpenFutureLearningCenter"),"read-only entry snapshot exposes actual FLC control")
 await click(entry.flc_button);await frames(8)
 var host=current_scene
 check(host.get_script().resource_path=="res://scripts/main.gd" and host.flc_entry_mode,"entry uses actual Main activity owner")
 check(not root.has_meta("flc_entry_requested"),"one-shot launch request consumed")
 check(host.phone==null and host.world==null,"story and phone are not running behind exploration")
 var activity:Control=host.active_game
 check(is_instance_valid(activity) and activity.configured,"formal activity configured")
 if not is_instance_valid(activity):quit(1);return
 check(activity.canvas.size==Vector2i(960,540),"actual world uses canonical viewport")
 check(activity.floor_view.get_script().resource_path.ends_with("floor_view.gd"),"real FLC floor mounted")
 host._open_game_now({"kind":"future_learning_center"});await frames()
 check(host.active_game==activity,"repeated entry cannot duplicate host")
 check(story_snapshot()==before,"initial entry changes no story/native scene/player/checkpoint")
 for viewport_size:Vector2i in [Vector2i(1280,720),Vector2i(390,844),Vector2i(780,440)]:
  root.size=viewport_size;host.size=viewport_size;host._layout();await frames()
  var surface:Control=activity.surface
  check(is_equal_approx(surface.scale.x,surface.scale.y),"uniform world scaling "+str(viewport_size))
  check(surface.position.x>=-.1 and surface.position.y>=51.9 and surface.position.x+960*surface.scale.x<=host.size.x+.1 and surface.position.y+540*surface.scale.y<=host.size.y+.1,"world and return control fit "+str(viewport_size))
 var platform=load("res://scripts/platform/web_platform.gd").new();host.add_child(platform);platform.setup(host,state)
 var observed:Dictionary=platform.read_snapshot()
 check(observed.phoneRect.is_empty() and observed.presentation.landscapePreferred,"web snapshot supports activity-only Main without fake shell")
 check(observed.activity.kind=="flc" and observed.activity.puzzleRect.width>0 and observed.activity.has("formulaCompleted"),"read-only activity snapshot exposes root geometry and real model fields")
 platform._apply_visibility(true)
 check(activity.suspended and activity.canvas.gui_disable_input and activity.floor_view.process_mode==Node.PROCESS_MODE_DISABLED,"focus loss suspends floor and input")
 platform._apply_visibility(false)
 check(not activity.suspended and not activity.canvas.gui_disable_input,"focus return reenables same floor")
 var floor_world=activity.floor_view
 floor_world.load_floor(2);floor_world.set_foot(floor_world.puzzle_approach("koala"));floor_world.open_puzzle("koala");await frames()
 var station:Control=floor_world.active_puzzle
 var touch:=InputEventScreenTouch.new();touch.index=7;touch.pressed=true;touch.position=station.module_position(5)
 activity.canvas.push_input(touch,true);await frames()
 check(station.touch_id==7,"real activity viewport accepts object touch")
 var second:=InputEventScreenTouch.new();second.index=8;second.pressed=true;second.position=station.module_position(4)
 activity.canvas.push_input(second,true);await frames()
 check(station.touch_id==7 and station.held==5,"second viewport finger cannot steal first object")
 platform._on_browser_touch_cancel(["[8]"]);await frames()
 check(station.touch_id==7 and station.held==5,"nonowner browser cancellation does not cancel owner")
 platform._on_browser_touch_cancel(["[7]"]);await frames()
 check(station.touch_id==-1 and station.held==-1 and station.model.chain.is_empty(),"browser cancellation releases actual room pointer without insertion")
 var late:=InputEventScreenTouch.new();late.index=7;late.pressed=false;late.position=station.socket(0)
 activity.canvas.push_input(late,true);await frames()
 check(station.model.chain.is_empty(),"canceled owner late release cannot insert object")
 var replacement:=InputEventScreenTouch.new();replacement.index=9;replacement.pressed=true;replacement.position=station.module_position(4)
 activity.canvas.push_input(replacement,true);await frames()
 check(station.touch_id==9 and station.held==4,"new viewport finger can acquire object after cancellation")
 platform._on_browser_touch_cancel(["[9]"]);await frames()
 station.close();await frames()
 var retained_floor=activity.floor_view
 check(retained_floor.has_method("suspend_activity") and retained_floor.has_method("checkpoint_state"),"production floor lifecycle contract exists")
 var bridge:=SaveBridge.new();host.add_child(bridge);bridge.digest=FileAccess.get_sha256(state.SAVE_PATH)
 activity.suspend();activity.set_exit_waiting()
 check(activity.exit_pending and activity.back.disabled and activity.canvas.gui_disable_input,"pending save keeps owner alive and disables return")
 bridge.fail=true
 check(not await host._wait_flc_save(activity,bridge),"failed durable acknowledgement rejects exit")
 activity.exit_failed()
 check(host.active_game==activity and not activity.disposed and not activity.back.disabled and not activity.suspended,"failed save permits retry and continued exploration")
 activity.suspend();activity.set_exit_waiting();bridge.fail=false;bridge.digest="stale-acknowledgement"
 check(not await host._wait_flc_save(activity,bridge),"finished transport with stale digest cannot authorize exit")
 activity.exit_failed()
 activity.suspend();activity.set_exit_waiting();bridge.fail=false;bridge.digest=FileAccess.get_sha256(state.SAVE_PATH)
 check(await host._wait_flc_save(activity,bridge),"matching current saved bytes acknowledge before exit")
 var acknowledged_digest:=FileAccess.get_sha256(state.SAVE_PATH)
 activity.finish_leave();await frames(8)
 check(FileAccess.get_sha256(state.SAVE_PATH)==acknowledged_digest,"acknowledged bytes unchanged by host and floor teardown")
 check(current_scene.get_script().resource_path=="res://scripts/entry.gd","normal return goes to entry chooser")
 check(auto_accept_quit,"entry restores native window close after acknowledged FLC return")
 check(story_snapshot()==before,"return preserves main story")
 await click(current_scene.flc_button);await frames(8)
 check(current_scene.flc_entry_mode and is_instance_valid(current_scene.active_game),"normal reentry works without stale request")
 await click(current_scene.active_game.back);await frames(8)
 check(story_snapshot()==before,"second round trip preserves story")
 print("FLC_ACTIVITY_HOST %d checks; %d failures"%[checks,failures]);quit(1 if failures else 0)
