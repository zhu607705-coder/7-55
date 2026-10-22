extends SceneTree
## Source-specific actual native inputs. Uses fixtures only, never State save writes.
const Pages=preload("res://scripts/ui/phone_pages.gd")
const Chapter=preload("res://scripts/chapters/chapter1_2.gd")
const ChapterThree=preload("res://scripts/chapters/chapter3.gd")
var pages=Pages.new()
var controller=Chapter.new()
var third_controller=ChapterThree.new()
var s: Dictionary
var surface: Control
var view: Control
var checks=0
var failures=0
var actions: Array=[]
var routes: Array=[]
func _process(delta: float) -> bool:
	# Standalone factory fixture supplies the same persistent host clock as Main.
	if not s.is_empty():
		var clock: RefCounted=controller.phone_entry_session(s)
		for event: Dictionary in clock.advance(delta*1000):
			if event.has("action"): controller.dispatch(s,str(event.action),event.get("value"))
	return false

func _initialize() -> void: call_deferred("run")
func expect(ok: bool, why: String) -> void:
	checks+=1
	if not ok: failures+=1; push_error(why)
func fresh() -> Dictionary:
	var state: Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://data/initial_state.json"))
	state.native={"chapter":2,"page":"cc98","scene":"dorm_hub","mode":"light","selected_item":""}
	state.actOne.phase="movement_required"; state.actOne.inventoryRecovered=true; state.items.campusCard=true; state.networkMode="campus_wifi"; state.flags.codeScattered=true; state.flags.checkinDone=true
	return state
func acknowledge_story_sessions() -> void:
	# Main owns the story overlay. This UI-only fixture acts as its registered host
	# and acknowledges each actual authored line before testing the next app action.
	var session=controller.library.story_session(s)
	while session!=null:
		if session.status=="issued": session.attach(s,self)
		for line in session.lines: session.advance(s,self)
		controller.dispatch(s,"lib_story_complete",session)
		session=controller.library.story_session(s)
func show(page: String) -> void:
	if is_instance_valid(view): view.free()
	s.native.page=page
	pages.entry_session=controller.phone_entry_session(s)
	if pages.entry_session.family=="zjuding" and pages.entry_session.entry_allowed:
		while pages.entry_session.phase=="loading": await process_frame
	view=pages.build(page,controller.view(page,s),s); surface.add_child(view); await process_frame; await process_frame
func node(id: String) -> Node: return view.find_child(id,true,false)
func click(target: Control) -> void:
	expect(target!=null,"Pointer target exists")
	if not target: return
	var point=target.get_global_rect().get_center()
	var move=InputEventMouseMotion.new(); move.position=point; move.global_position=point; root.push_input(move,true)
	var down=InputEventMouseButton.new(); down.position=point; down.global_position=point; down.button_index=MOUSE_BUTTON_LEFT; down.pressed=true; root.push_input(down,true); await process_frame
	var up=InputEventMouseButton.new(); up.position=point; up.global_position=point; up.button_index=MOUSE_BUTTON_LEFT; root.push_input(up,true); await process_frame
func scroll_to(id: String, position: int) -> void:
	var scroll: ScrollContainer=node(id); scroll.scroll_vertical=position; await process_frame; await process_frame
func set_input(id: String,text: String) -> void:
	var input: LineEdit=node(id); input.text=text; input.text_changed.emit(text)
func capture(name: String) -> void:
	if not "--capture" in OS.get_cmdline_user_args() or DisplayServer.get_name()=="headless": return
	await process_frame; await process_frame; await RenderingServer.frame_post_draw
	DirAccess.make_dir_recursive_absolute("res://.screenshots/phone-fidelity-completion")
	root.get_texture().get_image().save_png("res://.screenshots/phone-fidelity-completion/"+name+".png")
func run() -> void:
	root.size=Vector2i(424,854)
	surface=Control.new(); surface.size=Vector2(424,814); surface.position.y=40; root.add_child(surface)
	var theme=Theme.new(); theme.default_font=load("res://assets/rpg/fonts/fusion_pixel_12px_proportional_zh_hans.ttf"); theme.default_font_size=18; surface.theme=theme
	pages.action_requested.connect(func(id,value):
		actions.append([id,value])
		if str(id).begins_with("c3_"): third_controller.dispatch(s,id,value)
		else: controller.dispatch(s,id,value)
		acknowledge_story_sessions())
	pages.page_requested.connect(func(page): routes.append(page))
	s=fresh(); await show("cc98")
	expect(node("Cc98LoginSubmit").disabled,"Empty source login cannot submit")
	expect(node("Cc98LoginAttempts").text=="立即机会 3/3","Source immediate attempts shown")
	expect(node("Cc98HintFragment_0").text=="•••","Unrevealed hint fragments are hidden")
	await capture("cc98-login-top")
	await scroll_to("Cc98LoginScroll",245)
	await click(node("Cc98ReadCampusCard")); expect(s.actOne.cc98Login.studentIdDiscovered,"Actual source card read emits validated identity intent")
	await show("cc98"); expect(node("Cc98LoginStudentId").text=="3250100755","Read card fills exact source ID on re-render")
	await scroll_to("Cc98LoginScroll",350)
	for i in range(3):
		await click(node("Cc98RevealHint")); await show("cc98")
		expect(s.actOne.cc98Login.revealedHintCount==i+1,"Hint count remains controller-owned")
		expect(node("Cc98HintFragment_"+str(i)).text==["ZJU","1897","!"][i],"Each authored fragment unlocks sequentially")
	expect(node("Cc98RevealHint").disabled,"Three revealed hints disable source reveal button")
	set_input("Cc98LoginPassword","draft-kept")
	await show("control_center"); await show("cc98")
	expect(node("Cc98LoginPassword").text=="draft-kept","Control Center preserves underlying authentication draft")
	await capture("cc98-login-evidence")
	await scroll_to("Cc98LoginScroll",0); set_input("Cc98LoginPassword","wrong")
	await click(node("Cc98PasswordVisibility")); expect(not node("Cc98LoginPassword").secret,"Password visibility is functional")
	for i in range(3):
		set_input("Cc98LoginPassword","wrong"); await click(node("Cc98LoginSubmit")); await show("cc98")
		expect(s.actOne.cc98Login.failureCount==i+1,"Failed real input increments only controller attempts")
		expect(node("Cc98LoginPassword").text.is_empty(),"Rejected password clears but ID remains")
	expect(node("Cc98LoginSubmit").disabled and node("Cc98LoginAttempts").text.begins_with("锁定"),"Third failure displays active lockout and disables submit")
	expect(pages.cc98_login.remaining_ms(s.actOne.cc98Login)>28000,"Lockout preserves source 30-second duration")
	# Simulate elapsed wall clock in isolated fixture; timer updates UI without a new state action.
	s.actOne.cc98Login.lockUntilMs=int(Time.get_unix_time_from_system()*1000)+100
	set_input("Cc98LoginPassword","ZJU1897!"); await create_timer(.4).timeout
	expect(not node("Cc98LoginSubmit").disabled,"Source 250ms countdown unlocks after deadline")
	await click(node("Cc98LoginSubmit")); expect(s.actOne.cc98Login.authenticated,"Full native authentication succeeds through controller")
	# Check-in keeps source bottom keypad, local drafts and controller-only ending handoff.
	s=fresh(); s.native.chapter=1; s.actOne.phase="prologue"; s.flags.checkinDone=false; s.flags.cardZeroTaken=false
	await show("checkin")
	expect(node("CheckinSubmit").disabled and node("CheckinKey_1").position.y>470,"Source check-in keypad is bottom anchored and incomplete submit disabled")
	await click(node("CheckinKey_1")); await click(node("CheckinAbsenceZero")); await show("checkin")
	expect(s.flags.cardZeroTaken and node("CheckinSlot_0").text=="1","Collecting the source absence zero keeps current keypad draft")
	for key in ["2","3","4"]: await click(node("CheckinKey_"+key))
	expect(not node("CheckinSubmit").disabled and node("CheckinReadyFrame").visible,"Fourth entered digit activates source-ready frame")
	expect(node("CheckinEntryPulse")!=null and view.find_children("CheckinEntryPulse*","Panel",true,false).size()==1,"Rapid keys replace the one source entry pulse rather than stacking multiple digits")
	await capture("checkin-ready")
	await click(node("CheckinSubmit")); await show("checkin")
	expect(node("CheckinError").visible and node("CheckinSlot_0").text.is_empty() and not s.flags.checkinDone,"Controller rejection clears draft and shows source wrong-code state")
	await click(node("CheckinKey_0")); await show("control_center"); await show("checkin")
	expect(node("CheckinSlot_0").text=="0","Control Center preserves check-in draft")
	for key in ["7","9","8"]: await click(node("CheckinKey_"+key))
	s.networkMode="cellular"; await click(node("CheckinSubmit")); await show("checkin")
	expect(pages.checkin_page.code=="0798" and not s.flags.checkinDone,"Network rejection preserves entered code and cannot begin ending")
	s.networkMode="campus_wifi"; await click(node("CheckinSubmit"))
	expect(s.flags.checkinDone and s.actOne.phase=="prologue" and actions[-1]==["c1_checkin","0798"],"Valid keypad input delegates check-in while leaving the authored interception gate intact")
	# Native library home, source room crop, library alternatives, selection and confirmation.
	s=fresh(); s.actOne.phase="reservation_required"; s.actOne.manualControlTested=true; await show("library_app")
	expect(node("LibraryReaderPortrait")!=null,"Library reader hero uses original artwork")
	expect(node("LibraryApp_reserve")!=null and node("LibraryApp_catalog")==null,"Library access matches source phase gates")
	expect(node("LibraryLocked_borrow") is Label,"Locked library slots have no button semantics")
	expect(view.get_meta("handles_all_actions",false),"Native library hides generic action fallback")
	await capture("library-home")
	await click(node("LibraryApp_reserve")); await show("library_app")
	var photo: TextureRect=node("LibraryRoomPhoto_0")
	expect(photo.texture is AtlasTexture and photo.texture.region==Rect2(173,684,298,328),"Room artwork uses exact source crop, not miniature screenshot")
	await capture("library-spaces")
	await click(node("LibraryChooseBuilding")); await show("library_app"); await click(node("LibrarySheetOption_0")); await show("library_app")
	expect(pages.native_library.selected_library=="主馆" and node("LibraryRoom_3")!=null,"Native library chooser loads four source main-library rooms")
	await click(node("LibraryChooseBuilding")); await show("library_app"); await click(node("LibrarySheetOption_1")); await show("library_app")
	await click(node("LibraryRoom_1")); await show("library_app")
	expect(pages.native_library.selected_room=="一层书库" and node("LibrarySeat_022")!=null,"Room opens original seat map")
	await show("control_center"); await show("library_app")
	expect(pages.native_library.local_page=="seat" and node("LibrarySeat_022")!=null,"Control Center preserves nested Library page")
	await click(node("LibrarySeatView_list")); await show("library_app")
	expect(node("LibrarySeatListScroll")!=null and node("LibrarySeat_160")!=null,"Source seat list exposes all 160 seats in a separate scroll")
	expect(node("LibrarySeat_005").position.x==node("LibrarySeat_001").position.x,"Source seat list uses four columns")
	await click(node("LibrarySeatView_map")); await show("library_app")
	await click(node("LibrarySeatSection_4")); await show("library_app")
	expect(node("LibrarySeat_160")!=null and node("LibrarySeat_022")==null,"Source map uses 32-seat sections, no omitted high-numbered seats")
	await click(node("LibrarySeatSection_0")); await show("library_app")
	expect(node("LibrarySeat_029").position.x<node("LibrarySeat_021").position.x,"Source table ordering 29/25, 21/17, 13/9, 5/1 preserved")
	await click(node("LibrarySeat_022")); await show("library_app"); expect(not s.ui.librarySeatReserved,"Selecting seat does not bypass reservation confirmation")
	await capture("library-seat-map")
	await click(node("LibraryReserveNow")); await show("library_app"); expect(node("LibraryReservationConfirm")!=null,"Native reservation confirmation sheet opens")
	await click(node("LibraryReservationCancel")); await show("library_app"); expect(not s.ui.librarySeatReserved,"Cancel leaves controller reservation untouched")
	await click(node("LibraryReserveNow")); await show("library_app"); await click(node("LibraryReservationConfirm")); await show("library_app")
	expect(s.ui.librarySeatReserved and s.actOne.phase=="movement_ready","Real confirmation applies exact source reservation controller")
	await click(node("LibrarySeat_021")); expect(s.ui.librarySelectedSeat=="022","Confirmed seat cannot be silently changed")
	# Functional searches and deliberate selection keep the terminal evidence gate.
	s.actOne.phase="complete"; s.ui.libraryFinalsPhase="evidence_gathering"; s.ui.libraryFinalsPuzzle.investigationOpened=true; s.ui.libraryFinalsPuzzle.catalogUnlocked=false
	await show("library_catalog"); set_input("LibraryCatalogQuery","三分钟离座法"); await click(node("LibraryCatalogSearch")); await show("library_catalog")
	expect(s.native.lib_catalog_result_ids.size()==5,"Source catalog shows all five original similar books")
	expect(not s.ui.libraryFinalsPuzzle.catalogSearchCompleted,"Functional search cannot bypass terminal clue gate")
	await capture("library-catalog")
	await click(node("LibraryCatalogResult_three-minute-leave-method")); expect(not s.items.callNumber755,"Selecting before terminal cannot grant evidence")
	s.ui.libraryFinalsPuzzle.catalogUnlocked=true; await show("library_catalog"); await click(node("LibraryCatalogSearch")); await show("library_catalog")
	await click(node("LibraryCatalogResult_three-minute-leave-method")); await show("library_catalog")
	expect(s.items.callNumber755 and s.ui.libraryFinalsPuzzle.callNumberCollected,"Source catalog result passes selection to validated evidence controller")
	# Recovery materials use original item IDs; wrong drop cannot submit another slot.
	s.ui.libraryFinalsPhase="top_ten_reached"; s.ui.libraryFinalsPuzzle.bdCount=3
	s.items.bagNonPersonProof=true; s.items.seat022Receipt=true; s.items.libraryPresenceProof=true
	await show("library_recovery"); await click(node("LibraryRecoveryOpen")); await show("library_recovery")
	expect(node("LibraryGeneratePass").disabled,"PASS button requires three controller-validated records")
	var slot=node("LibraryRecoverySlot_bag_non_person_proof")
	slot._drop_data(Vector2(10,10),{"kind":"inventory_item","item":"seat022Receipt"})
	expect(s.ui.libraryFinalsPuzzle.recoverySubmittedEvidenceIds.is_empty(),"Wrong inventory drop does not submit recovery evidence")
	slot._drop_data(Vector2(10,10),{"kind":"inventory_item","item":"bagNonPersonProof"}); await show("library_recovery")
	expect(not s.items.bagNonPersonProof and s.ui.libraryFinalsPuzzle.recoverySubmittedEvidenceIds.has("bag_non_person_proof"),"Matching recovery drop preserves source consume contract")
	await click(node("LibraryRecoverySlot_seat_022_receipt")); await show("library_recovery")
	await click(node("LibraryRecoverySlot_library_presence_proof")); await show("library_recovery")
	expect(not node("LibraryGeneratePass").disabled,"PASS enabled only after three validated slots")
	await capture("library-recovery")
	await click(node("LibraryGeneratePass")); await show("library_recovery")
	expect(s.items.seatReleasePass and not s.ui.libraryFinalsPuzzle.backpackEvicted,"PASS generation never remotely removes backpack")
	await capture("library-pass")
	routes.clear(); await click(node("LibraryRecoverySlot_bag_non_person_proof"))
	expect(routes.is_empty() and node("LibrarySubmittedDocument")!=null,"Consumed recovery evidence opens source inline document modal")
	await capture("library-submitted-document")
	await click(node("SubmittedDocumentClose")); await process_frame
	expect(node("LibrarySubmittedDocument")==null and s.items.seatReleasePass,"Document close returns to unchanged recovery application")
	var document_requests: Array=[]
	var document_consumer=func(config): document_requests.append(config)
	pages.document_requested.connect(document_consumer)
	await click(node("LibraryRecoverySlot_bag_non_person_proof"))
	expect(document_requests.size()==1 and document_requests[0].item_id=="bagNonPersonProof" and node("LibrarySubmittedDocument")==null,"Connected Main consumer receives exact document request instead of local overlay")
	pages.document_requested.disconnect(document_consumer)
	var full_modal=load("res://scripts/ui/phone_document_modal.gd").new(); full_modal.setup(pages,"bagNonPersonProof",true)
	expect(is_equal_approx(full_modal.size.y*pages.PHONE_SCALE,854),"Integrated document overlay covers full 854px interior including status strip")
	full_modal.free()
	# Card is CSS artwork in source; exact native field layout supports actual item drops.
	s=fresh(); s.items.rightArrow=true; s.actOne.rightArrowAssembled=true; s.actOne.exerciseStarted=true
	await show("campus_card"); var balance=node("CampusCardBalance")
	expect(balance!=null and balance is Button,"Campus-card source balance has a visible native target")
	expect(node("CampusCardGradient").size.is_equal_approx(Vector2(392,256)/pages.PHONE_SCALE) and node("CampusCardPlate").clip_contents,"Gradient texture ignores intrinsic size before layout and clips inside card border")
	await capture("campus-card-source")
	balance._drop_data(Vector2(10,10),{"kind":"inventory_item","item":"rightArrow"})
	expect(s.actOne.balanceShifted and s.items.rightArrow and s.wallet.campusCardCents==600,"Actual balance drop retains reusable arrow and delegates decimal shift")
	# Source later notifications, evolving unresolved timestamps and direct app targets.
	s=fresh(); s.flags.codeScattered=true; s.actOne.phase="complete"; s.canteenHunt.active=true; s.native.chapter=3
	s.theaterHunt.cc98TicketCommissionPhase="posted"; await show("phone_home")
	expect(node("HomeNotification_theater_ticket")!=null and node("HomeNotification_overdue_book")!=null,"Chapter 3 includes source ticket commission and overdue-book notices")
	await capture("home-chapter3-notifications")
	s.networkMode="offline"; routes.clear(); await click(node("HomeNotification_theater_ticket")); expect(routes.is_empty(),"Ticket notice respects source network entry gate")
	s.networkMode="cellular"; s.theaterHunt.cc98TicketCommissionPhase="first_wave_failed"; await show("phone_home"); routes.clear(); await click(node("HomeNotification_theater_ticket")); expect(routes==["c3_ticket_post"],"Second-wave ticket notice uses existing cellular-enabled controller surface")
	s.qizhenLake.phase="complete"; s.chapterThreeInterlude.recoveryOpened=true; await show("phone_home")
	var notices=pages._home_notifications()
	expect(notices.size()==2 and notices[0].body=="待核验时间窗：待恢复 — 待恢复" and notices[0].time=="待恢复","Interlude hides both unresolved timestamp endpoints")
	expect(node("HomeInterludeTopNotice")!=null and node("HomeNotification_theater_ticket")==null,"Interlude notifications take source priority over chapter 3")
	routes.clear(); await click(node("HomeNotification_recovery")); expect(routes==["c35_recovery"],"Interlude notice opens existing recovery surface")
	s.chapterThreeInterlude.evidenceIds=["journal_start","broadcast_end"]; await show("phone_home"); notices=pages._home_notifications()
	expect(notices[0].body=="待核验时间窗：22:37:05 — 22:45:00" and notices[0].time=="22:45","Timestamp endpoints appear only after their source evidence facts")
	await capture("home-interlude-notifications")
	s.chapterThreeInterlude.completed=true; s.chapterThreeInterlude.replayUnlocked=true; s.chapter4.prologueSeen=true; s.chapter4.phase="hall_clock_inspection"; s.native.chapter=4; await show("phone_home")
	expect(node("HomeNotification_chapter_four_photo")!=null and pages._home_notifications().size()==1,"Current Chapter 4 shows source photo reminder without restoring retired phone gates")
	await capture("home-chapter4-notifications")
	# Chapter 3 reuses the real catalog; receiving the program reveals a query, not a clue.
	s=fresh(); s.flags.codeScattered=true; s.native.chapter=3; s.actOne.phase="complete"; s.qizhenLake.active=true; s.qizhenLake.phase="location_search"; s.items.wetProgram=true
	await show("c3_lake_catalog")
	expect(node("LibraryCatalogQuery")!=null and node("LibraryReflectionKeyword")==null,"Lake catalog uses native search without revealing a keyword before query")
	node("LibraryCatalogQuery")._drop_data(Vector2(5,5),{"kind":"inventory_item","item":"rightArrow"}); expect(not pages.native_library.qizhen_catalog_visible,"Wrong paper does not reveal abnormal-loan search")
	node("LibraryCatalogQuery")._drop_data(Vector2(5,5),{"kind":"inventory_item","item":"wetProgram"}); await show("c3_lake_catalog")
	expect(node("LibraryCatalogQuery").text=="签到记录夹页" and node("LibraryReflectionKeyword")!=null and not s.qizhenLake.reflectionClueFound,"Wet program fills exact source query without collecting clue")
	await capture("library-lake-catalog")
	await scroll_to("LibraryScroll_catalog",90); await click(node("LibraryReflectionKeyword")); await show("c3_lake_catalog")
	expect(s.qizhenLake.reflectionClueFound and s.items.reflectionKeyword and s.items.wetProgram,"Recording source result delegates clue ownership and retains program until all three carriers")
	set_input("LibraryCatalogQuery","三分钟"); await click(node("LibraryCatalogSearch")); await show("c3_lake_catalog")
	expect(node("LibraryCatalogResult_three-minute-leave-method")!=null,"Normal library search remains usable after Chapter 2")
	# Home source weather hit area is invisible, full widget, and correct at mobile scale.
	s=fresh(); await show("phone_home"); var weather=node("HomeWeatherOpen")
	expect(node("SourceHomeArtwork")!=null,"Home draws the original CSS campus silhouette at source dimensions")
	await capture("home-source-geometry")
	expect(weather.text.is_empty() and weather.size.is_equal_approx(Vector2(212,182)/pages.PHONE_SCALE),"Home weather uses source invisible card hit area with no overlapping label")
	surface.scale=Vector2.ONE*(338.0/424.0); root.size=Vector2i(390,844); surface.position=Vector2(26,40)
	await capture("home-source-mobile390")
	routes.clear(); await click(weather); expect(routes==["weather"],"Scaled mobile full-widget weather input works")
	view.queue_free(); await process_frame
	print("PHONE_LIBRARY_LOGIN_TESTS: %d checks; %d failures" % [checks,failures]); quit(1 if failures else 0)
