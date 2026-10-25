extends SceneTree
## Local presentation fixtures: functional conversation search and sender alignment.
const Pages=preload("res://scripts/ui/phone_pages.gd")
var checks := 0
var failures := 0
func _initialize() -> void: run.call_deferred()
func check(ok: bool, message: String) -> void:
	checks+=1
	if not ok:failures+=1;push_error("WECHAT UI: "+message)
func run() -> void:
	var source: Node=root.get_node("State");source.developer_mode=true
	check(source.begin_checkpoint("c1-code-hunt"),"source fixture")
	var state: Dictionary=source.d.duplicate(true)
	var pages := Pages.new()
	var surface: Control=pages.build("wechat",{},state);root.add_child(surface)
	for i: int in 6:await process_frame
	var before := JSON.stringify(state)
	var search: LineEdit=surface.find_child("WechatSearch",true,false)
	check(search!=null,"conversation list has a real search field")
	search.text="朋友";search.text_changed.emit(search.text)
	check(surface.find_child("WechatRow_1",true,false).visible,"search retains matching conversation")
	for id: String in ["0","2","3"]:check(not surface.find_child("WechatRow_"+id,true,false).visible,"search hides unrelated conversation "+id)
	search.text="不存在的联系人";search.text_changed.emit(search.text)
	check(surface.find_child("WechatNoResults",true,false).visible,"empty results are explicit")
	search.text="";search.text_changed.emit("")
	for id: String in ["0","1","2","3"]:check(surface.find_child("WechatRow_"+id,true,false).visible,"clearing restores conversation "+id)
	check(JSON.stringify(state)==before,"search changes presentation only")
	surface.free()
	state.actOne.phase="complete";state.flags.codeScattered=true
	pages.friend_open=true
	surface=pages.build("wechat",{},state);root.add_child(surface)
	for i: int in 6:await process_frame
	var reply: Control=surface.find_child("WechatSelfReply",true,false)
	var avatar: Control=surface.find_child("WechatSelfAvatar",true,false)
	check(reply!=null and avatar!=null,"authored outgoing reply has its own avatar")
	if reply!=null and avatar!=null:
		check(avatar.get_global_rect().position.x>=reply.get_global_rect().end.x,"outgoing avatar is on the right of the green bubble")
	check(surface.find_child("FriendChatBack",true,false)!=null,"chat retains actual return to conversation list")
	surface.free();pages.friend_open=false
	for scale_value in [.85,1.0,1.35]:
		state.native.settings.text_scale=scale_value
		surface=pages.build("wechat",{},state);root.add_child(surface)
		for i in range(6):await process_frame
		var toggle=surface.find_child("WechatSearchToggle",true,false)
		check(toggle!=null and not surface.find_child("WechatSearch",true,false).visible,"reference toolbar owns collapsed search")
		var previous=-INF
		for id in ["WechatRow_0","WechatRow_1","WechatRow_2","WechatRow_3","TiyiOfficialAccount","WechatPublicAccounts"]:
			var row=surface.find_child(id,true,false)
			check(row.get_global_rect().position.y>=previous-.1,"container owns row ordering at font "+str(scale_value))
			previous=row.get_global_rect().end.y
			for field in ["ConversationTitle","ConversationPreview","ConversationTime"]:
				var text=row.find_child(field,true,false)
				check(row.get_global_rect().grow(.1).encloses(text.get_global_rect()),"row owns text bounds: "+field)
				check(text.clip_text and text.text_overrun_behavior==TextServer.OVERRUN_TRIM_ELLIPSIS,"single-line copy cannot escape its column")
		check(surface.find_child("WechatTab_chats",true,false).find_child("WechatTabCaption",true,false).text=="微信","reference bottom navigation label")
		surface.free()
	await process_frame
	print("WECHAT_REFERENCE_UI ",checks," checks; ",failures," failures")
	quit(1 if failures else 0)
