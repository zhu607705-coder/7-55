extends RefCounted
## App-specific native Control reconstruction of Chapter 3 phone evidence surfaces.
## Emits only intents. Buttons never mutate validated puzzle facts.
signal action_requested(id: String,value: Variant)
signal page_requested(page: String)
const NativeUi=preload("res://scripts/ui/native_ui_theme.gd")
const JournalPages=preload("res://scripts/ui/c3_journal_pages.gd")
var journal_builder: RefCounted=JournalPages.new()
const VoiceProgress=preload("res://scripts/ui/c3_voice_progress.gd")
const PhotoSequence=preload("res://scripts/ui/c35_photo_sequence.gd")
var current_view: Dictionary={}
const Motion=preload("res://scripts/ui/c3_evidence_motion.gd")
var last_requested_page:String=""
var observed_ready:Array=[]
var pending_arrivals:Array=[]
var observed_recovery:bool=false
const Ring=preload("res://scripts/ui/c3_investigation_ring.gd")
const Interlude=preload("res://scripts/chapters/c3_interlude.gd")
var module: RefCounted=Interlude.new()
var state: Dictionary={}
var page_id: String=""
const INK=Color("101923")
const GREEN=Color("24677c")
const MUTED=Color("59676e")

func _init() -> void:
	journal_builder.action_requested.connect(_journal_action)
	journal_builder.page_requested.connect(_journal_page)

func _journal_action(id: String,value: Variant) -> void:
	action_requested.emit(id,value)

func _journal_page(page: String) -> void:
	page_requested.emit(page)

func build(page: String, _view: Dictionary, s: Dictionary) -> Control:
	# Source P18 Photos switches its contents for the interlude. Keep the
	# ordinary Home app route, but show its recovered frames in this phase.
	if page=="photos" and s.qizhenLake.phase=="complete" and not s.chapterThreeInterlude.completed: page="c35_photos"
	var page_entry:bool=page!=last_requested_page
	last_requested_page=page
	if page in ["c3_journal","c3_journal_camera"]: return journal_builder.build(page,_view,s)
	if page not in ["c35_recovery","c35_journal","c35_photos","c35_voice","c35_official","c35_messages","c35_network","c3_ticket_post"]: return null
	state=s
	current_view=_view
	page_id=page
	var ready_now:Array=[]
	var interlude:Dictionary=s.chapterThreeInterlude
	for pair:Array in [["c35_photos",interlude.photoSequenceSolved],["c35_voice",interlude.voiceSequenceSolved],["c35_official",interlude.officialNoticeSaved and interlude.routeScreenshotSaved],["c35_network",interlude.networkRecordRead]]:
		if pair[1]:ready_now.append(pair[0])
	if observed_recovery:
		for id:String in ready_now:
			if not observed_ready.has(id) and not pending_arrivals.has(id):pending_arrivals.append(id)
	observed_ready=ready_now;observed_recovery=true
	var root: VBoxContainer=VBoxContainer.new()
	root.set_meta("handles_all_actions",true)
	root.set_meta("source_page",true)
	# The scroll viewport owns width; fixed 396+padding+scrollbar widens the phone.
	root.custom_minimum_size.x=0
	root.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	root.add_theme_constant_override("separation",12)
	match page:
		"c35_recovery": recovery(root)
		"c35_journal": journal(root)
		"c35_photos": photos(root)
		"c35_voice": voice(root)
		"c35_official": official(root)
		"c35_messages": messages(root)
		"c35_network": network(root)
		"c3_ticket_post": ticket(root)
	# Source app header: 38px navigation column, title stack and stable 82px total rhythm.
	for unused: int in range(2):
		if root.get_child_count()>0 and root.get_child(0) is Label:
			var old: Node=root.get_child(0)
			root.remove_child(old)
			old.free()
	var header: HBoxContainer=HBoxContainer.new()
	header.custom_minimum_size.y=62
	header.add_theme_constant_override("separation",8)
	var back: Button=button(header,"‹",func() -> void:
		if page=="c35_voice": action_requested.emit("c35_voice_exit",null)
		else: page_requested.emit("phone_home" if page in ["c35_recovery","c3_ticket_post"] else "c35_recovery"))
	# 36 logical pixels retain a 28px target at the 390px compact scale.
	back.custom_minimum_size=Vector2(36,36)
	back.size_flags_horizontal=Control.SIZE_SHRINK_BEGIN
	back.size_flags_vertical=Control.SIZE_SHRINK_CENTER
	var heading: VBoxContainer=VBoxContainer.new()
	heading.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	heading.size_flags_vertical=Control.SIZE_SHRINK_CENTER
	header.add_child(heading)
	var labels: Dictionary={"c35_recovery":["RECOVERY 03.5","未同步的七分五十五秒"],"c35_journal":["CC98 小程序","启真湖划船记录"],"c35_photos":["PHOTOS","恢复的项目"],"c35_voice":["VOICE MEMOS","语音备忘录"],"c35_official":["公众号 · 22:40","紫金港楼宇服务"],"c35_messages":["群聊 · 18人","麦斯威夜间自习群"],"c35_network":["浙大钉 · 校园网络","夜间接入记录"],"c3_ticket_post":["CC98 · 校园生活","学生剧《7:55》临时退票"]}
	heading.add_child(label(labels[page][0],12,MUTED))
	heading.add_child(label(labels[page][1],21))
	root.add_child(header)
	root.move_child(header,0)
	var outer: PanelContainer=PanelContainer.new()
	outer.set_meta("handles_all_actions",true)
	outer.set_meta("source_page",true)
	outer.custom_minimum_size.x=0
	outer.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	var background: StyleBoxFlat=StyleBoxFlat.new()
	background.bg_color=Color("d7d9d2") if page in ["c35_recovery","c35_photos","c35_voice"] else Color("f0f0eb")
	background.content_margin_left=14
	background.content_margin_right=14
	background.content_margin_top=10
	background.content_margin_bottom=28
	outer.add_theme_stylebox_override("panel",background)
	outer.add_child(root)
	if page in ["c35_voice","c35_recovery"] and page_entry:Motion.enter(outer,bool(state.native.get("settings",{}).get("reduced_motion",false)))
	return outer

func label(text: String, size: int=17, color: Color=INK) -> Label:
	var node: Label=Label.new()
	node.text=text
	node.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	node.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	node.add_theme_font_size_override("font_size",maxi(10,int(round(size*0.8))))
	node.add_theme_color_override("font_color",color)
	return node

func card(parent: Control,color: Color=Color("eef0e9")) -> VBoxContainer:
	var panel: PanelContainer=PanelContainer.new()
	panel.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	var style: StyleBoxFlat=StyleBoxFlat.new()
	style.bg_color=color
	style.set_corner_radius_all(0)
	style.border_color=INK
	style.set_border_width_all(3 if page_id in ["c35_recovery","c35_photos","c35_voice"] else 1)
	style.shadow_color=Color(0.063,0.098,0.137,0.22)
	style.shadow_offset=Vector2(4,4)
	style.shadow_size=0
	style.content_margin_left=15
	style.content_margin_right=15
	style.content_margin_top=15
	style.content_margin_bottom=15
	panel.add_theme_stylebox_override("panel",style)
	parent.add_child(panel)
	var box: VBoxContainer=VBoxContainer.new()
	box.add_theme_constant_override("separation",10)
	panel.add_child(box)
	return box

func button(parent: Control,text: String,callback: Callable,accent: bool=false) -> Button:
	var node: Button=Button.new()
	node.text=text
	node.custom_minimum_size.y=44
	node.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	node.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	NativeUi.apply_button(node,GREEN if accent else Color("f0f0e8"),Color.WHITE if accent else INK,INK,0,3 if accent else 2,NativeUi.FONT_LABEL,Vector2(14,8),Color("7fd1d4") if accent else GREEN)
	node.pressed.connect(callback)
	if page_id in ["c35_voice","c35_recovery"]:Motion.press(node,bool(state.native.get("settings",{}).get("reduced_motion",false)))
	parent.add_child(node)
	return node

func action(parent: Control,text: String,id: String,value: Variant=null,accent: bool=false) -> Button:
	return button(parent,text,func() -> void: action_requested.emit(id,value),accent)

func navigate(parent: Control,text: String,page: String) -> void:
	button(parent,text,func() -> void: page_requested.emit(page))

func eyebrow(parent: Control,text: String) -> void:
	parent.add_child(label(text,12,MUTED))

func image_node(path: String,size: Vector2,mirror: bool=false) -> TextureRect:
	var image: TextureRect=TextureRect.new()
	image.expand_mode=TextureRect.EXPAND_IGNORE_SIZE
	image.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	image.custom_minimum_size=size
	image.flip_h=mirror
	image.mouse_filter=Control.MOUSE_FILTER_IGNORE
	if ResourceLoader.exists(path): image.texture=load(path)
	return image

func evidence_edge(box:VBoxContainer,edge:Color,width:int=1)->void:
	var panel:PanelContainer=box.get_parent()
	var style:StyleBoxFlat=panel.get_theme_stylebox("panel").duplicate()
	style.set_border_width_all(width);style.border_color=edge
	style.shadow_offset=Vector2(2,2)
	panel.add_theme_stylebox_override("panel",style)

func recovery(root: VBoxContainer) -> void:
	var c: Dictionary=state.chapterThreeInterlude
	eyebrow(root,"RECOVERY 03.5")
	root.add_child(label("未同步的七分五十五秒",25))
	if not c.recoveryOpened:
		var box: VBoxContainer=card(root,Color("eaf5ee"))
		box.add_child(label("检测到 7 分 55 秒未同步记录",21))
		box.add_child(label("启真湖的离开记录仍在，后面的去向没有写入。手机时钟与带来源的记录不一致，不能直接采用。",16))
		var grid: GridContainer=GridContainer.new()
		grid.columns=2
		box.add_child(grid)
		for text: String in ["媒体缓存  7 帧","短会话  3 条","通知归档  12 条","时间索引  异常"]: grid.add_child(label(text,14,MUTED))
		box.add_child(label("林星宇  我离开湖边以后，去了哪里？\n系统  照片、录音、消息都存了，就是没记清你去了哪。先看还能读出的。",16))
		action(box,"打开恢复工具","c35_begin",null,true)
		return
	var window: VBoxContainer=card(root,Color("e7f1ed"))
	evidence_edge(window,GREEN,2)
	eyebrow(window,"待核验时间窗")
	window.add_child(label(("22:37:05" if c.evidenceIds.has("journal_start") else "待恢复")+"  —  "+("22:45:00" if c.voiceSequenceSolved else "待恢复"),25,GREEN))
	window.add_child(label("对照离湖时刻和最后一段录音，查清这段时间发生了什么。",14,MUTED))
	if not c.evidenceIds.has("journal_start"):
		var box: VBoxContainer=card(root)
		box.add_child(label("先查离湖时间",20))
		box.add_child(label("划船帖的最后一条回复保留了带来源的离湖时间。",16))
		navigate(box,"查看划船帖","c35_journal")
		return
	var branches: Array=[{"label":"照片线索","page":"c35_photos","ready":c.photoSequenceSolved},{"label":"录音线索","page":"c35_voice","ready":c.voiceSequenceSolved},{"label":"消息线索","page":"c35_official","ready":c.officialNoticeSaved and c.routeScreenshotSaved},{"label":"网络记录","page":"c35_network","ready":c.networkRecordRead}]
	var box: VBoxContainer=card(root)
	eyebrow(box,"EVIDENCE LOOP")
	evidence_edge(box,Color("70898c"),1)
	box.add_child(label("留下了哪些记录",21))
	box.add_child(label("先看哪项都行，查过的会记在这里",14,MUTED))
	var ring: Control=Ring.new()
	ring.configure(branches,pending_arrivals.duplicate(),bool(state.native.get("settings",{}).get("reduced_motion",false)))
	pending_arrivals.clear()
	ring.page_requested.connect(func(page: String) -> void: page_requested.emit(page))
	box.add_child(ring)
	if c.evidenceIds.size()!=4: return
	var reasons: Array=[{"id":"number_not_time","label":"这是编号，不是本段记录的时间"},{"id":"earlier_independent_event","label":"这是更早的独立事件"},{"id":"frozen_local_clock","label":"这是本机冻结值，不能代表实际时间"}]
	var decoys: Array=[{"id":"canteen_0755","label":"食堂 0755"},{"id":"theater_0832","label":"剧场 08:32"},{"id":"status_clock_075523","label":"状态栏 07:55:23"}]
	for decoy: Dictionary in decoys:
		var row: VBoxContainer=card(root,Color("e3ebe2") if c.rejectedDecoyIds.has(decoy.id) else Color("eef0e9"))
		evidence_edge(row,Color("6e9285") if c.rejectedDecoyIds.has(decoy.id) else Color("70898c"),1)
		row.add_child(label(decoy.label+(" · 已排除" if c.rejectedDecoyIds.has(decoy.id) else " · 选择排除理由"),17))
		if c.rejectedDecoyIds.has(decoy.id): continue
		for reason: Dictionary in reasons: action(row,reason.label,"c35_reject:"+str(decoy.id),reason.id)
	if module.exclusions_ready(c):
		var timeline: VBoxContainer=card(root,Color("fffaf3"))
		evidence_edge(timeline,GREEN,2)
		timeline.add_child(label("自动恢复的时间线",20))
		for entry:Array in [["22:37:05","CC98 划船记录"],["时间缺失","恢复照片"],["区间末段","夜间接入记录"],["22:45:00","广播录音"]]:
			var line:HBoxContainer=HBoxContainer.new();line.custom_minimum_size.y=28;line.add_theme_constant_override("separation",10);timeline.add_child(line)
			var marker:ColorRect=ColorRect.new();marker.custom_minimum_size=Vector2(3,18);marker.size_flags_vertical=Control.SIZE_SHRINK_CENTER;marker.color=GREEN;line.add_child(marker)
			var time:Label=label(entry[0],16,GREEN);time.custom_minimum_size.x=80;time.size_flags_horizontal=Control.SIZE_SHRINK_BEGIN;line.add_child(time)
			line.add_child(label(entry[1],16))
		if c.destinationId==null:
			timeline.add_child(label("哪个地方能对上时间、沿途声音、入口变化和网络记录？",16))
			for place: Dictionary in Interlude.DESTINATIONS: action(timeline,place.label,"c35_destination",place.id)
		else: action(timeline,"开始回放","c35_replay",null,true)

func journal(root: VBoxContainer) -> void:
	eyebrow(root,"CC98 小程序")
	var article: VBoxContainer=card(root,Color.WHITE)
	article.add_child(label("舟  林星宇\n楼主 · 22:37",14,MUTED))
	article.add_child(label("启真湖划船记录｜风景很好，返程提前了",22))
	article.add_child(label("从小码头下水。湖面比岸边安静，风从剧场方向过来。最后一张照片没同步上来，我先回岸上整理。",17))
	article.add_child(image_node("res://assets/ui/photo-evidence/chapter35_live_lake_memory_a.webp",Vector2(340,150)))
	article.add_child(label("启真湖 · 22:37:05",13,MUTED))
	article.add_child(label("2楼  晚上水面反光挺亮，靠岸别太快。\n3楼  最后一张图像是朝东边拍的。",16))
	if state.chapterThreeInterlude.evidenceIds.has("journal_start"):
		navigate(root,"返回记录恢复","c35_recovery")
		return
	var choice: VBoxContainer=card(root)
	choice.add_child(label("本次记录准备结束，选择楼主的最后一条回复。",16))
	var selected: String=state.native.get("c35_summary_choice","details_withheld")
	action(choice,("● " if selected=="safe_return" else "○ ")+"安全返航\n船和人都回来了。湖上的事先记到这里，剩下的等我整理。","c35_summary_select","safe_return")
	action(choice,("● " if selected=="details_withheld" else "○ ")+"细节暂不公开\n最后一段发生了点不适合写进划船记录的事。人已上岸，其他细节暂时保留。","c35_summary_select","details_withheld")
	action(choice,"发布收尾并保存时间","c35_journal",selected,true)

func photos(root: VBoxContainer) -> void:
	eyebrow(root,"PHOTOS")
	root.add_child(label("恢复的项目",25))
	root.add_child(label("7 张 · 帧顺序损坏",14,MUTED))
	var selected: Array=state.native.get("c35_photo_selection",[])
	var stage: VBoxContainer=card(root)
	var stage_header: HBoxContainer=HBoxContainer.new()
	stage.add_child(stage_header)
	stage_header.add_child(label("IMG_0755_LIVE · 帧顺序损坏",17))
	var reset: Button=action(stage_header,"重排","c35_photo_reset")
	reset.name="PhotoReorder"
	reset.size_flags_horizontal=Control.SIZE_SHRINK_END
	reset.custom_minimum_size.x=72
	stage.add_child(label("选出同一段运动中连续的三帧，再按先后顺序放入。",16,MUTED))
	for slot: int in range(3):
		var text: String="%d · 待选择"%[slot+1]
		if slot<selected.size():
			for frame: Dictionary in Interlude.FRAMES:
				if frame.id==selected[slot]: text="%d · %s"%[slot+1,frame.label]
		stage.add_child(label(text,17))
	var grid: GridContainer=GridContainer.new()
	grid.columns=3
	grid.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	grid.add_theme_constant_override("h_separation",7)
	grid.add_theme_constant_override("v_separation",8)
	root.add_child(grid)
	for frame: Dictionary in Interlude.FRAMES:
		var cell: VBoxContainer=VBoxContainer.new()
		cell.custom_minimum_size.x=94
		cell.size_flags_horizontal=Control.SIZE_EXPAND_FILL
		grid.add_child(cell)
		var portrait: AspectRatioContainer=AspectRatioContainer.new()
		portrait.ratio=0.78
		portrait.stretch_mode=AspectRatioContainer.STRETCH_WIDTH_CONTROLS_HEIGHT
		portrait.size_flags_horizontal=Control.SIZE_EXPAND_FILL
		portrait.custom_minimum_size=Vector2(94,94/0.78)
		# AspectRatioContainer sizes its child, not the following VBox row.
		# Reserve the complete source portrait height after width allocation.
		portrait.resized.connect(func() -> void: portrait.custom_minimum_size.y=portrait.size.x/0.78)
		cell.add_child(portrait)
		var preview: Button=Button.new()
		preview.set_meta("recovered_frame",frame.id)
		preview.disabled=selected.has(frame.id) or selected.size()>=3
		var photo: TextureRect=image_node("res://assets/ui/photo-evidence/chapter35_live_"+str(frame.image)+".webp",Vector2.ZERO,frame.get("mirror",false))
		photo.name="RecoveredPhoto"
		photo.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_COVERED
		photo.texture_filter=CanvasItem.TEXTURE_FILTER_NEAREST
		photo.modulate.a=0.45 if preview.disabled else 1.0
		photo.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		preview.add_child(photo)
		preview.pressed.connect(func() -> void: action_requested.emit("c35_select_photo",frame.id))
		portrait.add_child(preview)
		var title: String=frame.label
		if selected.has(frame.id): title="%d  %s" % [selected.find(frame.id)+1,title]
		var select: Button=action(cell,title,"c35_select_photo",frame.id)
		select.disabled=preview.disabled
		cell.add_child(label("07:55:23",11,MUTED))
	var order: VBoxContainer=card(root)
	order.add_child(label("已选择 %d / 3 张" % selected.size(),17))
	if state.chapterThreeInterlude.photoSequenceSolved:
		var preview: TextureRect=PhotoSequence.new()
		preview.name="RecoveredSequence"
		preview.custom_minimum_size.y=132
		preview.configure(bool(state.native.get("settings",{}).get("reduced_motion",false)))
		order.add_child(preview)
		order.add_child(label("连续帧已恢复",17,GREEN))
	var submit: Button=action(order,"确认照片顺序","c35_photos",selected.duplicate(),true)
	submit.disabled=selected.size()!=3

func voice(root: VBoxContainer) -> void:
	eyebrow(root,"VOICE MEMOS")
	root.add_child(label("录音",25))
	root.add_child(label("时间索引异常 · 核对录音里的环境与声音",14,MUTED))
	var selected: Array=state.native.get("c35_voice_selection",[])
	var stage: String=state.native.get("c35_voice_stage","selection")
	var summary: VBoxContainer=card(root,Color("d9ebe5"))
	summary.add_child(label("1 / 2 筛选录音" if stage=="selection" else "2 / 2 排列顺序",14,GREEN))
	summary.add_child(label("逐段试听，从七段恢复文件中留下同一次移动过程的四段。" if stage=="selection" else "根据环境声的连续变化，调整四段录音的先后位置。",14,MUTED))
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
		var row: VBoxContainer=card(root,Color("f0dfdc") if playing else Color("eef0e9"))
		row.set_meta("recording_id",recording.id)
		row.add_theme_constant_override("separation",7)
		var panel: PanelContainer=row.get_parent()
		var frame: StyleBoxFlat=panel.get_theme_stylebox("panel").duplicate()
		frame.set_border_width_all(2 if playing or paused else 1)
		frame.border_color=Color("c72f3a") if playing else (Color("8a5558") if paused else Color("546269"))
		if kept: frame.border_width_left=5; frame.border_color=GREEN
		frame.content_margin_left=12; frame.content_margin_right=12
		frame.content_margin_top=10; frame.content_margin_bottom=10
		frame.shadow_size=0; frame.shadow_offset=Vector2(2,2)
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
		NativeUi.apply_button(play,Color("c72f3a") if playing else Color("fffaf3"),Color.WHITE if playing else Color("942931"),Color("c72f3a"),0,2,14,Vector2(8,6))
		if stage=="selection":
			var keep: Button=action(controls,"✓ 移出候选" if kept else "保留这段" if reviewed else "试听后可选","c35_select_voice",recording.id)
			NativeUi.apply_button(keep,GREEN if kept else Color("dbe7e2"),Color.WHITE if kept else INK,GREEN,0,2,14,Vector2(8,6))
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
				NativeUi.apply_button(excerpt,Color("dbe7e2"),Color("22353b"),Color("70898c"),0,1,14,Vector2(6,5))
	var order: VBoxContainer=card(root)
	order.add_child(label("录音顺序  %d / 4" % selected.size(),18))
	for id: String in selected:
		for recording: Dictionary in records:
			if recording.id==id: order.add_child(label("%d  %s" % [selected.find(id)+1,recording.code],15))
	if stage=="selection":
		action(order,"清空选择","c35_voice_clear")
		var next: Button=action(order,"进入排序","c35_voice_stage","ordering",true)
		next.disabled=selected.size()!=4
	else:
		action(order,"重新筛选","c35_voice_stage","selection")
		var submit: Button=action(order,"确认录音顺序","c35_voice",selected.duplicate(),true)
		submit.disabled=selected.size()!=4

func official(root: VBoxContainer) -> void:
	eyebrow(root,"公众号 · 22:40")
	root.add_child(label("紫金港楼宇服务",23))
	var box: VBoxContainer=card(root,Color.WHITE)
	eyebrow(box,"校园楼宇运行通知")
	box.add_child(label("夜间闭楼与入口调整",23))
	box.add_child(label("22:45 起，北教学区一处楼宇进入夜间清楼。A 楼一层东侧入口暂停通行，人员请从大厅主入口进入。",18))
	box.add_child(label("主电梯保留运行，楼层开放情况以现场提示为准。",17))
	action(box,"通知已保存" if state.chapterThreeInterlude.officialNoticeSaved else "保存通知","c35_official",null,true)
	navigate(root,"麦斯威夜间自习群","c35_messages")
	navigate(root,"返回记录恢复","c35_recovery")

func messages(root: VBoxContainer) -> void:
	eyebrow(root,"群聊 · 18人")
	root.add_child(label("麦斯威夜间自习群",23))
	var selected: Array=state.native.get("c35_route_selection",[])
	for entry: Dictionary in Interlude.MESSAGES:
		var bubble: VBoxContainer=card(root,Color("d3efc6") if selected.has(entry.id) else Color.WHITE)
		eyebrow(bubble,entry.author)
		bubble.add_child(label(entry.text,18))
		if not state.chapterThreeInterlude.routeScreenshotSaved:
			action(bubble,"已选" if selected.has(entry.id) else "选择","c35_select_route",entry.id)
	if state.chapterThreeInterlude.routeScreenshotSaved:
		var shot: VBoxContainer=card(root,Color("e8eee7"))
		shot.add_child(label("A1",35,GREEN))
		shot.add_child(label("22:42 入口调整截图\n东侧关闭 / 西侧主入口可通行",16))
	else:
		var submit: Button=action(root,"保存路线截图","c35_route",selected.duplicate(),true)
		submit.disabled=selected.size()!=2
	navigate(root,"公众号通知","c35_official")

func network(root: VBoxContainer) -> void:
	eyebrow(root,"浙大钉 · 校园网络")
	root.add_child(label("夜间接入记录",24))
	var filters: Dictionary=state.native.get("c35_network_filters",{"time":"all","session":"all","area":"all"})
	var filter_box: VBoxContainer=card(root)
	var definitions: Array=[{"id":"time","label":"时间","options":[["all","全部时间"],["missing_475","未同步区间"],["last_minute","最后一分钟"]]},{"id":"session","label":"会话","options":[["all","全部设备"],["unknown_short","陌生短会话"],["authenticated","已认证设备"]]},{"id":"area","label":"区域","options":[["all","全部区域"],["north_a","北教学区 A 区"],["other","其他区域"]]}]
	for definition: Dictionary in definitions:
		var row: HBoxContainer=HBoxContainer.new()
		filter_box.add_child(row)
		row.add_child(label(definition.label,15,MUTED))
		var options: OptionButton=OptionButton.new()
		options.size_flags_horizontal=Control.SIZE_EXPAND_FILL
		options.custom_minimum_size.y=38
		row.add_child(options)
		for index: int in range(definition.options.size()):
			options.add_item(definition.options[index][1])
			if filters.get(definition.id,"all")==definition.options[index][0]: options.select(index)
		options.item_selected.connect(func(index: int) -> void: action_requested.emit("c35_filter",{"key":definition.id,"value":definition.options[index][0]}))
	var records: Array=module.filtered_records(state)
	root.add_child(label("查询结果  %d 条" % records.size(),14,MUTED))
	for record: Dictionary in records:
		var row: VBoxContainer=card(root,Color.WHITE)
		row.add_child(label(record.label,18))
		row.add_child(label(record.detail,15,MUTED))
		action(row,"已保存" if state.chapterThreeInterlude.networkRecordId==record.id else "保存候选记录","c35_network",record.id,true)
	if records.is_empty(): root.add_child(label("没有符合当前筛选条件的记录。",17))
	navigate(root,"返回记录恢复","c35_recovery")

func ticket(root: VBoxContainer) -> void:
	var c: Dictionary=module.content("chapter3-theater.content").cc98TicketCommission
	var t: Dictionary=state.theaterHunt
	eyebrow(root,"CC98 · "+str(c.board))
	root.add_child(label(c.title,23))
	var post: VBoxContainer=card(root,Color.WHITE)
	post.add_child(label(c.author+"  ·  "+c.time,14,MUTED))
	post.add_child(label(c.body,17))
	var archive: Dictionary=c.productionArchive
	var show: VBoxContainer=card(post,Color("e8ebf1"))
	eyebrow(show,archive.seasonLabel)
	show.add_child(label(archive.title,24))
	show.add_child(label(archive.tagline,17))
	show.add_child(label(archive.summary,15,MUTED))
	for fact: Dictionary in archive.facts: show.add_child(label(fact.label+"  "+fact.value,15))
	post.add_child(label(c.initialReply,16,MUTED))
	var status: VBoxContainer=card(root,Color("ecf4ec"))
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
