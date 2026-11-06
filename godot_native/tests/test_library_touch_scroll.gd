extends "res://tests/test_cc98_auth_touch_scroll.gd"
## Actual Main/World processing and the existing raw-touch harness. Scrolling
## must not turn a proof card into an upload or a catalogue card into a choice.
var actions: Array[String]=[]

func check(ok: bool,message: String) -> void:
	checks+=1
	if not ok: failures+=1; push_error("LIBRARY TOUCH SCROLL: "+message)

func facts() -> String:
	return JSON.stringify({"items":state.d.items,"actOne":state.d.actOne,"ui":state.d.ui})

func reset_scroll(id: String) -> void:
	node(id).scroll_vertical=0; await frames()

func check_scroll(id: String,start: Vector2,end: Vector2,canceled: bool=false) -> void:
	var before:=facts(); var count:=actions.size()
	var phone_rect:=rect(shell.phone); var header_rect:=rect(node("PhoneNav_back"))
	var selected: String=shell.phone_builder.native_library.selected_seat
	var scroll_before: int=node(id).scroll_vertical
	if canceled:
		await touch(start,true)
		for i in range(1,11):
			var event:=InputEventScreenDrag.new(); event.index=0
			event.position=start.lerp(end,i/10.0); event.relative=(end-start)/10.0
			Input.parse_input_event(event); Input.flush_buffered_events(); await frames(2)
		await touch(end,false,true); await create_timer(.35).timeout; await frames()
	else: await swipe(start,end)
	check(node(id).scroll_vertical>scroll_before,"raw touch scrolls "+id+" at "+str(root.size))
	check(facts()==before and actions.size()==count,"swiping emits no action and preserves items/story: "+id)
	check(shell.phone_builder.native_library.selected_seat==selected,"swiping never selects a seat")
	check(rect(shell.phone).is_equal_approx(phone_rect) and rect(node("PhoneNav_back")).is_equal_approx(header_rect),"scrolling preserves phone/header geometry")
	check(shell.phone_scroll.scroll_vertical==0,"outer phone remains fixed")
	check(node("PhoneNav_back").mouse_filter==Control.MOUSE_FILTER_STOP,"fixed header retains its original input boundary")
	check(shell.is_processing() and shell.world.is_processing(),"Main and World retain normal processing")

func swipe_body(id: String) -> void:
	var area:=rect(node(id))
	await check_scroll(id,area.position+area.size*Vector2(.88,.77),area.position+area.size*Vector2(.88,.27))

func swipe_card(scroll_id: String,card_id: String,distance: float,canceled: bool=false) -> void:
	await reset_scroll(scroll_id)
	var target: Control=node(card_id)
	check(target!=null and rect(node(scroll_id)).encloses(rect(target)),"entire card is visible before touch: "+card_id)
	if target==null: return
	var start:=rect(target).get_center()
	await check_scroll(scroll_id,start,start-Vector2(0,distance),canceled)

func library_entry() -> void:
	await tap(node("HomeApp_zjuding"))
	# The ordinary entry clock runs in Main; do not disable it or skip its phase.
	await create_timer(1.7).timeout; await frames()
	await tap(node("ZjudingApp_library"))
	check(state.d.native.page=="library_app","ordinary home/ZJUding tile enters the library")

func reservation_path() -> void:
	fixture(); state.d.actOne.phase="reservation_required"; state.d.actOne.cc98Login.authenticated=true
	shell.mobile_world=false; shell.phone_builder.native_library.reset(); shell._refresh(); await frames()
	await library_entry()
	await swipe_body("LibraryScroll_home"); await reset_scroll("LibraryScroll_home")
	await tap(node("LibraryApp_reserve"))
	await swipe_body("LibraryScroll_spaces"); await reset_scroll("LibraryScroll_spaces")
	await tap(node("LibraryRoom_1"))
	await swipe_body("LibraryScroll_seat"); await reset_scroll("LibraryScroll_seat")
	await tap(node("LibrarySeatView_list"))
	await swipe_body("LibrarySeatListScroll"); await reset_scroll("LibrarySeatListScroll")
	# A press that becomes a list swipe must not select a seat locally either.
	var seat: Control=node("LibrarySeat_001"); var start:=rect(seat).get_center()
	await check_scroll("LibrarySeatListScroll",start,start-Vector2(0,65))
	await reset_scroll("LibrarySeatListScroll"); await tap(node("LibrarySeat_001"))
	check(shell.phone_builder.native_library.selected_seat=="001" and not state.d.ui.librarySeatReserved,"stationary list touch selects without reserving")
	await tap(node("LibraryReserveNow"))
	check(node("LibraryReservationConfirm").mouse_filter==Control.MOUSE_FILTER_STOP and node("LibrarySheetShade").mouse_filter==Control.MOUSE_FILTER_STOP,"fixed confirmation sheet keeps its input boundary")
	var before:=facts(); var count:=actions.count("c2_reserve")
	await tap(node("LibraryReservationCancel"))
	check(node("LibrarySheetShade")==null and facts()==before and actions.count("c2_reserve")==count,"cancel closes sheet without booking")
	await tap(node("LibrarySeatBack")); await tap(node("PhoneNav_back")); await tap(node("PhoneNav_back"))
	check(state.d.native.page=="zjuding","fixed Back returns through room list and library to ZJUding")
	await tap(node("ZjudingApp_library")); await swipe_body("LibraryScroll_home")

func evidence_path() -> void:
	# Source-generated retained checkpoint contains the controller-earned three
	# originals and rank 01, before any recovery submission. Saves stay isolated.
	check(state.begin_checkpoint("c2-recovery-form"),"retained recovery checkpoint loads")
	state.open_page("phone_home"); shell.mobile_world=false
	shell.phone_builder.native_library.reset(); shell._refresh(); await frames()
	check(state.d.items.bagNonPersonProof and state.d.ui.libraryFinalsPuzzle.recoverySubmittedEvidenceIds.is_empty(),"fixture starts before proof consumption")
	await library_entry(); await tap(node("LibraryApp_catalog"))
	var scroll_id:="LibraryScroll_catalog"
	var card_id:="LibraryCatalogResult_three-minute-leave-method"
	await swipe_body(scroll_id)
	await swipe_card(scroll_id,card_id,65)
	await swipe_card(scroll_id,card_id,65,true)
	await reset_scroll(scroll_id)
	var count:=actions.count("lib_catalog_select")
	await tap(node(card_id))
	check(actions.count("lib_catalog_select")==count+1,"stationary catalogue touch submits exactly one existing intent")
	var before:=facts()
	await tap(node("PhoneNav_back")); await tap(node("LibraryApp_catalog"))
	await reset_scroll(scroll_id); await swipe_card(scroll_id,card_id,65)
	check(facts()==before,"catalogue Back and re-entry preserve the existing evidence")
	await tap(node("PhoneNav_back")); await tap(node("LibraryApp_recovery"))
	scroll_id="LibraryScroll_recovery"; card_id="LibraryRecoverySlot_bag_non_person_proof"
	# Recovery has only a short scroll range. Start in its deliberate card gap.
	var body: Control=node(scroll_id).get_child(0)
	var start:=body.get_global_transform_with_canvas()*Vector2(352,226)
	await check_scroll(scroll_id,start,start-Vector2(0,110))
	await swipe_card(scroll_id,card_id,35)
	await swipe_card(scroll_id,card_id,35,true)
	check(state.d.items.bagNonPersonProof and state.d.ui.libraryFinalsPuzzle.recoverySubmittedEvidenceIds.is_empty(),"swipes and canceled drags never consume recovery proofs")
	await reset_scroll(scroll_id); count=actions.count("lib_recovery_upload")
	await tap(node(card_id))
	check(actions.count("lib_recovery_upload")==count+1 and not state.d.items.bagNonPersonProof,"stationary proof touch submits and consumes exactly once")
	check(state.d.ui.libraryFinalsPuzzle.recoverySubmittedEvidenceIds==["bag_non_person_proof"],"only the selected original was submitted")
	before=facts()
	await tap(node("PhoneNav_back")); await tap(node("LibraryApp_recovery")); await reset_scroll(scroll_id)
	check(facts()==before and node("LibraryRecoveryAction_bag_non_person_proof").text=="查看","Back and re-entry retain consumed-proof View")
	await tap(node(card_id))
	check(is_instance_valid(shell.phone_document) and actions.count("lib_recovery_upload")==count+1,"repeated stationary touch opens the submitted document without another upload")
	if is_instance_valid(shell.phone_document):
		var close: Control=shell.phone_document.find_child("SubmittedDocumentClose",true,false)
		check(close.mouse_filter==Control.MOUSE_FILTER_STOP,"document modal remains outside scroll bubbling")
		await tap(close)
	check(not is_instance_valid(shell.phone_document) and facts()==before,"document close returns without consuming more items")

func run() -> void:
	check(load("res://tests/native_test_isolation.gd").is_isolated_save(),"touch test uses isolated saves")
	if failures: quit(1); return
	var old_mouse:=Input.emulate_mouse_from_touch; var old_touch:=Input.emulate_touch_from_mouse
	Input.emulate_mouse_from_touch=true; Input.emulate_touch_from_mouse=true
	check(DisplayServer.is_touchscreen_available(),"raw touch uses the engine touchscreen scroll path")
	state=root.get_node("State"); fixture(); root.size=Vector2i(390,844)
	shell=load("res://scenes/main.tscn").instantiate(); root.add_child(shell); await frames()
	state.action_completed.connect(func(id,_before,_after,_result): actions.append(id))
	for viewport: Vector2i in [Vector2i(390,844),Vector2i(360,640),Vector2i(430,860),Vector2i(1280,720)]:
		root.size=viewport; shell.size=Vector2(viewport); await frames()
		await reservation_path(); await evidence_path()
	await shell.shutdown(); shell.queue_free(); await frames()
	Input.emulate_mouse_from_touch=old_mouse; Input.emulate_touch_from_mouse=old_touch
	print("LIBRARY_TOUCH_SCROLL: %d checks, %d failures" % [checks,failures])
	quit(0 if failures==0 else 1)
