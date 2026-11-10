extends RefCounted
## App-specific native Control reconstruction of Chapter 3 phone evidence surfaces.
## Emits only intents. Buttons never mutate validated puzzle facts.
signal action_requested(id: String,value: Variant)
signal page_requested(page: String)
const NativeUi=preload("res://scripts/ui/native_ui_theme.gd")
const Palette=preload("res://scripts/ui/phone_palette.gd")
const Typography=preload("res://scripts/ui/native_typography.gd")
const JournalPages=preload("res://scripts/ui/c3_journal_pages.gd")
var journal_builder: RefCounted=JournalPages.new()
const VoiceProgress=preload("res://scripts/ui/c3_voice_progress.gd")
const PhotoSequence=preload("res://scripts/ui/c35_photo_sequence.gd")
const AppFrame=preload("res://scripts/ui/phone_app_frame.gd")
const LakePalette=preload("res://scripts/ui/chapter35_palette.gd")
const InvestigationPages=preload("res://scripts/ui/c35_investigation_pages.gd")
const Investigation=preload("res://scripts/chapters/c35_investigation.gd")
const DingChoices=preload("res://scripts/ui/c35_ding_chat.gd")
var investigation_pages := InvestigationPages.new()
const WechatSocial=preload("res://scripts/ui/wechat_social_pages.gd")
const WechatChrome=preload("res://scripts/ui/wechat_chrome.gd")
var current_view: Dictionary={}
var footer: VBoxContainer
var scroll_offsets: Dictionary={}
var return_pages: Dictionary={}
var photo_view_id: String=""
var expanded_voice_id: String=""
var rejection_choices: Dictionary={}
var destination_choice: String=""
const Interlude=preload("res://scripts/chapters/c3_interlude.gd")
var module: RefCounted=Interlude.new()
var state: Dictionary={}
var page_id: String=""
const INK=Palette.INK
const GREEN=Palette.ACCENT
const MUTED=Palette.MUTED
# These pages already use the logical 424px phone interior, not the older
# 378px authored canvas. Keep requested type sizes; never shrink them again.
# 15px remains above 12px after the 390px shell fit (366 / 430).
const CAPTION_FONT_SIZE := 15
# Keep secondary copy legible through the phone's low-battery display veil.
const INTRO_SECONDARY := Color("505050")

func _init() -> void:
	journal_builder.action_requested.connect(_journal_action)
	journal_builder.page_requested.connect(_journal_page)

func _journal_action(id: String,value: Variant) -> void:
	action_requested.emit(id,value)

func _journal_page(page: String) -> void:
	page_requested.emit(page)

func build(page: String, _view: Dictionary, s: Dictionary) -> Control:
	var requested_page := page
	if page=="photos" and s.qizhenLake.phase=="complete" and not s.chapterThreeInterlude.completed: page="c35_photos"
	if page in ["c3_journal","c3_journal_camera"]: return journal_builder.build(page,_view,s)
	if page not in ["c35_recovery","c35_journal","c35_photos","c35_voice","c35_official","c35_messages","c35_network","c3_ticket_post"]: return null
	if not is_same(state,s):
		return_pages.clear()
		scroll_offsets.clear()
		photo_view_id=""
	state=s;current_view=_view;page_id=page
	if requested_page=="photos" or (page=="c35_voice" and _view.get("previous_phone_page")=="phone_home"):
		return_pages[page]="phone_home"
	if page!="c35_photos":photo_view_id=""
	if page=="c35_recovery" and Investigation.has_route(s): return investigation_pages.build(self,s)
	if page=="c35_recovery" and not s.chapterThreeInterlude.recoveryOpened: return recovery_intro()
	var frame := AppFrame.new()
	frame.name="C35App_"+page
	var headings: Dictionary={"c35_recovery":["记录恢复",""],"c35_journal":["CC98","我的帖子"],"c35_photos":["照片","恢复的项目"],"c35_voice":["语音备忘录",""],"c35_official":["紫金港楼宇服务","公众号"],"c35_messages":["麦斯威夜间自习群","18 位成员"],"c35_network":["夜间接入记录",""],"c3_ticket_post":["临时退票","CC98 · 校园生活"]}
	if page=="c35_photos" and not photo_view_id.is_empty():headings[page]=["查看照片",""]
	var scroll_key := page+("_viewer" if page=="c35_photos" and not photo_view_id.is_empty() else "")
	var exits: bool=page in ["c35_recovery","c3_ticket_post"] or (return_pages.get(page)=="phone_home" and (page!="c35_photos" or photo_view_id.is_empty()))
	frame.configure(headings[page][0],headings[page][1],int(scroll_offsets.get(scroll_key,0)),exits)
	frame.scroll_changed.connect(func(value: float) -> void: scroll_offsets[scroll_key]=int(value))
	frame.back_requested.connect(_back)
	footer=frame.footer
	if page in ["c35_recovery","c35_journal","c35_photos","c35_messages"]:
		frame.background.color=LakePalette.BACKDROP
	match page:
		"c35_recovery": recovery(frame.content)
		"c35_journal": journal(frame)
		"c35_photos":
			if photo_view_id.is_empty():photos(frame.content)
			else:photo_viewer(frame.content)
		"c35_voice": voice(frame.content)
		"c35_official": official(frame.content)
		"c35_messages": messages(frame.content)
		"c35_network": network(frame.content)
		"c3_ticket_post": ticket(frame.content)
	return frame

func _back() -> void:
	if page_id=="c35_photos" and not photo_view_id.is_empty():
		photo_view_id="";page_requested.emit("c35_photos");return
	if page_id=="c35_voice":action_requested.emit("c35_voice_exit",return_pages.get(page_id,"c35_recovery"));return
	page_requested.emit(str(return_pages.get(page_id,"phone_home" if page_id in ["c35_recovery","c3_ticket_post"] else "c35_recovery")))

func recovery_intro() -> Control:
	var frame := AppFrame.new()
	frame.name="C35RecoveryIntro"
	frame.configure("记录恢复","",0,true)
	frame.back_button.name="C35IntroBack"
	frame.back_requested.connect(func() -> void:page_requested.emit("phone_home"))
	frame.content.add_theme_constant_override("separation",18)
	var intro: Dictionary=module.copy_data().intro
	var scene := intro_group(frame.content,6)
	var art := image_node("res://assets/native/chapter35_recovery_20261023/lake_memory.png",Vector2(0,164))
	art.name="C35IntroArt";art.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_COVERED
	scene.add_child(art)
	var location := label("启真湖小码头 · 上岸后",15,INTRO_SECONDARY)
	location.name="C35IntroLocation"
	scene.add_child(location)

	var record := intro_group(frame.content,6)
	var title := label("未同步的七分五十五秒",28,INK)
	title.name="C35IntroTitle"
	record.add_child(title)
	var status := label(intro.heading,16,INTRO_SECONDARY)
	status.name="C35IntroStatus"
	record.add_child(status)

	rule(frame.content)
	var dialogue := intro_group(frame.content,12)
	intro_passage(intro_group(dialogue,3),"C35IntroNarrator","旁白",intro.detail,INTRO_SECONDARY)
	intro_passage(intro_group(dialogue,3),"C35IntroPlayer","林星宇",intro.player,INK)

	var next_step := card(frame.content,Palette.SURFACE)
	next_step.add_theme_constant_override("separation",5)
	# Keep the forum name with the action at the phone's fixed reading width.
	var instruction := str(intro.system).replace("。先","。\n先").replace("，把","，\n把")
	intro_passage(next_step,"C35IntroSystem","下一步 · CC98",instruction,INK)
	var begin := action(frame.footer,"开始恢复","c35_begin",null,true);begin.name="C35BeginRecovery"
	lake_primary(begin)
	begin.custom_minimum_size.y=50
	return frame

func intro_group(parent: Control, separation: int) -> VBoxContainer:
	var group := VBoxContainer.new()
	group.add_theme_constant_override("separation",separation)
	parent.add_child(group)
	return group

func intro_passage(group: VBoxContainer, node_name: String, speaker: String, copy: String, color: Color) -> void:
	group.name=node_name
	group.add_child(label(speaker,15,INTRO_SECONDARY))
	group.add_child(label(copy,17,color))

func label(text: String, size: int=17, color: Color=INK) -> Label:
	var node: Label=Label.new()
	node.text=text
	node.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	node.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	node.add_theme_font_size_override("font_size",maxi(CAPTION_FONT_SIZE,size))
	Typography.apply_body(node)
	node.add_theme_color_override("font_color",color)
	return node

func display_label(text: String, size: int=15, color: Color=INK) -> Label:
	var node: Label=label(text,size,color)
	Typography.apply_display(node)
	return node

func card(parent: Control,color: Color=Palette.SURFACE) -> VBoxContainer:
	var panel := PanelContainer.new()
	panel.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	var style := StyleBoxFlat.new()
	style.bg_color=color;style.set_corner_radius_all(4)
	style.content_margin_left=14;style.content_margin_right=14
	style.content_margin_top=14;style.content_margin_bottom=14
	panel.add_theme_stylebox_override("panel",style)
	parent.add_child(panel)
	var box: VBoxContainer=VBoxContainer.new()
	box.add_theme_constant_override("separation",10)
	panel.add_child(box)
	return box

func button(parent: Control,text: String,callback: Callable,accent: bool=false) -> Button:
	var node: Button=Button.new()
	node.text=text
	Typography.apply_body(node)
	node.custom_minimum_size.y=44
	node.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	node.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	NativeUi.apply_button(node,Palette.ACCENT if accent else Palette.CONTROL,Palette.SURFACE if accent else INK,Palette.LINE,3,0,17,Vector2(12,10),Palette.ACCENT)
	node.pressed.connect(callback)
	parent.add_child(node)
	return node

func style_choice(choice: OptionButton) -> void:
	NativeUi.apply_button(choice,Palette.SURFACE,INK,Palette.LINE,3,1,16,Vector2(10,8),GREEN)
	var popup := choice.get_popup()
	popup.add_theme_stylebox_override("panel",NativeUi.box(Palette.SURFACE,Palette.LINE,1,3,Vector2(8,8)))
	popup.add_theme_stylebox_override("hover",NativeUi.box(Palette.SELECTED))
	popup.add_theme_color_override("font_color",INK);popup.add_theme_color_override("font_hover_color",INK)

func action(parent: Control,text: String,id: String,value: Variant=null,accent: bool=false) -> Button:
	var result := button(parent,text,func() -> void: action_requested.emit(id,value),accent)
	result.set_meta("intent",id);result.set_meta("intent_value",value)
	return result

func navigate(parent: Control,text: String,page: String,accent: bool=false) -> Button:
	return button(parent,text,func() -> void:
		return_pages[page]=page_id
		page_requested.emit(page),accent)

func lake_primary(control: Button) -> void:
	NativeUi.apply_button(control,LakePalette.NIGHT,LakePalette.PAPER,LakePalette.NIGHT,4,1,17,Vector2(12,8),LakePalette.PALE)
	control.add_theme_stylebox_override("disabled",NativeUi.box(LakePalette.DISABLED,LakePalette.DISABLED,1,4,Vector2(12,8)))
	control.add_theme_color_override("font_disabled_color",LakePalette.SECONDARY)

func eyebrow(parent: Control,text: String) -> void:
	parent.add_child(display_label(text,15,MUTED))

func image_node(path: String,size: Vector2,mirror: bool=false) -> TextureRect:
	var image: TextureRect=TextureRect.new()
	image.expand_mode=TextureRect.EXPAND_IGNORE_SIZE
	image.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	image.custom_minimum_size=size
	image.flip_h=mirror
	image.mouse_filter=Control.MOUSE_FILTER_IGNORE
	if ResourceLoader.exists(path): image.texture=load(path)
	return image

func rule(parent: Control) -> void:
	var divider := ColorRect.new()
	divider.color=Palette.LINE
	divider.custom_minimum_size.y=1
	divider.mouse_filter=Control.MOUSE_FILTER_IGNORE
	parent.add_child(divider)

func recovery_endpoint(row: HBoxContainer, caption: String, control_name: String, time: String) -> void:
	var endpoint := VBoxContainer.new()
	endpoint.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	endpoint.add_theme_constant_override("separation",3)
	row.add_child(endpoint)
	var value := label("待恢复" if time.is_empty() else time,24,LakePalette.PENDING if time.is_empty() else LakePalette.PAPER)
	value.name=control_name
	value.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	endpoint.add_child(value)
	var hint := label(caption,15,LakePalette.PALE)
	hint.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	endpoint.add_child(hint)

func recovery(root: VBoxContainer) -> void:
	var c: Dictionary=state.chapterThreeInterlude
	var has_departure: bool=c.evidenceIds.has("journal_start")
	var window := card(root,LakePalette.NIGHT)
	window.name="C35TimeWindow"
	window.add_child(label("待核验时间窗",16,LakePalette.PALE))
	var endpoints := HBoxContainer.new()
	endpoints.add_theme_constant_override("separation",8)
	window.add_child(endpoints)
	recovery_endpoint(endpoints,"离湖时间","C35RecoveryDepartureValue","22:37:05" if has_departure else "")
	var connector := ColorRect.new()
	connector.color=LakePalette.PALE
	connector.custom_minimum_size=Vector2(28,1)
	connector.size_flags_vertical=Control.SIZE_SHRINK_CENTER
	connector.mouse_filter=Control.MOUSE_FILTER_IGNORE
	endpoints.add_child(connector)
	recovery_endpoint(endpoints,"末段时间","C35RecoveryArrivalValue","22:45:00" if c.voiceSequenceSolved else "")
	if not has_departure:
		var departure := card(root)
		var departure_title := label("离湖记录",22)
		departure_title.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
		departure.add_child(departure_title)
		var copy := str(module.copy_data().intro.system).replace("。先","。\n先").replace("，把","，\n把")
		departure.add_child(label(copy,16,INTRO_SECONDARY))
		var open := navigate(departure,"查看划船帖","c35_journal",true)
		lake_primary(open)
		open.custom_minimum_size.y=48
		return
	var sources: Array=[
		["照片","连续帧", "c35_photos", c.photoSequenceSolved,"photo","album","eee5dd"],
		["录音","试听与排序", "c35_voice", c.voiceSequenceSolved,"voice","voice","f0d8d0"],
		["消息","楼宇通知与群聊", "c35_official", c.officialNoticeSaved and c.routeScreenshotSaved,"chat","messages","61b58c"],
		["网络","夜间接入记录", "c35_network", c.networkRecordRead,"network","campus","496a7b"]]
	var source_title := label("来源记录",16,INTRO_SECONDARY)
	source_title.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	root.add_child(source_title)
	var list := VBoxContainer.new()
	list.add_theme_constant_override("separation",0)
	root.add_child(list)
	var source_buttons: Array[Button]=[]
	for source: Array in sources:
		var open := WechatChrome.conversation(list,source[0],source[1],"已归档" if source[3] else "›",1.0)
		open.accessibility_name="查看"+source[0]
		for id in ["ConversationTime","ConversationPreview"]:
			open.find_child(id,true,false).add_theme_font_size_override("font_size",CAPTION_FONT_SIZE)
		open.find_child("ConversationTime",true,false).custom_minimum_size.x=50
		var icon := image_node("res://ui_assets/phone_icons/%s.svg" % source[5],Vector2.ZERO)
		var slot := open.find_child("AvatarSlot",true,false) as Control
		var icon_frame := Panel.new()
		icon_frame.position=Vector2(3,3);icon_frame.size=Vector2(42,42)
		icon_frame.mouse_filter=Control.MOUSE_FILTER_IGNORE
		icon_frame.add_theme_stylebox_override("panel",NativeUi.box(Color(source[6]),INK,2,4))
		slot.add_child(icon_frame)
		icon_frame.add_child(icon);icon.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT,Control.PRESET_MODE_MINSIZE,6)
		open.pressed.connect(func() -> void:
			return_pages[source[2]]="c35_recovery";page_requested.emit(source[2]))
		open.name="C35Source_"+source[4]
		source_buttons.append(open)
		open.gui_input.connect(func(event: InputEvent) -> void:
			if not event is InputEventKey or not event.pressed:return
			var index := source_buttons.find(open)
			var target := -1
			if event.keycode==KEY_DOWN:target=posmod(index+1,source_buttons.size())
			elif event.keycode==KEY_UP:target=posmod(index-1,source_buttons.size())
			elif event.keycode==KEY_HOME:target=0
			elif event.keycode==KEY_END:target=source_buttons.size()-1
			if target>=0:source_buttons[target].grab_focus();open.accept_event())
	if c.evidenceIds.size()!=4:return
	root.add_child(label("时间核验",19))
	var reasons: Array=[{"id":"number_not_time","label":"这是编号，不是本段记录的时间"},{"id":"earlier_independent_event","label":"这是更早的独立事件"},{"id":"frozen_local_clock","label":"这是本机冻结值，不能代表实际时间"}]
	for decoy: Dictionary in [{"id":"canteen_0755","label":"食堂 0755"},{"id":"theater_0832","label":"剧场 08:32"},{"id":"status_clock_075523","label":"状态栏 07:55:23"}]:
		var row := card(root);row.add_child(label(decoy.label,18))
		if c.rejectedDecoyIds.has(decoy.id):
			row.add_child(label("已排除",15,GREEN))
			row.add_child(label(module.copy_data().exclusionCopy[decoy.id],16,MUTED));continue
		var choose := OptionButton.new();choose.name="C35Reason_"+decoy.id;choose.fit_to_longest_item=false;choose.clip_text=true;choose.custom_minimum_size.y=44
		choose.size_flags_horizontal=Control.SIZE_EXPAND_FILL;choose.add_item("选择排除理由…")
		for reason: Dictionary in reasons:
			choose.add_item(reason.label)
			if rejection_choices.get(decoy.id,"")==reason.id:choose.select(choose.item_count-1)
		row.add_child(choose);style_choice(choose)
		var submit := button(row,"确认排除",func() -> void:action_requested.emit("c35_reject:"+decoy.id,rejection_choices.get(decoy.id,"")))
		submit.name="C35Reject_"+decoy.id;submit.disabled=not rejection_choices.has(decoy.id)
		choose.item_selected.connect(func(index: int) -> void:
			if index==0:rejection_choices.erase(decoy.id)
			else:rejection_choices[decoy.id]=reasons[index-1].id
			submit.disabled=index==0)
	var matrix := card(root);matrix.name="C35EvidenceMatrix"
	matrix.add_child(label("记录对照",19))
	matrix.add_child(label("离湖 · CC98 × 照片",17))
	matrix.add_child(label("同一移动过程，方向连续。",16,MUTED))
	matrix.add_child(label("末段 · 录音 × 网络",17))
	matrix.add_child(label("室内广播、三秒陌生设备与候选地点需要同时成立。",16,MUTED))
	var candidate_label := "尚未保存"
	for record: Dictionary in Interlude.RECORDS:
		if record.id==c.networkRecordId:candidate_label=record.label
	matrix.add_child(label("已保存的候选记录",15,MUTED))
	var candidate := label(candidate_label,16);candidate.name="C35EvidenceMatrixCandidate";matrix.add_child(candidate)
	if not module.exclusions_ready(c):return
	var timeline := card(root);timeline.name="C35RecoveredTimeline"
	timeline.add_child(label("恢复的时间线",19))
	for entry: Array in [["22:37:05","CC98 划船记录"],["时间缺失","恢复照片"],["区间末段","夜间接入记录"],["22:45:00","广播录音"]]:
		timeline.add_child(label(entry[0]+"  ·  "+entry[1],16))
	if c.destinationId==null:
		var destination := card(root);destination.add_child(label("最终地点",19))
		var choose := OptionButton.new();choose.name="C35Destination";choose.fit_to_longest_item=false;choose.clip_text=true;choose.custom_minimum_size.y=44;choose.add_item("选择与记录相符的地点…");destination.add_child(choose);style_choice(choose)
		for place: Dictionary in Interlude.DESTINATIONS:
			choose.add_item(place.label)
			if destination_choice==place.id:choose.select(choose.item_count-1)
		var submit := button(destination,"确认地点",func() -> void:action_requested.emit("c35_destination",destination_choice),true)
		submit.name="C35ConfirmDestination";submit.disabled=destination_choice.is_empty()
		choose.item_selected.connect(func(index: int) -> void:
			destination_choice="" if index==0 else Interlude.DESTINATIONS[index-1].id;submit.disabled=index==0)
	else:
		var replay := card(root);replay.name="C35RecoveredPath"
		replay.add_child(label("路径记录已恢复",19))
		replay.add_child(label(module.copy_data().destinationConfirmed,16))
		replay.add_child(label("回放会从启真湖最后一帧开始，并在已确认地点结束。",16,MUTED))
		action(footer,"开始回放","c35_replay",null,true)

func journal(frame: Control) -> void:
	var root: VBoxContainer=frame.content
	var article := card(root,LakePalette.PAPER)
	article.add_child(label("启真湖划船记录｜风景很好，返程提前了",23))
	article.add_child(label("林星宇  ·  楼主",16,Color("346589")))
	var photo := image_node("res://assets/ui/photo-evidence/chapter35_live_lake_memory_a.webp",Vector2(0,202))
	photo.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_COVERED
	article.add_child(photo)
	article.add_child(label("从小码头下水。湖面比岸边安静，风从剧场方向过来。最后一张照片没同步上来，我先回岸上整理。",17))
	article.add_child(label("启真湖 · 22:37:05",15,MUTED))
	var published: bool=state.chapterThreeInterlude.evidenceIds.has("journal_start")
	if published:
		var receipt := card(root,LakePalette.SELECTED)
		receipt.name="C35JournalReceipt"
		receipt.add_child(label("收尾回复已发布 · 离湖时间已保存",15,LakePalette.INK))
	var replies := card(root,LakePalette.PAPER)
	for reply: Array in [["2楼","晚上水面反光挺亮，靠岸别太快。"],["3楼","最后一张图像是朝东边拍的。"]]:
		if replies.get_child_count()>0:rule(replies)
		replies.add_child(label(reply[0],15,MUTED))
		replies.add_child(label(reply[1],17))
	if published: return
	var choices: Dictionary={}
	for id: String in ["safe_return","details_withheld"]:
		var reply: Dictionary=module.copy_data().journalReplies[id]
		choices[id]=str(reply.label)+"\n"+str(reply.body)
	var reply_field := button(replies,"回复这条记录…",func() -> void:
		DingChoices.choice_sheet(self,frame,"选择要发布的回复",choices,func(id: String) -> void:
			action_requested.emit("c35_journal",id)))
	reply_field.name="C35JournalComposer"
	reply_field.alignment=HORIZONTAL_ALIGNMENT_LEFT

func photos(root: VBoxContainer) -> void:
	var selected: Array=state.native.get("c35_photo_selection",[])
	var stage := card(root,LakePalette.NIGHT);stage.name="C35PhotoOrder"
	stage.add_child(label("连续帧顺序  %d / 3" % selected.size(),17,LakePalette.PAPER))
	var strip := HBoxContainer.new();strip.add_theme_constant_override("separation",8);stage.add_child(strip)
	for index: int in range(3):
		var filled: bool=index<selected.size()
		var cell := card(strip)
		cell.add_theme_constant_override("separation",3)
		cell.custom_minimum_size.y=73
		cell.get_parent().add_theme_stylebox_override("panel",NativeUi.box(LakePalette.SELECTED if filled else LakePalette.NIGHT,LakePalette.PALE if filled else LakePalette.EDGE,1,4,Vector2(6,5)))
		if filled:
			for frame: Dictionary in Interlude.FRAMES:
				if frame.id==selected[index]:
					cell.add_child(image_node("res://assets/ui/photo-evidence/chapter35_live_"+frame.image+".webp",Vector2(0,49),frame.get("mirror",false)))
					var sequence_label := label(str(index+1)+" · "+frame.label.trim_prefix("FRM "),15,LakePalette.INK)
					sequence_label.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
					cell.add_child(sequence_label)
		else:
			var empty := label(str(index+1),21,LakePalette.PALE);empty.size_flags_vertical=Control.SIZE_EXPAND_FILL
			empty.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;empty.vertical_alignment=VERTICAL_ALIGNMENT_CENTER
			cell.add_child(empty)
	var gallery_hint := label("原始时间 07:55:23 · 点图预览，点编号排序",15,LakePalette.SECONDARY)
	gallery_hint.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	root.add_child(gallery_hint)
	var grid := GridContainer.new();grid.columns=3;grid.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	grid.add_theme_constant_override("h_separation",8);grid.add_theme_constant_override("v_separation",10);root.add_child(grid)
	for frame: Dictionary in Interlude.FRAMES:
		var cell := VBoxContainer.new();cell.custom_minimum_size.x=96;cell.size_flags_horizontal=Control.SIZE_EXPAND_FILL;grid.add_child(cell)
		var preview := Button.new();preview.name="C35View_"+frame.id;preview.tooltip_text="查看 "+frame.label
		preview.custom_minimum_size.y=94
		NativeUi.apply_button(preview,LakePalette.NIGHT,LakePalette.PAPER,LakePalette.EDGE,3,1,17,Vector2.ZERO,LakePalette.PALE)
		var photo := image_node("res://assets/ui/photo-evidence/chapter35_live_"+frame.image+".webp",Vector2.ZERO,frame.get("mirror",false))
		photo.name="RecoveredPhoto";photo.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED;photo.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);preview.add_child(photo)
		preview.pressed.connect(func() -> void:photo_view_id=frame.id;page_requested.emit("c35_photos"));cell.add_child(preview)
		var caption: String=(str(selected.find(frame.id)+1)+" · " if selected.has(frame.id) else "")+frame.label
		var select := action(cell,caption,"c35_select_photo",frame.id)
		if selected.has(frame.id):
			NativeUi.apply_button(select,LakePalette.SELECTED,LakePalette.INK,LakePalette.EDGE,3,1,17,Vector2(8,8),LakePalette.EDGE)
		else:
			NativeUi.apply_button(select,LakePalette.PAPER,LakePalette.INK,LakePalette.DISABLED,3,1,17,Vector2(8,8),LakePalette.EDGE)
		select.disabled=state.chapterThreeInterlude.photoSequenceSolved or (not selected.has(frame.id) and selected.size()>=3)
	if state.chapterThreeInterlude.photoSequenceSolved:
		var preview := PhotoSequence.new();preview.name="RecoveredSequence";preview.custom_minimum_size.y=132
		preview.configure(bool(state.native.get("settings",{}).get("reduced_motion",false)));root.add_child(preview)
		footer.add_child(label("连续帧已恢复",17,LakePalette.INK));return
	var controls := HBoxContainer.new();controls.add_theme_constant_override("separation",10);footer.add_child(controls)
	var reset := action(controls,"重排","c35_photo_reset");reset.custom_minimum_size.x=76;reset.size_flags_horizontal=Control.SIZE_SHRINK_BEGIN
	var submit := action(controls,"确认照片顺序","c35_photos",selected.duplicate(),true);submit.disabled=selected.size()!=3
	lake_primary(submit)

func photo_viewer(root: VBoxContainer) -> void:
	var frame: Dictionary={}
	for entry: Dictionary in Interlude.FRAMES:
		if entry.id==photo_view_id:frame=entry
	if frame.is_empty():photo_view_id="";photos(root);return
	var metadata := VBoxContainer.new();metadata.add_theme_constant_override("separation",4)
	root.add_child(metadata)
	metadata.add_child(label(frame.label,20))
	metadata.add_child(label("原始文件时间 · 07:55:23",15,MUTED))
	var image_width: float=AppFrame.EXTENT.x-2*AppFrame.READING_INSET
	root.add_child(image_node("res://assets/ui/photo-evidence/chapter35_live_"+frame.image+".webp",Vector2(0,image_width),frame.get("mirror",false)))
	var selected: Array=state.native.get("c35_photo_selection",[])
	var controls := HBoxContainer.new();controls.add_theme_constant_override("separation",10);root.add_child(controls)
	for shift: int in [-1,1]:
		button(controls,"上一张" if shift<0 else "下一张",func() -> void:
			var index := 0
			for i: int in range(Interlude.FRAMES.size()):
				if Interlude.FRAMES[i].id==photo_view_id:index=i
			photo_view_id=Interlude.FRAMES[posmod(index+shift,Interlude.FRAMES.size())].id;page_requested.emit("c35_photos"))
	var select := action(footer,"移出顺序" if selected.has(frame.id) else "选入第 %d 帧" % (selected.size()+1),"c35_select_photo",frame.id,true)
	select.disabled=state.chapterThreeInterlude.photoSequenceSolved or (not selected.has(frame.id) and selected.size()>=3)
	lake_primary(select)

func voice(root: VBoxContainer) -> void:
	var selected: Array=state.native.get("c35_voice_selection",[])
	var stage: String=state.native.get("c35_voice_stage","selection")
	var summary := VBoxContainer.new();summary.add_theme_constant_override("separation",6);root.add_child(summary)
	summary.add_child(label("1 / 2 筛选录音" if stage=="selection" else "2 / 2 排列顺序",18))
	summary.add_child(label("逐段试听，从七段恢复文件中留下同一次移动过程的四段。" if stage=="selection" else "根据环境声的连续变化，调整四段录音的先后位置。",15,MUTED))
	var records: Array=[]
	for clip_id: String in ["decoy_theater","lake","decoy_library","stone","decoy_canteen","lobby","broadcast"]:
		for recording: Dictionary in module.content("chapter3-interlude-voice-memos.audio.content").recordings:
			if recording.id==clip_id: records.append(recording)
	if stage=="ordering":
		var ordered: Array=[]
		for id: String in selected:
			for recording: Dictionary in records:
				if recording.id==id: ordered.append(recording)
		records=ordered
	for recording: Dictionary in records:
		var active: Variant=current_view.get("media_session")
		var current: Variant=active if active!=null and active.clip_id==recording.id else null
		var playing: bool=current!=null and current.phase=="playing"
		var paused: bool=current!=null and current.phase=="paused"
		var kept: bool=selected.has(recording.id)
		var reviewed: bool=module.voice_reviewed(state,recording.id)
		var row: VBoxContainer=card(root,Palette.SELECTED if playing else Palette.SURFACE)
		row.set_meta("recording_id",recording.id)
		row.add_theme_constant_override("separation",7)
		var panel: PanelContainer=row.get_parent()
		var frame: StyleBoxFlat=panel.get_theme_stylebox("panel").duplicate()
		frame.set_border_width_all(1)
		frame.border_color=GREEN if kept or playing else (Palette.MUTED if paused else Palette.LINE)
		frame.content_margin_left=12; frame.content_margin_right=12
		frame.content_margin_top=10; frame.content_margin_bottom=10
		frame.shadow_size=0; frame.shadow_offset=Vector2.ZERO
		panel.add_theme_stylebox_override("panel",frame)
		var heading: HBoxContainer=HBoxContainer.new();row.add_child(heading)
		var code: Label=label(str(recording.code),20);heading.add_child(code)
		var status: Label=label("候选 %d"%[selected.find(recording.id)+1] if kept else ("已试听" if reviewed else "待试听"),14,GREEN if kept or reviewed else MUTED)
		status.add_theme_font_size_override("font_size",14)
		status.autowrap_mode=TextServer.AUTOWRAP_OFF
		status.custom_minimum_size.x=64
		status.horizontal_alignment=HORIZONTAL_ALIGNMENT_RIGHT
		status.size_flags_horizontal=Control.SIZE_SHRINK_END
		heading.add_child(status)
		var generated: Dictionary=module.content("chapter3-interlude-voice-memos.audio.generated").assets.get(recording.asset,{})
		var waveform: VBoxContainer=VoiceProgress.new()
		waveform.setup(current,recording,generated,bool(state.native.get("settings",{}).get("reduced_motion",false)))
		row.add_child(waveform)
		var controls: HBoxContainer=HBoxContainer.new();controls.add_theme_constant_override("separation",8);row.add_child(controls)
		var play: Button=action(controls,"Ⅱ 暂停" if playing else "▶ 继续播放" if paused else "▶  %.1f 秒" % (float(generated.get("durationMs",recording.targetDurationMs))/1000),"c35_listen",recording.id)
		NativeUi.apply_button(play,GREEN if playing else Palette.CONTROL,Palette.SURFACE if playing else INK,Palette.LINE,3,1,15,Vector2(8,6),GREEN)
		if stage=="selection":
			var keep: Button=action(controls,"移出候选" if kept else "保留这段" if reviewed else "试听后可选","c35_select_voice",recording.id)
			keep.disabled=not reviewed and not kept
			NativeUi.apply_button(keep,GREEN if kept else Palette.CONTROL,Palette.SURFACE if kept else INK,GREEN if kept else Palette.LINE,3,1,15,Vector2(8,6),GREEN)
		else:
			action(controls,"上移","c35_voice_move",{"id":recording.id,"shift":-1}).disabled=selected.find(recording.id)==0
			action(controls,"下移","c35_voice_move",{"id":recording.id,"shift":1}).disabled=selected.find(recording.id)==selected.size()-1
		if reviewed:
			row.add_child(label(str(recording.revealZh)+" · "+str(recording.time),18,MUTED))
			var excerpts: GridContainer=GridContainer.new();excerpts.columns=2;excerpts.add_theme_constant_override("h_separation",6);excerpts.add_theme_constant_override("v_separation",6);row.add_child(excerpts)
			for index: int in range(recording.get("soundEvents",[]).size()):
				var part: Dictionary=recording.soundEvents[index]
				var excerpt: Button=action(excerpts,str(part.labelZh)+"\n"+{"near":"近","mid":"中","far":"远"}.get(str(part.distance),"")+"距","c35_excerpt",{"id":recording.id,"index":index})
				excerpt.custom_minimum_size=Vector2(0,54)
				excerpt.text_overrun_behavior=TextServer.OVERRUN_NO_TRIMMING
				NativeUi.apply_button(excerpt,Palette.CONTROL,INK,Palette.LINE,3,1,14,Vector2(6,5),GREEN)
	if state.chapterThreeInterlude.voiceSequenceSolved:
		footer.add_child(label("录音已归档 · 22:45:00",16,GREEN));return
	footer.add_child(label("已保留 %d / 4 段" % selected.size(),16))
	var controls := HBoxContainer.new();controls.add_theme_constant_override("separation",10);footer.add_child(controls)
	if stage=="selection":
		var clear := action(controls,"清空选择","c35_voice_clear");clear.custom_minimum_size.x=108;clear.size_flags_horizontal=Control.SIZE_SHRINK_BEGIN
		var next := action(controls,"进入排序","c35_voice_stage","ordering",true);next.disabled=selected.size()!=4
	else:
		var reset := action(controls,"重新筛选","c35_voice_stage","selection");reset.custom_minimum_size.x=108;reset.size_flags_horizontal=Control.SIZE_SHRINK_BEGIN
		var submit := action(controls,"确认录音顺序","c35_voice",selected.duplicate(),true);submit.disabled=selected.size()!=4

func official(root: VBoxContainer) -> void:
	var box := card(root,Color.WHITE)
	box.add_child(label("校园楼宇运行通知",15,MUTED))
	box.add_child(label("夜间闭楼与入口调整",25))
	box.add_child(label("公众号 · 22:40",15,GREEN))
	box.add_child(WechatSocial.article_cover(WechatSocial.load_campus_content(),Vector2(0,202)))
	box.add_child(label("22:45 起，北教学区一处楼宇进入夜间清楼。A 楼一层东侧入口暂停通行，人员请从大厅主入口进入。",19))
	box.add_child(label("主电梯保留运行，楼层开放情况以现场提示为准。",18))
	var saved: bool=state.chapterThreeInterlude.officialNoticeSaved
	var save := action(footer,"通知已保存" if saved else "保存通知","c35_official",null,true);save.disabled=saved
	navigate(root,"麦斯威夜间自习群  ›","c35_messages")

func messages(root: VBoxContainer) -> void:
	var selected: Array=state.native.get("c35_route_selection",[])
	var saved: bool=state.chapterThreeInterlude.routeScreenshotSaved
	var date := label("22:42",15,MUTED);date.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;root.add_child(date)
	for entry: Dictionary in module.route_messages():
		if entry.id=="withdrawn":
			var removed := label(entry.text,15,MUTED);removed.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;root.add_child(removed);continue
		var line := HBoxContainer.new();line.add_theme_constant_override("separation",10);root.add_child(line)
		var avatar := PanelContainer.new();avatar.custom_minimum_size=Vector2(40,40);avatar.size_flags_vertical=Control.SIZE_SHRINK_BEGIN
		var avatar_style := StyleBoxFlat.new();avatar_style.bg_color={"林昊":Color("547f9d"),"陈嘉":Color("7993a1"),"周琪":Color("70503b"),"室友":Color("385b79")}.get(entry.author,GREEN);avatar_style.set_corner_radius_all(4);avatar.add_theme_stylebox_override("panel",avatar_style)
		line.add_child(avatar);var initial := label(entry.author.left(1),18,Color.WHITE);initial.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;initial.vertical_alignment=VERTICAL_ALIGNMENT_CENTER;avatar.add_child(initial)
		var stack := VBoxContainer.new();stack.size_flags_horizontal=Control.SIZE_EXPAND_FILL;stack.add_theme_constant_override("separation",5);line.add_child(stack)
		var heading := HBoxContainer.new()
		heading.add_theme_constant_override("separation",8)
		stack.add_child(heading)
		heading.add_child(label(entry.author,15,LakePalette.SECONDARY))
		var picked: bool=selected.has(entry.id)
		if picked:
			var mark := label("已选择",15,LakePalette.INK)
			mark.name="C35RouteSelected"
			mark.autowrap_mode=TextServer.AUTOWRAP_OFF
			mark.size_flags_horizontal=Control.SIZE_SHRINK_END
			heading.add_child(mark)
		var panel := PanelContainer.new();panel.name="C35Message_"+entry.id
		var fill := LakePalette.SELECTED if picked else LakePalette.PAPER
		panel.add_theme_stylebox_override("panel",NativeUi.box(fill,LakePalette.EDGE if picked else Color.TRANSPARENT,1,4,Vector2(12,10)))
		stack.add_child(panel)
		var bubble := VBoxContainer.new();bubble.size_flags_horizontal=Control.SIZE_EXPAND_FILL;panel.add_child(bubble)
		var message := label(entry.text,18)
		message.autowrap_mode=TextServer.AUTOWRAP_ARBITRARY
		bubble.add_child(message)
		if not saved:
			var select := Button.new();select.name="C35MessageSelect_"+entry.id
			select.tooltip_text="取消选择" if selected.has(entry.id) else "选择这条消息"
			select.accessibility_name=select.tooltip_text+" · "+entry.author
			select.set_meta("phone_button_role","hit_region")
			select.set_meta("intent","c35_select_route");select.set_meta("intent_value",entry.id);select.set_meta("route_selected",selected.has(entry.id))
			select.custom_minimum_size.y=44
			for mode in ["normal","disabled","pressed"]:select.add_theme_stylebox_override(mode,StyleBoxEmpty.new())
			var hover := StyleBoxFlat.new();hover.bg_color=Color(Palette.INK,0.05);select.add_theme_stylebox_override("hover",hover)
			var focus := StyleBoxFlat.new();focus.bg_color=Color.TRANSPARENT;focus.border_color=LakePalette.EDGE;focus.set_border_width_all(2);select.add_theme_stylebox_override("focus",focus)
			select.pressed.connect(func() -> void:action_requested.emit("c35_select_route",entry.id))
			select.disabled=not selected.has(entry.id) and selected.size()>=2
			panel.add_child(select)
	if saved:
		var receipt := card(root,LakePalette.SELECTED);receipt.add_child(label("路线截图已保存",18,LakePalette.INK))
		receipt.add_child(label("22:42 入口调整截图\n东侧关闭 / 西侧主入口可通行",16))
		footer.add_child(label("已保存 2 条消息",15,LakePalette.INK))
	else:
		footer.add_child(label("点选消息 · 已选 %d / 2 条" % selected.size(),15,MUTED))
		var submit := action(footer,"保存路线截图","c35_route",selected.duplicate(),true);submit.disabled=selected.size()!=2
		lake_primary(submit)

func network(root: VBoxContainer) -> void:
	var filters: Dictionary=state.native.get("c35_network_filters",{"time":"all","session":"all","area":"all"})
	var filter_box := HBoxContainer.new()
	filter_box.add_theme_constant_override("separation",8)
	root.add_child(filter_box)
	var definitions: Array=[{"id":"time","label":"时间","options":[["all","全部时间"],["missing_475","未同步区间"],["last_minute","最后一分钟"]]},{"id":"session","label":"会话","options":[["all","全部设备"],["unknown_short","陌生短会话"],["authenticated","已认证设备"]]},{"id":"area","label":"区域","options":[["all","全部区域"],["north_a","北教学区 A 区"],["other","其他区域"]]}]
	for definition: Dictionary in definitions:
		var row := VBoxContainer.new()
		row.size_flags_horizontal=Control.SIZE_EXPAND_FILL
		filter_box.add_child(row)
		row.add_child(label(definition.label,15,MUTED))
		var options: OptionButton=OptionButton.new()
		options.size_flags_horizontal=Control.SIZE_EXPAND_FILL
		options.fit_to_longest_item=false;options.clip_text=true
		options.custom_minimum_size.y=44
		row.add_child(options);style_choice(options)
		NativeUi.apply_button(options,Palette.SURFACE,INK,Palette.LINE,3,1,15,Vector2(6,8),GREEN)
		for index: int in range(definition.options.size()):
			options.add_item(definition.options[index][1])
			if filters.get(definition.id,"all")==definition.options[index][0]: options.select(index)
		options.item_selected.connect(func(index: int) -> void: action_requested.emit("c35_filter",{"key":definition.id,"value":definition.options[index][0]}))
	var records: Array=module.filtered_records(state)
	root.add_child(label("查询结果  %d 条" % records.size(),14,MUTED))
	if records.is_empty(): root.add_child(label("没有符合当前筛选条件的记录。",17))
	else:
		var results := card(root)
		for record: Dictionary in records:
			if results.get_child_count()>0:rule(results)
			var row := HBoxContainer.new();row.add_theme_constant_override("separation",12);results.add_child(row)
			var details := VBoxContainer.new();details.size_flags_horizontal=Control.SIZE_EXPAND_FILL;row.add_child(details)
			details.add_child(label(record.label,18))
			details.add_child(label(record.detail,15,MUTED))
			var saved: bool=state.chapterThreeInterlude.networkRecordId==record.id
			var save := action(row,"已保存" if saved else "保存","c35_network",record.id)
			save.accessibility_name=("已保存" if saved else "保存候选记录")+" · "+str(record.label)
			save.custom_minimum_size.x=60
			save.size_flags_horizontal=Control.SIZE_SHRINK_END
			save.size_flags_vertical=Control.SIZE_SHRINK_CENTER
			NativeUi.apply_button(save,Palette.SELECTED if saved else Palette.CONTROL,GREEN if saved else INK,Palette.LINE,3,0,15,Vector2(8,8),GREEN)
	if state.chapterThreeInterlude.networkRecordId!=null:footer.add_child(label("候选记录已保存",16,GREEN))

func ticket(root: VBoxContainer) -> void:
	var c: Dictionary=module.content("chapter3-theater.content").cc98TicketCommission
	var t: Dictionary=state.theaterHunt
	eyebrow(root,"CC98 · "+str(c.board))
	root.add_child(label(c.title,23))
	var post: VBoxContainer=card(root,Color.WHITE)
	post.add_child(label(c.author+"  ·  "+c.time,14,MUTED))
	post.add_child(label(c.body,17))
	var archive: Dictionary=c.productionArchive
	var show: VBoxContainer=card(post,Palette.BACKGROUND)
	eyebrow(show,archive.seasonLabel)
	show.add_child(label(archive.title,24))
	show.add_child(label(archive.tagline,17))
	show.add_child(label(archive.summary,15,MUTED))
	for fact: Dictionary in archive.facts: show.add_child(label(fact.label+"  "+fact.value,15))
	post.add_child(label(c.initialReply,16,MUTED))
	var status: VBoxContainer=card(root,Palette.SELECTED)
	var phase: String=t.cc98TicketCommissionPhase
	var copy_key: String={"posted":"postedStatus","accepted":"acceptedStatus","first_wave_failed":"firstWaveStatus","delivered":"deliveredStatus"}.get(phase,"postedStatus")
	status.add_child(label(c[copy_key],17))
	if phase=="posted": action(status,c.acceptLabel,"c3_ticket_accept",null,true)
	elif phase in ["accepted","first_wave_failed"]: action(status,c.firstWaveLabel if phase=="accepted" else c.secondWaveLabel,"c3_ticket_claim",null,true)
	elif phase=="delivered":
		status.add_child(label(c.pickupCodeLabel,14,MUTED))
		status.add_child(label("0832",34,GREEN))
		status.add_child(label(c.pickupInstruction,16))
	var networks: HBoxContainer=HBoxContainer.new()
	root.add_child(networks)
	for entry: Array in [["campus_wifi","校园网"],["cellular","移动数据"],["offline","无网络"]]: action(networks,("● " if state.networkMode==entry[0] else "○ ")+entry[1],"c3_network",entry[0])
