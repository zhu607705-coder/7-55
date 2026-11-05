extends SceneTree
const Host=preload("res://scripts/ui/minigame_host.gd")
const Overlay=preload("res://scripts/ui/native_pause_overlay.gd")
var errors:=0
var checks:=0
func _initialize():run.call_deferred()
func check(ok:bool,label:String):
 checks+=1
 if not ok:errors+=1;push_error(label)
func key(code:Key,down:bool):
 var e:=InputEventKey.new();e.keycode=code;e.physical_keycode=code;e.pressed=down;root.push_input(e,true)
func frames():
 for i in 3:await process_frame
func run():
 if not preload("res://tests/native_test_isolation.gd").is_isolated_save():quit(2);return
 var game=Host.new();root.add_child(game);game.set_process(false)
 game.setup({"type":"rhythm","spotId":"locker_key","chartId":"locker_key","session_id":77})
 await frames()
 game.begin();key(KEY_D,true);game._process(.02);key(KEY_D,false);game.toggle_pause();await frames()
 check(game.paused and game.shared_pause_overlay.is_open(),"actual fishing activity starts paused with its shared card")
 var cloud=load("res://scripts/platform/cloud_saves.gd").new();root.add_child(cloud);cloud.set_process(false);cloud.process_mode=Node.PROCESS_MODE_ALWAYS;cloud.layer=150;cloud._build_surface()
 var activations=[0]
 var cancellations=[0];game.cancelled.connect(func():cancellations[0]+=1)
 Overlay.set_environment_blocked(self,true)
 cloud._show("本地输入验证",[["继续",func():activations[0]+=1]])
 var cloud_button:Button=cloud._column.get_child(cloud._column.get_child_count()-1)
 cloud_button.grab_focus();Overlay.set_environment_blocked(self,false)
 check(root.gui_get_focus_owner()==cloud_button,"platform foreground return does not steal focus from Cloud")
 key(KEY_ENTER,true);key(KEY_ENTER,false);await frames()
 check(game.paused,"cloud cover prevents underlying shared Continue from root Enter")
 check(activations[0]==1,"root Enter still activates the focused Cloud button")
 if not game.paused:game.toggle_pause()
 var retry:Button=game.shared_pause_overlay.action_buttons[0]
 retry.grab_focus();key(KEY_ENTER,true);key(KEY_ENTER,false);await frames()
 check(game.paused and game.running,"shared Retry cannot reset the actual activity while Cloud owns Tree")
 var exit_action:Button=game.shared_pause_overlay.action_buttons[1]
 exit_action.grab_focus();key(KEY_ENTER,true);key(KEY_ENTER,false);await frames()
 check(cancellations[0]==0 and game.paused and game.running,"shared Exit cannot cancel the activity while Cloud owns Tree")
 cloud_button.grab_focus();key(KEY_SPACE,true);key(KEY_SPACE,false);await frames()
 check(activations[0]==2 and game.paused,"Cloud keeps Space keyboard activation without leaking Continue")
 cloud._resume();cloud.queue_free();await frames()
 game.shared_pause_overlay.present(true)
 game.shared_pause_overlay.resume_button.grab_focus();key(KEY_ENTER,true);key(KEY_ENTER,false);await frames()
 check(not game.paused and game.running,"ordinary Continue works after Cloud releases its lease")
 game.toggle_pause();game.shared_pause_overlay.action_buttons[0].grab_focus();key(KEY_ENTER,true);key(KEY_ENTER,false);await frames()
 check(not game.paused and not game.running and game.model.phase=="idle","original shared Retry is usable after Cloud releases")
 game.begin();key(KEY_D,true);game._process(.02);key(KEY_D,false);game.toggle_pause()
 game.shared_pause_overlay.action_buttons[1].grab_focus();key(KEY_ENTER,true);key(KEY_ENTER,false);await frames()
 check(cancellations[0]==1 and not game.running,"original shared Exit is usable after Cloud releases")
 game.queue_free();await frames()
 print("CLOUD_PAUSE_INPUT: ",checks," checks; ",errors," failures");quit(1 if errors else 0)
