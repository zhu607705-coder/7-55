extends SceneTree
## Portable Main/input coverage. Controller-earned fixture, isolated from saves.
const Chapter=preload("res://scripts/chapters/chapter1_2.gd")
const Page=preload("res://scripts/ui/cc98_investigation_page.gd")
const Library=preload("res://scripts/chapters/library022.gd")
var state: Node
var shell: Control
var earned: Dictionary
var checks=0
var failures=0
var events: Array=[]
var geometry: Array=[]

func _initialize() -> void: run.call_deferred()
func frames(count: int=4) -> void:
	for i in range(count): await process_frame
func check(ok: bool,message: String) -> void:
	checks+=1
	if not ok: failures+=1; push_error("CC98 INVESTIGATION: "+message)
func story_snapshot() -> String: return JSON.stringify({"items":state.d.items,"puzzle":state.d.ui.libraryFinalsPuzzle,"phase":state.d.ui.libraryFinalsPhase,"actOne":state.d.actOne})
func node(id: String) -> Node: return shell.page_body.find_child(id,true,false)
func rect(control: Control) -> Rect2:
	var transform=control.get_global_transform_with_canvas()
	return Rect2(transform.origin,control.size*transform.get_scale())
func mouse(point: Vector2,down: bool) -> void:
	var event=InputEventMouseButton.new(); event.position=point; event.global_position=point; event.button_index=MOUSE_BUTTON_LEFT; event.pressed=down; Input.parse_input_event(event); Input.flush_buffered_events(); await frames(1)
func click(target: Control) -> void:
	var point=rect(target).get_center()
	var motion=InputEventMouseMotion.new(); motion.position=point; motion.global_position=point; Input.parse_input_event(motion); Input.flush_buffered_events()
	await mouse(point,true); await mouse(point,false); await frames()
func key(code: Key) -> void:
	for down in [true,false]:
		var event=InputEventKey.new(); event.keycode=code; event.physical_keycode=code; event.pressed=down; Input.parse_input_event(event); Input.flush_buffered_events(); await frames(1)
	await frames()
func capture(name: String) -> void:
	var directory=OS.get_environment("CC98_CAPTURE_DIR")
	if directory.is_empty() or DisplayServer.get_name()=="headless": return
	DirAccess.make_dir_recursive_absolute(directory)
	await RenderingServer.frame_post_draw
	check(root.get_texture().get_image().save_png(directory.path_join(name+".png"))==OK,"fixture capture saved: "+name)
func acknowledge(controller: RefCounted,s: Dictionary) -> void:
	var session=controller.library.story_session(s)
	while session!=null:
		session.attach(s,self)
		for line in session.lines: session.advance(s,self)
		controller.dispatch(s,"lib_story_complete",session)
		session=controller.library.story_session(s)
func earn() -> Dictionary:
	var s=state.initial(); var controller=Chapter.new()
	s.native.chapter=2; s.native.scene="campus_bootstrap"; s.native.page="phone_home"
	s.actOne.phase="complete"; s.actOne.cc98Login.authenticated=true; s.actOne.inventoryRecovered=true
	s.networkMode="campus_wifi"; s.ui.libraryFinalsPhase="library_route_unlocked"; s.items.rightArrow=true
	for intent in [["lib_enter",null],["lib_record",null],["lib_backpack",null],["lib_note",null],["lib_investigate","occupancyNote"],["lib_catalog_terminal",null],["lib_catalog_search","三分钟离座法"],["lib_catalog_select","three-minute-leave-method"],["lib_shelf",null],["lib_read_rule",null],["lib_front_desk",null],["lib_photo",null]]:
		controller.dispatch(s,intent[0],intent[1]); acknowledge(controller,s)
	s.ui.brightness=20
	for intent in [["lib_dim_photo",null],["lib_view_photo","seat_022_clue"],["lib_item_report",null],["lib_scan",null],["lib_scan_result",{"scanMs":720,"identityChecks":[false,false,false],"stamped":true}]]:
		controller.dispatch(s,intent[0],intent[1])
	for i in range(10): controller.library.story_session(s,100)
	acknowledge(controller,s); controller.dispatch(s,"lib_receipt")
	s.networkMode="cellular"; controller.dispatch(s,"lib_audit",["7","47","3"]); acknowledge(controller,s)
	s.networkMode="campus_wifi"; s.ui.brightness=100; s.native.page="cc98"
	for item: String in Library.EVIDENCE.values(): check(s.items[item],"source controller earns "+item)
	check(s.ui.libraryFinalsPuzzle.cc98UploadedEvidenceIds.is_empty(),"fixture stops before any upload")
	return s
func refresh() -> void:
	shell._refresh(); await frames()
	shell.world.set_process(false)
func restore() -> void:
	state.story_reset.emit(); state.d=earned.duplicate(true); shell.phone_builder.cc98_post="seat-022-backpack"
	shell.mobile_world=false; shell.phone_chrome.inventory_open=false; await refresh()
	shell.phone_scroll.scroll_vertical=0; await frames()
func drag(item_id: String,slot_id: String,offset: Vector2=Vector2(220,75)) -> void:
	var chrome=shell.phone_chrome
	if not chrome.inventory_open: await click(chrome.inventory_handle)
	var item=chrome.inventory_slots.get_node("Item_"+item_id)
	chrome.inventory_scroll.ensure_control_visible(item); await frames()
	var slot: Control=node("Cc98EvidenceSlot_"+slot_id)
	for id in ["EvidenceLabel","EvidenceSource","Cc98EvidenceUpload_"+slot_id]:
		var target: Control=slot.get_node(id)
		check(not rect(target).intersects(rect(chrome.inventory_handle)) and not rect(target).intersects(rect(chrome.inventory_body)),"expanded drawer leaves material text and action readable")
	await capture("drawer-open-"+str(root.size.x))
	var start=rect(item).get_center(); var end=slot.get_global_transform_with_canvas()*offset
	var motion=InputEventMouseMotion.new(); motion.position=start; motion.global_position=start; Input.parse_input_event(motion); Input.flush_buffered_events()
	await mouse(start,true)
	for i in range(1,11):
		motion=InputEventMouseMotion.new(); motion.position=start.lerp(end,i/10.0); motion.global_position=motion.position; motion.relative=(end-start)/10.0; motion.button_mask=MOUSE_BUTTON_MASK_LEFT; Input.parse_input_event(motion); Input.flush_buffered_events(); await frames(1)
	check(root.gui_is_dragging(),"real inventory drag starts")
	await mouse(end,false); await frames()
	if chrome.inventory_open: await click(chrome.inventory_handle)
func run() -> void:
	state=root.get_node("State"); state.developer_mode=true; earned=earn(); state.d=earned.duplicate(true)
	shell=load("res://scenes/main.tscn").instantiate(); root.add_child(shell); await frames(); shell.set_process(false)
	state.action_completed.connect(func(id,_before,_after,result): events.append({"id":id,"result":result.duplicate(true)}))
	var source: Dictionary=JSON.parse_string(FileAccess.get_file_as_string(Page.SOURCE)).cc98
	for size in [Vector2i(390,844),Vector2i(430,860),Vector2i(1440,900)]:
		root.size=size; shell.size=Vector2(size); await frames(); await restore()
		var before=JSON.stringify(state.d)
		check(node("Cc98Investigation")!=null,"source investigation mounts at "+str(size))
		check(node("Cc98CopyCatalogTitle")!=null,"earned copy-title consumer retained")
		check(node("Cc98ReplyTitle_3").text=="3楼 · 前排先占楼" and node("Cc98ReplyTitle_6").text=="6楼 · 三分钟后再来","floor labels use source integers")
		check(node("Cc98ReplyBody_16").text=="xxx" and node("Cc98ReplyBody_24")==null,"source BD content stays gated")
		for control in shell.page_body.find_children("Cc98Reply*","Label",true,false):
			shell.phone_scroll.ensure_control_visible(control); await frames()
			check(control.get_line_count()==control.get_visible_line_count(),"all authored reply lines fit: "+control.name)
			var chrome=shell.phone_chrome
			var shadow=rect(chrome.inventory_handle); shadow.position+=Vector2(3,3)*chrome.inventory_handle.get_global_transform_with_canvas().get_scale()
			for rail in [rect(chrome.inventory_handle),rect(chrome.inventory_count),shadow]: check(not rect(control).intersects(rail),"collapsed rail, badge and shadow clear "+control.name)
		check(JSON.stringify(state.d)==before,"reading and scrolling changes no story state")
		shell.phone_scroll.scroll_vertical=0; await frames(); await capture("thread-"+str(size.x))
		await click(node("Cc98EvidenceJump"))
		var viewport=rect(shell.phone_scroll)
		for evidence: Dictionary in source.evidenceSlots:
			var slot: Control=node("Cc98EvidenceSlot_"+str(evidence.id))
			check(slot!=null and slot.get_node("EvidenceLabel").text==evidence.label and slot.get_node("EvidenceSource").text==evidence.source,"source label and provenance preserved for "+str(evidence.id))
			check(viewport.grow(1).encloses(rect(slot)),"manual jump shows entire slot: "+str(evidence.id))
			check(not node("Cc98EvidenceUpload_"+str(evidence.id)).disabled,"owned proof offers explicit upload")
			check(slot._can_drop_data(Vector2(2,2),{"kind":"inventory_item","item":"rightArrow"}) and slot._can_drop_data(slot.size-Vector2(2,2),{"kind":"inventory_item","item":"rightArrow"}),"full material row accepts drop attempts without item filtering")
		check(JSON.stringify(state.d)==before,"manual uploader jump never submits")
		check(shell.page_body.find_children("*","Button",true,false).filter(func(button): return button.text=="上传证据").is_empty(),"generic proof dropdown is replaced once")
		await capture("default-slots-"+str(size.x))
		await drag("archivedLeaveRule","bag_non_person_proof")
		check(JSON.stringify(state.d)==before,"wrong slot preserves every story/item fact")
		check(node("Cc98EvidenceFeedback").text=="这个槽位需要对应名称的纸质材料。","wrong slot keeps source-visible feedback")
		await capture("wrong-slot-"+str(size.x))
		await drag("bagNonPersonProof","bag_non_person_proof",Vector2(140,20))
		check(state.d.ui.libraryFinalsPuzzle.cc98UploadedEvidenceIds==["bag_non_person_proof"],"actual full-row drag uploads exactly the matching proof")
		check(state.d.items.bagNonPersonProof,"retained proof follows controller semantics")
		check(node("Cc98EvidenceUpload_bag_non_person_proof").disabled and node("Cc98EvidenceUpload_bag_non_person_proof").text=="已上传","uploaded state is readable and ordinary button disables")
		await capture("accepted-"+str(size.x))
		var uploaded_before=story_snapshot()
		await drag("bagNonPersonProof","bag_non_person_proof")
		check(story_snapshot()==uploaded_before,"repeat drag cannot duplicate or consume evidence")
		check(not events.is_empty() and events.back().id=="lib_upload" and str(events.back().result).contains("需要未上传的有效证据原件"),"repeat attempt reaches existing controller feedback")
		await capture("already-uploaded-"+str(size.x))
		await click(node("Cc98EvidenceUpload_archived_leave_rule"))
		check(state.d.ui.libraryFinalsPuzzle.cc98UploadedEvidenceIds.size()==2 and not state.d.items.archivedLeaveRule,"ordinary click consumes only source rule original")
		var receipt: Button=node("Cc98EvidenceUpload_seat_022_receipt"); receipt.grab_focus(); await key(KEY_SPACE)
		check(state.d.ui.libraryFinalsPuzzle.cc98UploadedEvidenceIds.size()==3,"keyboard Space uses same explicit upload intent")
		await click(node("Cc98EvidenceUpload_library_presence_proof"))
		check(state.d.ui.libraryFinalsPhase=="bd_briefing" and not state.d.ui.libraryFinalsPuzzle.preBdBriefingSeen,"four uploads retain source story gate")
		check(node("Cc98ReplyBody_24")==null,"fourth upload does not expose unopened BD controls")
		geometry.append({"viewport":str(size),"phone":str(rect(shell.phone)),"slot":str(rect(node("Cc98EvidenceSlot_archived_leave_rule")))})
	# Missing ownership, unread-rule and stale gates stay controller-authoritative.
	await restore(); state.d.items.libraryPresenceProof=false; await refresh(); check(node("Cc98EvidenceUpload_library_presence_proof").disabled,"unowned proof cannot be clicked")
	var stale=node("Cc98EvidenceSlot_archived_leave_rule"); state.d.ui.libraryFinalsPuzzle.archivedRuleRead=false
	stale._drop_data(Vector2(10,10),{"kind":"inventory_item","item":"archivedLeaveRule"}); await frames()
	check(state.d.ui.libraryFinalsPuzzle.cc98UploadedEvidenceIds.is_empty() and state.d.items.archivedLeaveRule,"unread rule remains rejected by existing controller")
	check(str(events.back().result).contains("先阅读旧版规则"),"unread rule keeps existing feedback")
	for phase: String in Page.BD_PHASES:
		await restore(); state.d.ui.libraryFinalsPuzzle.cc98UploadedEvidenceIds=Library.EVIDENCE.keys(); state.d.ui.libraryFinalsPuzzle.preBdBriefingSeen=true; state.d.ui.libraryFinalsPhase=phase; await refresh()
		for id: String in Library.EVIDENCE: check(node("Cc98EvidenceUpload_"+id).disabled and node("Cc98EvidenceUpload_"+id).text=="已上传","public source record persists in "+phase)
		check(node("Cc98ReplyBody_24")!=null,"earned BD reply remains visible in "+phase)
	await restore(); shell.phone_scroll.scroll_vertical=0; await frames(); await click(node("Cc98BackToFeed"))
	check(node("Cc98EvidenceUploader")==null,"Back removes local uploader without pending work")
	shell.phone_builder.cc98_post="seat-022-backpack"; await refresh(); check(node("Cc98EvidenceFeedback").text.is_empty(),"reopen starts with clean local feedback")
	await shell.shutdown(); shell.queue_free(); await frames()
	print("CC98 investigation: ",checks," checks, ",failures," failures; geometry=",JSON.stringify(geometry))
	quit(1 if failures else 0)
