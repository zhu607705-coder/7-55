extends SceneTree
## Reconstructed recovery-2 real Main pointer/key, source gates, drafts and receipt.
const Chapter=preload("res://scripts/chapters/chapter1_2.gd")
var state: Node
var shell: Control
var checks=0
var failures=0
var rows: Array=[]
var geometry: Array=[]
var case_name=""
var earned: Dictionary
func _initialize() -> void: run.call_deferred()
func frames(count: int=4) -> void:
	for i in range(count): await process_frame
func check(ok: bool,label: String) -> void:
	checks+=1; rows.append({"case":case_name,"check":label,"passed":ok})
	if not ok: failures+=1; push_error(case_name+": "+label)
func node(id: String) -> Control: return shell.page_body.find_child(id,true,false)
func rect(control: Control) -> Rect2:
	var x=control.get_global_transform_with_canvas(); return Rect2(x.origin,control.size*x.get_scale())
func click(control: Control) -> void:
	if control==null: check(false,"click target exists"); return
	var point=rect(control).get_center()
	var motion=InputEventMouseMotion.new(); motion.position=point; root.push_input(motion,true)
	for down in [true,false]:
		var event=InputEventMouseButton.new(); event.position=point; event.button_index=MOUSE_BUTTON_LEFT; event.pressed=down; root.push_input(event,true); await frames(1)
	await frames()
func key(code: Key,unicode_value: int=0,ctrl: bool=false) -> void:
	for down in [true,false]:
		var event=InputEventKey.new(); event.keycode=code; event.physical_keycode=code; event.unicode=unicode_value; event.ctrl_pressed=ctrl; event.pressed=down; root.push_input(event,true); await frames(1)
	await frames()
func type_into(id: String,text: String) -> void:
	var field=node("TiyiField_"+id)
	await click(field); await key(KEY_A,0,true); await key(KEY_BACKSPACE)
	for ch in text: await key(ch.unicode_at(0),ch.unicode_at(0))
	check(node("TiyiField_"+id)!=null and node("TiyiField_"+id).text==text,"actual keyboard retains typed "+id+"="+text)
func acknowledge(controller: RefCounted,s: Dictionary) -> void:
	var session=controller.library.story_session(s)
	while session!=null:
		session.attach(s,self)
		for line in session.lines: session.advance(s,self)
		controller.dispatch(s,"lib_story_complete",session); session=controller.library.story_session(s)
func source_fixture() -> Dictionary:
	var s=state.initial(); var controller=Chapter.new()
	s.native.chapter=2; s.native.page="library_app"; s.native.scene="campus_bootstrap"
	s.actOne.phase="complete"; s.actOne.cc98Login.authenticated=true; s.networkMode="campus_wifi"; s.ui.libraryFinalsPhase="library_route_unlocked"
	controller.dispatch(s,"lib_enter"); acknowledge(controller,s)
	controller.dispatch(s,"lib_record"); controller.dispatch(s,"lib_backpack"); acknowledge(controller,s)
	controller.dispatch(s,"lib_note"); controller.dispatch(s,"lib_investigate","occupancyNote"); acknowledge(controller,s)
	controller.dispatch(s,"lib_catalog_terminal"); controller.dispatch(s,"lib_catalog_search","三分钟离座法")
	controller.dispatch(s,"lib_catalog_select","three-minute-leave-method"); acknowledge(controller,s)
	controller.dispatch(s,"lib_shelf"); controller.dispatch(s,"lib_read_rule"); acknowledge(controller,s)
	s.networkMode="cellular"; s.native.page="phone_home"
	check(s.ui.libraryFinalsPuzzle.entranceRecordRead and s.ui.libraryFinalsPuzzle.investigationOpened and s.ui.libraryFinalsPuzzle.archivedRuleRead,"ordinary source actions earn three materials")
	return s
func open_ready() -> void:
	state.open_page("tiyi"); shell._refresh()
	var deadline=Time.get_ticks_msec()+10000
	while (state.get_phone_entry_session().phase!="ready" or node("TiyiPresenceForm")==null) and Time.get_ticks_msec()<deadline:
		await process_frame
	await frames()
	check(state.get_phone_entry_session().phase=="ready" and node("TiyiPresenceForm")!=null,"entry reaches ready and mounts form before monotonic deadline")
func new_shell() -> void:
	if is_instance_valid(shell): await shell.shutdown(); shell.queue_free(); await frames()
	shell=load("res://scenes/main.tscn").instantiate(); root.add_child(shell); await frames()
	shell.mobile_world=false; shell.world.set_process(false)
func check_presence_rail() -> void:
	var form=node("TiyiPresenceForm");var chrome=shell.phone_chrome
	check(chrome.inventory.is_visible_in_tree() and not chrome.inventory_open,"presence text is tested against the visible collapsed inventory rail")
	var handle=rect(chrome.inventory_handle);var shadow=handle
	shadow.position+=Vector2(3,3)*chrome.inventory_handle.get_global_transform_with_canvas().get_scale()
	var badge=rect(chrome.inventory_count)
	var previous_scroll=shell.phone_scroll.scroll_vertical
	for offset in [0,120,240,360,480,600]:
		shell.phone_scroll.scroll_vertical=offset;await frames()
		var intersections:Array=[];var visible_labels=0
		for label in form.find_children("*","Label",true,false):
			var visible=rect(label).intersection(rect(shell.phone_scroll))
			if not visible.has_area():continue
			visible_labels+=1
			for rail in [handle,shadow,badge]:
				if visible.intersects(rail):intersections.append(label.text)
		for button in form.find_children("*","Button",true,false):
			var font:Font=button.get_theme_font("font")
			var text_size=font.get_string_size(button.text,HORIZONTAL_ALIGNMENT_LEFT,-1,button.get_theme_font_size("font_size"))
			var transform=button.get_global_transform_with_canvas()
			var caption=Rect2(transform*((button.size-text_size)*.5),text_size*transform.get_scale())
			var visible=caption.intersection(rect(shell.phone_scroll))
			if not visible.has_area():continue
			visible_labels+=1
			for rail in [handle,shadow,badge]:
				if visible.intersects(rail):intersections.append("button caption: "+button.text)
		for input in form.find_children("*","LineEdit",true,false):
			var visible=rect(input).intersection(rect(shell.phone_scroll))
			if not visible.has_area():continue
			visible_labels+=1
			for rail in [handle,shadow,badge]:
				if visible.intersects(rail):intersections.append("field: "+str(input.name))
		check(visible_labels>0 and intersections.is_empty(),"all visible presence text clears collapsed handle/shadow/badge at scroll "+str(offset)+": "+str(intersections))
		geometry.append({"viewport":case_name,"kind":"receipt" if node("TiyiPresenceResult")!=null else "form","requestedScroll":offset,"actualScroll":shell.phone_scroll.scroll_vertical,"visibleLabels":visible_labels,"overlaps":intersections,"handle":str(handle),"shadow":str(shadow),"badge":str(badge)})
	shell.phone_scroll.scroll_vertical=previous_scroll;await frames()
	var content_panels=form.find_children("*","Panel",true,false).filter(func(panel):return panel.position.y>=54)
	for panel in content_panels:
		check(panel.position.x>=38 and panel.get_rect().end.x<=364.5,"content card preserves the right boundary and clears the rail edge")
	for label in form.find_children("*","Label",true,false):
		if label.position.y<54:continue
		check(label.position.x>=50 and label.get_rect().end.x<=364.5 and label.get_rect().end.y<=form.size.y,"presence text stays inside inset app content: "+label.text)
		check(label.get_line_count()==label.get_visible_line_count(),"all wrapped presence text lines stay visible: "+label.text)
	var route=node("TiyiRecordedRoute")
	var headings=form.find_children("*","Label",true,false).filter(func(label):return label.text=="检测到室内异常锻炼路线")
	check(headings.size()==1 and not headings[0].get_rect().intersects(route.get_rect()),"route heading and wrapped route remain separate")
	for i in range(3):
		var body=node("TiyiEvidence_"+str(i))
		var header=form.find_children("*","Label",true,false).filter(func(label):return label.position.y==706+i*117+8)
		check(header.size()==1 and not header[0].get_rect().intersects(body.get_rect()),"source card heading and body remain separate: "+str(i))
func report() -> void:
	var path=OS.get_environment("UI_QA_REPORT")
	if path.is_empty(): path="user://tiyi-presence-main.json"
	var file=FileAccess.open(path,FileAccess.WRITE)
	if file==null: failures+=1; push_error("Cannot write report: "+path)
	else: file.store_string(JSON.stringify({"provenance":"reconstructed recovery-2","checks":checks,"failures":failures,"graphical_acceptance":false,"geometry":geometry,"cases":rows},"\t")); file.close()
	print("TIYI_MAIN: ",checks," checks; ",failures," failures"); quit(1 if failures else 0)
func run() -> void:
	state=root.get_node("State"); state.developer_mode=false; earned=source_fixture()
	for viewport in [Vector2i(390,844),Vector2i(430,860),Vector2i(1440,900)]:
		case_name=str(viewport); root.size=viewport; state.story_reset.emit(); state.d=earned.duplicate(true)
		await new_shell(); await open_ready()
		if node("TiyiPresenceForm")==null: continue
		await check_presence_rail()
		check(node("TiyiEvidence_1").text.contains("公示编号 47\n") and not node("TiyiEvidence_1").text.contains("47.0"),"source notice number is displayed as integer")
		check(node("TiyiField_arrival").text=="5" and node("TiyiField_notice").text=="45" and node("TiyiField_proofs").text=="1","authored wrong defaults displayed")
		check(shell.page_body.find_children("*","Button",true,false).filter(func(b): return b.text=="提交补录单").is_empty(),"generic appended form action is removed")
		for id in ["TiyiField_arrival","TiyiField_notice","TiyiField_proofs","TiyiPresenceSubmit"]:
			var target=node(id); var r=rect(target)
			check(rect(shell.phone_scroll).grow(.5).encloses(r),"first-screen visible control: "+id)
			check(r.size.y>=28,"physical hit height >=28: "+id)
			geometry.append({"viewport":str(viewport),"id":id,"rect":str(r)})
		var before_items=state.d.items.duplicate(true)
		await type_into("arrival",""); await click(node("TiyiPresenceSubmit"))
		check(state.d.ui.libraryFinalsPuzzle.auditAttemptCount==1 and not state.d.items.libraryPresenceProof,"empty actual input rejected by original validator")
		check(node("TiyiPresenceFeedback").text.contains("不一致"),"first rejection appears inline")
		await type_into("arrival","5"); await click(node("TiyiPresenceSubmit"))
		check(state.d.ui.libraryFinalsPuzzle.auditAttemptCount==2 and node("TiyiPresenceFeedback").text.contains("三项"),"second rejection keeps authored hint tier")
		await click(node("TiyiPresenceSubmit"))
		check(state.d.ui.libraryFinalsPuzzle.auditAttemptCount==3 and node("TiyiPresenceFeedback").text.contains("仍有字段"),"third rejection keeps source hint")
		check(state.d.items==before_items,"three failed attempts create no inventory rewards")
		await type_into("notice","46")
		check(root.gui_get_focus_owner()==node("TiyiField_notice") and node("TiyiField_notice").caret_column==2,"draft rebuild preserves keyboard focus and caret")
		check(state.d.ui.libraryFinalsPuzzle.auditPublicNoticeFloor==46,"valid typed draft uses controller setter")
		await click(node("TiyiPlus_notice")); check(state.d.ui.libraryFinalsPuzzle.auditPublicNoticeFloor==47,"plus button persists draft")
		check(root.gui_get_focus_owner()==node("TiyiPlus_notice"),"step rebuild preserves button focus")
		await key(KEY_ENTER); check(state.d.ui.libraryFinalsPuzzle.auditPublicNoticeFloor==48,"focused step can be used repeatedly by keyboard")
		state.open_page("phone_home"); await frames(); await open_ready()
		check(node("TiyiField_notice").text=="48","back/reopen preserves draft")
		check(state.save_game(),"ordinary save writes earned draft")
		check(state.load_game(),"ordinary reload accepts earned draft")
		await new_shell(); await open_ready()
		check(node("TiyiField_notice").text=="48","ordinary save/reload preserves draft")
		await type_into("arrival","0")
		check(node("TiyiField_arrival").text=="0" and state.d.ui.libraryFinalsPuzzle.auditArrivalMinutes==0,"actual explicit zero stays while editing")
		state.open_page("phone_home"); await frames(); await open_ready()
		check(node("TiyiField_arrival").text=="5" and state.d.ui.libraryFinalsPuzzle.auditArrivalMinutes==0,"actual Home/reopen uses source zero/default fallback without changing stored zero")
		check(state.save_game(),"actual zero ordinary save succeeds")
		var zero_save: Dictionary=JSON.parse_string(FileAccess.get_file_as_string("user://save.json"))
		check(zero_save.state.ui.libraryFinalsPuzzle.auditArrivalMinutes==0,"actual zero save contains zero without bookkeeping")
		check(state.load_game(),"actual zero ordinary reload succeeds")
		await new_shell(); await open_ready()
		check(state.d.ui.libraryFinalsPuzzle.auditArrivalMinutes==0 and node("TiyiField_arrival").text=="5","fresh view retains inherited source zero/default fallback")
		await type_into("arrival","7"); await type_into("notice","47"); await type_into("proofs","3")
		await click(node("TiyiField_arrival")); await key(KEY_TAB)
		check(root.gui_get_focus_owner()==node("TiyiField_notice"),"Tab advances to second field")
		await key(KEY_TAB); check(root.gui_get_focus_owner()==node("TiyiField_proofs"),"Tab advances to third field")
		await key(KEY_ENTER); check(root.gui_get_focus_owner()==node("TiyiPresenceSubmit"),"field Enter advances to submit")
		await key(KEY_ENTER)
		check(state.d.ui.libraryFinalsPuzzle.presenceProofCollected and state.d.items.libraryPresenceProof and state.d.ui.libraryFinalsPuzzle.auditAttemptCount==4,"correct real input grants exactly existing proof")
		var host=shell.library_story_host; host.set_process(false); host.tick(0)
		var guard=0
		while host.current!=null and guard<30: await key(KEY_SPACE); guard+=1
		check(state.get_library_story_session()==null,"earned proof dialogue completes through actual input")
		check(node("TiyiPresenceResult")!=null and node("TiyiPresenceSubmit")==null,"earned receipt replaces form")
		check(state.save_game(),"earned receipt ordinary save succeeds")
		check(state.load_game(),"earned receipt ordinary reload succeeds")
		await new_shell(); await open_ready()
		for field in [["arrival","到座耗时：7 分钟"],["notice","公示编号：47 号"],["proofs","证明数量：3 项"]]:
			check(node("TiyiReceipt_"+field[0])!=null and node("TiyiReceipt_"+field[0]).text==field[1],"normal-save receipt uses integer label: "+field[0])
		check(not node("TiyiEvidence_1").text.contains("47.0"),"normal-save source notice retains integer formatting")
		await check_presence_rail()
		var complete=state.d.ui.libraryFinalsPuzzle.duplicate(true); var items=state.d.items.duplicate(true)
		state.act("lib_audit",{"arrival":"7","notice":"47","proofs":"3"}); await frames()
		check(state.d.ui.libraryFinalsPuzzle==complete and state.d.items==items,"repeat submission cannot grant or count twice")
		state.open_page("phone_home"); await frames(); await open_ready()
		check(node("TiyiPresenceResult")!=null and node("TiyiField_arrival")==null,"already-complete reopen preserves receipt without editable fields")
		for network in ["campus_wifi","off"]:
			state.d.networkMode=network; state.open_page("phone_home"); await frames(); state.open_page("tiyi"); await frames()
			check(node("TiyiPresenceForm")==null,"network entry gate remains authoritative: "+network)
	await shell.shutdown(); shell.queue_free(); await frames(); report()
