extends SceneTree
## Main/viewport ownership fixture. It does not grant a catch or alter the manual save.
var checks:=0
var failures:=0
var shell: Control
var state: Node
func _initialize() -> void:run.call_deferred()
func check(ok: bool,label: String) -> void:
	checks+=1
	if not ok:failures+=1;push_error("FISHING RETURN: "+label)
func frames(count: int=3) -> void:
	for i in range(count):await process_frame
func tap(button: Button) -> void:
	var event:=InputEventMouseButton.new()
	event.position=button.get_global_rect().get_center();event.global_position=event.position;event.button_index=MOUSE_BUTTON_LEFT;event.pressed=true
	root.push_input(event,true);await frames()
	event=event.duplicate();event.pressed=false;root.push_input(event,true);await frames()
func run() -> void:
	state=root.get_node("State");state.developer_mode=true;state.d=state.initial()
	var s: Dictionary=state.d
	s.native.chapter=3;s.native.scene="qizhen_lake";s.native.page="c3_lake";s.native.mode="light";s.runtimeMode="rpg";s.rpgScene="qizhen_lake"
	s.qizhenLake.merge({"active":true,"phase":"tool_chain","zone":"open_water","vehicle":"kayak","boardingTutorialCompleted":true,"kayakEquipped":true,"leftPaddleEquipped":true,"rightPaddleEquipped":true},true)
	shell=load("res://scenes/main.tscn").instantiate();root.add_child(shell);await frames()
	shell.set_process(false);shell.world.set_process(false)
	var held_items: Dictionary=s.items.duplicate(true)
	for dimensions: Vector2i in [Vector2i(390,844),Vector2i(430,860),Vector2i(1180,812),Vector2i(844,390)]:
		root.size=dimensions;shell._show_world_mobile();shell._layout();await frames()
		shell._open_game({"type":"rhythm","chartId":"locker_key","spotId":"locker_key","title":"锈蚀钥匙","session_id":"focus-only"})
		await frames();var game: Control=shell.active_game;game.set_process(false)
		check(game.size==Vector2(dimensions) and game.scale==Vector2.ONE,"real Main gives fishing the full physical viewport")
		check(not shell.world_frame.is_visible_in_tree(),"fishing owns presentation without old lake hints beneath it")
		await tap(game.start_button);await tap(game.pause_button)
		check(game.paused,"actual root controls reach Pause")
		root.size=Vector2i(dimensions.y,dimensions.x);shell._layout();await frames()
		check(game.paused and game.model.controls.is_empty(),"rotation retains Pause and releases held controls")
		root.size=dimensions;shell._layout();await frames()
		await tap(game.exit_button)
		check(not is_instance_valid(shell.active_game) and shell.world_frame.is_visible_in_tree(),"Exit removes the sole game and returns the existing lake")
		check(shell.world_viewport.gui_get_focus_owner()==shell.world,"Exit restores world keyboard focus without another click")
		check(not shell.world._shell_input_blocked(),"lake input owner is unpaused after Exit")
		check(s.items==held_items and s.qizhenLake.phase=="tool_chain","presentation and exit grant no catch or story progress")
	await shell.shutdown();shell.queue_free();await frames()
	print("LAKE_FISHING_FOCUS_RETURN: ",checks," checks; ",failures," failures")
	quit(1 if failures else 0)
