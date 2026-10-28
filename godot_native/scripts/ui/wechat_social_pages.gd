extends RefCounted
## Browsing state only. Reading, searching and liking never grant story facts.
const Palette=preload("res://scripts/ui/phone_palette.gd")
const Typography=preload("res://scripts/ui/native_typography.gd")
const NativeUi=preload("res://scripts/ui/native_ui_theme.gd")
const Chrome=preload("res://scripts/ui/wechat_chrome.gd")
const Bubble=preload("res://scripts/ui/wechat_message_bubble.gd")
const TiyiAccess=preload("res://scripts/chapters/tiyi_access.gd")
var campus: Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://data/source/chapter4-wechat.content.json")).official
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

func route(state: Dictionary, page: String, previous: String) -> void:
	if not is_same(owner,state):
		owner=state;tab="chats";panel="";article="";history_open=false;scrolls.clear();likes.clear()
	if page!=previous and page not in ["wechat","control_center"]:
		tab="chats";panel="";article="";history_open=false

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
	scroll.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	root.add_child(scroll)
	var margin:=MarginContainer.new();margin.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	margin.add_theme_constant_override("margin_left",inset);margin.add_theme_constant_override("margin_right",inset)
	margin.add_theme_constant_override("margin_top",18);margin.add_theme_constant_override("margin_bottom",20)
	scroll.add_child(margin)
	var column:=VBoxContainer.new();column.name="WechatFeed";column.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	column.add_theme_constant_override("separation",16);margin.add_child(column)
	if not key.is_empty():
		var restore: int=int(scrolls.get(key,0))
		scroll.get_v_scroll_bar().value_changed.connect(func(value): scrolls[key]=value)
		scroll.ready.connect(func(): scroll.set_deferred("scroll_vertical",restore))
	return column

func header(b, root: Control, title: String, back: Callable=Callable(), id: String="WechatLocalBack") -> void:
	b._header(root,title,Palette.CHROME,Palette.INK,back if back.is_valid() else func(): tab="chats";panel="";article="";b.tiyi_official_open=false;refresh(b))
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
		Chrome.icon(action,selected,Rect2(33,7,29,29),color)
		var caption=b._label(action,["微信","通讯录","发现","我"][i],Rect2(0,40,94.5,23),mini(17,font_size(b,13)),color,HORIZONTAL_ALIGNMENT_CENTER)
		caption.name="WechatTabCaption"

func open_panel(b, value: String) -> void:
	panel=value;article="";refresh(b)

func article_link(b, parent: Control, item: Dictionary, destination: String) -> void:
	var column:=card(parent)
	copy(column,str(item.get("section","历史文章")),font_size(b,12),Palette.MUTED)
	button(column,str(item.title),func(): article=str(item.id);article_parent=destination;refresh(b),"WechatArticle_"+str(item.id))
	if item.has("summary"):copy(column,str(item.summary),font_size(b,15),Palette.MUTED)
	if item.has("publishedAt"):copy(column,str(item.publishedAt),font_size(b,12),Palette.MUTED)

func show_article(b, item: Dictionary) -> Control:
	var root=b._base(Palette.BACKGROUND,b.APP_HEIGHT)
	header(b,root,"文章",func():article="";refresh(b))
	var column=feed(b,root,57,0,"article:"+str(item.id))
	copy(column,str(item.title),font_size(b,23))
	copy(column,("浙大体育与艺术" if article_parent=="tiyi" else str(campus.name))+" · "+str(item.get("publishedAt",item.get("section","历史文章"))),font_size(b,12),Palette.MUTED)
	for paragraph in item.body:copy(column,str(paragraph),font_size(b,18))
	return root

func build_extra(b) -> Control:
	if not article.is_empty():
		for item in social_copy.tiyi_articles if article_parent=="tiyi" else campus_articles():
			if item.id==article:return show_article(b,item)
	if panel=="officials":return accounts(b)
	if panel=="campus":return campus_account(b)
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

func accounts(b) -> Control:
	var root=b._base(Palette.BACKGROUND,b.APP_HEIGHT);header(b,root,"公众号")
	var column=feed(b,root,57,0,"accounts")
	button(column,"浙大体育与艺术",func():b.tiyi_official_open=true;refresh(b),"TiyiOfficialAccount")
	copy(column,"修读手记 · 场馆日常 · 客户端服务",font_size(b,14),Palette.MUTED)
	button(column,str(campus.name),func():open_panel(b,"campus"),"WechatCampusAccount")
	copy(column,str(campus.profileNote),font_size(b,14),Palette.MUTED)
	return root

func campus_account(b) -> Control:
	var root=b._base(Palette.BACKGROUND,b.APP_HEIGHT)
	header(b,root,str(campus.name),func():open_panel(b,"officials"))
	var column=feed(b,root,57,0,"campus")
	copy(column,"公众号 · 历史文章",font_size(b,13),Palette.MUTED)
	for item in campus_articles():article_link(b,column,item,"campus")
	return root

func tiyi_account(b) -> Control:
	if not article.is_empty() and article_parent=="tiyi":
		for item in social_copy.tiyi_articles:
			if item.id==article:return show_article(b,item)
	var root=b._base(Palette.BACKGROUND,b.APP_HEIGHT);root.name="TiyiOfficialAccountPage"
	root.set_meta("handles_all_actions",true)
	header(b,root,"浙大体育与艺术",func():b.tiyi_official_open=false;article="";refresh(b),"TiyiOfficialBack")
	var column=feed(b,root,57,57,"tiyi")
	copy(column,"公众号",font_size(b,13),Palette.MUTED)
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
	for item in social_copy.tiyi_articles.slice(0,2):article_link(b,column,item,"tiyi")
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
