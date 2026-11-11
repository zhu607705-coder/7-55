extends SceneTree
## Exercise early browsing without story writes, chapter-aware chats and real text geometry.
const Pages=preload("res://scripts/ui/phone_pages.gd")
const Bubble=preload("res://scripts/ui/wechat_message_bubble.gd")
const Chapter=preload("res://scripts/chapters/chapter1_2.gd")
var checks=0
var failures=0
var pages=Pages.new()
var controller=Chapter.new()
var state: Dictionary
var surface: Control
var actions: Array=[]

func _initialize() -> void:run.call_deferred()
func check(ok: bool, message: String) -> void:
	checks+=1
	if not ok:failures+=1;push_error("WECHAT SOCIAL: "+message)
func frames(count: int=8) -> void:
	for i in range(count):await process_frame
func render() -> void:
	if is_instance_valid(surface):surface.free()
	pages.entry_session=controller.phone_entry_session(state)
	surface=pages.build("wechat",controller.view("wechat",state),state)
	root.add_child(surface);await frames()
func node(id: String) -> Node:return surface.find_child(id,true,false)
func press(id: String) -> void:
	var target=node(id)
	check(target is Button,"reachable button "+id)
	if target is Button:target.pressed.emit();await render()
func has_text(text: String) -> bool:
	for label in surface.find_children("*","Label",true,false):
		if text in label.text:return true
	return false

func enter_official_query(value: String) -> void:
	var field := node("WechatOfficialQuery") as LineEdit
	check(field != null and field.is_visible_in_tree(), "public account search has a visible text field")
	if field == null: return
	field.text = value
	field.text_changed.emit(value)
	await frames()

func click_official_article(id: String) -> void:
	var target := node(id) as Button
	var scroll := node("WechatScroll") as ScrollContainer
	check(target != null and scroll != null, "article is a clickable part of the scrollable feed")
	if target == null or scroll == null: return
	scroll.ensure_control_visible(target)
	await frames()
	var visible := target.get_global_rect().intersection(scroll.get_global_rect())
	check(visible.has_area(), "article can be scrolled to a visible hit area")
	if not visible.has_area(): return
	var action_start := actions.size()
	for pressed: bool in [true, false]:
		var event := InputEventMouseButton.new()
		event.button_index = MOUSE_BUTTON_LEFT
		event.pressed = pressed
		event.position = visible.get_center()
		event.global_position = event.position
		root.push_input(event, true)
		await frames(1)
	check(actions.size() > action_start, "ordinary mouse click reaches the whole article card")
	await render()

func check_official_feed() -> void:
	var before := JSON.stringify(state)
	var action_start := actions.size()
	check(node("WechatOfficialFeed") is Control, "official-account conversation opens the mixed feed")
	for id: String in ["WechatCampusAccount", "TiyiOfficialAccount", "WechatLifeAccount"]:
		check(node(id) is Button, "frequently read accounts expose a profile control " + id)
	check(node("WechatFeedArticle_night-notice") == null, "opening-day feed hides the chapter-four notice")

	await press("WechatOfficialUnread")
	check(node("WechatFeedArticle_umbrella-stand") is Button, "unread feed contains the unread lead campus article")
	await click_official_article("WechatFeedArticle_umbrella-stand")
	check(has_text("大厅伞架") and has_text("精选留言"), "feed opens the original article and its comments")
	await press("WechatLocalBack")
	check(node("WechatFeedArticle_umbrella-stand") == null, "return stays in unread view and removes the newly read item")
	await press("WechatOfficialUnread")
	check(node("WechatFeedArticle_umbrella-stand") is Button, "all posts still include the read article")

	var scroll := node("WechatScroll") as ScrollContainer
	check(scroll != null, "official feed owns its own scroll container")
	if scroll != null:
		scroll.scroll_vertical = 430
		await frames()
		var previous_scroll := scroll.scroll_vertical
		check(previous_scroll >= 350, "mixed account feed reaches a deep reading position")
		await press("WechatFeedArticle_night-study")
		await press("WechatLocalBack")
		scroll = node("WechatScroll") as ScrollContainer
		check(scroll != null and scroll.scroll_vertical == previous_scroll, "article back restores the exact feed reading position")

	await press("WechatOfficialSearch")
	await enter_official_query("不存在的公众号测试词")
	check(has_text("没有找到相关的公众号或文章"), "an unmatched search explicitly shows empty results")
	await enter_official_query("22:45")
	check(node("WechatFeedArticle_night-notice") == null, "search cannot surface the locked notice")
	await enter_official_query("门厅那排")
	check(node("WechatFeedArticle_umbrella-stand") is Button and node("WechatFeedArticle_night-study") == null, "title search retains the matching article only")
	await press("WechatFeedArticle_umbrella-stand")
	check(has_text("雨伞认错三次"), "search result opens the same complete article")
	await press("WechatLocalBack")
	var field := node("WechatOfficialQuery") as LineEdit
	check(field != null and field.text == "门厅那排" and node("WechatFeedArticle_umbrella-stand") is Button, "reader back restores the query and its results")
	await enter_official_query("")
	check(node("WechatFeedAccount_campus") is Button and node("WechatFeedArticle_umbrella-stand") == null, "cleared search restores the account directory")
	await press("WechatLocalBack")
	check(node("WechatOfficialQuery") == null and node("WechatFeedArticle_umbrella-stand") is Button, "search back returns to the feed")
	await check_official_following()
	check(JSON.stringify(state) == before, "feed, search, follow and unread state never write story or inventory")
	check(actions.slice(action_start).all(func(action): return action == "phone_refresh"), "local official-account interactions emit only presentation refreshes")

func check_official_following() -> void:
	await press("WechatLifeAccount")
	check(has_text("紫金港拾光"), "the lifestyle account has its own profile")
	await press("WechatArticle_campus-life-dock")
	check(has_text("码头天亮得比路上早") and has_text("豆浆不要糖"), "the lifestyle account opens its own article and comment")
	await press("WechatLocalBack")
	await press("WechatProfileFollow")
	var follow := node("WechatProfileFollow") as Button
	check(follow != null and follow.text == "关注公众号", "unfollowing updates the profile control")
	await press("WechatLocalBack")
	await press("WechatOfficialFollowing")
	check(node("WechatFeedAccount_campus-life") == null and node("WechatFeedAccount_campus") is Button, "following list removes only the unfollowed account")
	await press("WechatLocalBack")
	await press("WechatOfficialSearch")
	await enter_official_query("紫金港拾光")
	check(node("WechatFeedAccount_campus-life") is Button and node("WechatFeedAccount_tiyi") == null, "search can find an unfollowed account by its name")
	await press("WechatFeedAccount_campus-life")
	await press("WechatProfileFollow")
	follow = node("WechatProfileFollow") as Button
	check(follow != null and follow.text == "已关注公众号", "following again updates the profile control")
	await press("WechatLocalBack")
	await press("WechatLocalBack")
	await press("WechatOfficialFollowing")
	check(node("WechatFeedAccount_campus-life") is Button, "following list includes the newly followed account")
	await press("WechatLocalBack")

func check_official_profile() -> void:
	check(has_text("置顶") and node("WechatArticle_umbrella-stand") is Button, "all posts show the account's pinned lead article")
	await press("WechatProfileTab_articles")
	check(not has_text("置顶") and node("WechatArticle_umbrella-stand") is Button, "articles tab keeps the article in the compact list without a pin label")
	await press("WechatArticle_umbrella-stand")
	await press("WechatLocalBack")
	check(not has_text("置顶") and node("WechatArticle_lost-found") is Button, "reader back preserves the account's articles tab")
	await press("WechatProfileTab_all")
	check(has_text("置顶"), "all posts restores the pinned presentation")

func check_bubbles() -> void:
	for label: Label in surface.find_children("MessageText","Label",true,false):
		var bubble: Control=label.get_parent().get_parent()
		var bounds=bubble.get_global_rect()
		var ink=label.get_global_rect()
		check(bounds.encloses(ink),"wrapped text remains inside its own bubble")
		check(ink.position.y-bounds.position.y>=8 and bounds.end.y-ink.end.y>=8,"bubble reserves vertical breathing room")
		check(label.size.y+0.1>=label.get_minimum_size().y,"all wrapped text lines fit")

func run() -> void:
	root.size=Vector2i(430,860)
	state=root.get_node("State").initial()
	state.native.page="wechat";state.native.chapter=1
	pages.action_requested.connect(func(id,value):actions.append(id);controller.dispatch(state,id,value))
	await render()
	var before=JSON.stringify(state)
	await press("TiyiOfficialAccount")
	check(node("TiyiDownloadCard")==null,"opening-day account has no future update card")
	await press("TiyiStudyMenu")
	check(node("WechatScroll")!=null and has_text(pages.wechat_social.social_copy.tiyi_articles[0].body[0]),"opening-day sports article is readable")
	await press("WechatLocalBack")
	await press("TiyiContact")
	check(state.actOne.tiyiUpdateStage=="not_started" and not actions.has("c2_tiyi_discover"),"opening contact reads service text without discovering a future update")
	await press("WechatLocalBack");await press("TiyiOfficialBack")
	await press("WechatPublicAccounts")
	await check_official_feed()
	await press("WechatCampusAccount")
	check(surface.find_children("WechatArticle_*","Button",true,false).size()==6,"all six existing non-puzzle campus articles are available from opening")
	check(not has_text("22:45"),"early account does not disclose the later night-clearance clue")
	await check_official_profile()
	await press("WechatArticle_umbrella-stand")
	check(has_text("伞") and not has_text("22:45"),"article opens its full content without the locked notice")
	var cover := node("WechatArticleCover") as TextureRect
	check(cover!=null and cover.texture!=null and cover.texture.get_size()==Vector2(960,540),"archive reader loads a full-size cover")
	check(has_text("雨伞认错三次") and has_text("精选留言"),"archive reader displays the supplied comments")
	await press("WechatLocalBack")
	check(node("WechatArticle_lost-found")!=null,"article back returns to same account")
	await press("WechatLocalBack");await press("WechatLocalBack")
	for tab: String in ["discover", "me"]:
		var button := node("WechatTab_" + tab) as Button
		check(button != null and button.disabled and button.focus_mode == Control.FOCUS_NONE,
			"locked footer tab is disabled and excluded from keyboard focus: " + tab)
		if button != null:
			for down: bool in [true, false]:
				var event := InputEventMouseButton.new()
				event.button_index = MOUSE_BUTTON_LEFT
				event.pressed = down
				event.position = button.get_global_rect().get_center()
				event.global_position = event.position
				root.push_input(event, true)
				await frames(1)
			button.pressed.emit()
		check(pages.wechat_social.tab == "chats", "locked footer tab cannot open: " + tab)
	await press("WechatTab_contacts")
	check(pages.wechat_social.tab == "contacts", "contacts remains usable")
	await press("WechatTab_chats")
	check(JSON.stringify(state)==before,"early browsing and reading leave the story snapshot unchanged")
	# A later save can legitimately have no C1 scatter animation receipt.
	state.native.chapter=2;state.actOne.phase="movement_required";state.flags.codeScattered=false
	pages.wechat_social.panel="";pages.wechat_social.tab="chats";pages.friend_open=true
	await render()
	check(node("WechatFollowupQuestion")!=null and node("WechatOpeningMessage")==null,"C2 current chat does not depend on C1 animation flags")
	check(not has_text("突然开始点名") and not has_text("任务："),"C1 warning is not presented as a later objective")
	check_bubbles()
	state.native.chapter=4;state.actOne.phase="prologue"
	await render()
	check(node("WechatFollowupQuestion")==null and not has_text("突然开始点名"),"stale legacy phase cannot turn a later chapter back into C1")
	await press("WechatEarlierMessages")
	check(has_text("突然开始点名"),"earlier messages remain accessible through explicit history")
	# Same logical layout, enlarged fonts and independently scaled outer phone.
	for font_scale in [.85,1.0,1.35]:
		state.native.settings={"text_scale":font_scale}
		for outer_scale in [1.0,390.0/430.0]:
			await render();surface.scale*=outer_scale;await frames();check_bubbles()
	pages.friend_open=false
	await render()
	await press("WechatPublicAccounts");await press("WechatCampusAccount")
	var before_night_notice=JSON.stringify(state)
	await press("WechatArticle_night-notice")
	cover=node("WechatArticleCover") as TextureRect
	check(cover!=null and cover.texture!=null and cover.texture.resource_path.ends_with("/notice.webp"),"night notice loads the shared cover")
	check(has_text("22:45") and has_text("作者回复"),"later account can read the full notice and its reply")
	check(JSON.stringify(state)==before_night_notice,"reading the later article does not grant story facts")
	if is_instance_valid(surface):surface.free()
	var column=VBoxContainer.new();column.size=Vector2(378,720);root.add_child(column)
	for outgoing in [false,true]:
		var message=Bubble.new()
		message.configure("长消息需要完整换行，不能压到气泡外面。".repeat(8)+"\nLongUnbrokenWord".repeat(8),outgoing,24)
		column.add_child(message)
	await frames(12)
	var previous_end=0.0
	for message in column.get_children():
		check(message.bubble.get_global_rect().encloses(message.text_label.get_global_rect()),"long Chinese and unbroken Latin text remain contained")
		check(message.position.y>=previous_end,"auto-height message rows never overlap")
		previous_end=message.position.y+message.size.y
	column.free();await frames(1)
	print("WECHAT_SOCIAL_PAGES ",checks," checks; ",failures," failures")
	quit(1 if failures else 0)
