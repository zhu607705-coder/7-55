extends SceneTree
const Pages=preload("res://scripts/ui/phone_pages.gd")
const Chapter=preload("res://scripts/chapters/chapter1_2.gd")
const Utilities=preload("res://scripts/chapters/phone_utilities.gd")
const Store=preload("res://scripts/data/cc98_store.gd")
var p=Pages.new()
var c=Chapter.new()
var s: Dictionary
var body: Control
var checks=0
var failed=0
func _initialize() -> void: call_deferred("_run")
func expect(ok: bool,label: String) -> void:
	checks+=1
	if not ok: failed+=1; push_error(label)
func fresh() -> Dictionary:
	var state: Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://data/initial_state.json"))
	state.native={"chapter":2,"page":"phone_home","scene":"","mode":"light","selected_item":""}
	state.actOne.phase="movement_required"
	return state
func show(page: String) -> void:
	if is_instance_valid(body): body.free()
	s.native.page=page
	body=p.build(page,c.view(page,s),s)
	root.add_child(body)
	await process_frame
func node(name: String) -> Node: return body.find_child(name,true,false)
func click(button: Control) -> void:
	var position=button.get_global_rect().get_center()
	var motion=InputEventMouseMotion.new(); motion.position=position; motion.global_position=position; root.push_input(motion,true)
	var down=InputEventMouseButton.new(); down.button_index=MOUSE_BUTTON_LEFT; down.pressed=true; down.position=position; down.global_position=position; root.push_input(down,true)
	await process_frame
	var up=InputEventMouseButton.new(); up.button_index=MOUSE_BUTTON_LEFT; up.pressed=false; up.position=position; up.global_position=position; root.push_input(up,true)
	await process_frame
func _run() -> void:
	root.size=Vector2i(500,1000)
	s=fresh()
	p.action_requested.connect(func(id,value): c.dispatch(s,id,value))
	var test_directory="user://phone-utilities-test-"+str(OS.get_process_id())
	expect(DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(test_directory))==OK,"isolated test store directory is created")
	Store.posts_path=test_directory.path_join("posts.json"); Store.quest_path=test_directory.path_join("quest.json")
	expect(Store.restore_defaults()==OK,"isolated test stores start writable")
	await show("settings")
	node("SettingsSearch").text="桌面"
	node("SettingsSearch").text_changed.emit("桌面")
	expect(node("Settings_desktop").visible and not node("Settings_sound").visible,"settings real search filters matching rows")
	await click(node("Settings_desktop"))
	expect(p.settings_page=="desktop","native Settings Button opens desktop subpage")
	await show("settings")
	await click(node("MoveDown_wechat"))
	expect(s.ui.homeAppOrder[1]=="wechat","move-down Button mutates authored order")
	c.dispatch(s,"phone_app_reset")
	p.settings_page="sound"; await show("settings")
	await click(node("BackgroundMusicToggle"))
	expect(s.ui.musicMuted and not s.ui.musicPlaying,"background mute stays independent from puzzle playback")
	p.settings_page="display"; await show("settings")
	var brightness=node("SettingsBrightness")
	brightness.value=17; brightness.drag_ended.emit(true)
	expect(s.ui.brightness==17,"brightness slider drag commits shared photo brightness")
	await show("control_center")
	s.ui.brightness=85; s.ui.musicPlaying=true
	await click(node("LowPowerToggle"))
	expect(s.phoneBattery.lowPowerMode and s.ui.brightness==45 and not s.ui.musicPlaying,"low power caps brightness and pauses source music")
	c.dispatch(s,"c1_network","cellular"); s.phoneBattery.percent=1; c.dispatch(s,"c1_network","campus_wifi")
	expect(s.phoneBattery.percent==1,"network switch preserves source 1 percent reserve")
	await show("phone_home")
	expect(node("Locked_clock")==null and node("HomeApp_clock")==null,"unavailable clock has no placeholder, slot or interactive icon")
	var old=s.ui.homeAppOrder.duplicate()
	var left=node("HomeApp_wechat")
	var right=node("HomeApp_tiyi")
	var source_point=left.get_global_rect().get_center()
	var target_point=right.get_global_rect().get_center()
	var down=InputEventMouseButton.new(); down.button_index=MOUSE_BUTTON_LEFT; down.pressed=true; down.position=source_point; down.global_position=source_point; root.push_input(down,true)
	await create_timer(.52).timeout
	expect(p.home_editing,"actual held pointer enters home editing after 460 ms")
	var motion=InputEventMouseMotion.new(); motion.position=target_point; motion.global_position=target_point; motion.button_mask=MOUSE_BUTTON_MASK_LEFT; root.push_input(motion,true)
	await process_frame
	var up=InputEventMouseButton.new(); up.button_index=MOUSE_BUTTON_LEFT; up.position=target_point; up.global_position=target_point; root.push_input(up,true)
	await process_frame
	expect(s.ui.homeAppOrder[0]=="tiyi" and s.ui.homeAppOrder[1]=="wechat","actual native drag swaps available home apps")
	expect(s.ui.homeAppOrder[9]==old[9],"drag leaves locked slot fixed")
	p.home_editing=false; await show("phone_home")
	node("HomeApp_wechat").grab_focus()
	var f2=InputEventKey.new(); f2.keycode=KEY_F2; f2.pressed=true; root.push_input(f2,true)
	await process_frame
	expect(p.home_editing,"F2 enters source desktop edit mode")
	var arrow=InputEventKey.new(); arrow.keycode=KEY_RIGHT; arrow.pressed=true; root.push_input(arrow,true)
	await process_frame
	await show("phone_home")
	expect(root.gui_get_focus_owner()==node("HomeApp_wechat"),"keyboard reordering preserves focus on moved icon")
	var escape=InputEventKey.new(); escape.keycode=KEY_ESCAPE; escape.pressed=true; root.push_input(escape,true)
	await process_frame
	expect(not p.home_editing,"Escape exits native home editing")
	c.dispatch(s,"phone_app_remove","wechat")
	expect(not "wechat" in s.ui.hiddenHomeAppIds,"story app removal rejected")
	c.dispatch(s,"phone_app_remove","tiyi")
	expect(s.ui.hiddenHomeAppIds.is_empty(),"Tiyi removal requires both proofs")
	s.actOne.exerciseStarted=true; s.ui.libraryFinalsPuzzle.presenceProofCollected=true
	c.dispatch(s,"phone_app_remove","tiyi")
	await show("settings"); p.settings_page="apps"; await show("settings")
	await click(node("Restore_tiyi"))
	expect(s.ui.hiddenHomeAppIds.is_empty(),"Settings Restore button restores optional app")
	s.actOne.cc98Login.authenticated=true
	await show("cc98")
	expect(node("Cc98EditToggle")==null,"post editor remains unavailable in formal play")
	var search=node("Cc98Search"); search.text="待办清单"; search.text_changed.emit(search.text)
	expect(node("Post_mood-room-01").visible and not node("Post_mood-room-02").visible,"real CC98 search filters title and body")
	search.text=""; search.text_changed.emit("")
	await click(node("OpenPost_act-two-gamepad-market"))
	expect(p.cc98_post=="act-two-gamepad-market","feed opens source market thread")
	await show("cc98")
	await click(node("Cc98BackToFeed"))
	expect(p.cc98_post.is_empty(),"thread back returns to list")
	await show("cc98")
	await click(node("Cc98Tab_boards")); await show("cc98")
	expect(p.cc98_tab=="boards","board navigation is functional")
	s.native.checkpoint_id="c2_test"
	p.cc98_tab="hot"; await show("cc98")
	await click(node("Cc98EditToggle")); await show("cc98")
	expect(p.cc98_editing,"developer editor Button starts editing")
	var title=node("Post_act-two-gamepad-market").find_child("Edit_title",true,false)
	title.text="虚构测试帖子"; title.text_changed.emit(title.text)
	await click(node("Cc98EditToggle"))
	expect(Store.load_quest_overrides().get("act-two-gamepad-market",{}).get("title")=="虚构测试帖子","explicit Save Button persists quest overrides")
	var original=Store.load_posts()[0].duplicate(true)
	expect(Store.save_edits({original.id:{"body":"本机修改的正文"}})==OK,"normal post changes save in separate store")
	var reset=fresh()
	var loaded=Store.all_posts(reset)
	var normal: Dictionary={}
	for post in loaded:
		if post.id==original.id: normal=post
	expect(normal.get("body")=="本机修改的正文" and normal.get("threadReplies")==original.threadReplies,"story reset retains edited body and authored replies")
	expect(Store.quest_posts(reset)[0].title=="虚构测试帖子","story reset retains quest overrides")
	expect(not Store.validate_bundle({"posts":"bad","questPostOverrides":{}}),"invalid imported separate store rejected")
	# Every Settings subpage is a real source-layout panel, including informational pages.
	await show("settings")
	for section in ["network","sound","display","desktop","apps","privacy","activity","about"]:
		p.settings_page=section
		await show("settings")
		expect(body.size.x==424 and body.get_meta("source_page",false),"Settings "+section+" uses the source-width native layout")
	var bundle={"posts":Store.defaults(),"questPostOverrides":{"act-two-gamepad-market":{"body":"导入的虚构正文"}}}
	expect(Store.validate_bundle(bundle) and Store.import_bundle(bundle)==OK,"explicit separate-storage bundle imports successfully")
	expect(Store.quest_posts(fresh())[0].body=="导入的虚构正文","bundle quest body survives fresh story state")
	expect(Store.import_bundle({"posts":Store.defaults()})==OK and Store.quest_posts(fresh())[0].body=="导入的虚构正文","partial browser store import leaves absent store untouched")
	var before_import=FileAccess.get_file_as_bytes(Store.posts_path)
	var good_quest_path=Store.quest_path
	Store.quest_path=test_directory.path_join("quest-import-blocked-directory")
	DirAccess.make_dir_absolute(ProjectSettings.globalize_path(Store.quest_path))
	var replacement=Store.defaults(); replacement[0].body="不能留下的部分导入"
	var failed_import=Store.import_bundle({"posts":replacement,"questPostOverrides":{}})
	expect(failed_import!=OK and FileAccess.get_file_as_bytes(Store.posts_path)==before_import,"failed second document import rolls back first exact bytes")
	DirAccess.remove_absolute(ProjectSettings.globalize_path(Store.quest_path))
	Store.quest_path=good_quest_path
	Store.restore_defaults()
	body.queue_free(); await process_frame
	print("PHONE_UTILITY_TESTS: %d checks; %d failures" % [checks,failed])
	quit(1 if failed else 0)
