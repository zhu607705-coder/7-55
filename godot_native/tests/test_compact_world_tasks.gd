extends "res://tests/test_portrait_exploration.gd"
## Actual Main controls and root input; isolated source-phase fixtures.
## Display-edge clearance is checked here, not physical device notch behavior.
var observations: Array=[]
var current_size:=Vector2i(390,844)
func node(id: String) -> Control: return shell.find_child(id,true,false)
func key(code: int,down: bool,shift:=false) -> void:
	var input:=InputEventKey.new();input.keycode=code;input.physical_keycode=code;input.pressed=down;input.shift_pressed=shift
	event(input);await process_frame
func press(code: int,shift:=false) -> void:
	await key(code,true,shift);await key(code,false,shift);await frames()
func setup_world(dimensions: Vector2i,bag_open:=false) -> void:
	shell._close_modal();shell._close_phone_document();state.story_reset.emit()
	check(state.begin_checkpoint("c3-canteen-entry"),"fixture loads original checkpoint")
	state.d.canteenHunt.entryPaperEscaped=true
	state.d.canteenHunt.trayTaskStarted=true
	state.d.canteenHunt.returnedTrayIds=["tray_blue_01","tray_blue_02","tray_blue_03"]
	state.d.canteenHunt.queueChallengeSeen=true;state.d.canteenHunt.drinkShelfRead=true
	state.d.playerName="这是一个很长的角色名字用于检查顶部入口不会随世界文字挤出画面"
	state.d.native.log=[{"text":"这是一条很长的已见记录，用来确认任务入口不会把历史文本放进顶部工具栏。","time":"fixture"}]
	current_size=dimensions;root.size=dimensions;shell.size=Vector2(dimensions)
	shell.mobile_world=true;shell.compact_inventory_open=bag_open;shell._refresh();await frames(6)
	shell.world.set_process(false);shell.c3_scene_host.set_process(false);shell.c3_narrative_host.set_process(false)
	shell.world.grab_focus()
func presentation() -> Dictionary:
	return {"phone_size":shell.phone.size,"phone_scale":shell.phone.scale,"phone_position":shell.phone.position,"world_size":shell.world.size,"world_scale":shell.world_frame.scale,"world_rect":shell.world_frame.get_global_rect(),"viewport":shell.world_viewport.size,"player":shell.world.player,"camera":shell.world.camera,"zoom":shell.world.zoom,"pan":shell.world.pan_offset,"bag":shell.compact_inventory_open,"controls":shell.world.mobile_control_metrics()}
func check_top_row() -> void:
	var tasks:Control=shell.world_tasks
	check(tasks.is_visible_in_tree() and not tasks.disabled,"compact world exposes enabled direct Tasks entry")
	check(tasks.text=="任务" and tasks.size==Vector2(84,44) and tasks.scale==Vector2.ONE,"Tasks remains a bounded physical44px target")
	check(Rect2(8,8,shell.size.x-16,48).encloses(tasks.get_global_rect()),"Tasks fits the existing top-row edge clearance")
	check(not tasks.get_global_rect().intersects(shell.mobile_back.get_global_rect()),"Tasks does not cover return-to-phone")
	check(not tasks.get_global_rect().intersects(shell.world_frame.get_global_rect()),"Tasks stays outside world camera and touch surface")
	if shell.inventory_handle.visible:
		check(not tasks.get_global_rect().intersects(shell.inventory_handle.get_global_rect()),"Tasks does not overlap portrait or landscape bag handle")
	check(shell.find_children("WorldTasks","Button",true,false).size()==1 and node("JournalObjective")==null,"world adds one entry and no permanent objective panel")
	observations.append({"viewport":str(current_size),"tasks":str(tasks.get_global_rect()),"back":str(shell.mobile_back.get_global_rect()),"bag":str(shell.inventory_handle.get_global_rect()),"world":str(shell.world_frame.get_global_rect()),"bag_open":shell.compact_inventory_open})
func check_theme() -> void:
	var button:Button=shell.world_tasks
	check(button.get_theme_font("font")==shell.font and button.get_theme_font_size("font_size")==18,"Tasks inherits the existing world top-row typography")
	var reference:StyleBoxFlat=button.get_theme_stylebox("normal")
	for name in ["hover","pressed","hover_pressed","disabled"]:
		var style:StyleBoxFlat=button.get_theme_stylebox(name)
		check(style.get_minimum_size()==reference.get_minimum_size(),"button state preserves hit-area geometry: "+name)
	check(button.get_theme_stylebox("focus").border_width_left>=2,"Tasks retains visible keyboard focus outline")
func journal_round_trip(method: String) -> void:
	var before:=JSON.stringify(state.d);var layout:=presentation();var count:=actions.size()
	# Use a held thumb intent to verify an opening journal ends its ownership.
	shell.world.touch_axis=Vector2.LEFT;shell.world.mobile_touch_roles[9]="stick"
	if method=="keyboard":shell.world_tasks.grab_focus();await press(KEY_SPACE)
	elif method=="touch":
		var point:Vector2=shell.world_tasks.get_global_rect().get_center();touch(point,true);touch(point,false);await frames()
	else:await click(shell.world_tasks)
	check(is_instance_valid(shell.modal) and node("NativeJournal")!=null,"direct "+method+" opens the existing journal")
	if not is_instance_valid(shell.modal):return
	check(node("JournalObjective").text==state.objective() and node("JournalNextStep").text.contains("调配台"),"direct journal shows the current earned-fact objective")
	check(shell.modal.find_children("NativeJournal","",true,false).size()==1,"direct entry mounts exactly one journal")
	check(shell.world_tasks.disabled and shell.inventory_handle.disabled,"journal blocks background top-row and inventory input")
	check(shell.world.touch_axis==Vector2.ZERO and shell.world.mobile_touch_roles.is_empty(),"opening ends outstanding thumb ownership")
	check(root.gui_get_focus_owner()==node("JournalResume"),"existing resume button receives keyboard focus")
	var identity:int=shell.modal.get_instance_id();shell.world_tasks.pressed.emit();await frames()
	check(shell.modal.get_instance_id()==identity,"queued repeated Tasks cannot replace its modal")
	await press(KEY_TAB);check(shell.modal.is_ancestor_of(root.gui_get_focus_owner()),"journal Tab remains trapped inside modal")
	await key(KEY_D,true);shell.world._process(.15);await key(KEY_D,false)
	check(shell.world.player==layout.player,"held movement key cannot move world under journal")
	if method=="keyboard":await click(node("JournalResume"))
	else:await press(KEY_ESCAPE)
	check(not is_instance_valid(shell.modal) and shell.world.has_focus() and root.gui_get_focus_owner()==null,"journal close restores world input focus")
	check(not shell.world_tasks.disabled and presentation()==layout,"journal close restores controls without changing phone/world/camera/body geometry")
	check(JSON.stringify(state.d)==before and actions.size()==count,"open/read/close does not change any save fact or submit a story action")
	await press(KEY_ENTER);check(not is_instance_valid(shell.modal),"next Enter does not reopen a stale Tasks focus")
func phone_round_trip() -> void:
	var geometry:=presentation();var hunt:Dictionary=state.d.canteenHunt.duplicate(true)
	await click(shell.mobile_back)
	check(shell.phone.visible and not shell.world_tasks.visible and not shell.world_frame.visible,"phone return hides the world Tasks entry")
	var page:String=state.d.native.page;shell.world_tasks.pressed.emit();await frames()
	check(not is_instance_valid(shell.modal) and state.d.native.page==page,"queued hidden-world press cannot open journal over phone")
	var back:Control
	for button in shell.page_body.find_children("*","Button",true,false):
		if button.text=="返回现场":back=button
	check(back!=null,"ordinary phone page retains its existing return-to-world action")
	if back==null:return
	shell.phone_scroll.ensure_control_visible(back);await frames();await click(back)
	check(shell.world_tasks.visible and not shell.phone.visible and shell.world_frame.visible,"normal phone return restores direct Tasks")
	check(presentation()==geometry and state.d.canteenHunt==hunt,"phone round trip preserves world, phone and story facts")
func restored_movement() -> void:
	await click(shell.world_tasks);await frames();await click(node("JournalResume"))
	var before:Vector2=shell.world.player;var hunt:Dictionary=state.d.canteenHunt.duplicate(true)
	var direction:=Vector2.RIGHT if shell.world.can_stand(before+Vector2(8.25,0)) else Vector2.LEFT
	await key(KEY_D if direction==Vector2.RIGHT else KEY_A,true);shell.world._process(.05)
	await key(KEY_D if direction==Vector2.RIGHT else KEY_A,false)
	check(shell.world.player.distance_to(before)>1 and not is_instance_valid(shell.modal),"real keyboard movement resumes after direct journal close")
	before=shell.world.player
	var controls:Dictionary=shell.world.mobile_control_metrics()
	var point:=world_screen(controls.stick+Vector2(32,0))
	touch(point,true);await frames(2);shell.world._process(.05);touch(point,false);await frames()
	check(shell.world.player.distance_to(before)>1 and shell.world.touch_axis==Vector2.ZERO,"real thumb input resumes and releases after direct journal close")
	check(state.d.canteenHunt==hunt,"restored movement does not fabricate canteen progression")
func rejected_press(label: String) -> void:
	shell._sync_inventory_dock_input();var before:=JSON.stringify(state.d);var count:=actions.size()
	var owner=root.gui_get_focus_owner();var modal:Control=shell.modal;var game:Control=shell.active_game
	check(shell.world_tasks.disabled,"Tasks respects existing input lock: "+label)
	shell.world_tasks.pressed.emit();await frames()
	check(shell.modal==modal and shell.active_game==game and root.gui_get_focus_owner()==owner,"queued Tasks preserves existing owner: "+label)
	check(JSON.stringify(state.d)==before and actions.size()==count,"blocked Tasks leaves story state unchanged: "+label)
func guards() -> void:
	await setup_world(current_size)
	shell._modal_base("现有窗口");await frames();await rejected_press("modal");shell._close_modal()
	await setup_world(current_size)
	shell._open_phone_document({"item_id":"occupancyNote"});await frames();await rejected_press("phone document");shell._close_phone_document()
	await setup_world(current_size)
	state.d.ui.controlCenterOpen=true;await rejected_press("control center");state.d.ui.controlCenterOpen=false
	shell.world.capture_mode=true;await rejected_press("capture");shell.world.capture_mode=false
	shell.world_effect=Control.new();shell.world_effect.set_meta("blocks_input",true);shell.add_child(shell.world_effect)
	await rejected_press("world effect");shell.world_effect.free();shell.world_effect=null
	await setup_world(current_size)
	shell._open_game({"script":"res://scripts/games/virtual_run.gd","viewport":[430,860]});await frames()
	check(not shell.world_tasks.visible,"active minigame hides the Tasks entry")
	await rejected_press("minigame")
	if is_instance_valid(shell.active_game):shell.active_game.cancelled.emit();await frames()
	check(shell.world_tasks.visible and not shell.world_tasks.disabled,"minigame cancel restores Tasks")
	await setup_world(current_size)
	state.d.canteenHunt.trayTaskStarted=false;state.d.canteenHunt.returnedTrayIds=[];shell._refresh();await frames()
	shell.world.player=Vector2(1466,608);shell.world._sync_player();state.act("c3_target:auntie");await frames()
	check(state.get_c3_narrative_session()!=null and state.story_input_locked(),"guard uses a controller-issued C3 dialogue")
	await rejected_press("C3 narrative");state.story_reset.emit()
func run() -> void:
	check(ProjectSettings.globalize_path("user://").begins_with("/tmp/"),"test uses an isolated profile")
	if failures:quit(1);return
	state=root.get_node("State");state.developer_mode=true;state.d=state.initial()
	shell=load("res://scenes/main.tscn").instantiate();root.add_child(shell);await frames();shell.set_process(false)
	state.action_completed.connect(func(id,_a,_b,_result):actions.append(id))
	for dimensions in [Vector2i(390,844),Vector2i(430,860),Vector2i(844,390),Vector2i(860,430)]:
		for bag_open in [false,true]:
			await setup_world(dimensions,bag_open);check_top_row();check_theme()
			for method in ["pointer","keyboard","touch"]:await journal_round_trip(method)
			await phone_round_trip()
			await restored_movement()
		await guards()
	var earned_path:=OS.get_environment("CANTEEN_EARNED_SAVE")
	if not earned_path.is_empty():
		var earned:Dictionary=JSON.parse_string(FileAccess.get_file_as_string(earned_path)).state
		for dimensions in [Vector2i(390,844),Vector2i(430,860),Vector2i(844,390),Vector2i(860,430)]:
			shell._close_modal();state.story_reset.emit();state.d=earned.duplicate(true)
			current_size=dimensions;root.size=dimensions;shell.size=Vector2(dimensions);shell.mobile_world=true
			shell.compact_inventory_open=false;shell._refresh();await frames(6)
			shell.world.set_process(false);shell.c3_scene_host.set_process(false);shell.c3_narrative_host.set_process(false)
			check_top_row()
			for method in ["pointer","keyboard","touch"]:await journal_round_trip(method)
	await setup_world(Vector2i(1440,900))
	check(shell.world_tasks.visible and not shell.phone.visible and shell.world_viewport.size==Vector2i(960,540),"desktop exposes world tasks and retains authored viewport")
	shell.world_tasks.pressed.emit();await frames();check(is_instance_valid(shell.modal),"desktop uses the same world Tasks path");shell._close_modal()
	var output:=OS.get_environment("UI_QA_REPORT")
	if not output.is_empty():
		var file:=FileAccess.open(output,FileAccess.WRITE);file.store_string(JSON.stringify({"checks":checks,"failures":failures,"gui_used":false,"physical_device":false,"earned_snapshot":not earned_path.is_empty(),"observations":observations},"\t"));file.close()
	await shell.shutdown();shell.queue_free();await frames()
	print("COMPACT_WORLD_TASKS: %d checks; %d failures"%[checks,failures]);quit(1 if failures else 0)
