extends SceneTree
var checks := 0
var failures := 0
func _initialize() -> void: run.call_deferred()
func check(ok: bool,message: String) -> void:
	checks += 1
	if not ok: failures += 1; push_error("C4_MAIN: "+message)
func frames(count: int = 3) -> void:
	for i in range(count): await process_frame
func screen_rect(node: Control) -> Rect2:
	var transform := node.get_global_transform_with_canvas()
	return Rect2(transform.origin,node.size*transform.get_scale())
func mouse_click(node: Control) -> void:
	var point := screen_rect(node).get_center()
	var motion := InputEventMouseMotion.new(); motion.position=point
	root.push_input(motion,true)
	for down in [true,false]:
		var event := InputEventMouseButton.new()
		event.position=point; event.global_position=point; event.button_index=MOUSE_BUTTON_LEFT; event.pressed=down
		root.push_input(event,true); await frames(1)
func press_key(code: int) -> void:
	for down in [true,false]:
		var event := InputEventKey.new(); event.keycode=code; event.physical_keycode=code; event.pressed=down
		root.push_input(event,true); await frames(1)

## Isolated source-checkpoint integration, not continuous earned play.
var shell: Control
var state_node: Node
var source_data: Dictionary
func prepare(view: Vector2i, checkpoint: String) -> void:
	if is_instance_valid(shell):
		await shell.shutdown(); shell.queue_free(); await frames(3)
	state_node.begin_checkpoint(checkpoint)
	root.size=view
	shell=load("res://scenes/main.tscn").instantiate(); root.add_child(shell)
	shell._refresh(); await frames(5)
func run() -> void:
	state_node=root.get_node("State"); state_node.developer_mode=true
	source_data=JSON.parse_string(FileAccess.get_file_as_string("res://data/native/chapter4-device-source.json"))
	for view: Vector2i in [Vector2i(390,844),Vector2i(1440,900)]:
		await prepare(view,"c4-755-classrooms-1850")
		state_node.act("c4_device_duty_board"); await frames(4)
		var panel=shell.modal
		check(is_instance_valid(panel) and panel.has_method("sync_authority"),"Main mounts source device panel from real controller intent")
		if not is_instance_valid(panel): continue
		check(panel.session.view_kind()=="controls","checkpoint is light device controls")
		var before_player=state_node.d.native.player.duplicate(true)
		await press_key(KEY_D)
		check(state_node.d.native.player==before_player,"device modal blocks world walking")
		check(Rect2(Vector2.ZERO,Vector2(view)).encloses(panel.frame.get_global_rect()),"Main automatic mount contains entire device frame")
		await mouse_click(panel.submit_button)
		check(shell.modal==panel and not panel.session.feedback.is_empty(),"wrong actual mouse submit stays mounted with local feedback")
		check(shell.toast.text.is_empty(),"device wrong submit emits no duplicate toast")
		await press_key(KEY_TAB)
		var focused=root.gui_get_focus_owner()
		check(focused==panel or panel.is_ancestor_of(focused),"Tab focus remains inside device")
		# Source initial elevator,104,105: move elevator down twice using live controls.
		await mouse_click(panel.find_child("down_main_elevator",true,false))
		await mouse_click(panel.find_child("down_main_elevator",true,false))
		var draft=panel.session.draft.duplicate(true)
		shell._refresh(); await frames()
		check(shell.modal==panel and panel.session.draft==draft,"unrelated Main refresh retains exact session/draft")
		await mouse_click(panel.submit_button)
		check(panel.session.completed and "a1_duty_board_reconstructed" in state_node.d.chapter4.factIds,"real corrected controls submit through authoritative State")
		await press_key(KEY_ESCAPE)
		check(shell.modal==null,"Escape closes completed device")
		state_node.act("c4_device_duty_board"); await frames()
		check(shell.modal.session.completed and shell.modal.session.draft==source_data.defaults,"reopen completed device derives fact and fresh source draft")
		check(Rect2(Vector2.ZERO,Vector2(view)).encloses(screen_rect(shell.modal.close_button)),"completed close target remains on screen")
		await mouse_click(shell.modal.close_button)
		check(shell.modal==null,"real close button unmounts modal")
		# Missing film must open explanatory panel in light and dark.
		await prepare(view,"c4-755-room204-1850")
		for mode in ["light","dark"]:
			if state_node.d.chapter4.mode!=mode: state_node.act("c4_mode")
			state_node.act("c4_device_media_alignment"); await frames()
			check(is_instance_valid(shell.modal) and shell.modal.session.view_kind()=="locked","missing film explanation opens in "+mode)
			if is_instance_valid(shell.modal): await press_key(KEY_ESCAPE)
	await prepare(Vector2i(1440,900),"c4-755-checkin")
	state_node.act("c4_checkin_card"); await frames(2)
	check(state_node.d.chapter4.phase=="morning_checkin" and shell.world_effect==null,"first check-in item does not begin door handoff")
	state_node.act("c4_checkin_paper"); await frames(3)
	check(state_node.d.chapter4.phase=="exterior_closure" and is_instance_valid(shell.world_effect) and shell.active_game==null,"second check-in item automatically begins source door prelude")
	await prepare(Vector2i(1440,900),"c4-755-closure")
	var closure_before=state_node.d.chapter4.duplicate(true)
	state_node.act("c4_lamp_start"); await frames(2)
	check(shell.active_game==null and is_instance_valid(shell.world_effect),"Main keeps questions hidden during actual in-world door prelude")
	var door=shell.world_effect
	door.set_process(false)
	for i in range(28): door._process(.05)
	check(shell.active_game==null and not state_node.d.chapter4.completed,"1.4s door prelude cannot open or complete lamp")
	door._process(.05); door._process(.05)
	await frames(3)
	check(is_instance_valid(shell.active_game) and shell.active_game.kind=="star_lamp_closure" and shell.active_game.stage=="questions","after exact source delay Main mounts registered closure questions")
	check(state_node.d.chapter4==closure_before,"door handoff does not write answers or story")
	await prepare(Vector2i(390,844),"c4-755-closure")
	state_node.act("c4_lamp_start"); await frames(2)
	var cancelled=shell.world_effect
	shell._cancel_world_effect(); await frames(2)
	check(not is_instance_valid(cancelled) and shell.active_game==null,"cancelled door cannot later open stale questions")
	state_node.act("c4_lamp_start"); await frames(2)
	check(is_instance_valid(shell.world_effect) and shell.world_effect.elapsed_ms<300,"ordinary retry creates fresh door timing")
	await shell.shutdown(); shell.queue_free(); await frames(3)
	print("C4_DEVICE_MAIN: %d checks; %d failures" %[checks,failures]); quit(1 if failures else 0)
