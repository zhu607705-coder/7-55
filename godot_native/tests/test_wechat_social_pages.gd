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
	await press("WechatPublicAccounts");await press("WechatCampusAccount")
	check(surface.find_children("WechatArticle_*","Button",true,false).size()==6,"all six existing non-puzzle campus articles are available from opening")
	check(not has_text("22:45"),"early account does not disclose the later night-clearance clue")
	await press("WechatArticle_umbrella-stand")
	check(has_text("伞") and not has_text("22:45"),"article opens its full content without the locked notice")
	await press("WechatLocalBack")
	check(node("WechatArticle_lost-found")!=null,"article back returns to same account")
	await press("WechatLocalBack");await press("WechatLocalBack")
	await press("WechatTab_discover");await press("WechatMoments")
	check(surface.find_children("WechatMoment_*","VBoxContainer",true,false).size()==4,"four opening-day Moments are populated")
	var scroll: ScrollContainer=node("WechatScroll")
	scroll.scroll_vertical=120;await frames()
	await press("WechatLike_breakfast")
	check(pages.wechat_social.likes.get("breakfast",false),"like changes local browsing state")
	check(node("WechatScroll").scroll_vertical==120,"like refresh preserves reading position")
	await press("WechatLocalBack");await press("WechatTab_me");await press("WechatMyMoments")
	check(node("WechatMoment_breakfast")!=null and node("WechatMoment_rain")==null,"liked view contains only liked posts")
	await press("WechatLike_breakfast")
	check(surface.find_children("WechatMoment_*","VBoxContainer",true,false).is_empty(),"unlike removes the entry from liked view")
	check(JSON.stringify(state)==before,"all early browsing, article reading and likes leave the story snapshot unchanged")
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
