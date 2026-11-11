extends RefCounted
const Frame = preload("res://scripts/ui/phone_app_frame.gd")
const Palette = preload("res://scripts/ui/chapter35_palette.gd")
const Investigation = preload("res://scripts/chapters/c35_investigation.gd")
const Campus = preload("res://scripts/ui/c35_campus_pin_map.gd")
const CampusLayers = preload("res://scripts/presentation/campus_layered_map.gd")
const Typography = preload("res://scripts/ui/native_typography.gd")
const NativeUi = preload("res://scripts/ui/native_ui_theme.gd")
const Ding = preload("res://scripts/ui/c35_ding_chat.gd")
const HallRecording = preload("res://scripts/ui/c35_hall_recording.gd")
const HOMEWORK_NOTICE := "@全体成员 今晚 23:00 截止第十周作业补交。没交成功的同学请点我头像私信，发 PDF，带姓名和学号。"
const PHOTOS := {
	"lake":["IMG_夜间湖面_01.jpg","22:31","lake_memory_a"],
	"dock":["IMG_靠岸船头_02.jpg","22:35","paper_right"],
}
const CHAT_HISTORY := [
	["22:38","chen_mo","第七题那个反常积分到底收不收敛？我写了半页。"],
	["22:39","lin_xiao","化成 p-积分比一下，我刚写完拍了。"],
	["22:40","zhao_yu","刚从红边球场那边路过，看见保安打着手电往北教东门赶。估计要提前锁门了。"],
	["22:41","lin_xiao","还好我溜得快，启真湖那边风好大。"],
]

var map_pose: Dictionary={}
var source_state: Dictionary={}
var layers: RefCounted

func build(pages, snapshot: Dictionary) -> Control:
	if not is_same(source_state,snapshot):
		map_pose={}
		source_state=snapshot
	var step := Investigation.step(snapshot)
	var route: Dictionary=snapshot.native[Investigation.KEY]
	if step not in ["private","map","entrance"]: layers=null
	var frame := Frame.new()
	frame.name="C35Investigation"
	frame.enable_touch_reading()
	frame.background.color=Palette.BACKDROP
	var app: Array={
		"inbox":["浙大钉","消息"],"notice":["课程群",""],"assignment":["课程助教","微积分（甲）"],"camera":["相机","作业扫描"],
		"files":["最近项目","本机文件与照片"],"file":["文件预览",Investigation.FILE_NAMES[route.get("preview_file",Investigation.LEGACY_FILE_ID)]],
		"attached":["课程助教","微积分（甲）"],"file_error":["课程助教","微积分（甲）"],"receipt":["课程助教","微积分（甲）"],"album_trace":["照片","最近项目"],"journal":["记录恢复",""],
		"group":["课程群",""],"seen":["课程群",""],"private":["周琪","浙大钉 · 私聊"],
		"map":["紫金港校园地图","位置共享"],"entrance":["紫金港校园地图","比对入口方向"],"arrival":["北教学区","夜间录音与校园网"],"confirmed":["记录恢复",""],
	}.get(step,["记录恢复",""])
	var back_action: String={"camera":"cancel_camera","files":"close_files","file":"close_preview","attached":"replace_file","album_trace":"close_album"}.get(step,"")
	frame.configure(app[0],app[1],0,back_action.is_empty())
	frame.back_requested.connect(func() -> void:
		if not back_action.is_empty():
			pages.action_requested.emit("c35_trace:"+back_action,null)
			return
		layers=null
		pages.page_requested.emit("phone_home"))
	build_note(pages,frame,snapshot,route)
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
			for item: Array in CHAT_HISTORY:
				chat_time(pages,frame,item[0])
				Ding.bubble(pages,frame.content,item[1],item[2],Ding.profile.bind(pages,frame,item[1]))
			chat_time(pages,frame,"22:48")
			Ding.bubble(pages,frame.content,"ta",HOMEWORK_NOTICE,open_ta)
			frame.ready.connect(func() -> void:
				await frame.get_tree().process_frame
				if not is_instance_valid(frame) or not frame.is_inside_tree(): return
				var bar := frame.scroll.get_v_scroll_bar() as VScrollBar
				frame.scroll.scroll_vertical=ceili(bar.max_value-bar.page))
		"assignment":
			Ding.bubble(pages,frame.content,"ta","来自微积分（甲）课程群\n第十周作业补交")
			var sources := Ding.bubble(pages,frame.content,"player","添加作业",Callable(),true)
			var actions := HBoxContainer.new()
			actions.add_theme_constant_override("separation",6)
			sources.add_child(actions)
			Ding.chip(pages,actions,"＋ 附件",func() -> void: pages.action_requested.emit("c35_trace:files",null)).name="C35HomeworkAttachments"
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
			if snapshot.chapterThreeInterlude.evidenceIds.has("journal_start"):
				var thread := section(pages,frame,"微积分（甲）课程群","有同学在聊今晚北教的闭楼通知。")
				link_action(pages,thread,"打开课程群","continue_group")
			else:
				var reminder := Ding.surface(pages,frame.content,Ding.WHITE,Vector2(12,10),12)
				var banner := reminder.get_parent() as Control
				frame.content.move_child(banner,0)
				reminder.add_child(pages.label("照片 · 2 张夜间照片尚未同步",16,Ding.INK))
				Ding.chip(pages,reminder,"查看最近项目",func() -> void: pages.action_requested.emit("c35_trace:open_album","dock"))
				if not route.get("album_seen",false) and not snapshot.native.get("settings",{}).get("reduced_motion",false):
					banner.modulate.a=0
					frame.ready.connect(func() -> void:
						banner.create_tween().tween_property(banner,"modulate:a",1.0,.2))
		"album_trace": build_album(pages,frame,route)
		"journal":
			var trace := section(pages,frame,"离湖时间","上岸后的去向没同步。划船帖里还留着返航记录。")
			pages.lake_primary(pages.navigate(trace,"继续查看划船帖","c35_journal",true))
		"group","seen":
			var contact := func(id: String) -> bool:
				if step!="seen" or id not in ["zhou_qi","chen_jia"]: return false
				pages.action_requested.emit("c35_trace:private",id)
				return true
			Ding.group_settings(pages,frame,contact,"群公告：第十周作业补交请私信课程助教。")
			chat_time(pages,frame,"22:40")
			Ding.bubble(pages,frame.content,"zhao_yu",CHAT_HISTORY[2][2])
			chat_time(pages,frame,"22:50")
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
				Ding.bubble(pages,frame.content,"zhao_yu","我在东门那儿还瞥见个人影。林星宇，你是不是跟着保安进去了？")
				Ding.bubble(pages,frame.content,"zhou_qi","@林星宇 你刚给我发过位置共享，我这儿还留着。私聊说。",func() -> void: contact.call("zhou_qi"))
		"private":
			Ding.bubble(pages,frame.content,"player","你那儿的定位还能打开吗？",Callable(),true,"已读")
			Ding.bubble(pages,frame.content,"zhou_qi","赵宇看到的是保安去巡门。你发语音说东门铁门拉了两下没开，准备沿中间那条长绿地绕到另一头。")
			var share := Ding.bubble(pages,frame.content,"zhou_qi","信号到 22:42:04 就断了。我这儿只加载出一块。")
			var cached := Ding.chip(pages,share,"位置共享 · 已过期  ›",func() -> void: show_fragment(pages,frame))
			cached.name="C35LocationShare"
		"map": build_map(pages,frame)
		"entrance": build_entrance(pages,frame)
		"arrival": build_verification(pages,frame,route)
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
		if id==Investigation.PHOTO_ID:
			var recent := HBoxContainer.new()
			recent.add_theme_constant_override("separation",8)
			frame.content.add_child(recent)
			for key: String in PHOTOS:
				var photo: Array=PHOTOS[key]
				var tile := Ding.surface(pages,recent,Ding.WHITE,Vector2(9,8),8)
				tile.get_parent().size_flags_horizontal=Control.SIZE_EXPAND_FILL
				var thumbnail: TextureRect=pages.image_node("res://assets/ui/photo-evidence/chapter35_live_%s.webp" % photo[2],Vector2(0,92))
				thumbnail.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_COVERED
				tile.add_child(thumbnail)
				tile.add_child(pages.label("%s  ·  未同步" % photo[1],14,Color("9f3036")))
				var open := link_action(pages,tile,"夜间湖面" if key=="lake" else "靠岸船头","open_album",key)
				open.name="C35RecentPhoto_"+key


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
	var choices: Dictionary=Investigation.REPLIES
	if route.get("identity_requested",false):
		choices={"identity":"我是林星宇，学号 3250100755。刚忘了备注，麻烦学长了！"}
	var choose := Ding.chip(pages,compose,"补发姓名和学号…" if choices.size()==1 else "选择补交说明…",func() -> void:
		Ding.choice_sheet(pages,frame,"补交说明",choices,func(value: String) -> void:
			pages.action_requested.emit("c35_trace:reply",value)))
	choose.name="C35ChooseHomework"

func chat_time(pages,frame: Control,time: String) -> void:
	var stamp := pages.label(time,13,Ding.MUTED) as Label
	stamp.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	frame.content.add_child(stamp)

func build_album(pages,frame: Control,route: Dictionary) -> void:
	var key: String=route.get("album_photo","dock")
	var photo: Array=PHOTOS.get(key,PHOTOS.dock)
	var entry := section(pages,frame,photo[0],"拍摄于 %s  ·  云端未同步" % photo[1])
	var preview := pages.image_node("res://assets/ui/photo-evidence/chapter35_live_%s.webp" % photo[2],Vector2(0,220)) as TextureRect
	preview.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	entry.add_child(preview)
	if key=="dock":
		entry.add_child(pages.label("关联草稿 · CC98 校园生活",15,Palette.SECONDARY))
		link_action(pages,entry,"查看 CC98 划船帖","journal")
	else:
		entry.add_child(pages.label("同一组里还有一张靠岸时拍的照片。",15,Palette.SECONDARY))

func build_note(pages,frame: Control,snapshot: Dictionary,route: Dictionary) -> void:
	if not snapshot.chapterThreeInterlude.evidenceIds.has("journal_start"): return
	var pin := pages.button(frame.toolbar,"便签",func() -> void: toggle_note(pages,frame,snapshot,route)) as Button
	pin.name="C35InvestigationNote"
	pin.position=Vector2(364,7)
	pin.size=Vector2(52,42)
	NativeUi.apply_button(pin,Ding.WHITE,Ding.LINK,Ding.LINE,9,1,14,Vector2(6,4),Ding.LINK)

func toggle_note(pages,frame: Control,snapshot: Dictionary,route: Dictionary) -> void:
	var prior := frame.get_node_or_null("C35NoteDrawer")
	if prior!=null:
		prior.queue_free()
		return
	var drawer := VBoxContainer.new()
	drawer.name="C35NoteDrawer"
	drawer.z_index=57
	drawer.position=Vector2(42,56)
	drawer.size.x=374
	frame.add_child(drawer)
	var notes := Ding.surface(pages,drawer,Ding.WHITE,Vector2(14,13),10)
	notes.add_child(pages.label("调查便签",19,Ding.INK))
	notes.add_child(pages.label("22:37:05  ·  在启真湖小码头上岸",16,Ding.INK))
	if Investigation.STEPS.find(Investigation.step(snapshot))>=Investigation.STEPS.find("private"):
		notes.add_child(pages.label("22:42:04  ·  东门外的位置共享断开",16,Ding.INK))
	if route.get("entry_side","")=="west":
		notes.add_child(pages.label("绕过中庭绿地，往西侧大厅走",16,Ding.INK))
	if route.get("broadcast_heard",false):
		notes.add_child(pages.label("22:45:00  ·  听见清楼广播",16,Ding.INK))
	Ding.chip(pages,notes,"收起便签",drawer.queue_free)

func fragment_preview(height: float) -> Control:
	var view := Control.new()
	view.name="C35CachedMapFragment"
	view.custom_minimum_size=Vector2(0,height)
	view.clip_contents=true
	view.mouse_filter=Control.MOUSE_FILTER_IGNORE
	view.texture_filter=CanvasItem.TEXTURE_FILTER_NEAREST
	var art := campus_layers()
	view.draw.connect(func() -> void:
		var district: Rect2=Investigation.NORTH_TEACHING_AREA
		var crop := district.grow_individual(20,300,20,8)
		var factor := view.size.y/crop.size.y
		var origin: Vector2=view.size*.5-crop.get_center()*factor
		view.draw_rect(Rect2(Vector2.ZERO,view.size),Palette.NIGHT)
		art.draw_background(view,origin,factor,view.size,0)
		view.draw_rect(Rect2(Vector2.ZERO,view.size),Color(0.19,0.27,0.34,0.40))
		var route := PackedVector2Array([
			origin+Vector2(district.end.x-12,district.get_center().y-25)*factor,
			origin+Vector2(district.end.x-54,district.get_center().y+10)*factor,
			origin+Vector2(district.position.x+48,district.get_center().y+12)*factor])
		for i in range(1,route.size()):
			view.draw_dashed_line(route[i-1],route[i],Palette.PENDING,2,7)
		view.draw_circle(route[0],5,Palette.PAPER)
		view.draw_rect(Rect2(view.size.x*.88,0,view.size.x*.12,view.size.y*.36),Palette.NIGHT)
		view.draw_rect(Rect2(0,view.size.y*.82,view.size.x*.16,view.size.y*.18),Palette.NIGHT))
	view.resized.connect(view.queue_redraw)
	return view

func show_fragment(pages,frame: Control) -> void:
	var old: Node=frame.content.find_child("C35SharedMapCache",true,false)
	if old!=null: return
	var cached := section(pages,frame,"缓存位置残片","最后更新于 22:42:04")
	cached.name="C35SharedMapCache"
	cached.add_child(fragment_preview(228))
	link_action(pages,cached,"在校园地图中比对落点","map")
	frame.scroll.ensure_control_visible.call_deferred(cached)

func build_entrance(pages,frame: Control) -> void:
	var card := section(pages,frame,"北教学区","位置卡断开时，林星宇还在东门外。沿着院落中间的绿地，他接下来绕向哪一侧？")
	card.add_child(fragment_preview(224))
	link_action(pages,card,"跟着保安走东门","entrance","east").name="C35EastEntrance"
	link_action(pages,card,"绕过绿地走西侧","entrance","west").name="C35WestEntrance"

func build_verification(pages,frame: Control,route: Dictionary) -> void:
	var heard: bool=route.get("broadcast_heard",false)
	if route.get("entry_side","")=="west":
		Ding.bubble(pages,frame.content,"zhou_qi","对，那一侧是推拉玻璃门。你刚进去几秒语音就断了。")
	var audio := section(pages,frame,"未命名环境录音","本机 · 5 秒")
	var playback := HallRecording.new()
	audio.add_child(playback)
	playback.build(pages,heard,float(pages.state.native.get("settings",{}).get("volume",1.0)))
	playback.broadcast_reviewed.connect(func() -> void: pages.action_requested.emit("c35_trace:broadcast",null))
	var list := section(pages,frame,"ZJUWLAN 连接记录","北教学区  ·  22:35 – 22:50")
	for i: int in Investigation.RECORDS.size():
		var record: Array=Investigation.RECORDS[i]
		var item := Ding.surface(pages,list,Ding.WHITE,Vector2(11,9),8)
		item.add_child(pages.label("%02d  ·  %s  ·  %s" % [i+1,record[1],record[2]],16,Ding.INK))
		var details := VBoxContainer.new()
		details.visible=false
		var show := Ding.chip(pages,item,"详情",func() -> void: details.visible=not details.visible)
		show.name="C35RecordDetail_"+record[0]
		item.add_child(details)
		details.add_child(pages.label("%s  ·  %s" % [record[3],record[4]],15,Ding.MUTED))
		var compare := link_action(pages,details,"对照录音","compare",record[0])
		compare.name="C35Compare_"+record[0]

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
	var caption: Label=pages.label("周琪：启真湖西北，红边球场隔街往南。\n找排成田字的四组院落，中间有长条绿地。",15,Palette.PALE)
	caption.name="C35MapClue"
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
	var residual := fragment_preview(96)
	residual.modulate.a=.84
	residual.visible=false
	map.add_child(residual)
	residual.position=Vector2(9,0)
	residual.size=Vector2(122,96)
	var residual_toggle := Ding.chip(pages,map,"残片",func() -> void: residual.visible=not residual.visible)
	residual_toggle.name="C35MapFragmentToggle"
	residual_toggle.size=Vector2(70,42)
	var place_residual := func() -> void:
		residual_toggle.position=Vector2(9,map.size.y-51)
		residual.position.y=map.size.y-154
	map.resized.connect(place_residual)
	place_residual.call()
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
