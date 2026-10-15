extends "res://tests/test_cc98_investigation_layout.gd"
## Real Main mouse/keyboard/drag input; controller-earned fixtures, isolated saves.
const Recovery=preload("res://scripts/ui/native_library_pages.gd")
var bd_earned: Dictionary
var recovery_earned: Dictionary
var feedback_messages: Array=[]

func check(ok: bool,message: String) -> void:
	checks+=1
	if not ok: failures+=1; push_error("LIBRARY RECOVERY FEEDBACK: "+message)

func earn_followup() -> void:
	var controller=Chapter.new(); var s=earn()
	for id: String in Library.EVIDENCE:
		controller.dispatch(s,"lib_upload",id); acknowledge(controller,s)
	check(s.ui.libraryFinalsPhase=="top_ten_rising","source upload/briefing earns BD controls")
	bd_earned=s.duplicate(true)
	for floor_number in [25,27,29,31]: controller.dispatch(s,"lib_bd_select",Page.BD_POSTS[floor_number])
	controller.dispatch(s,"lib_bd_submit"); acknowledge(controller,s)
	controller.dispatch(s,"lib_recovery_open")
	s.native.page="library_recovery"
	check(s.ui.libraryFinalsPhase=="recovery_application","source BD validation earns recovery application")
	recovery_earned=s.duplicate(true)

func restore_followup(snapshot: Dictionary) -> void:
	state.story_reset.emit(); state.d=snapshot.duplicate(true)
	shell.phone_builder.cc98_post="seat-022-backpack" if state.d.native.page=="cc98" else ""
	shell.mobile_world=false; shell.phone_chrome.inventory_open=false; await refresh()
	state.advance_phone_entry(1600); await refresh()
	shell.phone_scroll.scroll_vertical=0
	if node("LibraryScroll_recovery"): node("LibraryScroll_recovery").scroll_vertical=0
	await frames()

func reveal(id: String) -> void:
	var target: Control=node(id)
	check(target!=null,"input target exists: "+id)
	if not target: return
	var ancestor=target.get_parent()
	while ancestor:
		if ancestor is ScrollContainer:
			ancestor.ensure_control_visible(target); await frames()
		ancestor=ancestor.get_parent()

func tap(id: String) -> void:
	await reveal(id); await click(node(id))

func state_choices() -> Array: return state.d.ui.libraryFinalsPuzzle.bdSelectedPostIds

func check_bd_order(floors: Array) -> void:
	var ids: Array=[]
	for floor_number in floors: ids.append(Page.BD_POSTS[floor_number])
	check(state_choices()==ids,"controller owns exact selected order "+str(floors))
	var summary=Page.new().bd_order(ids)
	check(node("Cc98BdReview").text==summary,"top review reflects saved choices")
	for floor_number in Page.BD_POSTS:
		var position=floors.find(floor_number)
		var button: Button=node("Cc98BdSelect_%d" % floor_number)
		check(button.disabled==(position>=0),"selected reply cannot duplicate: "+str(floor_number))
		check(button.text==("已选第%d项" % (position+1) if position>=0 else "bd"),"local selected ordinal reflects saved state")
		check(node("Cc98BdOrder_%d" % floor_number).text==summary,"local review reflects exact selected order")
		check(node("Cc98BdUndo_%d" % floor_number).disabled==floors.is_empty(),"local Undo tracks current choices")

func check_bd_geometry() -> void:
	for floor_number in Page.BD_POSTS:
		var panel: Panel=node("Cc98ReplyPanel_%d" % floor_number)
		for prefix in ["Cc98ReplyTitle_","Cc98ReplyBody_","Cc98BdOrder_","Cc98BdSelect_","Cc98BdUndo_","Cc98BdReview_"]:
			var target: Control=node(prefix+str(floor_number))
			check(rect(panel).grow(1).encloses(rect(target)),"reply contains "+target.name)
			if target is Label: check(target.get_line_count()==target.get_visible_line_count(),"all BD lines fit "+target.name)
		await reveal("Cc98BdOrder_%d" % floor_number)
		check(not rect(node("Cc98BdOrder_%d" % floor_number)).intersects(rect(node("Cc98BdSelect_%d" % floor_number))),"order line does not cover local BD controls")
		for rail in [rect(shell.phone_chrome.inventory_handle),rect(shell.phone_chrome.inventory_count)]: check(not rect(node("Cc98BdOrder_%d" % floor_number)).intersects(rail),"collapsed drawer clears local order")

func drag_recovery(item_id: String,id: String,offset: Vector2) -> void:
	await reveal("LibraryRecoverySlot_"+id)
	var chrome=shell.phone_chrome
	if not chrome.inventory_open: await click(chrome.inventory_handle)
	var item=chrome.inventory_slots.get_node("Item_"+item_id)
	chrome.inventory_scroll.ensure_control_visible(item); await frames()
	var slot: Control=node("LibraryRecoverySlot_"+id)
	for prefix in ["LibraryRecoveryName_","LibraryRecoverySource_","LibraryRecoveryFeedback_","LibraryRecoveryAction_"]:
		var target: Control=node(prefix+id)
		check(not rect(target).intersects(rect(chrome.inventory_handle)) and not rect(target).intersects(rect(chrome.inventory_body)),"expanded drawer clears "+prefix+id)
	var start=rect(item).get_center(); var end=slot.get_global_transform_with_canvas()*offset
	await drag_path(start,end)
	if chrome.inventory_open: await click(chrome.inventory_handle)

func drag_path(start: Vector2,end: Vector2) -> void:
	var motion=InputEventMouseMotion.new(); motion.position=start; motion.global_position=start; Input.parse_input_event(motion); Input.flush_buffered_events()
	await mouse(start,true)
	for i in range(1,11):
		motion=InputEventMouseMotion.new(); motion.position=start.lerp(end,i/10.0); motion.global_position=motion.position; motion.relative=(end-start)/10.0; motion.button_mask=MOUSE_BUTTON_MASK_LEFT; Input.parse_input_event(motion); Input.flush_buffered_events(); await frames(1)
	check(root.gui_is_dragging(),"real inventory drag starts")
	await mouse(end,false); await frames()

func blank_release(item_id: String) -> void:
	var chrome=shell.phone_chrome
	if not chrome.inventory_open: await click(chrome.inventory_handle)
	var item=chrome.inventory_slots.get_node("Item_"+item_id)
	chrome.inventory_scroll.ensure_control_visible(item); await frames()
	var end=rect(shell.phone).position+Vector2(320,150)*shell.phone.get_global_transform_with_canvas().get_scale()
	await drag_path(rect(item).get_center(),end)
	if chrome.inventory_open: await click(chrome.inventory_handle)

func save_reload() -> void:
	check(ProjectSettings.globalize_path("user://").begins_with("/tmp/"),"persistence test isolated from formal save")
	if not ProjectSettings.globalize_path("user://").begins_with("/tmp/"): return
	state.developer_mode=false
	check(state.save_game(),"controller-earned state passes real save validation")
	state.d=state.initial()
	check(state.load_game(),"real saved state reloads")
	state.developer_mode=true; state.story_reset.emit(); shell.mobile_world=false; state.advance_phone_entry(1600); await refresh()

func check_recovery_geometry() -> void:
	var chrome=shell.phone_chrome
	var scroll: ScrollContainer=node("LibraryScroll_recovery")
	for id in ["LibraryRecoveryConditionsTitle","LibraryRecoveryConditions","LibraryRecoverySlot_bag_non_person_proof","LibraryRecoverySlot_seat_022_receipt","LibraryRecoverySlot_library_presence_proof","LibraryGeneratePass"]:
		await reveal(id)
		check(rect(scroll).grow(1).encloses(rect(node(id))),"scroll viewport contains "+id)
		for rail in [rect(chrome.inventory_handle),rect(chrome.inventory_count)]: check(not rect(node(id)).intersects(rail),"collapsed drawer clears "+id)
	for target in shell.page_body.find_children("LibraryRecovery*","Label",true,false):
		check(target.get_line_count()==target.get_visible_line_count(),"all label lines fit "+target.name)
		if target.get_parent().name.begins_with("LibraryRecoverySlot_"):
			check(Rect2(Vector2.ZERO,target.get_parent().size).encloses(Rect2(target.position,target.size)),"card contains "+target.name)
	for evidence in Recovery.RECOVERY:
		var slot=node("LibraryRecoverySlot_"+str(evidence[0]))
		check(slot._can_drop_data(Vector2(2,2),{"kind":"inventory_item","item":"rightArrow"}) and slot._can_drop_data(slot.size-Vector2(2,2),{"kind":"inventory_item","item":"rightArrow"}),"full card accepts attempts without item oracle")
	geometry.append({"viewport":str(root.size),"conditions":str(rect(node("LibraryRecoveryConditions"))),"lastCard":str(rect(node("LibraryRecoverySlot_library_presence_proof"))),"scroll":str(rect(scroll))})

func run() -> void:
	state=root.get_node("State"); state.developer_mode=true; earn_followup(); state.d=bd_earned.duplicate(true)
	shell=load("res://scenes/main.tscn").instantiate(); root.add_child(shell); await frames(); shell.set_process(false)
	state.action_completed.connect(func(id,_before,_after,result): events.append({"id":id,"result":result.duplicate(true)}))
	state.feedback.connect(func(message): feedback_messages.append(message))
	for size in [Vector2i(390,844),Vector2i(430,860),Vector2i(1440,900)]:
		root.size=size; shell.size=Vector2(size); await frames(); await restore_followup(bd_earned)
		check_bd_order([]); await check_bd_geometry()
		await tap("Cc98BdRepliesJump")
		check(rect(shell.phone_scroll).grow(1).encloses(rect(node("Cc98ReplyPanel_24"))),"manual reply jump lands at first numeric reply")
		await tap("Cc98BdSelect_24"); check_bd_order([24])
		var before=story_snapshot(); var scroll_before=shell.phone_scroll.scroll_vertical
		await click(node("Cc98BdSelect_24"))
		check(story_snapshot()==before and shell.phone_scroll.scroll_vertical==scroll_before,"duplicate click neither mutates nor jumps")
		await tap("Cc98BdSelect_29"); check_bd_order([24,29])
		await reveal("Cc98BdUndo_29"); node("Cc98BdUndo_29").grab_focus(); await key(KEY_SPACE); check_bd_order([24])
		await tap("Cc98BdReview_31")
		check(rect(shell.phone_scroll).grow(1).encloses(rect(node("Cc98BdReview"))),"local review manually returns to chosen-order summary")
		await tap("Cc98BdSubmit")
		check(state.d.ui.libraryFinalsPhase=="top_ten_rising" and state_choices().size()==1,"incomplete order keeps proof and phase")
		await tap("Cc98BdUndo"); check_bd_order([])
		for floor_number in [24,26,28,30]: await tap("Cc98BdSelect_%d" % floor_number)
		await tap("Cc98BdReview_30"); await tap("Cc98BdSubmit"); check_bd_order([])
		check(state.d.ui.libraryFinalsPhase=="top_ten_rising" and not state.d.items.seatReleasePass and state.d.ui.libraryFinalsPuzzle.bdPasswordAttemptCount==1,"wrong complete order grants no rank/PASS and resets displayed choice state")
		await tap("Cc98BdSelect_27"); await tap("Cc98BdSelect_25"); await save_reload(); check_bd_order([27,25])
		await restore_followup(bd_earned); check_bd_order([])
		for floor_number in [25,27,29,31]: await tap("Cc98BdSelect_%d" % floor_number)
		await tap("Cc98BdReview_31"); await tap("Cc98BdSubmit")
		check(state.d.ui.libraryFinalsPhase=="top_ten_reached" and not state.d.items.seatReleasePass,"correct input still reaches controller story gate, without PASS")
		await restore_followup(recovery_earned); await check_recovery_geometry()
		before=story_snapshot(); var feedback_count=feedback_messages.size()
		await blank_release("seat022Receipt")
		check(story_snapshot()==before,"blank release preserves all item/story facts")
		check(feedback_messages.size()>feedback_count and str(feedback_messages.back()).contains("没有落在可使用的物品上"),"blank release retains generic no-target explanation")
		await drag_recovery("seat022Receipt","library_presence_proof",Vector2(270,96))
		check(story_snapshot()==before,"wrong proof on visible Submit cannot consume or advance")
		check(node("LibraryRecoveryFeedback_library_presence_proof").text=="材料不符，请核对本栏名称","wrong proof shows persistent targeted mismatch")
		await refresh()
		check(node("LibraryRecoveryFeedback_library_presence_proof").text=="材料不符，请核对本栏名称","mismatch survives ordinary rebuild")
		await drag_recovery("seat022Receipt","bag_non_person_proof",Vector2(150,20))
		check(story_snapshot()==before,"wrong proof on card body is equally safe")
		check(node("LibraryRecoveryFeedback_bag_non_person_proof").text=="材料不符，请核对本栏名称","full-card mismatch has explicit explanation")
		await drag_recovery("bagNonPersonProof","bag_non_person_proof",Vector2(150,20))
		check(state.d.ui.libraryFinalsPuzzle.recoverySubmittedEvidenceIds==["bag_non_person_proof"] and not state.d.items.bagNonPersonProof,"real full-card drop consumes only matching original")
		check(node("LibraryRecoveryAction_bag_non_person_proof").text=="查看" and not node("LibraryRecoveryFeedback_bag_non_person_proof").text.contains("不符"),"accepted card changes to View and clears stale mismatch")
		await save_reload()
		check(state.d.ui.libraryFinalsPuzzle.recoverySubmittedEvidenceIds==["bag_non_person_proof"] and not state.d.items.bagNonPersonProof,"partial submission and consumed original survive reload")
		check(not node("LibraryRecoveryFeedback_library_presence_proof").text.contains("不符"),"transient mismatch clears on new loaded state")
		before=story_snapshot(); await tap("LibraryRecoverySlot_bag_non_person_proof")
		check(is_instance_valid(shell.phone_document) and shell.phone_chrome.input_blocked,"consumed proof opens canonical full-phone document")
		await click(shell.phone_document.find_child("SubmittedDocumentClose",true,false)); await frames()
		check(not is_instance_valid(shell.phone_document) and not shell.phone_chrome.input_blocked and story_snapshot()==before,"closing View preserves state and restores input")
		await tap("LibraryRecoverySlot_bag_non_person_proof"); await key(KEY_ESCAPE)
		check(not is_instance_valid(shell.phone_document) and story_snapshot()==before,"repeated View/Escape never grants or consumes")
		await drag_recovery("seat022Receipt","seat_022_receipt",Vector2(270,96))
		await drag_recovery("libraryPresenceProof","library_presence_proof",Vector2(150,20))
		check(state.d.ui.libraryFinalsPuzzle.recoverySubmittedEvidenceIds.size()==3 and not state.d.items.seat022Receipt and not state.d.items.libraryPresenceProof,"all matched inputs use existing three-original contract")
		check(not node("LibraryGeneratePass").disabled and not state.d.items.seatReleasePass,"three proofs enable explicit PASS generation without granting early")
		await tap("LibraryGeneratePass")
		check(state.d.items.seatReleasePass and state.d.ui.libraryFinalsPhase=="pass_ready" and not state.d.ui.libraryFinalsPuzzle.backpackEvicted,"explicit generation retains authored PASS briefing/world-use gate")
		await restore_followup(recovery_earned); state.d.items.libraryPresenceProof=false; await refresh()
		before=story_snapshot(); await tap("LibraryRecoverySlot_library_presence_proof")
		check(story_snapshot()==before and node("LibraryRecoveryFeedback_library_presence_proof").text=="尚未取得本栏证明原件","missing-original click is controller rejected with persistent explanation")
		var stale=node("LibraryRecoverySlot_library_presence_proof")
		stale._drop_data(Vector2(150,20),{"kind":"inventory_item","item":"libraryPresenceProof"}); await frames()
		check(story_snapshot()==before,"forged matching payload without ownership grants nothing")
		await restore_followup(recovery_earned)
		check(not node("LibraryRecoveryFeedback_library_presence_proof").text.contains("尚未"),"new session resets transient missing-material feedback")
		state.d.ui.libraryFinalsPhase="top_ten_reached"; await refresh(); before=story_snapshot()
		await tap("LibraryRecoverySlot_library_presence_proof")
		check(story_snapshot()==before and node("LibraryRecoveryFeedback_library_presence_proof").text=="请先开启本次恢复申请","premature card activation preserves application gate with an explanation")
		await tap("LibraryRecoveryOpen")
		check(state.d.ui.libraryFinalsPhase=="recovery_application" and not node("LibraryRecoveryFeedback_library_presence_proof").text.contains("开启"),"opening application clears an obsolete gate explanation")
	await shell.shutdown(); shell.queue_free(); await frames()
	var report={"checks":checks,"failures":failures,"geometry":geometry,"coverage":"Headless Main input at390/430/desktop; physical mobile and GUI appearance unverified"}
	var path=OS.get_environment("UI_QA_REPORT")
	if not path.is_empty():
		var file=FileAccess.open(path,FileAccess.WRITE); file.store_string(JSON.stringify(report,"\t")); file.close()
	print("LIBRARY_RECOVERY_FEEDBACK: ",checks," checks / ",failures," failures; geometry=",JSON.stringify(geometry))
	quit(1 if failures else 0)
