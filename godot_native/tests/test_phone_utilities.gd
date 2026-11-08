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
	var default_posts: Array=Store.defaults()
	var historical: Dictionary=Store.source("cc98.post-default-history").posts
	var legacy_posts: Array=default_posts.filter(func(post): return historical.has(post.id)).duplicate(true)
	for post in legacy_posts:
		for field in ["title", "body", "replies", "author"]:
			var values: Array = historical[post.id].get(field, [])
			if not values.is_empty():
				post[field] = values[0]
	legacy_posts[0].author="player author";legacy_posts[0].time="player time"
	legacy_posts[1].title+=" ";legacy_posts[1].body+="\n"
	legacy_posts[2].body="player body";legacy_posts[3].title="player title"
	var explicit_quest: Dictionary={"title":legacy_posts[0].title,"body":legacy_posts[0].body}
	expect(not historical.has("act-two-gamepad-market"), "default copy history excludes quest posts")
	expect(Store.import_bundle({"posts":legacy_posts,"questPostOverrides":{"act-two-gamepad-market":explicit_quest}})==OK,"whole-row old editor store imports normally")
	var upgraded_posts: Array=Store.load_posts()
	expect(upgraded_posts.size()==86 and upgraded_posts[0].replies==default_posts[0].replies,"legacy feeds receive the current corpus and updated reply counts")
	expect(upgraded_posts[1].author=="匿名用户" and upgraded_posts[2].author=="匿名用户", "historical default authors migrate to anonymous posting")
	var follows_source: bool=true
	for index in range(upgraded_posts.size()):
		if index in [1,2,3]:continue
		follows_source=follows_source and upgraded_posts[index].title==default_posts[index].title and upgraded_posts[index].body==default_posts[index].body
	expect(follows_source,"exact historical titles and bodies yield to the current source")
	expect(upgraded_posts[0].author=="player author" and upgraded_posts[0].time=="player time","default prose upgrade preserves independently edited metadata")
	expect(upgraded_posts[1].title==legacy_posts[1].title and upgraded_posts[1].body==legacy_posts[1].body,"nonexact player prose survives without trimming or fuzzy matching")
	expect(upgraded_posts[2].title==default_posts[2].title and upgraded_posts[2].body=="player body" and upgraded_posts[3].title=="player title" and upgraded_posts[3].body==default_posts[3].body,"title and body upgrades preserve the other independently edited field")
	expect(Store.load_quest_overrides().get("act-two-gamepad-market")==explicit_quest,"explicit quest overrides are never upgraded even when text matches old defaults")
	expect(Store.restore_defaults()==OK,"default upgrade checks leave a fresh isolated editor store")
	var missing_replies={"id":"test-custom-thread","time":"刚刚"}
	var generated: Array=Store.thread_replies(missing_replies)
	expect(generated.size() in [2,3,4] and generated==Store.thread_replies(missing_replies),"custom posts get repeatable fallback replies")
	expect(Store.thread_replies({"id":"test-empty-thread","threadReplies":[]}).is_empty(),"explicit empty replies stay empty")
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
	expect(node("LowPowerToggle")==null,"retired low-power mode has no interactive control")
	c.dispatch(s,"phone_low_power")
	expect(s.phoneBattery.keys()==["percent"] and s.ui.brightness==85 and s.ui.musicPlaying,"retired power intent cannot cap brightness or pause music")
	c.dispatch(s,"phone_settings_brightness",100)
	expect(s.ui.brightness==100 and s.ui.brightnessUserAdjusted,"Settings preserves explicit manual100 without a power cap")
	c.dispatch(s,"c1_network","cellular"); s.phoneBattery.percent=1; c.dispatch(s,"c1_network","campus_wifi")
	expect(s.phoneBattery.percent==0 and s.ui.brightness==100 and s.ui.musicPlaying,"network consumption reaches zero without limiting brightness or music")
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
	await process_frame
	await click(node("OpenPost_mood-room-01")); await show("cc98")
	expect(node("Cc98ThreadReply_3")!=null and "bd" in node("Cc98ThreadReply_3").text,"ordinary bd copy displays through the actual detail entry")
	var owner_label: bool=false
	for label: Label in body.find_children("*","Label",true,false):
		if "想把今天过完　楼主　3楼" == label.text: owner_label=true
	expect(owner_label,"follow-up floor shows the real thread author")
	await click(node("Cc98BackToFeed")); await show("cc98")
	search = node("Cc98Search"); search.text = "材料下午点完提交"; search.text_changed.emit(search.text)
	await process_frame
	await click(node("OpenPost_mood-room-02")); await show("cc98")
	var anonymous_alias_visible := false
	for label: Label in body.find_children("*", "Label", true, false):
		if label.text == "匿名用户 [甲]　3楼": anonymous_alias_visible = true
	expect(anonymous_alias_visible, "anonymous reply retains its authored floor alias")
	await click(node("Cc98BackToFeed")); await show("cc98")
	search = node("Cc98Search"); search.text = "怕室友也刷98"; search.text_changed.emit(search.text)
	await process_frame
	await click(node("OpenPost_mood-room-03")); await show("cc98")
	var headings: Array[String] = []
	for label: Label in body.find_children("*", "Label", true, false):
		headings.append(label.text)
	expect("匿名楼主　3楼" in headings, "anonymous follow-up uses the anonymous owner label")
	expect("麦斯威美式续命　5楼" in headings, "new persona resolves to its authored forum nickname")
	await click(node("Cc98BackToFeed")); await show("cc98")
	search=node("Cc98Search"); search.text="翻面章鱼"; search.text_changed.emit(search.text)
	expect(node("Post_daily-ex-16").visible and not node("Post_mood-room-01").visible,"new campus post participates in existing search")
	await process_frame
	await click(node("OpenPost_daily-ex-16")); await show("cc98")
	expect(node("Cc98ThreadTitle")!=null and "翻面章鱼" in node("Cc98ThreadTitle").text,"new campus post opens as a normal thread")
	await click(node("Cc98BackToFeed")); await show("cc98")
	search=node("Cc98Search")
	search.text=""; search.text_changed.emit("")
	await process_frame
	var market: Control=node("OpenPost_act-two-gamepad-market")
	var feed_scroll: Node=market.get_parent()
	while feed_scroll!=null and not feed_scroll is ScrollContainer: feed_scroll=feed_scroll.get_parent()
	if feed_scroll is ScrollContainer:
		feed_scroll.ensure_control_visible(market)
		await process_frame
	await click(market)
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
	# Optional billing uses receipts, never the story wallet or attendance.
	var store=root.get_node("State")
	var account=preload("res://scripts/chapters/campus_network_account.gd")
	store.d=store.initial();store.d.native.page="zjuding"
	var untouched=JSON.stringify([store.d.wallet,store.d.flags,store.d.items,store.d.actOne,store.d.networkMode])
	c.dispatch(store.d,"phone_network_review","duplicate_billing")
	expect(not account.account(store.d).resolved,"guessing a cause without documents cannot clear arrears")
	c.dispatch(store.d,"phone_network_document","bill")
	c.dispatch(store.d,"phone_network_document","receipt")
	c.dispatch(store.d,"phone_network_review","signal_issue")
	expect(not account.account(store.d).resolved,"unrelated signal complaint preserves arrears")
	c.dispatch(store.d,"phone_network_review","duplicate_billing")
	expect(account.account(store.d).resolved,"matching inspected documents resolves duplicate billing")
	expect(JSON.stringify([store.d.wallet,store.d.flags,store.d.items,store.d.actOne,store.d.networkMode])==untouched,"billing cannot spend story money or unlock attendance and chapters")
	expect(store.validate_snapshot(store.d) and store.save_game(),"billing state passes native save validation")
	store.d=store.initial();expect(store.load_game() and account.account(store.d).resolved,"billing survives real native save and reload")
	var forged=store.d.duplicate(true);forged.native.campus_network_account.receipt_seen=false
	expect(not store.validate_snapshot(forged),"save rejects settlement without receipt evidence")
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
