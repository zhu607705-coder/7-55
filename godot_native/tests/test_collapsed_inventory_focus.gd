extends SceneTree
## Real Main root-viewport input; source-eligible fixture, not an earned campaign.
var state: Node
var shell: Control
var checks: Array=[]
var actions: Array=[]
var case_name: String
func _initialize() -> void: run.call_deferred()
func frames(count:=3) -> void:
	for i in count: await process_frame
func focus_path(viewport: Viewport) -> String:
	var focused=viewport.gui_get_focus_owner()
	return str(focused.get_path()) if focused else "none"
func check(ok: bool,label: String,detail: Variant=null) -> void:
	checks.append({"case":case_name,"check":label,"pass":ok,"detail":detail,"root_focus":focus_path(root),"world_focus":focus_path(shell.world_viewport)})
	if not ok: push_error("INLINE INVENTORY: "+case_name+" / "+label)
func event(input: InputEvent) -> void:
	Input.parse_input_event(input); Input.flush_buffered_events()
func key(code: int,pressed: bool,shift:=false) -> void:
	var input:=InputEventKey.new(); input.keycode=code; input.physical_keycode=code; input.pressed=pressed; input.shift_pressed=shift; event(input)
	await process_frame
func press(code: int,shift:=false) -> void:
	await key(code,true,shift); await key(code,false,shift); await frames()
func click(control: Control) -> void:
	check(control.is_visible_in_tree() and Rect2(Vector2.ZERO,Vector2(root.size)).encloses(control.get_global_rect()),"pointer target is visible and onscreen")
	var point:=control.get_global_rect().get_center()
	var motion:=InputEventMouseMotion.new(); motion.position=point; motion.global_position=point; event(motion)
	for down in [true,false]:
		var input:=InputEventMouseButton.new(); input.position=point; input.global_position=point; input.button_index=MOUSE_BUTTON_LEFT; input.pressed=down; event(input); await process_frame
	await frames()
func fixture() -> void:
	shell._close_modal(); shell._close_phone_document(); state.story_reset.emit()
	state.d=state.initial(); state.developer_mode=true
	state.d.native.chapter=2; state.d.native.scene="library_interior"; state.d.native.page="library_app"
	state.d.runtimeMode="rpg"; state.d.rpgScene="library_interior"; state.d.rpgCheckpoint="library_entrance"
	state.d.actOne.phase="complete"; state.d.actOne.inventoryRecovered=true; state.d.networkMode="campus_wifi"
	state.d.ui.libraryFinalsPhase="library_entered"; state.d.ui.libraryFinalsPuzzle.libraryVisitedPoints=["entrance"]
	state.d.items.campusCard=true; state.d.items.rightArrow=true; state.d.items.occupancyNote=true
	state.d.native.positions={"library_interior:":{"x":715.0,"y":850.0}}
	shell.mobile_world=true; shell.compact_inventory_open=false; shell._refresh(); await frames(5)
	shell.world.set_process(false); shell.world._process(0); shell.world.grab_focus()
	check(shell.world.can_stand(shell.world.player) and shell.world.nearby.get("id","")!="entrance_record","fixture starts on valid floor outside record radius",shell.world.player)
	check(not shell.inventory_handle.visible and shell.inventory_dock.visible,"compact fixture directly exposes its item row")
func walk_to_record() -> void:
	var before:Vector2=shell.world.player
	await key(KEY_W,true)
	for i in 8: shell.world._process(.05)
	await key(KEY_W,false); shell.world._process(0)
	check(shell.world.player.distance_to(before)>1,"real W input moves the actor after releasing item focus",[before,shell.world.player])
	check(shell.world.nearby.get("id","")=="entrance_record","real nearby lookup resolves entrance record",shell.world.nearby.get("id",""))
func try_record() -> void:
	var count:=actions.count("lib_open_record")
	await press(KEY_SPACE)
	check(actions.count("lib_open_record")==count+1 and state.d.native.page=="library_record","next Space opens nearby record once through normal interaction",{"page":state.d.native.page,"actions":actions.count("lib_open_record")-count,"bag_open":shell.compact_inventory_open})
	check(not shell.inventory_handle.visible,"reading never restores the obsolete bag switch")
	check(not state.d.ui.libraryFinalsPuzzle.entranceRecordRead and not state.d.ui.libraryFinalsPuzzle.backpackInspected,"opening record preserves evidence acknowledgement and later story gates")
func inline_keyboard() -> void:
	await fixture()
	var view_before:Rect2=shell.world_view.get_global_rect()
	var camera_before:Vector2=shell.world.camera
	var item:Control=shell.inventory_buttons.get_child(0)
	item.grab_focus();await frames()
	var count:=actions.count("lib_open_record")
	await press(KEY_SPACE)
	check(state.d.native.selected_item==item.item_id and root.gui_get_focus_owner()==item,"Space selects the focused inline item")
	check(actions.count("lib_open_record")==count,"item Space never leaks into nearby world actions")
	await press(KEY_ENTER)
	check(is_instance_valid(shell.modal) and shell.inspected_item_id==item.item_id,"Enter opens the focused item's details")
	shell._close_modal();await frames()
	check(root.gui_get_focus_owner()==item,"closing details restores item focus")
	check(shell.world_view.get_global_rect()==view_before and shell.world.camera==camera_before,"item selection and inspection never resize or recenter the map")
	await press(KEY_ESCAPE)
	check(root.gui_get_focus_owner()==null and shell.world.has_focus(),"Escape returns item focus to world movement")
	await walk_to_record();await try_record()
func legacy_callback() -> void:
	await fixture()
	var view_before:Rect2=shell.world_view.get_global_rect()
	var count:=actions.size()
	shell.inventory_handle.pressed.emit();await frames()
	check(shell.inventory_dock.visible and not shell.inventory_handle.visible,"queued legacy bag callback leaves permanent items visible")
	check(shell.world_view.get_global_rect()==view_before and shell.world.has_focus() and root.gui_get_focus_owner()==null,"legacy callback cannot resize map or steal keyboard focus")
	check(actions.size()==count,"legacy callback submits no story action")
func assert_blocked(label: String) -> void:
	shell._sync_inventory_dock_input()
	var owner=root.gui_get_focus_owner(); var world_owner=shell.world_viewport.gui_get_focus_owner(); var count:=actions.size()
	for item:Control in shell.inventory_buttons.get_children():
		check(item.disabled,"guard disables actual inline item: "+label)
	# Exercise the actual connected callback too, as if a queued signal arrived
	# after the blocker opened. It may relayout but must never steal focus.
	shell.compact_inventory_open=true; shell.inventory_handle.pressed.emit(); await frames()
	check(root.gui_get_focus_owner()==owner and shell.world_viewport.gui_get_focus_owner()==world_owner,"collapse callback preserves blocker focus: "+label)
	check(actions.size()==count,"collapse callback does not submit story action: "+label)
	shell._resume_canteen_defense_after_reset(); await frames()
	check(root.gui_get_focus_owner()==owner and shell.world_viewport.gui_get_focus_owner()==world_owner,"late reset callback preserves blocker focus: "+label)
	# With no root owner, the existing phone/story/game guards must still stop
	# recovery from assigning keyboard input to the blocked world.
	root.gui_release_focus(); shell.world_viewport.gui_release_focus()
	shell._resume_canteen_defense_after_reset(); await frames()
	check(not shell.world.has_focus() and actions.size()==count,"late reset cannot focus or interact with blocked world: "+label)
func guards() -> void:
	await fixture()
	shell._modal_base("Focus guard"); await frames(); await assert_blocked("modal"); shell._close_modal()
	await fixture()
	shell._open_phone_document({"item_id":"occupancyNote"}); await frames(); await assert_blocked("phone document"); shell._close_phone_document()
	await fixture()
	state.d.ui.controlCenterOpen=true; await assert_blocked("control center"); state.d.ui.controlCenterOpen=false
	await fixture()
	shell._open_game({"script":"res://scripts/games/virtual_run.gd","viewport":[430,860]}); await frames(); await assert_blocked("active game")
	if is_instance_valid(shell.active_game): shell.active_game.cancelled.emit(); await frames()
	await fixture()
	shell.world.capture_mode=true; await assert_blocked("world capture"); shell.world.capture_mode=false
	await fixture()
	shell.world_effect=Control.new(); shell.world_effect.set_meta("blocks_input",true); shell.add_child(shell.world_effect)
	await assert_blocked("world effect"); shell.world_effect.free(); shell.world_effect=null
	await fixture()
	state.d.native.scene="campus_bootstrap"; state.d.ui.libraryFinalsPhase="library_route_unlocked"; state.act("lib_enter"); await frames()
	check(state.get_library_story_session()!=null,"story guard uses actual controller-issued Library dialogue")
	await assert_blocked("Library story"); state.story_reset.emit()
	await fixture()
	state.d.native.chapter=3; state.d.native.scene="canteen_interior"; state.d.native.page="c3_canteen"
	state.d.canteenHunt.active=true; state.d.canteenHunt.phase="tray_search"; state.d.canteenHunt.entryPaperEscaped=true
	shell._refresh(); await frames(); shell.world.player=Vector2(1466,608); shell.world._sync_player(); state.act("c3_target:auntie"); await frames()
	var story:RefCounted=state.get_c3_narrative_session()
	check(story!=null and not story.blocks_movement() and state.story_input_locked(),"ordinary C3 dialogue allows movement while locking interactions")
	await assert_blocked("C3 dialogue"); state.story_reset.emit()
	await fixture()
	shell.mobile_world=false; shell._layout(); await frames(); shell.mobile_back.release_focus()
	var phone_button:Control=shell.phone.find_children("*","Button",true,false)[0]; phone_button.grab_focus()
	check(not shell.world_frame.is_visible_in_tree(),"hidden-world guard uses visible phone surface")
	var count:=actions.size(); shell.inventory_handle.pressed.emit(); await frames()
	check(root.gui_get_focus_owner()==phone_button and not shell.world.has_focus(),"hidden-world collapse preserves phone focus")
	check(actions.size()==count,"hidden-world collapse preserves controller actions")
	shell._resume_canteen_defense_after_reset(); await frames()
	check(root.gui_get_focus_owner()==phone_button and not shell.world.has_focus(),"late reset preserves visible phone button focus")
	root.gui_release_focus(); shell._resume_canteen_defense_after_reset(); await frames()
	check(not shell.world.has_focus(),"late reset cannot focus a hidden world even without a root owner")

func subviewport_focus() -> void:
	case_name="subviewport-focus-owner"
	await fixture()
	var owner:=Button.new(); owner.text="Existing world UI"; shell.world.add_child(owner)
	root.gui_release_focus(); owner.grab_focus(); await frames()
	shell._resume_canteen_defense_after_reset(); await frames()
	check(root.gui_get_focus_owner()==null and shell.world_viewport.gui_get_focus_owner()==owner,"late reset preserves a valid SubViewport child focus owner")
	owner.queue_free(); await frames()

func imported_world_keyboard() -> void:
	case_name="desktop-normal-import-focus"
	# The source checkpoint supplies legal progression facts, not an earned
	# campaign claim. Export/import use the shipped validator and real files.
	shell._close_modal(); state.story_reset.emit(); await frames()
	state.developer_mode=true
	check(state.begin_checkpoint("c2-dorm-exit"),"source-eligible dorm exit fixture exists")
	state.d.native.erase("checkpoint_id")
	state.d.native.mode="light"
	state.d.native.positions={"dorm_hub:":{"x":504.0,"y":720.0}}
	check(state.export_save("user://focus-dorm.json")==OK,"ordinary portable dorm fixture exports through validator")
	state.d=state.initial(); state.developer_mode=false
	state.d.native.page="phone_home"; state.d.currentScene="phone_home"
	check(state.export_save("user://focus-phone.json")==OK,"ordinary phone fixture exports through validator")
	# Mount a real running Main rather than reusing the frozen spatial fixtures
	# above. Its normal refresh loop must own the imported visibility/targets.
	await shell.shutdown(); shell.queue_free(); await frames()
	root.size=Vector2i(1280,720)
	shell=load("res://scenes/main.tscn").instantiate(); root.add_child(shell); await frames(10)
	check(not shell.world_frame.is_visible_in_tree(),"normal import begins on the phone, not a pre-focused world")
	shell._show_settings(); await frames()
	var result:Dictionary=state.import_save("user://focus-dorm.json")
	check(result.get("ok",false),"normal file import accepts the source-eligible dorm fixture",result)
	await frames(10)
	check(shell.world_frame.is_visible_in_tree() and root.gui_get_focus_owner()==null and shell.world.has_focus(),"import reveals and focuses world after deferred layout without a test focus call")
	check(state.d.actOne.manualControlTested and state.d.actOne.canLeaveDorm and shell.world.nearby.get("id","")=="exit_door","import preserves original earned-fact and proximity requirements",{"target":shell.world.nearby,"position":shell.world.player})
	var before:Vector2=shell.world.player
	await key(KEY_RIGHT,true); await create_timer(.08).timeout; await key(KEY_RIGHT,false); await frames()
	check(shell.world.player.distance_to(before)>1 and shell.world.nearby.get("id","")=="exit_door","real root direction moves actor while legitimate exit remains nearby",{"before":before,"after":shell.world.player,"target":shell.world.nearby})
	var count:=actions.count("c2_dorm_exit")
	await press(KEY_SPACE); await frames(8)
	check(actions.count("c2_dorm_exit")==count+1 and state.d.native.scene=="campus_bootstrap","root Space exits imported dorm exactly once without test grabbing world focus")
	shell._show_settings(); await frames()
	result=state.import_save("user://focus-phone.json"); await frames(10)
	check(result.get("ok",false) and not shell.world_frame.is_visible_in_tree() and not shell.world.has_focus(),"normal phone import never focuses the hidden world",result)
func run() -> void:
	if not load("res://tests/native_test_isolation.gd").is_isolated_save():
		push_error("COLLAPSED INVENTORY TEST ISOLATION REQUIRED"); quit(2); return
	state=root.get_node("State"); state.developer_mode=true; state.d=state.initial()
	shell=load("res://scenes/main.tscn").instantiate(); root.add_child(shell); await frames(); shell.set_process(false)
	state.action_completed.connect(func(id,_before,_after,_result):actions.append(id))
	for dimensions in [Vector2i(390,844),Vector2i(430,860),Vector2i(844,390)]:
		root.size=dimensions; shell.size=Vector2(dimensions); await frames()
		case_name=str(dimensions)+"/inline-keyboard";await inline_keyboard()
		case_name=str(dimensions)+"/legacy-callback";await legacy_callback()
		case_name=str(dimensions)+"/guards"; await guards()
	await subviewport_focus()
	await imported_world_keyboard()
	var failures:=checks.filter(func(row):return not row.pass).size()
	var path:=OS.get_environment("UI_QA_REPORT")
	if not path.is_empty():
		var file:=FileAccess.open(path,FileAccess.WRITE); file.store_string(JSON.stringify({"kind":"native-Main-root-input-regression","graphical_acceptance":false,"checks":checks.size(),"failures":failures,"observations":checks},"\t")); file.close()
	await shell.shutdown(); shell.queue_free(); await frames()
	print("INLINE_INVENTORY_FOCUS: %d checks; %d failures"%[checks.size(),failures]); quit(1 if failures else 0)
