extends SceneTree
## Real viewport keyboard/touch dispatch; no gameplay or save authority.
const Overlay=preload("res://scripts/ui/native_pause_overlay.gd")
var failures:=0
var checks:=0
var resumed:=0
var secondary:=0
func _initialize()->void:run.call_deferred()
func check(ok:bool,label:String)->void:
	checks+=1
	if not ok:failures+=1;push_error(label)
func key(code:Key,down:bool=true,echo:bool=false)->void:
	var event:=InputEventKey.new();event.keycode=code;event.physical_keycode=code;event.pressed=down;event.echo=echo
	root.push_input(event,true);await process_frame
func run()->void:
	root.size=Vector2i(430,860)
	var owner:=Control.new();owner.focus_mode=Control.FOCUS_ALL;root.add_child(owner)
	var overlay=Overlay.mount(owner,func():resumed+=1)
	overlay.set_actions([{"text":"退出","callback":func():secondary+=1}]);overlay.present(true)
	owner.grab_focus();await key(KEY_TAB);await key(KEY_TAB,false)
	check(root.gui_get_focus_owner()==overlay.resume_button,"Tab from generic Control focuses Continue without typed-array error")
	await key(KEY_TAB);await key(KEY_TAB,false)
	check(root.gui_get_focus_owner()==overlay.action_buttons[0],"Tab reaches the original secondary action")
	await key(KEY_ENTER);await key(KEY_ENTER,false)
	check(secondary==1 and resumed==0,"Enter invokes only focused secondary action")
	owner.grab_focus();await key(KEY_ENTER);await key(KEY_ENTER,false)
	check(resumed==1,"Enter from generic Control activates Continue without typed-array error")
	await key(KEY_SPACE,false);await key(KEY_SPACE,true,true)
	check(resumed==1,"Unowned release and held repeat cannot activate Continue")
	await key(KEY_SPACE);await key(KEY_SPACE,true,true);await key(KEY_SPACE,false)
	check(resumed==2,"Fresh Space activates once and consumes its repeat and release")
	await key(KEY_ESCAPE);await key(KEY_ESCAPE,false)
	check(resumed==3,"Escape remains an explicit fresh resume input")
	Input.call("set_emulate_mouse_from_touch",true)
	for down:bool in [true,false]:
		var touch:=InputEventScreenTouch.new();touch.index=0;touch.position=overlay.resume_button.get_global_rect().get_center();touch.pressed=down
		Input.parse_input_event(touch);await process_frame;await process_frame
	Input.call("set_emulate_mouse_from_touch",false)
	check(resumed==4,"Ordinary touch activates visible Continue once")
	owner.queue_free();await process_frame;await process_frame
	print("SHARED_PAUSE_FOCUS_INPUT: %d checks; %d failures"%[checks,failures]);quit(1 if failures else 0)
