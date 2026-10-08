extends "res://tests/test_chapter4_device_main.gd"
## Isolated native host regression. Fixture film is not an earned-play claim.
const StudioModel = preload("res://scripts/objects/room302_studio_model.gd")
var studio_actions: Array[String] = []

func shell_snapshot() -> Dictionary:
	return {
		"phone":shell.phone.visible,"world":shell.world_frame.visible,
		"back":shell.mobile_back.visible,"return":shell.phone_world_return.visible,
		"tasks":shell.world_tasks.visible,"handle":shell.inventory_handle.visible,
		"bag":shell.inventory_dock.visible,"mobile":shell.mobile_world,
		"open_bag":shell.compact_inventory_open,"input":shell.world_viewport.gui_disable_input,
		"position":shell.world_frame.position,"extent":shell.world_frame.size,
		"scale":shell.world_frame.scale,"viewport":shell.world_viewport.size,
		"pan":shell.world.pan_offset,"touch_emulation":Input.emulate_mouse_from_touch,"mouse_mode":Input.mouse_mode
	}

func open_studio() -> Control:
	state_node.act("c4_device_media_alignment")
	await frames(5)
	return shell.modal

func input_touch(down: bool) -> void:
	var event := InputEventScreenTouch.new()
	event.index=0;event.pressed=down;event.position=Vector2(2,2)
	root.push_input(event,true)
	await frames(1)

func run() -> void:
	state_node=root.get_node("State");state_node.developer_mode=true
	state_node.action_completed.connect(func(action: String,_before: Dictionary,_after: Dictionary,_result: Dictionary):
		if action in ["c4_media_studio_event","c4_solve_media_alignment"]: studio_actions.append(action)
	)
	for dimensions: Vector2i in [Vector2i(1440,900),Vector2i(1180,812),Vector2i(390,844)]:
		await prepare(dimensions,"c4-755-room204-1850")
		shell._show_world_mobile();shell.compact_inventory_open=true;shell._layout();await frames()
		shell.world_tasks.grab_focus();await frames()
		check(root.gui_get_focus_owner()==shell.world_tasks,"fixture establishes the original root control focus")
		var before: Dictionary=shell_snapshot()
		var facts: Array=state_node.d.chapter4.factIds.duplicate()
		var panel: Control=await open_studio()
		check(is_instance_valid(panel) and panel.get_script().resource_path=="res://scripts/objects/room302_studio_panel.gd","media_alignment selects bounded physical studio")
		if not is_instance_valid(panel): continue
		check(panel.color.a==1.0 and panel.position==Vector2.ZERO and panel.size==Vector2(dimensions) and panel.scale==Vector2.ONE,"studio is opaque and fills the actual window unscaled")
		check(panel._safe_insets==shell._room302_safe_insets(),"Main forwards supported platform safe insets")
		check(not shell.world_frame.visible and not shell.phone.visible and not shell.mobile_back.visible and not shell.world_tasks.visible and not shell.inventory_dock.visible and not shell.inventory_handle.visible and not shell.phone_world_return.visible,"studio hides exploration and phone HUD")
		check(shell.world_viewport.gui_disable_input,"studio disables retained exploration SubViewport input")
		check(panel.session.view_kind()=="locked" and panel.hint.text.contains("底片"),"missing film remains explanatory and cannot operate")
		check(panel.input_mode=="keyboard","narrow pointer viewport does not force touch instructions")
		check(Rect2(Vector2.ZERO,Vector2(dimensions)).encloses(screen_rect(panel.close_button)),"Return remains fully inside viewport")
		var player: Dictionary=state_node.d.native.player.duplicate(true)
		var count: int=studio_actions.size()
		await press_key(KEY_D);await press_key(KEY_1);await press_key(KEY_ENTER)
		check(state_node.d.native.player==player and studio_actions.size()==count and state_node.d.chapter4.factIds==facts,"missing-film input neither walks nor submits or grants facts")
		await press_key(KEY_TAB)
		check(root.gui_get_focus_owner()==panel.close_button,"Tab traps focus on Return")
		await press_key(KEY_ENTER)
		check(shell.modal==null and studio_actions.size()==count,"Return Enter closes without scanner submission")
		check(shell_snapshot()==before,"close restores exact shell layout, input and inventory state")
		check(root.gui_get_focus_owner()==shell.world_tasks,"close restores original root control focus")

		# Real input family, rather than the layout breakpoint, chooses hints.
		panel=await open_studio()
		await input_touch(true);await input_touch(false)
		check(panel.input_mode=="touch" and panel.view.touch_mode,"real touch selects touch affordances")
		var emulated := InputEventMouseMotion.new();emulated.device=InputEvent.DEVICE_ID_EMULATION
		emulated.position=Vector2(2,2);root.push_input(emulated,true)
		check(panel.input_mode=="touch","synthetic mouse cannot override actual touch mode")
		await press_key(KEY_TAB)
		check(panel.input_mode=="keyboard" and not panel.view.touch_mode,"hardware keyboard switches a hybrid session back")
		await press_key(KEY_KP_ENTER)
		check(shell.modal==null,"Return keypad Enter retains native Button activation")

		# Dark missing-film entry follows the same precedence and closes cleanly.
		state_node.act("c4_mode");await frames()
		panel=await open_studio()
		check(panel.session.view_kind()=="locked" and panel.hint.text.contains("底片"),"dark missing-film entry does not expose observation controls")
		await press_key(KEY_ESCAPE)
		check(shell.modal==null,"Escape closes missing-film dark studio")
		state_node.act("c4_mode");await frames()

	# State.act receives each studio input once and owns the saved checkpoint.
	await prepare(Vector2i(1180,812),"c4-755-room204-1850")
	state_node.d.chapter4.factIds.append("a3_archive_film_retrieved")
	state_node.d.native.settings.reduced_motion=true
	shell._show_world_mobile();await frames();shell.world.grab_focus()
	var panel: Control=await open_studio()
	var previous: Dictionary=StudioModel.initial()
	await press_key(KEY_1);await press_key(KEY_3)
	var checkpoint: Dictionary=state_node.d.native.get("c4_media_studio",{})
	check(checkpoint==StudioModel.transition(previous,{"kind":"swap","a":0,"b":2}).checkpoint,"lamp keys submit the accepted bounded move through State.act")
	check(panel.checkpoint==checkpoint and not "a3_media_alignment_completed" in state_node.d.chapter4.factIds,"host resolves from authority without granting completion")
	await press_key(KEY_ESCAPE)
	check(shell.world_viewport.gui_get_focus_owner()==shell.world,"close restores exploration SubViewport focus")
	panel=await open_studio()
	check(panel.checkpoint==checkpoint and panel.selected==-1,"close and reopen restores checkpoint with no stale local selection")
	await press_key(KEY_2)
	check(panel.selected==1,"partial keyboard selection is local")
	var retained_viewport: Vector2i=shell.world_viewport.size
	root.size=Vector2i(390,844);await frames(5)
	check(shell.modal==panel and panel.size==Vector2(390,844) and panel.selected==-1,"resize fits same studio and cancels stale selection")
	check(shell.world_viewport.size==retained_viewport,"resize leaves hidden exploration viewport unchanged")
	check(Rect2(Vector2.ZERO,Vector2(390,844)).encloses(screen_rect(panel.close_button)),"resized Return remains on screen")
	check(panel.input_mode=="keyboard","resize never changes input family")
	await press_key(KEY_ESCAPE)
	check(shell.world_frame.visible and not shell.world_viewport.gui_disable_input and shell.room302_shell_restore.is_empty(),"resized close restores world input and releases snapshot")
	check(Rect2(Vector2.ZERO,Vector2(390,844)).encloses(screen_rect(shell.world_frame)),"restored exploration is refitted to the new window")

	# Replacing the modal restores the host first; retired callbacks are inert.
	panel=await open_studio()
	var count: int=studio_actions.size()
	panel.session.pending=true
	shell._modal_base("Replacement regression")
	check(shell.modal!=panel and shell.world_frame.visible and shell.room302_shell_restore.is_empty(),"replacement modal cannot retain studio-exclusive shell")
	panel.studio_event_requested.emit({"kind":"swap","a":1,"b":2})
	panel.submit_requested.emit("c4_solve_media_alignment",{},1)
	var replacement: Control=shell.modal
	panel.close_requested.emit()
	check(shell.modal==replacement,"retired close callback cannot close the replacement modal")
	check(studio_actions.size()==count and state_node.d.native.c4_media_studio==checkpoint,"retired modal events cannot write state")
	await frames();shell._close_modal();await frames()

	# Authority loss must close even if a now-stale request was pending.
	for boundary: String in ["scene","context","mode"]:
		await prepare(Vector2i(1180,812),"c4-755-room204-1850")
		state_node.d.chapter4.factIds.append("a3_archive_film_retrieved")
		shell._show_world_mobile();await frames()
		panel=await open_studio();panel.session.pending=true
		match boundary:
			"scene":state_node.d.native.scene="dorm_hub"
			"context":state_node.d.native.c4_context="archive_index"
			"mode":state_node.d.native.mode="dark";state_node.d.chapter4.mode="dark"
		state_node.changed.emit();await frames(5)
		check(shell.modal==null and shell.room302_shell_restore.is_empty() and not shell.world_viewport.gui_disable_input,"stale "+boundary+" releases pending studio and restores input")
		check(not "a3_media_alignment_completed" in state_node.d.chapter4.factIds,"stale "+boundary+" never grants completion")

	await shell.shutdown();shell.queue_free();await frames(3)
	print("ROOM302_STUDIO_MAIN: %d checks; %d failures"%[checks,failures]);quit(1 if failures else 0)
