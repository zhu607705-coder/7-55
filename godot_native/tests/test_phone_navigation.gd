extends SceneTree
## Actual pointer/keyboard regressions for source navigation, shared 40px offset,
## Zjuding local views, weather gates, and per-line system dialogue.
const Pages=preload("res://scripts/ui/phone_pages.gd")
const Chapter=preload("res://scripts/chapters/chapter1_2.gd")
var p=Pages.new()
var c=Chapter.new()
var s: Dictionary
var surface: Control
var body: Control
var page_events: Array=[]
var actions: Array=[]
var cues: Array=[]
var failed=0
var checks=0
func _process(delta: float) -> bool:
	# Standalone factory fixture supplies the same persistent host clock as Main.
	if not s.is_empty():
		var clock: RefCounted=c.phone_entry_session(s)
		for event: Dictionary in clock.advance(delta*1000):
			if event.has("action"): c.dispatch(s,str(event.action),event.get("value"))
	return false

func _initialize() -> void: call_deferred("_run")
func expect(ok: bool, message: String) -> void:
	checks+=1
	if not ok: failed+=1; push_error(message)
func fresh() -> Dictionary:
	var state: Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://data/initial_state.json"))
	state.native={"chapter":2,"page":"phone_home","scene":"","mode":"light","selected_item":""}
	state.actOne.phase="movement_required"
	state.actOne.inventoryRecovered=true; state.items.campusCard=true
	return state
func show(page: String) -> void:
	if is_instance_valid(body): body.free()
	s.native.page=page
	p.entry_session=c.phone_entry_session(s)
	if p.entry_session.family=="zjuding" and p.entry_session.entry_allowed:
		while p.entry_session.phase=="loading": await process_frame
	body=p.build(page,c.view(page,s),s); body.position.y=0 if page in ["alarm","desktop","control_center"] else 40
	surface.add_child(body); await process_frame
func node(name: String) -> Node: return body.find_child(name,true,false)
func click(button: Control) -> void:
	expect(button!=null,"Pointer target exists")
	if button==null: return
	var point=button.get_global_rect().get_center()
	var motion=InputEventMouseMotion.new(); motion.position=point; motion.global_position=point; root.push_input(motion,true)
	var down=InputEventMouseButton.new(); down.button_index=MOUSE_BUTTON_LEFT; down.pressed=true; down.position=point; down.global_position=point; root.push_input(down,true)
	await process_frame
	var up=InputEventMouseButton.new(); up.button_index=MOUSE_BUTTON_LEFT; up.position=point; up.global_position=point; root.push_input(up,true)
	await process_frame
func nav(kind: String) -> Control: return node("PhoneNav_"+kind)
func _run() -> void:
	root.size=Vector2i(500,1000)
	surface=Control.new(); surface.size=Vector2(424,854); root.add_child(surface)
	var theme=Theme.new(); theme.default_font=load("res://assets/rpg/fonts/fusion_pixel_12px_proportional_zh_hans.ttf"); theme.default_font_size=18; surface.theme=theme
	p.page_requested.connect(func(page): page_events.append(page))
	p.action_requested.connect(func(id,value): actions.append([id,value]); c.dispatch(s,id,value))
	p.presentation_requested.connect(func(cue): cues.append(cue))
	s=fresh()
	for page in ["phone_home","wechat","checkin","campus_card","bonsai","cc98","zjuding","tiyi","weather","directory","library_app","library_record","library_rule","library_recovery","library_catalog","library_archive","library_022_dialogue","photos","settings"]:
		await show(page)
		expect(body.custom_minimum_size.y>=813.99,"Source app fills 814px under status: "+page)
		expect(body.clip_contents,"Native app wrapper clips source interior: "+page)
	for target in [["wechat","exit","phone_home"],["checkin","back","zjuding"],["campus_card","back","zjuding"],["bonsai","exit","phone_home"],["weather","exit","phone_home"],["directory","back","zjuding"],["library_app","back","zjuding"],["library_record","back","library_app"],["library_rule","back","library_app"],["library_recovery","back","library_app"],["library_catalog","back","library_app"],["library_archive","back","library_app"],["library_022_dialogue","back","library_app"],["photos","exit","phone_home"]]:
		page_events.clear(); await show(target[0]); await click(nav(target[1]))
		expect(page_events==[target[2]],"Pointer navigation "+target[0]+" → "+target[2])
	# Check-in returns into the actual authored learn page, and its hotspot is live.
	s.actOne.phase="prologue"; await show("checkin"); await click(nav("back")); await show("zjuding")
	expect(p.zjuding_page=="learn" and node("ZjudingCheckin")!=null,"Check-in back returns to source learn page")
	page_events.clear(); await click(node("ZjudingCheckin")); expect(page_events==["checkin"],"Learn source-aligned hotspot opens check-in")
	await click(nav("back")); await show("zjuding")
	expect(p.zjuding_page=="hub","Learn back returns to hub")
	# Locked actions retain a static icon; all source utilities unlock with identity.
	s.actOne.inventoryRecovered=false; s.items.campusCard=false; await show("zjuding")
	expect(node("ZjudingLocked_smart_classroom")!=null and node("ZjudingApp_smart_classroom")==null,"Locked source service is not an active placeholder")
	s=fresh(); await show("zjuding")
	await click(node("ZjudingTab_contacts")); await show("zjuding")
	expect(p.zjuding_panel=="contacts" and node("ZjudingOpenDirectory")!=null,"Contacts bottom tab opens authored panel")
	page_events.clear(); await click(node("ZjudingOpenDirectory")); expect(page_events==["directory"],"Contacts routes to department directory")
	await click(nav("back")); await show("zjuding")
	await click(node("ZjudingSearchBar")); await show("zjuding")
	var search=node("ZjudingSearch"); search.text="词汇"; search.text_changed.emit("词汇")
	expect(node("ZjudingSearch_language_cards").visible and not node("ZjudingSearch_library").visible,"Search matches source keywords")
	await click(node("ZjudingSearch_language_cards")); await show("zjuding")
	await click(node("ZjudingWord_reflection")); await show("zjuding")
	expect(p.zjuding_detail=="reflection","Language card reveals source translation")
	for panel in ["smart_classroom","network_account","logistics","lost_found","visitor_preview","language_cards","feedback_draft","all_apps","contacts","messages","profile"]:
		p.zjuding_panel=panel; p.zjuding_detail=""; await show("zjuding")
		expect(node("ZjudingScroll")!=null and body.size.y>=814,"Dedicated source panel: "+panel)
	p.zjuding_panel="visitor_preview"; await show("zjuding")
	var name_field=node("ZjudingVisitor_name"); name_field.text="访客甲"; name_field.text_changed.emit(name_field.text)
	var date_field=node("ZjudingVisitor_date"); date_field.text="08月24日"; date_field.text_changed.emit(date_field.text)
	await click(node("ZjudingDraftSave")); await show("zjuding")
	expect(p.zjuding_feedback_status.begins_with("未提交·本机预览"),"Visitor draft produces only local source preview")
	await click(nav("back")); await show("zjuding")
	await click(node("ZjudingProfileMenu")); await show("zjuding")
	page_events.clear(); await click(node("ZjudingMenu_2")); expect(page_events==["phone_home"],"Authored profile menu exits Zjuding")
	# Control-center close restores the originating app, not a hardcoded home.
	await show("settings"); await show("control_center"); actions.clear(); await click(nav("close")); expect(actions[0][0]=="native_control_center_close","Control center closes modal without navigating underlying page")
	await show("settings"); p.settings_page="about"; await show("settings"); actions.clear(); await click(node("NativeSaveTools")); expect(actions[0][0]=="native_save_tools","About exposes labeled native save extension")
	# Control Center keeps source 854 px modal geometry and real vertical pointer/keyboard controls.
	await show("control_center")
	expect(is_equal_approx(body.size.y,854) and body.get_meta("source_overlay",false),"Control center covers full phone interior at y=0")
	var brightness=node("ControlBrightness")
	await click(brightness)
	expect(s.ui.brightness==50,"Vertical slider center maps to 50 percent")
	brightness.grab_focus()
	var up_key=InputEventKey.new(); up_key.keycode=KEY_UP; up_key.pressed=true; root.push_input(up_key,true); await process_frame
	expect(s.ui.brightness==60,"Vertical slider ArrowUp uses source ten-point step")
	await click(node("LowPowerToggle")); await show("control_center")
	await click(node("ControlBrightness")); expect(s.ui.brightness==45,"Vertical slider caps low-power value at 45 percent of full range")
	actions.clear(); await click(node("ControlSaveNow")); expect(actions[0][0]=="native_save_now","Source Save button routes native persistence intent")
	await click(node("ControlResetOpen")); await show("control_center"); expect(node("ControlResetConfirm")!=null,"Reset requires source inline confirmation")
	await click(node("ControlResetCancel")); await show("control_center"); expect(node("ControlResetConfirm")==null,"Cancel leaves story intact")
	await click(node("ControlResetOpen")); await show("control_center"); actions.clear(); await click(node("ControlResetConfirm")); expect(actions[0][0]=="native_reset_progress","Only confirmed reset sends reset intent")
	await click(nav("close")); await show("control_center"); expect(node("ControlResetConfirm")==null,"Closing and reopening control center clears stale reset confirmation")
	s=fresh(); s.actOne.phase="prologue"; s.ui.musicPlaying=true; await show("control_center")
	await click(node("ControlHeadphones")); expect(not s.flags.headphoneFallen,"Headphones do not collect before source 550ms fall")
	await create_timer(.58).timeout; expect(s.flags.headphoneFallen and s.items.headphone,"Headphone fall completes before collection intent")
	# Source Tiyi artwork ratio/hitbox, allowed entry delay, and both loading/main exits.
	s=fresh(); s.actOne.phase="prologue"; s.networkMode="cellular"; await show("tiyi")
	expect(node("TiyiEntry")!=null and node("TiyiCount47")==null,"Tiyi source loader owns first1400ms")
	await create_timer(1.6).timeout; await show("tiyi")
	expect(node("TiyiSourcePlate")!=null and node("TiyiCount47")!=null,"Tiyi uses authored source plate and percentage-aligned target")
	await click(node("TiyiCount47")); expect(s.flags.tiyiCountTaken,"Actual rendered 47 hotspot collects source digit")
	page_events.clear(); await click(nav("exit")); expect(page_events==["phone_home"],"Tiyi main source exit returns home")
	await show("phone_home"); await show("tiyi"); page_events.clear(); await click(node("TiyiLoadingExit")); expect(page_events==["phone_home"],"Tiyi loading source exit remains clickable")
	# WeChat source list restores the missing helper row and real row feedback.
	s=fresh(); await show("wechat"); await click(node("WechatRow_0")); expect(node("SourceToast")!=null,"File transfer helper shows authored row feedback")
	await click(node("WechatRow_2")); expect(node("SourceToast")!=null,"Roommate row is functional")
	expect(node("WechatRow_3")!=null,"All four source WeChat rows exist")
	# Broad query can reveal more than six results; only empty-query suggestions are capped.
	p.zjuding_page="hub"; p.zjuding_panel=""; await show("zjuding"); await click(node("ZjudingSearchBar")); await show("zjuding")
	var full_search=node("ZjudingSearch"); full_search.text="_"; full_search.text_changed.emit("_")
	expect(node("ZjudingSearch_all_apps").visible and node("ZjudingSearch_feedback_draft").visible and not node("ZjudingSearch_learn").visible,"Nonempty search exposes more than six source registry matches")
	p.zjuding_overlay=""
	s=fresh()
	# Actual reader drop + 650ms source delay + real form submission.
	await show("directory"); node("DirectoryCardReader")._drop_data(Vector2(10,10),{"kind":"inventory_item","item":"campusCard"})
	expect(node("DirectoryName").text.is_empty(),"Reader does not bypass authored 650ms scan")
	await create_timer(.7).timeout
	expect(node("DirectoryStudentId").text=="3250100755","Reader fills exact source student ID after scan")
	await click(node("DirectoryCall")); expect(s.actOne.characterNamed,"Native directory form forwards identity to existing controller")
	# Weather data, availability, collection, and global later weather projection.
	await show("weather"); expect(node("WeatherTemperature").text=="18°C","Weather uses source light-rain temperature")
	expect(node("WeatherWaterCard").disabled,"Water card unavailable before exercise")
	s.actOne.exerciseStarted=true; await show("weather"); await click(node("WeatherWaterCard")); expect(s.actOne.weatherWaterTaken,"Weather water card executes existing clue intent")
	s.qizhenLake.rainSafetyCleared=true; await show("weather"); expect(node("WeatherTemperature").text=="19°C","Weather reflects source overcast projection")
	# Source line pacing: no state mutation from rendering/partial dialogue.
	for mode in ["inventory","inventory_ready","departure","reservation"]:
		s=fresh(); s.actOne.phase="system_required" if mode in ["inventory","inventory_ready"] else "system_return_required" if mode=="departure" else "reservation_briefing_required"
		if mode=="inventory": s.actOne.inventoryRecovered=false; s.items.campusCard=false
		s.actOne.manualControlTested=true; cues.clear(); actions.clear(); page_events.clear(); await show("system_chat")
		var count=5 if mode=="inventory" else 6 if mode=="departure" else 4
		var original=s.actOne.phase
		for i in range(count-1): await click(node("SystemDialogueAdvance")); expect(s.actOne.phase==original,"Partial "+mode+" dialogue does not advance state")
		await click(node("SystemDialogueAdvance"))
		expect(s.actOne.phase==("inventory_required" if mode=="inventory" else "reservation_required" if mode=="reservation" else "movement_required"),"Final source line commits "+mode)
		expect(cues[-1]=="act2_system_dialogue_closed","Source dialogue closes current voice lifecycle")
		expect(cues.size()==1 if mode=="reservation" else cues.has("act2_system_found_intro") if mode.begins_with("inventory") else cues.has("act2_system_departure"),"Only authored source voice cues emit: "+mode)
	# At scaled mobile width actual navigation still resolves to the visible target.
	s=fresh(); surface.scale=Vector2.ONE*(338.0/424.0); await show("weather"); page_events.clear(); await click(nav("exit")); expect(page_events==["phone_home"],"Scaled mobile pointer hits rendered navigation")
	if "--capture" in OS.get_cmdline_user_args() and DisplayServer.get_name()!="headless":
		surface.scale=Vector2.ONE; await show("weather"); await process_frame; await process_frame; root.get_texture().get_image().save_png("/tmp/phone-weather-native.png")
		p.zjuding_page="hub"; p.zjuding_panel=""; await show("zjuding"); await process_frame; await process_frame; root.get_texture().get_image().save_png("/tmp/phone-zjuding-native.png")
	body.queue_free(); await process_frame
	print("PHONE_NAVIGATION_TESTS: %d checks; %d failures" % [checks,failed])
	quit(1 if failed else 0)
