extends SceneTree
## External physical apparatus share cancellation and synthetic-pointer ownership.
var checks:=0
var failures:=0
func _initialize()->void:run.call_deferred()
func check(ok:bool,label:String)->void:
 checks+=1
 if not ok:failures+=1;push_error("FLC_PHYSICAL_TOUCH "+label)
func send_touch(view,index:int,at:Vector2,pressed:bool,canceled:=false)->void:
 var e:=InputEventScreenTouch.new();e.index=index;e.position=at;e.pressed=pressed;e.canceled=canceled;view._input(e)
func synthetic_click(view,at:Vector2)->void:
 for pressed:bool in [true,false]:
  var e:=InputEventMouseButton.new();e.device=InputEvent.DEVICE_ID_EMULATION;e.position=at;e.button_index=MOUSE_BUTTON_LEFT;e.pressed=pressed;view._input(e)
func open_view(view,id:String)->void:
 if id.begins_with("motion_lab_"):view.open(id.trim_prefix("motion_lab_"))
 else:view.open()
func run()->void:
 root.size=Vector2i(960,540)
 for id:String in ["workbench","signal_sync","motion_lab_solar","motion_lab_robotics","pantry_tray"]:
  var script_id:="motion_lab" if id.begins_with("motion_lab_") else id
  var view=load("res://campuses/future_learning_center/scripts/%s_view.gd"%script_id).new();root.add_child(view);open_view(view,id);await process_frame
  var book:=Vector2(880,105)
  synthetic_click(view,book)
  check(not view.book_open and view.pointer_owner==-2,id+" emulated pointer cannot start a new gesture")
  view.book_open=false;view.cancel_gesture()
  send_touch(view,4,book,true);send_touch(view,4,book,false)
  check(view.book_open,id+" real touch opens book once")
  synthetic_click(view,book)
  check(view.book_open,id+" emulated pointer after release cannot close book")
  view.book_open=false
  send_touch(view,8,book,true,true)
  check(view.pointer_owner==-2 and view.gesture.is_empty(),id+" canceled down cannot acquire ownership")
  view.cancel_gesture()
  send_touch(view,2,book,true);send_touch(view,3,book,true);send_touch(view,3,book,false)
  check(view.pointer_owner==2,id+" second finger cannot steal or release")
  send_touch(view,2,book,true,true)
  check(view.pointer_owner==-2 and view.gesture.is_empty() and not view.book_open,id+" owned canceled down retires gesture without action")
  send_touch(view,2,book,false)
  check(not view.book_open,id+" late release after cancellation stays inert")
  send_touch(view,5,book,true);view._notification(Node.NOTIFICATION_APPLICATION_FOCUS_OUT);send_touch(view,5,book,false)
  check(not view.book_open and view.pointer_owner==-2,id+" focus loss clears ownership")
  view.close();open_view(view,id);send_touch(view,6,book,true);send_touch(view,6,book,false)
  check(view.book_open,id+" reentry restores ordinary touch")
  view.close();view.queue_free();await process_frame
 print("FLC_PHYSICAL_TOUCH %d checks; %d failures"%[checks,failures]);quit(1 if failures else 0)
