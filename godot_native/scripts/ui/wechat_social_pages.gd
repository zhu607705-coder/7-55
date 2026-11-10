extends RefCounted
## Browsing state only. Reading, searching and liking never grant story facts.
const Palette=preload("res://scripts/ui/phone_palette.gd")
const Typography=preload("res://scripts/ui/native_typography.gd")
const NativeUi=preload("res://scripts/ui/native_ui_theme.gd")
const Chrome=preload("res://scripts/ui/wechat_chrome.gd")
const Official=preload("res://scripts/ui/wechat_official_pages.gd")
const Bubble=preload("res://scripts/ui/wechat_message_bubble.gd")
const TiyiAccess=preload("res://scripts/chapters/tiyi_access.gd")
const CAMPUS_CONTENT="res://data/source/chapter4-wechat.content.json"
var campus: Dictionary=load_campus_content()
var social_copy: Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://data/native/wechat-social-content.json"))
var tab="chats"
var search_open=false
var panel=""
var article=""
var article_parent=""
var history_open=false
var likes: Dictionary={}
var scrolls: Dictionary={}
var owner: Dictionary={}
var official_mode := "feed"
var official_query := ""
var official_read: Dictionary = {}
var official_following: Dictionary = {}
var profile_articles_only := false

static func load_campus_content() -> Dictionary:
	return JSON.parse_string(FileAccess.get_file_as_string(CAMPUS_CONTENT)).official

static func article_cover(item: Dictionary, minimum_size: Vector2) -> TextureRect:
	var cover := TextureRect.new()
	cover.name="WechatArticleCover"
	if item.has("coverTone"):
		cover.texture=load("res://assets/ui/wechat/official/%s.webp" % item.coverTone)
	cover.texture_filter=CanvasItem.TEXTURE_FILTER_NEAREST
	cover.expand_mode=TextureRect.EXPAND_IGNORE_SIZE
	cover.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_COVERED
	cover.custom_minimum_size=minimum_size
	cover.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	cover.mouse_filter=Control.MOUSE_FILTER_IGNORE
	cover.accessibility_name=str(item.get("coverAlt", ""))
	return cover

func word(key: String) -> String:
	return str(social_copy.ui[key])

func campus_articles() -> Array:
	# IDs and publication metadata remain source-owned; only optional prose changes.
	var articles: Array=[]
	for source_article in campus.optionalArticles:
		var item: Dictionary=source_article.duplicate(true)
		for revised in social_copy.campus_articles:
			if revised.id==item.id:item.merge(revised,true);break
		articles.append(item)
	return articles

func night_notice() -> Dictionary:
	var item: Dictionary=campus.duplicate()
	item.merge({
		"id":"night-notice",
		"section":"夜间通知",
		"title":campus.articleTitle,
		"body":[campus.summary]+campus.details
	})
	return item

func can_browse_night_notice(b) -> bool:
	return int(b.s.native.get("chapter",1))>=4

func route(state: Dictionary, page: String, previous: String) -> void:
	if not is_same(owner,state):
		owner=state;tab="chats";panel="";article="";history_open=false;scrolls.clear();likes.clear()
		official_read.clear();official_following.clear();official_query="";official_mode="feed";profile_articles_only=false
	if page!=previous and page not in ["wechat","control_center"]:
		tab="chats";panel="";article="";history_open=false;official_mode="feed";official_query="";profile_articles_only=false

func font_size(b, value: int=17) -> int:
	return roundi(value*clampf(float(b.s.get("native",{}).get("settings",{}).get("text_scale",1.0)),.85,1.35))

func refresh(b) -> void:
	b.action_requested.emit("phone_refresh",null)

func copy(parent: Control, text: String, size: int=17, color: Color=Palette.INK) -> Label:
	var label:=Label.new();Typography.apply_body(label)
	label.text=text;label.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	label.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	label.add_theme_font_size_override("font_size",size)
	label.add_theme_color_override("font_color",color)
	label.mouse_filter=Control.MOUSE_FILTER_IGNORE
	parent.add_child(label)
	return label

func button(parent: Control, text: String, callback: Callable, id: String, primary: bool=false) -> Button:
	var control:=Button.new();Typography.apply_body(control)
	control.set_meta("phone_button_role","action")
	control.name=id;control.text=text;control.custom_minimum_size.y=44
	control.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	control.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	NativeUi.apply_button(control,Palette.ACCENT if primary else Color.WHITE,Color.WHITE if primary else Palette.INK,Palette.LINE,4,1,roundi(16*clampf(float(owner.get("native",{}).get("settings",{}).get("text_scale",1.0)),.85,1.35)),Vector2(12,10))
	control.pressed.connect(callback);parent.add_child(control)
	return control

func card(parent: Control) -> VBoxContainer:
	var frame:=PanelContainer.new();frame.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	var skin:=StyleBoxFlat.new();skin.bg_color=Color.WHITE;skin.set_corner_radius_all(4)
	skin.content_margin_left=14;skin.content_margin_right=14;skin.content_margin_top=14;skin.content_margin_bottom=14
	frame.add_theme_stylebox_override("panel",skin);parent.add_child(frame)
	var column:=VBoxContainer.new();column.add_theme_constant_override("separation",12);frame.add_child(column)
	return column

func feed(b, root: Control, top: float=57, bottom: float=0, key: String="", inset: int=12) -> VBoxContainer:
	var scroll:=ScrollContainer.new();scroll.name="WechatScroll"
	scroll.position=Vector2(0,top);scroll.size=Vector2(378,b.APP_HEIGHT-top-bottom)
	scroll.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED
	scroll.scroll_deadzone=8
	scroll.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	root.add_child(scroll)
	var margin:=MarginContainer.new();margin.size_flags_horizontal=Control.SIZE_EXPAND_FILL; margin.mouse_filter=Control.MOUSE_FILTER_PASS
	margin.add_theme_constant_override("margin_left",inset);margin.add_theme_constant_override("margin_right",inset)
	margin.add_theme_constant_override("margin_top",18);margin.add_theme_constant_override("margin_bottom",20)
	scroll.add_child(margin)
	var column:=VBoxContainer.new();column.name="WechatFeed";column.size_flags_horizontal=Control.SIZE_EXPAND_FILL;column.mouse_filter=Control.MOUSE_FILTER_PASS
	column.add_theme_constant_override("separation",16);margin.add_child(column)
	if not key.is_empty():
		var restore: int=int(scrolls.get(key,0))
		var remember := func(value: float): scrolls[key] = value
		if restore == 0:
			scroll.get_v_scroll_bar().value_changed.connect(remember)
		else:
			scroll.ready.connect(func():
				# Card minimum sizes settle after the first container layout.
				var tree := scroll.get_tree()
				await tree.process_frame
				await tree.process_frame
				if not is_instance_valid(scroll) or not scroll.is_inside_tree():
					return
				scroll.scroll_vertical = restore
				scroll.get_v_scroll_bar().value_changed.connect(remember))
	return column

func header(b, root: Control, title: String, back: Callable=Callable(), id: String="WechatLocalBack", background: Color=Palette.CHROME) -> void:
	b._header(root,title,background,Palette.INK,back if back.is_valid() else func(): tab="chats";panel="";article="";b.tiyi_official_open=false;refresh(b))
	var nav=root.find_child("PhoneNav_back",true,false)
	if nav:nav.name=id

func footer(b, root: Control) -> void:
	var height=68.0
	b._panel(root,Rect2(0,b.APP_HEIGHT-height,378,height),Palette.CHROME,Palette.LINE,0,1)
	var ids=["chats","contacts","discover","me"]
	for i in range(4):
		var selected: String=ids[i]
		var color: Color=Palette.ACCENT if tab==selected else Palette.INK
		var action=b._button(root,"",Rect2(i*94.5,b.APP_HEIGHT-height,94.5,height),func():tab=selected;panel="";article="";b.tiyi_official_open=false;refresh(b),Palette.CHROME,Palette.INK,0,Color.TRANSPARENT)
		action.name="WechatTab_"+selected
		action.set_meta("phone_button_role","navigation")
		action.set_meta("phone_button_selected",tab==selected)
		Chrome.icon(action,selected,Rect2(33,7,29,29),color)
		var caption=b._label(action,["微信","通讯录","发现","我"][i],Rect2(0,40,94.5,23),mini(17,font_size(b,13)),color,HORIZONTAL_ALIGNMENT_CENTER)
		caption.name="WechatTabCaption"

func open_panel(b, value: String) -> void:
	if value.is_empty() and panel=="officials":
		official_mode="feed";official_query=""
	panel=value;article="";refresh(b)

func show_article(b, item: Dictionary) -> Control:
	var root: Control=b._base(Color.WHITE,b.APP_HEIGHT)
	root.name="WechatOfficialArticle"
	header(b,root,"公众号",func():article="";refresh(b),"WechatLocalBack",Color.WHITE)
	var column=feed(b,root,54,0,"article:"+str(item.id),20)
	copy(column,str(item.title),font_size(b,25))
	copy(column,Official.name_for(self,article_parent),font_size(b,14),Official.LINK)
	copy(column,str(item.get("publishedAt",item.get("section","历史文章"))),font_size(b,13),Official.MUTED)
	if item.has("coverTone"):
		column.add_child(article_cover(item,Vector2(0,182)))
	for paragraph: String in item.body:
		var label := copy(column,paragraph,font_size(b,17))
		label.add_theme_constant_override("line_spacing",6)
	if item.has("comments"):
		copy(column,"精选留言",font_size(b,17))
		for entry: Dictionary in item.comments:
			var comment:=card(column)
			comment.get_parent().add_theme_stylebox_override("panel", NativeUi.box(Official.FEED,Color.TRANSPARENT,0,7,Vector2(12,11)))
			copy(comment,"%s  ·  %s 赞" % [entry.author,entry.likes],font_size(b,13),Official.MUTED)
			copy(comment,str(entry.text),font_size(b,16))
			if entry.has("reply"):
				copy(comment,"作者回复",font_size(b,13),Official.GREEN)
				copy(comment,str(entry.reply),font_size(b,16))
	return root

func build_extra(b) -> Control:
	if not article.is_empty():
		for item: Dictionary in Official.items(b,self,article_parent):
			if item.id==article:return show_article(b,item)
	if panel=="officials":return Official.feed(b,self)
	if panel in ["campus","campus-life"]:return official_account(b,panel)
	if panel=="moments":return moments(b)
	if panel=="liked":return moments(b,true)
	if panel in ["roommate","mentor","helper"]:return conversation(b,panel)
	if tab=="chats":return null
	var root=b._base(Palette.BACKGROUND,b.APP_HEIGHT)
	header(b,root,{"contacts":"通讯录","discover":"发现","me":"我"}[tab],func():b.page_requested.emit("phone_home"),"PhoneNav_exit")
	var column=feed(b,root,57,68,tab)
	match tab:
		"contacts":
			button(column,"公众号",func():open_panel(b,"officials"),"WechatPublicAccounts")
			button(column,"朋友",func():b._open_wechat_friend(),"WechatContact_friend")
			button(column,"室友",func():open_panel(b,"roommate"),"WechatContact_roommate")
			button(column,"导师",func():open_panel(b,"mentor"),"WechatContact_mentor")
		"discover":
			button(column,"朋友圈",func():open_panel(b,"moments"),"WechatMoments")
			button(column,"公众号 · 历史文章",func():open_panel(b,"officials"),"WechatDiscoverAccounts")
		"me":
			copy(column,"我",font_size(b,25))
			copy(column,word("me_caption"),font_size(b,16),Palette.MUTED)
			button(column,word("liked"),func():open_panel(b,"liked"),"WechatMyMoments")
			copy(column,"已赞 %d 条动态"%likes.values().count(true),font_size(b,14),Palette.MUTED)
	footer(b,root)
	return root

func official_account(b, account: String) -> Control:
	var root: Control=b._base(Color.WHITE,b.APP_HEIGHT)
	root.name="WechatOfficialProfile"
	header(b,root,"公众号",func():open_panel(b,"officials"),"WechatLocalBack",Color.WHITE)
	var column=feed(b,root,54,0,"profile:"+account,17)
	Official.profile_intro(b,self,column,account)
	Official.profile_articles(b,self,column,account)
	return root

func tiyi_account(b) -> Control:
	if not article.is_empty() and article_parent=="tiyi":
		for item in social_copy.tiyi_articles:
			if item.id==article:return show_article(b,item)
	var root=b._base(Color.WHITE,b.APP_HEIGHT);root.name="TiyiOfficialAccountPage"
	root.set_meta("handles_all_actions",true)
	header(b,root,"公众号",func():b.tiyi_official_open=false;article="";refresh(b),"TiyiOfficialBack",Color.WHITE)
	var column=feed(b,root,54,57,"profile:tiyi",17)
	Official.profile_intro(b,self,column,"tiyi")
	var stage: String=str(b.s.actOne.get("tiyiUpdateStage","not_started"))
	if TiyiAccess.update_required(b.s) and stage!="not_started":
		var download=card(column);download.name="TiyiDownloadCard"
		copy(download,"浙大体艺 APP",font_size(b,22))
		copy(download,"客户端服务",font_size(b,13),Palette.MUTED)
		if stage=="official_entry_found":
			button(download,word("acquire_update"),func():b.action_requested.emit("c2_tiyi_acquire",null),"TiyiAcquireUpdate",true)
			copy(download,word("network"),font_size(b,13),Palette.MUTED)
		elif stage=="package_ready":
			copy(download,word("package_ready"),font_size(b,17))
			button(download,"安装更新",func():b.action_requested.emit("c2_tiyi_install",null),"TiyiInstallUpdate",true)
		else:
			copy(download,word("installed"),font_size(b,17))
			button(download,word("return_home"),func():b.page_requested.emit("phone_home"),"TiyiUpdateReturnHome",true)
	Official.profile_articles(b,self,column,"tiyi")
	b._panel(root,Rect2(0,b.APP_HEIGHT-57,378,57),Palette.CHROME,Palette.LINE,0,1)
	for i in range(3):
		var index: int=i
		var menu=b._button(root,["修读手记","场馆日常","联系我们"][i],Rect2(i*126,b.APP_HEIGHT-55,126,53),func():
			if index==2 and TiyiAccess.update_required(b.s):b.action_requested.emit("c2_tiyi_discover",null)
			else:article=social_copy.tiyi_articles[index].id;article_parent="tiyi";refresh(b),Palette.CHROME,Palette.INK,0,Palette.LINE)
		menu.name=["TiyiStudyMenu","TiyiVenueMenu","TiyiContact"][i]
	return root

func moments(b, only_liked: bool=false) -> Control:
	var root=b._base(Palette.BACKGROUND,b.APP_HEIGHT)
	header(b,root,word("liked") if only_liked else "朋友圈",func():panel="";refresh(b))
	var column=feed(b,root,57,0,"liked" if only_liked else "moments")
	copy(column,word("liked") if only_liked else word("moments_heading"),font_size(b,24))
	if only_liked and likes.values().count(true)==0:copy(column,word("liked_empty"),font_size(b,16),Palette.MUTED)
	for post in social_copy.moments:
		if only_liked and not likes.get(post.id,false):continue
		var entry=card(column);entry.name="WechatMoment_"+post.id
		copy(entry,post.author,font_size(b,17),Color("576b95"))
		copy(entry,post.text,font_size(b,18))
		copy(entry,post.time,font_size(b,12),Palette.MUTED)
		button(entry,"取消赞" if likes.get(post.id,false) else "赞",func():likes[post.id]=not likes.get(post.id,false);refresh(b),"WechatLike_"+post.id)
		for comment in post.comments:copy(entry,comment,font_size(b,14),Palette.MUTED)
	return root

func conversation(b, who: String) -> Control:
	var root=b._base(Palette.BACKGROUND,b.APP_HEIGHT)
	header(b,root,{"roommate":"室友","mentor":"导师","helper":"文件传输助手"}[who],func():panel="";refresh(b))
	var column=feed(b,root,57,0,"conversation:"+who,0)
	var text: String=social_copy.conversation[who]
	if who=="helper":
		copy(column,text,font_size(b,15),Palette.MUTED).name="MessageText"
		return root
	var row=Bubble.new();row.configure(text,who=="helper",font_size(b,18));column.add_child(row)
	row.avatar.get_child(0).text={"roommate":"室","mentor":"导","helper":"我"}[who]
	return root
