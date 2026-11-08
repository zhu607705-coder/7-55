extends SceneTree
## Portable headless Main/input contract; no developer checkpoint or UI callback shortcuts.
const Chapter=preload("res://scripts/chapters/chapter1_2.gd")
const DisplayFixture=preload("res://tests/zh_text_fixture.gd")
const RULE_BODY="期末周修订版 · 已归档\n适用范围：座位被非本人随身物持续占用\n目标座位：022\n恢复申请须同时具备三类证明：\n一、本人确实到馆；\n二、目标座位与凭据一致；\n三、当前占用物不具备本人身份。\n规则依据须先完成公开公示。"
var state: Node
var shell: Control
var checks=0
var failures=0
var outcomes: Array=[]
var geometry: Array=[]
var events: Array=[]
var case_name=""
var before_shelf: Dictionary

func _initialize() -> void: run.call_deferred()
func frames(count: int=4) -> void:
	for i in range(count): await process_frame
func check(ok: bool,message: String) -> void:
	checks+=1
	outcomes.append({"case":case_name,"check":message,"passed":ok})
	if not ok: failures+=1; push_error("LIBRARY RULE: "+case_name+" / "+message)
func screen_rect(control: Control) -> Rect2:
	var transform=control.get_global_transform_with_canvas()
	return Rect2(transform.origin,control.size*transform.get_scale())
func buttons(text: String) -> Array:
	return shell.page_body.find_children("*","Button",true,false).filter(func(button): return button.text==text)
func click_at(point: Vector2) -> void:
	var motion=InputEventMouseMotion.new(); motion.position=point; root.push_input(motion,true)
	for down in [true,false]:
		var event=InputEventMouseButton.new(); event.position=point; event.button_index=MOUSE_BUTTON_LEFT; event.pressed=down; root.push_input(event,true)
		await frames(1)
	await frames()
func key(code: Key) -> void:
	for down in [true,false]:
		var event=InputEventKey.new(); event.keycode=code; event.physical_keycode=code; event.pressed=down; root.push_input(event,true)
		await frames(1)
	await frames()
func acknowledge(controller: RefCounted,s: Dictionary) -> void:
	var session=controller.library.story_session(s)
	while session!=null:
		session.attach(s,self)
		for line in session.lines: session.advance(s,self)
		controller.dispatch(s,"lib_story_complete",session)
		session=controller.library.story_session(s)
func earned_shelf() -> Dictionary:
	var s=state.initial()
	s.native.chapter=2; s.native.page="library_app"; s.native.scene="campus_bootstrap"
	s.actOne.phase="complete"; s.actOne.cc98Login.authenticated=true; s.networkMode="campus_wifi"
	s.ui.libraryFinalsPhase="library_route_unlocked"
	var controller=Chapter.new()
	controller.dispatch(s,"lib_enter"); acknowledge(controller,s)
	controller.dispatch(s,"lib_register_arrival"); controller.dispatch(s,"lib_record"); controller.dispatch(s,"lib_backpack"); acknowledge(controller,s)
	controller.dispatch(s,"lib_note"); controller.dispatch(s,"lib_investigate","occupancyNote"); acknowledge(controller,s)
	controller.dispatch(s,"lib_catalog_terminal"); controller.dispatch(s,"lib_catalog_search","三分钟离座法")
	controller.dispatch(s,"lib_catalog_select","three-minute-leave-method"); acknowledge(controller,s)
	check(s.items.callNumber755 and s.ui.libraryFinalsPuzzle.callNumberCollected,"ordinary source actions earn the shelf item")
	check(not s.ui.libraryFinalsPuzzle.archivedRuleCollected and not s.ui.libraryFinalsPuzzle.archivedRuleRead,"shelf fixture has not collected or acknowledged the rule")
	return s
func document_access() -> void:
	var controller=Chapter.new()
	var s: Dictionary=before_shelf.duplicate(true)
	var items: Dictionary=s.items.duplicate(true)
	var result: Dictionary=controller.dispatch(s,"lib_open_rule")
	check(not result.has("page") and s.items==items and not s.ui.libraryFinalsPuzzle.archivedRuleRead,"unacquired rule cannot be opened or acknowledged through its document intent")
	controller.dispatch(s,"lib_shelf")
	items=s.items.duplicate(true)
	# The retained paper belongs to the player, including after an ordinary
	# library exit. No physical shelf replay or second item grant is needed.
	controller.dispatch(s,"lib_exit")
	result=controller.dispatch(s,"lib_open_rule")
	check(result.get("page","")=="library_rule" and s.native.scene=="campus_bootstrap","acquired paper opens after leaving the Library without changing the retained scene")
	check(s.items==items and not s.ui.libraryFinalsPuzzle.archivedRuleRead,"opening an acquired document preserves all items and does not acknowledge reading")
	controller.dispatch(s,"lib_read_rule"); acknowledge(controller,s)
	check(s.ui.libraryFinalsPuzzle.archivedRuleRead and s.ui.libraryFinalsPuzzle.archivedRuleBriefingSeen,"explicit read and its authored briefing remain the only acknowledgement path outside the Library")
	controller.dispatch(s,"lib_upload","archived_leave_rule")
	check(not s.items.archivedLeaveRule,"ordinary public upload consumes its original rule item")
	items=s.items.duplicate(true)
	result=controller.dispatch(s,"lib_open_rule")
	check(result.get("page","")=="library_rule" and s.items==items and not s.items.archivedLeaveRule,"reopening the acquired archive after upload never recreates a consumed original")
func refresh() -> void:
	shell._refresh(); await frames()
	if state.get_phone_entry_session().phase=="loading": state.advance_phone_entry(1500); shell._refresh(); await frames()
	shell.world.set_process(false)
func reopen(page: String) -> void:
	state.open_page(page); await refresh()
func reopen_rule_by_pointer() -> void:
	var header: Button=shell.page_body.find_child("PhoneNav_back",true,false)
	check(header!=null and header.tooltip_text=="返回图书馆","rule reader exposes its ordinary Library header return")
	if header==null: return
	await click_at(screen_rect(header).get_center()); await refresh()
	check(state.d.native.page=="library_app","actual rule header returns to Library home")
	var target: Button=shell.page_body.find_child("LibraryApp_rule",true,false)
	check(target!=null,"acquired rule has a persistent ordinary Library app entry")
	if target==null: return
	check(screen_rect(shell.phone_scroll).encloses(screen_rect(target)),"acquired rule entry is visible at the initial Library home scroll")
	await click_at(screen_rect(target).get_center()); await refresh()
	check(state.d.native.page=="library_rule","actual acquired-rule entry opens its existing reader")
func fixture() -> void:
	state.story_reset.emit(); state.d=before_shelf.duplicate(true)
	shell.phone_builder.native_library.reset(); shell.compact_inventory_open=false
	shell.mobile_world=true; shell.world_page_origin_scene="library_interior"
	await refresh()
	state.act("lib_shelf"); await refresh()
	check(state.d.native.page=="library_rule" and state.d.items.archivedLeaveRule and not state.d.items.callNumber755,"normal shelf dispatch opens rule and consumes exactly the earned call number")
	check(not state.d.ui.libraryFinalsPuzzle.archivedRuleRead and state.get_library_story_session()==null,"opening rule does not acknowledge it or start its reading dialogue")
	check(shell.world_frame.visible and not shell.phone.visible,"accepted shelf acquisition keeps the cabinet reveal visible")
	for i in range(290): shell.world._process(0.01)
	await refresh()
	check(not shell.phone.visible and shell.world_frame.visible and is_instance_valid(shell.modal),"complete reveal opens a world document over the retained scene")
func check_rule_text() -> void:
	var labels=shell.page_body.find_children("*","Label",true,false).filter(func(label): return label.text==RULE_BODY)
	check(labels.size()==1,"exact complete rule wording appears once")
	if labels.size()==1:
		check(labels[0].get_line_count()==labels[0].get_visible_line_count(),"every rule line fits the unchanged card")
		check(screen_rect(shell.phone_scroll).grow(.5).encloses(screen_rect(labels[0])),"complete rule text is visible at initial scroll")
		var chrome=shell.phone_chrome
		check(chrome.inventory.is_visible_in_tree() and not chrome.inventory_open,"source phone inventory rail remains visible and collapsed")
		var handle=screen_rect(chrome.inventory_handle)
		var shadow=handle; shadow.position+=Vector2(3,3)*chrome.inventory_handle.get_global_transform_with_canvas().get_scale()
		var badge=screen_rect(chrome.inventory_count)
		for rail in [handle,shadow,badge]:
			check(not screen_rect(labels[0]).intersects(rail),"collapsed phone handle, badge and shadow do not cover rule text")
func assert_collapsed_rail(viewport: Vector2i) -> void:
	check(not shell.compact_inventory_open,"phone and rule navigation preserve collapsed inventory preference")
	if viewport.x<1100:
		check(not shell.inventory_handle.is_visible_in_tree() and not shell.inventory_dock.is_visible_in_tree(),"compact phone surface has no inventory overlay")
		shell._show_world_mobile(); await frames()
		check(not shell.inventory_handle.is_visible_in_tree() and shell.inventory_dock.is_visible_in_tree(),"return to world retains directly exposed items without a bag toggle")
		check(screen_rect(shell.world_view).encloses(screen_rect(shell.inventory_dock)),"inline items remain inside the world without changing its viewport")
		shell.mobile_world=false; shell._layout(); await frames()
	else:
		check(not shell.inventory_dock.is_visible_in_tree(),"desktop phone mode hides the world inventory")
func run() -> void:
	state=root.get_node("State");state.developer_mode=true;state.d=state.initial()
	before_shelf=earned_shelf();document_access()
	shell=load("res://scenes/main.tscn").instantiate();root.add_child(shell);await frames();shell.set_process(false)
	state.action_completed.connect(func(id,_before,_after,result):events.append({"id":id,"result":result.duplicate(true)}))
	for dimensions:Vector2i in [Vector2i(390,844),Vector2i(430,860),Vector2i(1440,900)]:
		case_name=str(dimensions);root.size=dimensions;shell.size=Vector2(dimensions);await frames();await fixture()
		var reader:Control=shell.modal
		var scroll:ScrollContainer=reader.find_child("LibraryWorldDocumentScroll",true,false)
		var action:Button=reader.find_child("LibraryWorldDocumentClose",true,false)
		check(reader!=null and scroll!=null and action!=null,"earned paper mounts the actual bound volume")
		if reader==null or scroll==null or action==null:continue
		var items:Dictionary=state.d.items.duplicate(true)
		check(action.disabled and not reader.end_seen,"read action cannot acknowledge the cover")
		check(reader.find_children("*","Label",true,false).any(func(label):return label.text==RULE_BODY),"all original rule wording is preserved")
		shell._return_from_phone();await key(KEY_ESCAPE);await key(KEY_P)
		check(shell.mobile_world and not shell.phone.visible and state.d.native.page=="library_rule","map and keyboard cannot leave before the end")
		check(not state.d.ui.libraryFinalsPuzzle.archivedRuleRead and state.d.items==items,"blocked navigation never grants a read or changes items")
		scroll.scroll_vertical=100000;await frames()
		check(reader.end_seen and not action.disabled,"the actual scroll end enables closing")
		var count:int=events.size()
		await click_at(screen_rect(action).get_center())
		check(state.d.ui.libraryFinalsPuzzle.archivedRuleRead,"closing at the end submits the original read intent")
		check(events.slice(count).filter(func(row):return row.id=="lib_read_rule").size()==1,"read is committed exactly once")
		check(state.d.items==items,"reading preserves inventory")
	await shell.shutdown();shell.queue_free();await frames()
	print("LIBRARY_RULE_ACTION: ",checks," checks; ",failures," failures")
	quit(1 if failures else 0)
