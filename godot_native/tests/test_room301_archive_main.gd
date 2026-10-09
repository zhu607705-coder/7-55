extends "res://tests/test_chapter4_device_main.gd"
## Real Main/root input with an explicitly source-seeded A3 checkpoint.
const ArchiveMotion=preload("res://scripts/objects/room301_archive_motion.gd")
var archive_submits:=0
func prepare_archive(dimensions:Vector2i)->void:
	if is_instance_valid(shell):
		await shell.shutdown();shell.queue_free();await frames(3)
	# Reuse the recorded native A3 elevator route. Remove only the archive
	# result so this test must earn it through the original solver again.
	state_node.d=JSON.parse_string(FileAccess.get_file_as_string("res://tests/fixtures/room302_earned_film_entry.json")).state
	state_node.d.chapter4.factIds.erase(ArchiveMotion.FACT)
	state_node.d.runtimeMode="rpg";state_node.developer_mode=true
	root.size=dimensions
	shell=load("res://scenes/main.tscn").instantiate();root.add_child(shell);shell._refresh();await frames(5)
func click_at(point:Vector2)->void:
	var motion:=InputEventMouseMotion.new();motion.position=point;root.push_input(motion,true)
	for down in [true,false]:
		var event:=InputEventMouseButton.new();event.position=point;event.global_position=point;event.button_index=MOUSE_BUTTON_LEFT;event.pressed=down
		root.push_input(event,true);await frames(1)
func touch_at(point:Vector2,index:=0)->void:
	for down in [true,false]:
		var event:=InputEventScreenTouch.new();event.position=point;event.index=index;event.pressed=down
		root.push_input(event,true);await frames(1)
func select_index(panel:Control,key:String,value:String,touch:=false)->void:
	var row:int=panel.view.KEYS.find(key)
	if row<0:check(false,"Missing source index "+key);return
	for attempt in range(4):
		if panel.session.draft[panel.view.DRAFT_KEYS[row]]==value:return
		var rect:Rect2=panel.view.index_targets[row].rect
		var at:=Vector2(rect.end.x-16,rect.get_center().y)
		if touch:await touch_at(at)
		else:await click_at(at)
	check(panel.session.draft[panel.view.DRAFT_KEYS[row]]==value,"Actual attached selector reaches "+value)
func settle(panel:Control)->void:
	for i in range(14):panel.view._process(.05)
	await frames(2)
func open_archive()->Control:
	state_node.act("c4_device_archive_index");await frames(4);return shell.modal
func shell_state()->Dictionary:
	return {"player":shell.world.player,"camera":shell.world.camera,"pan":shell.world.pan_offset,"viewport":shell.world_viewport.size,"world_visible":shell.world_frame.visible,"phone_visible":shell.phone.visible,"input":shell.world_viewport.gui_disable_input,"mobile":shell.mobile_world}
func run()->void:
	if not OS.get_user_data_dir().begins_with("/tmp/"):
		push_error("Refusing Room301 persistence tests outside an isolated /tmp HOME/XDG_DATA_HOME; formal saves must remain untouched.")
		quit(2)
		return
	state_node=root.get_node("State");state_node.developer_mode=true
	state_node.action_completed.connect(func(action:String,_a:Dictionary,_b:Dictionary,_c:Dictionary):if action=="c4_solve_archive_index":archive_submits+=1)
	for dimensions:Vector2i in [Vector2i(1280,720),Vector2i(390,844)]:
		await prepare_archive(dimensions)
		check(state_node.d.chapter4.floor=="A3","Source checkpoint owns original A3 access")
		shell._show_world_mobile();await frames();shell.world_tasks.grab_focus();await frames()
		var before:=shell_state();var panel:Control=await open_archive()
		check(is_instance_valid(panel) and panel.get_script().resource_path=="res://scripts/objects/room301_archive_panel.gd","Original archive action mounts dedicated object view")
		if not is_instance_valid(panel):continue
		check(not shell.world_frame.visible and shell.world_viewport.gui_disable_input,"Archive owns input while retaining world viewport")
		var player:Dictionary=state_node.d.native.player.duplicate(true)
		await press_key(KEY_D);check(state_node.d.native.player==player,"Modal key cannot walk original player")
		var touch:=dimensions.x==390
		await select_index(panel,"yearBand","1977_1984",touch);await select_index(panel,"floor","A1",touch);await select_index(panel,"purpose","attendance",touch)
		var count:=archive_submits
		if touch:await touch_at(panel.view.handle.get_center())
		else:await click_at(panel.view.handle.get_center())
		check(archive_submits==count+1 and not panel.session.completed and not panel.feedback.text.is_empty(),"Actual wrong drawer input reaches original solver once")
		await settle(panel)
		check(not ArchiveMotion.FACT in state_node.d.chapter4.factIds,"Wrong attempt has no film fact")
		await press_key(KEY_ESCAPE);check(shell.modal==null,"Escape closes without gameplay gate")
		check(shell_state()==before,"Cancel restores exact world, player, camera, shell and viewport")
		panel=await open_archive()
		check(panel.session.draft==panel.session.source.defaults,"Unfinished reentry resets the original ephemeral filter draft")
		await select_index(panel,"yearBand","1991_1998",touch)
		# Real ordinary persistence: local selections/gestures must not enter save.
		state_node.developer_mode=false
		check(state_node.save_game(),"Source checkpoint saves with unfinished local index")
		var partial_facts:Array=state_node.d.chapter4.factIds.duplicate()
		state_node.developer_mode=true
		panel.view._owned_pointer("touch",7,true,panel.view.handle.get_center())
		check(state_node.load_game(),"Ordinary save reload succeeds")
		shell._refresh();await frames(3)
		check(shell.modal==null,"Loading the same scene retires the old owning state and partial gesture")
		check(state_node.d.chapter4.factIds==partial_facts and not ArchiveMotion.FACT in state_node.d.chapter4.factIds,"Reload preserves unfinished facts without film reward")
		panel=await open_archive()
		check(panel.session.draft==panel.session.source.defaults and not panel.view.dragging,"Reload cannot restore half a selection gesture")
		await select_index(panel,"yearBand","1991_1998",touch);await select_index(panel,"floor","A3",touch);await select_index(panel,"purpose","wayfinding",touch)
		count=archive_submits
		if touch:await touch_at(panel.view.handle.get_center())
		else:await click_at(panel.view.handle.get_center())
		check(archive_submits==count+1 and panel.session.completed and ArchiveMotion.FACT in state_node.d.chapter4.factIds,"Actual index strips and handle grant only original archive fact")
		check(panel.fresh_success and shell.world.chapter4_layers.archive_motion.stage!="handoff","Accepted fact is immediate; world handoff waits for panel close")
		var facts:Array=state_node.d.chapter4.factIds.duplicate()
		await press_key(KEY_ENTER);check(archive_submits==count+1 and state_node.d.chapter4.factIds==facts,"Repeated completed Enter does not resubmit")
		await press_key(KEY_ESCAPE);await frames(1)
		check(shell.modal==null and shell.world.chapter4_layers.archive_motion.stage=="handoff","Closing starts one source-anchored handoff")
		check(shell.world.player==before.player and shell.world.camera==before.camera and shell.world.pan_offset==before.pan,"World handoff never reframes or teleports player")
		panel=await open_archive()
		check(panel.session.completed and not panel.fresh_success and shell.world.chapter4_layers.archive_motion.stage=="idle","Immediate reentry retires handoff and displays terminal state")
		await press_key(KEY_ESCAPE);await frames()
		check(shell.world.chapter4_layers.archive_motion.stage=="idle","Completed close never repeats film acquisition")
		state_node.developer_mode=false;check(state_node.save_game(),"Accepted original result saves normally")
		state_node.d=state_node.initial();check(state_node.load_game(),"Completed ordinary save reloads")
		state_node.developer_mode=true
		panel=await open_archive();check(panel.session.completed and not panel.fresh_success,"Completed reload is read-only without new acquisition")
		await press_key(KEY_ESCAPE)
	# A stale retired panel cannot submit, close, or start a later modal's handoff.
	await prepare_archive(Vector2i(1280,720))
	var retired:Control=await open_archive();shell.remove_child(retired);shell.modal=null
	var replacement:Control=await open_archive();var count:=archive_submits
	retired.submit_requested.emit("c4_solve_archive_index",{"yearBand":"1991_1998","floor":"A3","purpose":"wayfinding"},1)
	retired.close_requested.emit();retired.world_handoff_requested.emit(true);await frames()
	check(shell.modal==replacement and archive_submits==count and shell.world.chapter4_layers.archive_motion.stage!="handoff","Retired callback cannot submit, close replacement or replay acquisition")
	retired.dispose_session();retired.free();shell._close_modal();await frames()
	await shell.shutdown();shell.queue_free();await frames(3)
	print("ROOM301_ARCHIVE_MAIN: %d checks; %d failures"%[checks,failures]);quit(1 if failures else 0)
