extends RefCounted
## Native reconstructions of original phone app hierarchies. Source CSS colors and art.
## All hotspots emit intents; this builder never changes story state.
signal action_requested(action_id: String, value: Variant)
signal page_requested(page: String)
signal presentation_requested(cue: String)
signal document_requested(config: Dictionary)
const OpeningPresentation = preload("res://scripts/ui/native_opening_presentation.gd")
const PhoneNotice = preload("res://scripts/ui/native_phone_notice.gd")
const NativeUi = preload("res://scripts/ui/native_ui_theme.gd")
const PhotoEvidence = preload("res://scripts/ui/photo_evidence_surface.gd")
const WeatherIcon = preload("res://scripts/ui/native_weather_icon.gd")
const TiyiIdentity = preload("res://scripts/ui/native_tiyi_identity.gd")
const EndingResume = preload("res://scripts/ui/native_ending_resume.gd")
const CheckinPage = preload("res://scripts/ui/native_checkin_page.gd")
var checkin_page = CheckinPage.new()
const HomeArt = preload("res://scripts/ui/phone_home_art.gd")
const NativeLibrary = preload("res://scripts/ui/native_library_pages.gd")
var native_library = NativeLibrary.new()
const Cc98Login = preload("res://scripts/ui/cc98_login_page.gd")
const Cc98Gamepad = preload("res://scripts/ui/cc98_gamepad_exchange.gd")
var cc98_login = Cc98Login.new()
const LakeApps = preload("res://scripts/ui/c3_lake_app_context.gd")
var lake_apps = LakeApps.new()
const Utilities = preload("res://scripts/chapters/phone_utilities.gd")
const DropButton = preload("res://scripts/ui/phone_drop_button.gd")
const APP_HEIGHT = 814.0 * 378.0 / 424.0
const PHONE_SCALE = 424.0 / 378.0
var control_center_return = "phone_home"
var control_reset_confirm = false
const PhoneEntry=preload("res://scripts/chapters/phone_entry_session.gd")
const EntryVisual=preload("res://scripts/ui/phone_entry_visual.gd")
var entry_session=PhoneEntry.new()
var friend_open: bool:
	get: return entry_session.friend_open
	set(value):
		if value: entry_session.friend_open=true
		else: entry_session.close_friend()
var zjuding_page = "hub"
var zjuding_panel = ""
var zjuding_overlay = ""
var zjuding_query = ""
var zjuding_detail = ""
var zjuding_visitor = {"name":"","date":"","purpose":"校园参观"}
var zjuding_feedback = {"category":"功能建议","content":""}
var zjuding_feedback_status = ""
const HomeButton = preload("res://scripts/ui/home_app_button.gd")
const PhoneChrome = preload("res://scripts/ui/phone_chrome.gd")
const Posts = preload("res://scripts/data/cc98_store.gd")
var settings_page = "root"
var settings_query = ""
var cc98_tab = "hot"
var cc98_board = ""
var cc98_post = ""
var cc98_query = ""
var cc98_followed: Array = ["校园生活","学习天地","交通出行","开怀一笑"]
var cc98_recent: Array = []
var cc98_drafts: Dictionary = {}
var cc98_editing = false
var cc98_note_ready = false
var home_focus_id = ""
var home_editing = false
const INK = Color("222322")
const PAPER = Color("fff4d8")
const BLUE = Color("174d9d")
const MUTED = Color("637080")
var handled: Array = []
var s: Dictionary = {}
var previous_page = ""
var displayed_balance_shifted = false
var bonsai_stage_seen = -1

func build(page: String, view: Dictionary, state: Dictionary) -> Control:
	s = state
	entry_session.route(s)
	lake_apps.route(previous_page,page,s)
	if page != previous_page and page != "control_center":
		if not page.begins_with("library_"): native_library.reset()
		if page!="checkin": checkin_page.reset()
		if page == "settings": settings_page = "root"; settings_query = ""
		if page != "cc98":
			cc98_login.reset()
			cc98_tab="hot"; cc98_board=""; cc98_post=""; cc98_query=""; cc98_recent=[]; cc98_followed=["校园生活","学习天地","交通出行","开怀一笑"]; cc98_drafts={}; cc98_editing=false; cc98_note_ready=false
		if page != "phone_home": home_editing = false; home_focus_id = ""
		if page != "wechat": friend_open = false
		if page != "bonsai": bonsai_stage_seen = -1
	if page=="control_center" and previous_page!="control_center":
		control_center_return=previous_page if not previous_page.is_empty() else "phone_home"
		control_reset_confirm=false
	previous_page = page
	handled = []
	var root: Control
	if page!="control_center" and entry_session.family=="zjuding" and entry_session.phase!="ready":
		root=_entry_loading("zjuding")
	else:
		match page:
			"alarm": root = _alarm()
			"desktop": root = _wake()
			"ending": root = EndingResume.new().build(self)
			"phone_home": root = _home()
			"wechat": root = _wechat(view)
			"system_chat": root = _conversation(view)
			"control_center": root = _controls()
			"checkin": root = _checkin()
			"campus_card": root = _campus_card()
			"bonsai": root = _bonsai()
			"cc98": root = _cc98(view)
			"zjuding": root = _zjuding()
			"tiyi": root = _tiyi(view)
			"weather": root = _weather()
			"directory": root = _directory()
			"library_app", "library_recovery", "library_record", "library_rule", "library_catalog", "library_archive", "library_022_dialogue", "c3_lake_catalog": root = _library(page,view)
			"photos": root = _photos(view)
			"settings": root = _settings(view)
			_: return null
	var bare = page in ["alarm","desktop","ending"]
	if not bare:
		root.custom_minimum_size.y = maxf(APP_HEIGHT,root.custom_minimum_size.y)
		root.size.y = root.custom_minimum_size.y
	root.set_meta("handled_action_ids",handled.duplicate())
	var outer = Control.new()
	var factor = PHONE_SCALE
	outer.custom_minimum_size = Vector2(424,854 if bare else root.custom_minimum_size.y*factor)
	outer.size = outer.custom_minimum_size
	root.scale = Vector2.ONE*factor
	outer.add_child(root)
	outer.set_meta("handled_action_ids",handled.duplicate())
	outer.set_meta("handles_app_grid",root.get_meta("handles_app_grid",false))
	outer.set_meta("source_page",true)
	outer.set_meta("bare",bare)
	outer.set_meta("source_overlay",root.get_meta("source_overlay",false))
	outer.set_meta("handles_all_actions",root.get_meta("handles_all_actions",false))
	outer.clip_contents = true
	return outer

func _base(color: Color, height: float = 570) -> Control:
	var root = Control.new()
	root.custom_minimum_size = Vector2(378,height)
	root.size = root.custom_minimum_size
	root.clip_contents = true
	var background = ColorRect.new()
	background.color = color
	background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.add_child(background)
	return root

func _style(color: Color, border: Color = Color.TRANSPARENT, radius: int = 0, width: int = 0) -> StyleBoxFlat:
	var style = StyleBoxFlat.new()
	style.bg_color = color
	style.border_color = border
	style.set_border_width_all(width)
	style.set_corner_radius_all(radius)
	return style

func _panel(root: Control, rect: Rect2, color: Color, border: Color = Color.TRANSPARENT, radius: int = 0, width: int = 0) -> Panel:
	var panel = Panel.new()
	panel.position = rect.position
	panel.size = rect.size
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_theme_stylebox_override("panel",_style(color,border,radius,width))
	root.add_child(panel)
	return panel

func _label(root: Control, text: String, rect: Rect2, fs: int = 18, color: Color = INK, align: HorizontalAlignment = HORIZONTAL_ALIGNMENT_LEFT) -> Label:
	var label = Label.new()
	label.position = rect.position
	label.size = rect.size
	label.text = text
	label.add_theme_color_override("font_color",color)
	label.add_theme_font_size_override("font_size",fs)
	label.horizontal_alignment = align
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(label)
	return label

func _button(root: Control, text: String, rect: Rect2, callback: Callable, color: Color = PAPER, ink: Color = INK, radius: int = 0, border: Color = INK) -> Button:
	var button = Button.new()
	button.position = rect.position
	button.size = rect.size
	button.text = text
	# The 378px canvas scales by 424/378. Source 14px labels use 13 authored
	# pixels (14.58 logical); explicit app sizes remain authored exceptions.
	NativeUi.apply_button(button,color,ink,border,radius,2 if border.a > 0 else 0,NativeUi.font_size_for_scale(NativeUi.FONT_LABEL,PHONE_SCALE),Vector2.ZERO)
	button.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	button.pressed.connect(callback)
	root.add_child(button)
	return button

func _act(root: Control, text: String, rect: Rect2, id: String, value: Variant = null, color: Color = PAPER, ink: Color = INK, radius: int = 0, border: Color = INK) -> Button:
	if not handled.has(id): handled.append(id)
	return _button(root,text,rect,func(): action_requested.emit(id,value),color,ink,radius,border)

func _page(root: Control, text: String, rect: Rect2, page: String, color: Color = PAPER, ink: Color = INK) -> Button:
	return _button(root,text,rect,func(): page_requested.emit(page),color,ink)

func _image(root: Control, path: String, rect: Rect2) -> TextureRect:
	var image = TextureRect.new()
	image.position = rect.position
	image.size = rect.size
	image.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	image.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	image.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var resource = "res://assets/" + path
	if ResourceLoader.exists(resource): image.texture = load(resource)
	root.add_child(image)
	return image

func _grid_texture(root: Control, color: Color = Color("ead7ae")) -> void:
	for x in range(0,378,14): _panel(root,Rect2(x,0,1,root.custom_minimum_size.y),Color(color,.18))
	for y in range(0,int(root.custom_minimum_size.y),14): _panel(root,Rect2(0,y,378,1),Color(color,.18))

func _nav(root: Control, kind: String, label: String, callback: Callable, rect: Rect2 = Rect2(7,5,40,44), color: Color = Color.TRANSPARENT, ink: Color = INK) -> Button:
	var button = _button(root,"‹" if kind=="back" else "×",rect,callback,color,ink,0,Color.TRANSPARENT)
	button.name = "PhoneNav_"+kind
	button.tooltip_text = label
	button.set_meta("phone_nav_kind",kind)
	button.set_meta("phone_nav_label",label)
	button.add_theme_font_size_override("font_size",30)
	for mode in ["normal","pressed"]: button.add_theme_stylebox_override(mode,_style(color))
	button.add_theme_stylebox_override("hover",_style(Color(ink,.06)))
	button.add_theme_stylebox_override("focus",_style(Color.TRANSPARENT,Color("1975dc"),0,2))
	button.z_index = 4
	return button

func _return_zjuding(page: String = "hub") -> void:
	zjuding_page=page; zjuding_panel=""; zjuding_overlay=""
	page_requested.emit("zjuding")

func _header(root: Control, title: String, color: Color = Color.WHITE, ink: Color = INK, back: Callable = Callable(), kind: String = "back", label: String = "返回手机主页") -> void:
	_panel(root,Rect2(0,0,378,54),color)
	_nav(root,kind,label,back if back.is_valid() else func(): page_requested.emit("phone_home"),Rect2(7,5,40,44),color,ink)
	var heading=_label(root,title,Rect2(50,5,278,44),16,ink,HORIZONTAL_ALIGNMENT_CENTER)
	heading.autowrap_mode=TextServer.AUTOWRAP_OFF; heading.clip_text=true; heading.text_overrun_behavior=TextServer.OVERRUN_TRIM_ELLIPSIS
	_label(root,"···",Rect2(333,8,37,38),22,ink,HORIZONTAL_ALIGNMENT_CENTER)
	_panel(root,Rect2(0,53,378,1),Color("d5dae0"))

func _opening_base() -> Control:
	var root:=_base(Color("fff6df"),761.4)
	var gradient:=Gradient.new()
	gradient.offsets=PackedFloat32Array([0,.52,1])
	gradient.colors=PackedColorArray([Color("fff6df"),Color("fff0cc"),Color("fff7e2")])
	var texture:=GradientTexture2D.new(); texture.gradient=gradient; texture.fill_from=Vector2.ZERO; texture.fill_to=Vector2.ONE
	var background:=TextureRect.new(); background.name="OpeningPaperGradient"; background.texture=texture; background.expand_mode=TextureRect.EXPAND_IGNORE_SIZE; background.mouse_filter=Control.MOUSE_FILTER_IGNORE; background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT); root.add_child(background)
	for x in range(0,424,14): _panel(root,Rect2(x/PHONE_SCALE,0,2/PHONE_SCALE,761.4),Color("fae7b9",.14))
	for y in range(0,854,14): _panel(root,Rect2(0,y/PHONE_SCALE,378,2/PHONE_SCALE),Color("fae7b9",.18))
	return root

func _opening_chip(root: Control,text: String,center: Vector2) -> Label:
	var font_size:=int(round(NativeUi.FONT_BODY/PHONE_SCALE))
	var width: float=PhoneNotice.FONT.get_string_size(text,HORIZONTAL_ALIGNMENT_LEFT,-1,font_size).x+24/PHONE_SCALE
	var height: float=PhoneNotice.FONT.get_height(font_size)+14/PHONE_SCALE
	var rect:=Rect2(center-Vector2(width,height)/2,Vector2(width,height))
	var panel:=_panel(root,rect,Color("fff8e2",.9),INK,0,2)
	var style: StyleBoxFlat=panel.get_theme_stylebox("panel"); style.shadow_color=Color("775c31",.25); style.shadow_offset=Vector2(2,2)/PHONE_SCALE
	return _label(root,text,rect,font_size,INK,HORIZONTAL_ALIGNMENT_CENTER)

func _opening_button(root: Control,text: String,rect: Rect2,id: String,kind: String) -> Button:
	var fill:=Color("c85454") if kind=="danger" else Color("fff6df") if kind=="paper" else Color("4d7ed9")
	var ink:=INK if kind=="paper" else Color("fff6df")
	var border:=Color("8f3535") if kind=="danger" else INK if kind=="paper" else Color("2c56a8")
	var button:=_act(root,text,rect,id,null,fill,ink,0,border)
	# Source .px-btn.big is18 logical pixels: nearest integer16 in378px art space.
	NativeUi.apply_button(button,fill,ink,border,0,2,int(round(NativeUi.FONT_TITLE/PHONE_SCALE)),Vector2.ZERO)
	for state: String in ["normal","hover","pressed","hover_pressed","disabled"]:
		var style: StyleBoxFlat=button.get_theme_stylebox(state)
		style.shadow_color=Color("775c31",.25)
		style.shadow_offset=Vector2(0,1 if state in ["pressed","hover_pressed"] else 4)/PHONE_SCALE
		if state=="pressed": style.bg_color=fill; style.border_color=border
		if state in ["hover","hover_pressed"]:
			style.bg_color=Color(minf(fill.r*1.12,1),minf(fill.g*1.12,1),minf(fill.b*1.12,1))
			style.border_color=Color(minf(border.r*1.12,1),minf(border.g*1.12,1),minf(border.b*1.12,1))
	button.add_theme_color_override("font_hover_color",Color(minf(ink.r*1.12,1),minf(ink.g*1.12,1),minf(ink.b*1.12,1)))
	button.add_theme_color_override("font_hover_pressed_color",button.get_theme_color("font_hover_color"))
	button.name="OpeningAction_"+id
	button.set_meta("source_css_class","px-btn "+kind+" big")
	# CSS :active moves the complete rendered control, including its hit area.
	button.button_down.connect(func(): button.position=rect.position+Vector2(0,3)/PHONE_SCALE)
	button.button_up.connect(func(): button.position=rect.position)
	return button

func _alarm() -> Control:
	var root = _opening_base()
	var bell:=OpeningPresentation.create_bell(root,Vector2(189,244.5),PHONE_SCALE)
	_opening_chip(root,"早八闹钟",Vector2(189,320)).name="AlarmLabel"
	OpeningPresentation.create_clock(root,Rect2(12,347,354,105),PHONE_SCALE)
	_label(root,"学在浙大签到还剩 5 分钟",Rect2(20,457,338,38),int(round(NativeUi.FONT_BODY/PHONE_SCALE)),INK,HORIZONTAL_ALIGNMENT_CENTER).name="AlarmSubtitle"
	var ringing = s.native.get("alarm_ringing",false)
	if ringing: OpeningPresentation.animate(root,bell,PHONE_SCALE)
	_opening_button(root,"关闭" if ringing else "开始游戏",Rect2(82,529,214,64),"c1_dismiss_alarm" if ringing else "c1_start_alarm","danger" if ringing else "primary")
	handled.append("c1_dismiss_alarm")
	return root

func _wake() -> Control:
	var root = _opening_base()
	root.set_meta("handles_app_grid",true)
	_label(root,"07:55",Rect2(Vector2(20,16)/PHONE_SCALE,Vector2(180,36)/PHONE_SCALE),int(round(NativeUi.FONT_DISPLAY/PHONE_SCALE))).name="WakeTime"
	_label(root,"ZJUWLAN · %s%%" % int(s.phoneBattery.percent),Rect2(Vector2(210,16)/PHONE_SCALE,Vector2(194,36)/PHONE_SCALE),NativeUi.font_size_for_scale(NativeUi.FONT_LABEL,PHONE_SCALE),INK,HORIZONTAL_ALIGNMENT_RIGHT).name="WakeNetwork"
	if not s.native.get("wake_warned",false):
		_opening_chip(root,"（我）",Vector2(189,303)).name="WakePlayerChip"
		_opening_button(root,"……再睡5分钟……",Rect2(45,338,288,72),"c1_wake","paper")
		var narration:=PhoneNotice.create("你没有5分钟了，但你很有勇气","旁白")
		narration.name="WakeNarration"; narration.position=Vector2(16,52)/PHONE_SCALE; narration.scale=Vector2.ONE/PHONE_SCALE
		root.add_child(narration); PhoneNotice.layout(narration,392)
	else:
		var flash = _label(root,"起床蠢货\n！！！",Rect2(15,245,348,180),53,Color("c85454"),HORIZONTAL_ALIGNMENT_CENTER)
		_animate_flash(root,flash)
		_opening_button(root,"进入手机主界面",Rect2(64,450,250,68),"c1_enter_home","primary")
	handled.append("c1_wake")
	return root

func _home_rect(x: float, y: float, w: float, h: float) -> Rect2:
	return Rect2(Vector2(x,y-40)/PHONE_SCALE,Vector2(w,h)/PHONE_SCALE)

func _home() -> Control:
	var root = _base(PAPER,643)
	root.set_meta("handles_app_grid",true)
	var artwork=HomeArt.new(); artwork.name="SourceHomeArtwork"; artwork.size=Vector2(378,APP_HEIGHT); artwork.tower_open=s.flags.towerOpened; artwork.flower_bloomed=s.flags.flowerBloomed; root.add_child(artwork)
	if s.actOne.phase=="prologue":
		var tower=_drop_action(root,_home_rect(288,116,66,330),"c1_tower"); tower.name="TowerDropTarget"; tower.disabled=s.native.get("tower_key_pending",false)
		if s.native.get("tower_key_pending",false) and s.items.towerKey and not s.flags.towerOpened: _animate_tower_key(root)
	var bonsai=_button(root,"",_home_rect(352,558,50,58),func(): page_requested.emit("bonsai"),Color.TRANSPARENT,INK,0,Color.TRANSPARENT); bonsai.name="HomeBonsaiOpen"; bonsai.tooltip_text="湖边盆栽，已开花" if s.flags.flowerBloomed else "湖边盆栽"
	for mode in ["normal","hover","pressed"]: bonsai.add_theme_stylebox_override(mode,_style(Color.TRANSPARENT))
	# Exact source widget geometry. Whole-card click has no extra visible button.
	var rain=not s.qizhenLake.rainSafetyCleared
	_panel(root,_home_rect(18,59,212,182),Color("775c31",.25))
	_panel(root,_home_rect(15,56,212,182),Color("fff8e2",.85),INK,0,2)
	var cloud=Polygon2D.new(); cloud.color=Color("bfd1db")
	var cloud_points=PackedVector2Array()
	for point in [[0,53],[13,53],[13,35],[27,35],[27,17],[40,17],[40,2],[63,2],[63,16],[78,16],[78,34],[92,34],[92,53],[100,53],[100,77],[0,77]]:
		cloud_points.append((Vector2(42,82)+Vector2(point[0]*.7,point[1]*.36)-Vector2(0,40))/PHONE_SCALE)
	cloud.polygon=cloud_points; root.add_child(cloud)
	if rain:
		for drop in [[59,129],[83,126],[97,135]]: _panel(root,_home_rect(drop[0],drop[1],6,12),Color("6aa8df"))
	_label(root,"小雨" if rain else "多云",_home_rect(119,77,84,27),16)
	_label(root,"18°C" if rain else "19°C",_home_rect(119,108,94,41),34)
	_label(root,"最高 20°C / 最低 15°C",_home_rect(37,160,177,21),12)
	_panel(root,_home_rect(37,190,168,2),Color("decfb4"))
	_label(root,"空气湿度 "+("88%" if rain else "76%"),_home_rect(37,201,105,22),11,Color("c85454"))
	_label(root,"西南风 2级",_home_rect(140,201,70,22),11,Color("c85454"),HORIZONTAL_ALIGNMENT_RIGHT)
	if s.actOne.phase!="prologue":
		var weather_target=_button(root,"",_home_rect(15,56,212,182),func(): page_requested.emit("weather"),Color.TRANSPARENT,INK,0,Color.TRANSPARENT)
		weather_target.name="HomeWeatherOpen"; weather_target.tooltip_text="打开天气"
		for mode in ["normal","hover","pressed"]: weather_target.add_theme_stylebox_override(mode,_style(Color.TRANSPARENT))
	elif rain and s.flags.codeScattered and not s.flags.waterDropTaken:
		var drop=_act(root,"",_home_rect(60,116,28,30),"c1_rain_drop",null,Color.TRANSPARENT,INK,0,Color.TRANSPARENT)
		_panel(drop,Rect2(10,4,8,14),Color("7db6ec")); drop.name="HomeLiveWaterDrop"; drop.tooltip_text="收集水滴"
	var chapter=int(s.native.get("chapter",1))
	_build_home_apps(root)
	if s.flags.gearFallen and not s.flags.gearNineTaken: _act(root,"✱ 9",Rect2(270,360,64,55),"c1_collect_gear",null,Color("575b65"),Color("f1d367"),18)
	var notifications=_home_notifications()
	var heights: Array=[]; var group_height=0
	for notice in notifications:
		var height=72 if str(notice.body).length()>26 else 56
		heights.append(height); group_height+=height
	group_height+=maxi(0,notifications.size()-1)*7
	var y=810-group_height
	for n in range(notifications.size()):
		var notice: Dictionary=notifications[n]
		var triangle_active=notice.id=="triangle" and s.actOne.phase in ["movement_required","reservation_briefing_required","reservation_required","movement_ready"] and s.actOne.exerciseStarted and not s.actOne.pushTriangleTaken
		var card: Control
		if triangle_active:
			card=_act(root,"",_home_rect(16,y,392,heights[n]),"c2_triangle",null,Color("fff8e2",.85),INK,0,INK); card.name="HomeTriangleNotification"
		elif not str(notice.get("route","")).is_empty():
			card=_button(root,"",_home_rect(16,y,392,heights[n]),func(): _home_open_notification(root,notice),Color("fff8e2",.85),INK,0,INK)
		else: card=_panel(root,_home_rect(16,y,392,heights[n]),Color("fff8e2",.85),INK,0,2)
		if not triangle_active: card.name="HomeNotification_"+str(notice.id)
		card.set_meta("notification_id",notice.id)
		var icon=_panel(card,Rect2(10,9,32,32),Color("61b58c") if notice.icon=="wechat" else Color("66bfe0") if notice.icon=="weather" else Color("ece9df") if notice.icon in ["photos","zjuding"] else Color("4d7ed9"),INK,0,2)
		match notice.icon:
			"zjuding": _image(icon,"ui/zjuding.png",Rect2(2,2,28,28))
			"cc98": _label(icon,"98",Rect2(1,1,30,30),13,Color.WHITE,HORIZONTAL_ALIGNMENT_CENTER)
			"recovery":
				for i in range(3): _panel(icon,Rect2(5,6+i*7,22-i*4,3),Color("d9f2e6"))
			"wechat": _panel(icon,Rect2(9,9,14,14),Color("eef8e0"),Color.TRANSPARENT,7)
			"photos":
				for petal in [[5,5,"e88a9f"],[17,5,"7fb0e8"],[5,17,"8fce7c"],[17,17,"e8a05f"]]: _panel(icon,Rect2(petal[0],petal[1],11,11),Color(petal[2]),Color.TRANSPARENT,5)
				_panel(icon,Rect2(12,12,9,9),Color("f5c542"),Color.TRANSPARENT,4)
			"weather":
				_panel(icon,Rect2(5,7,21,11),Color.WHITE); _panel(icon,Rect2(10,3,11,7),Color.WHITE)
				if rain:
					for x in [8,15,22]: _panel(icon,Rect2(x,21,3,6),Color("bfeaff"))
			_:
				if triangle_active: _label(icon,"▶",Rect2(1,1,30,30),21,Color.WHITE,HORIZONTAL_ALIGNMENT_CENTER)
				else: _panel(icon,Rect2(6,5,19,21),Color.TRANSPARENT,Color.WHITE,0,2)
		_label(card,"方向校准" if triangle_active else str(notice.title),Rect2(60,6,239,19),16)
		_label(card,"头像方向正确，正文方向未知。" if triangle_active else str(notice.body),Rect2(60,27,239,(heights[n]-30)/PHONE_SCALE),10,Color("8d7f66"))
		_label(card,str(notice.time),Rect2(299,6,41,18),10,Color("c85454"),HORIZONTAL_ALIGNMENT_RIGHT)
		y+=heights[n]+7
	# Source page dots remain decorative and cannot route or advance progression.
	for i in range(3): _panel(root,_home_rect(184+i*22,828,10,10),INK if i==0 else Color("c5c3b9"),INK,0,2)
	if s.qizhenLake.phase=="complete" and not s.chapterThreeInterlude.completed:
		var note=_button(root,"",_home_rect(12,48,400,62),func(): page_requested.emit("c35_recovery"),Color("fffdf4"),INK,0,INK); note.name="HomeInterludeTopNotice"
		_panel(note,Rect2(10,10,34,34),Color("4d7ed9"),INK,0,2)
		for i in range(3): _panel(note,Rect2(16,17+i*7,22-i*4,3),Color("d9f2e6"))
		_label(note,"记录恢复",Rect2(54,7,230,21),16)
		_label(note,"检测到 7 分 55 秒未同步记录",Rect2(54,30,268,19),10,MUTED)
		_label(note,"现在",Rect2(317,7,32,20),10,Color("c85454"))
	elif not s.flags.codeScattered or s.actOne.phase == "friend_message_required":
		var note = _page(root,"",Rect2(12,4,352,50),"wechat",Color("f6f2e7"))
		_app_icon(_panel(note,Rect2(10,8,34,34),Color("61b58c"),INK,4,1),"wechat",.7)
		_label(note,"朋友",Rect2(54,4,232,22),16)
		_label(note,"成功了吗" if s.actOne.phase=="friend_message_required" else "快快老师在点名，学在浙大。",Rect2(54,26,275,19),12,MUTED)

	return root

func _home_notification(id: String, title: String, body: String, time: String, icon: String, route: String="") -> Dictionary:
	return {"id":id,"title":title,"body":body,"time":time,"icon":icon,"route":route}

func _home_notifications() -> Array:
	# The source projection gives interlude priority and never reveals unresolved timestamps.
	var interlude: Dictionary=s.chapterThreeInterlude
	if s.qizhenLake.phase=="complete" and not interlude.completed:
		var start="22:37:05" if interlude.evidenceIds.has("journal_start") else "待恢复"
		var end="22:45:00" if interlude.evidenceIds.has("broadcast_end") else "待恢复"
		return [_home_notification("recovery","记录恢复","待核验时间窗：%s — %s" % [start,end] if interlude.recoveryOpened else "检测到 7 分 55 秒未同步记录。","22:45" if interlude.evidenceIds.has("broadcast_end") else "待恢复","recovery","c35_recovery"),_home_notification("network","校园网络","发现一条未归档的夜间接入记录。","22:42","wechat")]
	if interlude.completed and interlude.replayUnlocked:
		# Current thirteen-phase Chapter 4 has no legacy phone gate. Compatibility
		# notification projection below remains read-only and never creates an action.
		var rows: Array=[]; var objective=_home_chapter4_objective()
		if not objective.is_empty():
			if objective.id=="study_index": rows.append(_home_notification("study_index","CC98 · 学习天地","课程年份入口与旧自习讨论待导入","22:38","cc98","study_index"))
			else: rows.append(_home_notification("chapter_four_wechat","微信",objective.label,"22:47","wechat","wechat"))
		rows.append(_home_notification("chapter_four_photo","照片","IMG_0755 的识别结果仍需现场核验","22:46","photos"))
		return rows
	var third=s.ui.libraryFinalsPuzzle.nextQuestId=="chapter_three_canteen_hunt" or s.ui.libraryFinalsPhase=="friend_contacted" or s.canteenHunt.active or s.theaterHunt.active or s.qizhenLake.active
	if third:
		var rows: Array=[]; var ticket: Dictionary=s.theaterHunt; var phase=str(ticket.cc98TicketCommissionPhase)
		if phase!="locked":
			var message="现场帮抢委托待接" if phase=="posted" else "已接单，第一波待开始" if phase=="accepted" else "第一波未抢到：当前网速过慢，第二波即将开放" if phase=="first_wave_failed" else "第一波抢票成功，运气很好，钱包没那么好" if ticket.cc98TicketClaimedWave==1 else "08:32 第二波取票回执已同步"
			var time="08:31" if ticket.cc98TicketClaimedWave==1 else "08:29" if phase=="posted" else "08:30" if phase=="accepted" else "08:31" if phase=="first_wave_failed" else "08:32"
			rows.append(_home_notification("theater_ticket","CC98 · 学生剧《7:55》",message,time,"cc98","c3_ticket_post"))
		rows.append_array([_home_notification("overdue_book","图书馆","您有一本书已逾期 755 天","08:25","schedule"),_home_notification("shelf_reply","CC98","Re: 三楼书架是不是多了一层？","08:24","cc98"),_home_notification("new_photo","照片","新增照片「看不清的书脊」","08:23","photos")])
		return rows
	return [_home_notification("triangle","课程提醒","签到记录未更新。你本人仍未抵达。","07:50","schedule"),_home_notification("campus","浙大钉" if s.actOne.dormHubUnlocked else "学在浙大","校园地图已恢复访问，寝室入口可用。" if s.actOne.dormHubUnlocked else "课堂签到仍在等待四位代码。","07:45","zjuding"),_home_notification("weather","天气","小雨。局部黏着物可能松动。" if not s.qizhenLake.rainSafetyCleared else "多云。启真湖小码头降水已经停止。","07:35","weather","weather" if s.actOne.phase!="prologue" else "")]

func _home_chapter4_objective() -> Dictionary:
	var chapter: Dictionary=s.chapter4; var clues: Array=chapter.clueIds
	if not chapter.prologueSeen: return {}
	match chapter.phase:
		"elevator_track_sync":
			if not clues.has("wechat_official_notice_read"): return {"id":"official_notice","label":"查看校园后勤服务的夜间运行通知"}
			if chapter.elevatorHistoryObserved and not clues.has("wechat_elevator_audio_archived"): return {"id":"elevator_audio","label":"归档主电梯历史提示音"}
		"npc_schedule_route":
			if not clues.has("wechat_student_route_saved"):
				return {"id":"study_index","label":"从 CC98 导入学习天地资料索引"} if not clues.has("cc98_study_index_imported") else {"id":"student_route","label":"保存麦斯威夜间自习群的路线讨论"}
		"wayfinding_fragment_board":
			if clues.has("a3_old_signage_observed") or chapter.solvedPuzzleIds.has("wayfinding_fragment_board"):
				if not clues.has("wechat_wayfinding_photos_archived"): return {"id":"wayfinding_photos","label":"归档三楼新旧导视板照片"}
				if not clues.has("wechat_wayfinding_compared"): return {"id":"wayfinding_compare","label":"请朋友对照新旧导视板"}
	return {}

func _home_open_notification(root: Control, notice: Dictionary) -> void:
	if notice.route=="c3_ticket_post":
		var cellular=s.networkMode=="cellular" and s.theaterHunt.cc98TicketCommissionPhase in ["accepted","first_wave_failed","delivered"]
		if s.networkMode!="campus_wifi" and not cellular: _toast(root,"当前网络无法打开 CC98，请先恢复可访问的网络环境。"); return
	if notice.route=="study_index": cc98_post="chapter4-study-index"; page_requested.emit("cc98")
	else: page_requested.emit(notice.route)

func _build_home_apps(root: Control) -> void:
	var colors={"wechat":Color("61b58c"),"tiyi":Color("e8893f"),"zjuding":Color("539ccb"),"settings":Color("777989"),"photos":Color("eee5dd"),"timeline_recovery":Color("a0bdbd"),"voice_memos":Color("d89e96"),"cc98":Color("4d7ed9"),"control_center":Color("756aa9"),"clock":Color("e8e5db")}
	var order=Utilities.normalized_order(s.ui.homeAppOrder)
	var layout={"order":order.duplicate(),"buttons":{},"slots":{},"labels":{},"changed":false}
	var visible_index=0
	for id_value in order:
		var id=str(id_value)
		if id in s.ui.hiddenHomeAppIds and Utilities.can_remove(s,id): continue
		var index=visible_index; visible_index+=1
		var point=Vector2(20+(index%4)*72,252+int(index/4)*96)/PHONE_SCALE
		layout.slots[id]=point
		if not Utilities.app_available(s,id):
			# Locked slots have no icon, focus or pointer semantics in the source.
			_label(root,"xxx",Rect2(point,Vector2(48,73)),13,Color("5c6363"),HORIZONTAL_ALIGNMENT_CENTER).name="Locked_"+id
			continue
		var button=HomeButton.new()
		button.position=point; button.size=Vector2(48,48); button.name="HomeApp_"+id
		button.editable=s.actOne.phase!="prologue"; button.editing=home_editing
		for mode in ["normal","hover","pressed"]: button.add_theme_stylebox_override(mode,_style(colors[id],INK,0,2))
		button.add_theme_stylebox_override("focus",_style(Color.TRANSPARENT,Color("4caed2"),0,3))
		root.add_child(button)
		if id=="settings" and s.actOne.phase=="prologue":
			button.text="" if s.flags.gearFallen else "✱"; button.add_theme_font_size_override("font_size",35)
			if s.ui.autoRotate and not s.flags.gearFallen: _animate_rotation(root,button,"gear")
		else: _app_icon(button,id)
		var objective=_home_chapter4_objective() if s.chapterThreeInterlude.completed and s.chapterThreeInterlude.replayUnlocked else {}
		if not objective.is_empty() and ((objective.id=="study_index" and id=="cc98") or (objective.id!="study_index" and id=="wechat")):
			_panel(button,Rect2(37,-6,17,17),Color("d72e32"),Color.WHITE,0,2)
			_label(button,"1",Rect2(37,-6,17,17),10,Color.WHITE,HORIZONTAL_ALIGNMENT_CENTER)
		layout.buttons[id]=button
		layout.labels[id]=_label(root,Utilities.LABELS[id],Rect2(point+Vector2(-1,53.5),Vector2(50,16)),12,INK,HORIZONTAL_ALIGNMENT_CENTER)
		button.pressed.connect(func():
			if not button.can_activate(): return
			if id=="settings" and s.actOne.phase=="prologue": action_requested.emit("c1_gear",null)
			else: page_requested.emit({"timeline_recovery":"c35_recovery","voice_memos":"c35_voice"}.get(id,id)))
		button.editing_started.connect(func():
			home_focus_id=id
			home_editing=true
			for app in layout.buttons.values(): app.editing=true
			_home_edit_visuals(root,layout))
		button.dragged.connect(func(global_point: Vector2):
			var local_point=root.get_global_transform().affine_inverse()*global_point
			for other_id in layout.buttons:
				if other_id==id: continue
				var other: Button=layout.buttons[other_id]
				if Rect2(other.position,Vector2(48,73)).has_point(local_point):
					var old=button.position
					button.position=other.position; other.position=old
					layout.labels[id].position=button.position+Vector2(-1,53.5)
					layout.labels[other_id].position=other.position+Vector2(-1,53.5)
					var source_index=layout.order.find(id); var target_index=layout.order.find(other_id)
					layout.order[source_index]=other_id; layout.order[target_index]=id; layout.changed=true
					return)
		button.drag_finished.connect(func():
			if layout.changed: action_requested.emit("phone_home_order",layout.order.duplicate()))
		button.move_requested.connect(func(offset): home_focus_id=id; action_requested.emit("phone_app_move",{"id":id,"offset":offset,"from_home":true}))
		button.removal_requested.connect(func(): action_requested.emit("phone_app_remove",id))
		button.editing_finished.connect(func(): home_editing=false; action_requested.emit("phone_refresh",{}))
	if home_editing:
		_home_edit_visuals(root,layout)
		if layout.buttons.has(home_focus_id): root.ready.connect(func(): layout.buttons[home_focus_id].grab_focus())

func _home_edit_visuals(root: Control, layout: Dictionary) -> void:
	if root.has_node("HomeEditingDone"): return
	var done=_button(root,"完成",Rect2(287,16,70,37),func(): home_editing=false; action_requested.emit("phone_refresh",{}),Color("fff5df"))
	done.name="HomeEditingDone"; done.z_index=10
	for id in layout.buttons:
		var button: Button=layout.buttons[id]
		button.pivot_offset=button.size/2
		if root.is_inside_tree():
			var wiggle=button.create_tween().set_loops()
			wiggle.tween_property(button,"rotation",-.035,.13)
			wiggle.tween_property(button,"rotation",.035,.13)
		if Utilities.can_remove(s,id):
			var remove=_act(button,"−",Rect2(-8,-9,25,25),"phone_app_remove",id,Color("c2534d"),Color.WHITE,12)
			remove.name="Remove_"+str(id)

func _wechat(_view: Dictionary) -> Control:
	if friend_open: return _friend_chat()
	var root=_base(Color("ededed"),APP_HEIGHT)
	_panel(root,Rect2(0,0,378,47),Color("f7f7f7"),Color("d6d6d6"),0,1)
	_nav(root,"exit","退出微信，返回手机主页",func(): page_requested.emit("phone_home"),Rect2(7,1,40,44),Color("f7f7f7"))
	_label(root,"聊天(4)",Rect2(54,5,270,37),16,INK,HORIZONTAL_ALIGNMENT_CENTER)
	_label(root,"⌕ ⊕",Rect2(325,9,45,29),14,INK,HORIZONTAL_ALIGNMENT_RIGHT)
	_panel(root,Rect2(0,47,378,33),Color("f2f2f2"),Color("e0e0e0"),0,1)
	_label(root,"已登录 2 台设备 ›",Rect2(14,53,350,21),12,Color("666666"))
	var preview="你到底到哪了？" if lake_apps.active(s) else "成功了吗" if s.actOne.phase=="friend_message_required" else "这是签到码 ▓▓▓▓" if s.flags.codeScattered else "快快老师在点名，学在浙大"
	var movement=s.actOne.phase in ["movement_required","reservation_briefing_required","reservation_required","movement_ready"]
	var rows=[["文件传输助手","[图片]","09:28",Color("10af42")],["朋友",preview,"07:55",Color("a9c5e8")],["室友","晚上一起去食堂吃饭呀~","07:21",Color("72bb50")],["导师","头像框中间多了一条被封住的竖线。" if movement and not s.actOne.mentorLineReleased else "请把实验报告的初稿发我一下。","07:18",Color("9c80d8")]]
	for i in range(4):
		var row: Array=rows[i]; var index=i; var y=80+i*70
		var button=_button(root,"",Rect2(0,y,378,70),func():
			if index==1:
				friend_open=true
				action_requested.emit("c1_friend" if s.actOne.phase=="prologue" and not s.flags.codeScattered else "phone_refresh",null)
			else: _toast(root,["文件传输助手：只有你给自己发的表情包。","","室友：还有 12 秒进入梦乡最深处。","导师：实验报告仍然不会自己完成。"][index]),Color.WHITE,INK,0,Color.TRANSPARENT)
		button.name="WechatRow_"+str(index)
		_panel(button,Rect2(0,69,378,1),Color("ececec"))
		var avatar=_panel(button,Rect2(12,10,47,47),row[3],Color("6d7b80"),0,2)
		if i==0:
			_panel(avatar,Rect2(11,13,23,20),Color.WHITE)
			var triangle=Polygon2D.new(); triangle.position=Vector2(19,17); triangle.polygon=PackedVector2Array([Vector2(0,0),Vector2(8,5),Vector2(0,10)]); triangle.color=row[3]; avatar.add_child(triangle)
		elif i==1:
			if not s.flags.slashTaken:
				var slash=_panel(avatar,Rect2(21,6,5,35 if not s.flags.slashHalfDropped else 20),Color("16273f")); slash.pivot_offset=Vector2(2.5,17.5); slash.rotation=deg_to_rad(38)
				if s.flags.slashHalfDropped:
					var hanging=_panel(avatar,Rect2(7,40,5,18),Color("16273f"))
					root.ready.connect(func():
						var swing=hanging.create_tween().set_loops(); swing.tween_property(hanging,"rotation",deg_to_rad(-14),.5); swing.tween_property(hanging,"rotation",deg_to_rad(10),.5))
			var target=_button(button,"",Rect2(12,10,47,47),func():
				if not s.flags.codeScattered or s.flags.slashTaken:
					friend_open=true
					action_requested.emit("c1_friend" if s.actOne.phase=="prologue" and not s.flags.codeScattered else "phone_refresh",null)
				else: action_requested.emit("c1_avatar",null),Color.TRANSPARENT,INK,0,Color.TRANSPARENT); target.name="WechatFriendAvatar"
			for mode in ["normal","pressed","hover"]: target.add_theme_stylebox_override(mode,_style(Color.TRANSPARENT))
		elif i==2: _panel(avatar,Rect2(11,11,23,23),Color.TRANSPARENT,Color("264b2d"),0,4)
		elif not s.actOne.mentorLineReleased:
			_panel(avatar,Rect2(20,6,5,31),Color("2c2440"))
			if movement:
				_panel(avatar,Rect2(13,7,19,5),Color("cbc4d8"),Color("554963"),0,1)
				_panel(avatar,Rect2(13,33,19,5),Color("cbc4d8"),Color("554963"),0,1)
				_drop_action(button,Rect2(12,10,47,47),"c2_mentor").name="WechatMentorAvatar"
		_label(button,row[0],Rect2(74,12,249,26),16)
		var caption=_label(button,row[1],Rect2(74,42,242,20),12,Color("8a8a8a"))
		caption.autowrap_mode=TextServer.AUTOWRAP_OFF; caption.clip_text=true; caption.text_overrun_behavior=TextServer.OVERRUN_TRIM_ELLIPSIS
		_label(button,row[2],Rect2(323,14,43,18),10,Color("999999"),HORIZONTAL_ALIGNMENT_RIGHT)
	if s.ui.autoRotate and s.actOne.phase=="prologue" and s.flags.codeScattered and not s.flags.slashHalfDropped: _animate_rotation(root,root,"slash")
	_panel(root,Rect2(0,APP_HEIGHT-55,378,55),Color("f7f7f7"),Color("d6d6d6"),0,1)
	for i in range(4):
		var color=Color("429355") if i==0 else Color("333333")
		var icon=_panel(root,Rect2(38+i*94.5,APP_HEIGHT-46,18,18),color if i==0 else Color.TRANSPARENT,color,9 if i in [1,2] else 1,2)
		_label(root,["聊天","联系人","发现","我的"][i],Rect2(i*94.5,APP_HEIGHT-22,94.5,17),10,color,HORIZONTAL_ALIGNMENT_CENTER)
	handled.append("c1_friend"); handled.append("c2_friend_exchange")
	return root

func _friend_chat() -> Control:
	var root=_base(Color("ededed"),620)
	_panel(root,Rect2(0,0,378,57),Color("f7f7f7"))
	_button(root,"‹",Rect2(9,9,38,38),func(): friend_open=false; lake_apps.friend_closed(); action_requested.emit("c1_friend_cancel" if s.actOne.phase=="prologue" else "phone_refresh",null),Color("f7f7f7"),INK,0,Color.TRANSPARENT).name="FriendChatBack"
	_label(root,"朋友",Rect2(59,9,239,38),23)
	_label(root,"…",Rect2(331,9,33,38),26)
	_panel(root,Rect2(16,83,40,40),Color("d5ba8b"),Color("a6a6a6"),3,1)
	_label(root,"/",Rect2(16,83,40,40),27,Color("644845"),HORIZONTAL_ALIGNMENT_CENTER)
	_panel(root,Rect2(68,80,287,58),Color.WHITE,Color("d4d8d4"),3,1)
	_label(root,"快快老师在点名，学在浙大。",Rect2(79,87,263,43),18)
	var message=Control.new(); message.size=Vector2(378,86); message.position=Vector2(0,157); root.add_child(message)
	_panel(message,Rect2(16,3,40,40),Color("d5ba8b"),Color("a6a6a6"),3,1)
	_label(message,"/",Rect2(16,3,40,40),27,Color("644845"),HORIZONTAL_ALIGNMENT_CENTER)
	_panel(message,Rect2(68,0,287, 70.0),Color.WHITE,Color("d4d8d4"),3,1)
	_label(message,"这是签到码",Rect2(80,7,245,27),18)
	var digits: Array=[]
	for i in range(4):
		var digit=_label(message,"▓",Rect2(81+i*34,37,28,28),22,INK,HORIZONTAL_ALIGNMENT_CENTER)
		digits.append(digit)
	if s.flags.codeScattered:
		for digit in digits: digit.text="▢"; digit.modulate=Color("bbbbbb")
		if s.actOne.phase=="prologue":
			_label(root,"任务：找回四位签到码",Rect2(20,290,338,50),19,Color("5d4407"),HORIZONTAL_ALIGNMENT_CENTER)
		else:
			_panel(root,Rect2(16,261,40,40),Color("d5ba8b"),Color("a6a6a6"),3,1)
			_panel(root,Rect2(68,259,138,49),Color.WHITE,Color("d4d8d4"),3,1)
			_label(root,"成功了吗",Rect2(81,265,112,36),19)
			var reply=_panel(root,Rect2(70,340,285,68),Color("a7e775"),Color("89be69"),3,1)
			_label(reply,"没有，但我正试着威胁系统",Rect2(13,7,259,54),18)
			var question=_panel(root,Rect2(68,441, 70,49),Color.WHITE,Color("d4d8d4"),3,1)
			_label(question,"？",Rect2(8,6,54,36),22)
			if s.actOne.phase=="friend_message_required":
				reply.visible=false; question.visible=false
				root.ready.connect(func():
					var tween=root.create_tween(); tween.tween_interval(.7)
					tween.tween_callback(func(): reply.visible=true)
					tween.tween_interval(.85); tween.tween_callback(func(): question.visible=true)
					tween.tween_interval(.6); tween.tween_callback(func(): action_requested.emit("c2_friend_exchange",null)))
			else: _label(root,"任务：找到系统",Rect2(20,534,338,48),19,Color("5d4407"),HORIZONTAL_ALIGNMENT_CENTER)
	else:
		message.visible=false
		var burst=_panel(root,Rect2(13,280,352,206),Color("100d13"),Color("74232c"),0,2)
		burst.visible=false
		_panel(burst,Rect2(158,14,36,36),Color("3a0d10"),Color("d43a3a"),18,8)
		_label(burst,"等等等等，你想翘课？没门！",Rect2(12,62,328,59),23,Color("ff7070"),HORIZONTAL_ALIGNMENT_CENTER)
		_label(burst,"我不会让你签上的！",Rect2(12,123,328,29),19,Color.WHITE,HORIZONTAL_ALIGNMENT_CENTER)
		var laugh=_label(burst,"找你的数字去吧哈哈哈",Rect2(12,163,328,31),19,Color("ffb1b1"),HORIZONTAL_ALIGNMENT_CENTER); laugh.visible=false
		var skip=_button(root,"",Rect2(0,60,378,560),func(): entry_session.skip_friend(),Color.TRANSPARENT,Color.TRANSPARENT,0,Color.TRANSPARENT)
		skip.name="FriendAttackSkip"; skip.mouse_filter=Control.MOUSE_FILTER_IGNORE; skip.focus_mode=Control.FOCUS_NONE
		for mode in ["normal","hover","pressed","focus"]: skip.add_theme_stylebox_override(mode,_style(Color.TRANSPARENT))
		message.name="FriendCodeMessage"; burst.name="FriendAttackBurst"; laugh.name="FriendAttackLaugh"
		EntryVisual.bind_friend(root,entry_session,message,burst,laugh,digits,skip,PHONE_SCALE)

	handled.append("c1_friend"); handled.append("c1_avatar"); handled.append("c2_friend_exchange")
	lake_apps.append_friend(self,root)
	return root

func _conversation(_view: Dictionary) -> Control:
	if entry_session.family=="zjuding" and entry_session.phase!="ready": return _entry_loading("zjuding")
	# The source system conversation is a modal over the hub, advanced one line at a time.
	var saved_panel=zjuding_panel; var saved_page=zjuding_page; var saved_overlay=zjuding_overlay
	zjuding_panel=""; zjuding_page="hub"; zjuding_overlay=""
	var root = _zjuding()
	zjuding_panel=saved_panel; zjuding_page=saved_page; zjuding_overlay=saved_overlay
	var source: Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://data/source/act-one-bootstrap.content.json"))
	var cues=["act2_system_found_intro","","act2_system_inventory_demand","act2_system_inventory_missing","act2_system_just_find_it"]
	var texts=["","拜托了，帮我改一下签到记录","","",""]
	var completion="c2_confront_system"
	var inventory_ready=s.actOne.phase=="system_required" and s.actOne.inventoryRecovered and s.items.campusCard
	if inventory_ready:
		cues=["act2_system_found_intro","","act2_system_inventory_demand","act2_system_move_now"]
		texts=["","拜托了，帮我改一下签到记录","","先把校园卡收好。寝室里的人还需要找到移动方法。"]
	elif s.actOne.phase=="system_return_required":
		cues=["act2_system_departure","","act2_system_confession","act2_system_friend","act2_system_library","act2_system_move_now"]
		texts=["","？","","","",""]; completion="c2_movement_quest"
	elif s.actOne.phase=="reservation_briefing_required":
		cues=["","","",""]
		texts=["别打扰我……哦，你已经完事了，速度还挺快的","我以为你要在寝室“就再睡一会儿”呢","你知道的，去图书馆要先完成座位预约。","基础馆一层书库022，记住了。"]
		completion="c2_reservation_briefing"
	for i in range(cues.size()):
		if texts[i].is_empty() and not str(cues[i]).is_empty(): texts[i]=source.audioNarration[cues[i]].subtitleZh
	var layer=_button(root,"",Rect2(0,0,378,APP_HEIGHT),func(): pass,Color(0,0,0,.48),Color.WHITE,0,Color.TRANSPARENT)
	layer.name="SystemDialogueAdvance"; layer.z_index=20; layer.tooltip_text="系统对话，点击任意位置继续"
	for mode in ["normal","hover","pressed","focus"]: layer.add_theme_stylebox_override(mode,_style(Color(0,0,0,.48)))
	var box=_panel(layer,Rect2(16,APP_HEIGHT-185,346,118),Color("0d1116"),Color("ff6575"),0,4)
	var speaker=_label(box,"系统",Rect2(14,7,283,27),16,Color("ff6575"))
	var copy=_label(box,"",Rect2(14,37,289,68),18,Color.WHITE)
	_label(box,"▼",Rect2(305,75,26,26),18,Color("ff6575"))
	var dialogue={"index":0,"done":false}
	var present=func():
		var index=int(dialogue.index)
		speaker.text="我" if index==1 and completion!="c2_reservation_briefing" else "系统"
		copy.text=texts[index]
		if not str(cues[index]).is_empty(): presentation_requested.emit(str(cues[index]))
		box.modulate.a=0
		var tween=root.create_tween(); tween.tween_property(box,"modulate:a",1.0,.44)
	layer.pressed.connect(func():
		if dialogue.done: return
		if dialogue.index+1<texts.size(): dialogue.index+=1; present.call()
		else:
			dialogue.done=true; layer.disabled=true
			presentation_requested.emit("act2_system_dialogue_closed")
			action_requested.emit(completion,null)
			if inventory_ready: action_requested.emit("c2_movement_quest",null)
			elif completion!="c2_movement_quest": page_requested.emit("zjuding"))
	root.ready.connect(func(): layer.grab_focus(); present.call())
	handled.append("c2_confront_system"); handled.append("c2_movement_quest"); handled.append("c2_reservation_briefing")
	root.set_meta("handles_all_actions",true)
	return root

func _controls() -> Control:
	# Source ControlCenter is an overlay over the entire 424×854 phone interior.
	var height=854.0/PHONE_SCALE
	var root=_base(Color(20/255.0,18/255.0,14/255.0,.45),height)
	root.set_meta("source_overlay",true)
	var close=func():
		control_reset_confirm=false
		action_requested.emit("native_control_center_close",null)
	var backdrop=_button(root,"",Rect2(0,0,378,height),close,Color.TRANSPARENT,INK,0,Color.TRANSPARENT)
	backdrop.name="ControlCenterBackdrop"
	for mode in ["normal","hover","pressed","focus"]: backdrop.add_theme_stylebox_override(mode,_style(Color.TRANSPARENT))
	var panel_height=580.0+(53 if control_reset_confirm else 0)+(21 if int(s.phoneBattery.percent)==1 else 0)
	var panel=_panel(root,Rect2(0,0,378,panel_height),Color("e9e5da"),INK,0,2)
	panel.mouse_filter=Control.MOUSE_FILTER_STOP; panel.name="ControlCenterPanel"
	_label(panel,"7月9日 周四",Rect2(14,13,260,27),16)
	var close_button=_nav(panel,"close","收起控制中心",close,Rect2(337,12,27,27),PAPER)
	close_button.add_theme_font_size_override("font_size",16)
	var network=str(s.networkMode)
	for i in range(2):
		var active=(network=="campus_wifi" if i==0 else network=="cellular")
		var button=_act(panel,"",Rect2(14+i*180,51,170,56),"c1_network","校园网" if i==0 else "移动数据",Color("4d7ed9") if active else Color("cfd3d9"),Color.WHITE if active else INK,0,INK)
		button.name="ControlNetwork_"+("wifi" if i==0 else "cellular")
		_panel(button,Rect2(9,10,34,34),Color.WHITE,INK,0,2)
		if i==0:
			_label(button,"≋",Rect2(11,8,30,25),26,INK,HORIZONTAL_ALIGNMENT_CENTER)
			_panel(button,Rect2(24,33,5,5),INK)
		else:
			for bar in range(4): _panel(button,Rect2(15+bar*5,34-bar*4,3,5+bar*4),INK)
		_label(button,"ZJUWLAN" if i==0 else "移动数据",Rect2(50,12,115,19),12,Color.WHITE if active else INK)
		_label(button,("已连接" if active else "未连接") if i==0 else ("使用中" if active else "已关闭"),Rect2(50,33,115,14),10,Color.WHITE if active else MUTED)
	var music=_panel(panel,Rect2(14,117,284,104),Color("cfd3d9"),INK,0,2)
	_source_icon(music,"music",Rect2(11,9,27,27))
	_label(music,"正在播放：早八进行曲" if s.ui.musicPlaying else "未在播放",Rect2(47,12,225,25),12)
	_act(music,"❚❚" if s.ui.musicPlaying else "▶",Rect2(12,51,49,40),"c1_music",null,INK,PAPER,0,INK).name="ControlMusicPlay"
	if not s.flags.headphoneFallen:
		var headphones=_button(music,"",Rect2(74,51,42,40),func(): pass,Color.TRANSPARENT,INK,0,Color.TRANSPARENT)
		headphones.name="ControlHeadphones"; headphones.tooltip_text="耳机"
		_source_icon(headphones,"headphone",Rect2(5,4,29,29))
		if s.ui.musicPlaying:
			root.ready.connect(func():
				var wobble=headphones.create_tween().set_loops(); headphones.pivot_offset=headphones.size/2
				wobble.tween_property(headphones,"rotation",deg_to_rad(-6),.11); wobble.tween_property(headphones,"rotation",deg_to_rad(7),.11))
		headphones.pressed.connect(func():
			if not s.ui.musicPlaying: action_requested.emit("c1_headphone",null); return
			if headphones.disabled: return
			headphones.disabled=true
			presentation_requested.emit("headphone_drop_started")
			var fall=root.create_tween(); fall.tween_property(headphones,"position:y",headphones.position.y+220/PHONE_SCALE,.55)
			fall.parallel().tween_property(headphones,"modulate:a",0.0,.55)
			fall.tween_callback(func(): action_requested.emit("c1_headphone",null)))
	else: _label(music,"耳机不见了",Rect2(76,60,153,25),10,MUTED)
	handled.append("c1_headphone")
	var slider=Control.new(); slider.position=Vector2(307,117); slider.size=Vector2(57,104); slider.focus_mode=Control.FOCUS_ALL; slider.mouse_default_cursor_shape=Control.CURSOR_VSIZE; slider.name="ControlBrightness"; slider.tooltip_text="亮度"; panel.add_child(slider)
	_panel(slider,Rect2(0,0,57,104),Color("b8bcc4"),INK,0,2)
	var fill=_panel(slider,Rect2(2,2+(100-float(s.ui.brightness))*1.0,53,float(s.ui.brightness)),Color("f5c542"))
	_source_icon(slider,"sun",Rect2(17,72,23,23))
	var brightness={"held":false,"value":float(s.ui.brightness)}
	var update=func(y: float):
		brightness.value=clampf(round(100*(1-y/104.0)),0,45 if s.phoneBattery.lowPowerMode else 100)
		fill.position.y=102-brightness.value; fill.size.y=brightness.value
		slider.tooltip_text="亮度 %d%%" % int(brightness.value)
	slider.gui_input.connect(func(event):
		if event is InputEventMouseButton and event.button_index==MOUSE_BUTTON_LEFT:
			if event.pressed: brightness.held=true; slider.grab_focus(); update.call(event.position.y)
			elif brightness.held: brightness.held=false; update.call(event.position.y); action_requested.emit("c1_brightness",brightness.value)
			slider.accept_event()
		elif event is InputEventMouseMotion and brightness.held: update.call(event.position.y); slider.accept_event()
		elif event is InputEventKey and event.pressed and event.keycode in [KEY_UP,KEY_DOWN]:
			var value=clampf(brightness.value+(10 if event.keycode==KEY_UP else -10),0,45 if s.phoneBattery.lowPowerMode else 100)
			brightness.value=value; update.call(104*(1-value/100)); action_requested.emit("c1_brightness",value); slider.accept_event())
	handled.append("c1_brightness")
	var toggle_data=[["⟳","自动旋转",""],["≋","振动","振动一直开着。它见证了闹钟的一切。"],["✈","飞行模式","飞行模式？你连教室都飞不到。"],["☾","勿扰","勿扰模式无法阻挡早八。"]]
	for i in range(4):
		var data: Array=toggle_data[i]
		var button=_button(panel,"",Rect2(14+i*90,232,80,66),func():
			if data[1]=="自动旋转": action_requested.emit("c1_auto_rotate",null)
			else: _toast(root,data[2]),Color.TRANSPARENT,INK,0,Color.TRANSPARENT)
		button.name="ControlToggle_"+str(i)
		_panel(button,Rect2(19,0,43,43),Color("f5c542") if (i==0 and s.ui.autoRotate) or i==1 else Color("cfd3d9"),INK,0,2)
		_label(button,data[0],Rect2(19,0,43,43),22,INK,HORIZONTAL_ALIGNMENT_CENTER)
		_label(button,data[1],Rect2(0,48,80,18),12,INK,HORIZONTAL_ALIGNMENT_CENTER)
	handled.append("c1_auto_rotate")
	var critical=int(s.phoneBattery.percent)<=5
	var power=_panel(panel,Rect2(14,313,350,141+(21 if int(s.phoneBattery.percent)==1 else 0)),Color("edd2cf") if critical else Color("d8eadb") if s.phoneBattery.lowPowerMode else Color("d9dde2"),INK,0,2)
	_label(power,"电池 %d%%" % int(s.phoneBattery.percent),Rect2(9,8,267,20),13)
	_label(power,"打开应用：%s%% / 次" % (1 if s.phoneBattery.lowPowerMode else 2),Rect2(9,30,267,17),10,MUTED)
	_panel(power,Rect2(305,10,35,28),Color("c85454") if critical else Color("2d7a52"),INK,0,2)
	_label(power,"BAT",Rect2(305,10,35,28),9,Color.WHITE,HORIZONTAL_ALIGNMENT_CENTER)
	_panel(power,Rect2(9,55,332,12),Color("f4f0e7"),INK,0,2)
	_panel(power,Rect2(11,57,maxf(2,328*float(s.phoneBattery.percent)/100),8),Color("c85454") if critical else Color("2d7a52"))
	var low_power=_act(power,"",Rect2(9,76,332,35),"phone_low_power",null,Color("f5c542") if s.phoneBattery.lowPowerMode else PAPER,INK,0,INK); low_power.name="LowPowerToggle"
	_label(low_power,"关闭低电量模式" if s.phoneBattery.lowPowerMode else "开启低电量模式",Rect2(8,6,167,25),12)
	_label(low_power,"恢复每次 2% 耗电" if s.phoneBattery.lowPowerMode else "每次只耗 1%；亮度限至 45%，暂停音乐",Rect2(169,3,155,29),8,MUTED,HORIZONTAL_ALIGNMENT_RIGHT)
	_label(power,"剧场入口左侧设有充电服务站，需走到设备旁接线。" if s.get("rpgScene","")=="theater_interior" else "充电需要在现场与充电服务站交互。",Rect2(9,118,332,18),10)
	if int(s.phoneBattery.percent)==1: _label(power,"电量仅剩 1%，请寻找现场充电服务站。",Rect2(9,139,332,18),10,Color("7a241f"))
	var save_y=467+(21 if int(s.phoneBattery.percent)==1 else 0)
	var saves=_panel(panel,Rect2(14,save_y,350,95+(53 if control_reset_confirm else 0)),Color("cfd3d9"),INK,0,2)
	_label(saves,"游戏进度",Rect2(9,8,267,20),13)
	_label(saves,"自动保存已开启",Rect2(9,30,267,17),10,MUTED)
	_panel(saves,Rect2(299,10,41,28),Color("1e5da8"),INK,0,2)
	_label(saves,"SAVE",Rect2(299,10,41,28),9,Color.WHITE,HORIZONTAL_ALIGNMENT_CENTER)
	if control_reset_confirm:
		_label(saves,"将清除章节、道具和谜题进度。编辑过的 CC98 帖子会保留。",Rect2(9,55,332,44),12,Color("5d2424"))
		_button(saves,"取消",Rect2(9,107,162,31),func(): control_reset_confirm=false; action_requested.emit("phone_refresh",{}),PAPER).name="ControlResetCancel"
		_act(saves,"确认重置",Rect2(179,107,162,31),"native_reset_progress",null,Color("b64b4b"),Color.WHITE,0).name="ControlResetConfirm"
	else:
		_act(saves,"立即保存",Rect2(9,56,162,31),"native_save_now",null,PAPER).name="ControlSaveNow"
		_button(saves,"重置剧情进度",Rect2(179,56,162,31),func(): control_reset_confirm=true; action_requested.emit("phone_refresh",{}),Color("b64b4b"),Color.WHITE,0).name="ControlResetOpen"
	for button in [saves.get_node_or_null("ControlSaveNow"),saves.get_node_or_null("ControlResetOpen"),saves.get_node_or_null("ControlResetCancel"),saves.get_node_or_null("ControlResetConfirm")]:
		if button: button.add_theme_font_size_override("font_size",12)
	return root

func _source_icon(root: Control, id: String, rect: Rect2) -> Control:
	var icon=PhoneChrome.PixelIcon.new()
	icon.pixels=PhoneChrome.PIXEL_ICONS.get(id,{})
	icon.position=rect.position; icon.size=rect.size; root.add_child(icon)
	return icon

func _toast(root: Control, text: String) -> void:
	var previous=root.get_node_or_null("SourceToast")
	if previous: previous.free()
	var toast=_panel(root,Rect2(24,55,330,66),Color(.10,.12,.14,.95),Color("d2c89c"),1,2)
	toast.name="SourceToast"; toast.z_index=30
	_label(toast,text,Rect2(10,8,310,50),14,Color.WHITE,HORIZONTAL_ALIGNMENT_CENTER)
	var tween=root.create_tween(); tween.tween_interval(2.2); tween.tween_callback(toast.queue_free)

func _checkin() -> Control:
	return checkin_page.build(self)

func _campus_card() -> Control:
	# P04 is CSS-authored: its crest and portrait are shapes, not a missing raster.
	# Coordinates below preserve p04-campus-card.css inside the 424×854 source frame.
	var root=_base(Color("eef0f6"),APP_HEIGHT)
	_panel(root,_home_rect(0,40,424,108),Color("2c56a8"))
	for x in range(0,424,12): _panel(root,_home_rect(x,40,2,814),Color(.08,.18,.47,.04))
	for y in range(40,854,12): _panel(root,_home_rect(0,y,424,2),Color(.08,.18,.47,.05))
	for i in range(4):
		var x=54+i*97
		_panel(root,_home_rect(x,94,26,26),Color.TRANSPARENT,Color.WHITE,12 if i==2 else 3 if i==1 else 0,3)
		if i==3: _panel(root,_home_rect(x,113,26,7),Color.WHITE)
		_label(root,["扫一扫","付款码","卡片充值","卡包"][i],_home_rect(18+i*97,126,97,20),12,Color.WHITE,HORIZONTAL_ALIGNMENT_CENTER)
	_panel(root,_home_rect(17,164,396,260),Color(.04,.08,.20,.45))
	var card=_panel(root,_home_rect(14,161,396,260),Color("1d3f8f"),Color("0e2257"),0,2); card.name="CampusCardPlate"; card.clip_contents=true
	var gradient=Gradient.new(); gradient.offsets=PackedFloat32Array([0,.68,1]); gradient.colors=PackedColorArray([Color("2a53b0"),Color("1d3f8f"),Color("1d3f8f")])
	var gradient_texture=GradientTexture2D.new(); gradient_texture.gradient=gradient; gradient_texture.width=396; gradient_texture.height=260; gradient_texture.fill_from=Vector2(.17,0); gradient_texture.fill_to=Vector2(.83,1)
	var gradient_view=TextureRect.new(); gradient_view.name="CampusCardGradient"; gradient_view.expand_mode=TextureRect.EXPAND_IGNORE_SIZE; gradient_view.texture=gradient_texture; gradient_view.position=Vector2(2,2)/PHONE_SCALE; gradient_view.size=Vector2(392,256)/PHONE_SCALE; gradient_view.mouse_filter=Control.MOUSE_FILTER_IGNORE; card.add_child(gradient_view)
	_panel(root,_home_rect(30,177,30,30),Color("dfe9ff"),Color.WHITE,15,2)
	_panel(root,_home_rect(40,187,10,10),Color.WHITE,Color.TRANSPARENT,5)
	_label(root,"浙江大学",_home_rect(70,182,106,24),16,Color("f2f6ff"))
	_label(root,"ZHEJIANG UNIVERSITY",_home_rect(188,189,205,16),8,Color("c7d5ee"))
	_panel(root,_home_rect(30,218,364,2),Color(1,1,1,.25))
	# Pixel portrait proportions, eyes and hoodie ties follow the original CSS.
	_panel(root,_home_rect(30,232,96,118),Color("7ea4e0"),Color("cfdcf5"),0,3)
	_panel(root,_home_rect(49,247,56,34),Color("3a2c22"))
	_panel(root,_home_rect(57,265,40,34),Color("f2c9a0"))
	for x in [64,86]: _panel(root,_home_rect(x,279,5,5),Color("2c2118"))
	_panel(root,_home_rect(41,297,72,52),Color("2f5fb3"))
	_panel(root,_home_rect(41,297,72,3),Color("244b8f"))
	for x in [67,81]: _panel(root,_home_rect(x,306,4,20),Color.WHITE)
	var identity=s.actOne.inventoryRecovered and s.items.campusCard
	for row in [["学　号：","3250100755" if identity else "▓▓▓▓▓▓▓▓"],["姓　名：","林星宇" if identity else "▓▓▓"],["卡账户：","1000100000"]]:
		var i=[["学　号："],["姓　名："],["卡账户："]].find([row[0]])
		_label(root,row[0],_home_rect(138,234+i*25,68,23),12,Color("cedcf3"))
		_label(root,row[1],_home_rect(210,234+i*25,181,23),12,Color("f2f6ff"))
	_label(root,"校园卡余额：",_home_rect(138,312,92,27),12,Color("cedcf3"))
	var balance=DropButton.new(); balance.name="CampusCardBalance"; balance.position=_home_rect(232,305,161,40).position; balance.size=_home_rect(232,305,161,40).size
	balance.disabled=s.actOne.phase not in ["movement_required","reservation_briefing_required","reservation_required","movement_ready"] or s.actOne.balanceShifted
	balance.text="¥%.2f" % (maxi(0,int(s.wallet.campusCardCents))/100.0)
	balance.add_theme_font_size_override("font_size",21)
	for mode in ["normal","hover","pressed","disabled"]: balance.add_theme_stylebox_override(mode,_style(Color.TRANSPARENT))
	balance.add_theme_stylebox_override("focus",_style(Color.TRANSPARENT,Color("f5c542"),0,2))
	for mode in ["font_color","font_hover_color","font_pressed_color","font_disabled_color"]: balance.add_theme_color_override(mode,Color("f2f6ff"))
	balance.pressed.connect(func(): action_requested.emit("c2_balance",str(s.native.get("selected_item",""))))
	balance.item_dropped.connect(func(item): action_requested.emit("c2_balance",item)); root.add_child(balance); handled.append("c2_balance")
	if s.actOne.balanceShifted and not displayed_balance_shifted:
		balance.text="¥0.06"
		var arrow=_label(root,"→",_home_rect(244,338,35,29),24,Color("f5c542"))
		root.ready.connect(func():
			var tween=arrow.create_tween(); tween.tween_property(arrow,"position:x",345/PHONE_SCALE,1.1); tween.parallel().tween_property(arrow,"modulate:a",0.0,1.1)
			tween.tween_callback(func(): balance.text="¥%.2f" % (maxi(0,int(s.wallet.campusCardCents))/100.0)))
	displayed_balance_shifted=s.actOne.balanceShifted
	_panel(root,_home_rect(30,363,364,42),Color(.04,.1,.27,.35),Color(1,1,1,.5),0,1)
	_panel(root,_home_rect(44,374,20,20),Color("f5c542"),Color("8f6b16"),10,2)
	_panel(root,_home_rect(50,380,8,8),Color("8f6b16"),Color.TRANSPARENT,4)
	_label(root,"我的零钱：",_home_rect(72,371,103,28),12,Color("f2f6ff"))
	_label(root,"¥%.2f" % (maxi(0,int(s.wallet.cashCents))/100.0),_home_rect(179,371,184,28),16,Color.WHITE)
	_label(root,"›",_home_rect(367,369,18,30),22,Color.WHITE)
	_panel(root,_home_rect(14,433,396,77),Color("fffdf6"),INK,0,2)
	for i in range(4):
		var x=55+i*97
		_panel(root,_home_rect(x,447,24,24),Color.TRANSPARENT,Color("4d7ed9"),12 if i==2 else 4 if i==1 else 0,3)
		if i==0: _panel(root,_home_rect(x,447,7,24),Color("4d7ed9"))
		_label(root,["账单","付款码","卡片充值","挂失·解挂"][i],_home_rect(18+i*97,477,97,21),12,INK,HORIZONTAL_ALIGNMENT_CENTER)
	_panel(root,_home_rect(14,522,396,282),Color("fff8e2"),INK,0,2)
	_label(root,"▎校园新闻",_home_rect(30,537,254,25),13)
	_label(root,"查看全部 ›",_home_rect(297,537,97,25),10,Color("4d7ed9"),HORIZONTAL_ALIGNMENT_RIGHT)
	_label(root,"浙江大学图书馆暑期开放安排通知！",_home_rect(30,575,364,29),12)
	_panel(root,_home_rect(30,622,364,100),Color("79b7e8"),INK,0,2)
	_panel(root,_home_rect(32,677,360,43),Color("7ec27e"))
	_panel(root,_home_rect(32,624,360,96),Color(.15,.31,.63,.35))
	_label(root,"2026 年暑期图书馆开放安排",_home_rect(43,646,338,47),16,Color.WHITE,HORIZONTAL_ALIGNMENT_CENTER)
	_label(root,"1天前 · 校园资讯中心",_home_rect(30,754,364,26),10,Color("999999"))
	_nav(root,"back","返回浙大钉",func(): _return_zjuding(),_home_rect(10,50,40,40),PAPER)
	_panel(root,_home_rect(0,812,424,42),Color("fbfcfe"),Color("d5dae4"),0,2)
	for i in range(5):
		if i==2:
			_panel(root,_home_rect(184,800,56,48),Color("4d7ed9"),Color("1d3f8f"),24,2)
			_label(root,"校园码",_home_rect(184,809,56,26),10,Color.WHITE,HORIZONTAL_ALIGNMENT_CENTER)
		else: _label(root,["首页","资讯","校园码","应用","我的"][i],_home_rect(i*84.8,822,84.8,22),10,Color("4d7ed9") if i==0 else Color("7a8194"),HORIZONTAL_ALIGNMENT_CENTER)
	return root

func _bonsai() -> Control:
	var root = _base(Color("cfc3de"),APP_HEIGHT)
	var plant = _image(root,"ui/bonsai_bloom.png" if s.flags.flowerBloomed else "ui/bonsai_bud.png",Rect2(0,-40/PHONE_SCALE,378,854/PHONE_SCALE))
	plant.name="BonsaiArtwork"
	plant.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	var stage = int(s.flags.plantWatered)+int(s.flags.plantLit)+int(s.flags.plantFertilized)
	plant.pivot_offset = Vector2(189,463)
	plant.scale = Vector2.ONE*(1.0+stage*.045)
	# Invisible semantic plant silhouette measured on the two 941x1672 assets.
	# Inversion follows the actual cropped/scaled artwork, including growth.
	var button=DropButton.new(); button.name="BonsaiPlant"
	button.position=Vector2.ZERO; button.size=Vector2(378,APP_HEIGHT)
	button.hit_texture=plant
	button.focus_anchor_source=Vector2(470,1290)
	button.hit_polygons=[PackedVector2Array([
		Vector2(451,701),Vector2(494,701),Vector2(507,765),Vector2(589,751),Vector2(597,771),Vector2(518,817),Vector2(494,846),Vector2(551,839),Vector2(607,838),Vector2(655,863),Vector2(575,909),Vector2(526,932),Vector2(593,941),Vector2(638,964),Vector2(639,1047),Vector2(621,1070),Vector2(605,1226),Vector2(563,1259),Vector2(386,1272),Vector2(329,1237),Vector2(315,1077),Vector2(290,1050),Vector2(289,963),Vector2(319,943),Vector2(392,931),Vector2(332,913),Vector2(282,924),Vector2(287,897),Vector2(337,865),Vector2(381,862),Vector2(427,885),Vector2(418,857),Vector2(369,830),Vector2(329,773),Vector2(341,765),Vector2(416,781),Vector2(459,817),Vector2(459,774),Vector2(445,749)
	])]
	if s.flags.flowerBloomed:
		button.hit_polygons=[PackedVector2Array([
			Vector2(424,447),Vector2(540,441),Vector2(585,461),Vector2(612,537),Vector2(563,593),Vector2(513,600),Vector2(532,643),Vector2(588,618),Vector2(593,599),Vector2(625,599),Vector2(634,637),Vector2(596,693),Vector2(655,665),Vector2(711,690),Vector2(743,739),Vector2(732,779),Vector2(686,829),Vector2(633,820),Vector2(690,883),Vector2(648,900),Vector2(615,894),Vector2(650,958),Vector2(625,955),Vector2(601,951),Vector2(628,981),Vector2(628,1051),Vector2(604,1077),Vector2(584,1235),Vector2(550,1257),Vector2(383,1257),Vector2(343,1230),Vector2(326,1078),Vector2(306,1050),Vector2(306,985),Vector2(335,964),Vector2(279,960),Vector2(270,942),Vector2(317,905),Vector2(286,886),Vector2(226,885),Vector2(225,864),Vector2(278,834),Vector2(234,807),Vector2(234,765),Vector2(255,748),Vector2(289,761),Vector2(309,810),Vector2(341,820),Vector2(326,741),Vector2(281,733),Vector2(240,711),Vector2(248,670),Vector2(235,648),Vector2(262,625),Vector2(274,585),Vector2(306,587),Vector2(324,562),Vector2(355,577),Vector2(373,576),Vector2(386,600),Vector2(416,627),Vector2(416,665),Vector2(389,692),Vector2(411,716),Vector2(446,709),Vector2(446,665),Vector2(423,623),Vector2(450,620),Vector2(479,647),Vector2(475,589),Vector2(432,587),Vector2(397,561),Vector2(396,527),Vector2(391,497),Vector2(423,485)
		])]
	for mode in ["normal","hover","pressed","focus"]: button.add_theme_stylebox_override(mode,_style(Color.TRANSPARENT))
	button.item_dropped.connect(func(item): action_requested.emit("c1_plant",item))
	button.pressed.connect(func(): action_requested.emit("c1_flower",null))
	button.tooltip_text="盛开的盆栽" if s.flags.flowerBloomed else "盆栽"
	root.add_child(button)
	var status="开花了？！" if s.flags.flowerBloomed else "它绝对不会开花" if stage==0 else "好像有点想开花"
	_panel(root,Rect2(54,18,270,45),Color("fff9e8"),INK,1,2)
	_label(root,status,Rect2(61,22,256,37),21,INK,HORIZONTAL_ALIGNMENT_CENTER).name="BonsaiStatus"
	for i in range(3):
		var active = [s.flags.plantWatered,s.flags.plantLit,s.flags.plantFertilized][i]
		var box=_panel(root,Rect2(91+i*69,APP_HEIGHT-62,46,46),Color("fffdf4") if active else Color("97859f"),INK,0,2)
		box.name="BonsaiCondition_"+str(i)
		var icon=_source_icon(box,["waterDrop","sun","fertilizer"][i],Rect2(8,8,30,30))
		if not active: icon.modulate=Color(.65,.65,.65,.55)
	var old_stage=stage if bonsai_stage_seen<0 else bonsai_stage_seen
	bonsai_stage_seen=stage
	if old_stage!=stage:
		plant.scale=Vector2.ONE*(1.0+old_stage*.045)
		root.ready.connect(func():
			var growth=root.create_tween()
			growth.tween_method(func(t:float): plant.scale=Vector2.ONE*(1.0+lerpf(old_stage,stage,floorf(t*4)/4.0)*.045),0.0,1.0,.6))
	root.ready.connect(func(): _apply_bonsai_light.call_deferred(root))
	if s.native.get("flower_eight_visible",false) and not s.flags.flowerEightTaken:
		var eight = _act(root,"8",Rect2(147,174,84,90),"c1_collect_flower",null,Color.TRANSPARENT,Color("f4d562"),0,Color.TRANSPARENT)
		eight.name="BonsaiEight"
		eight.add_theme_font_size_override("font_size",67)
		root.ready.connect(func():
			eight.pivot_offset = eight.size/2
			eight.scale = Vector2.ONE*.3
			var tween = eight.create_tween()
			tween.tween_property(eight,"scale",Vector2.ONE*1.15,.42)
			tween.tween_property(eight,"scale",Vector2.ONE,.18))
	_nav(root,"exit","退出盆栽，返回手机主页",func(): page_requested.emit("phone_home"),Rect2(9,7,40,40),PAPER)
	for id in ["c1_plant","c1_plant_light","c1_flower","c1_collect_flower"]: handled.append(id)
	return root

func _apply_bonsai_light(root: Control) -> void:
	# Match the mounted source effect. Rebuilds and Control Center overlays cannot
	# duplicate the effect, and a departed page cannot claim the light condition.
	if not is_instance_valid(root) or root.is_queued_for_deletion() or not root.is_inside_tree(): return
	if str(s.native.page)!="bonsai" or s.flags.plantLit or float(s.ui.brightness)<80: return
	action_requested.emit("c1_plant_light",null)

func _cc98(view: Dictionary) -> Control:
	var ticket_cellular=s.networkMode=="cellular" and s.theaterHunt.cc98TicketCommissionPhase in ["accepted","first_wave_failed","delivered"]
	if s.networkMode!="campus_wifi" and not ticket_cellular:
		var denied=_base(Color("e8eef2"),620)
		_label(denied,"CC98",Rect2(40,157,298,69),46,Color("1e6f9b"),HORIZONTAL_ALIGNMENT_CENTER)
		var status=_label(denied,"校内访问验证",Rect2(30,246,318,45),26,INK,HORIZONTAL_ALIGNMENT_CENTER)
		_label(denied,"正在检查 ZJUWLAN",Rect2(30,298,318,41),18,MUTED,HORIZONTAL_ALIGNMENT_CENTER)
		_label(denied,"·　·　·",Rect2(30,352,318,41),30,MUTED,HORIZONTAL_ALIGNMENT_CENTER)
		_page(denied,"退出",Rect2(122,487,134,45),"phone_home")
		denied.ready.connect(func():
			var tween=denied.create_tween(); tween.tween_interval(1.6)
			tween.tween_callback(func(): status.text="网络验证失败")
			tween.tween_property(denied,"modulate",Color("c98c93"),.31)
			tween.tween_property(denied,"modulate",Color.WHITE,.31)
			tween.tween_callback(func(): action_requested.emit("phone_cc98_network_rejected",{})))
		denied.set_meta("handles_all_actions",true)
		return denied
	if not s.actOne.cc98Login.authenticated: return _cc98_story(view)
	if s.chapterThreeInterlude.recoveryOpened and not s.chapterThreeInterlude.evidenceIds.has("journal_start"):
		var recovery=_base(Color("eef0f3"),620)
		recovery.set_meta("handles_all_actions",true)
		recovery.ready.connect(func(): action_requested.emit("phone_open_journal_closeout",{}))
		return recovery
	var all=Posts.all_posts(s)
	lake_apps.augment_posts(self,all)
	for post in all:
		if cc98_drafts.has(post.id): post.merge(cc98_drafts[post.id],true)
	var opened: Dictionary={}
	for post in all:
		if post.id==cc98_post: opened=post; break
	if not opened.is_empty():
		if cc98_editing: return _cc98_edit_post(opened)
		if opened.id in ["seat-022-backpack","act-two-gamepad-market"]:
			var story=view.duplicate(true)
			story.title=opened.title
			story.post=opened
			if opened.id=="act-two-gamepad-market": story.body=opened.title+"\n"+opened.body; story.erase("rows")
			elif story.has("body"):
				var lines=str(story.body).split("\n"); lines[0]=str(opened.body); story.body="\n".join(lines)
			var control=_cc98_story(story)
			_button(control,"‹ 热门话题",Rect2(181,11,183,36),func(): cc98_post=""; action_requested.emit("phone_refresh",{}),Color("297b9b"),Color.WHITE,0,Color.TRANSPARENT).name="Cc98BackToFeed"
			return control
		return _cc98_thread(opened)
	var root=_base(Color("f4f5f6"),630)
	root.set_meta("handles_all_actions",true)
	_panel(root,Rect2(0,0,378,56),Color("28769b"))
	_nav(root,"exit","退出 CC98，返回手机主页",func(): page_requested.emit("phone_home"),Rect2(7,6,40,44),Color("28769b"),Color.WHITE)
	_label(root,"热门话题",Rect2(51,9,213,38),25,Color.WHITE)
	if Utilities.editing_allowed(s):
		_button(root,"保存" if cc98_editing else "编辑",Rect2(300,12,66,34),func():
			if cc98_editing:
				cc98_editing=false; action_requested.emit("phone_cc98_save",cc98_drafts.duplicate(true)); cc98_drafts.clear()
			else: cc98_editing=true; action_requested.emit("phone_refresh",{}),Color("28769b"),Color.WHITE,0,Color.TRANSPARENT).name="Cc98EditToggle"
	_label(root,"今日　 发现　 本周　 本月　 往年今日　 活动",Rect2(11,61,359,36),14,Color("337ea3"),HORIZONTAL_ALIGNMENT_CENTER)
	var search=_line_edit(root,"搜索帖子、版面与校园资料",Rect2(12,104,354,37),cc98_query)
	search.name="Cc98Search"
	var scroll=ScrollContainer.new(); scroll.position=Vector2(0,151); scroll.size=Vector2(378,APP_HEIGHT-151-61-(55 if cc98_editing else 0))
	scroll.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED; root.add_child(scroll)
	var feed=VBoxContainer.new(); feed.size_flags_horizontal=Control.SIZE_EXPAND_FILL; feed.add_theme_constant_override("separation",0); scroll.add_child(feed)
	var cards: Array=[]
	if s.ui.libraryFinalsPhase=="evidence_gathering" and s.ui.libraryFinalsPuzzle.occupancyNoteCollected and not s.ui.libraryFinalsPuzzle.investigationOpened:
		_cc98_note_search(feed)
	lake_apps.cc98_search(self,feed)
	if cc98_tab=="boards" and cc98_board.is_empty():
		var boards: Array=[]
		for post in all:
			if not boards.has(post.board): boards.append(post.board)
		var preferred=["校园生活","郁闷小屋","交通出行","学习天地","手机服务","图书馆","自习室","食堂","打印服务","校园卡","失物招领","二手市场","开怀一笑"]
		boards.sort_custom(func(a,b): return preferred.find(a)<preferred.find(b))
		for board in boards:
			var count=0
			for post in all:
				if post.board==board: count+=1
			var row=_base(Color.WHITE,92); row.custom_minimum_size.x=370
			_button(row,str(board),Rect2(12,7,242,36),func(): cc98_board=board; action_requested.emit("phone_refresh",{}),Color.WHITE,Color("28769b"),0,Color.TRANSPARENT)
			_label(row,"当前 %d 帖" % count,Rect2(25,48,236,28),13,MUTED)
			_button(row,"已关注" if board in cc98_followed else "关注",Rect2(284,26,80,35),func():
				if board in cc98_followed: cc98_followed.erase(board)
				else: cc98_followed.append(board)
				action_requested.emit("phone_refresh",{}),Color("e4eef3"),Color("28769b"))
			feed.add_child(row)
	elif cc98_tab=="profile":
		var profile=_base(Color("edf2f5"),93); feed.add_child(profile)
		_label(profile,"我的浏览",Rect2(13,7,350,32),23)
		_label(profile,"关注版面 %d 个　浏览记录 %d 条" % [cc98_followed.size(),cc98_recent.size()],Rect2(13,46,350,31),15,MUTED)
		for id in cc98_recent:
			for post in all:
				if post.id==id: cards.append(_cc98_feed_card(feed,post))
		if cc98_recent.is_empty(): _cc98_empty(feed,"还没有浏览记录。打开一篇帖子后会出现在这里。")
	else:
		var filtered: Array=[]
		for post in all:
			if not cc98_board.is_empty() and post.board!=cc98_board: continue
			if cc98_tab=="followed" and post.board not in cc98_followed: continue
			filtered.append(post)
		if cc98_tab=="new": filtered.sort_custom(func(a,b): return _cc98_freshness(a)>_cc98_freshness(b))
		if not cc98_board.is_empty():
			var header=_base(Color("edf2f5"),51); feed.add_child(header)
			_button(header,"‹ 全部版面　"+cc98_board,Rect2(12,6,351,38),func(): cc98_board=""; action_requested.emit("phone_refresh",{}),Color("edf2f5"),Color("28769b"),0,Color.TRANSPARENT)
		for post in filtered: cards.append(_cc98_feed_card(feed,post))
		if filtered.is_empty(): _cc98_empty(feed,"这个版面暂时没有可显示的帖子。")
	var filter=func(query):
		cc98_query=str(query)
		for card in cards: card.visible=str(query).strip_edges().is_empty() or str(card.get_meta("search_text")).to_lower().contains(str(query).strip_edges().to_lower())
	search.text_changed.connect(filter); filter.call(cc98_query)
	_panel(root,Rect2(0,APP_HEIGHT-55,378,55),Color.WHITE,Color("c9d6df"),0,1)
	var tabs=[["hot","◉","热门"],["new","✿","新帖"],["followed","♡","关注"],["boards","▦","版面"],["profile","◎","我"]]
	for i in range(tabs.size()):
		var tab: Array=tabs[i]
		_button(root,str(tab[1])+"\n"+str(tab[2]),Rect2(i*75+2,APP_HEIGHT-51,73,46),func(): cc98_tab=tab[0]; cc98_board=""; cc98_post=""; cc98_editing=false; action_requested.emit("phone_refresh",{}),Color.WHITE,Color("28769b") if cc98_tab==tab[0] else MUTED,0,Color.TRANSPARENT).name="Cc98Tab_"+str(tab[0])
	if cc98_editing:
		_button(root,"恢复默认帖子",Rect2(12,APP_HEIGHT-107,354,42),func(): cc98_drafts.clear(); cc98_editing=false; action_requested.emit("phone_cc98_reset",{}),Color("edf2f5"),INK).name="Cc98RestorePosts"
		root.custom_minimum_size.y=APP_HEIGHT; root.size.y=APP_HEIGHT
	return root

func _cc98_feed_card(feed: Control, post: Dictionary) -> Control:
	var card=_base(Color.WHITE,160 if cc98_editing else 137)
	card.set_meta("search_text",str(post.title)+str(post.body)+str(post.author)+str(post.board))
	card.name="Post_"+str(post.id)
	if cc98_editing:
		for field in [["author",Rect2(52,9,142,30)],["board",Rect2(255,9,109,30)],["title",Rect2(13,49,351,38)],["replies",Rect2(13,93,52,28)],["views",Rect2(91,93,64,28)],["time",Rect2(211,93,153,28)]]:
			var key=str(field[0]); var input=_line_edit(card,"",field[1],str(post.get(key,""))); input.name="Edit_"+key
			input.text_changed.connect(func(text):
				if not text.strip_edges().is_empty(): _cc98_draft(post.id,key,text.strip_edges()))
		_button(card,"正文",Rect2(279,126,85,28),func(): _cc98_open(post.id),Color("e5edf3"),Color("28769b"),1).name="EditBody_"+str(post.id)
	else:
		_button(card,"",Rect2(0,0,378,136),func(): _cc98_open(post.id),Color.WHITE,INK,0,Color.TRANSPARENT).name="OpenPost_"+str(post.id)
		_label(card,str(post.author),Rect2(52,8,194,28),15,Color("526576"))
		_label(card,str(post.board),Rect2(258,8,106,28),13,Color("5985a0"),HORIZONTAL_ALIGNMENT_RIGHT)
		_label(card,str(post.title),Rect2(13,48,351,48),19,Color("152b3a"))
		_label(card,"%s 回复 · %s 浏览" % [post.replies,post.views],Rect2(13,105,206,24),12,MUTED)
		_label(card,str(post.time),Rect2(223,105,141,24),11,MUTED,HORIZONTAL_ALIGNMENT_RIGHT)
	_panel(card,Rect2(14,8,30,30),Color("c6d8df"),Color("7098a8"),15,1)
	_label(card,str(post.get("rank","")),Rect2(206,8,45,28),14,Color("d98932"),HORIZONTAL_ALIGNMENT_CENTER)
	_panel(card,Rect2(0,card.size.y-1,378,1),Color("dce3e8"))
	feed.add_child(card)
	return card

func _cc98_open(id: String) -> void:
	if id=="theater-755-ticket-commission" and not cc98_editing:
		page_requested.emit("c3_ticket_post")
		return
	cc98_post=id; cc98_recent.erase(id); cc98_recent.push_front(id)
	if cc98_recent.size()>8: cc98_recent.resize(8)
	action_requested.emit("phone_refresh",{})

func _cc98_draft(id: String, key: String, value: String) -> void:
	if not cc98_drafts.has(id): cc98_drafts[id]={}
	cc98_drafts[id][key]=value

func _cc98_freshness(post: Dictionary) -> int:
	if post.time=="刚刚": return 99999999
	var regex=RegEx.new(); regex.compile("(\\d{1,2}):(\\d{2})")
	var found=regex.search(str(post.time))
	return int(found.get_string(1))*60+int(found.get_string(2)) if found else 0

func _cc98_empty(feed: Control, text: String) -> void:
	var row=_base(Color("edf2f5"),88); feed.add_child(row)
	_label(row,text,Rect2(20,10,338,67),16,MUTED,HORIZONTAL_ALIGNMENT_CENTER)

func _cc98_edit_post(post: Dictionary) -> Control:
	var root=_base(Color("edf2f5"),620); root.set_meta("handles_all_actions",true)
	_label(root,str(post.author),Rect2(15,14,284,37),19,Color("28769b"))
	_button(root,"×",Rect2(326,14,38,38),func(): cc98_post=""; action_requested.emit("phone_refresh",{}),Color("edf2f5"),INK,0,Color.TRANSPARENT).name="Cc98CloseEditor"
	_label(root,str(post.title),Rect2(15,70,349,65),22)
	var body=TextEdit.new(); body.position=Vector2(15,151); body.size=Vector2(349,384); body.text=str(post.body)
	body.wrap_mode=TextEdit.LINE_WRAPPING_BOUNDARY; body.add_theme_font_size_override("font_size",18); body.name="Cc98BodyEditor"; root.add_child(body)
	body.text_changed.connect(func(): _cc98_draft(post.id,"body",body.text))
	_label(root,str(post.board)+" · "+str(post.time),Rect2(15,550,349,38),14,MUTED)
	return root

func _cc98_thread(post: Dictionary) -> Control:
	var replies: Array=post.get("threadReplies",[])
	var body_height=maxf(120,ceil(str(post.body).length()/18.0)*25+35)
	var root=_base(Color("eef0f3"),250+body_height+replies.size()*151)
	root.set_meta("handles_all_actions",true)
	_panel(root,Rect2(0,0,378,56),Color("28769b"))
	_button(root,"‹",Rect2(9,10,37,37),func(): cc98_post=""; action_requested.emit("phone_refresh",{}),Color("28769b"),Color.WHITE,0,Color.TRANSPARENT).name="Cc98BackToFeed"
	_label(root,"CC98小程序",Rect2(59,9,233,38),24,Color.WHITE)
	_nav(root,"close","退出帖子，返回热门话题",func(): cc98_post=""; action_requested.emit("phone_refresh",{}),Rect2(328,6,40,44),Color("28769b"),Color.WHITE).name="Cc98CloseThread"
	_label(root,"热门　"+str(post.title),Rect2(14,72,350,72),23,Color("173143"))
	_panel(root,Rect2(10,155,358,body_height+64),Color.WHITE)
	_label(root,str(post.author)+"　　楼主　1楼",Rect2(24,162,330,31),17,Color("28769b"))
	_label(root,str(post.body),Rect2(24,205,330,body_height-10),18)
	var y=int(236+body_height)
	_label(root,"热门回复",Rect2(14,y,350,36),23)
	y+=47
	var personas: Dictionary={}
	for persona in Posts.source("cc98.thread-personas"): personas[persona.id]=persona
	for reply in replies:
		# Source generic threads do not show bd reply artwork outside the investigation.
		if reply.has("image") or str(reply.get("text","")).to_lower().contains("bd"): continue
		var persona: Dictionary=personas.get(reply.get("personaId",""),{})
		_panel(root,Rect2(10,y,358,143),Color.WHITE,Color("dce3e8"),0,1)
		_label(root,str(persona.get("nickname",reply.get("personaId","")))+"　"+str(reply.get("floor","")),Rect2(24,y+6,330,27),15,Color("28769b"))
		_label(root,str(reply.get("text","")),Rect2(24,y+42,330,72),17)
		_label(root,str(reply.get("time",""))+"　♡ "+str(reply.get("likes","0")),Rect2(24,y+116,330,22),12,MUTED)
		y+=151
	root.custom_minimum_size.y=y+14; root.size.y=y+14
	if post.id=="qizhen-wet-paper-witness": lake_apps.witness_footer(self,root,y+10)
	return root

func _cc98_note_search(feed: Control) -> void:
	var box=_base(Color("e7eef3"),567 if cc98_note_ready else 136)
	_label(box,"资料搜索　　可接收道具",Rect2(13,8,352,30),17,Color("2c7797"))
	_label(box,"022 占座纸条" if s.items.occupancyNote else "把占座纸条拖到这里",Rect2(13,49,252,37),16,MUTED)
	var drop=DropButton.new(); drop.position=Vector2(13,47); drop.size=Vector2(252,42); drop.name="Cc98NoteDrop"
	for mode in ["normal","hover","pressed","focus"]: drop.add_theme_stylebox_override(mode,_style(Color.TRANSPARENT))
	drop.item_dropped.connect(func(item):
		if item=="occupancyNote" and s.items.occupancyNote: cc98_note_ready=true; action_requested.emit("phone_refresh",{}))
	box.add_child(drop)
	_button(box,"搜索",Rect2(277,47,87,39),func():
		if s.items.occupancyNote: cc98_note_ready=true; action_requested.emit("phone_refresh",{}),Color("28769b"),Color.WHITE).name="Cc98NoteSearch"
	if cc98_note_ready:
		var results=[["seat-022-backpack","【求助】022 的书包占座三天了","23 楼","一层书库 022 有个书包，纸条写着离开三分钟。人没回来，座位也没有空。"],["seat-022-old-source","【求助】022 座位今日临时离开","12 楼","来源为今日新帖，没有旧版离座规定的引用。"],["seat-022-wrong-time","【记录】二南 022 晚间使用情况","31 楼","发布时间为当日 22:40，早于纸条中的本次离座事件。"],["seat-022-missing-attachment","【闲聊】一层书库今天还有位置吗","18 楼","正文提到 022，附件区为空。"]]
		for i in range(results.size()):
			var result: Array=results[i]
			var card=_button(box,"",Rect2(13,98+i*106,351,97),func():
				if result[0]=="seat-022-backpack": cc98_post=result[0]; action_requested.emit("lib_investigate","occupancyNote")
				else: action_requested.emit("phone_cc98_search_reject",result[0]),Color.WHITE,INK,0,Color("bccbd5"))
			card.name="Cc98Result_"+str(result[0])
			_label(card,str(result[1])+"　"+str(result[2]),Rect2(10,6,330,40),17,Color("28769b"))
			_label(card,str(result[3]),Rect2(10,50,330,42),13,MUTED)
	else: _label(box,"拖入纸条或点击搜索后显示候选记录。",Rect2(13,97,352,28),13,MUTED)
	feed.add_child(box)

func _cc98_story(view: Dictionary) -> Control:
	if not s.actOne.cc98Login.authenticated: return cc98_login.build(self)
	if str(view.get("post", {}).get("id", "")) == "act-two-gamepad-market": return Cc98Gamepad.new().build(self, view)
	var rows: Array = view.get("rows",[])
	var root = _base(Color("f2f3f5"),maxf(500,750+rows.size()*164))
	_panel(root,Rect2(0,0,378,57),Color("297b9b"))
	_label(root,"CC98",Rect2(17,4,154,48),33,Color.WHITE)
	_label(root,"≡　　　⌕",Rect2(258,8,105,42),24,Color.WHITE,HORIZONTAL_ALIGNMENT_RIGHT)
	_label(root,"热门话题　　校园生活　　二手市场",Rect2(13,67,352,36),15,Color("457d94"),HORIZONTAL_ALIGNMENT_CENTER)
	_panel(root,Rect2(0,111,378,3),Color("50a0b5"))
	_label(root,str(view.get("title","")),Rect2(17,128,344,52),21)
	var summary = str(view.get("body",""))
	if rows.is_empty():
		_panel(root,Rect2(12,190,354,264),Color.WHITE,Color("d1d6dc"),0,1)
		_label(root,str(view.get("post",{}).get("author","手柄毕业生"))+"　·　"+str(view.get("post",{}).get("board","二手市场")),Rect2(25,204,326,31),16,Color("2e88a7"))
		_label(root,summary,Rect2(25,244,326,137),19)
		_label(root,"%s 回复　%s 浏览　%s" % [view.get("post",{}).get("replies","19"),view.get("post",{}).get("views","982"),view.get("post",{}).get("time","07:55")],Rect2(25,402,326,25),13,MUTED)
	else:
		var summary_height = maxf(110,minf(420,60+summary.length()/20.0*21))
		_panel(root,Rect2(12,190,354,summary_height),Color.WHITE,Color("d1d6dc"),0,1)
		_label(root,summary,Rect2(25,202,328,summary_height-24),17)
		var y = int(204+summary_height)
		if s.ui.libraryFinalsPhase == "top_ten_rising":
			_act(root,"撤回最后一次 bd",Rect2(14,y,170,42),"lib_bd_undo",null,Color("e7eef1"))
			_act(root,"核验热度口令",Rect2(195,y,170,42),"lib_bd_submit",null,Color("cee2e8"))
			y += 57
		var bd = {24:"bd-notice-tens",25:"bd-rule-count",26:"bd-rank-first",27:"bd-identity-zero",28:"bd-call-number-tail",29:"bd-seat-tail",30:"bd-reply-count",31:"bd-arrival-minutes"}
		for row in rows:
			_panel(root,Rect2(0,y,378,157),Color.WHITE,Color("dce1e5"),0,1)
			_label(root,str(row.get("title","")),Rect2(15,y+10,346,29),16,Color("337e9b"))
			_label(root,str(row.get("body","")),Rect2(15,y+45,346,83),17)
			var floor_number = int(str(row.get("title","")).get_slice(" ",0))
			if s.ui.libraryFinalsPhase=="top_ten_rising" and bd.has(floor_number):
				_act(root,"bd",Rect2(301,y+120,58,28),"lib_bd_select",bd[floor_number],Color("e8f0f4"),Color("367d99"),2,Color("86b1c4"))
			y += 164
		root.custom_minimum_size.y = y+8
		root.size.y = y+8
	return root

const ZJU_APPS = [
	["learn","学在浙大","学","f4ebd4","learning","学习 签到 课程","always"],
	["smart_classroom","智云课堂","云","b7a4e0","learning","课程 课堂 课件 日程","identity"],
	["campus_map","校园地图","位","8cbde7","campus","地图 导航 教学楼 图书馆 启真湖","map"],
	["network_account","网络缴费","¥","78c5c8","service","校园网 流量 账户 连接","identity"],
	["logistics","后勤服务","勤","e3a77a","service","后勤 报修 服务 网络 图书馆","identity"],
	["lost_found","失物招领","寻","a1c999","service","失物 书包 证明 档案","identity"],
	["visitor_preview","访客预约","访","78bdd3","service","访客 预约 入校 草稿","identity"],
	["library","图书馆","图","5d80b4","library","馆藏 座位 预约 图书 022","library"],
	["language_cards","慧学外语","F","c3ccd4","learning","外语 英语 词汇 卡片","identity"],
	["feedback_draft","开发反馈","信","6ca1de","service","意见 反馈 建议 开发者 GitHub Issue","identity"],
	["all_apps","全部","▦","e0e8f4","campus","全部 应用 工作台","identity"]
]

func _zju_identity() -> bool:
	return s.actOne.inventoryRecovered and s.items.campusCard

func _zju_library_access() -> bool:
	return s.actOne.phase in ["reservation_required","movement_ready","complete"] or s.ui.librarySeatReserved or s.ui.libraryFinalsPhase!="idle"

func _zju_available(app: Array) -> bool:
	match app[6]:
		"always": return true
		"map": return s.actOne.phase!="prologue" and s.actOne.dormHubUnlocked
		"library": return _zju_library_access()
		_: return _zju_identity()

func _zju_open(id: String) -> void:
	zjuding_overlay=""; zjuding_detail=""; zjuding_feedback_status=""
	if id=="learn": zjuding_page="learn"; zjuding_panel=""; action_requested.emit("phone_refresh",{})
	elif id=="library": page_requested.emit("library_app")
	elif id=="directory": page_requested.emit("directory")
	elif id=="campus_card": page_requested.emit("campus_card")
	elif id=="campus_map":
		if s.qizhenLake.active and s.qizhenLake.phase!="inactive":
			var solved: bool=s.qizhenLake.phase!="location_search"
			if solved and ((s.rpgScene=="campus_qizhen_loop" and s.rpgCheckpoint=="campus_qizhen_gate") or (s.rpgScene=="qizhen_lake" and s.qizhenLake.phase!="lake_unlocked")):
				zjuding_page="hub"
				action_requested.emit("c3_map_resume",null)
			else: zjuding_page="campus_map"; action_requested.emit("phone_refresh",{})
		else: action_requested.emit("c2_enter_campus" if s.actOne.phase=="complete" else "c2_enter_dorm",null)
	else: zjuding_panel=id; action_requested.emit("phone_refresh",{})

func _zju_back() -> void:
	zjuding_panel=""; zjuding_overlay=""; zjuding_page="hub"; zjuding_detail=""
	action_requested.emit("phone_refresh",{})

func _zju_scroll(root: Control, top: float = 0) -> Control:
	var scroll=ScrollContainer.new(); scroll.position=Vector2(0,top); scroll.size=Vector2(378,APP_HEIGHT-top-60)
	scroll.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED; scroll.name="ZjudingScroll"; root.add_child(scroll)
	var content=_base(Color("f4f7fd"),APP_HEIGHT-top-60); content.custom_minimum_size.x=378; content.size.x=378; scroll.add_child(content)
	return content

func _zju_nav(root: Control, active: String = "home") -> void:
	_panel(root,Rect2(0,APP_HEIGHT-60,378,60),Color("fbfcfe"),Color("cad6e7"),0,2)
	var tabs=[["home","⌂","首页"],["contacts","◉","通讯录"],["all_apps","▦","工作台"],["messages","✦","消息"],["profile","◎","我的"]]
	for i in range(5):
		var tab: Array=tabs[i]; var rect=Rect2(i*75.6,APP_HEIGHT-57,75.6,54)
		if tab[0]=="home" or _zju_identity():
			var button=_button(root,tab[1]+"\n"+tab[2],rect,func():
				if tab[0]=="home": _zju_back()
				else: _zju_open(tab[0]),Color("e8f0ff") if active==tab[0] else Color("fbfcfe"),Color("1454bd") if active==tab[0] else Color("798493"),0,Color.TRANSPARENT)
			button.add_theme_font_size_override("font_size",12); button.name="ZjudingTab_"+str(tab[0])
		else: _label(root,tab[1],rect,22,Color("abb4c2"),HORIZONTAL_ALIGNMENT_CENTER)

func _zju_app_tile(root: Control, app: Array, rect: Rect2) -> void:
	var enabled=_zju_available(app)
	var target: Control
	if enabled:
		target=_button(root,"",rect,func(): _zju_open(app[0]),Color.WHITE,BLUE,0,Color.TRANSPARENT)
		target.name="ZjudingApp_"+str(app[0])
	else:
		target=_panel(root,rect,Color.WHITE); target.name="ZjudingLocked_"+str(app[0])
	var icon=_panel(target,Rect2((rect.size.x-38)/2,10,38,38),Color(app[3]),Color("9ea7b8"),0,2)
	_label(icon,app[2],Rect2(0,0,38,38),22,Color("174d9d"),HORIZONTAL_ALIGNMENT_CENTER)
	var label=_label(target,app[1],Rect2(0,53,rect.size.x,24),12,INK if enabled else Color("a0a8b5"),HORIZONTAL_ALIGNMENT_CENTER)
	label.autowrap_mode=TextServer.AUTOWRAP_OFF; label.clip_text=true; label.text_overrun_behavior=TextServer.OVERRUN_TRIM_ELLIPSIS

func _zjuding() -> Control:
	if entry_session.family=="zjuding" and entry_session.phase!="ready": return _entry_loading("zjuding")
	var root=_base(Color("f4f7fd"),APP_HEIGHT)
	handled.append("c2_enter_dorm"); handled.append("c2_enter_campus")
	if not zjuding_panel.is_empty():
		_zju_utility(root)
	elif zjuding_page=="campus_map" and s.qizhenLake.active and s.qizhenLake.phase!="inactive":
		lake_apps.map_page(self,root)
	elif zjuding_page=="learn":
		# The browser uses this exact source illustration with its measured 108% top crop.
		var background=_image(root,"ui/zjuding_home.png",Rect2(0,-59.08/PHONE_SCALE,378,854*1.08/PHONE_SCALE))
		background.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_COVERED
		_nav(root,"back","返回浙大钉",_zju_back,Rect2(9,7,40,44),PAPER)
		if s.actOne.phase=="prologue":
			var hotspot=_button(root,"",Rect2(378*.515,(854*.205-40)/PHONE_SCALE,378*.425,854*.155/PHONE_SCALE),func(): page_requested.emit("checkin"),Color.TRANSPARENT,INK,0,Color.TRANSPARENT)
			hotspot.name="ZjudingCheckin"; hotspot.tooltip_text="校务签到"
			for mode in ["normal","hover","pressed"]: hotspot.add_theme_stylebox_override(mode,_style(Color.TRANSPARENT))
		_panel(root,Rect2(0,APP_HEIGHT-55,378,55),Color("fbfcfe"),Color("d5dae4"),0,2)
		var learn=_button(root,"▣\n学在浙大",Rect2(0,APP_HEIGHT-52,189,50),func(): pass,Color("fbfcfe"),Color("1793b8"),0,Color.TRANSPARENT)
		learn.name="ZjudingLearnTab"; learn.add_theme_font_size_override("font_size",13)
		_label(root,"◎",Rect2(189,APP_HEIGHT-51,189,44),24,Color("7a8194"),HORIZONTAL_ALIGNMENT_CENTER)
	else:
		var body=_zju_scroll(root)
		body.custom_minimum_size.y=686; body.size.y=686
		var identity=_zju_identity()
		_button(body,"林星宇" if identity else "用户",Rect2(11,15,46,46),func(): zjuding_overlay="profile"; action_requested.emit("phone_refresh",{}),Color("e9f1ff"),BLUE,0,Color("88aee8")).name="ZjudingProfileMenu"
		_label(body,"林星宇" if identity else "身份未读取",Rect2(67,14,173,29),21,INK)
		_label(body,"浙江大学",Rect2(67,43,173,23),12,Color("777777"))
		if identity: _button(body,"⌕　百事通",Rect2(249,18,117,38),func(): zjuding_overlay="search"; action_requested.emit("phone_refresh",{}),Color("f7f7f9"),MUTED,0,Color("b9bbc1")).name="ZjudingSearchOpen"
		else: _label(body,"⌕　百事通",Rect2(249,18,117,38),16,Color("a5aab2"),HORIZONTAL_ALIGNMENT_CENTER)
		var card=_panel(body,Rect2(11,74,356,230),Color("0755b9"),Color("063f90"),0,2)
		for x in [26,152,262]: _panel(card,Rect2(x,17,53,39),Color(.7,.85,1,.13))
		if s.actOne.phase in ["system_required","inventory_required","system_return_required","reservation_briefing_required"]:
			_act(card,"求",Rect2(15,24,59,59),"c2_open_system",null,Color("b51f31"),Color.WHITE,30,Color.WHITE).name="ZjudingSystemSeal"
		else:
			_panel(card,Rect2(15,24,59,59),Color("0755b9"),Color("e7f0ff"),30,3)
			_label(card,"求",Rect2(15,24,59,59),22,Color.WHITE,HORIZONTAL_ALIGNMENT_CENTER)
		_label(card,"林星宇" if identity else "▓▓▓",Rect2(88,27,204,31),16,Color.WHITE)
		_label(card,"3250100755/求是学院（归口..." if identity else "▓▓▓▓▓▓▓▓",Rect2(88,63,238,25),12,Color.WHITE)
		_panel(card,Rect2(10,100,336,117),Color.TRANSPARENT,Color("6096d2"),0,2)
		for i in range(4):
			var titles=["身份码","电子校园卡","校园钱包","部门黄页"]; var icons=["◎","▣","◇","☎"]
			var active=(i==1 and identity) or (i==3 and s.actOne.phase!="prologue")
			var rect=Rect2(12+i*83,103,82,111)
			if active:
				var id="campus_card" if i==1 else "directory"
				var action=_button(card,icons[i]+"\n"+titles[i],rect,func(): _zju_open(id),Color("0755b9"),Color.WHITE,0,Color.TRANSPARENT)
				action.add_theme_font_size_override("font_size",13); action.name="ZjudingShortcut_"+id
			else: _label(card,icons[i],rect,34,Color("a6c0e3"),HORIZONTAL_ALIGNMENT_CENTER)
		if identity: _button(body,"⌕　搜索应用与服务             搜索",Rect2(18,312,342,39),func(): zjuding_overlay="search"; action_requested.emit("phone_refresh",{}),Color.WHITE,MUTED,0,Color("a8b5cb")).name="ZjudingSearchBar"
		else: _label(body,"⌕　浙大百事通                    搜索",Rect2(18,312,342,39),16,Color("a4acb8"))
		_panel(body,Rect2(11,360,356,273),Color.WHITE,Color("d4e1f7"),0,2)
		for i in range(ZJU_APPS.size()): _zju_app_tile(body,ZJU_APPS[i],Rect2(16+i%5*69.5,365+int(i/5)*85.5,69.5,85.5))
		_zju_nav(root)
	if not zjuding_overlay.is_empty(): _zju_sheet(root)
	return root

func _zju_summary(body: Control, eyebrow: String, title: String, detail: String) -> void:
	_panel(body,Rect2(13,12,352,112),Color.WHITE,Color("bdcce1"),0,2)
	_panel(body,Rect2(13,12,6,112),Color("1c5ca7"))
	_label(body,eyebrow,Rect2(27,21,324,20),11,BLUE)
	_label(body,title,Rect2(27,47,324,29),21,INK)
	_label(body,detail,Rect2(27,80,324,34),12,MUTED)

func _zju_row(body: Control, y: float, title: String, detail: String, label: String = "", callback: Callable = Callable(), height: float = 82) -> void:
	_panel(body,Rect2(13,y,352,height),Color.WHITE,Color("c4cede"),0,1)
	_label(body,title,Rect2(27,y+8,248,29),16,INK)
	_label(body,detail,Rect2(27,y+40,244,height-44),12,MUTED)
	if callback.is_valid():
		var button=_button(body,label,Rect2(285,y+22,65,36),callback,Color("edf3ff"),BLUE,0,Color("315d9e"))
		button.add_theme_font_size_override("font_size",12)

func _zju_utility(root: Control) -> void:
	var titles={"smart_classroom":"智云课堂","network_account":"网络账户","logistics":"后勤服务","lost_found":"失物招领","visitor_preview":"访客预约预览","language_cards":"慧学外语","feedback_draft":"开发者反馈","all_apps":"全部应用","contacts":"通讯录","messages":"消息","profile":"我的"}
	_header(root,titles.get(zjuding_panel,"浙大钉"),Color("f8faff"),BLUE,_zju_back,"back","返回浙大钉")
	var body=_zju_scroll(root,57)
	var network={"campus_wifi":"校园网已连接","cellular":"当前使用移动数据","offline":"当前处于离线状态"}.get(s.networkMode,"")
	match zjuding_panel:
		"smart_classroom":
			_zju_summary(body,"本机课程预览","3 门课程","查看课程日程和缓存说明，不产生签到或成绩记录。")
			var courses=[["化学工程基础","周一 08:00 · 北教学区 A-204","课程资料已缓存在本机。"],["数据方法与 AI4S","周三 13:15 · 线上课堂","最近一次课件仅供预览。"],["实验室安全","周五 10:00 · 东教学区 3-106","安全提醒已读取，不产生签到记录。"]]
			var y=137.0
			for course in courses:
				var selected=zjuding_detail==course[0]
				_zju_row(body,y,course[0],course[1]+("\n"+course[2] if selected else ""),"收起" if selected else "查看",func(): zjuding_detail="" if selected else course[0]; action_requested.emit("phone_refresh",{}),112 if selected else 82)
				y+=122 if selected else 92
		"network_account":
			_zju_summary(body,"当前连接",network,"页面只读取本机网络状态，不扣费、不充值、不生成账单。")
			_zju_row(body,137,"校园网 · "+("可用" if s.networkMode=="campus_wifi" else "未连接"),"浙大钉与 CC98 需要校园网。")
			_zju_row(body,229,"移动数据 · "+("使用中" if s.networkMode=="cellular" else "备用"),"浙大体艺的网络规则与浙大钉不同。")
			_button(body,"收起连接说明" if zjuding_detail=="network" else "查看连接说明",Rect2(13,325,352,42),func(): zjuding_detail="" if zjuding_detail=="network" else "network"; action_requested.emit("phone_refresh",{}),Color("edf3ff"),BLUE).name="ZjudingNetworkDetails"
			if zjuding_detail=="network": _label(body,"如需切换网络，请返回手机控制中心。本页不会自动修改网络模式。",Rect2(20,384,338,66),14,MUTED)
		"contacts":
			_zju_summary(body,"校园公开联络表","3 个服务联络点","号码来自当前游戏内容，页面不会直接拨号。")
			var contacts=[["校园服务台","87950000"],["游戏联络台","3250100755"],["体艺值班台","87951234"]]
			for i in range(3): _zju_row(body,137+i*92,"☎　"+contacts[i][0],contacts[i][1])
			if s.actOne.phase!="prologue": _button(body,"打开部门黄页",Rect2(13,424,352,43),func(): _zju_open("directory"),Color("edf3ff"),BLUE).name="ZjudingOpenDirectory"
		"profile","logistics":
			if zjuding_panel=="profile": _zju_summary(body,"校园身份","林星宇" if _zju_identity() else "身份未读取","3250100755" if _zju_identity() else "取得电子校园卡后显示")
			else: _zju_summary(body,"校园服务聚合","后勤状态台","所有条目只读取已开放的本地功能，未提交任何报修工单。")
			_zju_row(body,137,"当前网络",network,"详情",func(): _zju_open("network_account"))
			_zju_row(body,229,"图书馆预约" if zjuding_panel=="profile" else "图书馆服务","座位 "+str(s.ui.librarySelectedSeat) if s.ui.librarySeatReserved else "当前无预约","查看",func(): _zju_open("library") if _zju_library_access() else null)
			if zjuding_panel=="profile":
				_zju_row(body,321,"电子校园卡","已读取" if _zju_identity() else "未读取","查看",func(): _zju_open("campus_card") if _zju_identity() else null)
				_zju_row(body,413,"开发者反馈","GitHub Issues","查看",func(): _zju_open("feedback_draft"))
			else:
				_zju_row(body,321,"校园导航","已开放" if s.actOne.dormHubUnlocked else "当前阶段未开放","进入",func(): _zju_open("campus_map") if s.actOne.dormHubUnlocked else null)
				_zju_row(body,413,"服务联络","部门黄页可用","查看",func(): _zju_open("contacts"))
		"messages":
			var messages=[["校园网状态",network,""]]
			if _zju_identity(): messages.append(["校园身份已读取","林星宇·3250100755","campus_card"])
			if _zju_library_access(): messages.append(["图书馆座位预约" if s.ui.librarySeatReserved else "图书馆服务已开放","已预约 "+str(s.ui.librarySelectedSeat)+" 号座位" if s.ui.librarySeatReserved else "当前可用功能以图书馆首页实际状态为准。","library"])
			_zju_summary(body,"当前已公开状态",str(messages.size())+" 条消息","只聚合已发生的网络、身份、预约和记录状态。")
			for i in range(messages.size()):
				var entry: Array=messages[i]
				_zju_row(body,137+i*92,entry[0],entry[1],"查看",Callable() if entry[2].is_empty() else func(): _zju_open(entry[2]))
		"language_cards":
			_zju_summary(body,"本地微卡片","校园场景外语","点击卡片查看中文释义与场景例句。")
			var words=[["wayfinding","导向；路径识别","Wayfinding signs connect the lobby and classrooms."],["reflection","倒影；反射","The reflection appears below the bridge."],["maintenance","维修；保养","The maintenance cart is parked by the service door."]]
			for i in range(words.size()):
				var word: Array=words[i]; var selected=zjuding_detail==word[0]
				var card=_button(body,"",Rect2(13,137+i*130,352,118),func(): zjuding_detail="" if selected else word[0]; action_requested.emit("phone_refresh",{}),Color("e8f0fa") if selected else Color.WHITE,INK,0,Color("bccbe0"))
				card.name="ZjudingWord_"+str(word[0])
				_label(card,word[1] if selected else "点击查看释义",Rect2(13,8,326,22),12,BLUE)
				_label(card,word[0],Rect2(13,35,326,32),25,INK)
				_label(card,word[2] if selected else "EN / ZH",Rect2(13,75,326,35),11,MUTED)
		"all_apps":
			_zju_summary(body,"统一应用目录","工作台","应用状态与首页、搜索完全一致。未开放项保留原名称与静态图标。")
			var y=137.0
			for category in [["learning","学习"],["campus","校园"],["service","服务"],["library","图书馆"]]:
				_label(body,category[1],Rect2(13,y,350,32),20,BLUE); y+=36
				var count=0
				for app in ZJU_APPS:
					if app[4]==category[0] and app[0]!="all_apps": _zju_app_tile(body,app,Rect2(13+count%4*88,y+int(count/4)*87,88,86)); count+=1
				y+=ceil(count/4.0)*87+14
			body.custom_minimum_size.y=y; body.size.y=y
		"lost_found":
			var owned=[]
			for item in [["itemRecognitionReport","书包物品识别报告","照片·本机识别"],["bagNonPersonProof","书包非本人证明","图书馆前台"],["seat022Receipt","022 座位小票","基础馆一层书库"],["libraryPresenceProof","本人到馆证明","浙大体艺·到馆记录"]]:
				if s.items.get(item[0],false): owned.append(item)
			_zju_summary(body,"仅显示已公开记录",str(owned.size())+" 份本机档案","查看档案不会生成证明、改变物品或推进图书馆进度。")
			if owned.is_empty(): _zju_row(body,137,"暂无已公开档案","后续只会在相关记录真正取得后显示。")
			for i in range(owned.size()):
				var item: Array=owned[i]
				_zju_row(body,137+i*92,item[1],item[2],"查看",func(): zjuding_detail=item[0]; action_requested.emit("phone_refresh",{}))
			if not zjuding_detail.is_empty():
				var info=_label(body,"",Rect2(20,137+owned.size()*92,338,110),15,MUTED)
				for item in JSON.parse_string(FileAccess.get_file_as_string("res://data/source/items.config.json")):
					if item.id==zjuding_detail: info.text=str(item.get("description",item.get("intro",item.name)))
		"visitor_preview","feedback_draft": _zju_draft_form(body)
	_zju_nav(root,zjuding_panel if zjuding_panel in ["contacts","messages","profile"] else "all_apps")

func _zju_draft_form(body: Control) -> void:
	var visitor=zjuding_panel=="visitor_preview"
	_zju_summary(body,"本机预览工具" if visitor else "7:55 开发者通道","访客信息草稿" if visitor else "向开发团队反馈","草稿仅保存在当前会话，不代表正式入校申请。" if visitor else "整理问题或建议后，可直接前往 GitHub 提交 Issue。")
	if visitor:
		for i in range(2):
			var key="name" if i==0 else "date"
			_label(body,"访客姓名" if i==0 else "到访日期",Rect2(20,138+i*82,338,25),14,INK)
			var input=_line_edit(body,"用于本机预览" if i==0 else "例如：08月24日",Rect2(20,170+i*82,338,39),zjuding_visitor[key]); input.max_length=24; input.name="ZjudingVisitor_"+key
			input.text_changed.connect(func(value): zjuding_visitor[key]=value)
		_label(body,"到访用途",Rect2(20,302,338,25),14,INK)
		var purpose=OptionButton.new(); purpose.position=Vector2(20,334); purpose.size=Vector2(338,39)
		for value in ["校园参观","学术交流","亲友来访"]: purpose.add_item(value)
		purpose.select(["校园参观","学术交流","亲友来访"].find(zjuding_visitor.purpose)); purpose.item_selected.connect(func(index): zjuding_visitor.purpose=purpose.get_item_text(index)); body.add_child(purpose)
	else:
		_button(body,"GitHub 仓库",Rect2(20,137,162,38),func(): OS.shell_open("https://github.com/zhu607705-coder/7-55"),Color("edf3ff"),BLUE)
		_button(body,"提交 Issue",Rect2(195,137,163,38),func():
			var first=str(zjuding_feedback.content).split("\n")[0].left(60)
			OS.shell_open("https://github.com/zhu607705-coder/7-55/issues/new?title="+("["+str(zjuding_feedback.category)+"] "+(first if not first.is_empty() else "游戏反馈")).uri_encode()+"&body="+("## 反馈内容\n\n"+str(zjuding_feedback.content)+"\n\n## 游戏\n\n7:55").uri_encode()),Color("245db8"),Color.WHITE)
		_label(body,"分类",Rect2(20,188,338,25),14)
		var category=OptionButton.new(); category.position=Vector2(20,220); category.size=Vector2(338,39)
		for value in ["功能建议","交互问题","内容校对"]: category.add_item(value)
		category.select(["功能建议","交互问题","内容校对"].find(zjuding_feedback.category)); category.item_selected.connect(func(index): zjuding_feedback.category=category.get_item_text(index)); body.add_child(category)
		_label(body,"反馈内容",Rect2(20,269,338,25),14)
		var content=TextEdit.new(); content.position=Vector2(20,300); content.size=Vector2(338,113); content.text=zjuding_feedback.content; content.placeholder_text="描述问题、复现步骤或建议"; content.wrap_mode=TextEdit.LINE_WRAPPING_BOUNDARY; body.add_child(content)
		content.text_changed.connect(func(): zjuding_feedback.content=content.text.left(500))
	var y=390 if visitor else 430
	_button(body,"清空",Rect2(20,y,107,43),func():
		if visitor: zjuding_visitor={"name":"","date":"","purpose":"校园参观"}
		else: zjuding_feedback={"category":"功能建议","content":""}
		zjuding_feedback_status="内容已清空。"; action_requested.emit("phone_refresh",{}),Color("edf3ff"),BLUE).name="ZjudingDraftClear"
	_button(body,"保存预览草稿" if visitor else "保存草稿",Rect2(140,y,218,43),func():
		if visitor: zjuding_feedback_status="请填写访客姓名和到访日期，再生成本机预览。" if str(zjuding_visitor.name).strip_edges().is_empty() or str(zjuding_visitor.date).strip_edges().is_empty() else "未提交·本机预览\n"+str(zjuding_visitor.name)+"　"+str(zjuding_visitor.date)+"·"+str(zjuding_visitor.purpose)
		else: zjuding_feedback_status="请先填写意见内容。" if str(zjuding_feedback.content).strip_edges().is_empty() else "反馈草稿已保存。"
		action_requested.emit("phone_refresh",{}),Color("245db8"),Color.WHITE).name="ZjudingDraftSave"
	_label(body,zjuding_feedback_status,Rect2(20,y+59,338,82),14,MUTED)

func _zju_sheet(root: Control) -> void:
	var overlay=Control.new(); overlay.name="ZjudingActionSheet"; overlay.size=Vector2(378,APP_HEIGHT); overlay.z_index=10; root.add_child(overlay)
	var shade=_button(overlay,"",Rect2(0,0,378,APP_HEIGHT),func(): zjuding_overlay=""; action_requested.emit("phone_refresh",{}),Color(0,0,0,.4),INK,0,Color.TRANSPARENT)
	for mode in ["normal","hover","pressed","focus"]: shade.add_theme_stylebox_override(mode,_style(Color(0,0,0,.4)))
	var top=APP_HEIGHT-400 if zjuding_overlay=="search" else APP_HEIGHT-270
	var box=_panel(overlay,Rect2(10,top,358,APP_HEIGHT-top-10),Color("f8faff"),Color("315d9e"),2,2)
	box.mouse_filter=Control.MOUSE_FILTER_STOP
	_label(box,"浙大百事通" if zjuding_overlay=="search" else "个人菜单",Rect2(12,10,277,35),21,BLUE)
	_nav(box,"close","关闭菜单",func(): zjuding_overlay=""; action_requested.emit("phone_refresh",{}),Rect2(310,7,38,38),Color("f8faff"))
	if zjuding_overlay=="search":
		var search=_line_edit(box,"输入应用、服务或关键词",Rect2(13,54,332,39),zjuding_query); search.name="ZjudingSearch"
		var result_scroll=ScrollContainer.new(); result_scroll.position=Vector2(13,105); result_scroll.size=Vector2(332,272); result_scroll.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED; box.add_child(result_scroll)
		var results=Control.new(); results.custom_minimum_size=Vector2(332,272); result_scroll.add_child(results)
		var matches: Array=[]
		for i in range(ZJU_APPS.size()):
			var app: Array=ZJU_APPS[i]
			var button=_button(results,app[1]+("　未开放" if not _zju_available(app) else "　›"),Rect2(0,0,326,39),func(): _zju_open(app[0]),Color.WHITE,BLUE,0,Color("bdcce1"))
			button.disabled=not _zju_available(app); button.name="ZjudingSearch_"+str(app[0]); button.set_meta("query_text",app[0]+" "+app[1]+" "+app[5]); matches.append(button)
		var filter=func(query: String):
			zjuding_query=query; var count=0
			for button in matches:
				button.visible=(query.strip_edges().is_empty() or str(button.get_meta("query_text")).to_lower().contains(query.strip_edges().to_lower())) and (not query.strip_edges().is_empty() or count<6)
				if button.visible: button.position.y=count*43; count+=1
			results.custom_minimum_size.y=maxf(272,count*43); results.size.y=results.custom_minimum_size.y
		search.text_changed.connect(filter); filter.call(zjuding_query)
	else:
		for i in range(3):
			var label=["个人资料","账号与安全","退出浙大钉"][i]
			_button(box,label,Rect2(13,59+i*54,332,43),func():
				if label=="退出浙大钉": zjuding_overlay=""; page_requested.emit("phone_home")
				else: _zju_open("profile"),Color.WHITE,BLUE,0,Color("315d9e")).name="ZjudingMenu_"+str(i)

func _tiyi(view: Dictionary) -> Control:
	var root = _base(Color("eef0f4"),APP_HEIGHT)
	if entry_session.phase!="ready":
		root.free()
		return _entry_loading("tiyi")
	if str(view.get("title","")).contains("补录"):
		_header(root,"浙大体艺",Color("3b79e9"),Color.WHITE,func(): page_requested.emit("phone_home"),"exit","退出浙大体艺，返回手机主页")
		_panel(root,Rect2(16,73,346,397),Color.WHITE,Color("b4becb"),4,1)
		_label(root,str(view.title),Rect2(29,92,320,50),18,Color("3b69a7"))
		_label(root,str(view.body),Rect2(29,158,320,261),13)
		return root
	# Source CSS preserves the 852/1846 image ratio at the full phone height.
	var source_height=854.0/PHONE_SCALE
	var source_width=source_height*852.0/1846.0
	var source_left=(378-source_width)/2
	_image(root,"ui/tiyi_main.png",Rect2(source_left,-40/PHONE_SCALE,source_width,source_height)).name="TiyiSourcePlate"
	var exit_button=_nav(root,"exit","退出浙大体艺，返回手机主页",func(): page_requested.emit("phone_home"),Rect2(9,7,40,44),PAPER)
	TiyiIdentity.style_exit(exit_button)
	if s.actOne.phase=="prologue":
		var hotspot=Rect2(source_left+source_width*(.141-.254/2),source_height*(.274-.088/2)-40/PHONE_SCALE,source_width*.254,source_height*.088)
		var count=_act(root,"",hotspot,"c1_tiyi_digit",null,Color.TRANSPARENT,INK,0,Color.TRANSPARENT)
		count.name="TiyiCount47"; count.tooltip_text="运动打卡次数 47"
		for mode in ["normal","hover","pressed"]: count.add_theme_stylebox_override(mode,_style(Color.TRANSPARENT))
	if s.actOne.phase in ["movement_required","reservation_briefing_required","reservation_required","movement_ready"] and s.ui.libraryFinalsPhase=="idle":
		var exercise=_act(root,"",Rect2((378-318/PHONE_SCALE)/2,APP_HEIGHT-(106+76)/PHONE_SCALE,318/PHONE_SCALE,76/PHONE_SCALE),"c2_exercise",null,Color("2f86dd") if not s.actOne.exerciseStarted else Color("4bad70"),Color.WHITE,10,Color("194f8d"))
		exercise.disabled=s.actOne.exerciseStarted; exercise.name="TiyiExercise"
		TiyiIdentity.style_exercise(exercise,s.actOne.exerciseStarted)
		_label(exercise,"课外锻炼进行中" if s.actOne.exerciseStarted else "开始虚拟定位",Rect2(10,8,263,27),13,Color.WHITE,HORIZONTAL_ALIGNMENT_CENTER)
		if not s.actOne.exerciseStarted: _label(exercise,"10 分钟跑完 3 km · 点击生成轨迹" if s.actOne.characterNamed else "请先在部门黄页确认参加者",Rect2(10,36,263,23),12,Color.WHITE,HORIZONTAL_ALIGNMENT_CENTER)

	return root

func _weather() -> Control:
	# Weather identity: clear condition silhouette, cool sky palette, calm cards.
	# Source text, weather branches, actions and lake workflow remain unchanged.
	var root = _base(Color("e5f0f6"),APP_HEIGHT)
	var rain = not s.qizhenLake.rainSafetyCleared
	_panel(root,Rect2(0,4,378,57),Color("eef4f6"))
	_panel(root,Rect2(0,59,378,3),Color("26333b"))
	_nav(root,"exit","退出天气，返回手机主页",func(): page_requested.emit("phone_home"),Rect2(11,10,40,44),Color("eef4f6"))
	_label(root,"杭州 · 紫金港",Rect2(57,12,256,40),16,Color("17212a"),HORIZONTAL_ALIGNMENT_CENTER)
	_label(root,"07:55",Rect2(313,18,53,28),12,INK,HORIZONTAL_ALIGNMENT_RIGHT)
	var hero = _panel(root,Rect2(16,75,346,219),Color("b5d7ea") if rain else Color("cbdce7"),Color("7facc4"),14,1)
	var condition_icon=WeatherIcon.new(); condition_icon.kind="rain" if rain else "cloud"
	condition_icon.position=Vector2(116,4); condition_icon.size=Vector2(114,92); condition_icon.name="WeatherConditionIcon"; hero.add_child(condition_icon)
	_label(hero,"小雨" if rain else "多云",Rect2(8,94,330,27),16,Color("102736"),HORIZONTAL_ALIGNMENT_CENTER)
	_label(hero,"18°C" if rain else "19°C",Rect2(8,123,330,56),50,Color("102736"),HORIZONTAL_ALIGNMENT_CENTER).name="WeatherTemperature"
	_label(hero,"体感温度 17°C" if rain else "体感温度 19°C",Rect2(8,184,330,22),12,Color("102736"),HORIZONTAL_ALIGNMENT_CENTER)
	var details=[["湿度","88%" if rain else "76%"],["风向","西南风 2级"],["降水","正在发生" if rain else "已经停止"],["建议",lake_apps.weather_advice(s) if lake_apps.weather_context(s) else "处理黏着物"]]
	for i in range(4):
		var rect=Rect2(16+i%2*177,306+int(i/2)*66,169,56)
		_panel(root,rect,Color("f6fbfd"),Color("b0cad8"),9,1)
		var metric_label=_label(root,details[i][0],Rect2(rect.position+Vector2(9,5),Vector2(128,18)),12,Color("536d7d"))
		metric_label.size.y=18
		_label(root,details[i][1],Rect2(rect.position+Vector2(9,26),Vector2(151,23)),13,Color("17212a"))
		if i<3:
			var metric_icon=WeatherIcon.new(); metric_icon.kind=["drop","wind","rain" if rain else "cloud"][i]
			metric_icon.position=rect.position+Vector2(137,5); metric_icon.size=Vector2(25,24); root.add_child(metric_icon)
	if lake_apps.weather_context(s):
		lake_apps.weather_card(self,root)
		return root
	var collected=s.actOne.weatherWaterTaken
	var available=s.actOne.exerciseStarted
	var water=_act(root,"",Rect2(16,439,346,88),"c2_weather_drop",null,Color("f7fbfd"),INK,10,Color("37704a") if collected else Color("388dcc"))
	water.name="WeatherWaterCard"; water.disabled=not available and not collected
	var glyph=WeatherIcon.new(); glyph.kind="drop"; glyph.position=Vector2(14,13); glyph.size=Vector2(46,60); glyph.name="WeatherCollectibleDrop"; water.add_child(glyph)
	_label(water,"水滴已收集" if collected else "接住一滴水" if available else "还没有开始外出打卡",Rect2(69,8,263,30),16)
	_label(water,"它正在道具栏里等着被使用" if collected else "这滴水看起来比天气预报更有用" if available else "你都还没有开始外出打卡，一滴雨都不会落到你身上。",Rect2(69,40,263,39),12,Color("5f6b73"))
	return root

func _directory() -> Control:
	var root = _base(Color("eef3fa"),APP_HEIGHT)
	_header(root,"部门黄页",Color("f8faff"),BLUE,func(): _return_zjuding(),"back","返回浙大钉")
	for i in range(3):
		var labels = ["校园服务台","游戏联络台","体艺值班台"]
		var phones = ["87950000","3250••••55","87951234"]
		_panel(root,Rect2(13,67+i*64,352,60),Color.WHITE,Color("c6cfd9"),0,1)
		_label(root,"☎",Rect2(23,79+i*64,37,36),24,BLUE)
		_label(root,labels[i],Rect2(70,71+i*64,275,26),16,BLUE)
		_label(root,phones[i],Rect2(70,98+i*64,275,21),12,MUTED)
	_panel(root,Rect2(13,273,352,352),Color.WHITE,Color("c6cfd9"),0,2)
	var status=_label(root,"校园身份读卡区",Rect2(81,289,258,27),16,BLUE)
	var hint=_label(root,"点击查看提示，或将身份凭证放入此处",Rect2(81,320,258,32),11,MUTED)
	_panel(root,Rect2(28,291,40,51),Color("d7e6f7"),BLUE,0,2)
	_label(root,"ID",Rect2(28,302,40,27),18,BLUE,HORIZONTAL_ALIGNMENT_CENTER)
	_label(root,"☎　联络未命名人物",Rect2(27,366,324,30),18,BLUE)
	_label(root,"请输入校园卡上的完整身份",Rect2(27,397,324,24),12,MUTED)
	_label(root,"姓名",Rect2(27,431,49,36),14)
	var name_field=_line_edit(root,"校园卡姓名",Rect2(83,431,265,39)); name_field.name="DirectoryName"
	_label(root,"学号",Rect2(27,485,49,36),14)
	var id_field=_line_edit(root,"10 位学号",Rect2(83,485,265,39)); id_field.max_length=10; id_field.name="DirectoryStudentId"
	var scan_state={"active":false}
	var scan=func(item: String):
		if item!="campusCard" or not _zju_identity() or scan_state.active: return
		scan_state.active=true; status.text="校园卡识别中"; hint.text="正在识别持卡人字段……"
		var timer=root.create_tween(); timer.tween_interval(.65)
		timer.tween_callback(func(): name_field.text="林星宇"; id_field.text="3250100755"; status.text="电子校园卡已读取"; hint.text="姓名与 10 位学号已填入"; scan_state.active=false)
	var reader=DropButton.new(); reader.position=Vector2(20,282); reader.size=Vector2(338,78); reader.name="DirectoryCardReader"; reader.tooltip_text="校园卡读卡区"
	for mode in ["normal","hover","pressed"]: reader.add_theme_stylebox_override(mode,_style(Color.TRANSPARENT))
	reader.add_theme_stylebox_override("focus",_style(Color.TRANSPARENT,BLUE,0,2))
	reader.item_dropped.connect(scan); reader.pressed.connect(func(): scan.call(str(s.native.get("selected_item","")))); root.add_child(reader)
	_button(root,"已联络：林星宇" if s.actOne.characterNamed and _zju_identity() else "☎ 呼叫",Rect2(27,555,321,46),func(): action_requested.emit("c2_identify",{"name":name_field.text,"student_id":id_field.text}),Color("245db8"),Color.WHITE).name="DirectoryCall"
	handled.append("c2_identify")
	return root

func _library(page: String, view: Dictionary) -> Control:
	if page in ["library_app","library_catalog","library_recovery","c3_lake_catalog"]: return native_library.build(self,page)
	var rows: Array = view.get("rows",[])
	var root = _base(Color("f5f6fa"),maxf(460,200+rows.size()*196))
	_header(root,str(view.get("title","图书馆")),Color("174d9d"),Color.WHITE,func():
		if page=="library_app": _return_zjuding()
		else: page_requested.emit("library_app"),"back","返回浙大钉" if page=="library_app" else "返回图书馆")
	var y = 76
	if rows.is_empty():
		_panel(root,Rect2(16,76,346,342),Color.WHITE,Color("c7d0da"),3,1)
		_label(root,str(view.get("body","")),Rect2(31,91,315,310),20,Color("34445c"))
		if page=="library_record":
			for action: Dictionary in view.get("actions",[]):
				if action.id!="lib_record": continue
				var record=_act(root,str(action.label),Rect2(16,434,346,48),str(action.id),null,BLUE,Color.WHITE,3,Color.TRANSPARENT)
				record.name="LibraryRecordAction"
				record.disabled=bool(action.get("disabled",false))
	else:
		_label(root,str(view.get("body","")),Rect2(20,67,338,102),17,MUTED)
		y = 180
		for row in rows:
			_panel(root,Rect2(13,y,352,181),Color.WHITE,Color("c9d2de"),3,1)
			_label(root,str(row.get("title","")),Rect2(27,y+12,324,42),21,BLUE)
			_label(root,str(row.get("body","")),Rect2(27,y+58,324,114),16,Color("4a596d"))
			y += 196
	return root

func _photos(view: Dictionary) -> Control:
	var photo_data: Array = JSON.parse_string(FileAccess.get_file_as_string("res://data/native_phone_photos.json"))
	var selected = str(s.native.get("lib_selected_photo",""))
	var root = _base(Color("f5f6fa"),640)
	if not selected.is_empty():
		for photo in photo_data:
			if photo.id != selected: continue
			_header(root,str(photo.title),Color.WHITE,INK,func(): action_requested.emit("lib_close_photo",null),"back","返回相册")
			_image(root,str(photo.image),Rect2(14,72,350,335))
			_label(root,"%s · %s\n%s · %s" % [photo.file,photo.location,photo.capturedAt,photo.detail],Rect2(21,422,336,104),18)
			if photo.get("storyRole","") == "library_clue":
				_label(root,"旧照与刚拍下的标签内容一致。" if s.ui.libraryFinalsPuzzle.photoDimmed else "先把刚拍下的主照片亮度降到 20% 以下。",Rect2(21,530,336,55),17,MUTED)
				if s.ui.libraryFinalsPuzzle.photoDimmed and not s.ui.libraryFinalsPuzzle.itemReportGenerated: _act(root,"用旧照补全物品报告",Rect2(27,591,324,46),"lib_item_report",null,Color("d7e5d7"))
			_act(root,"返回相册",Rect2(267,6,100,41),"lib_close_photo",null,Color("f5f6fa"),MUTED,0,Color.TRANSPARENT)
			return root
	_header(root,"照片",Color.WHITE,INK,func(): page_requested.emit("phone_home"),"exit","退出照片，返回手机主页")
	if not s.ui.libraryFinalsPuzzle.photoCaptured:
		_label(root,str(view.get("body","没有可显示的书包照片。")),Rect2(30,190,318,130),20,MUTED,HORIZONTAL_ALIGNMENT_CENTER)
		return root
	_label(root,"IMG_0755.JPG",Rect2(17,64,217,35),21)
	_label(root,"022 · 一层书库",Rect2(217,67,147,30),14,MUTED,HORIZONTAL_ALIGNMENT_RIGHT)
	var evidence_surface = PhotoEvidence.new()
	evidence_surface.position = Vector2(16,107)
	evidence_surface.configure(float(s.ui.brightness),s.ui.libraryFinalsPuzzle,bool(s.native.get("settings",{}).get("reduced_motion",false)))
	root.add_child(evidence_surface)
	var readable: bool = evidence_surface.exposure.readable
	_label(root,"控制中心亮度　%s%%" % int(s.ui.brightness),Rect2(22,419,333,35),19)
	_label(root,"识别稳定，标签内容已锁定。" if readable else "光照太亮了，识别器无法对焦。" if float(s.ui.brightness)>56 else "标签边缘已出现，识别信号仍不稳定。",Rect2(22,457,333,56),18,MUTED)
	var y = 527
	if readable:
		_label(root,"旧相册里还有一张同场景照片",Rect2(20,y,338,39),19)
		_act(root,"查看 022 旧照",Rect2(22,y+44,334,45),"lib_view_photo","seat_022_clue",Color("e7eddf"))
		y += 105
	_act(root,"最近 12 张",Rect2(15,y,170,42),"lib_photo_filter","recent",Color("e4e8ed"))
	_act(root,"校园与日常",Rect2(193,y,170,42),"lib_photo_filter","campus_life",Color("e4e8ed"))
	y += 55
	var index = 0
	for photo in photo_data:
		if s.native.get("lib_photo_filter","recent")=="campus_life" and photo.albumId != "campus_life": continue
		var x = 14+(index%3)*119
		var top = y+int(index/3)*119
		var thumbnail = _act(root,"",Rect2(x,top,111,111),"lib_view_photo",photo.id,Color.WHITE,INK,2,Color("ccd2da"))
		_image(thumbnail,str(photo.image),Rect2(3,3,105,83))
		_label(thumbnail,str(photo.file).substr(4,4),Rect2(4,88,103,18),13,MUTED,HORIZONTAL_ALIGNMENT_CENTER)
		index += 1
	root.custom_minimum_size.y = y+ceil(index/3.0)*119+24
	root.size.y = root.custom_minimum_size.y
	return root

func _settings(view: Dictionary) -> Control:
	var rows = [["network","网","校园网络与移动数据","查看当前连接"],["sound","声","声音与振动","背景音乐"],["display","显","显示与辅助","亮度与可读性"],["desktop","桌","桌面与壁纸","移动图标与恢复排布"],["apps","应","应用管理","恢复可选应用"],["privacy","权","隐私与权限","相机、照片与网络"],["activity","电","电池与后台活动","检查 07:55 记录"],["about","系","系统诊断与关于","存档与运行状态"]]
	var title = "设置"
	for entry in rows:
		if entry[0]==settings_page: title = entry[2]
	var root = _base(Color("d9e0e3"),740 if settings_page=="desktop" else 620)
	_panel(root,Rect2(0,0,378,60),Color("f2f0e6"),Color("17202a"),0,2)
	_button(root,"‹",Rect2(7,11,36,38),func():
		if settings_page=="root": page_requested.emit("phone_home")
		else: settings_page="root"; action_requested.emit("phone_refresh",{}),Color("f2f0e6"),INK,0,Color.TRANSPARENT).name="SettingsBack"
	_label(root,"PHONE SYSTEM",Rect2(52,7,245,18),10,MUTED)
	_label(root,title,Rect2(52,27,266,25),17,Color("17202a"))
	_label(root,"07:55",Rect2(318,14,52,32),12,INK)
	if settings_page=="root":
		var search = _line_edit(root,"搜索设置项",Rect2(13,72,352,40),settings_query)
		search.name="SettingsSearch"
		var controls: Array = []
		for index in range(rows.size()):
			var entry: Array = rows[index]
			var row = _button(root,"",Rect2(13,125+index*59,352,59),func(): settings_page=entry[0]; action_requested.emit("phone_refresh",{}),Color("e9edf0"),INK,0,Color("9ca8ad"))
			row.name="Settings_"+entry[0]
			_panel(row,Rect2(9,13,30,30),Color("1e6f9b"))
			_label(row,entry[1],Rect2(9,13,30,30),16,Color.WHITE,HORIZONTAL_ALIGNMENT_CENTER)
			_label(row,entry[2],Rect2(49,7,273,24),16,Color("17202a"))
			_label(row,entry[3],Rect2(49,32,273,18),11,MUTED)
			_label(row,"›",Rect2(326,12,20,32),24,MUTED)
			controls.append(row)
		var filter = func(query: String):
			settings_query=query
			var y=125
			for i in range(rows.size()):
				controls[i].visible = query.strip_edges().is_empty() or (str(rows[i][2])+str(rows[i][3])).contains(query.strip_edges())
				if controls[i].visible: controls[i].position.y=y; y+=59
		search.text_changed.connect(filter)
		filter.call(settings_query)
		return root
	_label(root,title,Rect2(13,75,352,36),21,Color("17202a"))
	match settings_page:
		"network":
			_settings_pairs(root,[["当前网络",{"campus_wifi":"ZJUWLAN","cellular":"移动数据","offline":"离线"}.get(s.networkMode,"")],["CC98","可访问" if s.networkMode=="campus_wifi" else "等待校园网"]],125)
			_page(root,"打开控制中心切换网络",Rect2(13,232,352,44),"control_center",Color("f2f0e6"))
		"sound":
			var button=_act(root,"",Rect2(13,125,352,70),"phone_music_mute",null,Color("f2f0e6"))
			button.name="BackgroundMusicToggle"
			_label(button,"背景音乐",Rect2(12,6,260,30),18)
			_label(button,"语音与操作音效保持开启",Rect2(12,37,260,24),12,MUTED)
			_panel(button,Rect2(277,18,61,32),Color("1e6f9b"))
			_label(button,"关闭" if s.ui.musicMuted else "开启",Rect2(277,18,61,32),16,Color.WHITE,HORIZONTAL_ALIGNMENT_CENTER)
		"display":
			_panel(root,Rect2(13,125,352,100),Color("e9edf0"),INK,0,2)
			_label(root,"屏幕亮度",Rect2(26,136,268,29),18)
			var value=_label(root,str(int(s.ui.brightness))+"%",Rect2(303,136,50,29),18,MUTED,HORIZONTAL_ALIGNMENT_RIGHT)
			_brightness_slider(root,Rect2(26,178,326,34),100,"phone_settings_brightness",value).name="SettingsBrightness"
			_label(root,"照片取证会读取这个亮度值。",Rect2(13,240,352,44),14,Color("505b61"))
		"desktop":
			_label(root,"桌面也支持长按图标进入编辑。这里可用按钮精确调整顺序。",Rect2(13,115,352,52),14,Color("505b61"))
			_panel(root,Rect2(13,178,352,62),Color("18242d"))
			_label(root,"旧截图第一排",Rect2(25,184,328,19),11,Color("8dc4df"))
			_label(root,"微信　浙大钉　照片　CC98",Rect2(25,207,328,27),18,Color("e9edf0"))
			var order=Utilities.normalized_order(s.ui.homeAppOrder)
			for i in range(order.size()):
				var id=str(order[i])
				var y=253+i*43
				_panel(root,Rect2(13,y,352,43),Color("e9edf0"),Color("a7b0b4"),0,1)
				_label(root,"%s. %s" % [i+1,Utilities.LABELS[id]],Rect2(24,y+5,238,33),16)
				var up=_act(root,"↑",Rect2(272,y+6,39,31),"phone_app_move",{"id":id,"offset":-1},Color("f2f0e6")); up.disabled=i==0; up.name="MoveUp_"+id
				var down=_act(root,"↓",Rect2(316,y+6,39,31),"phone_app_move",{"id":id,"offset":1},Color("f2f0e6")); down.disabled=i==order.size()-1; down.name="MoveDown_"+id
			_act(root,"恢复默认顺序",Rect2(13,696,352,40),"phone_app_reset",null,Color("f2f0e6")).name="RestoreDefaultOrder"
		"apps":
			var y=122
			if s.ui.hiddenHomeAppIds.is_empty(): _label(root,"没有从桌面移除的可选应用。",Rect2(13,y,352,46),15,MUTED); y+=52
			for id in s.ui.hiddenHomeAppIds:
				_panel(root,Rect2(13,y,352,48),Color("e9edf0"),INK,0,1)
				_label(root,Utilities.LABELS.get(id,id),Rect2(24,y+5,249,38),18)
				_act(root,"恢复",Rect2(287,y+6,65,36),"phone_app_restore",id,Color("f2f0e6")).name="Restore_"+str(id)
				y+=52
			_label(root,"当前允许从桌面移除　浙大体艺" if Utilities.can_remove(s,"tiyi") else "当前阶段还没有可删除的可选应用。",Rect2(13,y+5,352,54),15,MUTED)
			_label(root,"微信、照片、CC98、浙大钉、设置等剧情应用只能移动。",Rect2(13,y+70,352,65),15,MUTED)
		"privacy": _settings_pairs(root,[["相机","取证时使用"],["照片","保存剧情照片"],["校园网络","CC98 与校内服务"]],125)
		"activity":
			_label(root,"当前没有需要核验的剧情记录。",Rect2(13,117,352,43),14,MUTED)
			var records=[["07:48","天气","天气卡片刷新","1%"],["07:55","照片","重新建立 IMG_0755 索引","7%"],["07:52","微信","同步两条新消息","1%"],["07:55","时钟","系统时间被后台唤醒","5%"],["07:55","浙大钉","恢复 A2 室内定位","6%"],["08:02","CC98","读取热门话题缓存","1%"]]
			for i in range(records.size()):
				var r: Array=records[i]; var y=174+i*60
				_panel(root,Rect2(13,y,352,60),Color("e9edf0"),Color("a7b0b4"),0,1)
				_label(root,r[0],Rect2(22,y+14,50,30),12)
				_label(root,r[1],Rect2(79,y+5,231,25),16)
				_label(root,r[2],Rect2(79,y+30,231,23),12,MUTED)
				_label(root,r[3],Rect2(322,y+14,33,30),12,MUTED,HORIZONTAL_ALIGNMENT_RIGHT)
		"about":
			_settings_pairs(root,[["游戏时间","07:55"],["存档","自动保存与上一版本恢复"],["桌面应用",str(s.ui.homeAppOrder.size()-s.ui.hiddenHomeAppIds.size())+" 个可见"]],125)
			_act(root,"存档管理",Rect2(13,289,352,44),"native_save_tools",null,Color("f2f0e6")).name="NativeSaveTools"
			_label(root,"原生版工具 · 导入、导出与开发调试",Rect2(13,345,352,30),12,MUTED)
	return root

func _settings_pairs(root: Control, entries: Array, start: float) -> void:
	for i in range(entries.size()):
		_panel(root,Rect2(13,start+i*48,352,48),Color("e9edf0"),Color("a7b0b4"),0,1)
		_label(root,str(entries[i][0]),Rect2(24,start+i*48+8,149,32),16)
		_label(root,str(entries[i][1]),Rect2(158,start+i*48+8,194,32),13,Color("58666d"),HORIZONTAL_ALIGNMENT_RIGHT)

func _line_edit(root: Control, placeholder: String, rect: Rect2, text: String = "") -> LineEdit:
	var input=LineEdit.new()
	input.position=rect.position; input.size=rect.size
	input.placeholder_text=placeholder; input.text=text
	NativeUi.apply_input(input,Color("fffaf0"),INK,INK,0,16,Vector2(8,4))
	root.add_child(input)
	return input

func _brightness_slider(root: Control, rect: Rect2, maximum: float, id: String, output: Label) -> HSlider:
	var slider=HSlider.new()
	slider.position=rect.position; slider.size=rect.size
	slider.min_value=0; slider.max_value=maximum; slider.value=s.ui.brightness
	slider.value_changed.connect(func(v): output.text=str(int(v))+"%")
	slider.drag_ended.connect(func(changed):
		if changed: action_requested.emit(id,slider.value))
	slider.gui_input.connect(func(event):
		if event is InputEventKey and not event.pressed and event.keycode in [KEY_LEFT,KEY_RIGHT,KEY_HOME,KEY_END]: action_requested.emit(id,slider.value))
	root.add_child(slider)
	handled.append(id)
	return slider

func _animate_flash(root: Control, label: Label) -> void:
	root.ready.connect(func():
		var tween = label.create_tween().set_loops()
		tween.tween_property(label,"modulate:a",.24,.21)
		tween.tween_property(label,"modulate:a",1.0,.21)
	)

func _animate_rotation(root: Control, visual: Control, kind: String) -> void:
	root.ready.connect(func():
		var start_ms = Time.get_ticks_msec()
		visual.pivot_offset = visual.size/2
		var tween = visual.create_tween()
		if kind == "gear":
			tween.tween_property(visual,"rotation",PI,.675)
			tween.tween_property(visual,"rotation",PI*1.78,.225)
			tween.tween_property(visual,"position",visual.position+Vector2(-8,245),.60).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
		else:
			tween.tween_property(visual,"rotation",deg_to_rad(7),.44)
			tween.tween_property(visual,"rotation",deg_to_rad(-4),.33)
			tween.tween_property(visual,"rotation",0.0,.33)
		tween.tween_callback(func(): action_requested.emit("c1_gear_rotated" if kind=="gear" else "c1_slash_rotated",{"elapsedMs":int(round(tween.get_total_elapsed_time()*1000.0))}))
	)

func _app_icon(root: Control, id: String, factor: float = 1.0) -> void:
	var icon = Control.new()
	icon.size = Vector2(48,48)
	icon.scale = Vector2.ONE*factor
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(icon)
	match id:
		"wechat":
			_panel(icon,Rect2(6,10,27,21),Color.WHITE,Color.TRANSPARENT,11)
			_panel(icon,Rect2(21,20,23,19),Color("edf8ed"),Color.TRANSPARENT,10)
			for position in [Vector2(13,17),Vector2(23,17),Vector2(26,26),Vector2(35,26)]: _panel(icon,Rect2(position,Vector2(3,3)),Color("61b58c"))
		"tiyi":
			_panel(icon,Rect2(26,6,8,8),Color.WHITE,Color.TRANSPARENT,4)
			var body = _panel(icon,Rect2(21,16,8,16),Color.WHITE)
			body.rotation = .25
			for limb in [[27,19,14,5,-.55],[13,20,14,5,.65],[13,32,20,5,-.78],[25,32,17,5,.55]]:
				var segment = _panel(icon,Rect2(limb[0],limb[1],limb[2],limb[3]),Color.WHITE)
				segment.rotation = limb[4]
		"zjuding": _image(icon,"ui/zjuding.png",Rect2(3,3,42,42))
		"photos":
			for petal in [[10,11,"e88a9f"],[25,11,"7fb0e8"],[10,27,"8fce7c"],[25,27,"e8a05f"]]: _panel(icon,Rect2(petal[0],petal[1],16,16),Color(petal[2]),Color.TRANSPARENT,8)
			_panel(icon,Rect2(20,20,12,12),Color("f5c542"),Color.TRANSPARENT,6)
		"control_center":
			_panel(icon,Rect2(7,9,22,26),Color.TRANSPARENT,Color.WHITE,0,3)
			_panel(icon,Rect2(21,18,21,23),Color.TRANSPARENT,Color.WHITE,0,3)
		"clock":
			_panel(icon,Rect2(6,6,36,36),Color("fff6e1"),Color("343333"),18,3)
			_panel(icon,Rect2(23,13,3,13),Color("343333"))
			_panel(icon,Rect2(24,24,12,3),Color("343333"))
		"cc98": _label(icon,"CC98",Rect2(3,8,42,31),19,Color.WHITE,HORIZONTAL_ALIGNMENT_CENTER)
		"settings": _label(icon,"✱",Rect2(3,3,42,42),37,Color.WHITE,HORIZONTAL_ALIGNMENT_CENTER)
		"voice_memos":
			_panel(icon,Rect2(20,10,9,22),Color.WHITE,Color.TRANSPARENT,5)
			_panel(icon,Rect2(14,23,20,14),Color.TRANSPARENT,Color.WHITE,8,2)
			_panel(icon,Rect2(23,36,3,5),Color.WHITE)
		_:
			_panel(icon,Rect2(11,9,26,31),Color("eef3ec"),Color("4a7472"),2,2)
			for y in [17,24,31]: _panel(icon,Rect2(16,y,16,2),Color("86aaa2"))

func _entry_loading(app: String) -> Control:
	var root:=_base(Color.WHITE,APP_HEIGHT)
	root.name="TiyiEntry" if app=="tiyi" else "ZjudingEntry"
	root.set_meta("handles_all_actions",true)
	if app=="zjuding":
		var loading:=preload("res://scripts/ui/native_zjuding_loading_art.gd").new()
		loading.size=Vector2(378,APP_HEIGHT)
		root.add_child(loading)
	else:
		var loading:=_image(root,"ui/"+app+"_loading.png",Rect2(0,0,378,APP_HEIGHT))
		loading.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_COVERED
	var dots: Array=[]
	if app in ["tiyi","zjuding"]:
		for i in range(3):
			var dot:=_panel(root,Rect2(Vector2((378*PHONE_SCALE-52)/2+i*20,APP_HEIGHT*PHONE_SCALE-(128 if app=="tiyi" else 96)-12)/PHONE_SCALE,Vector2(12,12)/PHONE_SCALE),Color("4d7ed9") if app=="tiyi" else Color("9db9e8"),Color(0,0,0,.25),0,2)
			dot.name="EntryLoadingDot"+str(i); dot.set_meta("rest_y",dot.position.y); dots.append(dot)
	if app=="zjuding" and entry_session.blocked_hint_sent:
		var caption_height: float=PhoneNotice.FONT.get_height(int(round(NativeUi.FONT_BODY/PHONE_SCALE)))+14/PHONE_SCALE
		_opening_chip(root,"请连接校园网后重新进入",Vector2(189,APP_HEIGHT-60/PHONE_SCALE-caption_height/2)).name="ZjudingReentryHint"
	_page(root,"退出",Rect2(130,APP_HEIGHT-56/PHONE_SCALE,118,36/PHONE_SCALE),"phone_home").name="TiyiLoadingExit" if app=="tiyi" else "ZjudingLoadingExit"
	if app=="tiyi": EntryVisual.bind_crash(root,entry_session,PHONE_SCALE,dots)
	else: EntryVisual.bind_loading(root,entry_session,PHONE_SCALE,dots)
	return root

func _drop_action(root: Control, rect: Rect2, id: String) -> Button:
	var button=DropButton.new(); button.position=rect.position; button.size=rect.size
	for mode in ["normal","hover","pressed","focus"]: button.add_theme_stylebox_override(mode,_style(Color.TRANSPARENT))
	button.item_dropped.connect(func(item): action_requested.emit(id,item))
	button.pressed.connect(func(): action_requested.emit(id,str(s.native.get("selected_item",""))))
	root.add_child(button); handled.append(id)
	return button

func _animate_tower_key(root: Control) -> void:
	var key=_panel(root,_home_rect(348,220,30,8),Color("eed45c"),INK,0,2)
	_panel(key,Rect2(Vector2(23,-4)/PHONE_SCALE,Vector2(14,14)/PHONE_SCALE),Color("90969d"),INK,7,2)
	key.pivot_offset=Vector2(0,4)
	root.ready.connect(func():
		presentation_requested.emit("tower_key_insert")
		var tween=key.create_tween()
		tween.tween_property(key,"position",_home_rect(327,220,30,8).position,.65)
		tween.tween_callback(func(): presentation_requested.emit("tower_key_rotate"))
		tween.tween_property(key,"rotation",PI/2,.8)
		tween.tween_interval(.25)
		tween.tween_callback(func(): action_requested.emit("c1_tower_complete",{"elapsedMs":int(round(tween.get_total_elapsed_time()*1000))})))
