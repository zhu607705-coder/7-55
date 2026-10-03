extends RefCounted
## Additive source app content. Only existing controller intents grant evidence.
const DropButton=preload("res://scripts/ui/phone_drop_button.gd")
const Chrome=preload("res://scripts/ui/phone_chrome.gd")
const PostStore=preload("res://scripts/data/cc98_store.gd")
const INK=Color("163f4a")
const TEAL=Color("247990")
const ROWS=[
	["bridgeKeyword","bridge","桥边","CC98 目击帖","方向靠近桥"],
	["reflectionKeyword","reflection","倒影","馆藏异常记录","页码只出现在倒影中"],
	["lakeKeyword","lake","湖面","微信聊天","湖面出现逆风水纹"]]
var content: Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://data/source/chapter3-qizhen-lake.content.json"))
var cc98_ready: bool=false
var cc98_feedback: String=""
var chat_started: int=-1
var chat_step: int=0
var map_feedback: String=""
var weather_feedback: String=""
func active(s: Dictionary) -> bool:
	return s.qizhenLake.active and s.qizhenLake.phase=="location_search"
func route(previous: String,next: String,s: Dictionary) -> void:
	if previous==next: return
	if next!="cc98": cc98_ready=false; cc98_feedback=""
	if next!="wechat": chat_started=-1; chat_step=0
	if next!="zjuding": map_feedback=""
	if next!="weather": weather_feedback=""
	if next=="cc98": cc98_ready=bool(s.qizhenLake.bridgeClueFound)
	if next=="wechat": chat_step=3 if s.qizhenLake.lakeClueFound else 0
func friend_closed() -> void:
	chat_started=-1
func augment_posts(b,posts: Array) -> void:
	if not active(b.s) or not (cc98_ready or b.s.qizhenLake.bridgeClueFound): return
	var replies: Array=[]
	for i in range(content.locationSearch.cc98.replies.size()):
		var raw: String=content.locationSearch.cc98.replies[i]
		replies.append({"personaId":["late-printer","yuquan-wind","anonymous-user"][i],"time":"今天 09:%02d"%(12+i*2),"floor":"%d楼"%[3,8,14][i],"text":raw.substr(raw.find("：")+1),"likes":str([7,4,14][i]),"dislikes":"0"})
	for post: Dictionary in posts:
		if post.id=="qizhen-wet-paper-witness": post.threadReplies=replies; return
	# Source CC98 renders questPosts before ordinary posts, including the first
	# searched witness before its keyword has been collected.
	var ordinary_start := 0
	while ordinary_start < posts.size() and str(posts[ordinary_start].get("id","")) in PostStore.QUEST_IDS:
		ordinary_start += 1
	posts.insert(ordinary_start,{"id":"qizhen-wet-paper-witness","author":"匿名用户","avatar":"anonymous","rank":"12","board":"校园生活","title":content.locationSearch.cc98.title,"replies":"3","views":"755","time":"刚刚","body":"如题。","threadReplies":replies})
func cc98_search(b,feed: Control) -> void:
	if not active(b.s): return
	var root: Control=b._base(Color("e7eef3"),154)
	b._label(root,"目击搜索　　可接收道具",Rect2(13,8,352,30),17,Color("2c7797"))
	b._label(root,"剧院门口 湿纸" if b.s.items.wetProgram else "把湿掉的节目单拖到这里",Rect2(13,49,252,37),16,b.MUTED)
	var drop:=DropButton.new(); drop.position=Vector2(13,47); drop.size=Vector2(252,42); drop.name="Cc98WetProgramDrop"
	for mode in ["normal","hover","pressed","focus"]: drop.add_theme_stylebox_override(mode,b._style(Color.TRANSPARENT))
	drop.item_dropped.connect(func(item: String):
		if item=="wetProgram" and b.s.items.wetProgram:
			cc98_ready=true; cc98_feedback="湿纸特征已加入搜索。找到一条刚发布的目击帖。"; b.action_requested.emit("phone_refresh",{}))
	root.add_child(drop)
	b._button(root,"搜索",Rect2(277,47,87,39),func():
		if b.s.items.wetProgram: cc98_ready=true; cc98_feedback="找到 1 条刚发布的目击帖。"
		else: cc98_feedback="需要能说明纸张状态的实物线索。"
		b.action_requested.emit("phone_refresh",{}),Color("28769b"),Color.WHITE).name="Cc98WetProgramSearch"
	b._label(root,cc98_feedback if not cc98_feedback.is_empty() else "先用实物特征建立目击范围。",Rect2(13,96,352,49),14,b.MUTED)
	feed.add_child(root)
func witness_footer(b,root: Control,y: float) -> void:
	if not active(b.s): return
	var found: bool=b.s.qizhenLake.bridgeClueFound
	b._panel(root,Rect2(10,y,358,190 if found else 115),Color("eaf6ff"),Color("174d9d"),0,3)
	b._label(root,"目击信息可归纳为一个地点关键词",Rect2(23,y+10,332,44),16,b.INK)
	var save: Button=b._button(root,"已取得：桥边" if found else "记录关键词：桥边",Rect2(23,y+60,332,43),func(): b.action_requested.emit("c3_clue:bridge",null),Color("28769b"),Color.WHITE)
	save.name="Cc98BridgeKeyword"; save.disabled=found
	save.add_theme_color_override("font_disabled_color",Color("36546f"))
	save.add_theme_stylebox_override("disabled",b._style(Color("dce9f7"),Color("0a3777"),0,3))
	if found: b._label(root,content.locationSearch.cc98.system+"\n"+content.locationSearch.cc98.player,Rect2(23,y+114,332,65),16,b.MUTED)
	root.custom_minimum_size.y=y+(210 if found else 135); root.size.y=root.custom_minimum_size.y
func append_friend(b,root: Control) -> void:
	if not active(b.s): return
	if b.s.qizhenLake.lakeClueFound: chat_step=3
	elif chat_started<0: chat_started=Time.get_ticks_msec()
	var rows: Array=[]
	var y: float=595
	for i in range(content.locationSearch.wechat.size()):
		var text: String=content.locationSearch.wechat[i]
		var self_reply: bool=text.begins_with("自动回复：")
		var row:=Control.new(); row.name="QizhenChatLine_"+str(i); row.position=Vector2(0,y); row.size=Vector2(378,98); root.add_child(row)
		if not self_reply:
			b._panel(row,Rect2(16,3,40,40),Color("d5ba8b"),Color("a6a6a6"),3,1)
			b._label(row,"/",Rect2(16,3,40,40),27,Color("644845"),HORIZONTAL_ALIGNMENT_CENTER)
		var x: float=30 if self_reply else 68
		b._panel(row,Rect2(x,0,287,87),Color("a7e775") if self_reply else Color.WHITE,Color("89be69") if self_reply else Color("d4d8d4"),3,1)
		b._label(row,text,Rect2(x+11,7,263,74),18,b.INK)
		rows.append(row); y+=100
	var save: Button=b._button(root,"已保存地点词：湖面" if b.s.qizhenLake.lakeClueFound else "保存地点词：湖面",Rect2(20,y,338,48),func(): b.action_requested.emit("c3_clue:lake",null),Color("f5d75e"),Color("28251d"),0,Color("28251d"))
	save.name="WechatLakeKeyword"; save.disabled=b.s.qizhenLake.lakeClueFound
	save.add_theme_color_override("font_disabled_color",Color("355b4b"))
	save.add_theme_stylebox_override("disabled",b._style(Color("dce7df"),Color("6c8177"),0,3))
	var update=func():
		if not is_instance_valid(root): return
		if b.s.qizhenLake.lakeClueFound: chat_step=3
		elif chat_started>=0:
			var elapsed: int=Time.get_ticks_msec()-chat_started
			if elapsed>=260: chat_step=clampi(1+(elapsed-260)/520,0,3)
		for i in range(rows.size()): rows[i].visible=i<chat_step
		save.visible=chat_step==3
	update.call()
	var timer:=Timer.new(); timer.wait_time=.02; timer.timeout.connect(update); root.add_child(timer)
	root.ready.connect(func(): timer.start())
	root.custom_minimum_size.y=y+76; root.size.y=root.custom_minimum_size.y
func import_map(b,item: String) -> void:
	if not active(b.s): map_feedback="当前没有需要合并的地点线索。"
	else:
		for row: Array in ROWS:
			if item==row[0] and b.s.items.get(item,false):
				if b.s.qizhenLake.mapClueIds.has(row[1]): map_feedback="这条记录已经参与检索。"; b.action_requested.emit("phone_refresh",{}); return
				b.action_requested.emit("c3_map:"+row[1],null); map_feedback=""; return
		map_feedback="地图没有从这件道具中读到地点关键词。"
	b.action_requested.emit("phone_refresh",{})
func map_page(b,root: Control) -> void:
	root.set_meta("handles_all_actions",true)
	b._header(root,"校园地图",Color.WHITE,INK,b._zju_back,"back","返回浙大钉")
	var inner: Control=b._zju_scroll(root,54)
	var q: Dictionary=b.s.qizhenLake
	var solved: bool=q.phase not in ["location_search","inactive"]
	var count: int=q.mapClueIds.size()
	b._panel(inner,Rect2(14,16,350,87),Color.WHITE,Color("214f59"),0,3)
	b._panel(inner,Rect2(26,29,48,48),TEAL,INK,0,3); b._label(inner,"位",Rect2(26,29,48,48),25,Color.WHITE,HORIZONTAL_ALIGNMENT_CENTER)
	b._label(inner,"交叉检索台",Rect2(85,26,266,29),21,INK)
	b._label(inner,"保留原始来源，核对三条地点记录",Rect2(85,60,266,30),13,b.MUTED)
	var frame:=DropButton.new(); frame.position=Vector2(14,118); frame.size=Vector2(350,392); frame.name="QizhenMapDrop"; frame.focus_mode=Control.FOCUS_NONE
	frame.add_theme_stylebox_override("normal",b._style(Color("f8fbf8"),Color("214f59"),0,4)); frame.item_dropped.connect(func(item): import_map(b,item)); inner.add_child(frame)
	b._panel(frame,Rect2(4,4,342,55),INK)
	b._label(frame,"已接入  %d / 3"%count,Rect2(14,13,169,36),22,Color("ffe27b"))
	b._label(frame,"入口已标记" if solved else "待核对" if count==3 else "收集中",Rect2(194,17,142,29),14,Color("d6f0d9") if solved else Color("c5dcda"),HORIZONTAL_ALIGNMENT_RIGHT)
	for i in range(ROWS.size()):
		var row: Array=ROWS[i]; var added: bool=q.mapClueIds.has(row[1]); var owned: bool=b.s.items.get(row[0],false); var y: float=60+i*109
		b._panel(frame,Rect2(4,y,342,109),Color("e8f2df") if added else Color("f8fbf8"),Color("b6c9c7"),0,1)
		var icon:=Chrome.PixelIcon.new(); icon.pixels=Chrome.PIXEL_ICONS.get(row[0],{}); icon.position=Vector2(13,y+33); icon.size=Vector2(40,40); frame.add_child(icon)
		b._label(frame,row[3],Rect2(61,y+9,205,21),12,b.MUTED)
		b._label(frame,row[4],Rect2(61,y+32,205,43),16,INK)
		b._label(frame,"提取词："+row[2],Rect2(61,y+79,205,22),14,INK)
		if owned and not added:
			b._button(frame,"导入",Rect2(269,y+34,67,41),func(): import_map(b,row[0]),TEAL,Color.WHITE,0,INK).name="QizhenMapImport_"+row[1]
		else: b._label(frame,"已接入" if added else "未取得",Rect2(267,y+38,69,34),13,Color("1d5537") if added else b.MUTED,HORIZONTAL_ALIGNMENT_CENTER)
	var y: float=526
	if count==3 and not solved:
		b._panel(inner,Rect2(14,y,350,135),Color("fff8d5"),Color("ab9851"),0,2)
		b._label(inner,content.locationSearch.map.reason,Rect2(27,y+9,324,58),16,INK)
		b._button(inner,content.locationSearch.map.confirm,Rect2(27,y+78,324,43),func(): b.action_requested.emit("c3_map_confirm",null),TEAL,Color.WHITE).name="QizhenMapConfirm"
		y+=151
	var feedback: String=content.locationSearch.map.three if solved else content.locationSearch.map.ready if count==3 else content.locationSearch.map.two if count==2 else content.locationSearch.map.one if count==1 else "三条记录来自不同应用。先取得地点词，再在这里逐条接入。"
	b._label(inner,map_feedback if not map_feedback.is_empty() else feedback,Rect2(17,y,344,72),16,INK); y+=83
	if solved:
		b._panel(inner,Rect2(14,y,350,255),Color("eff7e8"),Color("577b60"),0,3)
		b._label(inner,"启真湖",Rect2(28,y+12,322,35),25,Color("245637"))
		b._label(inner,content.locationSearch.map.reason+"\n"+content.locationSearch.map.player+"\n"+content.locationSearch.map.system,Rect2(28,y+55,322,126),16,INK)
		b._button(inner,"前往大地图上的启真湖入口",Rect2(28,y+191,322,49),func(): b.zjuding_page="hub"; b.action_requested.emit("c3_map_enter",null),TEAL,Color.WHITE).name="QizhenMapEnter"
		y+=272
	inner.custom_minimum_size.y=y+24; inner.size.y=inner.custom_minimum_size.y
func weather_context(s: Dictionary) -> bool:
	return s.qizhenLake.active and s.qizhenLake.phase not in ["inactive","location_search","lake_unlocked"]
func weather_available(s: Dictionary) -> bool:
	var q: Dictionary=s.qizhenLake
	return q.phase=="rain_recovery" and q.rainRescueCompleted and q.weatherAdjustmentRequested and s.items.hairDryer and not q.rainSafetyCleared
func weather_advice(s: Dictionary) -> String:
	return "返回码头确认" if s.qizhenLake.rainSafetyCleared else "处理湖区云图" if s.qizhenLake.weatherAdjustmentRequested and s.items.hairDryer else "暂不适合下水"
func weather_card(b,root: Control) -> void:
	var q: Dictionary=b.s.qizhenLake
	var available: bool=weather_available(b.s)
	var complete: bool=q.rainSafetyCleared
	var card:=DropButton.new(); card.position=Vector2(16,439); card.size=Vector2(346,126); card.name="QizhenWeatherDevice"; card.disabled=not available
	for mode in ["normal","hover","pressed","disabled"]: card.add_theme_stylebox_override(mode,b._style(Color("e7f3e7") if complete else Color("f7fbfd"),Color("37704a") if complete else b.BLUE,0,3))
	root.add_child(card)
	var fail=func(message: String): weather_feedback=message; b.action_requested.emit("phone_refresh",{})
	card.item_dropped.connect(func(item: String):
		if item=="hairDryer" and available: weather_feedback=""; b.action_requested.emit("c3_weather_start",null)
		else: fail.call("这件道具无法送风 · 请拖入寝室吹风机"))
	card.pressed.connect(func():
		var selected: String=str(b.s.native.get("selected_item",""))
		if selected=="hairDryer": weather_feedback=""; b.action_requested.emit("c3_weather_start",null)
		elif not selected.is_empty(): fail.call("当前道具无法送风 · 请改用寝室吹风机")
		else: weather_feedback="道具栏已展开 · 拖入吹风机，键盘可按空格选中"; b.action_requested.emit("c3_weather_inventory",null))
	b._label(card,"✓" if complete else "+",Rect2(15,21,42,49),31,Color("37704a") if complete else b.BLUE,HORIZONTAL_ALIGNMENT_CENTER)
	var title: String="湖区状态已更新" if complete else "接入寝室吹风机" if q.weatherAdjustmentRequested and b.s.items.hairDryer else "缺少可用设备" if q.weatherAdjustmentRequested else "暂无湖区记录"
	var detail: String="返回码头确认"+(" · 最少 %d 次校正"%q.weatherControlBestMoves if q.weatherControlBestMoves>0 else "") if complete else weather_feedback if available and not weather_feedback.is_empty() else "从左侧道具栏拖到此接口" if available else "先检查寝室书桌" if q.weatherAdjustmentRequested else "完成码头检查后再查看"
	b._label(card,title,Rect2(69,10,263,37),18,INK)
	b._label(card,detail,Rect2(69,50,263,67),15,Color("5f6b73"))
