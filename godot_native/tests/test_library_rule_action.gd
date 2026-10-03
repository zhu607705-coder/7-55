extends SceneTree
## Portable headless Main/input contract; no developer checkpoint or UI callback shortcuts.
const Chapter=preload("res://scripts/chapters/chapter1_2.gd")
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
	controller.dispatch(s,"lib_record"); controller.dispatch(s,"lib_backpack"); acknowledge(controller,s)
	controller.dispatch(s,"lib_note"); controller.dispatch(s,"lib_investigate","occupancyNote"); acknowledge(controller,s)
	controller.dispatch(s,"lib_catalog_terminal"); controller.dispatch(s,"lib_catalog_search","三分钟离座法")
	controller.dispatch(s,"lib_catalog_select","three-minute-leave-method"); acknowledge(controller,s)
	check(s.items.callNumber755 and s.ui.libraryFinalsPuzzle.callNumberCollected,"ordinary source actions earn the shelf item")
	check(not s.ui.libraryFinalsPuzzle.archivedRuleCollected and not s.ui.libraryFinalsPuzzle.archivedRuleRead,"shelf fixture has not collected or acknowledged the rule")
	return s
func refresh() -> void:
	shell._refresh(); await frames()
	if state.get_phone_entry_session().phase=="loading": state.advance_phone_entry(1500); shell._refresh(); await frames()
	shell.world.set_process(false)
func reopen(page: String) -> void:
	state.open_page(page); await refresh()
func fixture() -> void:
	state.story_reset.emit(); state.d=before_shelf.duplicate(true)
	shell.phone_builder.native_library.reset(); shell.compact_inventory_open=false
	shell.mobile_world=true; shell.world_page_origin_scene="library_interior"
	await refresh()
	state.act("lib_shelf"); await refresh()
	check(state.d.native.page=="library_rule" and state.d.items.archivedLeaveRule and not state.d.items.callNumber755,"normal shelf dispatch opens rule and consumes exactly the earned call number")
	check(not state.d.ui.libraryFinalsPuzzle.archivedRuleRead and state.get_library_story_session()==null,"opening rule does not acknowledge it or start its reading dialogue")
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
		check(shell.inventory_handle.is_visible_in_tree() and not shell.inventory_dock.is_visible_in_tree(),"return to world retains collapsed inventory rail")
		check(not screen_rect(shell.world_frame).intersects(screen_rect(shell.inventory_handle)),"collapsed inventory rail never covers world viewport")
		shell.mobile_world=false; shell._layout(); await frames()
	else:
		check(not screen_rect(shell.phone).intersects(screen_rect(shell.inventory_dock)),"desktop inventory stays separate from phone")
func run() -> void:
	state=root.get_node("State"); state.developer_mode=true; state.d=state.initial()
	before_shelf=earned_shelf()
	shell=load("res://scenes/main.tscn").instantiate(); root.add_child(shell); await frames(); shell.set_process(false)
	state.action_completed.connect(func(id,_before,_after,result): events.append({"id":id,"result":result.duplicate(true)}))
	var source: Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://tests/fixtures/library_story_source.json"))
	for viewport in [Vector2i(390,844),Vector2i(430,860),Vector2i(1440,900)]:
		case_name=str(viewport); root.size=viewport; shell.size=Vector2(viewport); await frames()
		await fixture()
		var items=state.d.items.duplicate(true); var puzzle=state.d.ui.libraryFinalsPuzzle.duplicate(true)
		var phone_rect=screen_rect(shell.phone)
		for repeat in range(3):
			if repeat>0: await reopen("library_app"); await reopen("library_rule")
			check_rule_text()
			var matches=buttons("阅读旧版离座规则")
			check(matches.size()==1,"existing controller action appears exactly once after open/reopen")
			if matches.size()!=1: continue
			var target: Button=matches[0]; var rect=screen_rect(target)
			var visible=screen_rect(shell.phone_scroll).grow(.5).encloses(rect)
			check(visible,"reading action is visible beside the rule at initial scroll")
			check(target.name=="LibraryRuleAction","reading action is handled within its rule page")
			check(rect.size.y>=43.99,"reading action is at least 44 physical pixels tall")
			check(not target.disabled,"earned reading action stays enabled")
			var chrome=shell.phone_chrome
			var inventory_right=maxf(screen_rect(chrome.inventory_handle).end.x+3*chrome.scale.x*shell.phone.scale.x,screen_rect(chrome.inventory_count).end.x)
			check(rect.position.x>=inventory_right,"action clears collapsed rail even when rail is moved vertically")
			check(state.d.items==items and state.d.ui.libraryFinalsPuzzle==puzzle,"opening and reopening never mutate inventory or proof")
			check(screen_rect(shell.phone)==phone_rect,"rule reopening keeps canonical phone bounds")
			geometry.append({"viewport":str(viewport),"repeat":repeat,"button":str(rect),"scroll":str(screen_rect(shell.phone_scroll)),"visible":visible})
		await assert_collapsed_rail(viewport)
		var matches=buttons("阅读旧版离座规则")
		if matches.size()!=1 or not screen_rect(shell.phone_scroll).grow(.5).encloses(screen_rect(matches[0])): continue
		var point=screen_rect(matches[0]).get_center(); var event_count=events.size()
		await click_at(point)
		check(events.slice(event_count).filter(func(event): return event.id=="lib_read_rule").size()==1,"real pointer dispatches lib_read_rule exactly once")
		check(state.d.ui.libraryFinalsPuzzle.archivedRuleRead and not state.d.ui.libraryFinalsPuzzle.archivedRuleBriefingSeen,"read queues briefing without prematurely acknowledging it")
		check(state.d.items==items,"reading never consumes or creates another item")
		var host=shell.library_story_host; host.set_process(false); host.tick(0)
		check(host.current!=null and host.current.sequence_id=="library_archived_rule_recovered","existing source reading dialogue remains the owner")
		if host.current!=null:
			var expected: Array=source.sequences.library_archived_rule_recovered
			check(host.current.lines.size()==expected.size(),"reading retains every authored dialogue line")
			check(host.view.body.text==expected[0].text,"reading dialogue begins with exact source text")
			await click_at(point)
			check(events.slice(event_count).filter(func(event): return event.id=="lib_read_rule").size()==1,"repeated pointer is captured by dialogue and never rereads")
			for line in range(expected.size()):
				if host.current==null: break
				check(host.view.body.text==expected[host.current.line_index].text,"normal input preserves authored dialogue text")
				await key(KEY_SPACE)
			check(state.d.ui.libraryFinalsPuzzle.archivedRuleBriefingSeen,"only full source dialogue acknowledgement completes briefing")
		await reopen("library_app"); await reopen("library_rule")
		check_rule_text()
		check(buttons("阅读旧版离座规则").is_empty(),"already read rule has no duplicate read action after reopen")
		check(state.d.items==items and state.d.ui.libraryFinalsPhase=="evidence_gathering","repeated/reopened reading preserves source phase and items")
		check(state.get_library_story_session()==null,"completed briefing is not requeued by reopen")
		# Source-ineligible page entry must not fabricate a reading action.
		state.story_reset.emit(); state.d=before_shelf.duplicate(true); state.d.native.page="library_rule"; shell.mobile_world=false
		await refresh()
		check(buttons("阅读旧版离座规则").is_empty() and not state.d.ui.libraryFinalsPuzzle.archivedRuleRead,"missing shelf proof keeps the existing reading gate closed")
	await shell.shutdown(); shell.queue_free(); await frames()
	var path=OS.get_environment("LIBRARY_RULE_REPORT")
	if not path.is_empty():
		var file=FileAccess.open(path,FileAccess.WRITE); file.store_string(JSON.stringify({"checks":checks,"failures":failures,"graphical_acceptance":false,"geometry":geometry,"cases":outcomes},"\t")); file.close()
	print("LIBRARY_RULE_ACTION: ",checks," checks; ",failures," failures; geometry=",JSON.stringify(geometry))
	quit(1 if failures else 0)
