extends SceneTree
const Pages=preload("res://scripts/ui/chapter3_phone_pages.gd")
const MediaHost=preload("res://scripts/media/c3_media_host.gd")
const Chapter=preload("res://scripts/chapters/chapter3.gd")
var checks: int=0
var errors: int=0
func check(condition: bool,message: String) -> void:
	checks+=1
	if not condition: errors+=1; push_error(message)
func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var ui: RefCounted=Pages.new()
	var controller: RefCounted=Chapter.new()
	var s: Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://data/initial_state.json"))
	s.native={"chapter":3,"page":"c35_recovery","scene":"","mode":"light","player":{},"selected_item":"","log":[],"completed":[]}
	s.qizhenLake.phase="complete"
	s.qizhenLake.active=true
	controller.dispatch(s,"c35_begin")
	controller.dispatch(s,"c35_journal","safe_return")
	var media: Node=MediaHost.new()
	root.add_child(media)
	media.setup(func() -> Dictionary: return s)
	media.event.connect(func(id: String,value: Variant) -> void: controller.dispatch(s,id,value))
	ui.action_requested.connect(func(id: String,value: Variant) -> void:
		var request: Dictionary=controller.dispatch(s,id,value)
		if request.get("media") is Dictionary: media.apply(request.media))
	for page: String in ["c35_recovery","c35_journal","c35_photos","c35_voice","c35_official","c35_messages","c35_network","c3_ticket_post"]:
		var surface: Control=ui.build(page,controller.view(page,s),s)
		check(surface!=null,"specialized page exists "+page)
		check(surface.get_child_count()>=1 and surface.get_child(0).get_child_count()>=2,"page contains native content "+page)
		root.add_child(surface)
		surface.free()
	check(ui.build("unrelated",{},s)==null,"unknown pages safely delegate")
	controller.dispatch(s,"c35_select_photo","paper_left")
	controller.dispatch(s,"c35_select_photo","paper_middle")
	controller.dispatch(s,"c35_select_photo","paper_right")
	check(s.native.c35_photo_selection.size()==3 and not s.chapterThreeInterlude.photoSequenceSolved,"photo UI selection does not solve automatically")
	controller.dispatch(s,"c35_photos",s.native.c35_photo_selection)
	check(s.chapterThreeInterlude.photoSequenceSolved,"explicit photo submit validates")
	controller.dispatch(s,"c35_filter",{"key":"time","value":"missing_475"})
	controller.dispatch(s,"c35_filter",{"key":"session","value":"unknown_short"})
	controller.dispatch(s,"c35_filter",{"key":"area","value":"north_a"})
	var result: Array=controller.interlude.filtered_records(s)
	check(result.size()==1 and result[0].id=="record_0755","three source filters isolate actual short network record")
	check(not s.chapterThreeInterlude.networkRecordRead,"filtering never auto-saves evidence")
	# Exercise the full recovered-phone route through the actual native Button signals.
	s.chapterThreeInterlude=JSON.parse_string(FileAccess.get_file_as_string("res://data/initial_state.json")).chapterThreeInterlude
	s.native.erase("c35_photo_selection")
	s.native.erase("c35_voice_selection")
	press(ui,controller,s,"c35_recovery","打开恢复工具")
	press(ui,controller,s,"c35_journal","安全返航")
	check(not s.chapterThreeInterlude.evidenceIds.has("journal_start"),"summary selection does not publish early")
	press(ui,controller,s,"c35_journal","发布收尾并保存时间")
	for code: String in ["FRM B2","FRM 91","FRM 4C"]: press(ui,controller,s,"c35_photos",code)
	press(ui,controller,s,"c35_photos","确认照片顺序")
	for code: String in ["CLIP D7","CLIP 91","CLIP 4C","CLIP 3A"]:
		press(ui,controller,s,"c35_voice","▶",code)
		await create_timer(4.65).timeout
		press(ui,controller,s,"c35_voice","保留这段",code)
	press(ui,controller,s,"c35_voice","进入排序")
	press(ui,controller,s,"c35_voice","确认录音顺序")
	press(ui,controller,s,"c35_official","保存通知")
	press(ui,controller,s,"c35_messages","选择","东边入口已经封了")
	press(ui,controller,s,"c35_messages","选择","我在西侧看见保洁推车")
	press(ui,controller,s,"c35_messages","保存路线截图")
	press(ui,controller,s,"c35_network","保存候选记录","22:44:57")
	check(s.chapterThreeInterlude.evidenceIds.size()==4,"all four sources can be collected through native UI buttons")
	press(ui,controller,s,"c35_recovery","这是编号","食堂 0755")
	press(ui,controller,s,"c35_recovery","这是更早","剧场 08:32")
	press(ui,controller,s,"c35_recovery","这是本机","状态栏 07:55:23")
	press(ui,controller,s,"c35_recovery","段永平教学楼 A 楼一层")
	press(ui,controller,s,"c35_recovery","开始回放")
	check(s.chapterThreeInterlude.replayUnlocked,"entire validated interlude completes through native UI signals")
	if not await media.shutdown():
		errors+=1
	media.queue_free()
	await process_frame
	await process_frame
	print("Chapter 3 native phone UI checks: ",checks,"; failures: ",errors)
	quit(0 if errors==0 else 1)

func contains_text(node: Node,text: String) -> bool:
	if node is Label and text in node.text: return true
	for child: Node in node.get_children():
		if contains_text(child,text): return true
	return false
func find_card(node: Node,text: String) -> Node:
	for child: Node in node.get_children():
		if child is PanelContainer and contains_text(child,text): return child
		var nested: Node=find_card(child,text)
		if nested!=null: return nested
	return null
func find_button(node: Node,text: String) -> Button:
	if node is Button and text in node.text: return node
	for child: Node in node.get_children():
		var found: Button=find_button(child,text)
		if found!=null: return found
	return null
func press(ui: RefCounted,controller: RefCounted,s: Dictionary,page: String,text: String,row_text: String="") -> void:
	s.native.page=page
	var surface: Control=ui.build(page,controller.view(page,s),s)
	var scope: Node=surface if row_text.is_empty() else find_card(surface,row_text)
	var selected: Button=find_button(scope,text) if scope!=null else null
	check(selected!=null and not selected.disabled,"native button reachable "+page+" / "+text+" / "+row_text)
	if selected!=null and not selected.disabled: selected.pressed.emit()
	surface.free()
