extends "res://tests/test_chapter4_device_main.gd"
## Real native Main and root input from an explicitly isolated pre-plate fixture.
const Model=preload("res://scripts/objects/room201_press_model.gd")
const ENTRY="res://tests/fixtures/room201_projection_entry.json"
var press_actions: Array[String]=[]
func setup_press(dimensions:Vector2i,collect:bool=true)->void:
	if is_instance_valid(shell):await shell.shutdown();shell.queue_free();await frames(3)
	state_node.d=JSON.parse_string(FileAccess.get_file_as_string(ENTRY)).state
	state_node.developer_mode=true
	state_node.d.native.settings.reduced_motion=true
	if collect:state_node.act("c4_plate")
	root.size=dimensions;shell=load("res://scenes/main.tscn").instantiate();root.add_child(shell)
	shell._show_world_mobile();shell._refresh();await frames(5)
func open_press()->Control:
	state_node.act("c4_device_positioning_calibration");await frames(5)
	return shell.modal
func settle(panel:Control)->void:
	# Advance only presentation time. It cannot write a checkpoint or story fact.
	for i in 24:
		if panel.view.motion.is_empty():break
		panel.view._process(.06)
	await frames(2)
func key_step(panel:Control,code:int)->void:
	await press_key(code);await settle(panel)
func point_click(point:Vector2)->void:
	var motion:=InputEventMouseMotion.new();motion.position=point;root.push_input(motion,true)
	for down:bool in [true,false]:
		var event:=InputEventMouseButton.new();event.position=point;event.global_position=point;event.button_index=MOUSE_BUTTON_LEFT;event.pressed=down
		root.push_input(event,true);await frames(1)
func scene_point(panel:Control,source:Vector2)->Vector2:return panel.view.get_global_transform_with_canvas()*(panel.view.origin+source*panel.view.fit)
func run()->void:
	state_node=root.get_node("State")
	state_node.action_completed.connect(func(action:String,_before:Dictionary,_after:Dictionary,_result:Dictionary):
		if action in ["c4_plate_press_event","c4_solve_positioning_calibration"]:press_actions.append(action)
	)
	for dimensions:Vector2i in [Vector2i(1440,900),Vector2i(1180,812),Vector2i(390,844)]:
		await setup_press(dimensions,false)
		shell.world_tasks.grab_focus();await frames()
		var original_focus:Control=root.gui_get_focus_owner()
		var player:Dictionary=state_node.d.native.player.duplicate(true)
		var count:int=press_actions.size()
		var panel:Control=await open_press()
		check(is_instance_valid(panel) and panel.get_script().resource_path=="res://scripts/objects/room201_press_panel.gd","201 target opens the actual fullscreen press")
		if not is_instance_valid(panel):continue
		check(panel.color.a==1 and panel.position==Vector2.ZERO and panel.size==Vector2(dimensions) and panel.scale==Vector2.ONE,"physical press fills actual viewport unscaled")
		check(not shell.world_frame.visible and not shell.phone.visible and not shell.world_tasks.visible and not shell.inventory_dock.visible and shell.world_viewport.gui_disable_input,"one press owns the surface and hidden world input")
		check(panel.session.view_kind()=="locked" and not panel.view.interactive,"missing actual plate shows empty non-operable press")
		await press_key(KEY_D);await press_key(KEY_ENTER)
		check(state_node.d.native.player==player and press_actions.size()==count and not state_node.d.native.has("c4_plate_press"),"empty-press keys cannot walk, fabricate a plate or start a checkpoint")
		check(Rect2(Vector2.ZERO,Vector2(dimensions)).encloses(screen_rect(panel.close_button)),"Return stays inside actual viewport")
		await press_key(KEY_TAB);check(root.gui_get_focus_owner()==panel.close_button,"Tab traps focus on native Return")
		await press_key(KEY_ENTER)
		check(shell.modal==null and shell.world_frame.visible and not shell.world_viewport.gui_disable_input,"Return restores world with input released")
		check(root.gui_get_focus_owner()==original_focus,"Return restores original root focus")

		state_node.act("c4_plate");await frames()
		check(state_node.d.items.clockPositioningPlate,"existing drawer collection supplies the exact plate")
		panel=await open_press()
		var before_facts:Array=state_node.d.chapter4.factIds.duplicate()
		await point_click(scene_point(panel,panel.view.loose_center));await settle(panel)
		check(panel.checkpoint.inserted and state_node.d.native.c4_plate_press.inserted,"actual plate pointer target inserts through State")
		await point_click(scene_point(panel,panel.view.lever_handle()));await settle(panel)
		check(state_node.d.chapter4.factIds==before_facts and panel.checkpoint.inserted and not panel.feedback.text.is_empty(),"actual wrong lever pull rebounds and retains the plate")
		await key_step(panel,KEY_LEFT)
		var partial:Dictionary=state_node.d.native.c4_plate_press.duplicate(true)
		await press_key(KEY_ESCAPE);panel=await open_press()
		check(panel.checkpoint==partial and not panel.view.dragging,"close and reopen retain accepted rail position but release gesture")
		await key_step(panel,KEY_LEFT);await key_step(panel,KEY_DOWN)
		for i in 3:await point_click(scene_point(panel,panel.view.wheel+Vector2(28,0)));await settle(panel)
		check(Model.ready_to_press(state_node.d.native.c4_plate_press) and state_node.d.chapter4.factIds==before_facts,"rail keys and actual spring wheel prepare the plate without awarding completion")
		await point_click(scene_point(panel,panel.view.lever_handle()));await settle(panel)
		check(panel.session.completed and state_node.d.chapter4.factIds.count("a2_positioning_plate_calibrated")==1 and state_node.d.items.clockPositioningPlate,"actual lever commits exactly one calibration, preserving plate for old clock")
		var accepted:Dictionary=state_node.d.duplicate(true)
		await press_key(KEY_ENTER);await press_key(KEY_R)
		check(state_node.d==accepted,"finished press cannot submit twice or reset progress")
		await mouse_click(panel.close_button);await frames()
		check(shell.modal==null and shell.world_frame.visible and not shell.world_viewport.gui_disable_input,"completed press returns to original exploration")

	await finish_cross_floor_route()
	# Legacy calibration may precede 204 pickup; preserve the fact, not a phantom item.
	await setup_press(Vector2i(390,844),false)
	state_node.d.chapter4.factIds.append("a2_positioning_plate_calibrated")
	var legacy_panel:Control=await open_press()
	check(legacy_panel.session.completed and not legacy_panel.plate_available and not legacy_panel.checkpoint.inserted and not legacy_panel.view.completed,"legacy completion before pickup shows no invented physical plate")
	check(legacy_panel.hint.text.contains("204") and not legacy_panel.hint.text.contains("背包里"),"legacy calibrated but unowned plate points back to actual drawer")
	await press_key(KEY_ESCAPE);state_node.act("c4_plate");legacy_panel=await open_press()
	check(legacy_panel.session.completed and legacy_panel.plate_available and legacy_panel.view.completed,"legacy completion remains accepted once original plate is really collected")
	await press_key(KEY_ESCAPE)
	# Resize/focus/pending replacement use the same host ownership as 302.
	await setup_press(Vector2i(1180,812));var panel:Control=await open_press()
	await key_step(panel,KEY_ENTER)
	var old_viewport:Vector2i=shell.world_viewport.size
	root.size=Vector2i(390,844);await frames(5)
	check(panel.size==Vector2(390,844) and shell.world_viewport.size==old_viewport,"resize refits press without mutating hidden exploration viewport")
	panel.session.pending=true;shell._modal_base("Replacement regression")
	var replacement:Control=shell.modal;var count:int=press_actions.size()
	panel.press_event_requested.emit({"kind":"reset"});panel.submit_requested.emit("c4_solve_positioning_calibration",Model.source().registration.calibration.duplicate(),1);panel.close_requested.emit()
	check(shell.modal==replacement and press_actions.size()==count and shell.room302_shell_restore.is_empty(),"retired callbacks cannot close replacement or write progress")
	shell._close_modal();await frames()
	for boundary:String in ["scene","context","mode","time","stairs"]:
		await setup_press(Vector2i(1180,812));panel=await open_press();panel.session.pending=true
		match boundary:
			"scene":state_node.d.native.scene="dorm_hub"
			"context":state_node.d.native.c4_context="power_topology"
			"mode":state_node.d.native.mode="dark";state_node.d.chapter4.mode="dark"
			"time":state_node.d.chapter4.timeState="2245_opening"
			"stairs":state_node.d.chapter4.factIds.erase("misaligned_stair_solved")
		state_node.changed.emit();await frames(5)
		check(shell.modal==null and shell.room302_shell_restore.is_empty() and not shell.world_viewport.gui_disable_input,"stale "+boundary+" closes pending press and releases input")
	await shell.shutdown();shell.queue_free();await frames(3)
	print("ROOM201_PRESS_MAIN ",checks," checks; ",failures," failures");quit(1 if failures else 0)

func finish_cross_floor_route()->bool:
	# Interaction entry is source-assisted; this is not a claim of walked navigation.
	# Real windows retain the existing focus gate; the harness never bypasses it.
	var focus_deadline:int=Time.get_ticks_msec()+20000
	if not root.has_focus():print("ROOM201_ROUTE_WAITING_FOR_NATIVE_FOCUS")
	while not root.has_focus() and Time.get_ticks_msec()<focus_deadline:await frames(1)
	if not root.has_focus():check(false,"native capture requires a genuinely focused game window");return false
	print("ROOM201_ROUTE_START focused=",root.has_focus()," from=",state_node.d.chapter4.floor)
	state_node.act("c4_elevator");await frames(5)
	var selector:Control=shell.modal
	check(is_instance_valid(selector) and selector.has_method("choose"),"calibrated plate reaches existing elevator selector")
	if not is_instance_valid(selector):return false
	await mouse_click(selector.buttons.A1);await mouse_click(selector.primary);await frames(2)
	check(is_instance_valid(shell.world_effect),"actual floor controls start original timed elevator ride")
	var travel_deadline:int=Time.get_ticks_msec()+20000
	var focus_pause_reported:=false
	while is_instance_valid(shell.world_effect) and Time.get_ticks_msec()<travel_deadline:
		if not root.has_focus():
			if not focus_pause_reported:print("ROOM201_ROUTE_PAUSED focused=false elapsed_ms=",shell.world_effect.elapsed_ms);focus_pause_reported=true
		else:shell.world_effect._process(.05)
		await frames(1)
	var arrived:bool=state_node.d.chapter4.floor=="A1" and shell.world_frame.visible
	check(arrived,"original elevator arrival retains the plate and returns to A1")
	print("ROOM201_ROUTE_ARRIVAL focused=",root.has_focus()," floor=",state_node.d.chapter4.floor," accepted=",arrived)
	if not arrived:return false
	state_node.act("c4_install_plate");await frames(4)
	check(not state_node.d.items.clockPositioningPlate and state_node.d.chapter4.phase=="maintenance_repair" and state_node.d.chapter4.timeState=="1850_evening","existing installation consumes plate exactly once but leaves clock untuned")
	state_node.act("c4_clock");await frames(5)
	var clock_panel:Control=shell.modal
	check(is_instance_valid(clock_panel) and clock_panel.required_time=="2245_maintenance","installed plate opens the existing 22:45 detent control")
	if not is_instance_valid(clock_panel):return false
	await mouse_click(clock_panel.buttons[2]);await mouse_click(clock_panel.submit_button);await frames(5)
	var stabilized:bool=state_node.d.chapter4.timeState=="2245_maintenance" and shell.modal==null and shell.world_frame.visible
	check(stabilized,"actual old-clock controls stabilize22:45 and restore exploration")
	return stabilized
