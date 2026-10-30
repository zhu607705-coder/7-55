extends SceneTree
const Style=preload("res://campuses/future_learning_center/scripts/apparatus_style.gd")
var checks:=0
var failures:=0
var exits:=0
func _initialize()->void:run.call_deferred()
func frames()->void:
 for i:int in 2:await process_frame
func check(ok:bool,label:String)->void:
 checks+=1
 if not ok:failures+=1;push_error("APPARATUS STYLE: "+label)
func mouse(at:Vector2,down:bool)->void:
 var event:=InputEventMouseButton.new();event.position=at;event.button_index=MOUSE_BUTTON_LEFT;event.pressed=down;root.push_input(event)
func touch(id:int,at:Vector2,down:bool,canceled:=false)->void:
 var event:=InputEventScreenTouch.new();event.index=id;event.position=at;event.pressed=down;event.canceled=canceled;root.push_input(event)
func run()->void:
 root.size=Vector2i(960,540)
 check(Style.font()==Style.font(),"one shared closeup font cache")
 check(Style.font().base_font.antialiasing==TextServer.FONT_ANTIALIASING_GRAY,"SelectedSans uses grayscale antialiasing")
 for name:String in ["focus","koala","logic","collab"]:
  var view:Control=load("res://campuses/future_learning_center/scripts/puzzles/%s_view.gd"%name).new()
  view.size=Vector2(960,540);root.add_child(view);view.open();await frames()
  var button:Button=view.get_node("ApparatusExit")
  view.closed.connect(func():exits+=1)
  var initial_exits:=exits
  var at:=button.get_global_transform_with_canvas()*(button.size/2)
  check(button.text=="离开操作台" and button.accessibility_name.contains("房间"),name+" distinct room-return label")
  check(button.get_theme_font("font")==Style.font() and button.get_theme_stylebox("focus")!=null,name+" shared font and visible focus state")
  mouse(at,true);await frames();check(view.visible and exits==initial_exits,name+" mouse press does not close immediately")
  view.propagate_notification(Node.NOTIFICATION_APPLICATION_FOCUS_OUT);mouse(at,false);await frames()
  check(view.visible and exits==initial_exits,name+" focus loss retires pressed navigation")
  touch(3,at,true);touch(3,at,false,true);touch(3,at,false);await frames()
  check(view.visible and exits==initial_exits,name+" touchcancel and late release do not close")
  touch(3,at,true);touch(4,at,true);touch(4,at,false);await frames()
  check(view.visible and button.touch_owner==3,name+" second finger cannot activate or steal navigation")
  touch(3,Vector2(100,100),false);await frames()
  check(view.visible and exits==initial_exits,name+" outside release aborts navigation")
  touch(5,at,true);touch(5,at,false);await frames()
  check(not view.visible and exits==initial_exits+1,name+" owned touch returns to room once")
  view.open();mouse(at,true);mouse(at,false);await frames()
  check(not view.visible and exits==initial_exits+2,name+" mouse exit remains usable after reopen")
  view.open();button.grab_focus();await frames()
  for down:bool in [true,false]:
   var key:=InputEventKey.new();key.keycode=KEY_SPACE;key.pressed=down;root.push_input(key)
  await frames();check(not view.visible and exits==initial_exits+3,name+" focused navigation keyboard activation does not start apparatus")
  view.queue_free();await frames()
 # Exercise the actual formal host, including the scaled 960x540 viewport.
 root.size=Vector2i(844,390)
 var host=load("res://scripts/games/future_learning_center/view.gd").new()
 host.size=Vector2(844,390);root.add_child(host);await frames()
 host.floor_view.persistence_enabled=false
 host.floor_view.load_floor(4);host.floor_view.set_foot(host.floor_view.puzzle_approach("focus_a"));host.floor_view.open_puzzle("focus_a");await frames()
 var station=host.floor_view.active_puzzle
 var inner:Button=station.get_node("ApparatusExit")
 check(host.room_back.visible and not inner.visible,"formal host exposes one room exit without duplicate")
 check(host.room_back.get_global_rect().size.y>=44 and host.room_back.get_global_rect().size.x>=144,"narrow formal navigation retains actual 44px touch target")
 check(host.back.visible and host.back.text.contains("入口"),"two distinct navigation destinations")
 var room_at:Vector2=host.room_back.get_global_rect().get_center()
 touch(11,room_at,true)
 var cancel:=InputEventScreenTouch.new();cancel.index=11;cancel.canceled=true
 host.cancel_browser_touch(cancel);touch(11,room_at,false);await frames()
 check(station.visible and host.room_back.touch_owner<0,"browser touchcancel retires root navigation owner")
 mouse(room_at,true);host.propagate_notification(Node.NOTIFICATION_APPLICATION_FOCUS_OUT);host.resume();mouse(room_at,false);await frames()
 check(not host.room_back.visible,"suspension closes room via existing lifecycle and retires navigation")
 host.floor_view.open_puzzle("focus_a");await frames()
 check(host.room_back.visible and not inner.visible,"reopening restores accessible host exit")
 touch(12,room_at,true);touch(12,room_at,false);await frames()
 check(not station.visible and not host.room_back.visible and inner.visible,"room exit closes only apparatus and restores standalone button")
 host.floor_view.open_puzzle("focus_a");await frames();host.suspend();host.set_exit_waiting();await frames()
 check(not host.room_back.visible and host.back.disabled,"saving hides obsolete room exit")
 host.exit_failed();await frames()
 check(not host.back.disabled and not host.suspended,"save failure keeps activity usable")
 host.floor_view.open_puzzle("focus_a");await frames()
 check(host.room_back.visible,"reenter apparatus after save retry failure")
 host.configure_activity_layout(Vector2(390,844),true);await frames()
 check(not host.back.get_global_rect().intersects(host.room_back.get_global_rect()),"portrait 390px save-retry and room exits never overlap")
 check(host.back.text=="保存重试" and host.back.accessibility_name.contains("未完成"),"compact retry retains full accessible failure meaning")
 host.floor_view.active_puzzle.queue_free();await frames()
 check(not host.room_back.visible,"freed apparatus never leaves a dangling room-exit target")
 host.queue_free();await frames()
 print("FLC_APPARATUS_STYLE %d checks; %d failures"%[checks,failures]);quit(1 if failures else 0)
