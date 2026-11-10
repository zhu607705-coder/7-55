extends RefCounted
const Frame = preload("res://scripts/ui/phone_app_frame.gd")
const Palette = preload("res://scripts/ui/chapter35_palette.gd")
const Investigation = preload("res://scripts/chapters/c35_investigation.gd")
const Campus = preload("res://scripts/ui/c35_campus_pin_map.gd")
const CampusLayers = preload("res://scripts/presentation/campus_layered_map.gd")
const Typography = preload("res://scripts/ui/native_typography.gd")
const NativeUi = preload("res://scripts/ui/native_ui_theme.gd")
const Ding = preload("res://scripts/ui/c35_ding_chat.gd")
const HOMEWORK_NOTICE := "第十周作业补交：没提交成功的同学，自己把作业 PDF 私信发给我。记得写上姓名和学号，我好登记。"

var map_pose: Dictionary={}
var source_state: Dictionary={}
var layers: RefCounted

func build(pages, snapshot: Dictionary) -> Control:
	if not is_same(source_state,snapshot):
		map_pose={}
		source_state=snapshot
	var step := Investigation.step(snapshot)
	var route: Dictionary=snapshot.native[Investigation.KEY]
	if step!="map": layers=null
	var frame := Frame.new()
	frame.name="C35Investigation"
	frame.background.color=Palette.BACKDROP
	var app: Array={
		"inbox":["浙大钉","消息"],"notice":["课程群",""],"assignment":["课程助教","微积分（甲）"],"camera":["相机","作业扫描"],
		"files":["本机文件","最近使用"],"file":["文件预览",Investigation.FILE_NAMES[route.get("preview_file",Investigation.LEGACY_FILE_ID)]],
		"attached":["课程助教","微积分（甲）"],"file_error":["课程助教","微积分（甲）"],"receipt":["课程助教","微积分（甲）"],"album_trace":["照片","最近项目"],"journal":["记录恢复",""],
		"group":["课程群",""],"seen":["课程群",""],"private":["周琪","浙大钉 · 私聊"],
		"map":["紫金港校园地图","位置共享"],"arrival":["记录恢复","入口核验"],"confirmed":["记录恢复",""],
	}.get(step,["记录恢复",""])
	var back_action: String={"camera":"cancel_camera","files":"close_files","file":"close_preview","attached":"replace_file"}.get(step,"")
	frame.configure(app[0],app[1],0,back_action.is_empty())
	frame.back_requested.connect(func() -> void:
		if not back_action.is_empty():
			pages.action_requested.emit("c35_trace:"+back_action,null)
			return
		layers=null
		pages.page_requested.emit("phone_home"))
	if step in ["inbox","notice","assignment","attached","file_error","receipt","group","seen","private"]:
		frame.background.color=Ding.BACKDROP
	match step:
		"inbox":
			var conversations := Ding.surface(pages,frame.content,Ding.WHITE,Vector2(12,10),12)
			var row := HBoxContainer.new()
			conversations.add_child(row)
			Ding.avatar(pages,row,"课程群",func() -> void: pages.action_requested.emit("c35_trace:message",null))
			var notice := Ding.chip(pages,row,"微积分（甲）课程群\n助教：第十周作业补交通知",func() -> void: pages.action_requested.emit("c35_trace:message",null))
			notice.name="C35CourseConversation"
			notice.alignment=HORIZONTAL_ALIGNMENT_LEFT
			conversations.add_child(pages.label("1 条未读 · 来自课程群",14,Ding.LINK))
		"notice":
			var open_ta := func() -> void: pages.action_requested.emit("c35_trace:ta_private",null)
			var open_member := func(id: String) -> bool:
				if id=="ta": open_ta.call()
				return id=="ta"
			Ding.group_settings(pages,frame,open_member,HOMEWORK_NOTICE)
			Ding.bubble(pages,frame.content,"ta",HOMEWORK_NOTICE,open_ta)
			Ding.bubble(pages,frame.content,"chen_jia","收到，我也去看一下系统里的提交记录。")
		"assignment":
			Ding.bubble(pages,frame.content,"ta","来自微积分（甲）课程群\n第十周作业补交")
			var sources := Ding.bubble(pages,frame.content,"player","附件",Callable(),true)
			var actions := HBoxContainer.new()
			actions.add_theme_constant_override("separation",6)
			sources.add_child(actions)
			Ding.chip(pages,actions,"查看本机文件",func() -> void: pages.action_requested.emit("c35_trace:files",null))
			Ding.chip(pages,actions,"拍摄作业",func() -> void: pages.action_requested.emit("c35_trace:camera",null))
		"camera":
			var view := pages.card(frame.content,Palette.NIGHT) as VBoxContainer
			view.add_child(pages.label("文档相机 · 取景",16,Palette.PALE))
			paper_preview(pages,view,Investigation.PHOTO_ID)
			var shutter := pages.action(view,"","c35_trace:capture") as Button
			shutter.name="C35CameraShutter"
			shutter.tooltip_text="拍照"
			shutter.accessibility_name=shutter.tooltip_text
			shutter.size_flags_horizontal=Control.SIZE_SHRINK_CENTER
			shutter.custom_minimum_size=Vector2(60,60)
			NativeUi.apply_button(shutter,Color.TRANSPARENT,Palette.PAPER,Color.TRANSPARENT,30,0,17,Vector2.ZERO,Palette.PALE)
			var lens := Control.new()
			lens.mouse_filter=Control.MOUSE_FILTER_IGNORE
			shutter.add_child(lens)
			lens.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
			lens.draw.connect(func() -> void:
				lens.draw_circle(lens.size/2,24,Palette.PALE,false,2,true)
				lens.draw_circle(lens.size/2,19,Palette.PAPER,true,-1,true))
		"files": build_files(pages,frame,route)
		"file": build_preview(pages,frame,route)
		"attached": build_submission(pages,frame,route)
		"file_error":
			Ding.bubble(pages,frame.content,"player",Investigation.REPLIES.identity,Callable(),true,"已读")
			var response := Ding.bubble(pages,frame.content,"ta","文件打开异常。原图我看到了，登记系统读不了这种格式。把原图转成 PDF 再发给我吧。")
			Ding.chip(pages,response,"处理附件",func() -> void: pages.action_requested.emit("c35_trace:repair",null))
		"receipt":
			Ding.bubble(pages,frame.content,"player",Investigation.REPLIES.identity+"\n第十周作业.pdf",Callable(),true,"已读")
			Ding.bubble(pages,frame.content,"ta","这份能打开了。林星宇，第十周补交已登记。")
			var trace := section(pages,frame,"相册 · 原图仍在本机","作业原图一直在本机。刚才从相册选图时，划船那组也有一张标着「未同步」。")
			link_action(pages,trace,"查看最近照片","open_album")
		"album_trace":
			var entry := section(pages,frame,"划船 · 最后一张","本机原图 · 未同步")
			entry.add_child(pages.image_node("res://assets/ui/photo-evidence/chapter35_live_paper_right.webp",Vector2(0,170)))
			entry.add_child(pages.label("和划船帖里是同一段湖岸。回原帖看看最后一次发帖时间。",16,Palette.SECONDARY))
			link_action(pages,entry,"查看 CC98 划船帖","journal")
		"journal":
			var trace := section(pages,frame,"离湖时间","上岸后的去向没同步。划船帖里还留着返航记录。")
			pages.lake_primary(pages.navigate(trace,"继续查看划船帖","c35_journal",true))
		"group","seen":
			var contact := func(id: String) -> bool:
				if step!="seen" or id not in ["zhou_qi","chen_jia"]: return false
				pages.action_requested.emit("c35_trace:private",id)
				return true
			Ding.group_settings(pages,frame,contact,"群公告：第十周作业补交请私信课程助教。")
			Ding.bubble(pages,frame.content,"zhou_qi","你刚刚到哪了？你发过来的位置卡我这儿还在。",(func() -> void: contact.call("zhou_qi")) if step=="seen" else Callable())
			Ding.bubble(pages,frame.content,"chen_jia","我还在湖边，先回去整理照片。",(func() -> void: contact.call("chen_jia")) if step=="seen" else Callable())
			if step=="group":
				Ding.composer(pages,frame,"发消息…",Investigation.GROUP_REPLIES,func(id: String) -> void: pages.action_requested.emit("c35_trace:ask",id))
			else:
				Ding.bubble(pages,frame.content,"player",Investigation.GROUP_REPLIES.get(route.get("group_reply","route")),Callable(),true,"未读")
				var status := frame.content.find_child("C35ReadStatus",true,false) as Label
				frame.ready.connect(func() -> void:
					await status.get_tree().create_timer(.8).timeout
					if is_instance_valid(status):
						status.text="已读 2"
						status.add_theme_color_override("font_color",Ding.LINK))
				frame.content.add_child(pages.label("点头像发私信",14,Ding.MUTED))
		"private":
			Ding.bubble(pages,frame.content,"player","你那儿的定位还能打开吗？",Callable(),true,"已读")
			var share := Ding.bubble(pages,frame.content,"zhou_qi","你刚才发过定位。那片教学楼在启真湖西北，几组庭院之间有一条南北向的绿带。东门清楼时锁了，西侧大厅还亮着灯。")
			Ding.chip(pages,share,"位置共享 · 已过期  ›",func() -> void: pages.action_requested.emit("c35_trace:map",null)).name="C35LocationShare"
		"map": build_map(pages,frame)
		"arrival":
			section(pages,frame,"段永平教学楼 · 西侧大厅入口","大厅录音转写 · 22:45:00\n「本楼开始清楼，请从大厅主入口离开。」")
			var choices := section(pages,frame,"校园网夜间接入","哪条记录与大厅的地点和清楼时间对得上？")
			for row: Array in [
				["22:44:31 · 剧场前厅","record_theater_hall"],
				["22:44:57 · 北教学区 A 区 · 3 秒","record_0755"],
				["22:44:12 · 启真湖小码头","record_qizhen_dock"],
			]:
				pages.action(choices,row[0],"c35_trace:compare",row[1])
		"confirmed":
			var verified := section(pages,frame,"离湖路径已核验","22:37:05  ·  启真湖小码头上岸\n22:44:57  ·  北教 A 楼西侧大厅接入\n22:45:00  ·  大厅清楼广播")
			pages.lake_primary(pages.action(verified,"从西侧大厅开始回放","c35_replay",null,true))
	return frame

func build_files(pages,frame: Control,route: Dictionary) -> void:
	for id: String in [Investigation.FILE_ID,Investigation.PHOTO_ID,Investigation.EARLIER_FILE_ID]:
		if not Investigation.file_available(route,id): continue
		var row := pages.card(frame.content,Palette.PAPER) as VBoxContainer
		row.add_child(pages.label(Investigation.FILE_NAMES[id],19,Palette.INK))
		var format := "JPG · 相机原图" if id==Investigation.PHOTO_ID else "PDF · 1 页"
		row.add_child(pages.label(format,14,Palette.SECONDARY))
		var preview := pages.action(row,"预览","c35_trace:preview",id) as Button
		preview.name="C35Preview_"+id
		preview.accessibility_name="预览"+Investigation.FILE_NAMES[id]

func paper_preview(pages,parent: Control,id: String) -> VBoxContainer:
	var sheet := pages.card(parent,Palette.PAPER) as VBoxContainer
	var week := "第九周" if id==Investigation.EARLIER_FILE_ID else "第十周"
	sheet.add_child(pages.label("微积分（甲）  "+week+"作业",22,Palette.INK))
	sheet.add_child(pages.label("姓名：林星宇",16,Palette.SECONDARY))
	var work := "第 3 题  求 f 在 0 处的六阶导数。\nf(x) = x² e^(2x) + ln(1+x³)\n\n取六次项的系数，再乘 6!。\n乘积项和对数项分别计算。"
	if id==Investigation.EARLIER_FILE_ID: work="第 2 题  求 f(x) = x² e^x 的一阶导数。\n对两个因子分别求导，再按乘积法则合并。"
	var copy := pages.label(work,17,Palette.INK) as Label
	copy.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	sheet.add_child(copy)
	if id==Investigation.FILE_ID: sheet.add_child(pages.label("扫描件 · 第 1 / 1 页",14,Palette.SECONDARY))
	return sheet

func build_preview(pages,frame: Control,route: Dictionary) -> void:
	var id: String=route.get("preview_file",Investigation.LEGACY_FILE_ID)
	var sheet := paper_preview(pages,frame.content,id)
	if id==Investigation.EARLIER_FILE_ID:
		sheet.add_child(pages.label("归档文件 · 与当前补交周次不符",15,Palette.SECONDARY))
		return
	var actions := HBoxContainer.new()
	actions.add_theme_constant_override("separation",8)
	sheet.add_child(actions)
	if id==Investigation.PHOTO_ID:
		pages.action(actions,"附上原图","c35_trace:attach",id)
		link_action(pages,actions,"转为 PDF","convert")
	else:
		link_action(pages,actions,"附到补交","attach",id)

func build_submission(pages,frame: Control,route: Dictionary) -> void:
	var id: String=route.get("attachment",Investigation.LEGACY_FILE_ID)
	if route.get("identity_requested",false):
		Ding.bubble(pages,frame.content,"player",Investigation.REPLIES.bare,Callable(),true,"已读")
		Ding.bubble(pages,frame.content,"ta","我看到了。请把姓名和学号也发给我，不然登记表上找不到这份作业是谁的。")
	var compose := Ding.bubble(pages,frame.content,"player","",Callable(),true)
	var chosen: String=route.get("reply","")
	var heading := HBoxContainer.new()
	compose.add_child(heading)
	heading.add_child(pages.label("发给助教",17,Ding.INK))
	if Investigation.REPLIES.has(chosen):
		var send := Ding.chip(pages,heading,"发送",func() -> void: pages.action_requested.emit("c35_trace:submit",null))
		send.name="C35SendHomework"
		send.custom_minimum_size.x=72
		send.size_flags_horizontal=Control.SIZE_SHRINK_END
	var attach := Ding.chip(pages,compose,Investigation.FILE_NAMES[id]+"  ›",func() -> void: pages.action_requested.emit("c35_trace:replace_file",null))
	attach.tooltip_text="更换附件"
	attach.accessibility_name="更换附件"
	var field := TextEdit.new()
	field.name="C35SubmissionText"
	field.editable=false
	field.focus_mode=Control.FOCUS_NONE
	field.mouse_filter=Control.MOUSE_FILTER_IGNORE
	field.wrap_mode=TextEdit.LINE_WRAPPING_BOUNDARY
	field.custom_minimum_size.y=98
	field.scroll_fit_content_height=true
	field.placeholder_text="请选择一条说明"
	field.text=Investigation.REPLIES.get(chosen,"")
	field.accessibility_name="补交说明"
	Typography.apply_body(field)
	field.add_theme_color_override("font_readonly_color",Ding.INK)
	field.add_theme_stylebox_override("read_only",NativeUi.box(Ding.WHITE,Ding.LINE,1,8,Vector2(10,8)))
	compose.add_child(field)
	var choose := Ding.chip(pages,compose,"选择补交说明…",func() -> void:
		Ding.choice_sheet(pages,frame,"补交说明",Investigation.REPLIES,func(value: String) -> void:
			pages.action_requested.emit("c35_trace:reply",value)))
	choose.name="C35ChooseHomework"

func section(pages, frame: Control, title: String, copy: String) -> VBoxContainer:
	var block: VBoxContainer=pages.card(frame.content,Palette.PAPER)
	var heading: Label=pages.label(title,20,Palette.INK)
	heading.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	block.add_child(heading)
	var body: Label=pages.label(copy,17,Palette.SECONDARY)
	body.autowrap_mode=TextServer.AUTOWRAP_ARBITRARY
	block.add_child(body)
	return block

func link_action(pages,parent: Control,text: String,action: String,value: Variant=null) -> Button:
	var control := pages.action(parent,text,"c35_trace:"+action,value,true) as Button
	pages.lake_primary(control)
	return control

func campus_layers() -> RefCounted:
	if layers==null:
		layers=CampusLayers.new()
		if not layers.configure():
			push_error("Chapter 3.5 campus resources: "+str(layers.errors))
	return layers

func build_map(pages, frame: Control) -> void:
	frame.scroll.vertical_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED
	frame.content_margin.add_theme_constant_override("margin_bottom",10)
	frame.content.add_theme_constant_override("separation",10)
	var clue: VBoxContainer=pages.card(frame.content,Palette.NIGHT)
	var caption: Label=pages.label("周琪：启真湖西北，找庭院中间的南北绿带。东门已锁，从西侧大厅进。",15,Palette.PALE)
	caption.autowrap_mode=TextServer.AUTOWRAP_ARBITRARY
	clue.add_child(caption)
	var search := LineEdit.new()
	search.name="C35MapSearch"
	search.placeholder_text="搜索校园地点"
	search.accessibility_name="搜索校园地点"
	search.clear_button_enabled=true
	search.custom_minimum_size.y=42
	Typography.apply_body(search)
	frame.content.add_child(search)
	var map := Campus.new()
	map.layers=campus_layers()
	var lake_gate: Dictionary=pages.module.world("campus_bootstrap").get("manifest",{}).get("qizhen",{}).get("gate",{})
	if lake_gate.has("x") and lake_gate.has("y"):
		map.lake_gate=Vector2(float(lake_gate.x),float(lake_gate.y))
	map.restore(map_pose)
	frame.content.add_child(map)
	build_map_tools(pages,map,search)
	var confirm: Button=pages.button(map,"使用这个落点",func() -> void:
		var chosen: Vector2=map.pin
		map.clear_pin()
		pages.action_requested.emit("c35_trace:pin",[chosen.x,chosen.y]),true)
	pages.lake_primary(confirm)
	confirm.size=Vector2(162,44)
	var place_callout := func() -> void:
		var tip: Vector2=map._map_origin()+map.pin*map._map_scale()
		confirm.visible=map.pin.is_finite() and Rect2(Vector2.ZERO,map.size).has_point(tip)
		if not confirm.visible: return
		var top := tip.y-72 if tip.y>=78 else tip.y+10
		confirm.position=Vector2(clampf(tip.x-confirm.size.x/2,6,map.size.x-confirm.size.x-6),top)
	map.resized.connect(place_callout)
	place_callout.call()
	map.pose_changed.connect(func(pose: Dictionary) -> void:
		map_pose=pose
		place_callout.call())

func build_map_tools(pages,map: Control,search: LineEdit) -> void:
	var controls := VBoxContainer.new()
	map.add_child(controls)
	controls.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_RIGHT)
	controls.offset_left=-52;controls.offset_right=-8;controls.offset_bottom=-8
	controls.offset_top=-102
	var north := pages.button(controls,"",map.overview) as Button
	north.name="C35MapOverview";north.tooltip_text="正北 · 回到校园全图";north.accessibility_name=north.tooltip_text
	map_tool_icon(north,true)
	var locate := pages.button(controls,"",func() -> void: map.show_area(map.lake_gate)) as Button
	locate.name="C35MapLocate";locate.tooltip_text="定位到启真湖入口";locate.accessibility_name=locate.tooltip_text
	map_tool_icon(locate,false)

	var results := pages.card(map,Palette.PAPER) as VBoxContainer
	var panel := results.get_parent() as PanelContainer
	panel.hide()
	panel.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	panel.offset_left=8;panel.offset_right=-8;panel.offset_top=8
	var places := {"启真湖入口":["启真湖 码头 湖",map.lake_gate]}
	var landmarks := {"north_teaching_V3":["北教学区","北教 段永平 A楼 教学楼"],"library":["基础图书馆","图书馆 基础馆"],"theater":["小剧场","剧场 梁祝"],"main_library_v1":["主图书馆","图书馆 主馆"]}
	for layer: Dictionary in map.layers.manifest.get("layers",[]):
		if not landmarks.has(layer.id): continue
		var names: Array=landmarks[layer.id]
		var origin := Vector2(layer.origin[0],layer.origin[1])
		var extent := Vector2(layer.nativeSize[0],layer.nativeSize[1])*float(layer.get("scale",1.0))
		places[names[0]]=[names[1],origin+extent/2]
	var no_results := pages.label("没有匹配的校园地点",15,Palette.SECONDARY) as Label
	results.add_child(no_results)
	var options: Array[Button]=[]
	for place: String in places:
		var area: Vector2=places[place][1]
		var option := pages.button(results,place,func() -> void:
			search.text=place
			panel.hide()
			map.show_area(area)
			map.grab_focus()) as Button
		option.set_meta("keywords",place+" "+places[place][0])
		options.append(option)
	var filter := func(query: String) -> void:
		var count:=0
		var term:=query.strip_edges().to_lower().replace(" ","")
		for option: Button in options:
			option.visible=term.is_empty() or str(option.get_meta("keywords")).to_lower().replace(" ","").contains(term)
			if option.visible: count+=1
		no_results.visible=count==0
		panel.show()
	search.focus_entered.connect(func() -> void: filter.call(search.text))
	search.text_changed.connect(filter)
	search.text_submitted.connect(func(_text: String) -> void:
		for option: Button in options:
			if option.visible:
				option.pressed.emit()
				return)
	map.focus_entered.connect(panel.hide)

func map_tool_icon(button: Button, compass: bool) -> void:
	var icon := Control.new()
	icon.mouse_filter=Control.MOUSE_FILTER_IGNORE
	button.add_child(icon)
	icon.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	icon.draw.connect(func() -> void:
		var point := icon.size/2
		if compass:
			icon.draw_circle(point,13,Palette.EDGE,false,1.5,true)
			icon.draw_colored_polygon(PackedVector2Array([point+Vector2(0,-11),point+Vector2(-5,4),point+Vector2(5,4)]),Color("a34438"))
			icon.draw_colored_polygon(PackedVector2Array([point+Vector2(0,11),point+Vector2(-5,-4),point+Vector2(5,-4)]),Palette.NIGHT)
		else:
			icon.draw_circle(point,9,Palette.NIGHT,false,1.8,true)
			icon.draw_circle(point,3,Palette.NIGHT)
			for direction: Vector2 in [Vector2.UP,Vector2.DOWN,Vector2.LEFT,Vector2.RIGHT]:
				icon.draw_line(point+direction*9,point+direction*13,Palette.NIGHT,2,true))
