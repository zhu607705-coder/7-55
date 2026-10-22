extends SceneTree
## Route real viewport events through input, GUI focus, and unhandled shortcuts.
const Game=preload("res://scripts/games/c3_spotlight.gd")
var checks:=0
var failures:=0
func _initialize()->void:run.call_deferred()
func check(ok:bool,message:String)->void:
	checks+=1
	if not ok:failures+=1;push_error("SPOTLIGHT KEYBOARD: "+message)
func key(code:Key,pressed:bool=true,echo:bool=false)->void:
	var event:=InputEventKey.new()
	event.keycode=code;event.physical_keycode=code;event.pressed=pressed;event.echo=echo
	root.push_input(event,true);await process_frame
func run()->void:
	var game:=Game.new();game.setup({"round":0});root.add_child(game);await process_frame
	game.set_process(false);game._primary();game.pause_button.grab_focus()
	check(root.gui_get_focus_owner()==game.pause_button,"pause remains keyboard focusable")
	await key(KEY_SPACE)
	check(game.screen=="running" and game.queued_dash,"Space dashes while Pause is focused")
	game.queued_dash=false
	await key(KEY_SPACE,true,true)
	check(not game.queued_dash and game.screen=="running","held-key repeat does not queue another dash")
	await key(KEY_SPACE,false)
	check(not game.queued_dash and game.screen=="running","Space release does not activate Pause")
	check(root.gui_get_focus_owner()==game.pause_button,"dash does not steal accessible button focus")
	await key(KEY_ENTER);await key(KEY_ENTER,false)
	check(game.screen=="paused","Enter still activates the focused Pause button")
	game.start_button.grab_focus();await key(KEY_ENTER);await key(KEY_ENTER,false)
	check(game.screen=="running","Enter activates focused Continue")
	game.pause_button.grab_focus();await key(KEY_SPACE);await key(KEY_ESCAPE)
	check(game.screen=="paused" and not game.queued_dash,"Esc still pauses and clears queued dash")
	game.start_button.grab_focus();await key(KEY_SPACE,false)
	check(game.screen=="paused" and not game.gameplay_space_owned,"owned Space release cannot activate Continue after Esc")
	await key(KEY_ESCAPE,false)
	await key(KEY_SPACE);await key(KEY_SPACE,false)
	check(game.screen=="running","fresh Space on paused Continue retains native button activation")
	await key(KEY_SPACE)
	game.notification(MainLoop.NOTIFICATION_APPLICATION_FOCUS_OUT)
	check(game.screen=="paused" and not game.gameplay_space_owned,"focus loss clears ownership when release may occur outside the window")
	game.start_button.grab_focus();await key(KEY_SPACE);await key(KEY_SPACE,false)
	check(game.screen=="running","fresh Space after focus loss activates Continue")
	await key(KEY_SPACE);game.setup({"round":0})
	check(not game.gameplay_space_owned,"new session clears stale Space ownership")
	game.start_button.grab_focus();await key(KEY_SPACE);await key(KEY_SPACE,false)
	check(game.screen=="running","fresh Space after setup activates Start")
	game.queue_free();await process_frame
	print("THEATER_SPOTLIGHT_KEYBOARD: %d checks; %d failures"%[checks,failures]);quit(1 if failures else 0)
