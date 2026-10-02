extends RefCounted
## Source-native mobile library. UI-local navigation and draft selection only.
## All booking, catalog evidence and recovery transitions are existing chapter intents.
const BLUE=Color("174d9d")
const INK=Color("222322")
const MUTED=Color("637080")
const DropInput=preload("res://scripts/ui/phone_drop_line_edit.gd")
const DocumentModal=preload("res://scripts/ui/phone_document_modal.gd")
const DropButton=preload("res://scripts/ui/phone_drop_button.gd")
const RECOVERY=[
	["bag_non_person_proof","书包非本人证明","bagNonPersonProof","失物招领 · 前台工作人员"],
	["seat_022_receipt","022 座位小票","seat022Receipt","一层书库 · 022 桌面夹缝"],
	["library_presence_proof","本人来过证明","libraryPresenceProof","浙大体艺 · 到馆记录补录"]
]
const COVERS={"correct":"three_minute_leave_method","distractor-1":"three_minute_leave_art","distractor-2":"three_minute_pause_application","distractor-3":"three_minute_rise_boundaries","distractor-4":"three_minute_empty_seat"}
var local_page="home"
var selected_library="基础馆"
var selected_room="一层书库"
var selected_seat=""
var space_mode="list"
var seat_view="map"
var seat_section=0
var rail_collapsed=false
var selected_date="07月10日 · 今天"
var selected_time="00:01 - 23:59"
var seat_filter="全部座位"
var sheet=""
var catalog_query=""
var catalog_advanced=false
var catalog_submitted=false
var catalog_selected=""
var qizhen_catalog_visible=false
var scroll_positions={}
var content: Dictionary={}

func reset() -> void:
	local_page="home"; sheet=""; scroll_positions={}
	selected_library="基础馆"; selected_room="一层书库"; selected_seat=""
	space_mode="list"; seat_view="map"; seat_section=0; rail_collapsed=false
	selected_date="07月10日 · 今天"; selected_time="00:01 - 23:59"; seat_filter="全部座位"
	catalog_query=""; catalog_advanced=false; catalog_submitted=false; catalog_selected=""; qizhen_catalog_visible=false

func data() -> Dictionary:
	if content.is_empty(): content=JSON.parse_string(FileAccess.get_file_as_string("res://data/source/library-finals.content.json"))
	return content

func refresh(b) -> void: b.action_requested.emit("phone_refresh",{})
func goto(b, page: String) -> void: local_page=page; sheet=""; refresh(b)
func open_recovery(b) -> void:
	if b.s.ui.libraryFinalsPhase=="top_ten_reached": b.action_requested.emit("lib_recovery_open",null)
	else: b.page_requested.emit("library_recovery")

func build(b, page: String) -> Control:
	if page in ["library_catalog","c3_lake_catalog"]: return catalog(b)
	if page=="library_recovery": return recovery(b)
	if b.s.ui.librarySeatReserved: selected_seat=str(b.s.ui.librarySelectedSeat)
	match local_page:
		"spaces": return spaces(b)
		"seat": return seats(b)
	return home(b)

func base(b, title: String, back: Callable) -> Control:
	var root: Control=b._base(Color("f6f7fa"),b.APP_HEIGHT)
	root.set_meta("handles_all_actions",true)
	b._header(root,title,Color.WHITE,INK,back,"back","返回图书馆" if local_page!="home" else "返回浙大钉")
	return root

func body(b, root: Control, key: String, height: float, bottom: float=0, background: Color=Color.TRANSPARENT) -> Control:
	var scroll=ScrollContainer.new(); scroll.name="LibraryScroll_"+key; scroll.position=Vector2(0,54); scroll.size=Vector2(378,b.APP_HEIGHT-54-bottom); scroll.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED; root.add_child(scroll)
	var inner=Control.new(); inner.custom_minimum_size=Vector2(370,maxf(scroll.size.y,height)); inner.size=inner.custom_minimum_size; scroll.add_child(inner)
	if background.a>0: b._panel(inner,Rect2(0,0,378,inner.size.y),background)
	scroll.get_v_scroll_bar().value_changed.connect(func(value): scroll_positions[key]=int(value))
	root.ready.connect(func(): scroll.scroll_vertical=int(scroll_positions.get(key,0)))
	return inner

func bottom_nav(b, root: Control, spaces_page: bool=false) -> void:
	b._panel(root,Rect2(0,b.APP_HEIGHT-60,378,60),Color.WHITE,Color("dce0e6"),0,1)
	for i in range(2):
		b._label(root,["⌂","◎"][i],Rect2(i*189,b.APP_HEIGHT-56,189,27),22,Color("666666"),HORIZONTAL_ALIGNMENT_CENTER)
		b._label(root,"首页" if i==0 else "我的中心" if spaces_page else "我的",Rect2(i*189,b.APP_HEIGHT-28,189,22),12,Color("666666"),HORIZONTAL_ALIGNMENT_CENTER)

func home(b) -> Control:
	var root=base(b,"浙大移动图书馆",func(): b._return_zjuding())
	var inner=body(b,root,"home",805,60)
	b._panel(inner,Rect2(0,0,378,132),Color("2b8bc9"))
	b._panel(inner,Rect2(-27,80,240,90),Color("357b56"),Color.TRANSPARENT,65)
	b._panel(inner,Rect2(151,80,285,90),Color("2c6b4e"),Color.TRANSPARENT,65)
	for flower in [[110,"ffd95d"],[135,"ef7f7f"],[164,"74d3f1"],[194,"f7e6be"],[232,"ef7f7f"]]: b._panel(inner,Rect2(flower[0],115,9,9),Color(flower[1]))
	var portrait: TextureRect=b._image(inner,"ui/library_avatar.png",Rect2(14,16,71,71)); portrait.name="LibraryReaderPortrait"
	var identity=b.s.actOne.inventoryRecovered and b.s.items.campusCard
	b._label(inner,"林星宇" if identity else "▓▓▓",Rect2(97,22,194,28),19,Color.WHITE)
	b._label(inner,"3250100755 ▱" if identity else "▓▓▓▓▓▓▓▓",Rect2(97,58,194,24),14,Color.WHITE)
	b._label(inner,"✉",Rect2(313,19,48,44),28,Color.WHITE,HORIZONTAL_ALIGNMENT_CENTER)
	b._label(inner,"?",Rect2(336,92,24,27),20,Color.WHITE,HORIZONTAL_ALIGNMENT_CENTER)
	b._panel(inner,Rect2(14,139,345,251),Color.WHITE,Color("a8a59d"),0,3)
	var reservation=b.s.actOne.phase in ["reservation_required","movement_ready","complete"] or b.s.ui.librarySeatReserved
	var recovery_open=b.s.ui.libraryFinalsPhase in ["top_ten_reached","recovery_application","pass_ready","backpack_removed","seat_recovered","friend_contacted"]
	var apps=[
		["catalog","馆藏检索","⌕",b.s.ui.libraryFinalsPuzzle.catalogUnlocked],
		["borrow","借阅信息","阅",false],["reserve","座位预约","24",reservation],["space","空间预约","⌂",false],
		["recommend","求是荐书","荐",false],["new","新书通报","新",false],["citation","查收查引","引",false],["fees","图书馆缴费","¥",false],
		["recovery","022恢复申请","PASS",recovery_open],["return","返回现场","↗",b.s.ui.libraryFinalsPhase!="idle"]]
	for i in range(apps.size()):
		var app: Array=apps[i]; var point=Vector2(23+(i%4)*83,149+int(i/4)*79)
		if not app[3]: b._label(inner,"xxx",Rect2(point,Vector2(75,71)),12,MUTED,HORIZONTAL_ALIGNMENT_CENTER).name="LibraryLocked_"+app[0]; continue
		var open_app=func():
			match app[0]:
				"catalog": b.page_requested.emit("library_catalog")
				"reserve": goto(b,"spaces")
				"recovery": open_recovery(b)
				"return": b.action_requested.emit("lib_enter",null)
		var target: Button=b._button(inner,"",Rect2(point,Vector2(75,71)),open_app,Color.TRANSPARENT,INK,0,Color.TRANSPARENT)
		target.name="LibraryApp_"+app[0]
		b._panel(target,Rect2(15,0,46,46),Color("0f66b7"),Color("073f7c"),0,3)
		b._label(target,str(app[2]),Rect2(15,0,46,46),14 if app[0]=="recovery" else 23,Color.WHITE,HORIZONTAL_ALIGNMENT_CENTER)
		b._label(target,str(app[1]),Rect2(0,50,75,21),10,INK,HORIZONTAL_ALIGNMENT_CENTER)
	var y=403
	if b.s.ui.libraryFinalsPhase=="top_ten_reached":
		var alert: Button=b._button(inner,"",Rect2(14,y,345,61),func(): open_recovery(b),Color("e9f3ff"),BLUE,0,BLUE); alert.name="LibraryRecoveryAlert"
		b._label(alert,"022 座位恢复申请已开放",Rect2(12,6,303,24),15,BLUE)
		b._label(alert,"帖子当前排名 01，可提交三项证明。",Rect2(12,30,303,23),12,MUTED)
		y+=74
	for i in range(3):
		b._panel(inner,Rect2(14,y,345,112),Color.WHITE,Color("a7a49c"),0,3)
		b._label(inner,"xxx",Rect2(26,y+9,268,26),19)
		b._label(inner,"xxx",Rect2(307,y+9,39,26),12,Color("a4722f"))
		for row in range(2):
			b._panel(inner,Rect2(26,y+42+row*31,319,1),Color("d2cec4"))
			b._label(inner,"xxx",Rect2(26,y+45+row*31,268,24),13)
			b._label(inner,"xxx",Rect2(307,y+45+row*31,39,24),12,Color("a4722f"))
		y+=124
	inner.custom_minimum_size.y=y+12
	bottom_nav(b,root)
	return root

func rooms(b) -> Array:
	if selected_library=="基础馆":
		var available=159 if b.s.ui.librarySeatReserved else 160
		return [["负一层书库","负一层",160,160,"foundation"],["一层书库","一层",160,available,"foundation"],["二层书库","二层",160,160,"foundation"]]
	if selected_library=="主馆": return [["二层南","二层",32,32,"south"],["二层北","二层",176,171,"north"],["三层东","三层",48,47,"east"],["三层南","三层",112,112,"south"]]
	return []

func enter_room(b, room: String) -> void:
	if b.s.ui.librarySeatReserved and (selected_library!="基础馆" or room!="一层书库"):
		return
	selected_room=room; seat_section=0
	if not b.s.ui.librarySeatReserved: selected_seat=""
	goto(b,"seat")

func spaces(b) -> Control:
	var root=base(b,"图书馆空间预约...",func(): goto(b,"home"))
	# This source page explicitly uses the platform sans-serif stack, unlike the pixel apps.
	var sans=SystemFont.new(); sans.font_names=PackedStringArray(["PingFang SC","Microsoft YaHei","Noto Sans CJK SC","sans-serif"]); sans.fallbacks=[load("res://assets/rpg/fonts/fusion_pixel_12px_proportional_zh_hans.ttf")]
	var page_theme=Theme.new(); page_theme.default_font=sans; root.theme=page_theme
	var width=25 if rail_collapsed else 48
	var rail_background: Panel=b._panel(root,Rect2(0,54,width,b.APP_HEIGHT-114),Color("061a49"))
	var rail: Button=b._button(root,"»\n\n座\n位\n预\n约" if not rail_collapsed else "»",Rect2(0,61,width,265),func(): rail_collapsed=not rail_collapsed; refresh(b),Color.TRANSPARENT,Color.WHITE,0,Color.TRANSPARENT); rail.name="LibraryReservationRail"
	var available_rooms=rooms(b)
	var inner=body(b,root,"spaces",170+available_rooms.size()*150,60,Color.WHITE)
	# The rail overlays the internal scroll region, as in the source two-column shell.
	root.move_child(rail_background,root.get_child_count()-1)
	root.move_child(rail,root.get_child_count()-1)
	var left=width+13; var working_width=365-left
	for i in range(2):
		var active=space_mode==["list","quick"][i]
		var button: Button=b._button(inner,["列表","快速选择"][i],Rect2(width+i*(378-width)/2.0,0,(378-width)/2.0,46),func(): space_mode=["list","quick"][i]; refresh(b),Color("39589e") if active else Color("122e66"),Color.WHITE,0,Color.TRANSPARENT); button.name="LibrarySpaceMode_"+["list","quick"][i]
	b._label(inner,"显示 %s 空间" % available_rooms.size(),Rect2(left+8,63,142,34),14,Color("737373"))
	var library_choice: Button=b._button(inner,selected_library+" ▾",Rect2(224,58,136,49),func(): sheet="libraries"; refresh(b),Color.WHITE,INK,4,Color("bdbdbd")); library_choice.name="LibraryChooseBuilding"; library_choice.add_theme_font_size_override("font_size",15)
	b._panel(inner,Rect2(left,117,working_width,1),Color("aaaaaa"))
	var y=138
	for i in range(available_rooms.size()):
		var room: Array=available_rooms[i]
		if space_mode=="quick":
			var quick: Button=b._button(inner,str(room[0])+"\n空闲 "+str(room[3]),Rect2(left+(i%2)*(working_width/2+2),132+int(i/2)*104,working_width/2-4,94),func(): enter_room(b,str(room[0])),Color("eef3fa"),BLUE,0,Color("acbbce")); quick.name="LibraryRoom_"+str(i); quick.add_theme_font_size_override("font_size",16)
			continue
		var art: TextureRect=b._image(inner,"ui/library_room_"+str(room[4])+".png",Rect2(left,y,105,116)); art.name="LibraryRoomPhoto_"+str(i); art.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_COVERED
		if room[4]=="foundation":
			var crop=AtlasTexture.new(); crop.atlas=load("res://assets/ui/library_foundation_reference.jpg"); crop.region=Rect2(173,684,298,328); art.texture=crop
		b._panel(inner,Rect2(left,y,60,26),Color("ef8d00"))
		b._label(inner,selected_library,Rect2(left+5,y+2,55,22),13,Color.WHITE)
		b._label(inner,str(room[0]),Rect2(left+122,y+2,working_width-122,28),18)
		b._label(inner,"座位 %s　空闲 %s" % [room[2],room[3]],Rect2(left+122,y+41,working_width-122,25),12,Color("888888"))
		var reserve: Button=b._button(inner,"预约",Rect2(left+122,y+80,64,34),func(): enter_room(b,str(room[0])),Color("39589e"),Color.WHITE,2,Color.TRANSPARENT); reserve.name="LibraryRoom_"+str(i); reserve.add_theme_font_size_override("font_size",15)
		b._panel(inner,Rect2(left,y+137,working_width,1),Color("d2d2d2")); y+=150
	b._label(inner,"没有更多了" if not available_rooms.is_empty() else "该馆暂未开放可预约空间",Rect2(left,y,working_width,46),14,Color("999999"),HORIZONTAL_ALIGNMENT_CENTER)
	bottom_nav(b,root,true)
	if not sheet.is_empty(): add_sheet(b,root)
	return root

func seat_count(b) -> int:
	for room in rooms(b):
		if room[0]==selected_room: return int(room[2])
	return 160

func select_seat(b, root: Control, seat: String) -> void:
	if b.s.ui.libraryFinalsPhase!="idle": b._toast(root,"本章的 022 状态由图书馆现场记录管理。"); return
	if b.s.ui.librarySeatReserved: b._toast(root,"座位 %s 已预约，不能在当前任务中改签。" % selected_seat); return
	selected_seat=seat; refresh(b)

func seats(b) -> Control:
	var root=base(b,"图书馆空间预约...",func(): goto(b,"spaces"))
	var count=seat_count(b)
	var active=b.s.ui.libraryFinalsPhase in ["occupied_seat_found","evidence_gathering","bd_briefing","top_ten_rising","top_ten_reached","recovery_application","pass_ready","backpack_removed","seat_recovered","friend_contacted"]
	var inner=body(b,root,"seat",772,60,Color("f7f7f5"))
	b._panel(inner,Rect2(0,0,378,91),Color.WHITE,Color("bdbab4"),0,1)
	b._label(inner,selected_library+" · "+selected_room,Rect2(16,9,282,29),19)
	var map_link: Button=b._button(inner,"查看平面图 ›",Rect2(16,43,126,32),func(): seat_view="map"; refresh(b),Color.TRANSPARENT,BLUE,0,Color.TRANSPARENT); map_link.add_theme_font_size_override("font_size",12)
	var detail: Button=b._button(inner,"查看房间详情 ›",Rect2(151,43,141,32),func(): b._toast(root,"%s：座位 %s，当前空闲 %s。" % [selected_room,count,count-(1 if b.s.ui.librarySeatReserved else 0)]),Color.TRANSPARENT,BLUE,0,Color.TRANSPARENT); detail.add_theme_font_size_override("font_size",12)
	b._label(inner,"空余 %s" % (count-(1 if b.s.ui.librarySeatReserved else 0)),Rect2(285,17,86,42),14,BLUE,HORIZONTAL_ALIGNMENT_CENTER)
	if active:
		var puzzle: Dictionary=b.s.ui.libraryFinalsPuzzle
		var status="座位已恢复" if puzzle.playerSeated else "清退已执行" if puzzle.backpackEvicted else "PASS 已签发" if puzzle.evictionPassGenerated else "恢复申请待提交" if b.s.ui.libraryFinalsPhase=="recovery_application" else "公示审核中" if b.s.ui.libraryFinalsPhase in ["bd_briefing","top_ten_rising","top_ten_reached"] else "占用异常"
		b._panel(inner,Rect2(12,103,352,95),Color("ecf2fa"),BLUE,0,2)
		b._label(inner,"022",Rect2(23,116,55,36),24,BLUE)
		b._label(inner,"当前现场状态 · "+status,Rect2(85,112,267,25),14,BLUE)
		b._label(inner,"现场已清空，座位等待本人确认。" if puzzle.backpackEvicted else "书包仍在现场，手机页面只负责查询与提交材料。",Rect2(85,139,260,48),12,MUTED)
	else:
		for entry in [["date",selected_date,Rect2(14,106,167,61)],["time",selected_time,Rect2(192,106,172,61)]]:
			var button: Button=b._button(inner,str(entry[1])+" ▾",entry[2],func(): sheet=entry[0]; refresh(b),Color.WHITE,INK,0,Color("bdbab4")); button.name="LibraryBooking_"+entry[0]; button.add_theme_font_size_override("font_size",14)
	var top=211 if active else 181
	for i in range(2):
		var button: Button=b._button(inner,["地图模式","列表模式"][i],Rect2(14+i*176,top,176,39),func(): seat_view=["map","list"][i]; refresh(b),BLUE if seat_view==["map","list"][i] else Color.WHITE,Color.WHITE if seat_view==["map","list"][i] else BLUE,0,Color("a7a39b")); button.name="LibrarySeatView_"+["map","list"][i]; button.add_theme_font_size_override("font_size",14)
	b._label(inner,"已选："+(selected_seat if not selected_seat.is_empty() else "-")+"　筛选："+seat_filter,Rect2(16,top+46,268,34),13)
	var filter_button: Button=b._button(inner,"▽≡ 筛选",Rect2(284,top+46,80,34),func(): sheet="filter"; refresh(b),Color.TRANSPARENT,BLUE,0,Color.TRANSPARENT); filter_button.name="LibrarySeatFilter"; filter_button.add_theme_font_size_override("font_size",14)
	var y=top+88
	if seat_view=="map":
		var sections=int(ceil(count/32.0))
		for section in range(sections):
			var button: Button=b._button(inner,"%03d–%03d" % [section*32+1,mini(count,(section+1)*32)],Rect2(14+(section%5)*70,y+int(section/5)*32,67,29),func(): seat_section=section; refresh(b),Color("39589e") if section==seat_section else Color.WHITE,Color.WHITE if section==seat_section else BLUE,0,Color("bbc8df")); button.name="LibrarySeatSection_"+str(section); button.add_theme_font_size_override("font_size",10)
		y+=int(ceil(sections/5.0))*32+7
		b._panel(inner,Rect2(14,y,350,347),Color.WHITE,Color("9d9a93"),0,2)
		b._label(inner,"N\n▲",Rect2(329,y+9,24,40),11,INK,HORIZONTAL_ALIGNMENT_CENTER)
		var starts=[[29,25],[21,17],[13,9],[5,1]]
		for table in range(4):
			var x=87+table*55
			if table==1: b._label(inner,"%03d   %03d" % [21+seat_section*32,17+seat_section*32],Rect2(x-1,y+12,54,17),9)
			for row in range(4):
				b._panel(inner,Rect2(x+20,y+34+row*32,7,30),Color("d6c6a6"))
				for side in range(2):
					var number=int(starts[table][side])+row+seat_section*32
					if number>count: continue
					var seat="%03d" % number
					var color=Color("b52d2d") if selected_seat==seat and b.s.ui.libraryFinalsPuzzle.backpackInspected and not b.s.ui.libraryFinalsPuzzle.playerSeated else BLUE if selected_seat==seat else Color.WHITE
					var target: Button=b._button(inner,"",Rect2(x-3+side*29,y+32+row*32,24,28),func(): select_seat(b,root,seat),Color.TRANSPARENT,INK,0,Color.TRANSPARENT); target.name="LibrarySeat_"+seat; target.tooltip_text="选择座位"+seat
					b._panel(target,Rect2(4,8,15,15),color,INK,0,2); b._panel(target,Rect2(3,23,17,3),INK)
			if table==1: b._label(inner,"%03d   %03d" % [24+seat_section*32,20+seat_section*32],Rect2(x-1,y+164,54,17),9)
		b._panel(inner,Rect2(23,y+270,331,2),Color("a7a39b"))
		for i in range(5):
			b._panel(inner,Rect2(27+i*65,y+285,12,12),[Color.WHITE,Color("d6c6a6"),BLUE,Color("d9c9aa"),Color("bfc1c1")][i],INK,0,1)
			b._label(inner,["空闲中","已预约","使用中","暂停中","不可用"][i],Rect2(26+i*65,y+301,62,19),10)
			b._label(inner,["Available","Reserved","Occupied","Suspending","Unavailable"][i],Rect2(26+i*65,y+320,62,16),7,MUTED)
		if active: b._label(inner,"手机端保留调查记录；书包、小票与 PASS 操作均在图书馆现场完成。",Rect2(16,y+357,347,42),12,MUTED)
	else:
		b._panel(inner,Rect2(14,y,350,347),Color.WHITE,BLUE,0,2)
		var list_scroll=ScrollContainer.new(); list_scroll.name="LibrarySeatListScroll"; list_scroll.position=Vector2(24,y+11); list_scroll.size=Vector2(330,325); list_scroll.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED; inner.add_child(list_scroll)
		var list=Control.new(); list.custom_minimum_size=Vector2(321,ceil(count/4.0)*42); list_scroll.add_child(list)
		for i in range(count):
			var seat="%03d" % (i+1)
			var target: Button=b._button(list,seat,Rect2((i%4)*81,int(i/4)*42,75,36),func(): select_seat(b,root,seat),BLUE if seat==selected_seat else Color.WHITE,Color.WHITE if seat==selected_seat else INK,0,Color("9d9a93")); target.name="LibrarySeat_"+seat; target.add_theme_font_size_override("font_size",13)
	b._panel(root,Rect2(0,b.APP_HEIGHT-60,378,60),Color.WHITE,Color("c9c4b9"),0,1)
	b._button(root,"↶ 返回",Rect2(13,b.APP_HEIGHT-49,102,39),func(): goto(b,"spaces"),Color.WHITE,BLUE,0,BLUE).name="LibrarySeatBack"
	b._button(root,"预约成功" if b.s.ui.librarySeatReserved else "立即预约",Rect2(126,b.APP_HEIGHT-49,239,39),func():
		if selected_seat.is_empty(): b._toast(root,"请先选择一个白色座位。")
		elif b.s.ui.librarySeatReserved: b._toast(root,"座位 %s 已预约。" % selected_seat)
		else: sheet="confirm"; refresh(b),BLUE,Color.WHITE,0,Color("082f72")).name="LibraryReserveNow"
	if not sheet.is_empty(): add_sheet(b,root)
	return root

func add_sheet(b, root: Control) -> void:
	var shade=ColorRect.new(); shade.name="LibrarySheetShade"; shade.color=Color(0,0,0,.46); shade.size=Vector2(378,b.APP_HEIGHT); root.add_child(shade)
	var choices={"libraries":["主馆","基础馆","农医馆","紫金港西区馆"],"date":["07月10日 · 今天","07月11日 · 明天","07月12日 · 后天"],"time":["08:00 - 12:00","13:00 - 17:00","18:00 - 22:00","00:01 - 23:59"],"filter":["靠窗","有电源","安静区","全部座位"]}
	var titles={"libraries":"选择馆舍","date":"预约日期","time":"预约时段","filter":"筛选座位","confirm":"确认预约"}
	var options: Array=choices.get(sheet,[])
	var height=220 if sheet=="confirm" else 76+options.size()*48
	var top=b.APP_HEIGHT-height
	b._panel(root,Rect2(0,top,378,height),Color("f8f6f0"),INK,0,2)
	b._label(root,str(titles[sheet]),Rect2(18,top+10,292,38),20)
	b._button(root,"×",Rect2(329,top+9,39,38),func(): sheet=""; refresh(b),Color.TRANSPARENT,INK,0,Color.TRANSPARENT).name="LibrarySheetClose"
	if sheet=="confirm":
		b._label(root,"%s · %s · %s 号座位\n%s，%s" % [selected_library,selected_room,selected_seat,selected_date,selected_time],Rect2(20,top+62,337,74),17)
		b._button(root,"再想一下",Rect2(17,top+158,166,43),func(): sheet=""; refresh(b),Color.WHITE,INK).name="LibraryReservationCancel"
		b._button(root,"确认预约",Rect2(195,top+158,166,43),func(): sheet=""; b.action_requested.emit("c2_reserve",{"library":selected_library,"room":selected_room,"seat":selected_seat}),BLUE,Color.WHITE).name="LibraryReservationConfirm"
	else:
		for i in range(options.size()):
			var option=str(options[i])
			b._button(root,option,Rect2(17,top+58+i*48,344,41),func():
				match sheet:
					"libraries": selected_library=option
					"date": selected_date=option
					"time": selected_time=option
					"filter": seat_filter=option
				sheet=""; refresh(b),Color.WHITE,INK,0,Color("b5b3ac")).name="LibrarySheetOption_"+str(i)

func normalize_query(value: String) -> String:
	return value.strip_edges().replace(" ","").replace("《","").replace("》","").to_lower()

func find_catalog_results(query: String) -> Array:
	var normalized=normalize_query(query)
	if normalized.is_empty(): return []
	var match_clue=normalized.length()>=3 and ("三分钟离座法".begins_with(normalized) or normalized.begins_with("三分钟离座法"))
	var ids: Array=[]
	for result in data().library.catalogResults:
		var searchable=str(result.title)+str(result.author)+str(result.callNumber)+str(result.publisher)+str(result.location)
		if match_clue or normalize_query(searchable).contains(normalized): ids.append(result.id)
	return ids

func catalog(b) -> Control:
	if b.s.qizhenLake.reflectionClueFound: qizhen_catalog_visible=true
	var root=base(b,"浙大移动图书馆",func(): local_page="home"; b.page_requested.emit("library_app"))
	var result_ids: Array=find_catalog_results(catalog_query) if catalog_submitted else []
	if not catalog_submitted and b.s.ui.libraryFinalsPuzzle.catalogSearchCompleted:
		for result in data().library.catalogResults: result_ids.append(result.id)
	var results: Array=[]
	for result in data().library.catalogResults:
		if result_ids.has(result.id): results.append(result)
	var extra=114 if catalog_advanced else 0
	var inner=body(b,root,"catalog",340+extra+results.size()*187,0,Color("fbf8ef"))
	b._button(inner,"中文文献库",Rect2(11,9,175,43),func(): b._toast(root,"当前正在使用中文文献库。"),Color("1165b5"),Color.WHITE,0,Color("063d7e"))
	b._label(inner,"xxx",Rect2(193,9,175,43),14,MUTED,HORIZONTAL_ALIGNMENT_CENTER)
	b._panel(inner,Rect2(11,62,356,115),Color("f3f0e8"),Color("b2aea5"),0,2)
	var query=DropInput.new(); query.position=Vector2(22,72); query.size=Vector2(266,41); query.placeholder_text="搜索文献"; query.text=catalog_query; query.add_theme_font_size_override("font_size",16); inner.add_child(query)
	query.name="LibraryCatalogQuery"; query.text_changed.connect(func(value): catalog_query=value)
	query.item_dropped.connect(func(item):
		if item!="wetProgram" or b.s.qizhenLake.phase!="location_search": b._toast(root,"馆藏检索没有识别这件道具中的页码特征。"); return
		catalog_query="签到记录夹页"; catalog_submitted=false; catalog_selected=""; qizhen_catalog_visible=true; refresh(b))
	query.add_theme_stylebox_override("normal",b._style(Color.WHITE,Color("8e8b84"),0,2)); query.add_theme_stylebox_override("focus",b._style(Color.WHITE,BLUE,0,2))
	query.add_theme_color_override("font_color",Color("1d1d1d")); query.add_theme_color_override("font_placeholder_color",Color("87847e"))
	var search=func():
		if catalog_query.strip_edges().is_empty(): b._toast(root,"请输入书名、作者或索书号。"); return
		if b.s.qizhenLake.active and b.s.qizhenLake.phase=="location_search" and normalize_query(catalog_query)=="签到记录夹页":
			qizhen_catalog_visible=true; catalog_submitted=false; catalog_selected=""; refresh(b); return
		catalog_submitted=true; catalog_selected=""
		if int(b.s.native.get("chapter",1))==2: b.action_requested.emit("lib_catalog_search",catalog_query)
		else: refresh(b)
	query.text_submitted.connect(func(_value): search.call())
	b._button(inner,"搜索",Rect2(296,72,60,41),search,Color("1165b5"),Color.WHITE,0,Color("063d7e")).name="LibraryCatalogSearch"
	for i in range(2):
		var field: Button=b._button(inner,"检索字段\n书名  ▾" if i==0 else "馆藏范围\n全部馆藏  ▾",Rect2(22+i*171,122,163,44),func(): b._toast(root,"当前检索字段固定为书名，高级检索可查看其他条件。" if i==0 else "当前馆藏范围为全部馆藏。"),Color.WHITE,BLUE,0,Color("b2aea5")); field.add_theme_font_size_override("font_size",12)
	var advanced: Button=b._button(inner,"收起高级检索" if catalog_advanced else "高级检索",Rect2(11,190,129,32),func(): catalog_advanced=not catalog_advanced; refresh(b),Color.TRANSPARENT,BLUE,0,Color.TRANSPARENT); advanced.name="LibraryCatalogAdvanced"; advanced.add_theme_font_size_override("font_size",13)
	b._label(inner,"检索到的书籍数：%s" % results.size(),Rect2(155,190,210,32),13,MUTED,HORIZONTAL_ALIGNMENT_RIGHT)
	if catalog_advanced:
		b._panel(inner,Rect2(11,229,356,99),Color("f3f0e8"),Color("b2aea5"),0,1)
		for i in range(3): b._label(inner,["题名匹配　 包含全部关键词","索书号分类　 全部分类","馆藏地点　 基础图书馆"][i],Rect2(24,237+i*29,326,27),13,MUTED)
	var y=237+extra
	if qizhen_catalog_visible:
		var lake_data: Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://data/source/chapter3-qizhen-lake.content.json"))
		var record: Dictionary=lake_data.locationSearch.catalog
		b._panel(inner,Rect2(11,y,356,322),Color("eaf3fc"),Color("30618e"),0,2)
		b._label(inner,"签到记录夹页",Rect2(23,y+11,232,30),18,BLUE)
		b._label(inner,"异常外借",Rect2(273,y+14,80,25),12,Color("a6632a"),HORIZONTAL_ALIGNMENT_RIGHT)
		for i in range(record.fields.size()):
			b._panel(inner,Rect2(23,y+55+i*33,332,33),Color.WHITE,Color("a9c2d6"),0,1)
			b._label(inner,str(record.fields[i][0]),Rect2(30,y+58+i*33,94,27),12,MUTED)
			b._label(inner,str(record.fields[i][1]),Rect2(129,y+58+i*33,218,27),12,BLUE)
		var save: Button=b._button(inner,"已取得：倒影" if b.s.qizhenLake.reflectionClueFound else "记录关键词：倒影",Rect2(23,y+233,332,39),func(): b.action_requested.emit("c3_clue:reflection",null),BLUE,Color.WHITE); save.name="LibraryReflectionKeyword"; save.disabled=b.s.qizhenLake.reflectionClueFound
		save.add_theme_color_override("font_disabled_color",Color("496276"))
		save.add_theme_stylebox_override("disabled",b._style(Color("d7e4ee"),Color("0f3c62"),0,3))
		if b.s.qizhenLake.reflectionClueFound: b._label(inner,str(record.player)+"\n"+str(record.system),Rect2(23,y+280,332,66),12,MUTED)
		y+=370
	b._label(inner,"检索结果　%s 条" % results.size() if not results.is_empty() else "没有匹配馆藏" if catalog_submitted else "新书推荐",Rect2(17,y,344,34),20,BLUE)
	y+=47
	if results.is_empty(): b._label(inner,"可尝试书名、作者或索书号中的连续文字。" if catalog_submitted else "输入题名后，相似书籍会同时列出。",Rect2(19,y,340,59),14,MUTED)
	for result in results:
		var correct=result.id=="three-minute-leave-method" and b.s.ui.libraryFinalsPuzzle.callNumberCollected
		var wrong=catalog_selected==result.id and not correct
		var tile: Button=b._button(inner,"",Rect2(11,y,356,174),func():
			catalog_selected=result.id
			if int(b.s.native.get("chapter",1))==2: b.action_requested.emit("lib_catalog_select",result.id)
			else: refresh(b),Color("e7f4e5") if correct else Color("fff0ee") if wrong else Color.WHITE,INK,0,Color("4d8745") if correct else Color("bc6a60") if wrong else Color("c7c2b8")); tile.name="LibraryCatalogResult_"+str(result.id)
		b._panel(tile,Rect2(10,18,82,105),Color("f2eee4"),Color("6f6b63"),0,2)
		b._image(tile,"phone/library-search/runtime/"+COVERS.get(result.cover,"three_minute_empty_seat")+".webp",Rect2(12,20,78,101))
		b._label(tile,str(result.title),Rect2(108,12,236,32),17,BLUE)
		b._label(tile,"著者："+str(result.author),Rect2(108,49,236,23),12,MUTED)
		b._label(tile,"索书号："+str(result.callNumber),Rect2(108,75,236,24),13)
		b._label(tile,str(result.year)+"　"+str(result.publisher),Rect2(108,102,236,22),11,MUTED)
		b._label(tile,str(result.location),Rect2(108,128,236,25),12,BLUE)
		y+=187
		if correct:
			b._label(inner,str(result.note),Rect2(22,y-7,335,52),13,Color("40683b")); y+=60
	inner.custom_minimum_size.y=maxf(inner.custom_minimum_size.y,y+22)
	return root

func recovery(b) -> Control:
	var root=base(b,"022座位恢复申请",func(): local_page="home"; b.page_requested.emit("library_app"))
	var puzzle: Dictionary=b.s.ui.libraryFinalsPuzzle
	var submitted: Array=puzzle.recoverySubmittedEvidenceIds
	var ready=puzzle.evictionPassGenerated or b.s.ui.libraryFinalsPhase in ["pass_ready","backpack_removed","seat_recovered","friend_contacted"]
	var inner=body(b,root,"recovery",665 if ready else 613,0,Color("eef3f8"))
	b._panel(inner,Rect2(12,12,353,75),Color("164f93"),Color("073b75"),0,3)
	b._panel(inner,Rect2(23,24,59,50),Color.WHITE,Color("062f61"),0,3)
	b._label(inner,"022",Rect2(23,24,59,50),25,BLUE,HORIZONTAL_ALIGNMENT_CENTER)
	b._label(inner,"基础馆 · 一层书库",Rect2(94,25,185,24),14,Color.WHITE)
	b._label(inner,"CC98 公示排名：01",Rect2(94,53,185,20),12,Color("d8e8ff"))
	b._panel(inner,Rect2(295,33,58,34),Color("f5d453"),Color("573f00"),0,2)
	b._label(inner,"PASS" if ready else "%s/3" % submitted.size(),Rect2(295,33,58,34),15,Color("332700"),HORIZONTAL_ALIGNMENT_CENTER)
	b._panel(inner,Rect2(14,97,349,9),Color("c8d1dc"),Color("7c8998"),0,1)
	b._panel(inner,Rect2(15,98,347 if ready else 347*submitted.size()/3.0,7),Color("4d8f61"))
	b._panel(inner,Rect2(12,118,353,92),Color.WHITE,Color("9da8b4"),0,2)
	b._label(inner,"旧版规则 · 恢复条件",Rect2(23,128,327,26),15,BLUE)
	b._label(inner,"CC98 公示已生效。三份材料分别确认占用物身份、座位编号与本人到馆记录。",Rect2(23,156,327,44),12,MUTED)
	for i in range(3):
		var evidence: Array=RECOVERY[i]; var uploaded=submitted.has(evidence[0]); var owned=bool(b.s.items.get(evidence[2],false)); var y=222+i*93
		var slot=DropButton.new(); slot.name="LibraryRecoverySlot_"+evidence[0]; slot.position=Vector2(12,y); slot.size=Vector2(353,82); slot.text=""
		var color=Color("e7f4e5") if uploaded else Color("eef6ff") if owned else Color("f8f8f6")
		var border=Color("4d8745") if uploaded else Color("3875b2") if owned else Color("a7adb2")
		for mode in ["normal","hover","pressed","disabled"]: slot.add_theme_stylebox_override(mode,b._style(color,border,0,2))
		slot.disabled=not uploaded and (not owned or b.s.ui.libraryFinalsPhase!="recovery_application")
		inner.add_child(slot)
		var upload=func():
			if uploaded:
				if not b.get_signal_connection_list("document_requested").is_empty():
					b.document_requested.emit({"item_id":str(evidence[2]),"source":"library_recovery"})
				else:
					var modal=DocumentModal.new(); modal.setup(b,str(evidence[2])); root.add_child(modal)
					modal.closed.connect(func(): modal.queue_free(); slot.grab_focus())
			else: b.action_requested.emit("lib_recovery_upload",evidence[0])
		slot.pressed.connect(upload)
		slot.item_dropped.connect(func(item):
			if item==evidence[2] and not uploaded: b.action_requested.emit("lib_recovery_upload",evidence[0]))
		b._panel(slot,Rect2(8,24,32,32),Color("dce9f8"),BLUE,0,1)
		b._label(slot,"%02d" % (i+1),Rect2(8,24,32,32),17,BLUE,HORIZONTAL_ALIGNMENT_CENTER)
		b._label(slot,evidence[1],Rect2(49,8,225,24),15,BLUE)
		b._label(slot,"来源："+evidence[3],Rect2(49,34,225,19),10,MUTED)
		b._label(slot,"材料已锁定到本次申请" if uploaded else "道具栏已识别，可提交校验" if owned else "待取得",Rect2(49,57,225,17),10,Color("4d8745") if uploaded else MUTED)
		b._panel(slot,Rect2(285,24,56,33),BLUE if uploaded or owned else Color("d9dde1"))
		b._label(slot,"查看" if uploaded else "提交",Rect2(285,24,56,33),13,Color.WHITE if uploaded or owned else MUTED,HORIZONTAL_ALIGNMENT_CENTER)
		b._label(slot,"已核验" if uploaded else "可提交" if owned else "待取得",Rect2(283,5,62,17),10,border,HORIZONTAL_ALIGNMENT_CENTER)
	if ready:
		b._panel(inner,Rect2(12,513,353,135),Color("e7f4e5"),Color("4d8745"),0,2)
		b._label(inner,"PASS 已签发",Rect2(26,526,325,34),24,Color("35643c"),HORIZONTAL_ALIGNMENT_CENTER)
		b._label(inner,"凭证只对 RPG 图书馆内的 022 书包生效。",Rect2(24,563,329,32),12,MUTED,HORIZONTAL_ALIGNMENT_CENTER)
		b._button(inner,"回图书馆处理书包",Rect2(30,605,317,32),func(): b.action_requested.emit("lib_enter",null),Color("4d8f61"),Color.WHITE).name="LibraryReturnToScene"
	elif b.s.ui.libraryFinalsPhase=="top_ten_reached":
		b._button(inner,"填写恢复申请",Rect2(12,513,353,45),func(): open_recovery(b),BLUE,Color.WHITE).name="LibraryRecoveryOpen"
	else:
		var generate: Button=b._button(inner,"生成 022 座位释放 PASS",Rect2(12,513,353,45),func(): b.action_requested.emit("lib_generate_pass",null),BLUE,Color.WHITE); generate.name="LibraryGeneratePass"; generate.disabled=submitted.size()<3 or b.s.ui.libraryFinalsPhase!="recovery_application"
	return root
