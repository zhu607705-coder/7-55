extends SceneTree
## Native-only F10 must not open a second interactive surface over a minigame.
var checks:=0
var failures:=0
func _initialize() -> void:run.call_deferred()
func check(ok: bool,message: String) -> void:
	checks+=1
	if not ok:failures+=1;push_error("GAME SETTINGS INPUT: "+message)
func frames(count: int=2) -> void:
	for i in count:await process_frame
func key(code: Key) -> void:
	for down in [true,false]:
		var e=InputEventKey.new();e.keycode=code;e.physical_keycode=code;e.pressed=down;root.push_input(e,true);await frames(1)
func click(node: Control) -> void:
	var at=node.get_global_transform_with_canvas()*(node.size/2)
	var motion=InputEventMouseMotion.new();motion.position=at;root.push_input(motion,true)
	for down in [true,false]:
		var e=InputEventMouseButton.new();e.button_index=MOUSE_BUTTON_LEFT;e.pressed=down;e.position=at;e.global_position=at;root.push_input(e,true);await frames(1)
func snapshot(game: Control) -> Dictionary:
	return {"running":game.running,"paused":game.paused,"tick":game.model.tick,"distance":game.model.distance,"inputs":game.model.inputs.duplicate(true)}
func run() -> void:
	var state=root.get_node("State");state.developer_mode=true;state.d=state.initial();root.size=Vector2i(390,844)
	var main=load("res://scenes/main.tscn").instantiate();root.add_child(main);await frames(5)
	state.begin_checkpoint("c3-canteen-drinks");main._refresh();main.mobile_world=true;main._layout();await frames(3)
	main._open_game({"type":"chase","viewport":[960,540]});await frames(4)
	check(not main.mobile_back.visible,"underlying phone return hidden while game active")
	var game: Control=main.active_game;game.set_process(false)
	var before=snapshot(game);await key(KEY_F10)
	check(not is_instance_valid(main.modal),"ready minigame retains exclusive surface")
	check(snapshot(game)==before,"F10 does not alter ready state/proof")
	await key(KEY_ENTER)
	check(game.running and not game.paused,"ordinary Enter still starts game")
	before=snapshot(game);await key(KEY_F10)
	check(not is_instance_valid(main.modal),"running minigame retains exclusive surface")
	check(snapshot(game)==before,"F10 does not alter running state/proof")
	await key(KEY_A)
	check(game.model.inputs.size()>before.inputs.size(),"ordinary movement still records source input proof")
	await key(KEY_ESCAPE)
	check(game.paused and not is_instance_valid(main.modal),"ordinary Escape still pauses game")
	before=snapshot(game);await key(KEY_F10)
	check(not is_instance_valid(main.modal),"paused minigame retains exclusive surface")
	check(snapshot(game)==before,"F10 does not alter paused state/proof")
	await key(KEY_ENTER)
	check(game.running and not game.paused,"ordinary Enter still resumes game")
	await click(game.exit_button);await frames()
	check(not is_instance_valid(main.active_game),"actual exit button closes game")
	check(main.mobile_back.visible and main.mobile_world,"phone return restored after actual game exit")
	await key(KEY_F10)
	check(is_instance_valid(main.modal),"F10 settings works after game exit")
	var focus=root.gui_get_focus_owner()
	check(focus==main.modal or (focus!=null and main.modal.is_ancestor_of(focus)),"post-game settings captures focus")
	await key(KEY_ESCAPE);check(not is_instance_valid(main.modal),"post-game settings closes normally")
	await main.shutdown();main.queue_free();await frames()
	print("NATIVE_GAME_SETTINGS_INPUT: ",checks," checks; ",failures," failures")
	quit(1 if failures else 0)
